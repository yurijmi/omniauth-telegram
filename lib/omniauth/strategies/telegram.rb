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

      REQUIRED_FIELDS = %w[id hash]
      SIGNATURE_FIELDS = %w[id first_name last_name username photo_url auth_date]

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
        if error = check_errors
          fail!(error)
        else
          super
        end
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

      def check_errors
        return :field_missing unless check_fields
        return :signature_mismatch unless check_signature
        return :session_expired unless check_session
      end

      def check_fields
        REQUIRED_FIELDS.all? { |f| request.params.include?(f) }
      end

      def check_signature
        secret = OpenSSL::Digest::SHA256.digest(options[:bot_secret])
        keys = (request.params.keys & SIGNATURE_FIELDS).sort
        signature = keys.map { |key| "%s=%s" % [key, request.params[key]] }.join("\n")
        hashed_signature = OpenSSL::HMAC.hexdigest(OpenSSL::Digest::SHA256.new, secret, signature)

        request.params["hash"] == hashed_signature
      end

      def check_session
        Time.now.to_i - request.params["auth_date"].to_i <= 86400
      end
    end
  end
end
