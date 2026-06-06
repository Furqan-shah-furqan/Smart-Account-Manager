// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter/material.dart';

import 'app_state.dart';
import 'app_theme.dart';
import 'app_widgets.dart';
import 'models.dart';

enum DashboardMetricType {
  grossSale,
  cashSale,
  creditSale,
  recovery,
  balanceCash,
  marketCredit,
  stockValue,
  profitEstimate,
}

class DashboardPage extends StatelessWidget {
  final AppState state;
  final Future<void> Function() onChanged;

  const DashboardPage({
    super.key,
    required this.state,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cashTotal = state.cashSales + state.totalRecovery + state.totalExpenses + state.depositTotal;
    final cashInPercent = cashTotal == 0 ? 0.0 : (state.cashSales + state.totalRecovery) / cashTotal;
    final cashOutPercent = cashTotal == 0 ? 0.0 : (state.totalExpenses + state.depositTotal) / cashTotal;
    final stockHealth = state.products.isEmpty ? 0.0 : (state.products.length - state.lowStockCount) / state.products.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        dashboardHero(context),
        const SizedBox(height: 18),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            StatCard(title: 'Gross Sale', value: state.rs(state.grossSale), icon: Icons.trending_up_rounded, color: Colors.green, onTap: () => openMetric(context, DashboardMetricType.grossSale)),
            StatCard(title: 'Cash Sale', value: state.rs(state.cashSales), icon: Icons.payments_rounded, color: Colors.blue, onTap: () => openMetric(context, DashboardMetricType.cashSale)),
            StatCard(title: 'Credit Sale', value: state.rs(state.creditSales), icon: Icons.credit_score_rounded, color: Colors.red, onTap: () => openMetric(context, DashboardMetricType.creditSale)),
            StatCard(title: 'Recovery', value: state.rs(state.totalRecovery), icon: Icons.call_received_rounded, color: Colors.purple, onTap: () => openMetric(context, DashboardMetricType.recovery)),
            StatCard(title: 'Balance Cash', value: state.rs(state.cashBalance), icon: Icons.account_balance_wallet_rounded, color: Colors.teal, onTap: () => openMetric(context, DashboardMetricType.balanceCash)),
            StatCard(title: 'Market Credit', value: state.rs(state.marketCredit), icon: Icons.store_rounded, color: Colors.orange, onTap: () => openMetric(context, DashboardMetricType.marketCredit)),
            StatCard(title: 'Stock Value', value: state.rs(state.stockValue), icon: Icons.inventory_2_rounded, color: Colors.indigo, onTap: () => openMetric(context, DashboardMetricType.stockValue)),
            StatCard(title: 'Profit Estimate', value: state.rs(state.monthlyProfitEstimate), icon: Icons.bar_chart_rounded, color: Colors.green, onTap: () => openMetric(context, DashboardMetricType.profitEstimate)),
          ],
        ),
        const SizedBox(height: 18),
        responsiveTwo(
          DataCard(
            title: 'Cash Flow',
            child: Column(
              children: [
                StatusBar(title: 'Cash In', value: state.rs(state.cashSales + state.totalRecovery), percent: cashInPercent, color: Colors.green, icon: Icons.call_received_rounded),
                const SizedBox(height: 18),
                StatusBar(title: 'Cash Out', value: state.rs(state.totalExpenses + state.depositTotal), percent: cashOutPercent, color: Colors.red, icon: Icons.call_made_rounded),
              ],
            ),
          ),
          DataCard(
            title: 'Stock Health',
            child: Column(
              children: [
                StatusBar(title: 'Healthy Stock', value: '${(stockHealth * 100).toStringAsFixed(0)}%', percent: stockHealth, color: Colors.green, icon: Icons.check_circle_rounded),
                const SizedBox(height: 18),
                StatusBar(title: 'Low Stock Items', value: state.lowStockCount.toString(), percent: state.products.isEmpty ? 0 : state.lowStockCount / state.products.length, color: Colors.orange, icon: Icons.warning_rounded),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        salesTable(state),
      ],
    );
  }

  void openMetric(BuildContext context, DashboardMetricType metric) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DashboardMetricPage(state: state, metric: metric),
      ),
    );
  }

  Widget dashboardHero(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xff1d4ed8), Color(0xff2563eb), Color(0xff38bdf8)]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        runSpacing: 20,
        children: [
          SizedBox(
            width: 560,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Cloud DSR Sales Management', style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(state.company?.name ?? 'Smart Account Manager', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                const Text('Salesman → Booker → Shopkeeper → Cash/Credit Sale → Recovery → Daily DSR Cash Report.', style: TextStyle(color: Colors.white, fontSize: 15, height: 1.5)),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  children: [
                    whiteButton('Book Sale', Icons.point_of_sale_rounded, () => showSaleDialog(context, state, onChanged)),
                    whiteButton('Load Stock', Icons.move_down_rounded, () => showLoadDialog(context, state, onChanged)),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 295,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.16), borderRadius: BorderRadius.circular(22)),
            child: Column(
              children: [
                heroLine('DSR / Bookers', state.dsrs.length.toString(), Icons.badge_rounded),
                heroLine('Shopkeepers', state.shopkeepers.length.toString(), Icons.store_rounded),
                heroLine('Credit Bills', state.sales.where((x) => x.type == SaleType.credit).length.toString(), Icons.receipt_long_rounded),
                heroLine('Low Stock', state.lowStockCount.toString(), Icons.warning_rounded),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget whiteButton(String text, IconData icon, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(text),
      style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xff1d4ed8), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
    );
  }

  Widget heroLine(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: const TextStyle(color: Colors.white70))),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class DashboardMetricPage extends StatefulWidget {
  final AppState state;
  final DashboardMetricType metric;

  const DashboardMetricPage({
    super.key,
    required this.state,
    required this.metric,
  });

  @override
  State<DashboardMetricPage> createState() => _DashboardMetricPageState();
}

class _DashboardMetricPageState extends State<DashboardMetricPage> {
  final fromController = TextEditingController();
  final toController = TextEditingController();
  final dayController = TextEditingController();
  final monthController = TextEditingController();
  final yearController = TextEditingController();

  AppState get state => widget.state;

  @override
  void dispose() {
    fromController.dispose();
    toController.dispose();
    dayController.dispose();
    monthController.dispose();
    yearController.dispose();
    super.dispose();
  }

  String get title {
    switch (widget.metric) {
      case DashboardMetricType.grossSale:
        return 'Gross Sale History';
      case DashboardMetricType.cashSale:
        return 'Cash Sale History';
      case DashboardMetricType.creditSale:
        return 'Credit Sale History';
      case DashboardMetricType.recovery:
        return 'Recovery History';
      case DashboardMetricType.balanceCash:
        return 'Balance Cash History';
      case DashboardMetricType.marketCredit:
        return 'Market Credit History';
      case DashboardMetricType.stockValue:
        return 'Stock Value History';
      case DashboardMetricType.profitEstimate:
        return 'Profit Estimate History';
    }
  }

  IconData get icon {
    switch (widget.metric) {
      case DashboardMetricType.grossSale:
        return Icons.trending_up_rounded;
      case DashboardMetricType.cashSale:
        return Icons.payments_rounded;
      case DashboardMetricType.creditSale:
        return Icons.credit_score_rounded;
      case DashboardMetricType.recovery:
        return Icons.call_received_rounded;
      case DashboardMetricType.balanceCash:
        return Icons.account_balance_wallet_rounded;
      case DashboardMetricType.marketCredit:
        return Icons.store_rounded;
      case DashboardMetricType.stockValue:
        return Icons.inventory_2_rounded;
      case DashboardMetricType.profitEstimate:
        return Icons.bar_chart_rounded;
    }
  }

  Color get color {
    switch (widget.metric) {
      case DashboardMetricType.grossSale:
      case DashboardMetricType.profitEstimate:
        return Colors.green;
      case DashboardMetricType.cashSale:
        return Colors.blue;
      case DashboardMetricType.creditSale:
        return Colors.red;
      case DashboardMetricType.recovery:
        return Colors.purple;
      case DashboardMetricType.balanceCash:
        return Colors.teal;
      case DashboardMetricType.marketCredit:
        return Colors.orange;
      case DashboardMetricType.stockValue:
        return Colors.indigo;
    }
  }

  bool dateOk(String date) {
    final clean = date.trim();
    if (clean.isEmpty) return true;

    if (!dateInRange(clean, fromController.text, toController.text)) {
      return false;
    }

    final parts = clean.split('-');
    if (parts.length == 3) {
      final year = yearController.text.trim();
      final month = monthController.text.trim().padLeft(monthController.text.trim().isEmpty ? 0 : 2, '0');
      final day = dayController.text.trim().padLeft(dayController.text.trim().isEmpty ? 0 : 2, '0');

      if (year.isNotEmpty && parts[0] != year) return false;
      if (month.isNotEmpty && parts[1] != month) return false;
      if (day.isNotEmpty && parts[2] != day) return false;
    }

    return true;
  }

  List<SaleEntry> filteredSales({SaleType? type}) {
    return state.sales.where((sale) {
      if (type != null && sale.type != type) return false;
      return dateOk(sale.date);
    }).toList();
  }

  List<RecoveryEntry> filteredRecoveries() {
    return state.recoveries.where((item) => dateOk(item.date)).toList();
  }

  List<ExpenseEntry> filteredExpenses() {
    return state.expenses.where((item) => dateOk(item.date)).toList();
  }

  List<DepositEntry> filteredDeposits() {
    return state.deposits.where((item) => dateOk(item.date)).toList();
  }

  List<ClaimEntry> filteredClaims() {
    return state.claims.where((item) => dateOk(item.date)).toList();
  }

  List<CompanyPurchase> filteredPurchases() {
    return state.companyPurchases.where((item) => dateOk(item.date)).toList();
  }

  double get filteredTotal {
    switch (widget.metric) {
      case DashboardMetricType.grossSale:
        return filteredSales().fold<double>(0, (sum, item) => sum + item.total);
      case DashboardMetricType.cashSale:
        return filteredSales(type: SaleType.cash).fold<double>(0, (sum, item) => sum + item.total);
      case DashboardMetricType.creditSale:
        return filteredSales(type: SaleType.credit).fold<double>(0, (sum, item) => sum + item.total);
      case DashboardMetricType.recovery:
        return filteredRecoveries().fold<double>(0, (sum, item) => sum + item.receivedAmount);
      case DashboardMetricType.balanceCash:
        final cashSales = filteredSales(type: SaleType.cash).fold<double>(0, (sum, item) => sum + item.total);
        final recovery = filteredRecoveries().fold<double>(0, (sum, item) => sum + item.receivedAmount);
        final expenses = filteredExpenses().fold<double>(0, (sum, item) => sum + item.amount);
        final deposits = filteredDeposits().fold<double>(0, (sum, item) => sum + item.total);
        return cashSales + recovery - expenses - deposits;
      case DashboardMetricType.marketCredit:
        final creditSales = filteredSales(type: SaleType.credit).fold<double>(0, (sum, item) => sum + item.total);
        final recovery = filteredRecoveries().fold<double>(0, (sum, item) => sum + item.receivedAmount);
        return creditSales - recovery;
      case DashboardMetricType.stockValue:
        return state.stockValue;
      case DashboardMetricType.profitEstimate:
        final saleProfit = filteredSales().fold<double>(0, (sum, sale) {
          final cost = (state.productById(sale.productId)?.purchasePrice ?? 0) * sale.quantity;
          return sum + sale.total - cost;
        });
        final expenses = filteredExpenses().fold<double>(0, (sum, item) => sum + item.amount);
        final claims = filteredClaims().fold<double>(0, (sum, item) => sum + item.amount);
        return saleProfit - expenses - claims;
    }
  }

