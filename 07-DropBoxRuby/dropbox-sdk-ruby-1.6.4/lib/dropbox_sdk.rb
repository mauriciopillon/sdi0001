require 'uri'
require 'net/https'
require 'cgi'
require 'json'
require 'yaml'
require 'base64'
require 'securerandom'
require 'pp'

module Dropbox # :nodoc:
    API_SERVER = "api.dropbox.com"
    API_CONTENT_SERVER = "api-content.dropbox.com"
    WEB_SERVER = "www.dropbox.com"

    API_VERSION = 1
    SDK_VERSION = "1.6.4"

    TRUSTED_CERT_FILE = File.join(File.dirname(__FILE__), 'trusted-certs.crt')

    def self.clean_params(params)
        r = {}
        params.each do |k,v|
            r[k] = v.to_s if not v.nil?
        end
        r
    end

    def self.make_query_string(params)
        clean_params(params).collect {|k,v|
            CGI.escape(k) + "=" + CGI.escape(v)
        }.join("&")
    end

    def self.verify_ssl_certificate(preverify_ok, ssl_context)
      if preverify_ok != true || ssl_context.error != 0
        err_msg = "SSL Verification failed -- Preverify: #{preverify_ok}, Error: #{ssl_context.error_string} (#{ssl_context.error})"
        raise OpenSSL::SSL::SSLError.new(err_msg)
      end
      true
    end

    def self.do_http(uri, request) # :nodoc:

        http = Net::HTTP.new(uri.host, uri.port)

        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
        http.ca_file = Dropbox::TRUSTED_CERT_FILE

        if RUBY_VERSION >= '1.9'
            # SSL protocol and ciphersuite settings are supported strating with version 1.9
            http.ssl_version = 'TLSv1'
            http.ciphers = 'ECDHE-RSA-AES256-GCM-SHA384:'\
                        'ECDHE-RSA-AES256-SHA384:'\
                        'ECDHE-RSA-AES256-SHA:'\
                        'ECDHE-RSA-AES128-GCM-SHA256:'\
                        'ECDHE-RSA-AES128-SHA256:'\
                        'ECDHE-RSA-AES128-SHA:'\
                        'ECDHE-RSA-RC4-SHA:'\
                        'DHE-RSA-AES256-GCM-SHA384:'\
                        'DHE-RSA-AES256-SHA256:'\
                        'DHE-RSA-AES256-SHA:'\
                        'DHE-RSA-AES128-GCM-SHA256:'\
                        'DHE-RSA-AES128-SHA256:'\
                        'DHE-RSA-AES128-SHA:'\
                        'AES256-GCM-SHA384:'\
                        'AES256-SHA256:'\
                        'AES256-SHA:'\
                        'AES128-GCM-SHA256:'\
                        'AES128-SHA256:'\
                        'AES128-SHA'
        end

        # Important security note!
        # Some Ruby versions (e.g. the one that ships with OS X) do not raise an exception if certificate validation fails.
        # We therefore have to add a custom callback to ensure that invalid certs are not accepted
        # See https://www.braintreepayments.com/braintrust/sslsocket-verify_mode-doesnt-verify
        # You can comment out this code in case your Ruby version is not vulnerable
        http.verify_callback = proc do |preverify_ok, ssl_context|
            Dropbox::verify_ssl_certificate(preverify_ok, ssl_context)
        end

        #We use this to better understand how developers are using our SDKs.
        request['User-Agent'] =  "OfficialDropboxRubySDK/#{Dropbox::SDK_VERSION}"

        begin
            http.request(request)
        rescue OpenSSL::SSL::SSLError => e
            raise DropboxError.new("SSL error connecting to Dropbox.  " +
                                   "There may be a problem with the set of certificates in \"#{Dropbox::TRUSTED_CERT_FILE}\".  #{e.message}")
        end
    end

    # Parse response. You probably shouldn't be calling this directly.  This takes responses from the server
    # and parses them.  It also checks for errors and raises exceptions with the appropriate messages.
    def self.parse_response(response, raw=false) # :nodoc:
        if response.kind_of?(Net::HTTPServerError)
            raise DropboxError.new("Dropbox Server Error: #{response} - #{response.body}", response)
        elsif response.kind_of?(Net::HTTPUnauthorized)
            raise DropboxAuthError.new("User is not authenticated.", response)
        elsif not response.kind_of?(Net::HTTPSuccess)
            begin
                d = JSON.parse(response.body)
            rescue
                raise DropboxError.new("Dropbox Server Error: body=#{response.body}", response)
            end
            if d['user_error'] and d['error']
                raise DropboxError.new(d['error'], response, d['user_error'])  #user_error is translated
            elsif d['error']
                raise DropboxError.new(d['error'], response)
            else
                raise DropboxError.new(response.body, response)
            end
        end

        return response.body if raw

        begin
            return JSON.parse(response.body)
        rescue JSON::ParserError
            raise DropboxError.new("Unable to parse JSON response: #{response.body}", response)
        end
    end

    # A string comparison function that is resistant to timing attacks.  If you're comparing a
    # string you got from the outside world with a string that is supposed to be a secret, use
    # this function to check equality.
    def self.safe_string_equals(a, b)
        if a.length != b.length
            false
        else
            a.chars.zip(b.chars).map {|ac,bc| ac == bc}.all?
        end
    end
end

