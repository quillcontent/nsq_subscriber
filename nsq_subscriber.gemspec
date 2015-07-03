# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'nsq_subscriber/version'

Gem::Specification.new do |spec|
  spec.name          = "nsq_subscriber"
  spec.version       = NsqSubscriber::VERSION
  spec.authors       = ["Aldo \"xoen\" Giambelluca"]
  spec.email         = ["aldo.giambelluca@gmail.com"]

  spec.summary       = %q{Build an NSQ subscriber easily}
  spec.description   = %q{Easily listen for NSQ messages and pass them to the releval handler}
  spec.homepage      = "https://github.com/quillcontent/nsq_subscriber"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # We're (xmjw) working on a PR to Krakow main that will fix the issue, until then, 
  # this is a patched version.
  spec.add_dependency "krakow", :git => 'git@github.com:xmjw/krakow.git'

  spec.add_development_dependency "bundler", "~> 1.9"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "byebug", "~> 4.0.5"
end
