# nntp-client

A NNTP (Network News Transfer Protocol) client aimed to provide a more useful interface to the [nntp-lib](https://github.com/spoved/nntp-lib.cr)

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     nntp-client:
       github: spoved/nntp-client.cr
   ```

2. Run `shards install`

## Usage

```crystal
require "nntp-client"

client = NNTP::Client.connect(
  host: ENV["USENET_HOST"],
  port: ENV["USENET_PORT"].to_i,
  user: ENV["USENET_USER"],
  secret: ENV["USENET_PASS"], method: :original
)

# Search for the article num of this post
client.find_article_num(
  message_id: "1359110409.83725.1@reader.easyusenet.nl",
  group: "alt.binaries.tun",
  batch_size: 2000,
  offset: 1958260_i64
) # => 1958270

# Fetch article headers
client.with_group "alt.binaries.tun" do
  client.headers(1958270) # => {num: 1958270, id: "1359110409.83725.1@reader.easyusenet.nl", headers: {"Path" => "not-for-mail", "From" => "lori256 <lori256@isiinheaven.net>", "Newsgroups" => "alt.binaries.tun", "Subject" => "2kGiFqHLaYfIBPbtk1CPsDsdDJubu4[1/5] - \"PbtdX885Fs5QvhcwY2Wo-thumb.jpg\" yEnc (1/1)", "Message-ID" => "<1359110409.83725.1@reader.easyusenet.nl>", "X-Newsposter" => "newsmangler 0.03 (yenc-fred) - http://www.madcowdisease.org/mcd/newsmangler", "Date" => "25 Jan 2013 10:39:23 GMT", "Lines" => "424", "Organization" => "easyusenet", "X-Received-Bytes" => "55537"}}
end
```

See spec tests for examples.

## Contributing

1. Fork it (<https://github.com/spoved/nntp-client.cr/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Holden Omans](https://github.com/kalinon) - creator and maintainer
