Gem::Specification.new do |s|
  s.name        = 'json-project'
  s.version     = '0.1.0'
  s.date        = '2016-08-21'
  s.summary     = "JSON structure preserving transform"
  s.description = "Iteratively parse a stream of JSON data and project it into a smaller version which can be held in memory"
  s.authors     = ["Keith Duncan"]
  s.email       = 'keith.duncan@github.com'
  s.files       = [
    "lib/json-project.rb",
    "lib/json-project/scanner.rb",
  ]
  s.homepage    = 'https://github.com/keithduncan/json-project'
  s.license     = 'MIT'
end
