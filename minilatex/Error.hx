package minilatex;
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
