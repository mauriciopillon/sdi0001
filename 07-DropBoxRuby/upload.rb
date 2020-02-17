# Install this the SDK with "gem install dropbox-sdk"
require 'dropbox_sdk'

# Get your app key and secret from the Dropbox developer website
APP_KEY = '8eplwhw62r806nw'
APP_SECRET = 'a84bu8lrh2c0f2i'

flow = DropboxOAuth2FlowNoRedirect.new(APP_KEY, APP_SECRET)
authorize_url = flow.start()
# Have the user sign in and authorize this app
puts '1. Go to: ' + authorize_url
puts '2. Click "Allow" (you might have to log in first)'
puts '3. Copy the authorization code'
print 'Enter the authorization code here: '
code = gets.strip
# This will fail if the user gave us an invalid authorization code
access_token, user_id = flow.finish(code)

client = DropboxClient.new(access_token)
puts "linked account:", client.account_info().inspect

file = open('foo.txt')
response = client.put_file('/magnum-opus.txt', file)
puts "uploaded:", response.inspect

