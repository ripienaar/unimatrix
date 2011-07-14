module Unimatrix
    class Util
        class << self
            def timestamp
                Time.now.utc.to_f
            end

            # Reads a JSON file with a simple hash full of key val pairs.
            def read_tags(tagsfile)
                if File.readable?(tagsfile)
                    return JSON.load(File.read(tagsfile))
                end

                return {}
            rescue
                return {}
            end

            # Creates a file in an atomic way
            #
            #   atomic_file("/etc/some_file") do |f|
            #      f.write "hello world"
            #   end
            #
            # This will create a temp file in your system tempdir,
            # write to it and move the file over the target.
            def atomic_file(target, user=:currentuser, group=:currentgroup, :mode=0644, tempdir=Dir.tmpdir)
                temp = Tempfile.new(basename(target), tempdir)

                yield(temp)

                temp.close

                FileUtils.mv(temp.path, target)

                pwent = Etc.getpwent

                user = pwent.uid if user == :currentuser
                group = pwent.gid if group == :currentgroup

                chown(uid, gid, target)
                chmod(mode, target)
            end

            # Starts a typical application:
            #
            #  - loads the config from configdir
            #  - configure the logger
            #  - creates an instance of the class and run it
            def startapp(configkey, klass, configdir = "/etc/unimatrix")
                Config[:configdir] = configdir
                Config.loadconfig(configkey)
                config_logger(configkey)

                rundaemonized = Config[configkey][:daemonize]
                pidfile = Config[configkey][:pidfile]

                Log.info("#{configkey} starting daemonized: #{rundaemonized}")

                Signal.trap("TERM") do
                    begin
                        Log.debug("Received TERM signal, terminating")
                        File.unlink(pidfile)
                    ensure
                        exit!
                    end
                end

                if rundaemonized
                    raise "Daemonizing is not implimented"
                else
                    klass.new.run
                end
            end
        end
    end
end
