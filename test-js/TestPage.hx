package;
import js.Browser;
import js.html.Element;
import js.html.TextAreaElement;
import minilatex.Token;
import minilatex.Tokenizer;
import minilatex.ExpansionProcessor;
import minilatex.ExecutionProcessor;
import minilatex.SimpleExecutionProcessor;
import minilatex.Error;
import minilatex.Command;

class TestPage
{
    private static function printResult(outputElement: Element, result: Array<ExecutionResult>)
    {
        for (t in result) {
            switch (t) {
            case Character(x):
                var e = Browser.document.createTextNode(x);
                outputElement.appendChild(e);
            case UnknownCommand(name):
                var textNode = Browser.document.createTextNode(name.toString());
                var spanElement = Browser.document.createElement("span");
                spanElement.appendChild(textNode);
                spanElement.className = "control-sequence";
                outputElement.appendChild(spanElement);
            case Group(children):
                outputElement.appendChild(Browser.document.createTextNode("{"));
                printResult(outputElement, children);
                outputElement.appendChild(Browser.document.createTextNode("}"));
            case AlignmentTab:
                outputElement.appendChild(Browser.document.createTextNode("&"));
            case Subscript:
                outputElement.appendChild(Browser.document.createTextNode("_"));
            case Superscript:
                outputElement.appendChild(Browser.document.createTextNode("^"));
            case MathShift:
                outputElement.appendChild(Browser.document.createTextNode("$"));
            case Space:
                var textNode = Browser.document.createTextNode("\u00A0");
                var spanElement = Browser.document.createElement("span");
                spanElement.appendChild(textNode);
                spanElement.className = "space";
                outputElement.appendChild(spanElement);
            }
        }
    }
    public static function main()
    {
        Browser.window.addEventListener("DOMContentLoaded", function() {
                var inputElement = cast Browser.document.getElementById("input");
                var compileButton = Browser.document.getElementById("compile");
                var outputElement = Browser.document.getElementById("output");
                compileButton.addEventListener("click", function() {
                        while (outputElement.hasChildNodes()) {
                            outputElement.removeChild(outputElement.firstChild);
                        }
                        try {
                            var tokenizer = new Tokenizer(inputElement.value);
                            var expansionProcessor = new ExpansionProcessor(tokenizer, DefaultScope.getDefaultScope(), 1000, 1000);
                            var executionProcessor = new SimpleExecutionProcessor(expansionProcessor);
                            var result = executionProcessor.processAll();
                            printResult(outputElement, result);
                        } catch (e: LaTeXError) {
                            Browser.window.alert(e.toString());
                        }
                    }, false);
            }, false);
    }
}
