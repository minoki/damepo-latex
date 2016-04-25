package minilatex.util;
import haxe.macro.Context;
import haxe.macro.Type;
import haxe.macro.Expr;
import haxe.macro.ComplexTypeTools;
import minilatex.util.IntSet;
import minilatex.util.UnicodeUtil;
using minilatex.util.UnicodeUtil;
@:forward(length)
abstract CharSet(IntSet)
{
    @:extern
    public inline function new(s)
    {
        this = s;
    }
    @:extern
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
    @:extern
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
    @:extern
    public inline function getCodePointSet()
    {
        return this;
    }
    @:extern
    public inline function hasCodePoint(x: Int)
    {
        return this.has(x);
    }
    public inline function has(c: String)
    {
        if (!UnicodeUtil.rxSingleCodepoint.match(c)) {
            throw "CharSet.has: invalid charater";
        }
        return this.has(UnicodeUtil.codePointAt(c, 0));
    }
    @:extern
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
    @:extern
    public inline function removeCodePoint(x: Int)
    {
        this.remove(x);
    }
    #if !cs @:extern inline #end
    public function codePointIterator()
    {
        return this.iterator();
    }
}
