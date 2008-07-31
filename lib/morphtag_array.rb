require 'proiel/morphtag'

module PROIEL
  class MorphtagArray < Array
    private

    def set_field!(field, value)
      each { |t| t[field.to_sym] = value }
    end

    public

    def degree=(value) set_field!(:degree, value); end
    def number=(value) set_field!(:number, value); end
    def gender=(value) set_field!(:gender, value); end
    def tense=(value) set_field!(:tense, value); end
    def mood=(value) set_field!(:mood, value); end

    def clear_fields(*fields)
      n = MorphtagArray.new
      self.each { |tag| n << tag.dup }
      n.clear_fields!(*fields)
      n
    end

    def clear_fields!(*fields)
      fields.each { |field| set_field!(field, nil) }
    end

    def grep(pattern)
      map { |tag| tag.to_s }.grep(pattern)
    end

    def classify_by_pos
      classify { |tag| tag.pos_to_s }
    end

    def classify_by_non_pos
      classify { |tag| tag.non_pos_to_s }
    end

    def intersection
      Logos::PositionalTag::intersection(MorphTag, *self)
    end
  end
end
