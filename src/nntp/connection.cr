require "log"
require "nntp-lib"
require "openssl"

class NNTP::Connection
  Log = ::Log.for(self)

  private property nntp_socket : NNTP::Socket? = nil

  property host : String = "127.0.0.1"
  property port : Int32 = 119
  property use_ssl : Bool = true
  property open_timeout : Int32 = 30
  property read_timeout : Int32 = 60
  property verify_mode : OpenSSL::SSL::VerifyMode = OpenSSL::SSL::VerifyMode::PEER
end

require "./connection/*"

class NNTP::Connection
  include NNTP::Connection::Articles
  include NNTP::Connection::Context
  include NNTP::Connection::Groups
  include NNTP::Connection::Search
  include NNTP::Connection::Pool

  # :nodoc:
  private def socket : NNTP::Socket
    self.nntp_socket.not_nil!
  end

  # :nodoc:
  private def conn_check!
    raise NNTP::Error::NoConnection.new("There is no active connection!") unless connected?
  end

  # nntp://user:password@usenethost.com:443/?ssl=true&verify_mode=none&method=original
  def initialize(uri : URI)
    @client_context = NNTP::SingleConnectionContext.new(uri)
    @host = uri.host || "127.0.0.1"
    @port = uri.port || 119

    @use_ssl = !!(uri.query_params["ssl"]? && uri.query_params["ssl"] == "true")

    @open_timeout = uri.query_params["open_timeout"]? ? uri.query_params["open_timeout"].to_i : 30
    @read_timeout = uri.query_params["read_timeout"]? ? uri.query_params["read_timeout"].to_i : 60

    case uri.query_params["verify_mode"]?.try &.downcase
    when "peer"
      @verify_mode = OpenSSL::SSL::VerifyMode::PEER
    when "none"
      @verify_mode = OpenSSL::SSL::VerifyMode::NONE
    else
      @verify_mode = OpenSSL::SSL::VerifyMode::PEER
    end
  end

  def self.new
    NNTP::Connection.new(URI.parse("nntp://127.0.0.1:119/?ssl=true&verify_mode=none&method=original"))
  end

  def self.new(host, port = 119, use_ssl = true,
               verify_mode : String = "peer",
               open_timeout : Int32 = 30,
               read_timeout : Int32 = 60) : Connection
    NNTP::Connection.new(URI.parse("nntp://#{host}:#{port}/?ssl=#{use_ssl}&verify_mode=#{verify_mode}&method=original" \
                                   "&open_timeout=#{open_timeout}&read_timeout=#{read_timeout}"))
  end

  # Will initialize a new `Connection` object, configure it, then establish a connection.
  # The created `Connection` will then be returned.
  # ```
  # client = NNTP::Connection.connect("localhost", user: "myuser", pass: "mypass")
  # client.connected? # => true
  # ```
  def self.connect(host, port = 119, use_ssl = true,
                   verify_mode : OpenSSL::SSL::VerifyMode = OpenSSL::SSL::VerifyMode::PEER,
                   open_timeout : Int32 = 30,
                   read_timeout : Int32 = 60,
                   user : String? = nil, secret : String? = nil,
                   method = :original) : Connection
    uri = URI.parse("nntp://#{URI.encode(user)}:#{URI.encode(secret)}@#{host}:#{port}/" \
                    "?ssl=#{use_ssl}&verify_mode=#{verify_mode}&method=#{method}" \
                    "&open_timeout=#{open_timeout}&read_timeout=#{read_timeout}")
    client = NNTP::Connection.new(uri)
    client.connect(user, secret, method)
    client
  end

  def self.connect(uri : URI)
    client = NNTP::Connection.new(uri)
    client.connect(uri.user, uri.password, :original)
    client
  end

  # Will yield `self` to provided block allow for variable setting.
  # Then create a new `NNTP::Socket` instance (without connecting) Will return `self`.
  # ```
  # client = NNTP::Connection.new
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
    ssl_context = OpenSSL::SSL::Context::Client.new
    ssl_context.verify_mode = verify_mode

    self.nntp_socket = NNTP::Socket.new(host, port, use_ssl, open_timeout, read_timeout, ssl_context: ssl_context)
    self
  end

  def close
    if connected?
      self.nntp_socket.not_nil!.finish
    end
    @client_context.discard self
  rescue ex : Net::NNTP::Error::UnknownError
    raise NNTP::Error::NoConnection.new
    # can raise an error if socket is already closed
  end

  # Returns `true` if a connection has been established and `false` if not.
  # ```
  # client = NNTP::Connection.new
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
  # client = NNTP::Connection.new
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

  def connect(uri : URI)
    connect(uri.user, uri.password)
  end
end
