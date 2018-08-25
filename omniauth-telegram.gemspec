lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "omniauth/telegram/version"

Gem::Specification.new do |spec|
  spec.name          = "omniauth-telegram"
  spec.version       = Omniauth::Telegram::VERSION
  spec.authors       = ["Yuri Mikhaylov"]
  spec.email         = ["me@yurijmi.ru"]

  spec.summary       = %q{An OmniAuth strategy for Telegram}
  spec.description   = %q{An OmniAuth strategy for Telegram}
  spec.homepage      = "https://github.com/yurijmi/omniauth-telegram"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "omniauth", "~> 1.0"

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
