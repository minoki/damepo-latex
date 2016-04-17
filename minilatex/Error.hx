package minilatex;
import minilatex.Token;
using Token.TokenLocationExtender;
class LaTeXError
{
    var message: String;
    public function new(message: String)
    {
        this.message = message;
    }
    public function toString(): String
    {
        return "LaTeX error: " + this.message;
    }
}
class TokenError extends LaTeXError
{
    var location: TokenLocation;
    public function new(message: String, location: TokenLocation)
    {
        super(message + " at " + location.toString());
        this.location = location;
    }
}
