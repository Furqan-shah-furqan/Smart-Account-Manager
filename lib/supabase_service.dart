import 'package:supabase_flutter/supabase_flutter.dart';
import 'models.dart';

class SupabaseService {
  final SupabaseClient client = Supabase.instance.client;

  User? get currentUser => client.auth.currentUser;

  String get currentUserId {
    final user = currentUser;
    if (user == null) throw Exception('User not logged in');
    return user.id;
  }

  void _validateAuthFields({required String email, required String password}) {
    final cleanEmail = email.trim().toLowerCase();
    final emailOk = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(cleanEmail);

    if (cleanEmail.isEmpty) {
      throw Exception('Email is required');
    }
    if (!emailOk) {
      throw Exception('Enter a valid email address like yourname@gmail.com');
    }
    if (cleanEmail == 'nobody@gmail.com' ||
        cleanEmail.startsWith('nobody@') ||
        cleanEmail.startsWith('test@')) {
      throw Exception('This test email is rejected by Supabase. Use your real email or a Gmail alias like yourname+test1@gmail.com');
    }
    if (password.trim().length < 6) {
      throw Exception('Password must be at least 6 characters');
    }
  }

  String _friendlyAuthError(Object error) {
    if (error is AuthException) {
      final message = error.message.toLowerCase();
      final code = (error.code ?? '').toLowerCase();
      final status = error.statusCode;

      if (status == '429' ||
          code.contains('over_email_send_rate_limit') ||
          message.contains('rate limit')) {
        return 'Signup email limit is reached in Supabase. Wait 1 hour, or disable Confirm Email in Supabase Auth settings for testing, then try again.';
      }
      if (code.contains('email_address_invalid') ||
          message.contains('email address') && message.contains('invalid')) {
        return 'This email is rejected by Supabase. Use your real email or a Gmail alias like yourname+test1@gmail.com.';
      }
      if (message.contains('already registered') ||
          message.contains('already been registered') ||
          message.contains('user already registered')) {
        return 'This email already has an account. Click Login instead of Create Account.';
      }
      return error.message;
    }
    return error.toString().replaceFirst('Exception: ', '');
  }

  Future<void> signIn({required String email, required String password}) async {
    _validateAuthFields(email: email, password: password);
    try {
      await client.auth.signInWithPassword(
        email: email.trim().toLowerCase(),
        password: password.trim(),
      );
    } catch (error) {
      throw Exception(_friendlyAuthError(error));
    }
  }

