
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "postal_transfers_pl/version"

Gem::Specification.new do |spec|
  spec.name          = 'postal_transfers_pl'
  spec.version       = PostalTransfersPl::VERSION
  spec.authors       = ['Filip Stybel', 'Michal Andros']
  spec.email         = ['filip.stybel@justcode.io', 'michalandros@gmail.com']

  spec.summary       = %q{Send mass postal orders using a csv via Polish Post Office API}
  spec.description   = %q{Send mass postal orders using a csv via Polish Post Office API, create and check for mass postal orders statuses via the API relay}
  spec.homepage      = 'https://github.com/justcodeio/postal_transfers_pl'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.11', '>= 1.11.2'
  spec.add_development_dependency 'rake', '~> 12.3', '>= 12.3.1'
  spec.add_development_dependency 'rspec', '~> 3.4'
  spec.add_development_dependency 'pry'
  spec.add_runtime_dependency 'savon', '~> 2.11', '>= 2.11.1'
end
