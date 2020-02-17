require File.expand_path('../../lib/dropbox_sdk', __FILE__)
require 'pp'

# You must use your Dropbox App key and secret to use the API.
# Find this at https://www.dropbox.com/developers
APP_KEY = ''
APP_SECRET = ''

def main
    if APP_KEY == '' or APP_SECRET == ''
        warn "ERROR: Set your APP_KEY and APP_SECRET at the top of search_cache.rb"
        exit
    end

    prog_name = __FILE__
    args = ARGV
    if args.size != 2
        warn "Usage: #{prog_name} <oauth1-access-token-key> <oauth1-access-token-secret>"
        exit 1
    end

    access_token_key = args[0]
    access_token_secret = args[1]

    sess = DropboxSession.new(APP_KEY, APP_SECRET)
    sess.set_access_token(access_token_key, access_token_secret)
    c = DropboxClient.new(sess)

    print "Creating OAuth 2 access token...\n"
    oauth2_access_token = c.create_oauth2_access_token

    print "Using OAuth 2 access token to get account info...\n"
    c2 = DropboxClient.new(oauth2_access_token)
    pp c2.account_info

    print "Disabling OAuth 1 access token...\n"
    c.disable_access_token
end

main()
