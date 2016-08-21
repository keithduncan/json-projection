Gem::Specification.new do |s|
  s.name        = 'json-projection'
  s.version     = '0.1.0'
  s.date        = '2016-08-21'
  s.summary     = "JSON structure preserving transform"
  s.description = "Iteratively parse a stream of JSON data and project it into a smaller version which can be held in memory"
  s.authors     = ["Keith Duncan"]
  s.email       = 'keith.duncan@github.com'
  s.files       = [
    "lib/json-projection.rb",
    "lib/json-projection/buffer.rb",
    "lib/json-projection/errors.rb",
    "lib/json-projection/events.rb",
    "lib/json-projection/fifo.rb",
    "lib/json-projection/parser.rb",
  ]
  s.homepage    = 'https://github.com/keithduncan/json-projection'
  s.license     = 'MIT'

  s.add_development_dependency 'byebug', '~> 5.0.0'
end
