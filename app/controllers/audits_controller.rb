class AuditsController < InheritedResources::Base
  actions :index, :show, :destroy

  before_filter :is_annotator?
  before_filter :is_administrator?, :only => [:destroy]
  before_filter :find_parents

  def destroy
    @audit = Audit.find(params[:id])

    if @audit.auditable.audits.last == @audit
      o = @audit.auditable.revision(:previous)

      if o.valid?
        o.without_auditing { o.save! }
        destroy!
        flash[:notice] = 'Change was successfully reverted'
      else
        flash[:error] = 'Unable to revert: resulting object state is invalid'
      end
    else
      flash[:error] = "Object has been modified after this revision"
    end
  end

  private

  def object
    @audit = Audit.find(params[:id])
  end

  def collection
    @audits = (@parent ? @parent.audits : Audit).paginate :page => current_page
  end

  protected

  def find_parents
    @parent = @user = User.find(params[:user_id]) unless params[:user_id].blank?
  end
end
