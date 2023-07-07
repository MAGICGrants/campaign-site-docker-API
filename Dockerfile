FROM rstudio/plumber
LABEL author="Rucknium" \
      maintainer="Rucknium"

RUN apt update && apt install -y libcurl4-openssl-dev cron
RUN R -e "install.packages(c('RCurl', 'RJSONIO', 'cronR'))"

COPY R/plumber.R /root/plumber.R
COPY R/cache-fundingrequired.R /root/cache-fundingrequired.R
COPY R/fundingrequiredJSON.rds /root/fundingrequiredJSON.rds

ENTRYPOINT cron start && R -e "plumber::pr_run(plumber::plumb('plumber.R', '/root'), host = '0.0.0.0', port = 8000)"
