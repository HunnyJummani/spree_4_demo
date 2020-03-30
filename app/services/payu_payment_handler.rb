class PayuPaymentHandler
  HEADER = {'Content-Type': 'text/json'}.freeze

  attr_reader :order, :payment_method

  def initialize(payment_method:, order:)
    @order = order
    @payment_method = payment_method
  end

  def send_payment
    uri = URI.parse('https://test.payu.in/_payment')
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
    {
      key: merchant_key,
      txnid: transaction_id,
      amount: order.total.to_f.to_s,
      productinfo: product_description,
      firstname: customer_fname,
      email: order.email,
      phone: customer_phone_number,
      surl: 'http://localhost:3001/spree/payu_handler/success',
      furl: 'http://localhost:3001/spree/payu_handler/fail',
      hash: payment_req_hash
    }
  end

  # key|txnid|amount|productinfo|firstname|email|udf1|udf2|udf3|udf4|udf5||||||salt.
  # REF : https://developer.payumoney.com/redirect/
  def payment_req_hash
    hash_str = "#{merchant_key}|#{transaction_id}|#{@order.total.to_f}|#{product_description}|#{customer_fname}|#{@order.email}|||||||||||#{key_salt}"
    Digest::SHA512.hexdigest hash_str
  end

  def merchant_key
    @merchant_key ||= payment_method.preferences[:merchant_key].presence
  end

  def key_salt
    @key_salt ||= payment_method.preferences[:key_salt].presence
  end

  # Transaction ID should be unique, If transaction fails and user try again then this number should be unique.
  def transaction_id
    @transaction_id ||= "#{order.number}#{SecureRandom.hex(5)}"
  end

  def product_description
    @product_description ||= order.products.map(&:description).join(', ')
  end

  def customer_fname
    @customer_fname ||= order.shipping_address.firstname.presence
  end

  def customer_phone_number
    @customer_phone_number ||= order.shipping_address.phone.presence
  end

end