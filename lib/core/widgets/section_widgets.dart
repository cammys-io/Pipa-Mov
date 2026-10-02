import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

String dinero(num value) => NumberFormat.currency(
  locale: 'es_MX',
  symbol: r'$',
  decimalDigits: 2,
).format(value);
String fechaCorta(DateTime value) => DateFormat('dd/MM/yyyy').format(value);

class SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const SummaryCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color = AppColors.primary,
  });
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    ),
  );
}

class SummaryGrid extends StatelessWidget {
  final List<Widget> children;
  const SummaryGrid({super.key, required this.children});
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final count = box.maxWidth < 550
          ? 1
          : box.maxWidth < 1050
          ? 2
          : children.length;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          for (final child in children)
            SizedBox(
              width: (box.maxWidth - (count - 1) * 16) / count,
              child: child,
            ),
        ],
      );
    },
  );
}

class EmptyState extends StatelessWidget {
  final String title;
  final String message;
  const EmptyState({super.key, required this.title, required this.message});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(32),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.inbox_outlined,
            size: 40,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    ),
  );
}

class CatalogToolbar extends StatelessWidget {
  final String hint;
  final String label;
  final ValueChanged<String> onChanged;
  final VoidCallback onAdd;
  const CatalogToolbar({
    super.key,
    required this.hint,
    required this.label,
    required this.onChanged,
    required this.onAdd,
  });
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final search = TextField(
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search),
        ),
        onChanged: onChanged,
      );
      final button = FilledButton.icon(
        onPressed: onAdd,
        icon: const Icon(Icons.add, size: 20),
        label: Text(label),
      );
      return box.maxWidth < 580
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [search, const SizedBox(height: 12), button],
            )
          : Row(
              children: [
                Expanded(child: search),
                const SizedBox(width: 16),
                button,
              ],
            );
    },
  );
}
