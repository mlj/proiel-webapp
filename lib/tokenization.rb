# encoding: UTF-8
#--
#
# Copyright 2015 University of Oslo
# Copyright 2015 Marius L. Jøhndal
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

module Proiel
  module Tokenization
    def self.load_patterns
      file_name = Rails.root.join(Proiel::Application.config.tokenization_patterns_path)
      patterns = JSON.parse(File.read(file_name))

      # Create actual regex. We forcefully anchor the regexes to avoid partial
      # matches. We also allow multi-line matches in case peculiar characters
      # that are interpreted as line separators occur in the data.
      regexes = patterns.map { |language, pattern| [language, Regexp.new("^#{pattern}$", Regexp::MULTILINE)] }

      Hash[regexes]
    end
  end
end

TOKENIZATION_PATTERNS = Proiel::Tokenization.load_patterns.freeze
