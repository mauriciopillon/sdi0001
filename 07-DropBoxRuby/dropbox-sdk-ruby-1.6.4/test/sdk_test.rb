require "test/unit"
require "../lib/dropbox_sdk"
require "securerandom"
require "set"

class SDKTest < Test::Unit::TestCase

    # Called before every test method runs. Can be used
    # to set up fixture information.
    def setup
        #@client = DropboxClient.new(ENV['DROPBOX_RUBY_SDK_ACCESS_TOKEN'])
        @client = DropboxClient.new(ENV['bV9CF_mwE-AAAAAAAAAACk1uSh9BBfEW3njWnALZYrYKHp9pdRGi27_zLY6neJ3o'])

        @foo = "testfiles/foo.txt"
        @frog = "testfiles/Costa Rican Frog.jpg"
        @song = "testfiles/dropbox_song.mp3"

        @test_dir = "/Ruby SDK Tests/" + Time.new.strftime("%Y-%m-%d %H.%M.%S") + "/"
    end

    def teardown
        unless @test_dir.nil?
            @client.file_delete(@test_dir)
        end
    end

    def hash_has(dict, options={}, *more)
        for key in more
            assert(dict.has_key?(key))
        end
        options.each do |key, value|
            assert_equal(value, dict[key])
        end
    end
    def assert_file(file, metadata, options={}, *more)
        hash_has(metadata,
            {
                "bytes" => File.size(file),
                "is_dir" => false
            }.merge(options),
            *more.concat(['revision', 'rev', 'size', 'modified'])
        )

    end

    def open_binary(filename)
        File.open(filename, 'rb') { |io| io.read }
    end
    def upload(filename, path, overwrite=false, parent_rev=nil)
        @client.put_file(path, open_binary(filename), overwrite, parent_rev)
    end

    def test_puts
        def assert_put(file, path)
            file_path = @test_dir + "put" + path
            result = @client.put_file(file_path, open(file, "rb"))
            assert_file(file, result, "path" => file_path)
        end

        assert_put(@foo, "foo.txt")
        assert_put(@frog, "frog.jpg")
        assert_put(@song, "song.mp3")
    end
    # Fake test


    def test_gets
        def assert_get(file, path)
            file_path = @test_dir + "get" + path
            upload(file, file_path)
            result = @client.get_file(file_path)
            local = open_binary(file)
            assert_equal(result.length, local.length)
            assert_equal(result, local)
        end

        assert_get(@foo, "foo.txt")
        assert_get(@frog, "frog.txt")
        assert_get(@song, "song.txt")
    end

    def test_metadatas
        def assert_metadata(file, path)
            file_path = @test_dir + "meta" + path
            upload(file, file_path)
            result = @client.metadata(file_path)
            assert_file(file, result, "path" => file_path)
        end
        assert_metadata(@foo, "foo.txt")
        assert_metadata(@frog, "frog.txt")
        assert_metadata(@song, "song.txt")
    end

    def test_create_folder
        path = @test_dir + "new_folder"
        result = @client.file_create_folder(path)
        assert_equal(result['size'], '0 bytes')
        assert_equal(result['bytes'], 0)
        assert_equal(result['path'], path)
        assert_equal(result['is_dir'], true)
    end

    def test_delete
        path = @test_dir + "delfoo.txt"
        upload(@foo, path)
        metadata = @client.metadata(path)
        assert_file(@foo, metadata, "path" => path)

        del_metadata = @client.file_delete(path)
        assert_file(@foo, del_metadata, "path" => path, "is_deleted" => true, "bytes" => 0)

    end

    def test_copy
        path = @test_dir + "copyfoo.txt"
        path2 = @test_dir + "copyfoo2.txt"
        upload(@foo, path)
        @client.file_copy(path, path2)
        metadata = @client.metadata(path)
        metadata2 = @client.metadata(path2)

        assert_file(@foo, metadata, "path" => path)
        assert_file(@foo, metadata2, "path" => path2)
    end

    def test_move
        path = @test_dir + "movefoo.txt"
        path2 = @test_dir + "movefoo2.txt"
        upload(@foo, path)
        @client.file_move(path, path2)

        metadata = @client.metadata(path)
        assert_file(@foo, metadata, "path" => path, "is_deleted" => true, "bytes" => 0)

        metadata = @client.metadata(path2)
        assert_file(@foo, metadata, "path" => path2)
    end

    def test_stream
        path = @test_dir + "/stream_song.mp3"
        upload(@song, path)
        link = @client.media(path)
        hash_has(link, {},
            "url",
            "expires"
        )
    end
    def test_share

        path = @test_dir + "/stream_song.mp3"
        upload(@song, path)
        link = @client.shares(path)
        hash_has(link, {},
            "url",
            "expires"
        )
    end
    def test_search

        path = @test_dir + "/search/"

        upload(@foo, path + "text.txt");
        upload(@foo, path + "subFolder/text.txt");
        upload(@foo, path + "subFolder/cow.txt");
        upload(@frog, path + "frog.jpg");
        upload(@frog, path + "frog2.jpg");
        upload(@frog, path + "subFolder/frog2.jpg");

        results = @client.search(path, "sasdfasdf")
        assert_equal(results, [])
        results = @client.search(path, "jpg")
        assert_equal(results.length, 3)

        for metadata in results
            assert_file(@frog, metadata)
        end

        results = @client.search(path + "subFolder", "jpg")
        assert_equal(results.length, 1)
        assert_file(@frog, results[0])

    end

    def test_revisions_restore

        path = @test_dir + "foo_revs.txt"
        upload(@foo, path)
        upload(@frog, path, overwrite = true)
        upload(@song, path, overwrite = true)
        revs = @client.revisions(path)
        metadata = @client.metadata(path)
        assert_file(@song, metadata, "path" => path, "mime_type" => "text/plain")

        assert_equal(revs.length, 3)
        assert_file(@song, revs[0], "path" => path, "mime_type" => "text/plain")
        assert_file(@frog, revs[1], "path" => path, "mime_type" => "text/plain")
        assert_file(@foo, revs[2], "path" => path, "mime_type" => "text/plain")

        metadata = @client.restore(path, revs[2]["rev"])
        assert_file(@foo, metadata, "path" => path, "mime_type" => "text/plain")
        metadata = @client.metadata(path)
        assert_file(@foo, metadata, "path" => path, "mime_type" => "text/plain")
    end

    def test_copy_ref

        path = @test_dir + "foo_copy_ref.txt"
        path2 = @test_dir + "foo_copy_ref_target.txt"

        upload(@foo, path)
        copy_ref = @client.create_copy_ref(path)
        hash_has(copy_ref, {},
            "expires",
            "copy_ref"
        )

        copied = @client.add_copy_ref(path2, copy_ref["copy_ref"])
        metadata = @client.metadata(path2)
        assert_file(@foo, metadata, "path" => path2)
        copied_foo = @client.get_file(path2)
        local_foo = open(@foo, "rb").gets
        assert_equal(copied_foo.length, local_foo.length)
        assert_equal(copied_foo, local_foo)
    end

    def test_chunked_upload
        path = @test_dir + "chunked_upload_file.txt"
        size = 1024*1024*10
        chunk_size = 4 * 1024 * 1102


        random_data = SecureRandom.random_bytes(n=size)
        uploader = @client.get_chunked_uploader(StringIO.new(random_data), size)
        error_count = 0
        while uploader.offset < size and error_count < 5
            begin
                upload = uploader.upload(chunk_size = chunk_size)
            rescue DropboxError => e
                error_count += 1
            end
        end
        uploader.finish(path)
        downloaded = @client.get_file(path)
        assert_equal(size, downloaded.length)
        assert_equal(random_data, downloaded)
    end

    def test_delta
        prefix = @test_dir + "delta"

        a = prefix + "/a.txt"
        upload(@foo, a)
        b = prefix + "/b.txt"
        upload(@foo, b)
        c = prefix + "/c"
        c_1 = prefix + "/c/1.txt"
        upload(@foo, c_1)
        c_2 = prefix + "/c/2.txt"
        upload(@foo, c_2)

        prefix_lc = prefix.downcase
        c_lc = c.downcase

        # /delta on everything
        expected = Set.new [prefix, a, b, c, c_1, c_2].map {|p| p.downcase}
        entries = Set.new
        cursor = nil
        while true
            r = @client.delta(cursor)
            entries = Set.new if r['reset']
            r['entries'].each { |path_lc, md|
                if path_lc.start_with?(prefix_lc+'/') || path_lc == prefix_lc
                    assert(md != nil)  # we should never get deletes under 'prefix'
                    entries.add path_lc
                end
            }
            if not r['has_more']
                break
            end
            cursor = r['cursor']
        end

        assert_equal(expected, entries)

        # /delta where path_prefix=c
        expected = Set.new [c, c_1, c_2].map {|p| p.downcase}
        entries = Set.new
        cursor = nil
        while true
            r = @client.delta(cursor, c)
            entries = Set.new if r['reset']
            r['entries'].each { |path_lc, md|
                assert path_lc.start_with?(c_lc+'/') || path_lc == c_lc
                assert(md != nil)  # we should never get deletes
                entries.add path_lc
            }
            if not r['has_more']
                break
            end
            cursor = r['cursor']
        end

        assert_equal(expected, entries)
    end
end
