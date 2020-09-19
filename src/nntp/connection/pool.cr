require "../connection_context"

module NNTP::Connection::Pool
  # :nodoc:
  property auto_release : Bool = true
  # :nodoc:
  property client_context : NNTP::ConnectionContext

  # :nodoc:
  protected def before_checkout
    @auto_release = true
  end

  # :nodoc:
  protected def after_release
    clear_context
  end

  # return this connection to the pool
  # managed by the client. Should be used
  # only if the connection was obtained by `NNTP::Client#checkout`.
  def release
    @client_context.release(self)
  end
end
