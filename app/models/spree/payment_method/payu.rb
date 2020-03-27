# frozen_string_literal: true

module Spree
  class PaymentMethod::Payu < ::Spree::PaymentMethod
    preference :merchant_key, :string
    preference :key_salt, :string
    preference :merchant_id, :string
    preference :authorization_header, :string

    def provider_class
      self.class
    end

    def method_type
      'payu'
    end

    def actions
      %w[capture void credit]
    end

    def credit(_arg1, _arg2, _arg3, _arg4)
      self
    end

    def authorization
      self
    end

    def success?
      true
    end

    def auto_capture?
      true
    end

    def payment_profiles_supported?
      true
    end

    def source_required?
      false
    end

    def void(_response_code, _credit_card, _options = {})
      ActiveMerchant::Billing::Response.new(true, "Square: Void success", {}, test: true, authorization: "12345")
    end

    def capture(_money, _authorization, _gateway_options)
      ActiveMerchant::Billing::Response.new(true, 'PayUMoney: Capture Success', {}, test: true)
    end

    def refund(money, authorization, _options = {})
      raise ArgumentError, 'Amount is required' unless money

      post = {}

      post[:command] = 'cancel_refund_transaction'
      post[:var1] = authorization
      post[:var2] = generate_unique_id
      post[:var3] = amount(money)

      add_auth(post, :command, :var1)

      commit(url('refund'), post)
      end
  end

  def commit(url, parameters)
    response = parse(ssl_post(url, post_data(parameters), 'Accept-Encoding' => 'identity'))

    Response.new(
      success_from(response),
      message_from(response),
      response,
      authorization: authorization_from(response),
      test: test?
    )
  end

  def success_from(response)
    if response['result_status']
      (response['status'] == 'success' && response['result_status'] == 'success')
    else
      (response['status'] == 'success' || response['status'].to_s == '1')
    end
  end

  def message_from(response)
    (response['error_message'] || response['error'] || response['msg'])
  end

  def authorization_from(response)
    response['mihpayid']
  end
end
