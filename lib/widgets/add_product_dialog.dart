import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/product.dart';

class AddProductDialog extends StatefulWidget {
  final Product? product;

  const AddProductDialog({super.key, this.product});

  @override
  State<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _vatController = TextEditingController();
  final _stockController = TextEditingController();
  final _categoryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _barcodeController.text = widget.product!.barcode ?? '';
      _costPriceController.text = widget.product!.costPrice.toString();
      _sellingPriceController.text = widget.product!.sellingPrice.toString();
      _vatController.text = widget.product!.vatPercent.toString();
      _stockController.text = widget.product!.stockQuantity.toString();
      _categoryController.text = widget.product!.category ?? '';
    } else {
      _vatController.text = '13'; // Default VAT for Nepal
    }
  }

  Future<void> _scanBarcode() async {
    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: const Text('Scan Barcode'),
            ),
            body: MobileScanner(
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                if (barcodes.isNotEmpty) {
                  final barcode = barcodes.first.rawValue;
                  if (barcode != null) {
                    Navigator.pop(context);
                    _barcodeController.text = barcode;
                  }
                }
              },
            ),
          ),
        ),
      );
    } catch (e) {
      _showMessage('Error scanning barcode');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.product == null ? 'Add Product' : 'Edit Product',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Form Fields
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Product Name *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Product name is required';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _barcodeController,
                              decoration: const InputDecoration(
                                labelText: 'Barcode',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: _scanBarcode,
                            icon: const Icon(Icons.qr_code_scanner),
                            style: IconButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _costPriceController,
                              decoration: const InputDecoration(
                                labelText: 'Cost Price *',
                                border: OutlineInputBorder(),
                                prefixText: 'Rs. ',
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Cost price is required';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Invalid price';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _sellingPriceController,
                              decoration: const InputDecoration(
                                labelText: 'Selling Price *',
                                border: OutlineInputBorder(),
                                prefixText: 'Rs. ',
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Selling price is required';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Invalid price';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _vatController,
                              decoration: const InputDecoration(
                                labelText: 'VAT %',
                                border: OutlineInputBorder(),
                                suffixText: '%',
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  final vat = double.tryParse(value);
                                  if (vat == null || vat < 0 || vat > 100) {
                                    return 'Invalid VAT percentage';
                                  }
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _stockController,
                              decoration: const InputDecoration(
                                labelText: 'Stock Quantity *',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Stock quantity is required';
                                }
                                if (int.tryParse(value) == null) {
                                  return 'Invalid quantity';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _categoryController,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveProduct,
                      child: Text(widget.product == null ? 'Add' : 'Update'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveProduct() {
    if (_formKey.currentState!.validate()) {
      final now = DateTime.now();
      final product = Product(
        id: widget.product?.id,
        name: _nameController.text.trim(),
        barcode: _barcodeController.text.trim().isEmpty 
            ? null 
            : _barcodeController.text.trim(),
        costPrice: double.parse(_costPriceController.text),
        sellingPrice: double.parse(_sellingPriceController.text),
        vatPercent: double.tryParse(_vatController.text) ?? 0,
        stockQuantity: int.parse(_stockController.text),
        category: _categoryController.text.trim().isEmpty 
            ? null 
            : _categoryController.text.trim(),
        createdAt: widget.product?.createdAt ?? now,
        updatedAt: now,
      );

      Navigator.pop(context, product);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _costPriceController.dispose();
    _sellingPriceController.dispose();
    _vatController.dispose();
    _stockController.dispose();
    _categoryController.dispose();
    super.dispose();
  }
}