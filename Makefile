SOURCES=$(shell ls src/*.nim)
DATE=$(shell date +%Y-%m-%d)
#NIMC= /opt/nim/0.14.2/bin/nim --lib:/opt/nim/0.14.2/lib/
#NIMC= /opt/nim/0.15.0/nim/bin/nim --lib:/opt/nim/0.15.0/nim/lib/
NIMC= /opt/nim/0.15.0-test/nim/bin/nim --lib:/opt/nim/0.15.0-test/nim/lib/
#NIMC= /opt/nim/devel/nim/bin/nim --lib:/opt/nim/devel/nim/lib/
NIMC=nim

synth: $(SOURCES)
	${NIMC} c -d:release -o:$@ --threads:on --tlsEmulation:off src/main.nim

clang: $(SOURCES)
	${NIMC} cpp --cc:clang --verbosity:2 -d:release -o:$@ --threads:on --tlsEmulation:off src/main.nim

osx: $(SOURCES)
	${NIMC} c -d:osx -d:release -o:nimsynth.app/Contents/MacOS/nimsynth --threads:on --stackTrace:off --tlsEmulation:off src/main.nim
	rm nimsynth-${DATE}-osx.zip || true
	zip -r nimsynth-${DATE}-osx.zip nimsynth.app

windows: $(SOURCES)
	${NIMC} c -d:windows -d:release -o:windows/nimsynth.exe --threads:on --stackTrace:off --tlsEmulation:off src/main.nim
.PHONY: windows

synth-debug: $(SOURCES)
	${NIMC} c -d:debug --lineTrace:on --stackTrace:on -x:on --debugger:native -d:jack -o:$@ --tlsEmulation:off --threads:on src/main.nim

web: $(SOURCES)
	${NIMC} c -d:release -o:web/nimsynth.html --threads:on -d:emscripten src/main.nim

run: synth
	./synth

rund: synth-debug
	./synth-debug

.PHONY: web run rund osx windows
