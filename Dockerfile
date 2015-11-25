FROM jackiig/html-mason

ENV PERL5LIB /usr/local/lib/perl/5.18.2/:/usr/local/share/perl/5.18.2/:/usr/lib/perl5

WORKDIR /usr/src/app/
ADD ./ /usr/src/app/

RUN mv mason-app.conf /etc/apache2/sites-enabled/000-default.conf

## What port do we expose to the world?
EXPOSE 80
CMD ["/usr/sbin/apache2", "-D", "FOREGROUND"]
