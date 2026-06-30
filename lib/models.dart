enum SaleType { cash, credit }

String saleTypeToDb(SaleType type) {
  return type == SaleType.cash ? 'cash' : 'credit';
}

SaleType saleTypeFromDb(String? value) {
  return value == 'credit' ? SaleType.credit : SaleType.cash;
}

String asText(dynamic value) => value?.toString() ?? '';

int asInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

double asDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

Map<String, dynamic> asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

class Company {
  final String id;
  final String name;
  final String phone;
  final String address;

  Company({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
  });

  factory Company.fromMap(Map<String, dynamic> map) {
    return Company(
      id: asText(map['id']),
      name: asText(map['name']),
      phone: asText(map['phone']),
      address: asText(map['address']),
    );
  }
}

class Profile {
  final String id;
  final String userId;
  final String companyId;
  final String fullName;
  final String role;

  Profile({
    required this.id,
    required this.userId,
    required this.companyId,
    required this.fullName,
    required this.role,
  });

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: asText(map['id']),
      userId: asText(map['user_id']),
      companyId: asText(map['company_id']),
      fullName: asText(map['full_name']),
      role: asText(map['role']),
    );
  }
}

class Supplier {
  final String id;
  final String name;
  final String phone;
  final String address;

  Supplier({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
  });

  factory Supplier.fromMap(Map<String, dynamic> map) {
    return Supplier(
      id: asText(map['id']),
      name: asText(map['name']),
      phone: asText(map['phone']),
      address: asText(map['address']),
    );
  }
}

class Dsr {
  final String id;
  final String name;
  final String phone;
  final String route;
  final String supplierId;
  final double salary;
  final double advanceBalance;

  Dsr({
    required this.id,
    required this.name,
    required this.phone,
    required this.route,
    required this.supplierId,
    required this.salary,
    required this.advanceBalance,
  });

  factory Dsr.fromMap(Map<String, dynamic> map) {
    return Dsr(
      id: asText(map['id']),
      name: asText(map['name']),
      phone: asText(map['phone']),
      route: asText(map['route']),
      supplierId: asText(map['supplier_id']),
      salary: asDouble(map['salary']),
      advanceBalance: asDouble(map['advance_balance']),
    );
  }
}

class Shopkeeper {
  final String id;
  final String shopName;
  final String ownerName;
  final String phone;
  final String area;
  final String dsrId;
  final double pendingCredit;

  Shopkeeper({
    required this.id,
    required this.shopName,
    required this.ownerName,
    required this.phone,
    required this.area,
    required this.dsrId,
    required this.pendingCredit,
  });

  factory Shopkeeper.fromMap(Map<String, dynamic> map) {
    return Shopkeeper(
      id: asText(map['id']),
      shopName: asText(map['shop_name']),
      ownerName: asText(map['owner_name']),
      phone: asText(map['phone']),
      area: asText(map['area']),
      dsrId: asText(map['dsr_id']),
      pendingCredit: asDouble(map['pending_credit']),
    );
  }
}

class Product {
  final String id;
  final String name;
  final String sku;
  final String category;
  final String brand;
  final String batchNo;
  final String mfgDate;
  final String expDate;
  final double purchasePrice;
  final double sellingPrice;
  final int warehouseStock;
  final int lowStockLimit;
  final int packetsPerCarton;
  final double companyDiscount;
  final double tradeDiscount;

  Product({
    required this.id,
    required this.name,
    required this.sku,
    required this.category,
    required this.brand,
    required this.batchNo,
    required this.mfgDate,
    required this.expDate,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.warehouseStock,
    required this.lowStockLimit,
    required this.packetsPerCarton,
    required this.companyDiscount,
    required this.tradeDiscount,
  });

  double get cartonPurchasePrice => purchasePrice * packetsPerCarton;
  double get cartonSellingPrice => sellingPrice * packetsPerCarton;

