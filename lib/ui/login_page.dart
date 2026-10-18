import 'dart:async';
import 'dart:math' as math;

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:betrader/services/auth_service.dart';
import 'package:betrader/locale/localized_texts.dart';
import 'package:betrader/helpers/common.dart';
import 'package:betrader/helpers/status_background.dart';
import 'package:betrader/ui/signin_page.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart' hide Config;
import '../config/config.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../helpers/google_sign_in_button.dart';
import '../helpers/preload_cache.dart';
import '../helpers/web_console_log.dart';
import '../services/bets_service.dart';
import 'first_time_page.dart';
import 'layout_page.dart';
import 'markets_page.dart';
import '../app_navigator.dart';

/// Helper function to wait for the next frame to be rendered.
///
/// Useful for ensuring UI updates are visible before proceeding with
/// navigation or state changes.
Future<void> _waitForNextFrame() async {
  final completer = Completer<void>();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    completer.complete();
  });
  await completer.future;
}

/// The login page widget handling user authentication.
///
/// Supports both manual login (email/password) and social login (Google).
/// Includes animated UI transitions and loading states during authentication.
class LoginPage extends StatefulWidget {
  /// Whether this is an automatic login attempt (e.g., from saved credentials).
  final bool isAutoLogin;
  const LoginPage({super.key, this.isAutoLogin = false});

  @override
  State<LoginPage> createState() => _LoginPageState();
  
  // Bandera estática para evitar múltiples instancias simultáneas
  static bool _isNavigating = false;
  
  /// Navigates to the login page, preventing duplicate navigations.
  ///
  /// Uses a static flag to ensure only one navigation occurs at a time.
  /// Can use either the provided context or the global navigator key.
  ///
  /// [context] Optional build context for navigation. If null, uses global navigator.
  static void navigateToLogin(BuildContext? context) {
    // Evitar navegaciones duplicadas dentro de 1 segundo
    if (_isNavigating) {
      return; // Ya hay una navegación en curso
    }
    
    _isNavigating = true;
    
    try {
      if (context != null && context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (Route<dynamic> route) => false,
        );
      } else {
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      debugPrint('Error navegando a LoginPage: $e');
    } finally {
      // Resetear la bandera después de un delay más largo
      Future.delayed(const Duration(milliseconds: 1000), () {
        _isNavigating = false;
      });
    }
  }
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  late AnimationController _contentController;
  late AnimationController _dotsController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  Timer? _contentDelayTimer;
  bool _isLoading = false; // Bandera para controlar cuando mostrar la animación de carga
  /// Placeholder hasta conectar un contador real de usuarios en línea.
  late final int _onlineUsers;

  @override
  void initState() {
    super.initState();
    _onlineUsers = 40 + math.Random().nextInt(161); // 40–200

    // Controlador para el contenido (con delay)
    _contentController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Controlador para la animación de puntos
    _dotsController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();

    // Controlador para la animación de pulso del icono
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Si es auto-login, ocultar botones y cargar datos
    if (widget.isAutoLogin) {
      // Ocultar botones inmediatamente
      _contentController.value = 0.0;
      _isLoading = true; // Activar bandera de carga
      // Cargar datos y luego navegar
      _handleAutoLogin();
    } else {
      // Iniciar animación del contenido después de un pequeño delay
      _contentDelayTimer = Timer(const Duration(milliseconds: 300), () {
        if (mounted) {
          _contentController.forward();
        }
      });
      _isLoading = false; // No mostrar animación de carga al inicio
    }
  }

