require File.expand_path('../../lib/dropbox_sdk', __FILE__)
require 'pp'
require 'shellwords'

####
# An example app using the Dropbox API Ruby Client
#   This ruby script sets up a basic command line interface (CLI)
#   that prompts a user to authenticate on the web, then
#   allows them to type commands to manipulate their dropbox.
####

# You must use your Dropbox App key and secret to use the API.
# Find this at https://www.dropbox.com/developers
APP_KEY = '8eplwhw62r806nw'
APP_SECRET = 'a84bu8lrh2c0f2i'

class DropboxCLI
    LOGIN_REQUIRED = %w{put get cp mv rm ls mkdir info logout search thumbnail}

    def initialize
        if APP_KEY == '' or APP_SECRET == ''
            puts "You must set your APP_KEY and APP_SECRET in cli_example.rb!"
            puts "Find this in your apps page at https://www.dropbox.com/developers/"
            exit
        end

        @client = nil
    end

    def login
        if not @client.nil?
            puts "already logged in!"
        else
            web_auth = DropboxOAuth2FlowNoRedirect.new(APP_KEY, APP_SECRET)
            authorize_url = web_auth.start()
            puts "1. Go to: #{authorize_url}"
            puts "2. Click \"Allow\" (you might have to log in first)."
            puts "3. Copy the authorization code."

            print "Enter the authorization code here: "
            STDOUT.flush
            auth_code = STDIN.gets.strip

            access_token, user_id = web_auth.finish(auth_code)

            @client = DropboxClient.new(access_token)
            puts "You are logged in.  Your access token is #{access_token}."
        end
    end

    def command_loop
        puts "Enter a command or 'help' or 'exit'"
        command_line = ''
        while command_line.strip != 'exit'
            begin
                execute_dropbox_command(command_line)
            rescue RuntimeError => e
                puts "Command Line Error! #{e.class}: #{e}"
                puts e.backtrace
            end
            print '> '
            command_line = gets.strip
        end
        puts 'goodbye'
        exit(0)
    end

    def execute_dropbox_command(cmd_line)
        command = Shellwords.shellwords cmd_line
        method = command.first
        if LOGIN_REQUIRED.include? method
            if @client
                send(method.to_sym, command)
            else
                puts 'must be logged in; type \'login\' to get started.'
            end
        elsif ['login', 'help'].include? method
            send(method.to_sym)
        else
            if command.first && !command.first.strip.empty?
                puts 'invalid command. type \'help\' to see commands.'
            end
        end
    end

    def logout(command)
        @client = nil
        puts "You are logged out."
    end

    def put(command)
        fname = command[1]

        #If the user didn't specifiy the file name, just use the name of the file on disk
        if command[2]
            new_name = command[2]
        else
            new_name = File.basename(fname)
        end

        if fname && !fname.empty? && File.exists?(fname) && (File.ftype(fname) == 'file') && File.stat(fname).readable?
            #This is where we call the the Dropbox Client
            pp @client.put_file(new_name, open(fname))
        else
            puts "couldn't find the file #{ fname }"
        end
    end

    def get(command)
        dest = command[2]
        if !command[1] || command[1].empty?
            puts "please specify item to get"
        elsif !dest || dest.empty?
            puts "please specify full local path to dest, i.e. the file to write to"
        elsif File.exists?(dest)
            puts "error: File #{dest} already exists."
        else
            src = clean_up(command[1])
            out,metadata = @client.get_file_and_metadata('/' + src)
            puts "Metadata:"
            pp metadata
            open(dest, 'w'){|f| f.puts out }
            puts "wrote file #{dest}."
        end
    end

    def mkdir(command)
        pp @client.file_create_folder(command[1])
    end

    # Example:
    # > thumbnail pic1.jpg ~/pic1-local.jpg large
    def thumbnail(command)
        dest = command[2]
        command[3] ||= 'small'
        out,metadata = @client.thumbnail_and_metadata(command[1], command[3])
        puts "Metadata:"
        pp metadata
        open(dest, 'w'){|f| f.puts out }
        puts "wrote thumbnail#{dest}."
    end

    def cp(command)
        src = clean_up(command[1])
        dest = clean_up(command[2])
        pp @client.file_copy(src, dest)
    end

    def mv(command)
        src = clean_up(command[1])
        dest = clean_up(command[2])
        pp @client.file_move(src, dest)
    end

    def rm(command)
        pp @client.file_delete(clean_up(command[1]))
    end

    def search(command)
        resp = @client.search('/',clean_up(command[1]))

        for item in resp
            puts item['path']
        end
    end

    def info(command)
        pp @client.account_info
    end

    def ls(command)
        command[1] = '/' + clean_up(command[1] || '')
        resp = @client.metadata(command[1])

        if resp['contents'].length > 0
            for item in resp['contents']
                puts item['path']
            end
        end
    end

    def help
        puts "commands are: login #{LOGIN_REQUIRED.join(' ')} help exit"
    end

    def clean_up(str)
        return str.gsub(/^\/+/, '') if str
        str
    end
end

cli = DropboxCLI.new
cli.command_loop
