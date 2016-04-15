package minilatex;
enum Token
{
    Character(c: String, depth: Int);
    ControlSequence(name: String, depth: Int);
}
class TokenExtender
{
    public static function withDepth(token: Token, depth: Int): Token
    {
        return switch (token) {
        case Character(x, _): Character(x, depth);
        case ControlSequence(x, _): ControlSequence(x, depth);
        };
    }
    public static function tokenToString(token: Token): String
    {
        return switch (token) {
        case Character(c, _): c;
        case ControlSequence(name, _): "\\" + name;
        };
    }
}
