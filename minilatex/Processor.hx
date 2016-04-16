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
    var commands: Map<TokenValue, Command>;
    var environments: Map<String, Environment>;
    var isatletter: Bool;
    public function new(parent)
    {
        this.parent = parent;
        this.commands = new Map();
        this.environments = new Map();
        this.isatletter = parent != null && parent.isatletter;
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
    public function isAtLetter(): Bool
    {
        return this.isatletter;
    }
    public function setAtLetter(value: Bool)
    {
        this.isatletter = value;
    }
}
typedef ExpansionToken = {
    var token: Token;
    var depth: Int;
}
class Processor
{
    var tokenizer: Tokenizer;
    public var currentScope: Scope;
    var pendingTokens: Array<ExpansionToken>;
    public function new(tokenizer: Tokenizer, defaultScope: Scope = null)
    {
        this.tokenizer = tokenizer;
        this.currentScope = new Scope(defaultScope);
        this.pendingTokens = [];
    }
    public function hasPendingToken(): Bool
    {
        return this.pendingTokens.length > 0;
    }
    public function unreadTokens(ts: Array<Token>, depth: Int)
    {
        for (t in ts) {
            this.unreadToken(t, depth);
        }
    }
    public function unreadToken(t: Null<Token>, depth: Int)
    {
        if (t != null) {
            this.pendingTokens.push({token: t, depth: depth});
        }
    }
    public function unreadExpansionTokens(ts: Array<ExpansionToken>)
    {
        for (t in ts) {
            this.unreadExpansionToken(t);
        }
    }
    public function unreadExpansionToken(t: Null<ExpansionToken>)
    {
        if (t != null) {
            this.pendingTokens.push(t);
        }
    }
    private function nextToken(): Null<ExpansionToken>
    {
        if (this.pendingTokens.length > 0) {
            return this.pendingTokens.shift();
        } else {
            var token = this.tokenizer.readToken();
            if (token != null) {
                return {token: token, depth: 0};
            } else {
                return null;
            }
        }
    }
    private function nextNonspaceToken(): Null<ExpansionToken>
    {
        while (true) {
            var t = this.nextToken();
            if (t != null) {
                switch (t.token.value) {
                case Character(c):
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
    public function readArgument(): Null<Array<Token>>
    {
        var t = this.nextNonspaceToken();
        if (t == null) {
            return null;
        }
        switch (t.token.value) {
        case Character('{'):
            var a: Array<Token> = [];
            var count = 0;
            while (true) {
                var u = this.nextToken();
                if (u == null) {
                    throw new LaTeXError("mismatched braces");
                }
                switch (u.token.value) {
                case Character('{'):
                    ++count;
                case Character('}'):
                    if (count == 0) {
                        return a;
                    } else {
                        --count;
                    }
                default:
                }
                a.push(u.token);
            }
        case _:
            return [t.token];
        }
    }
    public function readOptionalArgument(defaultValue: Array<Token> = null): Array<Token>
    {
        var t = this.nextNonspaceToken();
        if (t == null) {
            return defaultValue;
        }
        switch (t.token.value) {
        case Character('['):
            var a: Array<ExpansionToken> = [];
            var count = 0;
            while (true) {
                var t = this.nextToken();
                if (t == null) {
                    this.unreadExpansionTokens(a);
                    return defaultValue;
                }
                switch (t.token.value) {
                case Character('{'):
                    ++count;
                case Character('}'):
                    if (count > 0) {
                        --count;
                    }
                case Character(']'):
                    if (count == 0) {
                        return a.map(function(u) { return u.token; });
                    }
                default:
                }
                a.push(t);
            }
        default:
            this.unreadExpansionToken(t);
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
            switch (t.token.value) {
            case Character('#'):
                throw new LaTeXError("unexpected parameter char '#'");
            case Character('$'):
                var u = this.nextToken();
                var doubleDollar = u != null && switch (u.token.value) {
                case Character('$'):
                    true;
                default:
                    this.unreadExpansionToken(u);
                    false;
                };
                if (doubleDollar) {
                    throw new LaTeXError("display math with `$$' is not supported");
                }
                result[0].push(MathShift);
            case Character('&'):
                result[0].push(AlignmentTab);
            case Character('_'):
                result[0].push(Subscript);
            case Character('^'):
                result[0].push(Superscript);
            case Character('{'):
                this.currentScope = new Scope(this.currentScope);
                result.unshift([]);
            case Character('}'):
                if (result.length <= 1) {
                    throw new LaTeXError("extra '}'");
                }
                var content = result.shift();
                result[0].push(Group(content));
                this.currentScope = this.currentScope.parent;
                this.tokenizer.setAtLetter(this.currentScope.isAtLetter());
            case Character('~'): // active char
                switch (this.currentScope.lookupCommand(t.token.value)) {
                case null:
                    result[0].push(UnexpandableCommand("~"));
                    continue;
                    //throw new LaTeXError("command not found: ~");
                case ExpandableCommand(command):
                    if (t.depth > recursionLimit) {
                        throw new LaTeXError("recursion too deep");
                    }
                    var expanded = command.doExpand(this);
                    for (e in expanded) {
                        this.unreadToken(e, t.depth + 1);
                    }
                case ExecutableCommand(command):
                    result[0] = result[0].concat(command.doCommand(this));
                }
            case ControlSequence(name):
                switch (this.currentScope.lookupCommand(t.token.value)) {
                case null:
                    result[0].push(UnexpandableCommand(name));
                    continue;
                    //throw new LaTeXError("command not found: " + name);
                case ExpandableCommand(command):
                    if (t.depth > recursionLimit) {
                        throw new LaTeXError("recursion too deep");
                    }
                    var expanded = command.doExpand(this);
                    for (e in expanded) {
                        this.unreadToken(e, t.depth + 1);
                    }
                case ExecutableCommand(command):
                    result[0] = result[0].concat(command.doCommand(this));
                }
            case Character(c):
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
