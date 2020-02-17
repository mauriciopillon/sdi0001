package hello;

import javax.xml.ws.Endpoint;

public class HelloWorldServerPublisher {

	public static void main(String[] args) {

		System.out.println("Beginning to publish HelloWorldService now");
		Endpoint.publish("http://127.0.0.1:9876/WSHello", new HelloWorldServerImpl());
		System.out.println("Done publishing");
	}

}
