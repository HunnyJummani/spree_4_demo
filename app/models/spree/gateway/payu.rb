module Spree
  class Gateway::Payu < Spree::Gateway
    preference :merchant_key,   :string
    preference :key_salt, :string
    preference :merchant_id, :string
    preference :authorization_header, :string
    def provider_class
      self.class
    end

    def method_type
      "payu"
    end

    def actions
      %w(capture void credit)
    end

    def auto_capture?
      true
    end

    def payment_profiles_supported?
      true
    end

    def create_profile(payment)
      if payment.source.gateway_payment_profile_id.nil? && payment.source.encrypted_data.present?
        if payment.source.address_id.blank?
          payment.source.update(address_id: payment.order.bill_address_id)
        end

        data = {
          card_nonce:      payment.source.encrypted_data,
          cardholder_name: payment.source.name
        }

        if payment.order.bill_address
          data[:billing_address] = map_address payment.order.bill_address
        end

        transaction do
          expiry = payment.source_attributes["expiry"]
          payment.source.update_attributes(month: expiry.split("/")[0])
          payment.source.update_attributes(year: expiry.split("/")[1])

          customer = get_or_create_customer(payment.order)
          payment.source.update_attributes(gateway_customer_profile_id: customer.square_id) if customer

          customer_card_id = create_customer_card(customer.square_id, data)
          payment.source.update_attributes(gateway_payment_profile_id: customer_card_id) if customer_card_id
        end
      end
    end

    def authorize(_money, credit_card, _options = {})
      ActiveMerchant::Billing::Response.new(true, "PayUMoney: Auth Success", {}, test: true, authorization: "12345", avs_result: { code: "D" })
    end

    def capture(_money, authorization, _gateway_options)
      ActiveMerchant::Billing::Response.new(true, "PayUMoney: Capture Success", {}, test: true)
    end

    def cancel(_response_code)
      ActiveMerchant::Billing::Response.new(true, "PayUMoney: Cancel success", {}, test: true, authorization: "12345")
    end

    def credit(_money, _credit_card, _response_code, _options = {})
      ActiveMerchant::Billing::Response.new(true, "PayUMoney: Credit success", {}, test: true, authorization: "12345")
    end

    def purchase(_money, credit_card, _options = {})
      body = {}
      body[:source_id] = credit_card.gateway_payment_profile_id
      body[:idempotency_key] = SecureRandom.uuid
      body[:amount_money] = {}
      body[:amount_money][:amount] = _money
      body[:amount_money][:currency] = "INR"
      body[:autocomplete] = true
      body[:customer_id] = credit_card.gateway_customer_profile_id
      body[:location_id] = preferences[:location_id]
      body[:reference_id] = _options[:order_id]

      environment = preferences[:server]

      # TODO : need to change for Payu client
      # square      = ::Square::Client.new(access_token: preferences[:access_token], environment: environment)
      # result      = square.payments.create_payment(body: body)

      # if result.success?
      #   ActiveMerchant::Billing::Response.new(true, "Square: Purchase Success", {})
      # elsif result.error?
      #   ActiveMerchant::Billing::Response.new(true, "Square: Purchase Failure " + result.errors.to_s, {})
      # end
    end

    # def void(_response_code, _credit_card, _options = {})
    #   ActiveMerchant::Billing::Response.new(true, "Square: Void success", {}, test: true, authorization: "12345")
    # end

    private

    def create_customer_card(customer_id, body)
      environment = preferences[:server]
      square      = ::Payu::Client.new(access_token: preferences[:access_token], environment: environment)
      result      = JSON.parse(square.customers.create_customer_card(customer_id: customer_id, body: body).raw_body)

      if result["errors"]
        raise ::Spree::Core::GatewayError, result["errors"].first["detail"]
      end

      return result["card"]["id"]
    end

    # TODO : need to change for payu client
    # def get_or_create_customer(order)
    #   square_customer = if order.user_id.present?
    #                       SquareCustomer.where(owner: order.user).first_or_create
    #                     else
    #                       SquareCustomer.where(owner: order).first_or_create
    #                     end

    #   return square_customer if square_customer.square_id.present?

    #   bill_address = order.bill_address

    #   data = {
    #       given_name:    bill_address.firstname,
    #       family_name:   bill_address.lastname,
    #       email_address: order.email,
    #       address:       map_address(bill_address),
    #       phone_number:  bill_address.phone,
    #   }

    #   environment = preferences[:server]
    #   square      = ::Square::Client.new(access_token: preferences[:access_token], environment: environment)
    #   result      = JSON.parse(square.customers.create_customer(body: data).raw_body)

    #   square_customer.update_attributes(square_id: result["customer"]["id"])

    #   return square_customer
    # end

    def map_address(address)
      {
          address_line_1:                  address[:address1],
          address_line_2:                  address[:address2],
          locality:                        address[:city],
          administrative_district_level_1: address[:state].try(:name),
          postal_code:                     address[:zipcode],
          country:                         address[:country].try(:iso)
      }
    end
  end
end