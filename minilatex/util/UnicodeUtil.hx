package minilatex.util;
private class CodePointIterator
{
    var s: String;
    var index: Int;
    public function new(s: String, index: Int = 0)
    {
        this.s = s;
        this.index = index;
    }
    public function hasNext()
    {
        return this.index < this.s.length;
    }
    public function next()
    {
        var x = this.s.charCodeAt(index++);
        #if (js || java)
            /* decode UTF-16 sequence */
            if (0xD800 <= x && x <= 0xDFFF) {
                if (0xDC00 <= x) {
                    throw "codePointAt: invalid tail surrogate";
                }
                var y = this.s.charCodeAt(index++);
                if (0xDC00 <= y && y <= 0xDFFF) {
                    return (((x & 0x3FF) << 10) + 0x10000) | (y & 0x3FF);
                } else {
                    throw "codePointAt: invalid tail surrogate";
                }
            } else {
                return x;
            }
        #elseif (cpp || neko || php)
            /* decode UTF-8 sequence */
            if (x < 0x80) {
                return x;
            } else {
                if (x < 0xC0) {
                    throw "codePointAt: invalid UTF-8 sequence";
                } else if (x < 0xE0) {
                    var x2 = this.s.charCodeAt(index++);
                    var a0 = x & 0x1F;
                    var a1 = x2 & 0x3F;
                    var v = (a0 << 6) | a1;
                    if (v < 0x80 || (x2 & 0xC0) != 0x80) {
                        throw "codePointAt: invalid UTF-8 sequence";
                    }
                    return v;
                } else if (x < 0xF0) {
                    var x2 = this.s.charCodeAt(index++);
                    var x3 = this.s.charCodeAt(index++);
                    var a0 = x & 0x0F;
                    var a1 = x2 & 0x3F;
                    var a2 = x3 & 0x3F;
                    var v = (a0 << 12) | (a1 << 6) | a2;
                    if (v < 0x800 || (x2 & 0xC0) != 0x80 || (x3 & 0xC0) != 0x80) {
                        throw "codePointAt: invalid UTF-8 sequence";
                    }
                    return v;
                } else if (x < 0xF8) {
                    var x2 = this.s.charCodeAt(index++);
                    var x3 = this.s.charCodeAt(index++);
                    var x4 = this.s.charCodeAt(index++);
                    var a0 = x & 0x07;
                    var a1 = x2 & 0x3F;
                    var a2 = x3 & 0x3F;
                    var a3 = x4 & 0x3F;
                    var v = (a0 << 18) | (a1 << 12) | (a2 << 6) | a3;
                    if (v < 0x10000 || (x2 & 0xC0) != 0x80 || (x3 & 0xC0) != 0x80 || (x4 & 0xC0) != 0x80) {
                        throw "codePointAt: invalid UTF-8 sequence";
                    }
                    return v;
                } else {
                    throw "codePointAt: invalid UTF-8 sequence";
                }
            }
        #else
            return this.s.charCodeAt(this.index++);
        #end
    }
}
class UnicodeUtil
{
    #if js
        public static var rxSingleCodepoint = ~/^(?:[\u0000-\uD7FF\uE000-\uFFFF]|[\uD800-\uDBFF][\uDC00-\uDFFF])$/;
    #else // if (neko || cpp || php || flash || java)
        public static var rxSingleCodepoint = ~/^.$/us; /* s: PCRE_DOTALL */
    #end
    public static function codePointIterator(s: String): Iterator<Int>
    {
        return new CodePointIterator(s);
    }
    public static function codePointAt(c: String, i: Int)
    {
        var x = c.charCodeAt(i);
        #if (js || java)
            /* decode UTF-16 sequence */
            if (0xD800 <= x && x <= 0xDFFF) {
                if (0xDC00 <= x) {
                    throw "codePointAt: invalid tail surrogate";
                }
                var y = c.charCodeAt(i + 1);
                if (0xDC00 <= y && y <= 0xDFFF) {
                    return (((x & 0x3FF) << 10) + 0x10000) | (y & 0x3FF);
                } else {
                    throw "codePointAt: invalid tail surrogate";
                }
            } else {
                return x;
            }
        #elseif (cpp || neko || php)
            /* decode UTF-8 sequence */
            if (x < 0x80) {
                return x;
            } else {
                if (x < 0xC0) {
                    throw "codePointAt: invalid UTF-8 sequence";
                } else if (x < 0xE0) {
                    var x2 = c.charCodeAt(i + 1);
                    var a0 = x & 0x1F;
                    var a1 = x2 & 0x3F;
                    var v = (a0 << 6) | a1;
                    if (v < 0x80 || (x2 & 0xC0) != 0x80) {
                        throw "codePointAt: invalid UTF-8 sequence";
                    }
                    return v;
                } else if (x < 0xF0) {
                    var x2 = c.charCodeAt(i + 1);
                    var x3 = c.charCodeAt(i + 2);
                    var a0 = x & 0x0F;
                    var a1 = x2 & 0x3F;
                    var a2 = x3 & 0x3F;
                    var v = (a0 << 12) | (a1 << 6) | a2;
                    if (v < 0x800 || (x2 & 0xC0) != 0x80 || (x3 & 0xC0) != 0x80) {
                        throw "codePointAt: invalid UTF-8 sequence";
                    }
                    return v;
                } else if (x < 0xF8) {
                    var x2 = c.charCodeAt(i + 1);
                    var x3 = c.charCodeAt(i + 2);
                    var x4 = c.charCodeAt(i + 3);
                    var a0 = x & 0x07;
                    var a1 = x2 & 0x3F;
                    var a2 = x3 & 0x3F;
                    var a3 = x4 & 0x3F;
                    var v = (a0 << 18) | (a1 << 12) | (a2 << 6) | a3;
                    if (v < 0x10000 || (x2 & 0xC0) != 0x80 || (x3 & 0xC0) != 0x80 || (x4 & 0xC0) != 0x80) {
                        throw "codePointAt: invalid UTF-8 sequence";
                    }
                    return v;
                } else {
                    throw "codePointAt: invalid UTF-8 sequence";
                }
            }
        #else
            return c.charCodeAt(i);
        #end
    }
    public static function fromCodePoint(c: Int)
    {
        #if (js || java)
            /* encode UTF-16 */
            if (c < 0x10000) {
                if (0xD800 <= c && c <= 0xDFFF) {
                    throw "fromCodePoint: Invalid surrogate pairs";
                }
                return String.fromCharCode(c);
            } else {
                if (c > 0x10FFFF) {
                    throw "fromCodePoint: Code point out of range";
                }
                var hi = ((c - 0x10000) >> 10) | 0xD800;
                var lo = ((c - 0x10000) & 0x3FF) | 0xDC00;
                #if js
                    return (untyped String.fromCharCode)(hi, lo);
                #else
                    return String.fromCharCode(hi) + String.fromCharCode(lo);
                #end
            }
        #elseif (cpp || neko || php)
            /* encode UTF-8 */
            if (c < 0x80) {
                return String.fromCharCode(c);
            } else if (c < 0x800) { // 11 bits
                var c1 = (c >> 6) | 0xC0;
                var c2 = (c & 0x3F) | 0x80;
                return String.fromCharCode(c1) + String.fromCharCode(c2);
            } else if (c < 0x10000) { // 16 bits
                if (0xD800 <= c && c <= 0xDFFF) {
                    throw "fromCodePoint: Invalid surrogate pairs";
                }
                var c1 = (c >> 12) | 0xE0;
                var c2 = ((c >> 6) & 0x3F) | 0x80;
                var c3 = (c & 0x3F) | 0x80;
                return String.fromCharCode(c1) + String.fromCharCode(c2) + String.fromCharCode(c3);
            } else if (c < 0x110000) { // 21 bits
                var c1 = (c >> 18) | 0xF0;
                var c2 = ((c >> 12) & 0x3F) | 0x80;
                var c3 = ((c >> 6) & 0x3F) | 0x80;
                var c4 = (c & 0x3F) | 0x80;
                return String.fromCharCode(c1) + String.fromCharCode(c2) + String.fromCharCode(c3) + String.fromCharCode(c4);
            } else {
                throw "fromCodePoint: Code point out of range";
            }
        #else
            return String.fromCharCode(c);
        #end
    }
}
