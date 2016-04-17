package;
import minilatex.Token;
import minilatex.Tokenizer;
import minilatex.ExpansionProcessor;
import minilatex.ExecutionProcessor;
import minilatex.Scope;
import minilatex.Error;
import minilatex.Command;

class ExpansionTestCase extends haxe.unit.TestCase
{
    function assertEnumEquals<T>(expected: T, actual: T, ?c: haxe.PosInfos)
    {
        assertTrue(Type.enumEq(expected, actual), c);
    }
    static function expansionResultEquals(x: Null<ExpansionResult>, y: Null<ExpansionResult>): Bool
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
    function assertETEquals(expected: Null<ExpansionResult>, actual: Null<ExpansionResult>, ?c: haxe.PosInfos)
    {
        assertTrue(expansionResultEquals(expected, actual), c);
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
    function assertExecEquals(expected: Null<ExecutionResult>, actual: Null<ExecutionResult>, ?c: haxe.PosInfos)
    {
        assertTrue(executionResultEquals(expected, actual), c);
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
        assertETEquals(expansionProcessor.expand(), Character(" "));
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
    public function testSimpleMacro()
    {
        var tokenizer = new Tokenizer("\\newcommand{\\foo}[2]{#2#1}\n\\foo{x}{y}\n \n  \\foo{\\foo{a}{b}}{c}");
        var expansionProcessor = new ExpansionProcessor(tokenizer, DefaultScope.getDefaultScope());
        var executionProcessor = new ExecutionProcessor(expansionProcessor);
        var result = executionProcessor.processAll();
        var it = result.iterator();
        assertExecEquals(it.next(), Character(" "));
        assertExecEquals(it.next(), Character("y"));
        assertExecEquals(it.next(), Character("x"));
        assertExecEquals(it.next(), Character(" "));
        assertExecEquals(it.next(), UnknownCommand(new Token(ControlSequence("par"), null)));
        assertExecEquals(it.next(), Character("c"));
        assertExecEquals(it.next(), Character("b"));
        assertExecEquals(it.next(), Character("a"));
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
