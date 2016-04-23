package;
import minilatex.util.UnicodeUtil;
class UnicodeUtilCase extends haxe.unit.TestCase
{
    public function testFromCodePoint()
    {
        assertEquals("\u{32}", UnicodeUtil.fromCodePoint(0x32));
        assertEquals("\u{304}", UnicodeUtil.fromCodePoint(0x304));
        assertEquals("\u{3042}", UnicodeUtil.fromCodePoint(0x3042));
        assertEquals("\u{12345}", UnicodeUtil.fromCodePoint(0x12345));
    }
    public function testCodePointAt()
    {
        assertEquals(0x32, UnicodeUtil.codePointAt("\u0032", 0));
        assertEquals(0x304, UnicodeUtil.codePointAt("\u0304", 0));
        assertEquals(0x3042, UnicodeUtil.codePointAt("\u3042", 0));
        assertEquals(0x12345, UnicodeUtil.codePointAt("\u{12345}", 0));
    }
    public function testSingleCodepoint()
    {
        assertTrue(UnicodeUtil.rxSingleCodepoint.match("\u0000"));
        assertTrue(UnicodeUtil.rxSingleCodepoint.match("\u000A"));
        assertTrue(UnicodeUtil.rxSingleCodepoint.match("\u00A0"));
        assertTrue(UnicodeUtil.rxSingleCodepoint.match("\u0100"));
        assertTrue(UnicodeUtil.rxSingleCodepoint.match("\u3042"));
        assertTrue(UnicodeUtil.rxSingleCodepoint.match("\u{12345}"));
    }
}
class UnicodeUtilTest
{
    static function main()
    {
        var r = new haxe.unit.TestRunner();
        r.add(new UnicodeUtilCase());
        r.run();
    }
}
