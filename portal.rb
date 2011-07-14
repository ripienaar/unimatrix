#!/bin/env ruby

require 'pp'
require 'unimatrix'
require 'um/consumer/portal'

configdir = File.join(File.dirname(File.expand_path(__FILE__)), "etc")

UM::Util.startapp("consumer.portal", UM::Consumer::Portal, configdir)
