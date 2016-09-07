require "nsq"

require_relative "nsq_subscriber/no_handler_warning_handler"


# Listen for the NSQ queue, passing the messages to the right handler
class NsqSubscriber
  MAX_BACKOFF_MINS = 480

  def initialize(args)
    @lookupd = args.fetch(:lookupd)
    @topic   = args.fetch(:topic)
    @channel = args.fetch(:channel)
    # Maximum number of messages to allow in flight (concurrency knob)
    @max_in_flight = args.fetch(:max_in_flight, 25)
    # Maximum number of times this consumer will attempt to process a message before giving up
    @max_attempts = args.fetch(:max_attempts, 15)
    @max_backoff = args.fetch(:max_backoff, MAX_BACKOFF_MINS)

    @logger = args.fetch(:logger) { Logger.new(STDOUT) }
    @sleep_secs = args.fetch(:sleep_secs, 1)
    @handler_options = args.fetch(:handler_options, {})

    @handlers = Hash.new(NoHandlerWarningHandler)
  end

  def []=(message_type, handler)
    @handlers[message_type] = handler
  end

  def listen
    while true do
      read_messages
      sleep(@sleep_secs)
    end
  end

  protected

    def read_messages
      message = subscriber.pop
      @logger.info("NSQ message received = #{message.body}")
      process_message(message.body)
      message.finish
    rescue Exception => e
      backtrace = e.backtrace.join("\n")
      @logger.error("Error while processing message: #{e}")
      @logger.error("Backtrace: #{backtrace}")

      if message.attempts > @max_attempts
        @logger.warn("msg attempted #{message.attempts} times, giving up")
        message.finish
      else
        @logger.debug("Retrying in #{backoff_msecs(message.attempts)}ms")
        message.requeue(backoff_msecs(message.attempts))
      end
    end

    def subscriber
      @subscriber ||= begin
        ::Nsq.logger = @logger
        ::Nsq::Consumer.new(
          nsqlookupd: @lookupd,
          topic: @topic,
          channel: @channel,
          max_in_flight: @max_in_flight,
        )
      end
    end

    def process_message(message)
      json_message = JSON.parse(message)
      message_type = json_message["meta"]["event"]
      handler_options = {logger: @logger}.merge(@handler_options)
      handler = @handlers[message_type].new(json_message, handler_options)
      handler.call
    end

    def backoff_msecs(attempts)
      minutes = [2**attempts, @max_backoff].min
      mseconds = (minutes * 60 * 1000).to_i
    end

end
