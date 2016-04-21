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
    function expand(processor: IExpansionProcessor): Array<Token>;
}
interface ExecutableCommand
{
    function execute(processor: ExecutionProcessor): Array<ExecutionResult>;
}
class Scope
{
    public var parent: Scope;
    var commands: Map<TokenValue, Command>;
    var environments: Array<String>;
    public var isAtLetter: Bool;
    public function new(parent)
    {
        this.parent = parent;
        this.commands = new Map();
        this.environments = [];
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
    public function isEnvironmentDefined(name: String): Bool
    {
        var scope = this;
        while (scope != null) {
            if (scope.environments.indexOf(name) != -1) {
                return true;
            }
            scope = scope.parent;
        }
        return false;
    }
    public function defineEnvironment(name: String)
    {
        this.environments.push(name);
    }
    public function setAtLetter(value: Bool)
    {
        this.isAtLetter = value;
    }
}
