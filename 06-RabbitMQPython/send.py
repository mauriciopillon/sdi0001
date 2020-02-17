#!/usr/bin/env python
import pika

#connection = pika.BlockingConnection(pika.ConnectionParameters(
#        host='localhost'))

connection = pika.BlockingConnection(pika.ConnectionParameters(
        host='sdi-1',
        credentials=pika.PlainCredentials(username="sdi", password="sdi")))
channel = connection.channel()


channel.queue_declare(queue='maphello')

channel.basic_publish(exchange='',
                      routing_key='maphello',
                      body='Hello World!')
print(" [x] Sent 'Hello World!'")
connection.close()
