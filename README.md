# Convus Reviews [![CircleCI](https://dl.circleci.com/status-badge/img/gh/convus/convus_reviews/tree/main.svg?style=svg)](https://dl.circleci.com/status-badge/redirect/gh/convus/convus_reviews/tree/main)


## local working

Run these commands in the terminal, from the directory the project is in.

- Install the ruby gems with `bundle install`

- Install the node packages with `yarn install`

- Create and migrate the databases `bundle exec rake db:create db:migrate db:test:prepare`

- `./start` start the server.

  - [start](start) is a bash script. It starts redis in the background and runs foreman with the [dev procfile](Procfile_development)

- Go to [localhost:3009](http://localhost:3009)

| Toggle in development | command                      | default  |
| ---------             | -------                      | -------  |
| Caching               | `bin/rails dev:cache`        | disabled |
| [letter_opener](https://github.com/ryanb/letter_opener)     | `bin/rails dev:letter_opener` | enabled  |
| logging with lograge  | `bin/rails dev:lograge`       | enabled  |

