#!/usr/bin/env ruby
#
# dictionary_loader.rb - Loads raw PROIEL dictionaries
#
# Written by Marius L. Jøhndal, 2008.
#
# $Id: $
#
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), 'lib')
require 'proiel'
require 'jobs'
require 'xmlsimple'

module PROIEL
  module Tools
    class DictionaryLoader 
      def initialize(args)
        if args.length < 1 
          raise "Invalid arguments: data_file [...]"
        end

        @dicts = {}
        for infile in args
          c = XmlSimple.xml_in(infile, { 
            'KeyAttr' => { 
              'entry' => 'id', 
            }
          })
          id = c['id']
          @dicts[id] = { :entries => c['entries'].first['entry'],
                         :header => c['header'].first.rekey { |key| key.to_sym }, }
        end
      end

      def source
        nil 
      end

      def audited?
        false 
      end

      def run!(logger, job)
        @dicts.each_pair do |id, data|
          # Look up this dictionary or create it if it is new
          d = Dictionary.find_by_identifier(id)
          if d
            # Reset all data for this dictionary
            DictionaryEntry.delete_all "dictionary_id = #{d.id}" 
          else
            d = Dictionary.create(data[:header].merge({ :identifier => id }))
            logger.info { "New dictionary #{id} created" }
          end

          data[:entries].each_pair do |entry_id, entry_data|
            DictionaryEntry.create(:dictionary => d, :identifier => entry_id,
                                   :data => entry_data['content'].strip)
          end
        end
      end
    end
  end
end
