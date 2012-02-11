module Warden::Mixins
  module Urls
    def sanitize_query_string
      query_hash = env["rack.request.query_hash"]
      query_hash.delete("_method")
      query_hash.delete_if do |key, value|
        key =~ /^openid\./
      end

      env["QUERY_STRING"] = env["rack.request.query_string"] =
        Rack::Utils.build_query(env["rack.request.query_hash"])

      qs = env["QUERY_STRING"]
      request_uri = (env["PATH_INFO"] || "").dup
      request_uri << "?" + qs unless qs == ""
      env["REQUEST_URI"] = request_uri
    end

    def realm_url
      url = request.scheme + "://"
      url << request.host

      scheme, port = request.scheme, request.port
      if scheme == "https" && port != 443 ||
          scheme == "http" && port != 80
        url << ":#{port}"
      end

      url
    end

    def request_url
      url = realm_url
      url << request.script_name
      url << request.path_info
      url << "?#{request.query_string}" if request.query_string.to_s.length > 0
      url
    end
  end
end