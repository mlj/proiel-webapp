all: morphtag_constraints.a

clean:
	rm -f morphtag_constraints.a

morphtag_constraints.a: morphtag_constraints.fst
	fst-compiler $< $@
