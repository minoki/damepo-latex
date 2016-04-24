package minilatex;
import minilatex.Token;
import minilatex.Scope;
import minilatex.Error;
import minilatex.util.CharSet;
import minilatex.util.RxPattern;
import minilatex.util.RxPattern as P;
import minilatex.util.CharClass;
private enum State {
    NewLine;
    SkipSpaces;
    MiddleOfLine;
    Verbatim;
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
    private static inline function makeAnchoredRx(s): EReg
    {
        #if php
            return RxPattern.buildEReg(s, "uA");
        #else
            return RxPattern.buildEReg(RxPattern.AssertFirst() + s, "u");
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
        this.currentColumn += matchedPos.len;
    }
    public function new(input: String, filename: String = "<input>")
    {
        this.input = input;
        this.position = 0;
        this.filename = filename;
        this.currentLine = 1;
        this.currentColumn = 0;
        this.state = State.NewLine;
        this.rxSpaces = makeAnchoredRx(P.CharSetLit(" \t").some());
        var commentChar = P.CharLit("%");
        var escapeChar = P.CharLit("\\");
        var space = P.CharSetLit(" \t");
        var newLine = P.NewLine();

        var comment = commentChar + P.AnyExceptNewLine().any()
              + newLine.option();
        var letters = CharClass.Letter;
        var other = RxPattern.NotInSetLit("%\\");
        this.rxToken_atother =
            makeAnchoredRx(P.Group(comment)
                           | (escapeChar + (P.Group(letters.some())
                                            | P.Group(P.AnyCodePoint() | P.Empty())))
                           | P.Group(space)
                           | P.Group(newLine)
                           | P.Group(other));
        this.rxToken_atletter =
            makeAnchoredRx(P.Group(comment)
                           | (escapeChar + (P.Group((letters | P.CharLit("@")).some())
                                            | P.Group(P.AnyCodePoint() | P.Empty())))
                           | P.Group(space)
                           | P.Group(newLine)
                           | P.Group(other));
    }
    function getCurrentLocation(): TokenLocation
    {
        return new TokenLocation(this.filename, this.currentLine, this.currentColumn);
    }
    public function readToken(scope: IScope): Null<Token>
    {
        var rxToken = scope.isAtLetter ? this.rxToken_atletter : this.rxToken_atother;
        while (this.position < this.input.length) {
            if (this.state == State.Verbatim) {
                var currentLocation = this.getCurrentLocation();
                var c = this.input.charAt(this.position);
                ++this.position;
                ++this.currentColumn;
                if (c == '\n') {
                    ++this.currentLine;
                    this.currentColumn = 0;
                }
                return new Token(Character(c), currentLocation);
            }
            if (this.state == State.NewLine || this.state == State.SkipSpaces) {
                if (matchAnchoredRx(this.rxSpaces, this.input, this.position)) {
                    updatePosition(this.rxSpaces.matchedPos());
                    continue;
                }
            }
            var currentLocation = this.getCurrentLocation();
            if (matchAnchoredRx(rxToken, this.input, this.position)) {
                updatePosition(rxToken.matchedPos());

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
                    } else if (c == '') {
                        throw new TokenError("unexpected end of input after '\\'", currentLocation);
                    } else {
                        this.state = State.MiddleOfLine;
                    }
                    return new Token(ControlSequence(c), currentLocation);

                } else if (rxToken.matched(4) != null) { /* space */
                    this.state = State.SkipSpaces;
                    return new Token(Space(' '), currentLocation);

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
                        return new Token(Space(' '), currentLocation);
                    }

                } else if (rxToken.matched(6) != null) { /* other */
                    var c = rxToken.matched(6);
                    this.state = State.MiddleOfLine;
                    return new Token(switch (c) {
                        case '{': BeginGroup(c);
                        case '}': EndGroup(c);
                        case '&': AlignmentTab(c);
                        case '_': Subscript(c);
                        case '^': Superscript(c);
                        case '$': MathShift(c);
                        case '~': Active(c);
                        case '#': Parameter(c);
                        default: Character(c);
                        }, currentLocation);

                } else {
                    throw new TokenError("internal error", currentLocation);
                }
            } else {
                throw new TokenError("unexpected character", currentLocation);
            }
        }
        return null;
    }
    public function enterVerbatimMode()
    {
        this.state = State.Verbatim;
    }
    public function leaveVerbatimMode()
    {
        this.state = State.MiddleOfLine;
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
