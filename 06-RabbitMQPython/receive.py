#!/usr/bin/env python
import pika

#connection = pika.BlockingConnection(pika.ConnectionParameters(
#        host='localhost'))
connection = pika.BlockingConnection(pika.ConnectionParameters(
        host='sdi-1',
        credentials=pika.PlainCredentials(username="sdi", password="sdi")))
channel = connection.channel()


channel.queue_declare(queue='maphello')

def callback(ch, method, properties, body):
    print(" [x] Received %r" % body)

channel.basic_consume(callback,
                      queue='maphello',
                      no_ack=True)

print(' [*] Waiting for messages. To exit press CTRL+C')
channel.start_consuming()
