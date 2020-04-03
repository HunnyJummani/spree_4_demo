module Payu
  class RequestBuilder
    attr_reader :order, :payment_method

    def initialize(payment_method:, order:)
      @order = order
      @payment_method = payment_method
    end

    def payload
      {
        key: merchant_key,
        txnid: transaction_id,
        amount: order.total.to_f.to_s,
        productinfo: product_description,
        firstname: customer_fname,
        email: order.email,
        phone: customer_phone_number,
        surl: "#{Settings.app_host}/spree/payu_handler/success",
        furl: "#{Settings.app_host}/spree/payu_handler/fail",
        hash: payment_req_hash
      }
    end

    # key|txnid|amount|productinfo|firstname|email|udf1|udf2|udf3|udf4|udf5||||||salt.
    # REF : https://developer.payumoney.com/redirect/
    def payment_req_hash
      hash_str = "#{merchant_key}|#{transaction_id}|#{@order.total.to_f}|#{product_description}|#{customer_fname}|#{@order.email}|||||||||||#{key_salt}"
      digested_hash hash_str
    end

    # Generate reverse hash and compare that with params[:hash] provided by PayU
    # If that matches then then it confirms that req is coming from PayU
    # It is used to handle man-in-middle attack
    # Ref : https://developer.payumoney.com/redirect/#response-hash
    # salt|status||||||udf5|udf4|udf3|udf2|udf1|email|f_name|productinfo|amount|txnid|key

    def payment_resp_hash(params)
      hash_str = "#{key_salt}|#{params[:status]}|||||||||||#{params[:email]}|#{params[:firstname]}|#{params[:productinfo]}|#{params[:amount]}|#{params[:txnid]}|#{merchant_key}"
      digested_hash hash_str
    end

    def digested_hash(hash_str)
      Digest::SHA512.hexdigest hash_str
    end

    def merchant_key
      @merchant_key ||= payment_method.preferences[:merchant_key]
    end

    def key_salt
      @key_salt ||= payment_method.preferences[:key_salt]
    end

    # Transaction ID should be unique, If transaction fails and user try again then this number should be unique.
    def transaction_id
      @transaction_id ||= "#{order.number}-#{SecureRandom.hex(5)}"
    end

    def product_description
      @product_description ||= order.products.map(&:description).join(', ')
    end

    def customer_fname
      @customer_fname ||= order.shipping_address.firstname
    end

    def customer_phone_number
      @customer_phone_number ||= order.shipping_address.phone
    end
  end
end
