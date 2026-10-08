<?php
declare(strict_types=1);

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit;
}

function load_env(string $path): array {
    if (!is_file($path)) {
        return [];
    }
    $env = [];
    foreach (file($path, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) as $line) {
        $line = trim($line);
        if ($line === '' || str_starts_with($line, '#') || !str_contains($line, '=')) {
            continue;
        }
        [$key, $value] = explode('=', $line, 2);
        $env[trim($key)] = trim($value);
    }
    return $env;
}

function env_value(string $key, ?string $default = null): ?string {
    static $env = null;
    if ($env === null) {
        $env = load_env(dirname(__DIR__) . '/.env');
    }
    return $env[$key] ?? getenv($key) ?: $default;
}

function db(): PDO {
    static $pdo = null;
    if ($pdo !== null) {
        return $pdo;
    }
    $host = env_value('DB_HOST', '127.0.0.1');
    $port = env_value('DB_PORT', '3306');
    $name = env_value('DB_DATABASE', 'ahead_db');
    $user = env_value('DB_USERNAME', 'root');
    $pass = env_value('DB_PASSWORD', '');
    $dsn = "mysql:host={$host};port={$port};dbname={$name};charset=utf8mb4";
    $pdo = new PDO($dsn, $user, $pass, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    ]);
    return $pdo;
}

function json_input(): array {
    $raw = file_get_contents('php://input') ?: '{}';
    $data = json_decode($raw, true);
    return is_array($data) ? $data : [];
}

function respond(array $payload, int $status = 200): never {
    http_response_code($status);
    echo json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}

function require_fields(array $data, array $fields): void {
    foreach ($fields as $field) {
        if (!isset($data[$field]) || trim((string)$data[$field]) === '') {
            respond(['error' => "{$field} wajib diisi."], 422);
        }
    }
}

function bearer_token(): ?string {
    $header = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
    if (preg_match('/Bearer\s+(.+)/', $header, $matches)) {
        return trim($matches[1]);
    }
    return null;
}

function issue_token(int $userId): string {
    $token = bin2hex(random_bytes(32));
    $stmt = db()->prepare('INSERT INTO auth_tokens (user_id, token_hash, expires_at) VALUES (?, ?, DATE_ADD(NOW(), INTERVAL 30 DAY))');
    $stmt->execute([$userId, hash('sha256', $token)]);
    return $token;
}

function public_user(array $user): array {
    unset($user['password_hash']);
    return $user;
}

function current_user(): array {
    $token = bearer_token();
    if ($token === null) {
        respond(['error' => 'Token tidak ditemukan.'], 401);
    }
    $stmt = db()->prepare('SELECT users.* FROM auth_tokens JOIN users ON users.id = auth_tokens.user_id WHERE token_hash = ? AND expires_at > NOW() LIMIT 1');
    $stmt->execute([hash('sha256', $token)]);
    $user = $stmt->fetch();
    if (!$user) {
        respond(['error' => 'Token tidak valid atau kedaluwarsa.'], 401);
    }
    return public_user($user);
}

