import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../theme/app_theme.dart';

/// Un paiement couvre toujours un ou plusieurs cycles ENTIERS — jamais
/// un compte de séances choisi à la main. Le cycle en cours est
/// proposé dès sa première séance impayée, pour la totalité de ses
/// séances : pas besoin d'attendre que le groupe le boucle pour
/// encaisser d'avance.
Future<bool?> showRecordPaymentSheet(BuildContext context, {required String studentId}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _RecordPaymentSheet(studentId: studentId),
  );
}

class _RecordPaymentSheet extends StatefulWidget {
  const _RecordPaymentSheet({required this.studentId});

  final String studentId;

  @override
  State<_RecordPaymentSheet> createState() => _RecordPaymentSheetState();
}

class _RecordPaymentSheetState extends State<_RecordPaymentSheet> {
  late final _cycles = MockData.unpaidCycles(widget.studentId);
  var _cycleCount = 1;

  int get _sessions => _cycles.take(_cycleCount).fold<int>(0, (s, c) => s + c.sessions);
  double get _amount => _cycles.take(_cycleCount).fold<double>(0, (s, c) => s + c.amount);

  void _confirm() {
    MockData.recordCyclePayment(widget.studentId, cycleCount: _cycleCount);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Encaisser un paiement', style: textTheme.titleLarge),
            const SizedBox(height: AppSpacing.lg),
            if (_cycles.isEmpty)
              Text(
                'Rien à encaisser pour le moment — cet élève est à jour.',
                style: textTheme.bodyMedium,
              )
            else ...[
              if (_cycles.length > 1) ...[
                Text('Cycles à encaisser', style: textTheme.labelSmall),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    IconButton.filled(
                      onPressed: _cycleCount > 1
                          ? () => setState(() => _cycleCount--)
                          : null,
                      icon: const Icon(Icons.remove),
                    ),
                    Expanded(
                      child: Center(
                        child: Text('$_cycleCount', style: textTheme.headlineMedium),
                      ),
                    ),
                    IconButton.filled(
                      onPressed: _cycleCount < _cycles.length
                          ? () => setState(() => _cycleCount++)
                          : null,
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.canvas,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$_sessions séance${_sessions > 1 ? 's' : ''}',
                      style: textTheme.bodyMedium,
                    ),
                    Text(
                      '${_amount.toStringAsFixed(0)} DT',
                      style: textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: _confirm,
                child: const Text('Encaisser'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
