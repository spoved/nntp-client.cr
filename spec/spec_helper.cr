require "dotenv"
Dotenv.load if File.exists?(".env")

require "spec"
require "../src/nntp-client"

def with_client
  client = NNTP::Connection.connect(host: ENV["USENET_HOST"], port: ENV["USENET_PORT"].to_i,
    user: ENV["USENET_USER"], secret: ENV["USENET_PASS"], method: :original
  )
  yield client
ensure
  client.close unless client.nil?
end
