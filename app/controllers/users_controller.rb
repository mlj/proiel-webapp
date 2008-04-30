require 'password_generator'
 
class UsersController < ApplicationController
  before_filter :is_administrator?
  skip_before_filter :login_required, :only => [ :activate ]
  skip_before_filter :is_administrator?, :only => [ :activate ]
  filter_parameter_logging :password

  # GET /users
  # GET /users.xml
  def index
    @users = User.search(params.slice(:login), params[:page])

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @users }
    end
  end

  def new
    @user = User.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @user }
    end
  end

  # POST /users
  # POST /users.xml
  def create
    cookies.delete :auth_token
    # protects against session fixation attacks, wreaks havoc with 
    # request forgery protection.
    # uncomment at your own risk
    # reset_session
    pw = Password.generate
    @user = User.new(params[:user].merge!({ :password => pw, :password_confirmation => pw}))

    respond_to do |format|
      if @user.save
        flash[:notice] = 'User was successfully created.'
        format.html { redirect_to(@user) }
        format.xml  { render :xml => @user, :status => :created, :location => @user }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end
  rescue ActiveRecord::RecordInvalid
    render :action => 'new'
  end

  def activate
    unless request.post?
      self.current_user = params[:activation_code].blank? ? :false : User.find_by_activation_code(params[:activation_code])
      if not logged_in? or current_user.activated?
        flash.now[:error] = "Activation failed!"
        redirect_to :controller => 'home'
      end
    else
      # Be specific about which attributes we update so that nobody sneaks
      # anything past us.
      if self.current_user.update_attributes!({ :password => params[:user][:password],
                                                :password_confirmation => params[:user][:password_confirmation]})
        current_user.activate
        flash.now[:notice] = 'Account successfully activated.'
        redirect_to :controller => 'home'
      end
    end
  rescue ActiveRecord::RecordInvalid
    @user = self.current_user
    render
  end

  def show
    @user = User.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @user }
    end
  end

  def edit
    @user = User.find(params[:id])
  end
  
  def update
    @user = User.find(params[:id])

    respond_to do |format|
      if @user.update_attributes(params[:user])
        #FIXME
        @user.role_id = params[:user][:role_id]
        @user.save!

        flash[:notice] = 'User was successfully updated.'
        format.html { redirect_to(@user) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end
  end
end
