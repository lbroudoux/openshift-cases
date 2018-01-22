package com.github.lbroudoux.beer;

/**
 * @author laurent
 */
public class Beer {

   private String name;
   private String country;
   private String type;
   private Float rating;
   private String status;


   public Beer(){

   }

   public Beer(String name, String country, String type, Float rating, String status) {
      this.name = name;
      this.country = country;
      this.type = type;
      this.rating = rating;
      this.status = status;
   }

   public String getName() {
      return name;
   }

   public void setName(String name) {
      this.name = name;
   }

   public String getCountry() {
      return country;
   }

   public void setCountry(String country) {
      this.country = country;
   }

   public String getType() {
      return type;
   }

   public void setType(String type) {
      this.type = type;
   }

   public Float getRating() {
      return rating;
   }

   public void setRating(Float rating) {
      this.rating = rating;
   }

   public String getStatus() {
      return status;
   }

   public void setStatus(String status) {
      this.status = status;
   }
}
