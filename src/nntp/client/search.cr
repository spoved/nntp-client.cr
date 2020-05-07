require "./articles"

class NNTP::Client
  # Search for the provided *message_id* in the provided *group*. Will return a `Int64`
  # indicating the article number in the group if found.
  def search_for(message_id : String, group : String, batch_size = 100, offset : Int64? = nil)
    info = group_info group
    start_num = offset || info[:first]
    Log.info { "Searching in Group: #{group} for id: #{message_id}" }

    with_group group do
      while start_num < info[:last]
        end_num = (start_num + batch_size)
        Log.verbose { "Searching articles #{start_num}-#{end_num}" \
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

  def search_for_value(value : String, header : String, group : String, batch_size = 100, offset : Int64? = nil)
    info = group_info group
    start_num = offset || info[:first]
    Log.info { "Searching in Group: #{group} for a header: #{header} containing value: #{value}" }

    with_group group do
      while start_num < info[:last]
        end_num = (start_num + batch_size)
        Log.verbose { "Searching articles #{start_num}-#{end_num}" \
                      " out of ~#{info[:last]} : #{(end_num / info[:last]) * 100}%" }

        resp = xheader(header, start_num, end_num)
        resp.text.each do |line|
          if line =~ /#{value}/
            return line.split(/\s+/).first.to_i64
          end
        end
        start_num += batch_size + 1
      end
    end
    nil
  end
end
