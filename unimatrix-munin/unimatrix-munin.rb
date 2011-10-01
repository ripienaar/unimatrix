#!/usr/bin/ruby

require 'rubygems'
require 'stomp'
require 'json'
require 'optparse'
require 'facter'
require 'munin-ruby'
require 'yaml'
require 'timeout'
require 'pp'

options = {:stomp_hosts => nil,
           :stomp_user => nil,
           :stomp_password => nil,
           :stomp_port => 6163,
           :munin_host => "localhost",
           :munin_port => 4949,
           :origin => "munin",
           :subject => Facter.fqdn,
           :portal => "/queue/unimatrix.portal",
           :yaml => nil}

opt = OptionParser.new

opt.on("--user USER", "Connect as user") do |f|
    options[:stomp_user] = f
end

opt.on("--password PASSWORD", "Connection password") do |f|
    options[:stomp_password] = f
end

opt.on("--host HOST", "Host to connect to") do |f|
    if options[:stomp_hosts]
        options[:stomp_hosts] << f
    else
        options[:stomp_hosts] = [f]
    end
end

opt.on("--port PORT", Integer, "Port to connect to") do |f|
    options[:stomp_port] = f
end

opt.on("--munin-host HOST", "Munin Host") do |f|
    options[:munin_host] = f
end

opt.on("--munin-port PORT", Integer, "Munin Port") do |f|
    options[:munin_port] = f
end

opt.on("--origin ORIGIN", "Unimatrix Origin") do |f|
    options[:origin] = f
end

opt.on("--subject SUBJECT", "Unimatrix Subject") do |f|
    options[:subject] = f
end

opt.on("--portal PORTAL", "Unimatrix Portal") do |f|
    options[:portal] = f
end

opt.on("--config CONFIG", "YAML Config File") do |f|
    options[:yaml] = f
end

opt.parse!

if options[:yaml]
    options.merge!(YAML.load_file(options[:yaml]))
end

[:stomp_hosts, :stomp_user, :stomp_password].each {|v| raise "#{v} should be supplied" unless options[v]}

class UnimatrixMunin
    attr_reader :metrics, :services, :start_time, :connection, :options, :munin

    def initialize(options)
        @options = options

	Timeout::timeout(2) {
            @connection = connect_stomp
	}

        @munin = connect_munin

        @services = 0
        @metrics = 0

        @start_time = @munin.timestamp.utc
    end

    def connect_stomp
        connection = {:hosts => []}

        options[:stomp_hosts].each do |host|
            connection[:hosts] << {:host => host, :port => options[:stomp_port], :login => options[:stomp_user], :passcode => options[:stomp_password]}
        end

        Stomp::Connection.open(connection)
    end

    def connect_munin
        Munin::Node.new(options[:munin_host], :port => options[:munin_port])
    end

    def empty_event
        {"name"       => "munin",
         "text"       => "",
         "metrics"    => {},
         "tags"       => {},
         "severity"   => 0,
         "event_time" => start_time.to_i,
         "type"       => "metric",
         "subject"    => options[:subject],
         "origin"     => options[:origin]}
    end

    def event_for_service(service)
        @services += 1

        event = empty_event

        event["text"] = service.name

        service.params.each_pair do |k, v|
            @metrics += 1
            metric = [service.name, k].join(".")
            event["metrics"][metric] = v
        end

        return event
    end

    def stats
        stats_event = empty_event
        stats_event["metrics"] = {"um_munin.services" => @services, "um_munin.metrics" => @metrics, "um_munin.time" => (Time.now - @start_time).to_f}

        return stats_event
    end

    def publish
	Timeout::timeout(45) {
            munin.services.each do |service|
                event = event_for_service(munin.service(service))

                connection.publish(options[:portal], event.to_json)
            end

            connection.publish(options[:portal], stats.to_json)

            connection.disconnect
	}
    end
end

begin
    munin = UnimatrixMunin.new(options)
    munin.publish
rescue Timeout::Error
    puts "Timeout reached while sending munin stats"
end
