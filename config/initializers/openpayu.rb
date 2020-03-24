require 'openpayu'

SAMPLE_POS_ID = '4956554'
SAMPLE_SIGNATURE_KEY = 'CyaqssdWYNx7J7bdXxbigOFh0mbfGo5kMuWta1k3M/M='

OpenPayU::Configuration.configure do |config|
  config.merchant_pos_id  = SAMPLE_POS_ID
  config.signature_key    = SAMPLE_SIGNATURE_KEY
  config.algorithm        = 'MD5'
  config.service_domain   = 'payu.com'
  config.protocol         = 'https'
  config.env              = 'secure'
  config.order_url        = ''
  config.notify_url       = ''
  config.continue_url     = ''
end
