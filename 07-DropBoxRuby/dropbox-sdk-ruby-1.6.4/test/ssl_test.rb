require "test/unit"
require "../lib/dropbox_sdk"

class SSLTest < Test::Unit::TestCase

    # Called before every test method runs. Can be used
    # to set up fixture information.
    def setup
        @client = DropboxClient.new(ENV['DROPBOX_RUBY_SDK_ACCESS_TOKEN'])
    end

    def teardown
    end

    # Test Cases

    # Connection to Dropbox API
    # Should not raise exceptions
    def test_dropbox_connection
        Dropbox.module_eval do
            remove_const(:API_SERVER)
        end
        Dropbox.const_set("API_SERVER", "api.dropbox.com")
        @client.metadata('/')
    end

    # Connection to a host that presents a certificate for invalid hostname
    # Should raise DropboxError exception of the type 'SSL error'
    def test_hostname_validation
        Dropbox.module_eval do
            remove_const(:API_SERVER)
        end
        Dropbox.const_set("API_SERVER", "www.v.dropbox.com")
        begin
            @client.metadata('/')
        rescue  DropboxError => e
        end
        assert("#{e}".include? "SSL error")
    end

    # Connection to a host with an allowed certificate
    # Should raise DropboxError exception but not of the type 'SSL error'
    def test_valid_certificate
        Dropbox.module_eval do
            remove_const(:API_SERVER)
        end
        Dropbox.const_set("API_SERVER", "www.digicert.com")
        begin
            @client.metadata('/')
        rescue  DropboxError => e
        end
        assert(!("#{e}".include? "SSL error"))
    end

    # Connection to a host with a disallowed certificate
    # Should raise DropboxError exception of the type 'SSL error'
    def test_invalid_certificate
        Dropbox.module_eval do
            remove_const(:API_SERVER)
        end
        Dropbox.const_set("API_SERVER", "twitter.com")
        begin
            @client.metadata('/')
        rescue  DropboxError => e
        end
        assert("#{e}".include? "SSL error")
    end
end
