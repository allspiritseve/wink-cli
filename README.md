# Wink CLI

## Features

* Detects 401s and automatically refreshes access tokens
* Stores config in .winkrc file
* Works for both staging and production

## Example commands

```
# retrieve your user
ruby wink.rb me

# retrieve your user (manual form)
ruby wink.rb get /users/me

# update your name
ruby wink.rb PUT /users/me first_name=Joe last_name=User
```

## Tips

I recommend installing `jq` with Homebrew for formatting / parsing JSON:

```
brew install jq
ruby wink.rb me | tail -n 1 | jq '.'
```
