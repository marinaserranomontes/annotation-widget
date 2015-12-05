<?php
/* -----------------------------------------------------------------------------------------------
 * OpenTok Default Configuration
 *
 * This configuration is used as fallback when no other environment has been chosen. As a default,
 * the values are read from the environment variables, and there is no need to change this file.
 * -----------------------------------------------------------------------------------------------*/
echo json_encode(array(
    'key' => ($key = getenv('OPENTOK_KEY')) ? $key : '',
    'sessionId' => ($sessionId = getenv('OPENTOK_SESSION_ID')) ? $sessionId : '',
    'token' => ($token = getenv('OPENTOK_TOKEN')) ? $token : ''
));