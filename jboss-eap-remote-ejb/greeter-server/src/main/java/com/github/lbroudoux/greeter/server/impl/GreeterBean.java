package com.github.lbroudoux.greeter.server.impl;

import javax.ejb.Remote;
import javax.ejb.Stateless;

import com.github.lbroudoux.greeter.server.Greeter;

@Stateless
@Remote (Greeter.class)
public class GreeterBean implements Greeter {

  @Override
  public String greet(String user) {
    return "Hello " + user + ", have a pleasant day!";
  }
}
