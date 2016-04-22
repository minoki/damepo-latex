all: index.js SimpleHTML.js

lib_src = \
 ../minilatex/Token.hx \
 ../minilatex/Tokenizer.hx \
 ../minilatex/Scope.hx \
 ../minilatex/ExpansionProcessor.hx \
 ../minilatex/ExecutionProcessor.hx \
 ../minilatex/Command.hx \
 ../minilatex/TeXPrimitive.hx \
 ../minilatex/Environment.hx \
 ../minilatex/TypesetCommand.hx \
 ../minilatex/SimpleHTMLProcessor.hx \
 ../minilatex/Error.hx \
 ../minilatex/Util.hx

index.js: TestPage.hx $(lib_src)
	haxe -main TestPage -js $@ -cp ..

SimpleHTML.js: SimpleHTML.hx $(lib_src)
	haxe -main SimpleHTML -js $@ -cp ..
