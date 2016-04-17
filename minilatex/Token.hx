package minilatex;
enum TokenValue
{
    Character(c: String);
    ControlSequence(name: String);
}
typedef TokenLocation = {
    var filename: String;
    var line: Int;
    var column: Int;
}
class Token
{
    public var value: TokenValue;
    public var location: TokenLocation;
    public function new(value: TokenValue, location: TokenLocation)
    {
        this.value = value;
        this.location = location;
    }
    public static function tokenValueToString(value: TokenValue): String
    {
        return switch (value) {
        case Character(c): c;
        case ControlSequence(name): "\\" + name;
        };
    }
    public function toString(): String
    {
        return tokenValueToString(this.value);
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
