import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// All HTTP calls go through [ApiClient].
/// Screens never touch Dio or storage directly.
///
/// Base URL is pulled from --dart-define at build time:
///   flutter run --dart-define=API_BASE_URL=https://your-backend.onrender.com
///
/// Never hardcode the URL here.
class ApiClient {
  ApiClient._();

  static const _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://paycycle-backend-1.onrender.com',
  );

  /// Base URL for the subscriber payment page (pay.html).
  /// Update this when the frontend is hosted on a real domain.
  static const webBaseUrl = String.fromEnvironment(
    'WEB_BASE_URL',
    defaultValue: 'https://paycycle-backend-1.onrender.com',
  );

  static final _storage = const FlutterSecureStorage();
  static late final Dio _dio;

  /// Call once in main() before runApp
  static void init() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // JWT interceptor — attaches token to every request automatically
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'jwt');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          // 401 → clear token and let the app redirect to login
          if (error.response?.statusCode == 401) {
            await _storage.delete(key: 'jwt');
            await _storage.delete(key: 'user_name');
          }
          handler.next(error);
        },
      ),
    );
  }

  // ── Token + user helpers ─────────────────────────────────────
  static Future<void> saveToken(String token) =>
      _storage.write(key: 'jwt', value: token);

  static Future<void> clearToken() async {
    await _storage.delete(key: 'jwt');
    await _storage.delete(key: 'user_name');
  }

  static Future<bool> hasToken() async =>
      (await _storage.read(key: 'jwt')) != null;

  /// Save the user's display name — called right after signup/login
  static Future<void> saveName(String name) =>
      _storage.write(key: 'user_name', value: name);

  /// Read the stored name — used by the dashboard topbar
  static Future<String?> getName() => _storage.read(key: 'user_name');

  // ── Generic request helpers ──────────────────────────────────
  static Future<Map<String, dynamic>> get(String path) async {
    final res = await _dio.get<Map<String, dynamic>>(path);
    return res.data!;
  }

  static Future<List<dynamic>> getList(String path) async {
    final res = await _dio.get<List<dynamic>>(path);
    return res.data!;
  }

  static Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(path, data: body);
    return res.data!;
  }

  static Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final res = await _dio.patch<Map<String, dynamic>>(path, data: body);
    return res.data!;
  }

  // ── Auth ─────────────────────────────────────────────────────

  /// POST /auth/login → { access_token, token_type }
  ///
  /// Since the login response has no user object, the name shown
  /// on the dashboard comes from what was saved during signup.
  /// If the user reinstalls the app and logs in fresh, they'll see
  /// 'Loading...' until we add a /me endpoint later.
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final data = await post(
      '/auth/login',
      body: {'email': email, 'password': password},
    );

    // Backend returns access_token directly
    final token = data['access_token'] as String?;
    if (token == null) throw Exception('No token in login response');
    await saveToken(token);

    return data;
  }

  /// POST /auth/signup → user object (no token yet)
  ///
  /// Name is saved locally here so the dashboard can show it
  /// immediately after the user logs in with their new credentials.
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String phoneNumber,
  }) async {
    final data = await post(
      '/auth/signup',
      body: {
        'name': name,
        'email': email,
        'password': password,
        'phone_number': phoneNumber,
      },
    );

    // Save name from the form — backend doesn't return a token here yet
    await saveName(name);

    return data;
  }

  // ── Dashboard ─────────────────────────────────────────────────
  /// GET /auth/me → { name, email, phone_number, ... }
  static Future<Map<String, dynamic>> getMe() => get('/auth/me');

  /// GET /dashboard → { total_revenue, active_subscribers,
  ///                     failed_payments, next_billing }
  static Future<Map<String, dynamic>> getDashboard() => get('/dashboard');

  // ── Plans ─────────────────────────────────────────────────────
  /// GET /plans → [{ id, name, amount, billing_frequency, provider_id }]
  static Future<List<dynamic>> getPlans() => getList('/plans');

  /// POST /plans → { id, name, amount, billing_frequency, billing_day, payment_link }
  static Future<Map<String, dynamic>> createPlan({
    required String name,
    required int amount,
    required String cycle, // 'daily' | 'weekly' | 'monthly' | 'quarterly'
    int? billingDay,
  }) => post(
    '/plans',
    body: {
      'name': name,
      'amount': amount,
      'billing_frequency': cycle,
      if (billingDay != null) 'billing_day': billingDay,
    },
  );

  // ── Subscribers ───────────────────────────────────────────────
  /// GET /plans/:planId/subscribers → { subscribers[], collected, outstanding }
  static Future<Map<String, dynamic>> getSubscribers(String planId) =>
      get('/plans/$planId/subscribers');

  /// POST /charge/:subscriberId → { success, message }
  static Future<Map<String, dynamic>> retryCharge(String subscriberId) =>
      post('/charge/$subscriberId');

  /// PATCH /subscribers/:subscriberId/status → { success }
  static Future<Map<String, dynamic>> updateSubscriberStatus(
    String subscriberId, {
    required String status,
  }) => patch('/subscribers/$subscriberId/status', body: {'status': status});

  // ── My subscriptions ──────────────────────────────────────────
  /// GET /pay/:token → { plan_name, amount, cycle, provider_name }
  static Future<Map<String, dynamic>> getPaymentDetails(String token) =>
      get('/pay/$token');

  /// GET /my-subscriptions → { subscriptions[] }
  static Future<Map<String, dynamic>> getMySubscriptions() =>
      get('/my-subscriptions');

  // ── Wallet ────────────────────────────────────────────────────
  /// GET /wallet → { id, balance }  (balance is in kobo)
  /// NOTE: backend doesn't return total_earned/pending_clearance —
  /// those are derived client-side from the ledger in wallet_screen.dart.
  static Future<Map<String, dynamic>> getWallet() => get('/wallet/wallet');

  /// GET /wallet/wallet/ledger → [ { id, amount, type, reference, description, created_at }, ... ]
  /// Bare JSON array (confirmed against backend route), amount in kobo.
  static Future<List<dynamic>> getWalletLedger() =>
      getList('/wallet/wallet/ledger');

  /// POST /wallet/verify-account → { account_name }
  static Future<Map<String, dynamic>> verifyAccount({
    required String accountNumber,
    required String bankName,
  }) => post(
    '/wallet/verify-account',
    body: {'account_number': accountNumber, 'bank_name': bankName},
  );

  /// POST /wallet/withdraw → { success, reference }
  /// Amount must be in kobo (multiply Naira × 100 before calling)
  static Future<Map<String, dynamic>> withdraw({
    required int amountKobo,
    required String bankName,
    required String accountNumber,
    required String accountName,
  }) => post(
    '/wallet/withdraw',
    body: {
      'amount': amountKobo,
      'bank_name': bankName,
      'account_number': accountNumber,
      'account_name': accountName,
    },
  );
}