all: guide.html

%.html: %.mkd notes.css
	pandoc --toc -s -c notes.css $< > $@
