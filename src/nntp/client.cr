require "./connection"

module NNTP
  class Client
    include ConnectionContext

    # :nodoc:
    getter pool : NNTP::Pool(NNTP::Connection)

    # Returns the uri with the connection settings to the server
    getter uri : URI

    @pool : Pool(NNTP::Connection)
    @setup_connection : NNTP::Connection -> Nil

    def connection_pool_options(params : HTTP::Params)
      {
        initial_pool_size:  params.fetch("initial_pool_size", 1).to_i,
        max_pool_size:      params.fetch("max_pool_size", 0).to_i,
        max_idle_pool_size: params.fetch("max_idle_pool_size", 1).to_i,
        checkout_timeout:   params.fetch("checkout_timeout", 5.0).to_f,
        retry_attempts:     params.fetch("retry_attempts", 1).to_i,
        retry_delay:        params.fetch("retry_delay", 1.0).to_f,
      }
    end

    # :nodoc:
    def initialize(@uri : URI)
      params = HTTP::Params.parse(uri.query || "")
      pool_options = connection_pool_options(params)

      @setup_connection = ->(conn : NNTP::Connection) {
        conn.connect(@uri)
      }
      @pool = uninitialized Pool(Connection) # in order to use self in the factory proc
      @pool = Pool.new(**pool_options) {
        conn = NNTP::Connection.new(@uri)
        conn.client_context = self
        conn.auto_release = false
        @setup_connection.call conn
        conn
      }
    end

    def setup_connection(&proc : Connection -> Nil)
      @setup_connection = proc
      @pool.each_resource do |conn|
        @setup_connection.call conn
      end
    end

    # Closes all connection to the database.
    def close
      @pool.close
    end

    # :nodoc:
    def discard(connection : Connection)
      @pool.delete connection
    end

    # :nodoc:
    def release(connection : Connection)
      @pool.release connection
    end

    # :nodoc:
    def checkout_some(candidates : Enumerable(WeakRef(Connection))) : {Connection, Bool}
      @pool.checkout_some candidates
    end

    # yields a connection from the pool
    # the connection is returned to the pool
    # when the block ends
    def using_connection
      connection = self.checkout
      begin
        yield connection
      ensure
        connection.release
      end
    end

    # returns a connection from the pool
    # the returned connection must be returned
    # to the pool by explictly calling `Connection#release`
    def checkout
      connection = @pool.checkout
      connection.auto_release = false
      connection
    end

    # :nodoc:
    def retry
      @pool.retry do
        yield
      end
    end
  end
end
