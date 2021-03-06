require 'rubygems'
require 'json'
require 'tempfile'
require 'fileutils'
require 'logger'
require 'yaml'
require 'daemons'
require 'um/monkey_patches.rb'

module UM
    autoload :Config, "um/config"
    autoload :Event, "um/event"
    autoload :Log, "um/log"
    autoload :MongoStorage, "um/mongostorage"
    autoload :Router, "um/router"
    autoload :RouterInstance, "um/routerinstance"
    autoload :Stats, "um/stats"
    autoload :StompConnector, "um/stompconnector"
    autoload :StompConsumer, "um/stompconsumer"
    autoload :Util, "um/util"
end
