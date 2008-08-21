class AuditsController < ResourceController::Base
  actions :all, :except => [:new, :create, :update]
  before_filter :is_annotator?
  before_filter :is_administrator?, :only => [:destroy]

  destroy.before do
    raise "Object has been modified after this revision" unless @audit.latest_revision_of_auditable?
    raise "Object has been modified without revisioning" unless @audit.consistent_with_auditable?

    o = @audit.previous_revision_of_auditable
    raise "Unable to revert: resulting object state is invalid" unless o.valid?
    o.save!
  end

  private

  def object
    @change = Audit.find(params[:id])
  end

  def collection
    @changes = Audit.search(params[:query], :page => current_page)
  end
end
