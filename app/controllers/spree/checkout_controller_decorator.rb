# frozen_string_literal: true

module Spree
  module CheckoutControllerDecorator
    def self.prepended(base)
      base.class_eval do
        skip_before_action :verify_authenticity_token, only: [:update]
        before_action :pay_with_payu, only: :update, if: :order_in_payment?
      end
    end

    private

    def order_in_payment?
      @order.state == 'payment'
    end

    def pay_with_payu
      return if params[:order].blank? || params[:order][:payments_attributes].blank?

      pm_id = params[:order][:payments_attributes].first[:payment_method_id]
      payment_method = Spree::PaymentMethod.find(pm_id)

      return unless payment_method.is_a?(Spree::Gateway::Payu)

      uri = URI.parse('https://test.payu.in/_payment')

      header = { 'Content-Type': 'text/json' }
      hash_str = 'gtKFFx' + '|' + @order.number.to_s + '|' + @order.total.to_f.to_s + '|' + @order.products.map(&:description).join(', ').to_s + '|' + 'Hunny' + '|' + @order.email.to_s + '|||||||||||eCwWELxi'
      hash = Digest::SHA512.hexdigest hash_str
      data = {
        key: 'gtKFFx',
        txnid: @order.number,
        amount: @order.total.to_f.to_s,
        productinfo: @order.products.map(&:description).join(', '),
        firstname: 'Hunny',
        email: @order.email,
        phone: '8469057689',
        surl: 'http://localhost:3000/spree/payu_handler/success',
        furl: 'http://localhost:3000/spree/payu_handler/fail',
        hash: hash
      }
      # Create the HTTP objects
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Post.new(uri.request_uri, header)
      request.body = URI.encode_www_form(data)
      # Send the request
      response = http.request(request)
      if response.code == '200'
        render html: response.body.html_safe
      else
        redirect_to response['location']
      end
    end
  end
end

Spree::CheckoutController.prepend Spree::CheckoutControllerDecorator