  Widget filterInput(String label, TextEditingController controller, {double width = 150, bool number = false}) {
    return SizedBox(
      width: width,
      child: TextField(
        controller: controller,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          hintText: label.contains('Date') ? 'YYYY-MM-DD' : null,
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final pagePadding = screen.width < 520
        ? 12.0
        : screen.width < 980
            ? 14.0
            : 18.0;

    return Scaffold(
      backgroundColor: AppTheme.softBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(pagePadding),
          child: Column(
            children: [
              DataCard(
                title: title,
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: color.withOpacity(0.12),
                      child: Icon(icon, color: color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Filtered Total: ${state.rs(filteredTotal)}',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Tap back to return to Dashboard. Use filters to check date, day, month, or year history.',
                            style: TextStyle(color: Color(0xff6b7280)),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('Back'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              filterCard(
                title: 'History Filters',
                children: [
                  filterInput('From Date', fromController, width: 160),
                  filterInput('To Date', toController, width: 160),
                  filterInput('Day', dayController, width: 100, number: true),
                  filterInput('Month', monthController, width: 110, number: true),
                  filterInput('Year', yearController, width: 110, number: true),
                  clearFilterButton(() {
                    setState(() {
                      fromController.clear();
                      toController.clear();
                      dayController.clear();
                      monthController.clear();
                      yearController.clear();
                    });
                  }),
                ],
              ),
              const SizedBox(height: 18),
              metricTable(),
            ],
          ),
        ),
      ),
    );
  }

  Widget metricTable() {
    switch (widget.metric) {
      case DashboardMetricType.grossSale:
        return salesTable(state, rows: filteredSales());
      case DashboardMetricType.cashSale:
        return salesTable(state, rows: filteredSales(type: SaleType.cash));
      case DashboardMetricType.creditSale:
        return salesTable(state, rows: filteredSales(type: SaleType.credit));
      case DashboardMetricType.recovery:
        return recoveryTable(state, rows: filteredRecoveries());
      case DashboardMetricType.balanceCash:
        return cashLedgerTable();
      case DashboardMetricType.marketCredit:
        return marketCreditTable();
      case DashboardMetricType.stockValue:
        return stockValueTable();
      case DashboardMetricType.profitEstimate:
        return profitTable();
    }
  }

  Widget cashLedgerTable() {
    final rows = <_DashboardLedgerRow>[];

    for (final sale in filteredSales(type: SaleType.cash)) {
      rows.add(_DashboardLedgerRow(
        date: sale.date,
        type: 'Cash Sale',
        party: state.shopName(sale.shopkeeperId),
        detail: '${sale.billNo} • ${state.productName(sale.productId)}',
        amount: sale.total,
      ));
    }

    for (final recovery in filteredRecoveries()) {
      rows.add(_DashboardLedgerRow(
        date: recovery.date,
        type: 'Recovery',
        party: state.shopName(recovery.shopkeeperId),
        detail: recovery.chequeBillNo.isEmpty ? '-' : recovery.chequeBillNo,
        amount: recovery.receivedAmount,
      ));
    }

    for (final expense in filteredExpenses()) {
      rows.add(_DashboardLedgerRow(
        date: expense.date,
        type: 'Expense',
        party: state.dsrName(expense.dsrId),
        detail: expense.type,
        amount: -expense.amount,
      ));
    }

    for (final deposit in filteredDeposits()) {
      rows.add(_DashboardLedgerRow(
        date: deposit.date,
        type: 'Deposit',
        party: deposit.party,
        detail: 'Bank / party deposit',
        amount: -deposit.total,
      ));
    }

    rows.sort((a, b) => b.date.compareTo(a.date));

    return ledgerTable(
      title: 'Balance Cash Ledger',
      headers: const ['Date', 'Type', 'Party', 'Detail', 'In', 'Out', 'Effect'],
      rows: rows.map((row) {
        final isIn = row.amount >= 0;
        return [
          formatDateForUi(row.date),
          row.type,
          row.party,
          row.detail,
          isIn ? state.rs(row.amount) : '-',
          isIn ? '-' : state.rs(row.amount.abs()),
          state.rs(row.amount),
        ];
      }).toList(),
    );
  }

  Widget marketCreditTable() {
    final rows = <_DashboardLedgerRow>[];

    for (final sale in filteredSales(type: SaleType.credit)) {
      rows.add(_DashboardLedgerRow(
        date: sale.date,
        type: 'Credit Sale',
        party: state.shopName(sale.shopkeeperId),
        detail: '${sale.billNo} • ${state.productName(sale.productId)}',
        amount: sale.total,
      ));
    }

    for (final recovery in filteredRecoveries()) {
      rows.add(_DashboardLedgerRow(
        date: recovery.date,
        type: 'Recovery Paid',
        party: state.shopName(recovery.shopkeeperId),
        detail: recovery.chequeBillNo.isEmpty ? '-' : recovery.chequeBillNo,
        amount: -recovery.receivedAmount,
      ));
    }

    rows.sort((a, b) => b.date.compareTo(a.date));

    return ledgerTable(
      title: 'Market Credit Ledger',
      headers: const ['Date', 'Type', 'Shopkeeper', 'Detail', 'Credit Added', 'Paid', 'Balance Effect'],
      rows: rows.map((row) {
        final credit = row.amount >= 0;
        return [
          formatDateForUi(row.date),
          row.type,
          row.party,
          row.detail,
          credit ? state.rs(row.amount) : '-',
          credit ? '-' : state.rs(row.amount.abs()),
          state.rs(row.amount),
        ];
      }).toList(),
    );
  }

  Widget stockValueTable() {
    final purchases = filteredPurchases();

    return Column(
      children: [
        DataCard(
          title: 'Current Stock Value',
          child: state.products.isEmpty
              ? emptyBox('No primary receiving products found.')
              : horizontalTable(
                  DataTable(
                    columns: const [
                      DataColumn(label: Text('Product')),
                      DataColumn(label: Text('Brand')),
                      DataColumn(label: Text('Batch')),
                      DataColumn(label: Text('Stock Packets')),
                      DataColumn(label: Text('Packets/Carton')),
                      DataColumn(label: Text('Stock Cartons')),
                      DataColumn(label: Text('Packet Cost')),
                      DataColumn(label: Text('Stock Value')),
                    ],
                    rows: state.products.map((product) {
                      final cartons = product.packetsPerCarton <= 0 ? 0 : product.warehouseStock / product.packetsPerCarton;
                      final value = product.warehouseStock * product.purchasePrice;
                      return DataRow(cells: [
                        DataCell(Text(product.name)),
                        DataCell(Text(product.brand.isEmpty ? '-' : product.brand)),
                        DataCell(Text(product.batchNo.isEmpty ? '-' : product.batchNo)),
                        DataCell(Text(product.warehouseStock.toString())),
                        DataCell(Text(product.packetsPerCarton.toString())),
                        DataCell(Text(cartons.toStringAsFixed(cartons == cartons.roundToDouble() ? 0 : 1))),
                        DataCell(Text(state.rs(product.purchasePrice))),
                        DataCell(Text(state.rs(value))),
                      ]);
                    }).toList(),
                  ),
                ),
        ),
        const SizedBox(height: 18),
        ledgerTable(
          title: 'Purchase Stock History',
          headers: const ['Date', 'Product', 'Batch', 'Cartons', 'Packets', 'Packet Cost', 'Total Bill', 'Paid', 'Remaining'],
          rows: purchases.map((purchase) {
            return [
              formatDateForUi(purchase.date),
              state.productName(purchase.productId),
              purchase.batchNo.isEmpty ? '-' : purchase.batchNo,
              purchase.cartons.toString(),
              purchase.totalPackets.toString(),
              state.rs(purchase.packetPurchasePrice),
              state.rs(purchase.totalBill),
              state.rs(purchase.paidAmount),
              state.rs(purchase.remainingAmount),
            ];
          }).toList(),
        ),
      ],
    );
  }

  Widget profitTable() {
    final sales = filteredSales();

    return Column(
      children: [
        ledgerTable(
          title: 'Sale Profit History',
          headers: const ['Date', 'Bill No', 'Product', 'Qty', 'Sale Total', 'Cost', 'Profit'],
          rows: sales.map((sale) {
            final product = state.productById(sale.productId);
            final cost = (product?.purchasePrice ?? 0) * sale.quantity;
            final profit = sale.total - cost;
            return [
              formatDateForUi(sale.date),
              sale.billNo,
              state.productName(sale.productId),
              sale.quantity.toString(),
              state.rs(sale.total),
              state.rs(cost),
              state.rs(profit),
            ];
          }).toList(),
        ),
        const SizedBox(height: 18),
        ledgerTable(
          title: 'Profit Deductions',
          headers: const ['Date', 'Type', 'Detail', 'Amount'],
          rows: [
            ...filteredExpenses().map((expense) => [
                  formatDateForUi(expense.date),
                  'Expense',
                  expense.type,
                  state.rs(expense.amount),
                ]),
            ...filteredClaims().map((claim) => [
                  formatDateForUi(claim.date),
                  'Claim / Expiry',
                  '${state.productName(claim.productId)} • ${claim.type}',
                  state.rs(claim.amount),
                ]),
          ],
        ),
      ],
    );
  }

  Widget ledgerTable({
    required String title,
    required List<String> headers,
    required List<List<String>> rows,
  }) {
    return DataCard(
      title: title,
      child: rows.isEmpty
          ? emptyBox('No history found for selected filters.')
          : horizontalTable(
              DataTable(
                columns: headers.map((header) => DataColumn(label: Text(header))).toList(),
                rows: rows.map((row) => DataRow(cells: row.map((cell) => DataCell(Text(cell))).toList())).toList(),
              ),
            ),
    );
  }
}

class _DashboardLedgerRow {
  final String date;
  final String type;
  final String party;
  final String detail;
  final double amount;

  const _DashboardLedgerRow({
    required this.date,
    required this.type,
    required this.party,
    required this.detail,
    required this.amount,
  });
}

class SetupCompanyPage extends StatelessWidget {
  final AppState state;
  final Future<void> Function() onChanged;

  const SetupCompanyPage({
    super.key,
    required this.state,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final companyController = TextEditingController(text: 'AFRA Trader');
    final nameController = TextEditingController(text: 'Admin User');

    return DataCard(
      title: 'Company Setup',
      child: state.profile == null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Create your company profile first. This links your login user with one company in Supabase.'),
                textInput(label: 'Company Name', controller: companyController),
                textInput(label: 'Your Name', controller: nameController),
                const SizedBox(height: 14),
                primaryButton('Create Company Profile', Icons.business_rounded, () async {
                  await runAction(
                    context,
                    () => state.service.createCompanyAndProfile(
                      companyName: companyController.text.trim(),
                      fullName: nameController.text.trim(),
                    ),
                    onChanged,
                  );
                }),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Company: ${state.company?.name ?? '-'}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                Text('Role: ${state.profile?.role ?? '-'}'),
                const SizedBox(height: 12),
                const Text(
                  'Company setup is complete. Now add your real salesman, DSR/booker, shopkeepers, primary receiving products, and stock invoices manually.',
                  style: TextStyle(color: Color(0xff6b7280), height: 1.5),
                ),
              ],
            ),
    );
  }
}

class DsrPage extends StatelessWidget {
  final AppState state;
  final Future<void> Function() onChanged;

  const DsrPage({super.key, required this.state, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return tablePage(
      title: 'DSR / Booker',
      subtitle: 'Manage bookers, routes, assigned salesmen, salary, and stock.',
      buttonText: 'Add DSR',
      icon: Icons.person_add_rounded,
      onTap: () => showDsrDialog(context, state, onChanged),
      table: DataTable(
        columns: const [
          DataColumn(label: Text('Name')),
          DataColumn(label: Text('Phone')),
          DataColumn(label: Text('Route')),
          DataColumn(label: Text('Salesman')),
          DataColumn(label: Text('Salary')),
          DataColumn(label: Text('DSR Stock')),
          DataColumn(label: Text('Sales')),
          DataColumn(label: Text('Actions')),
        ],
        rows: state.dsrs.map((x) {
          final loaded = state.dsrStocks.where((s) => s.dsrId == x.id).fold(0, (sum, s) => sum + s.quantity);
          final sale = state.sales.where((s) => s.dsrId == x.id).fold(0.0, (sum, s) => sum + s.total);
          return DataRow(cells: [
            DataCell(Text(x.name)),
            DataCell(Text(x.phone)),
            DataCell(Text(x.route)),
            DataCell(Text(state.supplierName(x.supplierId))),
            DataCell(Text(state.rs(x.salary))),
            DataCell(Text(loaded.toString())),
            DataCell(Text(state.rs(sale))),
            DataCell(actionButtons(
              onEdit: () => showDsrDialog(context, state, onChanged, editItem: x),
              onDelete: () => confirmDelete(
                context: context,
                title: 'Delete DSR',
                message: 'Are you sure you want to delete this DSR? This is only allowed when no shops or sales are linked.',
                action: () => state.service.deleteDsr(x.id),
                onChanged: onChanged,
                ),
            )),
          ]);
        }).toList(),
      ),
    );
  }
}




class SupplierPage extends StatelessWidget {
  final AppState state;
  final Future<void> Function() onChanged;

  const SupplierPage({super.key, required this.state, required this.onChanged});

  List<Dsr> linkedDsrs(Supplier supplier) {
    return state.dsrs.where((dsr) => dsr.supplierId == supplier.id).toList();
  }

  String linkedDsrNames(Supplier supplier) {
    final linked = linkedDsrs(supplier).map((dsr) {
      final route = dsr.route.trim();
      return route.isEmpty ? dsr.name : '${dsr.name} ($route)';
    }).toList();

    return linked.isEmpty ? '-' : linked.join(', ');
  }

  Widget linkedDsrCell(Supplier supplier) {
    final linked = linkedDsrs(supplier);

    if (linked.isEmpty) {
      return const Text(
        'No linked DSR',
        style: TextStyle(color: Color(0xff9ca3af)),
      );
    }

    final first = linked.first;
    final route = first.route.trim();
    final firstLabel = route.isEmpty ? first.name : '${first.name} ($route)';
    final remaining = linked.length - 1;

    return SizedBox(
      width: 360,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Chip(
              label: Text(
                firstLabel,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff1d4ed8),
                ),
              ),
              backgroundColor: const Color(0xffdbeafe),
              side: const BorderSide(color: Color(0xffbfdbfe)),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          if (remaining > 0) ...[
            const SizedBox(width: 6),
            Tooltip(
              message: linkedDsrNames(supplier),
              child: Chip(
                label: Text(
                  '+$remaining more',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xff92400e),
                  ),
                ),
                backgroundColor: const Color(0xfffff7ed),
                side: const BorderSide(color: Color(0xffffedd5)),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return tablePage(
      title: 'Salesmen',
      subtitle: 'Salesman provides/delivers goods. Linked DSR names are shown before delete.',
      buttonText: 'Add Salesman',
      icon: Icons.local_shipping_rounded,
      onTap: () => showSupplierDialog(context, state, onChanged),
      table: DataTable(
        columnSpacing: 34,
        headingRowHeight: 44,
        dataRowMinHeight: 58,
        dataRowMaxHeight: 82,
        columns: const [
          DataColumn(label: Text('Salesman')),
          DataColumn(label: Text('Phone')),
          DataColumn(label: Text('Address')),
          DataColumn(label: Text('Linked DSR')),
          DataColumn(label: Text('Actions')),
        ],
        rows: state.suppliers.map((x) {
          final linkedDsrsText = linkedDsrNames(x);

          return DataRow(cells: [
            DataCell(SizedBox(width: 120, child: Text(x.name))),
            DataCell(SizedBox(width: 110, child: Text(x.phone))),
            DataCell(SizedBox(width: 130, child: Text(x.address))),
            DataCell(linkedDsrCell(x)),
            DataCell(
              SizedBox(
                width: 96,
                child: actionButtons(
                  onEdit: () => showSupplierDialog(context, state, onChanged, editItem: x),
                  onDelete: () {
                    confirmDelete(
                      context: context,
                      title: 'Delete Salesman',
                      message: linkedDsrsText == '-'
                          ? 'Are you sure you want to delete this salesman?'
                          : 'This salesman is linked with DSR: $linkedDsrsText. You cannot delete it until you remove or change that DSR salesman.',
                      action: () => state.service.deleteSupplier(x.id),
                      onChanged: onChanged,
                    );
                  },
                ),
              ),
            ),
          ]);
        }).toList(),
      ),
    );
  }
}

class ShopkeeperPage extends StatelessWidget {
  final AppState state;
  final Future<void> Function() onChanged;

  const ShopkeeperPage({super.key, required this.state, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return tablePage(
      title: 'Shopkeepers',
      subtitle: 'Manage shops, owner, area, and credit.',
      buttonText: 'Add Shopkeeper',
      icon: Icons.store_rounded,
      onTap: () => showShopDialog(context, state, onChanged),
      table: DataTable(
        columns: const [
          DataColumn(label: Text('Shop')),
          DataColumn(label: Text('Owner')),
          DataColumn(label: Text('Phone')),
          DataColumn(label: Text('Area')),
          DataColumn(label: Text('Booker')),
          DataColumn(label: Text('Pending Credit')),
          DataColumn(label: Text('Actions')),
        ],
        rows: state.shopkeepers.map((x) {
          return DataRow(cells: [
            DataCell(Text(x.shopName)),
            DataCell(Text(x.ownerName)),
            DataCell(Text(x.phone)),
            DataCell(Text(x.area)),
            DataCell(Text(state.dsrName(x.dsrId))),
            DataCell(Text(state.rs(x.pendingCredit))),
            DataCell(actionButtons(
              onEdit: () => showShopDialog(context, state, onChanged, editItem: x),
              onDelete: () => confirmDelete(
                context: context,
                title: 'Delete Shopkeeper',
                message: 'Are you sure you want to delete this shopkeeper? This is only allowed when no sales or recoveries are linked.',
                action: () => state.service.deleteShopkeeper(x.id),
                onChanged: onChanged,
                ),
            )),
          ]);
        }).toList(),
      ),
    );
  }
}

class ProductPage extends StatelessWidget {
  final AppState state;
  final Future<void> Function() onChanged;

  const ProductPage({super.key, required this.state, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        moduleHeader(
          title: 'Primary Receiving',
          subtitle: 'Add and manage primary receiving product details, prices, cartons, packets, and low stock limit.',
          buttonText: 'Add Receiving Product',
          icon: Icons.add_box_rounded,
          onTap: () => showProductDialog(context, state, onChanged),
        ),
        const SizedBox(height: 18),
        productTable(state, context: context, onChanged: onChanged),
      ],
    );
  }
}

class StockPage extends StatelessWidget {
  final AppState state;
  final Future<void> Function() onChanged;

  const StockPage({super.key, required this.state, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        moduleHeader(
          title: 'Stock',
          subtitle: 'Manage company invoices, purchase stock, current warehouse stock, cartons, and payable balance.',
          buttonText: 'Add Invoice / Stock',
          icon: Icons.add_business_rounded,
          onTap: () => showCompanyPurchaseDialog(context, state, onChanged),
        ),
        const SizedBox(height: 18),
        purchaseSummaryCards(state),
        const SizedBox(height: 18),
        productTable(state, context: context, onChanged: onChanged),
        const SizedBox(height: 18),
        companyPurchaseTable(state, context: context),
      ],
    );
  }
}

class CompanyPurchasePage extends StatelessWidget {
  final AppState state;
  final Future<void> Function() onChanged;

  const CompanyPurchasePage({
    super.key,
    required this.state,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return StockPage(state: state, onChanged: onChanged);
  }
}


class CompanyLedgerPage extends StatefulWidget {
  final AppState state;
  final Future<void> Function() onChanged;

  const CompanyLedgerPage({super.key, required this.state, required this.onChanged});

  @override
  State<CompanyLedgerPage> createState() => _CompanyLedgerPageState();
}

class _CompanyLedgerPageState extends State<CompanyLedgerPage> {
  final monthController = TextEditingController(text: DateTime.now().month.toString());
  final yearController = TextEditingController(text: DateTime.now().year.toString());

  AppState get state => widget.state;

  @override
  void dispose() {
    monthController.dispose();
    yearController.dispose();
    super.dispose();
  }

  String get selectedMonth => monthController.text.trim().padLeft(monthController.text.trim().isEmpty ? 0 : 2, '0');
  String get selectedYear => yearController.text.trim();

  bool monthOk(String date) {
    final parts = date.trim().split('-');
    if (parts.length != 3) return true;
    if (selectedMonth.isNotEmpty && parts[1] != selectedMonth) return false;
    if (selectedYear.isNotEmpty && parts[0] != selectedYear) return false;
    return true;
  }

  bool beforeSelectedMonth(String date) {
    if (selectedMonth.isEmpty || selectedYear.isEmpty) return false;
    final parts = date.trim().split('-');
    if (parts.length != 3) return false;
    final itemKey = '${parts[0]}-${parts[1]}';
    final selectedKey = '$selectedYear-$selectedMonth';
    return itemKey.compareTo(selectedKey) < 0;
  }

  List<CompanyPurchase> get purchases {
    final rows = state.companyPurchases.where((item) => monthOk(item.date)).toList();
    rows.sort((a, b) {
      final dateCompare = a.date.compareTo(b.date);
      if (dateCompare != 0) return dateCompare;
      return a.invoiceNo.compareTo(b.invoiceNo);
    });
    return rows;
  }

  double get openingBalance {
    return state.companyPurchases
        .where((item) => beforeSelectedMonth(item.date))
        .fold<double>(0, (sum, item) => sum + item.remainingAmount);
  }

  double get invoiceDebitTotal => purchases.fold<double>(0, (sum, item) => sum + item.totalBill);
  double get paymentCreditTotal => purchases.fold<double>(0, (sum, item) => sum + item.paidAmount);
  double get closingBalance => openingBalance + invoiceDebitTotal - paymentCreditTotal;

  Widget filterInput(String label, TextEditingController controller, {double width = 120}) {
    return SizedBox(
      width: width,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DataCard(
          title: 'General Ledger Report',
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 430,
                child: Text(
                  'Monthly distributor and company ledger in the same style as your sample: opening balance, invoice debit, payment credit, and running balance.',
                  style: const TextStyle(color: Color(0xff6b7280), height: 1.5),
                ),
              ),
              filterInput('Month', monthController, width: 110),
              filterInput('Year', yearController, width: 120),
              clearFilterButton(() {
                setState(() {
                  monthController.clear();
                  yearController.clear();
                });
              }),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            StatCard(title: 'Opening Balance', value: '${state.rs(openingBalance)} Dr', icon: Icons.history_rounded, color: Colors.blueGrey),
            StatCard(title: 'Invoice Debit', value: state.rs(invoiceDebitTotal), icon: Icons.receipt_long_rounded, color: Colors.indigo),
            StatCard(title: 'Payment Credit', value: state.rs(paymentCreditTotal), icon: Icons.payments_rounded, color: Colors.green),
            StatCard(title: 'Closing Balance', value: '${state.rs(closingBalance)} Dr', icon: Icons.account_balance_rounded, color: Colors.red),
          ],
        ),
        const SizedBox(height: 18),
        ledgerHeaderCard(),
        const SizedBox(height: 18),
        generalLedgerTable(),
        const SizedBox(height: 18),
        invoiceRegisterTable(),
      ],
    );
  }

  Widget ledgerHeaderCard() {
    final today = DateTime.now();
    final fromText = selectedMonth.isEmpty || selectedYear.isEmpty ? 'All' : '01/$selectedMonth/$selectedYear';
    final toText = selectedMonth.isEmpty || selectedYear.isEmpty ? 'All' : 'Monthly End';

    return DataCard(
      title: 'Ledger Header',
      child: Wrap(
        spacing: 18,
        runSpacing: 12,
        children: [
          ledgerInfoBox('From', fromText),
          ledgerInfoBox('To', toText),
          ledgerInfoBox('A/C Code', '021112'),
          ledgerInfoBox('A/C Name', state.company?.name ?? 'AFRA TRADER'),
          ledgerInfoBox('Printed', '${today.day.toString().padLeft(2, '0')}/${today.month.toString().padLeft(2, '0')}/${today.year}'),
        ],
      ),
    );
  }

  Widget ledgerInfoBox(String label, String value) {
    return Container(
      width: 190,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xfff8fafc),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xffe5e7eb)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xff6b7280), fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget generalLedgerTable() {
    final ledgerRows = <_CompanyLedgerRow>[];
    double balance = openingBalance;

    ledgerRows.add(_CompanyLedgerRow(
      bok: '',
      voucherNo: '',
      date: '',
      slipNo: '',
      bank: '',
      qty: '',
      description: 'Opening Balance',
      debit: 0,
      credit: 0,
      balance: balance,
    ));

    for (final item in purchases) {
      balance += item.totalBill;
      ledgerRows.add(_CompanyLedgerRow(
        bok: 'SB',
        voucherNo: item.invoiceNo.isEmpty ? item.id.substring(0, item.id.length > 6 ? 6 : item.id.length) : item.invoiceNo,
        date: formatDateForUi(item.date),
        slipNo: '',
        bank: '',
        qty: item.cartons.toString(),
        description: 'Sales against Invoice No. ${item.invoiceNo.isEmpty ? '-' : item.invoiceNo}',
        debit: item.totalBill,
        credit: 0,
        balance: balance,
      ));

      if (item.paidAmount > 0) {
        balance -= item.paidAmount;
        ledgerRows.add(_CompanyLedgerRow(
          bok: 'CR',
          voucherNo: item.invoiceNo.isEmpty ? '-' : item.invoiceNo,
          date: formatDateForUi(item.date),
          slipNo: item.note.isEmpty ? '-' : item.note,
          bank: item.note.toLowerCase().contains('cash') ? 'CASH' : '-',
          qty: '-',
          description: 'Payment to ${item.companyName.isEmpty ? 'Company' : item.companyName}',
          debit: 0,
          credit: item.paidAmount,
          balance: balance,
        ));
      }
    }

    return DataCard(
      title: 'General Ledger Detail',
      child: horizontalTable(
        DataTable(
          columnSpacing: 14,
          horizontalMargin: 8,
          headingRowHeight: 44,
          dataRowMinHeight: 44,
          dataRowMaxHeight: 58,
          columns: const [
            DataColumn(label: Text('BOK')),
            DataColumn(label: Text('V.No.')),
            DataColumn(label: Text('Date')),
            DataColumn(label: Text('Slip/Chq #')),
            DataColumn(label: Text('Bank')),
            DataColumn(label: Text('Qty')),
            DataColumn(label: Text('Description')),
            DataColumn(label: Text('Debit')),
            DataColumn(label: Text('Credit')),
            DataColumn(label: Text('Balance')),
          ],
          rows: [
            ...ledgerRows.map((row) {
              return DataRow(cells: [
                DataCell(Text(row.bok)),
                DataCell(Text(row.voucherNo)),
                DataCell(Text(row.date)),
                DataCell(SizedBox(width: 95, child: Text(row.slipNo, overflow: TextOverflow.ellipsis))),
                DataCell(SizedBox(width: 70, child: Text(row.bank, overflow: TextOverflow.ellipsis))),
                DataCell(Text(row.qty)),
                DataCell(SizedBox(width: 260, child: Text(row.description, overflow: TextOverflow.ellipsis))),
                DataCell(Text(row.debit == 0 ? '0' : state.rs(row.debit))),
                DataCell(Text(row.credit == 0 ? '0' : state.rs(row.credit))),
                DataCell(Text('${state.rs(row.balance)} Dr')),
              ]);
            }),
            DataRow(cells: [
              const DataCell(Text('')),
              const DataCell(Text('')),
              const DataCell(Text('')),
              const DataCell(Text('')),
              const DataCell(Text('')),
              const DataCell(Text('')),
              const DataCell(Text('Total Balance', style: TextStyle(fontWeight: FontWeight.w900))),
              DataCell(Text(state.rs(invoiceDebitTotal), style: const TextStyle(fontWeight: FontWeight.w900))),
              DataCell(Text(state.rs(paymentCreditTotal), style: const TextStyle(fontWeight: FontWeight.w900))),
              DataCell(Text('${state.rs(closingBalance)} Dr', style: const TextStyle(fontWeight: FontWeight.w900))),
            ]),
          ],
        ),
      ),
    );
  }

