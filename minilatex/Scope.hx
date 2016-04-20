package minilatex;
import minilatex.Token;
import minilatex.Tokenizer;
import minilatex.ExpansionProcessor;
import minilatex.ExecutionProcessor;
import minilatex.Error;
enum Command
{
    ExpandableCommand(c: ExpandableCommand);
    ExecutableCommand(c: ExecutableCommand);
}
interface ExpandableCommand
{
    public function doExpand(processor: IExpansionProcessor): Array<Token>;
}
interface ExecutableCommand
{
    public function doCommand(processor: ExecutionProcessor): Array<ExecutionResult>;
}
interface Environment
{
}
class Scope
{
    public var parent: Scope;
    var commands: Map<TokenValue, Command>;
    var environments: Map<String, Environment>;
    public var isAtLetter: Bool;
    public function new(parent)
    {
        this.parent = parent;
        this.commands = new Map();
        this.environments = new Map();
        this.isAtLetter = parent != null && parent.isAtLetter;
    }
    public function isCommandDefined(name: TokenValue): Bool
    {
        var scope = this;
        while (scope != null) {
            if (scope.commands.exists(name)) {
                return true;
            }
            scope = scope.parent;
        }
        return false;
    }
    public function lookupCommand(name: TokenValue): Command
    {
        var scope = this;
        while (scope != null) {
            if (scope.commands.exists(name)) {
                return scope.commands.get(name);
            }
            scope = scope.parent;
        }
        return null;
    }
    public function defineCommand(name: TokenValue, definition: Command)
    {
        this.commands.set(name, definition);
    }
    public function defineExpandableCommand(name: TokenValue, definition: ExpandableCommand)
    {
        this.defineCommand(name, ExpandableCommand(definition));
    }
    public function defineExecutableCommand(name: TokenValue, definition: ExecutableCommand)
    {
        this.defineCommand(name, ExecutableCommand(definition));
    }
    public function lookupEnvironment(name: String): Environment
    {
        if (this.environments.exists(name)) {
            return this.environments.get(name);
        } else if (this.parent != null) {
            return this.parent.lookupEnvironment(name);
        } else {
            return null;
        }
    }
    public function setAtLetter(value: Bool)
    {
        this.isAtLetter = value;
    }
}
