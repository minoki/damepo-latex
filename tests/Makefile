all: test-neko test-js test-php

lib_src = \
 ../minilatex/Token.hx \
 ../minilatex/Tokenizer.hx \
 ../minilatex/Scope.hx \
 ../minilatex/ExpansionProcessor.hx \
 ../minilatex/ExecutionProcessor.hx \
 ../minilatex/Command.hx \
 ../minilatex/Environment.hx \
 ../minilatex/Error.hx \
 ../minilatex/Util.hx

test-neko: Main.hx $(lib_src)
	haxe -main Main -cp .. -x test

test-js: Main.hx $(lib_src)
	haxe -main Main -cp .. -js test.js -cmd "node test.js"

test-php: Main.hx $(lib_src)
	haxe -main Main -cp .. -php testphp -cmd "php testphp/index.php"

test-cpp: Main.hx $(lib_src)
	haxe -main Main -cp .. -cpp testcpp -cmd "testcpp/Main"

.PHONY: all test-neko test-js test-php test-cpp

RxPatternTest-neko:
	haxe -main RxPatternTest -cp .. -x RxPatternTest

RxPatternTest-js:
	haxe -main RxPatternTest -cp .. -js RxPatternTest.js -cmd "node RxPatternTest.js"

RxPatternTest-php:
	haxe -main RxPatternTest -cp .. -php RxPatternTest-php -cmd "php RxPatternTest-php/index.php"

RxPatternTest-cpp:
	haxe -main RxPatternTest -cp .. -cpp RxPatternTest-cpp -cmd "RxPatternTest-cpp/RxPatternTest"

RxPatternTest-java:
	haxe -main RxPatternTest -cp .. -java RxPatternTest-java -cmd "java -jar RxPatternTest-java/RxPatternTest.jar"

.PHONY: RxPatternTest-neko RxPatternTest-js RxPatternTest-php RxPatternTest-cpp RxPatternTest-java

