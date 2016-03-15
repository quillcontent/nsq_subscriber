require "krakow"

require_relative "nsq_subscriber/no_handler_warning_handler"


# Listen for the NSQ queue, passing the messages to the right handler
class NsqSubscriber

  DEFAULT_SLEEP_SECS = 30
  MAX_EMPTY_QUEUE_ATTEMPTS = 10

  def initialize(args)
    @lookupd = args.fetch(:lookupd)
    @topic   = args.fetch(:topic)
    @channel = args.fetch(:channel)
    @max_in_flight = args.fetch(:max_in_flight, 25)
    @logger = args.fetch(:logger) { Logger.new(STDOUT) }
    @sleep_secs = args.fetch(:sleep_secs, DEFAULT_SLEEP_SECS)
    @handler_options = args.fetch(:handler_options, {})

    @handlers = Hash.new(NoHandlerWarningHandler)

    Krakow::Utils::Logging.level = :warn
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
      return if queue_empty?
      subscriber.queue.size.times do
        begin
          message = subscriber.queue.pop
          @logger.info("NSQ message received = #{message.message}")

          process_message(message)
        rescue Exception => e
          backtrace = e.backtrace.join("\n")
          @logger.error("Error while processing message: #{e}")
          @logger.error("Backtrace: #{backtrace}")
        ensure
          subscriber.confirm(message.message_id)
        end
      end
    end

    def queue_empty?
      if subscriber.queue.size.to_i == 0
        increase_empty_queue_count!
        new_subscriber! if empty_queue_count > MAX_EMPTY_QUEUE_ATTEMPTS
        true
      else
        false
      end
    end

    def subscriber
      @subscriber ||= new_subscriber!
    end

    def new_subscriber!
      @subscriber.terminate if @subscriber
      @logger.debug("Old NSQ/Krakow consumer terminated - New one instantiated")
      reset_empty_queue_count!
      @subscriber = Krakow::Consumer.new(
        nsqlookupd: @lookupd,
        topic: @topic,
        channel: @channel,
        max_in_flight: @max_in_flight
      )
    end

    def empty_queue_count
      @empty_queue_count.to_i
    end

    def reset_empty_queue_count!
      @empty_queue_count = 0
    end

    def increase_empty_queue_count!
      @empty_queue_count = @empty_queue_count.to_i + 1
    end

    def process_message(message)
      json_message = JSON.parse(message.message)
      message_type = json_message["meta"]["event"]
      handler_options = {logger: @logger}.merge(@handler_options)
      handler = @handlers[message_type].new(json_message, handler_options)
      handler.call
    end

end
