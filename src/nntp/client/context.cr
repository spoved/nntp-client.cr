class NNTP::Client
  alias Group = NamedTuple(
    name: String,
    total: Int64,
    first: Int64,
    last: Int64,
  )

  alias Header = NamedTuple(
    num: Int64,
    id: String,
    headers: Hash(String, String),
  )

  # Struct to hold the current group and article header information
  struct Context
    property group
    property article

    def initialize(@group : Group?, @article : Header?); end

    # Will return `true` if `group` is not nil
    def group?
      !self.group.nil?
    end

    # Will return `true` if `article_num` is not nil
    def article_num?
      !self.article.nil? && self.article.as(Header)[:num] != 0
    end

    # Will return `true` if `article_num` is not nil
    def message_id?
      !self.article.nil? && self.article.as(Header)[:message_id] != 0
    end

    # Will return the current article number. If no article number is set it
    # will raise a `NNTP::Client::Error::NoArticleContext` error. Check before
    # access with `article_num?`
    # ```
    # client.article_num? # => true
    # client.article_num  # => 56910000
    # ```
    def article_num : Int64
      raise NNTP::Client::Error::NoArticleContext.new unless article_num?
      self.article.as(Header)[:num]
    end

    # Will return the current article message id. If no article number is set it
    # will raise a `NNTP::Client::Error::NoArticleContext` error. Check before
    # access with `message_id?`
    # ```
    # client.message_id? # => true
    # client.message_id  # => "YwGnYrShOtJaBfSzZlTkKbBh-1587103108703@nyuu"
    # ```
    def message_id : String
      raise NNTP::Client::Error::NoArticleContext.new unless message_id?
      self.article.as(Header)[:message_id]
    end
  end

  private property curr_group : Group? = nil
  private property curr_article : Header? = nil

  # Returns the current `NNTP::Client::Context` indicating which (if any) NNTP positions are set.
  # (i.e. current group, article num or message id)
  def current_context : NNTP::Client::Context
    NNTP::Client::Context.new(curr_group, curr_article)
  end

  # :ditto:
  def context
    current_context
  end

  # :nodoc:
  private def unset_group_context
    self.curr_group = nil
  end

  # :nodoc:
  private def unset_article_context
    self.curr_article = nil
  end
end
