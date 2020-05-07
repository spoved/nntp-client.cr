require "../../spec_helper"

describe NNTP::Client do
  describe "with group context" do
    describe "#find_article_num" do
      it "will return article num" do
        with_client do |client|
          client.with_group "alt.binaries.tun" do
            num = client.find_article_num(
              message_id: "1359110409.83725.1@reader.easyusenet.nl",
              batch_size: 2000,
              offset: 1958260_i64
            ) # => 1958270
            num.should eq 1958270
          end
        end
      end
    end
  end

  describe "without group context" do
    describe "#find_article_num" do
      describe "with group provided" do
        it "will return article num" do
          with_client do |client|
            num = client.find_article_num(
              message_id: "1359110409.83725.1@reader.easyusenet.nl",
              group: "alt.binaries.tun",
              batch_size: 2000,
              offset: 1958260_i64
            ) # => 1958270
            num.should eq 1958270
          end
        end
      end

      describe "with no group provided" do
        it "will raise an error" do
          with_client do |client|
            expect_raises NNTP::Client::Error::NoGroupContext do
              client.find_article_num(
                message_id: "1359110409.83725.1@reader.easyusenet.nl",
                batch_size: 2000,
                offset: 1958260_i64
              ) # => 1958270
            end
          end
        end
      end
    end
  end
end
