#require 'logger'
require File.join(File.dirname(__FILE__), 'app')
#Dir[File.dirname(__FILE__) + '/lib/middleware/*.rb'].each { |file| require file }

#logger = Logger.new('log/ping-stub.log')
#use Rack::CommonLogger, logger
#use CustomLogger, logger

run PingStub
 