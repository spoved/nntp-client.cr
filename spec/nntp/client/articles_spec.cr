require "../../spec_helper"

describe NNTP::Client, focus: true do
  describe "with existing newsgroup" do
    newsgroup = "alt.binaries.cbt"
    describe "with existing" do
      article_num = 56910000_i64
      message_id = "YwGnYrShOtJaBfSzZlTkKbBh-1587103108703@nyuu"

      describe "article number" do
        describe "it fetches" do
          it "#article_head" do
            with_client do |client|
              client.with_group newsgroup do
                resp = client.article_head(article_num)
                resp[:num].should eq article_num
                resp[:id].should eq message_id
                resp[:headers].should be_a Hash(String, String)
                resp[:headers].should_not be_empty
              end
            end
          end

          it "#article_body", focus: true do
            with_client do |client|
              client.with_group newsgroup do
                resp = client.article_body(article_num)
                resp.should be_a Array(String)
                resp.should_not be_empty
              end
            end
          end
        end
      end

      describe "message id" do
        describe "it fetches" do
          it "#article_head" do
            with_client do |client|
              client.with_group newsgroup do
                resp = client.article_head(message_id)
                resp[:num].should eq 0
                resp[:id].should eq message_id
                resp[:headers].should be_a Hash(String, String)
                resp[:headers].should_not be_empty
              end
            end
          end

          it "#article_body" do
            with_client do |client|
              client.with_group newsgroup do
                resp = client.article_body(message_id)
                resp.should be_a Array(String)
                resp.should_not be_empty
              end
            end
          end
        end
      end
    end

    describe "with missing" do
      article_num = 10_i64
      message_id = "madeup-id@fake.com"

      describe "article number" do
        describe "it raises NoSuchArticle error" do
          it "#article_head" do
            with_client do |client|
              client.with_group newsgroup do
                expect_raises NNTP::Client::Error::NoSuchArticle, "Article Number: #{article_num}" do
                  client.article_head(article_num)
                end
              end
            end
          end

          it "#article_body" do
            with_client do |client|
              client.with_group newsgroup do
                expect_raises NNTP::Client::Error::NoSuchArticle, "Article Number: #{article_num}" do
                  client.article_body(article_num)
                end
              end
            end
          end
        end
      end

      describe "message id" do
        describe "it raises NoSuchArticle error" do
          it "#article_head" do
            with_client do |client|
              client.with_group newsgroup do
                expect_raises NNTP::Client::Error::NoSuchArticle, "Message Id: #{message_id}" do
                  client.article_head(message_id)
                end
              end
            end
          end

          it "#article_body" do
            with_client do |client|
              client.with_group newsgroup do
                expect_raises NNTP::Client::Error::NoSuchArticle, "Message Id: #{message_id}" do
                  client.article_body(message_id)
                end
              end
            end
          end
        end
      end
    end
  end
end
