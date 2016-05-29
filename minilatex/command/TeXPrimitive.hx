package minilatex.command;
import minilatex.Token;
import minilatex.Command;
import minilatex.ExpansionProcessor;
import minilatex.ExecutionProcessor;
import minilatex.Scope;
import minilatex.Error;
using Token.TokenValueExtender;
using TeXPrimitive.TeXPrimitive;
using ExpansionProcessor.ExpansionProcessorUtil;
class RelaxCommand implements ExecutableCommand<IExecutionProcessor>
{
    public function new()
    {
    }
    public function execute(processor: IExecutionProcessor)
    {
    }
}
class ExpandafterCommand implements ExpandableCommand
{
    public function new()
    {
    }
    public function expand(processor: IExpansionProcessor): Array<Token>
    {
        var token1 = processor.nextToken();
        var token2 = processor.nextToken();
        if (token1 == null || token2 == null) {
            throw new LaTeXError("\\expandafter: token missing");
        }
        switch (token2.token.value) {
        case Active(_) | ControlSequence(_):
            var command = processor.getCurrentScope().lookupExpandableCommand(token2.token.value);
            if (command != null) {
                if (token2.depth > processor.recursionLimit) {
                    throw new LaTeXError("recursion too deep");
                }
                var expanded = command.expand(processor);
                return [token1.token].concat(expanded);
                //processor.unreadTokens([token1.token].concat(expanded), token2.depth + 1);
                //return [];
            }
        default:
        }
        return [token1.token, token2.token];
    }
}
class CsnameCommand implements ExpandableCommand
{
    public function new()
    {
    }
    public function expand(processor: IExpansionProcessor): Array<Token>
    {
        var token = processor.expandedToken();
        var buf = new StringBuf();
        while (token != null) {
            switch (token.value) {
            case Active(_) | ControlSequence(_):
                switch (processor.getCurrentScope().lookupDynamicExecutableCommand(token.value)) {
                case null | ExpandableCommand(_):
                    throw new LaTeXError("\\csname: unexpected control sequence");
                case ExecutableCommand(command):
                    if (Std.is(command, EndcsnameCommand)) {
                        return [new Token(ControlSequence(buf.toString()), token.location)];
                    } else {
                        throw new LaTeXError("\\csname: command not allowed here");
                    }
                }
            case Character(c) | Space(c) | BeginGroup(c) | EndGroup(c) | AlignmentTab(c) | Subscript(c) | Superscript(c) | MathShift(c) | Parameter(c):
                buf.add(c);
            }
            token = processor.expandedToken();
        }
        throw new LaTeXError("\\csname: \\endcsname missing");
    }
}
class EndcsnameCommand implements ExecutableCommand<IExecutionProcessor>
{
    public function new()
    {
    }
    public function execute(processor: IExecutionProcessor)
    {
        throw new LaTeXError("Extra \\endcsname");
    }
}
class StringCommand implements ExpandableCommand
{
    public function new()
    {
    }
    public function expand(processor: IExpansionProcessor): Array<Token>
    {
        var token = processor.nextToken();
        switch (token.token.value) {
        case Character(c):
            return [token.token];
        case Space(c) | BeginGroup(c) | EndGroup(c) | AlignmentTab(c) | Subscript(c) | Superscript(c) | MathShift(c) | Active(c) | Parameter(c):
            // TODO: Other (category code 12)
            return [new Token(Character(c), null)];
        case ControlSequence(name):
            return TokenUtil.stringToTokenList("\\" + name);
        }
    }
}
class NumberCommand implements ExpandableCommand
{
    public function new()
    {
    }
    public function expand(processor: IExpansionProcessor): Array<Token>
    {
        var value = processor.readInteger();
        return TokenUtil.stringToTokenList("" + value);
    }
}
class RomannumeralCommand implements ExpandableCommand
{
    public function new()
    {
    }
    public function expand(processor: IExpansionProcessor): Array<Token>
    {
        var value = processor.readInteger();
        return TokenUtil.stringToTokenList(toRomanNumeral(value));
    }
    public static function toRomanNumeral(value: Int): String
    {
        if (value <= 0) {
            // not supported
            return "";
        }
        var d1 = value % 10;
        var d2 = Std.int(value / 10) % 10;
        var d3 = Std.int(value / 100) % 10;
        var d4 = Std.int(value / 1000);
        var buf = new StringBuf();
        for (i in 0...d4) {
            buf.add("m");
        }
        buf.add(["", "c", "cc", "ccc", "cd", "d", "dc", "dcc", "dccc", "cm"][d3]);
        buf.add(["", "x", "xx", "xxx", "xl", "l", "lx", "lxx", "lxxx", "xc"][d2]);
        buf.add(["", "i", "ii", "iii", "iv", "v", "vi", "vii", "viii", "ix"][d1]);
        return buf.toString();
    }
}
class UnsupportedTeXPrimitive implements ExecutableCommand<IExecutionProcessor>
{
    var name: TokenValue;
    public function new(name)
    {
        this.name = name;
    }
    public function execute(processor: IExecutionProcessor)
    {
        throw new LaTeXError("TeX primitive '" + this.name.toString() + "' is not supported");
    }
}
class TeXPrimitive
{
    public static function defineUnsupportedTeXPrimitive(scope: TDefiningScope<IExecutionProcessor>, name: String)
    {
        var cs = ControlSequence(name);
        scope.defineExecutableCommandT(cs, new UnsupportedTeXPrimitive(cs));
    }
    public static function defineTeXPrimitives(scope: TDefiningScope<IExecutionProcessor>)
    {
        scope.defineUnsupportedTeXPrimitive("def");
        scope.defineUnsupportedTeXPrimitive("edef");
        scope.defineUnsupportedTeXPrimitive("xdef");
        scope.defineUnsupportedTeXPrimitive("gdef");
        scope.defineUnsupportedTeXPrimitive("catcode");
        scope.defineExecutableCommandT(ControlSequence("relax"), new RelaxCommand());
        scope.defineExpandableCommand(ControlSequence("expandafter"), new ExpandafterCommand());
        scope.defineExpandableCommand(ControlSequence("csname"), new CsnameCommand());
        scope.defineExecutableCommandT(ControlSequence("endcsname"), new EndcsnameCommand());
        scope.defineExpandableCommand(ControlSequence("string"), new StringCommand());
        scope.defineExpandableCommand(ControlSequence("number"), new NumberCommand());
        scope.defineExpandableCommand(ControlSequence("romannumeral"), new RomannumeralCommand());
    }
}
