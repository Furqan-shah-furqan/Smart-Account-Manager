import 'models.dart';
import 'supabase_service.dart';

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

  double get totalRecovery => recoveries.fold(0, (sum, item) => sum + item.receivedAmount);
  double get totalExpenses => expenses.fold(0, (sum, item) => sum + item.amount);
  double get depositTotal => deposits.fold(0, (sum, item) => sum + item.total);
  double get claimAmount => claims.fold(0, (sum, item) => sum + item.amount);
  double get companyPayable => companyPurchases.fold(0, (sum, item) => sum + item.remainingAmount);
  double get purchaseTotal => companyPurchases.fold(0, (sum, item) => sum + item.totalBill);
  double get marketCredit => creditSales - totalRecovery;

  double get stockValue {
    return products.fold(0, (sum, item) => sum + (item.warehouseStock * item.purchasePrice));
  }

  double get cashBalance => cashSales + totalRecovery - totalExpenses - depositTotal;

  double get monthlyProfitEstimate {
    double cost = 0;
    for (final sale in sales) {
      cost += (productById(sale.productId)?.purchasePrice ?? 0) * sale.quantity;
    }
    return grossSale - cost - totalExpenses - claimAmount;
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
    final fuel = dsrExpenses.where((item) => item.type == 'Fuel Expense').fold(0.0, (sum, item) => sum + item.amount);
    final office = dsrExpenses.where((item) => item.type == 'Office Expense').fold(0.0, (sum, item) => sum + item.amount);
    final recovery = dsrRecoveries.fold(0.0, (sum, item) => sum + item.receivedAmount);

    final netSale = gross - returnStockAmount + extraAmount;
    final netCashSale = netSale - fuel - office - credit;
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
