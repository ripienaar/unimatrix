module UM
    class Event
        def initialize(event={})
            merge!(event)

            validate
        end

        def merge!(event)
            @event = empty_event unless @event
            @event.merge!(event)
        end

        def validate
            raise "Events require a subject and name" unless @event["subject"] && @event["name"]
            raise "Event type should be %s" % [valid_types.join(', ')] unless valid_types.include?(@event["type"])
        end

        def valid_types
            ["archive", "metric", "status"]
        end

        def to_status
            status = {}

            ["eventtime", "severity", "name", "text", "eventid", "subject", "origin", "tags", "type"].each do |k|
                status[k] = @event[k]
            end

            status
        end

        def to_metric
            metric = {}

            ["name", "subject", "eventtime", "origin", "eventid", "metrics", "tags", "type"].each do |k|
                metric[k] = @event[k]
            end

            metric
        end

        def to_json
            to_hash.to_json
        end

        def to_hash
            @event.reject{|k,v| v == nil}
        end

        def to_s
            "#<UM::Event:#{eventtime}: #{subject}.#{name}>"
        end

        def [](key)
            @event[key]
        end

        def []=(key, val)
            @event[key] = val
        end

        def include?(key)
            @event.include?(key)
        end

        def metrics
            @event["metrics"]
        end

        def tags
            @event["tags"]
        end

        def empty_event
            {"eventtime"     => Util.timestamp,
             "severity"      => nil,
             "text"          => nil,
             "origin"        => nil,
             "metrics"       => {},
             "tags"          => {}}
        end

        def method_missing(method, *args, &block)
            super unless @event.include?(method.to_s)

            @event[method.to_s]
        end
    end
end
