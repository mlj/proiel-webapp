class AuditsController < InheritedResources::Base
  actions :index, :show, :destroy

  before_filter :is_annotator?
  before_filter :is_administrator?, :only => [:destroy]
  before_filter :find_parents

  def destroy
    raise "Object has been modified after this revision" unless @audit.latest_revision_of_auditable?

    o = @audit.previous_revision_of_auditable
    raise "Unable to revert: resulting object state is invalid" unless o.valid?
    o.without_auditing { o.save! }

    destroy!
  end

  private

  def object
    @audit = Audit.find(params[:id])
  end

  def collection
    @audits = (@parent ? @parent.audits : Audit).search(params[:query], :page => current_page)
  end

  protected

  def find_parents
    @parent = @user = User.find(params[:user_id]) unless params[:user_id].blank?
  end
end
