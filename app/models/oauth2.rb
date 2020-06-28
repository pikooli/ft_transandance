class Oauth2

	require 'securerandom'
	require 'net/http'
	require 'json'

	def initialize
		if Rails.env.production?
			@client_id = Rails.application.credentials.oauth2[:client_id];
			@client_secret = Rails.application.credentials.oauth2[:client_secret];
		else
			@client_id = Rails.application.credentials.oauth2[:client_id_local];
			@client_secret = Rails.application.credentials.oauth2[:client_secret_local];
		end
		@redirect_uri = "";
		@state = "";
		@response_hash = {};
	end

	def authorization(endpoint, redirect_uri, scope = "")
		@redirect_uri = redirect_uri;
		@state = SecureRandom.hex();

		endpoint + "?" + \
		"response_type=code&" + \
		"client_id=" + @client_id + "&" + \
		"redirect_uri=" + @redirect_uri + "&" + \
		"scope=" + scope + "&" + \
		"state=" + @state;
	end

	def token(endpoint, code, state)
		if (state == @state)
			@state = nil;
			response = Net::HTTP.post_form(URI(endpoint), \
										   "grant_type" => "authorization_code",
										   "code" => code,
										   "redirect_uri" => @redirect_uri,
										   "client_id" => @client_id,
										   "client_secret" => @client_secret);
			@response_hash = JSON.parse(response.body);
		else
			nil;
		end
	end

	def authenticated_request(endpoint, key)
		uri = URI(endpoint);
		request = Net::HTTP::Get.new(uri);
		request["Authorization"] = "Bearer " + @response_hash["access_token"];
		response = Net::HTTP.start(uri.hostname,
								   uri.port,
								   :use_ssl => uri.scheme == "https") do |http|
			http.request(request);
		end
		JSON.parse(response.body)[key];
	end

end
