# JTwit application

This is a twitter inspired web application

## Changelog

1.0 - initial commit

## Getting started

To get started with the app, clone the repo and then install the needed gems:

```
$ bundle install --without production
```

Next, migrate the database:

```
$ rails db:migrate
```

Finally, run the test suite to verify that everything is working correctly:

```
$ rails test
```

If the test suite passes, you'll be ready to run the app in a local server:

```
$ rails server
```

To upload to heroku simply fork the repo to github, and connect it to heroku.

make sure you precompile css assets with

```
bundle exec rake assets:precompile
```

and make sure you create the db in heroku

```
heroku run rake db:migrate
```