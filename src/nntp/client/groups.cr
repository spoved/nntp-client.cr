require "./context"

class NNTP::Client
  # Will set the current group to provided *group* and yield `self` to provided block
  # ```
  # client.with_group("alt.binaries.cbt") do |c|
  #   # Perform actions within the context of group alt.binaries.cbt
  # end
  # ```
  def with_group(group, &block)
    conn_check!
    Log.info { "#{host}: setting current group to #{group}" }
    self.curr_group = group_info(group)
    yield self
    self.curr_group = nil
  end

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
    if /No Such Group/ === ex.message
      raise NNTP::Client::Error::NoSuchGroup.new(group)
    else
      raise ex
    end
  end
end