  Widget invoiceRegisterTable() {
    return DataCard(
      title: 'Invoice Register',
      child: purchases.isEmpty
          ? emptyBox('No company invoices found for selected month/year.')
          : horizontalTable(
              DataTable(
                columnSpacing: 16,
                headingRowHeight: 44,
                dataRowMinHeight: 50,
                dataRowMaxHeight: 62,
                columns: const [
                  DataColumn(label: Text('Invoice')),
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('Company')),
                  DataColumn(label: Text('Qty CTN')),
                  DataColumn(label: Text('Invoice Amount')),
                  DataColumn(label: Text('Paid')),
                  DataColumn(label: Text('Balance')),
                  DataColumn(label: Text('View')),
                ],
                rows: purchases.map((item) {
                  return DataRow(cells: [
                    DataCell(Text(item.invoiceNo.isEmpty ? '-' : item.invoiceNo)),
                    DataCell(Text(formatDateForUi(item.date))),
                    DataCell(SizedBox(width: 150, child: Text(item.companyName.isEmpty ? '-' : item.companyName, overflow: TextOverflow.ellipsis))),
                    DataCell(Text(item.cartons.toString())),
                    DataCell(Text(state.rs(item.totalBill))),
                    DataCell(Text(state.rs(item.paidAmount))),
                    DataCell(Text(state.rs(item.remainingAmount))),
                    DataCell(IconButton(
                      tooltip: 'View invoice',
                      icon: const Icon(Icons.receipt_long_rounded, color: AppTheme.primary),
                      onPressed: () => showCompanyInvoicePreview(context, state, item),
                    )),
                  ]);
                }).toList(),
              ),
            ),
    );
  }
}

class _CompanyLedgerRow {
  final String bok;
  final String voucherNo;
  final String date;
  final String slipNo;
  final String bank;
  final String qty;
  final String description;
  final double debit;
  final double credit;
  final double balance;

  const _CompanyLedgerRow({
    required this.bok,
    required this.voucherNo,
    required this.date,
    required this.slipNo,
    required this.bank,
    required this.qty,
    required this.description,
    required this.debit,
    required this.credit,
    required this.balance,
  });
}

class LoadFormPage extends StatefulWidget {
  final AppState state;
  final Future<void> Function() onChanged;

  const LoadFormPage({super.key, required this.state, required this.onChanged});

  @override
  State<LoadFormPage> createState() => _LoadFormPageState();
}

class _LoadFormPageState extends State<LoadFormPage> {
  bool showLoadForm = false;
  String dsrId = '';
  String productId = '';
  final qtyController = TextEditingController();

  AppState get state => widget.state;

  @override
  void initState() {
    super.initState();
    if (state.dsrs.isNotEmpty) dsrId = state.dsrs.first.id;
    if (state.products.isNotEmpty) productId = state.products.first.id;
  }

  @override
  void dispose() {
    qtyController.dispose();
    super.dispose();
  }

