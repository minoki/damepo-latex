package minilatex;
import minilatex.ExecutionProcessor;
import minilatex.Token;
import minilatex.Scope;
import minilatex.Error;
using Token.TokenValueExtender;
using TeXPrimitive.TeXPrimitive;
class RelaxCommand implements ExecutableCommand
{
    public function new()
    {
    }
    public function execute(processor: ExecutionProcessor)
    {
        return [];
    }
}
class UnsupportedTeXPrimitive implements ExecutableCommand
{
    var name: TokenValue;
    public function new(name)
    {
        this.name = name;
    }
    public function execute(processor: ExecutionProcessor): Array<ExecutionResult>
    {
        throw new LaTeXError("TeX primitive '" + this.name.toString() + "' is not supported");
    }
}
class TeXPrimitive
{
    public static function defineUnsupportedTeXPrimitive(scope: Scope, name: String)
    {
        var cs = ControlSequence(name);
        scope.defineExecutableCommand(cs, new UnsupportedTeXPrimitive(cs));
    }
    public static function defineTeXPrimitives(scope: Scope)
    {
        scope.defineUnsupportedTeXPrimitive("def");
        scope.defineUnsupportedTeXPrimitive("edef");
        scope.defineUnsupportedTeXPrimitive("xdef");
        scope.defineUnsupportedTeXPrimitive("gdef");
        scope.defineUnsupportedTeXPrimitive("catcode");
        scope.defineExecutableCommand(ControlSequence("relax"), new RelaxCommand());
    }
}
