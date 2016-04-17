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
    var filename: String;
    var currentLine: Int;
    var currentColumn: Int;
    var state: State;
    var rxSpaces: EReg;
    var rxToken_atletter: EReg;
    var rxToken_atother: EReg;
    private static inline function makeAnchoredRx(s: String): EReg
    {
        #if php
        return new EReg(s, "A");
        #else
        return new EReg("^(?:" + s + ")", "");
        #end
    }
    private static inline function matchAnchoredRx(r: EReg, s: String, pos: Int): Bool
    {
        #if php
            return r.matchSub(s, pos);
        #else
            return r.match(s.substring(pos));
        #end
    }
    private inline function updatePosition(matchedPos: {pos: Int, len: Int})
    {
        #if php
            this.position = matchedPos.pos + matchedPos.len;
        #else
            this.position += matchedPos.pos + matchedPos.len;
        #end
    }
    public function new(input: String, filename: String = "<input>")
    {
        this.input = input;
        this.position = 0;
        this.filename = filename;
        this.currentLine = 1;
        this.currentColumn = 0;
        this.state = State.NewLine;
        this.rxSpaces = makeAnchoredRx("[ \t]+");
        this.rxToken_atother = makeAnchoredRx("(%.*\n?)|\\\\(?:([a-zA-Z]+)|(.|\n))|([ \t])|(\n)|([^%\\\\])");
        this.rxToken_atletter = makeAnchoredRx("(%.*\n?)|\\\\(?:([a-zA-Z@]+)|(.|\n))|([ \t])|(\n)|([^%\\\\])");
    }
    function getCurrentLocation(): TokenLocation
    {
        return {filename: this.filename, line: this.currentLine, column: this.currentColumn};
    }
    public function readToken(scope: Scope): Null<Token>
    {
        var rxToken = scope.isAtLetter ? this.rxToken_atletter : this.rxToken_atother;
        while (this.position < this.input.length) {
            if (this.state == State.NewLine || this.state == State.SkipSpaces) {
                if (matchAnchoredRx(this.rxSpaces, this.input, this.position)) {
                    var matchedPos = this.rxSpaces.matchedPos();
                    updatePosition(matchedPos);
                    this.currentColumn += matchedPos.len; // rxSpaces does not match EOL
                    continue;
                }
            }
            if (matchAnchoredRx(rxToken, this.input, this.position)) {
                var matchedPos = rxToken.matchedPos();
                var currentLocation = this.getCurrentLocation();
                updatePosition(matchedPos);
                this.currentColumn += matchedPos.len;

                if (rxToken.matched(1) != null) { /* comment */
                    this.state = State.NewLine;
                    ++this.currentLine;
                    this.currentColumn = 0;
                    continue;

                } else if (rxToken.matched(2) != null) { /* control word */
                    var word = rxToken.matched(2);
                    this.state = State.SkipSpaces;
                    return new Token(ControlSequence(word), currentLocation);

                } else if (rxToken.matched(3) != null) { /* control symbol */
                    var c = rxToken.matched(3);
                    if (this.rxSpaces.match(c)) {
                        c = ' ';
                        this.state = State.SkipSpaces;
                    } else if (c == '\n') {
                        c = ' ';
                        this.state = State.NewLine;
                        ++this.currentLine;
                        this.currentColumn = 0;
                    } else {
                        this.state = State.MiddleOfLine;
                    }
                    return new Token(ControlSequence(c), currentLocation);

                } else if (rxToken.matched(4) != null) { /* space */
                    this.state = State.SkipSpaces;
                    return new Token(ControlSequence(' '), currentLocation);

                } else if (rxToken.matched(5) != null) { /* newline */
                    var currentLocation = this.getCurrentLocation();
                    ++this.currentLine;
                    this.currentColumn = 0;
                    switch (this.state) {
                    case State.NewLine:
                        return new Token(ControlSequence("par"), currentLocation);
                    case State.SkipSpaces:
                        this.state = State.NewLine;
                        continue;
                    default:
                        this.state = State.NewLine;
                        return new Token(Character(' '), currentLocation);
                    }

                } else if (rxToken.matched(6) != null) { /* other */
                    var c = rxToken.matched(6);
                    this.state = State.MiddleOfLine;
                    return new Token(Character(c), currentLocation);

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
