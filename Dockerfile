FROM ruby:3

RUN bundle config --global frozen 1

WORKDIR /usr/src/app

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

CMD ["jekyll", "serve","--host", "0.0.0.0"]
