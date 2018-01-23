package com.github.lbroudoux.greeter;

import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.PathParam;
import javax.ws.rs.Produces;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.SecurityContext;

import java.util.logging.Level;
import java.util.logging.Logger;
/**
 * A JAX-RS resource for exposing REST endpoints for Greeter manipulation
 */
@Path("greeter")
public class GreeterResource {

    private static Logger log = Logger.getLogger(GreeterResource.class.getName());

    @GET
  @Path("greet/{name}")
  @Produces({"application/json"})
  public String greet(@Context SecurityContext context, @PathParam("name") String name) {
    log.log(Level.INFO, "Getting new greet request for " + name);
    String response = "Hello " + name + "!";
    log.log(Level.INFO, "Found greeting result " + response);
    return "{\"response\":\"" + response + "\"}";
  }
}