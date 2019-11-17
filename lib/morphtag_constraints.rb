#--
#
# Copyright 2007, 2008, 2009, 2010 University of Oslo
# Copyright 2007, 2008 Marius L. Jøhndal
# Copyright 2010 Dag Haug
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

require 'singleton'

# Definition and test functions for constraints on morphtags.
# This is a singleton class and should be accessed using the
# +instance+ method.
class MorphtagConstraints
  include Singleton

  private

  def initialize
    @tag_spaces = {}
  end

  def make_tag_space(language)
    all_tags = []
    m = YAML.load_file(File.join('lib', 'morphtag_constraints', "#{language}_morphology.yml"))
    m[:constraints].each do |pos, pos_tagset|
      raise "Badly specified morphology for #{language}" unless pos_tagset[:mask] == MorphFeatures::MORPHOLOGY_PRESENTATION_SEQUENCE[0, pos_tagset[:mask].size]
      pos_tagset[:morphology].keys.each do |mask|
        vals = MorphFeatures::MORPHOLOGY_POSITIONAL_TAG_SEQUENCE.map do |f|
          if pos_tagset[:mask].include?(f)
            [mask[pos_tagset[:mask].index(f), 1]]# READ from the appropriate place in mask
          else
            case pos_tagset[:morphology][mask][f]
            when nil
              ['-']
            when :all
              m[:features][f]
            else
              pos_tagset[:morphology][mask][f]
            end
          end
        end
        all_tags += [pos].product(*vals).map(&:join)
      end
    end
    all_tags
  end

  public

  def tag_space(language)
    language = language.to_sym
    @tag_spaces[language] ||= make_tag_space(language)
  end

  # Tests if a morphtag is valid, i.e. that it does not violate
  # any of the specified constraints.
  def is_valid?(morphtag, language)
    tag_space(language).include?(morphtag)
  end
end
