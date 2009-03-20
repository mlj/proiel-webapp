class Iso6393codes < ActiveRecord::Migration
  MAP = [
    [ 'lat', 'la' ],
    [ 'chu', 'cu' ],
    [ 'xcl', 'hy' ],
  ]

  def self.up
    MAP.each do |to, from|
      execute("UPDATE languages SET iso_code = '#{to}' WHERE iso_code = '#{from}'");
    end
  end

  def self.down
    MAP.each do |from, to|
      execute("UPDATE languages SET iso_code = '#{to}' WHERE iso_code = '#{from}'");
    end
  end
end
