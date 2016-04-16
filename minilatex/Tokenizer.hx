package minilatex;
import minilatex.Token;
private enum State {
    NewLine;
    SkipSpaces;
    MiddleOfLine;
}
class Tokenizer
{
    var input: String;
    var position: Int;
    var unreadTokens: Array<Token>;
    var state: State;
    var rxSpaces: EReg;
    var rxComment: EReg;
    var rxControlWord: EReg;
    var rxControlWord_atother: EReg;
    var rxControlWord_atletter: EReg;
    var rxControlSymbol: EReg;
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
        this.unreadTokens = [];
        this.state = State.NewLine;
        this.rxSpaces = makeRx("[ \t]+");
        this.rxComment = makeRx("%[^\n]*\n?");
        this.rxControlWord_atother = makeRx("\\\\([a-zA-Z]+)");
        this.rxControlWord_atletter = makeRx("\\\\([a-zA-Z@]+)");
        this.rxControlWord = this.rxControlWord_atother;
        this.rxControlSymbol = makeRx("\\\\(.)");
    }
    public function hasPendingToken(): Bool
    {
        return this.unreadTokens.length > 0;
    }
    public function unreadToken(token: Null<Token>)
    {
        if (token != null) {
            this.unreadTokens.push(token);
        }
    }
    public function readToken(): Null<Token>
    {
        if (this.unreadTokens.length > 0) {
            return this.unreadTokens.shift();
        }
        while (this.position < this.input.length) {
            if (this.state == State.NewLine || this.state == State.SkipSpaces) {
                if (this.rxSpaces.matchSub(this.input, this.position)) {
                    var p = this.rxSpaces.matchedPos();
                    this.position = p.pos + p.len;
                    continue;
                }
            }
            var c = this.input.charAt(this.position);
            if (c == '\n') {
                ++this.position;
                if (this.state == State.NewLine) {
                    return ControlSequence("par", 0);
                } else if (this.state == State.SkipSpaces) {
                    this.state = State.NewLine;
                    continue;
                } else {
                    this.state = State.NewLine;
                    return Character(' ', 0);
                }
            }
            if (this.rxComment.matchSub(this.input, this.position)) {
                var p = this.rxComment.matchedPos();
                this.position = p.pos + p.len;
                this.state = State.NewLine;
                continue;
            } else if (this.rxControlWord.matchSub(this.input, this.position)) {
                var word = this.rxControlWord.matched(1);
                var p = this.rxControlWord.matchedPos();
                this.position = p.pos + p.len;
                this.state = State.SkipSpaces;
                return ControlSequence(word, 0);
            } else if (this.rxControlSymbol.matchSub(this.input, this.position)) {
                var c = this.rxControlSymbol.matched(1);
                var p = this.rxControlSymbol.matchedPos();
                this.position = p.pos + p.len;
                if (this.rxSpaces.match(c)) {
                    this.state = State.SkipSpaces;
                } else {
                    this.state = State.MiddleOfLine;
                }
                return ControlSequence(c, 0);
            } else {
                ++this.position;
                if (this.rxSpaces.match(c)) {
                    this.state = State.SkipSpaces;
                } else {
                    this.state = State.MiddleOfLine;
                }
                return Character(c, 0);
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
    public function setAtLetter(value: Bool)
    {
        this.rxControlWord = value ? this.rxControlWord_atletter : this.rxControlWord_atother;
    }
}
