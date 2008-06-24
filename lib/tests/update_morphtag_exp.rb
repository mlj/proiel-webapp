#!/usr/bin/env ruby
#

require 'proiel'
File.open(File.join(File.dirname(__FILE__), "update_morphtag_exp.txt")) do |f|
  f.each_line do |l|
    l.chomp!
    [:la, :grc, :got, :hy, :cy].each do |n|
      m = PROIEL::MorphTag.new(l)
      puts [l, n, m.is_valid?(n)].join(',')
    end
  end
end
