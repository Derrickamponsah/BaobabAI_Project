import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A labelled dropdown bound to a value, styled per new mockups.
class LabeledDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  const LabeledDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textDark, fontSize: 15)),
              const Text(' * ', style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold)),
              const Icon(Icons.info, size: 16, color: Color(0xFF4C84FF)),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: value,
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down, color: AppTheme.textLight),
            items: options
                .map((o) => DropdownMenuItem(
                    value: o, child: Text(o, overflow: TextOverflow.ellipsis)))
                .toList(),
            onChanged: onChanged,
            validator: (v) => v == null ? 'Please select $label' : null,
          ),
        ],
      ),
    );
  }
}

/// A numeric text field styled per new mockups.
class NumberField extends StatelessWidget {
  final String label;
  final String example;
  final TextEditingController controller;

  const NumberField({
    super.key,
    required this.label,
    required this.example,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textDark, fontSize: 15)),
              const Text(' * ', style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold)),
              const Icon(Icons.info, size: 16, color: Color(0xFF4C84FF)),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Required';
              final d = double.tryParse(v.trim());
              if (d == null || d <= 0) return 'Invalid positive number';
              return null;
            },
          ),
          const SizedBox(height: 6),
          Text('Example: $example', style: const TextStyle(color: AppTheme.textLight, fontSize: 13)),
        ],
      ),
    );
  }
}

/// The gradient button for primary actions
class GradientButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback onPressed;
  final bool loading;

  const GradientButton({
    super.key,
    required this.text,
    this.icon,
    required this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: loading
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: Colors.white),
                    const SizedBox(width: 8),
                  ],
                  Text(text, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              ),
      ),
    );
  }
}

