require "./context"

class NNTP::Client
  delegate list_active, list_active_times, list_distributions,
    list_distrib_pats, list_newsgroups, list_subscriptions,
    to: @nntp_socket.not_nil!

  # Fetch all groups
  def groups : Array(String)
    self.socket.list.text
  end

  # Will set the current group to provided *group* and yield `self` to provided block
  # ```
  # client.with_group("alt.binaries.cbt") do |c|
  #   # Perform actions within the context of group alt.binaries.cbt
  # end
  # ```
  def with_group(group, &block)
    conn_check!
    Log.info { "#{host}: setting current group to #{group}" }
    context_start(group, nil)
    yield self
    context_done
  end

  # Will fetch the requested group and return a `Group` tuple. If no group is
  # found, it will raise a `NNTP::Client::Error::NoSuchGroup` error.
  # ```
  # client.group_info "alt.binaries.cbt" # => {name: "alt.binaries.cbt", total: 56894558, first: 15495, last: 56910052}
  # ```
  def group_info(group) : Group
    resp = socket.group(group)
    parts = resp.msg.split(/\s+/)
    {
      name:  parts[3],
      total: parts[0].to_i64,
      first: parts[1].to_i64,
      last:  parts[2].to_i64,
    }
  rescue ex : Net::NNTP::Error::ServerBusy
    if /No Such Group/i === ex.message || /411/ === ex.message
      raise NNTP::Client::Error::NoSuchGroup.new(group)
    else
      raise ex
    end
  end

  # Will fetch a list of the article numbers in the provided group
  def group_article_ids(group)
    self.socket.listgroup(group).text.map &.to_i64
  end

  # Will fetch a list of the article numbers in the current group
  def article_ids
    check_group_context!
    self.socket.listgroup.text.map &.to_i64
  end
end