function ai_local_tutor_reply(string $message): string {
    $q = function_exists('mb_strtolower') ? mb_strtolower($message, 'UTF-8') : strtolower($message);
    $has = function (array $keywords) use ($q): bool {
        foreach ($keywords as $keyword) {
            if (str_contains($q, $keyword)) {
                return true;
            }
        }
        return false;
    };

    if ($has(['senyawa', 'molekul', 'unsur', 'atom', 'ion'])) {
        return 'Senyawa adalah zat yang terbentuk dari dua atau lebih unsur berbeda yang bergabung secara kimia dengan perbandingan tetap. Contohnya H2O, CO2, dan NaCl. Unsur hanya tersusun dari satu jenis atom, sedangkan senyawa punya beberapa unsur yang terikat dan membentuk sifat baru.';
    }

    if ($has(['asam', 'basa', 'ph', 'garam'])) {
        return 'Asam cenderung menghasilkan ion H+ di air, sedangkan basa menghasilkan ion OH-. pH kurang dari 7 bersifat asam, pH 7 netral, dan pH lebih dari 7 bersifat basa. Reaksi asam dan basa biasanya menghasilkan garam dan air.';
    }

    if ($has(['glbb', 'gerak lurus', 'kecepatan', 'percepatan'])) {
        return 'GLBB adalah gerak lurus berubah beraturan, yaitu gerak pada lintasan lurus dengan percepatan tetap. Rumus pentingnya: v = v0 + at, s = v0t + 1/2 at^2, dan v^2 = v0^2 + 2as.';
    }

    if ($has(['persamaan kuadrat', 'akar', 'diskriminan', 'faktorisasi'])) {
        return 'Persamaan kuadrat berbentuk ax^2 + bx + c = 0. Akar dapat dicari dengan faktorisasi, melengkapkan kuadrat, atau rumus x = (-b +- akar(b^2 - 4ac)) / 2a. Diskriminan menentukan jenis akarnya.';
    }

    if ($has(['soal', 'jawaban', 'pilihan ganda', 'essay', 'esai'])) {
        return 'Bisa, kirim soal lengkap beserta pilihan jawabannya jika ada. Saya akan bantu menentukan konsep, langkah penyelesaian, jawaban benar, dan alasan mengapa pilihan lain kurang tepat.';
    }

    return 'Saya menangkap pertanyaan kamu: "' . $message . '". Supaya jawabannya tepat, tulis istilah, rumus, atau soal lengkap yang ingin dibahas. Saya akan bantu dengan definisi, contoh, langkah penyelesaian, dan alasan jawabannya dengan bahasa yang mudah dipahami.';
}

$path = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH) ?? '/';
$path = '/' . trim(str_replace('/index.php', '', $path), '/');
$method = $_SERVER['REQUEST_METHOD'];

