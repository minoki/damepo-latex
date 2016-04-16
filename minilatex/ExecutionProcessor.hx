package minilatex;
import minilatex.Token;
import minilatex.Scope;
import minilatex.ExpansionProcessor;
import minilatex.Error;
enum ExecutionResult
{
    Character(c: String);
    UnknownCommand(name: Token);
    Group(c: Array<ExecutionResult>);
    AlignmentTab;
    Subscript;
    Superscript;
    MathShift;
}
class ExecutionProcessor
{
    public var expansionProcessor: ExpansionProcessor;
    public function new(expansionProcessor: ExpansionProcessor)
    {
        this.expansionProcessor = expansionProcessor;
    }
    public function processAll(): Array<ExecutionResult>
    {
        var result: Array<Array<ExecutionResult>> = [[]];
        while (true) {
            var t = this.expansionProcessor.expand();
            if (t == null) {
                if (result.length != 1) {
                    throw new LaTeXError("Unexpected end of input");
                } else {
                    return result[0];
                }
            }
            switch (t) {
            case Character(c):
                result[0].push(Character(c));
            case MathShift:
                result[0].push(MathShift);
            case AlignmentTab:
                result[0].push(AlignmentTab);
            case Subscript:
                result[0].push(Subscript);
            case Superscript:
                result[0].push(Superscript);
            case BeginGroup:
                this.expansionProcessor.enterScope();
                result.unshift([]);
            case EndGroup:
                if (result.length <= 1) {
                    throw new LaTeXError("extra '}'");
                }
                var content = result.shift();
                result[0].push(Group(content));
                this.expansionProcessor.leaveScope();
            case UnknownCommand(name):
                result[0].push(UnknownCommand(name));
                continue;
                //throw new LaTeXError("command not found: " + name.toString());
            case ExecutableCommand(name, command):
                result[0] = result[0].concat(command.doCommand(this));
            }
        }
    }
}
