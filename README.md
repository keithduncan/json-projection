# json-projection
Project a filtering transform over a JSON stream to avoid loading large quantities of data into memory.

`JsonProjection::Parser` is initialised with a stream containing JSON data.
Callers then request a stream of events to build up an object model or discard.

The parser is based on the state machine in
https://github.com/dgraham/json-stream/blob/master/lib/json/stream/parser.rb
modified to support pulling events instead of having them pushed as the data is
piped in.

`JsonProjection::Projector` is also initialised with a stream containing JSON
data. Internally it constructs a parser to pull events from. Given a schema of
data you are interested in `Projector` will pull events and ignore the subtrees
you don't need, constructing the subtrees only for those portions of the
document you are interested in.
