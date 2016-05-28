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
 ../minilatex/SimpleExecutionProcessor.hx \
 ../minilatex/command/Core.hx \
 ../minilatex/command/TeXPrimitive.hx \
 ../minilatex/command/Environment.hx \
 ../minilatex/command/TypesetCommand.hx \
 ../minilatex/SimpleHTMLProcessor.hx \
 ../minilatex/Error.hx \
 ../minilatex/Util.hx

haxeopt= -lib rxpattern -cp .. -dce full

index.js: TestPage.hx $(lib_src)
	haxe -main TestPage -js $@ $(haxeopt)

SimpleHTML.js: SimpleHTML.hx $(lib_src)
	haxe -main SimpleHTML -js $@ $(haxeopt)

%.min.js: %.js
	$(closure-compiler) --js $< --js_output_file $@
