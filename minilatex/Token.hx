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
}
class TokenExtender
{
    public static function tokenToString(token: Token): String
    {
        return switch (token.value) {
        case Character(c): c;
        case ControlSequence(name): "\\" + name;
        };
    }
}
