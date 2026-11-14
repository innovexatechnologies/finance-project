import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/widgets/app_empty_state.dart';
import 'package:link_vibe/feature/admin/models/platform_payment_method_model.dart';
import 'package:link_vibe/feature/admin/presentation/screens/admin_login_screen.dart';
import 'package:link_vibe/feature/admin/presentation/widgets/admin_sidebar.dart';
import 'package:link_vibe/feature/admin/presentation/widgets/admin_top_navbar.dart';
import 'package:link_vibe/feature/admin/services/admin_auth_service.dart';
import 'package:link_vibe/feature/admin/services/admin_payment_service.dart';

/// Enterprise Admin Screen for Platform Custodial Escrow Payment Methods
/// Allows Admin to manage Bank Accounts, JazzCash, EasyPaisa, and NayaPay accounts.
class AdminPaymentMethodsScreen extends StatefulWidget {
  const AdminPaymentMethodsScreen({super.key});

  @override
  State<AdminPaymentMethodsScreen> createState() =>
      _AdminPaymentMethodsScreenState();
}

class _AdminPaymentMethodsScreenState extends State<AdminPaymentMethodsScreen> {
  final AdminPaymentService _paymentService = AdminPaymentService();
  final AdminAuthService _authService = AdminAuthService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String _searchQuery = '';
  String _selectedFilter = 'All';
  bool _isSidebarCollapsed = false;

