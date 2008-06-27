TARGETS=cu-rules.csv grc-rules.csv la-rules.csv la-generated.csv cu-normalisation.ca cu-orthographics.ca cu.ca

all: $(TARGETS)
	make -C class_morphology

%.a: %.fst
	fst-compiler $< $@

%.ca: %.fst
	fst-compiler -c $< $@

cu.fst: cu.xml class_morphology.rb class_morphology/*
	ruby -I.. class_morphology.rb cu.xml cu.fst

clean:
	rm -f $(TARGETS)
	rm -f *.db

la-rules.csv: derive la-rules.dat
	ruby -I.. derive la la-rules.dat | sort > $@ 

cu-rules.csv: derive cu-rules.dat
	ruby -I.. derive cu cu-rules.dat | sort > $@ 

grc-rules.csv: derive grc-rules.dat
	ruby -I.. derive --caseless grc grc-rules.dat | sort > $@

la-generated.csv: perseus-blacklist derive-generated ../../data/morph-la-open.csv 
	./derive-generated ../../data/morph-la-open.csv | sort > $@

test: cu.ca
	fst-infl2 cu.ca < test.txt > test.tmp && diff -u test.tmp test.exp
