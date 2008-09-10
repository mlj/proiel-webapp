require 'test/unit'

require 'rubygems'
gem 'activerecord', '>= 1.15.4.7794'
require 'active_record'
require 'active_support'

$KCODE = 'u'

require "#{File.dirname(__FILE__)}/../init"

ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :dbfile => ":memory:")

def setup_db
  ActiveRecord::Schema.define(:version => 1) do
    create_table :books, :force => true do |t|
      t.string :f1
      t.string :f2
      t.string :f3
    end
  end
end

def teardown_db
  ActiveRecord::Base.connection.tables.each do |table|
    ActiveRecord::Base.connection.drop_table(table)
  end
end

class ValidatedBooks < ActiveRecord::Base
  def self.table_name() "books" end

  validates_unicode_normalization_of :f1
  validates_unicode_normalization_of :f2, :form => :c
  validates_unicode_normalization_of :f3, :form => :c, :message => 'Bad title'
end

class UnicodeNormalizationValidationTest < Test::Unit::TestCase
  def setup
    setup_db
    @valid = ValidatedBooks.create! :f1 => 'ἐγκαλέω', :f2 => 'ἐγκαλέω', :f3 => 'ἐγκαλέω' # on NFC
    @valid_nil = ValidatedBooks.create! :f1 => nil, :f2 => 'ἐγκαλέω', :f3 => 'ἐγκαλέω' # on NFC
  end

  def teardown
    teardown_db
  end

  def test_nfc
    assert_equal true, @valid.valid?
  end

  def test_nil
    assert_equal true, @valid_nil.valid?
  end

  def test_non_nfc
    assert_raise ActiveRecord::RecordInvalid do
      @invalid = ValidatedBooks.create! :f1 => 'ἐγκαλέω', :f2 => 'ἐγκαλέω', :f3 => 'ἐγκαλέω' # not on NFC
    end
  end
end
