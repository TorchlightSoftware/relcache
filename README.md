# relcache

A cache for relationships so you don't have to round trip to the DB in order to look them up.  A simpler implementation and interface than an all out graph database.

Relationships will be stored bi-directionally, and can be searched with a query interface based on MongoDB.

## Usage

Use 'set' to create many-1 relationships.  For instance, between user._id and user.name:

```coffee-script
relcache.set "user._id", 5, {name: 'Fred', email: 'fred@foo.com'}

relcache.get "user._id", 5                  # {name: 'Fred', email: 'fred@foo.com'}
relcache.get "user.name", 'Fred'            # {user._id: [5]}
relcache.get "user.email", 'fred@foo.com'   # {user._id: [5]}
```

The reverse relationships will always store and be returned as arrays.  Say you have two users with the same name:

```coffee-script
relcache.set "user._id", 5, {name: 'Fred'}
relcache.set "user._id", 7, {name: 'Fred'}

relcache.get "user.name", 'Fred' # {user._id: [5, 7]}
```

## LICENSE

(MIT License)

Copyright (c) 2013 Torchlight Software <info@torchlightsoftware.com>

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
