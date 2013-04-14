require 'base64'

module Rack
  module OAuth2
    module Util
      class << self
        def rfc3986_encode(text)
          URI.encode(text, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
        end

        def base64_encode(text)
          Base64.encode64(text).gsub(/\n/, '')
        end

        def compact_hash(hash)
          hash.reject do |key, value|
            value.blank?
          end
        end

        def try(object, *a, &b)
          if object.nil?
            nil
          else
            if a.empty? && block_given?
              yield object
            else
              object.public_send(*a, &b) if object.respond_to?(a.first)
            end
          end
        end

        def try!(object, *a, &b)
          if object.nil?
            nil
          else
            if a.empty? && block_given?
              yield object
            else
              object.public_send(*a, &b)
            end
          end
        end

        def symbolize(hash)
          hash.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
        end

        def parse_uri(uri)
          case uri
          when URI::Generic
            uri
          when String
            URI.parse(uri)
          else
            raise "Invalid format of URI is given."
          end
        end

        def to_query(object, key = nil)
          if object.is_a? Hash
            to_param(object)
          elsif object.is_a? Array
            prefix = "#{key}[]"
            object.collect { |v| to_query(v, prefix) }.join '&'
          else
            require 'cgi' unless defined?(CGI) && defined?(CGI::escape)
            "#{CGI.escape(to_param(key))}=#{CGI.escape(to_param(object).to_s)}"
          end
        end

        def to_param(object)
          if object.is_a? Hash
            object.collect do |k, v|
              to_query(v, k)
            end.sort * '&'
          elsif object.is_a? Array
            object.collect { |e| e.to_param }.join '/'
          elsif object.is_a? Object
            object.to_s
          else
            object
          end
        end

        def demodulize(path)
          path = path.to_s
          if i = path.rindex('::')
            path[(i+2)..-1]
          else
            path
          end
        end

        def redirect_uri(base_uri, location, params)
          redirect_uri = parse_uri base_uri
          case location
          when :query
            redirect_uri.query = [redirect_uri.query, Util.to_query(Util.compact_hash(params))].compact.join('&')
          when :fragment
            redirect_uri.fragment = Util.to_query(Util.compact_hash(params))
          end
          redirect_uri.to_s
        end

        def uri_match?(base, given)
          base = parse_uri(base)
          given = parse_uri(given)
          base.path = '/' if base.path.blank?
          given.path = '/' if given.path.blank?
          [:scheme, :host, :port].all? do |key|
            base.send(key) == given.send(key)
          end && /^#{base.path}/ =~ given.path
        rescue
          false
        end

      end
    end
  end
end