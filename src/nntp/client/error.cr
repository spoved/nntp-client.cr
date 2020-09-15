class NNTP::Client::Error < Exception
  class NoSuchGroup < NNTP::Client::Error; end

  class ContextError < NNTP::Client::Error; end

  class NoGroupContext < ContextError; end

  class NoArticleContext < ContextError; end

  class NoSuchArticle < NNTP::Client::Error; end

  class NoConnection < NNTP::Client::Error; end
end
