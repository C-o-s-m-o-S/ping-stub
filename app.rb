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
		config = AgentConfiguration.new

		agent_config_file = File.new(File.dirname(__FILE__) + "/agent-config.txt")
		config_properties = agent_config_file.reduce({}) do |properties, line|			
			key, value = line.split(/\s*=\s*/)
			properties[key] = value.chomp
			properties
		end

		config.setCipherSuite config_properties['ciper-suite']
		config.setCookieDomain config_properties['cookie-domain']
		config.setCookiePath config_properties['cookie-path']
		config.setDetectMalformedAttributes config_properties['detect-malformed-attributes']
		config.setNotBeforeTolerance config_properties['not-before-tolerance']
		config.setObfuscatePassword config_properties['obfuscate-password'] == "true" ? true : false
		config.setPassword config_properties['password']
		config.setRemoveTrailingBackslash config_properties['remove-trailing-backslash']
		config.setRenewUntilLifetime config_properties['token-lifetime'].to_i
		config.setSecureCookie config_properties['secure-cookie']
		config.setSessionCookie config_properties['session-cookie']
		config.setTokenLifetime config_properties['token-lifetime'].to_i
		config.setTokenName config_properties['token-name']
		config.setUseCookie config_properties['use-cookie'] == "true" ? true : false
		config.setUseSunJCE config_properties['use-sun-jce']
		config.setUseVerboseErrorMessages config_properties['verbose-error-messages'] == "true" ? true : false

		agent = Agent.new(config)

		tokenValues = HashMap.new
		tokenValues.put "not-before", (Time.now.utc + 5 * 1000).strftime("%Y-%m-%dT%H:%M:%SZ")
		tokenValues.put "authnContext", "urn:oasis:names:tc:SAML:2.0:ac:classes:unspecified"
		tokenValues.put "subject", "user"
		tokenValues.put "not-on-or-after", (Time.now.utc - 5 * 1000).strftime("%Y-%m-%dT%H:%M:%SZ")
		tokenValues.put "renew-until", (Time.now.utc + (12 * 60 * 60)).strftime("%Y-%m-%dT%H:%M:%SZ")	

		token = agent.writeToken tokenValues
		puts tokenValues
		return

		redirect to("#{target_resource}?opentoken=#{token}")

	end
end