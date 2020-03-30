# frozen_string_literal: true

module Spree
  class PayuHandlerController < Spree::StoreController
    skip_before_action :verify_authenticity_token
    before_action :check_response_authorized

    def success
      session[:payu_response] = params
      default_payment = {
        payments_attributes: [{
          source: nil,
          payment_method_id: payment_method.try(:id),
          amount: order.total
        }]
      }
      if order.update(default_payment)
        order.next
        redirect_to checkout_state_path(order.state)
      else
        logger.error(" --------  ERROR  -------- \nPAyu Payment Failure: Unable to create payment using parameters: #{order.errors.full_messages.join(', ')}")
        false
      end
    end

    def fail
      redirect_to checkout_state_path(order.state)
    end


    private

    # TODO
    # Generate reverse hash and compare that with params[:hash] provided by PayU
    # If that matches then then it confirms that req is coming from PayU
    # It is used to handle man-in-middle attack
    # Ref : https://developer.payumoney.com/redirect/#response-hash
    # salt|status||||||udf5|udf4|udf3|udf2|udf1|email|f_name|productinfo|amount|txnid|key
    def check_response_authorized
      hash_str = "#{key_salt}|||||||||||#{@order.email}|#{customer_fname}|#{product_description}|#{@order.total.to_f}|#{transaction_id}|#{merchant_key}"

      calculated_hash = Digest::SHA512.hexdigest hash_str

      if params[:hash] !=  calculated_hash
        redirect_to checkout_state_path(order.state), notice: 'Something went wrong'
      end
    end

    def payment_method
      @payment_method ||= Spree::PaymentMethod.find_by(type: 'Spree::PaymentMethod::Payu')
    end

    # params[:txnid] = "R695945340-asdasf"
    def order
      @order ||= Spree::Order.find(params[:txnid].splt('-').first)
    end
  end
end
