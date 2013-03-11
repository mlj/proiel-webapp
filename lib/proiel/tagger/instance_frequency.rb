#--
#
# Copyright 2008, 2009, 2010, 2011, 2012, 2013 University of Oslo
# Copyright 2008, 2009, 2010, 2011, 2012, 2013 Marius L. Jøhndal
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

module Tagger
  class InstanceFrequencyMethod < TaggerAnalysisMethod
    def initialize(language, completion_level)
      super language
      @completion_level = completion_level
    end

    def analyze(form)
      rel = Token.includes(:lemma, :sentence).where(:form => form).where("lemmata.language_tag = ?", @language.to_s)

      case @completion_level
      when 'reviewed_only'
        rel = rel.where("sentences.reviewed_by IS NOT NULL")
      when 'annotated_only'
        rel = rel.where("sentences.annotated_by IS NOT NULL")
      when 'any'
      else
        raise "invalid completion level specified in tagger.yml"
      end

      x = rel.group(:lemma_id, :morphology_tag).count.map { |(l, m), f| [MorphFeatures.new(Lemma.find(l), m), f] }
      sum = x.map(&:last).sum
      x.map { |m, f| [m, f / sum.to_f] }
    end
  end
end
