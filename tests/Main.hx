package;
import minilatex.Token;
import minilatex.Tokenizer;
import minilatex.ExpansionProcessor;
import minilatex.ExecutionProcessor;
import minilatex.Scope;
import minilatex.Error;
import minilatex.Command;
using Main.ExpansionResultExtension;

class ExpansionResultExtension
{
    public static function toString<E>(e: Null<ExpansionResult<E>>)
    {
        return switch (e) {
        case null:
            "(null)";
        case Character(c):
            "Character(" + c + ")";
        case UnknownCommand(name):
            "UnknownCommand(" + name.toString() + ")";
        case ExecutableCommand(name, _):
            "ExecutableCommand(" + name.toString() + ")";
        case BeginGroup: "{";
        case EndGroup: "}";
        case AlignmentTab: "&";
        case Subscript: "_";
        case Superscript: "^";
        case MathShift: "$";
        case Space: " ";
        }
    }
}

class ExpansionTestCase extends haxe.unit.TestCase
{
    function assertEnumEquals<T>(expected: T, actual: T, ?c: haxe.PosInfos)
    {
        assertTrue(Type.enumEq(expected, actual), c);
    }
    static function expansionResultEquals<E>(x: Null<ExpansionResult<E>>, y: Null<ExpansionResult<E>>): Bool
    {
        if (x == null || y == null) {
            return x == null && y == null;
        }
        return switch (x) {
        case UnknownCommand(name1):
            switch (y) {
            case UnknownCommand(name2): Type.enumEq(name1.value, name2.value);
            default: false;
            };
        case ExecutableCommand(name1, _):
            switch (y) {
            case ExecutableCommand(name2, _): Type.enumEq(name1.value, name2.value);
            default: false;
            };
        default: Type.enumEq(x, y);
        };
    }
    function assertETEquals<E>(expected: Null<ExpansionResult<E>>, actual: Null<ExpansionResult<E>>, ?c: haxe.PosInfos)
    {
        if (!expansionResultEquals(expected, actual)) {
            assertEquals(expected.toString(), actual.toString(), c);
        } else {
            assertTrue(true, c);
        }
    }
    static function executionResultEquals(x: Null<ExecutionResult>, y: Null<ExecutionResult>): Bool
    {
        if (x == null || y == null) {
            return x == null && y == null;
        }
        return switch (x) {
        case UnknownCommand(name1):
            switch (y) {
            case UnknownCommand(name2): Type.enumEq(name1.value, name2.value);
            default: false;
            };
        case Group(a):
            switch (y) {
            case Group(b):
                if (a.length != b.length) {
                    false;
                } else {
                    var i = 0;
                    while (i < a.length) {
                        if (!executionResultEquals(a[i], b[i])) {
                            return false;
                        }
                        ++i;
                    }
                    return true;
                }
            default: false;
            };
        default: Type.enumEq(x, y);
        };
    }
    static function executionResultToString(r: Null<ExecutionResult>)
    {
        return switch (r) {
        case null: "(null)";
        case Character(c): 'Character(\'${c}\')';
        case UnknownCommand(name): 'UnknownCommand(${name.toString()})';
        case Group(c): "Group([" + c.map(executionResultToString).join(", ") + "])";
        case AlignmentTab: "AlignmentTab";
        case Subscript: "Subscript";
        case Superscript: "Superscript";
        case MathShift: "MathShift";
        case Space: "Space";
        }
    }
    function assertExecEquals(expected: Null<ExecutionResult>, actual: Null<ExecutionResult>, ?c: haxe.PosInfos)
    {
        if (!executionResultEquals(expected, actual)) {
            assertEquals(executionResultToString(expected), executionResultToString(actual), c);
        }
    }
    public function testBasic()
    {
        var tokenizer = new Tokenizer("\\Hello world!\n% This is a comment\nGood\\%bye!");
        var expansionProcessor = new ExpansionProcessor(tokenizer, new Scope(null));
        assertETEquals(expansionProcessor.expand(), UnknownCommand(new Token(ControlSequence("Hello"), null)));
        assertETEquals(expansionProcessor.expand(), Character("w"));
        assertETEquals(expansionProcessor.expand(), Character("o"));
        assertETEquals(expansionProcessor.expand(), Character("r"));
        assertETEquals(expansionProcessor.expand(), Character("l"));
        assertETEquals(expansionProcessor.expand(), Character("d"));
        assertETEquals(expansionProcessor.expand(), Character("!"));
        assertETEquals(expansionProcessor.expand(), Space);
        assertETEquals(expansionProcessor.expand(), Character("G"));
        assertETEquals(expansionProcessor.expand(), Character("o"));
        assertETEquals(expansionProcessor.expand(), Character("o"));
        assertETEquals(expansionProcessor.expand(), Character("d"));
        assertETEquals(expansionProcessor.expand(), UnknownCommand(new Token(ControlSequence("%"), null)));
        assertETEquals(expansionProcessor.expand(), Character("b"));
        assertETEquals(expansionProcessor.expand(), Character("y"));
        assertETEquals(expansionProcessor.expand(), Character("e"));
        assertETEquals(expansionProcessor.expand(), Character("!"));
        assertETEquals(expansionProcessor.expand(), null);
    }
    public function testUnicode()
    {
        var tokenizer = new Tokenizer("\\Hello\u{3042}\\\u{1F600}a\\\u{20BBf}a");
        var expansionProcessor = new ExpansionProcessor(tokenizer, new Scope(null));
        assertETEquals(expansionProcessor.expand(), UnknownCommand(new Token(ControlSequence("Hello\u{3042}"), null)));
        assertETEquals(expansionProcessor.expand(), UnknownCommand(new Token(ControlSequence("\u{1F600}"), null)));
        assertETEquals(expansionProcessor.expand(), Character("a"));
        assertETEquals(expansionProcessor.expand(), UnknownCommand(new Token(ControlSequence("\u{20BBF}a"), null)));
        assertETEquals(expansionProcessor.expand(), null);
    }
    public function testSimpleMacro()
    {
        var tokenizer = new Tokenizer("\\newcommand{\\foo}[2]{#2#1}\n\\foo{x}{y}\n \n  \\foo{\\foo{a}{b}}{c}");
        var expansionProcessor = new ExpansionProcessor<ExecutionProcessor>(tokenizer, DefaultScope.getDefaultScope());
        var executionProcessor = new ExecutionProcessor(expansionProcessor);
        var result = executionProcessor.processAll();
        var it = result.iterator();
        assertExecEquals(Space, it.next());
        assertExecEquals(Character("y"), it.next());
        assertExecEquals(Character("x"), it.next());
        assertExecEquals(Space, it.next());
        assertExecEquals(UnknownCommand(new Token(ControlSequence("par"), null)), it.next());
        assertExecEquals(Character("c"), it.next());
        assertExecEquals(Character("b"), it.next());
        assertExecEquals(Character("a"), it.next());
        assertFalse(it.hasNext());
    }
    public function testOptionalArgument()
    {
        var tokenizer = new Tokenizer("\\newcommand\\hoge[1][x]{#1}%\n\\hoge { y}%\n\\hoge [z]%\n\\hoge\n");
        var expansionProcessor = new ExpansionProcessor<ExecutionProcessor>(tokenizer, DefaultScope.getDefaultScope());
        var executionProcessor = new ExecutionProcessor(expansionProcessor);
        var result = executionProcessor.processAll();
        var it = result.iterator();
        assertExecEquals(Character("x"), it.next());
        assertExecEquals(Group([Space, Character("y")]), it.next());
        assertExecEquals(Character("z"), it.next());
        assertExecEquals(Character("x"), it.next());
        assertFalse(it.hasNext());
    }
    public function testCompleteExpansion()
    {
        var tokenizer = new Tokenizer("\\newcommand\\two{2}\\newcommand\\Two{\\two}\\newcommand{\\foo}[\\Two]{#2#1}\\foo{x}{y}");
        var expansionProcessor = new ExpansionProcessor<ExecutionProcessor>(tokenizer, DefaultScope.getDefaultScope());
        var executionProcessor = new ExecutionProcessor(expansionProcessor);
        var result = executionProcessor.processAll();
        var it = result.iterator();
        assertExecEquals(Character("y"), it.next());
        assertExecEquals(Character("x"), it.next());
        assertFalse(it.hasNext());
    }
    public function testEnvironment()
    {
        var tokenizer = new Tokenizer("\\newenvironment{foo}{x}{y}\\begin{foo}123\\end{foo}");
        var expansionProcessor = new ExpansionProcessor<ExecutionProcessor>(tokenizer, DefaultScope.getDefaultScope());
        var executionProcessor = new ExecutionProcessor(expansionProcessor);
        var result = executionProcessor.processAll();
        var it = result.iterator();
        assertExecEquals(Group([Character("x"),
                                Character("1"),
                                Character("2"),
                                Character("3"),
                                Character("y")]), it.next());
        assertFalse(it.hasNext());
    }
}

class Main
{
    static function main()
    {
        var r = new haxe.unit.TestRunner();
        r.add(new ExpansionTestCase());
        r.run();
    }
}
