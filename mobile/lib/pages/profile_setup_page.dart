import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';
import '../services/profile_service.dart';

const kInterestOptions = <String>[
  'Basketball',
  'Gym',
  'Volleyball',
  'Running',
  'Pickleball',
  'Gaming',
  'Board Games',
  'Coding',
  'Hackathons',
  'Coffee',
  'Boba',
  'Study Buddy',
  'Music',
  'Concerts',
  'Photography',
  'Hiking',
  'Foodie',
  'Movies',
  'Anime',
];

class ProfileSetupPage extends StatefulWidget {
  final UserProfile profile;
  const ProfileSetupPage({super.key, required this.profile});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  late final TextEditingController _name;
  late final TextEditingController _bio;
  late final TextEditingController _major;
  late final TextEditingController _classYear;
  late Set<String> _interests;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.profile.displayName ?? '');
    _bio = TextEditingController(text: widget.profile.bio ?? '');
    _major = TextEditingController(text: widget.profile.major ?? '');
    _classYear = TextEditingController(text: widget.profile.classYear ?? '');
    _interests = widget.profile.interests.toSet();
  }

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    _major.dispose();
    _classYear.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final name = _name.text.trim();
      final p = UserProfile(
        uid: widget.profile.uid,
        displayName: name.isEmpty ? widget.profile.displayName : name,
        photoUrl: widget.profile.photoUrl,
        bio: _bio.text.trim().isEmpty ? null : _bio.text.trim(),
        classYear: _classYear.text.trim().isEmpty
            ? null
            : _classYear.text.trim(),
        major: _major.text.trim().isEmpty ? null : _major.text.trim(),
        interests: _interests.toList()..sort(),
        createdAt: widget.profile.createdAt,
        updatedAt: DateTime.now(),
      );
      await ProfileService.instance.upsertProfile(p);
      if (name.isNotEmpty) {
        final user = FirebaseAuth.instance.currentUser;
        await user?.updateDisplayName(name);
        await user?.reload();
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile saved')));
      // The gate will detect completion and route to AppShell automatically.
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSave = _interests.isNotEmpty; // your completion rule
    return Scaffold(
      appBar: AppBar(title: const Text('Create your profile')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Display name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _bio,
              decoration: const InputDecoration(labelText: 'Bio (optional)'),
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _major,
                    decoration: const InputDecoration(
                      labelText: 'Major (optional)',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: _classYear,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Class year'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Select your interests'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in kInterestOptions)
                  FilterChip(
                    label: Text(tag),
                    selected: _interests.contains(tag),
                    onSelected: (sel) {
                      setState(() {
                        if (sel) {
                          _interests.add(tag);
                        } else {
                          _interests.remove(tag);
                        }
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: (!canSave || _saving) ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save & Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
