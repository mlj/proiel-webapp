#--
#
# source.rb - PROIEL source file manipulation functions
#
# Copyright 2007, 2008, 2009, 2010 University of Oslo
# Copyright 2007, 2008, 2009, 2010 Marius L. Jøhndal
#
# This file is part of the PROIEL web application.
#
# The PROIEL web application is free software: you can redistribute it
# and/or modify it under the terms of the GNU General Public License
# version 2 as published by the Free Software Foundation.
#
# The PROIEL web application is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with the PROIEL web application.  If not, see
# <http://www.gnu.org/licenses/>.
#
#++
require 'unicode'
require 'open-uri'
require 'nokogiri'

module PROIEL
  class LegacySource
    def initialize(uri)
      @doc = Nokogiri::XML(open(uri))

      @metadata = {}

      t = @doc.at("text")
      @metadata[:id] = t.attributes["id"]
      @metadata[:language] = t.attributes["lang"]
      @metadata[:filename] = uri
    end


    def self.escape(string)
      string.gsub('&', '&amp;').gsub('<', '&lt;').gsub('>', '&gt;')
    end


    # Returns the meta-data for the source. The meta-data is returned
    # as a hash with keys corresponding to elements in the meta-data
    # header, and including the source identifier, language tag
    # and filename.
    attr_reader :metadata

    def read_tokens(tracked_references, options = {})

      (@doc/:text/:source_division).each do |sd|
        ref_fields = tracked_references.values.flatten.inject({}) { |res, u| res[u] = nil; res }

        sd_title = sd.attributes["title"] 
        sd_abbreviated_title = sd.attributes["abbreviated_title"]
        sd_abbreviated_title ||= sd_title
        sd_presentation = []
        # get the relevant reference fields, noting which ones changed
        if tracked_references["source_division"]
          tracked_references["source_division"].each { |tr| raise "Missing reference_field #{tr}" unless sd.attributes.has_key?(tr) }
          changes = sd.attributes.slice(*tracked_references["source_division"]).inject({}) { |m, v| m[v[0]] = v[1] if v[1] != ref_fields[v[0]] ; m }
          ref_fields.update(changes)
          sd_presentation[0] = (tracked_references["source_division"] & changes.keys).map { |u| "<milestone unit='#{u}' n='#{ref_fields[u]}'/>" }.join         
        end
        # start the first sentence with the milestones that changed
        
        (sd/:sentence).each_with_index do |s,i|
          sd_presentation[i] ||= ""
          # get the relevant reference fields, noting which ones changed
          if tracked_references["sentence"]
            tracked_references["sentence"].each { |tr| raise "Missing reference_field #{tr}" unless s.attributes.has_key?(tr) } 
            changes = s.attributes.slice(*tracked_references["sentence"]).inject({}) { |m, v| m[v[0]] = v[1] if v[1] != ref_fields[v[0]] ; m }
            ref_fields.update(changes)
            sd_presentation[i] += (tracked_references["sentence"] & changes.keys).map { |u| "<milestone unit='#{u}' n='#{ref_fields[u]}'/>" }.join
          end

          # Do a first iteration of tokens generating all the
          # information necessary for the creation of the sentence
          token_number = 0
          skip_tokens = 0
          
          (s/:token).each_with_index do |t, j|
            if skip_tokens > 0
              skip_tokens -= 1
              next
            end
            # get the relevant reference fields, noting which ones changed
            if tracked_references["token"]
              #puts t.inspect
              tracked_references["token"].each { |tr| raise "Missing reference_field #{tr}" unless t.attributes.has_key?(tr) } 
              changes = t.attributes.slice(*tracked_references["token"]).inject({}) { |m, v| m[v[0]] = v[1] if v[1] != ref_fields[v[0]] ; m }
              ref_fields.update(changes)
              sd_presentation[i] += (tracked_references["token"] & changes.keys).map { |u| "<milestone unit='#{u}' n='#{ref_fields[u]}'/>" }.join
            end
            
            case t.attributes["sort"]
            when "lacuna_start"
              sd_presentation[i] += '<gap/>'
            when "lacuna_end"
              sd_presentation[i] += '<gap/>'
            when "punctuation"
              case t.attributes["form"]
              when "["
                f = "<del>"
              when "]"
                f = "</del><s> </s>"
              when "<"
                f = "<add>"
              when ">"
                f = "</add><s> </s>"
              else
                f = "<pc>#{LegacySource.escape(t.attributes["form"])}</pc>"
                f += "<s> </s>" unless t.attributes["nospacing"] == "after"
              end
              sd_presentation[i] += f
            when "text"
              f = ""
              pure_segmentation = false
              if t.attributes["presentation-span"] 
                skip_tokens = t.attributes["presentation-span"].to_i - 1
              end
              
              # Tokens with presentation-form set
              if t.attributes["presentation-form"]
                # treat tokens without presentation-span set as having a span of 1
                span = t.attributes["presentation-span"].nil? ? 1 : t.attributes["presentation-span"].to_i
                case span
                when 1
                  f = "<corr sic='#{t.attributes["presentation-form"]}'>#{LegacySource.escape(t.attributes["form"])}</corr>"
                else
                  pure_segmentation = true if (s/:token).slice(j...(j + t.attributes["presentation-span"].to_i)).map { |tt| tt.attributes["form"] }.join == t.attributes["presentation-form"]

                  # If this is not pure segmentation we will be
                  # putting several tokens inside one <segmented>
                  # element and therefore need to check that there is
                  # no nesting
                  unless pure_segmentation
                    editorials =  ((s/:token).slice(j...(j + span)).map { |tt| tt.attributes["form"] }).select { |z| ["[", "]", "<", ">"].include?(z) }
                    STDOUT.puts "Warning: potential nesting" unless editorials.empty?
                    #raise "Nesting" unless editorials.count("[") == editorials.count("]") and editorials.count("<") == editorials.count(">")
                  end
                  # For now, use <seg> for tokens inside a resolution, since, unlike <w>'s they should be kept in the source division presentation. legacy_import.rb will then set the correct tags
                  f = "<segmented orig='#{t.attributes["presentation-form"]}'>" unless pure_segmentation
                  f += (s/:token).slice(j...(j + span)).map { |tt| "<seg>#{LegacySource.escape(tt.attributes["form"])}</seg>"}.join
                  f += "</segmented>" unless pure_segmentation
                end
                
                # Tokens without presentation-form  
              else
                f = "<w>#{LegacySource.escape(t.attributes["form"])}</w>"
              end
              
              raise "Token with sort = text should not have the nospacing attribute set" if t.attributes["nospacing"]
              
              # Add a space if appropriate
              f += "<s> </s>" if (s/:token).slice(j + 1) and not (s/:token).slice(j + 1).attributes["nospacing"] == 'before'
              sd_presentation[i] += f
            else
              raise "Invalid token sort #{t.attributes["sort"]}"
            end
          end
        end
        
        # next pass, sending tokenization
        
        (sd/:sentence).each_with_index do |s, i|
          ref_fields.update(s.attributes.slice(*tracked_references["sentence"]))

          first_token = true
          (s/:token).each_with_index do |t,j|
            ref_fields.update(t.attributes.slice(*tracked_references["token"]))

            if t.attributes["sort"] == "text"
              
              a = { :sentence_number => i, 
                :token_number => j + 1,
                :reference_fields => ref_fields, 
                :sd_title => sd_title,
                :sd_abbreviated_title => sd_abbreviated_title }
              a[:source_division_presentation] = sd_presentation if i == 0 and first_token
              a[:sentence_presentation] = sd_presentation[i] if first_token
              first_token = false
              
              (t/:notes/:note).each do |n|
                a[:notes] ||= []
                a[:notes] << { :origin => n.attributes['origin'], :contents => n.inner_html }
              end
              
              t.attributes.each_pair do |k, v|
                case k
                when 'form', 'references'
                  a[k.to_sym] = v
                when 'lemma'
                  a[:lemma] = [v, t.attributes["morphtag"][0,2]].join(",")
                when 'morphtag'
                  a[:morphtag] = v[2,MorphFeatures::MORPHOLOGY_LENGTH]
                  a[:morphtag] += "-" * (MorphFeatures::MORPHOLOGY_LENGTH - a[:morphtag].size)
                when 'foreign-ids'
                  a[:foreign_ids] = v
                when 'presentation-span', 'contraction', 'emendation', 'abbreviation', 'capitalisation', 'sort', 'nospacing', 'presentation-form', 'verse', 'chapter'
                when 'verse', 'section' #FIXME this should just be generated from tracked_references
                else
                  raise "Invalid source: token has unknown attribute #{k}"
                end
              end

              yield a[:form], a
            end
          end
        end
      end
    end
  end
end
