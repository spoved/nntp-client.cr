require "../../spec_helper"

describe NNTP::Client do
  describe "with existing newsgroup" do
    group = "alt.binaries.cbt"
    describe "#group_info" do
      it "fetches and parses info" do
        info = with_client &.group_info(group)
        info[:name].should eq group
      end
    end

    describe "#with_group" do
      it "changes current context" do
        with_client do |client|
          client.context.group.should be_nil
          client.with_group group do
            client.context.group.should_not be_nil
            client.context.group.not_nil![:name].should eq group
          end
        end
      end
    end
  end

  describe "with missing newsgroup" do
    group = "made.up.group"
    describe "#group_info" do
      it "raises error" do
        expect_raises NNTP::Client::Error::NoSuchGroup, group do
          with_client &.group_info(group)
        end
      end
    end

    describe "#with_group" do
      it "raises error" do
        expect_raises NNTP::Client::Error::NoSuchGroup, group do
          with_client do |client|
            client.context.group.should be_nil
            client.with_group group do
              client.context.group.should_not be_nil
              client.context.group.not_nil![:name].should eq group
            end
          end
        end
      end
    end
  end
end
