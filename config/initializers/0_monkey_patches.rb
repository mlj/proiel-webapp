# Monkey patch to avoid "All parts of a PRIMARY KEY must be NOT NULL; if you need NULL in a key, use UNIQUE instead"
# https://github.com/brianmario/mysql2/issues/784
class ActiveRecord::ConnectionAdapters::Mysql2Adapter
  NATIVE_DATABASE_TYPES[:primary_key] = "int(11) auto_increment PRIMARY KEY"
end

# Monkey patch active_support 3.2.22 for Ruby => 2.4.
# https://stackoverflow.com/questions/41703128/error-while-trying-to-load-the-gem-devise-activesupport-duration-cant-be-coe

# pulled from https://github.com/rails/rails/blob/v3.2.22.5/activesupport/lib/active_support/core_ext/numeric/time.rb
class Numeric
  def days
    ActiveSupport::Duration.new(24.hours * self, [[:days, self]])
  end
  alias :day :days

  def weeks
    ActiveSupport::Duration.new(7.days * self, [[:days, self * 7]])
  end
  alias :week :weeks

  def fortnights
    ActiveSupport::Duration.new(2.weeks * self, [[:days, self * 14]])
  end
  alias :fortnight :fortnights
end

# pulled from https://github.com/rails/rails/blob/v3.2.22.5/activesupport/lib/active_support/core_ext/integer/time.rb

class Integer
  def months
    ActiveSupport::Duration.new(30.days * self, [[:months, self]])
  end
  alias :month :months

  def years
    ActiveSupport::Duration.new(365.25.days * self, [[:years, self]])
  end
  alias :year :years
end

# Monkey patch arel 3.0.3 for Ruby => 2.4.
# https://stackoverflow.com/questions/44053672/simple-rails-app-error-cannot-visit-integer/44286212#44286212

module Arel
  module Visitors
    class DepthFirst < Arel::Visitors::Visitor
      alias :visit_Integer :terminal
    end

    class Dot < Arel::Visitors::Visitor
      alias :visit_Integer :visit_String
    end

    class ToSql < Arel::Visitors::Visitor
      alias :visit_Integer :literal
    end
  end
end
