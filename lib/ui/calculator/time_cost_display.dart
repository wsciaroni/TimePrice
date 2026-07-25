import 'package:flutter/material.dart';
import 'package:time_price/models/time_cost_result.dart';

class TimeCostDisplay extends StatelessWidget {
  const TimeCostDisplay({super.key, required this.result});

  final TimeCostResult result;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text(
              'Working Time Equivalent',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            Text(
              result.formattedNaturalString,
              key: const Key('time_cost_natural_string'),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
              textAlign: TextAlign.center,
            ),
            const Divider(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text(
                      'Net Hourly Wage',
                      style: TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${result.netHourlyPay.toStringAsFixed(2)}/hr',
                      key: const Key('net_hourly_pay_display'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Text(
                      'Total Price (w/ Tax)',
                      style: TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${result.totalPriceWithTax.toStringAsFixed(2)}',
                      key: const Key('total_price_tax_display'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Text('Working Hours', style: TextStyle(fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      result.totalWorkingHours.isInfinite
                          ? 'Infinite'
                          : result.totalWorkingHours.toStringAsFixed(2),
                      key: const Key('working_hours_display'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
