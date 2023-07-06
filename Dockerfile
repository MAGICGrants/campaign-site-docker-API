FROM rstudio/plumber
LABEL author="Rucknium" \
      maintainer="Rucknium"

RUN apt update
RUN apt install libcurl4-openssl-dev
RUN R -e "install.packages(c('RCurl', 'RJSONIO'))"

COPY R/plumber.R /root/plumber.R

CMD ["/root/plumber.R"]
