module UM
    class Config
        include Enumerable

        @settings = {}

        class << self
            attr_reader :settings

            def []=(key,val)
                @settings[key] = val
            end

            def [](key)
                @settings[key]
            end

            def include?(key)
                @settings.include?(key)
            end

            def each
                @settings.each_pair do |k, v|
                    yield({k => v})
                end
            end

            def loadconfig(key)
                raise "Set configdir" unless @settings.include?(:configdir)

                file = File.join([@settings[:configdir], "#{key}.yaml"])

                if File.exist?(file)
                    settings = YAML.load_file(file)

                    @settings[key] = settings
                else
                    raise "Cannot find file #{file} to load for #{key}"
                end
            end

            def method_missing(k, *args, &block)
                return @settings[k] if @settings.include?(k)

                k = k.to_s.gsub("_", ".")
                return @settings[k] if @settings.include?(k)

                super
            end

        end
    end
end
