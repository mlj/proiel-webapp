all:

%.db: %.csv update_db
	ruby -I.. update_db $< $@

clean:
	rm -f *.db
