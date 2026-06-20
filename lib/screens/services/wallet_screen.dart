import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class WalletContent extends StatefulWidget {
  const WalletContent({super.key});

  @override
  State<WalletContent> createState() => _WalletContentState();
}

class _WalletContentState extends State<WalletContent> {
  Map<String, dynamic>? _wallet;
  List<Map<String, dynamic>> _transactions = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadWallet();
  }

  Future<void> _loadWallet() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;
    if (mounted) setState(() { _loading = true; _error = null; });
    try {
      // maybeSingle() returns null instead of throwing when row doesn't exist
      var wallet = await supabase
          .from('wallets')
          .select()
          .eq('user_id', uid)
          .maybeSingle();

      // Row doesn't exist yet — create it
      if (wallet == null) {
        wallet = await supabase
            .from('wallets')
            .insert({
              'user_id': uid,
              'balance': 0,
              'currency': 'BDT',
              'updated_at': DateTime.now().toIso8601String(),
            })
            .select()
            .single();
      }

      final txns = await supabase
          .from('wallet_transactions')
          .select()
          .eq('wallet_id', uid)
          .order('created_at', ascending: false)
          .limit(20);

      if (mounted) {
        setState(() {
          _wallet = wallet;
          _transactions = List<Map<String, dynamic>>.from(txns);
          _loading = false;
        });
      }
    } on PostgrestException catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.message; });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  double get _thisMonthSpent {
    final now = DateTime.now();
    return _transactions
        .where((t) {
          if (t['type'] != 'debit') return false;
          final dt = DateTime.tryParse(t['created_at']?.toString() ?? '');
          return dt != null && dt.year == now.year && dt.month == now.month;
        })
        .fold(0.0, (sum, t) => sum + (t['amount'] as num).toDouble());
  }

  Future<void> _showAddMoneySheet() async {
    final amountCtrl = TextEditingController();
    final pinCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        bool showPin = false;
        bool processing = false;

        return StatefulBuilder(builder: (ctx, setSt) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
                24, 0, 24, MediaQuery.of(ctx).viewInsets.bottom + 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderLight,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2136E).withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.account_balance_wallet_rounded,
                        color: Color(0xFFE2136E), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('bKash',
                        style:
                            AppTextStyles.h5.copyWith(color: AppColors.primary)),
                    Text('Add money to your wallet',
                        style: AppTextStyles.caption),
                  ]),
                ]),
                const SizedBox(height: 24),
                if (!showPin) ...[
                  Text('Enter Amount',
                      style: AppTextStyles.label
                          .copyWith(color: AppColors.primary)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: amountCtrl,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: AppTextStyles.priceLg
                        .copyWith(color: AppColors.primary, fontSize: 28),
                    decoration: InputDecoration(
                      prefixText: '৳ ',
                      prefixStyle: AppTextStyles.priceLg
                          .copyWith(color: AppColors.primary, fontSize: 28),
                      hintText: '0',
                      hintStyle: AppTextStyles.priceLg
                          .copyWith(color: AppColors.textMuted, fontSize: 28),
                      filled: true,
                      fillColor: const Color(0xFFF0F4F8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        final v = double.tryParse(amountCtrl.text);
                        if (v == null || v <= 0) return;
                        setSt(() => showPin = true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE2136E),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Add to my wallet', style: AppTextStyles.btn),
                    ),
                  ),
                ] else ...[
                  Text('Enter bKash PIN',
                      style: AppTextStyles.label
                          .copyWith(color: AppColors.primary)),
                  const SizedBox(height: 4),
                  Text(
                    'Adding ৳${amountCtrl.text} from bKash',
                    style:
                        AppTextStyles.caption.copyWith(color: AppColors.secondary),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: pinCtrl,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 4,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: AppTextStyles.h4
                        .copyWith(color: AppColors.primary, letterSpacing: 12),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '• • • •',
                      hintStyle: AppTextStyles.h5
                          .copyWith(color: AppColors.textMuted, letterSpacing: 8),
                      filled: true,
                      fillColor: const Color(0xFFF0F4F8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: processing
                          ? null
                          : () async {
                              if (pinCtrl.text != '1234') {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content:
                                      const Text('Incorrect PIN. Try again.'),
                                  backgroundColor: AppColors.error,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ));
                                pinCtrl.clear();
                                return;
                              }
                              final amount = double.parse(amountCtrl.text);
                              final messenger = ScaffoldMessenger.of(context);
                              final nav = Navigator.of(ctx);
                              setSt(() => processing = true);
                              try {
                                await supabase.rpc('wallet_add_money',
                                    params: {'p_amount': amount});
                                if (mounted) {
                                  nav.pop();
                                  await _loadWallet();
                                  messenger.showSnackBar(SnackBar(
                                    content: Text(
                                        '৳${amount.toStringAsFixed(0)} added to your wallet!'),
                                    backgroundColor: AppColors.success,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ));
                                }
                              } on PostgrestException catch (e) {
                                if (mounted) {
                                  messenger.showSnackBar(SnackBar(
                                    content: Text(e.message),
                                    backgroundColor: AppColors.error,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ));
                                }
                                setSt(() => processing = false);
                              } catch (_) {
                                setSt(() => processing = false);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE2136E),
                        disabledBackgroundColor:
                            const Color(0xFFE2136E).withValues(alpha: 0.65),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: processing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5),
                            )
                          : Text('Confirm', style: AppTextStyles.btn),
                    ),
                  ),
                ],
                const SizedBox(height: 4),
              ],
            ),
          );
        });
      },
    );
  }

  IconData _txIcon(Map<String, dynamic> t) {
    final desc = (t['description'] ?? '').toString().toLowerCase();
    if (desc.contains('bkash') || desc.contains('added')) {
      return Icons.add_circle_rounded;
    }
    if (desc.contains('hotel')) return Icons.hotel_rounded;
    if (desc.contains('flight') || desc.contains('air')) {
      return Icons.flight_takeoff_rounded;
    }
    if (desc.contains('cab') || desc.contains('taxi')) {
      return Icons.local_taxi_rounded;
    }
    if (t['type'] == 'credit') return Icons.add_circle_rounded;
    return Icons.shopping_bag_rounded;
  }

  String _fmtDate(String? raw) {
    if (raw == null) return '';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return '';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final balance = (_wallet?['balance'] as num?)?.toDouble() ?? 0.0;
    final points = (_wallet?['points'] as num?)?.toInt() ?? 0;
    final monthSpent = _thisMonthSpent;

    return RefreshIndicator(
      onRefresh: _loadWallet,
      color: AppColors.secondary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Balance card ─────────────────────────────────────────────
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.28),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'TravelMeta Wallet',
                          style: AppTextStyles.labelSm.copyWith(
                              color: Colors.white.withValues(alpha: 0.80)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'ACTIVE',
                            style: AppTextStyles.labelSm.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ]),
                  const SizedBox(height: 20),
                  Text(
                    'Total Balance',
                    style: AppTextStyles.bodySm.copyWith(
                        color: Colors.white.withValues(alpha: 0.70)),
                  ),
                  const SizedBox(height: 6),
                  if (_loading)
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  else if (_error != null)
                    Text(
                      'Error: $_error',
                      style: AppTextStyles.caption
                          .copyWith(color: Colors.white.withValues(alpha: 0.85)),
                    )
                  else
                    Text(
                      '৳ ${balance.toStringAsFixed(0)}',
                      style: AppTextStyles.priceLg
                          .copyWith(color: Colors.white, fontSize: 34),
                    ),
                  const SizedBox(height: 20),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Earned Points',
                                style: AppTextStyles.caption.copyWith(
                                    color:
                                        Colors.white.withValues(alpha: 0.70)),
                              ),
                              Text(
                                '$points pts',
                                style: AppTextStyles.label.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700),
                              ),
                            ]),
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'This Month Spent',
                                style: AppTextStyles.caption.copyWith(
                                    color:
                                        Colors.white.withValues(alpha: 0.70)),
                              ),
                              Text(
                                '৳ ${monthSpent.toStringAsFixed(0)}',
                                style: AppTextStyles.label.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700),
                              ),
                            ]),
                      ]),
                ],
              ),
            ),
            // ── Quick actions ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _QuickAction(
                    icon: Icons.add_rounded,
                    label: 'Add Money',
                    onTap: _showAddMoneySheet,
                  ),
                  _QuickAction(
                      icon: Icons.send_rounded,
                      label: 'Send',
                      onTap: () {}),
                  _QuickAction(
                      icon: Icons.qr_code_rounded,
                      label: 'Pay',
                      onTap: () {}),
                  _QuickAction(
                      icon: Icons.history_rounded,
                      label: 'History',
                      onTap: () {}),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // ── Transactions ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Recent Transactions',
                        style: AppTextStyles.h5
                            .copyWith(color: AppColors.primary)),
                    Text('See All',
                        style: AppTextStyles.label
                            .copyWith(color: AppColors.secondary)),
                  ]),
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: AppColors.secondary),
                ),
              )
            else if (_transactions.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(children: [
                    Icon(Icons.receipt_long_rounded,
                        size: 48,
                        color: AppColors.textMuted.withValues(alpha: 0.40)),
                    const SizedBox(height: 12),
                    Text('No transactions yet',
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.textMuted)),
                  ]),
                ),
              )
            else
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: 16,
                        offset: Offset(0, 4))
                  ],
                ),
                child: Column(
                  children: List.generate(_transactions.length, (i) {
                    final t = _transactions[i];
                    final isCredit = t['type'] == 'credit';
                    final amount = (t['amount'] as num).toDouble();
                    final desc = t['description']?.toString() ?? '';
                    return Column(children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        child: Row(children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: isCredit
                                  ? AppColors.success.withValues(alpha: 0.10)
                                  : AppColors.secondary
                                      .withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(_txIcon(t),
                                size: 19,
                                color: isCredit
                                    ? AppColors.success
                                    : AppColors.secondary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    desc,
                                    style: AppTextStyles.label.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                      _fmtDate(
                                          t['created_at']?.toString()),
                                      style: AppTextStyles.caption),
                                ]),
                          ),
                          Text(
                            '${isCredit ? '+' : '-'}৳ ${amount.toStringAsFixed(0)}',
                            style: AppTextStyles.priceSm.copyWith(
                                color: isCredit
                                    ? AppColors.success
                                    : AppColors.error),
                          ),
                        ]),
                      ),
                      if (i < _transactions.length - 1)
                        const Divider(
                            height: 1,
                            indent: 70,
                            color: AppColors.borderLight),
                    ]);
                  }),
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Column(children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.secondary, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 12),
          ),
        ]),
      );
}
