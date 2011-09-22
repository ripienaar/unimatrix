module UM
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
            def atomic_file(target, user=:currentuser, group=:currentgroup, mode=0644, tempdir=Dir.tmpdir)
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

            def config_logger(configkey)
                Config.loadconfig("logger")
                if Config[configkey].include?(:logger)
                    Config["logger"].merge!(Config[configkey][:logger])
                end
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

                daemonize(configkey)

                Log.info("#{configkey} starting daemonized: #{Config[configkey][:daemonize]}")

                klass.new.run
            end

            # Sets up an application using the Daemons gem, looks in the config for:
            #
            #  - multiple_instance - true to allow multiple daemons to run
            #  - daemonize         - true to run in the background
            def daemonize(configkey)
                options = {}

                options[:multiple] = Config[configkey][:multiple_instances] || false
                options[:ontop] = !Config[configkey][:daemonize]
                options[:app_name] = configkey.gsub(".", "_")
                options[:dir_mode] = :normal
                options[:log_output] = true
                options[:log_dir] = File.dirname(Config["logger"][:logfile]) || "/var/log/unimatrix"
                options[:dir] = options[:log_dir]

                require 'pp'; pp options
                Daemons.daemonize(options)
            end
        end
    end
end
