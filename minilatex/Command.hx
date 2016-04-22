package minilatex;
import minilatex.Token;
import minilatex.ExpansionProcessor;
import minilatex.ExecutionProcessor;
import minilatex.Error;
import minilatex.Scope;
import minilatex.Environment;
import minilatex.TeXPrimitive;
import minilatex.Util;
using Token.TokenValueExtender;
using Token.TokenUtil;
using Command.ScopeExtender;
using ExpansionProcessor.ExpansionProcessorUtil;
using Util.NullExtender;
class ScopeExtender
{
    public static function defineUnsupportedCommand(scope: TDefiningScope<IExecutionProcessor>, name: String)
    {
        scope.defineExecutableCommandT(ControlSequence(name), new UnsupportedCommand(name));
    }
}
class UserCommand implements ExpandableCommand
{
    var name: TokenValue;
    var numberOfArguments: Int;
    var defaultValueForOptionalArgument: Null<Array<Token>>;
    var definitionBody: Array<Token>;
    var isLong: Bool;
    public function new(name: TokenValue, numberOfArguments, defaultValueForOptionalArgument, definitionBody, isLong)
    {
        this.name = name;
        this.numberOfArguments = numberOfArguments;
        this.defaultValueForOptionalArgument = defaultValueForOptionalArgument;
        this.definitionBody = definitionBody;
        this.isLong = isLong;
    }
    public function expand(processor: IExpansionProcessor)
    {
        var remainingArguments = this.numberOfArguments;
        var arguments: Array<Array<Token>> = [];
        if (remainingArguments > 0 && this.defaultValueForOptionalArgument != null) {
            var arg = processor.readOptionalArgument(this.name, this.isLong, this.defaultValueForOptionalArgument);
            arguments.push(arg);
            --remainingArguments;
        }
        while (remainingArguments > 0) {
            var arg = processor.readArgument(this.name, this.isLong);
            if (arg == null) {
                throw new LaTeXError("user-defined command: missing arguments");
            }
            arguments.push(arg);
            --remainingArguments;
        }
        var it = this.definitionBody.iterator();
        var result: Array<Token> = [];
        while (it.hasNext()) {
            var t = it.next();
            switch (t.value) {
            case Parameter(_):
                var u = it.next();
                if (u == null) {
                    throw new LaTeXError("user-defined command: invalid use of parameter character");
                }
                switch (u.value) {
                case Parameter(_):
                    result.push(u);
                case Character(c):
                    var index = TokenUtil.digitValue(c);
                    if (index == null || index <= 0) {
                        throw new LaTeXError("user-defined command: invalid parameter character");
                    };
                    if (index > this.numberOfArguments) {
                        throw new LaTeXError("user-defined command: parameter out of range");
                    }
                    result = result.concat(arguments[index-1]);
                case _:
                    throw new LaTeXError("user-defined command: invalid use of parameter character");
                }
            default:
                result.push(t);
            }
        }
        return result;
    }
}
class NewcommandCommand implements ExecutableCommand<IExecutionProcessor>
{
    var name: TokenValue;
    public function new(name = "newcommand")
    {
        this.name = ControlSequence(name);
    }
    public function execute(processor: IExecutionProcessor)
    {
        var expansionProcessor = processor.getExpansionProcessor();
        var isLong = !expansionProcessor.hasStar();
        var cmd = expansionProcessor.readArgument(this.name, false);
        var name = switch (cmd) {
        case [x]: x.value;
        case _: throw new LaTeXError(this.name.toString() + ": invalid command name");
        };
        var args = expansionProcessor.expandOptionalArgument(this.name, false);
        var numberOfArguments = args == null ? 0 : TokenUtil.tokenListToInt(args).throwIfNull(new LaTeXError(this.name.toString() + ": invalid number of arguments"));
        var opt = expansionProcessor.readOptionalArgument(this.name, true);
        var definitionBody = expansionProcessor.readArgument(this.name, true);
        var command = new UserCommand(name, numberOfArguments, opt, definitionBody, isLong);
        this.doDefineCommand(expansionProcessor.getCurrentScope(), name, command);
    }
    public function doDefineCommand(scope: IScope, name: TokenValue, command: ExpandableCommand)
    {
        if (scope.isCommandDefined(name)) {
            throw new LaTeXError("\\newcommand: command " + name.toString() + " is already defined");
        } else {
            scope.defineExpandableCommand(name, command);
        }
    }
}
class RenewcommandCommand extends NewcommandCommand
{
    public function new()
    {
        super("renewcommand");
    }
    public override function doDefineCommand(scope: IScope, name: TokenValue, command: ExpandableCommand)
    {
        if (!scope.isCommandDefined(name)) {
            throw new LaTeXError("\\renewcommand: command " + name.toString() + " is not defined");
        } else {
            scope.defineExpandableCommand(name, command);
        }
    }
}
class ProvidecommandCommand extends NewcommandCommand
{
    public function new()
    {
        super("providecommand");
    }
    public override function doDefineCommand(scope: IScope, name: TokenValue, command: ExpandableCommand)
    {
        if (!scope.isCommandDefined(name)) {
            scope.defineExpandableCommand(name, command);
        }
    }
}
class MakeatCommand implements ExecutableCommand<IExecutionProcessor>
{
    var atletter: Bool;
    public function new(atletter: Bool)
    {
        this.atletter = atletter;
    }
    public function execute(processor: IExecutionProcessor)
    {
        processor.setAtLetter(this.atletter);
    }
}
class VerbCommand implements ExecutableCommand<IExecutionProcessor>
{
    public function new()
    {
    }
    private static function characterValue(token: Null<ExpansionToken>): String
    {
        if (token == null) {
            throw new LaTeXError("unexpected end of input during \\verb");
        }
        return switch (token.token.value) {
        case Character(c): c;
        default:
            throw new LaTeXError("invalid token in \\verb");
        };
    }
    public function execute(processor: IExecutionProcessor)
    {
        var tokenizer = processor.getTokenizer();
        tokenizer.enterVerbatimMode();
        var exp = processor.getExpansionProcessor();
        var isInsideMacro = exp.hasPendingToken();
        var delimiterToken = exp.nextToken();
        if (delimiterToken == null) {
            throw new LaTeXError("\\verb: argument missing");
        }
        var delimiter = characterValue(delimiterToken);
        var star = false;
        if (delimiter == '*') {
            star = true;
            isInsideMacro = exp.hasPendingToken();
            delimiterToken = exp.nextToken();
            delimiter = characterValue(delimiterToken);
        }
        var name = star ? "\\verb*" : "\\verb";
        if (isInsideMacro) {
            throw new LaTeXError(name + " cannot be used inside macro argument");
        }
        if (delimiter == ' ') {
            throw new LaTeXError("there must not be a space character between " + name + " and the delimiter");
        }
        var result = new StringBuf();
        while (true) {
            var t = exp.nextToken();
            var c = characterValue(t);
            if (c == delimiter) {
                tokenizer.leaveVerbatimMode();
                processor.verbCommand(result.toString(), star);
                return;
            } else if (c == '\n') {
                throw new LaTeXError(name + " cannot contain a newline");
            }
            result.add(c);
        }
    }
}
class UnsupportedCommand implements ExecutableCommand<IExecutionProcessor>
{
    var name: String;
    public function new(name: String)
    {
        this.name = name;
    }
    public function execute(processor: IExecutionProcessor)
    {
        throw new LaTeXError("command '\\" + this.name + "' is not supported");
    }
}
class DefaultScope
{
    public static function defineStandardCommands(scope: TDefiningScope<IExecutionProcessor>)
    {
        TeXPrimitive.defineTeXPrimitives(scope);
        scope.defineExecutableCommandT(ControlSequence("newcommand"), new NewcommandCommand());
        scope.defineExecutableCommandT(ControlSequence("renewcommand"), new RenewcommandCommand());
        scope.defineExecutableCommandT(ControlSequence("providecommand"), new ProvidecommandCommand());
        scope.defineExecutableCommandT(ControlSequence("makeatletter"), new MakeatCommand(true));
        scope.defineExecutableCommandT(ControlSequence("makeatother"), new MakeatCommand(false));
        scope.defineExecutableCommandT(ControlSequence("verb"), new VerbCommand());
        scope.defineExecutableCommandT(ControlSequence("newenvironment"), new NewenvironmentCommand());
        scope.defineExecutableCommandT(ControlSequence("renewenvironment"), new RenewenvironmentCommand());
        scope.defineExpandableCommand(ControlSequence("begin"), new BeginEnvironmentCommand());
        scope.defineExpandableCommand(ControlSequence("end"), new EndEnvironmentCommand());
        scope.defineExecutableCommandT(InternalBeginEnvironmentCommand.commandName, new InternalBeginEnvironmentCommand());
        scope.defineExecutableCommandT(InternalEndEnvironmentCommand.commandName, new InternalEndEnvironmentCommand());
    }
    public static function getDefaultScope<E: IExecutionProcessor>(): Scope<E>
    {
        var scope = new Scope<E>(null);
        defineStandardCommands(scope);
        return scope;
    }
}
