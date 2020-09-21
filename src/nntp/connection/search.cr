require "./articles"

module NNTP::Connection::Search
  # Search for the provided *message_id* in the provided *group*. Will return a `Int64`
  # indicating the article number in the group if found.
  # *batch_size* determines the amount of articles to query at a time, while
  # *offset* determines the article start position. If `nil` *offset* will default
  # to the first article in *group*.
  #
  # ```
  # # Start searching at article 1958260 and query 2000 at a time
  # client.find_article_num(
  #   message_id: "1359110409.83725.1@reader.easyusenet.nl",
  #   group: "alt.binaries.tun",
  #   batch_size: 2000,
  #   offset: 1958260_i64
  # ) # => 1958270
  #
  # client.with_group "alt.binaries.tun" do
  #   client.find_article_num(
  #     message_id: "1359110409.83725.1@reader.easyusenet.nl",
  #     batch_size: 2000,
  #     offset: 1958260_i64
  #   ) # => 1958270
  # end
  # ```
  def find_article_num(message_id : String, group : String? = nil,
                       batch_size = 100, offset : Int64? = nil)
    info = if group.nil?
             check_group_context!
             context.group.not_nil!
           else
             group_info(group)
           end

    start_num = offset || info[:first]
    Log.info { "[#{Fiber.current.name}] Searching in Group: #{group} for id: #{message_id}" }

    with_group group do
      while start_num < info[:last]
        end_num = (start_num + batch_size)
        Log.debug { "[#{Fiber.current.name}] Searching articles #{start_num}-#{end_num}" \
                    " out of ~#{info[:last]} : #{(end_num / info[:last]) * 100}%" }

        resp = xheader("message-id", start_num, end_num)
        resp.text.each do |line|
          if line =~ /(\d+)\s+<#{message_id}>/
            return $1.to_i64
          end
        end
        start_num += batch_size + 1
      end
    end
    nil
  end

  # Search for the first article with the *value* within the specified *header*.
  # This will simply search for the substring within the header of each article
  # and return the first match.
  # If *exact* is `true` it will attempt to match the entire header value.
  #
  # *group* can be ommited if used within a `with_group` block. If the current context
  # does not have a group a `NNTP::Error::NoGroupContext` error will be raised.
  #
  # *batch_size* determines the amount of articles to query at a time, while
  # *offset* determines the article start position. If `nil` *offset* will default
  # to the first article in *group*.
  def search_for_header(header : String, value : String,
                        group : String? = nil, batch_size = 100,
                        offset : Int64? = nil, exact = false)
    info = if group.nil?
             check_group_context!
             context.group.not_nil!
           else
             group_info(group)
           end

    start_num = offset || info[:first]

    Log.info { "[#{Fiber.current.name}] Searching in Group: #{group} for a header: #{header} containing value: #{value}" }

    with_group group do
      while start_num < info[:last]
        end_num = (start_num + batch_size)
        Log.debug { "[#{Fiber.current.name}] Searching articles #{start_num}-#{end_num}" \
                    " out of ~#{info[:last]} : #{(end_num / info[:last]) * 100}%" }

        resp = xheader(header, start_num, end_num)
        resp.text.each do |line|
          if exact && line =~ /^(\d+)\s+#{value}$/
            return $1.to_i64
          elsif line =~ /#{value}/
            return line.split(/\s+/).first.to_i64
          end
        end
        start_num += batch_size + 1
      end
    end
    nil
  end
end
