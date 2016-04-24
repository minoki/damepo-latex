all: index.js SimpleHTML.js

closure-compiler-jar-candidates= \
 /usr/local/lib/node_modules/google-closure-compiler/compiler.jar \
 ~/node_modules/google-closure-compiler/compiler.jar
closure-compiler-jar= $(shell $(foreach jar,$(closure-compiler-jar-candidates),(test -f $(jar) && echo $(jar)) ||) echo compiler.jar)
closure-compiler= $(shell \
 (test -f $(closure-compiler-jar) && echo java -jar $(closure-compiler-jar)) \
 || which closure-compiler \
 || which closure)

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
 ../minilatex/Util.hx \
 ../minilatex/util/CharClass.hx \
 ../minilatex/util/CharSet.hx \
 ../minilatex/util/IntSet.hx \
 ../minilatex/util/RxPattern.hx \
 ../minilatex/util/UnicodeUtil.hx

index.js: TestPage.hx $(lib_src)
	haxe -main TestPage -js $@ -cp ..

SimpleHTML.js: SimpleHTML.hx $(lib_src)
	haxe -main SimpleHTML -js $@ -cp ..

%.min.js: %.js
	$(closure-compiler) --js $< --js_output_file $@
