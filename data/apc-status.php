<?php

$infoOpcode = @apc_cache_info('opcode', true);
$infoUser = @apc_cache_info('user', true);

echo json_encode(array(
  'opcode_mem_size' => (int) $infoOpcode['mem_size'],
  'user_mem_size'   => (int) $infoUser['mem_size'],
));
