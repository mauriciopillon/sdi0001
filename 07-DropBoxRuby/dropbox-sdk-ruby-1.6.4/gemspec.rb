# Build with: gem build gemspec.rb
Gem::Specification.new do |s|
    s.name = "dropbox-sdk"

    s.version = "1.6.4"
    s.license = 'MIT'

    s.authors = ["Dropbox, Inc."]
    s.email = ["support-api@dropbox.com"]

    s.add_dependency "json"

    s.homepage = "http://www.dropbox.com/developers/"
    s.summary = "Dropbox REST API Client."
    s.description = <<-EOF
        A library that provides a plain function-call interface to the
        Dropbox API web endpoints.
    EOF

    s.files = [
        "CHANGELOG", "LICENSE", "README",
        "examples/cli_example.rb", "examples/dropbox_controller.rb", "examples/web_file_browser.rb",
        "examples/copy_between_accounts.rb", "examples/chunked_upload.rb", "examples/oauth1_upgrade.rb",
        "examples/search_cache.rb",
        "lib/dropbox_sdk.rb", "lib/trusted-certs.crt",
    ]
end