  factory Product.fromMap(Map<String, dynamic> map) {
    final packets = asInt(map['packets_per_carton']);
    return Product(
      id: asText(map['id']),
      name: asText(map['name']),
      sku: asText(map['sku']),
      category: asText(map['category']),
      brand: asText(map['brand']),
      batchNo: asText(map['batch_no']),
      mfgDate: asText(map['mfg_date']),
      expDate: asText(map['exp_date']),
      purchasePrice: asDouble(map['purchase_price']),
      sellingPrice: asDouble(map['selling_price']),
      warehouseStock: asInt(map['warehouse_stock']),
      lowStockLimit: asInt(map['low_stock_limit']),
      packetsPerCarton: packets <= 0 ? 1 : packets,
      companyDiscount: asDouble(map['company_discount']),
      tradeDiscount: asDouble(map['trade_discount']),
    );
  }
}

class CompanyPurchase {
  final String id;
  final String date;
  final String invoiceNo;
  final String companyName;
  final String productId;
  final String batchNo;
  final int cartons;
  final int packetsPerCarton;
  final int totalPackets;
  final double packetPurchasePrice;
  final double sellingPrice;
  final double companyDiscount;
  final double companyDiscountPercent;
  final double tradeDiscountPercent;
  final double grossBill;
  final double discountTotal;
  final double totalBill;
  final double paidAmount;
  final double remainingAmount;
  final String distributorName;
  final String manufacturerName;
  final String note;

  CompanyPurchase({
    required this.id,
    required this.date,
    required this.invoiceNo,
    required this.companyName,
    required this.productId,
    required this.batchNo,
    required this.cartons,
    required this.packetsPerCarton,
    required this.totalPackets,
    required this.packetPurchasePrice,
    required this.sellingPrice,
    required this.companyDiscount,
    required this.companyDiscountPercent,
    required this.tradeDiscountPercent,
    required this.grossBill,
    required this.discountTotal,
    required this.totalBill,
    required this.paidAmount,
    required this.remainingAmount,
    required this.distributorName,
    required this.manufacturerName,
    required this.note,
  });

  factory CompanyPurchase.fromMap(Map<String, dynamic> map) {
    final totalPackets = asInt(map['total_packets']);
    final purchasePrice = asDouble(map['packet_purchase_price']);
    final grossFromDb = asDouble(map['gross_bill']);
    final discountFromDb = asDouble(map['discount_total']);
    final legacyDiscount = asDouble(map['company_discount']);
    final totalBillFromDb = asDouble(map['total_bill']);
    final gross = grossFromDb > 0 ? grossFromDb : totalPackets * purchasePrice;
    final discount = discountFromDb > 0 ? discountFromDb : legacyDiscount;
    final totalBill = totalBillFromDb > 0
        ? totalBillFromDb
        : (gross - discount).clamp(0, double.infinity).toDouble();
    final paid = asDouble(map['paid_amount']);
    final remainingFromDb = asDouble(map['remaining_amount']);

    return CompanyPurchase(
      id: asText(map['id']),
      date: asText(map['date']),
      invoiceNo: asText(map['invoice_no']),
      companyName: asText(map['company_name']),
      productId: asText(map['product_id']),
      batchNo: asText(map['batch_no']),
      cartons: asInt(map['cartons']),
      packetsPerCarton: asInt(map['packets_per_carton']),
      totalPackets: totalPackets,
      packetPurchasePrice: purchasePrice,
      sellingPrice: asDouble(map['selling_price']),
      companyDiscount: legacyDiscount > 0 ? legacyDiscount : discount,
      companyDiscountPercent: asDouble(map['company_discount_percent']),
      tradeDiscountPercent: asDouble(map['trade_discount_percent']),
      grossBill: gross,
      discountTotal: discount,
      totalBill: totalBill,
      paidAmount: paid,
      remainingAmount: remainingFromDb > 0
          ? remainingFromDb
          : (totalBill - paid).clamp(0, double.infinity).toDouble(),
      distributorName: asText(map['distributor_name']),
      manufacturerName: asText(map['manufacturer_name']).isNotEmpty
          ? asText(map['manufacturer_name'])
          : asText(map['company_name']),
      note: asText(map['note']),
    );
  }
}

