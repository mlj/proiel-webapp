class ChangesetsController < ResourceController::Base # ApplicationController
  before_filter :is_annotator?
  actions :all, :except => [ :new, :edit, :create, :update, :destroy ]

  private

  def collection
    @changesets = Changeset.search(params.slice(:user), params[:page])
  end
#--------------------------------------------------
# 
#   # GET /changesets
#   # GET /changesets.xml
#   def index
#     @changesets = Changeset.search(params.slice(:user), params[:page])
# 
#     respond_to do |format|
#       format.html # index.html.erb
#       format.xml  { render :xml => @changesets }
#     end
#   end
# 
#   # GET /changesets/1
#   # GET /changesets/1.xml
#   def show
#     @changeset = Changeset.find(params[:id])
# 
#     respond_to do |format|
#       format.html # show.html.erb
#       format.xml  { render :xml => @changeset }
#     end
#   end
#-------------------------------------------------- 
end
