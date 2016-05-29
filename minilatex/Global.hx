package minilatex;
import minilatex.Error;

class Global
{
    var counters: Map<String, Int>;
    var counterReset: Map<String, Array<String>>;
    public function new()
    {
        this.counters = new Map();
        this.counterReset = new Map();
    }
    public function newCounter(name: String, ?within: String)
    {
        if (this.counters.exists(name)) {
            throw new LaTeXError("Counter '" + name + "' already defined");
        }
        this.counters.set(name, 0);
        this.counterReset.set(name, []);
        if (within != null) {
            if (!this.counters.exists(within)) {
                throw new LaTeXError("No counter '" + within + "' defined");
            }
            this.counterReset.get(within).push(name);
        }
    }
    public function getCounterValue(name: String): Int
    {
        if (!this.counters.exists(name)) {
            // \@nocounterr{name}
            throw new LaTeXError("No counter '" + name + "' defined");
        }
        return this.counters.get(name);
    }
    public function setCounterValue(name: String, value: Int): Void
    {
        if (!this.counters.exists(name)) {
            // \@nocounterr{name}
            throw new LaTeXError("No counter '" + name + "' defined");
        }
        this.counters.set(name, value);
    }
    public function addToCounter(name: String, delta: Int): Void
    {
        if (!this.counters.exists(name)) {
            // \@nocounterr{name}
            throw new LaTeXError("No counter '" + name + "' defined");
        }
        this.counters.set(name, this.counters.get(name) + delta);
    }
    public function stepCounter(name: String): Void
    {
        if (!this.counters.exists(name)) {
            // \@nocounterr{name}
            throw new LaTeXError("No counter '" + name + "' defined");
        }
        var newValue = this.counters.get(name) + 1;
        this.counters.set(name, newValue);
        for (c in innerCounters(name)) {
            this.counters.set(c, 0);
        }
    }
    public function isCounterDefined(name: String): Bool
    {
        return this.counters.exists(name);
    }
    public function addToReset(name: String, within: String)
    {
        if (!this.counters.exists(name)) {
            // \@nocounterr{name}
            throw new LaTeXError("No counter '" + name + "' defined");
        }
        if (!this.counters.exists(within)) {
            // \@nocounterr{within}
            throw new LaTeXError("No counter '" + within + "' defined");
        }
        var inn = innerCounters(within);
        if (inn.indexOf(name) != -1) {
            throw new LaTeXError("\\@addtoreset: recursion detected");
        }
        this.counterReset.get(within).push(name);
    }
    function innerCounters(name: String): Array<String>
    {
        var countersToReset = this.counterReset.get(name);
        var result = [];
        while (countersToReset.length > 0) {
            var countersToReset2 = [];
            for (c in countersToReset) {
                result.push(c);
                countersToReset2 = countersToReset2.concat(this.counterReset.get(c));
            }
            countersToReset = countersToReset2;
        }
        return result;
    }
}
