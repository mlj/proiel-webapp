TARGETS=\
  cu.ca \
  cu-normalisation.ca \
  cu-orthographics.ca

all: $(TARGETS)
	make -C class_morphology

%.db: %.csv update_db
	ruby -I.. update_db $< $@

%.a: %.fst
	fst-compiler-utf8 -q $< $@

%.ca: %.fst
	fst-compiler-utf8 -q -c $< $@

cu.fst: cu.xml class_morphology.rb class_morphology/* cu-guesser.a
	ruby -I.. class_morphology.rb cu.xml cu.fst

clean:
	rm -f $(TARGETS)
	rm -f *.db

test: cu.ca
	fst-infl2 cu.ca < test.txt > test.tmp && diff -u test.tmp test.exp
