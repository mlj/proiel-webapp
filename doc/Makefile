all: texts.html morphology.html maintenance.html

%.html: %.markdown notes.css
	pandoc -s -c notes.css $< > $@
