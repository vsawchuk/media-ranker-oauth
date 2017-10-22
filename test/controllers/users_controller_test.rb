require 'test_helper'

describe UsersController do
  describe "index" do
    it "succeeds with many users" do
      log_in(users(:dan), users(:dan).provider.to_sym)
      # Assumption: there are many users in the DB
      User.count.must_be :>, 0

      get users_path
      must_respond_with :success
    end

    it "succeeds with one user" do #will never be able to access this page without a user since you must be logged in
      # Start with a clean slate
      Vote.destroy_all # for fk constraint
      Work.destroy_all # for fk constraint
      User.destroy_all
      User.create(username: "test", email: "test@email.com", uid: 1, provider: "github")
      log_in(User.first, User.first.provider.to_sym)

      get users_path
      must_respond_with :success
    end
  end

  describe "show" do
    it "succeeds for an extant user" do
      log_in(users(:dan), users(:dan).provider.to_sym)
      get user_path(User.first)
      must_respond_with :success
    end

    it "renders 404 not_found for a bogus user" do
      log_in(users(:dan), users(:dan).provider.to_sym)
      # User.last gives the user with the highest ID
      bogus_user_id = User.last.id + 1
      get user_path(bogus_user_id)
      must_respond_with :not_found
    end
  end
end
