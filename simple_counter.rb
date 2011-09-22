#!/bin/env ruby

require 'unimatrix'
require 'um/consumer/simple_counter'

configdir = File.join(File.dirname(File.expand_path(__FILE__)), "etc")

UM::Util.startapp("consumer.simple_counter", UM::Consumer::SimpleCounter, configdir)
