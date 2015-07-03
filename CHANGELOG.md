# Changelog

Please include notes on all updates and changes here.

# 0.0.4

**Custom Krakow build** while we await a fix/alternative for [this PR](https://github.com/chrisroberts/krakow/pull/36).

Adds a `max_in_flight` configuration option to specificy how many messages to take form the queue. Otherwise we read one message, then wait 1 second, this can quickly get delayed when the team is all testing at once. 

# 0.0.3

Read NSQ messages less frequently.

# 0.0.2

Ability to pass a custom `Hash` to the handlers, e.g. to pass OAuth provider URL
or any other configuration required by handlers.
