package hello;
 
import javax.jws.WebService;
 
@WebService(endpointInterface = "hello.HelloWorldServer")
public class HelloWorldServerImpl implements HelloWorldServer {
 
	public String sayHello(String name) {
		return "Hello " + name + " !, Hope you are doing well !!";
	}
 
}