  Future<void> saveInlineLoad() async {
    if (state.dsrs.isEmpty || state.products.isEmpty) {
      showSnack(context, 'Add booker, salesman, and product first.');
      return;
    }

    final selectedDsr = state.dsrById(dsrId);
    final salesmanId = selectedDsr?.supplierId ?? '';

    await runAction(
      context,
      () => state.service.loadStock(
        companyId: state.companyId,
        dsrId: dsrId,
        supplierId: salesmanId,
        productId: productId,
        quantity: toInt(qtyController.text),
      ),
      widget.onChanged,
    );

    if (mounted) {
      setState(() {
        qtyController.clear();
        showLoadForm = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (state.dsrs.isNotEmpty && dsrId.isEmpty) dsrId = state.dsrs.first.id;
    if (state.products.isNotEmpty && productId.isEmpty) productId = state.products.first.id;

    return Column(
      children: [
        moduleHeader(
          title: 'Secondary Order',
          subtitle: 'Create secondary order/load for a booker from warehouse stock.',
          buttonText: 'Add Load Form',
          icon: Icons.move_down_rounded,
          onTap: () => showLoadDialog(context, state, widget.onChanged),
        ),
        const SizedBox(height: 18),
        DataCard(
          title: 'Load Form Switch',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Add load form on this page',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: const Text(
                  'Turn this on to quickly send stock from warehouse to a booker.',
                  style: TextStyle(color: Color(0xff6b7280)),
                ),
                value: showLoadForm,
                onChanged: (value) => setState(() => showLoadForm = value),
              ),
              if (showLoadForm) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 240,
                      child: DropdownButtonFormField<String>(
                        value: dsrId.isEmpty ? null : dsrId,
                        decoration: const InputDecoration(labelText: 'Booker'),
                        items: state.dsrs.map((x) => DropdownMenuItem(value: x.id, child: Text(x.name))).toList(),
                        onChanged: (value) => setState(() => dsrId = value ?? dsrId),
                      ),
                    ),
                    SizedBox(
                      width: 280,
                      child: DropdownButtonFormField<String>(
                        value: productId.isEmpty ? null : productId,
                        decoration: const InputDecoration(labelText: 'Product'),
                        items: state.products.map((x) {
                          return DropdownMenuItem(
                            value: x.id,
                            child: Text('${x.name} - Warehouse: ${x.warehouseStock}'),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() => productId = value ?? productId),
                      ),
                    ),
                    SizedBox(
                      width: 180,
                      child: textInput(
                        label: 'Order / Load Quantity',
                        controller: qtyController,
                        number: true,
                      ),
                    ),
                    primaryButton('Save Load', Icons.save_rounded, saveInlineLoad),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        DataCard(
          title: 'Secondary Order History',
          child: state.loads.isEmpty
              ? emptyBox('No secondary orders found.')
              : horizontalTable(
                  DataTable(
                    columnSpacing: 20,
                    horizontalMargin: 8,
                    columns: const [
                      DataColumn(label: Text('Date')),
                      DataColumn(label: Text('Booker')),
                      DataColumn(label: Text('Salesman')),
                      DataColumn(label: Text('Product')),
                      DataColumn(label: Text('Qty')),
                    ],
                    rows: state.loads.map((x) {
                      return DataRow(cells: [
                        DataCell(Text(formatDateForUi(x.date))),
                        DataCell(SizedBox(width: 140, child: Text(state.dsrName(x.dsrId), overflow: TextOverflow.ellipsis))),
                        DataCell(SizedBox(width: 140, child: Text(state.supplierName(x.supplierId), overflow: TextOverflow.ellipsis))),
                        DataCell(SizedBox(width: 180, child: Text(state.productName(x.productId), overflow: TextOverflow.ellipsis))),
                        DataCell(Text(x.quantity.toString())),
                      ]);
                    }).toList(),
                  ),
                ),
        ),
      ],
    );
  }
}

class OrderBookingPage extends StatefulWidget {
  final AppState state;
  final Future<void> Function() onChanged;

  const OrderBookingPage({
    super.key,
    required this.state,
    required this.onChanged,
  });

  @override
  State<OrderBookingPage> createState() => _OrderBookingPageState();
}

class _OrderBookingPageState extends State<OrderBookingPage> {
  final fromController = TextEditingController();
  final toController = TextEditingController();
  String dsrId = '';
  String shopkeeperId = '';
  String productId = '';
  String saleType = '';

  @override
  Widget build(BuildContext context) {
    final state = widget.state;

    final rows = state.sales.where((x) {
      final dateOk = dateInRange(x.date, fromController.text, toController.text);
      final dsrOk = dsrId.isEmpty || x.dsrId == dsrId;
      final shopOk = shopkeeperId.isEmpty || x.shopkeeperId == shopkeeperId;
      final productOk = productId.isEmpty || x.productId == productId;
      final typeOk = saleType.isEmpty ||
          (saleType == 'cash' && x.type == SaleType.cash) ||
          (saleType == 'credit' && x.type == SaleType.credit);
      return dateOk && dsrOk && shopOk && productOk && typeOk;
    }).toList();

    return Column(
      children: [
        moduleHeader(
          title: 'Order Booking / Sales',
          subtitle: 'Book cash or credit sale. DSR stock decreases after sale.',
          buttonText: 'Book Order',
          icon: Icons.point_of_sale_rounded,
          onTap: () => showSaleDialog(context, state, widget.onChanged),
        ),
        const SizedBox(height: 18),
        filterCard(
          title: 'Sales Filters',
          children: [
            filterText('From Date', fromController),
            filterText('To Date', toController),
            filterDropdown(
              label: 'Booker',
              value: dsrId,
              items: state.dsrs.map((x) => FilterOption(x.id, x.name)).toList(),
              onChanged: (value) => setState(() => dsrId = value),
            ),
            filterDropdown(
              label: 'Shopkeeper',
              value: shopkeeperId,
              items: state.shopkeepers.map((x) => FilterOption(x.id, x.shopName)).toList(),
              onChanged: (value) => setState(() => shopkeeperId = value),
            ),
            filterDropdown(
              label: 'Product',
              value: productId,
              items: state.products.map((x) => FilterOption(x.id, x.name)).toList(),
              onChanged: (value) => setState(() => productId = value),
            ),
            filterDropdown(
              label: 'Sale Type',
              value: saleType,
              items: const [
                FilterOption('cash', 'Cash Sale'),
                FilterOption('credit', 'Credit Sale'),
              ],
              onChanged: (value) => setState(() => saleType = value),
            ),
            clearFilterButton(() {
              setState(() {
                fromController.clear();
                toController.clear();
                dsrId = '';
                shopkeeperId = '';
                productId = '';
                saleType = '';
              });
            }),
          ],
        ),
        const SizedBox(height: 18),
        salesTable(state, rows: rows),
      ],
    );
  }
}

class RecoveryPage extends StatefulWidget {
  final AppState state;
  final Future<void> Function() onChanged;

  const RecoveryPage({
    super.key,
    required this.state,
    required this.onChanged,
  });

  @override
  State<RecoveryPage> createState() => _RecoveryPageState();
}

class _RecoveryPageState extends State<RecoveryPage> {
  final fromController = TextEditingController();
  final toController = TextEditingController();
  String dsrId = '';
  String shopkeeperId = '';

  @override
  Widget build(BuildContext context) {
    final state = widget.state;

    final rows = state.recoveries.where((x) {
      final dateOk = dateInRange(x.date, fromController.text, toController.text);
      final dsrOk = dsrId.isEmpty || x.dsrId == dsrId;
      final shopOk = shopkeeperId.isEmpty || x.shopkeeperId == shopkeeperId;
      return dateOk && dsrOk && shopOk;
    }).toList();

    return Column(
      children: [
        moduleHeader(
          title: 'Credit Recovery',
          subtitle: 'Receive pending amount from shopkeeper.',
          buttonText: 'Add Recovery',
          icon: Icons.payments_rounded,
          onTap: () => showRecoveryDialog(context, state, widget.onChanged),
        ),
        const SizedBox(height: 18),
        filterCard(
          title: 'Recovery Filters',
          children: [
            filterText('From Date', fromController),
            filterText('To Date', toController),
            filterDropdown(
              label: 'Booker',
              value: dsrId,
              items: state.dsrs.map((x) => FilterOption(x.id, x.name)).toList(),
              onChanged: (value) => setState(() => dsrId = value),
            ),
            filterDropdown(
              label: 'Shopkeeper',
              value: shopkeeperId,
              items: state.shopkeepers.map((x) => FilterOption(x.id, x.shopName)).toList(),
              onChanged: (value) => setState(() => shopkeeperId = value),
            ),
            clearFilterButton(() {
              setState(() {
                fromController.clear();
                toController.clear();
                dsrId = '';
                shopkeeperId = '';
              });
            }),
          ],
        ),
        const SizedBox(height: 18),
        recoveryTable(state, rows: rows),
      ],
    );
  }
}

class ExpensePage extends StatefulWidget {
  final AppState state;
  final Future<void> Function() onChanged;

  const ExpensePage({
    super.key,
    required this.state,
    required this.onChanged,
  });

  @override
  State<ExpensePage> createState() => _ExpensePageState();
}

class _ExpensePageState extends State<ExpensePage> {
  final fromController = TextEditingController();
  final toController = TextEditingController();
  String dsrId = '';
  String expenseType = '';

  @override
  Widget build(BuildContext context) {
    final state = widget.state;

    final types = state.expenses.map((x) => x.type).toSet().toList();

    final rows = state.expenses.where((x) {
      final dateOk = dateInRange(x.date, fromController.text, toController.text);
      final dsrOk = dsrId.isEmpty || x.dsrId == dsrId;
      final typeOk = expenseType.isEmpty || x.type == expenseType;
      return dateOk && dsrOk && typeOk;
    }).toList();

    return Column(
      children: [
        moduleHeader(
          title: 'Expenses',
          subtitle: 'Fuel, office expense, advance payment, and other payments.',
          buttonText: 'Add Expense',
          icon: Icons.money_off_rounded,
          onTap: () => showExpenseDialog(context, state, widget.onChanged),
        ),
        const SizedBox(height: 18),
        filterCard(
          title: 'Expense Filters',
          children: [
            filterText('From Date', fromController),
            filterText('To Date', toController),
            filterDropdown(
              label: 'Booker',
              value: dsrId,
              items: state.dsrs.map((x) => FilterOption(x.id, x.name)).toList(),
              onChanged: (value) => setState(() => dsrId = value),
            ),
            filterDropdown(
              label: 'Expense Type',
              value: expenseType,
              items: types.map((x) => FilterOption(x, x)).toList(),
              onChanged: (value) => setState(() => expenseType = value),
            ),
            clearFilterButton(() {
              setState(() {
                fromController.clear();
                toController.clear();
                dsrId = '';
                expenseType = '';
              });
            }),
          ],
        ),
        const SizedBox(height: 18),
        expenseTable(state, rows: rows),
      ],
    );
  }
}

class DepositPage extends StatefulWidget {
  final AppState state;
  final Future<void> Function() onChanged;

  const DepositPage({
    super.key,
    required this.state,
    required this.onChanged,
  });

  @override
  State<DepositPage> createState() => _DepositPageState();
}

class _DepositPageState extends State<DepositPage> {
  final fromController = TextEditingController();
  final toController = TextEditingController();
  final partyController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final state = widget.state;

    final rows = state.deposits.where((x) {
      final dateOk = dateInRange(x.date, fromController.text, toController.text);
      final partyOk = partyController.text.trim().isEmpty ||
          x.party.toLowerCase().contains(partyController.text.trim().toLowerCase());
      return dateOk && partyOk;
    }).toList();

    return Column(
      children: [
        moduleHeader(
          title: 'Deposit',
          subtitle: 'Add party/bank deposit with cash denomination.',
          buttonText: 'Add Deposit',
          icon: Icons.account_balance_rounded,
          onTap: () => showDepositDialog(context, state, widget.onChanged),
        ),
        const SizedBox(height: 18),
        filterCard(
          title: 'Deposit Filters',
          children: [
            filterText('From Date', fromController),
            filterText('To Date', toController),
            filterText('Party / Bank', partyController),
            clearFilterButton(() {
              setState(() {
                fromController.clear();
                toController.clear();
                partyController.clear();
              });
            }),
          ],
        ),
        const SizedBox(height: 18),
        depositTable(state, rows: rows),
      ],
    );
  }
}

class ClaimPage extends StatefulWidget {
  final AppState state;
  final Future<void> Function() onChanged;

  const ClaimPage({
    super.key,
    required this.state,
    required this.onChanged,
  });

  @override
  State<ClaimPage> createState() => _ClaimPageState();
}

class _ClaimPageState extends State<ClaimPage> {
  final fromController = TextEditingController();
  final toController = TextEditingController();
  String productId = '';
  String claimType = '';

  @override
  Widget build(BuildContext context) {
    final state = widget.state;

    final types = state.claims.map((x) => x.type).toSet().toList();

    final rows = state.claims.where((x) {
      final dateOk = dateInRange(x.date, fromController.text, toController.text);
      final productOk = productId.isEmpty || x.productId == productId;
      final typeOk = claimType.isEmpty || x.type == claimType;
      return dateOk && productOk && typeOk;
    }).toList();

    return Column(
      children: [
        moduleHeader(
          title: 'Claims / Expiry',
          subtitle: 'Record expired product, damage, return, or claim.',
          buttonText: 'Add Claim',
          icon: Icons.report_problem_rounded,
          onTap: () => showClaimDialog(context, state, widget.onChanged),
        ),
        const SizedBox(height: 18),
        filterCard(
          title: 'Claim / Expiry Filters',
          children: [
            filterText('From Date', fromController),
            filterText('To Date', toController),
            filterDropdown(
              label: 'Product',
              value: productId,
              items: state.products.map((x) => FilterOption(x.id, x.name)).toList(),
              onChanged: (value) => setState(() => productId = value),
            ),
            filterDropdown(
              label: 'Type',
              value: claimType,
              items: types.map((x) => FilterOption(x, x)).toList(),
              onChanged: (value) => setState(() => claimType = value),
            ),
            clearFilterButton(() {
              setState(() {
                fromController.clear();
                toController.clear();
                productId = '';
                claimType = '';
              });
            }),
          ],
        ),
        const SizedBox(height: 18),
        claimTable(state, rows: rows),
      ],
    );
  }
}

enum ReportType {
  dsrDailySales,
  dsrWiseSales,
  productWiseSales,
  shopkeeperCredit,
  recovery,
  cashIn,
  deposit,
  expense,
  claimExpiry,
  stock,
  lowStock,
  profitLoss,
}

class _ReportItem {
  final ReportType type;
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const _ReportItem({
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

const List<_ReportItem> _reportItems = [
  _ReportItem(
    type: ReportType.dsrDailySales,
    title: 'DSR Daily Sales Report',
    description: 'Daily DSR sales with bill, shop, product, cash and credit detail.',
    icon: Icons.receipt_long_rounded,
    color: Colors.blue,
  ),
  _ReportItem(
    type: ReportType.dsrWiseSales,
    title: 'DSR-wise Sales Report',
    description: 'Check sales grouped by booker / DSR and selected date filters.',
    icon: Icons.badge_rounded,
    color: Colors.indigo,
  ),
  _ReportItem(
    type: ReportType.productWiseSales,
    title: 'Product-wise Sales',
    description: 'See product sales, quantity, bill value, and selected date history.',
    icon: Icons.inventory_2_rounded,
    color: Colors.deepPurple,
  ),
  _ReportItem(
    type: ReportType.shopkeeperCredit,
    title: 'Shopkeeper Credit Report',
    description: 'Track credit bills, paid recovery, and remaining market credit.',
    icon: Icons.store_rounded,
    color: Colors.orange,
  ),
  _ReportItem(
    type: ReportType.recovery,
    title: 'Recovery Report',
    description: 'All recovered cash from shopkeepers with DSR and balance detail.',
    icon: Icons.call_received_rounded,
    color: Colors.purple,
  ),
  _ReportItem(
    type: ReportType.cashIn,
    title: 'Cash In Report',
    description: 'Cash sale and recovery entries that increase cash balance.',
    icon: Icons.payments_rounded,
    color: Colors.green,
  ),
  _ReportItem(
    type: ReportType.deposit,
    title: 'Deposit Report',
    description: 'Bank or party deposits with note denomination and total amount.',
    icon: Icons.account_balance_rounded,
    color: Colors.teal,
  ),
  _ReportItem(
    type: ReportType.expense,
    title: 'Expense Report',
    description: 'Fuel, office, advance, and other expense history.',
    icon: Icons.money_off_rounded,
    color: Colors.red,
  ),
  _ReportItem(
    type: ReportType.claimExpiry,
    title: 'Claim / Expiry Report',
    description: 'Expired, damaged, returned, and claim stock report.',
    icon: Icons.report_problem_rounded,
    color: Colors.deepOrange,
  ),
  _ReportItem(
    type: ReportType.stock,
    title: 'Stock Report',
    description: 'Current product stock, cartons, batches, prices, and stock value.',
    icon: Icons.warehouse_rounded,
    color: Colors.blueGrey,
  ),
  _ReportItem(
    type: ReportType.lowStock,
    title: 'Low Stock Report',
    description: 'Products that are equal to or below their low stock limit.',
    icon: Icons.warning_rounded,
    color: Colors.amber,
  ),
  _ReportItem(
    type: ReportType.profitLoss,
    title: 'Profit / Loss Summary',
    description: 'Sale profit minus expenses and claim / expiry amount.',
    icon: Icons.bar_chart_rounded,
    color: Colors.green,
  ),
];

class ReportsPage extends StatelessWidget {
  final AppState state;
  final Future<void> Function() onChanged;

  const ReportsPage({super.key, required this.state, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DataCard(
          title: 'Reports Center',
          child: const Text(
            'Tap any report to open full details with date, day, month, and year filters.',
            style: TextStyle(color: Color(0xff6b7280), height: 1.5),
          ),
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = 14.0;
            final maxWidth = constraints.maxWidth;
            final columns = maxWidth >= 1150
                ? 4
                : maxWidth >= 850
                    ? 3
                    : maxWidth >= 560
                        ? 2
                        : 1;
            final cardWidth = (maxWidth - (gap * (columns - 1))) / columns;

            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: _reportItems.map((item) {
                return SizedBox(
                  width: cardWidth,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReportDetailPage(state: state, item: item),
                          ),
                        );
                      },
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 168),
                        padding: const EdgeInsets.all(18),
                        decoration: cardDecoration(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: item.color.withOpacity(0.12),
                                  child: Icon(item.icon, color: item.color),
                                ),
                                const Spacer(),
                                Icon(Icons.arrow_forward_rounded, color: item.color),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(
                              item.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                color: AppTheme.dark,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item.description,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xff6b7280),
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class ReportDetailPage extends StatefulWidget {
  final AppState state;
  final _ReportItem item;

  const ReportDetailPage({super.key, required this.state, required this.item});

  @override
  State<ReportDetailPage> createState() => _ReportDetailPageState();
}

class _ReportDetailPageState extends State<ReportDetailPage> {
  final fromController = TextEditingController();
  final toController = TextEditingController();
  final dayController = TextEditingController();
  final monthController = TextEditingController();
  final yearController = TextEditingController();

  AppState get state => widget.state;

  @override
  void dispose() {
    fromController.dispose();
    toController.dispose();
    dayController.dispose();
    monthController.dispose();
    yearController.dispose();
    super.dispose();
  }

  bool dateOk(String date) {
    final clean = date.trim();
    if (clean.isEmpty) return true;

    if (!dateInRange(clean, fromController.text, toController.text)) {
      return false;
    }

    final parts = clean.split('-');
    if (parts.length == 3) {
      final year = yearController.text.trim();
      final month = monthController.text.trim().padLeft(monthController.text.trim().isEmpty ? 0 : 2, '0');
      final day = dayController.text.trim().padLeft(dayController.text.trim().isEmpty ? 0 : 2, '0');

      if (year.isNotEmpty && parts[0] != year) return false;
      if (month.isNotEmpty && parts[1] != month) return false;
      if (day.isNotEmpty && parts[2] != day) return false;
    }

    return true;
  }

  List<SaleEntry> filteredSales({SaleType? type}) {
    return state.sales.where((sale) {
      if (type != null && sale.type != type) return false;
      return dateOk(sale.date);
    }).toList();
  }

  List<RecoveryEntry> filteredRecoveries() => state.recoveries.where((item) => dateOk(item.date)).toList();
  List<ExpenseEntry> filteredExpenses() => state.expenses.where((item) => dateOk(item.date)).toList();
  List<DepositEntry> filteredDeposits() => state.deposits.where((item) => dateOk(item.date)).toList();
  List<ClaimEntry> filteredClaims() => state.claims.where((item) => dateOk(item.date)).toList();
  List<CompanyPurchase> filteredPurchases() => state.companyPurchases.where((item) => dateOk(item.date)).toList();

  Widget filterInput(String label, TextEditingController controller, {double width = 150, bool number = false}) {
    return SizedBox(
      width: width,
      child: TextField(
        controller: controller,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          hintText: label.contains('Date') ? 'YYYY-MM-DD' : null,
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  double get filteredTotal {
    switch (widget.item.type) {
      case ReportType.dsrDailySales:
      case ReportType.dsrWiseSales:
      case ReportType.productWiseSales:
        return filteredSales().fold<double>(0, (sum, item) => sum + item.total);
      case ReportType.shopkeeperCredit:
        final credit = filteredSales(type: SaleType.credit).fold<double>(0, (sum, item) => sum + item.total);
        final recovery = filteredRecoveries().fold<double>(0, (sum, item) => sum + item.receivedAmount);
        return credit - recovery;
      case ReportType.recovery:
        return filteredRecoveries().fold<double>(0, (sum, item) => sum + item.receivedAmount);
      case ReportType.cashIn:
        final cash = filteredSales(type: SaleType.cash).fold<double>(0, (sum, item) => sum + item.total);
        final recovery = filteredRecoveries().fold<double>(0, (sum, item) => sum + item.receivedAmount);
        return cash + recovery;
      case ReportType.deposit:
        return filteredDeposits().fold<double>(0, (sum, item) => sum + item.total);
      case ReportType.expense:
        return filteredExpenses().fold<double>(0, (sum, item) => sum + item.amount);
      case ReportType.claimExpiry:
        return filteredClaims().fold<double>(0, (sum, item) => sum + item.amount);
      case ReportType.stock:
        return state.stockValue;
      case ReportType.lowStock:
        return state.products.where((item) => item.warehouseStock <= item.lowStockLimit).fold<double>(0, (sum, item) => sum + (item.warehouseStock * item.purchasePrice));
      case ReportType.profitLoss:
        final saleProfit = filteredSales().fold<double>(0, (sum, sale) {
          final cost = (state.productById(sale.productId)?.purchasePrice ?? 0) * sale.quantity;
          return sum + sale.total - cost;
        });
        final expenses = filteredExpenses().fold<double>(0, (sum, item) => sum + item.amount);
        final claims = filteredClaims().fold<double>(0, (sum, item) => sum + item.amount);
        return saleProfit - expenses - claims;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final pagePadding = screen.width < 520
        ? 12.0
        : screen.width < 980
            ? 14.0
            : 18.0;

    return Scaffold(
      backgroundColor: AppTheme.softBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DataCard(
                title: widget.item.title,
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: widget.item.color.withOpacity(0.12),
                      child: Icon(widget.item.icon, color: widget.item.color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Filtered Total: ${state.rs(filteredTotal)}',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.item.description,
                            style: const TextStyle(color: Color(0xff6b7280), height: 1.4),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('Back'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              filterCard(
                title: 'Report Filters',
                children: [
                  filterInput('From Date', fromController, width: 160),
                  filterInput('To Date', toController, width: 160),
                  filterInput('Day', dayController, width: 100, number: true),
                  filterInput('Month', monthController, width: 110, number: true),
                  filterInput('Year', yearController, width: 110, number: true),
                  clearFilterButton(() {
                    setState(() {
                      fromController.clear();
                      toController.clear();
                      dayController.clear();
                      monthController.clear();
                      yearController.clear();
                    });
                  }),
                ],
              ),
              const SizedBox(height: 18),
              reportBody(),
            ],
          ),
        ),
      ),
    );
  }

  Widget reportBody() {
    switch (widget.item.type) {
      case ReportType.dsrDailySales:
        return salesTable(state, rows: filteredSales());
      case ReportType.dsrWiseSales:
        return groupedDsrSalesReport();
      case ReportType.productWiseSales:
        return groupedProductSalesReport();
      case ReportType.shopkeeperCredit:
        return shopkeeperCreditReport();
      case ReportType.recovery:
        return recoveryTable(state, rows: filteredRecoveries());
      case ReportType.cashIn:
        return cashInReport();
      case ReportType.deposit:
        return depositTable(state, rows: filteredDeposits());
      case ReportType.expense:
        return expenseTable(state, rows: filteredExpenses());
      case ReportType.claimExpiry:
        return claimTable(state, rows: filteredClaims());
      case ReportType.stock:
        return stockReport(lowOnly: false);
      case ReportType.lowStock:
        return stockReport(lowOnly: true);
      case ReportType.profitLoss:
        return profitLossReport();
    }
  }

  Widget reportTable({required String title, required List<String> headers, required List<List<String>> rows}) {
    return DataCard(
      title: title,
      child: rows.isEmpty
          ? emptyBox('No records found for selected filters.')
          : horizontalTable(
              DataTable(
                columns: headers.map((header) => DataColumn(label: Text(header))).toList(),
                rows: rows.map((row) => DataRow(cells: row.map((cell) => DataCell(Text(cell))).toList())).toList(),
              ),
            ),
    );
  }

  Widget groupedDsrSalesReport() {
    final rows = state.dsrs.map((dsr) {
      final sales = filteredSales().where((sale) => sale.dsrId == dsr.id).toList();
      final cash = sales.where((sale) => sale.type == SaleType.cash).fold<double>(0, (sum, sale) => sum + sale.total);
      final credit = sales.where((sale) => sale.type == SaleType.credit).fold<double>(0, (sum, sale) => sum + sale.total);
      final total = sales.fold<double>(0, (sum, sale) => sum + sale.total);
      return [
        dsr.name,
        dsr.route.isEmpty ? '-' : dsr.route,
        sales.length.toString(),
        state.rs(cash),
        state.rs(credit),
        state.rs(total),
      ];
    }).where((row) => row[2] != '0').toList();

    return reportTable(
      title: 'DSR-wise Sales Summary',
      headers: const ['Booker', 'Route', 'Bills', 'Cash Sale', 'Credit Sale', 'Total Sale'],
      rows: rows,
    );
  }

  Widget groupedProductSalesReport() {
    final rows = state.products.map((product) {
      final sales = filteredSales().where((sale) => sale.productId == product.id).toList();
      final qty = sales.fold<int>(0, (sum, sale) => sum + sale.quantity);
      final total = sales.fold<double>(0, (sum, sale) => sum + sale.total);
      return [
        product.name,
        product.brand.isEmpty ? '-' : product.brand,
        product.batchNo.isEmpty ? '-' : product.batchNo,
        qty.toString(),
        sales.length.toString(),
        state.rs(total),
      ];
    }).where((row) => row[3] != '0').toList();

    return reportTable(
      title: 'Product-wise Sales Summary',
      headers: const ['Product', 'Brand', 'Batch', 'Qty Sold', 'Bills', 'Total Sale'],
      rows: rows,
    );
  }

  Widget shopkeeperCreditReport() {
    final rows = state.shopkeepers.map((shop) {
      final creditSales = filteredSales(type: SaleType.credit).where((sale) => sale.shopkeeperId == shop.id).toList();
      final recoveries = filteredRecoveries().where((recovery) => recovery.shopkeeperId == shop.id).toList();
      final credit = creditSales.fold<double>(0, (sum, sale) => sum + sale.total);
      final paid = recoveries.fold<double>(0, (sum, recovery) => sum + recovery.receivedAmount);
      final balance = credit - paid;
      return [
        shop.shopName,
        shop.ownerName.isEmpty ? '-' : shop.ownerName,
        state.dsrName(shop.dsrId),
        state.rs(credit),
        state.rs(paid),
        state.rs(balance),
        state.rs(shop.pendingCredit),
      ];
    }).where((row) => row[3] != state.rs(0) || row[4] != state.rs(0) || row[6] != state.rs(0)).toList();

    return reportTable(
      title: 'Shopkeeper Credit Summary',
      headers: const ['Shop', 'Owner', 'Booker', 'Credit Added', 'Paid', 'Filter Balance', 'Current Balance'],
      rows: rows,
    );
  }

  Widget cashInReport() {
    final rows = <_DashboardLedgerRow>[];

    for (final sale in filteredSales(type: SaleType.cash)) {
      rows.add(_DashboardLedgerRow(
        date: sale.date,
        type: 'Cash Sale',
        party: state.shopName(sale.shopkeeperId),
        detail: '${sale.billNo} • ${state.productName(sale.productId)}',
        amount: sale.total,
      ));
    }

    for (final recovery in filteredRecoveries()) {
      rows.add(_DashboardLedgerRow(
        date: recovery.date,
        type: 'Recovery',
        party: state.shopName(recovery.shopkeeperId),
        detail: recovery.chequeBillNo.isEmpty ? '-' : recovery.chequeBillNo,
        amount: recovery.receivedAmount,
      ));
    }

    rows.sort((a, b) => b.date.compareTo(a.date));

    return reportTable(
      title: 'Cash In History',
      headers: const ['Date', 'Type', 'Party', 'Detail', 'Amount'],
      rows: rows.map((row) {
        return [
          formatDateForUi(row.date),
          row.type,
          row.party,
          row.detail,
          state.rs(row.amount),
        ];
      }).toList(),
    );
  }

  Widget stockReport({required bool lowOnly}) {
    final products = lowOnly
        ? state.products.where((product) => product.warehouseStock <= product.lowStockLimit).toList()
        : state.products;

    return reportTable(
      title: lowOnly ? 'Low Stock Products' : 'Current Stock Report',
      headers: const ['Product', 'Brand', 'Batch', 'MFG', 'EXP', 'Packets', 'Per Carton', 'Cartons', 'Purchase', 'Selling', 'Value'],
      rows: products.map((product) {
        final cartons = product.packetsPerCarton <= 0 ? 0 : product.warehouseStock / product.packetsPerCarton;
        final value = product.warehouseStock * product.purchasePrice;
        return [
          product.name,
          product.brand.isEmpty ? '-' : product.brand,
          product.batchNo.isEmpty ? '-' : product.batchNo,
          product.mfgDate.isEmpty ? '-' : product.mfgDate,
          product.expDate.isEmpty ? '-' : product.expDate,
          product.warehouseStock.toString(),
          product.packetsPerCarton.toString(),
          cartons.toStringAsFixed(cartons == cartons.roundToDouble() ? 0 : 1),
          state.rs(product.purchasePrice),
          state.rs(product.sellingPrice),
          state.rs(value),
        ];
      }).toList(),
    );
  }

  Widget profitLossReport() {
    final sales = filteredSales();
    final expenses = filteredExpenses();
    final claims = filteredClaims();

    final saleTotal = sales.fold<double>(0, (sum, sale) => sum + sale.total);
    final costTotal = sales.fold<double>(0, (sum, sale) {
      final product = state.productById(sale.productId);
      return sum + ((product?.purchasePrice ?? 0) * sale.quantity);
    });
    final grossProfit = saleTotal - costTotal;
    final expenseTotal = expenses.fold<double>(0, (sum, item) => sum + item.amount);
    final claimTotal = claims.fold<double>(0, (sum, item) => sum + item.amount);
    final netProfit = grossProfit - expenseTotal - claimTotal;

    return Column(
      children: [
        reportTable(
          title: 'Profit / Loss Summary',
          headers: const ['Particular', 'Amount'],
          rows: [
            ['Sale Total', state.rs(saleTotal)],
            ['Product Cost', state.rs(costTotal)],
            ['Gross Profit', state.rs(grossProfit)],
            ['Expenses', state.rs(expenseTotal)],
            ['Claim / Expiry Loss', state.rs(claimTotal)],
            ['Net Profit / Loss', state.rs(netProfit)],
          ],
        ),
        const SizedBox(height: 18),
        reportTable(
          title: 'Sale Profit Detail',
          headers: const ['Date', 'Bill No', 'Product', 'Qty', 'Sale Total', 'Cost', 'Profit'],
          rows: sales.map((sale) {
            final product = state.productById(sale.productId);
            final cost = (product?.purchasePrice ?? 0) * sale.quantity;
            final profit = sale.total - cost;
            return [
              formatDateForUi(sale.date),
              sale.billNo,
              state.productName(sale.productId),
              sale.quantity.toString(),
              state.rs(sale.total),
              state.rs(cost),
              state.rs(profit),
            ];
          }).toList(),
        ),
      ],
    );
  }
}


class DsrReportPage extends StatefulWidget {
  final AppState state;
  final Future<void> Function() onChanged;

  const DsrReportPage({super.key, required this.state, required this.onChanged});

  @override
  State<DsrReportPage> createState() => _DsrReportPageState();
}

class _DsrReportPageState extends State<DsrReportPage> {
  String? selectedDsrId;
  late String selectedDate;

  final returnStockController = TextEditingController(text: '0');
  final extraAmountController = TextEditingController(text: '0');

  final note5000Controller = TextEditingController(text: '0');
  final note1000Controller = TextEditingController(text: '0');
  final note500Controller = TextEditingController(text: '0');
  final note100Controller = TextEditingController(text: '0');
  final note50Controller = TextEditingController(text: '0');
  final note20Controller = TextEditingController(text: '0');
  final note10Controller = TextEditingController(text: '0');
  final coinsController = TextEditingController(text: '0');

  double get physicalCash {
    return (toInt(note5000Controller.text) * 5000) +
        (toInt(note1000Controller.text) * 1000) +
        (toInt(note500Controller.text) * 500) +
        (toInt(note100Controller.text) * 100) +
        (toInt(note50Controller.text) * 50) +
        (toInt(note20Controller.text) * 20) +
        (toInt(note10Controller.text) * 10) +
        toDouble(coinsController.text);
  }

  @override
  void initState() {
    super.initState();
    selectedDate = widget.state.today;
    if (widget.state.dsrs.isNotEmpty) selectedDsrId = widget.state.dsrs.first.id;
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;

    if (state.dsrs.isEmpty) {
      return DataCard(title: 'DSR Daily Report', child: emptyBox('Add DSR first.'));
    }

    selectedDsrId ??= state.dsrs.first.id;

    final report = state.buildDsrDailyReport(
      dsrId: selectedDsrId!,
      date: selectedDate,
      returnStockAmount: toDouble(returnStockController.text),
      extraAmount: toDouble(extraAmountController.text),
      physicalCash: physicalCash,
    );

    final creditBills = state.salesFor(selectedDsrId!, selectedDate).where((x) => x.type == SaleType.credit).toList();
    final recoveryBills = state.recoveriesFor(selectedDsrId!, selectedDate);

    return Column(
      children: [
        DataCard(
          title: 'DSR Daily Report Controls',
          child: Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              SizedBox(
                width: 230,
                child: DropdownButtonFormField<String>(
                  value: selectedDsrId,
                  decoration: const InputDecoration(labelText: 'Select DSR'),
                  items: state.dsrs.map((x) => DropdownMenuItem(value: x.id, child: Text(x.name))).toList(),
                  onChanged: (value) => setState(() => selectedDsrId = value),
                ),
              ),
              SizedBox(
                width: 170,
                child: TextFormField(
                  initialValue: selectedDate,
                  decoration: const InputDecoration(labelText: 'Date'),
                  onChanged: (value) => setState(() => selectedDate = value),
                ),
              ),
              SizedBox(
                width: 180,
                child: TextField(
                  controller: returnStockController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Return Stock Amount'),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              SizedBox(
                width: 160,
                child: TextField(
                  controller: extraAmountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Extra Amount'),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              primaryButton('Save Cash Count', Icons.save_rounded, () async {
                await runAction(
                  context,
                  () => state.service.upsertCashCount(
                    companyId: state.companyId,
                    dsrId: selectedDsrId!,
                    date: selectedDate,
                    note5000: toInt(note5000Controller.text),
                    note1000: toInt(note1000Controller.text),
                    note500: toInt(note500Controller.text),
                    note100: toInt(note100Controller.text),
                    note50: toInt(note50Controller.text),
                    note20: toInt(note20Controller.text),
                    note10: toInt(note10Controller.text),
                    coins: toDouble(coinsController.text),
                  ),
                  widget.onChanged,
                );
              }),
              primaryButton('Print Preview', Icons.print_rounded, () {
                showDsrPrintPreview(
                  context: context,
                  state: state,
                  report: report,
                  dsrName: state.dsrName(selectedDsrId!),
                  creditBills: creditBills,
                  recoveryBills: recoveryBills,
                  cashRows: [
                    CashDenominationRow(
                      note: '5000',
                      count: toInt(note5000Controller.text),
                      amount: toInt(note5000Controller.text) * 5000.0,
                    ),
                    CashDenominationRow(
                      note: '1000',
                      count: toInt(note1000Controller.text),
                      amount: toInt(note1000Controller.text) * 1000.0,
                    ),
                    CashDenominationRow(
                      note: '500',
                      count: toInt(note500Controller.text),
                      amount: toInt(note500Controller.text) * 500.0,
                    ),
                    CashDenominationRow(
                      note: '100',
                      count: toInt(note100Controller.text),
                      amount: toInt(note100Controller.text) * 100.0,
                    ),
                    CashDenominationRow(
                      note: '50',
                      count: toInt(note50Controller.text),
                      amount: toInt(note50Controller.text) * 50.0,
                    ),
                    CashDenominationRow(
                      note: '20',
                      count: toInt(note20Controller.text),
                      amount: toInt(note20Controller.text) * 20.0,
                    ),
                    CashDenominationRow(
                      note: '10',
                      count: toInt(note10Controller.text),
                      amount: toInt(note10Controller.text) * 10.0,
                    ),
                    CashDenominationRow(
                      note: 'Coins',
                      count: 1,
                      amount: toDouble(coinsController.text),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 18),
        responsiveTwo(reportCard(report), denominationCard()),
        const SizedBox(height: 18),
        detailTable('Detail of Credit Bills', const ['Bill No', 'Date', 'Shop Name', 'Amount'], creditBills.map((x) => [x.billNo, x.date, state.shopName(x.shopkeeperId), state.rs(x.total)]).toList()),
        const SizedBox(height: 18),
        detailTable('Detail of Recovery Bills', const ['Bill No', 'Date', 'Shop Name', 'Received', 'Balance'], recoveryBills.map((x) => [x.chequeBillNo, x.date, state.shopName(x.shopkeeperId), state.rs(x.receivedAmount), state.rs(x.balanceAfter)]).toList()),
      ],
    );
  }

  Widget reportCard(DsrDailyReport report) {
    return DataCard(
      title: 'DSR Cash Calculation',
      child: Column(
        children: [
          calcRow('Gross Sale', report.grossSale),
          calcRow('Return Stock Amount', -report.returnStockAmount),
          calcRow('Extra Amount', report.extraAmount),
          const Divider(),
          calcRow('Net Sale', report.netSale, bold: true),
          calcRow('Less Fuel', -report.fuelExpense),
          calcRow('Less Office Expense', -report.officeExpense),
          calcRow('Less Credit', -report.creditSale),
          const Divider(),
          calcRow('Net Cash Sale', report.netCashSale, bold: true),
          calcRow('Plus Recovery', report.recovery),
          const Divider(),
          calcRow('Total DSR Cash', report.totalDsrCash, bold: true, color: AppTheme.primary),
          calcRow('Physical Cash', report.physicalCash),
          calcRow('Short', report.shortAmount, color: Colors.red),
          calcRow('Excess', report.excessAmount, color: Colors.green),
        ],
      ),
    );
  }

  Widget denominationCard() {
    return DataCard(
      title: 'Cash Denomination',
      child: Column(
        children: [
          cashRow('5000', note5000Controller, 5000),
          cashRow('1000', note1000Controller, 1000),
          cashRow('500', note500Controller, 500),
          cashRow('100', note100Controller, 100),
          cashRow('50', note50Controller, 50),
          cashRow('20', note20Controller, 20),
          cashRow('10', note10Controller, 10),
          textInput(label: 'Coins', controller: coinsController, number: true, onChanged: (_) => setState(() {})),
          const SizedBox(height: 12),
          Text('Total Physical Cash: ${widget.state.rs(physicalCash)}', style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.primary)),
        ],
      ),
    );
  }

  Widget cashRow(String title, TextEditingController controller, int noteValue) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(width: 70, child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800))),
          const Text('x'),
          const SizedBox(width: 10),
          SizedBox(
            width: 90,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(isDense: true, labelText: 'Count'),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text('= ${widget.state.rs(toInt(controller.text) * noteValue.toDouble())}')),
        ],
      ),
    );
  }

  Widget calcRow(String title, double value, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(title, style: TextStyle(fontWeight: bold ? FontWeight.w900 : FontWeight.w500))),
          Text(widget.state.rs(value), style: TextStyle(fontWeight: bold ? FontWeight.w900 : FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

Widget tablePage({
  required String title,
  required String subtitle,
  required String buttonText,
  required IconData icon,
  required VoidCallback onTap,
  required DataTable table,
}) {
  return Column(
    children: [
      moduleHeader(title: title, subtitle: subtitle, buttonText: buttonText, icon: icon, onTap: onTap),
      const SizedBox(height: 18),
      DataCard(title: '$title List', child: horizontalTable(table)),
    ],
  );
}


Widget moduleHeader({
  required String title,
  required String subtitle,
  required String buttonText,
  required IconData icon,
  required VoidCallback onTap,
}) {
  return DataCard(
    title: title,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xff6b7280),
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(width: 14),
        primaryButton(buttonText, icon, onTap),
      ],
    ),
  );
}

Widget detailTable(String title, List<String> headers, List<List<String>> rows) {
  return DataCard(
    title: title,
    child: rows.isEmpty
        ? emptyBox('No records found.')
        : horizontalTable(
            DataTable(
              columns: headers.map((x) => DataColumn(label: Text(x))).toList(),
              rows: rows.map((row) => DataRow(cells: row.map((cell) => DataCell(Text(cell))).toList())).toList(),
            ),
          ),
  );
}


Widget productTable(
  AppState state, {
  BuildContext? context,
  Future<void> Function()? onChanged,
}) {
  return DataCard(
    title: 'Primary Receiving Products',
    child: state.products.isEmpty
        ? emptyBox('No primary receiving products found.')
        : horizontalTable(
            DataTable(
              columnSpacing: 12,
              horizontalMargin: 6,
              dataRowMinHeight: 50,
              dataRowMaxHeight: 64,
              headingRowHeight: 44,
              columns: const [
                DataColumn(label: Text('Product')),
                DataColumn(label: Text('Brand')),
                DataColumn(label: Text('Batch')),
                DataColumn(label: Text('MFG')),
                DataColumn(label: Text('EXP')),
                DataColumn(label: Text('Pack')),
                DataColumn(label: Text('Packet Buy')),
                DataColumn(label: Text('Packet Sell')),
                DataColumn(label: Text('Carton Sell')),
                DataColumn(label: Text('Stock Packets')),
                DataColumn(label: Text('Stock Cartons')),
                DataColumn(label: Text('Company Disc.')),
                DataColumn(label: Text('Trade Disc.')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Actions')),
              ],
              rows: state.products.map((x) {
                final low = x.warehouseStock <= x.lowStockLimit;
                final cartons = x.packetsPerCarton <= 0 ? 0 : x.warehouseStock / x.packetsPerCarton;

                return DataRow(
                  cells: [
                    DataCell(SizedBox(width: 120, child: Text(x.name, overflow: TextOverflow.ellipsis))),
                    DataCell(SizedBox(width: 88, child: Text(x.brand.isEmpty ? '-' : x.brand, overflow: TextOverflow.ellipsis))),
                    DataCell(SizedBox(width: 92, child: Text(x.batchNo.isEmpty ? '-' : x.batchNo, overflow: TextOverflow.ellipsis))),
                    DataCell(Text(formatDateForUi(x.mfgDate))),
                    DataCell(Text(formatDateForUi(x.expDate))),
                    DataCell(Text('1 carton = ${x.packetsPerCarton}')),
                    DataCell(Text(state.rs(x.purchasePrice))),
                    DataCell(Text(state.rs(x.sellingPrice))),
                    DataCell(Text(state.rs(x.cartonSellingPrice))),
                    DataCell(Text(x.warehouseStock.toString())),
                    DataCell(Text(cartons.toStringAsFixed(cartons == cartons.roundToDouble() ? 0 : 1))),
                    DataCell(Text(state.rs(x.companyDiscount))),
                    DataCell(Text(state.rs(x.tradeDiscount))),
                    DataCell(
                      Chip(
                        label: Text(low ? 'Low' : 'Avail'),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        backgroundColor: low
                            ? const Color(0xffffe4e6)
                            : const Color(0xffdcfce7),
                      ),
                    ),
                    DataCell(
                      context == null || onChanged == null
                          ? const Text('-')
                          : SizedBox(
                              width: 76,
                              child: actionButtons(
                                onEdit: () => showProductDialog(context, state, onChanged, editItem: x),
                                onDelete: () => confirmDelete(
                                  context: context,
                                  title: 'Delete Product',
                                  message: 'Are you sure you want to delete this product? This is only allowed when no stock, load, or sales are linked.',
                                  action: () => state.service.deleteProduct(x.id),
                                  onChanged: onChanged,
                                ),
                              ),
                            ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
  );
}

Widget purchaseSummaryCards(AppState state) {
  return Wrap(
    spacing: 14,
    runSpacing: 14,
    children: [
      StatCard(title: 'Purchase Total', value: state.rs(state.purchaseTotal), icon: Icons.receipt_long_rounded, color: Colors.indigo),
      StatCard(title: 'Company Payable', value: state.rs(state.companyPayable), icon: Icons.account_balance_rounded, color: Colors.red),
      StatCard(title: 'Purchase Entries', value: state.companyPurchases.length.toString(), icon: Icons.inventory_2_rounded, color: Colors.green),
    ],
  );
}

Widget companyPurchaseTable(AppState state, {BuildContext? context}) {
  return DataCard(
    title: 'Company Purchase / Invoice History',
    child: state.companyPurchases.isEmpty
        ? emptyBox('No company purchases found.')
        : horizontalTable(
            DataTable(
              columnSpacing: 6,
              horizontalMargin: 6,
              headingRowHeight: 42,
              dataRowMinHeight: 46,
              dataRowMaxHeight: 54,
              columns: const [
                DataColumn(label: Text('Date')),
                DataColumn(label: Text('Inv')),
                DataColumn(label: Text('Company')),
                DataColumn(label: Text('Product')),
                DataColumn(label: Text('Batch')),
                DataColumn(label: Text('CTN')),
                DataColumn(label: Text('Pack')),
                DataColumn(label: Text('Qty')),
                DataColumn(label: Text('Rate')),
                DataColumn(label: Text('Gross')),
                DataColumn(label: Text('Disc')),
                DataColumn(label: Text('Net')),
                DataColumn(label: Text('Paid')),
                DataColumn(label: Text('Bal')),
                DataColumn(label: Text('View')),
              ],
              rows: state.companyPurchases.map((x) {
                final gross = x.totalPackets * x.packetPurchasePrice;
                return DataRow(cells: [
                  DataCell(SizedBox(width: 72, child: Text(formatDateForUi(x.date), overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)))),
                  DataCell(SizedBox(width: 46, child: Text(x.invoiceNo.isEmpty ? '-' : x.invoiceNo, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)))),
                  DataCell(SizedBox(width: 82, child: Text(x.companyName.isEmpty ? '-' : x.companyName, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)))),
                  DataCell(SizedBox(width: 108, child: Text(state.productName(x.productId), overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)))),
                  DataCell(SizedBox(width: 48, child: Text(x.batchNo.isEmpty ? '-' : x.batchNo, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)))),
                  DataCell(SizedBox(width: 36, child: Text(x.cartons.toString(), style: const TextStyle(fontSize: 12)))),
                  DataCell(SizedBox(width: 38, child: Text(x.packetsPerCarton.toString(), style: const TextStyle(fontSize: 12)))),
                  DataCell(SizedBox(width: 44, child: Text(x.totalPackets.toString(), style: const TextStyle(fontSize: 12)))),
                  DataCell(SizedBox(width: 58, child: Text(state.rs(x.packetPurchasePrice), overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)))),
                  DataCell(SizedBox(width: 62, child: Text(state.rs(gross), overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)))),
                  DataCell(SizedBox(width: 50, child: Text(state.rs(x.companyDiscount), overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)))),
                  DataCell(SizedBox(width: 62, child: Text(state.rs(x.totalBill), overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)))),
                  DataCell(SizedBox(width: 58, child: Text(state.rs(x.paidAmount), overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)))),
                  DataCell(SizedBox(width: 58, child: Text(state.rs(x.remainingAmount), overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)))),
                  DataCell(
                    SizedBox(
                      width: 38,
                      child: context == null
                          ? const Text('-')
                          : IconButton(
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                              tooltip: 'View invoice',
                              icon: const Icon(Icons.receipt_long_rounded, color: AppTheme.primary, size: 20),
                              onPressed: () => showCompanyInvoicePreview(context, state, x),
                            ),
                    ),
                  ),
                ]);
              }).toList(),
            ),
          ),
  );
}


Widget salesTable(AppState state, {List<SaleEntry>? rows}) {
  final data = rows ?? state.sales;

  return DataCard(
    title: 'Sales History',
    child: data.isEmpty
        ? emptyBox('No sales found.')
        : horizontalTable(
            DataTable(
              columnSpacing: 14,
              horizontalMargin: 8,
              headingRowHeight: 44,
              dataRowMinHeight: 48,
              dataRowMaxHeight: 56,
              columns: const [
                DataColumn(label: Text('Bill No')),
                DataColumn(label: Text('Date')),
                DataColumn(label: Text('Booker')),
                DataColumn(label: Text('Shop')),
                DataColumn(label: Text('Product')),
                DataColumn(label: Text('Qty')),
                DataColumn(label: Text('Price')),
                DataColumn(label: Text('Type')),
                DataColumn(label: Text('Total')),
              ],
              rows: data.map((x) {
                return DataRow(
                  cells: [
                    DataCell(SizedBox(width: 82, child: Text(x.billNo, overflow: TextOverflow.ellipsis))),
                    DataCell(SizedBox(width: 92, child: Text(formatDateForUi(x.date), overflow: TextOverflow.ellipsis))),
                    DataCell(SizedBox(width: 110, child: Text(state.dsrName(x.dsrId), overflow: TextOverflow.ellipsis))),
                    DataCell(SizedBox(width: 130, child: Text(state.shopName(x.shopkeeperId), overflow: TextOverflow.ellipsis))),
                    DataCell(SizedBox(width: 130, child: Text(state.productName(x.productId), overflow: TextOverflow.ellipsis))),
                    DataCell(SizedBox(width: 42, child: Text(x.quantity.toString()))),
                    DataCell(SizedBox(width: 70, child: Text(state.rs(x.price), overflow: TextOverflow.ellipsis))),
                    DataCell(SizedBox(width: 58, child: Text(x.type == SaleType.cash ? 'Cash' : 'Credit', overflow: TextOverflow.ellipsis))),
                    DataCell(SizedBox(width: 82, child: Text(state.rs(x.total), overflow: TextOverflow.ellipsis))),
                  ],
                );
              }).toList(),
            ),
          ),
  );
}

Widget recoveryTable(AppState state, {List<RecoveryEntry>? rows}) {
  final data = rows ?? state.recoveries;

  return DataCard(
    title: 'Recovery History',
    child: data.isEmpty
        ? emptyBox('No recovery found.')
        : horizontalTable(
            DataTable(
              columns: const [
                DataColumn(label: Text('Cheque/Bill No')),
                DataColumn(label: Text('Date')),
                DataColumn(label: Text('Booker')),
                DataColumn(label: Text('Shop')),
                DataColumn(label: Text('Received')),
                DataColumn(label: Text('Balance')),
              ],
              rows: data.map((x) {
                return DataRow(
                  cells: [
                    DataCell(Text(x.chequeBillNo)),
                    DataCell(Text(x.date)),
                    DataCell(Text(state.dsrName(x.dsrId))),
                    DataCell(Text(state.shopName(x.shopkeeperId))),
                    DataCell(Text(state.rs(x.receivedAmount))),
                    DataCell(Text(state.rs(x.balanceAfter))),
                  ],
                );
              }).toList(),
            ),
          ),
  );
}

Widget expenseTable(AppState state, {List<ExpenseEntry>? rows}) {
  final data = rows ?? state.expenses;

  return DataCard(
    title: 'Expense History',
    child: data.isEmpty
        ? emptyBox('No expenses found.')
        : horizontalTable(
            DataTable(
              columns: const [
                DataColumn(label: Text('Date')),
                DataColumn(label: Text('Booker')),
                DataColumn(label: Text('Type')),
                DataColumn(label: Text('Amount')),
                DataColumn(label: Text('Note')),
              ],
              rows: data.map((x) {
                return DataRow(
                  cells: [
                    DataCell(Text(x.date)),
                    DataCell(Text(state.dsrName(x.dsrId))),
                    DataCell(Text(x.type)),
                    DataCell(Text(state.rs(x.amount))),
                    DataCell(Text(x.note)),
                  ],
                );
              }).toList(),
            ),
          ),
  );
}

Widget depositTable(AppState state, {List<DepositEntry>? rows}) {
  final data = rows ?? state.deposits;

  return DataCard(
    title: 'Deposit History',
    child: data.isEmpty
        ? emptyBox('No deposits found.')
        : horizontalTable(
            DataTable(
              columns: const [
                DataColumn(label: Text('Date')),
                DataColumn(label: Text('Party')),
                DataColumn(label: Text('5000')),
                DataColumn(label: Text('1000')),
                DataColumn(label: Text('500')),
                DataColumn(label: Text('100')),
                DataColumn(label: Text('50')),
                DataColumn(label: Text('20')),
                DataColumn(label: Text('10')),
                DataColumn(label: Text('Coins')),
                DataColumn(label: Text('Total')),
              ],
              rows: data.map((x) {
                return DataRow(
                  cells: [
                    DataCell(Text(x.date)),
                    DataCell(Text(x.party)),
                    DataCell(Text(x.note5000.toString())),
                    DataCell(Text(x.note1000.toString())),
                    DataCell(Text(x.note500.toString())),
                    DataCell(Text(x.note100.toString())),
                    DataCell(Text(x.note50.toString())),
                    DataCell(Text(x.note20.toString())),
                    DataCell(Text(x.note10.toString())),
                    DataCell(Text(x.coins.toStringAsFixed(0))),
                    DataCell(Text(state.rs(x.total))),
                  ],
                );
              }).toList(),
            ),
          ),
  );
}

Widget claimTable(AppState state, {List<ClaimEntry>? rows}) {
  final data = rows ?? state.claims;

  return DataCard(
    title: 'Claim / Expiry History',
    child: data.isEmpty
        ? emptyBox('No claims found.')
        : horizontalTable(
            DataTable(
              columns: const [
                DataColumn(label: Text('Date')),
                DataColumn(label: Text('Product')),
                DataColumn(label: Text('Type')),
                DataColumn(label: Text('Qty')),
                DataColumn(label: Text('Amount')),
                DataColumn(label: Text('Note')),
              ],
              rows: data.map((x) {
                return DataRow(
                  cells: [
                    DataCell(Text(x.date)),
                    DataCell(Text(state.productName(x.productId))),
                    DataCell(Text(x.type)),
                    DataCell(Text(x.quantity.toString())),
                    DataCell(Text(state.rs(x.amount))),
                    DataCell(Text(x.note)),
                  ],
                );
              }).toList(),
            ),
          ),
  );
}




class CashDenominationRow {
  final String note;
  final int count;
  final double amount;

  const CashDenominationRow({
    required this.note,
    required this.count,
    required this.amount,
  });
}

void showDsrPrintPreview({
  required BuildContext context,
  required AppState state,
  required DsrDailyReport report,
  required String dsrName,
  required List<SaleEntry> creditBills,
  required List<RecoveryEntry> recoveryBills,
  required List<CashDenominationRow> cashRows,
}) {
  showDialog(
    context: context,
    builder: (dialogContext) {
      return Dialog(
        insetPadding: const EdgeInsets.all(18),
        child: SizedBox(
          width: 980,
          height: MediaQuery.of(context).size.height * 0.90,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'DSR Daily Report Print Preview',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: printCurrentPage,
                      icon: const Icon(Icons.print_rounded, size: 18),
                      label: const Text('Browser Print'),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(22),
                  child: DsrPrintableReport(
                    state: state,
                    report: report,
                    dsrName: dsrName,
                    creditBills: creditBills,
                    recoveryBills: recoveryBills,
                    cashRows: cashRows,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class DsrPrintableReport extends StatelessWidget {
  final AppState state;
  final DsrDailyReport report;
  final String dsrName;
  final List<SaleEntry> creditBills;
  final List<RecoveryEntry> recoveryBills;
  final List<CashDenominationRow> cashRows;

  const DsrPrintableReport({
    super.key,
    required this.state,
    required this.report,
    required this.dsrName,
    required this.creditBills,
    required this.recoveryBills,
    required this.cashRows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 900,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Column(
              children: [
                Text(
                  state.company?.name ?? 'Smart Account Manager',
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  'DSR Daily Sales Report | DSR: $dsrName | Date: ${report.date}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: calculationPrintTable()),
              const SizedBox(width: 14),
              Expanded(child: cashPrintTable()),
            ],
          ),
          const SizedBox(height: 18),
          printTable(
            title: 'Detail of Credit Bills',
            headers: const ['Bill No', 'Date', 'Shop Name', 'Amount'],
            rows: creditBills.map((x) {
              return [
                x.billNo,
                x.date,
                state.shopName(x.shopkeeperId),
                state.rs(x.total),
              ];
            }).toList(),
            totalLabel: 'Total Amount',
            totalValue: state.rs(creditBills.fold(0.0, (sum, item) => sum + item.total)),
          ),
          const SizedBox(height: 18),
          printTable(
            title: 'Detail of Recovery Bills',
            headers: const ['Cheque/Bill No', 'Date', 'Shop Name', 'Received Rs.', 'Balance Rs.'],
            rows: recoveryBills.map((x) {
              return [
                x.chequeBillNo,
                x.date,
                state.shopName(x.shopkeeperId),
                state.rs(x.receivedAmount),
                state.rs(x.balanceAfter),
              ];
            }).toList(),
            totalLabel: 'Total Recovery',
            totalValue: state.rs(recoveryBills.fold(0.0, (sum, item) => sum + item.receivedAmount)),
          ),
        ],
      ),
    );
  }

  Widget calculationPrintTable() {
    return printTable(
      title: 'DSR Cash Calculation',
      headers: const ['Particular', 'Amount'],
      rows: [
        ['Gross Sale', state.rs(report.grossSale)],
        ['Return Stock Amount', state.rs(report.returnStockAmount)],
        ['Extra Amount', state.rs(report.extraAmount)],
        ['Net Sale', state.rs(report.netSale)],
        ['Less Fuel', state.rs(report.fuelExpense)],
        ['Less Office Expense', state.rs(report.officeExpense)],
        ['Less Credit', state.rs(report.creditSale)],
        ['Net Cash Sale', state.rs(report.netCashSale)],
        ['Plus Recovery', state.rs(report.recovery)],
        ['Total DSR Cash', state.rs(report.totalDsrCash)],
        ['Physical Cash', state.rs(report.physicalCash)],
        ['Short', state.rs(report.shortAmount)],
        ['Excess', state.rs(report.excessAmount)],
      ],
    );
  }

  Widget cashPrintTable() {
    return printTable(
      title: 'AFRA TREDAR Range B Cash',
      headers: const ['Note', 'Count', 'Amount'],
      rows: cashRows.map((x) {
        return [
          x.note,
          x.count.toString(),
          state.rs(x.amount),
        ];
      }).toList(),
      totalLabel: 'Total DSR Cash',
      totalValue: state.rs(cashRows.fold(0.0, (sum, item) => sum + item.amount)),
    );
  }
}

Widget printTable({
  required String title,
  required List<String> headers,
  required List<List<String>> rows,
  String? totalLabel,
  String? totalValue,
}) {
  final safeRows = rows.isEmpty
      ? [
          List.generate(headers.length, (index) => index == 0 ? 'No record' : '-')
        ]
      : rows;

  return Container(
    decoration: BoxDecoration(border: Border.all(color: Colors.black87)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.black87)),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        Table(
          border: TableBorder.all(color: Colors.black87),
          columnWidths: {
            for (int i = 0; i < headers.length; i++) i: const FlexColumnWidth(),
          },
          children: [
            TableRow(
              decoration: const BoxDecoration(color: Color(0xfff3f4f6)),
              children: headers.map((x) => printCell(x, bold: true)).toList(),
            ),
            ...safeRows.map((row) {
              return TableRow(
                children: row.map((x) => printCell(x)).toList(),
              );
            }),
            if (totalLabel != null && totalValue != null)
              TableRow(
                children: [
                  printCell(totalLabel, bold: true),
                  for (int i = 1; i < headers.length - 1; i++) printCell(''),
                  printCell(totalValue, bold: true),
                ],
              ),
          ],
        ),
      ],
    ),
  );
}

Widget printCell(String text, {bool bold = false}) {
  return Padding(
    padding: const EdgeInsets.all(7),
    child: Text(
      text,
      style: TextStyle(fontWeight: bold ? FontWeight.w900 : FontWeight.w500, fontSize: 12),
    ),
  );
}


class FilterOption {
  final String value;
  final String label;

  const FilterOption(this.value, this.label);
}

bool dateInRange(String date, String from, String to) {
  final cleanDate = date.trim();
  final cleanFrom = from.trim();
  final cleanTo = to.trim();

  if (cleanFrom.isNotEmpty && cleanDate.compareTo(cleanFrom) < 0) {
    return false;
  }

  if (cleanTo.isNotEmpty && cleanDate.compareTo(cleanTo) > 0) {
    return false;
  }

  return true;
}

String formatDateForUi(String value) {
  final clean = value.trim();
  if (clean.isEmpty) return '-';
  final parts = clean.split('-');
  if (parts.length == 3 && parts[0].length == 4) {
    return '${parts[2]}-${parts[1]}-${parts[0]}';
  }
  return clean;
}

Widget filterCard({
  required String title,
  required List<Widget> children,
}) {
  return DataCard(
    title: title,
    child: Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: children,
    ),
  );
}

Widget filterText(String label, TextEditingController controller) {
  return SizedBox(
    width: 160,
    child: TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: label.contains('Date') ? 'YYYY-MM-DD' : null,
      ),
      onChanged: (_) {},
    ),
  );
}

Widget filterDropdown({
  required String label,
  required String value,
  required List<FilterOption> items,
  required ValueChanged<String> onChanged,
}) {
  return SizedBox(
    width: 190,
    child: DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(labelText: label),
      items: [
        const DropdownMenuItem(value: '', child: Text('All')),
        ...items.map((x) => DropdownMenuItem(value: x.value, child: Text(x.label))),
      ],
      onChanged: (newValue) => onChanged(newValue ?? ''),
    ),
  );
}

Widget clearFilterButton(VoidCallback onPressed) {
  return SizedBox(
    height: 48,
    child: OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.clear_rounded),
      label: const Text('Clear'),
    ),
  );
}

void printCurrentPage() {
  html.window.print();
}






Future<void> runAction(
  BuildContext context,
  Future<void> Function() action,
  Future<void> Function() onChanged,
) async {
  try {
    await action();
    await onChanged();

    if (!context.mounted) return;
    showSnack(
      context,
      'Saved successfully.',
      type: AppToastType.success,
    );
  } catch (error) {
    if (!context.mounted) return;
    showSnack(
      context,
      error.toString().replaceAll('Exception: ', ''),
      type: AppToastType.error,
    );
  }
}

Widget actionButtons({
  required VoidCallback onEdit,
  required VoidCallback? onDelete,
}) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton(
        tooltip: 'Edit',
        onPressed: onEdit,
        icon: const Icon(Icons.edit_rounded, color: AppTheme.primary),
      ),
      IconButton(
        tooltip: onDelete == null ? 'Delete disabled' : 'Delete',
        onPressed: onDelete,
        icon: Icon(
          Icons.delete_rounded,
          color: onDelete == null ? const Color(0xff9ca3af) : Colors.red,
        ),
      ),
    ],
  );
}


Future<void> confirmDelete({
  required BuildContext context,
  required String title,
  required String message,
  required Future<void> Function() action,
  required Future<void> Function() onChanged,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.delete_rounded),
            label: const Text('Delete'),
          ),
        ],
      );
    },
  );

  if (confirmed != true) return;

  await runAction(context, action, onChanged);
}

