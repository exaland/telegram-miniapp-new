<?php declare(strict_types=1);

use ShahradElahi\DurgerKing\App;
use ShahradElahi\DurgerKing\Plugins\WebService;
use TelegramBot\Entities\WebAppData;
use Utilities\Routing\Response;
use Utilities\Routing\Router;
use Utilities\Routing\Utils\StatusCode;

require_once __DIR__ . '/vendor/autoload.php';

ini_set('display_errors', '1');
error_reporting(E_ALL);

// Load environment variables
$dotenv = Dotenv\Dotenv::createImmutable(__DIR__);
$dotenv->load();

// Serve static files from /public
Router::resource("{$_ENV['REMOTE_URI']}/public", __DIR__ . '/public');

/**
 * Route pour Telegram Webhook ou WebApp
 */
Router::any("{$_ENV['REMOTE_URI']}/telegram", function () {

    // --- Détection WebApp ---
    // Une requête WebApp a généralement `order_data` et `method` dans POST/GET
    if (!empty($_REQUEST['order_data']) && !empty($_REQUEST['method'])) {

        // Normalisation des données reçues
        $rawData = [
            'method'      => $_REQUEST['method'],
            'order_data'  => $_REQUEST['order_data'],
            'comment'     => $_REQUEST['comment'] ?? '',
            'user'        => [
                'id'         => $_REQUEST['user_id']     ?? 0,
                'first_name' => $_REQUEST['first_name'] ?? '',
                'last_name'  => $_REQUEST['last_name']  ?? '',
                'username'   => $_REQUEST['username']   ?? '',
            ]
        ];

        // Création de l'objet WebAppData (émulation)
        $webAppData = new WebAppData($rawData);

        // Appel direct du plugin
        $webService = new WebService();
        foreach ($webService->onWebAppData($webAppData) as $result) {
            // Les méthodes du plugin peuvent retourner des yield
            // Ici on ne fait rien de spécial, mais on pourrait logger
        }

        return; // On termine ici pour WebApp
    }

    // --- Sinon, Webhook Telegram classique ---
    (new App())->resolve();
    Response::send(StatusCode::OK, 'Bot is working...');
});

/**
 * Route racine
 */
Router::any("{$_ENV['REMOTE_URI']}", function () {
    echo "Ready to serve...";
});
