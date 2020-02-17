# Install this the SDK with "gem install dropbox-sdk"
require 'dropbox-sdk'

client = DropboxClient.new("bV9CF_mwE-AAAAAAAAAA5ETu8J-UG20GYxupJGsoHxnDEWr_kqr0r384qDQREKay")
#puts client.account_info()["display_name"]
puts client.account_info()["uid"]
