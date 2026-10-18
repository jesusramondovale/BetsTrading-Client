import 'dart:typed_data';

import 'package:betrader/locale/localized_texts.dart';
import 'package:betrader/ui/layout_page.dart';
import 'package:betrader/ui/notifications_page.dart';
import 'package:betrader/ui/settings_view.dart';
import 'package:betrader/ui/store_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../helpers/common.dart';

/// Breakpoint ancho para shell tipo web (menú superior).
const double kWebShellBreakpoint = 900;

/// Contenido centrado estilo Polymarket.
const double kWebContentMaxWidth = 1100;

/// Paneles secundarios (ajustes, tienda, historiales).
const double kWebPanelMaxWidth = 720;

/// Layouts pensados para móvil (premios, perfiles) en desktop.
const double kWebPhoneMaxWidth = 520;

/// Formularios / listas de acciones (botones de tienda, etc.).
const double kWebFormMaxWidth = 480;

/// Diálogos y modales en web.
const double kWebDialogMaxWidth = 440;

/// `true` en Flutter Web o en pantallas anchas.
bool useWebShell(BuildContext context) {
  if (kIsWeb) return true;
  return MediaQuery.sizeOf(context).width >= kWebShellBreakpoint;
}

/// Envuelve [child] en un contenedor centrado con ancho máximo en shell web.
Widget webConstrainedBody({
  required BuildContext context,
  required Widget child,
  double maxWidth = kWebContentMaxWidth,
}) {
  if (!useWebShell(context)) return child;
  return Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}

/// Ancho estrecho para paneles/listas que no deben estirarse en desktop.
Widget webNarrowBody({
  required BuildContext context,
  required Widget child,
  double maxWidth = kWebPanelMaxWidth,
}) {
  return webConstrainedBody(
    context: context,
    child: child,
    maxWidth: maxWidth,
  );
}

/// Marco para diálogos/modales: centra y limita ancho (evita estirar a full-bleed).
Widget webDialogFrame({
  required Widget child,
  double maxWidth = kWebDialogMaxWidth,
  Alignment alignment = Alignment.center,
  EdgeInsetsGeometry padding =
      const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
}) {
  return SafeArea(
    child: Align(
      alignment: alignment,
      child: Padding(
        padding: padding,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Material(
            type: MaterialType.transparency,
            child: child,
          ),
        ),
      ),
    ),
  );
}

/// Barra superior estilo trading web (logo, secciones, saldo, settings, perfil).
class WebTopNavBar extends StatefulWidget {
  final MainMenuPageController controller;
  final MainMenuBottomNavKeys bottomNavKeys;
  final Uint8List? profilePicBytes;
  final String username;
  final VoidCallback? onProfileSelected;

  const WebTopNavBar({
    super.key,
    required this.controller,
    required this.bottomNavKeys,
    this.profilePicBytes,
    this.username = '',
    this.onProfileSelected,
  });

  @override
  State<WebTopNavBar> createState() => _WebTopNavBarState();
}

class _WebTopNavBarState extends State<WebTopNavBar> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  double _userPoints = 0;
  bool _isLoadingStore = false;

  @override
  void initState() {
    super.initState();
    _loadPoints();
  }

  Future<void> _loadPoints() async {
    final p = await _storage.read(key: 'points') ?? '0';
    if (!mounted) return;
    setState(() => _userPoints = double.tryParse(p) ?? 0);
  }

  void _go(int index) {
    widget.controller.updateIndex(index);
    if (index == 4) widget.onProfileSelected?.call();
  }

  Future<void> _openStore() async {
    if (_isLoadingStore) return;
    Common().vibrate();
    setState(() => _isLoadingStore = true);
    try {
      final preloadedData = await StorePage.preloadStoreData();
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StorePage(
            preloadedBuyOptions:
                preloadedData['buyOptions'] as List<Map<String, dynamic>>,
            preloadedAdRewardOptions:
                preloadedData['adRewardOptions'] as List<Map<String, dynamic>>,
            preloadedCurrency: preloadedData['currency'] as String,
            preloadedRewardPrize: preloadedData['rewardPrize'] as int,
          ),
        ),
      );
      if (!mounted) return;
      exchangePageKey.currentState?.loadData();
      await _loadPoints();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar la tienda: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingStore = false);
    }
  }

  void _openSettings() {
    Common().vibrate();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsView(
          onPersonalInfoTap: () {
            Navigator.pop(context);
            _go(4);
          },
          onShowNotifications: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => NotificationsPage(
                  onBack: () => Navigator.pop(context),
                ),
              ),
            );
          },
          controller: widget.controller,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = LocalizedStrings.of(context);

    return Material(
      color: Colors.black.withValues(alpha: 0.85),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: ValueListenableBuilder<int>(
          valueListenable: widget.controller.selectedIndexNotifier,
          builder: (context, index, _) {
            return Row(
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
                const SizedBox(width: 28),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _NavLink(
                          key: widget.bottomNavKeys.home,
                          label: strings?.get('home') ?? 'Home',
                          selected: index == 0,
                          onTap: () => _go(0),
                        ),
                        _NavLink(
                          key: widget.bottomNavKeys.markets,
                          label: strings?.get('liveMarkets') ?? 'Markets',
                          selected: index == 2,
                          onTap: () => _go(2),
                        ),
                        _NavLink(
                          key: widget.bottomNavKeys.exchange,
                          label: 'Exchange',
                          selected: index == 1,
                          onTap: () => _go(1),
                        ),
                        _NavLink(
                          key: widget.bottomNavKeys.awards,
                          label: strings?.get('awards') ?? 'Awards',
                          selected: index == 3,
                          onTap: () => _go(3),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  tooltip: strings?.get('settings') ?? 'Settings',
                  icon: const Icon(Icons.settings, color: Colors.white70, size: 22),
                  onPressed: _openSettings,
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: _openStore,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade900,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: _isLoadingStore
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset('assets/coin.png', width: 20, height: 20),
                              const SizedBox(width: 6),
                              Text(
                                NumberFormat.compact().format(_userPoints),
                                style: GoogleFonts.montserrat(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                KeyedSubtree(
                  key: widget.bottomNavKeys.profile,
                  child: InkWell(
                    onTap: () => _go(4),
                    borderRadius: BorderRadius.circular(20),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        widget.profilePicBytes != null
                            ? CircleAvatar(
                                backgroundImage: MemoryImage(widget.profilePicBytes!),
                                radius: 16,
                              )
                            : const Icon(
                                Icons.account_circle_outlined,
                                color: Colors.white70,
                                size: 32,
                              ),
                        if (widget.username.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            widget.username,
                            style: GoogleFonts.montserrat(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _NavLink extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavLink({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: selected ? Colors.white : Colors.white54,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: 2,
              width: selected ? 28 : 0,
              color: Colors.greenAccent,
            ),
          ],
        ),
      ),
    );
  }
}
