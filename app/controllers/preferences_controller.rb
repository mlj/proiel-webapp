class PreferencesController < ApplicationController
  def edit
    @preferences = user_preferences
  end

  def update
    current_user.preferences_will_change!
    current_user.preferences = Hash[params[:preferences]].symbolize_keys # save as a regular Hash, not HashWithIndifferentAccess
    current_user.save!

    flash[:notice] = 'Preferences saved'
    redirect_to :action => 'edit'
  end
end
