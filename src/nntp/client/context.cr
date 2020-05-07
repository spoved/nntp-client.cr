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

  private property _contexts : Array(NNTP::Client::Context) = Array(NNTP::Client::Context).new

  def context? : Bool?
    !_contexts.empty?
  end

  # Returns the current `NNTP::Client::Context` indicating which (if any) NNTP positions are set.
  # (i.e. current group, article num or message id)
  def context : NNTP::Client::Context
    context? ? _contexts.last : NNTP::Client::Context.new(nil, nil)
  end

  private def context_start(group : String?, article : Int32 | Int64 | Nil = nil)
    new_group, group_changed = _group_context_update(group)
    new_headers = _article_context_update(new_group, group_changed, article)
    _contexts << NNTP::Client::Context.new(new_group, new_headers)
  end

  private def _group_context_update(group)
    # Is the group provided nil?
    if group.nil?
      # if we have a current context and it has a group, we can use that
      if context? && context.group?
        new_group = context.group
        group_changed = false
      else
        # If we dont have a new or previous group to reference, time to raise a error
        raise NNTP::Client::Error::NoGroupContext.new(
          "A newsgroup must be provided or previously defined to change contexts"
        )
      end
    else
      # if we have a group provided, lets see if its changed from current
      if context? && context.group? && context.group_name == group
        # nope! its the same, lets use it
        new_group = context.group
        group_changed = false
      else
        # ok its different lets grab the info
        new_group = group_info(group)
        group_changed = true
      end
    end
    {new_group, group_changed}
  end

  private def _article_context_update(new_group, group_changed, article)
    # Now lets check the article
    if article.nil?
      # There wasnt one provided. done!
      nil
    elsif new_group.nil?
      # unsure how we got here, but if the new group is nil, raise an error
      raise NNTP::Client::Error::NoGroupContext.new(
        "A newsgroup must be provided or previously defined to change contexts"
      )
    elsif !group_changed && context.article? && context.article_num == article
      # So group didnt change and neither did the article. weird but w/e, reuse it
      context.article
    else
      # Believe we have a new article here, grab the header and update the pointer
      _headers(article)
    end
  end

  # :nodoc:
  private def context_done
    prev = _contexts.pop
    # Need to set NNTP internal pointers back to last context

    # if we dont have a current context now then were done
    return unless context?

    # if we dont have a group in the current context, then no pointer updates are needed
    return unless context.group?

    # Did previous context have a group (it should have!)
    if prev.group?
      # Check if current and last context groups were the same
      if prev.group.not_nil![:name] == context.group.not_nil![:name]
        # they were the same no need to update group
      else
        # Set group pointer to new context
        group_info(context.group.not_nil![:name])
      end
    else
      # For some reason we didnt have a group in last context, but we have one again?
      # fine, update the pointer.
      group_info(context.group.not_nil![:name])
    end

    # Lets keep article updates simple. Just updated the pointer if its set
    self.socket.stat context.article_num if context.article?
  end

  private def check_group_context!
    conn_check!
    raise NNTP::Client::Error::NoGroupContext.new(
      "A newsgroup must be set before trying to use an article"
    ) if !self.context? || !self.context.group?
  end

  private def check_article_context!
    conn_check!
    raise NNTP::Client::Error::NoArticleContext.new(
      "A article must be set before calling this method"
    ) if !self.context? || !self.context.article_num?
  end
end
