require "spec_helper"
require "nsq"

LOOKUPD = "http://127.0.0.1:4161"
NSQD = "127.0.0.1:4150"
TOPIC = "test_topic"
CHANNEL = "tests"
MSG_TYPE = "msg_type"

class TestHandler
  def initialize(json_message, opts)
    @message = json_message
    @logger = opts.fetch(:logger)
  end

  def call
    @logger.info "TestHandler#call"
  end
end

describe NsqSubscriber do

  let(:subscriber) do
    described_class.new(lookupd: LOOKUPD, topic: TOPIC, channel: CHANNEL)
  end

  let(:message) do
    {
      "meta": {
        "event": MSG_TYPE
      }
    }
  end

  let(:publish_msg) do
    begin
      Nsq::Producer.new(nsqd: NSQD, topic: TOPIC).write(message.to_json)
    rescue Errno::ECONNREFUSED => e
      throw "Failed to publish NSQ message. Is nsqd running on #{NSQD}? #{e.message}"
    end
  end

  before do
    publish_msg
    subscriber[MSG_TYPE] = TestHandler
  end

  it "calls #call on the handler" do
    expect_any_instance_of(TestHandler).to receive(:call)

    thread = Thread.new { subscriber.listen }
    sleep(4)
  end

end
