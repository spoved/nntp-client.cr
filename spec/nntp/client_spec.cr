require "../spec_helper"

describe NNTP::Client do
  config = {
    host:        ENV["USENET_HOST"],
    port:        ENV["USENET_PORT"].to_i,
    user:        ENV["USENET_USER"],
    pass:        ENV["USENET_PASS"],
    auth_method: :original,
  }

  describe "when created" do
    it "does not have a active socket" do
      client = NNTP::Client.new
      client.connected?.should be_false
    end
    it "has has default configuration" do
      client = NNTP::Client.new
      client.host.should eq "127.0.0.1"
      client.port.should eq 119
      client.use_ssl.should be_true
      client.open_timeout.should eq 30
      client.read_timeout.should eq 60
    end
  end

  describe "when configured" do
    describe "with a block" do
      it "retains new values" do
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
    end

    describe "correctly" do
      it "can eastablish connection" do
        client = NNTP::Client.new(config[:host], config[:port])
        client.connected?.should be_false
        begin
          client.connect(config[:user], config[:pass], config[:auth_method])
          client.connected?.should be_true
        ensure
          client.close
        end
      end
    end

    describe "incorrectly" do
      describe "with a bad host" do
        host = "not.a.real.host"
        describe "#connect" do
          it "should raise Socket::Addrinfo::Error" do
            client = NNTP::Client.new(host, config[:port])
            client.connected?.should be_false
            expect_raises Socket::Addrinfo::Error do
              client.connect(config[:user], config[:pass], config[:auth_method])
            end
          end
        end
      end

      describe "with a bad port" do
        port = 777
        describe "#connect" do
          it "should raise Socket::ConnectError" do
            client = NNTP::Client.new(config[:host], port)
            client.connected?.should be_false
            expect_raises Socket::ConnectError do
              client.connect(config[:user], config[:pass], config[:auth_method])
            end
          end
        end
      end

      describe "with a bad authentication" do
        user = "fakedude"
        describe "#connect" do
          it "should raise Net::NNTP::Error::AuthenticationError" do
            client = NNTP::Client.new(config[:host], config[:port])
            client.connected?.should be_false
            expect_raises Net::NNTP::Error::AuthenticationError do
              client.connect(user, config[:pass], config[:auth_method])
            end
          end
        end
      end
    end
  end

  it "#self.connect" do
    client = NNTP::Client.connect(host: config[:host], port: config[:port],
      user: config[:user], secret: config[:pass], method: config[:auth_method]
    )
    client.connected?.should be_true
    client.close
  end
end
