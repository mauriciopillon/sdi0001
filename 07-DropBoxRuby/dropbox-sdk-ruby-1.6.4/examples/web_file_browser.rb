# -------------------------------------------------------------------
# An example webapp that lets you browse and upload files to Dropbox.
# Demonstrates:
# - The webapp OAuth process.
# - The metadata() and put_file() calls.
#
# To set up:
# 1. Create a Dropbox App key and secret to use the API. https://www.dropbox.com/developers
# 2. Add http://localhost:4567/dropbox-auth-finish as a Redirect URI for your Dropbox app.
# 3. Copy your App key and App secret into APP_KEY and APP_SECRET below.
#
# To run:
# 1. Install Sinatra  $ gem install sinatra
# 2. Launch server    $ ruby web_file_browser.rb
# 3. Browse to        http://localhost:4567/
# -------------------------------------------------------------------

require 'rubygems'
require 'sinatra'
require 'pp'
require 'securerandom'
require File.expand_path('../../lib/dropbox_sdk', __FILE__)

# Get your app's key and secret from https://www.dropbox.com/developers/
APP_KEY = ''
APP_SECRET = ''

# -------------------------------------------------------------------
# OAuth stuff

def get_web_auth()
    return DropboxOAuth2Flow.new(APP_KEY, APP_SECRET, url('/dropbox-auth-finish'),
                                 session, :dropbox_auth_csrf_token)
end

get '/dropbox-auth-start' do
    authorize_url = get_web_auth().start()

    # Send the user to the Dropbox website so they can authorize our app.  After the user
    # authorizes our app, Dropbox will redirect them to our '/dropbox-auth-finish' endpoint.
    redirect authorize_url
end

get '/dropbox-auth-finish' do
    begin
        access_token, user_id, url_state = get_web_auth.finish(params)
    rescue DropboxOAuth2Flow::BadRequestError => e
        return html_page "Error in OAuth 2 flow", "<p>Bad request to /dropbox-auth-finish: #{e}</p>"
    rescue DropboxOAuth2Flow::BadStateError => e
        return html_page "Error in OAuth 2 flow", "<p>Auth session expired: #{e}</p>"
    rescue DropboxOAuth2Flow::CsrfError => e
        logger.info("/dropbox-auth-finish: CSRF mismatch: #{e}")
        return html_page "Error in OAuth 2 flow", "<p>CSRF mismatch</p>"
    rescue DropboxOAuth2Flow::NotApprovedError => e
        return html_page "Not Approved?", "<p>Why not, bro?</p>"
    rescue DropboxOAuth2Flow::ProviderError => e
        return html_page "Error in OAuth 2 flow", "Error redirect from Dropbox: #{e}"
    rescue DropboxError => e
        logger.info "Error getting OAuth 2 access token: #{e}"
        return html_page "Error in OAuth 2 flow", "<p>Error getting access token</p>"
    end

    # In this simple example, we store the authorized DropboxSession in the session.
    # A real webapp might store it somewhere more persistent.
    session[:access_token] = access_token
    redirect url('/')
end

get '/dropbox-unlink' do
    session.delete(:access_token)
    nil
end

# If we already have an authorized DropboxSession, returns a DropboxClient.
def get_dropbox_client
    if session[:access_token]
        return DropboxClient.new(session[:access_token])
    end
end

# -------------------------------------------------------------------
# File/folder display stuff

get '/' do
    # Get the DropboxClient object.  Redirect to OAuth flow if necessary.
    client = get_dropbox_client
    unless client
        redirect url("/dropbox-auth-start")
    end

    # Call DropboxClient.metadata
    path = params[:path] || '/'
    begin
        entry = client.metadata(path)
    rescue DropboxAuthError => e
        session.delete(:access_token)  # An auth error means the access token is probably bad
        logger.info "Dropbox auth error: #{e}"
        return html_page "Dropbox auth error"
    rescue DropboxError => e
        if e.http_response.code == '404'
            return html_page "Path not found: #{h path}"
        else
            logger.info "Dropbox API error: #{e}"
            return html_page "Dropbox API error"
        end
    end

    if entry['is_dir']
        render_folder(client, entry)
    else
        render_file(client, entry)
    end
end

def render_folder(client, entry)
    # Provide an upload form (so the user can add files to this folder)
    out = "<form action='/upload' method='post' enctype='multipart/form-data'>"
    out += "<label for='file'>Upload file:</label> <input name='file' type='file'/>"
    out += "<input type='submit' value='Upload'/>"
    out += "<input name='folder' type='hidden' value='#{h entry['path']}'/>"
    out += "</form>"  # TODO: Add a token to counter CSRF attacks.
    # List of folder contents
    entry['contents'].each do |child|
        cp = child['path']      # child path
        cn = File.basename(cp)  # child name
        if (child['is_dir']) then cn += '/' end
        out += "<div><a style='text-decoration: none' href='/?path=#{h cp}'>#{h cn}</a></div>"
    end

    html_page "Folder: #{entry['path']}", out
end

def render_file(client, entry)
    # Just dump out metadata hash
    html_page "File: #{entry['path']}", "<pre>#{h entry.pretty_inspect}</pre>"
end

# -------------------------------------------------------------------
# File upload handler

post '/upload' do
    # Check POST parameter.
    file = params[:file]
    unless file && (temp_file = file[:tempfile]) && (name = file[:filename])
        return html_page "Upload error", "<p>No file selected.</p>"
    end

    # Get the DropboxClient object.
    client = get_dropbox_client
    unless client
        return html_page "Upload error", "<p>Not linked with a Dropbox account.</p>"
    end

    # Call DropboxClient.put_file
    begin
        entry = client.put_file("#{params[:folder]}/#{name}", temp_file.read)
    rescue DropboxAuthError => e
        session.delete(:access_token)  # An auth error means the access token is probably bad
        logger.info "Dropbox auth error: #{e}"
        return html_page "Dropbox auth error"
    rescue DropboxError => e
        logger.info "Dropbox API error: #{e}"
        return html_page "Dropbox API error"
    end

    html_page "Upload complete", "<pre>#{h entry.pretty_inspect}</pre>"
end

# -------------------------------------------------------------------

def html_page(title, body='')
    "<html>" +
        "<head><title>#{h title}</title></head>" +
        "<body><h1>#{h title}</h1>#{body}</body>" +
    "</html>"
end

# Rack will issue a warning if no session secret key is set.  A real web app would not have
# a hard-coded secret in the code but would load it from a config file.
use Rack::Session::Cookie, :secret => 'dummy_secret'

set :port, 5000
enable :sessions

helpers do
    include Rack::Utils
    alias_method :h, :escape_html
end

if APP_KEY == '' or APP_SECRET == ''
    puts "You must set APP_KEY and APP_SECRET at the top of \"#{__FILE__}\"!"
    exit 1
end
