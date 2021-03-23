# Yasuri
[![Build Status](https://github.com/tac0x2a/yasuri/actions/workflows/ruby.yml/badge.svg)](https://github.com/tac0x2a/yasuri/actions/workflows/ruby.yml)
[![Coverage Status](https://coveralls.io/repos/tac0x2a/yasuri/badge.svg?branch=master)](https://coveralls.io/r/tac0x2a/yasuri?branch=master) [![Maintainability](https://api.codeclimate.com/v1/badges/c29480fea1305afe999f/maintainability)](https://codeclimate.com/github/tac0x2a/yasuri/maintainability)

Yasuri (鑢) is an easy web-scraping library for supporting "[Mechanize](https://github.com/sparklemotion/mechanize)".

Yasuri can reduce frequently processes in Scraping.

For example,

+ Open links in the page, scraping each page, and getting result as Hash.
+ Scraping texts in the page, and named result in Hash.
+ A table that repeatedly appears in a page each, scraping, get as an array.
+ Of each page provided by the pagination, scraping the only top 3.

You can implement easy by Yasuri.

## Sample

https://yasuri-sample.herokuapp.com/

(source code: https://github.com/tac0x2a/yasuri-sample)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'yasuri'
```

or

```ruby
# for Ruby 1.9.3 or lower
gem 'yasuri', '~> 2.0', '>= 2.0.13'

# for Ruby 3.0.0 or lower
gem 'yasuri', '~> 3.1'
```


And then execute:

    $ bundle

Or install it yourself as:

    $ gem install yasuri

## Usage

```ruby
# Node tree constructing by DSL
root = Yasuri.links_root '//*[@id="menu"]/ul/li/a' do
         text_title '//*[@id="contents"]/h2'
         text_content '//*[@id="contents"]/p[1]'
       end


# Node tree constructing by YAML
src = <<-EOYAML
links_root:
  path: "//*[@id='menu']/ul/li/a"
  text_title: "//*[@id='contents']/h2"
  text_content: "//*[@id='contents']/p[1]"
EOYAML
root = Yasuri.yaml2tree(src)


# Node tree constructing by JSON
src = <<-EOJSON
{
  "links_root": {
    "path": "//*[@id='menu']/ul/li/a",
    "text_title": "//*[@id='contents']/h2",
    "text_content": "//*[@id='contents']/p[1]"
  }
}
EOJSON
root = Yasuri.json2tree(src)


# Execution and getting scraped result
agent = Mechanize.new
root_page = agent.get("http://some.scraping.page.net/")

result = root.inject(agent, root_page)
# => [
#      {"title" => "PageTitle 01", "content" => "Page Contents  01" },
#      {"title" => "PageTitle 02", "content" => "Page Contents  02" },
#      ...
#      {"title" => "PageTitle N",  "content" => "Page Contents  N" }
#    ]
```

## Dev
```sh
$ gem install bundler
$ bundle install
```
### Test
```sh
$ rake
# or
$ rspec spec/*spec.rb
```

### Release RubyGems
```sh
# Only first time
$ curl -u <user_name> https://rubygems.org/api/v1/api_key.yaml > ~/.gem/credentials
$ chmod 0600 ~/.gem/credentials

$ nano lib/yasuri/version.rb # edit gem version
$ rake release
```

## Contributing

1. Fork it ( https://github.com/tac0x2a/yasuri/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
