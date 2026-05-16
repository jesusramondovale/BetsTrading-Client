import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import '../helpers/common.dart';
import '../locale/localized_texts.dart';
import 'package:crypto/crypto.dart';
import 'package:bech32/bech32.dart';
import 'package:base_x/base_x.dart';
import 'package:web3dart/web3dart.dart';

/// A page for managing withdrawal methods and payment addresses.
///
/// Allows users to add, edit, and verify withdrawal methods including
/// bank accounts, crypto wallets, and other payment options.
class RetireMethodsPage extends StatefulWidget {
  const RetireMethodsPage({super.key});

  @override
  State<RetireMethodsPage> createState() => _RetireMethodsPageState();
}

class _RetireMethodsPageState extends State<RetireMethodsPage> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final List<Map<String, dynamic>> _methods = [];
  bool _loading = true;
  bool _changed = false;
  Timer? _reloadTimer;

  /// Loads available withdrawal methods for the current user.
  ///
  /// Fetches methods from the server and displays their verification status.
  Future<void> _loadMethods() async {
    final userId = await _storage.read(key: 'sessionToken');
    if (userId == null) {
      setState(() {
        _methods.clear();
        _loading = false;
      });
      return;
    }

    try {
      final resp = await Common()
          .postRequestWrapper('Info', 'RetireOptions', {});

      if ((resp['statusCode'] ?? 500) == 200 && resp['body'] is List) {
        final list = <Map<String, dynamic>>[];
        for (final it in resp['body'] as List) {
          final type = (it['type'] ?? '').toString();
          final label = (it['label'] ?? '').toString();
          final verified = (it['verified'] ?? false) == true;
          final data = (it['data'] ?? {}) as Map<String, dynamic>;

          list.add({
            'id': it['id'],
            'type': type,
            'label': label,
            'verified': verified,
            'data': data,
          });
        }

        if (!mounted) return;
        setState(() {
          _methods
            ..clear()
            ..addAll(list);
          _loading = false;
        });
      } else {
        if (!mounted) return;
        setState(() => _loading = false);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _deleteMethod(String label) async {
    Common().vibrate();
    final userId = await _storage.read(key: 'sessionToken');
    if (userId == null) return;

    final resp = await Common().postRequestWrapper(
      'Info',
      'DeleteRetireOption',
      {'label': label},
    );

    if (resp['statusCode'] == 200) {
      setState(() {
        _methods.removeWhere((m) => m['id'] == label);
        _changed = true;
      });
      if (mounted) {
        Common().showFloatingSnack(
            context, LocalizedStrings.of(context)?.get('deleted') ?? 'Deleted');
      }
    } else {
      if (mounted) {
        Common().showErrorSnack(context);
      }
    }
  }

  Future<void> _addMethod() async {
    Common().vibrate();

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black.withValues(alpha: 0.75),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => const _NewMethodSheet(),
    );

    if (saved == true) {
      await _loadMethods();
      setState(() => _changed = true);
      if (mounted) {
        Common().showFloatingSnack(
          context,
          LocalizedStrings.of(context)?.get('methodAddedSuccessfully') ?? 'Method added successfully',
        );
      }
    }
  }

  Future<void> _showMethodDetails(BuildContext context, Map<String, dynamic> m) async {
    final strings = LocalizedStrings.of(context);
    final Color bgColor = Colors.grey[900]!;
    final Color textColor = Colors.white;

    final type = (m['type'] ?? '').toString();
    final label = (m['label'] ?? '').toString();
    final verified = (m['verified'] ?? false) == true;
    final data = (m['data'] ?? {}) as Map<String, dynamic>;

    // Construye campos según tipo
    final List<Widget> rows = [
      _kvRow(strings?.get('label') ?? 'Label', label, textColor),
      Divider(thickness: 0.1),
      _kvRow(strings?.get('type') ?? 'Type', _prettyType(type, strings), textColor),
      Divider(thickness: 0.1),
      _kvRow(strings?.get('verified') ?? 'Verified', verified ? (strings?.get('yes') ?? 'Yes') : (strings?.get('no') ?? 'No'), textColor),
      Divider(thickness: 0.1),
    ];

    if (type.toLowerCase() == 'bank') {
      final iban = (data['iban'] ?? '').toString();
      final holder = (data['holder'] ?? '').toString();
      final bic = (data['bic'] ?? '').toString();
      rows.addAll([
        _kvRow(strings?.get('iban') ?? 'IBAN', _mask(iban, keepTail: 4), textColor),
        if (holder.isNotEmpty) _kvRow(strings?.get('accountHolder') ?? 'Account holder', holder, textColor),
        if (bic.isNotEmpty) _kvRow(strings?.get('bicSwiftOptional') ?? 'BIC/SWIFT', bic, textColor),
      ]);
    } else if (type.toLowerCase() == 'paypal') {
      final email = (data['email'] ?? '').toString();
      rows.add(_kvRow(strings?.get('paypalEmail') ?? 'PayPal email', email, textColor));
    } else if (type.toLowerCase() == 'crypto') {
      final net = (data['network'] ?? '').toString();
      final addr = (data['address'] ?? '').toString();
      final memo = (data['memo'] ?? '').toString();
      rows.addAll([
        if (net.isNotEmpty) _kvRow(strings?.get('blockchainNetwork') ?? 'Network', net, textColor),
        if (addr.isNotEmpty) _kvRow(strings?.get('address') ?? 'Address', _mask(addr, keepTail: 6), textColor),
        if (memo.isNotEmpty) _kvRow(strings?.get('memoTagOptional') ?? 'Memo/Tag', memo, textColor),
      ]);
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: bgColor,
          insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: rows,
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
        );
      },
    );
  }

  Future<void> _onMethodTap(BuildContext context, Map<String, dynamic> method) async {
    final strings = LocalizedStrings.of(context);
    Common().vibrate();

    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.black.withValues(alpha: 0.9),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 6),
              Container(
                width: 44, height: 5,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.info_outline, color: Colors.white),
                title: Text(
                  strings?.get('viewDetails') ?? 'View details',
                  style: GoogleFonts.montserrat(color: Colors.white),
                ),
                onTap: () => Navigator.pop(context, 'details'),
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.redAccent),
                title: Text(
                  strings?.get('deleteMethod') ?? 'Delete method',
                  style: GoogleFonts.montserrat(color: Colors.redAccent),
                ),
                onTap: () => Navigator.pop(context, 'delete'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (action == 'details') {
      await _showMethodDetails(context, method);
    } else if (action == 'delete') {
      final ok = await _confirmDelete(context);
      if (ok == true) _deleteMethod(method['label']?.toString() ?? '');
    }
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final strings = LocalizedStrings.of(context);
    final Color bgColor = Colors.grey[900]!;
    final Color textColor = Colors.white;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) Navigator.pop(dialogContext, false);
          },
          child: AlertDialog(
            backgroundColor: bgColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              strings?.get('delete') ?? 'Delete',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 22,
                fontWeight: FontWeight.w300,
                color: textColor,
              ),
            ),
            content: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
              child: Text(
                strings?.get('confirmDelete') ?? 'Are you sure?',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w300,
                  color: textColor.withValues(alpha: .85),
                ),
              ),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey,
                  textStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w500),
                ),
                child: Text(strings?.get('cancel') ?? "Cancel"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: textColor,
                  textStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(strings?.get('delete') ?? "Delete"),
              ),
            ],
          ),
        );
      },
    );

    return result ?? false;
  }

  IconData _iconForType(String type) {
    switch (type.toLowerCase()) {
      case 'bank':
        return Icons.account_balance;
      case 'paypal':
        return Icons.paypal_rounded;
      case 'crypto':
        return Icons.currency_bitcoin;
      default:
        return Icons.account_balance;
    }
  }

  String _prettyType(String type, LocalizedStrings? strings) {
    switch (type.toLowerCase()) {
      case 'bank':
        return strings?.get('bankAccount') ?? 'Bank account';
      case 'paypal':
        return 'PayPal';
      case 'crypto':
        return strings?.get('blockchainNetwork') ?? 'Blockchain';
      default:
        return strings?.get('method') ?? 'Method';
    }
  }

  String _mask(String value, {int keepTail = 4}) {
    if (value.isEmpty) return '—';
    if (value.length <= keepTail) return value;
    final tail = value.substring(value.length - keepTail);
    return '•••• $tail';
  }

  Widget _kvRow(String k, String v, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              k,
              style: GoogleFonts.montserrat(
                color: textColor.withValues(alpha: .85),
                fontSize: 18,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 6,
            child: Text(
              v.isEmpty ? '—' : v,
              textAlign: TextAlign.right,
              style: GoogleFonts.roboto(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadMethods();
    _reloadTimer =
        Timer.periodic(const Duration(seconds: 6), (_) => _loadMethods());
  }

  @override
  void dispose() {
    _reloadTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = LocalizedStrings.of(context);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop(context, _changed);
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            strings?.get('withdrawMethods') ?? 'Withdraw methods',
            style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w300, fontSize: 30),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _changed),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: Colors.black54,
          foregroundColor: Colors.white,
          onPressed: _addMethod,
          icon: const Icon(Icons.add),
          label: Text(strings?.get('addMethod') ?? 'Add method'),
        ),
        body: Stack(
          children: [
            // Fondo
            Positioned.fill(
              child: Image.asset(
                'assets/android12splash.png',
                fit: BoxFit.cover,
              ),
            ),
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: Colors.transparent.withValues(alpha: 0.2),
                ),
              ),
            ),
            // Contenido
            Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                MediaQuery.of(context).padding.top + kToolbarHeight + 8,
                16,
                16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment
                    .stretch,
                children: [
                  Text(
                    strings?.get('manageWithdrawMethods') ??
                        'Manage your withdraw methods',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.roboto(
                      fontSize: 22,
                      color: Colors.white70,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  Expanded(
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : _methods.isEmpty
                            ? _EmptyState(onAdd: _addMethod)
                            : ListView.builder(
                                itemCount: _methods.length,
                                itemBuilder: (context, index) {
                                  final m = _methods[index];
                                  final type = (m['type'] ?? '').toString();
                                  final label = (m['label'] ?? '').toString();
                                  final verified =
                                      (m['verified'] ?? false) == true;

                                  final data =
                                      (m['data'] ?? {}) as Map<String, dynamic>;
                                  String subtitle = '';
                                  if (type.toLowerCase() == 'bank') {
                                    final iban =
                                        (data['iban'] ?? '').toString();
                                    subtitle = iban.isEmpty
                                        ? ''
                                        : 'IBAN • ${_mask(iban, keepTail: 4)}';
                                  } else if (type.toLowerCase() == 'paypal') {
                                    final mail =
                                        (data['email'] ?? '').toString();
                                    subtitle = mail;
                                  } else if (type.toLowerCase() == 'crypto') {
                                    final net =
                                        (data['network'] ?? '').toString();
                                    final addr =
                                        (data['address'] ?? '').toString();
                                    subtitle =
                                        '${net.isEmpty ? '—' : net} • ${_mask(addr, keepTail: 5)}';
                                  }

                                  return Card(
                                    color: Colors.white.withAlpha(22),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    clipBehavior: Clip.antiAlias, // <- recorta el ripple dentro de la tarjeta
                                    margin: const EdgeInsets.symmetric(vertical: 6),
                                    child: Dismissible(
                                      key: ValueKey(m['id'] ?? index),
                                      direction: DismissDirection.endToStart,
                                      background: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.red.withValues(alpha: .85),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        alignment: Alignment.centerRight,
                                        padding: const EdgeInsets.symmetric(horizontal: 20),
                                        child: const Icon(Icons.delete, color: Colors.white),
                                      ),
                                      confirmDismiss: (dir) async {
                                        return await _confirmDelete(context);
                                      },
                                      onDismissed: (_) => _deleteMethod(label),
                                      child: Material( // <- necesita Material para el InkWell
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(16), // <- mismo radio
                                          onTap: () => _onMethodTap(context, m), // <- abre bottom sheet
                                          child: ListTile(
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                            leading: CircleAvatar(
                                              radius: 22,
                                              backgroundColor: Colors.white.withAlpha(32),
                                              child: Icon(_iconForType(type), color: Colors.white),
                                            ),
                                            title: Text(
                                              label.isEmpty ? _prettyType(type, strings) : label,
                                              textAlign: TextAlign.left,
                                              style: GoogleFonts.montserrat(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w400,
                                                color: Colors.white,
                                              ),
                                            ),
                                            subtitle: subtitle.isEmpty
                                                ? null
                                                : Text(
                                              subtitle,
                                              textAlign: TextAlign.left,
                                              style: GoogleFonts.roboto(fontSize: 13, color: Colors.white70),
                                            ),
                                            trailing: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (verified)
                                                  const Icon(Icons.verified, color: Colors.greenAccent, size: 20),
                                                const SizedBox(width: 8),
                                                const Icon(Icons.more_vert, color: Colors.white70), // indicador de acciones
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// --------- NEW RETIRE METHOD SHEET CLASSES ------------

class _NewMethodSheet extends StatefulWidget {
  const _NewMethodSheet();

  @override
  State<_NewMethodSheet> createState() => _NewMethodSheetState();
}

class _NewMethodSheetState extends State<_NewMethodSheet> {
  static const _alphabetBTC = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';
  static const _alphabetXRP = 'rpshnaf39wBUDNEGHJKLM4PQRST7VWXYZ2bcdeCg65jkm8oFqi1tuvAxyz';

  final List<String> _networks = const ['BTC', 'XRP', 'ETH', 'RLUSD'];
  String? _selectedNetwork;
  String _type = 'bank';
  final _labelCtrl = TextEditingController();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  // BANK
  final _ibanCtrl = TextEditingController();
  final _holderCtrl = TextEditingController();
  final _bicCtrl = TextEditingController();
  final BaseXCodec _base58BTC = BaseXCodec(_alphabetBTC);
  final BaseXCodec _base58XRP = BaseXCodec(_alphabetXRP);

  // PAYPAL
  final _paypalEmailCtrl = TextEditingController();

  // CRYPTO
  final _addressCtrl = TextEditingController();
  final _memoCtrl = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;




  @override
  void dispose() {
    _labelCtrl.dispose();
    _ibanCtrl.dispose();
    _holderCtrl.dispose();
    _bicCtrl.dispose();
    _paypalEmailCtrl.dispose();
    _addressCtrl.dispose();
    _memoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = LocalizedStrings.of(context);

    return Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          top: 16,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Text(
                    strings?.get('addMethod') ?? 'Add method',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: 20,
                      fontWeight: FontWeight.w300,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _TypePicker(
                    value: _type,
                    onChanged: (v) => setState(() => _type = v),
                  ),
                  const SizedBox(height: 12),
                  _LabeledField(
                    label: strings?.get('label') ?? 'Label',
                    controller: _labelCtrl,
                    hint: _exampleLabelForType(_type),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? LocalizedStrings.of(context)!.get('thisFieldIsRequired') ?? "Field requried" : null,
                  ),
                  const SizedBox(height: 8),
                  if (_type == 'bank')
                    _bankFields()
                  else if (_type == 'paypal')
                    _paypalFields()
                  else
                    _cryptoFields(),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withAlpha(35),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(
                              strings?.get('save') ?? 'Save',
                              style: GoogleFonts.syncopate(
                                  fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                    ),
                  )
                ],
              ),
            ),
        ));
  }

  String _exampleLabelForType(String t) {
    switch (t) {
      case 'bank':
        return LocalizedStrings.of(context)!.get('exampleBankLabel') ?? "My BBVA account";
      case 'paypal':
        return LocalizedStrings.of(context)!.get('examplePayPalLabel') ?? "Main PayPal";
      case 'crypto':
        return LocalizedStrings.of(context)!.get('exampleCryptoLabel') ?? "USDT, BTC, XRP";
      default:
        return '';
    }
  }

  Widget _bankFields() {
    return Column(
      children: [
        _LabeledField(
          label: LocalizedStrings.of(context)!.get('iban') ?? 'IBAN',
          controller: _ibanCtrl,
          textInputType: TextInputType.text,
          hint: 'ESXX 1234 5678 9012 3456 7890',
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9 ]')),
            LengthLimitingTextInputFormatter(34 + 8),
            UpperCaseTextFormatter(),
            IbanSpacingFormatter(),
          ],
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return LocalizedStrings.of(context)!.get('thisFieldIsRequired') ?? 'Field required';
            }
            final iban = v.replaceAll(' ', '').toUpperCase();
            if (!RegExp(r'^[A-Z]{2}\d{2}[A-Z0-9]{1,30}$').hasMatch(iban)) {
              return LocalizedStrings.of(context)!.get('invalidIban') ?? 'Invalid IBAN';
            }
            if (!UpperCaseTextFormatter().isValidIban(iban)) return 'IBAN inválido';
            return null;
          },
        ),
        const SizedBox(height: 8),
        _LabeledField(
          label: LocalizedStrings.of(context)!.get('accountHolder') ?? "Account holder",
          controller: _holderCtrl,
          hint: LocalizedStrings.of(context)!.get('fullName') ?? "Full name",
          validator: (v) =>
              (v == null || v.trim().isEmpty) ?
                  LocalizedStrings.of(context)!.get('thisFieldIsRequired') ?? "Field requried": null,
        ),
        const SizedBox(height: 8),
        _LabeledField(
          label: LocalizedStrings.of(context)!.get('bicSwiftOptional') ?? "BIC/SWIFT (optional)",
          controller: _bicCtrl,
          hint: 'BBVAESMMXXX'
        ),
      ],
    );
  }

  Widget _paypalFields() {
    return _LabeledField(
      label: LocalizedStrings.of(context)!.get ('paypalEmail') ?? 'Email PayPal',
      controller: _paypalEmailCtrl,
      hint: 'user@mail.com',
      textInputType: TextInputType.emailAddress,
      validator: (v) {
        if (v == null || v.trim().isEmpty) return LocalizedStrings.of(context)!.get('thisFieldIsRequired') ?? "Field requried";
        final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v.trim());
        return ok ? null : LocalizedStrings.of(context)!.get('invalidEmail') ?? "Invalid email";
      },
    );
  }

  Widget _cryptoFields() {
    final strings = LocalizedStrings.of(context);

    return Column(
      children: [
        DropdownButtonFormField<String>(
          initialValue: _selectedNetwork,
          items: _networks.map((net) {
            return DropdownMenuItem(
              value: net,
              child: Text(net, style: const TextStyle(color: Colors.white)),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _selectedNetwork = value);
            // Si quieres revalidar al cambiar:
            // _formKey.currentState?.validate();
          },
          validator: (v) => (v == null || v.isEmpty)
              ? (strings?.get('thisFieldIsRequired') ?? 'Field required')
              : null,
          decoration: InputDecoration(
            labelText: strings?.get('blockchain') ?? 'Blockchain',
            labelStyle: const TextStyle(color: Colors.white70),
            filled: true,
            fillColor: Colors.white.withAlpha(18),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white24),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white54),
            ),
          ),
          dropdownColor: Colors.grey[900],
        ),
        const SizedBox(height: 8),
        _LabeledField(
          label: strings?.get('address') ?? 'Address',
          controller: _addressCtrl,
          hint: '0x..., rN2T..., bc1q..., etc.',
          validator: (v) => _validateAddress(_selectedNetwork ?? "", v ?? ''),
        ),
        const SizedBox(height: 8),
        _LabeledField(
          label: strings?.get('memoTagOptional') ?? "Memo/Tag (Optional)",
          controller: _memoCtrl,
          hint: "",
        ),
      ],
    );
  }

  String? _validateAddress(String? network, String address) {
    final strings = LocalizedStrings.of(context);
    if (network == null || network.isEmpty) {
      return strings?.get('thisFieldIsRequired') ?? "Field required";
    }
    if (address.trim().isEmpty) {
      return strings?.get('thisFieldIsRequired') ?? "Field required";
    }

    switch (network) {
      case 'BTC':
        return _isValidBTC(address) ? null : "BTC: ${LocalizedStrings.of(context)!.get('invalidAddress')
            ?? "Invalid address"}";
      case 'XRP':
      case 'RLUSD': // RLUSD uses XRPL
        return _isValidXRP(address) ? null : "XRPL: ${LocalizedStrings.of(context)!.get('invalidAddress')
            ?? "Invalid address"}";
      case 'ETH':
        return _isValidEthereumAddress(address) ? null : "ETH: ${LocalizedStrings.of(context)!.get('invalidAddress')
            ?? "Invalid address"} (ERC20)";
      default:
        return "Unsupported network";
    }
  }


