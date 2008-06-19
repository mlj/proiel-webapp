class BookmarksController < ResourceController::Base #ApplicationController
  before_filter :is_reviewer?
end