class DropboxSessionBase # :nodoc:

    attr_writer :locale

    def initialize(locale)
        @locale = locale
    end

    private

    def build_url(path, content_server)
        port = 443
        host = content_server ? Dropbox::API_CONTENT_SERVER : Dropbox::API_SERVER
        full_path = "/#{Dropbox::API_VERSION}#{path}"
        return URI::HTTPS.build({:host => host, :path => full_path})
    end

    def build_url_with_params(path, params, content_server) # :nodoc:
        target = build_url(path, content_server)
        params['locale'] = @locale
        target.query = Dropbox::make_query_string(params)
        return target
    end

    protected

    def do_http(uri, request) # :nodoc:
        sign_request(request)
        Dropbox::do_http(uri, request)
    end

    public

    def do_get(path, params=nil, headers=nil, content_server=false)  # :nodoc:
        params ||= {}
        assert_authorized
        uri = build_url_with_params(path, params, content_server)
        do_http(uri, Net::HTTP::Get.new(uri.request_uri))
    end

    def do_http_with_body(uri, request, body)
        if body != nil
            if body.is_a?(Hash)
                request.set_form_data(Dropbox::clean_params(body))
            elsif body.respond_to?(:read)
                if body.respond_to?(:length)
                    request["Content-Length"] = body.length.to_s
                elsif body.respond_to?(:stat) && body.stat.respond_to?(:size)
                    request["Content-Length"] = body.stat.size.to_s
                else
                    raise ArgumentError, "Don't know how to handle 'body' (responds to 'read' but not to 'length' or 'stat.size')."
                end
                request.body_stream = body
            else
                s = body.to_s
                request["Content-Length"] = s.length
                request.body = s
            end
        end
        do_http(uri, request)
    end

    def do_post(path, params=nil, headers=nil, content_server=false)  # :nodoc:
        params ||= {}
        assert_authorized
        uri = build_url(path, content_server)
        params['locale'] = @locale
        do_http_with_body(uri, Net::HTTP::Post.new(uri.request_uri, headers), params)
    end

    def do_put(path, params=nil, headers=nil, body=nil, content_server=false)  # :nodoc:
        params ||= {}
        assert_authorized
        uri = build_url_with_params(path, params, content_server)
        do_http_with_body(uri, Net::HTTP::Put.new(uri.request_uri, headers), body)
    end
end

# DropboxSession is responsible for holding OAuth 1 information.  It knows how to take your consumer key and secret
# and request an access token, an authorize url, and get an access token.  You just need to pass it to
# DropboxClient after its been authorized.
class DropboxSession < DropboxSessionBase  # :nodoc:

    # * consumer_key - Your Dropbox application's "app key".
    # * consumer_secret - Your Dropbox application's "app secret".
    def initialize(consumer_key, consumer_secret, locale=nil)
        super(locale)
        @consumer_key = consumer_key
        @consumer_secret = consumer_secret
        @request_token = nil
        @access_token = nil
    end

    private

    def build_auth_header(token) # :nodoc:
        header = "OAuth oauth_version=\"1.0\", oauth_signature_method=\"PLAINTEXT\", " +
            "oauth_consumer_key=\"#{URI.escape(@consumer_key)}\", "
        if token
            key = URI.escape(token.key)
            secret = URI.escape(token.secret)
            header += "oauth_token=\"#{key}\", oauth_signature=\"#{URI.escape(@consumer_secret)}&#{secret}\""
        else
            header += "oauth_signature=\"#{URI.escape(@consumer_secret)}&\""
        end
        header
    end

    def do_get_with_token(url, token, headers=nil) # :nodoc:
        uri = URI.parse(url)
        request = Net::HTTP::Get.new(uri.request_uri)
        request.add_field('Authorization', build_auth_header(token))
        Dropbox::do_http(uri, request)
    end

    protected

    def sign_request(request)  # :nodoc:
        request.add_field('Authorization', build_auth_header(@access_token))
    end

    public

    def get_token(url_end, input_token, error_message_prefix) #: nodoc:
        response = do_get_with_token("https://#{Dropbox::API_SERVER}:443/#{Dropbox::API_VERSION}/oauth#{url_end}", input_token)
        if not response.kind_of?(Net::HTTPSuccess) # it must be a 200
            raise DropboxAuthError.new("#{error_message_prefix}  Server returned #{response.code}: #{response.message}.", response)
        end
        parts = CGI.parse(response.body)

        if !parts.has_key? "oauth_token" and parts["oauth_token"].length != 1
            raise DropboxAuthError.new("Invalid response from #{url_end}: missing \"oauth_token\" parameter: #{response.body}", response)
        end
        if !parts.has_key? "oauth_token_secret" and parts["oauth_token_secret"].length != 1
            raise DropboxAuthError.new("Invalid response from #{url_end}: missing \"oauth_token\" parameter: #{response.body}", response)
        end

        OAuthToken.new(parts["oauth_token"][0], parts["oauth_token_secret"][0])
    end

    # This returns a request token.  Requests one from the dropbox server using the provided application key and secret if nessecary.
    def get_request_token()
        @request_token ||= get_token("/request_token", nil, "Error getting request token.  Is your app key and secret correctly set?")
    end

    # This returns a URL that your user must visit to grant
    # permissions to this application.
    def get_authorize_url(callback=nil)
        get_request_token()

        url = "/#{Dropbox::API_VERSION}/oauth/authorize?oauth_token=#{URI.escape(@request_token.key)}"
        if callback
            url += "&oauth_callback=#{URI.escape(callback)}"
        end
        if @locale
            url += "&locale=#{URI.escape(@locale)}"
        end

        "https://#{Dropbox::WEB_SERVER}#{url}"
    end

    # Clears the access_token
    def clear_access_token
        @access_token = nil
    end

    # Returns the request token, or nil if one hasn't been acquired yet.
    def request_token
        @request_token
    end

    # Returns the access token, or nil if one hasn't been acquired yet.
    def access_token
        @access_token
    end

    # Given a saved request token and secret, set this location's token and secret
    # * token - this is the request token
    # * secret - this is the request token secret
    def set_request_token(key, secret)
        @request_token = OAuthToken.new(key, secret)
    end

    # Given a saved access token and secret, you set this Session to use that token and secret
    # * token - this is the access token
    # * secret - this is the access token secret
    def set_access_token(key, secret)
        @access_token = OAuthToken.new(key, secret)
    end

    # Returns the access token. If this DropboxSession doesn't yet have an access_token, it requests one
    # using the request_token generate from your app's token and secret.  This request will fail unless
    # your user has gone to the authorize_url and approved your request
    def get_access_token
        return @access_token if authorized?

        if @request_token.nil?
            raise RuntimeError.new("No request token. You must set this or get an authorize url first.")
        end

        @access_token = get_token("/access_token", @request_token,  "Couldn't get access token.")
    end

    # If we have an access token, then do nothing.  If not, throw a RuntimeError.
    def assert_authorized
        unless authorized?
            raise RuntimeError.new('Session does not yet have a request token')
        end
    end

    # Returns true if this Session has been authorized and has an access_token.
    def authorized?
        !!@access_token
    end

    # serialize the DropboxSession.
    # At DropboxSession's state is capture in three key/secret pairs.  Consumer, request, and access.
    # Serialize returns these in a YAML string, generated from a converted array of the form:
    # [consumer_key, consumer_secret, request_token.token, request_token.secret, access_token.token, access_token.secret]
    # access_token is only included if it already exists in the DropboxSesssion
    def serialize
        toreturn = []
        if @access_token
            toreturn.push @access_token.secret, @access_token.key
        end

        get_request_token

        toreturn.push @request_token.secret, @request_token.key
        toreturn.push @consumer_secret, @consumer_key

        toreturn.to_yaml
    end

    # Takes a serialized DropboxSession YAML String and returns a new DropboxSession object
    def self.deserialize(ser)
        ser = YAML::load(ser)
        session = DropboxSession.new(ser.pop, ser.pop)
        session.set_request_token(ser.pop, ser.pop)

        if ser.length > 0
            session.set_access_token(ser.pop, ser.pop)
        end
        session
    end
