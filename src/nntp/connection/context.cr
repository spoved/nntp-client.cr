require "../context"

module NNTP::Connection::Context
  private property _contexts : Array(NNTP::Context) = Array(NNTP::Context).new

  def context? : Bool?
    !_contexts.empty?
  end

  def clear_context
    _contexts.clear
  end

  # Returns the current `NNTP::Context` indicating which (if any) NNTP positions are set.
  # (i.e. current group, article num or message id)
  def context : NNTP::Context
    context? ? _contexts.last : NNTP::Context.new(nil, nil)
  end

  # Will set current context
  def set_context(context : NNTP::Context)
    context_start(context.group_name, context.article_num? ? context.article_num : nil)
  end

  def context_start(group : String?, article : Int32 | Int64 | Nil = nil)
    new_group, group_changed = _group_context_update(group)
    new_headers = _article_context_update(new_group, group_changed, article)
    _contexts << NNTP::Context.new(new_group, new_headers)
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
        raise NNTP::Error::NoGroupContext.new(
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
      raise NNTP::Error::NoGroupContext.new(
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
    raise NNTP::Error::NoGroupContext.new(
      "A newsgroup must be set before trying to use an article"
    ) if !self.context? || !self.context.group?
  end

  private def check_article_context!
    conn_check!
    raise NNTP::Error::NoArticleContext.new(
      "A article must be set before calling this method"
    ) if !self.context? || !self.context.article_num?
  end
end
