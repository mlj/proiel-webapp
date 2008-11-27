all: cu-ascii.a got-ascii.a got-ascii-word.a grc-ascii.a grc-betacode.a
	
clean:
	rm -f *.a

%.a: %.fst
	fst-compiler-utf8 $< $@

got-ascii-word.a: got-ascii.a lgc-word-filter.a
