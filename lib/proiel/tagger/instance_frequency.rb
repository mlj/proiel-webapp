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
      # Keep MIN(tokens.id) in the SELECT-clause to apease Oracle et al.
      x = Token.connection.select_all("SELECT MIN(tokens.id) AS token_id, count(*) AS frequency FROM tokens LEFT JOIN sentences ON sentence_id = sentences.id LEFT JOIN lemmata ON lemma_id = lemmata.id WHERE form = #{Token.sanitize(form)} AND lemmata.language = #{Token.sanitize(@language.to_s)} AND reviewed_by IS NOT NULL GROUP BY morphology, lemma_id", 'Token')
      sum = x.map { |i| i["frequency"].to_i }.sum.to_f
      x.map { |i| [Token.find(i["token_id"]).morph_features, i["frequency"].to_i / sum] }
    end
  end
end