  Future<void> signUp({required String email, required String password}) async {
    _validateAuthFields(email: email, password: password);
    try {
      await client.auth.signUp(
        email: email.trim().toLowerCase(),
        password: password.trim(),
      );
    } catch (error) {
      throw Exception(_friendlyAuthError(error));
    }
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  Future<Profile?> getMyProfile() async {
    final row = await client.from('profiles').select().eq('user_id', currentUserId).maybeSingle();
    if (row == null) return null;
    return Profile.fromMap(asMap(row));
  }

  Future<Company?> getMyCompany(String companyId) async {
    final row = await client.from('companies').select().eq('id', companyId).maybeSingle();
    if (row == null) return null;
    return Company.fromMap(asMap(row));
  }

  Future<void> createCompanyAndProfile({
    required String companyName,
    required String fullName,
  }) async {
    if (companyName.trim().isEmpty) throw Exception('Company name is required');
    if (fullName.trim().isEmpty) throw Exception('Your name is required');

    final company = await client.from('companies').insert({
      'name': companyName.trim(),
      'owner_id': currentUserId,
    }).select().single();

    await client.from('profiles').insert({
      'user_id': currentUserId,
      'company_id': company['id'],
      'full_name': fullName.trim(),
      'role': 'owner',
    });
  }

  Future<List<Supplier>> getSuppliers() async {
    final rows = await client.from('suppliers').select().order('created_at');
    return rows.map<Supplier>((item) => Supplier.fromMap(asMap(item))).toList();
  }

  Future<List<Dsr>> getDsrs() async {
    final rows = await client.from('dsrs').select().order('created_at');
    return rows.map<Dsr>((item) => Dsr.fromMap(asMap(item))).toList();
  }

  Future<List<Shopkeeper>> getShopkeepers() async {
    final rows = await client.from('shopkeepers').select().order('created_at');
    return rows.map<Shopkeeper>((item) => Shopkeeper.fromMap(asMap(item))).toList();
  }

  Future<List<Product>> getProducts() async {
    final rows = await client.from('products').select().order('created_at');
    return rows.map<Product>((item) => Product.fromMap(asMap(item))).toList();
  }

  Future<List<CompanyPurchase>> getCompanyPurchases() async {
    final rows = await client.from('company_purchases').select().order('created_at', ascending: false);
    return rows.map<CompanyPurchase>((item) => CompanyPurchase.fromMap(asMap(item))).toList();
  }

  Future<List<DsrStock>> getDsrStocks() async {
    final rows = await client.from('dsr_stocks').select().order('created_at');
    return rows.map<DsrStock>((item) => DsrStock.fromMap(asMap(item))).toList();
  }

  Future<List<LoadEntry>> getLoads() async {
    final rows = await client.from('load_entries').select().order('created_at', ascending: false);
    return rows.map<LoadEntry>((item) => LoadEntry.fromMap(asMap(item))).toList();
  }

  Future<List<SaleEntry>> getSales() async {
    final rows = await client.from('sales').select().order('created_at', ascending: false);
    return rows.map<SaleEntry>((item) => SaleEntry.fromMap(asMap(item))).toList();
  }

  Future<List<RecoveryEntry>> getRecoveries() async {
    final rows = await client.from('recoveries').select().order('created_at', ascending: false);
    return rows.map<RecoveryEntry>((item) => RecoveryEntry.fromMap(asMap(item))).toList();
  }

  Future<List<ExpenseEntry>> getExpenses() async {
    final rows = await client.from('expenses').select().order('created_at', ascending: false);
    return rows.map<ExpenseEntry>((item) => ExpenseEntry.fromMap(asMap(item))).toList();
  }

  Future<List<DepositEntry>> getDeposits() async {
    final rows = await client.from('deposits').select().order('created_at', ascending: false);
    return rows.map<DepositEntry>((item) => DepositEntry.fromMap(asMap(item))).toList();
  }

  Future<List<ClaimEntry>> getClaims() async {
    final rows = await client.from('claims').select().order('created_at', ascending: false);
    return rows.map<ClaimEntry>((item) => ClaimEntry.fromMap(asMap(item))).toList();
  }

  Future<void> addSupplier({
    required String companyId,
    required String name,
    required String phone,
    required String address,
  }) async {
    if (name.trim().isEmpty) throw Exception('Supplier name is required');
    await client.from('suppliers').insert({
      'company_id': companyId,
      'name': name.trim(),
      'phone': phone.trim(),
      'address': address.trim(),
      'created_by': currentUserId,
    });
  }

  Future<void> addDsr({
    required String companyId,
    required String supplierId,
    required String name,
    required String phone,
    required String route,
    required double salary,
  }) async {
    if (name.trim().isEmpty) throw Exception('DSR name is required');
    await client.from('dsrs').insert({
      'company_id': companyId,
      'supplier_id': supplierId,
      'name': name.trim(),
      'phone': phone.trim(),
      'route': route.trim(),
      'salary': salary,
      'created_by': currentUserId,
    });
  }

  Future<void> addShopkeeper({
    required String companyId,
    required String dsrId,
    required String shopName,
    required String ownerName,
    required String phone,
    required String area,
  }) async {
    if (shopName.trim().isEmpty) throw Exception('Shop name is required');
    await client.from('shopkeepers').insert({
      'company_id': companyId,
      'dsr_id': dsrId,
      'shop_name': shopName.trim(),
      'owner_name': ownerName.trim(),
      'phone': phone.trim(),
      'area': area.trim(),
      'created_by': currentUserId,
    });
  }

  Future<void> addProduct({
    required String companyId,
    required String name,
    required String sku,
    required String category,
    required String brand,
    required String batchNo,
    required String mfgDate,
    required String expDate,
    required double purchasePrice,
    required double sellingPrice,
    required int warehouseStock,
    required int lowStockLimit,
    required int packetsPerCarton,
    required double companyDiscount,
    required double tradeDiscount,
  }) async {
    if (name.trim().isEmpty) throw Exception('Product name is required');
    if (purchasePrice <= 0) throw Exception('Packet purchase price must be greater than 0');
    if (sellingPrice <= 0) throw Exception('Packet selling price must be greater than 0');
    if (packetsPerCarton <= 0) throw Exception('Packets per carton must be greater than 0');

    await client.from('products').insert({
      'company_id': companyId,
      'name': name.trim(),
      'sku': sku.trim(),
      'category': category.trim(),
      'brand': brand.trim(),
      'batch_no': batchNo.trim(),
      'mfg_date': mfgDate.trim().isEmpty ? null : mfgDate.trim(),
      'exp_date': expDate.trim().isEmpty ? null : expDate.trim(),
      'purchase_price': purchasePrice,
      'selling_price': sellingPrice,
      'warehouse_stock': warehouseStock,
      'low_stock_limit': lowStockLimit,
      'packets_per_carton': packetsPerCarton,
      'company_discount': companyDiscount,
      'trade_discount': tradeDiscount,
      'created_by': currentUserId,
    });
  }


  Future<String> addProductReturningId({
    required String companyId,
    required String name,
    required String sku,
    required String category,
    required String brand,
    required String batchNo,
    required String mfgDate,
    required String expDate,
    required double purchasePrice,
    required double sellingPrice,
    required int warehouseStock,
    required int lowStockLimit,
    required int packetsPerCarton,
    required double companyDiscount,
    required double tradeDiscount,
  }) async {
    if (name.trim().isEmpty) throw Exception('Product name is required');

    final row = await client
        .from('products')
        .insert({
          'company_id': companyId,
          'name': name.trim(),
          'sku': sku.trim(),
          'category': category.trim(),
          'brand': brand.trim(),
          'batch_no': batchNo.trim(),
          'mfg_date': mfgDate.trim().isEmpty ? null : mfgDate.trim(),
          'exp_date': expDate.trim().isEmpty ? null : expDate.trim(),
          'purchase_price': purchasePrice,
          'selling_price': sellingPrice,
          'warehouse_stock': warehouseStock,
          'low_stock_limit': lowStockLimit,
          'packets_per_carton': packetsPerCarton,
          'company_discount': companyDiscount,
          'trade_discount': tradeDiscount,
          'created_by': currentUserId,
        })
        .select('id')
        .single();

    return asText(row['id']);
  }

  Future<void> addCompanyPurchase({
    required String companyId,
    required String invoiceNo,
    required String companyName,
    required String productId,
    required String batchNo,
    required int cartons,
    required int packetsPerCarton,
    required double packetPurchasePrice,
    required double companyDiscount,
    required double paidAmount,
    required String note,
    int extraUnits = 0,
  }) async {
    if (invoiceNo.trim().isEmpty) throw Exception('Invoice number is required');
    if (companyName.trim().isEmpty) throw Exception('Company name is required');
    if (productId.isEmpty) throw Exception('Product is required');
    if (packetsPerCarton <= 0) throw Exception('Packets per carton must be greater than 0');
    if (packetPurchasePrice <= 0) throw Exception('Packet purchase price must be greater than 0');

    final safeCartons = cartons < 0 ? 0 : cartons;
    final safeExtraUnits = extraUnits < 0 ? 0 : extraUnits;
    final totalPackets = (safeCartons * packetsPerCarton) + safeExtraUnits;
    if (totalPackets <= 0) throw Exception('Cartons or units must be greater than 0');
    final grossBill = totalPackets * packetPurchasePrice;
    final safeDiscount = companyDiscount < 0 ? 0 : companyDiscount;
    final totalBill = (grossBill - safeDiscount).clamp(0, double.infinity).toDouble();
    final safePaid = paidAmount < 0 ? 0 : paidAmount;
    final remaining = (totalBill - safePaid).clamp(0, double.infinity).toDouble();

    await client.from('company_purchases').insert({
      'company_id': companyId,
      'invoice_no': invoiceNo.trim(),
      'company_name': companyName.trim(),
      'product_id': productId,
      'batch_no': batchNo.trim(),
      'cartons': safeCartons,
      'packets_per_carton': packetsPerCarton,
      'total_packets': totalPackets,
      'packet_purchase_price': packetPurchasePrice,
      'company_discount': safeDiscount,
      'total_bill': totalBill,
      'paid_amount': safePaid,
      'remaining_amount': remaining,
      'note': note.trim(),
      'created_by': currentUserId,
    });

    final product = await client.from('products').select('warehouse_stock').eq('id', productId).single();
    final warehouseStock = asInt(product['warehouse_stock']);
    await client.from('products').update({
      'warehouse_stock': warehouseStock + totalPackets,
      'purchase_price': packetPurchasePrice,
      'packets_per_carton': packetsPerCarton,
      'company_discount': safeDiscount,
      if (batchNo.trim().isNotEmpty) 'batch_no': batchNo.trim(),
    }).eq('id', productId);

  }
  Future<void> returnStock({
  required String companyId,
  required String dsrId,
  required String productId,
  required int quantity,
  String note = '',
}) async {
  if (quantity <= 0) {
    throw Exception('Return quantity must be greater than 0');
  }

  // Distributor keeps one shared stock. DSRs do not hold separate stock.
  // This return is saved only as a movement/note for settlement history.
  await client.from('stock_movements').insert({
    'company_id': companyId,
    'product_id': productId,
    'dsr_id': dsrId,
    'movement_type': 'Return Note',
    'quantity': quantity,
    'note': note.trim().isEmpty
        ? 'Return noted for DSR settlement. Distributor stock is shared.'
        : note.trim(),
    'created_by': currentUserId,
  });
}

  Future<void> loadStock({
    required String companyId,
    required String dsrId,
    required String supplierId,
    required String productId,
    required int quantity,
  }) async {
    if (quantity <= 0) throw Exception('Quantity must be greater than 0');

    final product = await client
        .from('products')
        .select('warehouse_stock')
        .eq('id', productId)
        .single();
    final warehouseStock = asInt(product['warehouse_stock']);
    if (warehouseStock < quantity) throw Exception('Not enough distributor stock');

    // Do not deduct stock here. Load form is only a DSR/salesman sheet.
    // Real stock deduction happens when an order/sale is booked.
    final now = DateTime.now();
    final today =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    await client.from('load_entries').insert({
      'company_id': companyId,
      'date': today,
      'dsr_id': dsrId,
      'supplier_id': supplierId,
      'product_id': productId,
      'quantity': quantity,
      'created_by': currentUserId,
    });

    await client.from('stock_movements').insert({
      'company_id': companyId,
      'product_id': productId,
      'dsr_id': dsrId,
      'movement_type': 'Load Form Created',
      'quantity': quantity,
      'note': 'Load form created. Distributor stock remains shared.',
      'created_by': currentUserId,
    });
  }

  Future<void> bookSale({
    required String companyId,
    required String billNo,
    required String dsrId,
    required String productId,
    required int quantity,
    required double price,
    required SaleType type,
  }) async {
    if (billNo.trim().isEmpty) throw Exception('Bill number is required');
    if (quantity <= 0) throw Exception('Quantity must be greater than 0');
    if (price <= 0) throw Exception('Price must be greater than 0');

    final product = await client
        .from('products')
        .select('warehouse_stock')
        .eq('id', productId)
        .single();
    final warehouseStock = asInt(product['warehouse_stock']);

    if (warehouseStock < quantity) {
      throw Exception('Not enough distributor stock');
    }

    await client.from('products').update({
      'warehouse_stock': warehouseStock - quantity,
    }).eq('id', productId);

    await client.from('sales').insert({
      'company_id': companyId,
      'bill_no': billNo.trim(),
      'dsr_id': dsrId,
      'shopkeeper_id': null,
      'product_id': productId,
      'quantity': quantity,
      'price': price,
      'sale_type': saleTypeToDb(type),
      'created_by': currentUserId,
    });

    await client.from('stock_movements').insert({
      'company_id': companyId,
      'product_id': productId,
      'dsr_id': dsrId,
      'movement_type': type == SaleType.cash ? 'Cash Sale' : 'Credit Sale',
      'quantity': -quantity,
      'note': '${billNo.trim()} • Deducted from shared distributor stock',
      'created_by': currentUserId,
    });
  }

  Future<void> addRecovery({
    required String companyId,
    required String chequeBillNo,
    required String dsrId,
    required double amount,
  }) async {
    if (amount <= 0) throw Exception('Amount must be greater than 0');

    final creditRows = await client
        .from('sales')
        .select('total')
        .eq('company_id', companyId)
        .eq('dsr_id', dsrId)
        .eq('sale_type', 'credit');

    final recoveryRows = await client
        .from('recoveries')
        .select('received_amount')
        .eq('company_id', companyId)
        .eq('dsr_id', dsrId);

    final creditTotal = creditRows.fold<double>(
        0, (sum, item) => sum + asDouble(asMap(item)['total']));
    final recoveredTotal = recoveryRows.fold<double>(
        0, (sum, item) => sum + asDouble(asMap(item)['received_amount']));
    final pending = creditTotal - recoveredTotal;

    if (amount > pending) throw Exception('Recovery is greater than pending credit');

    final balanceAfter = pending - amount;

    await client.from('recoveries').insert({
      'company_id': companyId,
      'cheque_bill_no': chequeBillNo.trim(),
      'dsr_id': dsrId,
      'shopkeeper_id': null,
      'received_amount': amount,
      'balance_after': balanceAfter,
      'created_by': currentUserId,
    });
  }

  Future<void> addExpense({
    required String companyId,
    required String dsrId,
    required String type,
    required double amount,
    required String note,
  }) async {
    if (amount <= 0) throw Exception('Amount must be greater than 0');
    await client.from('expenses').insert({
      'company_id': companyId,
      'dsr_id': dsrId,
      'type': type,
      'amount': amount,
      'note': note.trim(),
      'created_by': currentUserId,
    });
  }

  Future<void> addDeposit({
    required String companyId,
    required String party,
    required Map<int, int> notes,
    required double coins,
  }) async {
    await client.from('deposits').insert({
      'company_id': companyId,
      'party': party.trim().isEmpty ? 'Deposit' : party.trim(),
      'note_5000': notes[5000] ?? 0,
      'note_1000': notes[1000] ?? 0,
      'note_500': notes[500] ?? 0,
      'note_100': notes[100] ?? 0,
      'note_50': notes[50] ?? 0,
      'note_20': notes[20] ?? 0,
      'note_10': notes[10] ?? 0,
      'coins': coins,
      'created_by': currentUserId,
    });
  }


  Future<void> updateCompanyPurchasePayment({
    required String purchaseId,
    required double paidAmount,
    required double remainingAmount,
  }) async {
    if (purchaseId.trim().isEmpty) throw Exception('Purchase ID is required');
    final safePaid = paidAmount < 0 ? 0 : paidAmount;
    final safeRemaining = remainingAmount < 0 ? 0 : remainingAmount;

    await client.from('company_purchases').update({
      'paid_amount': safePaid,
      'remaining_amount': safeRemaining,
    }).eq('id', purchaseId);
  }

  Future<void> addClaim({
    required String companyId,
    required String productId,
    required String type,
    required int quantity,
    required double amount,
    required String note,
  }) async {
    if (quantity <= 0) throw Exception('Quantity must be greater than 0');
    await client.from('claims').insert({
      'company_id': companyId,
      'product_id': productId,
      'type': type,
      'quantity': quantity,
      'amount': amount,
      'note': note.trim(),
      'created_by': currentUserId,
    });
  }

  Future<void> upsertCashCount({
    required String companyId,
    required String dsrId,
    required String date,
    required int note5000,
    required int note1000,
    required int note500,
    required int note100,
    required int note50,
    required int note20,
    required int note10,
    required double coins,
  }) async {
    final existing = await client
        .from('cash_counts')
        .select('id')
        .eq('dsr_id', dsrId)
        .eq('date', date)
        .maybeSingle();

    final data = {
      'company_id': companyId,
      'date': date,
      'dsr_id': dsrId,
      'note_5000': note5000,
      'note_1000': note1000,
      'note_500': note500,
      'note_100': note100,
      'note_50': note50,
      'note_20': note20,
      'note_10': note10,
      'coins': coins,
      'created_by': currentUserId,
    };

    if (existing == null) {
      await client.from('cash_counts').insert(data);
    } else {
      await client.from('cash_counts').update(data).eq('id', existing['id']);
    }
  }


  Future<void> updateSupplier({
    required String id,
    required String name,
    required String phone,
    required String address,
  }) async {
    if (name.trim().isEmpty) throw Exception('Supplier name is required');

    await client.from('suppliers').update({
      'name': name.trim(),
      'phone': phone.trim(),
      'address': address.trim(),
    }).eq('id', id);
  }

  Future<void> deleteSupplier(String id) async {
    final linkedDsrs = await client
        .from('dsrs')
        .select('name, route')
        .eq('supplier_id', id);

    if (linkedDsrs.isNotEmpty) {
      final linkedNames = linkedDsrs.map<String>((item) {
        final name = item['name']?.toString() ?? 'Unknown DSR';
        final route = item['route']?.toString() ?? '';
        return route.trim().isEmpty ? name : '$name ($route)';
      }).join(', ');

      throw Exception(
        'Cannot delete supplier because it is linked with DSR: $linkedNames',
      );
    }

    await client.from('suppliers').delete().eq('id', id);
  }

  Future<void> updateDsr({
    required String id,
    required String supplierId,
    required String name,
    required String phone,
    required String route,
    required double salary,
  }) async {
    if (name.trim().isEmpty) throw Exception('DSR name is required');

    await client.from('dsrs').update({
      'supplier_id': supplierId,
      'name': name.trim(),
      'phone': phone.trim(),
      'route': route.trim(),
      'salary': salary,
    }).eq('id', id);
  }

  Future<void> deleteDsr(String id) async {
    final linkedShops = await client
        .from('shopkeepers')
        .select('shop_name')
        .eq('dsr_id', id);

    final linkedSales = await client
        .from('sales')
        .select('bill_no')
        .eq('dsr_id', id)
        .limit(5);

    if (linkedShops.isNotEmpty || linkedSales.isNotEmpty) {
      final shopNames = linkedShops.map<String>((item) {
        return item['shop_name']?.toString() ?? 'Unknown Shop';
      }).join(', ');

      final billNumbers = linkedSales.map<String>((item) {
        return item['bill_no']?.toString() ?? 'Unknown Bill';
      }).join(', ');

      final parts = <String>[];

      if (shopNames.isNotEmpty) {
        parts.add('linked shops: $shopNames');
      }

      if (billNumbers.isNotEmpty) {
        parts.add('linked sales bills: $billNumbers');
      }

      throw Exception('Cannot delete DSR because it has ${parts.join(' and ')}.');
    }

    await client.from('dsrs').delete().eq('id', id);
  }

  Future<void> updateShopkeeper({
    required String id,
    required String dsrId,
    required String shopName,
    required String ownerName,
    required String phone,
    required String area,
  }) async {
    if (shopName.trim().isEmpty) throw Exception('Shop name is required');

    await client.from('shopkeepers').update({
      'dsr_id': dsrId,
      'shop_name': shopName.trim(),
      'owner_name': ownerName.trim(),
      'phone': phone.trim(),
      'area': area.trim(),
    }).eq('id', id);
  }

  Future<void> deleteShopkeeper(String id) async {
    final linkedSales = await client
        .from('sales')
        .select('bill_no')
        .eq('shopkeeper_id', id)
        .limit(5);

    final linkedRecoveries = await client
        .from('recoveries')
        .select('cheque_bill_no')
        .eq('shopkeeper_id', id)
        .limit(5);

    if (linkedSales.isNotEmpty || linkedRecoveries.isNotEmpty) {
      final bills = linkedSales.map<String>((item) {
        return item['bill_no']?.toString() ?? 'Unknown Bill';
      }).join(', ');

      final recoveryBills = linkedRecoveries.map<String>((item) {
        return item['cheque_bill_no']?.toString() ?? 'Unknown Recovery';
      }).join(', ');

      final parts = <String>[];

      if (bills.isNotEmpty) {
        parts.add('sales bills: $bills');
      }

      if (recoveryBills.isNotEmpty) {
        parts.add('recovery bills: $recoveryBills');
      }

      throw Exception(
        'Cannot delete shopkeeper because it has linked ${parts.join(' and ')}.',
      );
    }

    await client.from('shopkeepers').delete().eq('id', id);
  }

  Future<void> updateProduct({
    required String id,
    required String name,
    required String sku,
    required String category,
    required String brand,
    required String batchNo,
    required String mfgDate,
    required String expDate,
    required double purchasePrice,
    required double sellingPrice,
    required int warehouseStock,
    required int lowStockLimit,
    required int packetsPerCarton,
    required double companyDiscount,
    required double tradeDiscount,
  }) async {
    if (name.trim().isEmpty) throw Exception('Product name is required');
    if (purchasePrice <= 0) throw Exception('Packet purchase price must be greater than 0');
    if (sellingPrice <= 0) throw Exception('Packet selling price must be greater than 0');
    if (packetsPerCarton <= 0) throw Exception('Packets per carton must be greater than 0');

    await client.from('products').update({
      'name': name.trim(),
      'sku': sku.trim(),
      'category': category.trim(),
      'brand': brand.trim(),
      'batch_no': batchNo.trim(),
      'mfg_date': mfgDate.trim().isEmpty ? null : mfgDate.trim(),
      'exp_date': expDate.trim().isEmpty ? null : expDate.trim(),
      'purchase_price': purchasePrice,
      'selling_price': sellingPrice,
      'warehouse_stock': warehouseStock,
      'low_stock_limit': lowStockLimit,
      'packets_per_carton': packetsPerCarton,
      'company_discount': companyDiscount,
      'trade_discount': tradeDiscount,
    }).eq('id', id);
  }

  Future<void> deleteProduct(String id) async {
    final linkedSales = await client
        .from('sales')
        .select('bill_no')
        .eq('product_id', id)
        .limit(5);

    final linkedLoads = await client
        .from('load_entries')
        .select('id')
        .eq('product_id', id)
        .limit(5);

    final linkedStock = await client
        .from('dsr_stocks')
        .select('dsr_id, quantity')
        .eq('product_id', id);

    if (linkedSales.isNotEmpty || linkedLoads.isNotEmpty || linkedStock.isNotEmpty) {
      final bills = linkedSales.map<String>((item) {
        return item['bill_no']?.toString() ?? 'Unknown Bill';
      }).join(', ');

      final parts = <String>[];

      if (bills.isNotEmpty) {
        parts.add('sales bills: $bills');
      }

      if (linkedLoads.isNotEmpty) {
        parts.add('${linkedLoads.length} load record(s)');
      }

      if (linkedStock.isNotEmpty) {
        parts.add('${linkedStock.length} DSR stock record(s)');
      }

      throw Exception(
        'Cannot delete product because it has linked ${parts.join(', ')}.',
      );
    }

    await client.from('products').delete().eq('id', id);
  }



  Future<void> resetCompanyData(String companyId) async {
    if (companyId.trim().isEmpty) {
      throw Exception('Company ID is required');
    }

    final cleanCompanyId = companyId.trim();

    // Delete child/transaction tables first, then master tables.
    // This keeps the user account and company profile safe, but removes app data.
    final tables = [
      'cash_counts',
      'claims',
      'deposits',
      'expenses',
      'recoveries',
      'sales',
      'load_entries',
      'stock_movements',
      'dsr_stocks',
      'company_purchases',
      'shopkeepers',
      'products',
      'dsrs',
      'suppliers',
    ];

    for (final table in tables) {
      await client.from(table).delete().eq('company_id', cleanCompanyId);
    }
  }

}