try {
    if ($method === 'GET' && $path === '/health') {
        respond(['ok' => true, 'app' => 'AHEAD API']);
    }

    if ($method === 'POST' && $path === '/auth/register') {
        $data = json_input();
        require_fields($data, ['name', 'email', 'password', 'class', 'major']);
        if (!filter_var($data['email'], FILTER_VALIDATE_EMAIL)) {
            respond(['error' => 'Email tidak valid.'], 422);
        }
        if (!preg_match('/^(?=.*[A-Z])(?=.*\d).{8,}$/', (string)$data['password'])) {
            respond(['error' => 'Password harus minimal 8 karakter, mengandung huruf besar dan angka.'], 422);
        }
        $exists = db()->prepare('SELECT id FROM users WHERE email = ? LIMIT 1');
        $exists->execute([strtolower(trim((string)$data['email']))]);
        if ($exists->fetch()) {
            respond(['error' => 'Email sudah terdaftar. Silakan login.'], 409);
        }
        $stmt = db()->prepare('INSERT INTO users (name, email, password_hash, class, major, provider) VALUES (?, ?, ?, ?, ?, "email")');
        $stmt->execute([
            trim((string)$data['name']),
            strtolower(trim((string)$data['email'])),
            password_hash((string)$data['password'], PASSWORD_DEFAULT),
            trim((string)$data['class']),
            $data['major'] === 'IPS' ? 'IPS' : 'IPA',
        ]);
        respond(['message' => 'Akun berhasil dibuat. Silakan login manual.'], 201);
    }

    if ($method === 'POST' && $path === '/auth/login') {
        $data = json_input();
        require_fields($data, ['email', 'password']);
        $stmt = db()->prepare('SELECT * FROM users WHERE email = ? LIMIT 1');
        $stmt->execute([strtolower(trim((string)$data['email']))]);
        $user = $stmt->fetch();
        if (!$user || !$user['password_hash'] || !password_verify((string)$data['password'], $user['password_hash'])) {
            respond(['error' => 'Email atau password salah.'], 401);
        }
        respond(['token' => issue_token((int)$user['id']), 'user' => public_user($user)]);
    }

    if ($method === 'POST' && $path === '/auth/google') {
        $data = json_input();
        require_fields($data, ['id_token']);
        $clientId = env_value('GOOGLE_CLIENT_ID');
        if (!$clientId) {
            respond(['error' => 'GOOGLE_CLIENT_ID belum dikonfigurasi.'], 503);
        }
        $tokenUrl = 'https://oauth2.googleapis.com/tokeninfo?id_token=' . urlencode((string)$data['id_token']);
        $tokenJson = @file_get_contents($tokenUrl);
        if ($tokenJson === false) {
            respond(['error' => 'Token Google tidak dapat diverifikasi.'], 401);
        }
        $tokenInfo = json_decode($tokenJson, true);
        if (!is_array($tokenInfo) || ($tokenInfo['aud'] ?? null) !== $clientId || ($tokenInfo['email_verified'] ?? 'false') !== 'true') {
            respond(['error' => 'Token Google tidak valid untuk aplikasi ini.'], 401);
        }
        $email = strtolower(trim((string)$tokenInfo['email']));
        $name = trim((string)($tokenInfo['name'] ?? $email));
        $googleId = trim((string)($tokenInfo['sub'] ?? ''));
        $photo = $tokenInfo['picture'] ?? null;
        $requestedMajor = isset($data['major']) && $data['major'] === 'IPS'
            ? 'IPS'
            : (isset($data['major']) && $data['major'] === 'IPA' ? 'IPA' : null);
        $stmt = db()->prepare('SELECT * FROM users WHERE email = ? LIMIT 1');
        $stmt->execute([$email]);
        $user = $stmt->fetch();
        if ($user) {
            $major = $requestedMajor ?: ($user['major'] === 'IPS' ? 'IPS' : 'IPA');
            $update = db()->prepare('UPDATE users SET name = ?, class = "Kelas X", major = ?, provider = "google", google_id = ?, profile_photo = COALESCE(?, profile_photo) WHERE id = ?');
            $update->execute([$name, $major, $googleId, $photo, (int)$user['id']]);
            $stmt->execute([$email]);
            $user = $stmt->fetch();
            respond(['token' => issue_token((int)$user['id']), 'user' => public_user($user), 'created' => false]);
        }
        $major = $requestedMajor ?: 'IPA';
        $insert = db()->prepare('INSERT INTO users (name, email, password_hash, class, major, provider, google_id, profile_photo) VALUES (?, ?, NULL, "Kelas X", ?, "google", ?, ?)');
        $insert->execute([$name, $email, $major, $googleId, $photo]);
        $userId = (int)db()->lastInsertId();
        $stmt = db()->prepare('SELECT * FROM users WHERE id = ? LIMIT 1');
        $stmt->execute([$userId]);
        $user = $stmt->fetch();
        respond(['token' => issue_token($userId), 'user' => public_user($user), 'created' => true], 201);
    }

    if ($method === 'POST' && $path === '/auth/logout') {
        $token = bearer_token();
        if ($token) {
            $stmt = db()->prepare('DELETE FROM auth_tokens WHERE token_hash = ?');
            $stmt->execute([hash('sha256', $token)]);
        }
        respond(['message' => 'Logout berhasil.']);
    }

    if ($method === 'POST' && $path === '/password/forgot') {
        $data = json_input();
        require_fields($data, ['email']);
        $stmt = db()->prepare('SELECT id FROM users WHERE email = ? LIMIT 1');
        $stmt->execute([strtolower(trim((string)$data['email']))]);
        $user = $stmt->fetch();
        if (!$user) {
            respond(['error' => 'Email tidak ditemukan.'], 404);
        }
        $token = bin2hex(random_bytes(16));
        $stmt = db()->prepare('INSERT INTO password_reset_tokens (user_id, token, expires_at) VALUES (?, ?, DATE_ADD(NOW(), INTERVAL 15 MINUTE))');
        $stmt->execute([(int)$user['id'], hash('sha256', $token)]);
        respond([
            'message' => 'Token reset dibuat. Hubungkan SMTP untuk mengirim token via email.',
            'dev_token' => env_value('APP_ENV', 'local') === 'local' ? $token : null,
        ]);
    }

    if ($method === 'POST' && $path === '/password/reset') {
        $data = json_input();
        require_fields($data, ['email', 'token', 'password']);
        if (!preg_match('/^(?=.*[A-Z])(?=.*\d).{8,}$/', (string)$data['password'])) {
            respond(['error' => 'Password baru belum memenuhi syarat.'], 422);
        }
        $stmt = db()->prepare('SELECT prt.id, prt.user_id FROM password_reset_tokens prt JOIN users ON users.id = prt.user_id WHERE users.email = ? AND prt.token = ? AND prt.used_at IS NULL AND prt.expires_at > NOW() LIMIT 1');
        $stmt->execute([strtolower(trim((string)$data['email'])), hash('sha256', (string)$data['token'])]);
        $reset = $stmt->fetch();
        if (!$reset) {
            respond(['error' => 'Token salah atau kedaluwarsa.'], 422);
        }
        db()->beginTransaction();
        db()->prepare('UPDATE users SET password_hash = ? WHERE id = ?')->execute([password_hash((string)$data['password'], PASSWORD_DEFAULT), (int)$reset['user_id']]);
        db()->prepare('UPDATE password_reset_tokens SET used_at = NOW() WHERE id = ?')->execute([(int)$reset['id']]);
        db()->commit();
        respond(['message' => 'Password berhasil diubah.']);
    }

    if ($method === 'GET' && $path === '/me') {
        respond(['user' => current_user()]);
    }

    if ($method === 'GET' && $path === '/subjects') {
        respond(['data' => db()->query('SELECT * FROM subjects ORDER BY id')->fetchAll()]);
    }

    if ($method === 'GET' && $path === '/materials') {
        respond(['data' => db()->query('SELECT materials.*, subjects.name AS subject_name FROM materials JOIN subjects ON subjects.id = materials.subject_id ORDER BY materials.id')->fetchAll()]);
    }

    if ($method === 'GET' && $path === '/exams') {
        respond(['data' => db()->query('SELECT * FROM exams ORDER BY id')->fetchAll()]);
    }

    if ($method === 'GET' && $path === '/dashboard') {
        $user = current_user();
        $userId = (int)$user['id'];
        $material = (int)db()->query("SELECT COALESCE(AVG(progress), 0) FROM material_progress WHERE user_id = {$userId}")->fetchColumn();
        $practice = (int)db()->query("SELECT COALESCE(AVG(score), 0) FROM practice_sessions WHERE user_id = {$userId}")->fetchColumn();
        $exam = (int)db()->query("SELECT COALESCE(AVG(score), 0) FROM exam_sessions WHERE user_id = {$userId}")->fetchColumn();
        $consistency = 0;
        $score = (int)round(($material + $practice + $exam + $consistency) / 4);
        respond(['data' => [
            'ahead_score' => $score,
            'material_mastery' => $material,
            'practice' => $practice,
            'exam' => $exam,
            'consistency' => $consistency,
            'streak' => 0,
        ]]);
    }

    if ($method === 'POST' && $path === '/ai/chat') {
        $user = current_user();
        $data = json_input();
        require_fields($data, ['message']);
        if (!env_value('OPENAI_API_KEY')) {
            respond([
                'message' => ai_local_tutor_reply((string)$data['message']),
                'mode' => 'local_tutor',
                'user_id' => $user['id'],
            ]);
        }
        respond([
            'message' => ai_local_tutor_reply((string)$data['message']),
            'mode' => 'local_tutor',
            'user_id' => $user['id'],
        ]);
    }

    respond(['error' => 'Route tidak ditemukan.', 'path' => $path], 404);
} catch (Throwable $error) {
    if (isset($pdo) && db()->inTransaction()) {
        db()->rollBack();
    }
    respond(['error' => 'Server error.', 'detail' => env_value('APP_ENV', 'local') === 'local' ? $error->getMessage() : null], 500);
}
