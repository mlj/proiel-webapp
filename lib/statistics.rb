# encoding: UTF-8
#--
#
# Copyright 2014 Marius L. Jøhndal
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
  module Statistics
    def self.least_squares(x, y)
      raise ArgumentError, 'array lengths differ' unless x.size == y.size

      x_mean = x.reduce(&:+).to_f / x.size
      y_mean = y.reduce(&:+).to_f / y.size
      x_sqsum = x.reduce(0.0) { |sum, n| sum + n ** 2 }
      xy_sum = x.zip(y).reduce(0.0) { |sum, (m, n)| sum + m * n }

      sxy = xy_sum - x.length * x_mean * y_mean
      sx2 = x_sqsum - x.length * (x_mean ** 2)

      beta = sxy / sx2
      alfa = y_mean - beta * x_mean

      [alfa, beta]
    end
  end
end
