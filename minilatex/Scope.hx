package minilatex;
import minilatex.Token;
import minilatex.Command;
import minilatex.Tokenizer;
import minilatex.ExpansionProcessor;
import minilatex.ExecutionProcessor;
import minilatex.Error;
interface IScope
{
    function getParent(): IScope;
    var isAtLetter(default, null): Bool;
    function isCommandDefined(name: TokenValue): Bool;
    function lookupExpandableCommand(name: TokenValue): Null<ExpandableCommand>;
    function defineExpandableCommand(name: TokenValue, definition: ExpandableCommand): Void;
    function isEnvironmentDefined(name: String): Bool;
    function defineEnvironment(name: String): Void;
    function setAtLetter(value: Bool): Void;
}
typedef TScope = {
    function getParent(): IScope;
    var isAtLetter(default, null): Bool;
    function isCommandDefined(name: TokenValue): Bool;
    function lookupExpandableCommand(name: TokenValue): Null<ExpandableCommand>;
    function defineExpandableCommand(name: TokenValue, definition: ExpandableCommand): Void;
    function isEnvironmentDefined(name: String): Bool;
    function defineEnvironment(name: String): Void;
    function setAtLetter(value: Bool): Void;
}
/* covariant in E: TDefiningScope<ConcreteExecutionProcessor> -> TDefiningScope<IExecutionProcessor> */
typedef TDefiningScope<E> = {
    > TScope,
    //function defineCommand(name: TokenValue, definition: Command<E>): Void;
    function defineExecutableCommandT(name: TokenValue, definition: TExecutableCommand<E>): Void;
}
class Scope<E> implements IScope /* invariant in E */
{
    var parent: Scope<E>;
    var commands: Map<TokenValue, Command<E>>;
    var environments: Array<String>;
    public var isAtLetter: Bool;
    public function new(parent)
    {
        this.parent = parent;
        this.commands = new Map();
        this.environments = [];
        this.isAtLetter = parent != null && parent.isAtLetter;
    }
    public function getParent()
    {
        return this.parent;
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
    public function lookupCommand(name: TokenValue): Command<E>
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
    public function lookupExpandableCommand(name: TokenValue): Null<ExpandableCommand>
    {
        return switch (this.lookupCommand(name)) {
        case null: null;
        case ExpandableCommand(command): command;
        case ExecutableCommand(command): null;
        };
    }
    public function defineCommand(name: TokenValue, definition: Command<E>)
    {
        this.commands.set(name, definition);
    }
    public function defineExpandableCommand(name: TokenValue, definition: ExpandableCommand)
    {
        this.defineCommand(name, ExpandableCommand(definition));
    }
    public function defineExecutableCommand(name: TokenValue, definition: ExecutableCommand<E>)
    {
        this.defineCommand(name, ExecutableCommand(definition));
    }
    public function defineExecutableCommandT(name: TokenValue, definition: TExecutableCommand<E>)
    {
        this.defineExecutableCommand(name, WrappedExecutableCommand.wrap(definition));
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