void showSupplierDialog(BuildContext context, AppState state, Future<void> Function() onChanged, {Supplier? editItem}) {
  final nameController = TextEditingController(text: editItem?.name ?? '');
  final phoneController = TextEditingController(text: editItem?.phone ?? '');
  final addressController = TextEditingController(text: editItem?.address ?? '');

  simpleDialog(
    context: context,
    title: editItem == null ? 'Add Salesman' : 'Edit Salesman',
    children: [
      textInput(label: 'Salesman Name', controller: nameController),
      textInput(label: 'Phone', controller: phoneController),
      textInput(label: 'Address', controller: addressController),
    ],
    onSave: () async {
      await runAction(
        context,
        () => editItem == null
            ? state.service.addSupplier(
                companyId: state.companyId,
                name: nameController.text.trim(),
                phone: phoneController.text.trim(),
                address: addressController.text.trim(),
              )
            : state.service.updateSupplier(
                id: editItem.id,
                name: nameController.text.trim(),
                phone: phoneController.text.trim(),
                address: addressController.text.trim(),
              ),
        onChanged,
      );
    },
  );
}

void showDsrDialog(BuildContext context, AppState state, Future<void> Function() onChanged, {Dsr? editItem}) {
  if (state.suppliers.isEmpty) {
    showSnack(context, 'Add salesman first.');
    return;
  }

  final nameController = TextEditingController(text: editItem?.name ?? '');
  final phoneController = TextEditingController(text: editItem?.phone ?? '');
  final routeController = TextEditingController(text: editItem?.route ?? '');
  final salaryController = TextEditingController(text: editItem?.salary.toStringAsFixed(0) ?? '');

  String supplierId = editItem?.supplierId ?? state.suppliers.first.id;

  statefulDialog(
    context: context,
    title: editItem == null ? 'Add DSR / Booker' : 'Edit DSR / Booker',
    builder: (setDialog) {
      return [
        textInput(label: 'DSR Name', controller: nameController),
        textInput(label: 'Phone', controller: phoneController),
        textInput(label: 'Route / Area', controller: routeController),
        DropdownButtonFormField<String>(
          value: supplierId,
          decoration: const InputDecoration(labelText: 'Assigned Salesman'),
          items: state.suppliers.map((x) => DropdownMenuItem(value: x.id, child: Text(x.name))).toList(),
          onChanged: (value) => setDialog(() => supplierId = value ?? supplierId),
        ),
        textInput(label: 'Salary', controller: salaryController, number: true),
      ];
    },
    onSave: () async {
      await runAction(
        context,
        () => editItem == null
            ? state.service.addDsr(
                companyId: state.companyId,
                supplierId: supplierId,
                name: nameController.text.trim(),
                phone: phoneController.text.trim(),
                route: routeController.text.trim(),
                salary: toDouble(salaryController.text),
              )
            : state.service.updateDsr(
                id: editItem.id,
                supplierId: supplierId,
                name: nameController.text.trim(),
                phone: phoneController.text.trim(),
                route: routeController.text.trim(),
                salary: toDouble(salaryController.text),
              ),
        onChanged,
      );
    },
  );
}

