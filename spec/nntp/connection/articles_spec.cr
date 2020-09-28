require "../../spec_helper"

describe NNTP::Connection do
  describe "with existing newsgroup" do
    newsgroup = "alt.binaries.cbt"

    describe "active article pointer" do
      describe "existing" do
        article_num = 56910000_i64

        it "#last" do
          with_client do |client|
            client.with_group newsgroup do
              client.headers(article_num)
              resp = client.last
              resp[:num].should eq 56909999_i64
            end
          end
        end

        it "#next" do
          with_client do |client|
            client.with_group newsgroup do
              client.headers(article_num)
              resp = client.next
              resp[:num].should eq 56910001_i64
            end
          end
        end
      end

      describe "missing" do
        pending "#last" do
          with_client do |client|
            client.with_group newsgroup do
              expect_raises NNTP::Error::NoSuchArticle do
                client.last
              end
            end
          end
        end

        pending "#next" do
          with_client do |client|
            client.with_group newsgroup do
              expect_raises NNTP::Error::NoSuchArticle do
                puts client.next
              end
            end
          end
        end
      end
    end

    describe "with existing" do
      article_num = 56910000_i64
      message_id = "YwGnYrShOtJaBfSzZlTkKbBh-1587103108703@nyuu"

      describe "article number" do
        describe "it fetches" do
          it "#last" do
            with_client do |client|
              client.with_group newsgroup do
                client.headers(article_num)
                resp = client.last
                resp[:num].should eq 56909999_i64
              end
            end
          end

          it "#next" do
            with_client do |client|
              client.with_group newsgroup do
                client.headers(article_num)
                resp = client.next
                resp[:num].should eq 56910001_i64
              end
            end
          end

          it "#headers" do
            with_client do |client|
              client.with_group newsgroup do
                resp = client.headers(article_num)
                resp[:num].should eq article_num
                resp[:id].should eq message_id
                resp[:headers].should be_a Hash(String, String)
                resp[:headers].should_not be_empty
              end
            end
          end

          it "#body" do
            with_client do |client|
              client.with_group newsgroup do
                resp = client.body(article_num)
                resp.should be_a Array(String)
                resp.should_not be_empty
              end
            end
          end
        end
      end

      describe "message id" do
        describe "it fetches" do
          it "#headers" do
            with_client do |client|
              client.with_group newsgroup do
                resp = client.headers(message_id)
                resp[:num].should eq 0
                resp[:id].should eq message_id
                resp[:headers].should be_a Hash(String, String)
                resp[:headers].should_not be_empty
              end
            end
          end

          it "#body" do
            with_client do |client|
              client.with_group newsgroup do
                resp = client.body(message_id)
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
          it "#headers" do
            with_client do |client|
              client.with_group newsgroup do
                expect_raises NNTP::Error::NoSuchArticle, "Article Number: #{article_num}" do
                  client.headers(article_num)
                end
              end
            end
          end

          it "#body" do
            with_client do |client|
              client.with_group newsgroup do
                expect_raises NNTP::Error::NoSuchArticle, "Article Number: #{article_num}" do
                  client.body(article_num)
                end
              end
            end
          end
        end
      end

      describe "message id" do
        describe "it raises NoSuchArticle error" do
          it "#headers" do
            with_client do |client|
              client.with_group newsgroup do
                expect_raises NNTP::Error::NoSuchArticle, "Message Id: #{message_id}" do
                  client.headers(message_id)
                end
              end
            end
          end

          it "#body" do
            with_client do |client|
              client.with_group newsgroup do
                expect_raises NNTP::Error::NoSuchArticle, "Message Id: #{message_id}" do
                  client.body(message_id)
                end
              end
            end
          end
        end
      end
    end
  end
end