class DsrStock {
  final String id;
  final String dsrId;
  final String productId;
  final int quantity;

  DsrStock({
    required this.id,
    required this.dsrId,
    required this.productId,
    required this.quantity,
  });

  factory DsrStock.fromMap(Map<String, dynamic> map) {
    return DsrStock(
      id: asText(map['id']),
      dsrId: asText(map['dsr_id']),
      productId: asText(map['product_id']),
      quantity: asInt(map['quantity']),
    );
  }
}

class LoadEntry {
  final String id;
  final String date;
  final String dsrId;
  final String supplierId;
  final String productId;
  final int quantity;
  final String settlementId;
  final int loadCartons;
  final int loadLooseBoxes;
  final int returnCartons;
  final int returnLooseBoxes;
  final int returnQuantity;
  final int packetsPerCarton;
  final double sellingPrice;
  final double companyDiscountPercent;
  final double tradeOfferPercent;
  final double grossAmount;
  final double returnAmount;
  final double discountAmount;
  final double netAmount;
  final double extraAmount;
  final double physicalCash;
  final String note;
  final String generatedAt;

  LoadEntry({
    required this.id,
    required this.date,
    required this.dsrId,
    required this.supplierId,
    required this.productId,
    required this.quantity,
    required this.settlementId,
    required this.loadCartons,
    required this.loadLooseBoxes,
    required this.returnCartons,
    required this.returnLooseBoxes,
    required this.returnQuantity,
    required this.packetsPerCarton,
    required this.sellingPrice,
    required this.companyDiscountPercent,
    required this.tradeOfferPercent,
    required this.grossAmount,
    required this.returnAmount,
    required this.discountAmount,
    required this.netAmount,
    required this.extraAmount,
    required this.physicalCash,
    required this.note,
    required this.generatedAt,
  });

  bool get isGenerated => generatedAt.trim().isNotEmpty;

  factory LoadEntry.fromMap(Map<String, dynamic> map) {
    final quantity = asInt(map['quantity']);
    final price = asDouble(map['selling_price']);
    final grossFromDb = asDouble(map['gross_amount']);
    final returnQty = asInt(map['return_quantity']);
    final returnFromDb = asDouble(map['return_amount']);
    final discount = asDouble(map['discount_amount']);
    final gross = grossFromDb > 0 ? grossFromDb : quantity * price;
    final returnAmount = returnFromDb > 0 ? returnFromDb : returnQty * price;
    final netFromDb = asDouble(map['net_amount']);

    return LoadEntry(
      id: asText(map['id']),
      date: asText(map['date']),
      dsrId: asText(map['dsr_id']),
      supplierId: asText(map['supplier_id']),
      productId: asText(map['product_id']),
      quantity: quantity,
      settlementId: asText(map['settlement_id']),
      loadCartons: asInt(map['load_cartons']),
      loadLooseBoxes: asInt(map['load_loose_boxes']),
      returnCartons: asInt(map['return_cartons']),
      returnLooseBoxes: asInt(map['return_loose_boxes']),
      returnQuantity: returnQty,
      packetsPerCarton: asInt(map['packets_per_carton']) <= 0
          ? 1
          : asInt(map['packets_per_carton']),
      sellingPrice: price,
      companyDiscountPercent: asDouble(map['company_discount_percent']),
      tradeOfferPercent: asDouble(map['trade_offer_percent']),
      grossAmount: gross,
      returnAmount: returnAmount,
      discountAmount: discount,
      netAmount: netFromDb > 0
          ? netFromDb
          : (gross - returnAmount - discount)
              .clamp(0, double.infinity)
              .toDouble(),
      extraAmount: asDouble(map['extra_amount']),
      physicalCash: asDouble(map['physical_cash']),
      note: asText(map['note']),
      generatedAt: asText(map['generated_at']),
    );
  }
}

class SaleEntry {
  final String id;
  final String billNo;
  final String date;
  final String dsrId;
  final String shopkeeperId;
  final String productId;
  final int quantity;
  final double price;
  final double purchaseCost;
  final SaleType type;
  final double total;
  final String sourceType;
  final String loadSettlementId;
  final String loadEntryId;

