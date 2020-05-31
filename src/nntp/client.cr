require "log"
require "nntp-lib"

alias NNTP::Socket = Net::NNTP

module NNTP
  class Client
    Log = ::Log.for(self)

    private property nntp_socket : NNTP::Socket? = nil

    property host : String = "127.0.0.1"
    property port : Int32 = 119
    property use_ssl : Bool = true
    property open_timeout : Int32 = 30
    property read_timeout : Int32 = 60

    def initialize; end

    # :nodoc:
    private def socket : NNTP::Socket
      self.nntp_socket.not_nil!
    end

    # :nodoc:
    private def conn_check!
      raise "There is no active connection!" unless connected?
    end

    def self.new(host, port = 119, use_ssl = true,
                 open_timeout : Int32 = 30,
                 read_timeout : Int32 = 60) : Client
      NNTP::Client.new.configure do |c|
        c.host = host
        c.port = port
        c.use_ssl = use_ssl
        c.open_timeout = open_timeout
        c.read_timeout = read_timeout
      end
    end

    # Will initialize a new `Client` object, configure it, then establish a connection.
    # The created `Client` will then be returned.
    # ```
    # client = NNTP::Client.connect("localhost", user: "myuser", pass: "mypass")
    # client.connected? # => true
    # ```
    def self.connect(host, port = 119, use_ssl = true,
                     open_timeout : Int32 = 30,
                     read_timeout : Int32 = 60,
                     user : String? = nil, secret : String? = nil,
                     method = :original) : Client
      client = NNTP::Client.new.configure do |c|
        c.host = host
        c.port = port
        c.use_ssl = use_ssl
        c.open_timeout = open_timeout
        c.read_timeout = read_timeout
      end

      client.connect(user, secret, method)
      client
    end

    # Will yield `self` to provided block allow for variable setting.
    # Then create a new `NNTP::Socket` instance (without connecting) Will return `self`.
    # ```
    # client = NNTP::Client.new
    # client.configure do |c|
    #   c.host = host
    #   c.port = port
    #   c.use_ssl = use_ssl
    #   c.open_timeout = open_timeout
    #   c.read_timeout = read_timeout
    # end
    # ```
    def configure
      yield self

      self.nntp_socket = NNTP::Socket.new(host, port, use_ssl, open_timeout, read_timeout)
      self
    end

    def close
      if connected?
        self.nntp_socket.not_nil!.finish
      end
    rescue ex : Net::NNTP::Error::UnknownError
      # can raise an error if socket is already closed
    end

    # Returns `true` if a connection has been established and `false` if not.
    # ```
    # client = NNTP::Client.new
    # client.connected? # => false
    # client.connect
    # client.connected? # => true
    # ```
    def connected?
      return false if nntp_socket.nil?
      nntp_socket.as(NNTP::Socket).started?
    end

    # Will establish a `NNTP::Socket` connection using client setting and any authentication
    # params passed.
    # ```
    # client = NNTP::Client.new
    # client.connect("MyUSER", "SuperSecret")
    #  ```
    def connect(user : String? = nil, secret : String? = nil, method = :original)
      raise "A connection is already established" if connected?
      if nntp_socket.nil?
        self.nntp_socket = NNTP::Socket.new(host, port, use_ssl, open_timeout, read_timeout)
      end
      self.nntp_socket.not_nil!.start(user, secret, method)

      self
    end
  end
end

require "./client/*"
