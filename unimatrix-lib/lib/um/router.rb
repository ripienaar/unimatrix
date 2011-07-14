module UM
    class Router
        attr_reader :routingkey

        class << self
            def register_router(name, types, router)
                @routers ||= {}

                [types].flatten.each do |type|
                    @routers[type] ||= {}
                    @routers[type][name] = router
                end
            end

            def routers
                @routers || []
            end
        end

        def initialize(key)
            @routingkey = key

            Config.loadconfig("routes")
        end

        def route(event)
            return [] unless event.include?("type")

            loadroutes
            type = event["type"]
            routes = []

            if Router.routers.include?(type)
                Router.routers[type].each_pair do |name, router|
                    router.call(event, routes)
                end
            end

            routes.compact
        end

        def loadroutes
            if File.exist?(triggerfile)
                triggerage = File::Stat.new(triggerfile).mtime.to_f
            else
                triggerage = 0
            end

            @loaded ||= 0

            if @loaded < triggerage
                Log.debug("Reloading routes from disk after finding a new #{triggerfile}")

                routefiles.each do |route|
                    loadroute(route)
                end

                @loaded = Time.now.to_f
            elsif @loaded == 0
                routefiles.each do |route|
                    loadroute(route)
                end

                @loaded = Time.now.to_f
            end
        end

        def loadroute(route)
            Log.debug("Loading #{route}")

            RouterInstance.new(route)
        rescue Exception => e
            Log.error("Failed to load route #{route}: #{e.class}: #{e}")
        end

        def routefiles
            routesdir = File.join([Config["routes"][:routesdir], routingkey])

            files = []

            if File.directory?(routesdir)
                Dir.entries(routesdir).grep(/route.rb$/).each do |f|
                    files << File.join([routesdir, f])
                end
            end

            files
        end

        def triggerfile
            File.join([Config["routes"][:routesdir], Config["routes"][:reloadtrigger]])
        end
    end

end
