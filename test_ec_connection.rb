require 'openssl'
require 'net/http'
require 'faraday'

p12 = OpenSSL::PKCS12.new File.read("ipad_ec.p12")
cert = p12.certificate
key = p12.key

    ca_cert = '/ca.crt'
    ssl_opts = { verify: false, client_cert: cert, client_key: key, ca_file: ca_cert}

    conn = Faraday.new(url: 'https://localhost', ssl: ssl_opts) do |faraday|
      faraday.response :logger
      faraday.request :url_encoded
      faraday.adapter Faraday.default_adapter
    end
response = conn.get 'ping.txt'

puts response.body

