require "../context"

private macro delegate_block(*methods, to object)
  {% for method in methods %}
    {% if method.id.ends_with?('=') && method.id != "[]=" %}
      def {{method.id}}(arg)
        {{object.id}} &.{{method.id}} arg
      end
    {% else %}
      def {{method.id}}(*args, **options)
        {{object.id}} &.{{method.id}}(*args, **options)
      end

      {% if method.id != "[]=" %}
        def {{method.id}}(*args, **options)
          {{object.id}} &.{{method.id}}(*args, **options) do |*yield_args|
            yield *yield_args
          end
        end
      {% end %}
    {% end %}
  {% end %}
end

module NNTP::Connection::Groups
  delegate_block list_active, list_active_times, list_distributions,
    list_distrib_pats, list_newsgroups, list_subscriptions,
    list_overview_fmt, to: with_socket

  # Fetch all groups
  def groups : Array(String)
    with_socket &.list.text
  end

  # Will set the current group to provided *group* and yield `self` to provided block
  # ```
  # client.with_group("alt.binaries.cbt") do |c|
  #   # Perform actions within the context of group alt.binaries.cbt
  # end
  # ```
  def with_group(group, &block)
    conn_check!
    Log.info { "[#{Fiber.current.name}] #{host}: setting current group to #{group}" }
    context_start(group, nil)
    yield self
    context_done
  end

  # Will fetch the requested group and return a `Group` tuple. If no group is
  # found, it will raise a `NNTP::Error::NoSuchGroup` error.
  # ```
  # client.group_info "alt.binaries.cbt" # => {name: "alt.binaries.cbt", total: 56894558, first: 15495, last: 56910052}
  # ```
  def group_info(group) : NNTP::Context::Group
    resp = with_socket &.group(group)
    parts = resp.msg.split(/\s+/)
    {
      name:  parts[3],
      total: parts[0].to_i64,
      first: parts[1].to_i64,
      last:  parts[2].to_i64,
    }
  rescue ex : Net::NNTP::Error::ServerBusy
    if /No Such Group/i === ex.message || /411/ === ex.message
      raise ::NNTP::Error::NoSuchGroup.new(group)
    else
      raise ex
    end
  end

  # Will fetch a list of the article numbers in the provided group
  def group_article_ids(group)
    with_socket &.listgroup(group).text.map &.to_i64
  end

  # Will fetch a list of the article numbers in the current group
  def article_ids
    check_group_context!
    with_socket &.listgroup.text.map &.to_i64
  end
end
