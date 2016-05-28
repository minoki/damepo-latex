package minilatex;
import minilatex.Token;
import minilatex.ExpansionProcessor;
import minilatex.ExecutionProcessor;

enum Command<E>
{
    ExpandableCommand(c: ExpandableCommand);
    ExecutableCommand(c: ExecutableCommand<E>);
}
interface ExpandableCommand
{
    function expand(processor: IExpansionProcessor): Array<Token>;
}

interface ExecutableCommand<E>
{
    function execute(processor: E): Void;
}

/* contravariant in E: TExecutableCommand<IExecutionProcessor> -> TExecutableCommand<ConcreteExecutionProcessor> */
typedef TExecutableCommand<E> = {
    function execute(processor: E): Void;
}

#if (js || neko || php || python || lua) extern #end
class WrappedExecutableCommand<E> implements ExecutableCommand<E>
{
    var wrapped: TExecutableCommand<E>;
    public function new(x: TExecutableCommand<E>)
    {
        this.wrapped = x;
    }
    public function execute(processor: E): Void
    {
        this.wrapped.execute(processor);
    }
    public static inline function wrap<E>(x: TExecutableCommand<E>): ExecutableCommand<E>
    {
        #if (js || neko || php || python || lua)
            return cast x;
        #else
            return new WrappedExecutableCommand(x);
        #end
    }
}
