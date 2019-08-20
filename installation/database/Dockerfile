FROM ibmcom/db2

RUN mkdir /var/custom
COPY stocktrader.tar.gz /var/custom/stocktrader.tar.gz
COPY db2.sh /var/custom
RUN chmod a+x /var/custom/db2.sh
