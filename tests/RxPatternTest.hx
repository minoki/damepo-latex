import minilatex.util.CharSet;
import minilatex.util.RxPattern;
class RxPatternTest extends haxe.unit.TestCase
{
    public static inline function RxGroup(x) return RxPattern.Group(x);
    public function assertPatStrEquals(s: String, p, ?pos: haxe.PosInfos)
    {
        assertEquals(s, RxPattern.buildPatternString(p), pos);
    }
    public function assertMatch(s: String, p, ?pos: haxe.PosInfos)
    {
        assertTrue(RxPattern.buildEReg(p).match(s), pos);
    }
    public function assertNotMatch(s: String, p, ?pos: haxe.PosInfos)
    {
        assertFalse(RxPattern.buildEReg(p).match(s), pos);
    }
    public function testBasic()
    {
        assertPatStrEquals("a", RxPattern.Char("a"));
        assertPatStrEquals("a|xyz\\^\\\\", RxPattern.Char("a") | RxPattern.String("xyz^\\"));
        assertPatStrEquals("a|xyz\\^\\\\", RxPattern.Char("a") | RxPattern.StringLit("xyz^\\"));
        assertMatch("a", RxPattern.Char("a") | RxPattern.String("xyz^\\"));
        assertMatch("xyz^\\", RxPattern.Char("a") | RxPattern.String("xyz^\\"));
        assertPatStrEquals("[a-c]*|xyz", RxPattern.CharSet("abc").any() | RxPattern.String("xyz"));
        assertPatStrEquals("[a-c]*|(?:xyz)+", RxPattern.CharSet("abc").any() | RxPattern.String("xyz").some());
        assertPatStrEquals("[a-c]?", RxPattern.CharSet("abc").option());
        assertMatch("\u{12345}", RxPattern.AssertFirst() + RxPattern.AnyCodePoint() + RxPattern.AssertEnd());
        //assertMatch("\u{12345}", RxPattern.AssertFirst() + RxPattern.AnyExceptNewLine() + RxPattern.AssertEnd());
    }
    public static function main()
    {
        var r = new haxe.unit.TestRunner();
        r.add(new RxPatternTest());
        r.run();
    }
}
