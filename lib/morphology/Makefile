TARGETS=\
  cu-rules.db \
  grc-rules.db \
  la-rules.db \
  got-rules.db \
  la-generated.db \
  got-generated.db \
  cu-normalisation.ca \
  cu-orthographics.ca

all: $(TARGETS)
	make -C class_morphology

%.db: %.csv
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

la-rules.csv: derive la-rules.dat
	ruby -I.. derive la la-rules.dat | sort > $@ 

got-rules.csv: derive got-rules.dat
	ruby -I.. derive got got-rules.dat | sort > $@

cu-rules.csv: derive cu-rules.dat
	ruby -I.. derive cu cu-rules.dat | sort > $@ 

grc-rules.csv: derive grc-rules.dat
	ruby -I.. derive --caseless grc grc-rules.dat | sort > $@

test: cu.ca
	fst-infl2 cu.ca < test.txt > test.tmp && diff -u test.tmp test.exp