  SaleEntry({
    required this.id,
    required this.billNo,
    required this.date,
    required this.dsrId,
    required this.shopkeeperId,
    required this.productId,
    required this.quantity,
    required this.price,
    required this.purchaseCost,
    required this.type,
    required this.total,
    required this.sourceType,
    required this.loadSettlementId,
    required this.loadEntryId,
  });

  factory SaleEntry.fromMap(Map<String, dynamic> map) {
    final quantity = asInt(map['quantity']);
    final price = asDouble(map['price']);
    final totalFromDb = asDouble(map['total']);
    final loadFormAmount = asDouble(map['load_form_amount']);

    return SaleEntry(
      id: asText(map['id']),
      billNo: asText(map['bill_no']),
      date: asText(map['date']),
      dsrId: asText(map['dsr_id']),
      shopkeeperId: asText(map['shopkeeper_id']),
      productId: asText(map['product_id']),
      quantity: quantity,
      price: price,
      purchaseCost: asDouble(map['purchase_cost']),
      type: saleTypeFromDb(asText(map['sale_type'])),
      total: loadFormAmount > 0
          ? loadFormAmount
          : (totalFromDb > 0 ? totalFromDb : quantity * price),
      sourceType: asText(map['source_type']).isEmpty
          ? 'manual'
          : asText(map['source_type']),
      loadSettlementId: asText(map['load_settlement_id']),
      loadEntryId: asText(map['load_entry_id']),
    );
  }
}

class RecoveryEntry {
  final String id;
  final String chequeBillNo;
  final String date;
  final String dsrId;
  final String shopkeeperId;
  final double receivedAmount;
  final double balanceAfter;

  RecoveryEntry({
    required this.id,
    required this.chequeBillNo,
    required this.date,
    required this.dsrId,
    required this.shopkeeperId,
    required this.receivedAmount,
    required this.balanceAfter,
  });

  factory RecoveryEntry.fromMap(Map<String, dynamic> map) {
    return RecoveryEntry(
      id: asText(map['id']),
      chequeBillNo: asText(map['cheque_bill_no']),
      date: asText(map['date']),
      dsrId: asText(map['dsr_id']),
      shopkeeperId: asText(map['shopkeeper_id']),
      receivedAmount: asDouble(map['received_amount']),
      balanceAfter: asDouble(map['balance_after']),
    );
  }
}

class ExpenseEntry {
  final String id;
  final String date;
  final String dsrId;
  final String type;
  final double amount;
  final String note;

  ExpenseEntry({
    required this.id,
    required this.date,
    required this.dsrId,
    required this.type,
    required this.amount,
    required this.note,
  });

  factory ExpenseEntry.fromMap(Map<String, dynamic> map) {
    return ExpenseEntry(
      id: asText(map['id']),
      date: asText(map['date']),
      dsrId: asText(map['dsr_id']),
      type: asText(map['type']),
      amount: asDouble(map['amount']),
      note: asText(map['note']),
    );
  }
}

class DepositEntry {
  final String id;
  final String date;
  final String party;
  final String distributorName;
  final String referenceNo;
  final String note;
  final int note5000;
  final int note1000;
  final int note500;
  final int note100;
  final int note50;
  final int note20;
  final int note10;
  final double coins;
  final double paymentAmount;
  final double total;

  DepositEntry({
    required this.id,
    required this.date,
    required this.party,
    required this.distributorName,
    required this.referenceNo,
    required this.note,
    required this.note5000,
    required this.note1000,
    required this.note500,
    required this.note100,
    required this.note50,
    required this.note20,
    required this.note10,
    required this.coins,
    required this.paymentAmount,
    required this.total,
  });

