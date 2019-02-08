# json-projection

Project a filtering transform over a JSON stream to avoid loading large quantities
of data into memory.

There are two parts to gem, `JsonProjection::Parser` which is initialised with a
stream containing JSON data. Callers then request a stream of events to build up
an object model or discard. This is akin to a Streaming XML Parser or SAX.
The parser is based on the state machine in [dgraham/json-stream/lib/json/stream/parser.rb](https://github.com/dgraham/json-stream/blob/master/lib/json/stream/parser.rb)
modified to support pulling events instead of having them pushed as the data is
piped in.

The second part, `JsonProjection::Projector`, is also initialised with a stream
containing JSON data. Internally it constructs a parser to pull events from.
Given a schema of data you are interested in `Projector` will pull events and
construct the document subtrees for the portions of the document you are interested
in, ignore the subtrees you aren't interested in.

For improved performance and lower memory requirements this algorithm is now built-in
to [brianmario/yajl-ruby](https://github.com/brianmario/yajl-ruby/pull/171) as `Yajl::Projector`.

## Examples

Given the following JSON data, imagine it continuing with many more keys you
don't need:

```json
[
  {
    "user": {
      "name": "keith",
      "age": 26,
      "jobs": [
        {
          "title": "director of overworking",
          "company": "south coast software",
          "department": "most"
        },
        {
          "title": "some kind of computering",
          "company": "github the website dot com",
          "department": true
        }
      ]
    },
    "another key": {

    },
    "woah this document is huge": {

    },
    "many megabytes": {

    },
    "etc": {

    }
  }
]
```

We only need the `user` key, and really just the the `user`'s `name` key and
each `jobs`'s `title` key. We could implementing a schema-specific streaming
event handler for this data to ignore the keys we don't want and generate an
object model for the ones we do. That's a pain to build and maintain, what we
really want is a projection over the data just like we do when
`SELECT list, of, keys FROM table`.

```ruby
stream = File.open("somewhere.json", "r")

projector = JsonProjection::Projector.new(stream)

schema = {
  "user" => {
    "name" => nil,
    "jobs" => {
      "title" => nil,
    },
  },
}
data = projector.project(schema)

# data = [
# {
#   "user" => {
#     "name" => "keith",
#     "jobs" => [
#       { "title" => "director of overworking" },
#       { "title" => "some kind of computering" },
#     ]
#   }
# }
# ]
#
# use data...
```
