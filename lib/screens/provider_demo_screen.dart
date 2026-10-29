import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/counter_notifier.dart';

class ProviderDemoScreen extends StatelessWidget {
  const ProviderDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CounterNotifier(),
      // Builder so the Scaffold reads the notifier from below this provider.
      child: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Latihan 4 - Provider')),
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Provider dibangun di atas InheritedWidget. '
                      'notifyListeners() memberi tahu dependents untuk rebuild.',
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Consumer<CounterNotifier>(
                  builder: (context, counter, child) => Text(
                    '${counter.counter}',
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      tooltip: 'Kurangi',
                      onPressed: context.read<CounterNotifier>().decrement,
                      icon: const Icon(Icons.remove),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      tooltip: 'Tambah',
                      onPressed: context.read<CounterNotifier>().increment,
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: context.read<CounterNotifier>().reset,
                  child: const Text('Reset'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
