#!/usr/bin/env ruby

require 'json'
require 'openssl'
require 'faraday'
require 'jwt'

private_pem = ENV['APP_PRIVATE_KEY']
private_key = OpenSSL::PKey::RSA.new(private_pem)

# Generate the JWT
payload = {
  # issued at time
  iat: Time.now.to_i,
  # JWT expiration time (10 minute maximum)
  exp: Time.now.to_i + (10 * 60),
  # GitHub App's identifier
  iss: ENV['APP_ID']
}

jwt = JWT.encode(payload, private_key, "RS256")

connection = Faraday.new do |conn|
  conn.response :raise_error
  conn.adapter Faraday.default_adapter
end

response = connection.post("https://api.github.com/app/installations/#{ENV['APP_INSTALLATION_ID']}/access_tokens",
                           nil,
                           'Authorization' => "Bearer #{jwt}",
                           'Accept' => 'application/vnd.github.v3+json')
response_body = JSON.parse response.body
puts response_body['token']
