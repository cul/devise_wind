require 'devise'
class User
  devise :wind_authenticatable
  
  has_and_belongs_to_many :roles
end
