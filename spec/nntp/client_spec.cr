require "../spec_helper"

describe NNTP::Client do
  config = {
    host:        ENV["USENET_HOST"],
    port:        ENV["USENET_PORT"].to_i,
    user:        ENV["USENET_USER"],
    pass:        ENV["USENET_PASS"],
    auth_method: :original,
    uri:         URI.parse("nntp://#{ENV["USENET_USER"]}:#{URI.encode(ENV["USENET_PASS"])}" \
                   "@#{ENV["USENET_HOST"]}:#{ENV["USENET_PORT"]}/?ssl=true&verify_mode=none&method=original"),
  }

  it "can be initalized from uri" do
    NNTP::Client.new(config[:uri])
  end

  it "can eastablish connection" do
    client = NNTP::Client.new(config[:uri])
    client.using_connection do |conn|
      conn.connected?.should be_true
    end
  end
end
