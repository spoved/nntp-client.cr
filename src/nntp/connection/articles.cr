require "./context"

module NNTP::Connection::Articles
  # Will set the current article to provided *num* and yield `self` to provided block
  # ```
  # client.with_group("alt.binaries.cbt") do
  #   client.with_article(56910000) do
  #     # Perform actions within the context of group alt.binaries.cbt and with article #56910000
  #   end
  # end
  # ```
  def with_article(num : Int32 | Int64, &block)
    check_group_context!

    Log.info { "#{host}: setting current article to #{num}" }
    context_start(nil, num)
    yield self
    context_done
  end

  # Will return a `Header` tuple with the fetched article information.
  # ```
  # client.with_group "alt.binaries.cbt" do
  #   client.headers 56910000 # => {num: 56910000, id: "YwGnYrShOtJaBfSzZlTkKbBh-1587103108703@nyuu", headers: {"Organization" => "Usenet.Farm", "Message-Id" => "<YwGnYrShOtJaBfSzZlTkKbBh-1587103108703@nyuu>", "User-Agent" => "Nyuu/0.3.8", "X-Ufhash" => "lHibuaCxtuuI3C4ugIWhcSBuWhY%2B2Wu5sbzIanIMroeK4nRzeUWbUwFaNNhD7Tot6%2FKfcwbvXWhI9Am82VQ%2BKph5IYQ8NMOUARHaXY8LlmDbOnmGi8qNLxh0IocmkVeY04Cfy2trF4cEtuV3wP1kSR7IfuJV3UPO9ORwOFvlZtOe6CwX16D%2BKM1%2B%2FBcetDZIGZapQoDQIhngZNENi5cRFlWbmy3CEqwpMsm8", "Date" => "Fri, 17 Apr 20 05:58:28 UTC", "Path" => "not-for-mail", "Subject" => "[170/170] - \"2CDrmrC36H47j0n1f.part161.rar\" yEnc (186/214) 153066646", "From" => "3vq60fEnli <AEdwj0ie5p@kgiqA10.com>", "Newsgroups" => "alt.binaries.bungalow,alt.binaries.downunder,alt.binaries.flowed,alt.binaries.cbt,alt.binaries.test, alt.binaries.boneless,alt.binaries.iso", "X-Received-Bytes" => "740517", "X-Received-Body-CRC" => "3585757165"}}
  # end
  # ```
  def headers(num : Int32 | Int64)
    check_group_context!

    _headers(num)
  rescue ex : Net::NNTP::Error::ServerBusy
    check_for_no_such_article(ex, num: num)
  end

  private def _headers(num : Int32 | Int64)
    resp = self.socket.head(num)
    parse_head_resp(resp, num)
  end

  # See `headers(num : Int32 | Int64)`.
  # Note: Using the *message_id* instead of article num
  # will return a article num of `0`.
  # ```
  # client.with_group "alt.binaries.cbt" do
  #   client.headers "YwGnYrShOtJaBfSzZlTkKbBh-1587103108703@nyuu" # => {num: 0, id: "YwGnYrShOtJaBfSzZlTkKbBh-1587103108703@nyuu", headers: {"Organization" => "Usenet.Farm", "Message-Id" => "<YwGnYrShOtJaBfSzZlTkKbBh-1587103108703@nyuu>", "User-Agent" => "Nyuu/0.3.8", "X-Ufhash" => "lHibuaCxtuuI3C4ugIWhcSBuWhY%2B2Wu5sbzIanIMroeK4nRzeUWbUwFaNNhD7Tot6%2FKfcwbvXWhI9Am82VQ%2BKph5IYQ8NMOUARHaXY8LlmDbOnmGi8qNLxh0IocmkVeY04Cfy2trF4cEtuV3wP1kSR7IfuJV3UPO9ORwOFvlZtOe6CwX16D%2BKM1%2B%2FBcetDZIGZapQoDQIhngZNENi5cRFlWbmy3CEqwpMsm8", "Date" => "Fri, 17 Apr 20 05:58:28 UTC", "Path" => "not-for-mail", "Subject" => "[170/170] - \"2CDrmrC36H47j0n1f.part161.rar\" yEnc (186/214) 153066646", "From" => "3vq60fEnli <AEdwj0ie5p@kgiqA10.com>", "Newsgroups" => "alt.binaries.bungalow,alt.binaries.downunder,alt.binaries.flowed,alt.binaries.cbt,alt.binaries.test, alt.binaries.boneless,alt.binaries.iso", "X-Received-Bytes" => "740517", "X-Received-Body-CRC" => "3585757165"}}
  # end
  # ```
  def headers(message_id : String)
    check_group_context!

    resp = self.socket.head(message_id)
    parse_head_resp(resp)
  rescue ex : Net::NNTP::Error::ServerBusy
    check_for_no_such_article(ex, message_id: message_id)
  end

  # Will return an `Array(String)` that is the article's body text.
  def body(num : Int32 | Int64) : Array(String)
    check_group_context!

    self.socket.body(num).text
  rescue ex : Net::NNTP::Error::ServerBusy
    check_for_no_such_article(ex, num: num)
  end

  # :ditto:
  def body(message_id : String) : Array(String)
    self.socket.body(message_id).text
  rescue ex : Net::NNTP::Error::ServerBusy
    check_for_no_such_article(ex, message_id: message_id)
  end

  def xheader(header, message_id : String? = nil)
    check_group_context!
    check_article_context! if message_id.nil?
    self.socket.xdhr(header, message_id)
  rescue ex : Net::NNTP::Error::ServerBusy
    check_for_no_such_article(ex, message_id: message_id)
  end

  def xheader(header, num : Int64 | Int32, end_num : Int64 | Int32 | Nil = nil, all : Bool = false)
    check_group_context!

    self.socket.xdhr(header, num, end_num, all)
  rescue ex : Net::NNTP::Error::ServerBusy
    check_for_no_such_article(ex)
  end

  def xover(num : Int64 | Int32, end_num : Int64 | Int32 | Nil = nil, all : Bool = false)
    check_group_context!

    self.socket.xover(num, end_num, all)
  rescue ex : Net::NNTP::Error::ServerBusy
    check_for_no_such_article(ex)
  end

  def last
    check_group_context!

    self.socket.stat context.article_num? ? context.article_num : 0
    resp = self.socket.last
    parse_head_resp(resp)
  rescue ex : Net::NNTP::Error::ServerBusy
    check_for_no_such_article(ex)
  end

  def next
    check_group_context!

    self.socket.stat context.article_num? ? context.article_num : 0
    resp = self.socket.next
    parse_head_resp(resp)
  rescue ex : Net::NNTP::Error::ServerBusy
    check_for_no_such_article(ex)
  end

  private def check_for_no_such_article(ex, num : Int64 | Int32 | Nil = nil, message_id : String? = nil)
    msg = ""
    msg += "Message Id: #{message_id} " unless message_id.nil?
    msg += "Article Number: #{num}" unless num.nil?

    if /No Such Article/i === ex.message
      raise NNTP::Error::NoSuchArticle.new(msg)
    else
      raise ex
    end
  end

  # Will parse the header response and retun a `Header`
  private def parse_head_resp(resp, num : Int32 | Int64 | Nil = nil)
    headers = Hash(String, String).new
    resp.text.each do |line|
      key, val = line.split(/:\s+/)
      headers[key] = val
    end

    parts = resp.msg.split(/\s+/)
    n = parts[0].to_i64
    if n == 0 && !num.nil?
      n = num.to_i64
    end
    id = parts[1].gsub(/\<|\>/, "")

    {
      num:     n,
      id:      id,
      headers: headers,
    }
  end
end
