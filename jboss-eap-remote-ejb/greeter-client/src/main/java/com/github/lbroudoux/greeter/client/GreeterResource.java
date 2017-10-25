package com.github.lbroudoux.greeter.client;

import javax.ejb.EJB;
import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.PathParam;
import javax.ws.rs.Produces;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.SecurityContext;
import java.util.Hashtable;
import java.util.logging.Level;
import java.util.logging.Logger;

import javax.annotation.Resource;
import javax.enterprise.context.ApplicationScoped;

import com.github.lbroudoux.greeter.server.Greeter;
/**
 * A JAX-RS resource for exposing REST endpoints for Greeter manipulation
 */
@ApplicationScoped
@Path("greeter")
public class GreeterResource {

  private static Logger log = Logger.getLogger(GreeterResource.class.getName());

  //@Produces @EJB(lookup="../greeter-server/GreeterBean!com.github.lbroudoux.greeter.server.Greeter")
  //@Produces @EJB(ejbLink="../greeter-server/GreeterBean!com.github.lbroudoux.greeter.server.Greeter")
  //@javax.enterprise.inject.Produces @Resource(lookup="app:/greeter-server#GreeterBean!com.github.lbroudoux.greeter.server.Greeter")
  private Greeter greeter;

  @GET
  @Path("greet/{name}")
  @Produces({"application/json"})
  public String greet(@Context SecurityContext context, @PathParam("name") String name) {
    log.log(Level.INFO, "Getting new greet request for " + name);
    String response = "default";

    try {
      // Try a simple JNDI lookup if no greeter has been injected.
      if (greeter == null) {
        Hashtable properties = new Hashtable();
        properties.put(javax.naming.Context.URL_PKG_PREFIXES, "org.jboss.ejb.client.naming");
        javax.naming.Context jndiContext = new javax.naming.InitialContext(properties);
        Object obj = jndiContext.lookup("ejb:/greeter-server//GreeterBean!com.github.lbroudoux.greeter.server.Greeter");
        log.log(Level.INFO, "Lookup object class: " + obj.getClass());
        greeter  = (Greeter)obj;
      }
      // Invoke remote Greeter EJB.
      response = greeter.greet(name);
    } catch (Throwable t) {
      // Put some diagnostic traces...
      log.log(Level.WARNING, "Error: " + t.getMessage());
      t.printStackTrace();
    }
    log.log(Level.INFO, "Found greeting result " + response);
    return "{\"response\":\"" + response + "\"}";
  }
}
