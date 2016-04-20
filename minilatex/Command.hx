package minilatex;
import haxe.ds.Option;
import minilatex.Token;
import minilatex.ExpansionProcessor;
import minilatex.ExecutionProcessor;
import minilatex.Error;
import minilatex.Scope;
import minilatex.Util;
using Token.TokenValueExtender;
using Token.TokenUtil;
using Command.ScopeExtender;
using ExpansionProcessor.ExpansionProcessorUtil;
using Util.NullExtender;
class ScopeExtender
{
    public static function defineUnsupportedCommand(scope: Scope, name: String)
    {
        scope.defineExecutableCommand(ControlSequence(name), new UnsupportedCommand(name));
    }
    public static function defineUnsupportedTeXPrimitive(scope: Scope, name: String)
    {
        scope.defineExecutableCommand(ControlSequence(name), new UnsupportedTeXPrimitive(name));
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
    public function doExpand(processor: IExpansionProcessor)
    {
        var remainingArguments = this.numberOfArguments;
        var arguments: Array<Array<Token>> = [];
        if (remainingArguments > 0 && this.defaultValueForOptionalArgument != null) {
            var arg = processor.readOptionalArgument(this.defaultValueForOptionalArgument);
            if (!this.isLong) {
                arg.checkNoPar(this.name.toString());
            }
            arguments.push(arg);
            --remainingArguments;
        }
        while (remainingArguments > 0) {
            var arg = processor.readArgument();
            if (arg == null) {
                throw new LaTeXError("user-defined command: missing arguments");
            }
            if (!this.isLong) {
                arg.checkNoPar(this.name.toString());
            }
            arguments.push(arg);
            --remainingArguments;
        }
        var it = this.definitionBody.iterator();
        var result: Array<Token> = [];
        while (it.hasNext()) {
            var t = it.next();
            switch (t.value) {
            case Character('#'):
                var u = it.next();
                if (u == null) {
                    throw new LaTeXError("user-defined command: invalid use of parameter character");
                }
                switch (u.value) {
                case Character('#'):
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
class NewcommandCommand implements ExecutableCommand
{
    var name: String;
    public function new(name: String = "\\newcommand")
    {
        this.name = name;
    }
    public function doDefineCommand(processor: ExecutionProcessor, name: TokenValue, command: ExpandableCommand)
    {
        if (processor.expansionProcessor.currentScope.isCommandDefined(name)) {
            throw new LaTeXError("\\newcommand: command " + name.toString() + " is already defined");
        } else {
            processor.expansionProcessor.currentScope.defineExpandableCommand(name, command);
        }
    }
    public function doCommand(processor: ExecutionProcessor)
    {
        var isLong = !processor.expansionProcessor.hasStar();
        var cmd = processor.expansionProcessor.readArgument().checkNoPar(this.name);
        var name = switch (cmd) {
        case [x]: x.value;
        case _: throw new LaTeXError(this.name + ": invalid command name");
        };
        var args = processor.expansionProcessor.expandOptionalArgument().checkNoPar(this.name);
        var numberOfArguments = args == null ? 0 : TokenUtil.tokenListToInt(args).throwIfNull(new LaTeXError(this.name + ": invalid number of arguments"));
        var opt = processor.expansionProcessor.readOptionalArgument();
        var definitionBody = processor.expansionProcessor.readArgument();
        var command = new UserCommand(name, numberOfArguments, opt, definitionBody, isLong);
        this.doDefineCommand(processor, name, command);
        return [];
    }
}
class RenewcommandCommand extends NewcommandCommand
{
    public function new()
    {
        super("\\renewcommand");
    }
    public override function doDefineCommand(processor: ExecutionProcessor, name: TokenValue, command: ExpandableCommand)
    {
        if (!processor.expansionProcessor.currentScope.isCommandDefined(name)) {
            throw new LaTeXError("\\renewcommand: command " + name.toString() + " is not defined");
        } else {
            processor.expansionProcessor.currentScope.defineExpandableCommand(name, command);
        }
    }
}
class ProvidecommandCommand extends NewcommandCommand
{
    public function new()
    {
        super("\\providecommand");
    }
    public override function doDefineCommand(processor: ExecutionProcessor, name: TokenValue, command: ExpandableCommand)
    {
        if (!processor.expansionProcessor.currentScope.isCommandDefined(name)) {
            processor.expansionProcessor.currentScope.defineExpandableCommand(name, command);
        }
    }
}
class MakeatCommand implements ExecutableCommand
{
    var atletter: Bool;
    public function new(atletter: Bool)
    {
        this.atletter = atletter;
    }
    public function doCommand(processor: ExecutionProcessor): Array<ExecutionResult>
    {
        processor.expansionProcessor.setAtLetter(this.atletter);
        return [];
    }
}
class VerbCommand implements ExecutableCommand
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
    public function doCommand(processor: ExecutionProcessor): Array<ExecutionResult>
    {
        var exp = processor.expansionProcessor;
        exp.tokenizer.enterVerbatimMode();
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
                exp.tokenizer.leaveVerbatimMode();
                return [VerbCommand(result.toString(), star)];
            } else if (c == '\n') {
                throw new LaTeXError(name + " cannot contain a newline");
            }
            result.add(c);
        }
    }
}
class UnsupportedCommand implements ExecutableCommand
{
    var name: String;
    public function new(name: String)
    {
        this.name = name;
    }
    public function doCommand(processor: ExecutionProcessor): Array<ExecutionResult>
    {
        throw new LaTeXError("command '\\" + this.name + "' is not supported");
    }
}
class UnsupportedTeXPrimitive implements ExecutableCommand
{
    var name: String;
    public function new(name: String)
    {
        this.name = name;
    }
    public function doCommand(processor: ExecutionProcessor): Array<ExecutionResult>
    {
        throw new LaTeXError("TeX primitive '\\" + this.name + "' is not supported");
    }
}
class DefaultScope
{
    public static function defineStandardCommands(scope: Scope)
    {
        scope.defineUnsupportedTeXPrimitive("def");
        scope.defineUnsupportedTeXPrimitive("edef");
        scope.defineUnsupportedTeXPrimitive("xdef");
        scope.defineUnsupportedTeXPrimitive("gdef");
        scope.defineUnsupportedTeXPrimitive("catcode");
        scope.defineExecutableCommand(ControlSequence("newcommand"), new NewcommandCommand());
        scope.defineExecutableCommand(ControlSequence("renewcommand"), new RenewcommandCommand());
        scope.defineExecutableCommand(ControlSequence("providecommand"), new ProvidecommandCommand());
        scope.defineExecutableCommand(ControlSequence("makeatletter"), new MakeatCommand(true));
        scope.defineExecutableCommand(ControlSequence("makeatother"), new MakeatCommand(false));
        scope.defineExecutableCommand(ControlSequence("verb"), new VerbCommand());
    }
    public static function getDefaultScope(): Scope
    {
        var scope = new Scope(null);
        defineStandardCommands(scope);
        return scope;
    }
}
