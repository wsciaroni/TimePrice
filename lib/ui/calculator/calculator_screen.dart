import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:time_price/providers/app_state_provider.dart';
import 'package:time_price/ui/ar/ar_camera_scanner_screen.dart';
import 'package:time_price/ui/calculator/time_cost_display.dart';
import 'package:time_price/ui/settings/settings_screen.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final _priceController = TextEditingController();

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  void _openArScanner(BuildContext context) {
    final provider = Provider.of<AppStateProvider>(context, listen: false);
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const ArCameraScannerScreen(),
        ),
      ).then((_) {
        // Sync text field when returning from AR scanner if price was set
        if (provider.price > 0) {
          _priceController.text = provider.price.toStringAsFixed(2);
        }
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('TimePrice Calculator'),
            actions: [
              IconButton(
                key: const Key('ar_camera_button'),
                icon: const Icon(Icons.center_focus_strong),
                tooltip: 'AR Price Tag Scanner',
                onPressed: () => _openArScanner(context),
              ),
              IconButton(
                key: const Key('settings_button'),
                icon: const Icon(Icons.settings),
                onPressed: () {
                  unawaited(
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const SettingsScreen(),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  key: const Key('calculator_price_input'),
                  controller: _priceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Item Price (\$)',
                    hintText: 'Enter price e.g. 49.99',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  onChanged: (val) {
                    final p = double.tryParse(val.trim());
                    provider.updatePrice(p ?? 0.0);
                  },
                ),
                const SizedBox(height: 20),
                TimeCostDisplay(result: provider.result),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            key: const Key('ar_camera_fab'),
            icon: const Icon(Icons.camera_alt),
            label: const Text('AR Scanner'),
            onPressed: () => _openArScanner(context),
          ),
        );
      },
    );
  }
}

