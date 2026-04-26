regen: regen.c
	gcc -O2 regen.c -lm -o regen

all: regen
	for i in mk*; do ./$$i; done
	cp tfmix_*.txt ..

clean:
	-rm *.txt x y regen
