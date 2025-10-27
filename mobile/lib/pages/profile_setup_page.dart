import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_profile.dart';
import '../services/profile_service.dart';
import '../core/widgets/avatar.dart';

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
  late final TextEditingController _customInterest;
  late Set<String> _interests;
  bool _saving = false;
  String? _error;
  bool _showCustomInterestField = false;
  File? _newProfileImage; // New image selected from gallery/camera
  String? _profileImageUrl; // Current image URL from profile

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.profile.displayName ?? '');
    _bio = TextEditingController(text: widget.profile.bio ?? '');
    _major = TextEditingController(text: widget.profile.major ?? '');
    _classYear = TextEditingController(text: widget.profile.classYear ?? '');
    _customInterest = TextEditingController();
    _interests = widget.profile.interests.toSet();
    _profileImageUrl = widget.profile.photoUrl;
  }

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    _major.dispose();
    _classYear.dispose();
    _customInterest.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _newProfileImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  Future<String?> _uploadProfileImage(File imageFile) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      // Create a reference to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child('${user.uid}.jpg');

      // Upload the file
      final uploadTask = await storageRef.putFile(imageFile);

      // Get the download URL
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error uploading image: $e')));
      }
      return null;
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _addCustomInterest() {
    final custom = _customInterest.text.trim();
    if (custom.isEmpty) return;

    // Check if it already exists (case-insensitive)
    final lowerCustom = custom.toLowerCase();
    final exists = _interests.any((i) => i.toLowerCase() == lowerCustom);

    if (!exists) {
      setState(() {
        _interests.add(custom);
        _customInterest.clear();
        _showCustomInterestField = false;
      });
    } else {
      // Show a message that interest already exists
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Interest "$custom" already added'),
          duration: const Duration(seconds: 2),
        ),
      );
      _customInterest.clear();
    }
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      // Upload new profile image if selected
      String? newPhotoUrl = _profileImageUrl;
      if (_newProfileImage != null) {
        newPhotoUrl = await _uploadProfileImage(_newProfileImage!);
      }

      final name = _name.text.trim();
      final p = UserProfile(
        uid: widget.profile.uid,
        displayName: name.isEmpty ? widget.profile.displayName : name,
        photoUrl: newPhotoUrl,
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

      // Update Firebase Auth profile
      final user = FirebaseAuth.instance.currentUser;
      if (name.isNotEmpty) {
        await user?.updateDisplayName(name);
      }
      if (newPhotoUrl != null && newPhotoUrl != widget.profile.photoUrl) {
        await user?.updatePhotoURL(newPhotoUrl);
      }
      await user?.reload();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved successfully!')),
      );

      // Navigate back to previous screen (best practice for edit screens)
      Navigator.pop(context);
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

            // Profile picture editor
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      // Show either new image, current image, or default avatar
                      if (_newProfileImage != null)
                        CircleAvatar(
                          radius: 60,
                          backgroundImage: FileImage(_newProfileImage!),
                        )
                      else
                        AppAvatar(
                          imageUrl: _profileImageUrl,
                          displayName: _name.text.isNotEmpty
                              ? _name.text
                              : widget.profile.displayName,
                          size: 120,
                        ),
                      // Edit button overlay
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                            ),
                            onPressed: _showImageSourceDialog,
                            tooltip: 'Change profile picture',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap camera to change photo',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

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
                // Predefined interests
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
                // Custom interests (show as selectable filter chips with delete option)
                for (final customTag in _interests.where(
                  (i) => !kInterestOptions.contains(i),
                ))
                  FilterChip(
                    label: Text(customTag),
                    selected:
                        true, // Custom interests are always selected (they're in _interests)
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onSelected: (sel) {
                      // Deselecting removes the custom interest
                      if (!sel) {
                        setState(() {
                          _interests.remove(customTag);
                        });
                      }
                    },
                    onDeleted: () {
                      // Delete button also removes it
                      setState(() {
                        _interests.remove(customTag);
                      });
                    },
                  ),
                // "Add custom" action chip
                ActionChip(
                  avatar: const Icon(Icons.add, size: 18),
                  label: const Text('Add custom'),
                  onPressed: () {
                    setState(() {
                      _showCustomInterestField = !_showCustomInterestField;
                    });
                  },
                ),
              ],
            ),
            // Custom interest input field
            if (_showCustomInterestField) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customInterest,
                      decoration: const InputDecoration(
                        labelText: 'Custom interest',
                        hintText: 'e.g., Ultimate Frisbee',
                      ),
                      textCapitalization: TextCapitalization.words,
                      onSubmitted: (_) => _addCustomInterest(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.check),
                    onPressed: _addCustomInterest,
                    tooltip: 'Add',
                  ),
                ],
              ),
            ],
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
