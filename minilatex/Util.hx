package minilatex;
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
    public static inline function mapNull<T, U>(x: Null<T>, f: T -> U): Null<U>
    {
        return x == null ? null : f(x);
    }
    public static inline function liftNull<T, U>(f: T -> U, x: Null<T>): Null<U>
    {
        return x == null ? null : f(x);
    }
}
