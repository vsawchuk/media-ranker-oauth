require 'test_helper'

describe WorksController do
  describe "root" do
    it "succeeds with all media types" do
      # Precondition: there is at least one media of each category
      %w(album book movie).each do |category|
        Work.by_category(category).length.must_be :>, 0, "No #{category.pluralize} in the test fixtures"
      end

      get root_path
      must_respond_with :success
    end

    it "succeeds with one media type absent" do
      # Precondition: there is at least one media in two of the categories
      %w(album book).each do |category|
        Work.by_category(category).length.must_be :>, 0, "No #{category.pluralize} in the test fixtures"
      end

      # Remove all movies
      Work.by_category("movie").destroy_all

      get root_path
      must_respond_with :success
    end

    it "succeeds with no media" do
      Work.destroy_all
      get root_path
      must_respond_with :success
    end
  end

  CATEGORIES = %w(albums books movies)
  INVALID_CATEGORIES = ["nope", "42", "", "  ", "albumstrailingtext"]

  describe "index" do
    before do
      user = users(:dan)
      log_in(user, user.provider.to_sym)
    end
    it "succeeds when there are works" do
      Work.count.must_be :>, 0, "No works in the test fixtures"
      get works_path
      must_respond_with :success
    end

    it "succeeds when there are no works" do
      Work.destroy_all
      get works_path
      must_respond_with :success
    end
  end

  describe "new" do
    it "works" do
      log_in(users(:dan), users(:dan).provider.to_sym)
      get new_work_path
      must_respond_with :success
    end
  end

  describe "create" do
    before do
      user = users(:dan)
      log_in(user, user.provider.to_sym)
    end
    it "creates a work with valid data for a real category" do
      work_data = {
        work: {
          title: "test work"
        }
      }
      CATEGORIES.each do |category|
        work_data[:work][:category] = category

        start_count = Work.count

        post works_path(category), params: work_data
        must_redirect_to work_path(Work.last)

        Work.count.must_equal start_count + 1
      end
    end

    it "renders bad_request and does not update the DB for bogus data" do
      work_data = {
        work: {
          title: ""
        }
      }
      CATEGORIES.each do |category|
        work_data[:work][:category] = category

        start_count = Work.count

        post works_path(category), params: work_data
        must_respond_with :bad_request

        Work.count.must_equal start_count
      end
    end

    it "renders 400 bad_request for bogus categories" do
      work_data = {
        work: {
          title: "test work"
        }
      }
      INVALID_CATEGORIES.each do |category|
        work_data[:work][:category] = category

        start_count = Work.count

        post works_path(category), params: work_data
        must_respond_with :bad_request

        Work.count.must_equal start_count
      end
    end
  end

  describe "show" do
    it "succeeds for an extant work ID" do
      user = users(:dan)
      log_in(user, user.provider.to_sym)
      get work_path(Work.first)
      must_respond_with :success
    end

    it "renders 404 not_found for a bogus work ID" do
      user = users(:dan)
      log_in(user, user.provider.to_sym)
      bogus_work_id = Work.last.id + 1
      get work_path(bogus_work_id)
      must_respond_with :not_found
    end
  end

  describe "edit" do
    before do
      user = users(:dan)
      log_in(user, user.provider.to_sym)
    end
    it "succeeds for an extant work ID" do
      get edit_work_path(Work.first)
      must_respond_with :success
    end

    it "renders 404 not_found for a bogus work ID" do
      bogus_work_id = Work.last.id + 1
      get edit_work_path(bogus_work_id)
      must_respond_with :not_found
    end
  end

  describe "update" do
    before do
      user = users(:dan)
      log_in(user, user.provider.to_sym)
    end
    it "succeeds for valid data and an extant work ID" do
      work = Work.first
      work_data = {
        work: {
          title: work.title + " addition"
        }
      }

      patch work_path(work), params: work_data
      must_redirect_to work_path(work)

      # Verify the DB was really modified
      Work.find(work.id).title.must_equal work_data[:work][:title]
    end

    it "renders bad_request for bogus data" do
      work = Work.first
      work_data = {
        work: {
          title: ""
        }
      }

      patch work_path(work), params: work_data
      must_respond_with :not_found

      # Verify the DB was not modified
      Work.find(work.id).title.must_equal work.title
    end

    it "renders 404 not_found for a bogus work ID" do
      bogus_work_id = Work.last.id + 1
      get work_path(bogus_work_id)
      must_respond_with :not_found
    end
  end

  describe "destroy" do
    it "succeeds for an extant work ID" do
      user = users(:dan)
      log_in(user, user.provider.to_sym)
      work_id = Work.first.id

      delete work_path(work_id)
      must_redirect_to root_path

      # The work should really be gone
      Work.find_by(id: work_id).must_be_nil
    end

    it "renders 404 not_found and does not update the DB for a bogus work ID" do
      user = users(:dan)
      log_in(user, user.provider.to_sym)
      start_count = Work.count

      bogus_work_id = Work.last.id + 1
      delete work_path(bogus_work_id)
      must_respond_with :not_found

      Work.count.must_equal start_count
    end
  end

  describe "upvote" do
    let(:user) { users(:dan) }
    let(:work) { Work.create(title: "A new work", creator: "Someone", publication_year: 2010, category: "album", user_id: user.id) }

    def login
      log_in(user, user.provider.to_sym)
      must_respond_with :redirect
    end

    def logout
      post logout_path
      must_respond_with :redirect
    end

    it "redirects to root path if no user is logged in" do
      start_vote_count = work.votes.count

      post upvote_path(work)
      must_respond_with :redirect
      must_redirect_to root_path
      flash[:result_text].must_equal "Please login first"

      work.votes.count.must_equal start_vote_count
    end

    it "redirects to root path after the user has logged out" do
      start_vote_count = work.votes.count

      login
      logout

      post upvote_path(work)
      must_respond_with :redirect
      must_redirect_to root_path
      flash[:result_text].must_equal "Please login first"

      work.votes.count.must_equal start_vote_count
    end

    it "succeeds for a logged-in user and a fresh user-vote pair" do
      start_vote_count = work.votes.count

      login

      post upvote_path(work)
      # Should be a redirect_back
      must_respond_with :redirect

      work.reload
      work.votes.count.must_equal start_vote_count + 1
    end

    it "returns 409 conflict if the user has already voted for that work" do
      login
      Vote.create!(user: user, work: work)

      start_vote_count = work.votes.count

      post upvote_path(work)
      must_respond_with :conflict

      work.votes.count.must_equal start_vote_count
    end
  end
end
