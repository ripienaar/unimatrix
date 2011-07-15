module UM
    module Consumer
        # the main portal entry point to the event system
        #
        # It will save the event to a MongoDB archive and obtain a unique
        # ID from MongoDB that will become the event id.
        #
        # It will then route the message based on the routers but typically
        # to metric and status destinations, though anything that can be done
        # with routes can be destinations.
        #
        # You can run multiple instances of this router but if you are using
        # topics as portals you should ensure that each instance of the portal
        # has unique topics.  If you use queues then no problem just start as
        # many as you need
        class Portal<StompConsumer
            def initialize
                config("unimatrix.consumer.portal", "consumer.portal", "portal")

                @mongodb = MongoStorage.new(Config[configkey][:archive][:database], Config[configkey][:archive][:collection])
            end

            def archive(event)
                if event.include?("metrics")
                    newmetrics = {}

                    event["metrics"].each_pair do |metric, value|
                        # map .'s in metric names to __ because mongo is stupid
                        metric = metric.gsub(".", "__")
                        newmetrics[metric] = value
                    end

                    event["metrics"] = newmetrics
                end

                event["eventid"] = @mongodb.collection.save(event.to_hash).to_s
            end

            def on_message(msg)
                event = Event.new(JSON.load(msg))

                archive event
                publish event
            end
        end
    end
end
