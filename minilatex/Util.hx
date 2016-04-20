package minilatex;
import haxe.ds.Option;
import haxe.macro.Expr;
class ArrayReverseIterator<T>
{
    private var array: Array<T>;
    private var index: Int;
    public inline function new(array: Array<T>)
    {
        this.array = array;
        this.index = array.length;
    }
    public inline function hasNext()
    {
        return this.index > 0;
    }
    public inline function next()
    {
        return this.array[--this.index];
    }
}
class ArrayExtender
{
    public static inline function reverseIterator<T>(array: Array<T>): ArrayReverseIterator<T>
    {
        return new ArrayReverseIterator(array);
    }
}
class NullExtender
{
    public static inline function ifNull<T>(x: Null<T>, f: Void -> T): T
    {
        return x == null ? f() : x;
    }
    public macro static inline function withDefaultValue<T>(x: ExprOf<Null<T>>, d: ExprOf<T>)
    {
        return macro NullExtender.ifNull($x, function() return $d);
    }
    public macro static inline function throwIfNull<T, E>(x: ExprOf<Null<T>>, e: ExprOf<E>)
    {
        return macro NullExtender.ifNull($x, function() { throw $e; });
    }
    public static inline function mapNull<T, U>(x: Null<T>, f: T -> U): Null<U>
    {
        return x == null ? null : f(x);
    }
    public static inline function liftNull<T, U>(f: T -> U, x: Null<T>): Null<U>
    {
        return x == null ? null : f(x);
    }
    public static inline function bindNull<T, U>(x: Null<T>, f: T -> Null<U>): Null<U>
    {
        return x == null ? null : f(x);
    }
    public static inline function toOption<T>(x: Null<T>): Option<T>
    {
        return x == null ? None : Some(x);
    }
}
class OptionExtender
{
    public static inline function ifNone<T>(x: Option<T>, f: Void -> T): T
    {
        return switch (x) {
        case Some(v): v;
        default: f();
        }
    }
    public macro static inline function withDefaultValue<T>(x: ExprOf<Option<T>>, d: ExprOf<T>)
    {
        return macro OptionExtender.ifNone($x, function() return $d);
    }
    public macro static inline function throwIfNull<T, E>(x: ExprOf<Option<T>>, e: ExprOf<E>)
    {
        return macro OptionExtender.ifNone($x, function() { throw $e; });
    }
    public static inline function mapOption<T, U>(x: Option<T>, f: T -> U): Option<U>
    {
        return switch (x) {
        case Some(v): Some(f(v));
        default: None;
        };
    }
    public static inline function liftOption<T, U>(f: T -> U, x: Option<T>): Option<U>
    {
        return switch (x) {
        case Some(v): Some(f(v));
        default: None;
        };
    }
    public static inline function toNull<T>(x: Option<T>): Null<T>
    {
        return switch (x) {
        case Some(v): v;
        default: null;
        }
    }
}
