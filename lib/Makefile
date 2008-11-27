all:
	make -C proiel
	make -C morphology
	make -C transliterations

clean:
	make -C proiel clean
	make -C morphology clean
	make -C transliterations clean

test:
	for f in proiel/*.rb tests/test_*.rb; do ruby $$f; done
