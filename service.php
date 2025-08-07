<?php declare(strict_types=1);

use ShahradElahi\DurgerKing\App;
use Utilities\Routing\Response;
use Utilities\Routing\Router;
use Utilities\Routing\Utils\StatusCode;

require_once __DIR__ . '/vendor/autoload.php';

ini_set('display_errors', '1');
error_reporting(E_ALL);

$dotenv = Dotenv\Dotenv::createImmutable(__DIR__);
$dotenv->load();

Router::resource("https://creertonbot-ab19d53aadb0.herokuapp.com", __DIR__ . '/public');

Router::any("https://creertonbot-ab19d53aadb0.herokuapp.com/telegram", function () {
    (new App())->resolve();
    Response::send(StatusCode::OK, 'Bot is working...');
});

Router::any("https://creertonbot-ab19d53aadb0.herokuapp.com", function () {
    echo "Ready to serve...";
});