package minilatex;
import minilatex.Token;
import minilatex.Scope;
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
    var rxComment: EReg;
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
        this.state = State.NewLine;
        this.rxSpaces = makeRx("[ \t]+");
        this.rxComment = makeRx("%[^\n]*\n?");
        this.rxControlWord_atother = makeRx("\\\\([a-zA-Z]+)");
        this.rxControlWord_atletter = makeRx("\\\\([a-zA-Z@]+)");
        this.rxControlSymbol = makeRx("\\\\(.)");
    }
    public function readToken(scope: Scope): Null<Token>
    {
        var rxControlWord = scope.isAtLetter ? this.rxControlWord_atletter : this.rxControlWord_atother;
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
                    return new Token(ControlSequence("par"), null);
                } else if (this.state == State.SkipSpaces) {
                    this.state = State.NewLine;
                    continue;
                } else {
                    this.state = State.NewLine;
                    return new Token(Character(' '), null);
                }
            }
            if (this.rxComment.matchSub(this.input, this.position)) {
                var p = this.rxComment.matchedPos();
                this.position = p.pos + p.len;
                this.state = State.NewLine;
                continue;
            } else if (rxControlWord.matchSub(this.input, this.position)) {
                var word = rxControlWord.matched(1);
                var p = rxControlWord.matchedPos();
                this.position = p.pos + p.len;
                this.state = State.SkipSpaces;
                return new Token(ControlSequence(word), null);
            } else if (this.rxControlSymbol.matchSub(this.input, this.position)) {
                var c = this.rxControlSymbol.matched(1);
                var p = this.rxControlSymbol.matchedPos();
                this.position = p.pos + p.len;
                if (this.rxSpaces.match(c)) {
                    this.state = State.SkipSpaces;
                } else {
                    this.state = State.MiddleOfLine;
                }
                return new Token(ControlSequence(c), null);
            } else {
                ++this.position;
                if (this.rxSpaces.match(c)) {
                    this.state = State.SkipSpaces;
                } else {
                    this.state = State.MiddleOfLine;
                }
                return new Token(Character(c), null);
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
