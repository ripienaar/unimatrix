module UM
    class Stats
        attr_reader :options, :lastsent, :metrics, :connection, :frequency, :portal

        def initialize(name, origin, connection=nil, options={})
            require 'pp'

            options["subject"] = %x{hostname -f}.chomp unless options.include?("subject")
            options["type"] = "metric" unless options.include?("type")

            options["origin"] = origin
            options["name"] = name

            Config.loadconfig("stats")

            @options = options
            @connection = connection

            reset

            if connection
                raise "UM::Stats need unimatrix.stats config settings" unless Config.include?("stats")

                [:frequency, :portal].each do |c|
                    raise "Config should include unimatrix.stats.#{c}" unless Config["stats"].include?(c)
                end

                @frequency = Config["stats"][:frequency]
                @portal = Config["stats"][:portal]

                start_publisher
            end
        end

        def should_publish?(seconds)
            (Time.now.utc.to_i - lastsent) > seconds
        end

        def start_publisher
            Thread.new {
                loop do
                    begin
                        publish
                        sent
                    rescue Exception => e
                        Log.error("Failed to publish stats: #{e.class}: #{e}")
                    end

                    Log.debug("Sleeping #{frequency} seconds after publishing stats: #{@metrics.pretty_inspect}".chomp)
                    sleep frequency
                end
            }
        end

        def to_event
            event = Event.new(options)
            event.metrics.merge!(metrics)

            size, resident, shared, text, lib, data, dt = File.read("/proc/self/statm").split(" ")

            event.metrics["memsize"] = size.to_i * 4096
            event.metrics["memresident"] = resident.to_i * 4096
            event.metrics["memshared"] = shared.to_i * 4096

            if UM::Config["stats"].include?(:archive)
                # only include the archive option to disable it, else dont add it
                # and it will get archived, saves b/w and storage
                event["archive"] = false unless UM::Config["stats"][:archive]
            end

            event
        end

        def to_json
            to_event.to_json
        end

        def reset
            @metrics = {"events" => 0}
            sent
        end

        def publish
            if connection.respond_to?(:publish)
                connection.publish(portal, to_json)
            else
                Util.atomic_file(Util.spool_file_name(connection)) do |f|
                    f.print to_json
                end
            end
        end

        def sent
            @lastsent = Time.now.utc.to_i
        end

        def [](key)
            @metrics[key]
        end

        def []=(key, val)
            @metrics[key] = val
        end

        def increment(key="events")
            @metrics[key] += 1 rescue @metrics[key] = 1
        end
    end
end
