all: texts.html morphology.html maintenance.html todo.html changelog.html known_issues.html

%.html: %.markdown notes.css
	pandoc -s -c notes.css $< > $@
