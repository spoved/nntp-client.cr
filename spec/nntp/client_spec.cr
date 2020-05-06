require "../spec_helper"

describe NNTP::Client do
  it "initializes without a socket" do
    client = NNTP::Client.new
    client.connected?.should be_false
  end

  it "initializes with defaults" do
    client = NNTP::Client.new
    client.host.should eq "127.0.0.1"
    client.port.should eq 119
    client.use_ssl.should be_true
    client.open_timeout.should eq 30
    client.read_timeout.should eq 60
  end

  it "can be configured with a block" do
    client = NNTP::Client.new
    client.host.should eq "127.0.0.1"
    client.port.should eq 119

    client.configure do |c|
      c.host = "usenet.com"
      c.port = 222
      c.use_ssl = false
      c.open_timeout = 9999
      c.read_timeout = 1
    end

    client.host.should eq "usenet.com"
    client.port.should eq 222
    client.use_ssl.should be_false
    client.open_timeout.should eq 9999
    client.read_timeout.should eq 1
  end

  it "can connect" do
    client = NNTP::Client.new(ENV["USENET_HOST"], ENV["USENET_PORT"].to_i)
    client.connected?.should be_false
    begin
      client.connect(ENV["USENET_USER"], ENV["USENET_PASS"], :original)
      client.connected?.should be_true
    ensure
      client.close
    end
  end

  it "#self.connect" do
    client = NNTP::Client.connect(host: ENV["USENET_HOST"], port: ENV["USENET_PORT"].to_i,
      user: ENV["USENET_USER"], secret: ENV["USENET_PASS"], method: :original
    )
    client.connected?.should be_true
    client.close
  end
end