void showShopDialog(BuildContext context, AppState state, Future<void> Function() onChanged, {Shopkeeper? editItem}) {
  if (state.dsrs.isEmpty) {
    showSnack(context, 'Add DSR first.');
    return;
  }

  final shopController = TextEditingController(text: editItem?.shopName ?? '');
  final ownerController = TextEditingController(text: editItem?.ownerName ?? '');
  final phoneController = TextEditingController(text: editItem?.phone ?? '');
  final areaController = TextEditingController(text: editItem?.area ?? '');

  String dsrId = editItem?.dsrId ?? state.dsrs.first.id;

  statefulDialog(
    context: context,
    title: editItem == null ? 'Add Shopkeeper' : 'Edit Shopkeeper',
    builder: (setDialog) {
      return [
        textInput(label: 'Shop Name', controller: shopController),
        textInput(label: 'Owner Name', controller: ownerController),
        textInput(label: 'Phone', controller: phoneController),
        textInput(label: 'Area / Route', controller: areaController),
        DropdownButtonFormField<String>(
          value: dsrId,
          decoration: const InputDecoration(labelText: 'Assigned DSR'),
          items: state.dsrs.map((x) => DropdownMenuItem(value: x.id, child: Text(x.name))).toList(),
          onChanged: (value) => setDialog(() => dsrId = value ?? dsrId),
        ),
      ];
    },
    onSave: () async {
      await runAction(
        context,
        () => editItem == null
            ? state.service.addShopkeeper(
                companyId: state.companyId,
                dsrId: dsrId,
                shopName: shopController.text.trim(),
                ownerName: ownerController.text.trim(),
                phone: phoneController.text.trim(),
                area: areaController.text.trim(),
              )
            : state.service.updateShopkeeper(
                id: editItem.id,
                dsrId: dsrId,
                shopName: shopController.text.trim(),
                ownerName: ownerController.text.trim(),
                phone: phoneController.text.trim(),
                area: areaController.text.trim(),
              ),
        onChanged,
      );
    },
  );
}

