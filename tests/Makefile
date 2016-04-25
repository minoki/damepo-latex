all: test-neko test-js test-php

.PHONY: all

# $(call test-targets,<name>,<Main Class>)
define test-targets
$1-neko:
	haxe -main $2 -cp .. -x $1

$1-js:
	haxe -main $2 -cp .. -js $1.js -cmd "node $1.js"

$1-php:
	haxe -main $2 -cp .. -php $1-php -cmd "php $1-php/index.php"

$1-python:
	haxe -main $2 -cp .. -python $1.py -cmd "python3 $1.py"

$1-cpp:
	haxe -main $2 -cp .. -cpp $1-cpp -cmd "$1-cpp/$2"

$1-java:
	haxe -main $2 -cp .. -java $1-java -cmd "java -jar $1-java/$2.jar"

$1-cs:
	haxe -main $2 -cp .. -cs $1-cs

$1-all: $1-neko $1-js $1-php $1-python $1-cpp $1-java

.PHONY: $1-neko $1-js $1-php $1-python $1-cpp $1-java $1-cs
endef

$(eval $(call test-targets,test,Main))
$(eval $(call test-targets,UnicodeUtilTest,UnicodeUtilTest))
$(eval $(call test-targets,RxPatternTest,RxPatternTest))

