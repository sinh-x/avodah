import 'package:flutter/material.dart';

class ProjectListScreen extends StatelessWidget {
  const ProjectListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects'),
      ),
      body: const Center(
        child: Text('Projects coming soon'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Add project
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
