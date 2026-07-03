import 'models.dart';
import 'supabase_service.dart';

class ProfitLossSummary {
  final List<SaleEntry> sales;
  final List<ExpenseEntry> expenses;
  final List<ClaimEntry> claims;
  final int soldQuantity;
  final double grossSales;
  final double cashSales;
  final double creditSales;
  final double costOfGoodsSold;
  final double grossProfit;
  final double expenseOutflows;
  final double claimLoss;
  final double netProfit;

  const ProfitLossSummary({
    required this.sales,
    required this.expenses,
    required this.claims,
    required this.soldQuantity,
    required this.grossSales,
    required this.cashSales,
    required this.creditSales,
    required this.costOfGoodsSold,
    required this.grossProfit,
    required this.expenseOutflows,
    required this.claimLoss,
    required this.netProfit,
  });

  double get profitMarginPercent =>
      grossSales <= 0 ? 0 : (netProfit / grossSales) * 100;

  bool get isProfit => netProfit >= 0;
}

class AppState {
  final SupabaseService service;

  Profile? profile;
  Company? company;

  List<Supplier> suppliers = [];
  List<Dsr> dsrs = [];
  List<Shopkeeper> shopkeepers = [];
  List<Product> products = [];
  List<CompanyPurchase> companyPurchases = [];
  List<DsrStock> dsrStocks = [];
  List<LoadEntry> loads = [];
  List<SaleEntry> sales = [];
  List<RecoveryEntry> recoveries = [];
  List<ExpenseEntry> expenses = [];
  List<DepositEntry> deposits = [];
  List<ClaimEntry> claims = [];
  List<InvestmentEntry> investments = [];

  AppState({required this.service});

  String get companyId {
    final id = profile?.companyId;
    if (id == null || id.isEmpty) {
      throw Exception('Company not found. Please create company profile first.');
    }
    return id;
  }

