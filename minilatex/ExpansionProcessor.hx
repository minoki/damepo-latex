package minilatex;
import minilatex.Token;
import minilatex.Scope;
import minilatex.Tokenizer;
import minilatex.Error;
enum ExpansionResult
{
    Character(c: String);
    UnknownCommand(name: Token);
    ExecutableCommand(name: Token, command: ExecutableCommand);
    BeginGroup;
    EndGroup;
    AlignmentTab;
    Subscript;
    Superscript;
    MathShift;
}
class ExpansionToken
{
    public var token: Token;
    public var depth: Int;
    public function new(token: Token, depth: Int)
    {
        this.token = token;
        this.depth = depth;
    }
}
class ExpansionProcessor
{
    public var tokenizer: Tokenizer;
    public var currentScope: Scope;
    var pendingTokens: Array<ExpansionToken>;
    public var recursionLimit: Int;
    public var pendingTokenLimit: Int;
    public function new(tokenizer: Tokenizer, initialScope: Scope, recursionLimit: Int = 1000, pendingTokenLimit: Int = 1000)
    {
        this.tokenizer = tokenizer;
        this.currentScope = initialScope;
        this.pendingTokens = [];
        this.recursionLimit = recursionLimit;
        this.pendingTokenLimit = pendingTokenLimit;
    }
    public function hasPendingToken(): Bool
    {
        return this.pendingTokens.length > 0;
    }
    private function unreadTokens(ts: Array<Token>, depth: Int)
    {
        var i = ts.length;
        while (i > 0) {
            this.unreadToken(ts[--i], depth);
        }
    }
    private function unreadToken(t: Null<Token>, depth: Int)
    {
        if (t != null) {
            this.pendingTokens.unshift(new ExpansionToken(t, depth));
            if (this.pendingTokens.length > this.pendingTokenLimit) {
                throw new LaTeXError("token list too long");
            }
        }
    }
    private function unreadExpansionToken(t: Null<ExpansionToken>)
    {
        if (t != null) {
            this.pendingTokens.unshift(t);
            if (this.pendingTokens.length > this.pendingTokenLimit) {
                throw new LaTeXError("token list too long");
            }
        }
    }
    public function nextToken(): Null<ExpansionToken>
    {
        if (this.pendingTokens.length > 0) {
            return this.pendingTokens.shift();
        } else {
            var token = this.tokenizer.readToken(this.currentScope);
            if (token != null) {
                return new ExpansionToken(token, 0);
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
                    throw new LaTeXError("mismatched brackets");
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
    public function expand(): Null<ExpansionResult>
    {
        while (true) {
            var t = this.nextToken();
            if (t == null) {
                return null;
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
                return MathShift;
            case Character('&'):
                return AlignmentTab;
            case Character('_'):
                return Subscript;
            case Character('^'):
                return Superscript;
            case Character('{'):
                return BeginGroup;
            case Character('}'):
                return EndGroup;
            case Character('~') | ControlSequence(_):
                switch (this.currentScope.lookupCommand(t.token.value)) {
                case null:
                    return UnknownCommand(t.token);
                case ExpandableCommand(command):
                    if (t.depth > this.recursionLimit) {
                        throw new LaTeXError("recursion too deep");
                    }
                    var expanded = command.doExpand(this);
                    this.unreadTokens(expanded, t.depth + 1);
                    // continue
                case ExecutableCommand(command):
                    return ExecutableCommand(t.token, command);
                }
            case Character(c):
                return Character(c);
            }
        }
    }
    public function setAtLetter(value: Bool)
    {
        this.currentScope.setAtLetter(value);
    }
    public function enterScope()
    {
        this.currentScope = new Scope(this.currentScope);
    }
    public function leaveScope()
    {
        this.currentScope = this.currentScope.parent;
    }
}
