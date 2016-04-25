/*
 Utilities to construct regexp pattern strings
*/
package minilatex.util;
import minilatex.util.CharSet;
import minilatex.util.UnicodeUtil;
import haxe.macro.Context;
import haxe.macro.Expr;

// An enum to describe the context of the expression
@:enum
abstract Precedence(Int)
{
    var Disjunction = 0;
    var Alternative = 1;
    var Term = 2;
    var Atom = 3;
    @:op(A > B) static function gt(lhs: Precedence, rhs: Precedence): Bool;
}

/* A class to construct the pattern string with minimum number of parenthesis */
@:unreflective
@:final
@:allow(minilatex.util.RxPattern)
class Subpattern
{
    var pattern(default, null): String;
    var prec(default, null): Precedence;
    inline function new(pattern: String, prec: Precedence)
    {
        this.pattern = pattern;
        this.prec = prec;
    }
    inline function withPrec(prec: Precedence)
    {
        return prec > this.prec
            ? "(?:" + this.pattern + ")"
            : this.pattern;
    }
}

abstract RxPattern(Subpattern)
{
    @:extern
    public inline function new(pattern: String, prec: Precedence)
        this = new Subpattern(pattern, prec);
    @:extern
    public static inline function Disjunction(pattern: String)
        return new Disjunction(pattern);
    @:extern
    public static inline function Alternative(pattern: String)
        return new Alternative(pattern);
    @:extern
    public static inline function Term(pattern: String)
        return new Term(pattern);
    @:extern
    public static inline function Atom(pattern: String)
        return new Atom(pattern);
    public static inline function AnyCodePoint()
    {
        #if (js || cs || target_js)
            return new Disjunction("[\\u0000-\\uD7FF\\uE000-\\uFFFF]|[\\uD800-\\uDBFF][\\uDC00-\\uDFFF]");
        #elseif python
            return new Atom("[\\u0000-\\U0010FFFF]");
        #else
            return new Atom("[\\x{0}-\\x{10FFFF}]");
        #end
    }
    static var rxSpecialChars = ~/^[\^\$\\\.\*\+\?\(\)\[\]\{\}\|\t\n\r]$/;
    static function escapeChar(c: String)
    {
        /*
        if (c == '^' || c == '$' || c == '\\' || c == '.'
            || c == '*' || c == '+' || c == '?'
            || c == '(' || c == ')' || c == '[' || c == ']'
            || c == '{' || c == '}' || c == '|') {
            return "\\" + c;
        } else if (c == '\t') {
            return "\\t";
        } else if (c == '\n') {
            return "\\n";
        } else if (c == '\r') {
            return "\\r";
        } else {
            return c;
        }
        */
        if (rxSpecialChars.match(c)) {
            return "\\" + c;
        } else  {
            switch (c) {
            case '\t': return "\\t";
            case '\n': return "\\n";
            case '\r': return "\\r";
            case c: return c;
            }
        }
        /*
        switch (c) {
        case '^' | '$' | '\\' | '.' | '*' | '+' | '?'
            | '(' | ')' | '[' | ']' | '{' | '}' | '|':
            return "\\" + c;
        case '\t': return "\\t";
        case '\n': return "\\n";
        case '\r': return "\\r";
        case c: return c;
        }
        */
    }
    @:extern
    public static inline function Char(c: String)
        return Atom(escapeChar(c));
    macro public static function CharLit(c: String)
    {
        var pos = Context.currentPos();
        try {
            var r = ~/^.$/us;
            if (r.match(c)) {
                var s = escapeChar(c);
                var e = {pos: pos, expr: ExprDef.EConst(Constant.CString(s))};
                return macro new minilatex.util.RxPattern.Atom($e);
            } else {
                Context.error("minilatex.util.RxPattern.CharLit: not single character", pos);
                return null;
            }
        } catch (e: String) {
            Context.error(e, pos);
            return null;
        }
    }

    public static inline function String(s: String)
        return Alternative(~/[\^\$\\\.\*\+\?\(\)\[\]\{\}\|\t\n\r]/g.map(s, function(e) return escapeChar(e.matched(0))));
    macro public static function StringLit(s: String)
    {
        var pos = Context.currentPos();
        try {
            var s = ~/[\^\$\\\.\*\+\?\(\)\[\]\{\}\|\t\n\r]/g.map(s, function(e) return escapeChar(e.matched(0)));
            var e = {pos: pos, expr: ExprDef.EConst(Constant.CString(s))};
            return macro new minilatex.util.RxPattern.Alternative($e);
        } catch (e: String) {
            Context.error(e, pos);
            return null;
        }
    }

    /*
    public static var AnyExceptNewLine = Atom(".");
    public static var NewLine = Atom("\\n");
    public static var Empty = Alternative("");
    public static var AssertFirst = Term("^");
    public static var AssertEnd = Term("$");
    */
    @:extern
    public static inline function AnyExceptNewLine()
        return Atom(".");
    @:extern
    public static inline function NewLine()
        return Atom("\\n");
    @:extern
    public static inline function Empty()
        return Alternative("");
    @:extern
    public static inline function AssertFirst()
        return Term("^");
    @:extern
    public static inline function AssertEnd()
        return Term("$");
    #if js
    @:extern
    public static inline function AssertStartOfSubject()
        return Term("^");
    @:extern
    public static inline function AssertEndOfSubject()
        return Term("$");
    #elseif python
    @:extern
    public static inline function AssertStartOfSubject()
        return Term("\\A");
    @:extern
    public static inline function AssertEndOfSubject()
        return Term("\\Z");
    #else // (neko || cpp || php || java || cs)
    @:extern
    public static inline function AssertStartOfSubject()
        return Term("\\A");
    @:extern
    public static inline function AssertEndOfSubject()
        return Term("\\z");
    #end

    public static function CharSet(set: CharSet, invert = false): RxPattern
    {
        var it = set.codePointIterator();
        if (it.hasNext()) {
            var hasRange = false;
            var cs: Array<String> = [];
            var x = it.next();
            var more: Bool;
            do {
                var start: Int = x;
                var end: Int = x;
                more = false;
                while (it.hasNext()) {
                    x = it.next();
                    if (end == x - 1) {
                        end = x;
                    } else {
                        more = true;
                        break;
                    }
                }
                var s = escapeChar(UnicodeUtil.fromCodePoint(start));
                if (start == end) {
                    cs.push(s);
                } else {
                    var t = escapeChar(UnicodeUtil.fromCodePoint(end));
                    cs.push(s + "-" + t);
                    hasRange = true;
                }
            } while (more);
            var r = cs.join("");
            if (invert) {
                return Atom("[^" + r + "]");
            } else if (hasRange || cs.length > 1) {
                return Atom("[" + r + "]");
            } else {
                return Atom(r);
            }
        }
        if (invert) {
            return AnyCodePoint();
        } else {
            return Atom("[]");
        }
    }
    @:extern
    public static inline function NotInSet(set: CharSet)
        return CharSet(set, true);
    macro public static function CharSetLit(s: String)
    {
        var pos = Context.currentPos();
        try {
            var rxp: RxPattern = CharSet(minilatex.util.CharSet.fromString(s), false);
            var e = {pos: pos, expr: ExprDef.EConst(Constant.CString(rxp.get()))};
            switch(rxp.getPrec()) {
            case Precedence.Disjunction:
                return macro new minilatex.util.RxPattern.Disjunction($e);
            case Precedence.Alternative:
                return macro new minilatex.util.RxPattern.Alternative($e);
            case Precedence.Term:
                return macro new minilatex.util.RxPattern.Term($e);
            case Precedence.Atom:
                return macro new minilatex.util.RxPattern.Atom($e);
            }
        } catch (e: String) {
            Context.error(e, pos);
            return null;
        }
    }
    macro public static function NotInSetLit(s: String)
    {
        var pos = Context.currentPos();
        try {
            var rxp: RxPattern = CharSet(minilatex.util.CharSet.fromString(s), true);
            var e = {pos: pos, expr: ExprDef.EConst(Constant.CString(rxp.get()))};
            switch(rxp.getPrec()) {
            case Precedence.Disjunction:
                return macro new minilatex.util.RxPattern.Disjunction($e);
            case Precedence.Alternative:
                return macro new minilatex.util.RxPattern.Alternative($e);
            case Precedence.Term:
                return macro new minilatex.util.RxPattern.Term($e);
            case Precedence.Atom:
                return macro new minilatex.util.RxPattern.Atom($e);
            }
        } catch (e: String) {
            Context.error(e, pos);
            return null;
        }
    }

    @:extern
    public static inline function Group(p: Disjunction): Atom
        return Atom("(" + p.toDisjunction() + ")");

    // Operations on RxPatterns
    @:extern
    @:op(A + B)
    public inline function followedBy(rhs: Alternative)
    {
        return new Alternative(toAlternative() + rhs.toAlternative());
    }
    @:extern
    @:op(A | B)
    public inline function choice(rhs: Disjunction)
    {
        return new Disjunction(toDisjunction() + "|" + rhs.toDisjunction());
    }
    // Accessors
    @:extern
    public inline function get()
        return this.pattern;
    @:extern
    private inline function getPrec()
        return this.prec;
    @:extern
    public inline function build(options = "u")
        return new EReg(this.pattern, options);
    @:extern
    public static inline function buildPatternString(x: Disjunction)
        return x.get();
    @:extern
    public static inline function buildEReg(x, options = "u")
        return new EReg(buildPatternString(x), options);

    @:extern
    public inline function toDisjunction()
        return this.pattern;
    @:extern
    public inline function toAlternative()
        return this.withPrec(Precedence.Alternative);
    @:extern
    public inline function toTerm()
        return this.withPrec(Precedence.Term);
    @:extern
    public inline function toAtom()
        return this.withPrec(Precedence.Atom);

    // Quantifiers
    @:extern
    public inline function option()
        return Term(toAtom() + "?");
    @:extern
    public inline function any()
        return Term(toAtom() + "*");
    @:extern
    public inline function some()
        return Term(toAtom() + "+");

    // Implicit casts
    @:extern
    @:to public inline function asDisjunction() return new Disjunction(toDisjunction());
    @:extern
    @:to public inline function asAlternative() return new Alternative(toAlternative());
    @:extern
    @:to public inline function asTerm() return new Term(toTerm());
    @:extern
    @:to public inline function asAtom() return new Atom(toAtom());
}

