# Wink CLI

## Features

* Detects 401s and automatically refreshes access tokens
* Stores config in .winkrc file
* Friendlier syntax than curl (but not as powerful)
* Works for both staging and production

## Installation

```bash
# Clone repo
git clone git@github.com:allspiritseve/wink-cli.git

# cd into directory
cd wink-cli

# Install gems
bundle install

# Create /usr/local/bin/wink (optional)
make
```

## Running commands

```bash
# Locally
bundle exec wink.rb COMMAND [<options>]

# Using global `wink` executable
wink COMMAND [<options>]
```

## Command Reference

```bash
# Set configuration values
wink configure

# View configuration values
wink config

# Log in with your browser
wink authorize

# obtain Wink credentials
wink authorize

# view Wink credentials
wink credentials

# retrieve your user
wink me

# retrieve your user (manual form)
wink get /users/me

# update your name
wink PUT /users/me first_name=Joe last_name=User
```

## Tips

I recommend installing `jq` with Homebrew for formatting / parsing JSON:

```
brew install jq
ruby wink.rb me | tail -n 1 | jq '.'
```
