require 'net/http'
require 'digest/sha1'
require 'thread'
require 'ipaddr'
require 'socket'
require 'timeout'
require 'pp'

require_relative 'ruby-bencode/lib/bencode.rb'
require_relative 'client'
require_relative 'block'
require_relative 'file_wrapper'
require_relative 'meta_info'
require_relative 'download_controller'
require_relative 'file_writer_process'
require_relative 'block_request_process'
require_relative 'incoming_message_process'
require_relative 'tracker'
require_relative 'peer'
require_relative 'bitfield'
require_relative 'message'
require_relative 'piece'

Client.new(ARGV.first)