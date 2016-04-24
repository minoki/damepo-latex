all: test-neko test-js test-php

test-neko:
	haxe -main Main -cp .. -x test

test-js:
	haxe -main Main -cp .. -js test.js -cmd "node test.js"

test-php:
	haxe -main Main -cp .. -php test-php -cmd "php test-php/index.php"

test-python:
	haxe -main Main -cp .. -python test.py -cmd "python3 test.py"

test-cpp:
	haxe -main Main -cp .. -cpp test-cpp -cmd "test-cpp/Main"

test-java:
	haxe -main Main -cp .. -java test-java -cmd "java -jar test-java/Main.jar"

.PHONY: all test-neko test-js test-python test-php test-cpp test-java

RxPatternTest-neko:
	haxe -main RxPatternTest -cp .. -x RxPatternTest

RxPatternTest-js:
	haxe -main RxPatternTest -cp .. -js RxPatternTest.js -cmd "node RxPatternTest.js"

RxPatternTest-php:
	haxe -main RxPatternTest -cp .. -php RxPatternTest-php -cmd "php RxPatternTest-php/index.php"

RxPatternTest-python:
	haxe -main RxPatternTest -cp .. -python RxPatternTest.py -cmd "python3 RxPatternTest.py"

RxPatternTest-cpp:
	haxe -main RxPatternTest -cp .. -cpp RxPatternTest-cpp -cmd "RxPatternTest-cpp/RxPatternTest"

RxPatternTest-java:
	haxe -main RxPatternTest -cp .. -java RxPatternTest-java -cmd "java -jar RxPatternTest-java/RxPatternTest.jar"

.PHONY: RxPatternTest-neko RxPatternTest-js RxPatternTest-python RxPatternTest-php RxPatternTest-cpp RxPatternTest-java

