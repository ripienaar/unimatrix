module UM
    class StompConnector
        attr_reader :connection

        def initialize(hosts, options={})
            require 'stomp'

            conn = {:hosts => hosts}
            conn.merge!(options)

            @connection = Stomp::Connection.new(conn)
        end

        def self.connectstomp(configkey)
            if Config[configkey].include?(:stomp)
                StompConnector.new(Config[configkey][:stomp][:servers], Config[configkey][:stomp][:options])
            else
                Config.loadconfig("stomp")
                StompConnector.new(Config["stomp"][:servers], Config["stomp"][:options])
            end
        end

        def poll
            @connection.poll
        end

        def subscribed_to?(destination)
            subscriptions.include?(destination)
        end

        def subscriptions
            @connection.instance_variable_get("@subscriptions")
        end

        def subscribe(sources)
            [sources].flatten.each do |source|
                Log.debug("Subscribing to #{source}")
                connection.subscribe(source)
            end
        end

        def unsubscribe(sources)
            [sources].flatten.each do |source|
                Log.debug("Unsubscribing from #{source}")
                connection.unsubscribe(source)
            end
        end

        def receive
            connection.receive
        end

        def publish(target, message, headers={})
            connection.publish(target, message, headers)
        end

        def safe_receive(retries, dlq, &blk)
            msg = receive

            begin
                if blk.arity == 1
                    blk.call(msg.body.clone)
                elsif blk.arity == 2
                    blk.call(msg.body.clone, msg.headers.clone)
                end
            rescue Exception => e
                Log.warn("Handling message from middleware failed: #{e.class}: #{e}")
                Log.warn(e.backtrace.join("\n\t"))
                connection.unreceive(msg, :max_redeliveries => retries, :dead_letter_queue => dlq)
                sleep 1
            end
        end
    end
end
