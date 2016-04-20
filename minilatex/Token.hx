package minilatex;
enum TokenValue
{
    Character(c: String);
    ControlSequence(name: String);
}
class TokenValueExtender
{
    public static function toString(value: TokenValue): String
    {
        return switch (value) {
        case Character(c): c;
        case ControlSequence(name): "\\" + name;
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
class Token
{
    public var value: TokenValue;
    public var location: Null<TokenLocation>;
    public function new(value: TokenValue, location: Null<TokenLocation>)
    {
        this.value = value;
        this.location = location;
    }
    public function toString(): String
    {
        return TokenValueExtender.toString(this.value);
    }
}
