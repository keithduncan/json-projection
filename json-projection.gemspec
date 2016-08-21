Gem::Specification.new do |s|
  s.name        = 'json-projection'
  s.version     = '0.1.3'
  s.date        = '2016-08-21'
  s.summary     = "JSON structure preserving transform"
  s.description = "Iteratively parse a stream of JSON data and project it into a smaller version which can be held in memory"
  s.authors     = ["Keith Duncan"]
  s.email       = 'keith.duncan@github.com'
  s.files       = [
    "lib/json-projection/parser/buffer.rb",
    "lib/json-projection/parser/errors.rb",
    "lib/json-projection/parser/events.rb",
    "lib/json-projection/parser/fifo.rb",
    "lib/json-projection/parser.rb",
    "lib/json-projection/projector.rb",
    "lib/json-projection.rb",
  ]
  s.homepage    = 'https://github.com/keithduncan/json-projection'
  s.license     = 'MIT'
  s.required_ruby_version = '>= 2.0'

  s.add_development_dependency 'rake', '~> 11.2.2'
  s.add_development_dependency 'byebug', '~> 5.0.0'
  s.add_development_dependency 'minitest-focus', '~> 1.1.2'
  s.add_development_dependency 'minitest', '~> 5.9.0'
end
