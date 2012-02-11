class SessionsController < Devise::SessionsController
  protect_from_forgery
  alias_method :new, :create
end
