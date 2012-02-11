module DeviseWind::Controllers::Sessions

  def authenticating_with_wind?
    # Controller isn't available in all contexts (e.g. irb)
    return false unless session_class.controller
    
    # Initial request when user presses one of the button helpers
    (session_class.controller.params && !session_class.controller.params[:login_with_wind].blank?) ||
    # When the oauth provider responds and we made the initial request
    (defined?(wind_response) && wind_response && session_class.controller.session && session_class.controller.session[:wind_request_class] == self.class.name)
  end
  
  def validate_password_with_wind?
    !using_wind? && require_password?
  end

  def using_wind?
    !wind_login.blank?
  end

  def generate_verified_login
    validate_path = "/validate?ticketid=#{wind_controller.params['ticketid']}"
    wind_validate = Net::HTTP.new("wind.columbia.edu",443)
    wind_validate.use_ssl = true
    wind_validate.start
    wind_resp = wind_validate.get(validate_path)
    wind_validate.finish
    #puts wind_resp.body
    authdoc = Nokogiri::XML(wind_resp.body)
    ns = {'wind'=>'http://www.columbia.edu/acis/rad/authmethods/wind'}
    _user = authdoc.xpath('//wind:authenticationSuccess/wind:user', ns)
    wind_data = nil
    if _user.length > 0
      wind_data = {}
      wind_data[:uni] =  _user[0].content
      wind_data[:affils] = authdoc.xpath('//wind:authenticationSuccess/wind:affiliations/wind:affil',ns).collect {|x| x.content}
    end
    wind_data
  end
end
