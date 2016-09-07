# Changelog

Please include notes on all updates and changes here.

# 0.1.0

* Using nsq-ruby gem to subscribe to nsq instead of Krakow
* Adds `max_backoff` config which determines the max time (in minutes) to backoff on message failure. Default is 8h. An exponential backoff strategy is used.
* Removed `backoff_interval` config

# 0.0.5

* Messages are re-queued/re-tried on exception
* Adds `max_attempts` config which determines the number of times a message
  will be re-queue on fail. Default is 15
* Adds `backoff_interval` config is used to calculate for how long the consumer
  will backoff when failures occur (failures * backoff_interval seconds).
  Default is 120 seconds

# 0.0.4

**Custom Krakow build** while we await a fix/alternative for [this PR](https://github.com/chrisroberts/krakow/pull/36).

Adds a `max_in_flight` configuration option to specificy how many messages to take form the queue. Otherwise we read one message, then wait 1 second, this can quickly get delayed when the team is all testing at once.

# 0.0.3

Read NSQ messages less frequently.

# 0.0.2

Ability to pass a custom `Hash` to the handlers, e.g. to pass OAuth provider URL
or any other configuration required by handlers.
