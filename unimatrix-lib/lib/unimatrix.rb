require 'rubygems'
require 'json'
require 'tempfile'
require 'fileutils'
require 'logger'
require 'yaml'
require 'daemons'

module UM
    autoload :Config, "um/config"
    autoload :Log, "um/log"
    autoload :Util, "um/util"
end
