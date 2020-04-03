module Payu
  class PaymentHandler
    HEADER = {'Content-Type': 'text/json'}.freeze

    attr_reader :order, :payment_method

    def initialize(payment_method:, order:)
      @order = order
      @payment_method = payment_method
    end

    def send_payment
      uri = URI.parse(Settings.payu_in_host)
      # Create the HTTP objects
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Post.new(uri.request_uri, HEADER)
      request.body = URI.encode_www_form(request_payload)
      # Send the request
      http.request(request)
    end

    private

    def request_payload
      RequestBuilder.new(payment_method: payment_method, order: order).payload
    end
  end
end