# Convus

View it: **[Convus.org](https://www.convus.org/)**

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
| Caching               | `bundle exec rails dev:cache`| disabled |
| [letter_opener][]     | `bin/rake dev:letter_opener` | enabled  |
| logging with lograge  | `bin/rake dev:lograge`       | enabled  |

[letter_opener]: https://github.com/ryanb/letter_opener

