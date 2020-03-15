#!/bin/sh
set -e

bundle exec bundle exec bin/proiel-webapp check

rm -f output/greek-nt.xml && bundle exec bin/proiel-webapp export text 1 output/greek-nt.xml
rm -f output/pl-am.xml && bundle exec bin/proiel-webapp export text 73 output/pl-am.xml

rm -f output/dependency_alignments.txt && bundle exec bin/proiel-webapp export dependency_alignments output/dependency_alignments.txt
rm -f output/inflections.txt && bundle exec bin/proiel-webapp export inflections output/inflections.txt
rm -f output/information_statuses.txt && bundle exec bin/proiel-webapp export information_statuses output/information_statuses.txt
rm -f output/morphology.txt && bundle exec bin/proiel-webapp export morphology output/morphology.txt
rm -f output/notes.txt && bundle exec bin/proiel-webapp export notes output/notes.txt
rm -f output/semantic_relations.txt && bundle exec bin/proiel-webapp export semantic_relations output/semantic_relations.txt
rm -f output/semantic_tags.txt && bundle exec bin/proiel-webapp export semantic_tags output/semantic_tags.txt
rm -f output/token_alignments.txt && bundle exec bin/proiel-webapp export token_alignments output/token_alignments.txt

exit

# inflections:             I E D       OK
# notes:                   I E D       OK
# information_statuses:    I E D       OK
# morphology:              I E D       OK
# semantic_relations:      I E D       OK
# semantic_tags:           I E D       OK
# token_alignments:        I E D       OK
# dependency_alignments    I E D       OK
# history                      D
# text (XML):              I E         Information loss

for task in $TASKS; do
  rm -f $task.csv

  bin/proiel-webapp export $task $task.csv.orig
  bin/proiel-webapp delete $task
  bin/proiel-webapp import $task $task.csv.orig
  bin/proiel-webapp export $task $task.csv

  sort $task.csv.orig >A
  sort $task.csv      >B
  diff A B
  rm A B
done
