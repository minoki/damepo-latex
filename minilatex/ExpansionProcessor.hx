package minilatex;
import minilatex.Token;
import minilatex.Scope;
import minilatex.Tokenizer;
import minilatex.Error;
import minilatex.Util;
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
    function nextToken(): Null<ExpansionToken>;
    function unreadNonNullExpansionToken(t: ExpansionToken): Void;
}
class ExpansionProcessorUtil
{
    public static inline function unreadTokens(p: IExpansionProcessor, ts: Array<Token>, depth: Int)
    {
        for (t in ts.reverseIterator()) {
            unreadToken(p, t, depth);
        }
    }
    public static inline function unreadToken(p: IExpansionProcessor, t: Null<Token>, depth: Int)
    {
        if (t != null) {
            p.unreadNonNullExpansionToken(new ExpansionToken(t, depth));
        }
    }
    public static function unreadExpansionToken(p: IExpansionProcessor, t: Null<ExpansionToken>)
    {
        if (t != null) {
            p.unreadNonNullExpansionToken(t);
        }
    }
    public static function nextNonspaceToken(p: IExpansionProcessor): Null<ExpansionToken>
    {
        while (true) {
            var t = p.nextToken();
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
    public static function readArgument(p: IExpansionProcessor): Null<Array<Token>>
    {
        var t = p.nextNonspaceToken();
        if (t == null) {
            return null;
        }
        switch (t.token.value) {
        case Character('{'):
            var a: Array<Token> = [];
            var count = 0;
            while (true) {
                var u = p.nextToken();
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
    public static function readOptionalArgument(p: IExpansionProcessor, defaultValue: Array<Token> = null): Array<Token>
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
                case Character('{'):
                    ++count;
                case Character('}'):
                    if (count > 0) {
                        --count;
                    }
                case Character(']'):
                    if (count == 0) {
                        return a;
                    }
                default:
                }
                a.push(t.token);
            }
        default:
            p.unreadExpansionToken(t);
            return defaultValue;
        }
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
    public function hasPendingToken(): Bool
    {
        return this.pendingTokens.length > 0;
    }
    public function unreadNonNullExpansionToken(t: ExpansionToken)
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
