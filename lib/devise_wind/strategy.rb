require 'net/https'
class Devise::Strategies::WindAuthenticatable < Devise::Strategies::Authenticatable
  include Warden::Mixins::Urls
  # :stopdoc:

  HTTP_METHODS = %w(GET HEAD PUT POST DELETE OPTIONS)

  RESPONSE = "rack.wind.response"
  AUTHENTICATE_HEADER = "WWW-Authenticate"
  AUTHENTICATE_REGEXP = /^Wind/

  URL_FIELD_SELECTOR = lambda { |field| field.to_s =~ %r{^https?://} }

  # :startdoc:  
  
  # Helper method for building the "WWW-Authenticate" header value.
  #
  #   Rack::Wind.build_header(:server => "http://josh.openid.com/")
  #     #=> Wind server="https://wind.columbia.edu/"
  def self.build_header(params = {})
    'Wind ' + params.map { |key, value|
      if value.is_a?(Array)
        "#{key}=\"#{value.join(',')}\""
      else
        "#{key}=\"#{value}\""
      end
    }.join(', ')
  end

  # Helper method for parsing "WWW-Authenticate" header values into
  # a hash.
  #
  #   Rack::Wind.parse_header("Wind identifier='http://josh.openid.com/'")
  #     #=> {:identifier => "http://josh.openid.com/"}
  def self.parse_header(str)
    params = {}
    if str =~ AUTHENTICATE_REGEXP
      str = str.gsub(/#{AUTHENTICATE_REGEXP}\s+/, '')
      str.split(', ').each { |pair|
        key, *value = pair.split('=')
        value = value.join('=')
        value.gsub!(/^\"/, '').gsub!(/\"$/, "")
        value = value.split(',')
        params[key] = value.length > 1 ? value : value.first
      }
    end
    params
  end
  
  # valid? indicates the applicability of this strategy to the authn request
  def valid?
    valid_mapping? # apply to any request for a wind user
  end
  
  def valid_mapping?
    mapping.to.respond_to?(:find_by_wind_login_field)
  end
  
  def wind_response?
    not wind_response.nil?
  end
  
  def wind_response
    params['ticketid']
  end
  
  def authenticate!
    Rails.logger.debug("Authenticating with WIND for mapping #{mapping.to}")

    if wind_response
      handle_response!
    else # redirect to WIND login with a 30x status
      redirect! wind_redirect_url
    end
  end
  
  def wind_redirect_url
    # Ask for XML response explicitly, since CUIT changes 
    # default response format arbitrarily.
    # "https://#{mapping.to.wind_host}/login?destination=#{CGI.escapeHTML(request_url)}&service=#{CGI.escapeHTML(mapping.to.wind_service)}"
    "https://#{mapping.to.wind_host}/login?sendxml=1&destination=#{CGI.escapeHTML(request_url)}&service=#{CGI.escapeHTML(mapping.to.wind_service)}"

  end
  
  def handle_response!
    ticket_id = params['ticketid']
    # Ask for XML response explicitly, since CUIT changes 
    # default response format arbitrarily.
    # validate_path = "/validate?ticketid=#{ticket_id}"
    validate_path = "/validate?sendxml=1&ticketid=#{ticket_id}"
    wind_validate = Net::HTTP.new("wind.columbia.edu",443)
    wind_validate.use_ssl = true
    wind_validate.verify_mode = OpenSSL::SSL::VERIFY_NONE
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
      Rails.logger.debug wind_data.inspect
      _resource = mapping.to.find_or_create_by_wind_login_field(wind_data[:uni])
      _resource.affiliations= wind_data[:affils]
      _resource.save!
      success! _resource
    else
      Rails.logger.warn "user not found in wind response"
    end
  end
end

Warden::Strategies.add :wind_authenticatable, Devise::Strategies::WindAuthenticatable