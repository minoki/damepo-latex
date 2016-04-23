package minilatex.util;
import haxe.macro.Context;
import haxe.macro.Type;
import haxe.macro.Expr;
import haxe.macro.ComplexTypeTools;
import minilatex.util.IntSet;
import minilatex.util.UnicodeUtil;
using minilatex.util.UnicodeUtil;
abstract CharSet(IntSet)
{
    public inline function new(s)
    {
        this = s;
    }
    public static inline function empty()
    {
        return new CharSet(IntSet.empty());
    }
    public static inline function singleton(c: String)
    {
        if (!UnicodeUtil.rxSingleCodepoint.match(c)) {
            throw "CharSet.add: invalid character added";
        }
        var x = UnicodeUtil.codePointAt(c, 0);
        return new CharSet(IntSet.singleton(x));
    }
    @:from
    public static inline function fromString(s: String)
    {
        return new CharSet(IntSet.fromIterator(s.codePointIterator()));
    }
    macro public static function fromStringLiteral(s: String)
    {
        var pos = Context.currentPos();
        try {
            var is = IntSet.fromIterator(s.codePointIterator()).iterator();
            var elements = [];
            for (x in is) {
                elements.push({pos: pos, expr: ExprDef.EConst(Constant.CInt("" + x))});
            }
            var array = {pos: pos, expr: ExprDef.EArrayDecl(elements)};
            return macro new minilatex.util.CharSet(new minilatex.util.IntSet($array));
        } catch (e: String) {
            Context.error(e, pos);
            return null;
        }
    }
    public inline function getCodePointSet()
    {
        return this;
    }
    public inline function containsCodePoint(x: Int)
    {
        return this.contains(x);
    }
    public inline function contains(c: String)
    {
        if (!UnicodeUtil.rxSingleCodepoint.match(c)) {
            throw "CharSet.contains: invalid charater";
        }
        return this.contains(UnicodeUtil.codePointAt(c, 0));
    }
    public inline function addCodePoint(x: Int)
    {
        this.add(x);
    }
    public function add(c: String)
    {
        if (!UnicodeUtil.rxSingleCodepoint.match(c)) {
            throw "CharSet.add: invalid character added";
        }
        this.add(UnicodeUtil.codePointAt(c, 0));
    }
    public inline function removeCodePoint(x: Int)
    {
        this.remove(x);
    }
    public inline function size()
    {
        return this.size();
    }
    public inline function codePointIterator(): Iterator<Int>
    {
        return this.iterator();
    }
}
