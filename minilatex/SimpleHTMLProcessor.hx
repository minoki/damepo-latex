package minilatex;
import minilatex.ExpansionProcessor;
import minilatex.ExecutionProcessor;
import minilatex.Scope;
import minilatex.Error;
import minilatex.command.Core;
import minilatex.command.TypesetCommand;
class HTMLUtil
{
    private static var rxHTMLSpecialChars = new EReg("[<\"\'&>\u00A0]", "g");
    private static function escapeHTMLOneChar(r: EReg)
    {
        return switch (r.matched(0)) {
        case '<': "&lt;";
        case '>': "&gt;";
        case '"': "&quot;";
        case '&': "&amp;";
        case '\'': "&apos;";
        case '\u00A0': "&nbsp;";
        case c: c;
        };
    }
    public static inline function escapeHTML(s: String)
    {
        return rxHTMLSpecialChars.map(s, escapeHTMLOneChar);
    }
}
class ParCommand implements ExecutableCommand<SimpleHTMLProcessor>
{
    public function new()
    {
    }
    public function execute(processor: SimpleHTMLProcessor)
    {
        processor.paragraph();
    }
}
class SimpleHTMLProcessor extends BasicExecutionProcessor<SimpleHTMLProcessor>
    implements ITypesetExecutionProcessor
    implements IVerbTextExecutionProcessor
{
    var totalBuf: StringBuf;
    var currentBuf: StringBuf;
    var scopeLevel: Int;
    var unread: Null<ExpansionResult<SimpleHTMLProcessor>>;
    public function new(expansionProcessor: ExpansionProcessor<SimpleHTMLProcessor>)
    {
        super(expansionProcessor);
        this.totalBuf = new StringBuf();
        this.currentBuf = new StringBuf();
        this.scopeLevel = 0;
    }
    public function defineCommands()
    {
        var scope = this.expansionProcessor.getCurrentScope();
        DefaultScope.defineStandardCommands(scope);
        DefaultScope.defineVerbCommand(scope);
        TypesetCommand.defineStandardTypesetCommands(scope);
        scope.defineExecutableCommand(ControlSequence("par"), new ParCommand());
    }
    function nextToken(): Null<ExpansionResult<SimpleHTMLProcessor>>
    {
        if (this.unread != null) {
            var t = this.unread;
            this.unread = null;
            return t;
        } else {
            return this.expansionProcessor.expand();
        }
    }
    function readNextChar(): Null<String>
    {
        var t = this.nextToken();
        return switch (t) {
        case null: null;
        case Character(c): c;
        default: this.unread = t; null;
        };
    }
    function unreadChar(c: String)
    {
        if (c != null) {
            this.unread = Character(c);
        }
    }
    public function process(): Bool
    {
        var t = this.nextToken();
        switch (t) {
        case null:
            this.checkEnvironment();
            if (this.scopeLevel > 0) {
                throw new LaTeXError("Unexpected end of input");
            }
            return false;
        case Character(c):
            switch(c) {
            case '"': c = "\u201D"; // rdquot
            case '\'':
                var c2 = this.readNextChar();
                if (c2 == '\'') {
                    c = "\u201D"; // rdquot
                } else {
                    c = "\u2019"; // rquot
                    this.unreadChar(c2);
                }
            case '`':
                var c2 = this.readNextChar();
                if (c2 == '`') {
                    c = "\u201C"; // ldquot
                } else {
                    c = "\u2018"; // lquot
                    this.unreadChar(c2);
                }
            case '-':
                var c2 = this.readNextChar();
                if (c2 == '-') {
                    var c3 = this.readNextChar();
                    if (c3 == '-') {
                        c = "\u2014"; // em dash
                    } else {
                        c = "\u2013"; // en dash
                        this.unreadChar(c3);
                    }
                } else {
                    c = "-";
                    this.unreadChar(c2);
                }
            case '?':
                var c2 = this.readNextChar();
                if (c2 == '\'') {
                    c = "\u00BF";
                } else {
                    this.unreadChar(c2);
                }
            case '!':
                var c2 = this.readNextChar();
                if (c2 == '\'') {
                    c = "\u00A1";
                } else {
                    this.unreadChar(c2);
                }
                }
            currentBuf.add(HTMLUtil.escapeHTML(c));
        case Space:
            currentBuf.add(" ");
        case BeginGroup:
            this.expansionProcessor.enterScope();
            ++this.scopeLevel;
        case EndGroup:
            if (this.scopeLevel == 0) {
                throw new LaTeXError("mismatched closing brace '}'");
            }
            --this.scopeLevel;
            this.expansionProcessor.leaveScope();
        case MathShift:
            throw new LaTeXError("Math Shift is not supported yet. Sorry!");
        case AlignmentTab:
            throw new LaTeXError("Alignment Tab is not supported yet. Sorry!");
        case Subscript:
            throw new LaTeXError("Subscript is not supported yet. Sorry!");
        case Superscript:
            throw new LaTeXError("Superscript is not supported yet. Sorry!");
        case UnknownCommand(name):
            throw new LaTeXError("Unknown command: " + name.toString());
        case ExecutableCommand(name, command):
            command.execute(this);
        }
        return true;
    }
    public function typesetChar(c: String)
    {
        currentBuf.add(HTMLUtil.escapeHTML(c));
    }
    public function verbCommand(content: String, star: Bool)
    {
        currentBuf.add("<code>");
        currentBuf.add(HTMLUtil.escapeHTML(content));
        currentBuf.add("</code>");
    }
    public function paragraph()
    {
        var s = currentBuf.toString();
        if (s != "")
        {
            totalBuf.add("<p>");
            totalBuf.add(s);
            totalBuf.add("</p>");
            currentBuf = new StringBuf();
        }
    }
    public function toHTMLSource()
    {
        var t = totalBuf.toString();
        var s = currentBuf.toString();
        if (s != "") {
            return t + "<p>" + s + "</p>";
        } else {
            return t;
        }
    }
}
