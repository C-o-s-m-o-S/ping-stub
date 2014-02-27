require 'sinatra/base'
require 'rubygems'
require 'java'
require "sinatra/reloader"
require 'lib/opentoken-agent-2.5.1.jar'
require 'lib/commons-collections-3.2.jar'
require 'lib/servlet-api-2.4.jar'
require 'lib/commons-beanutils-1.7.0.jar'
require 'lib/commons-logging-1.0.4.jar'
java_import 'com.pingidentity.opentoken.Agent'
java_import 'com.pingidentity.opentoken.AgentConfiguration'
java_import 'java.util.HashMap'
# java_import 'org.apache.commons.collections.MultiHashMap'

class PingStub < Sinatra::Base
	configure :development do
    	register Sinatra::Reloader
  	end
	$CLASSPATH << 'lib'

	get '/' do
	  if params[:opentoken]
		  agent = Agent.new('agent-config.txt')
		  map = agent.readToken params[:opentoken]

		  response = ""
		  map.keys.each do |key|
		  	response += "#{key}: #{map[key]}<br/>"
		  end
		  return [200, response]
	  end
	  erb :index
	end

	get '/sso' do
		redirect to('https://aconex-sp.aws.solidstate.com.au:8080/sp/startSSO.ping?PartnerIdpId=aconexidp&TargetResource=http://localhost:3000')
	end

	get '/sp/startSSO.ping' do
		target_resource = params[:TargetResource]		

		agent = Agent.new("agent-config.txt")

		tokenValues = HashMap.new
		tokenValues.put "not-before", (Time.now.utc - (5 * 1000)).strftime("%Y-%m-%dT%H:%M:%SZ")
		tokenValues.put "authnContext", "urn:oasis:names:tc:SAML:2.0:ac:classes:unspecified"
		tokenValues.put "subject", "user"
		tokenValues.put "not-on-or-after", (Time.now.utc + (5 * 1000)).strftime("%Y-%m-%dT%H:%M:%SZ")
		tokenValues.put "renew-until", (Time.now.utc + (12 * 60 * 60)).strftime("%Y-%m-%dT%H:%M:%SZ")	

		token = agent.writeToken tokenValues
		redirect to("#{target_resource}?opentoken=#{token}")

	end
end