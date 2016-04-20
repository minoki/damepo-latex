all: index.js

lib_src = \
 ../minilatex/Token.hx \
 ../minilatex/Tokenizer.hx \
 ../minilatex/Scope.hx \
 ../minilatex/ExpansionProcessor.hx \
 ../minilatex/ExecutionProcessor.hx \
 ../minilatex/Command.hx \
 ../minilatex/Error.hx \
 ../minilatex/Util.hx

index.js: TestPage.hx $(lib_src)
	haxe -main TestPage -js $@ -cp ..
