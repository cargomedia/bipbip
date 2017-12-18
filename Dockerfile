FROM library/ruby

RUN apt-get update && apt-get install -y g++ libsasl2-dev libmysqlclient-dev libxslt1-dev libxml2-dev
RUN gem install bundle

COPY Gemfile bipbip.gemspec /opt/bipbip/
COPY lib/bipbip/version.rb /opt/bipbip/lib/bipbip/version.rb

WORKDIR /opt/bipbip
RUN bundle install
COPY . /opt/bipbip

ENTRYPOINT /opt/bipbip/bin/bipbip
CMD  -c /etc/bipbip.yml