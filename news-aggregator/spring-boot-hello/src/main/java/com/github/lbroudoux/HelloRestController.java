package com.github.lbroudoux;

import java.util.concurrent.atomic.AtomicLong;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * @author lbroudoux
 */
@RestController
@RequestMapping("/api")
public class HelloRestController {

  private static final String template = "Hello, %s!";
  private final AtomicLong counter = new AtomicLong();

  @CrossOrigin
  @RequestMapping(method = RequestMethod.GET, value = "/hello")
  public Greeting hello(@RequestParam(value="name", defaultValue="World") String name) {
    return new Greeting(counter.incrementAndGet(),
                            String.format(template, name));
  }
}
