package minilatex;
import haxe.ds.Option;
import minilatex.Processor;
import minilatex.Error;
using Command.ScopeExtender;
class ScopeExtender
{
    public static function defineUnsupportedCommand(scope: Scope, name: String)
    {
        scope.defineExecutableCommand(ControlSequence(name, 0), new UnsupportedCommand(name));
    }
    public static function defineUnsupportedTeXPrimitive(scope: Scope, name: String)
    {
        scope.defineExecutableCommand(ControlSequence(name, 0), new UnsupportedTeXPrimitive(name));
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
    public function doExpand(processor: Processor)
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
            switch (t) {
            case Character('#', _):
                var u = it.next();
                switch (u) {
                case Character('#', _):
                    result.push(u);
                case Character(c, _):
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
    public function doDefineCommand(processor: Processor, name: Token, numberOfArguments: Int, opt: Null<Array<Token>>, definitionBody: Array<Token>)
    {
        if (processor.currentScope.isCommandDefined(name)) {
            throw new LaTeXError("\\newcommand: command " + (switch (name) {
                    case ControlSequence(x, _): "\\" + x;
                    case Character(x, _): x;
                    }) + " is already defined");
        } else {
            processor.currentScope.defineExpandableCommand(name, new UserCommand(numberOfArguments, opt, definitionBody));
        }
    }
    public function doCommand(processor: Processor)
    {
        var cmd = processor.readArgument();
        var name = switch (cmd) {
        case [x]: x;
        case _: throw new LaTeXError(this.name + ": invalid command name");
        };
        var numberOfArguments = switch (processor.readOptionalArgument([Character('0', 0)])) {
        case [Character(x, _)]: switch (CommandUtil.digitValue(x)) {
            case Some(n): n;
            default: throw new LaTeXError(this.name + ": invalid number of arguments");
            };
        case _: throw new LaTeXError(this.name + ": invalid number of arguments");
        };
        var opt = processor.readOptionalArgument();
        var definitionBody = processor.readArgument();
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
    public override function doDefineCommand(processor: Processor, name: Token, numberOfArguments: Int, opt: Null<Array<Token>>, definitionBody: Array<Token>)
    {
        if (!processor.currentScope.isCommandDefined(name)) {
            throw new LaTeXError("\\renewcommand: command " + (switch (name) {
                    case ControlSequence(x, _): "\\" + x;
                    case Character(x, _): x;
                    }) + " is not defined");
        } else {
            processor.currentScope.defineExpandableCommand(name, new UserCommand(numberOfArguments, opt, definitionBody));
        }
    }
}
class ProvidecommandCommand extends NewcommandCommand
{
    public function new()
    {
        super("\\providecommand");
    }
    public override function doDefineCommand(processor: Processor, name: Token, numberOfArguments: Int, opt: Null<Array<Token>>, definitionBody: Array<Token>)
    {
        if (!processor.currentScope.isCommandDefined(name)) {
            processor.currentScope.defineExpandableCommand(name, new UserCommand(numberOfArguments, opt, definitionBody));
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
    public function doCommand(processor: Processor): Array<ProcessorResult>
    {
        processor.setAtLetter(this.atletter);
        return [];
    }
}
class UnsupportedCommand implements ExecutableCommand
{
    var name: String;
    public function new(name: String)
    {
        this.name = name;
    }
    public function doCommand(processor: Processor): Array<ProcessorResult>
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
    public function doCommand(processor: Processor): Array<ProcessorResult>
    {
        throw new LaTeXError("TeX primitive '\\" + this.name + "' is not supported");
    }
}
class DefaultScope
{
    public static function getDefaultScope(): Scope
    {
        var scope = new Scope(null);
        scope.defineUnsupportedTeXPrimitive("def");
        scope.defineUnsupportedTeXPrimitive("edef");
        scope.defineUnsupportedTeXPrimitive("xdef");
        scope.defineUnsupportedTeXPrimitive("gdef");
        scope.defineUnsupportedTeXPrimitive("catcode");
        scope.defineExecutableCommand(ControlSequence("newcommand", 0), new NewcommandCommand());
        scope.defineExecutableCommand(ControlSequence("renewcommand", 0), new RenewcommandCommand());
        scope.defineExecutableCommand(ControlSequence("providecommand", 0), new ProvidecommandCommand());
        scope.defineExecutableCommand(ControlSequence("makeatletter", 0), new MakeatCommand(true));
        scope.defineExecutableCommand(ControlSequence("makeatother", 0), new MakeatCommand(false));
        return scope;
    }
}
