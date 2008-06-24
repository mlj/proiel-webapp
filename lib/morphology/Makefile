TARGETS=cu-rules.csv grc-rules.csv la-rules.csv la-generated.csv

all: $(TARGETS)

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
