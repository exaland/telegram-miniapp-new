<?php declare(strict_types=1);

$result = \TelegramBot\Request::setWebhook([
    'bot_token' => "7731229792:AAEFfAlMpgWWk_MeQ53nTdnmTfey0ElQ_7M"
    'url' => $_ENV['REMOTE_PATH'] . '/telegram',
    'drop_pending_updates' => true,
]);

echo $_ENV['REMOTE_PATH'] . '/telegram' . PHP_EOL;
echo $result->isOk() ? 'Webhook set successfully!' : 'Webhook set failed!';