// ---------- VALIDACIONES REALES -----------

  bool _isValidBTC(String address) {
    try {
      if (address.startsWith('bc1')) {
        // Bech32 (SegWit)
        final decoded = bech32.decode(address, 90);
        return decoded.hrp == 'bc' || decoded.hrp == 'tb';
      } else {
        // Base58Check
        return _base58CheckVerify(address, _base58BTC);
      }
    } catch (_) {
      return false;
    }
  }

  bool _isValidXRP(String address) {
    try {
      return _base58CheckVerify(address, _base58XRP);
    } catch (_) {
      return false;
    }
  }

  bool _isValidEthereumAddress(String address) {
    try {
      EthereumAddress.fromHex(address); // Lanza excepción si es inválido
      return true;
    } catch (_) {
      return false;
    }
  }


// ---------- HELPERS -----------

  bool _base58CheckVerify(String addr, BaseXCodec codec) {
    final decoded = codec.decode(addr);
    if (decoded.length < 4) return false;

    final payload = decoded.sublist(0, decoded.length - 4);
    final checksum = decoded.sublist(decoded.length - 4);

    final hash1 = sha256.convert(payload).bytes;
    final hash2 = sha256.convert(hash1).bytes;
    final calcChecksum = hash2.sublist(0, 4);

    return _listEquals(checksum, calcChecksum);
  }

  bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    String? userId = await _storage.read(key: 'sessionToken') ?? "none";
    final type = _type;
    final label = _labelCtrl.text.trim();

    Map<String, dynamic> data;
    if (type == 'bank') {
      data = {
        'userId': userId,
        'label': label,
        'iban': _ibanCtrl.text.trim(),
        'holder': _holderCtrl.text.trim(),
        'bic': _bicCtrl.text.trim(),
      };
      final response = await Common().postRequestWrapper("Info", "AddBankRetireMethod", data);
      if (response['statusCode'] == 200) {
        Common().showFloatingSnack(context, LocalizedStrings.of(context)!.get('methodAddedSuccessfully') ?? "Method added successfully");
        Navigator.pop(context,true);
      }
      else{
        Common().showErrorSnack(context);
      }
    }

    else if (type == 'paypal') {
      data = {
        'userId': userId,
        'label': label,
        'email': _paypalEmailCtrl.text.trim(),
      };
      final response = await Common().postRequestWrapper("Info", "AddPaypalRetireMethod", data);
      if (response['statusCode'] == 200) {
        Common().showFloatingSnack(context, LocalizedStrings.of(context)!.get('methodAddedSuccessfully') ?? "Method added successfully");
        Navigator.pop(context,true);
      }
      else{
        Common().showErrorSnack(context);
      }
    }

    else if (type == "crypto"){
      data = {
        'userId': userId,
        'label': label,
        'network': _selectedNetwork,
        'address': _addressCtrl.text.trim(),
        'memo': _memoCtrl.text.trim(),
      };
      final response = await Common().postRequestWrapper("Info", "AddCryptoRetireMethod", data);
      if (response['statusCode'] == 200) {
        Common().showFloatingSnack(context, LocalizedStrings.of(context)!.get('methodAddedSuccessfully') ?? "Method added successfully");
        Navigator.pop(context, true);
      }
      else{
        Common().showErrorSnack(context);
      }
    }


  }
}

