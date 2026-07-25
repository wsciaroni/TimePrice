import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:time_price/models/deduction.dart';
import 'package:time_price/models/income_config.dart';
import 'package:time_price/models/pay_frequency.dart';
import 'package:time_price/models/tax_config.dart';
import 'package:time_price/providers/app_state_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _payController;
  late PayFrequency _frequency;
  late TextEditingController _taxController;

  final _dedNameController = TextEditingController();
  final _dedAmountController = TextEditingController();
  DeductionType _dedType = DeductionType.preTax;
  DeductionAmountType _dedAmountType = DeductionAmountType.flat;
  PayFrequency _dedFrequency = PayFrequency.hourly;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<AppStateProvider>(context, listen: false);
    _payController = TextEditingController(
      text: provider.incomeConfig.amount.toString(),
    );
    _frequency = provider.incomeConfig.frequency;
    _taxController = TextEditingController(
      text: provider.taxConfig.salesTaxRate.toString(),
    );
  }

  @override
  void dispose() {
    _payController.dispose();
    _taxController.dispose();
    _dedNameController.dispose();
    _dedAmountController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings(BuildContext context) async {
    final provider = Provider.of<AppStateProvider>(context, listen: false);
    final payVal = double.tryParse(_payController.text.trim()) ?? 0.0;
    final taxVal = double.tryParse(_taxController.text.trim()) ?? 0.0;

    await provider.updateIncomeConfig(
      IncomeConfig(amount: payVal < 0 ? 0.0 : payVal, frequency: _frequency),
    );
    await provider.updateTaxConfig(
      TaxConfig(salesTaxRate: taxVal < 0 ? 0.0 : taxVal),
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved successfully.')),
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _addDeduction(BuildContext context) async {
    final provider = Provider.of<AppStateProvider>(context, listen: false);
    final name = _dedNameController.text.trim();
    final amt = double.tryParse(_dedAmountController.text.trim());

    if (name.isNotEmpty && amt != null && amt > 0) {
      await provider.addDeduction(
        Deduction(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: name,
          amount: amt,
          type: _dedType,
          amountType: _dedAmountType,
          frequency: _dedFrequency,
        ),
      );
      _dedNameController.clear();
      _dedAmountController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppStateProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            key: const Key('save_settings_btn'),
            icon: const Icon(Icons.save),
            onPressed: () => _saveSettings(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Income Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('settings_pay_amount_input'),
              controller: _payController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Base Pay Amount (\$)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<PayFrequency>(
              key: const Key('settings_pay_frequency_dropdown'),
              initialValue: _frequency,
              decoration: const InputDecoration(
                labelText: 'Pay Frequency',
                border: OutlineInputBorder(),
              ),
              items: PayFrequency.values
                  .map(
                    (f) =>
                        DropdownMenuItem(value: f, child: Text(f.displayName)),
                  )
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _frequency = val);
              },
            ),
            const Divider(height: 30),
            const Text(
              'Sales Tax Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('settings_sales_tax_input'),
              controller: _taxController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Sales Tax Rate (%)',
                border: OutlineInputBorder(),
              ),
            ),
            const Divider(height: 30),
            const Text(
              'Payroll Deductions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('settings_deduction_name_input'),
              controller: _dedNameController,
              decoration: const InputDecoration(
                labelText: 'Deduction Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('settings_deduction_amount_input'),
                    controller: _dedAmountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Amount / % Rate',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<DeductionAmountType>(
                    initialValue: _dedAmountType,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: DeductionAmountType.values
                        .map(
                          (t) => DropdownMenuItem(
                            value: t,
                            child: Text(
                              t == DeductionAmountType.flat
                                  ? 'Flat (\$)'
                                  : '% of Income',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _dedAmountType = val);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<DeductionType>(
                    initialValue: _dedType,
                    decoration: const InputDecoration(
                      labelText: 'Tax Category',
                    ),
                    items: DeductionType.values
                        .map(
                          (t) => DropdownMenuItem(
                            value: t,
                            child: Text(
                              t == DeductionType.preTax
                                  ? 'Pre-Tax'
                                  : 'Post-Tax',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _dedType = val);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<PayFrequency>(
                    initialValue: _dedFrequency,
                    decoration: const InputDecoration(labelText: 'Frequency'),
                    items: PayFrequency.values
                        .map(
                          (f) => DropdownMenuItem(
                            value: f,
                            child: Text(f.displayName),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _dedFrequency = val);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              key: const Key('settings_add_deduction_btn'),
              onPressed: () => _addDeduction(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Deduction'),
            ),
            const SizedBox(height: 12),
            if (provider.deductions.isEmpty)
              const Text('No deductions configured.')
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: provider.deductions.length,
                itemBuilder: (context, index) {
                  final d = provider.deductions[index];
                  return ListTile(
                    key: Key('deduction_item_${d.id}'),
                    title: Text(d.name),
                    subtitle: Text(
                      '${d.amountType == DeductionAmountType.flat ? "\$${d.amount}" : "${d.amount}%"} (${d.type == DeductionType.preTax ? "Pre-Tax" : "Post-Tax"}, ${d.frequency.displayName})',
                    ),
                    trailing: IconButton(
                      key: Key('delete_deduction_btn_${d.id}'),
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => provider.removeDeduction(d.id),
                    ),
                  );
                },
              ),
            const Divider(height: 30),
            ElevatedButton.icon(
              key: const Key('reset_onboarding_btn'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade100,
              ),
              icon: const Icon(Icons.restart_alt, color: Colors.red),
              label: const Text(
                'Reset Setup & Onboarding',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () async {
                await provider.resetOnboarding();
                if (context.mounted) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