  factory DepositEntry.fromMap(Map<String, dynamic> map) {
    final denominations = asInt(map['note_5000']) * 5000 +
        asInt(map['note_1000']) * 1000 +
        asInt(map['note_500']) * 500 +
        asInt(map['note_100']) * 100 +
        asInt(map['note_50']) * 50 +
        asInt(map['note_20']) * 20 +
        asInt(map['note_10']) * 10 +
        asDouble(map['coins']);
    final payment = asDouble(map['payment_amount']);
    final totalFromDb = asDouble(map['total']);

    return DepositEntry(
      id: asText(map['id']),
      date: asText(map['date']),
      party: asText(map['party']),
      distributorName: asText(map['distributor_name']),
      referenceNo: asText(map['reference_no']),
      note: asText(map['note']),
      note5000: asInt(map['note_5000']),
      note1000: asInt(map['note_1000']),
      note500: asInt(map['note_500']),
      note100: asInt(map['note_100']),
      note50: asInt(map['note_50']),
      note20: asInt(map['note_20']),
      note10: asInt(map['note_10']),
      coins: asDouble(map['coins']),
      paymentAmount: payment,
      total: totalFromDb > 0
          ? totalFromDb
          : (payment > 0 ? payment : denominations.toDouble()),
    );
  }
}

class ClaimEntry {
  final String id;
  final String date;
  final String productId;
  final String type;
  final int quantity;
  final double amount;
  final String note;

  ClaimEntry({
    required this.id,
    required this.date,
    required this.productId,
    required this.type,
    required this.quantity,
    required this.amount,
    required this.note,
  });

  factory ClaimEntry.fromMap(Map<String, dynamic> map) {
    return ClaimEntry(
      id: asText(map['id']),
      date: asText(map['date']),
      productId: asText(map['product_id']),
      type: asText(map['type']),
      quantity: asInt(map['quantity']),
      amount: asDouble(map['amount']),
      note: asText(map['note']),
    );
  }
}

class InvestmentEntry {
  final String id;
  final String date;
  final String investorName;
  final String investmentType;
  final String customInvestmentType;
  final String paymentMethod;
  final String customPaymentMethod;
  final String referenceNo;
  final double amount;
  final String note;

  InvestmentEntry({
    required this.id,
    required this.date,
    required this.investorName,
    required this.investmentType,
    required this.customInvestmentType,
    required this.paymentMethod,
    required this.customPaymentMethod,
    required this.referenceNo,
    required this.amount,
    required this.note,
  });

  String get displayType =>
      investmentType == 'Other' && customInvestmentType.trim().isNotEmpty
          ? customInvestmentType.trim()
          : investmentType;

  String get displayPaymentMethod =>
      paymentMethod == 'Other' && customPaymentMethod.trim().isNotEmpty
          ? customPaymentMethod.trim()
          : paymentMethod;

  bool get isCash => paymentMethod == 'Cash';

  bool get isBankOrOnline =>
      paymentMethod == 'Bank Transfer' || paymentMethod == 'Online Transfer';

  factory InvestmentEntry.fromMap(Map<String, dynamic> map) {
    return InvestmentEntry(
      id: asText(map['id']),
      date: asText(map['date']),
      investorName: asText(map['investor_name']),
      investmentType: asText(map['investment_type']),
      customInvestmentType: asText(map['custom_investment_type']),
      paymentMethod: asText(map['payment_method']),
      customPaymentMethod: asText(map['custom_payment_method']),
      referenceNo: asText(map['reference_no']),
      amount: asDouble(map['amount']),
      note: asText(map['note']),
    );
  }
}

class DsrDailyReport {
  final String date;
  final String dsrId;
  final double grossSale;
  final double returnStockAmount;
  final double extraAmount;
  final double netSale;
  final double fuelExpense;
  final double officeExpense;
  final double creditSale;
  final double netCashSale;
  final double recovery;
  final double totalDsrCash;
  final double physicalCash;
  final double shortAmount;
  final double excessAmount;

  DsrDailyReport({
    required this.date,
    required this.dsrId,
    required this.grossSale,
    required this.returnStockAmount,
    required this.extraAmount,
    required this.netSale,
    required this.fuelExpense,
    required this.officeExpense,
    required this.creditSale,
    required this.netCashSale,
    required this.recovery,
    required this.totalDsrCash,
    required this.physicalCash,
    required this.shortAmount,
    required this.excessAmount,
  });
}
