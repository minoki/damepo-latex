package minilatex;
import haxe.ds.Option;
import minilatex.Token;
import minilatex.ExpansionProcessor;
import minilatex.ExecutionProcessor;
import minilatex.Error;
import minilatex.Scope;
import minilatex.Util;
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
class CommandUtil
{
    public static function digitValue(c: String): Option<Int>
    {
        return switch (c) {
        case '0': Some(0);
        case '1': Some(1);
        case '2': Some(2);
        case '3': Some(3);
        case '4': Some(4);
        case '5': Some(5);
        case '6': Some(6);
        case '7': Some(7);
        case '8': Some(8);
        case '9': Some(9);
        case _: None;
        }
    }
    public static function digitValueN(c: String): Null<Int>
    {
        return switch (c) {
        case '0': 0;
        case '1': 1;
        case '2': 2;
        case '3': 3;
        case '4': 4;
        case '5': 5;
        case '6': 6;
        case '7': 7;
        case '8': 8;
        case '9': 9;
        case _: null;
        }
    }
}
class UserCommand implements ExpandableCommand
{
    var numberOfArguments: Int;
    var defaultValueForOptionalArgument: Null<Array<Token>>;
    var definitionBody: Array<Token>;
    public function new(numberOfArguments, defaultValueForOptionalArgument, definitionBody)
    {
        this.numberOfArguments = numberOfArguments;
        this.defaultValueForOptionalArgument = defaultValueForOptionalArgument;
        this.definitionBody = definitionBody;
    }
    public function doExpand(processor: IExpansionProcessor)
    {
        var remainingArguments = this.numberOfArguments;
        var arguments: Array<Array<Token>> = [];
        if (remainingArguments > 0 && this.defaultValueForOptionalArgument != null) {
            arguments.push(processor.readOptionalArgument(this.defaultValueForOptionalArgument));
            --remainingArguments;
        }
        while (remainingArguments > 0) {
            var arg = processor.readArgument();
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
            case Character('#'):
                var u = it.next();
                if (u == null) {
                    throw new LaTeXError("user-defined command: invalid use of parameter character");
                }
                switch (u.value) {
                case Character('#'):
                    result.push(u);
                case Character(c):
                    var index = switch (CommandUtil.digitValue(c)) {
                    case Some(i) if (i > 0): i;
                    default: throw new LaTeXError("user-defined command: invalid parameter character");
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
    public function doDefineCommand(processor: ExecutionProcessor, name: TokenValue, numberOfArguments: Int, opt: Null<Array<Token>>, definitionBody: Array<Token>)
    {
        if (processor.expansionProcessor.currentScope.isCommandDefined(name)) {
            throw new LaTeXError("\\newcommand: command " + (switch (name) {
                    case ControlSequence(x): "\\" + x;
                    case Character(x): x;
                    }) + " is already defined");
        } else {
            processor.expansionProcessor.currentScope.defineExpandableCommand(name, new UserCommand(numberOfArguments, opt, definitionBody));
        }
    }
    private static inline function tokenListToInt(tokens: Array<Token>, defaultValue: Int): Option<Int>
    {
        if (tokens == null) {
            return Some(defaultValue);
        }
        if (tokens.length != 1) {
            return None;
        }
        return switch (tokens[0].value) {
        case Character(x):
            CommandUtil.digitValue(x);
        case _: None;
        };
    }
    private static inline function tokenListToIntN(tokens: Array<Token>, defaultValue: Int): Null<Int>
    {
        if (tokens == null) {
            return defaultValue;
        }
        if (tokens.length != 1) {
            return null;
        }
        return switch (tokens[0].value) {
        case Character(x):
            CommandUtil.digitValueN(x);
        case _: null;
        };
    }
    public function doCommand(processor: ExecutionProcessor)
    {
        var cmd = processor.expansionProcessor.readArgument();
        var name = switch (cmd) {
        case [x]: x.value;
        case _: throw new LaTeXError(this.name + ": invalid command name");
        };
        var args = processor.expansionProcessor.expandOptionalArgument();
        var numberOfArguments = tokenListToIntN(args, 0)
            .throwIfNull(new LaTeXError(this.name + ": invalid number of arguments"));
        var opt = processor.expansionProcessor.readOptionalArgument();
        var definitionBody = processor.expansionProcessor.readArgument();
        this.doDefineCommand(processor, name, numberOfArguments, opt, definitionBody);
        return [];
    }
}
class RenewcommandCommand extends NewcommandCommand
{
    public function new()
    {
        super("\\renewcommand");
    }
    public override function doDefineCommand(processor: ExecutionProcessor, name: TokenValue, numberOfArguments: Int, opt: Null<Array<Token>>, definitionBody: Array<Token>)
    {
        if (!processor.expansionProcessor.currentScope.isCommandDefined(name)) {
            throw new LaTeXError("\\renewcommand: command " + (switch (name) {
                    case ControlSequence(x): "\\" + x;
                    case Character(x): x;
                    }) + " is not defined");
        } else {
            processor.expansionProcessor.currentScope.defineExpandableCommand(name, new UserCommand(numberOfArguments, opt, definitionBody));
        }
    }
}
class ProvidecommandCommand extends NewcommandCommand
{
    public function new()
    {
        super("\\providecommand");
    }
    public override function doDefineCommand(processor: ExecutionProcessor, name: TokenValue, numberOfArguments: Int, opt: Null<Array<Token>>, definitionBody: Array<Token>)
    {
        if (!processor.expansionProcessor.currentScope.isCommandDefined(name)) {
            processor.expansionProcessor.currentScope.defineExpandableCommand(name, new UserCommand(numberOfArguments, opt, definitionBody));
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
