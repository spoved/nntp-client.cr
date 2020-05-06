class NNTP::Client
  alias Group = NamedTuple(
    name: String,
    total: Int64,
    first: Int64,
    last: Int64,
  )

  struct Context
    property group, article_num, message_id

    def initialize(@group : Group?, @article_num : Int64?, @message_id : String?); end

    def group?
      !self.group.nil?
    end

    def article_num?
      !self.article_num.nil?
    end

    def message_id?
      !self.message_id.nil?
    end
  end

  private property curr_group : Group? = nil
  private property curr_article_num : Int64? = nil
  private property curr_message_id : String? = nil

  # Returns the current `NNTP::Client::Context` indicating which (if any) NNTP positions are set.
  # (i.e. current group, article num or message id)
  def current_context : NNTP::Client::Context
    NNTP::Client::Context.new(curr_group, curr_article_num, curr_message_id)
  end
end
