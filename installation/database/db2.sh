cd /var/custom/
tar -xvf stocktrader.tar.gz
su - db2inst1
cd /var/custom/stocktrader
db2move STOCKTRD import
