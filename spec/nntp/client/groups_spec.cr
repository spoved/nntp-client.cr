require "../../spec_helper"

describe NNTP::Client do
  describe "newsgroup" do
    describe "#group_info" do
      it "fetches and parses info" do
        info = with_client &.group_info("alt.binaries.cbt")
        info[:name].should eq "alt.binaries.cbt"
      end

      it "raises error when group is missing" do
        expect_raises NNTP::Client::Error::NoSuchGroup, "made.up.group" do
          with_client &.group_info("made.up.group")
        end
      end
    end

    describe "#with_group" do
      it "changes current context" do
        with_client do |client|
          client.current_context.group.should be_nil
          client.with_group "alt.binaries.cbt" do
            client.current_context.group.should_not be_nil
            client.current_context.group.not_nil![:name].should eq "alt.binaries.cbt"
          end
        end
      end
    end
  end
end
