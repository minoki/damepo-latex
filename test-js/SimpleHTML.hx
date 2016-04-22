package;
import js.Browser;
import js.html.Element;
import js.html.TextAreaElement;
import minilatex.Tokenizer;
import minilatex.Scope;
import minilatex.ExpansionProcessor;
import minilatex.Error;
import minilatex.SimpleHTMLProcessor;

class SimpleHTML
{
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
                            var expansionProcessor = new ExpansionProcessor(tokenizer, new Scope(null), 1000, 1000);
                            var executionProcessor = new SimpleHTMLProcessor(expansionProcessor);
			    executionProcessor.defineCommands();
			    while (executionProcessor.process()) {
			    }
                            var result = executionProcessor.toHTMLSource();
			    outputElement.innerHTML = result;
                        } catch (e: LaTeXError) {
                            Browser.window.alert(e.toString());
                        }
                    }, false);
            }, false);
    }
}
