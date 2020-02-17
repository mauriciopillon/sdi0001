from zeep.client import Client

# RPC style soap service
client = Client('http://localhost:8000/?wsdl')
#client.service.slow_request('request-1')
print(client.service.sayHello())
