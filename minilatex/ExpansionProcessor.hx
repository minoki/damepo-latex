package minilatex;
import minilatex.Token;
import minilatex.Command;
import minilatex.Scope;
import minilatex.Global;
import minilatex.Tokenizer;
import minilatex.Error;
import minilatex.Util;
import minilatex.ExecutionProcessor;
import rxpattern.unicode.CodePoint;
using Token.TokenValueExtender;
using Util.ArrayExtender;
using Util.NullExtender;
using ExpansionProcessor.ExpansionProcessorUtil;
enum ExpansionResult<E>
{
    Character(c: String);
    UnknownCommand(name: Token);
    ExecutableCommand(name: Token, command: ExecutableCommand<E>);
    BeginGroup;
    EndGroup;
    AlignmentTab;
    Subscript;
    Superscript;
    MathShift;
    Space;
}
@:final
class ExpansionToken
{
    public var token: Token;
    public var depth: Int;
    public inline function new(token: Token, depth: Int)
    {
        this.token = token;
        this.depth = depth;
    }
}
interface IExpansionProcessor
{
    var recursionLimit(default, null): Int;
    var pendingTokenLimit(default, null): Int;
    function getCurrentScope(): IScope;
    function getGlobalScope(): IScope;
    function getGlobal(): Global;
    function hasPendingToken(): Bool;
    function nextToken(): Null<ExpansionToken>;
    function expandedExpansionToken(?skipSpaces: Bool): Null<ExpansionToken>;
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
                    throw new LaTeXError("Paragraph ended before " + name.toString() + " was complete");
                default:
                }
                a.push(u.token);
            }
        case ControlSequence("par") if (!isLong):
            throw new LaTeXError("Paragraph ended before " + name.toString() + " was complete");
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
            throw new LaTeXError("Paragraph ended before " + name.toString() + " was complete");
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
    public static function expandedToken(p: IExpansionProcessor, skipSpaces = false): Null<Token>
    {
        var t = p.expandedExpansionToken(skipSpaces);
        if (t != null) {
            return t.token;
        } else {
            return null;
        }
    }
    public static function skipOptionalSpace(p: IExpansionProcessor): Void
    {
        var t = p.nextToken();
        if (t == null) {
            return;
        }
        switch (t.token.value) {
        case Space(_):
            /* Do nothing */
        default:
            p.unreadExpansionToken(t);
        }
    }
    public static function readInteger(p: IExpansionProcessor): Int
    {
        var t = p.expandedToken(true);
        var sign = 1;
        while (t != null) {
            switch (t.value) {
            case Character('+'):
                /* do nothing */
            case Character('-'):
                sign = -sign;
            default: break;
            }
            t = p.expandedToken(true);
        }
        if (t == null) {
            throw new LaTeXError("integer expected");
        }
        switch (t.value) {
        case Character('`'):
            // character code
            var u = p.nextToken();
            if (u == null) {
                throw new LaTeXError("improper alphabetic constant");
            }
            var c = switch (u.token.value) {
            case Character(c): c;
            case ControlSequence(name): name;
            case Space(c): c;
            case BeginGroup(c): c;
            case EndGroup(c): c;
            case AlignmentTab(c): c;
            case Subscript(c): c;
            case Superscript(c): c;
            case MathShift(c): c;
            case Active(c): c;
            case Parameter(c): c;
            };
            var it = CodePoint.codePointIterator(c);
            if (!it.hasNext()) {
                throw new LaTeXError("improper alphabetic constant");
            }
            var cp = it.next();
            if (it.hasNext()) {
                throw new LaTeXError("improper alphabetic constant");
            }
            p.skipOptionalSpace();
            return sign * cp;
        case Character('"'): // hexadecimal
            var u = p.expandedExpansionToken();
            var buf = new StringBuf();
            while (u != null) {
                switch (u.token.value) {
                case Character(c) if (~/[0-9a-fA-F]/.match(c)):
                    buf.add(c);
                    u = p.expandedExpansionToken();
                case Space(_):
                    /* optional space: ignore it */
                    break;
                default:
                    p.unreadExpansionToken(u);
                    break;
                }
            }
            var s = buf.toString();
            if (s == "") {
                throw new LaTeXError("missing number");
            }
            return Std.parseInt("0x" + s);
        case Character("'"): // octal
            var u = p.expandedExpansionToken();
            var buf = new StringBuf();
            while (u != null) {
                switch (u.token.value) {
                case Character(c) if (~/[0-7]/.match(c)):
                    buf.add(c);
                    u = p.expandedExpansionToken();
                case Space(_):
                    /* optional space: ignore it */
                    break;
                default:
                    p.unreadExpansionToken(u);
                    break;
                }
            }
            var s = buf.toString();
            if (s == "") {
                throw new LaTeXError("missing number");
            }
            return octalToInt(s);
        case Character(d) if (TokenUtil.digitValue(d) != null):
            // decimal
            var u = p.expandedExpansionToken();
            var buf = new StringBuf();
            buf.add(d);
            while (u != null) {
                switch (u.token.value) {
                case Character(c) if (~/[0-9]/.match(c)):
                    buf.add(c);
                    u = p.expandedExpansionToken();
                case Space(_):
                    /* optional space: ignore it */
                    break;
                default:
                    p.unreadExpansionToken(u);
                    break;
                }
            }
            var s = buf.toString();
            if (s == "") {
                throw new LaTeXError("missing number");
            }
            return Std.parseInt(s);
        case ControlSequence("value"):
            var name = p.expandArgument(ControlSequence("value"), false).bindNull(TokenUtil.tokenListToName);
            if (name == null) {
                throw new LaTeXError("\\value: counter name expected");
            }
            return p.getGlobal().getCounterValue(name);
        case ControlSequence(name) if (name.substr(0, 2) == "c@"):
            // Hack
            var counterName = name.substr(2);
            return p.getGlobal().getCounterValue(counterName);
        default:
            // TODO: internal integers
            throw new LaTeXError("missing number");
        }
    }
    public static function readIntegerFromTokenList(processor: IExpansionProcessor, tokenList: Array<Token>): Int
    {
        var localProcessor = new LocalExpansionProcessor(tokenList, processor);
        var value = readInteger(localProcessor);
        if (localProcessor.hasPendingToken()) {
            throw new LaTeXError("extra token after integer");
        }
        return value;
    }
    public static function readIntegerArgument(processor: IExpansionProcessor, name: TokenValue): Int
    {
        var tokenList = expandArgument(processor, name, false);
        return readIntegerFromTokenList(processor, tokenList);
    }
    private static function octalToInt(s: String)
    {
        var value = 0;
        for (i in 0...s.length) {
            var d = "01234567".indexOf(s.charAt(i));
            value = value * 8 + d;
        }
        return value;
    }
}
class LocalExpansionProcessor implements IExpansionProcessor
{
    var tokens: Array<ExpansionToken>;
    var scope: IScope;
    var globalScope: IScope;
    var global: Global;
    public var recursionLimit: Int;
    public var pendingTokenLimit: Int;
    public function new(tokens: Array<Token>, base: IExpansionProcessor)
    {
        this.tokens = tokens.map(function(t) { return new ExpansionToken(t, 0); });
        this.scope = base.getCurrentScope();
        this.globalScope = base.getGlobalScope();
        this.global = base.getGlobal();
        this.recursionLimit = base.recursionLimit;
        this.pendingTokenLimit = base.pendingTokenLimit + tokens.length;
    }
    public function getCurrentScope()
    {
        return this.scope;
    }
    public function getGlobalScope()
    {
        return this.globalScope;
    }
    public function getGlobal()
    {
        return this.global;
    }
    public function hasPendingToken()
    {
        return this.tokens.length > 0;
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
    public function expandedExpansionToken(?skipSpaces = false): Null<ExpansionToken>
    {
        while (true) {
            var t = this.nextToken();
            if (t == null) {
                return null;
            }
            switch (t.token.value) {
            case Parameter(_):
                throw new LaTeXError("unexpected parameter char '#'");
            case Space(_) if (skipSpaces):
                /* continue */
            case Active(_) | ControlSequence(_):
                switch (this.scope.lookupExpandableCommand(t.token.value)) {
                case null:
                    return t;
                case command:
                    if (t.depth > this.recursionLimit) {
                        throw new LaTeXError("recursion too deep");
                    }
                    var expanded = command.expand(this);
                    this.unreadTokens(expanded, t.depth + 1);
                    /* continue */
                }
            default:
                return t;
            }
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
                switch (this.scope.lookupExpandableCommand(t.token.value)) {
                case null:
                    return t.token;
                case command:
                    if (t.depth > this.recursionLimit) {
                        throw new LaTeXError("recursion too deep");
                    }
                    var expanded = command.expand(this);
                    this.unreadTokens(expanded, t.depth + 1);
                    /* continue */
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
        var localProcessor = new LocalExpansionProcessor(tokens, this);
        return localProcessor.expandAll();
    }
}
class ExpansionProcessor<E> implements IExpansionProcessor
{
    public var tokenizer: Tokenizer;
    public var currentScope: Scope<E>;
    var globalScope: Scope<E>;
    var global: Global;
    var pendingTokens: Array<ExpansionToken>;
    public var recursionLimit: Int;
    public var pendingTokenLimit: Int;
    public function new(tokenizer: Tokenizer, globalScope: Scope<E>, global: Global, recursionLimit: Int = 1000, pendingTokenLimit: Int = 1000)
    {
        this.tokenizer = tokenizer;
        this.currentScope = globalScope;
        this.globalScope = globalScope;
        this.global = global;
        this.pendingTokens = [];
        this.recursionLimit = recursionLimit;
        this.pendingTokenLimit = pendingTokenLimit;
    }
    public function getCurrentScope()
    {
        return this.currentScope;
    }
    public function getGlobalScope()
    {
        return this.globalScope;
    }
    public function getGlobal()
    {
        return this.global;
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
    public function expandedExpansionToken(?skipSpaces = false): Null<ExpansionToken>
    {
        while (true) {
            var t = this.nextToken();
            if (t == null) {
                return null;
            }
            switch (t.token.value) {
            case Parameter(_):
                throw new LaTeXError("unexpected parameter char '#'");
            case Space(_) if (skipSpaces):
                /* continue */
            case Active(_) | ControlSequence(_):
                switch (this.currentScope.lookupExpandableCommand(t.token.value)) {
                case null:
                    return t;
                case command:
                    if (t.depth > this.recursionLimit) {
                        throw new LaTeXError("recursion too deep");
                    }
                    var expanded = command.expand(this);
                    this.unreadTokens(expanded, t.depth + 1);
                    /* continue */
                }
            default:
                return t;
            }
        }
    }
    public function expand(skipSpaces = false): Null<ExpansionResult<E>>
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
                if (!skipSpaces) {
                    return Space;
                } else {
                    /* continue */
                }
            case Character(c):
                return Character(c);
            }
        }
    }
    public function enterScope()
    {
        this.currentScope = new Scope(this.currentScope);
    }
    public function leaveScope()
    {
        this.currentScope = this.currentScope.getParent();
    }
    public function expandCompletely(tokens: Array<Token>): Array<Token>
    {
        var localProcessor = new LocalExpansionProcessor(tokens, this);
        return localProcessor.expandAll();
    }
}
