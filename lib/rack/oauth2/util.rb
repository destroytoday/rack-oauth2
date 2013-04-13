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
            object.collect do |k, v|
             to_query(v, k)
            end.sort * '&'
          elsif object.is_a? Array
            prefix = "#{key}[]"
            object.collect { |v| to_query(v, prefix) }.join '&'
          else
            require 'cgi' unless defined?(CGI) && defined?(CGI::escape)
            "#{CGI.escape(to_param(key))}=#{CGI.escape(to_param(object).to_s)}"
          end
        end

        def to_param(object)
          if object.is_a? Array
            object.collect { |e| e.to_param }.join '/'
          else
            object.to_s
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

        def delegate(*methods)
          options = methods.pop
          unless options.is_a?(Hash) && to = options[:to]
            raise ArgumentError, "Delegation needs a target. Supply an options hash with a :to key as the last argument (e.g. delegate :hello, :to => :greeter)."
          end

          if options[:prefix] == true && options[:to].to_s =~ /^[^a-z_]/
            raise ArgumentError, "Can only automatically set the delegation prefix when delegating to a method."
          end

          prefix = options[:prefix] && "#{options[:prefix] == true ? to : options[:prefix]}_"

          file, line = caller.first.split(':', 2)
          line = line.to_i

          methods.each do |method|
            on_nil =
              if options[:allow_nil]
                'return'
              else
                %(raise "#{self}##{prefix}#{method} delegated to #{to}.#{method}, but #{to} is nil: \#{self.inspect}")
              end

            module_eval(<<-EOS, file, line - 5)
              if instance_methods(false).map(&:to_s).include?("#{prefix}#{method}")
                remove_possible_method("#{prefix}#{method}")
              end

              def #{prefix}#{method}(*args, &block)               # def customer_name(*args, &block)
                #{to}.__send__(#{method.inspect}, *args, &block)  #   client.__send__(:name, *args, &block)
              rescue NoMethodError                                # rescue NoMethodError
                if #{to}.nil?                                     #   if client.nil?
                  #{on_nil}                                       #     return # depends on :allow_nil
                else                                              #   else
                  raise                                           #     raise
                end                                               #   end
              end                                                 # end
            EOS
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