end


class DropboxOAuth2Session < DropboxSessionBase  # :nodoc:

    def initialize(oauth2_access_token, locale=nil)
        super(locale)
        if not oauth2_access_token.is_a?(String)
            raise "bad type for oauth2_access_token (expecting String)"
        end
        @access_token = oauth2_access_token
    end

    def assert_authorized
        true
    end

    protected

    def sign_request(request)  # :nodoc:
        request.add_field('Authorization', 'Bearer ' + @access_token)
    end
end

# Base class for the two OAuth 2 authorization helpers.
class DropboxOAuth2FlowBase  # :nodoc:
    def initialize(consumer_key, consumer_secret, locale=nil)
        if not consumer_key.is_a?(String)
            raise ArgumentError, "consumer_key must be a String, got #{consumer_key.inspect}"
        end
        if not consumer_secret.is_a?(String)
            raise ArgumentError, "consumer_secret must be a String, got #{consumer_secret.inspect}"
        end
        if not (locale.nil? or locale.is_a?(String))
            raise ArgumentError, "locale must be a String or nil, got #{locale.inspect}"
        end
        @consumer_key = consumer_key
        @consumer_secret = consumer_secret
        @locale = locale
    end

    def _get_authorize_url(redirect_uri, state)
        params = {
            "client_id" => @consumer_key,
            "response_type" => "code",
            "redirect_uri" => redirect_uri,
            "state" => state,
            "locale" => @locale,
        }

        host = Dropbox::WEB_SERVER
        path = "/#{Dropbox::API_VERSION}/oauth2/authorize"

        target = URI::Generic.new("https", nil, host, nil, nil, path, nil, nil, nil)
        target.query = Dropbox::make_query_string(params)

        target.to_s
    end

    # Finish the OAuth 2 authorization process.  If you used a redirect_uri, pass that in.
    # Will return an access token string that you can use with DropboxClient.
    def _finish(code, original_redirect_uri)
        if not code.is_a?(String)
            raise ArgumentError, "code must be a String"
        end

        uri = URI.parse("https://#{Dropbox::API_SERVER}/1/oauth2/token")
        request = Net::HTTP::Post.new(uri.request_uri)
        client_credentials = @consumer_key + ':' + @consumer_secret
        request.add_field('Authorization', 'Basic ' + Base64.encode64(client_credentials).chomp("\n"))

        params = {
            "grant_type" => "authorization_code",
            "code" => code,
            "redirect_uri" => original_redirect_uri,
            "locale" => @locale,
        }

        request.set_form_data(Dropbox::clean_params(params))

        response = Dropbox::do_http(uri, request)

        j = Dropbox::parse_response(response)
        ["token_type", "access_token", "uid"].each { |k|
            if not j.has_key?(k)
                raise DropboxError.new("Bad response from /token: missing \"#{k}\".")
            end
            if not j[k].is_a?(String)
                raise DropboxError.new("Bad response from /token: field \"#{k}\" is not a string.")
            end
        }
        if j["token_type"] != "bearer" and j["token_type"] != "Bearer"
            raise DropboxError.new("Bad response from /token: \"token_type\" is \"#{token_type}\".")
        end

        return j['access_token'], j['uid']
    end
end

# OAuth 2 authorization helper for apps that can't provide a redirect URI
# (such as the command line example apps).
class DropboxOAuth2FlowNoRedirect < DropboxOAuth2FlowBase

    # * consumer_key: Your Dropbox API app's "app key"
    # * consumer_secret: Your Dropbox API app's "app secret"
    # * locale: The locale of the user currently using your app.
    def initialize(consumer_key, consumer_secret, locale=nil)
        super(consumer_key, consumer_secret, locale)
    end

    # Returns a authorization_url, which is a page on Dropbox's website.  Have the user
    # visit this URL and approve your app.
    def start()
        _get_authorize_url(nil, nil)
    end

    # If the user approves your app, they will be presented with an "authorization code".
    # Have the user copy/paste that authorization code into your app and then call this
    # method to get an access token.
    #
    # Returns a two-entry list (access_token, user_id)
    # * access_token is an access token string that can be passed to DropboxClient.
    # * user_id is the Dropbox user ID of the user that just approved your app.
    def finish(code)
        _finish(code, nil)
    end
end

