class SessionsController < Devise::SessionsController
  protect_from_forgery
  def new
    create
  end
end
