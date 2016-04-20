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
