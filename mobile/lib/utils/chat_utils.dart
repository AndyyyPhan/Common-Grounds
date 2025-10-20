import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/chat_service.dart';
import '../services/profile_service.dart';
import '../pages/chat_detail_page.dart';

/// Utility class for chat-related operations
class ChatUtils {
  /// Start a conversation with another user
  /// Opens the chat detail page after creating/finding the conversation
  static Future<void> startConversationWith(
    BuildContext context,
    String otherUserId,
  ) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      // Get current user's profile
      final currentUserProfile = await ProfileService.instance.getProfile(
        currentUser.uid,
      );
      if (currentUserProfile == null) {
        if (context.mounted) Navigator.of(context).pop();
        throw Exception('Could not load your profile');
      }

      // Get other user's profile
      final otherUserProfile = await ProfileService.instance.getProfile(
        otherUserId,
      );
      if (otherUserProfile == null) {
        if (context.mounted) Navigator.of(context).pop();
        throw Exception('Could not load user profile');
      }

      // Create profile maps for conversation metadata
      final currentUserProfileMap = {
        'displayName': currentUserProfile.displayName,
        'photoUrl': currentUserProfile.photoUrl,
      };

      final otherUserProfileMap = {
        'displayName': otherUserProfile.displayName,
        'photoUrl': otherUserProfile.photoUrl,
      };

      // Get or create conversation
      final conversationId = await ChatService.instance.getOrCreateConversation(
        currentUser.uid,
        otherUserId,
        currentUserProfileMap,
        otherUserProfileMap,
      );

      // Close loading dialog
      if (context.mounted) Navigator.of(context).pop();

      // Navigate to chat detail page
      if (context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatDetailPage(
              conversationId: conversationId,
              otherUserId: otherUserId,
              otherUserName: otherUserProfile.displayName ?? 'User',
            ),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if open
      if (context.mounted) Navigator.of(context).pop();

      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start conversation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
