class NNTP::Client::Error < Exception
  class NoSuchGroup < NNTP::Client::Error; end
end
