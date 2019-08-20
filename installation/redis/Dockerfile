FROM bitnami/redis:latest

#Stop Redis 
#CP 
#Start 
#RUN sed -i 's/appendonly yes/appendonly no/g' /opt/bitnami/redis/etc/redis.conf
#RUN redis-server /opt/bitnami/redis/etc/redis.conf
COPY dump.rdb /bitnami/redis/data/
#RUN sed -i 's/appendonly no/appendonly yes/g' /opt/bitnami/redis/etc/redis.conf
#RUN redis-server /opt/bitnami/redis/etc/redis.conf
#RUN chown redis:redis /var/lib/redis/dump.rdb

