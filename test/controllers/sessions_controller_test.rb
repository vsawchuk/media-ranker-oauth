require "test_helper"

describe SessionsController do
  describe "login_form" do
    # The login form is a static page - no real way to make it fail
    it "succeeds" do
      get login_path
      must_respond_with :success
    end
  end

  describe "oauth" do
    let(:user) {users(:dan)}
    let(:other_user) {users(:kari)}

    it "creates a new user successfully" do
      new_user = User.new(username: "new user", email: "newuser@test.com", uid: 5, provider: "github")
      # Precondition: no user with this username exists
      User.find_by(username: new_user.username).must_be_nil
      proc{log_in(new_user, :github)}.must_change 'User.count', +1
      flash[:status].must_equal :success
      flash[:result_text].must_equal "Welcome #{new_user.username}"
      must_redirect_to root_path
    end

    it "succeeds for a returning user" do
      proc{log_in(user, user.provider.to_sym)}.must_change 'User.count', 0
      flash[:status].must_equal :success
      flash[:result_text].must_equal "Logged in successfully"
      must_redirect_to root_path
    end

    it "returns error message if the username is blank" do
      invalid_user = User.new(username: "", email: "newuser@test.com", uid: 5, provider: "github")
      log_in(invalid_user, invalid_user.provider.to_sym)
      must_respond_with :redirect
      flash[:status].must_equal :failure
      flash[:result_text].must_equal "Unable to save user"
    end

    it "succeeds if a different user is already logged in" do
      log_in(user, user.provider.to_sym)
      flash[:status].must_equal :success
      flash[:result_text].must_equal "Logged in successfully"
      must_redirect_to root_path

      log_in(other_user, other_user.provider.to_sym)
      flash[:status].must_equal :success
      flash[:result_text].must_equal "Logged in successfully"
      must_redirect_to root_path
    end
  end

  describe "logout" do
    it "succeeds if the user is logged in" do
      # Gotta be logged in first
      user = users(:dan)
      log_in(user, user.provider.to_sym)
      flash[:result_text].must_equal "Logged in successfully"
      must_redirect_to root_path

      post logout_path
      must_redirect_to root_path
      session[:user_id].must_equal nil
    end

    it "succeeds if the user is not logged in" do
      post logout_path
      must_redirect_to root_path
      session[:user_id].must_equal nil
    end
  end
end
