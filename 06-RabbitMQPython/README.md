# Python code for RabbitMQ tutorials

Here you can find Python code examples from [RabbitMQ
tutorials](http://www.rabbitmq.com/getstarted.html).

To successfully use the examples you will need a running RabbitMQ server.

## Requirements

To run this code you need to install the `pika` package version 0.10.0 or later. To install it, run

    pip install pika==0.11.0

You may first need to run

    easy_install pip


## Code

[Tutorial one: "Hello World!"](http://www.rabbitmq.com/tutorial-one-python.html):

    python3 send.py
    python3 receive.py

sudo rabbitmqctl add_user sdi sdi
sudo rabbitmqctl set_user sdi administrator
sudo rabbitmqctl set_user_tags sdi administrator
sudo rabbitmqctl set_permissions -p / sdi ".*" ".*" ".*"
