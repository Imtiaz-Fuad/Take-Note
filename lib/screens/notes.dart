import 'package:flutter/material.dart';

class Notes extends StatelessWidget {
  const Notes({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
      ),
      body: SafeArea(
        child: Center(
          child: Column(children: [
            Text("Your notes will appear here"),
          ],),
        ),
      ),
    );
  }
}