# The standard OAuth 2 authorization helper.  Use this if you're writing a web app.
class DropboxOAuth2Flow < DropboxOAuth2FlowBase

    # * consumer_key: Your Dropbox API app's "app key"
    # * consumer_secret: Your Dropbox API app's "app secret"
    # * redirect_uri: The URI that the Dropbox server will redirect the user to after the user
    #   finishes authorizing your app.  This URI  must be HTTPs-based and pre-registered with
    #   the Dropbox servers, though localhost URIs are allowed without pre-registration and can
    #   be either HTTP or HTTPS.
    # * session: A hash that represents the current web app session (will be used to save the CSRF
    #   token)
    # * csrf_token_key: The key to use when storing the CSRF token in the session (for example,
    #   :dropbox_auth_csrf_token)
    # * locale: The locale of the user currently using your app (ex: "en" or "en_US").
    def initialize(consumer_key, consumer_secret, redirect_uri, session, csrf_token_session_key, locale=nil)
        super(consumer_key, consumer_secret, locale)
        if not redirect_uri.is_a?(String)
            raise ArgumentError, "redirect_uri must be a String, got #{consumer_secret.inspect}"
        end
        @redirect_uri = redirect_uri
        @session = session
        @csrf_token_session_key = csrf_token_session_key
    end

    # Starts the OAuth 2 authorizaton process, which involves redirecting the user to
    # the returned "authorization URL" (a URL on the Dropbox website).  When the user then
    # either approves or denies your app access, Dropbox will redirect them to the
    # redirect_uri you provided to the constructor, at which point you should call finish()
    # to complete the process.
    #
    # This function will also save a CSRF token to the session and csrf_token_session_key
    # you provided to the constructor.  This CSRF token will be checked on finish() to prevent
    # request forgery.
    #
    # * url_state: Any data you would like to keep in the URL through the authorization
    #   process.  This exact value will be returned to you by finish().
    #
    # Returns the URL to redirect the user to.
    def start(url_state=nil)
        unless url_state.nil? or url_state.is_a?(String)
            raise ArgumentError, "url_state must be a String"
        end

        csrf_token = SecureRandom.base64(16)
        state = csrf_token
        unless url_state.nil?
            state += "|" + url_state
        end
        @session[@csrf_token_session_key] = csrf_token

        return _get_authorize_url(@redirect_uri, state)
    end

    # Call this after the user has visited the authorize URL (see: start()), approved your app,
    # and was redirected to your redirect URI.
    #
    # * query_params: The query params on the GET request to your redirect URI.
    #
    # Returns a tuple of (access_token, user_id, url_state).  access_token can be used to
    # construct a DropboxClient.  user_id is the Dropbox user ID of the user that jsut approved
    # your app.  url_state is the value you originally passed in to start().
    #
    # Can throw BadRequestError, BadStateError, CsrfError, NotApprovedError,
    # ProviderError, and the standard DropboxError.
    def finish(query_params)
        csrf_token_from_session = @session[@csrf_token_session_key]

        # Check well-formedness of request.

        state = query_params['state']
        if state.nil?
            raise BadRequestError.new("Missing query parameter 'state'.")
        end

        error = query_params['error']
        error_description = query_params['error_description']
        code = query_params['code']

        if not error.nil? and not code.nil?
            raise BadRequestError.new("Query parameters 'code' and 'error' are both set;" +
                                      " only one must be set.")
        end
        if error.nil? and code.nil?
            raise BadRequestError.new("Neither query parameter 'code' or 'error' is set.")
        end

        # Check CSRF token

        if csrf_token_from_session.nil?
            raise BadStateError.new("Missing CSRF token in session.");
        end
        unless csrf_token_from_session.length > 20
            raise RuntimeError.new("CSRF token unexpectedly short: #{csrf_token_from_session.inspect}")
        end

        split_pos = state.index('|')
        if split_pos.nil?
            given_csrf_token = state
            url_state = nil
        else
            given_csrf_token, url_state = state.split('|', 2)
        end
        if not Dropbox::safe_string_equals(csrf_token_from_session, given_csrf_token)
            raise CsrfError.new("Expected #{csrf_token_from_session.inspect}, " +
                                    "got #{given_csrf_token.inspect}.")
        end
        @session.delete(@csrf_token_session_key)

        # Check for error identifier

        if not error.nil?
            if error == 'access_denied'
                # The user clicked "Deny"
                if error_description.nil?
                    raise NotApprovedError.new("No additional description from Dropbox.")
                else
                    raise NotApprovedError.new("Additional description from Dropbox: #{error_description}")
                end
            else
                # All other errors.
                full_message = error
                if not error_description.nil?
                    full_message += ": " + error_description
                end
                raise ProviderError.new(full_message)
            end
        end

        # If everything went ok, make the network call to get an access token.

        access_token, user_id = _finish(code, @redirect_uri)
        return access_token, user_id, url_state
    end

    # Thrown if the redirect URL was missing parameters or if the given parameters were not valid.
    #
    # The recommended action is to show an HTTP 400 error page.
    class BadRequestError < Exception; end

    # Thrown if all the parameters are correct, but there's no CSRF token in the session.  This
    # probably means that the session expired.
    #
    # The recommended action is to redirect the user's browser to try the approval process again.
    class BadStateError < Exception; end

    # Thrown if the given 'state' parameter doesn't contain the CSRF token from the user's session.
    # This is blocked to prevent CSRF attacks.
    #
    # The recommended action is to respond with an HTTP 403 error page.
    class CsrfError < Exception; end

    # The user chose not to approve your app.
    class NotApprovedError < Exception; end

    # Dropbox redirected to your redirect URI with some unexpected error identifier and error
    # message.
    class ProviderError < Exception; end
end


# A class that represents either an OAuth request token or an OAuth access token.
class OAuthToken # :nodoc:
    def initialize(key, secret)
        @key = key
        @secret = secret
    end

    def key
        @key
    end

    def secret
        @secret
    end
end


# This is the usual error raised on any Dropbox related Errors
class DropboxError < RuntimeError
    attr_accessor :http_response, :error, :user_error
    def initialize(error, http_response=nil, user_error=nil)
        @error = error
        @http_response = http_response
        @user_error = user_error
    end

    def to_s
        return "#{user_error} (#{error})" if user_error
        "#{error}"
    end
end

# This is the error raised on Authentication failures.  Usually this means
# one of three things
# * Your user failed to go to the authorize url and approve your application
# * You set an invalid or expired token and secret on your Session
# * Your user deauthorized the application after you stored a valid token and secret
class DropboxAuthError < DropboxError
end

# This is raised when you call metadata with a hash and that hash matches
# See documentation in metadata function
class DropboxNotModified < DropboxError
end

