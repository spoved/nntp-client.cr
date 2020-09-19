require "nntp-lib"

alias NNTP::Socket = Net::NNTP

require "./nntp-client/*"
require "./nntp/*"
