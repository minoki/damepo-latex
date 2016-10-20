package minilatex;
import minilatex.Error;

class Global
{
    var namedCounters: Map<String, Int>;
    var counterReset: Map<String, Array<String>>;
    public function new()
    {
        this.namedCounters = new Map();
        this.counterReset = new Map();
    }
    public function newNamedCounter(name: String, ?within: String)
    {
        if (this.namedCounters.exists(name)) {
            throw new LaTeXError("Counter '" + name + "' already defined");
        }
        this.namedCounters.set(name, 0);
        this.counterReset.set(name, []);
        if (within != null) {
            if (!this.namedCounters.exists(within)) {
                throw new LaTeXError("No counter '" + within + "' defined");
            }
            this.counterReset.get(within).push(name);
        }
    }
    public function getNamedCounterValue(name: String): Int
    {
        if (!this.namedCounters.exists(name)) {
            // \@nocounterr{name}
            throw new LaTeXError("No counter '" + name + "' defined");
        }
        return this.namedCounters.get(name);
    }
    public function setNamedCounterValue(name: String, value: Int): Void
    {
        if (!this.namedCounters.exists(name)) {
            // \@nocounterr{name}
            throw new LaTeXError("No counter '" + name + "' defined");
        }
        this.namedCounters.set(name, value);
    }
    public function addToNamedCounter(name: String, delta: Int): Void
    {
        if (!this.namedCounters.exists(name)) {
            // \@nocounterr{name}
            throw new LaTeXError("No counter '" + name + "' defined");
        }
        this.namedCounters.set(name, this.namedCounters.get(name) + delta);
    }
    public function stepNamedCounter(name: String): Void
    {
        if (!this.namedCounters.exists(name)) {
            // \@nocounterr{name}
            throw new LaTeXError("No counter '" + name + "' defined");
        }
        var newValue = this.namedCounters.get(name) + 1;
        this.namedCounters.set(name, newValue);
        for (c in innerCounters(name)) {
            this.namedCounters.set(c, 0);
        }
    }
    public function isNamedCounterDefined(name: String): Bool
    {
        return this.namedCounters.exists(name);
    }
    public function addToReset(name: String, within: String)
    {
        if (!this.namedCounters.exists(name)) {
            // \@nocounterr{name}
            throw new LaTeXError("No counter '" + name + "' defined");
        }
        if (!this.namedCounters.exists(within)) {
            // \@nocounterr{within}
            throw new LaTeXError("No counter '" + within + "' defined");
        }
        var inn = innerCounters(name);
        if (inn.indexOf(within) != -1) {
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
