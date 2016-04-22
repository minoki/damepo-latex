package minilatex;
import minilatex.Token;
import minilatex.Tokenizer;
import minilatex.ExpansionProcessor;
import minilatex.ExecutionProcessor;
import minilatex.Error;
enum Command<E> /* contravariant in E: Command<IExecutionProcessor> -> Command<ConcreteExecutionProcessor> */
{
    ExpandableCommand(c: ExpandableCommand);
    ExecutableCommand(c: ExecutableCommand<E>);
}
interface ExpandableCommand
{
    function expand(processor: IExpansionProcessor): Array<Token>;
}
interface ExecutableCommand<E> /* contravariant in E: ExecutableCommand<IExecutionProcessor> -> ExecutableCommand<ConcreteExecutionProcessor> */
{
    function execute(processor: E): Void;
}
typedef TExecutableCommand<E> = {
    function execute(processor: E): Void;
}
class WrappedExecutableCommand<E> implements ExecutableCommand<E>
{
    var wrapped: TExecutableCommand<E>;
    public function new(x: TExecutableCommand<E>)
    {
        this.wrapped = x;
    }
    public function execute(processor: E)
    {
        this.wrapped.execute(processor);
    }
    public static inline function wrap<E>(x: TExecutableCommand<E>): ExecutableCommand<E>
    {
        #if js
            return cast x;
        #else
            return new WrappedExecutableCommand(x);
        #end
    }
}
enum Command_Bottom /* Command<Bottom> */
{
    ExpandableCommand(c: ExpandableCommand);
    ExecutableCommand;
}
interface IScope
{
    function getParent(): IScope;
    var isAtLetter(default, null): Bool;
    function isCommandDefined(name: TokenValue): Bool;
    function lookupExpandableCommand(name: TokenValue): Command_Bottom;
    function defineExpandableCommand(name: TokenValue, definition: ExpandableCommand): Void;
    function isEnvironmentDefined(name: String): Bool;
    function defineEnvironment(name: String): Void;
    function setAtLetter(value: Bool): Void;
}
typedef TScope = {
    function getParent(): IScope;
    var isAtLetter(default, null): Bool;
    function isCommandDefined(name: TokenValue): Bool;
    function lookupExpandableCommand(name: TokenValue): Command_Bottom;
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
    public function lookupExpandableCommand(name: TokenValue): Command_Bottom
    {
        return switch (this.lookupCommand(name)) {
        case null: null;
        case ExpandableCommand(command): ExpandableCommand(command);
        case ExecutableCommand(command): ExecutableCommand;
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
