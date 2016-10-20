package minilatex.command;
import minilatex.Token;
import minilatex.Scope;
import minilatex.Global;
import minilatex.Command;
import minilatex.command.Core; // UserCommand
import minilatex.command.TeXPrimitive; // RomannumeralCommand
import minilatex.ExpansionProcessor;
import minilatex.ExecutionProcessor;
import minilatex.Util;
import minilatex.Error;
using ExpansionProcessor.ExpansionProcessorUtil;
using Util.NullExtender;
class NewcounterCommand implements ExecutableCommand<IExecutionProcessor>
{
    var name: TokenValue;
    public function new()
    {
        this.name = ControlSequence("newcounter");
    }
    public function execute(processor: IExecutionProcessor)
    {
        var expP = processor.getExpansionProcessor();
        var counterName = expP.expandArgument(this.name, false)
            .bindNull(TokenUtil.tokenListToName)
            .throwIfNull(new LaTeXError("invalid token while reading counter name"));
        var withinT = expP.expandOptionalArgument(this.name, false, null);
        var within = if (withinT != null) {
            TokenUtil.tokenListToName(withinT).throwIfNull(new LaTeXError("invalid token while reading counter name"));
        } else {
            null;
        };
        processor.getGlobal().newNamedCounter(counterName, within);
        // Define \the<counter>
        var theCounter = ControlSequence("the" + counterName);
        expP.getGlobalScope().defineExpandableCommand(theCounter, new UserCommand(theCounter, 0, null, [new Token(ControlSequence("@arabic"), null), new Token(ControlSequence("c@" + counterName), null)], false));
        // TODO: \c@<counter>, \cl@<counter>, \p@<counter>
    }
}
class SetcounterCommand implements ExecutableCommand<IExecutionProcessor>
{
    var name: TokenValue;
    public function new()
    {
        this.name = ControlSequence("setcounter");
    }
    public function execute(processor: IExecutionProcessor)
    {
        var expP = processor.getExpansionProcessor();
        var counterName = expP.expandArgument(this.name, false)
            .bindNull(TokenUtil.tokenListToName)
            .throwIfNull(new LaTeXError("invalid token while reading counter name"));
        var value = expP.readIntegerArgument(this.name);
        processor.getGlobal().setNamedCounterValue(counterName, value);
    }
}
class AddtocounterCommand implements ExecutableCommand<IExecutionProcessor>
{
    var name: TokenValue;
    public function new()
    {
        this.name = ControlSequence("addtocounter");
    }
    public function execute(processor: IExecutionProcessor)
    {
        var expP = processor.getExpansionProcessor();
        var counterName = expP.expandArgument(this.name, false)
            .bindNull(TokenUtil.tokenListToName)
            .throwIfNull(new LaTeXError("invalid token while reading counter name"));
        var value = expP.readIntegerArgument(this.name);
        processor.getGlobal().addToNamedCounter(counterName, value);
    }
}
class StepcounterCommand implements ExecutableCommand<IExecutionProcessor>
{
    var name: TokenValue;
    public function new()
    {
        this.name = ControlSequence("stepcounter");
    }
    public function execute(processor: IExecutionProcessor)
    {
        var expP = processor.getExpansionProcessor();
        var counterName = expP.expandArgument(this.name, false)
            .bindNull(TokenUtil.tokenListToName)
            .throwIfNull(new LaTeXError("invalid token while reading counter name"));
        processor.getGlobal().stepNamedCounter(counterName);
    }
}
class RefstepcounterCommand implements ExecutableCommand<IExecutionProcessor>
{
    var name: TokenValue;
    public function new()
    {
        this.name = ControlSequence("refstepcounter");
    }
    public function execute(processor: IExecutionProcessor)
    {
        var expP = processor.getExpansionProcessor();
        var counterName = expP.expandArgument(this.name, false)
            .bindNull(TokenUtil.tokenListToName)
            .throwIfNull(new LaTeXError("invalid token while reading counter name"));
        processor.getGlobal().stepNamedCounter(counterName);
        // TODO: define \@currentreference
    }
}
class AddtoresetCommand implements ExecutableCommand<IExecutionProcessor>
{
    var name: TokenValue;
    public function new()
    {
        this.name = ControlSequence("@addtoreset");
    }
    public function execute(processor: IExecutionProcessor)
    {
        var expP = processor.getExpansionProcessor();
        var counterName = expP.expandArgument(this.name, false)
            .bindNull(TokenUtil.tokenListToName)
            .throwIfNull(new LaTeXError("invalid token while reading counter name"));
        var within = expP.expandArgument(this.name, false)
            .bindNull(TokenUtil.tokenListToName)
            .throwIfNull(new LaTeXError("invalid token while reading counter name"));
        processor.getGlobal().addToReset(counterName, within);
    }
}
class ArabicCommand implements ExpandableCommand
{
    var name: TokenValue;
    public function new()
    {
        this.name = ControlSequence("arabic");
    }
    public function expand(processor: IExpansionProcessor): Array<Token>
    {
        var counterName = processor.expandArgument(this.name, false)
            .bindNull(TokenUtil.tokenListToName)
            .throwIfNull(new LaTeXError("invalid token while reading counter name"));
        var value = processor.getGlobal().getNamedCounterValue(counterName);
        return TokenUtil.stringToTokenList("" + value);
    }
}
class InternalArabicCommand implements ExpandableCommand
{
    var name: TokenValue;
    public function new()
    {
        this.name = ControlSequence("@arabic");
    }
    public function expand(processor: IExpansionProcessor): Array<Token>
    {
        var value = processor.readIntegerArgument(this.name);
        return TokenUtil.stringToTokenList("" + value);
    }
}
class RomanCommand implements ExpandableCommand
{
    var name: TokenValue;
    var uppercase: Bool;
    public function new(name: TokenValue, uppercase: Bool)
    {
        this.name = name;
        this.uppercase = uppercase;
    }
    public function expand(processor: IExpansionProcessor): Array<Token>
    {
        var counterName = processor.expandArgument(this.name, false)
            .bindNull(TokenUtil.tokenListToName)
            .throwIfNull(new LaTeXError("invalid token while reading counter name"));
        var value = processor.getGlobal().getNamedCounterValue(counterName);
        var s = RomannumeralCommand.toRomanNumeral(value);
        if (this.uppercase) s = s.toUpperCase();
        return TokenUtil.stringToTokenList(s);
    }
}
class AlphCommand implements ExpandableCommand
{
    var name: TokenValue;
    var uppercase: Bool;
    public function new(name: TokenValue, uppercase: Bool)
    {
        this.name = name;
        this.uppercase = uppercase;
    }
    public function expand(processor: IExpansionProcessor): Array<Token>
    {
        var counterName = processor.expandArgument(this.name, false)
            .bindNull(TokenUtil.tokenListToName)
            .throwIfNull(new LaTeXError("invalid token while reading counter name"));
        var value = processor.getGlobal().getNamedCounterValue(counterName);
        return TokenUtil.stringToTokenList(toAlph(value, this.uppercase));
    }
    static function toAlph(value: Int, uppercase: Bool): String
    {
        if (value > 26) {
            throw new LaTeXError("Counter too large");
        } else if (value < 0) {
            throw new LaTeXError("Counter too small");
        } else if (value == 0) {
            return "";
        } else {
            return String.fromCharCode((uppercase ? 'A' : 'a').charCodeAt(0) + value - 1);
        }
    }
}
class CounterCommands
{
    public static function defineCounterCommands(scope: TDefiningScope<IExecutionProcessor>)
    {
        scope.defineExecutableCommandT(ControlSequence("newcounter"), new NewcounterCommand());
        scope.defineExecutableCommandT(ControlSequence("setcounter"), new SetcounterCommand());
        scope.defineExecutableCommandT(ControlSequence("addtocounter"), new AddtocounterCommand());
        scope.defineExecutableCommandT(ControlSequence("stepcounter"), new StepcounterCommand());
        scope.defineExecutableCommandT(ControlSequence("refstepcounter"), new RefstepcounterCommand());
        scope.defineExecutableCommandT(ControlSequence("@addtoreset"), new AddtoresetCommand());
        scope.defineExpandableCommand(ControlSequence("arabic"), new ArabicCommand());
        scope.defineExpandableCommand(ControlSequence("@arabic"), new InternalArabicCommand());
        scope.defineExpandableCommand(ControlSequence("roman"), new RomanCommand(ControlSequence("roman"), false));
        scope.defineExpandableCommand(ControlSequence("Roman"), new RomanCommand(ControlSequence("Roman"), true));
        scope.defineExpandableCommand(ControlSequence("alph"), new AlphCommand(ControlSequence("alph"), false));
        scope.defineExpandableCommand(ControlSequence("Alph"), new AlphCommand(ControlSequence("Alph"), true));
        // TODO: \fnsymbol
    }
}
