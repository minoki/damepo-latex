all: test-neko test-js test-php

lib_src = \
 ../minilatex/Token.hx \
 ../minilatex/Tokenizer.hx \
 ../minilatex/Scope.hx \
 ../minilatex/ExpansionProcessor.hx \
 ../minilatex/ExecutionProcessor.hx \
 ../minilatex/Command.hx \
 ../minilatex/Error.hx \
 ../minilatex/Util.hx

test-neko: Main.hx $(lib_src)
	haxe -main Main -cp .. -x test

test-js: Main.hx $(lib_src)
	haxe -main Main -cp .. -js test.js -cmd "node test.js"

test-php: Main.hx $(lib_src)
	haxe -main Main -cp .. -php testphp -cmd "php testphp/index.php"

.PHONY: all test-neko test-js test-php
