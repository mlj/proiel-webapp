class JobsController < ResourceController::Base # ApplicationController
  before_filter :is_annotator?
  actions :all, :except => [ :new, :edit, :create, :update, :destroy ]

  private

  def collection
    @jobs = Job.search(params.slice(:user), params[:page])
  end

#--------------------------------------------------
#   # GET /jobs
#   # GET /jobs.xml
#   def index
#     @jobs = Job.search(params.slice(:user), params[:page])
# 
#     respond_to do |format|
#       format.html # index.html.erb
#       format.xml  { render :xml => @jobs }
#     end
#   end
# 
#   # GET /jobs/1
#   # GET /jobs/1.xml
#   def show
#     @job = Job.find(params[:id])
# 
#     respond_to do |format|
#       format.html # show.html.erb
#       format.xml  { render :xml => @job }
#     end
#   end
#-------------------------------------------------- 
end
