package minilatex;
import haxe.ds.Option;
import minilatex.Processor;
import minilatex.Error;
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
class UserCommand implements Command
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
    public function doCommand(processor: Processor)
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
        while (it.hasNext()) {
            var t = it.next();
            switch (t) {
            case Character('#', _):
                var u = it.next();
                switch (u) {
                case Character('#', _):
                    processor.unreadToken(u);
                case Character(c, _):
                    var index = switch (CommandUtil.digitValue(c)) {
                    case Some(i) if (i > 0): i;
                    default: throw new LaTeXError("user-defined command: invalid parameter character");
                    };
                    if (index > this.numberOfArguments) {
                        throw new LaTeXError("user-defined command: parameter out of range");
                    }
                    processor.unreadTokens(arguments[index-1]);
                case _:
                    throw new LaTeXError("user-defined command: invalid use of parameter character");
                }
            default:
                processor.unreadToken(t);
            }
        }
        return [];
    }
}
class NewcommandCommand implements Command
{
    public function new()
    {
    }
    public function doDefineCommand(processor: Processor, name: Token, numberOfArguments: Int, opt: Null<Array<Token>>, definitionBody: Array<Token>)
    {
        if (processor.currentScope.isCommandDefined(name)) {
            throw new LaTeXError("\\newcommand: command " + (switch (name) {
                    case ControlSequence(x, _): "\\" + x;
                    case Character(x, _): x;
                    }) + " is already defined");
        } else {
            processor.currentScope.defineCommand(name, new UserCommand(numberOfArguments, opt, definitionBody));
        }
    }
    public function doCommand(processor: Processor)
    {
        var cmd = processor.readArgument();
        var name = switch (cmd) {
        case [x]: x;
        case _: throw new LaTeXError("\\newcommand: invalid command name");
        };
        var numberOfArguments = switch (processor.readOptionalArgument([Character('0', 0)])) {
        case [Character(x, _)]: switch (CommandUtil.digitValue(x)) {
            case Some(n): n;
            default: throw new LaTeXError("\\newcommand: invalid number of arguments");
            };
        case _: throw new LaTeXError("\\newcommand: invalid number of arguments");
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
        super();
    }
    public override function doDefineCommand(processor: Processor, name: Token, numberOfArguments: Int, opt: Null<Array<Token>>, definitionBody: Array<Token>)
    {
        if (!processor.currentScope.isCommandDefined(name)) {
            throw new LaTeXError("\\renewcommand: command " + (switch (name) {
                    case ControlSequence(x, _): "\\" + x;
                    case Character(x, _): x;
                    }) + " is not defined");
        } else {
            processor.currentScope.defineCommand(name, new UserCommand(numberOfArguments, opt, definitionBody));
        }
    }
}
class ProvidecommandCommand extends NewcommandCommand
{
    public function new()
    {
        super();
    }
    public override function doDefineCommand(processor: Processor, name: Token, numberOfArguments: Int, opt: Null<Array<Token>>, definitionBody: Array<Token>)
    {
        if (!processor.currentScope.isCommandDefined(name)) {
            processor.currentScope.defineCommand(name, new UserCommand(numberOfArguments, opt, definitionBody));
        }
    }
}
class MakeatCommand implements Command
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
class UnsupportedTeXPrimitive implements Command
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
        scope.defineCommand(ControlSequence("newcommand", 0), new NewcommandCommand());
        scope.defineCommand(ControlSequence("renewcommand", 0), new RenewcommandCommand());
        scope.defineCommand(ControlSequence("providecommand", 0), new ProvidecommandCommand());
        scope.defineCommand(ControlSequence("makeatletter", 0), new MakeatCommand(true));
        scope.defineCommand(ControlSequence("makeatother", 0), new MakeatCommand(false));
        scope.defineCommand(ControlSequence("def", 0), new UnsupportedTeXPrimitive("def"));
        scope.defineCommand(ControlSequence("edef", 0), new UnsupportedTeXPrimitive("edef"));
        scope.defineCommand(ControlSequence("xdef", 0), new UnsupportedTeXPrimitive("xdef"));
        scope.defineCommand(ControlSequence("gdef", 0), new UnsupportedTeXPrimitive("gdef"));
        scope.defineCommand(ControlSequence("catcode", 0), new UnsupportedTeXPrimitive("catcode"));
        return scope;
    }
}
