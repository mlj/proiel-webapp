require 'ar-extensions'

class BatchImport < Array
  def initialize(model, limit, columns, cb)
    @model = model
    @limit = limit
    @columns = columns
    @cb = cb
  end

  def <<(e)
    super

    if self.length == @limit
      import
      self.clear
    end
  end

  def flush
    import
  end

  private
  
  def import
    @cb.call(self)
    @model.import(@columns, self, { :validate => false})
  end
end
