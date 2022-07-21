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
require 'rqb/local/tasks'
```

### ``./src/Rakefile``

```ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'rqb/remote/tasks'
```
