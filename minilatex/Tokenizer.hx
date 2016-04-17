package minilatex;
import minilatex.Token;
import minilatex.Scope;
import minilatex.Error;
private enum State {
    NewLine;
    SkipSpaces;
    MiddleOfLine;
}
class Tokenizer
{
    var input: String;
    var position: Int;
    var state: State;
    var rxSpaces: EReg;
    var rxToken_atletter: EReg;
    var rxToken_atother: EReg;
    private static inline function makeRx(s: String): EReg
    {
        #if php
        return new EReg(s, "A");
        #else
        return new EReg("^" + s, "");
        #end
    }
    public function new(input: String)
    {
        this.input = input;
        this.position = 0;
        this.state = State.NewLine;
        this.rxSpaces = makeRx("[ \t]+");
        this.rxToken_atother = makeRx("(?:(%.*\n?)|\\\\(?:([a-zA-Z]+)|(.|\n))|([ \t])|(\n)|([^%\\\\]))");
        this.rxToken_atletter = makeRx("(?:(%.*\n?)|\\\\(?:([a-zA-Z@]+)|(.|\n))|([ \t])|(\n)|([^%\\\\]))");
    }
    public function readToken(scope: Scope): Null<Token>
    {
        var rxToken = scope.isAtLetter ? this.rxToken_atletter : this.rxToken_atother;
        while (this.position < this.input.length) {
            if (this.state == State.NewLine || this.state == State.SkipSpaces) {
                if (this.rxSpaces.matchSub(this.input, this.position)) {
                    var p = this.rxSpaces.matchedPos();
                    this.position = p.pos + p.len;
                    continue;
                }
            }
            if (rxToken.matchSub(this.input, this.position)) {
                var p = rxToken.matchedPos();
                this.position = p.pos + p.len;

                if (rxToken.matched(1) != null) { /* comment */
                    this.state = State.NewLine;
                    continue;

                } else if (rxToken.matched(2) != null) { /* control word */
                    var word = rxToken.matched(2);
                    this.state = State.SkipSpaces;
                    return new Token(ControlSequence(word), null);

                } else if (rxToken.matched(3) != null) { /* control symbol */
                    var c = rxToken.matched(3);
                    if (this.rxSpaces.match(c)) {
                        c = ' ';
                        this.state = State.SkipSpaces;
                    } else if (c == '\n') {
                        c = ' ';
                        this.state = State.NewLine;
                    } else {
                        this.state = State.MiddleOfLine;
                    }
                    return new Token(ControlSequence(c), null);

                } else if (rxToken.matched(4) != null) { /* space */
                    this.state = State.SkipSpaces;
                    return new Token(ControlSequence(' '), null);

                } else if (rxToken.matched(5) != null) { /* newline */
                    switch (this.state) {
                    case State.NewLine:
                        return new Token(ControlSequence("par"), null);
                    case State.SkipSpaces:
                        this.state = State.NewLine;
                        continue;
                    default:
                        this.state = State.NewLine;
                        return new Token(Character(' '), null);
                    }

                } else if (rxToken.matched(6) != null) { /* other */
                    var c = rxToken.matched(6);
                    this.state = State.MiddleOfLine;
                    return new Token(Character(c), null);

                } else {
                    throw new LaTeXError("regexp error");
                }
            } else {
                throw new LaTeXError("unexpected character");
            }
        }
        return null;
    }
    public function nextRawChar(): Null<String>
    {
        if (this.position < this.input.length) {
            var c = this.input.charAt(this.position);
            ++this.position;
            return c;
        } else {
            return null;
        }
    }
    public function readRaw(delimiter: String): Null<String>
    {
        if (this.position < this.input.length) {
            var i = this.input.indexOf(delimiter, this.position);
            if (i < 0) {
                return null;
            } else {
                var s = this.input.substr(this.position, i - this.position);
                this.position = i + s.length;
                return s;
            }
        } else {
            return null;
        }
    }
}
