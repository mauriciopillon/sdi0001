
/** HelloServer.java **/

import java.rmi.*;
import java.rmi.server.*;
import java.rmi.registry.*;

public class HelloServer implements HelloWorld {
   public HelloServer() {}
   // main()
   // hello()

   public static void main(String[] args) {
      try {
         // Instancia o objeto servidor e a sua stub
         HelloServer server = new HelloServer();
         HelloWorld stub = (HelloWorld) UnicastRemoteObject.exportObject(server, 0);
         // Registra a stub no RMI Registry para que ela seja obtAida pelos clientes
         Registry registry = LocateRegistry.createRegistry(6600);
         //Registry registry = LocateRegistry.getRegistry(9999);
         registry.bind("Hello", stub);
         System.out.println("Servidor pronto");
      } catch (Exception ex) {
         ex.printStackTrace();
      }
   }

public String hello() throws RemoteException {
   System.out.println("Executando hello()");
   return "Hello!!!";
}
}
