package minilatex;
import minilatex.Error;
enum TokenValue
{
    Character(c: String);
    ControlSequence(name: String);
    Space(c: String);
    BeginGroup(c: String);
    EndGroup(c: String);
    AlignmentTab(c: String);
    Subscript(c: String);
    Superscript(c: String);
    MathShift(c: String);
    Active(c: String);
    Parameter(c: String);
}
class TokenValueExtender
{
    public static function toString(value: TokenValue): String
    {
        return switch (value) {
        case Character(c): c;
        case ControlSequence(name): "\\" + name;
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
    }
}
class TokenLocation
{
    public var filename: String;
    public var line: Int;
    public var column: Int;
    public function new(filename: String, line: Int, column: Int)
    {
        this.filename = filename;
        this.line = line;
        this.column = column;
    }
}
class TokenLocationExtender
{
    public static function toString(location: Null<TokenLocation>)
    {
        if (location == null) {
            return "(location info unavailable)";
        } else {
            return "file " + location.filename + ", line " + location.line + ", column " + location.column;
        }
    }
}
@:final
class Token
{
    public var value: TokenValue;
    public var location: Null<TokenLocation>;
    public inline function new(value: TokenValue, location: Null<TokenLocation>)
    {
        this.value = value;
        this.location = location;
    }
    public function toString(): String
    {
        return TokenValueExtender.toString(this.value);
    }
}
class TokenUtil
{
    public static function digitValue(c: String): Null<Int>
    {
        return switch (c) {
        case '0': 0;
        case '1': 1;
        case '2': 2;
        case '3': 3;
        case '4': 4;
        case '5': 5;
        case '6': 6;
        case '7': 7;
        case '8': 8;
        case '9': 9;
        case _: null;
        }
    }
    public static function tokenListToInt(tokens: Array<Token>): Null<Int>
    {
        if (tokens.length != 1) {
            return null;
        }
        return switch (tokens[0].value) {
        case Character(x): digitValue(x);
        default: null;
        };
    }
    public static function tokenListToName(tokens: Array<Token>): Null<String>
    {
        var s = new StringBuf();
        for (t in tokens) {
            switch (t.value) {
            case Character(c):
                s.add(c);
            default:
                return null;
            }
        }
        return s.toString();
    }
}
