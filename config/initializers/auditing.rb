# Extend the Audit class from acts_as_audited with our standard search function.
class Audit
  protected

  def self.search(query, options = {})
    options[:order] ||= 'created_at DESC'

    paginate options
  end
end
