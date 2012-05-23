class SessionsController < Devise::SessionsController
	protect_from_forgery
	def new
		create
		redirect_to root_path
	end
	
	def destroy
		signed_in = signed_in?(resource_name)
		redirect_path = after_sign_out_path_for(resource_name)
		Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name)
		set_flash_message :notice, :signed_out if signed_in

		# We actually need to hardcode this as Rails default responder doesn't
		# support returning empty response on GET request
		respond_to do |format|
		  format.any(*navigational_formats) { redirect_to "https://wind.columbia.edu/logout?passthrough=1&destination=" + root_url }
		  format.all do
		    method = "to_#{request_format}"
		    text = {}.respond_to?(method) ? {}.send(method) : ""
		    render :text => text, :status => :ok
		  end
		end
	end
end
