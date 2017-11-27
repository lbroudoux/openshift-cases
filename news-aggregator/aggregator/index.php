<!doctype html>
<html>
  <head>
    <meta charset="utf-8">
  	<title>Aggregator Demo</title>

    <link rel="stylesheet" href="css/bootstrap.css">
    <link rel="stylesheet" href="css/main.css">
  </head>
  <body>
    <nav class="navbar navbar-default">
      <div class="container-fluid">
        <div class="navbar-header">
          <button type="button" class="navbar-toggle collapsed" data-toggle="collapse" data-target="#navbar-menu">
            <span class="sr-only">Toggle navigation</span>
            <span class="icon-bar"></span>
            <span class="icon-bar"></span>
            <span class="icon-bar"></span>
          </button>
          <a class="navbar-brand" href="#">
            <h1 class="logo">
              <img alt="Brand" src="images/aggregator.png" height="42" width="42"/>
            </h1>
          </a>
        </div>
        <div class="collapse navbar-collapse" id="bs-example-navbar-collapse-1">
          <ul class="nav navbar-nav" style="padding-left: 50px">
            <li><h3 style="width: 350px">Aggregator Demo</h3></li>
          </ul>
          <div class="navbar-form navbar-right" role="search" style="padding-top: 5px">
            <div class="form-group">
              <input id="greeting_url" type="text" class="form-control" placeholder="http://hello-news-demo.cloudapps.example.com">
              / <input id="articles_url" type="text" class="form-control" placeholder="http://articles-news-demo.cloudapps.example.com">
            </div>
          </div>
        </div>
      </div>
    </nav>
    <div class="container-fluid">
      <div class="jumbotron">
        <h2>News Aggregator on Openshift !</h2>
    	  <p>This demo is to demonstrate how OpenShift can help deploying your publication microservices architecture</p>
    	</div>
      <div class="row">
        <div class="col-md-8">
          <div class="panel panel-default">
            <div class="panel-heading">
              <h2 class="panel-title"><span class="glyphicon glyphicon-send" aria-hidden="true"></span> Articles</h2>
            </div>
            <div class="panel-body" id="article">
            </div>
          </div>
        </div>
        <div class="col-md-4">
          <div class="panel panel-default">
            <div class="panel-heading">
              <h2 class="panel-title"><span class="glyphicon glyphicon-comment" aria-hidden="true"></span> Salutation</h2>
            </div>
            <div class="panel-body" id="greeting">
            </div>
          </div>
          <div class="panel panel-default">
            <div class="panel-heading">
              <h2 class="panel-title"><span class="glyphicon glyphicon-comment" aria-hidden="true"></span> Personnalisation</h2>
            </div>
            <div class="panel-body">
              <div class="form-horizontal">
                <div class="form-group">
                  <label for="firstname" class="col-lg-2 control-label">Votre Prénom</label>
                  <div class="col-lg-10">
                    <input type="text" class="form-control" id="firstname" name="firstname" placeholder="Prénom">
                  </div>
                </div>
                <div class="form-group">
                  <div class="col-lg-10 col-lg-offset-2">
                    <button type="reset" class="btn btn-default">Cancel</button>
                    <button type="button" class="btn btn-primary" id="registerButton">Go</button>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    <script src="js/jquery.js"></script>
    <script src="js/bootstrap.min.js"></script>
    <script>
    var GREETING_URL = "http://hello-news-demo.cloudapps.example.com";
    var ARTICLES_URL = "http://articles-news-demo.cloudapps.example.com";
    var FIRSTNAME = "Laurent";

    $("#greeting_url").blur(function(){
      var value = $("#greeting_url").val();
      if (value === null || value === "") {
        $("#greeting_url").val(GREETING_URL);
      } else {
        GREETING_URL = value;
      }
    });
    $("#articles_url").blur(function(){
      var value = $("#articles_url").val();
      if (value === null || value === "") {
        $("#articles_url").val(ARTICLES_URL);
      } else {
        ARTICLES_URL = value;
      }
    });

    $("#registerButton").click(function(){
      FIRSTNAME = $('input[name=firstname]').val();
      retrieveGreeting();
    });

    $(document).ready(function() {
      retrieveGreeting();
      retrieveArticle();
    });

    function retrieveGreeting() {
      $.get(GREETING_URL+"/api/hello?name=" + FIRSTNAME, function( data ) {
          console.log('In handler !');
          if (data != null) {
            $('#greeting').html(data.content + ' - <span class="badge">' + data.id + '</span>');
          }
      })
      .fail(function(data) {
        console.log('In fail ! - ' + JSON.stringify(data));
      });
    };

    function retrieveArticle() {
      $.get(ARTICLES_URL+"/article.php", function( data ) {
          console.log('In handler !');
          if (data != null) {
            $('#article').html(data);
            $('#article img').each(function(){ this.src = ARTICLES_URL + '/' + this.src.substr(this.src.indexOf('images/')) });
          }
      })
      .fail(function(data) {
        console.log('In fail ! - ' + JSON.stringify(data));
      });
    };
    </script>
  </body>
</html>