  final List<String> _filters = [
    'All',
    'Active Only',
    'Inactive Only',
    PlatformPaymentMethodType.bankAccount,
    PlatformPaymentMethodType.jazzCash,
    PlatformPaymentMethodType.easyPaisa,
    PlatformPaymentMethodType.nayapay,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _paymentService.loadPaymentMethods();
    });
  }

  void _showFeedback(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _handleSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AppColors.error),
            SizedBox(width: 10),
            Text('Sign Out Console'),
          ],
        ),
        content: const Text(
          'Are you sure you want to end your active administrative session? Session credentials will be invalidated securely.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _authService.logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
        (route) => false,
      );
    }
  }

  void _onRouteSelected(String routeId) {
    AdminSidebar.navigateToRoute(
      context,
      scaffoldKey: _scaffoldKey,
      currentRouteId: 'settings',
      targetRouteId: routeId,
    );
  }

  List<PlatformPaymentMethodModel> _filterMethods(
      List<PlatformPaymentMethodModel> all) {
    return all.where((m) {
      // Filter by selection
      if (_selectedFilter == 'Active Only' && !m.isActive) return false;
      if (_selectedFilter == 'Inactive Only' && m.isActive) return false;
      if (_selectedFilter == PlatformPaymentMethodType.bankAccount &&
          m.methodType != PlatformPaymentMethodType.bankAccount) {
        return false;
      }
      if (_selectedFilter == PlatformPaymentMethodType.jazzCash &&
          m.methodType != PlatformPaymentMethodType.jazzCash) {
        return false;
      }
      if (_selectedFilter == PlatformPaymentMethodType.easyPaisa &&
          m.methodType != PlatformPaymentMethodType.easyPaisa) {
        return false;
      }
      if (_selectedFilter == PlatformPaymentMethodType.nayapay &&
          m.methodType != PlatformPaymentMethodType.nayapay) {
        return false;
      }

      // Filter by search query
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final inBank = m.bankOrWalletName.toLowerCase().contains(q);
        final inTitle = m.accountTitle.toLowerCase().contains(q);
        final inNumber = m.accountNumber.toLowerCase().contains(q);
        final inIban = m.iban?.toLowerCase().contains(q) ?? false;
        final inType = m.methodType.toLowerCase().contains(q);
        if (!inBank && !inTitle && !inNumber && !inIban && !inType) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    _showFeedback('$label copied to clipboard');
  }

  Future<void> _confirmDelete(PlatformPaymentMethodModel method) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.errorBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.error, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'Delete Account',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently remove "${method.bankOrWalletName} - ${method.accountTitle}" from platform escrow methods? This account will no longer be visible to companies.',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Delete',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final ok = await _paymentService.deletePaymentMethod(method.id);
      if (ok) {
        _showFeedback('Platform payment account deleted successfully.');
      } else {
        _showFeedback(
          _paymentService.lastError ?? 'Failed to delete payment account.',
          isError: true,
        );
      }
    }
  }

  void _showAddEditModal({PlatformPaymentMethodModel? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddEditMethodSheet(
        existing: existing,
        onSave: (method) async {
          if (existing != null) {
            final ok = await _paymentService.updatePaymentMethod(method);
            if (ok) {
              _showFeedback('Payment account updated successfully.');
            } else {
              _showFeedback(
                _paymentService.lastError ?? 'Failed to update account.',
                isError: true,
              );
            }
          } else {
            final ok = await _paymentService.addPaymentMethod(method);
            if (ok) {
              _showFeedback('New platform payment account added.');
            } else {
              _showFeedback(
                _paymentService.lastError ?? 'Failed to add payment account.',
                isError: true,
              );
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 960;

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: AppColors.background,
          endDrawer: isDesktop
              ? null
              : Drawer(
                  backgroundColor: AppColors.darkNavy,
                  child: AdminSidebar(
                    activeRouteId: 'settings',
                    onRouteSelected: _onRouteSelected,
                    onSignOut: _handleSignOut,
                    isCollapsed: false,
                  ),
                ),
          body: Row(
            children: [
              if (isDesktop)
                AdminSidebar(
                  activeRouteId: 'settings',
                  onRouteSelected: _onRouteSelected,
                  onSignOut: _handleSignOut,
                  isCollapsed: _isSidebarCollapsed,
                  onToggleCollapse: () {
                    setState(() => _isSidebarCollapsed = !_isSidebarCollapsed);
                  },
                ),
              Expanded(
                child: Column(
                  children: [
                    AdminTopNavbar(
                      pageTitle: 'Platform Escrow Accounts',
                      breadcrumb: 'Escrow & Finance Hub',
                      onOpenDrawer: () =>
                          _scaffoldKey.currentState?.openEndDrawer(),
                      onSignOut: _handleSignOut,
                      onSearch: (query) {
                        setState(() => _searchQuery = query);
                      },
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () => _paymentService.loadPaymentMethods(
                            forceRefresh: true),
                        color: AppColors.primary,
                        child: ValueListenableBuilder<bool>(
                          valueListenable: _paymentService.isLoadingNotifier,
                          builder: (context, isLoading, _) {
                            return ValueListenableBuilder<
                                List<PlatformPaymentMethodModel>>(
                              valueListenable:
                                  _paymentService.paymentMethodsNotifier,
                              builder: (context, allMethods, _) {
                                final filtered = _filterMethods(allMethods);
                                final totalCount = allMethods.length;
                                final activeCount =
                                    allMethods.where((m) => m.isActive).length;
                                final inactiveCount = totalCount - activeCount;

                                return ListView(
                                  padding: const EdgeInsets.all(24),
                                  children: [
                                    _buildHeaderBanner(isDesktop),
                                    const SizedBox(height: 20),
                                    _buildMetricsRow(
                                      isDesktop: isDesktop,
                                      total: totalCount,
                                      active: activeCount,
                                      inactive: inactiveCount,
                                    ),
                                    const SizedBox(height: 24),
                                    _buildFilterRow(isDesktop),
                                    const SizedBox(height: 18),
                                    if (isLoading && allMethods.isEmpty)
                                      const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(40),
                                          child: CircularProgressIndicator(
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      )
                                    else if (filtered.isEmpty)
                                      _buildEmptyState()
                                    else
                                      _buildCardsGrid(
                                        filtered,
                                        isDesktop: isDesktop,
                                      ),
                                    const SizedBox(height: 40),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 4,
            icon: const Icon(Icons.add_rounded),
            label: Text(
              'Add Payment Method',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            onPressed: () => _showAddEditModal(),
          ),
        );
      },
    );
  }

  Widget _buildHeaderBanner(bool isDesktop) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Custodial Escrow Platform Accounts',
                      style: GoogleFonts.poppins(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Companies deposit upfront project funding directly into these accounts. Active accounts are shown on Company checkout screens. Funds remain locked in platform escrow until student delivery approval.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.9),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              if (isDesktop) ...[
                const SizedBox(width: 20),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.deepNavy,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                  label: Text(
                    'Add Method',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  onPressed: () => _showAddEditModal(),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsRow({
    required bool isDesktop,
    required int total,
    required int active,
    required int inactive,
  }) {
    final cards = [
      _buildMetricTile(
        title: 'Total Methods',
        value: '$total',
        subtitle: 'Configured accounts',
        icon: Icons.account_balance_wallet_outlined,
        color: AppColors.primary,
        bgColor: AppColors.lightIceBlue,
      ),
      _buildMetricTile(
        title: 'Active Accounts',
        value: '$active',
        subtitle: 'Shown to companies',
        icon: Icons.check_circle_outline_rounded,
        color: AppColors.success,
        bgColor: AppColors.successBg,
      ),
      _buildMetricTile(
        title: 'Inactive Accounts',
        value: '$inactive',
        subtitle: 'Hidden from checkout',
        icon: Icons.pause_circle_outline_rounded,
        color: AppColors.warning,
        bgColor: AppColors.warningBg,
      ),
      _buildMetricTile(
        title: 'Escrow Security',
        value: 'Protected',
        subtitle: 'Company-to-Admin-to-Student',
        icon: Icons.verified_user_outlined,
        color: AppColors.teal,
        bgColor: AppColors.lightAqua,
      ),
    ];

    if (isDesktop) {
      return Row(
        children: cards
            .map((c) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: c,
                  ),
                ))
            .toList(),
      );
    } else {
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: cards
            .map((c) => SizedBox(
                  width: double.infinity,
                  child: c,
                ))
            .toList(),
      );
    }
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.softShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkNavy,
                  ),
                ),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow(bool isDesktop) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.filter_list_rounded,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                'Filter Methods:',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkNavy,
                ),
              ),
            ],
          ),
          ..._filters.map((filter) {
            final isSelected = _selectedFilter == filter;
            return ChoiceChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedFilter = filter);
                }
              },
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surfaceAlt,
              labelStyle: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.border,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCardsGrid(
    List<PlatformPaymentMethodModel> methods, {
    required bool isDesktop,
  }) {
    if (isDesktop && methods.length > 1) {
      final leftColumn = <PlatformPaymentMethodModel>[];
      final rightColumn = <PlatformPaymentMethodModel>[];
      for (int i = 0; i < methods.length; i++) {
        if (i.isEven) {
          leftColumn.add(methods[i]);
        } else {
          rightColumn.add(methods[i]);
        }
      }

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              children: leftColumn
                  .map((m) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildPaymentMethodCard(m),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              children: rightColumn
                  .map((m) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildPaymentMethodCard(m),
                      ))
                  .toList(),
            ),
          ),
        ],
      );
    } else {
      return Column(
        children: methods
            .map((m) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildPaymentMethodCard(m),
                ))
            .toList(),
      );
    }
  }

  Widget _buildPaymentMethodCard(PlatformPaymentMethodModel method) {
    final brandColor = method.brandColor;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: method.isActive
              ? brandColor.withValues(alpha: 0.3)
              : AppColors.border,
          width: method.isActive ? 1.5 : 1,
        ),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Header Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: brandColor.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(15),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: brandColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(method.icon, color: brandColor, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              method.bankOrWalletName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkNavy,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: brandColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                method.methodType,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: brandColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Active / Inactive Switch
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      method.isActive ? 'Active' : 'Inactive',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: method.isActive
                            ? AppColors.success
                            : AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Switch.adaptive(
                      value: method.isActive,
                      activeThumbColor: AppColors.success,
                      activeTrackColor: AppColors.successBg,
                      onChanged: (val) async {
                        final ok = await _paymentService.toggleMethodStatus(
                          method.id,
                          val,
                        );
                        if (ok) {
                          _showFeedback(
                            val
                                ? '${method.bankOrWalletName} marked Active (Visible to Companies)'
                                : '${method.bankOrWalletName} marked Inactive (Hidden from Checkout)',
                          );
                        } else {
                          _showFeedback(
                            _paymentService.lastError ??
                                'Failed to toggle status.',
                            isError: true,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Details Body
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Account Title
                _buildFieldDetail(
                  icon: Icons.person_outline_rounded,
                  label: 'Account Title',
                  value: method.accountTitle,
                  onCopy: () => _copyToClipboard(
                    method.accountTitle,
                    'Account Title',
                  ),
                ),
                const SizedBox(height: 12),

                // Account / Mobile Number
                _buildFieldDetail(
                  icon: Icons.tag_rounded,
                  label: method.methodType ==
                          PlatformPaymentMethodType.bankAccount
                      ? 'Account Number'
                      : 'Mobile Wallet Number',
                  value: method.accountNumber,
                  isMonospace: true,
                  onCopy: () => _copyToClipboard(
                    method.accountNumber,
                    'Account Number',
                  ),
                ),

                // Optional IBAN
                if (method.iban != null &&
                    method.iban!.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildFieldDetail(
                    icon: Icons.qr_code_2_rounded,
                    label: 'IBAN',
                    value: method.iban!,
                    isMonospace: true,
                    onCopy: () => _copyToClipboard(method.iban!, 'IBAN'),
                  ),
                ],

                // Optional Instructions
                if (method.instructions != null &&
                    method.instructions!.trim().isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Deposit Instructions (Shown to Company)',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                method.instructions!,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.textPrimary,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                const Divider(color: AppColors.border, height: 1),
                const SizedBox(height: 12),

                // Action Buttons Row (Edit & Delete)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            method.isActive
                                ? Icons.visibility_rounded
                                : Icons.visibility_off_rounded,
                            size: 14,
                            color: method.isActive
                                ? AppColors.success
                                : AppColors.textMuted,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              method.isActive
                                  ? 'Visible during checkout'
                                  : 'Hidden from checkout',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                color: method.isActive
                                    ? AppColors.success
                                    : AppColors.textMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Delete Method',
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: AppColors.error,
                            size: 20,
                          ),
                          onPressed: () => _confirmDelete(method),
                        ),
                        const SizedBox(width: 4),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.edit_outlined, size: 15),
                          label: Text(
                            'Edit',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 12.5,
                            ),
                          ),
                          onPressed: () =>
                              _showAddEditModal(existing: method),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldDetail({
    required IconData icon,
    required String label,
    required String value,
    bool isMonospace = false,
    VoidCallback? onCopy,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: isMonospace
                    ? GoogleFonts.jetBrainsMono(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkNavy,
                        letterSpacing: 0.4,
                      )
                    : GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkNavy,
                      ),
              ),
            ],
          ),
        ),
        if (onCopy != null)
          InkWell(
            onTap: onCopy,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.copy_rounded, size: 12, color: AppColors.primary),
                  SizedBox(width: 4),
                  Text(
                    'Copy',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const AppEmptyState(
            title: 'No Escrow Payment Methods Found',
            subtitle:
                'No accounts match the selected filter or search query. Click below to add a new bank or wallet method.',
            icon: Icons.account_balance_wallet_outlined,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Payment Method'),
            onPressed: () => _showAddEditModal(),
          ),
        ],
      ),
    );
  }
}

