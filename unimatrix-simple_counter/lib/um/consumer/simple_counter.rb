module UM
    module Consumer
        class SimpleCounter<StompConsumer
            def initialize
                config("unimatrix.consumer.simple_counter", "consumer.simple_counter", "simple_counter")

                @total = MongoStorage.new(Config[configkey][:archive][:database], Config[configkey][:archive][:total_collection])
                @hour = MongoStorage.new(Config[configkey][:archive][:database], Config[configkey][:archive][:hour_collection])
                @month = MongoStorage.new(Config[configkey][:archive][:database], Config[configkey][:archive][:month_collection])
            end

            def count(event)
                counter = [event["subject"], event["name"]].join(".")

                time = Time.at(event["eventtime"])
                hour = time.truncate(:hour).utc
                month = time.truncate(:day).truncate(:month).utc
                count = event["metrics"]["count"]

                @total.collection.update({"counter" => counter}, {"$inc" => {"value" => count}}, :upsert => true)
                @hour.collection.update({"counter" => counter, "time" => hour}, {"$inc" => {"value" => count}}, :upsert => true)
                @month.collection.update({"counter" => counter, "time" => month}, {"$inc" => {"value" => count}}, :upsert => true)
            end

            def on_message(msg)
                event = Event.new(JSON.load(msg))

                count event
            end
        end
    end
end
