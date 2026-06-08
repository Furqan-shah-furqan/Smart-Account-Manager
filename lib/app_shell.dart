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
  bool logoHover = false;

  final List<String> menu = const [
    'Dashboard',
    'All Products',
    'DSR & Salesman',
    'Primary Receiving',
    'Secondary Order',
    'Load Form Settlement',
    'Order Booking',
    'Company Ledger',
    'Stock',
    'Recovery',
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

  bool get showingCompanySetup => selectedIndex == -1;

  String get pageTitle {
    if (showingCompanySetup) return 'Company';
    if (selectedIndex >= 0 && selectedIndex < menu.length) {
      return menu[selectedIndex];
    }
    return 'Dashboard';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 980;
    final sideWidth = sidebarOpen ? (screenWidth < 1180 ? 222.0 : 238.0) : 68.0;

    return Scaffold(
      drawer: isDesktop ? null : Drawer(child: sidebar(isDesktop: false)),
      floatingActionButton: widget.state.profile == null
          ? null
          : FloatingActionButton(
              onPressed: () => showProductDialog(context, widget.state, refresh),
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add_box_rounded),
            ),
      appBar: isDesktop
          ? null
          : AppBar(
              title: Text(pageTitle),
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              elevation: 0,
              actions: [
                IconButton(
                  tooltip: 'Company',
                  onPressed: () => setState(() => selectedIndex = -1),
                  icon: const Icon(Icons.business_rounded),
                ),
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: refresh,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
      body: Row(
        children: [
          if (isDesktop)
            AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeInOutCubic,
              width: sideWidth,
              child: sidebar(isDesktop: true),
            ),
          Expanded(
            child: Column(
              children: [
                if (isDesktop) topBar(isDesktop),
                if (busy) const LinearProgressIndicator(minHeight: 2),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final padding = constraints.maxWidth < 620 ? 12.0 : 18.0;
                      return SingleChildScrollView(
                        padding: EdgeInsets.all(padding),
                        child: selectedPage(),
                      );
                    },
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
    final expanded = sidebarOpen || !isDesktop;

    return Container(
      color: AppTheme.dark,
      child: SafeArea(
        child: Column(
          children: [
            sidebarHeader(isDesktop),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 8),
                itemCount: menu.length,
                itemBuilder: (context, index) {
                  final active = selectedIndex == index;

                  return Tooltip(
                    message: expanded ? '' : menu[index],
                    waitDuration: const Duration(milliseconds: 350),
                    child: Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: expanded ? 10 : 8,
                        vertical: 3,
                      ),
                      child: ListTile(
                        dense: true,
                        selected: active,
                        selectedTileColor: AppTheme.primary,
                        minLeadingWidth: 24,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: expanded ? 12 : 12,
                          vertical: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        leading: Icon(
                          menuIcon(index),
                          size: 21,
                          color: active ? Colors.white : const Color(0xffd1d5db),
                        ),
                        title: expanded
                            ? Text(
                                menu[index],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: active ? Colors.white : const Color(0xffd1d5db),
                                  fontWeight: active ? FontWeight.w900 : FontWeight.w500,
                                ),
                              )
                            : null,
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
    final expanded = sidebarOpen || !isDesktop;
    final tooltip = sidebarOpen ? 'Close sidebar' : 'Open sidebar';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        expanded ? 14 : 8,
        18,
        expanded ? 12 : 8,
        16,
      ),
      child: Row(
        mainAxisAlignment: expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
        children: [
          Tooltip(
            message: isDesktop ? tooltip : 'Smart Account',
            child: MouseRegion(
              onEnter: (_) => setState(() => logoHover = true),
              onExit: (_) => setState(() => logoHover = false),
              child: InkWell(
                borderRadius: BorderRadius.circular(17),
                onTap: isDesktop
                    ? () => setState(() => sidebarOpen = !sidebarOpen)
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Icon(
                    logoHover && isDesktop
                        ? (sidebarOpen
                            ? Icons.keyboard_double_arrow_left_rounded
                            : Icons.keyboard_double_arrow_right_rounded)
                        : Icons.account_balance_wallet_rounded,
                    color: Colors.white,
                    size: 27,
                  ),
                ),
              ),
            ),
          ),
          if (expanded) ...[
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Smart Account',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Supabase Cloud',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Color(0xff9ca3af), fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget sidebarFooter(bool isDesktop) {
    final expanded = sidebarOpen || !isDesktop;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeInOutCubic,
      width: double.infinity,
      margin: EdgeInsets.all(expanded ? 12 : 8),
      padding: EdgeInsets.all(expanded ? 12 : 8),
      decoration: BoxDecoration(
        color: const Color(0xff1f2937),
        borderRadius: BorderRadius.circular(18),
      ),
      child: expanded
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
      Icons.table_chart_rounded,
      Icons.groups_rounded,
      Icons.inventory_2_rounded,
      Icons.move_down_rounded,
      Icons.receipt_long_rounded,
      Icons.point_of_sale_rounded,
      Icons.account_balance_wallet_rounded,
      Icons.warehouse_rounded,
      Icons.payments_rounded,
      Icons.money_off_rounded,
      Icons.account_balance_rounded,
      Icons.report_problem_rounded,
      Icons.bar_chart_rounded,
    ];

    return icons[index];
  }

  Widget topBar(bool isDesktop) {
    return Container(
      constraints: const BoxConstraints(minHeight: 76),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xffe5e7eb))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              pageTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AppTheme.dark,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () => setState(() => selectedIndex = -1),
                icon: const Icon(Icons.business_rounded, size: 17),
                label: const Text('Company'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              primaryButton('Refresh', Icons.refresh_rounded, refresh),
            ],
          ),
        ],
      ),
    );
  }

  Widget selectedPage() {
    if (!showingCompanySetup && widget.state.profile == null) {
      return SetupCompanyPage(state: widget.state, onChanged: refresh);
    }

    switch (selectedIndex) {
      case -1:
        return SetupCompanyPage(state: widget.state, onChanged: refresh);
      case 0:
        return DashboardPage(state: widget.state, onChanged: refresh);
      case 1:
        return AllProductsPage(state: widget.state, onChanged: refresh);
      case 2:
        return SalesTeamPage(state: widget.state, onChanged: refresh);
      case 3:
        return ProductPage(state: widget.state, onChanged: refresh);
      case 4:
        return LoadFormPage(state: widget.state, onChanged: refresh);
      case 5:
        return LoadFormSettlementPage(state: widget.state, onChanged: refresh);
      case 6:
        return OrderBookingPage(state: widget.state, onChanged: refresh);
      case 7:
        return CompanyLedgerPage(state: widget.state, onChanged: refresh);
      case 8:
        return StockPage(state: widget.state, onChanged: refresh);
      case 9:
        return RecoveryPage(state: widget.state, onChanged: refresh);
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
