module UM
    class MongoStorage
        attr_reader :collection

        def initialize(db, collection)
            require 'mongo'

            @connection = Mongo::Connection.new("localhost", nil, :safe => true).db(db)
            @collection = @connection.collection(collection)
        end
    end
end
