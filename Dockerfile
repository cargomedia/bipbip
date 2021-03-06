FROM library/ruby:2.5-stretch

RUN apt-get update && apt-get install -y g++ libsasl2-dev default-libmysqlclient-dev libxslt1-dev libxml2-dev libfcgi0ldbl
RUN gem install bundle

ADD https://git.io/vyCoJ /usr/local/bin/wait-for-it
RUN chmod a+x /usr/local/bin/wait-for-it

COPY Gemfile Gemfile.lock bipbip.gemspec /opt/bipbip/
COPY lib/bipbip/version.rb /opt/bipbip/lib/bipbip/version.rb


WORKDIR /opt/bipbip
RUN bundle install
COPY . /opt/bipbip

CMD /opt/bipbip/bin/bipbip -c /opt/bipbip/etc/config.yml
