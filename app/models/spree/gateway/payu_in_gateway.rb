module Spree
  class Gateway::PayuInGateway < Spree::Gateway
    preference :merchant_key, :string
    preference :key_salt, :string
    #preference :merchant_id, :string
    #preference :authorization_header, :string

    def method_type
      'payu_in'
    end

    def provider_class
      ActiveMerchant::Billing::PayuInGateway
    end

    def actions
      %w[credit]
    end

    def payment_profiles_supported?
      false
    end

    def source_required?
      false
    end

    def auto_capture?
      true
    end

    # Purchase is already handled in payU webcheckout flow. So jut giving canned response
    def purchase(_money, credit_card, _options = {})
      ActiveMerchant::Billing::Response.new(true, 'PayUIn Gateway: Forced success', {}, test: true)
    end

    def credit(_money, authorization, _options = {})
      response = provider_class.new({key: preferences[:merchant_key], salt: preferences[:key_salt], test: test?}).refund(_money, authorization, _options)
      if response.success?
        ActiveMerchant::Billing::Response.new(true, 'PayUIn Gateway: refund success', {}, test: test?, authorization: response.params['request_id'])
      else
        ActiveMerchant::Billing::Response.new(false, 'PayUIn Gateway: refund failed', {}, test: test?)
      end
    end

    # As such this is not supported.
    def authorize(*_args)
      ActiveMerchant::Billing::Response.new(true, 'PayUIn will automatically capture the amount after creating a shipment.')
    end

    # As such this is not supported.
    def capture(*_args)
      ActiveMerchant::Billing::Response.new(true, 'PayUIn will automatically capture the amount after creating a shipment.')
    end

    # For order cancellation, refund needs to create separately. Cancel method not present for payU gateway
    def cancel(_response_code)
      ActiveMerchant::Billing::Response.new(true, 'PayUIn Gateway: Forced success', {}, test: true)
    end

    def test?
      preferences[:test_mode]
    end

  end
end