# Use this class to make Dropbox API calls.  You'll need to obtain an OAuth 2 access token
# first; you can get one using either DropboxOAuth2Flow or DropboxOAuth2FlowNoRedirect.
class DropboxClient

    # Args:
    # * +oauth2_access_token+: Obtained via DropboxOAuth2Flow or DropboxOAuth2FlowNoRedirect.
    # * +locale+: The user's current locale (used to localize error messages).
    def initialize(oauth2_access_token, root="auto", locale=nil)
        if oauth2_access_token.is_a?(String)
            @session = DropboxOAuth2Session.new(oauth2_access_token, locale)
        elsif oauth2_access_token.is_a?(DropboxSession)
            @session = oauth2_access_token
            @session.get_access_token
            if not locale.nil?
                @session.locale = locale
            end
        else
            raise ArgumentError.new("oauth2_access_token doesn't have a valid type")
        end

        @root = root.to_s  # If they passed in a symbol, make it a string

        if not ["dropbox","app_folder","auto"].include?(@root)
            raise ArgumentError.new("root must be :dropbox, :app_folder, or :auto")
        end
        if @root == "app_folder"
            #App Folder is the name of the access type, but for historical reasons
            #sandbox is the URL root component that indicates this
            @root = "sandbox"
        end
    end

    # Returns some information about the current user's Dropbox account (the "current user"
    # is the user associated with the access token you're using).
    #
    # For a detailed description of what this call returns, visit:
    # https://www.dropbox.com/developers/reference/api#account-info
    def account_info()
        response = @session.do_get "/account/info"
        Dropbox::parse_response(response)
    end

    # Disables the access token that this +DropboxClient+ is using.  If this call
    # succeeds, further API calls using this object will fail.
    def disable_access_token
        @session.do_post "/disable_access_token"
        nil
    end

    # If this +DropboxClient+ was created with an OAuth 1 access token, this method
    # can be used to create an equivalent OAuth 2 access token.  This can be used to
    # upgrade your app's existing access tokens from OAuth 1 to OAuth 2.
    def create_oauth2_access_token
        if not @session.is_a?(DropboxSession)
            raise ArgumentError.new("This call requires a DropboxClient that is configured with " \
                                    "an OAuth 1 access token.")
        end
        response = @session.do_post "/oauth2/token_from_oauth1"
        Dropbox::parse_response(response)['access_token']
    end

    # Uploads a file to a server.  This uses the HTTP PUT upload method for simplicity
    #
    # Args:
    # * +to_path+: The directory path to upload the file to. If the destination
    #   directory does not yet exist, it will be created.
    # * +file_obj+: A file-like object to upload. If you would like, you can
    #   pass a string as file_obj.
    # * +overwrite+: Whether to overwrite an existing file at the given path. [default is False]
    #   If overwrite is False and a file already exists there, Dropbox
    #   will rename the upload to make sure it doesn't overwrite anything.
    #   You must check the returned metadata to know what this new name is.
    #   This field should only be True if your intent is to potentially
    #   clobber changes to a file that you don't know about.
    # * +parent_rev+: The rev field from the 'parent' of this upload. [optional]
    #   If your intent is to update the file at the given path, you should
    #   pass the parent_rev parameter set to the rev value from the most recent
    #   metadata you have of the existing file at that path. If the server
    #   has a more recent version of the file at the specified path, it will
    #   automatically rename your uploaded file, spinning off a conflict.
    #   Using this parameter effectively causes the overwrite parameter to be ignored.
    #   The file will always be overwritten if you send the most-recent parent_rev,
    #   and it will never be overwritten you send a less-recent one.
    # Returns:
    # * a Hash containing the metadata of the newly uploaded file.  The file may have a different
    #   name if it conflicted.
    #
    # Simple Example
    #  client = DropboxClient(oauth2_access_token)
    #  #session is a DropboxSession I've already authorized
    #  client.put_file('/test_file_on_dropbox', open('/tmp/test_file'))
    # This will upload the "/tmp/test_file" from my computer into the root of my App's app folder
    # and call it "test_file_on_dropbox".
    # The file will not overwrite any pre-existing file.
    def put_file(to_path, file_obj, overwrite=false, parent_rev=nil)
        path = "/files_put/#{@root}#{format_path(to_path)}"
        params = {
            'overwrite' => overwrite.to_s,
            'parent_rev' => parent_rev,
        }

        headers = {"Content-Type" => "application/octet-stream"}
        content_server = true
        response = @session.do_put path, params, headers, file_obj, content_server

        Dropbox::parse_response(response)
    end

    # Returns a ChunkedUploader object.
    #
    # Args:
    # * +file_obj+: The file-like object to be uploaded.  Must support .read()
    # * +total_size+: The total size of file_obj
    def get_chunked_uploader(file_obj, total_size)
        ChunkedUploader.new(self, file_obj, total_size)
    end

    # ChunkedUploader is responsible for uploading a large file to Dropbox in smaller chunks.
    # This allows large files to be uploaded and makes allows recovery during failure.
    class ChunkedUploader
        attr_accessor :file_obj, :total_size, :offset, :upload_id, :client

        def initialize(client, file_obj, total_size)
            @client = client
            @file_obj = file_obj
            @total_size = total_size
            @upload_id = nil
            @offset = 0
        end

        # Uploads data from this ChunkedUploader's file_obj in chunks, until
        # an error occurs. Throws an exception when an error occurs, and can
        # be called again to resume the upload.
        #
        # Args:
        # * +chunk_size+: The chunk size for each individual upload.  Defaults to 4MB.
        def upload(chunk_size=4*1024*1024)
            last_chunk = nil

            while @offset < @total_size
                if not last_chunk
                    last_chunk = @file_obj.read(chunk_size)
                end

                resp = {}
                begin
                    resp = Dropbox::parse_response(@client.partial_chunked_upload(last_chunk, @upload_id, @offset))
                    last_chunk = nil
                rescue SocketError => e
                  raise e
                rescue SystemCallError => e
                  raise e
                rescue DropboxError => e
                  raise e if e.http_response.nil? or e.http_response.code[0] == '5'
                    begin
                      resp = JSON.parse(e.http_response.body)
                      raise DropboxError.new('server response does not have offset key') unless resp.has_key? 'offset'
                    rescue JSON::ParserError
                      raise DropboxError.new("Unable to parse JSON response: #{e.http_response.body}")
                    end
                end

                if resp.has_key? 'offset' and resp['offset'] > @offset
                    @offset += (resp['offset'] - @offset) if resp['offset']
                    last_chunk = nil
                end
                @upload_id = resp['upload_id'] if resp['upload_id']
            end
        end

        # Completes a file upload
        #
        # Args:
        # * +to_path+: The directory path to upload the file to. If the destination
        #   directory does not yet exist, it will be created.
        # * +overwrite+: Whether to overwrite an existing file at the given path. [default is False]
        #   If overwrite is False and a file already exists there, Dropbox
        #   will rename the upload to make sure it doesn't overwrite anything.
        #   You must check the returned metadata to know what this new name is.
        #   This field should only be True if your intent is to potentially
        #   clobber changes to a file that you don't know about.
        # * parent_rev: The rev field from the 'parent' of this upload.
        #   If your intent is to update the file at the given path, you should
        #   pass the parent_rev parameter set to the rev value from the most recent
        #   metadata you have of the existing file at that path. If the server
        #   has a more recent version of the file at the specified path, it will
        #   automatically rename your uploaded file, spinning off a conflict.
        #   Using this parameter effectively causes the overwrite parameter to be ignored.
        #   The file will always be overwritten if you send the most-recent parent_rev,
        #   and it will never be overwritten you send a less-recent one.
        #
        # Returns:
        # *  A Hash with the metadata of file just uploaded.
        #    For a detailed description of what this call returns, visit:
        #    https://www.dropbox.com/developers/reference/api#metadata
        def finish(to_path, overwrite=false, parent_rev=nil)
            response = @client.commit_chunked_upload(to_path, @upload_id, overwrite, parent_rev)
            Dropbox::parse_response(response)
        end
    end

    def commit_chunked_upload(to_path, upload_id, overwrite=false, parent_rev=nil)  #:nodoc
        path = "/commit_chunked_upload/#{@root}#{format_path(to_path)}"
        params = {'overwrite' => overwrite.to_s,
                  'upload_id' => upload_id,
                  'parent_rev' => parent_rev,
                }
        headers = nil
        content_server = true
        @session.do_post path, params, headers, content_server
    end

    def partial_chunked_upload(data, upload_id=nil, offset=nil)  #:nodoc
        params = {
            'upload_id' => upload_id,
            'offset' => offset,
        }
        headers = {'Content-Type' => "application/octet-stream"}
        content_server = true
        @session.do_put '/chunked_upload', params, headers, data, content_server
    end

    # Download a file
    #
    # Args:
    # * +from_path+: The path to the file to be downloaded
    # * +rev+: A previous revision value of the file to be downloaded
    #
    # Returns:
    # * The file contents.
    def get_file(from_path, rev=nil)
        response = get_file_impl(from_path, rev)
        Dropbox::parse_response(response, raw=true)
    end

    # Download a file and get its metadata.
    #
    # Args:
    # * +from_path+: The path to the file to be downloaded
    # * +rev+: A previous revision value of the file to be downloaded
    #
    # Returns:
    # * The file contents.
    # * The file metadata as a hash.
    def get_file_and_metadata(from_path, rev=nil)
        response = get_file_impl(from_path, rev)
        parsed_response = Dropbox::parse_response(response, raw=true)
        metadata = parse_metadata(response)
        return parsed_response, metadata
    end

    # Download a file (helper method - don't call this directly).
    #
    # Args:
    # * +from_path+: The path to the file to be downloaded
    # * +rev+: A previous revision value of the file to be downloaded
    #
    # Returns:
    # * The HTTPResponse for the file download request.
    def get_file_impl(from_path, rev=nil) # :nodoc:
        path = "/files/#{@root}#{format_path(from_path)}"
        params = {
            'rev' => rev,
        }
        headers = nil
        content_server = true
        @session.do_get path, params, headers, content_server
    end
    private :get_file_impl

    # Parses out file metadata from a raw dropbox HTTP response.
    #
    # Args:
    # * +dropbox_raw_response+: The raw, unparsed HTTPResponse from Dropbox.
    #
    # Returns:
    # * The metadata of the file as a hash.
    def parse_metadata(dropbox_raw_response) # :nodoc:
        begin
            raw_metadata = dropbox_raw_response['x-dropbox-metadata']
            metadata = JSON.parse(raw_metadata)
        rescue
            raise DropboxError.new("Dropbox Server Error: x-dropbox-metadata=#{raw_metadata}",
                                   dropbox_raw_response)
        end
        return metadata
    end
    private :parse_metadata

    # Copy a file or folder to a new location.
    #
    # Args:
    # * +from_path+: The path to the file or folder to be copied.
    # * +to_path+: The destination path of the file or folder to be copied.
    #   This parameter should include the destination filename (e.g.
    #   from_path: '/test.txt', to_path: '/dir/test.txt'). If there's
    #   already a file at the to_path, this copy will be renamed to
    #   be unique.
    #
    # Returns:
    # * A hash with the metadata of the new copy of the file or folder.
    #   For a detailed description of what this call returns, visit:
    #   https://www.dropbox.com/developers/reference/api#fileops-copy
    def file_copy(from_path, to_path)
        params = {
            "root" => @root,
            "from_path" => format_path(from_path, false),
            "to_path" => format_path(to_path, false),
        }
        response = @session.do_post "/fileops/copy", params
        Dropbox::parse_response(response)
    end

    # Create a folder.
    #
    # Arguments:
    # * +path+: The path of the new folder.
    #
    # Returns:
    # *  A hash with the metadata of the newly created folder.
    #    For a detailed description of what this call returns, visit:
    #    https://www.dropbox.com/developers/reference/api#fileops-create-folder
    def file_create_folder(path)
        params = {
            "root" => @root,
            "path" => format_path(path, false),
        }
        response = @session.do_post "/fileops/create_folder", params

        Dropbox::parse_response(response)
    end

    # Deletes a file
    #
    # Arguments:
    # * +path+: The path of the file to delete
    #
    # Returns:
    # *  A Hash with the metadata of file just deleted.
    #    For a detailed description of what this call returns, visit:
    #    https://www.dropbox.com/developers/reference/api#fileops-delete
    def file_delete(path)
        params = {
            "root" => @root,
            "path" => format_path(path, false),
        }
        response = @session.do_post "/fileops/delete", params
        Dropbox::parse_response(response)
    end

    # Moves a file
    #
    # Arguments:
    # * +from_path+: The path of the file to be moved
    # * +to_path+: The destination path of the file or folder to be moved
    #   If the file or folder already exists, it will be renamed to be unique.
    #
    # Returns:
    # *  A Hash with the metadata of file or folder just moved.
    #    For a detailed description of what this call returns, visit:
    #    https://www.dropbox.com/developers/reference/api#fileops-delete
    def file_move(from_path, to_path)
        params = {
            "root" => @root,
            "from_path" => format_path(from_path, false),
            "to_path" => format_path(to_path, false),
        }
        response = @session.do_post "/fileops/move", params
        Dropbox::parse_response(response)
    end

    # Retrives metadata for a file or folder
    #
    # Arguments:
    # * path: The path to the file or folder.
    # * list: Whether to list all contained files (only applies when
    #   path refers to a folder).
    # * file_limit: The maximum number of file entries to return within
    #   a folder. If the number of files in the directory exceeds this
    #   limit, an exception is raised. The server will return at max
    #   25,000 files within a folder.
    # * hash: Every directory listing has a hash parameter attached that
    #   can then be passed back into this function later to save on
    #   bandwidth. Rather than returning an unchanged folder's contents, if
    #   the hash matches a DropboxNotModified exception is raised.
    # * rev: Optional. The revision of the file to retrieve the metadata for.
    #   This parameter only applies for files. If omitted, you'll receive
    #   the most recent revision metadata.
    # * include_deleted: Specifies whether to include deleted files in metadata results.
    #
    # Returns:
    # * A Hash object with the metadata of the file or folder (and contained files if
    #   appropriate).  For a detailed description of what this call returns, visit:
    #   https://www.dropbox.com/developers/reference/api#metadata
    def metadata(path, file_limit=25000, list=true, hash=nil, rev=nil, include_deleted=false)
        params = {
            "file_limit" => file_limit.to_s,
            "list" => list.to_s,
            "include_deleted" => include_deleted.to_s,
            "hash" => hash,
            "rev" => rev,
        }

        response = @session.do_get "/metadata/#{@root}#{format_path(path)}", params
        if response.kind_of? Net::HTTPRedirection
            raise DropboxNotModified.new("metadata not modified")
        end
        Dropbox::parse_response(response)
    end

    # Search directory for filenames matching query
    #
    # Arguments:
    # * path: The directory to search within
    # * query: The query to search on (3 character minimum)
    # * file_limit: The maximum number of file entries to return/
    #   If the number of files exceeds this
    #   limit, an exception is raised. The server will return at max 1,000
    # * include_deleted: Whether to include deleted files in search results
    #
    # Returns:
    # * A Hash object with a list the metadata of the file or folders matching query
    #   inside path.  For a detailed description of what this call returns, visit:
    #   https://www.dropbox.com/developers/reference/api#search
    def search(path, query, file_limit=1000, include_deleted=false)
        params = {
            'query' => query,
            'file_limit' => file_limit.to_s,
            'include_deleted' => include_deleted.to_s
        }

        response = @session.do_get "/search/#{@root}#{format_path(path)}", params
        Dropbox::parse_response(response)
    end

    # Retrive revisions of a file
    #
    # Arguments:
    # * path: The file to fetch revisions for. Note that revisions
    #   are not available for folders.
    # * rev_limit: The maximum number of file entries to return within
    #   a folder. The server will return at max 1,000 revisions.
    #
    # Returns:
    # * A Hash object with a list of the metadata of the all the revisions of
    #   all matches files (up to rev_limit entries)
    #   For a detailed description of what this call returns, visit:
    #   https://www.dropbox.com/developers/reference/api#revisions
    def revisions(path, rev_limit=1000)
        params = {
            'rev_limit' => rev_limit.to_s
        }

        response = @session.do_get "/revisions/#{@root}#{format_path(path)}", params
        Dropbox::parse_response(response)
    end

    # Restore a file to a previous revision.
    #
    # Arguments:
    # * path: The file to restore. Note that folders can't be restored.
    # * rev: A previous rev value of the file to be restored to.
    #
    # Returns:
    # * A Hash object with a list the metadata of the file or folders restored
    #   For a detailed description of what this call returns, visit:
    #   https://www.dropbox.com/developers/reference/api#search
    def restore(path, rev)
        params = {
            'rev' => rev.to_s
        }

        response = @session.do_post "/restore/#{@root}#{format_path(path)}", params
        Dropbox::parse_response(response)
    end

    # Returns a direct link to a media file
    # All of Dropbox's API methods require OAuth, which may cause problems in
    # situations where an application expects to be able to hit a URL multiple times
    # (for example, a media player seeking around a video file). This method
    # creates a time-limited URL that can be accessed without any authentication.
    #
    # Arguments:
    # * path: The file to stream.
    #
    # Returns:
    # * A Hash object that looks like the following:
    #      {'url': 'https://dl.dropboxusercontent.com/1/view/abcdefghijk/example', 'expires': 'Thu, 16 Sep 2011 01:01:25 +0000'}
    def media(path)
        response = @session.do_get "/media/#{@root}#{format_path(path)}"
        Dropbox::parse_response(response)
    end

    # Get a URL to share a media file
    # Shareable links created on Dropbox are time-limited, but don't require any
    # authentication, so they can be given out freely. The time limit should allow
    # at least a day of shareability, though users have the ability to disable
    # a link from their account if they like.
    #
    # Arguments:
    # * path: The file to share.
    #
    # Returns:
    # * A Hash object that looks like the following example:
    #      {'url': 'https://db.tt/c0mFuu1Y', 'expires': 'Tue, 01 Jan 2030 00:00:00 +0000'}
    #   For a detailed description of what this call returns, visit:
    #    https://www.dropbox.com/developers/reference/api#shares
    def shares(path)
        response = @session.do_get "/shares/#{@root}#{format_path(path)}"
        Dropbox::parse_response(response)
    end

    # Download a thumbnail for an image.
    #
    # Arguments:
    # * from_path: The path to the file to be thumbnailed.
    # * size: A string describing the desired thumbnail size. At this time,
    #   'small' (32x32), 'medium' (64x64), 'large' (128x128), 's' (64x64),
    #   'm' (128x128), 'l' (640x640), and 'xl' (1024x1024) are officially supported sizes.
    #   Check https://www.dropbox.com/developers/reference/api#thumbnails
    #   for more details. [defaults to large]
    # Returns:
    # * The thumbnail data
    def thumbnail(from_path, size='large')
        response = thumbnail_impl(from_path, size)
        Dropbox::parse_response(response, raw=true)
    end

    # Download a thumbnail for an image along with the image's metadata.
    #
    # Arguments:
    # * from_path: The path to the file to be thumbnailed.
    # * size: A string describing the desired thumbnail size. See thumbnail()
    #   for details.
    # Returns:
    # * The thumbnail data
    # * The metadata for the image as a hash
    def thumbnail_and_metadata(from_path, size='large')
        response = thumbnail_impl(from_path, size)
        parsed_response = Dropbox::parse_response(response, raw=true)
        metadata = parse_metadata(response)
        return parsed_response, metadata
    end

    # A way of letting you keep a local representation of the Dropbox folder
    # heirarchy.  You can periodically call delta() to get a list of "delta
    # entries", which are instructions on how to update your local state to
    # match the server's state.
    #
    # Arguments:
    # * +cursor+: On the first call, omit this argument (or pass in +nil+).  On
    #   subsequent calls, pass in the +cursor+ string returned by the previous
    #   call.
    # * +path_prefix+: If provided, results will be limited to files and folders
    #   whose paths are equal to or under +path_prefix+.  The +path_prefix+ is
    #   fixed for a given cursor.  Whatever +path_prefix+ you use on the first
    #   +delta()+ must also be passed in on subsequent calls that use the returned
    #   cursor.
    #
    # Returns: A hash with three fields.
    # * +entries+: A list of "delta entries" (described below)
    # * +reset+: If +true+, you should reset local state to be an empty folder
    #   before processing the list of delta entries.  This is only +true+ only
    #   in rare situations.
    # * +cursor+: A string that is used to keep track of your current state.
    #   On the next call to delta(), pass in this value to return entries
    #   that were recorded since the cursor was returned.
    # * +has_more+: If +true+, then there are more entries available; you can
    #   call delta() again immediately to retrieve those entries.  If +false+,
    #   then wait at least 5 minutes (preferably longer) before checking again.
    #
    # Delta Entries: Each entry is a 2-item list of one of following forms:
    # * [_path_, _metadata_]: Indicates that there is a file/folder at the given
    #   path.  You should add the entry to your local state.  (The _metadata_
    #   value is the same as what would be returned by the #metadata() call.)
    #   * If the path refers to parent folders that don't yet exist in your
    #     local state, create those parent folders in your local state.  You
    #     will eventually get entries for those parent folders.
    #   * If the new entry is a file, replace whatever your local state has at
    #     _path_ with the new entry.
    #   * If the new entry is a folder, check what your local state has at
    #     _path_.  If it's a file, replace it with the new entry.  If it's a
    #     folder, apply the new _metadata_ to the folder, but do not modify
    #     the folder's children.
    # * [path, +nil+]: Indicates that there is no file/folder at the _path_ on
    #   Dropbox.  To update your local state to match, delete whatever is at
    #   _path_, including any children (you will sometimes also get separate
    #   delta entries for each child, but this is not guaranteed).  If your
    #   local state doesn't have anything at _path_, ignore this entry.
    #
    # Remember: Dropbox treats file names in a case-insensitive but case-preserving
    # way.  To facilitate this, the _path_ strings above are lower-cased versions of
    # the actual path.  The _metadata_ dicts have the original, case-preserved path.
    def delta(cursor=nil, path_prefix=nil)
        params = {
            'cursor' => cursor,
            'path_prefix' => path_prefix,
        }

        response = @session.do_post "/delta", params
        Dropbox::parse_response(response)
    end

    # Download a thumbnail (helper method - don't call this directly).
    #
    # Args:
    # * +from_path+: The path to the file to be thumbnailed.
    # * +size+: A string describing the desired thumbnail size. See thumbnail()
    #   for details.
    #
    # Returns:
    # * The HTTPResponse for the thumbnail request.
    def thumbnail_impl(from_path, size='large') # :nodoc:
        path = "/thumbnails/#{@root}#{format_path(from_path, true)}"
        params = {
            "size" => size
        }
        headers = nil
        content_server = true
        @session.do_get path, params, headers, content_server
    end
    private :thumbnail_impl


    # Creates and returns a copy ref for a specific file.  The copy ref can be
    # used to instantly copy that file to the Dropbox of another account.
    #
    # Args:
    # * +path+: The path to the file for a copy ref to be created on.
    #
    # Returns:
    # * A Hash object that looks like the following example:
    #      {"expires"=>"Fri, 31 Jan 2042 21:01:05 +0000", "copy_ref"=>"z1X6ATl6aWtzOGq0c3g5Ng"}
    def create_copy_ref(path)
        path = "/copy_ref/#{@root}#{format_path(path)}"
        response = @session.do_get path
        Dropbox::parse_response(response)
    end

    # Adds the file referenced by the copy ref to the specified path
    #
    # Args:
    # * +copy_ref+: A copy ref string that was returned from a create_copy_ref call.
    #   The copy_ref can be created from any other Dropbox account, or from the same account.
    # * +to_path+: The path to where the file will be created.
    #
    # Returns:
    # * A hash with the metadata of the new file.
    def add_copy_ref(to_path, copy_ref)
        params = {'from_copy_ref' => copy_ref,
                  'to_path' => "#{to_path}",
                  'root' => @root}

        response = @session.do_post "/fileops/copy", params
        Dropbox::parse_response(response)
    end

    #From the oauth spec plus "/".  Slash should not be ecsaped
    RESERVED_CHARACTERS = /[^a-zA-Z0-9\-\.\_\~\/]/  # :nodoc:

    def format_path(path, escape=true) # :nodoc:
        path = path.gsub(/\/+/,"/")
        # replace multiple slashes with a single one

        path = path.gsub(/^\/?/,"/")
        # ensure the path starts with a slash

        path.gsub(/\/?$/,"")
        # ensure the path doesn't end with a slash

        return URI.escape(path, RESERVED_CHARACTERS) if escape
        path
    end

end
