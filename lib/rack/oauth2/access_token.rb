module Rack
  module OAuth2
    class AccessToken
      include AttrRequired, AttrOptional
      attr_required :access_token, :token_type, :httpclient
      attr_optional :refresh_token, :expires_in, :scope

      def initialize(attributes = {})
        (required_attributes + optional_attributes).each do |key|
          self.send :"#{key}=", attributes[key]
        end
        @token_type = Util.demodulize(self.class.name).underscore.to_sym
        @httpclient = Rack::OAuth2.http_client("#{self.class} (#{VERSION})")
        @httpclient.request_filter << Authenticator.new(self)
        attr_missing!
      end

      def get(*args)
        @httpclient.get(*args)
      end

      def post(*args)
        @httpclient.post(*args)
      end

      def put(*args)
        @httpclient.put(*args)
      end

      def delete(*args)
        @httpclient.delete(*args)
      end

      def token_response(options = {})
        {
          :access_token => access_token,
          :refresh_token => refresh_token,
          :token_type => token_type,
          :expires_in => expires_in,
          :scope => Array(scope).join(' ')
        }
      end
    end
  end
end

require 'rack/oauth2/access_token/authenticator'
require 'rack/oauth2/access_token/bearer'
require 'rack/oauth2/access_token/mac'
require 'rack/oauth2/access_token/legacy'