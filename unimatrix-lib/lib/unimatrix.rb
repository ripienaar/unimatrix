require 'rubygems'
require 'json'
require 'tempfile'
require 'fileutils'
require 'logger'
require 'yaml'
require 'daemons'

module UM
    autoload :Config, "um/config"
    autoload :Event, "um/event"
    autoload :Log, "um/log"
    autoload :Router, "um/router"
    autoload :RouterInstance, "um/routerinstance"
    autoload :Stats, "um/stats"
    autoload :StompConnector, "um/stompconnector"
    autoload :StompConsumer, "um/stompconsumer"
    autoload :Util, "um/util"
end
