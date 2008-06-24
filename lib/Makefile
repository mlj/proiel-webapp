all:
	make -C proiel
	make -C morphology

test:
	for f in proiel/*.rb tests/test_*.rb; do ruby $$f; done
