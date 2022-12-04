## Install

```shell
bundle config set --local clean 'true'
bundle config set --local path 'vendor/bundle'
bundle install --standalone
```

## Rakefile

### ``./Rakefile``

```ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'aldine/local/tasks'
```

## Environment 

The following files are loaded as [``dotenv``][bkeepers/dotenv] files:

* ``.env.local``
* ``.env``

The file ``.env.sample`` is used to perform [environment validation][fastruby/dotenv_validator].

See also:
* [Dotenv][bkeepers/dotenv]
* [Dotenv Validator][fastruby/dotenv_validator]

## Developper

### Replacement ``Rakefile`` in ``tmp`` directory

```ruby
# frozen_string_literal: true                                                                 

require 'bundler/setup'
require '/workdir/lib/aldine'
require 'aldine/remote/tasks'
```

<!-- hypelinks -->

[bkeepers/dotenv]: https://github.com/bkeepers/dotenv
[fastruby/dotenv_validator]: https://github.com/fastruby/dotenv_validator
