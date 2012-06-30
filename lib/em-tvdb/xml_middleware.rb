require 'rest-core/middleware'

class RestCore::XmlDecode
  def self.members; [:xml_decode]; end
  include RestCore::Middleware

  def call(env)
    return app.call(env) if env[DRY]
    if env[ASYNC]
      app.call(env.merge(ASYNC => lambda{ |response|
        env[ASYNC].call(process(response))
      }))
    else
      process(app.call(env))
    end
  end

  def process(response)
    response['RESPONSE_BODY'] = xml_decode(response['RESPONSE_BODY'])
    response
  # rescue
  #   fail(response, error)
  end
  
private
  def xml_decode(data)
    Nokogiri::XML::parse(data)
  end
  
end
