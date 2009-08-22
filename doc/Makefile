all: morphology.html todo.html data_model.html

%.html: %.markdown notes.css
	pandoc -s -c notes.css $< > $@
