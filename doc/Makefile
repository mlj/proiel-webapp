all: texts.html morphology.html

%.html: %.markdown notes.css
	pandoc -s -c notes.css $< > $@
