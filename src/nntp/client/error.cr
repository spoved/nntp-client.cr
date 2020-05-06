class NNTP::Client::Error < Exception
  class NoSuchGroup < NNTP::Client::Error; end

  class NoGroupContext < NNTP::Client::Error; end
end
