#!/bin/bash

cd /var/custom/
tar -xvf stocktrader.tar.gz
cd /var/custom/stocktrader
db2move STOCKTRD import
