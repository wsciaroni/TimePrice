import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:time_price/models/deduction.dart';
import 'package:time_price/models/income_config.dart';
import 'package:time_price/models/pay_frequency.dart';
import 'package:time_price/models/tax_config.dart';
import 'package:time_price/providers/app_state_provider.dart';

class OnboardingWizardScreen extends StatefulWidget {
  const OnboardingWizardScreen({super.key});

  @override
  State<OnboardingWizardScreen> createState() => _OnboardingWizardScreenState();
}

class _OnboardingWizardScreenState extends State<OnboardingWizardScreen> {
  int _currentStep = 0;

  // Step 1 Controllers
  final _amountController = TextEditingController(text: '25.0');
  PayFrequency _selectedFrequency = PayFrequency.hourly;

  // Step 2 State
  final List<Deduction> _tempDeductions = [];
  final _dedNameController = TextEditingController();
  final _dedAmountController = TextEditingController();
  DeductionType _dedType = DeductionType.preTax;
  DeductionAmountType _dedAmountType = DeductionAmountType.flat;
  PayFrequency _dedFrequency = PayFrequency.hourly;

  // Step 3 Controller
  final _taxController = TextEditingController(text: '0.0');

  @override
  void dispose() {
    _amountController.dispose();
    _dedNameController.dispose();
    _dedAmountController.dispose();
    _taxController.dispose();
    super.dispose();
  }

  void _addDeduction() {
    final name = _dedNameController.text.trim();
    final amt = double.tryParse(_dedAmountController.text.trim());
    if (name.isNotEmpty && amt != null && amt > 0) {
      setState(() {
        _tempDeductions.add(
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
      });
    }
  }

  Future<void> _finishOnboarding(BuildContext context) async {
    final provider = Provider.of<AppStateProvider>(context, listen: false);
    final incomeVal = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final taxVal = double.tryParse(_taxController.text.trim()) ?? 0.0;

    await provider.updateIncomeConfig(
      IncomeConfig(
        amount: incomeVal < 0 ? 0.0 : incomeVal,
        frequency: _selectedFrequency,
      ),
    );
    await provider.setDeductions(_tempDeductions);
    await provider.updateTaxConfig(
      TaxConfig(salesTaxRate: taxVal < 0 ? 0.0 : taxVal),
    );
    await provider.setOnboardingCompleted(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to TimePrice Setup'),
        centerTitle: true,
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep < 2) {
            setState(() {
              _currentStep += 1;
            });
          } else {
            unawaited(_finishOnboarding(context));
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() {
              _currentStep -= 1;
            });
          }
        },
        controlsBuilder: (context, details) {
          final isActiveStep = details.stepIndex == _currentStep;
          final isFinalStep = details.stepIndex == 2;
          final Key buttonKey = isActiveStep
              ? Key(isFinalStep ? 'finish_onboarding_btn' : 'next_step_btn')
              : Key('inactive_step_btn_${details.stepIndex}');

          return Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Row(
              children: [
                ElevatedButton(
                  key: buttonKey,
                  onPressed: details.onStepContinue,
                  child: Text(isFinalStep ? 'Finish Setup' : 'Next'),
                ),
                if (details.stepIndex > 0) ...[
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: details.onStepCancel,
                    child: const Text('Back'),
                  ),
                ],
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text('1. Income Setup'),
            isActive: _currentStep >= 0,
            content: Column(
              children: [
                TextField(
                  key: const Key('onboarding_pay_amount_input'),
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Base Pay Amount (\$)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<PayFrequency>(
                  key: const Key('onboarding_pay_frequency_dropdown'),
                  initialValue: _selectedFrequency,
                  decoration: const InputDecoration(
                    labelText: 'Pay Frequency',
                    border: OutlineInputBorder(),
                  ),
                  items: PayFrequency.values
                      .map(
                        (freq) => DropdownMenuItem(
                          value: freq,
                          child: Text(freq.displayName),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedFrequency = val;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          Step(
            title: const Text('2. Payroll Deductions (Optional)'),
            isActive: _currentStep >= 1,
            content: Column(
              children: [
                TextField(
                  key: const Key('onboarding_deduction_name_input'),
                  controller: _dedNameController,
                  decoration: const InputDecoration(
                    labelText: 'Deduction Name (e.g. 401k, Health)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('onboarding_deduction_amount_input'),
                        controller: _dedAmountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Amount / Rate',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<DeductionAmountType>(
                        initialValue: _dedAmountType,
                        decoration: const InputDecoration(
                          labelText: 'Amount Type',
                        ),
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
                        decoration: const InputDecoration(
                          labelText: 'Frequency',
                        ),
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
                  key: const Key('onboarding_add_deduction_btn'),
                  onPressed: _addDeduction,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Deduction'),
                ),
                const Divider(),
                if (_tempDeductions.isEmpty)
                  const Text('No deductions added.')
                else
                  Column(
                    children: _tempDeductions
                        .map(
                          (d) => ListTile(
                            title: Text(d.name),
                            subtitle: Text(
                              '${d.amountType == DeductionAmountType.flat ? "\$${d.amount}" : "${d.amount}%"} (${d.type == DeductionType.preTax ? "Pre-Tax" : "Post-Tax"}, ${d.frequency.displayName})',
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  _tempDeductions.removeWhere(
                                    (item) => item.id == d.id,
                                  );
                                });
                              },
                            ),
                          ),
                        )
                        .toList(),
                  ),
              ],
            ),
          ),
          Step(
            title: const Text('3. Sales Tax Setup'),
            isActive: _currentStep >= 2,
            content: Column(
              children: [
                TextField(
                  key: const Key('onboarding_sales_tax_input'),
                  controller: _taxController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Sales Tax Rate (%)',
                    border: OutlineInputBorder(),
                    hintText: 'e.g. 7.0 for 7%',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
