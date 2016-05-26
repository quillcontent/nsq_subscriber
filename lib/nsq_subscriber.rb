require "krakow"

require_relative "nsq_subscriber/no_handler_warning_handler"


# Listen for the NSQ queue, passing the messages to the right handler
class NsqSubscriber

  def initialize(args)
    @lookupd = args.fetch(:lookupd)
    @topic   = args.fetch(:topic)
    @channel = args.fetch(:channel)
    # Maximum number of messages to allow in flight (concurrency knob)
    @max_in_flight = args.fetch(:max_in_flight, 25)
    # Maximum number of times this consumer will attempt to process a message before giving up
    @max_attempts = args.fetch(:max_attempts, 15)
    @backoff_interval = args.fetch(:backoff_interval, 120)

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
      return if subscriber.queue.size.nil?
      subscriber.queue.size.times do
        begin
          message = subscriber.queue.pop
          @logger.info("NSQ message received = #{message.message}")

          if message.attempts > @max_attempts
            @logger.info("msg #{message.message_id} attempted #{message.attempts} times, giving up")
          else
            process_message(message)
          end
          subscriber.confirm(message.message_id)
        rescue Exception => e
          backtrace = e.backtrace.join("\n")
          @logger.error("Error while processing message: #{e}")
          @logger.error("Backtrace: #{backtrace}")
          subscriber.requeue(message.message_id)
        end
      end
    end

    def subscriber
      @subscriber ||= begin
        Krakow::Utils::Logging.level = :warn
        Krakow::Consumer.new(
          nsqlookupd: @lookupd,
          topic: @topic,
          channel: @channel,
          max_in_flight: @max_in_flight,
          backoff_interval: @backoff_interval,
        )
      end
    end

    def process_message(message)
      json_message = JSON.parse(message.message)
      message_type = json_message["meta"]["event"]
      handler_options = {logger: @logger}.merge(@handler_options)
      handler = @handlers[message_type].new(json_message, handler_options)
      handler.call
    end

end
