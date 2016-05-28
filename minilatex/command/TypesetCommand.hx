package minilatex.command;
import minilatex.Scope;
import minilatex.ExecutionProcessor;
class CharCommand implements ExecutableCommand<ITypesetExecutionProcessor>
{
    var value: String;
    public function new(value: String)
    {
        this.value = value;
    }
    public function execute(processor: ITypesetExecutionProcessor)
    {
        processor.typesetChar(this.value);
    }
}
class TypesetCommand
{
    public static function defineStandardTypesetCommands(scope: TDefiningScope<ITypesetExecutionProcessor>)
    {
        scope.defineExecutableCommandT(ControlSequence("$"), new CharCommand("$"));
        scope.defineExecutableCommandT(ControlSequence("&"), new CharCommand("&"));
        scope.defineExecutableCommandT(ControlSequence("%"), new CharCommand("%"));
        scope.defineExecutableCommandT(ControlSequence("#"), new CharCommand("#"));
        scope.defineExecutableCommandT(ControlSequence("_"), new CharCommand("_"));
        scope.defineExecutableCommandT(ControlSequence("{"), new CharCommand("}"));
        scope.defineExecutableCommandT(Active("~"), new CharCommand("\u00A0")); // non-breaking space
        scope.defineExecutableCommandT(ControlSequence("OE"), new CharCommand("\u0152"));
        scope.defineExecutableCommandT(ControlSequence("oe"), new CharCommand("\u0153"));
        scope.defineExecutableCommandT(ControlSequence("AE"), new CharCommand("\u00C6"));
        scope.defineExecutableCommandT(ControlSequence("ae"), new CharCommand("\u00E6"));
        scope.defineExecutableCommandT(ControlSequence("AA"), new CharCommand("\u00C5"));
        scope.defineExecutableCommandT(ControlSequence("aa"), new CharCommand("\u00E5"));
        scope.defineExecutableCommandT(ControlSequence("O"), new CharCommand("\u00D8"));
        scope.defineExecutableCommandT(ControlSequence("o"), new CharCommand("\u00F8"));
        scope.defineExecutableCommandT(ControlSequence("L"), new CharCommand("\u0141"));
        scope.defineExecutableCommandT(ControlSequence("l"), new CharCommand("\u0142"));
        scope.defineExecutableCommandT(ControlSequence("ss"), new CharCommand("\u00DF"));
        scope.defineExecutableCommandT(ControlSequence("dag"), new CharCommand("\u2020"));
        scope.defineExecutableCommandT(ControlSequence("ddag"), new CharCommand("\u2021"));
        scope.defineExecutableCommandT(ControlSequence("S"), new CharCommand("\u00A7"));
        scope.defineExecutableCommandT(ControlSequence("P"), new CharCommand("\u00B6"));
        scope.defineExecutableCommandT(ControlSequence("copyright"), new CharCommand("\u00A9"));
        scope.defineExecutableCommandT(ControlSequence("pounds"), new CharCommand("\u00A3"));
    }
}