  /// Handles automatic login flow.
  ///
  /// Preloads market data while showing loading animation, then navigates
  /// to the main menu page.
  Future<void> _handleAutoLogin() async {
    // Asegurar que el estado de carga esté activo
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    
    // Esperar a que el frame se renderice para mostrar la animación de carga
    await _waitForNextFrame();
    if (!mounted) return;
    
    // Esperar un frame adicional para asegurar que el widget de carga esté completamente renderizado
    await _waitForNextFrame();
    if (!mounted) return;
    
    // Mostrar notificación de bienvenido durante la carga
    final strings = LocalizedStrings.of(context);
    final storage = const FlutterSecureStorage();
    String? username = await storage.read(key: 'username');
    if (username != null && mounted) {
      Common().showFloatingSnack(context, "${strings?.get('welcome') ?? "Welcome"} $username!");
    }
    
    // Cargar TODOS los datos durante "Cargando..." antes de abandonar la vista
    await Future.wait([
      MarketsView.preloadAllMarketData(),
      PreloadCache.preloadAll(),
    ]);
    
    if (!mounted) return;
    
    // Navegar a MainMenuPage solo cuando todo esté listo
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainMenuPage()),
    );
  }

  @override
  void dispose() {
    // Cancelar el timer si existe
    _contentDelayTimer?.cancel();
    _contentDelayTimer = null;
    
    // Detener y resetear las animaciones antes de hacer dispose
    if (_contentController.isAnimating) {
      _contentController.stop();
    }
    _contentController.reset();
    _dotsController.dispose();
    _pulseController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _onLoadingChanged(bool isLoading) {
    if (mounted) {
      setState(() {
        _isLoading = isLoading;
      });
    }
  }

  Widget _webTopBar() {
    return Material(
      color: Colors.black.withValues(alpha: 0.55),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
        ),
        child: Row(
          children: [
            Image.asset('assets/new_icon.png', width: 28, height: 28),
            const SizedBox(width: 10),
            Text(
              'Betrader',
              style: GoogleFonts.syncopate(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Web',
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white54,
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _webLoginCard(LocalizedStrings? strings) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 40),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
          ),
        ),
        // Intrinsic height: el borde se ajusta al contenido (sin hueco vacío).
        child: LoginForm(
          animationController: _contentController,
          onLoadingStateChanged: _onLoadingChanged,
          webMode: true,
        ),
      ),
    );
  }

  Widget _webHeroCopy(LocalizedStrings? strings, {bool compact = false}) {
    final onlineLabel = strings?.get('usersOnline') ??
        '$_onlineUsers usuarios en línea';
    final onlineText = onlineLabel.contains('{count}')
        ? onlineLabel.replaceAll('{count}', '$_onlineUsers')
        : '$_onlineUsers usuarios en línea';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment:
          compact ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          'Re-descubre el juego de la bolsa',
          textAlign: compact ? TextAlign.center : TextAlign.left,
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontSize: compact ? 28 : 42,
            fontWeight: FontWeight.w700,
            height: 1.15,
          ),
        ),
        SizedBox(height: compact ? 14 : 20),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: compact ? 9 : 10,
              height: compact ? 9 : 10,
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF22C55E).withValues(alpha: 0.55),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              onlineText,
              style: GoogleFonts.montserrat(
                color: Colors.white70,
                fontSize: compact ? 14 : 16,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _webLoginBody(LocalizedStrings? strings) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 880;
        final padH = wide ? 40.0 : 24.0;

        if (wide) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: padH, vertical: 32),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 5,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 48),
                        child: _webHeroCopy(strings),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Align(
                        alignment: Alignment.center,
                        child: _webLoginCard(strings),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Vista estrecha: bloque centrado en vertical y horizontal.
        final minH = constraints.maxHeight > 48
            ? constraints.maxHeight - 48
            : constraints.maxHeight;
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: padH, vertical: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minH),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _webHeroCopy(strings, compact: true),
                  const SizedBox(height: 36),
                  _webLoginCard(strings),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = LocalizedStrings.of(context);
    final isWeb = kIsWeb;

    if (isWeb) {
      return Scaffold(
        backgroundColor: StatusBackgroundColors.top,
        body: Stack(
          children: [
            const Positioned.fill(child: StatusBackground()),
            Column(
              children: [
                _webTopBar(),
                Expanded(
                  child: FadeTransition(
                    opacity: _contentController,
                    child: _webLoginBody(strings),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    Config.codeVersion,
                    style: GoogleFonts.montserrat(
                      color: Colors.white38,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            if (_isLoading && _contentController.value < 0.1)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.45),
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: StatusBackgroundColors.top,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0.0,
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: StatusBackground()),
          // Contenido con animaciones escalonadas
          FadeTransition(
            opacity: _contentController,
            child: Center(
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: LoginForm(
                      animationController: _contentController,
                      onLoadingStateChanged: _onLoadingChanged,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Animación de carga con icono y texto "Cargando" cuando el contenido está oculto
          AnimatedBuilder(
            animation: Listenable.merge([_contentController, _dotsController, _pulseController]),
            builder: (context, child) {
              // Mostrar solo cuando está cargando activamente (auto-login o durante login)
              if (_isLoading && _contentController.value < 0.1) {
                final strings = LocalizedStrings.of(context);
                // Calcular cuántos puntos mostrar (0, 1, 2 o 3)
                final dotsValue = _dotsController.value;
                int dotsCount;
                if (dotsValue < 0.25) {
                  dotsCount = 0;
                } else if (dotsValue < 0.5) {
                  dotsCount = 1;
                } else if (dotsValue < 0.75) {
                  dotsCount = 2;
                } else {
                  dotsCount = 3;
                }
                
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icono con efecto de pulso suave
                      Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.15 * (1 - _pulseAnimation.value)),
                                blurRadius: 40 * (1 - _pulseAnimation.value),
                                spreadRadius: 15 * (1 - _pulseAnimation.value),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/new_icon.png',
                            width: 250,
                            height: 250,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      // Texto "Cargando" con puntos parpadeantes
                      AnimatedBuilder(
                        animation: Listenable.merge([_pulseController, _dotsController]),
                        builder: (context, child) {
                          return Opacity(
                            opacity: 0.6 + (0.4 * _pulseAnimation.value),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 70),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    height: 45, // Altura fija para mantener posición estática
                                    child: Center(
                                      child: Text(
                                        strings?.get('loading') ?? 'Cargando',
                                        style: GoogleFonts.notoSerifJp(
                                          fontSize: 32,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white,
                                          letterSpacing: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 45, // Ancho fijo para mantener posición del texto "Cargando"
                                    height: 45, // Altura fija para mantener posición estática
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        '.' * dotsCount,
                                        style: GoogleFonts.notoSerifJp(
                                          fontSize: 32,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white,
                                          letterSpacing: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          // Botón izquierdo
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 20,
            left: 16,
            child: FadeTransition(
              opacity: _contentController,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(-1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _contentController,
                  curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
                )),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.fromLTRB(5, 0, 0, 0),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    surfaceTintColor: Colors.transparent,
                    backgroundColor: Colors.transparent,
                    overlayColor: Colors.transparent.withValues(alpha: 0),
                    elevation: 0,
                  ),
                  onPressed: () => {
                    Common().vibrate(),
                    Common().applyImmersive(),
                    Common().openInAppBrowser(context,Config.statusPage)
                  },
                  child: Icon(
                    FontAwesomeIcons.signal,
                    size: 26,
                    color: Colors.white70.withValues(alpha: .5),
                  ),
                ),
              ),
            ),
          ),
          // Botón derecho
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 20,
            right: 16,
            child: FadeTransition(
              opacity: _contentController,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _contentController,
                  curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
                )),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.fromLTRB(0, 0, 5, 0),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    surfaceTintColor: Colors.transparent,
                    backgroundColor: Colors.transparent,
                    overlayColor: Colors.transparent.withValues(alpha: 0),
                    elevation: 0,
                  ),
                  onPressed: () => Common().openInAppBrowser(context, Config.instagramPage),
                  child: Icon(
                    FontAwesomeIcons.instagram,
                    size: 35,
                    color: Colors.white70.withValues(alpha: .5),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(10.0),
        child: Text(
          Config.codeVersion,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

/// A form widget for user login with email/password and social login options.
///
/// Handles form validation, authentication requests, and provides UI for
/// switching between social and manual login modes.
class LoginForm extends StatefulWidget {
  /// Animation controller for form appearance animations.
  final AnimationController animationController;
  
  /// Callback invoked when loading state changes.
  final Function(bool) onLoadingStateChanged;

  /// Layout compacto de escritorio (estilo Polymarket / web).
  final bool webMode;
  
  const LoginForm({
    super.key, 
    required this.animationController,
    required this.onLoadingStateChanged,
    this.webMode = false,
  });

  @override
  LoginFormState createState() => LoginFormState();
}

class LoginFormState extends State<LoginForm> with WidgetsBindingObserver {
  Widget _constrainAuthControl(Widget child) {
    return SizedBox(width: double.infinity, child: child);
  }

  double get _authRadius => widget.webMode ? 8.0 : 30.0;

  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showSocialSignIn = true;
  bool _isKeyboardVisible = false;


  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  bool _googleAuthBusy = false;
  GoogleSignIn? _webGoogle;
  StreamSubscription<GoogleSignInAccount?>? _webGoogleSub;

  Future<void> _handleGoogleAuthResult(
    int? result,
    LocalizedStrings strings,
  ) async {
    if (!mounted) return;

    if (result != null && result == 0) {
      String? id = await _storage.read(key: 'sessionToken');
      await BetsService().getUserInfo(id!);
      if (!mounted) return;

      widget.onLoadingStateChanged(true);
      await widget.animationController.reverse();
      await Future.delayed(const Duration(milliseconds: 300));

      await _waitForNextFrame();
      if (!mounted) return;

      await _waitForNextFrame();
      if (!mounted) return;

      String? username = await _storage.read(key: 'username');
      Common().showFloatingSnack(
        context,
        "${strings.get('welcome') ?? "Welcome"} $username!",
      );

      await MarketsView.preloadAllMarketData();

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainMenuPage()),
      );
    } else if (result != null && result == 3) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const FirstTimePage()),
      );
    } else if (result != null && result == 2) {
      String? id = await _storage.read(key: 'sessionToken');
      await BetsService().getUserInfo(id!);
      if (!mounted) return;
      String? username = await _storage.read(key: 'username');
      Common().showFloatingSnack(
        context,
        "${strings.get('welcome') ?? "Welcome"} $username!",
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const FirstTimePage()),
      );
    } else {
      if (!mounted) return;
      final detail =
          AuthService.lastError ?? 'Google login failed (result=$result)';
      // ignore: avoid_print
      print('[LoginPage] FAIL $detail');
      Common().showFloatingSnack(
        context,
        detail,
        backgroundColor: Colors.red,
        theDuration: 10,
      );
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Google login'),
          content: SingleChildScrollView(child: Text(detail)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _runGoogleAuth(Future<int?> Function() authCall) async {
    if (_googleAuthBusy) return;
    _googleAuthBusy = true;
    Common().applyImmersive();
    if (!mounted) {
      _googleAuthBusy = false;
      return;
    }
    showDialog(
      barrierColor: Colors.black.withAlpha(100),
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        );
      },
    );
    int? result;
    try {
      result = await authCall();
    } finally {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
    try {
      if (!mounted) return;
      final strings = LocalizedStrings.of(context);
      if (strings == null) return;
      await _handleGoogleAuthResult(result, strings);
    } finally {
      _googleAuthBusy = false;
    }
  }

  Future<void> _onGoogleSignInPressed() async {
    // Móvil / desktop: popup nativo.
    await _runGoogleAuth(() => AuthService().googleSignIn());
  }

  Future<void> _onWebGoogleAccount(GoogleSignInAccount? account) async {
    if (!kIsWeb || account == null || _googleAuthBusy) return;
    final auth = await account.authentication;
    final idToken = auth.idToken;
    webConsoleLog(
      '[GoogleWeb] account=${account.email} idToken=${idToken != null && idToken.isNotEmpty}',
    );
    if (idToken == null || idToken.isEmpty) {
      if (!mounted) return;
      Common().showFloatingSnack(
        context,
        'Google no entregó idToken. Recarga e inténtalo de nuevo.',
        backgroundColor: Colors.red,
        theDuration: 8,
      );
      return;
    }
    await _runGoogleAuth(
      () => AuthService().googleSignInWithIdToken(idToken),
    );
  }

  /// Handles the login process with email and password.
  ///
  /// Validates credentials, shows loading indicator, authenticates user,
  /// and navigates to main menu on success. Shows error messages on failure.
  ///
  /// [strings] Localized strings for UI messages.
  void logInHelper(LocalizedStrings strings) async {
    if (!mounted) return;
    final user = _usernameController.text.trim();
    // No trim de password: espacios finales pueden ser parte de la clave.
    final pass = _passwordController.text;
    void uiLog(String msg) {
      final line = '[LoginUI] $msg';
      webConsoleLog(line);
      // ignore: avoid_print
      print(line);
    }

    uiLog('email login tapped user="$user" passwordLen=${pass.length}');
    showDialog(
      barrierColor: Colors.black.withAlpha(100),
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      final result = await AuthService().logIn(user, pass);
      uiLog('AuthService.logIn returned success=${result['success']} message=${result['message']}');
      if (!mounted) return;
      Navigator.of(context).pop();

      if (result['success']) {
        String? id = await _storage.read(key: 'sessionToken');
        uiLog('sessionToken=${id == null || id.isEmpty ? "(null/empty)" : "ok len=${id.length}"}');
        await BetsService().getUserInfo(id!);
        uiLog('getUserInfo done → navigating MainMenu');
        if (!mounted) return;
        
        // Activar bandera de carga y ocultar botones con animación inversa
        widget.onLoadingStateChanged(true);
        await widget.animationController.reverse();
        await Future.delayed(const Duration(milliseconds: 300));
        
        // Esperar a que el frame se renderice para asegurar que el widget de carga esté visible
        await _waitForNextFrame();
        if (!mounted) return;
        
        // Esperar un frame adicional para asegurar renderizado completo
        await _waitForNextFrame();
        if (!mounted) return;
        
        // Mostrar notificación de bienvenido durante la carga
        Common().showFloatingSnack(context, "${strings.get('welcome') ?? "Welcome"}  $user!");
        
        // Cargar TODOS los datos durante "Cargando..." antes de abandonar la vista
        await Future.wait([
          MarketsView.preloadAllMarketData(),
          PreloadCache.preloadAll(),
        ]);
        
        if (!mounted) return;
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => const MainMenuPage()));

      } else {
        final msg = (result['message'] ?? 'Login failed').toString();
        uiLog('login failed → $msg');
        if (!mounted) return;
        Common().showFloatingSnack(
          context,
          msg,
          backgroundColor: Colors.red,
        );
      }
    } catch (e, st) {
      uiLog('EXCEPTION: $e\n$st');
      if (!mounted) return;
      Navigator.of(context).pop();
      Common().showFloatingSnack(
        context,
        e.toString(),
        backgroundColor: Colors.red,
      );
    }
  }

  /// Shows a dialog for password reset via email.
  ///
  /// Displays a form where users can enter their email to receive
  /// a password reset link.
  ///
  /// [context] The build context for showing the dialog.
  /// Returns `true` if password reset was successful, `false` otherwise.
  Future<bool?> showEmailPasswordDialog(BuildContext context) async {
    final strings = LocalizedStrings.of(context);
    final TextEditingController emailController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final Color bgColor = Colors.grey[900]!;
    final Color fieldColor = Colors.grey[850]!;
    final Color textColor = Colors.white;

    return await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) Navigator.pop(dialogContext, false);
          },
          child: AlertDialog(
            backgroundColor: bgColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              strings?.get('resetPasswordInfo') ?? "Your account password will be reset and the new one will be sent to your email address",
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 22,
                fontWeight: FontWeight.w300,
                color: textColor,
              ),
            ),
            content: Form(
              key: formKey,
              child: TextFormField(
                controller: emailController,
                style: GoogleFonts.montserrat(color: textColor),
                decoration: InputDecoration(
                  labelText: strings?.get('email') ?? "Email",
                  labelStyle: GoogleFonts.montserrat(color: textColor),
                  filled: true,
                  fillColor: fieldColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return strings?.get('thisFieldIsRequired') ?? "Required";
                  }
                  final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                  if (!emailRegex.hasMatch(value)) {
                    return strings?.get('invalidEmail') ?? "Invalid email format";
                  }
                  return null;
                },
              ),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              StatefulBuilder(
                builder: (context, setState) => ElevatedButton(
                  onPressed: () async {
                    FocusManager.instance.primaryFocus?.unfocus();
                    if (formKey.currentState?.validate() != true) return;

                    final response = await Common()
                        .postRequestWrapper('Auth','ResetPassword', {"emailOrId": emailController.text.trim()} , includeJwt: false);

                    if (response['statusCode'] == 200) {
                      Navigator.of(dialogContext).pop(true);
                      Common().showFloatingSnack(
                          context,
                          strings?.get('successPassword') ??
                              "Password changed successfully");

                    } else if (response['statusCode'] == 404){
                      Common().showErrorSnack(context);

                    } else {
                      Common().showErrorSnack(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: textColor,
                    textStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w600).copyWith(inherit: false),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child:
                  Text(strings?.get('newPassword') ?? "New Password"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUsernameField(LocalizedStrings strings) {
    final fieldSize = widget.webMode ? 15.0 : 25.0;
    final labelSize = widget.webMode ? 14.0 : 25.0;
    return TextFormField(
      cursorColor: Colors.black,
      controller: _usernameController,
      decoration: InputDecoration(
          border: OutlineInputBorder(borderSide: BorderSide.none),
          labelText: "E-mail / ${strings.get('username') ?? 'User name'}",
          labelStyle: GoogleFonts.syncopate(fontSize: labelSize),
          errorStyle: GoogleFonts.montserrat(
            color: Colors.red,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          floatingLabelStyle: GoogleFonts.syncopate(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),

      ),
      style: GoogleFonts.montserrat(fontSize: fieldSize),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return strings.get('pleaseEnterUsername') ??
              'Please enter your username';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField(LocalizedStrings strings) {
    final fieldSize = widget.webMode ? 15.0 : 25.0;
    final labelSize = widget.webMode ? 14.0 : 25.0;
    return TextFormField(
      cursorColor: Colors.black,
      controller: _passwordController,
      obscureText: true,
      decoration: InputDecoration(
          border: OutlineInputBorder(borderSide: BorderSide.none),
          labelText: (strings.get('password') ?? 'Password'),
          labelStyle: GoogleFonts.syncopate(fontSize: labelSize),
          errorStyle: GoogleFonts.montserrat(
            color: Colors.red,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          floatingLabelStyle: GoogleFonts.syncopate(
            color: Colors.white,
              fontWeight: FontWeight.w500,
          ),
      ),
      style: GoogleFonts.montserrat(fontSize: fieldSize),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return strings.get('pleaseEnterPassword') ??
              'Please enter your password';
        }
        return null;
      },
    );
  }

  static const double _authBtnHeight = 50;

  ButtonStyle _authButtonStyle({
    required Color foreground,
    required Color background,
  }) {
    return ElevatedButton.styleFrom(
      foregroundColor: foreground,
      backgroundColor: background,
      elevation: 0,
      fixedSize: const Size(double.infinity, _authBtnHeight),
      minimumSize: const Size(double.infinity, _authBtnHeight),
      maximumSize: const Size(double.infinity, _authBtnHeight),
      padding: EdgeInsets.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_authRadius),
      ),
    );
  }

  Widget _buildGoogleSignInButton(LocalizedStrings strings) {
    final visual = SizedBox(
      height: _authBtnHeight,
      width: double.infinity,
      child: ElevatedButton(
        style: _authButtonStyle(
          foreground: Colors.black,
          background: Colors.white,
        ),
        onPressed: () async {
          if (kIsWeb) return; // Clic real: capa GIS transparente encima.
          await _onGoogleSignInPressed();
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/google.png', height: 24, width: 24),
            const SizedBox(width: 10),
            Text(
              strings.get('googleSignIn') ?? 'Continue with Google',
              style: GoogleFonts.montserrat(fontSize: 16, color: Colors.black),
            ),
          ],
        ),
      ),
    );

    if (!kIsWeb) {
      return _constrainAuthControl(visual);
    }

    // Mismo look + GIS invisible encima (idToken). Misma altura que e-mail.
    return _constrainAuthControl(
      SizedBox(
        height: _authBtnHeight,
        width: double.infinity,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_authRadius),
          child: Stack(
            fit: StackFit.expand,
            children: [
              IgnorePointer(child: visual),
              Opacity(
                opacity: 0.02,
                child: buildGoogleSignInWebButton(minimumWidth: 400),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildManualLogInButton(LocalizedStrings strings) {
    return _constrainAuthControl(
      SizedBox(
        height: _authBtnHeight,
        width: double.infinity,
        child: ElevatedButton(
          style: _authButtonStyle(
            foreground: Colors.white,
            background: Colors.black,
          ),
          onPressed: () {
            Common().applyImmersive();
            if (mounted) {
              setState(() {
                _showSocialSignIn = !_showSocialSignIn;
              });
            }
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.email, color: Colors.white, size: 24),
              const SizedBox(width: 10),
              Text(
                strings.get('commonSignIn') ?? 'Log In',
                style: GoogleFonts.montserrat(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginAndRegisterButtons(
      BuildContext context, LocalizedStrings strings) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            textStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w600).copyWith(inherit: false),

            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_authRadius),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          ),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              FocusManager.instance.primaryFocus?.unfocus();
              logInHelper(strings);
            }
          },
          child: Text(strings.get('logIn') ?? 'Log In'),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[800],
            foregroundColor: Colors.white,
            textStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w600).copyWith(inherit: false),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_authRadius),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          ),
          onPressed: () {
            Common().applyImmersive();
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const SignIn()));
          },
          child: Text(strings.get('signIn') ?? 'Register'),
        ),
      ],
    );
  }

  Widget _buildToggleButton(LocalizedStrings strings) {
    return _constrainAuthControl(
      ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey[850],
        foregroundColor: Colors.white,
        textStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w600).copyWith(inherit: false),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_authRadius),
        ),
        minimumSize: const Size.fromHeight(48),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
      onPressed: () {
        Common().applyImmersive();
        if (mounted) {
          setState(() {
            _showSocialSignIn = !_showSocialSignIn;
          });
        }
      },
      child: Text(
        _showSocialSignIn
            ? (strings.get('commonSignIn') ?? "E-mail log-in")
            : (strings.get('backToSocialsLogin') ?? "Back to Social Logins"),
        textAlign: TextAlign.center,
      ),
    ),
    );
  }

  Widget _buildForgotPasswordButton(LocalizedStrings strings) {
    return Row(

      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          onPressed: () {
            Common().applyImmersive();
            showEmailPasswordDialog(context);
          },
          child: Text(strings.get('forgotPassword') ?? 'Forgot Password?',
              style: GoogleFonts.syncopate(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white)),
        )
      ],
    );
  }

  Widget _buildCreateNewAccountButton(LocalizedStrings strings) {
    return TextButton(
      onPressed: () {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const SignIn()));
      },
      child: Text(strings.get('noAccountRegister') ?? 'Don\'t have an account?',
          style: GoogleFonts.lato(
              decoration: TextDecoration.underline,
              decorationColor: Colors.blue,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.blue)),
    );
  }

  @override
  void didChangeMetrics() {
    if (!mounted) return;
    final bottomInset = View.of(context).viewInsets.bottom;
    final isVisible = bottomInset > 0.0;
    if (isVisible != _isKeyboardVisible) {
      if (mounted) {
        setState(() => _isKeyboardVisible = isVisible);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (kIsWeb) {
      _webGoogle = GoogleSignIn(
        clientId: Config.googleWebClientId,
        scopes: const <String>['openid', 'email', 'profile'],
      );
      _webGoogleSub = _webGoogle!.onCurrentUserChanged.listen(_onWebGoogleAccount);
      // Inicializa el plugin GIS (necesario antes del renderButton).
      _webGoogle!.isSignedIn();
    }
  }

  Widget _buildAnimatedWidget({
    required Widget child,
    required int index,
    required int total,
  }) {
    final delay = index / total;
    final duration = 0.4;
    final start = delay;
    final end = delay + duration;

    return FadeTransition(
      opacity: Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: widget.animationController,
        curve: Interval(start, end.clamp(0.0, 1.0), curve: Curves.easeOut),
      )),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.0, 0.3),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: widget.animationController,
          curve: Interval(start, end.clamp(0.0, 1.0), curve: Curves.easeOutCubic),
        )),
        child: ScaleTransition(
          scale: Tween<double>(
            begin: 0.8,
            end: 1.0,
          ).animate(CurvedAnimation(
            parent: widget.animationController,
            curve: Interval(start, end.clamp(0.0, 1.0), curve: Curves.easeOutBack),
          )),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = LocalizedStrings.of(context);
    final web = widget.webMode;
    final logoSize = web ? 96.0 : 200.0;
    final titleSize = web ? 26.0 : 38.0;

    return Form(
      key: _formKey,
      child: Column(
        // Sin esto el Column se estira a toda la altura del card y deja
        // un hueco vacío debajo del contenido.
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (!web)
            AnimatedOpacity(
              opacity: _isKeyboardVisible ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: _buildAnimatedWidget(
                index: 0,
                total: _showSocialSignIn ? 5 : 6,
                child: AutoSizeText(
                  "betrader.v1",
                  textAlign: TextAlign.center,
                  minFontSize: 20,
                  maxLines: 1,
                  style: GoogleFonts.syncopate(
                    fontWeight: FontWeight.w500,
                    fontSize: titleSize,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          else
            _buildAnimatedWidget(
              index: 0,
              total: _showSocialSignIn ? 5 : 6,
              child: Text(
                strings?.get('logIn') ?? 'Log in',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w700,
                  fontSize: titleSize,
                  color: Colors.white,
                ),
              ),
            ),
          SizedBox(height: web ? 20 : 20),
          _buildAnimatedWidget(
            index: 1,
            total: _showSocialSignIn ? 5 : 6,
            child: Image.asset(
              'assets/new_icon.png',
              width: logoSize,
              height: web ? logoSize : null,
              fit: BoxFit.contain,
            ),
          ),
          SizedBox(height: web ? 28 : 30),

          if (_showSocialSignIn) ...[
            _buildAnimatedWidget(
              index: 2,
              total: 5,
              child: _buildGoogleSignInButton(strings!),
            ),
            SizedBox(height: web ? 14 : 8),
            _buildAnimatedWidget(
              index: 3,
              total: 5,
              child: _buildManualLogInButton(strings),
            ),
            SizedBox(height: web ? 24 : 16),
            _buildAnimatedWidget(
              index: 4,
              total: 5,
              child: Column(
                children: [
                  _buildForgotPasswordButton(strings),
                  _buildCreateNewAccountButton(strings),
                ],
              ),
            ),
          ] else ...[
            _buildAnimatedWidget(
              index: 2,
              total: 6,
              child: _buildUsernameField(strings!),
            ),
            const SizedBox(height: 16),
            _buildAnimatedWidget(
              index: 3,
              total: 6,
              child: _buildPasswordField(strings),
            ),
            const SizedBox(height: 20),
            _buildAnimatedWidget(
              index: 4,
              total: 6,
              child: _buildLoginAndRegisterButtons(context, strings),
            ),
            const SizedBox(height: 16),
            _buildAnimatedWidget(
              index: 5,
              total: 6,
              child: Column(
                children: [
                  _buildToggleButton(strings),
                  const SizedBox(height: 16),
                  _buildForgotPasswordButton(strings),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _webGoogleSub?.cancel();
    _webGoogleSub = null;
    try {
      WidgetsBinding.instance.removeObserver(this);
    } catch (e) {
      // Ignorar errores si el observer ya fue removido
    }
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
