require 'omniauth'
require 'openssl'
require 'base64'

module OmniAuth
  module Strategies
    class Telegram
      include OmniAuth::Strategy
      
      args [:bot_name, :bot_secret]
      
      option :name, 'telegram'
      option :bot_name, nil
      option :bot_secret, nil
      option :button_config, {}
      
      FIELDS      = %w[id first_name last_name username photo_url auth_date hash]
      HASH_FIELDS = %w[auth_date first_name id last_name photo_url username]
      
      def request_phase
        html = <<-HTML
          <!DOCTYPE html>
          <html>
          <head>
            <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
            <title>Telegram Login</title>
          </head>
          <body>
        HTML
        
        data_attrs = options.button_config.map { |k,v| "data-#{k}=\"#{v}\"" }.join(" ")
        
        html << "<script async
              src=\"https://telegram.org/js/telegram-widget.js?4\"
              data-telegram-login=\"#{options.bot_name}\"
              data-auth-url=\"#{callback_url}\"
        #{data_attrs}></script>"
        
        html << <<-HTML
          </body>
          </html>
        HTML
        
        Rack::Response.new(html, 200, 'content-type' => 'text/html').finish
      end
      
      def callback_phase
        unless FIELDS.all? { |f| request.params.include?(f) }
          fail!(:field_missing)
        end
        
        unless check_signature
          fail!(:signature_mismatch)
        end
        
        if Time.now.to_i - request.params["auth_date"].to_i > 86400
          fail!(:session_expired)
        end
        
        super
      end
      
      uid do
        request.params["id"]
      end
      
      info do
        {
            name:       "#{request.params["first_name"]} #{request.params["last_name"]}",
            nickname:   request.params["username"],
            first_name: request.params["first_name"],
            last_name:  request.params["last_name"],
            image:      request.params["photo_url"]
        }
      end
      
      extra do
        {
            auth_date: Time.at(request.params["auth_date"].to_i)
        }
      end
      
      private
      
      def check_signature
        secret = OpenSSL::Digest::SHA256.digest(options[:bot_secret])
        signature = HASH_FIELDS.map { |f| "%s=%s" % [f, request.params[f]] }.join("\n")
        hashed_signature = OpenSSL::HMAC.hexdigest(OpenSSL::Digest::SHA256.new, secret, signature)
        
        request.params["hash"] == hashed_signature
      end
    end
  end
end
