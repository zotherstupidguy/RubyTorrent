class BlockRequestProcess

  def initialize(queue)
    @queue = queue
  end
  
  def run!
    loop do
      request = @queue.pop
      connection = request[:connection]
      connection.write(compose_request(request))
    end
  end
  
  def compose_request(request)
      msg_length = "\0\0\0\x0d"
      id = "\6"
      piece_index = [request[:index]].pack("N")
      byte_offset = [request[:offset]].pack("N")
      request_length = "\0\0\x40\0"
      msg_length + id + piece_index + byte_offset + request_length
  end

end