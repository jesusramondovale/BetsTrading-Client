import 'dart:async';
import 'dart:ui';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:betrader/services/auth_service.dart';
import 'package:betrader/locale/localized_texts.dart';
import 'package:betrader/helpers/common.dart';
import 'package:betrader/ui/signin_page.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart' hide Config;
import '../config/config.dart';
import '../helpers/preload_cache.dart';
import '../services/bets_service.dart';
import 'first_time_page.dart';
import 'layout_page.dart';
import 'markets_page.dart';
import '../main.dart' show navigatorKey;

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
  late AnimationController _blurController;
  late AnimationController _contentController;
  late AnimationController _dotsController;
  late AnimationController _pulseController;
  late Animation<double> _blurAnimation;
  late Animation<double> _pulseAnimation;
  Timer? _contentDelayTimer;
  bool _isLoading = false; // Bandera para controlar cuando mostrar la animación de carga

  @override
  void initState() {
    super.initState();
    
    // Controlador para el blur del fondo
    _blurController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
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

    _blurAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _blurController,
      curve: Curves.easeOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Iniciar animación del blur inmediatamente
    _blurController.forward();
    
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
    if (_blurController.isAnimating) {
      _blurController.stop();
    }
    if (_contentController.isAnimating) {
      _contentController.stop();
    }
    _blurController.reset();
    _contentController.reset();
    _dotsController.dispose();
    _pulseController.dispose();
    _blurController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0.0,
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          // Fondo principal intacto
          Positioned.fill(
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withValues(alpha: 0.1),
                BlendMode.darken,
              ),
              child: Image.asset(
                'assets/android12splash-clean.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(color: Colors.black);
                },
              ),
            ),
          ),
          // Blur con animación progresiva (ligero emborronamiento)
          AnimatedBuilder(
            animation: _blurAnimation,
            builder: (context, child) {
              if (!mounted) {
                return const SizedBox.shrink();
              }
              return Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 0.0 + (5.0 * _blurAnimation.value),
                    sigmaY: 0.0 + (5.0 * _blurAnimation.value),
                  ),
                  child: Container(color: Colors.transparent),
                ),
              );
            },
          ),
          // Contenido con animaciones escalonadas
          FadeTransition(
            opacity: _contentController,
            child: Center(
              child: SingleChildScrollView(
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  padding: const EdgeInsets.all(16.0),
                  child: LoginForm(
                    animationController: _contentController,
                    onLoadingStateChanged: (isLoading) {
                      if (mounted) {
                        setState(() {
                          _isLoading = isLoading;
                        });
                      }
                    },
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
  
  const LoginForm({
    super.key, 
    required this.animationController,
    required this.onLoadingStateChanged,
  });

  @override
  LoginFormState createState() => LoginFormState();
}

class LoginFormState extends State<LoginForm> with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showSocialSignIn = true;
  bool _isKeyboardVisible = false;


  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Handles the login process with email and password.
  ///
  /// Validates credentials, shows loading indicator, authenticates user,
  /// and navigates to main menu on success. Shows error messages on failure.
  ///
  /// [strings] Localized strings for UI messages.
  void logInHelper(LocalizedStrings strings) async {
    if (!mounted) return;
    showDialog(
      barrierColor: Colors.black.withAlpha(100),
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    final pass = _passwordController.text.trim();

    try {
      final result = await AuthService()
          .logIn(_usernameController.text.trim(), pass.toString());
      if (!mounted) return;
      Navigator.of(context).pop();

      if (result['success']) {
        String? id = await _storage.read(key: 'sessionToken');
        await BetsService().getUserInfo(id!);
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
        Common().showFloatingSnack(context, "${strings.get('welcome') ?? "Welcome"}  ${_usernameController.text.trim()}!");
        
        // Cargar TODOS los datos durante "Cargando..." antes de abandonar la vista
        await Future.wait([
          MarketsView.preloadAllMarketData(),
          PreloadCache.preloadAll(),
        ]);
        
        if (!mounted) return;
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => const MainMenuPage()));

      } else {
        if (!mounted) return;
        if ("null" == result['message'] || null == result['message']) {
          Common().showFloatingSnack(context,"Oops... ${strings.get("serverUnavailable")}", backgroundColor: Colors.red);
        } else {
          Common().showFloatingSnack(context,"Oops... ${strings.get(result['message'])}", backgroundColor: Colors.red);
        }
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      Common().popDialog("Error", "An unexpected error occurred.", context);
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
                      Common().showFloatingSnack(
                          context,
                          strings?.get('userOrEmailNotFound') ??
                              "Mail not found",
                          backgroundColor: Colors.red);

                    } else {
                      Common().showFloatingSnack(
                          context,
                          strings?.get('errorChangingPassword') ??
                              "Error changing password",
                          backgroundColor: Colors.red);
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
    return TextFormField(
      cursorColor: Colors.black,
      controller: _usernameController,
      decoration: InputDecoration(
          border: OutlineInputBorder(borderSide: BorderSide.none),
          labelText: "E-mail / ${strings.get('username') ?? 'User name'}",
          labelStyle: GoogleFonts.syncopate(fontSize: 25),
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
      style: GoogleFonts.montserrat(fontSize: 25),
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
    return TextFormField(
      cursorColor: Colors.black,
      controller: _passwordController,
      obscureText: true,
      decoration: InputDecoration(
          border: OutlineInputBorder(borderSide: BorderSide.none),
          labelText: (strings.get('password') ?? 'Password'),
          labelStyle: GoogleFonts.syncopate(fontSize: 25),
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
      style: GoogleFonts.montserrat(fontSize: 25),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return strings.get('pleaseEnterPassword') ??
              'Please enter your password';
        }
        return null;
      },
    );
  }

  Widget _buildGoogleSignInButton(LocalizedStrings strings) {
    return ElevatedButton(

      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.black,
        backgroundColor: Colors.white,
        minimumSize: const Size(50,50),
        maximumSize: Size(
            MediaQuery.of(context).size.width*0.85,
            50),
      ),
      onPressed: () async {
        Common().applyImmersive();
        if (!mounted) return;
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
          result = await AuthService().googleSignIn();
        } finally {
          if (mounted && Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        }
        if (!mounted) return;

        if (result != null && result == 0)
        {
          // Validated
          String? id = await _storage.read(key: 'sessionToken');
          await BetsService().getUserInfo(id!);
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
        String? username = await _storage.read(key: 'username');
        Common().showFloatingSnack(context, "${strings.get('welcome') ?? "Welcome"} $username!");
        
        // Cargar todos los datos mientras se muestra el login
        await MarketsView.preloadAllMarketData();
        
        if (!mounted) return;
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => const MainMenuPage()));
        }
        else if (result != null && result == 3) {
          if (!mounted) return;
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => const FirstTimePage()));
        }
        // First Google login
        else if (result != null && result == 2) {
          // Validated
          String? id = await _storage.read(key: 'sessionToken');
          await BetsService().getUserInfo(id!);
          if (!mounted) return;
          String? username = await _storage.read(key: 'username');
          Common().showFloatingSnack(context, "${strings.get('welcome') ?? "Welcome"} $username!");
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const FirstTimePage()));
        }
        else {
          if (!mounted) return;
          Common().showFloatingSnack(context, "Ooops... error!", backgroundColor: Colors.red);
          if (kDebugMode) {
            print("Error on Google LogIn.");
          }
        }
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/google.png', height: 30),
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Text(strings.get('googleSignIn') ?? 'Continue with Google',
                style:
                    GoogleFonts.montserrat(fontSize: 16, color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Widget _buildManualLogInButton(LocalizedStrings strings) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        minimumSize: const Size(50,50),
        maximumSize: Size(
            MediaQuery.of(context).size.width*0.85,
            50),
        padding: const EdgeInsets.symmetric(horizontal: 20),
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
          const Icon(Icons.email, color: Colors.white, size: 25),
          const SizedBox(width: 10),
          Text(
            strings.get('commonSignIn') ?? 'Log In',
            style: GoogleFonts.montserrat(fontSize: 16),
          ),
        ],
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

            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
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
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey[850],
        foregroundColor: Colors.white,
        textStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w600).copyWith(inherit: false),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
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

    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Texto que se oculta con el teclado
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
                  fontSize: 38,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildAnimatedWidget(
            index: 1,
            total: _showSocialSignIn ? 5 : 6,
            child: Image.asset('assets/new_icon.png', width: 200, fit: BoxFit.cover),
          ),
          const SizedBox(height: 30),

          if (_showSocialSignIn) ...[
            _buildAnimatedWidget(
              index: 2,
              total: 5,
              child: _buildGoogleSignInButton(strings!),
            ),
            const SizedBox(height: 8),
            _buildAnimatedWidget(
              index: 3,
              total: 5,
              child: _buildManualLogInButton(strings),
            ),
            const SizedBox(height: 16),
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
    // Remover observer ANTES de cualquier otra operación
    // No verificamos mounted aquí porque dispose() se llama cuando el widget ya no está montado
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
