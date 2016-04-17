all: test-js test-neko

lib_src = \
 ../minilatex/Token.hx \
 ../minilatex/Tokenizer.hx \
 ../minilatex/Scope.hx \
 ../minilatex/ExpansionProcessor.hx \
 ../minilatex/ExecutionProcessor.hx \
 ../minilatex/Command.hx \
 ../minilatex/Error.hx

test.js: Main.hx $(lib_src)
	haxe -main Main -js $@ -cp ..

test-js: test.js
	node $<

test-neko: Main.hx $(lib_src)
	haxe -main Main -x test -cp ..

.PHONY: all test-js test-neko
