module NNTP
  module ConnectionContext
    # Returns the uri with the connection settings to the database
    abstract def uri : URI

    # Indicates that the *connection* was permanently closed
    # and should not be used in the future.
    abstract def discard(connection : Connection)

    # Indicates that the *connection* is no longer needed
    # and can be reused in the future.
    abstract def release(connection : Connection)
  end

  # :nodoc:
  class SingleConnectionContext
    include ConnectionContext

    getter uri : URI

    def initialize(@uri : URI)
    end

    def discard(connection : Connection)
    end

    def release(connection : Connection)
    end
  end
end
