package minilatex.command;
import minilatex.Token;
import minilatex.Command;
import minilatex.ExpansionProcessor;
import minilatex.ExecutionProcessor;
import minilatex.Error;
import minilatex.command.Core;
import minilatex.Scope;
using Core.ScopeExtender;
using ExpansionProcessor.ExpansionProcessorUtil;
using Util.NullExtender;
using Token.TokenValueExtender;
using Token.TokenUtil;
class NewenvironmentCommand implements ExecutableCommand<IExecutionProcessor>
{
    var rxEnvironmentName: EReg;
    var name: TokenValue;
    public function new(name = "newenvironment")
    {
        this.rxEnvironmentName = ~/^(?!end)[a-zA-Z0-9*]+$/;
        this.name = ControlSequence(name);
    }
    public function execute(processor: IExecutionProcessor)
    {
        var expansionProcessor = processor.getExpansionProcessor();
        var isLong = !expansionProcessor.hasStar();
        var name = expansionProcessor.expandArgument(this.name, false)
            .bindNull(TokenUtil.tokenListToName)
            .throwIfNull(new LaTeXError("invalid token while reading the name of environment"));
        if (~/^end/.match(name)) {
            throw new LaTeXError("environment name must not start with 'end'");
        }
        if (!this.rxEnvironmentName.match(name)) {
            throw new LaTeXError(this.name.toString() + ": invalid environment name");
        }
        var args = expansionProcessor.expandOptionalArgument(this.name, false);
        var numberOfArguments = args == null ? 0 : TokenUtil.tokenListToInt(args)
            .throwIfNull(new LaTeXError(this.name.toString() + ": invalid number of arguments"));
        var opt = expansionProcessor.readOptionalArgument(this.name, true);
        var beginDef = expansionProcessor.readArgument(this.name, true);
        var endDef = expansionProcessor.readArgument(this.name, true);
        var scope = expansionProcessor.getCurrentScope();
        if (this.shouldDefineEnvironment(scope, name)) {
            var beginCmdName = ControlSequence(name);
            var endCmdName = ControlSequence("end" + name);
            var beginCmd = new UserCommand(beginCmdName, numberOfArguments, opt, beginDef, isLong);
            var endCmd = new UserCommand(endCmdName, 0, null, endDef, false);
            scope.defineExpandableCommand(beginCmdName, beginCmd);
            scope.defineExpandableCommand(endCmdName, endCmd);
            scope.defineEnvironment(name);
        }
    }
    public function shouldDefineEnvironment(scope: IScope, name: String)
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
        super("renewenvironment");
    }
    public override function shouldDefineEnvironment(scope: IScope, name: String)
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
    public function expand(processor: IExpansionProcessor)
    {
        var name = processor.expandArgument(ControlSequence("begin"), false)
            .bindNull(TokenUtil.tokenListToName)
            .throwIfNull(new LaTeXError("\\begin{}: invalid environment name"));
        if (!processor.getCurrentScope().isEnvironmentDefined(name)) {
            throw new LaTeXError("\\begin{}: environment '" + name + "' not found");
        }
        return [new Token(BeginGroup('{'), null),
                new Token(InternalBeginEnvironmentCommand.commandName, null),
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
    public function expand(processor: IExpansionProcessor)
    {
        var name = processor.expandArgument(ControlSequence("end"), false)
            .bindNull(TokenUtil.tokenListToName)
            .throwIfNull(new LaTeXError("\\end{}: invalid environment name"));
        if (!processor.getCurrentScope().isEnvironmentDefined(name)) {
            throw new LaTeXError("\\end{}: environment '" + name + "' not found");
        }
        return [new Token(ControlSequence("end" + name), null),
                new Token(InternalEndEnvironmentCommand.commandName, null),
                new Token(ControlSequence(name), null),
                new Token(EndGroup('}'), null)
                ];
    }
}

class InternalBeginEnvironmentCommand implements ExecutableCommand<IExecutionProcessor>
{
    public function new()
    {
    }
    public static var commandName = ControlSequence("<begin environment>");
    public function execute(processor: IExecutionProcessor)
    {
        var name = switch (processor.getExpansionProcessor().nextToken().token.value) {
        case ControlSequence(name): name;
        default: throw new LaTeXError("\\begin: internal error");
        };
        processor.beginEnvironment(name);
    }
}
class InternalEndEnvironmentCommand implements ExecutableCommand<IExecutionProcessor>
{
    public function new()
    {
    }
    public static var commandName = ControlSequence("<end environment>");
    public function execute(processor: IExecutionProcessor)
    {
        var name = switch (processor.getExpansionProcessor().nextToken().token.value) {
        case ControlSequence(name): name;
        default: throw new LaTeXError("\\end: internal error");
        };
        processor.endEnvironment(name);
    }
}
