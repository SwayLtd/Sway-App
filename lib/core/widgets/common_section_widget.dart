import 'package:flutter/material.dart';

class CommonSectionWidget extends StatelessWidget {
  final String title;
  final Widget child;
  final bool hiddenIfNotFoundOrError;
  final AsyncSnapshot? snapshot;

  const CommonSectionWidget({
    required this.title,
    required this.child,
    this.hiddenIfNotFoundOrError = false,
    this.snapshot,
  });

  @override
  Widget build(BuildContext context) {
    if (snapshot != null) {
      if (snapshot!.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      } else if (snapshot!.hasError) {
        return hiddenIfNotFoundOrError
            ? const SizedBox.shrink()
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitle(),
                  const SizedBox(height: 10),
                  Text('Error: ${snapshot!.error}'),
                ],
              );
      } else if (!snapshot!.hasData || (snapshot!.data is List && (snapshot!.data as List).isEmpty)) {
        return hiddenIfNotFoundOrError
            ? const SizedBox.shrink()
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitle(),
                  const SizedBox(height: 10),
                  const Text('No data found'),
                ],
              );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitle(),
        const SizedBox(height: 10),
        child,
      ],
    );
  }

  Widget _buildTitle() {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }
}
