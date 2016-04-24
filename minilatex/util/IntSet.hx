package minilatex.util;
#if python
import python.Set;
@:forward(length, iterator, add, remove, has)
abstract IntSet(Set<Int>) from Set<Int>
{
    inline function new(a) this = a;
    inline function toNativeSet(): Set<Int> return this;
    public static inline function empty()
    {
        return new IntSet(new Set());
    }
    public static inline function singleton(x: Int)
    {
        return new IntSet(new Set([x]));
    }
    public static inline function fromRange(from: Int, to: Int)
    {
        return new IntSet(new Set([for (x in from ... to) x]));
    }
    public static inline function fromIterator(it: Iterator<Int>)
    {
        var set = empty();
        for (x in it) {
            set.add(x);
        }
        return set;
    }
    public static function union(x: IntSet, y: IntSet)
    {
        return x.toNativeSet().union(y.toNativeSet());
    }
}
#elseif java
import java.NativeArray;
import java.util.Collection;
import java.util.HashSet;
import java.util.List;
@:forward(length, iterator, add, remove, has)
abstract IntSet(HashSet<Int>) from HashSet<Int>
{
    inline function new(a) this = a;
    inline function toNativeSet(): HashSet<Int> return this;
    public var length(get, never): Int;
    public inline function get_length()
    {
        return this.size();
    }
    public inline function has(x: Int)
    {
        return this.contains;
    }
    public static inline function empty()
    {
        return new IntSet(new HashSet());
    }
    public static inline function singleton(x: Int)
    {
        var set = empty();
        set.add(x);
        return set;
    }
    public static inline function fromRange(from: Int, to: Int)
    {
        return fromIterator(from ... to);
    }
    public static inline function fromIterator(it: Iterator<Int>)
    {
        var set = empty();
        for (x in it) {
            set.add(x);
        }
        return set;
    }
    public static function union(x: IntSet, y: IntSet)
    {
        return x.toNativeSet().clone().addAll(y.toNativeSet());
    }
}
#else
@:forward(length, iterator)
abstract IntSet(Array<Int>)
{
    inline function new(a)
    {
        this = a;
    }
    public static inline function empty()
    {
        return new IntSet([]);
    }
    public static inline function singleton(x: Int)
    {
        return new IntSet([x]);
    }
    public static inline function fromRange(from: Int, to: Int)
    {
        return new IntSet([for (x in from ... to) x]);
    }
    public static inline function fromIterator(it: Iterator<Int>)
    {
        var set = empty();
        for (x in it) {
            set.add(x);
        }
        return set;
    }
    public function has(x: Int)
    {
        var u = this.length;
        var l = 0;
        while (l < u) {
            var i = Std.int((u + l) / 2);
            if (this[i] < x) {
                l = i + 1;
            } else if (this[i] > x) {
                u = i;
            } else {
                return true;
            }
        }
        return false;
    }
    public function add(x: Int)
    {
        var u = this.length;
        var l = 0;
        while (l < u) {
            var i = Std.int((u + l) / 2);
            if (this[i] < x) {
                l = i + 1;
            } else if (this[i] > x) {
                u = i;
            } else {
                /* already contains x */
                return;
            }
        }
        this.insert(l, x);
    }
    public function remove(x: Int)
    {
        var u = this.length;
        var l = 0;
        while (l < u) {
            var i = Std.int((u + l) / 2);
            if (this[i] < x) {
                l = i + 1;
            } else if (this[i] > x) {
                u = i;
            } else {
                this.splice(i, 1);
                return;
            }
        }
    }
    public inline function _getArray(): Array<Int>
    {
        return this;
    }
    public static function union(x: IntSet, y: IntSet)
    {
        var xa = x._getArray();
        var ya = y._getArray();
        var xl = xa.length;
        var yl = ya.length;
        var xi = 0;
        var yi = 0;
        var a = [];
        while (xi < xl && yi < yl) {
            var cx = xa[xi];
            var cy = ya[yi];
            if (cx < cy) {
                a.push(cx);
                ++xi;
            } else if (cy < cx) {
                a.push(cy);
                ++yi;
            } else {
                a.push(cx);
                ++xi;
                ++yi;
            }
        }
        while (xi < xl) {
            a.push(xa[xi++]);
        }
        while (yi < yl) {
            a.push(ya[yi++]);
        }
        return new IntSet(a);
    }
}
#end
