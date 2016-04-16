package minilatex;
import minilatex.Token;
import minilatex.Tokenizer;
import minilatex.Error;
using minilatex.Token.TokenExtender;
enum ProcessorResult
{
    Character(c: String);
    UnexpandableCommand(name: String);
    Group(c: Array<ProcessorResult>);
    AlignmentTab;
    Subscript;
    Superscript;
    MathShift;
}
enum Command
{
    ExpandableCommand(c: ExpandableCommand);
    ExecutableCommand(c: ExecutableCommand);
}
interface ExpandableCommand
{
    public function doExpand(processor: Processor): Array<Token>;
}
interface ExecutableCommand
{
    public function doCommand(processor: Processor): Array<ProcessorResult>;
}
interface Environment
{
}
class Scope
{
    public var parent: Scope;
    var commands: Map<Token, Command>;
    var environments: Map<String, Environment>;
    var isatletter: Bool;
    public function new(parent)
    {
        this.parent = parent;
        this.commands = new Map();
        this.environments = new Map();
        this.isatletter = parent != null && parent.isatletter;
    }
    public function isCommandDefined(name: Token): Bool
    {
        name = name.withDepth(0);
        var scope = this;
        while (scope != null) {
            if (scope.commands.exists(name)) {
                return true;
            }
            scope = scope.parent;
        }
        return false;
    }
    public function lookupCommand(name: Token): Command
    {
        name = name.withDepth(0);
        var scope = this;
        while (scope != null) {
            if (scope.commands.exists(name)) {
                return scope.commands.get(name);
            }
            scope = scope.parent;
        }
        return null;
    }
    public function defineCommand(name: Token, definition: Command)
    {
        this.commands.set(name.withDepth(0), definition);
    }
    public function defineExpandableCommand(name: Token, definition: ExpandableCommand)
    {
        this.defineCommand(name, ExpandableCommand(definition));
    }
    public function defineExecutableCommand(name: Token, definition: ExecutableCommand)
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
    public function isAtLetter(): Bool
    {
        return this.isatletter;
    }
    public function setAtLetter(value: Bool)
    {
        this.isatletter = value;
    }
}
class Processor
{
    var tokenizer: Tokenizer;
    public var currentScope: Scope;
    public function new(tokenizer: Tokenizer, defaultScope: Scope = null)
    {
        this.tokenizer = tokenizer;
        this.currentScope = new Scope(defaultScope);
    }
    public function hasPendingToken(): Bool
    {
        return this.tokenizer.hasPendingToken();
    }
    public function unreadTokens(ts: Array<Token>)
    {
        for (t in ts) {
            this.unreadToken(t);
        }
    }
    public function unreadToken(t: Null<Token>)
    {
        if (t != null) {
            this.tokenizer.unreadToken(t);
        }
    }
    private function nextNonspaceToken(): Null<Token>
    {
        while (true) {
            var t = this.nextToken();
            if (t != null) {
                switch (t) {
                case Character(c, _):
                    if (c != " " && c != "\t" && c != "\n") {
                        return t;
                    }
                    continue;
                default:
                    return t;
                }
            } else {
                return t;
            }
        }
    }
    private function nextToken(): Null<Token>
    {
        return this.tokenizer.readToken();
    }
    public function readArgument(): Null<Array<Token>>
    {
        var t = this.nextNonspaceToken();
        switch (t) {
        case null: return null;
        case Character('{', _):
            var a = new Array<Token>();
            var count = 0;
            while (true) {
                var u = this.nextToken();
                switch (u) {
                case null:
                    throw new LaTeXError("mismatched braces");
                case Character('{', _):
                    ++count;
                case Character('}', _):
                    if (count == 0) {
                        return a;
                    } else {
                        --count;
                    }
                default:
                }
                a.push(u);
            }
        case _:
            return [t];
        }
    }
    public function readOptionalArgument(defaultValue: Array<Token> = null): Array<Token>
    {
        var t = this.nextNonspaceToken();
        switch (t) {
        case Character('[', _):
            var a = new Array<Token>();
            var count = 0;
            while (true) {
                var t = this.nextToken();
                switch (t) {
                case null:
                    for (u in a) {
                        this.unreadToken(u);
                    }
                    return defaultValue;
                case Character('{', _):
                    ++count;
                case Character('}', _):
                    if (count > 0) {
                        --count;
                    }
                case Character(']', _):
                    if (count == 0) {
                        return a;
                    }
                default:
                }
                a.push(t);
            }
        default:
            this.unreadToken(t);
            return defaultValue;
        }
    }
    public function process(recursionLimit: Int = 1000): Array<ProcessorResult>
    {
        var result: Array<Array<ProcessorResult>> = [[]];
        while (true) {
            var t = this.nextToken();
            if (t == null) {
                if (result.length != 1) {
                    throw new LaTeXError("Unexpected end of input");
                } else {
                    return result[0];
                }
            }
            switch (t) {
            case Character('#', _):
                throw new LaTeXError("unexpected parameter char '#'");
            case Character('$', _):
                var u = this.nextToken();
                var doubleDollar = switch (u) {
                case Character('$', _):
                    true;
                default:
                    this.unreadToken(u);
                    false;
                };
                if (doubleDollar) {
                    throw new LaTeXError("display math with `$$' is not supported");
                }
                result[0].push(MathShift);
            case Character('&', _):
                result[0].push(AlignmentTab);
            case Character('_', _):
                result[0].push(Subscript);
            case Character('^', _):
                result[0].push(Superscript);
            case Character('{', _):
                this.currentScope = new Scope(this.currentScope);
                result.unshift([]);
            case Character('}', _):
                if (result.length <= 1) {
                    throw new LaTeXError("extra '}'");
                }
                var content = result.shift();
                result[0].push(Group(content));
                this.currentScope = this.currentScope.parent;
                this.tokenizer.setAtLetter(this.currentScope.isAtLetter());
            case Character('~', depth): // active char
                switch (this.currentScope.lookupCommand(t)) {
                case null:
                    result[0].push(UnexpandableCommand("~"));
                    continue;
                    //throw new LaTeXError("command not found: ~");
                case ExpandableCommand(command):
                    if (depth > recursionLimit) {
                        throw new LaTeXError("recursion too deep");
                    }
                    var expanded = command.doExpand(this);
                    for (e in expanded) {
                        this.unreadToken(e.withDepth(depth + 1));
                    }
                case ExecutableCommand(command):
                    if (depth > recursionLimit) {
                        throw new LaTeXError("recursion too deep");
                    }
                    result[0] = result[0].concat(command.doCommand(this));
                }
            case ControlSequence(name, depth):
                switch (this.currentScope.lookupCommand(t)) {
                case null:
                    result[0].push(UnexpandableCommand(name));
                    continue;
                    //throw new LaTeXError("command not found: " + name);
                case ExpandableCommand(command):
                    if (depth > recursionLimit) {
                        throw new LaTeXError("recursion too deep");
                    }
                    var expanded = command.doExpand(this);
                    for (e in expanded) {
                        this.unreadToken(e.withDepth(depth + 1));
                    }
                case ExecutableCommand(command):
                    if (depth > recursionLimit) {
                        throw new LaTeXError("recursion too deep");
                    }
                    result[0] = result[0].concat(command.doCommand(this));
                }
            case Character(c, _):
                result[0].push(Character(c));
            }
        }
    }
    public function setAtLetter(value: Bool)
    {
        this.currentScope.setAtLetter(value);
        this.tokenizer.setAtLetter(value);
    }
}
