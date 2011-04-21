<?php

require_once "scripts/cmdline.php";

// can also define crontab.php in modules, with same format as this file

return array(
   array(
       'interval' => 720, // minutes
       'cmd' => "php scripts/backup.php"
   ),
   array(
       'interval' => 1440,
       'cmd' => "php scripts/backup_s3.php"
   )   
);