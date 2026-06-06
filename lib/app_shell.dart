import 'package:flutter/material.dart';

import 'app_state.dart';
import 'app_theme.dart';
import 'app_widgets.dart';
import 'pages.dart';

class AppShell extends StatefulWidget {
  final AppState state;
  final Future<void> Function() onChanged;
  final Future<void> Function() onLogout;

  const AppShell({
    super.key,
    required this.state,
    required this.onChanged,
    required this.onLogout,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int selectedIndex = 0;
  bool busy = false;
  bool sidebarOpen = true;

  final List<String> menu = const [
    'Dashboard',
    'Setup Company',
    'DSR / Booker',
    'Suppliers',
    'Shopkeepers',
    'Products',
    'Load Form',
    'Order Booking',
    'Recovery',
    'DSR Daily Report',
    'Expenses',
    'Deposit',
    'Claims / Expiry',
    'Reports',
  ];

  Future<void> refresh() async {
    setState(() => busy = true);
    await widget.onChanged();
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 980;

    return Scaffold(
      drawer: isDesktop ? null : Drawer(child: sidebar(isDesktop: false)),
      appBar: isDesktop
          ? null
          : AppBar(
              title: const Text('Smart Account Manager'),
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              elevation: 0,
            ),
      body: Row(
        children: [
          if (isDesktop)
            AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeInOutCubic,
              width: sidebarOpen ? 275 : 82,
              child: sidebar(isDesktop: true),
            ),
          Expanded(
            child: Column(
              children: [
                topBar(isDesktop),
                if (busy) const LinearProgressIndicator(minHeight: 2),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(18),
                    child: selectedPage(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget sidebar({required bool isDesktop}) {
    return Container(
      color: AppTheme.dark,
      child: SafeArea(
        child: Column(
          children: [
            sidebarHeader(isDesktop),
            Expanded(
              child: ListView.builder(
                itemCount: menu.length,
                itemBuilder: (context, index) {
                  final active = selectedIndex == index;

                  return Tooltip(
                    message: sidebarOpen || !isDesktop ? '' : menu[index],
                    waitDuration: const Duration(milliseconds: 350),
                    child: Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: sidebarOpen || !isDesktop ? 12 : 10,
                        vertical: 4,
                      ),
                      child: ListTile(
                        selected: active,
                        selectedTileColor: AppTheme.primary,
                        minLeadingWidth: 26,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: sidebarOpen || !isDesktop ? 14 : 13,
                          vertical: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        leading: Icon(
                          menuIcon(index),
                          color: active ? Colors.white : const Color(0xffd1d5db),
                        ),
                        title: AnimatedOpacity(
                          opacity: sidebarOpen || !isDesktop ? 1 : 0,
                          duration: const Duration(milliseconds: 180),
                          child: sidebarOpen || !isDesktop
                              ? Text(
                                  menu[index],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: active ? Colors.white : const Color(0xffd1d5db),
                                    fontWeight: active ? FontWeight.w900 : FontWeight.w500,
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                        onTap: () {
                          setState(() => selectedIndex = index);
                          if (MediaQuery.of(context).size.width < 980) {
                            Navigator.pop(context);
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            sidebarFooter(isDesktop),
          ],
        ),
      ),
    );
  }

  Widget sidebarHeader(bool isDesktop) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(sidebarOpen || !isDesktop ? 22 : 14),
      child: Column(
        crossAxisAlignment:
            sidebarOpen || !isDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          if (sidebarOpen || !isDesktop) ...[
            const SizedBox(height: 12),
            const Text(
              'Smart Account',
              style: TextStyle(
                color: Colors.white,
                fontSize: 23,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Text(
              'Supabase Cloud',
              style: TextStyle(color: Color(0xff9ca3af), fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }

  Widget sidebarFooter(bool isDesktop) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeInOutCubic,
      width: double.infinity,
      margin: const EdgeInsets.all(14),
      padding: EdgeInsets.all(sidebarOpen || !isDesktop ? 14 : 8),
      decoration: BoxDecoration(
        color: const Color(0xff1f2937),
        borderRadius: BorderRadius.circular(18),
      ),
      child: sidebarOpen || !isDesktop
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.state.company?.name ?? 'No company yet',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.state.profile?.role ?? 'Setup required',
                  style: const TextStyle(
                    color: Color(0xffd1d5db),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: widget.onLogout,
                    icon: const Icon(Icons.logout_rounded, color: Colors.white),
                    label: const Text(
                      'Logout',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            )
          : IconButton(
              tooltip: 'Logout',
              onPressed: widget.onLogout,
              icon: const Icon(Icons.logout_rounded, color: Colors.white),
            ),
    );
  }

  IconData menuIcon(int index) {
    final icons = [
      Icons.dashboard_rounded,
      Icons.business_rounded,
      Icons.badge_rounded,
      Icons.local_shipping_rounded,
      Icons.store_rounded,
      Icons.inventory_2_rounded,
      Icons.move_down_rounded,
      Icons.point_of_sale_rounded,
      Icons.payments_rounded,
      Icons.receipt_long_rounded,
      Icons.money_off_rounded,
      Icons.account_balance_rounded,
      Icons.report_problem_rounded,
      Icons.bar_chart_rounded,
    ];

    return icons[index];
  }

  Widget topBar(bool isDesktop) {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xffe5e7eb))),
      ),
      child: Row(
        children: [
          if (isDesktop)
            IconButton(
              tooltip: sidebarOpen ? 'Close sidebar' : 'Open sidebar',
              onPressed: () {
                setState(() {
                  sidebarOpen = !sidebarOpen;
                });
              },
              icon: AnimatedRotation(
                turns: sidebarOpen ? 0 : 0.5,
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeInOut,
                child: const Icon(Icons.menu_open_rounded),
              ),
            ),
          if (isDesktop) const SizedBox(width: 8),
          Expanded(
            child: Text(
              menu[selectedIndex],
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AppTheme.dark,
              ),
            ),
          ),
          primaryButton('Refresh', Icons.refresh_rounded, refresh),
        ],
      ),
    );
  }

  Widget selectedPage() {
    if (selectedIndex != 1 && widget.state.profile == null) {
      return SetupCompanyPage(state: widget.state, onChanged: refresh);
    }

    switch (selectedIndex) {
      case 0:
        return DashboardPage(state: widget.state, onChanged: refresh);
      case 1:
        return SetupCompanyPage(state: widget.state, onChanged: refresh);
      case 2:
        return DsrPage(state: widget.state, onChanged: refresh);
      case 3:
        return SupplierPage(state: widget.state, onChanged: refresh);
      case 4:
        return ShopkeeperPage(state: widget.state, onChanged: refresh);
      case 5:
        return ProductPage(state: widget.state, onChanged: refresh);
      case 6:
        return LoadFormPage(state: widget.state, onChanged: refresh);
      case 7:
        return OrderBookingPage(state: widget.state, onChanged: refresh);
      case 8:
        return RecoveryPage(state: widget.state, onChanged: refresh);
      case 9:
        return DsrReportPage(state: widget.state, onChanged: refresh);
      case 10:
        return ExpensePage(state: widget.state, onChanged: refresh);
      case 11:
        return DepositPage(state: widget.state, onChanged: refresh);
      case 12:
        return ClaimPage(state: widget.state, onChanged: refresh);
      default:
        return ReportsPage(state: widget.state, onChanged: refresh);
    }
  }
}
