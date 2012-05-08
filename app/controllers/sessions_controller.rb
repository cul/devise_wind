class SessionsController < Devise::SessionsController
  protect_from_forgery
  def new
    create
    redirect_to root_path
  end
end
