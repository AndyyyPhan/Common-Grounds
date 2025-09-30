import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../my_app_state.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<MyAppState>().favorites;
    if (favorites.isEmpty)
      return const Center(child: Text('No favorites yet.'));
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Favorites (${favorites.length})',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        for (final p in favorites)
          ListTile(
            leading: const Icon(Icons.favorite),
            title: Text(p.asLowerCase),
          ),
      ],
    );
  }
}
