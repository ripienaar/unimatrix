module UM
    class RouterInstance
        attr_reader :options, :router, :name, :type

        def initialize(routerfile)
            instance_eval(File.read(routerfile))
        end

        def call(event, routes)
            @router.call(event, routes)
        end

        def add_route(options, &blk)
            raise "routes need a name" unless options.include?(:name)
            raise "routes need a type" unless options.include?(:type)

            Log.debug("Creating route #{options[:name]}")

            @options = options
            @router = blk
            @name = options[:name]
            @type = options[:type]

            Router.register_router(options[:name], options[:type], self)
        end
    end
end