@:notNull
abstract Disjunction(String)
{
    @:extern
    public inline function new(pattern: String) this = pattern;

    // Accessors
    @:extern
    public inline function get() return this;
    @:extern
    public inline function build(options = "u") return new EReg(this, options);
    @:extern
    public inline function toDisjunction() return this;
    @:extern
    public inline function toAlternative() return "(?:" + this + ")";
    @:extern
    public inline function toTerm() return "(?:" + this + ")";
    @:extern
    public inline function toAtom() return "(?:" + this + ")";

    // Implicit casts
    @:extern
    @:to public inline function asAlternative() return new Alternative(toAlternative());
    @:extern
    @:to public inline function asTerm() return new Term(toTerm());
    @:extern
    @:to public inline function asAtom() return new Atom(toAtom());
    @:extern
    @:to public inline function asPattern() return new RxPattern(this, Precedence.Disjunction);

    // Quantifiers
    @:extern
    public inline function option() return new Term(toAtom() + "?");
    @:extern
    public inline function any() return new Term(toAtom() + "*");
    @:extern
    public inline function some() return new Term(toAtom() + "+");

    // Binary operators
    @:extern
    @:op(A + B)
    public inline function followedBy(rhs: Alternative)
        return new Alternative(toAlternative() + rhs.toAlternative());
    @:extern
    @:op(A | B)
    public inline function choice(rhs: Disjunction)
        return new Disjunction(toDisjunction() + "|" + rhs.toDisjunction());
}
@:forward(get, build, option, any, some)
abstract Alternative(Disjunction)
{
    @:extern
    public inline function new(pattern: String) this = new Disjunction(pattern);

    // Accessors
    @:extern
    public inline function toDisjunction() return this.get();
    @:extern
    public inline function toAlternative() return this.get();
    @:extern
    public inline function toTerm() return "(?:" + this.get() + ")";
    @:extern
    public inline function toAtom() return "(?:" + this.get() + ")";

    // Implicit casts
    @:extern
    @:to public inline function asDisjunction() return this;
    @:extern
    @:to public inline function asTerm() return new Term(toTerm());
    @:extern
    @:to public inline function asAtom() return new Atom(toAtom());
    @:extern
    @:to public inline function asPattern() return new RxPattern(this.get(), Precedence.Alternative);

    // Binary operators
    @:extern
    @:op(A + B)
    public inline function followedBy(rhs: Alternative)
        return new Alternative(toAlternative() + rhs.toAlternative());
    @:extern
    @:op(A | B)
    public inline function choice(rhs: Disjunction)
        return new Disjunction(toDisjunction() + "|" + rhs.toDisjunction());
}
@:forward(get, build, option, any, some)
abstract Term(Alternative)
{
    @:extern
    public inline function new(pattern: String) this = new Alternative(pattern);

    // Accessors
    @:extern
    public inline function toDisjunction() return this.get();
    @:extern
    public inline function toAlternative() return this.get();
    @:extern
    public inline function toTerm() return this.get();
    @:extern
    public inline function toAtom() return "(?:" + this.get() + ")";

    // Implicit casts
    @:extern
    @:to public inline function asDisjunction() return this.asDisjunction();
    @:extern
    @:to public inline function asAlternative() return this;
    @:extern
    @:to public inline function asAtom() return new Atom(toAtom());
    @:extern
    @:to public inline function asPattern() return new RxPattern(this.get(), Precedence.Term);

    // Binary operators
    @:extern
    @:op(A + B)
    public inline function followedBy(rhs: Alternative)
        return new Alternative(toAlternative() + rhs.toAlternative());
    @:extern
    @:op(A | B)
    public inline function choice(rhs: Disjunction)
        return new Disjunction(toDisjunction() + "|" + rhs.toDisjunction());
}
@:forward(get, build)
abstract Atom(Term)
{
    @:extern
    public inline function new(pattern: String) this = new Term(pattern);

    // Accessors
    @:extern
    public inline function toDisjunction() return this.get();
    @:extern
    public inline function toAlternative() return this.get();
    @:extern
    public inline function toTerm() return this.get();
    @:extern
    public inline function toAtom() return this.get();

    // Implicit casts
    @:extern
    @:to public inline function asDisjunction() return this.asDisjunction();
    @:extern
    @:to public inline function asAlternative() return this.asAlternative();
    @:extern
    @:to public inline function asTerm() return this;
    @:extern
    @:to public inline function asPattern() return new RxPattern(this.get(), Precedence.Atom);

    // Quantifiers (redefine here because toAtom() has different definition from Term)
    @:extern
    public inline function option() return new Term(toAtom() + "?");
    @:extern
    public inline function any() return new Term(toAtom() + "*");
    @:extern
    public inline function some() return new Term(toAtom() + "+");

    // Binary operators
    @:extern
    @:op(A + B)
    public inline function followedBy(rhs: Alternative)
        return new Alternative(toAlternative() + rhs.toAlternative());
    @:extern
    @:op(A | B)
    public inline function choice(rhs: Disjunction)
        return new Disjunction(toDisjunction() + "|" + rhs.toDisjunction());
}
