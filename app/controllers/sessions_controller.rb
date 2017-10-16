class SessionsController < ApplicationController
  skip_before_filter :determine_access, only: [:create, :login_form]

  def logout
    session[:user_id] = nil
    flash[:status] = :success
    flash[:result_text] = "Successfully logged out"
    redirect_to root_path
  end

  def login_form
    if @login_user
      flash[:status] = :failure
      flash[:result_text] = "You are already logged in"
      redirect_back(fallback_location: root_path)
    end
  end

  def create
    auth_hash = request.env['omniauth.auth']

    if auth_hash['uid']
      user = User.find_by(uid: auth_hash[:uid], provider: auth_hash['provider'])
      if user.nil?
        case auth_hash['provider']
          when 'google_oauth2'
            user = User.new(uid: auth_hash[:uid], provider: auth_hash[:provider], username: auth_hash[:info][:name], email: auth_hash[:info][:email])
          when 'github'
            user = User.new(uid: auth_hash[:uid], provider: auth_hash[:provider], username: auth_hash[:info][:nickname], email: auth_hash[:info][:email])
        end
        if user.save
          flash[:status] = :success
          flash[:result_text] = "Welcome #{user.username}"
        else
          flash[:status] = :failure
          flash[:result_text] = "Unable to save user"
        end
      else
        flash[:status] = :success
        flash[:result_text] = "Logged in successfully"
      end
      session[:user_id] = user.id
      redirect_to root_path
    else
      flash[:status] = :failure
      flash[:result_text] = "Could not log in"
      redirect_to root_path
    end
  end
end
