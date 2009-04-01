#!/usr/bin/env ruby
require 'proiel'

LANGUAGES = [:lat, :grc, :got, :xcl, :chu]

all_tags = LANGUAGES.map do |language|
  PROIEL::MorphTag.new.completions(language)
end.flatten.map(&:to_s).sort.uniq

all_tags.each do |tag|
  m = PROIEL::MorphTag.new(tag)
  f = [tag] + LANGUAGES.select { |language| m.is_valid?(language) }
  puts f.join(',')
end