class _TypePicker extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _TypePicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget chip(String v, String text, IconData icon) {
      final selected = v == value;
      return ChoiceChip(
        selected: selected,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 6),
            Text(text),
          ],
        ),
        onSelected: (_) => onChanged(v),
        labelStyle: GoogleFonts.roboto(
          color: Colors.white,
          fontSize: 13,
        ),
        backgroundColor: Colors.white12,
        selectedColor: Colors.white24,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      );
    }

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        chip('bank', 'Banco', Icons.account_balance),
        chip('paypal', 'PayPal', Icons.paypal_sharp),
        chip('crypto', 'Crypto', Icons.currency_bitcoin),
      ],
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputType? textInputType;
  final List<TextInputFormatter>? inputFormatters;


  const _LabeledField({
    required this.label,
    required this.controller,
    this.hint,
    this.validator,
    this.textInputType,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 13,
            fontWeight: FontWeight.w300,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: textInputType,
          style: const TextStyle(color: Colors.white),
          validator: validator,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white54),
            filled: true,
            fillColor: Colors.white.withAlpha(18),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white24),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white54),
            ),
          ),
        ),
      ],
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }

  bool isValidIban(String iban) {
    final s = (iban.substring(4) + iban.substring(0, 4))
        .toUpperCase()
        .replaceAllMapped(RegExp(r'[A-Z]'), (m) => (m[0]!.codeUnitAt(0) - 55).toString());
    // MOD 97 grande sin desbordar
    int mod = 0;
    for (int i = 0; i < s.length; i++) {
      final c = s.codeUnitAt(i) - 48; // '0' -> 0
      mod = (mod * 10 + c) % 97;
    }
    return mod == 1;
  }
}

class IbanSpacingFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {

    String digitsOnly = newValue.text.replaceAll(' ', '').toUpperCase();

    final buffer = StringBuffer();
    for (int i = 0; i < digitsOnly.length; i++) {
      buffer.write(digitsOnly[i]);
      if ((i + 1) % 4 == 0 && i + 1 != digitsOnly.length) {
        buffer.write(' ');
      }
    }

    final formatted = buffer.toString();

    // Calculamos nueva posición del cursor
    int cursorPos = formatted.length;
    if (formatted.endsWith(' ') && oldValue.text.length > newValue.text.length) {
      cursorPos--;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursorPos),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final strings = LocalizedStrings.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_wallet_outlined,
              size: 56, color: Colors.white.withValues(alpha: .85)),
          const SizedBox(height: 12),
          Text(
            strings?.get('noMethods') ?? 'No withdraw methods yet',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w300,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            strings?.get('addFirstMethod') ?? 'Add your first method',
            textAlign: TextAlign.center,
            style: GoogleFonts.roboto(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: Text(strings?.get('addMethod') ?? 'Add method'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withAlpha(30),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          )
        ],
      ),
    );
  }
}
