class SessionsController < Devise::SessionsController
  protect_from_forgery
  def new
    create
    render "create"
  end
end
