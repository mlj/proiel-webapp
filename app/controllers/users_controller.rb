class UsersController < ApplicationController
  before_filter :is_administrator?
  skip_before_filter :login_required, :only => [ :new, :create, :activate ]
  skip_before_filter :is_administrator?, :only => [ :new, :create, :activate ]
  filter_parameter_logging :password

  before_filter :find_user, :only => [:suspend, :unsuspend, :destroy, :purge]
 
  DEFAULT_ROLE = Role.find_by_code('reader')

  def index
    @users = User.search(params.slice(:login), params[:page])
  end

  def new
    @user = User.new
  end

  def create
    cookies.delete :auth_token
    # protects against session fixation attacks, wreaks havoc with 
    # request forgery protection.
    # uncomment at your own risk
    # reset_session
    @user = User.new(params[:user])
    @user.role_id = DEFAULT_ROLE 
    @user.register! if @user.valid?
    if @user.errors.empty?
      flash[:notice] = "An e-mail has been sent to #{params[:user][:email]} for confirmation."
      redirect_to :action => 'new'
    else
      render :action => 'new'
    end
  end

  def show
    @user = User.find(params[:id])
  end

  def edit
    @user = User.find(params[:id])
  end

  def update
    @user = User.find(params[:id])

    if @user.update_attributes(params[:user])
      #FIXME
      @user.role_id = params[:user][:role_id]
      @user.save!

      flash[:notice] = 'User was successfully updated.'
      redirect_to(@user)
    else
      render :action => "edit"
    end
  end

  def activate
    self.current_user = params[:activation_code].blank? ? false : User.find_by_activation_code(params[:activation_code])

    #if !current_user.crypted_password?
    #  if !params[:user][:password] or !params[:user][:password_confirmation]
    #    # Account has no password yet
    #    render :action => 'activate'
    #    return
    #  else
    #    self.current_user.update_attributes(params[:user].slice(:password, :password_confirmation))
    #  end
    #end

    if logged_in? && !current_user.active?
      current_user.activate!
      flash[:notice] = "Account activated."
    end
    redirect_back_or_default('/')
  end

  def suspend
    @user.suspend!
    redirect_to users_path
  end

  def unsuspend
    @user.unsuspend!
    redirect_to users_path
  end

  def destroy
    @user.delete!
    redirect_to users_path
  end

  def purge
    @user.destroy
    redirect_to users_path
  end

  protected

  def find_user
    @user = User.find(params[:id])
  end
end
