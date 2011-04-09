#--
#
# Copyright 2008, 2009, 2010, 2011 University of Oslo
# Copyright 2008, 2009, 2010, 2011 Marius L. Jøhndal
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
    def initialize(language)
      super(language)
    end

    def analyze(form)
      x = Token.count(:all,
                      :include => [:lemma, :sentence],
                      :conditions => ['form = ? AND lemmata.language = ? AND sentences.reviewed_by IS NOT NULL',
                        form, @language.to_s],
                      :group => [:lemma_id, :morphology]).map { |(l, m), f| [MorphFeatures.new(Lemma.find(l), m), f] }
      sum = x.map(&:last).sum
      x.map { |m, f| [m, f / sum.to_f] }
    end
  end
end
