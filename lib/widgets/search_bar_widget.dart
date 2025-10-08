import 'package:flutter/material.dart';
import 'dart:async';

/// Search bar widget with debouncing and clear button
class SearchBarWidget extends StatefulWidget {
  final String? initialValue;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;
  final String hintText;
  final Duration debounceDuration;

  const SearchBarWidget({
    Key? key,
    this.initialValue,
    required this.onChanged,
    this.onClear,
    this.hintText = 'Search tasks...',
    this.debounceDuration = const Duration(milliseconds: 300),
  }) : super(key: key);

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  late final TextEditingController _controller;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged(String value) {
    // Cancel previous timer
    _debounceTimer?.cancel();

    // Start new timer
    _debounceTimer = Timer(widget.debounceDuration, () {
      widget.onChanged(value);
    });
  }

  void _onClear() {
    _controller.clear();
    _debounceTimer?.cancel();
    widget.onChanged('');
    if (widget.onClear != null) {
      widget.onClear!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _controller,
        onChanged: _onTextChanged,
        decoration: InputDecoration(
          hintText: widget.hintText,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: _onClear,
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        textInputAction: TextInputAction.search,
      ),
    );
  }
}
