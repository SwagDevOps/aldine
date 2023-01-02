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

## Aliasing

Commands provided by the package can be aliased (to be more semantic), as the following __example__:

```latex
% aldine --------------------------------------------------------------
\DeclareCommandCopy\emptypage\aldineEmptyPage
\DeclareCommandCopy\markdown\aldineMarkdown
\DeclareCommandCopy\svgconv\aldineSvgConv
\DeclareCommandCopy\blason\aldineBlason
\DeclareCommandCopy\chapters\aldineChapters
\DeclareCommandCopy\hyperrefSetup\aldineHyperrefSetup
\DeclareCommandCopy\imageFull\aldineImageFull
```

## Developper

### Environment

```dotenv
# file: .env.local

ALDINE__DIRECTORIES__LIB=tex
ALDINE__DIRECTORIES__RUBY=lib
```

Dotenv above changes ``lib`` to ``tex`` for tex packages,
and add ruby ``lib`` directory to mounted directories.
It assumes working from the current sources directory.

### Replacement ``Rakefile`` in ``src`` and ``tmp`` directory

```ruby
# frozen_string_literal: true                                                                 

require 'bundler/setup'
require '/workdir/lib/aldine'
require 'aldine/remote/tasks'
```

<!-- hypelinks -->

[bkeepers/dotenv]: https://github.com/bkeepers/dotenv
[fastruby/dotenv_validator]: https://github.com/fastruby/dotenv_validator
