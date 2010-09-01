def remove_inflections
  language_tag = 'lat'
  analyzer = SFSTAnalyzer.new(language_tag, File.join(RAILS_ROOT, 'lib/morphology/lat.a'))

  language = Language.find_by_tag(language_tag)
  language.inflections.find_each do |i|
    c = analyzer.analyze(i.form)
    if c.include?(i.morph_features) and not i.manual_rule
      i.destroy
    end
  end
end
