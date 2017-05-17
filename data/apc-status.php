<?php

$infoOpcode = @apc_cache_info('opcode', true);
$infoUser = @apc_cache_info('user', true);
$infoAlloc = @apc_sma_info(true);

echo json_encode(array(
    'opcode_mem_size' => (int) $infoOpcode['mem_size'],
    'user_mem_size'   => (int) $infoUser['mem_size'],
    'avail_mem_size'  => (int) $infoAlloc['avail_mem'],
));
