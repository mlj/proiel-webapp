#!/usr/bin/env ruby
#
# form_list.rb - Word form list manipulation functions
#
# Written by Marius L. Jøhndal, 2008.
#
module PROIEL
  class FormListReader
    def initialize(file_name)
      @f = File.open(file_name)
    end

    def each_entry(language)
      @f.each_line do |l|
        l.chomp!
        form_language, form, *analyses = l.split(/,\s*/)
        next unless form_language == language.to_s
        yield form, analyses
      end
    end
  end

  class FormListWriter
    def initialize(file_name)
      @f = File.open(file_name, 'w')
    end

    def add_entry(language, form, *analyses)
      unless analyses.empty?
        fields = [language, form] + analyses.sort
        line = fields.join(',')
        @f.puts line
      end
    end
  end
end