void showProductDialog(BuildContext context, AppState state, Future<void> Function() onChanged, {Product? editItem}) {
  final nameController = TextEditingController(text: editItem?.name ?? 'Eclairs Chocolate');
  final skuController = TextEditingController(text: editItem?.sku ?? 'ECL-${state.products.length + 1}');
  final categoryController = TextEditingController(text: editItem?.category ?? 'Confectionery');
  final brandController = TextEditingController(text: editItem?.brand ?? 'Cadbury');
  final batchController = TextEditingController(text: editItem?.batchNo ?? 'ECL-160626');
  final mfgController = TextEditingController(text: editItem?.mfgDate ?? '2026-06-16');
  final expController = TextEditingController(text: editItem?.expDate ?? '2027-08-21');
  final packetsController = TextEditingController(text: editItem?.packetsPerCarton.toString() ?? '24');
  final purchaseController = TextEditingController(text: editItem?.purchasePrice.toStringAsFixed(0) ?? '189');
  final sellingController = TextEditingController(text: editItem?.sellingPrice.toStringAsFixed(0) ?? '189');
  final stockController = TextEditingController(text: editItem?.warehouseStock.toString() ?? '0');
  final lowController = TextEditingController(text: editItem?.lowStockLimit.toString() ?? '24');
  final companyDiscountController = TextEditingController(text: editItem?.companyDiscount.toStringAsFixed(0) ?? '0');
  final tradeDiscountController = TextEditingController(text: editItem?.tradeDiscount.toStringAsFixed(0) ?? '0');

  simpleDialog(
    context: context,
    title: editItem == null ? 'Add Receiving Product' : 'Edit Product',
    children: [
      const Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Product packing example: 1 carton = 24 packets. Stock is saved in packets so billing stays simple.',
          style: TextStyle(color: Color(0xff6b7280), height: 1.4),
        ),
      ),
      textInput(label: 'Product Name', controller: nameController),
      textInput(label: 'SKU / Code', controller: skuController),
      textInput(label: 'Category', controller: categoryController),
      textInput(label: 'Company / Brand', controller: brandController),
      textInput(label: 'Batch No', controller: batchController),
      textInput(label: 'MFG Date (YYYY-MM-DD)', controller: mfgController),
      textInput(label: 'EXP Date (YYYY-MM-DD)', controller: expController),
      textInput(label: 'Packets Per Carton', controller: packetsController, number: true),
      textInput(label: 'Packet Purchase Price', controller: purchaseController, number: true),
      textInput(label: 'Packet Selling Price', controller: sellingController, number: true),
      textInput(label: 'Warehouse Stock in Packets', controller: stockController, number: true),
      textInput(label: 'Low Stock Limit in Packets', controller: lowController, number: true),
      textInput(label: 'Discount From Company', controller: companyDiscountController, number: true),
      textInput(label: 'Trade / Shop Discount', controller: tradeDiscountController, number: true),
    ],
    onSave: () async {
      await runAction(
        context,
        () => editItem == null
            ? state.service.addProduct(
                companyId: state.companyId,
                name: nameController.text.trim(),
                sku: skuController.text.trim(),
                category: categoryController.text.trim(),
                brand: brandController.text.trim(),
                batchNo: batchController.text.trim(),
                mfgDate: mfgController.text.trim(),
                expDate: expController.text.trim(),
                purchasePrice: toDouble(purchaseController.text),
                sellingPrice: toDouble(sellingController.text),
                warehouseStock: toInt(stockController.text),
                lowStockLimit: toInt(lowController.text),
                packetsPerCarton: toInt(packetsController.text),
                companyDiscount: toDouble(companyDiscountController.text),
                tradeDiscount: toDouble(tradeDiscountController.text),
              )
            : state.service.updateProduct(
                id: editItem.id,
                name: nameController.text.trim(),
                sku: skuController.text.trim(),
                category: categoryController.text.trim(),
                brand: brandController.text.trim(),
                batchNo: batchController.text.trim(),
                mfgDate: mfgController.text.trim(),
                expDate: expController.text.trim(),
                purchasePrice: toDouble(purchaseController.text),
                sellingPrice: toDouble(sellingController.text),
                warehouseStock: toInt(stockController.text),
                lowStockLimit: toInt(lowController.text),
                packetsPerCarton: toInt(packetsController.text),
                companyDiscount: toDouble(companyDiscountController.text),
                tradeDiscount: toDouble(tradeDiscountController.text),
              ),
        onChanged,
      );
    },
  );
}


