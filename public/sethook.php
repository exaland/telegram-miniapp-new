<?php declare(strict_types=1);

$result = \TelegramBot\Request::setWebhook([
    'bot_token' => "7731229792:AAEFfAlMpgWWk_MeQ53nTdnmTfey0ElQ_7M",
    'url' => "https://creertonbot-ab19d53aadb0.herokuapp.com/telegram",
    'drop_pending_updates' => true,
]);

echo "https://creertonbot-ab19d53aadb0.herokuapp.com/telegram" . PHP_EOL;
echo $result->isOk() ? 'Webhook set successfully!' : 'Webhook set failed!';