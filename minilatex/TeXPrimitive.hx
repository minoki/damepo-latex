package minilatex;
import minilatex.ExpansionProcessor;
import minilatex.ExecutionProcessor;
import minilatex.Token;
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
class NumberCommand implements ExpandableCommand
{
    public function new()
    {
    }
    public function expand(processor: IExpansionProcessor): Array<Token>
    {
        var value = processor.readInteger();
        var s = "" + value;
        var result = [];
        for (i in 0...s.length) {
            result.push(new Token(Character(s.charAt(i)), null));
        }
        return result;
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
        var s = toRomanNumeral(value);
        var result = [];
        for (i in 0...s.length) {
            result.push(new Token(Character(s.charAt(i)), null));
        }
        return result;
    }
    static function toRomanNumeral(value: Int): String
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
        scope.defineExpandableCommand(ControlSequence("number"), new NumberCommand());
        scope.defineExpandableCommand(ControlSequence("romannumeral"), new RomannumeralCommand());
    }
}
