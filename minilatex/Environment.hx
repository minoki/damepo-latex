package minilatex;
import minilatex.Token;
import minilatex.ExpansionProcessor;
import minilatex.ExecutionProcessor;
import minilatex.Error;
import minilatex.Command;
import minilatex.Scope;
using Command.ScopeExtender;
using ExpansionProcessor.ExpansionProcessorUtil;
using Util.NullExtender;
using Token.TokenUtil;
class NewenvironmentCommand implements ExecutableCommand
{
    var rxEnvironmentName: EReg;
    var name: String;
    public function new(name: String = "\\newenvironment")
    {
        this.rxEnvironmentName = ~/^(?!end)[a-zA-Z0-9*]+$/;
        this.name = name;
    }
    public function doCommand(processor: ExecutionProcessor)
    {
        var expansionProcessor = processor.expansionProcessor;
        var isLong = !expansionProcessor.hasStar();
        var name = expansionProcessor.expandArgument()
            .bindNull(TokenUtil.tokenListToName)
            .throwIfNull(new LaTeXError("invalid token while reading the name of environment"));
        if (!this.rxEnvironmentName.match(name)) {
            throw new LaTeXError(this.name + ": invalid environment name");
        }
        var args = processor.expansionProcessor.expandOptionalArgument();
        var numberOfArguments = args == null ? 0 : TokenUtil.tokenListToInt(args)
            .throwIfNull(new LaTeXError(this.name + ": invalid number of arguments"));
        var opt = processor.expansionProcessor.readOptionalArgument();
        var beginDef = processor.expansionProcessor.readArgument();
        var endDef = processor.expansionProcessor.readArgument();
        var scope = processor.expansionProcessor.currentScope;
        if (this.shouldDefineEnvironment(scope, name)) {
            var beginCmdName = ControlSequence(name);
            var endCmdName = ControlSequence("end" + name);
            var beginCmd = new UserCommand(beginCmdName, numberOfArguments, opt, beginDef, isLong);
            var endCmd = new UserCommand(endCmdName, 0, null, endDef, false);
            scope.defineExpandableCommand(beginCmdName, beginCmd);
            scope.defineExpandableCommand(endCmdName, endCmd);
            scope.defineEnvironment(name);
        }
        return [];
    }
    public function shouldDefineEnvironment(scope: Scope, name: String)
    {
        if (scope.isEnvironmentDefined(name)) {
            throw new LaTeXError("\\newenvironment: environment '" + name + "' is already defined");
        } else if (scope.isCommandDefined(ControlSequence(name))) {
            throw new LaTeXError("\\newenvironment: environment '" + name + "' is already defined");
        } else {
            return true;
        }
    }
}
class RenewenvironmentCommand extends NewenvironmentCommand
{
    public function new()
    {
        super("\\renewenvironment");
    }
    public override function shouldDefineEnvironment(scope: Scope, name: String)
    {
        if (!scope.isEnvironmentDefined(name)) {
            throw new LaTeXError("\\renewenvironment: environment '" + name + "' is not defined");
        } else {
            return true;
        }
    }
}
class BeginEnvironmentCommand implements ExpandableCommand
{
    public function new()
    {
    }
    public function doExpand(processor: IExpansionProcessor)
    {
        var name = processor.expandArgument()
            .checkNoPar("\\begin")
            .bindNull(TokenUtil.tokenListToName)
            .throwIfNull(new LaTeXError("\\begin{}: invalid environment name"));
        if (!processor.getCurrentScope().isEnvironmentDefined(name)) {
            throw new LaTeXError("\\begin{}: environment '" + name + "' not found");
        }
        return [new Token(ControlSequence("<begin environment>"), null),
                new Token(ControlSequence(name), null),
                new Token(ControlSequence(name), null)
                ];
    }
}
class EndEnvironmentCommand implements ExpandableCommand
{
    public function new()
    {
    }
    public function doExpand(processor: IExpansionProcessor)
    {
        var name = processor.expandArgument()
            .checkNoPar("\\end")
            .bindNull(TokenUtil.tokenListToName)
            .throwIfNull(new LaTeXError("\\end{}: invalid environment name"));
        if (!processor.getCurrentScope().isEnvironmentDefined(name)) {
            throw new LaTeXError("\\end{}: environment '" + name + "' not found");
        }
        return [new Token(ControlSequence("end" + name), null),
                new Token(ControlSequence("<end environment>"), null),
                new Token(ControlSequence(name), null),
                ];
    }
}

class InternalBeginEnvironmentCommand implements ExecutableCommand
{
    public function new()
    {
    }
    public function doCommand(processor: ExecutionProcessor)
    {
        var name = switch (processor.expansionProcessor.nextToken().token.value) {
        case ControlSequence(name): name;
        default: throw new LaTeXError("\\begin: internal error");
        };
        processor.beginEnvironment(name);
        return [];
    }
}
class InternalEndEnvironmentCommand implements ExecutableCommand
{
    public function new()
    {
    }
    public function doCommand(processor: ExecutionProcessor)
    {
        var name = switch (processor.expansionProcessor.nextToken().token.value) {
        case ControlSequence(name): name;
        default: throw new LaTeXError("\\end: internal error");
        };
        processor.endEnvironment(name);
        return [];
    }
}
