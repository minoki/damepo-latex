package minilatex;
import minilatex.ExecutionProcessor;
import minilatex.Token;
import minilatex.Scope;
import minilatex.Error;
using Token.TokenValueExtender;
using TeXPrimitive.TeXPrimitive;
class RelaxCommand implements ExecutableCommand<IExecutionProcessor>
{
    public function new()
    {
    }
    public function execute(processor: IExecutionProcessor)
    {
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
    }
}
