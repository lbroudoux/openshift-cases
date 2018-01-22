package com.github.lbroudoux.beer;

import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * @author laurent
 */
@RestController
@RequestMapping("/api")
public class BeerCatalogController {

   @CrossOrigin
   @RequestMapping(method = RequestMethod.GET, value = "/beer")
   public List<Beer> getBeers(
         @RequestParam(value = "page", required = false, defaultValue = "0") int page) {
      return BeerRepository.getBeers();
   }

   @CrossOrigin
   @RequestMapping(method = RequestMethod.GET, value = "/beer/{name}")
   public Beer getBeer(
         @PathVariable("name") String name) {
      return BeerRepository.findByName(name);
   }

   @CrossOrigin
   @RequestMapping(method = RequestMethod.GET, value = "/beer/findByStatus/{status}")
   public List<Beer> getByStatus(
         @PathVariable("status") String status) {
      return BeerRepository.findByStatus(status);
   }
}
