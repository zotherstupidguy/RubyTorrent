class Client
    
  def initialize(path_to_file)
    @torrent = File.open(path_to_file)
    set_instance_variables
    set_peers
  end
  
  def set_instance_variables
    @message_queue = Queue.new
    @block_request_queue = Queue.new
    @incoming_block_queue = Queue.new
    @peers = []
    @meta_info = MetaInfo.new(BEncode::Parser.new(@torrent).parse!)
    @id = rand_id # make better later
    @tracker = Tracker.new(@meta_info.announce)
    @handshake = "\x13BitTorrent protocol\x00\x00\x00\x00\x00\x00\x00\x00#{@meta_info.info_hash}#{@id}"
  end
  
  def send_tracker_request
    @tracker.make_request(get_tracker_request_params)
  end
  
  def tracker_request_params
    { info_hash:    @meta_info.info_hash,          
      peer_id:      rand_id,
      port:         '6881',
      uploaded:     '0',
      downloaded:   '0',
      left:         '10000',
      compact:      '1',
      no_peer_id:   '0',
      event:        'started' }
  end
  
  def set_peers
    peers = @tracker.make_request(tracker_request_params)["peers"].scan(/.{6}/)
    peers.map! do |peer|
      peer.unpack('a4n')
    end
    peers.each do |ip_string, port|
      set_peer(ip_string, port)   
    end
  end
  
  def set_peer(ip_string, port)
    begin
      Timeout::timeout(1) { @peers << Peer.new(ip_string, port, @handshake) }
    rescue => exception
      puts exception
    end
  end

  def rand_id
    result = ""
    20.times { result << rand(9).to_s }
    result
  end

  def run!
    peer = @peers.last
    Thread::abort_on_exception = true # remove later?
    Thread.new { Message.parse_stream(peer, @message_queue) }
    Thread.new { IncomingMessageProcess.new(@message_queue, @incoming_block_queue).run! } 
    Thread.new { DownloadController.new(@meta_info, @block_request_queue, @incoming_block_queue, @peers).run! } 
    Thread.new { BlockRequestProcess.new(@block_request_queue).run! }
    Thread.new { keep_alive(peer) }
    Message.send_interested(peer) # change later
  end
  
  def join_threads
    Thread.list.each { |thread| thread.join unless current_thread?(thread) }
  end
  
  def keep_alive(peer)
    loop do
      peer.connection.write("\0\0\0\0")
      sleep(60)
    end
  end
  
  def current_thread?(thread)
    thread == Thread.current
  end
end
