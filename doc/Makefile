all: morphology.html maintenance.html todo.html changelog.html known_issues.html data_model.html

%.html: %.markdown notes.css
	pandoc -s -c notes.css $< > $@
