<h1 style=" text-align:center; margin-top:10%;">Google authentication is success, will redirect soon</h1>
<?php
include 'gpConfig.php';

if(isset($_GET['code'])){
	$gClient->authenticate($_GET['code']);
	$_SESSION['g_token'] = $gClient->getAccessToken();
  echo '<script type="text/javascript">
document.location="'.$siteURL.'";
</script>';

}


?>
