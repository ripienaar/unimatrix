module UM
    class StompConsumer
        attr_reader :connection, :retries, :dlq, :origin, :name, :stats, :router, :configkey, :routingkey

        def config(name, configkey, routingkey)
            @name = name
            @configkey = configkey
            @routingkey = routingkey

            raise "should respond to on_message" unless respond_to?(:on_message)

            Util.config_logger(configkey)

            @dlq = Config[configkey][:dlq]
            @origin = name unless @origin
            @retries = 6 unless @retries
            @router = Router.new(routingkey)

            Log.info("StompConsumer #{name} starting with dlq=#{dlq} and #{retries} retries")

            @connection = StompConnector.connectstomp(configkey)
        end

        def run
            subscribe Config[configkey][:consume]

            @stats = Stats.new(name, origin, connection) if Config[configkey][:keepstats]

            consume
        end

        def subscribe(sources)
            [sources].flatten.each do |source|
                Log.debug("Subscribing to #{source}")
                connection.subscribe source
            end
        end

        def publish(event)
            router.route(event).each do |route|
                if event.is_a?(String)
                    connection.publish(route, event)
                else
                    connection.publish(route, event.to_json)
                end
            end
        end

        def on_message(msg)
            event = Event.new(JSON.load(msg))

            publish event
        end

        def consume
            loop do
                begin
                    connection.safe_receive(retries, dlq) do |msg|
                        stats.increment if Config[configkey][:keepstats]

                        on_message(msg)
                    end
                rescue Interrupt
                    Log.warn("Exiting on interrupt")
                    exit!
                rescue Exception => e
                    Log.error("Failed to receive messages from the portal: #{e.class}: #{e}")
                    sleep 2
                end
            end
        end
    end
end
