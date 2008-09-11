class AuditsController < ResourceController::Base
  actions :all, :except => [:new, :create, :update]
  before_filter :is_annotator?
  before_filter :is_administrator?, :only => [:destroy]
  before_filter :find_parents

  destroy.before do
    raise "Object has been modified after this revision" unless @audit.latest_revision_of_auditable?

    o = @audit.previous_revision_of_auditable
    raise "Unable to revert: resulting object state is invalid" unless o.valid?
    o.without_auditing { o.save! }
  end

  private

  def object
    @change = Audit.find(params[:id])
  end

  def collection
    @changes = (@parent ? @parent.audits : Audit).search(params[:query], :page => current_page)
  end

  protected

  def find_parents
    @parent = @user = User.find(params[:user_id]) unless params[:user_id].blank?
  end
end
