FROM rstudio/plumber
LABEL author="Rucknium" \
      maintainer="Rucknium"

RUN apt update && apt install -y libcurl4-openssl-dev cron
RUN R -e "install.packages(c('RCurl', 'RJSONIO', 'cronR'))"

COPY R/plumber.R /root/plumber.R
COPY R/cache-fundingrequired.R /root/cache-fundingrequired.R
COPY R/fundingrequiredJSON.rds /root/fundingrequiredJSON.rds

CMD ["/root/plumber.R"]
