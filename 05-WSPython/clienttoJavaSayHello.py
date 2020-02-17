from zeep.client import Client

# RPC style soap service
client = Client('http://localhost:9876/WSHello?wsdl')
print(client.service.sayHello('SDI/UDESC'))
