# NsqSubscriber

Easily listen for NSQ messages and pass them to the relevant handler.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'nsq_subscriber'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install nsq_subscriber

## Usage

Define one or more handler classes:

```ruby
class ExampleHandler
  def initialize(json_message, opts)
    @message = json_message
    @logger  = opts.fetch(:logger) { Logger.new(STDOUT) }
  end

  def call
    @logger.info "TODO: Handle message: #{@message}"
  end
end
```

Then instanciate an `NsqSubscriber` specifying the NSQLookupd, topic and channel:

```ruby
subscriber = NsqSubscriber.new(
  lookupd: "http://127.0.0.1:4161",
  topic: "example_topic",
  channel: "test_app",
  handler_options: {"oauth_provider": "http://www.example.com"}
)
subscriber["test_this"] = ExampleHandler
subscriber.listen
```

This will listen to events about the "example_topic" topic and when one of them
is in the following format it will trigger `ExampleHandler#call`.

```ruby
{
  "meta": {
    "event": "test_this"
  },
  "data": {
    "meaning": 42
  }
}
```

The `:handler_options` key will be passed to the handler when a relevant message
will be received.

## Running the tests

To run the tests:

```bash
$ bundle exec rspec
```

NOTE: nsqd and nsqlookupd will need to be running locally. Follow the instructions on NSQ documentation: http://nsq.io/overview/quick_start.html

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/[my-github-username]/nsq_subscriber/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
