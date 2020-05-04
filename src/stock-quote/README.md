The stock-quote microservice gets the price of a specified stock.

### Build stock-quote service
Here are the steps to recompile and rebuild stock-quote image:
```
# cd stocktrader-jil/src/stock-quote/
# mvn package
# docker build -t stock-quote:latest -t stocktraders/stock-quote:latest .
# docker tag stock-quote:latest stocktraders/stock-quote:latest
# docker push stocktraders/stock-quote:latest
```