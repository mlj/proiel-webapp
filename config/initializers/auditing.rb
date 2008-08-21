# Extend the Audit class from acts_as_audited with our standard search function.
class Audit
  protected

  def self.search(query, options = {})
    options[:order] ||= 'created_at DESC'

    paginate options
  end

  public

  # Checks if this audit represents the auditable's lastest revision.
  def latest_revision_of_auditable?
    true
  end

  # Checks if the auditable's current state is consistent with the changes
  # in this audit.
  def consistent_with_auditable?
    true
  end

  # Reconstructs the auditable's state as per its previous revision.
  def previous_revision_of_auditable
    auditable.revision(:previous)
  end
end
