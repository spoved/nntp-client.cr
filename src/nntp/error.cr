class NNTP::Error < Net::NNTP::Error
  class PoolTimeout < NNTP::Error; end

  class NoSuchGroup < NNTP::Error; end

  class ContextError < NNTP::Error; end

  class NoGroupContext < ContextError; end

  class NoArticleContext < ContextError; end

  class NoSuchArticle < NNTP::Error; end

  class NoConnection < NNTP::Error; end
end
