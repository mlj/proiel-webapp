rule '.a' => ['.fst'] do |t|
  sh "cd #{Rails.root.join('lib', 'transliterations')} && fst-compiler-utf8 #{t.source} #{t.name}" 
end

TRANSLITERATION_FILES = %w{
  chu-ascii.a
  got-ascii.a
  lgc-word-filter.a
  got-ascii-word.a
  grc-ascii.a
  grc-betacode.a
  grc-simple.a
}.map { |f| Rails.root.join('lib', 'transliterations', f) }

desc 'Generate transliteration FSTs'
task :make_fsts => TRANSLITERATION_FILES do
end



