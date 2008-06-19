all: manual.csv generated.csv

manual.csv: derive la-rules.dat grc-rules.dat cu-rules.dat
	./derive la la-rules.dat | sort > manual.csv
	./derive cu cu-rules.dat | sort >> manual.csv
	./derive --caseless grc grc-rules.dat | sort >> manual.csv

generated.csv: perseus-blacklist derive-generated ../data/morph-la-open.csv 
	./derive-generated ../data/morph-la-open.csv | sort > generated.csv
