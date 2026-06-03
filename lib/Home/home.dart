import 'package:flutter/material.dart';


class SmartAccountManagerApp extends StatelessWidget {
  const SmartAccountManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Account Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Arial',
        scaffoldBackgroundColor: const Color(0xfff3f6fb),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff2563eb),
        ),
      ),
      home: const SmartAccountHome(),
    );
  }
}

class Product {
  String name;
  String sku;
  String category;
  double purchasePrice;
  double sellingPrice;
  int openingStock;
  int currentStock;
  int lowStockLimit;
  int soldStock;

  Product({
    required this.name,
    required this.sku,
    required this.category,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.openingStock,
    required this.currentStock,
    required this.lowStockLimit,
    this.soldStock = 0,
  });
}

class Customer {
  String name;
  double pendingCredit;

  Customer({
    required this.name,
    this.pendingCredit = 0,
  });
}

class Supplier {
  String name;

  Supplier({required this.name});
}

class PurchaseRecord {
  String invoice;
  String supplier;
  String product;
  int qty;
  double purchasePrice;
  double discount;
  double tax;
  double paidAmount;
  String date;

  PurchaseRecord({
    required this.invoice,
    required this.supplier,
    required this.product,
    required this.qty,
    required this.purchasePrice,
    required this.discount,
    required this.tax,
    required this.paidAmount,
    required this.date,
  });

  double get total {
    return (qty * purchasePrice) - discount + tax;
  }
}

class SaleRecord {
  String invoice;
  String customer;
  String product;
  int qty;
  double sellingPrice;
  bool isCredit;
  String date;

  SaleRecord({
    required this.invoice,
    required this.customer,
    required this.product,
    required this.qty,
    required this.sellingPrice,
    required this.isCredit,
    required this.date,
  });

  double get total {
    return qty * sellingPrice;
  }
}

class RecoveryRecord {
  String customer;
  double receivedAmount;
  String date;

  RecoveryRecord({
    required this.customer,
    required this.receivedAmount,
    required this.date,
  });
}

class CashTransaction {
  String title;
  double amount;
  String type;
  String date;

  CashTransaction({
    required this.title,
    required this.amount,
    required this.type,
    required this.date,
  });
}

class StockMovement {
  String product;
  int qty;
  String type;
  String note;
  String date;

  StockMovement({
    required this.product,
    required this.qty,
    required this.type,
    required this.note,
    required this.date,
  });
}

class ActivityItem {
  String title;
  String subtitle;
  IconData icon;
  Color color;

  ActivityItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

class SmartAccountHome extends StatefulWidget {
  const SmartAccountHome({super.key});

  @override
  State<SmartAccountHome> createState() => _SmartAccountHomeState();
}

class _SmartAccountHomeState extends State<SmartAccountHome> {
  int selectedIndex = 0;
  int invoiceNumber = 1001;

  final double openingCash = 50000;

  final List<String> menuItems = [
    'Dashboard',
    'Purchase',
    'Sales',
    'Recovery',
    'Cash Balance',
    'Credit',
    'Stock Summary',
    'Stock Management',
    'Reports',
  ];

  final List<Product> products = [
    Product(
      name: 'Rice Bag',
      sku: 'RB-001',
      category: 'Grocery',
      purchasePrice: 2800,
      sellingPrice: 3200,
      openingStock: 40,
      currentStock: 25,
      lowStockLimit: 10,
      soldStock: 15,
    ),
    Product(
      name: 'Cooking Oil',
      sku: 'CO-002',
      category: 'Grocery',
      purchasePrice: 520,
      sellingPrice: 650,
      openingStock: 50,
      currentStock: 9,
      lowStockLimit: 12,
      soldStock: 41,
    ),
    Product(
      name: 'Sugar Pack',
      sku: 'SP-003',
      category: 'Grocery',
      purchasePrice: 180,
      sellingPrice: 230,
      openingStock: 100,
      currentStock: 80,
      lowStockLimit: 15,
      soldStock: 20,
    ),
  ];

  final List<Customer> customers = [
    Customer(name: 'Ali Traders', pendingCredit: 3500),
    Customer(name: 'Hassan Store', pendingCredit: 2000),
    Customer(name: 'Cash Customer', pendingCredit: 0),
  ];

  final List<Supplier> suppliers = [
    Supplier(name: 'Metro Supplier'),
    Supplier(name: 'City Wholesale'),
    Supplier(name: 'Quick Supply Co'),
  ];

  final List<PurchaseRecord> purchases = [];
  final List<SaleRecord> sales = [];
  final List<RecoveryRecord> recoveries = [];
  final List<CashTransaction> cashTransactions = [];
  final List<StockMovement> stockMovements = [];
  final List<ActivityItem> activities = [];

  String get today {
    final now = DateTime.now();
    return '${now.day}-${now.month}-${now.year}';
  }

  double get totalSales {
    return sales.fold(0, (sum, item) => sum + item.total);
  }

  double get totalPurchases {
    return purchases.fold(0, (sum, item) => sum + item.total);
  }

  double get totalRecovery {
    return recoveries.fold(0, (sum, item) => sum + item.receivedAmount);
  }

  double get totalCredit {
    return customers.fold(0, (sum, item) => sum + item.pendingCredit);
  }

  double get cashIn {
    return cashTransactions
        .where((item) => item.type == 'in')
        .fold(0, (sum, item) => sum + item.amount);
  }

  double get cashOut {
    return cashTransactions
        .where((item) => item.type == 'out')
        .fold(0, (sum, item) => sum + item.amount);
  }

  double get cashBalance {
    return openingCash + cashIn - cashOut;
  }

  double get stockValue {
    return products.fold(
      0,
      (sum, item) => sum + (item.currentStock * item.purchasePrice),
    );
  }

  double get profitEstimate {
    return products.fold(
      0,
      (sum, item) {
        return sum + ((item.sellingPrice - item.purchasePrice) * item.soldStock);
      },
    );
  }

