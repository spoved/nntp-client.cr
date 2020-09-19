require "./error"

# Struct to hold the current group and article header information
struct NNTP::Context
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

  property group : Group?
  property article : Header?

  def initialize(@group : Group?, @article : Header?); end

  # Will return `true` if `group` is not nil
  def group?
    !self.group.nil?
  end

  # Will return `true` if `article_num` is not nil and not 0
  def article_num?
    !self.article.nil? && self.article.as(Header)[:num] != 0
  end

  # :ditto:
  def article?
    article_num?
  end

  # Will return `true` if `article_num` is not nil
  def message_id?
    !self.article.nil? && self.article.not_nil![:message_id] != 0
  end

  def group_name : String
    self.group.not_nil![:name]
  end

  # Will return the current article number. If no article number is set it
  # will raise a `NNTP::Error::NoArticleContext` error. Check before
  # access with `article_num?`
  # ```
  # client.article_num? # => true
  # client.article_num  # => 56910000
  # ```
  def article_num : Int64
    raise NNTP::Error::NoArticleContext.new unless article_num?
    self.article.as(Header)[:num]
  end

  # Will return the current article message id. If no article number is set it
  # will raise a `NNTP::Error::NoArticleContext` error. Check before
  # access with `message_id?`
  # ```
  # client.message_id? # => true
  # client.message_id  # => "YwGnYrShOtJaBfSzZlTkKbBh-1587103108703@nyuu"
  # ```
  def message_id : String
    raise NNTP::Error::NoArticleContext.new unless message_id?
    self.article.as(Header)[:message_id]
  end
end
