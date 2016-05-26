package minilatex;
import minilatex.Token;
import minilatex.Scope;
import minilatex.ExpansionProcessor;
import minilatex.Error;
interface IExecutionProcessor
{
    function getTokenizer(): Tokenizer;
    function setAtLetter(isLetter: Bool): Void;
    function getExpansionProcessor(): IExpansionProcessor;
    function beginEnvironment(name: String): Void;
    function endEnvironment(name: String): Void;
}
interface ITypesetExecutionProcessor extends IExecutionProcessor
{
    function typesetChar(c: String): Void;
}
interface IVerbTextExecutionProcessor extends IExecutionProcessor
{
    function verbCommand(text: String, star: Bool): Void;
}
class BasicExecutionProcessor<E> implements IExecutionProcessor
{
    public var expansionProcessor: ExpansionProcessor<E>;
    var environmentStack: Array<String>;
    public function new(expansionProcessor: ExpansionProcessor<E>)
    {
        this.expansionProcessor = expansionProcessor;
        this.environmentStack = [];
    }
    public function getTokenizer(): Tokenizer
    {
        return this.expansionProcessor.tokenizer;
    }
    public function setAtLetter(value: Bool)
    {
        this.expansionProcessor.currentScope.setAtLetter(value);
    }
    public function getExpansionProcessor()
    {
        return this.expansionProcessor;
    }
    public function beginEnvironment(name: String)
    {
        this.environmentStack.push(name);
    }
    public function endEnvironment(name: String)
    {
        var lastEnv = this.environmentStack.pop();
        if (lastEnv == null) {
            throw new LaTeXError("No matching \\begin{" + name + "} for \\end{" + name + "}");
        } else if (lastEnv != name) {
            throw new LaTeXError("\\begin{" + lastEnv + "} ended by \\end{" + name + "}");
        }
    }
    public function checkEnvironment()
    {
        if (this.environmentStack.length > 0) {
            var name = this.environmentStack[this.environmentStack.length - 1];
            throw new LaTeXError("\\begin{" + name + "} is not ended");
        }
    }
}
