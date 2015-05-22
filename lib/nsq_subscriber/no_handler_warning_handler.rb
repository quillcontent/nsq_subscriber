# Default message handler. Warns "No handler registered for message type ..."
class NoHandlerWarningHandler

  def initialize(message_hash, opts={})
    @message = message_hash
    @logger  = opts.fetch(:logger) { Logger.new(STDOUT) }
  end

  def call
    message_type = @message["meta"]["event"]
    @logger.warn("No handler registered for message type '#{message_type}'")
  end

end