  int get lowStockCount {
    return products.where((item) => item.currentStock <= item.lowStockLimit).length;
  }

  int get availableStock {
    return products.fold(0, (sum, item) => sum + item.currentStock);
  }

  int get soldStock {
    return products.fold(0, (sum, item) => sum + item.soldStock);
  }

  int get purchasedStock {
    return products.fold(0, (sum, item) => sum + item.openingStock);
  }

  double get stockHealthPercent {
    if (products.isEmpty) return 0;

    final healthyItems = products
        .where((item) => item.currentStock > item.lowStockLimit)
        .length;

    return healthyItems / products.length;
  }

  String generateInvoice(String prefix) {
    return '$prefix-${invoiceNumber++}';
  }

  double toDouble(String value) {
    return double.tryParse(value.trim()) ?? 0;
  }

  int toInt(String value) {
    return int.tryParse(value.trim()) ?? 0;
  }

  String rs(double value) {
    return 'Rs ${value.toStringAsFixed(0)}';
  }

  String autoSku() {
    return 'PRD-${products.length + 1}'.padLeft(7, '0');
  }

  void showSnack(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void addActivity({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    activities.insert(
      0,
      ActivityItem(
        title: title,
        subtitle: subtitle,
        icon: icon,
        color: color,
      ),
    );

    if (activities.length > 10) {
      activities.removeLast();
    }
  }

  void showAddProductDialog() {
    final nameController = TextEditingController();
    final skuController = TextEditingController(text: autoSku());
    final categoryController = TextEditingController(text: 'General');
    final purchaseController = TextEditingController();
    final sellingController = TextEditingController();
    final openingStockController = TextEditingController(text: '0');
    final lowStockController = TextEditingController(text: '5');

    String errorText = '';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, dialogSetState) {
            return AlertDialog(
              title: const Text(
                'Add New Product',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      if (errorText.isNotEmpty)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xffffe4e6),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xfffecdd3)),
                          ),
                          child: Text(
                            errorText,
                            style: const TextStyle(
                              color: Color(0xff9f1239),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      inputField('Product Name *', nameController),
                      inputField('SKU / Code', skuController),
                      inputField('Category', categoryController),
                      inputField('Purchase Price *', purchaseController, number: true),
                      inputField('Selling Price *', sellingController, number: true),
                      inputField('Opening Stock', openingStockController, number: true),
                      inputField('Low Stock Limit', lowStockController, number: true),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final sku = skuController.text.trim().isEmpty
                        ? autoSku()
                        : skuController.text.trim();
                    final category = categoryController.text.trim().isEmpty
                        ? 'General'
                        : categoryController.text.trim();

                    final purchasePrice = toDouble(purchaseController.text);
                    final sellingPrice = toDouble(sellingController.text);
                    final openingStock = toInt(openingStockController.text);
                    final lowStockLimit = toInt(lowStockController.text);

                    if (name.isEmpty) {
                      dialogSetState(() {
                        errorText = 'Product name is required.';
                      });
                      return;
                    }

                    if (purchasePrice <= 0) {
                      dialogSetState(() {
                        errorText = 'Purchase price must be greater than 0.';
                      });
                      return;
                    }

                    if (sellingPrice <= 0) {
                      dialogSetState(() {
                        errorText = 'Selling price must be greater than 0.';
                      });
                      return;
                    }

                    if (sellingPrice < purchasePrice) {
                      dialogSetState(() {
                        errorText = 'Selling price should not be less than purchase price.';
                      });
                      return;
                    }

                    final alreadyExists = products.any(
                      (item) =>
                          item.name.toLowerCase() == name.toLowerCase() ||
                          item.sku.toLowerCase() == sku.toLowerCase(),
                    );

                    if (alreadyExists) {
                      dialogSetState(() {
                        errorText = 'Product name or SKU already exists.';
                      });
                      return;
                    }

                    setState(() {
                      products.add(
                        Product(
                          name: name,
                          sku: sku,
                          category: category,
                          purchasePrice: purchasePrice,
                          sellingPrice: sellingPrice,
                          openingStock: openingStock,
                          currentStock: openingStock,
                          lowStockLimit: lowStockLimit,
                          soldStock: 0,
                        ),
                      );

                      stockMovements.insert(
                        0,
                        StockMovement(
                          product: name,
                          qty: openingStock,
                          type: 'Opening Stock',
                          note: 'Product created',
                          date: today,
                        ),
                      );

                      addActivity(
                        title: 'New Product Added',
                        subtitle: '$name added with $openingStock opening stock',
                        icon: Icons.add_box_rounded,
                        color: Colors.blue,
                      );
                    });

                    Navigator.pop(dialogContext);
                    showSnack('Product saved successfully.');
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Save Product'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void showPurchaseDialog() {
    if (products.isEmpty || suppliers.isEmpty) {
      showSnack('Please add product and supplier first.');
      return;
    }

    String selectedSupplier = suppliers.first.name;
    String selectedProduct = products.first.name;

    final qtyController = TextEditingController();
    final priceController = TextEditingController(
      text: products.first.purchasePrice.toStringAsFixed(0),
    );
    final discountController = TextEditingController(text: '0');
    final taxController = TextEditingController(text: '0');
    final paidController = TextEditingController();

    String errorText = '';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, dialogSetState) {
            final qty = toInt(qtyController.text);
            final price = toDouble(priceController.text);
            final discount = toDouble(discountController.text);
            final tax = toDouble(taxController.text);
            final total = (qty * price) - discount + tax;

            return AlertDialog(
              title: const Text(
                'Add Purchase',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      if (errorText.isNotEmpty) errorBox(errorText),
                      DropdownButtonFormField<String>(
                        value: selectedSupplier,
                        decoration: formDecoration('Supplier'),
                        items: suppliers.map((supplier) {
                          return DropdownMenuItem(
                            value: supplier.name,
                            child: Text(supplier.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          dialogSetState(() {
                            selectedSupplier = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedProduct,
                        decoration: formDecoration('Product'),
                        items: products.map((product) {
                          return DropdownMenuItem(
                            value: product.name,
                            child: Text(product.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value == null) return;

                          final product = products.firstWhere(
                            (item) => item.name == value,
                          );

                          dialogSetState(() {
                            selectedProduct = value;
                            priceController.text =
                                product.purchasePrice.toStringAsFixed(0);
                          });
                        },
                      ),
                      inputField(
                        'Quantity *',
                        qtyController,
                        number: true,
                        onChanged: (_) => dialogSetState(() {}),
                      ),
                      inputField(
                        'Purchase Price *',
                        priceController,
                        number: true,
                        onChanged: (_) => dialogSetState(() {}),
                      ),
                      inputField(
                        'Discount',
                        discountController,
                        number: true,
                        onChanged: (_) => dialogSetState(() {}),
                      ),
                      inputField(
                        'Tax',
                        taxController,
                        number: true,
                        onChanged: (_) => dialogSetState(() {}),
                      ),
                      inputField('Paid Amount', paidController, number: true),
                      const SizedBox(height: 12),
                      totalBox('Purchase Total', total),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    final qty = toInt(qtyController.text);
                    final price = toDouble(priceController.text);
                    final discount = toDouble(discountController.text);
                    final tax = toDouble(taxController.text);
                    final paid = toDouble(paidController.text);
                    final total = (qty * price) - discount + tax;

                    if (qty <= 0) {
                      dialogSetState(() {
                        errorText = 'Quantity must be greater than 0.';
                      });
                      return;
                    }

                    if (price <= 0) {
                      dialogSetState(() {
                        errorText = 'Purchase price must be greater than 0.';
                      });
                      return;
                    }

                    if (total < 0) {
                      dialogSetState(() {
                        errorText = 'Total cannot be negative.';
                      });
                      return;
                    }

                    if (paid > cashBalance) {
                      dialogSetState(() {
                        errorText = 'Not enough cash balance for this payment.';
                      });
                      return;
                    }

                    final product = products.firstWhere(
                      (item) => item.name == selectedProduct,
                    );

                    setState(() {
                      product.currentStock += qty;
                      product.purchasePrice = price;

                      final invoice = generateInvoice('PUR');

                      purchases.insert(
                        0,
                        PurchaseRecord(
                          invoice: invoice,
                          supplier: selectedSupplier,
                          product: selectedProduct,
                          qty: qty,
                          purchasePrice: price,
                          discount: discount,
                          tax: tax,
                          paidAmount: paid,
                          date: today,
                        ),
                      );

                      if (paid > 0) {
                        cashTransactions.insert(
                          0,
                          CashTransaction(
                            title: 'Purchase payment - $invoice',
                            amount: paid,
                            type: 'out',
                            date: today,
                          ),
                        );
                      }

                      stockMovements.insert(
                        0,
                        StockMovement(
                          product: selectedProduct,
                          qty: qty,
                          type: 'Stock In',
                          note: 'Purchase invoice saved',
                          date: today,
                        ),
                      );

                      addActivity(
                        title: 'Purchase Saved',
                        subtitle: '$selectedProduct stock increased by $qty',
                        icon: Icons.shopping_cart_checkout_rounded,
                        color: Colors.orange,
                      );
                    });

                    Navigator.pop(dialogContext);
                    showSnack('Purchase saved. Stock increased.');
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Save Purchase'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void showSaleDialog() {
    if (products.isEmpty || customers.isEmpty) {
      showSnack('Please add product and customer first.');
      return;
    }

    String selectedCustomer = customers.first.name;
    String selectedProduct = products.first.name;
    bool isCreditSale = false;

    final qtyController = TextEditingController();
    final priceController = TextEditingController(
      text: products.first.sellingPrice.toStringAsFixed(0),
    );

    String errorText = '';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, dialogSetState) {
            final product = products.firstWhere(
              (item) => item.name == selectedProduct,
            );

            final qty = toInt(qtyController.text);
            final price = toDouble(priceController.text);
            final total = qty * price;

            return AlertDialog(
              title: const Text(
                'Add Sale',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      if (errorText.isNotEmpty) errorBox(errorText),
                      DropdownButtonFormField<String>(
                        value: selectedCustomer,
                        decoration: formDecoration('Customer'),
                        items: customers.map((customer) {
                          return DropdownMenuItem(
                            value: customer.name,
                            child: Text(customer.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value == null) return;

                          dialogSetState(() {
                            selectedCustomer = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedProduct,
                        decoration: formDecoration('Product'),
                        items: products.map((product) {
                          return DropdownMenuItem(
                            value: product.name,
                            child: Text(
                              '${product.name} - Stock: ${product.currentStock}',
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value == null) return;

                          final selected = products.firstWhere(
                            (item) => item.name == value,
                          );

                          dialogSetState(() {
                            selectedProduct = value;
                            priceController.text =
                                selected.sellingPrice.toStringAsFixed(0);
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      infoBox(
                        'Available Stock',
                        '${product.currentStock} units available',
                        product.currentStock <= product.lowStockLimit
                            ? Colors.red
                            : Colors.green,
                      ),
                      inputField(
                        'Quantity *',
                        qtyController,
                        number: true,
                        onChanged: (_) => dialogSetState(() {}),
                      ),
                      inputField(
                        'Selling Price *',
                        priceController,
                        number: true,
                        onChanged: (_) => dialogSetState(() {}),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Credit Sale',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(
                          isCreditSale
                              ? 'Customer pending balance will increase'
                              : 'Cash balance will increase',
                        ),
                        value: isCreditSale,
                        onChanged: (value) {
                          dialogSetState(() {
                            isCreditSale = value;
                          });
                        },
                      ),
                      totalBox('Sale Total', total),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    final qty = toInt(qtyController.text);
                    final price = toDouble(priceController.text);

                    if (qty <= 0) {
                      dialogSetState(() {
                        errorText = 'Quantity must be greater than 0.';
                      });
                      return;
                    }

                    if (price <= 0) {
                      dialogSetState(() {
                        errorText = 'Selling price must be greater than 0.';
                      });
                      return;
                    }

                    final product = products.firstWhere(
                      (item) => item.name == selectedProduct,
                    );

                    if (product.currentStock < qty) {
                      dialogSetState(() {
                        errorText = 'Not enough stock. Sale is not allowed.';
                      });
                      return;
                    }

                    final total = qty * price;

                    final customer = customers.firstWhere(
                      (item) => item.name == selectedCustomer,
                    );

                    setState(() {
                      product.currentStock -= qty;
                      product.soldStock += qty;
                      product.sellingPrice = price;

                      final invoice = generateInvoice('SAL');

                      sales.insert(
                        0,
                        SaleRecord(
                          invoice: invoice,
                          customer: selectedCustomer,
                          product: selectedProduct,
                          qty: qty,
                          sellingPrice: price,
                          isCredit: isCreditSale,
                          date: today,
                        ),
                      );

                      if (isCreditSale) {
                        customer.pendingCredit += total;
                      } else {
                        cashTransactions.insert(
                          0,
                          CashTransaction(
                            title: 'Cash sale - $invoice',
                            amount: total,
                            type: 'in',
                            date: today,
                          ),
                        );
                      }

                      stockMovements.insert(
                        0,
                        StockMovement(
                          product: selectedProduct,
                          qty: qty,
                          type: 'Stock Out',
                          note: isCreditSale ? 'Credit sale' : 'Cash sale',
                          date: today,
                        ),
                      );

                      addActivity(
                        title: isCreditSale ? 'Credit Sale Saved' : 'Cash Sale Saved',
                        subtitle: '$selectedProduct sold quantity $qty',
                        icon: Icons.point_of_sale_rounded,
                        color: isCreditSale ? Colors.red : Colors.green,
                      );
                    });

                    Navigator.pop(dialogContext);
                    showSnack('Sale saved. Stock decreased.');
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Save Sale'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void showRecoveryDialog() {
    if (customers.isEmpty) {
      showSnack('Please add customer first.');
      return;
    }

    String selectedCustomer = customers.first.name;
    final amountController = TextEditingController();

    String errorText = '';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, dialogSetState) {
            final customer = customers.firstWhere(
              (item) => item.name == selectedCustomer,
            );

            return AlertDialog(
              title: const Text(
                'Add Recovery',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              content: SizedBox(
                width: 460,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      if (errorText.isNotEmpty) errorBox(errorText),
                      DropdownButtonFormField<String>(
                        value: selectedCustomer,
                        decoration: formDecoration('Customer'),
                        items: customers.map((customer) {
                          return DropdownMenuItem(
                            value: customer.name,
                            child: Text(customer.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value == null) return;

                          dialogSetState(() {
                            selectedCustomer = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      infoBox(
                        'Pending Credit',
                        rs(customer.pendingCredit),
                        customer.pendingCredit > 0 ? Colors.red : Colors.green,
                      ),
                      inputField(
                        'Received Amount *',
                        amountController,
                        number: true,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    final amount = toDouble(amountController.text);

                    final customer = customers.firstWhere(
                      (item) => item.name == selectedCustomer,
                    );

                    if (amount <= 0) {
                      dialogSetState(() {
                        errorText = 'Received amount must be greater than 0.';
                      });
                      return;
                    }

                    if (customer.pendingCredit <= 0) {
                      dialogSetState(() {
                        errorText = 'This customer has no pending credit.';
                      });
                      return;
                    }

                    if (amount > customer.pendingCredit) {
                      dialogSetState(() {
                        errorText = 'Received amount cannot be more than pending credit.';
                      });
                      return;
                    }

                    setState(() {
                      customer.pendingCredit -= amount;

                      recoveries.insert(
                        0,
                        RecoveryRecord(
                          customer: selectedCustomer,
                          receivedAmount: amount,
                          date: today,
                        ),
                      );

                      cashTransactions.insert(
                        0,
                        CashTransaction(
                          title: 'Recovery from $selectedCustomer',
                          amount: amount,
                          type: 'in',
                          date: today,
                        ),
                      );

                      addActivity(
                        title: 'Recovery Received',
                        subtitle: '${rs(amount)} received from $selectedCustomer',
                        icon: Icons.payments_rounded,
                        color: Colors.purple,
                      );
                    });

                    Navigator.pop(dialogContext);
                    showSnack('Recovery saved. Credit decreased and cash increased.');
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Save Recovery'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void deleteProduct(int index) {
    final productName = products[index].name;

    setState(() {
      products.removeAt(index);

      addActivity(
        title: 'Product Deleted',
        subtitle: '$productName was removed from stock',
        icon: Icons.delete_rounded,
        color: Colors.red,
      );
    });

    showSnack('Product deleted.');
  }

  void stockAdjustment(Product product, int qty) {
    setState(() {
      product.currentStock += qty;

      stockMovements.insert(
        0,
        StockMovement(
          product: product.name,
          qty: qty,
          type: 'Adjustment',
          note: 'Manual stock adjustment',
          date: today,
        ),
      );

      addActivity(
        title: 'Stock Adjusted',
        subtitle: '${product.name} stock changed by $qty',
        icon: Icons.tune_rounded,
        color: Colors.indigo,
      );
    });

    showSnack('Stock adjusted.');
  }

  @override
  void initState() {
    super.initState();

    cashTransactions.add(
      CashTransaction(
        title: 'Opening cash balance',
        amount: openingCash,
        type: 'in',
        date: today,
      ),
    );

    activities.addAll([
      ActivityItem(
        title: 'System Ready',
        subtitle: 'Smart Account Manager demo started',
        icon: Icons.check_circle_rounded,
        color: Colors.green,
      ),
      ActivityItem(
        title: 'Low Stock Found',
        subtitle: 'Cooking Oil is below stock limit',
        icon: Icons.warning_rounded,
        color: Colors.orange,
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 950;

    return Scaffold(
      drawer: isDesktop ? null : Drawer(child: sidebar()),
      appBar: isDesktop
          ? null
          : AppBar(
              title: const Text('Smart Account Manager'),
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
            ),
      body: Row(
        children: [
          if (isDesktop)
            SizedBox(
              width: 270,
              child: sidebar(),
            ),
          Expanded(
            child: Column(
              children: [
                topBar(),
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

  Widget sidebar() {
    return Container(
      color: const Color(0xff111827),
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 52,
                    width: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xff2563eb),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Smart Account',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Text(
                    'Manager',
                    style: TextStyle(
                      color: Color(0xff9ca3af),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: menuItems.length,
                itemBuilder: (context, index) {
                  final active = selectedIndex == index;

                  return Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    child: ListTile(
                      selected: active,
                      selectedTileColor: const Color(0xff2563eb),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      leading: Icon(
                        menuIcon(index),
                        color: active ? Colors.white : const Color(0xffd1d5db),
                      ),
                      title: Text(
                        menuItems[index],
                        style: TextStyle(
                          color: active ? Colors.white : const Color(0xffd1d5db),
                          fontWeight: active ? FontWeight.w900 : FontWeight.w500,
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          selectedIndex = index;
                        });

                        if (MediaQuery.of(context).size.width < 950) {
                          Navigator.pop(context);
                        }
                      },
                    ),
                  );
                },
              ),
            ),
            Container(
              margin: const EdgeInsets.all(14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xff1f2937),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Color(0xff2563eb),
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Admin User\nFull Access',
                      style: TextStyle(color: Colors.white, fontSize: 13),
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

  IconData menuIcon(int index) {
    switch (index) {
      case 0:
        return Icons.dashboard_rounded;
      case 1:
        return Icons.shopping_cart_checkout_rounded;
      case 2:
        return Icons.point_of_sale_rounded;
      case 3:
        return Icons.payments_rounded;
      case 4:
        return Icons.account_balance_wallet_rounded;
      case 5:
        return Icons.credit_score_rounded;
      case 6:
        return Icons.inventory_2_rounded;
      case 7:
        return Icons.warehouse_rounded;
      default:
        return Icons.bar_chart_rounded;
    }
  }

  Widget topBar() {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xffe5e7eb)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              menuItems[selectedIndex],
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Color(0xff111827),
              ),
            ),
          ),
          Wrap(
            spacing: 10,
            children: [
              topButton(
                'Purchase',
                Icons.add_shopping_cart_rounded,
                showPurchaseDialog,
              ),
              topButton(
                'Sale',
                Icons.point_of_sale_rounded,
                showSaleDialog,
              ),
              topButton(
                'Product',
                Icons.add_box_rounded,
                showAddProductDialog,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget topButton(String text, IconData icon, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 17),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xff2563eb),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  Widget selectedPage() {
    switch (selectedIndex) {
      case 0:
        return dashboardPage();
      case 1:
        return purchasePage();
      case 2:
        return salesPage();
      case 3:
        return recoveryPage();
      case 4:
        return cashBalancePage();
      case 5:
        return creditPage();
      case 6:
        return stockSummaryPage();
      case 7:
        return stockManagementPage();
      default:
        return reportsPage();
    }
  }

  Widget dashboardPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        dashboardHero(),
        const SizedBox(height: 18),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            statCard('Total Sales', totalSales, Icons.trending_up_rounded, Colors.green),
            statCard('Total Purchases', totalPurchases, Icons.shopping_cart_rounded, Colors.orange),
            statCard('Recovery', totalRecovery, Icons.payments_rounded, Colors.purple),
            statCard('Cash Balance', cashBalance, Icons.wallet_rounded, Colors.blue),
            statCard('Total Credit', totalCredit, Icons.credit_card_rounded, Colors.red),
            statCard('Stock Value', stockValue, Icons.inventory_2_rounded, Colors.teal),
          ],
        ),
        const SizedBox(height: 18),
        responsiveTwoColumns(
          infographicCashFlow(),
          infographicStockHealth(),
        ),
        const SizedBox(height: 18),
        lowStockAlert(),
        const SizedBox(height: 18),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            quickActionCard(
              'Add Purchase',
              'Increase stock and record payment',
              Icons.add_shopping_cart_rounded,
              Colors.orange,
              showPurchaseDialog,
            ),
            quickActionCard(
              'Add Sale',
              'Cash sale or credit sale',
              Icons.point_of_sale_rounded,
              Colors.green,
              showSaleDialog,
            ),
            quickActionCard(
              'Add Recovery',
              'Receive customer pending amount',
              Icons.payments_rounded,
              Colors.purple,
              showRecoveryDialog,
            ),
            quickActionCard(
              'Add Product',
              'Create new inventory item',
              Icons.add_box_rounded,
              Colors.blue,
              showAddProductDialog,
            ),
          ],
        ),
        const SizedBox(height: 18),
        responsiveTwoColumns(
          recentActivities(),
          recentSalesAndPurchases(),
        ),
      ],
    );
  }

  Widget dashboardHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xff1d4ed8),
            Color(0xff2563eb),
            Color(0xff38bdf8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.18),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        runSpacing: 20,
        children: [
          SizedBox(
            width: 520,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Business Overview',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Smart Account Manager',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Track sales, purchases, stock, credit, recovery, and cash balance from one clean dashboard.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    whiteHeroButton('Add Sale', Icons.point_of_sale_rounded, showSaleDialog),
                    whiteHeroButton('Add Product', Icons.add_box_rounded, showAddProductDialog),
                  ],
                )
              ],
            ),
          ),
          Container(
            width: 280,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withOpacity(0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                miniHeroRow('Products', products.length.toString(), Icons.inventory_2_rounded),
                miniHeroRow('Available Stock', availableStock.toString(), Icons.warehouse_rounded),
                miniHeroRow('Low Stock', lowStockCount.toString(), Icons.warning_rounded),
                miniHeroRow('Customers Credit', rs(totalCredit), Icons.credit_score_rounded),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget whiteHeroButton(String text, IconData icon, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xff1d4ed8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  Widget miniHeroRow(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.22),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget purchasePage() {
    return Column(
      children: [
        moduleHeader(
          title: 'Purchase Module',
          subtitle: 'Add real purchases. Stock increases and cash decreases by paid amount.',
          buttonText: 'Add Purchase',
          icon: Icons.add_shopping_cart_rounded,
          onTap: showPurchaseDialog,
        ),
        const SizedBox(height: 18),
        dataCard(
          title: 'Purchase History',
          child: horizontalTable(
            DataTable(
              columns: const [
                DataColumn(label: Text('Invoice')),
                DataColumn(label: Text('Date')),
                DataColumn(label: Text('Supplier')),
                DataColumn(label: Text('Product')),
                DataColumn(label: Text('Qty')),
                DataColumn(label: Text('Price')),
                DataColumn(label: Text('Discount')),
                DataColumn(label: Text('Tax')),
                DataColumn(label: Text('Total')),
                DataColumn(label: Text('Paid')),
              ],
              rows: purchases.map((item) {
                return DataRow(
                  cells: [
                    DataCell(Text(item.invoice)),
                    DataCell(Text(item.date)),
                    DataCell(Text(item.supplier)),
                    DataCell(Text(item.product)),
                    DataCell(Text(item.qty.toString())),
                    DataCell(Text(rs(item.purchasePrice))),
                    DataCell(Text(rs(item.discount))),
                    DataCell(Text(rs(item.tax))),
                    DataCell(Text(rs(item.total))),
                    DataCell(Text(rs(item.paidAmount))),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget salesPage() {
    return Column(
      children: [
        moduleHeader(
          title: 'Sales Module',
          subtitle: 'Add cash sales or credit sales. Stock decreases automatically.',
          buttonText: 'Add Sale',
          icon: Icons.point_of_sale_rounded,
          onTap: showSaleDialog,
        ),
        const SizedBox(height: 18),
        dataCard(
          title: 'Sales History',
          child: horizontalTable(
            DataTable(
              columns: const [
                DataColumn(label: Text('Invoice')),
                DataColumn(label: Text('Date')),
                DataColumn(label: Text('Customer')),
                DataColumn(label: Text('Product')),
                DataColumn(label: Text('Qty')),
                DataColumn(label: Text('Price')),
                DataColumn(label: Text('Type')),
                DataColumn(label: Text('Total')),
              ],
              rows: sales.map((item) {
                return DataRow(
                  cells: [
                    DataCell(Text(item.invoice)),
                    DataCell(Text(item.date)),
                    DataCell(Text(item.customer)),
                    DataCell(Text(item.product)),
                    DataCell(Text(item.qty.toString())),
                    DataCell(Text(rs(item.sellingPrice))),
                    DataCell(Text(item.isCredit ? 'Credit' : 'Cash')),
                    DataCell(Text(rs(item.total))),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget recoveryPage() {
    return Column(
      children: [
        moduleHeader(
          title: 'Recovery Module',
          subtitle: 'Receive customer payments. Pending credit decreases and cash increases.',
          buttonText: 'Add Recovery',
          icon: Icons.payments_rounded,
          onTap: showRecoveryDialog,
        ),
        const SizedBox(height: 18),
        dataCard(
          title: 'Recovery History',
          child: horizontalTable(
            DataTable(
              columns: const [
                DataColumn(label: Text('Date')),
                DataColumn(label: Text('Customer')),
                DataColumn(label: Text('Received Amount')),
              ],
              rows: recoveries.map((item) {
                return DataRow(
                  cells: [
                    DataCell(Text(item.date)),
                    DataCell(Text(item.customer)),
                    DataCell(Text(rs(item.receivedAmount))),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget cashBalancePage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            statCard('Opening Cash', openingCash, Icons.flag_rounded, Colors.indigo),
            statCard('Cash In', cashIn, Icons.call_received_rounded, Colors.green),
            statCard('Cash Out', cashOut, Icons.call_made_rounded, Colors.red),
            statCard('Current Cash', cashBalance, Icons.wallet_rounded, Colors.blue),
          ],
        ),
        const SizedBox(height: 18),
        infographicCashFlow(),
        const SizedBox(height: 18),
        dataCard(
          title: 'Cash Transaction History',
          child: horizontalTable(
            DataTable(
              columns: const [
                DataColumn(label: Text('Date')),
                DataColumn(label: Text('Title')),
                DataColumn(label: Text('Type')),
                DataColumn(label: Text('Amount')),
              ],
              rows: cashTransactions.map((item) {
                return DataRow(
                  cells: [
                    DataCell(Text(item.date)),
                    DataCell(Text(item.title)),
                    DataCell(
                      Chip(
                        label: Text(item.type == 'in' ? 'Cash In' : 'Cash Out'),
                        backgroundColor: item.type == 'in'
                            ? const Color(0xffdcfce7)
                            : const Color(0xffffe4e6),
                      ),
                    ),
                    DataCell(Text(rs(item.amount))),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget creditPage() {
    return Column(
      children: [
        moduleHeader(
          title: 'Credit Module',
          subtitle: 'View customer pending credit and receive partial payments.',
          buttonText: 'Add Recovery',
          icon: Icons.payments_rounded,
          onTap: showRecoveryDialog,
        ),
        const SizedBox(height: 18),
        dataCard(
          title: 'Customer Credit Report',
          child: horizontalTable(
            DataTable(
              columns: const [
                DataColumn(label: Text('Customer')),
                DataColumn(label: Text('Pending Credit')),
                DataColumn(label: Text('Status')),
              ],
              rows: customers.map((item) {
                return DataRow(
                  cells: [
                    DataCell(Text(item.name)),
                    DataCell(Text(rs(item.pendingCredit))),
                    DataCell(
                      Chip(
                        label: Text(item.pendingCredit > 0 ? 'Unpaid' : 'Paid'),
                        backgroundColor: item.pendingCredit > 0
                            ? const Color(0xffffe4e6)
                            : const Color(0xffdcfce7),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget stockSummaryPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            smallStatCard('Total Products', products.length.toString(), Icons.category_rounded, Colors.blue),
            smallStatCard('Available Stock', availableStock.toString(), Icons.inventory_rounded, Colors.green),
            smallStatCard('Sold Stock', soldStock.toString(), Icons.sell_rounded, Colors.orange),
            smallStatCard('Opening Stock', purchasedStock.toString(), Icons.shopping_bag_rounded, Colors.purple),
            statCard('Stock Value', stockValue, Icons.price_check_rounded, Colors.teal),
            statCard('Profit Estimate', profitEstimate, Icons.trending_up_rounded, Colors.green),
          ],
        ),
        const SizedBox(height: 18),
        infographicStockHealth(),
        const SizedBox(height: 18),
        productTable(),
      ],
    );
  }

  Widget stockManagementPage() {
    return Column(
      children: [
        moduleHeader(
          title: 'Stock Management',
          subtitle: 'Add products, delete products, adjust stock, and view movement history.',
          buttonText: 'Add Product',
          icon: Icons.add_box_rounded,
          onTap: showAddProductDialog,
        ),
        const SizedBox(height: 18),
        productTable(),
        const SizedBox(height: 18),
        dataCard(
          title: 'Stock Movement History',
          child: horizontalTable(
            DataTable(
              columns: const [
                DataColumn(label: Text('Date')),
                DataColumn(label: Text('Product')),
                DataColumn(label: Text('Qty')),
                DataColumn(label: Text('Type')),
                DataColumn(label: Text('Note')),
              ],
              rows: stockMovements.map((item) {
                return DataRow(
                  cells: [
                    DataCell(Text(item.date)),
                    DataCell(Text(item.product)),
                    DataCell(Text(item.qty.toString())),
                    DataCell(Text(item.type)),
                    DataCell(Text(item.note)),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget reportsPage() {
    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: [
        reportCard('Daily Sales Report', Icons.point_of_sale_rounded),
        reportCard('Daily Purchase Report', Icons.shopping_cart_rounded),
        reportCard('Cash Balance Report', Icons.wallet_rounded),
        reportCard('Credit Report', Icons.credit_card_rounded),
        reportCard('Recovery Report', Icons.payments_rounded),
        reportCard('Stock Report', Icons.inventory_2_rounded),
        reportCard('Low Stock Report', Icons.warning_rounded),
        reportCard('Profit / Loss Summary', Icons.bar_chart_rounded),
      ],
    );
  }

  Widget infographicCashFlow() {
    final maxValue = cashIn + cashOut == 0 ? 1 : cashIn + cashOut;
    final cashInPercent = cashIn / maxValue;
    final cashOutPercent = cashOut / maxValue;

    return dataCard(
      title: 'Cash Flow Infographic',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          infographicLine(
            title: 'Cash In',
            value: rs(cashIn),
            percent: cashInPercent,
            color: Colors.green,
            icon: Icons.call_received_rounded,
          ),
          const SizedBox(height: 16),
          infographicLine(
            title: 'Cash Out',
            value: rs(cashOut),
            percent: cashOutPercent,
            color: Colors.red,
            icon: Icons.call_made_rounded,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xffeff6ff),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet_rounded, color: Color(0xff2563eb)),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Current Cash Balance',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                Text(
                  rs(cashBalance),
                  style: const TextStyle(
                    color: Color(0xff2563eb),
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget infographicStockHealth() {
    return dataCard(
      title: 'Stock Health Infographic',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          infographicLine(
            title: 'Healthy Stock',
            value: '${(stockHealthPercent * 100).toStringAsFixed(0)}%',
            percent: stockHealthPercent,
            color: Colors.green,
            icon: Icons.check_circle_rounded,
          ),
          const SizedBox(height: 16),
          infographicLine(
            title: 'Low Stock Items',
            value: lowStockCount.toString(),
            percent: products.isEmpty ? 0 : lowStockCount / products.length,
            color: Colors.orange,
            icon: Icons.warning_rounded,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              miniMetric('Products', products.length.toString(), Colors.blue),
              miniMetric('Available', availableStock.toString(), Colors.green),
              miniMetric('Sold', soldStock.toString(), Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget infographicLine({
    required String title,
    required String value,
    required double percent,
    required Color color,
    required IconData icon,
  }) {
    final safePercent = percent.clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: color.withOpacity(0.12),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: safePercent,
            minHeight: 9,
            backgroundColor: color.withOpacity(0.12),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget miniMetric(String title, String value, Color color) {
    return Container(
      width: 130,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xff6b7280),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget lowStockAlert() {
    final lowItems = products
        .where((item) => item.currentStock <= item.lowStockLimit)
        .map((item) => item.name)
        .join(', ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: lowStockCount > 0 ? const Color(0xfffffbeb) : const Color(0xffecfdf5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: lowStockCount > 0 ? const Color(0xfff59e0b) : const Color(0xff10b981),
        ),
      ),
      child: Row(
        children: [
          Icon(
            lowStockCount > 0 ? Icons.warning_rounded : Icons.check_circle_rounded,
            color: lowStockCount > 0 ? const Color(0xffd97706) : const Color(0xff059669),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              lowStockCount > 0
                  ? 'Low stock alert: $lowItems'
                  : 'All products have enough stock.',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: Color(0xff111827),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget quickActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 270,
        padding: const EdgeInsets.all(18),
        decoration: cardDecoration(),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: color.withOpacity(0.12),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xff6b7280),
                      fontSize: 12,
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

  Widget recentActivities() {
    return dataCard(
      title: 'Recent Activity',
      child: activities.isEmpty
          ? emptyBox('No activity yet.')
          : Column(
              children: activities.take(6).map((item) {
                return simpleRow(
                  item.title,
                  item.subtitle,
                  '',
                  item.color,
                  icon: item.icon,
                );
              }).toList(),
            ),
    );
  }

  Widget recentSalesAndPurchases() {
    return dataCard(
      title: 'Recent Sales & Purchases',
      child: Column(
        children: [
          if (sales.isEmpty && purchases.isEmpty) emptyBox('No sales or purchases yet.'),
          ...sales.take(3).map((item) {
            return simpleRow(
              item.invoice,
              '${item.customer} - ${item.product}',
              rs(item.total),
              item.isCredit ? Colors.red : Colors.green,
              icon: Icons.point_of_sale_rounded,
            );
          }),
          ...purchases.take(3).map((item) {
            return simpleRow(
              item.invoice,
              '${item.supplier} - ${item.product}',
              rs(item.total),
              Colors.orange,
              icon: Icons.shopping_cart_checkout_rounded,
            );
          }),
        ],
      ),
    );
  }

  Widget productTable() {
    return dataCard(
      title: 'Products',
      child: products.isEmpty
          ? emptyBox('No products found. Click Add Product to create one.')
          : horizontalTable(
              DataTable(
                columns: const [
                  DataColumn(label: Text('Product')),
                  DataColumn(label: Text('SKU')),
                  DataColumn(label: Text('Category')),
                  DataColumn(label: Text('Purchase')),
                  DataColumn(label: Text('Selling')),
                  DataColumn(label: Text('Opening')),
                  DataColumn(label: Text('Current')),
                  DataColumn(label: Text('Low Limit')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Adjust')),
                  DataColumn(label: Text('Delete')),
                ],
                rows: List.generate(products.length, (index) {
                  final item = products[index];
                  final low = item.currentStock <= item.lowStockLimit;

                  return DataRow(
                    cells: [
                      DataCell(Text(item.name)),
                      DataCell(Text(item.sku)),
                      DataCell(Text(item.category)),
                      DataCell(Text(rs(item.purchasePrice))),
                      DataCell(Text(rs(item.sellingPrice))),
                      DataCell(Text(item.openingStock.toString())),
                      DataCell(Text(item.currentStock.toString())),
                      DataCell(Text(item.lowStockLimit.toString())),
                      DataCell(
                        Chip(
                          label: Text(low ? 'Low Stock' : 'Available'),
                          backgroundColor: low
                              ? const Color(0xffffe4e6)
                              : const Color(0xffdcfce7),
                        ),
                      ),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Increase stock',
                              onPressed: () {
                                stockAdjustment(item, 1);
                              },
                              icon: const Icon(Icons.add_circle, color: Colors.green),
                            ),
                            IconButton(
                              tooltip: 'Decrease stock',
                              onPressed: item.currentStock > 0
                                  ? () {
                                      stockAdjustment(item, -1);
                                    }
                                  : null,
                              icon: const Icon(Icons.remove_circle, color: Colors.orange),
                            ),
                          ],
                        ),
                      ),
                      DataCell(
                        IconButton(
                          onPressed: () {
                            deleteProduct(index);
                          },
                          icon: const Icon(Icons.delete_rounded, color: Colors.red),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
    );
  }

  Widget moduleHeader({
    required String title,
    required String subtitle,
    required String buttonText,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return dataCard(
      title: title,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmall = constraints.maxWidth < 620;

          if (isSmall) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xff6b7280),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                mainActionButton(buttonText, icon, onTap),
              ],
            );
          }

          return Row(
            children: [
              Expanded(
                child: Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xff6b7280),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              mainActionButton(buttonText, icon, onTap),
            ],
          );
        },
      ),
    );
  }

  Widget statCard(String title, double value, IconData icon, Color color) {
    return SizedBox(
      width: 260,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: cardDecoration(),
        child: Row(
          children: [
            Container(
              height: 54,
              width: 54,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xff6b7280),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    rs(value),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xff111827),
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

  Widget smallStatCard(String title, String value, IconData icon, Color color) {
    return SizedBox(
      width: 260,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: cardDecoration(),
        child: Row(
          children: [
            Container(
              height: 54,
              width: 54,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xff6b7280),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xff111827),
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

  Widget reportCard(String title, IconData icon) {
    return SizedBox(
      width: 270,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xffeff6ff),
              child: Icon(icon, color: const Color(0xff2563eb)),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Date range filter, PDF export, and Excel export option.',
              style: TextStyle(
                color: Color(0xff6b7280),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget dataCard({
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.circle, size: 10, color: Color(0xff2563eb)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xff111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget mainActionButton(String text, IconData icon, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xff2563eb),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  Widget inputField(
    String label,
    TextEditingController controller, {
    bool number = false,
    Function(String)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: TextField(
        controller: controller,
        keyboardType: number
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        onChanged: onChanged,
        decoration: formDecoration(label),
      ),
    );
  }

  InputDecoration formDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xfff9fafb),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xffe5e7eb)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xff2563eb), width: 1.5),
      ),
    );
  }

  Widget errorBox(String text) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xffffe4e6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xfffecdd3)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xff9f1239),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget infoBox(String title, String value, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_rounded, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget totalBox(String title, double value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xffeff6ff),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xffbfdbfe)),
      ),
      child: Text(
        '$title: ${rs(value)}',
        style: const TextStyle(
          color: Color(0xff1d4ed8),
          fontWeight: FontWeight.w900,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget horizontalTable(Widget table) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: table,
    );
  }

  Widget emptyBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(color: Color(0xff6b7280)),
      ),
    );
  }

  Widget simpleRow(
    String title,
    String subtitle,
    String amount,
    Color color, {
    IconData icon = Icons.receipt_long_rounded,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xfff9fafb),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffe5e7eb)),
      ),
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
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xff6b7280),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (amount.isNotEmpty)
            Text(
              amount,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: Color(0xff111827),
              ),
            ),
        ],
      ),
    );
  }

  Widget responsiveTwoColumns(Widget left, Widget right) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 850) {
          return Column(
            children: [
              left,
              const SizedBox(height: 18),
              right,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: left),
            const SizedBox(width: 18),
            Expanded(child: right),
          ],
        );
      },
    );
  }

  BoxDecoration cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xffe5e7eb)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }
}