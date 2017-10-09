<?php if(session_status()!=PHP_SESSION_ACTIVE) session_start() ?>
<!DOCTYPE html>
<head>
<meta charset="utf-8">
<title>Odoo Key Portal - Powered by Magnus</title>
<meta name="description" content="Odoo Key Portal">
<meta name="author" content="Magnus Red">
<meta http-equiv="cache-control" content="max-age=0" />
<meta http-equiv="cache-control" content="no-cache" />
<meta http-equiv="expires" content="0" />
<meta http-equiv="expires" content="Tue, 01 Jan 1980 1:00:00 GMT" />
<meta http-equiv="pragma" content="no-cache" />
<meta name="viewport" content="width=device-width, initial-scale=1">
<link rel="stylesheet" type="text/css" href="style.css" />
<link href="social-button/css/social-buttons.css" rel="stylesheet" type="text/css"/>
<script type="text/javascript" src="http://code.jquery.com/jquery-latest.min.js"></script>
<script src="http://www.modernizr.com/downloads/modernizr-latest.js"></script>
<script type="text/javascript" src="placeholder.js"></script>
</head>
<body>
<?php
include 'gpConfig.php';

if (isset($_SESSION['g_token'])) {
	$gClient->setAccessToken($_SESSION['g_token']);
  session_destroy();
    session_unset();
}

if ($gClient->getAccessToken()) {
	//auth with google
	//Get user profile data from google

	$gpUserProfile = $google_oauthV2->userinfo->get();
	$username=$gpUserProfile['email'];
	validate_domain($username,$vdomain);
}

?>
	<div class="form-container">
    <form id="slick-login" action="#" method="POST">
<?php
    $authUrl = $gClient->createAuthUrl();
	echo  '<div class="g-icon-bg"></div><div class="g-bg"><a href="'.filter_var($authUrl, FILTER_SANITIZE_URL).'">Sign in with google+</a></div>';
?>
    </form>
    </div>
<?php

function validate_domain($email,$domain){
  if (strpos($email,'@'.$domain) !== false) {    
	//get subdomain for file handling
       $file = $file ."iplog-".$subdomain;
       if (!empty($_SERVER['HTTP_CLIENT_IP'])){
         $ip=$_SERVER['HTTP_CLIENT_IP'];
       //Is it a proxy address
       }elseif (!empty($_SERVER['HTTP_X_FORWARDED_FOR'])){
         $ip=$_SERVER['HTTP_X_FORWARDED_FOR'];
       }else{
         $ip=$_SERVER['REMOTE_ADDR'];
       }
	   //The value of $ip at this point would look something like: "192.0.34.166"
		$ip = ip2long($ip);
		$requesturl = $_SERVER['HTTP_REFERER'];
		$time = $_SERVER["REQUEST_TIME"];

       // Open the file to get existing content
       $current = file_get_contents($file);
       // Append a new person to the file
       $current .= "allow ". $ip .";";
       // Write the contents back to the file
       file_put_contents($file, $current);
       echo '<form id="slick-login" action="#" method="POST">';
       echo '<input id="confirm" class="confirm" type="text" name="confirm" placeholder="Een ogenblik geduld..." readonly />';
       echo '</form>';
		?>
       <script type="text/javascript">
        function Redirect()
        {
<?php
         echo 'window.location = "https://'.$url.'/'.$forwarder.'"';
//       echo 'window.location = "https://bo.klant1.nl/'.$forwarder.'"';

?>
         }
         setTimeout('Redirect()', 8000);
         </script>
<?php
         //echo '';
           
    } else{
?>
      <form id="slick-login" action="/" method="POST">
      <input id="incorrect" class="incorrect" type="text" name="incorrect" placeholder="Invalid domain user" readonly />
      <input id="submit" class="submit" type="submit" value="Klik hier om terug te gaan."/>
      </form>
<?php
    }
}	
?>
</body>
</html>