/// Bottom Sheet / Modal Dialog for adding or updating a platform payment method.
class _AddEditMethodSheet extends StatefulWidget {
  final PlatformPaymentMethodModel? existing;
  final ValueChanged<PlatformPaymentMethodModel> onSave;

  const _AddEditMethodSheet({
    this.existing,
    required this.onSave,
  });

  @override
  State<_AddEditMethodSheet> createState() => _AddEditMethodSheetState();
}

class _AddEditMethodSheetState extends State<_AddEditMethodSheet> {
  final _formKey = GlobalKey<FormState>();

  late String _selectedType;
  late TextEditingController _bankNameCtrl;
  late TextEditingController _titleCtrl;
  late TextEditingController _numberCtrl;
  late TextEditingController _ibanCtrl;
  late TextEditingController _instructionsCtrl;
  late bool _isActive;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _selectedType = e?.methodType ?? PlatformPaymentMethodType.bankAccount;
    _bankNameCtrl = TextEditingController(
      text: e?.bankOrWalletName ??
          (_selectedType == PlatformPaymentMethodType.bankAccount
              ? 'Meezan Bank Ltd'
              : _selectedType),
    );
    _titleCtrl = TextEditingController(text: e?.accountTitle ?? '');
    _numberCtrl = TextEditingController(text: e?.accountNumber ?? '');
    _ibanCtrl = TextEditingController(text: e?.iban ?? '');
    _instructionsCtrl = TextEditingController(text: e?.instructions ?? '');
    _isActive = e?.isActive ?? true;
  }

  @override
  void dispose() {
    _bankNameCtrl.dispose();
    _titleCtrl.dispose();
    _numberCtrl.dispose();
    _ibanCtrl.dispose();
    _instructionsCtrl.dispose();
    super.dispose();
  }

  void _onTypeChanged(String? newType) {
    if (newType == null) return;
    setState(() {
      _selectedType = newType;
      if (widget.existing == null) {
        if (newType == PlatformPaymentMethodType.bankAccount &&
            _bankNameCtrl.text.isEmpty) {
          _bankNameCtrl.text = 'Meezan Bank Ltd';
        } else if (newType != PlatformPaymentMethodType.bankAccount) {
          _bankNameCtrl.text = '$newType Merchant';
        }
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final method = PlatformPaymentMethodModel(
      id: widget.existing?.id ?? '',
      methodType: _selectedType,
      bankOrWalletName: _bankNameCtrl.text.trim(),
      accountTitle: _titleCtrl.text.trim(),
      accountNumber: _numberCtrl.text.trim(),
      iban: _ibanCtrl.text.trim().isEmpty ? null : _ibanCtrl.text.trim(),
      instructions: _instructionsCtrl.text.trim().isEmpty
          ? null
          : _instructionsCtrl.text.trim(),
      isActive: _isActive,
      createdAt: widget.existing?.createdAt,
      updatedAt: widget.existing?.updatedAt,
    );

    widget.onSave(method);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;
    final viewInsets = MediaQuery.of(context).viewInsets;

    return Container(
      margin: EdgeInsets.only(
        top: 60,
        bottom: viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top handle
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Title row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isEditing
                                ? Icons.edit_note_rounded
                                : Icons.account_balance_wallet_rounded,
                            color: AppColors.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEditing
                                  ? 'Edit Payment Account'
                                  : 'Add Escrow Payment Account',
                              style: GoogleFonts.poppins(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkNavy,
                              ),
                            ),
                            Text(
                              'Companies transfer project funds here for escrow',
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(color: AppColors.border, height: 1),
                const SizedBox(height: 20),

                // Method Type Dropdown
                Text(
                  'Payment Method Type *',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkNavy,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedType,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.category_rounded, size: 20),
                    filled: true,
                    fillColor: AppColors.surfaceAlt,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                  items: PlatformPaymentMethodType.all.map((t) {
                    return DropdownMenuItem<String>(
                      value: t,
                      child: Text(
                        t,
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: _onTypeChanged,
                ),
                const SizedBox(height: 16),

                // Bank / Provider Name
                Text(
                  'Bank or Wallet Name *',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkNavy,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _bankNameCtrl,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.business_rounded, size: 20),
                    hintText: 'e.g. Meezan Bank Ltd, JazzCash Merchant',
                    filled: true,
                    fillColor: AppColors.surfaceAlt,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Please enter bank or wallet name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Account Title
                Text(
                  'Account Title *',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkNavy,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleCtrl,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.person_rounded, size: 20),
                    hintText: 'e.g. SkillBridge Escrow Services Pvt Ltd',
                    filled: true,
                    fillColor: AppColors.surfaceAlt,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Account Title is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Account / Mobile Number
                Text(
                  _selectedType == PlatformPaymentMethodType.bankAccount
                      ? 'Account Number *'
                      : 'Mobile Wallet Number *',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkNavy,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _numberCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.numbers_rounded, size: 20),
                    hintText: _selectedType ==
                            PlatformPaymentMethodType.bankAccount
                        ? 'e.g. 01020304050607'
                        : 'e.g. 03001234567',
                    filled: true,
                    fillColor: AppColors.surfaceAlt,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Account Number is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // IBAN (Optional for Bank)
                Text(
                  'IBAN (Optional)',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkNavy,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _ibanCtrl,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                    hintText: 'e.g. PK36MEZN0001020304050607',
                    filled: true,
                    fillColor: AppColors.surfaceAlt,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Special Deposit Instructions (Optional)
                Text(
                  'Deposit Instructions (Shown to Companies)',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkNavy,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _instructionsCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.note_alt_outlined, size: 20),
                    hintText:
                        'e.g. Please include your Project ID in the transfer memo. Upload receipt screenshot after transfer.',
                    filled: true,
                    fillColor: AppColors.surfaceAlt,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Active Toggle
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _isActive
                                ? Icons.visibility_rounded
                                : Icons.visibility_off_rounded,
                            size: 18,
                            color: _isActive
                                ? AppColors.success
                                : AppColors.textMuted,
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Active Status',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.darkNavy,
                                ),
                              ),
                              Text(
                                _isActive
                                    ? 'Visible to companies during checkout'
                                    : 'Hidden from checkout',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Switch.adaptive(
                        value: _isActive,
                        activeThumbColor: AppColors.success,
                        onChanged: (val) => setState(() => _isActive = val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Save / Cancel Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: _isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save_rounded, size: 18),
                        label: Text(
                          _isSaving
                              ? 'Saving...'
                              : (isEditing ? 'Update Method' : 'Save Method'),
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                          ),
                        ),
                        onPressed: _isSaving ? null : _submit,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

