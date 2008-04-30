require 'fastercsv'

#FIXME: in extensions.rb
def clamp(i, a, b)
  (i < a ? a : (i > b ? b : i))
end

def max(a, b)
  a > b ? a : b
end

def navigate_range(i, minimum, maximum)
  i = clamp(i, minimum, maximum)
  back = i > minimum ? i - 1 : nil
  fwd = i < maximum ? i + 1 : nil
  [i, back, fwd]
end

# Iterate elements and construct a hash based on pairs of [ key, value ] from
# the block. Example:
# 
#   (0..2).to_assoc_hash { |i| [ i, i * 2 ] }
#   => { 0 => 0, 1 => 2,  2 => 4 }
#
module Enumerable
  def to_assoc_hash
    Hash[*self.collect { |e| yield e }.flatten]
  end
end

# Read a CSV file with a header and output the contents as an array of hashes with keys named
# based on the field names (as symbols). It is a bad idea to use this on big
# files.
def csv_to_array(filename)
  csv = CSV::parse(File.open(filename, 'r') {|f| f.read })
  fields = csv.shift
  csv.collect do |record| 
    (0..(fields.length - 1)).to_assoc_hash { |i| [fields[i].to_sym, record[i].to_s] }
  end
end

def csv_to_array(filename)
  csv = FasterCSV.read(filename)
  fields = csv.shift
  csv.collect do |record| 
    (0..(fields.length - 1)).to_assoc_hash { |i| [fields[i].to_sym, record[i].to_s] }
  end
end

def csv_foreach(filename)
  FasterCSV::HeaderConverters[:mysymbol] = lambda { |h| h.to_sym }
  FasterCSV.foreach(filename, { :headers => true, :header_converters => :mysymbol }) do |e|
    yield e.to_hash
  end
end

def make_tag(element, attributes, indentation = 0)
  optional_attributes = attributes.keys.collect { |s| s.to_s }.sort.collect { |k| " #{k.gsub(/_/, '-')}='#{attributes[k.to_sym].to_s.gsub(/_/, '-')}'" }
  ' ' * indentation + "<#{element}#{optional_attributes}>" + yield + "</#{element}>"
end

# Memoises the result of a block by marshalling the return value
# from the block and saving it to a file, unless the result has 
# already been saved to the file. Useful for creating quick
# cache files for the result of time consuming operations. 
def marshalled_memoise(file_name)
  if File.exists?(file_name)
    obj = Marshal.load(File.open(file_name))
  else
    obj = yield
    File.open(file_name, 'w') { |f| Marshal.dump(obj, f) }
  end
  obj
end

