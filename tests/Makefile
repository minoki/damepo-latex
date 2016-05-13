all: test-neko test-js test-php

.PHONY: all

haxeopt= -lib rxpattern -cp ..

# $(call test-targets,<name>,<Main Class>)
define test-targets
$1-neko:
	haxe -main $2 $(haxeopt) -x $1

$1-js:
	haxe -main $2 $(haxeopt) -js $1.js -cmd "node $1.js"

$1-php:
	haxe -main $2 $(haxeopt) -php $1-php -cmd "php $1-php/index.php"

$1-python:
	haxe -main $2 $(haxeopt) -python $1.py -cmd "python3 $1.py"

$1-lua:
	haxe -main $2 $(haxeopt) -lua $1.lua -cmd "lua $1.lua"

$1-cpp:
	haxe -main $2 $(haxeopt) -cpp $1-cpp -cmd "$1-cpp/$2"

$1-java:
	haxe -main $2 $(haxeopt) -java $1-java -cmd "java -jar $1-java/$2.jar"

$1-cs:
	haxe -main $2 $(haxeopt) -cs $1-cs

$1-all: $1-neko $1-js $1-php $1-python $1-cpp $1-java

.PHONY: $1-neko $1-js $1-php $1-python $1-lua $1-cpp $1-java $1-cs
endef

$(eval $(call test-targets,test,Main))