void showCompanyInvoicePreview(BuildContext context, AppState state, CompanyPurchase selectedInvoice) {
  final invoiceNo = selectedInvoice.invoiceNo.trim();
  final invoiceRows = state.companyPurchases.where((item) {
    if (invoiceNo.isEmpty) return item.id == selectedInvoice.id;
    return item.invoiceNo.trim() == invoiceNo;
  }).toList();

  final invoiceAmount = invoiceRows.fold<double>(0, (sum, item) => sum + item.totalBill);
  final invoicePaid = invoiceRows.fold<double>(0, (sum, item) => sum + item.paidAmount);
  final invoiceRemaining = invoiceRows.fold<double>(0, (sum, item) => sum + item.remainingAmount);
  final totalCartons = invoiceRows.fold<int>(0, (sum, item) => sum + item.cartons);
  final grossTotal = invoiceRows.fold<double>(0, (sum, item) => sum + (item.totalPackets * item.packetPurchasePrice));
  final discountTotal = invoiceRows.fold<double>(0, (sum, item) => sum + item.companyDiscount);
  final previousBalance = state.companyPurchases.where((item) {
    if (item.id == selectedInvoice.id) return false;
    if (item.date.compareTo(selectedInvoice.date) < 0) return true;
    if (item.date == selectedInvoice.date && item.invoiceNo.compareTo(selectedInvoice.invoiceNo) < 0) return true;
    return false;
  }).fold<double>(0, (sum, item) => sum + item.remainingAmount);

  showDialog(
    context: context,
    builder: (dialogContext) {
      return Dialog(
        insetPadding: const EdgeInsets.all(12),
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.96,
          height: MediaQuery.of(context).size.height * 0.92,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Company Invoice Preview',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: printCurrentPage,
                      icon: const Icon(Icons.print_rounded, size: 18),
                      label: const Text('Print'),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(14),
                  child: Center(
                    child: CompanyInvoicePrintable(
                      state: state,
                      invoice: selectedInvoice,
                      rows: invoiceRows,
                      invoiceAmount: invoiceAmount,
                      invoicePaid: invoicePaid,
                      invoiceRemaining: invoiceRemaining,
                      previousBalance: previousBalance,
                      totalCartons: totalCartons,
                      grossTotal: grossTotal,
                      discountTotal: discountTotal,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class CompanyInvoicePrintable extends StatelessWidget {
  final AppState state;
  final CompanyPurchase invoice;
  final List<CompanyPurchase> rows;
  final double invoiceAmount;
  final double invoicePaid;
  final double invoiceRemaining;
  final double previousBalance;
  final int totalCartons;
  final double grossTotal;
  final double discountTotal;

  const CompanyInvoicePrintable({
    super.key,
    required this.state,
    required this.invoice,
    required this.rows,
    required this.invoiceAmount,
    required this.invoicePaid,
    required this.invoiceRemaining,
    required this.previousBalance,
    required this.totalCartons,
    required this.grossTotal,
    required this.discountTotal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1000,
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          invoiceTopHeader(),
          const SizedBox(height: 12),
          invoiceItemsTable(),
          const SizedBox(height: 12),
          invoiceBottomSection(),
          const SizedBox(height: 26),
          const Center(
            child: Text(
              'Designed for Smart Account Manager',
              style: TextStyle(fontSize: 11, color: Color(0xff6b7280)),
            ),
          ),
        ],
      ),
    );
  }

  Widget invoiceTopHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 6,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(border: Border.all(color: Colors.black87)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                invoiceHeaderLine('M/S', '021112    ${state.company?.name ?? 'AFRA TRADER'}'),
                invoiceHeaderLine('Address', state.company?.address ?? ''),
                invoiceHeaderLine('Remarks', invoice.note),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(
                child: Text(
                  'Sales Invoice',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xff7f1d1d)),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(border: Border.all(color: Colors.black87)),
                child: Column(
                  children: [
                    invoiceHeaderLine('Invoice No.', invoice.invoiceNo.isEmpty ? '-' : invoice.invoiceNo),
                    invoiceHeaderLine('Invoice Date', formatDateForUi(invoice.date)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(border: Border.all(color: Colors.black54)),
                child: Text(
                  invoice.companyName.isEmpty ? 'Company Invoice' : invoice.companyName,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xff374151)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget invoiceHeaderLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text('$label :', style: const TextStyle(fontWeight: FontWeight.w900))),
          Expanded(child: Text(value.isEmpty ? '-' : value, maxLines: 1, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget invoiceItemsTable() {
    final tableRows = <TableRow>[
      TableRow(
        decoration: const BoxDecoration(color: Color(0xfff3f4f6)),
        children: const [
          _InvoiceCell('#', bold: true),
          _InvoiceCell('Description', bold: true),
          _InvoiceCell('Pack', bold: true),
          _InvoiceCell('SAP Code', bold: true),
          _InvoiceCell('Batch No.', bold: true),
          _InvoiceCell('Expiry Date', bold: true),
          _InvoiceCell('Quantity', bold: true),
          _InvoiceCell('Rate', bold: true),
          _InvoiceCell('Gross Value', bold: true),
          _InvoiceCell('T/O @', bold: true),
          _InvoiceCell('T/O Amt.', bold: true),
          _InvoiceCell('% Disc.', bold: true),
          _InvoiceCell('Disc. Amt.', bold: true),
          _InvoiceCell('Total Value', bold: true),
          _InvoiceCell('Extra T/O', bold: true),
        ],
      ),
    ];

    for (int i = 0; i < rows.length; i++) {
      final item = rows[i];
      final product = state.productById(item.productId);
      final gross = item.totalPackets * item.packetPurchasePrice;
      final cartonRate = item.packetsPerCarton * item.packetPurchasePrice;
      final discountPercent = gross <= 0 ? 0 : (item.companyDiscount / gross) * 100;

      tableRows.add(TableRow(children: [
        _InvoiceCell('${i + 1}'),
        _InvoiceCell(state.productName(item.productId)),
        _InvoiceCell('${item.packetsPerCarton}X${item.cartons}'),
        _InvoiceCell(product?.sku.isEmpty ?? true ? '-' : product!.sku),
        _InvoiceCell(item.batchNo.isEmpty ? '-' : item.batchNo),
        _InvoiceCell(product?.expDate.isEmpty ?? true ? '-' : formatDateForUi(product!.expDate)),
        _InvoiceCell(item.cartons.toString()),
        _InvoiceCell(cartonRate.toStringAsFixed(0)),
        _InvoiceCell(gross.toStringAsFixed(0)),
        const _InvoiceCell('0.00'),
        const _InvoiceCell('0'),
        _InvoiceCell(discountPercent.toStringAsFixed(2)),
        _InvoiceCell(item.companyDiscount.toStringAsFixed(0)),
        _InvoiceCell(item.totalBill.toStringAsFixed(0)),
        const _InvoiceCell('0'),
      ]));
    }

    tableRows.add(TableRow(
      decoration: const BoxDecoration(color: Color(0xfff8fafc)),
      children: [
        const _InvoiceCell('', bold: true),
        const _InvoiceCell('TOTAL:', bold: true),
        const _InvoiceCell('', bold: true),
        const _InvoiceCell('', bold: true),
        const _InvoiceCell('', bold: true),
        const _InvoiceCell('', bold: true),
        _InvoiceCell(totalCartons.toString(), bold: true),
        const _InvoiceCell('', bold: true),
        _InvoiceCell(grossTotal.toStringAsFixed(0), bold: true),
        const _InvoiceCell('', bold: true),
        const _InvoiceCell('0', bold: true),
        const _InvoiceCell('', bold: true),
        _InvoiceCell(discountTotal.toStringAsFixed(0), bold: true),
        _InvoiceCell(invoiceAmount.toStringAsFixed(0), bold: true),
        const _InvoiceCell('-', bold: true),
      ],
    ));

    return Table(
      border: TableBorder.all(color: Colors.black87),
      columnWidths: const {
        0: FixedColumnWidth(28),
        1: FixedColumnWidth(170),
        2: FixedColumnWidth(54),
        3: FixedColumnWidth(64),
        4: FixedColumnWidth(58),
        5: FixedColumnWidth(70),
        6: FixedColumnWidth(52),
        7: FixedColumnWidth(56),
        8: FixedColumnWidth(70),
        9: FixedColumnWidth(46),
        10: FixedColumnWidth(56),
        11: FixedColumnWidth(48),
        12: FixedColumnWidth(62),
        13: FixedColumnWidth(70),
        14: FixedColumnWidth(54),
      },
      children: tableRows,
    );
  }

  Widget invoiceBottomSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 250,
          child: Table(
            border: TableBorder.all(color: Colors.black87),
            children: const [
              TableRow(children: [_InvoiceCell('Description', bold: true), _InvoiceCell('1ST', bold: true), _InvoiceCell('2ND', bold: true), _InvoiceCell('3RD', bold: true)]),
              TableRow(children: [_InvoiceCell('Date'), _InvoiceCell(''), _InvoiceCell(''), _InvoiceCell('')]),
              TableRow(children: [_InvoiceCell('No. of CTN'), _InvoiceCell(''), _InvoiceCell(''), _InvoiceCell('')]),
              TableRow(children: [_InvoiceCell('Loader Name'), _InvoiceCell(''), _InvoiceCell(''), _InvoiceCell('')]),
              TableRow(children: [_InvoiceCell('Van No.'), _InvoiceCell(''), _InvoiceCell(''), _InvoiceCell('')]),
            ],
          ),
        ),
        const SizedBox(width: 70),
        const Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 80),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text("Receiver's by", style: TextStyle(fontWeight: FontWeight.w900)),
                Text('Authorized by', style: TextStyle(fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 235,
          child: Column(
            children: [
              summaryLine('Special Disc.', '-'),
              summaryLine('Claimable Disc.', '-'),
              summaryLine('Freight', '-'),
              summaryLine('Invoice Amount', state.rs(invoiceAmount)),
              summaryLine('Paid Amount', state.rs(invoicePaid)),
              summaryLine('Invoice Balance', state.rs(invoiceRemaining)),
              summaryLine('Previous', state.rs(previousBalance)),
              summaryLine('Total Balance', state.rs(previousBalance + invoiceRemaining), bold: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget summaryLine(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontWeight: bold ? FontWeight.w900 : FontWeight.w800, color: const Color(0xff7f1d1d)),
            ),
          ),
          SizedBox(
            width: 100,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(fontWeight: bold ? FontWeight.w900 : FontWeight.w800, color: const Color(0xff7f1d1d)),
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceCell extends StatelessWidget {
  final String text;
  final bool bold;

  const _InvoiceCell(this.text, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 9.2, fontWeight: bold ? FontWeight.w900 : FontWeight.w500),
      ),
    );
  }
}

void showCompanyPurchaseDialog(BuildContext context, AppState state, Future<void> Function() onChanged) {
  if (state.products.isEmpty) {
    showSnack(context, 'Add product first.');
    return;
  }

  String productId = state.products.first.id;
  Product selectedProduct = state.products.first;
  final invoiceController = TextEditingController();
  final companyController = TextEditingController(text: selectedProduct.brand.isNotEmpty ? selectedProduct.brand : (state.company?.name ?? ''));
  final batchController = TextEditingController(text: selectedProduct.batchNo);
  final cartonsController = TextEditingController(text: '1');
  final packetsController = TextEditingController(text: selectedProduct.packetsPerCarton.toString());
  final priceController = TextEditingController(text: selectedProduct.purchasePrice.toStringAsFixed(0));
  final discountController = TextEditingController(text: selectedProduct.companyDiscount.toStringAsFixed(0));
  final paidController = TextEditingController(text: '0');
  final noteController = TextEditingController();

  statefulDialog(
    context: context,
    title: 'Add Company Purchase',
    builder: (setDialog) {
      final cartons = toInt(cartonsController.text);
      final packets = toInt(packetsController.text);
      final price = toDouble(priceController.text);
      final discount = toDouble(discountController.text);
      final paid = toDouble(paidController.text);
      final totalPackets = cartons * packets;
      final gross = totalPackets * price;
      final totalBill = (gross - discount).clamp(0, double.infinity).toDouble();
      final remaining = (totalBill - paid).clamp(0, double.infinity).toDouble();

      return [
        DropdownButtonFormField<String>(
          value: productId,
          decoration: const InputDecoration(labelText: 'Product'),
          items: state.products.map((x) => DropdownMenuItem(value: x.id, child: Text(x.name))).toList(),
          onChanged: (value) {
            if (value == null) return;
            setDialog(() {
              productId = value;
              selectedProduct = state.productById(value) ?? selectedProduct;
              batchController.text = selectedProduct.batchNo;
              if (selectedProduct.brand.isNotEmpty) companyController.text = selectedProduct.brand;
              packetsController.text = selectedProduct.packetsPerCarton.toString();
              priceController.text = selectedProduct.purchasePrice.toStringAsFixed(0);
              discountController.text = selectedProduct.companyDiscount.toStringAsFixed(0);
            });
          },
        ),
        textInput(label: 'Invoice No', controller: invoiceController),
        textInput(label: 'Company Name', controller: companyController),
        textInput(label: 'Batch No', controller: batchController),
        textInput(label: 'Cartons Received', controller: cartonsController, number: true, onChanged: (_) => setDialog(() {})),
        textInput(label: 'Packets Per Carton', controller: packetsController, number: true, onChanged: (_) => setDialog(() {})),
        textInput(label: 'Packet Purchase Price', controller: priceController, number: true, onChanged: (_) => setDialog(() {})),
        textInput(label: 'Discount From Company', controller: discountController, number: true, onChanged: (_) => setDialog(() {})),
        textInput(label: 'Paid Amount To Company', controller: paidController, number: true, onChanged: (_) => setDialog(() {})),
        textInput(label: 'Slip / Cheque / Bank / Note', controller: noteController),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xfff8fafc),
            border: Border.all(color: const Color(0xffe5e7eb)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total packets: $totalPackets', style: const TextStyle(fontWeight: FontWeight.w800)),
              Text('Gross bill: ${state.rs(gross)}'),
              Text('Total after discount: ${state.rs(totalBill)}'),
              Text('Remaining payable: ${state.rs(remaining)}', style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.red)),
            ],
          ),
        ),
      ];
    },
    onSave: () async {
      await runAction(
        context,
        () => state.service.addCompanyPurchase(
          companyId: state.companyId,
          invoiceNo: invoiceController.text.trim(),
          companyName: companyController.text.trim(),
          productId: productId,
          batchNo: batchController.text.trim(),
          cartons: toInt(cartonsController.text),
          packetsPerCarton: toInt(packetsController.text),
          packetPurchasePrice: toDouble(priceController.text),
          companyDiscount: toDouble(discountController.text),
          paidAmount: toDouble(paidController.text),
          note: noteController.text.trim(),
        ),
        onChanged,
      );
    },
  );
}


void showLoadDialog(BuildContext context, AppState state, Future<void> Function() onChanged) {
  if (state.dsrs.isEmpty || state.suppliers.isEmpty || state.products.isEmpty) {
    showSnack(context, 'Add DSR/booker, salesman, and product first.');
    return;
  }

  String dsrId = state.dsrs.first.id;
  String supplierId = state.dsrs.first.supplierId;
  String productId = state.products.first.id;
  final qtyController = TextEditingController();

  statefulDialog(
    context: context,
    title: 'Load Form / Secondary Order',
    builder: (setDialog) {
      return [
        DropdownButtonFormField<String>(
          value: dsrId,
          decoration: const InputDecoration(labelText: 'Booker'),
          items: state.dsrs.map((x) => DropdownMenuItem(value: x.id, child: Text(x.name))).toList(),
          onChanged: (value) {
            setDialog(() {
              dsrId = value ?? dsrId;
              supplierId = state.dsrById(dsrId)?.supplierId ?? supplierId;
            });
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: productId,
          decoration: const InputDecoration(labelText: 'Product'),
          items: state.products.map((x) => DropdownMenuItem(value: x.id, child: Text('${x.name} - Warehouse: ${x.warehouseStock}'))).toList(),
          onChanged: (value) => setDialog(() => productId = value ?? productId),
        ),
        textInput(label: 'Order / Load Quantity', controller: qtyController, number: true),
      ];
    },
    onSave: () async {
      await runAction(
        context,
        () => state.service.loadStock(
          companyId: state.companyId,
          dsrId: dsrId,
          supplierId: supplierId,
          productId: productId,
          quantity: toInt(qtyController.text),
        ),
        onChanged,
      );
    },
  );
}

void showSaleDialog(BuildContext context, AppState state, Future<void> Function() onChanged) {
  if (state.dsrs.isEmpty || state.shopkeepers.isEmpty || state.products.isEmpty) {
    showSnack(context, 'Add DSR, shopkeeper, and product first.');
    return;
  }

  String dsrId = state.dsrs.first.id;
  String shopkeeperId = state.shopkeepers.first.id;
  String productId = state.products.first.id;
  SaleType saleType = SaleType.cash;

  final qtyController = TextEditingController();
  final priceController = TextEditingController(text: state.products.first.sellingPrice.toStringAsFixed(0));
  final billController = TextEditingController(text: 'BILL-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}');

  statefulDialog(
    context: context,
    title: 'Book Order / Sale',
    builder: (setDialog) {
      return [
        textInput(label: 'Bill No', controller: billController),
        DropdownButtonFormField<String>(
          value: dsrId,
          decoration: const InputDecoration(labelText: 'Booker'),
          items: state.dsrs.map((x) => DropdownMenuItem(value: x.id, child: Text(x.name))).toList(),
          onChanged: (value) => setDialog(() => dsrId = value ?? dsrId),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: shopkeeperId,
          decoration: const InputDecoration(labelText: 'Shopkeeper'),
          items: state.shopkeepers.map((x) => DropdownMenuItem(value: x.id, child: Text('${x.shopName} - Credit: ${state.rs(x.pendingCredit)}'))).toList(),
          onChanged: (value) => setDialog(() => shopkeeperId = value ?? shopkeeperId),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: productId,
          decoration: const InputDecoration(labelText: 'Product'),
          items: state.products.map((x) => DropdownMenuItem(value: x.id, child: Text('${x.name} - DSR Stock: ${state.dsrProductStock(dsrId, x.id)}'))).toList(),
          onChanged: (value) {
            setDialog(() {
              productId = value ?? productId;
              priceController.text = state.productById(productId)?.sellingPrice.toStringAsFixed(0) ?? priceController.text;
            });
          },
        ),
        textInput(label: 'Quantity', controller: qtyController, number: true),
        textInput(label: 'Selling Price', controller: priceController, number: true),
        const SizedBox(height: 12),
        DropdownButtonFormField<SaleType>(
          value: saleType,
          decoration: const InputDecoration(labelText: 'Sale Type'),
          items: const [
            DropdownMenuItem(value: SaleType.cash, child: Text('Cash Sale')),
            DropdownMenuItem(value: SaleType.credit, child: Text('Credit Sale')),
          ],
          onChanged: (value) => setDialog(() => saleType = value ?? saleType),
        ),
      ];
    },
    onSave: () async {
      await runAction(
        context,
        () => state.service.bookSale(
          companyId: state.companyId,
          billNo: billController.text.trim(),
          dsrId: dsrId,
          shopkeeperId: shopkeeperId,
          productId: productId,
          quantity: toInt(qtyController.text),
          price: toDouble(priceController.text),
          type: saleType,
        ),
        onChanged,
      );
    },
  );
}

void showRecoveryDialog(BuildContext context, AppState state, Future<void> Function() onChanged) {
  if (state.dsrs.isEmpty || state.shopkeepers.isEmpty) {
    showSnack(context, 'Add DSR and shopkeeper first.');
    return;
  }

  String dsrId = state.dsrs.first.id;
  String shopkeeperId = state.shopkeepers.first.id;

  final amountController = TextEditingController();
  final billController = TextEditingController(text: 'REC-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}');

  statefulDialog(
    context: context,
    title: 'Add Recovery',
    builder: (setDialog) {
      return [
        DropdownButtonFormField<String>(
          value: dsrId,
          decoration: const InputDecoration(labelText: 'Booker'),
          items: state.dsrs.map((x) => DropdownMenuItem(value: x.id, child: Text(x.name))).toList(),
          onChanged: (value) => setDialog(() => dsrId = value ?? dsrId),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: shopkeeperId,
          decoration: const InputDecoration(labelText: 'Shopkeeper'),
          items: state.shopkeepers.map((x) => DropdownMenuItem(value: x.id, child: Text('${x.shopName} - Pending: ${state.rs(x.pendingCredit)}'))).toList(),
          onChanged: (value) => setDialog(() => shopkeeperId = value ?? shopkeeperId),
        ),
        textInput(label: 'Cheque / Bill No', controller: billController),
        textInput(label: 'Received Amount', controller: amountController, number: true),
      ];
    },
    onSave: () async {
      await runAction(
        context,
        () => state.service.addRecovery(
          companyId: state.companyId,
          chequeBillNo: billController.text.trim(),
          dsrId: dsrId,
          shopkeeperId: shopkeeperId,
          amount: toDouble(amountController.text),
        ),
        onChanged,
      );
    },
  );
}

void showExpenseDialog(BuildContext context, AppState state, Future<void> Function() onChanged) {
  if (state.dsrs.isEmpty) {
    showSnack(context, 'Add DSR first.');
    return;
  }

  String dsrId = state.dsrs.first.id;
  String expenseType = 'Fuel Expense';
  final amountController = TextEditingController();
  final noteController = TextEditingController();
  final types = ['Fuel Expense', 'Office Expense', 'Advance Payment', 'Extra Payment In', 'Payment Out Credit', 'Return Payment', 'Advance Payment Return', 'Other Expense'];

  statefulDialog(
    context: context,
    title: 'Add Expense / Payment',
    builder: (setDialog) {
      return [
        DropdownButtonFormField<String>(
          value: dsrId,
          decoration: const InputDecoration(labelText: 'Booker'),
          items: state.dsrs.map((x) => DropdownMenuItem(value: x.id, child: Text(x.name))).toList(),
          onChanged: (value) => setDialog(() => dsrId = value ?? dsrId),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: expenseType,
          decoration: const InputDecoration(labelText: 'Type'),
          items: types.map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(),
          onChanged: (value) => setDialog(() => expenseType = value ?? expenseType),
        ),
        textInput(label: 'Amount', controller: amountController, number: true),
        textInput(label: 'Note', controller: noteController),
      ];
    },
    onSave: () async {
      await runAction(
        context,
        () => state.service.addExpense(
          companyId: state.companyId,
          dsrId: dsrId,
          type: expenseType,
          amount: toDouble(amountController.text),
          note: noteController.text.trim(),
        ),
        onChanged,
      );
    },
  );
}

void showDepositDialog(BuildContext context, AppState state, Future<void> Function() onChanged) {
  final partyController = TextEditingController();
  final coinsController = TextEditingController(text: '0');
  final noteControllers = {
    for (final note in [5000, 1000, 500, 100, 50, 20, 10]) note: TextEditingController(text: '0'),
  };

  simpleDialog(
    context: context,
    title: 'Add Deposit',
    children: [
      textInput(label: 'Party / Bank', controller: partyController),
      ...noteControllers.entries.map((entry) => textInput(label: '${entry.key} Notes Count', controller: entry.value, number: true)),
      textInput(label: 'Coins', controller: coinsController, number: true),
    ],
    onSave: () async {
      final notes = <int, int>{};
      noteControllers.forEach((note, controller) => notes[note] = toInt(controller.text));
      await runAction(
        context,
        () => state.service.addDeposit(
          companyId: state.companyId,
          party: partyController.text.trim(),
          notes: notes,
          coins: toDouble(coinsController.text),
        ),
        onChanged,
      );
    },
  );
}

void showClaimDialog(BuildContext context, AppState state, Future<void> Function() onChanged) {
  if (state.products.isEmpty) {
    showSnack(context, 'Add product first.');
    return;
  }

  String productId = state.products.first.id;
  String claimType = 'Expiry';

  final qtyController = TextEditingController();
  final amountController = TextEditingController();
  final noteController = TextEditingController();

  statefulDialog(
    context: context,
    title: 'Add Claim / Expiry',
    builder: (setDialog) {
      return [
        DropdownButtonFormField<String>(
          value: productId,
          decoration: const InputDecoration(labelText: 'Product'),
          items: state.products.map((x) => DropdownMenuItem(value: x.id, child: Text(x.name))).toList(),
          onChanged: (value) => setDialog(() => productId = value ?? productId),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: claimType,
          decoration: const InputDecoration(labelText: 'Type'),
          items: const ['Expiry', 'Claim', 'Damage', 'Return Stock'].map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(),
          onChanged: (value) => setDialog(() => claimType = value ?? claimType),
        ),
        textInput(label: 'Quantity', controller: qtyController, number: true),
        textInput(label: 'Amount', controller: amountController, number: true),
        textInput(label: 'Note', controller: noteController),
      ];
    },
    onSave: () async {
      await runAction(
        context,
        () => state.service.addClaim(
          companyId: state.companyId,
          productId: productId,
          type: claimType,
          quantity: toInt(qtyController.text),
          amount: toDouble(amountController.text),
          note: noteController.text.trim(),
        ),
        onChanged,
      );
    },
  );
}

void simpleDialog({
  required BuildContext context,
  required String title,
  required List<Widget> children,
  required Future<void> Function() onSave,
}) {
  showDialog(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        content: SizedBox(
          width: 540,
          child: SingleChildScrollView(child: Column(children: children)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await onSave();
            },
            icon: const Icon(Icons.save_rounded),
            label: const Text('Save'),
          ),
        ],
      );
    },
  );
}

void statefulDialog({
  required BuildContext context,
  required String title,
  required List<Widget> Function(void Function(VoidCallback fn) setDialog) builder,
  required Future<void> Function() onSave,
}) {
  showDialog(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setDialog) {
          return AlertDialog(
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
            content: SizedBox(
              width: 560,
              child: SingleChildScrollView(child: Column(children: builder(setDialog))),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  await onSave();
                },
                icon: const Icon(Icons.save_rounded),
                label: const Text('Save'),
              ),
            ],
          );
        },
      );
    },
  );
}