  String get today {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String rs(double value) => 'Rs ${value.toStringAsFixed(0)}';

  void clearLocal() {
    profile = null;
    company = null;
    suppliers = [];
    dsrs = [];
    shopkeepers = [];
    products = [];
    companyPurchases = [];
    dsrStocks = [];
    loads = [];
    sales = [];
    recoveries = [];
    expenses = [];
    deposits = [];
    claims = [];
    investments = [];
  }

  Future<void> loadAll() async {
    profile = await service.getMyProfile();

    if (profile != null) {
      company = await service.getMyCompany(profile!.companyId);
      suppliers = await service.getSuppliers();
      dsrs = await service.getDsrs();
      shopkeepers = await service.getShopkeepers();
      products = await service.getProducts();
      companyPurchases = await service.getCompanyPurchases();
      dsrStocks = await service.getDsrStocks();
      loads = await service.getLoads();
      sales = await service.getSales();
      recoveries = await service.getRecoveries();
      expenses = await service.getExpenses();
      deposits = await service.getDeposits();
      claims = await service.getClaims();
      investments = await service.getInvestments();
    }
  }

  Supplier? supplierById(String id) {
    for (final item in suppliers) {
      if (item.id == id) return item;
    }
    return null;
  }

  Dsr? dsrById(String id) {
    for (final item in dsrs) {
      if (item.id == id) return item;
    }
    return null;
  }

  Shopkeeper? shopById(String id) {
    for (final item in shopkeepers) {
      if (item.id == id) return item;
    }
    return null;
  }

  Product? productById(String id) {
    for (final item in products) {
      if (item.id == id) return item;
    }
    return null;
  }

  String supplierName(String id) => supplierById(id)?.name ?? '-';
  String dsrName(String id) => dsrById(id)?.name ?? '-';
  String shopName(String id) => shopById(id)?.shopName ?? 'Distributor';
  String productName(String id) => productById(id)?.name ?? '-';

  int dsrProductStock(String dsrId, String productId) {
    // Stock is controlled by the distributor/warehouse only.
    // DSR is used for sales/report ownership, not for separate stock holding.
    return productById(productId)?.warehouseStock ?? 0;
  }

  int distributorProductStock(String productId) {
    return productById(productId)?.warehouseStock ?? 0;
  }

  int get lowStockCount {
    return products.where((item) => item.warehouseStock <= item.lowStockLimit).length;
  }

  int get totalStockBox {
    return products.fold<int>(0, (sum, item) => sum + item.warehouseStock);
  }

  int get totalStockCtn {
    return products.fold<int>(0, (sum, item) {
      final pack = item.packetsPerCarton <= 0 ? 1 : item.packetsPerCarton;
      return sum + (item.warehouseStock ~/ pack);
    });
  }

  int get totalLooseBox {
    return products.fold<int>(0, (sum, item) {
      final pack = item.packetsPerCarton <= 0 ? 1 : item.packetsPerCarton;
      return sum + (item.warehouseStock % pack);
    });
  }

  String get totalStockCtnBoxText => '$totalStockCtn CTN / $totalLooseBox Box';


  double get grossSale => sales.fold(0, (sum, item) => sum + item.total);

  double get cashSales {
    return sales.where((item) => item.type == SaleType.cash).fold(0, (sum, item) => sum + item.total);
  }

  double get creditSales {
    return sales.where((item) => item.type == SaleType.credit).fold(0, (sum, item) => sum + item.total);
  }

  static const Set<String> cashInExpenseTypes = {
    'Extra Payment In',
    'Advance Payment Return',
  };

  double get totalRecovery =>
      recoveries.fold(0, (sum, item) => sum + item.receivedAmount);

  double get totalExpenseOutflows => expenses
      .where((item) => !cashInExpenseTypes.contains(item.type))
      .fold(0, (sum, item) => sum + item.amount);

  double get totalOtherCashInflows => expenses
      .where((item) => cashInExpenseTypes.contains(item.type))
      .fold(0, (sum, item) => sum + item.amount);

  double get totalExpenses => totalExpenseOutflows;
  double get depositTotal => deposits.fold(0, (sum, item) => sum + item.total);
  double get claimAmount => claims.fold(0, (sum, item) => sum + item.amount);
  double get companyPayable =>
      companyPurchases.fold(0, (sum, item) => sum + item.remainingAmount);
  double get purchaseTotal =>
      companyPurchases.fold(0, (sum, item) => sum + item.totalBill);
  double get marketCredit =>
      (creditSales - totalRecovery).clamp(0, double.infinity).toDouble();

  double get recordedInvestment =>
      investments.fold(0, (sum, item) => sum + item.amount);

  // Investment contains only money intentionally added as capital.
  // Credit sales and recoveries are tracked separately through Market Credit.
  double get totalInvestment => recordedInvestment;

  double get cashInvestment => investments
      .where((item) => item.isCash)
      .fold(0, (sum, item) => sum + item.amount);

  double get bankOnlineInvestment => investments
      .where((item) => item.isBankOrOnline)
      .fold(0, (sum, item) => sum + item.amount);

  double get loanInvestment => investments
      .where((item) => item.investmentType == 'Loan Received')
      .fold(0, (sum, item) => sum + item.amount);

  double get stockValue {
    return products.fold(
        0, (sum, item) => sum + (item.warehouseStock * item.purchasePrice));
  }

  double get cashBalance =>
      cashSales +
      totalRecovery +
      totalOtherCashInflows +
      cashInvestment -
      totalExpenseOutflows -
      depositTotal;

  double saleUnitCost(SaleEntry sale) {
    if (sale.purchaseCost > 0) return sale.purchaseCost;
    return productById(sale.productId)?.purchasePrice ?? 0;
  }

  double saleCost(SaleEntry sale) => saleUnitCost(sale) * sale.quantity;

  double saleProfit(SaleEntry sale) => sale.total - saleCost(sale);

  bool _dateMatchesRange(String date, String fromDate, String toDate) {
    final value = date.trim();
    final from = fromDate.trim();
    final to = toDate.trim();
    if (from.isNotEmpty && value.compareTo(from) < 0) return false;
    if (to.isNotEmpty && value.compareTo(to) > 0) return false;
    return true;
  }

  ProfitLossSummary calculateProfitLoss({
    String fromDate = '',
    String toDate = '',
    String dsrId = '',
    String salesmanId = '',
    String productId = '',
  }) {
    final filteredSales = sales.where((sale) {
      if (!_dateMatchesRange(sale.date, fromDate, toDate)) return false;
      if (dsrId.isNotEmpty && sale.dsrId != dsrId) return false;
      if (salesmanId.isNotEmpty &&
          dsrById(sale.dsrId)?.supplierId != salesmanId) {
        return false;
      }
      if (productId.isNotEmpty && sale.productId != productId) return false;
      return true;
    }).toList();

    final filteredExpenses = expenses.where((expense) {
      if (!_dateMatchesRange(expense.date, fromDate, toDate)) return false;
      if (dsrId.isNotEmpty && expense.dsrId != dsrId) return false;
      if (salesmanId.isNotEmpty &&
          dsrById(expense.dsrId)?.supplierId != salesmanId) {
        return false;
      }
      return !cashInExpenseTypes.contains(expense.type);
    }).toList();

    // Claims are company/product-level records and have no DSR ownership.
    // Excluding them from DSR/salesman views prevents the same company loss
    // from being incorrectly assigned to an individual team member.
    final includeCompanyClaims = dsrId.isEmpty && salesmanId.isEmpty;
    final filteredClaims = includeCompanyClaims
        ? claims.where((claim) {
            if (!_dateMatchesRange(claim.date, fromDate, toDate)) return false;
            if (productId.isNotEmpty && claim.productId != productId) {
              return false;
            }
            return true;
          }).toList()
        : <ClaimEntry>[];

    final gross = filteredSales.fold<double>(
        0, (sum, sale) => sum + sale.total);
    final cash = filteredSales
        .where((sale) => sale.type == SaleType.cash)
        .fold<double>(0, (sum, sale) => sum + sale.total);
    final credit = filteredSales
        .where((sale) => sale.type == SaleType.credit)
        .fold<double>(0, (sum, sale) => sum + sale.total);
    final cost = filteredSales.fold<double>(
        0, (sum, sale) => sum + saleCost(sale));
    final expenseTotal = filteredExpenses.fold<double>(
        0, (sum, expense) => sum + expense.amount);
    final claimTotal = filteredClaims.fold<double>(
        0, (sum, claim) => sum + claim.amount);
    final grossProfitValue = gross - cost;
    final netProfitValue = grossProfitValue - expenseTotal - claimTotal;

    return ProfitLossSummary(
      sales: filteredSales,
      expenses: filteredExpenses,
      claims: filteredClaims,
      soldQuantity: filteredSales.fold<int>(
          0, (sum, sale) => sum + sale.quantity),
      grossSales: gross,
      cashSales: cash,
      creditSales: credit,
      costOfGoodsSold: cost,
      grossProfit: grossProfitValue,
      expenseOutflows: expenseTotal,
      claimLoss: claimTotal,
      netProfit: netProfitValue,
    );
  }

  double get totalCostOfGoodsSold => calculateProfitLoss().costOfGoodsSold;
  double get grossProfit => calculateProfitLoss().grossProfit;
  double get netProfit => calculateProfitLoss().netProfit;
  double get profitMarginPercent =>
      calculateProfitLoss().profitMarginPercent;
  double get totalCapitalValue => totalInvestment + netProfit;

  double get monthlyProfitEstimate => netProfit;

  int totalPurchasedForProduct(String productId) => companyPurchases
      .where((item) => item.productId == productId)
      .fold(0, (sum, item) => sum + item.totalPackets);

  int totalSoldForProduct(String productId) => sales
      .where((item) => item.productId == productId)
      .fold(0, (sum, item) => sum + item.quantity);

  double get secondaryLoadTotal {
    final seenSettlements = <String>{};
    double extra = 0;
    double rowNet = 0;
    for (final load in loads) {
      rowNet += load.netAmount;
      final key = load.settlementId.isEmpty ? load.id : load.settlementId;
      if (seenSettlements.add(key)) extra += load.extraAmount;
    }
    return rowNet + extra;
  }

  List<SaleEntry> salesFor(String dsrId, String date) {
    return sales.where((item) => item.dsrId == dsrId && item.date == date).toList();
  }

  List<RecoveryEntry> recoveriesFor(String dsrId, String date) {
    return recoveries.where((item) => item.dsrId == dsrId && item.date == date).toList();
  }

  List<ExpenseEntry> expensesFor(String dsrId, String date) {
    return expenses.where((item) => item.dsrId == dsrId && item.date == date).toList();
  }

  DsrDailyReport buildDsrDailyReport({
    required String dsrId,
    required String date,
    required double returnStockAmount,
    required double extraAmount,
    required double physicalCash,
  }) {
    final dsrSales = salesFor(dsrId, date);
    final dsrRecoveries = recoveriesFor(dsrId, date);
    final dsrExpenses = expensesFor(dsrId, date);

    final gross = dsrSales.fold(0.0, (sum, item) => sum + item.total);
    final credit = dsrSales.where((item) => item.type == SaleType.credit).fold(0.0, (sum, item) => sum + item.total);
    final fuel = dsrExpenses
        .where((item) => item.type == 'Fuel Expense')
        .fold(0.0, (sum, item) => sum + item.amount);
    final office = dsrExpenses
        .where((item) => item.type == 'Office Expense')
        .fold(0.0, (sum, item) => sum + item.amount);
    final otherOutflows = dsrExpenses
        .where((item) =>
            !cashInExpenseTypes.contains(item.type) &&
            item.type != 'Fuel Expense' &&
            item.type != 'Office Expense')
        .fold(0.0, (sum, item) => sum + item.amount);
    final otherInflows = dsrExpenses
        .where((item) => cashInExpenseTypes.contains(item.type))
        .fold(0.0, (sum, item) => sum + item.amount);
    final recovery =
        dsrRecoveries.fold(0.0, (sum, item) => sum + item.receivedAmount);

    final netSale = gross - returnStockAmount + extraAmount;
    final netCashSale =
        netSale - fuel - office - otherOutflows - credit + otherInflows;
    final totalDsrCash = netCashSale + recovery;
    final difference = physicalCash - totalDsrCash;

    return DsrDailyReport(
      date: date,
      dsrId: dsrId,
      grossSale: gross,
      returnStockAmount: returnStockAmount,
      extraAmount: extraAmount,
      netSale: netSale,
      fuelExpense: fuel,
      officeExpense: office,
      creditSale: credit,
      netCashSale: netCashSale,
      recovery: recovery,
      totalDsrCash: totalDsrCash,
      physicalCash: physicalCash,
      shortAmount: difference < 0 ? difference.abs() : 0,
      excessAmount: difference > 0 ? difference : 0,
    );
  }


}
