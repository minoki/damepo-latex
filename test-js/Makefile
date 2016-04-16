all: index.js

lib_src = \
 ../minilatex/Token.hx \
 ../minilatex/Tokenizer.hx \
 ../minilatex/Scope.hx \
 ../minilatex/Processor.hx \
 ../minilatex/Command.hx \
 ../minilatex/Error.hx

index.js: TestPage.hx $(lib_src)
	haxe -main TestPage -js $@ -cp ..
