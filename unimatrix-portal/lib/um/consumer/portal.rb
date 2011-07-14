module UM
    module Consumer
        class Portal<StompConsumer
            def initialize
                @name = "unimatrix.consumer.portal"
                @configkey = "consumer.portal"
                @routingkey = "portal"

                #@mongodb = MongoStorage.new(Config[configkey][:archive][:database], Config[configkey][:archive][:collection])
                #@callbacks = CallbackRouter.new("portal")

                config
            end

            def callback(event)
                @callbacks.callback(event, @connection)
            end

            def archive(event)
                should_save = true
                should_save = event["archive"] if event.include?("archive")

                if should_save
                    if event.include?("metrics")
                        newmetrics = {}

                        event["metrics"].each_pair do |metric, value|
                            metric = metric.gsub(".", "__")
                            newmetrics[metric] = value
                        end

                        event["metrics"] = newmetrics
                    end

                    event["eventid"] = @mongodb.collection.save(event.to_hash).to_s
                end
            end

            def on_message(msg)
                event = Event.new(JSON.load(msg))

                pp event

                #archive event
                #publish event
                #callback event
            end
        end
    end
end
