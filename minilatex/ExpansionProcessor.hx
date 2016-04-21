package minilatex;
import minilatex.Token;
import minilatex.Scope;
import minilatex.Tokenizer;
import minilatex.Error;
import minilatex.Util;
using Token.TokenValueExtender;
using Util.ArrayExtender;
using ExpansionProcessor.ExpansionProcessorUtil;
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
    Space;
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
interface IExpansionProcessor
{
    function getCurrentScope(): Scope;
    function nextToken(): Null<ExpansionToken>;
    function unreadExpansionToken(t: ExpansionToken): Void;
    function expandCompletely(tokens: Array<Token>): Array<Token>;
}
class ExpansionProcessorUtil
{
    public static inline function unreadTokens(p: IExpansionProcessor, ts: Array<Token>, depth: Int)
    {
        for (t in ts.reverseIterator()) {
            p.unreadExpansionToken(new ExpansionToken(t, depth));
        }
    }
    public static function nextNonspaceToken(p: IExpansionProcessor): Null<ExpansionToken>
    {
        while (true) {
            var t = p.nextToken();
            if (t != null) {
                switch (t.token.value) {
                case Space(c):
                    continue;
                default:
                    return t;
                }
            } else {
                return t;
            }
        }
    }
    public static function hasStar(p: IExpansionProcessor): Bool
    {
        var t = p.nextToken();
        return t != null && switch (t.token.value) {
        case Character('*'): true;
        default:
            p.unreadExpansionToken(t);
            false;
        };
    }
    public static function readArgument(p: IExpansionProcessor, name: TokenValue, isLong: Bool): Null<Array<Token>>
    {
        var t = p.nextNonspaceToken();
        if (t == null) {
            return null;
        }
        switch (t.token.value) {
        case BeginGroup(_):
            var a: Array<Token> = [];
            var count = 0;
            while (true) {
                var u = p.nextToken();
                if (u == null) {
                    throw new LaTeXError("mismatched braces");
                }
                switch (u.token.value) {
                case BeginGroup(_):
                    ++count;
                case EndGroup(_):
                    if (count == 0) {
                        return a;
                    } else {
                        --count;
                    }
                case ControlSequence("par") if (!isLong):
                    throw new LaTeXError("Paragraph ended before " + name.toString() + " was compelete");
                default:
                }
                a.push(u.token);
            }
        case ControlSequence("par") if (!isLong):
            throw new LaTeXError("Paragraph ended before " + name.toString() + " was compelete");
        case _:
            return [t.token];
        }
    }
    public static function readOptionalArgument(p: IExpansionProcessor, name: TokenValue, isLong: Bool, defaultValue: Array<Token> = null): Array<Token>
    {
        var t = p.nextNonspaceToken();
        if (t == null) {
            return defaultValue;
        }
        switch (t.token.value) {
        case Character('['):
            var a: Array<Token> = [];
            var count = 0;
            while (true) {
                var t = p.nextToken();
                if (t == null) {
                    throw new LaTeXError("mismatched brackets");
                }
                switch (t.token.value) {
                case BeginGroup(_):
                    ++count;
                case EndGroup(_):
                    if (count > 0) {
                        --count;
                    }
                case Character(']'):
                    if (count == 0) {
                        return a;
                    }
                case ControlSequence("par") if (!isLong):
                    throw new LaTeXError("Paragraph ended before " + name.toString() + " was compelete");
                default:
                }
                a.push(t.token);
            }
        case ControlSequence("par") if (!isLong):
            throw new LaTeXError("Paragraph ended before " + name.toString() + " was compelete");
        default:
            p.unreadExpansionToken(t);
            return defaultValue;
        }
    }
    public static function expandArgument(p: IExpansionProcessor, name: TokenValue, isLong: Bool): Null<Array<Token>>
    {
        var a = p.readArgument(name, isLong);
        return if (a != null) {
            p.expandCompletely(a);
        } else {
            null;
        };
    }
    public static function expandOptionalArgument(p: IExpansionProcessor, name: TokenValue, isLong: Bool, defaultValue: Array<Token> = null): Null<Array<Token>>
    {
        var a = p.readOptionalArgument(name, isLong, defaultValue);
        return if (a != null) {
            p.expandCompletely(a);
        } else {
            null;
        };
    }
}
class LocalExpansionProcessor implements IExpansionProcessor
{
    var tokens: Array<ExpansionToken>;
    var scope: Scope;
    var recursionLimit: Int;
    var pendingTokenLimit: Int;
    public function new(tokens: Array<Token>, scope: Scope, recursionLimit: Int = 1000, pendingTokenLimit: Int = 1000)
    {
        this.tokens = tokens.map(function(t) { return new ExpansionToken(t, 0); });
        this.scope = scope;
        this.recursionLimit = recursionLimit;
        this.pendingTokenLimit = pendingTokenLimit + tokens.length;
    }
    public function getCurrentScope()
    {
        return this.scope;
    }
    public function nextToken(): Null<ExpansionToken>
    {
        if (this.tokens.length > 0) {
            return this.tokens.shift();
        } else {
            return null;
        }
    }
    public function unreadExpansionToken(t: ExpansionToken)
    {
        this.tokens.unshift(t);
        if (this.tokens.length > this.pendingTokenLimit) {
            throw new LaTeXError("token list too long");
        }
    }
    public function expand(): Null<Token>
    {
        while (true) {
            var t = this.nextToken();
            if (t == null) {
                return null;
            }
            switch (t.token.value) {
            case Parameter(_):
                throw new LaTeXError("unexpected parameter char '#'");
            case Active(_) | ControlSequence(_):
                switch (this.scope.lookupCommand(t.token.value)) {
                case null:
                    return t.token;
                case ExpandableCommand(command):
                    if (t.depth > this.recursionLimit) {
                        throw new LaTeXError("recursion too deep");
                    }
                    var expanded = command.expand(this);
                    this.unreadTokens(expanded, t.depth + 1);
                    /* continue */
                case ExecutableCommand(command):
                    throw new LaTeXError("you cannot execute a command here");
                }
            default:
                return t.token;
            }
        }
    }
    public function expandAll(): Array<Token>
    {
        var t: Token;
        var result: Array<Token> = [];
        while ((t = this.expand()) != null) {
            result.push(t);
        }
        return result;
    }
    public function expandCompletely(tokens: Array<Token>): Array<Token>
    {
        var localProcessor = new LocalExpansionProcessor(tokens, this.scope, this.recursionLimit, this.pendingTokenLimit);
        return localProcessor.expandAll();
    }
}
class ExpansionProcessor implements IExpansionProcessor
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
    public function getCurrentScope()
    {
        return this.currentScope;
    }
    public function hasPendingToken(): Bool
    {
        return this.pendingTokens.length > 0;
    }
    public function unreadExpansionToken(t: ExpansionToken)
    {
        this.pendingTokens.unshift(t);
        if (this.pendingTokens.length > this.pendingTokenLimit) {
            throw new LaTeXError("token list too long");
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
    public function expand(): Null<ExpansionResult>
    {
        while (true) {
            var t = this.nextToken();
            if (t == null) {
                return null;
            }
            switch (t.token.value) {
            case Parameter(_):
                throw new LaTeXError("unexpected parameter char '#'");
            case MathShift(_):
                var u = this.nextToken();
                var doubleDollar = u != null && switch (u.token.value) {
                case MathShift(_):
                    true;
                default:
                    this.unreadExpansionToken(u);
                    false;
                };
                if (doubleDollar) {
                    throw new LaTeXError("display math with `$$' is not supported");
                }
                return MathShift;
            case AlignmentTab(_):
                return AlignmentTab;
            case Subscript(_):
                return Subscript;
            case Superscript(_):
                return Superscript;
            case BeginGroup(_):
                return BeginGroup;
            case EndGroup(_):
                return EndGroup;
            case Active(_) | ControlSequence(_):
                switch (this.currentScope.lookupCommand(t.token.value)) {
                case null:
                    return UnknownCommand(t.token);
                case ExpandableCommand(command):
                    if (t.depth > this.recursionLimit) {
                        throw new LaTeXError("recursion too deep");
                    }
                    var expanded = command.expand(this);
                    this.unreadTokens(expanded, t.depth + 1);
                    // continue
                case ExecutableCommand(command):
                    return ExecutableCommand(t.token, command);
                }
            case Space(c):
                return Space;
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
    public function expandCompletely(tokens: Array<Token>): Array<Token>
    {
        var localProcessor = new LocalExpansionProcessor(tokens, this.currentScope, this.recursionLimit, this.pendingTokenLimit);
        return localProcessor.expandAll();
    }
}
