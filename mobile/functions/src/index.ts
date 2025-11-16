import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { onDocumentCreated, onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { setGlobalOptions } from 'firebase-functions/v2';
import * as admin from 'firebase-admin';

// Initialize Firebase Admin
admin.initializeApp();

// Set global options for 2nd gen functions
setGlobalOptions({
  region: 'us-central1',
});

// Types for our data structures
interface UserLocation {
  geohash: string;
  latitude: number;
  longitude: number;
  lastUpdated: admin.firestore.Timestamp;
  isVisible: boolean;
}

interface UserProfile {
  uid: string;
  displayName?: string;
  photoUrl?: string;
  bio?: string;
  classYear?: string;
  major?: string;
  interests: string[];
  createdAt: admin.firestore.Timestamp;
  updatedAt: admin.firestore.Timestamp;
  location?: UserLocation;
}

interface ProximityMatch {
  userProfile: UserProfile;
  distanceKm: number;
  commonInterests: string[];
  matchScore: number;
}

interface FindMatchesRequest {
  currentUserUid: string;
  maxDistanceKm?: number;
  minCommonInterests?: number;
  limit?: number;
}

interface FindMatchesResponse {
  matches: ProximityMatch[];
  totalProcessed: number;
  executionTimeMs: number;
}

/**
 * Calculate distance between two coordinates using Haversine formula
 */
function calculateDistance(
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number
): number {
  const R = 6371; // Earth's radius in kilometers
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLon = (lon2 - lon1) * Math.PI / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1 * Math.PI / 180) *
      Math.cos(lat2 * Math.PI / 180) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

/**
 * Get common interests between two users using Set intersection
 */
function getCommonInterests(
  interests1: string[],
  interests2: string[]
): string[] {
  const set1 = new Set(interests1);
  return interests2.filter(interest => set1.has(interest));
}

/**
 * Calculate match score based on interests and distance
 */
function calculateMatchScore(
  commonInterestsCount: number,
  currentUserInterestsCount: number,
  otherUserInterestsCount: number,
  distanceKm: number
): number {
  // Interest similarity score (0-1) - Jaccard similarity
  const interestSimilarity =
    commonInterestsCount /
    (currentUserInterestsCount + otherUserInterestsCount - commonInterestsCount);

  // Distance score (closer is better, 0-1)
  const distanceScore = (10 - Math.min(distanceKm, 10)) / 10;

  // Weighted combination: 70% interests, 30% distance
  return (interestSimilarity * 0.7) + (distanceScore * 0.3);
}

/**
 * Get nearby geohashes for proximity search
 */
function getNearbyGeohashes(
  centerGeohash: string,
  maxDistanceKm: number
): string[] {
  // For now, return a simple implementation
  // In production, you'd want a more sophisticated geohash expansion
  const geohashes = [centerGeohash];
  
  // Add neighboring geohashes (simplified)
  if (centerGeohash.length >= 6) {
    const base = centerGeohash.substring(0, 5);
    for (let i = 0; i < 8; i++) {
      geohashes.push(base + i.toString());
    }
  }
  
  return geohashes.slice(0, 10); // Firestore whereIn limit
}

/**
 * Cloud Function to find nearby users with similar interests
 */
export const findNearbyMatches = onCall(
  { region: 'us-central1' },
  async (request): Promise<FindMatchesResponse> => {
    const data = request.data as FindMatchesRequest;
    const context = request.auth;
    const startTime = Date.now();
    
    // Validate authentication
    if (!context) {
      throw new HttpsError(
        'unauthenticated',
        'User must be authenticated to find matches'
      );
    }

    const {
      currentUserUid,
      maxDistanceKm = 0.1, // 100 meters default
      minCommonInterests = 1,
      limit = 10
    } = data;

    // Validate current user
    if (currentUserUid !== context.uid) {
      throw new HttpsError(
        'permission-denied',
        'Can only find matches for authenticated user'
      );
    }

    try {
      const db = admin.firestore();
      
      // Get current user profile
      const currentUserDoc = await db.collection('users').doc(currentUserUid).get();
      if (!currentUserDoc.exists) {
        throw new HttpsError(
          'not-found',
          'Current user profile not found'
        );
      }

      const currentUserProfile = currentUserDoc.data() as UserProfile;
      
      // Validate user has location and interests
      if (!currentUserProfile.location?.isVisible) {
        return {
          matches: [],
          totalProcessed: 0,
          executionTimeMs: Date.now() - startTime
        };
      }

      if (currentUserProfile.interests.length === 0) {
        return {
          matches: [],
          totalProcessed: 0,
          executionTimeMs: Date.now() - startTime
        };
      }

      const currentGeohash = currentUserProfile.location.geohash;
      const currentLat = currentUserProfile.location.latitude;
      const currentLng = currentUserProfile.location.longitude;

      if (!currentLat || !currentLng) {
        throw new HttpsError(
          'invalid-argument',
          'Current user location coordinates not available'
        );
      }

      // Get nearby geohashes
      const nearbyGeohashes = getNearbyGeohashes(currentGeohash, maxDistanceKm);

      console.log(`🔍 PROXIMITY SEARCH STARTED for user: ${currentUserProfile.displayName}`);
      console.log(`📍 Current location: ${currentLat}, ${currentLng}`);
      console.log(`📍 Current geohash: ${currentGeohash}`);
      console.log(`📍 User interests: ${currentUserProfile.interests}`);
      console.log(`🔍 Searching in ${nearbyGeohashes.length} geohash areas`);

      // Query users in nearby geohashes
      const query = await db
        .collection('users')
        .where('location.geohash', 'in', nearbyGeohashes)
        .where('location.isVisible', '==', true)
        .limit(100) // Get more users for filtering
        .get();

      console.log(`🔍 Query found ${query.docs.length} users`);

      const matches: ProximityMatch[] = [];
      let totalProcessed = 0;

      // Pre-compute current user's interest set for O(1) lookups
      // const currentInterestsSet = new Set(currentUserProfile.interests);

      for (const doc of query.docs) {
        // Skip current user
        if (doc.id === currentUserUid) continue;

        totalProcessed++;

        try {
          const userProfile = doc.data() as UserProfile;

          // Check if user has location coordinates
          if (!userProfile.location?.latitude || !userProfile.location?.longitude) {
            continue;
          }

          // Calculate distance
          const distance = calculateDistance(
            currentLat,
            currentLng,
            userProfile.location.latitude,
            userProfile.location.longitude
          );

          // Filter by distance
          if (distance > maxDistanceKm) continue;

          // Get common interests
          const commonInterests = getCommonInterests(
            currentUserProfile.interests,
            userProfile.interests
          );

          // Filter by minimum common interests
          if (commonInterests.length < minCommonInterests) continue;

          // Calculate match score
          const matchScore = calculateMatchScore(
            commonInterests.length,
            currentUserProfile.interests.length,
            userProfile.interests.length,
            distance
          );

          matches.push({
            userProfile,
            distanceKm: distance,
            commonInterests,
            matchScore
          });

        } catch (error) {
          console.error(`Error processing user ${doc.id}:`, error);
          continue;
        }
      }

      // Sort by match score (highest first) and limit results
      matches.sort((a, b) => b.matchScore - a.matchScore);
      const limitedMatches = matches.slice(0, limit);

      console.log(`✅ Found ${limitedMatches.length} matches out of ${totalProcessed} processed users`);
      console.log(`⏱️ Execution time: ${Date.now() - startTime}ms`);

      return {
        matches: limitedMatches,
        totalProcessed,
        executionTimeMs: Date.now() - startTime
      };

    } catch (error) {
      console.error('Error in findNearbyMatches:', error);
      
      if (error instanceof HttpsError) {
        throw error;
      }
      
      throw new HttpsError(
        'internal',
        'An error occurred while finding matches',
        error
      );
    }
  }
);

/**
 * Cloud Function to get user profile by UID
 */
export const getUserProfile = onCall(
  { region: 'us-central1' },
  async (request) => {
    const data = request.data as { uid: string };
    const context = request.auth;
    
    // Validate authentication
    if (!context) {
      throw new HttpsError(
        'unauthenticated',
        'User must be authenticated'
      );
    }

    const { uid } = data;
    const db = admin.firestore();
    
    try {
      const userDoc = await db.collection('users').doc(uid).get();
      
      if (!userDoc.exists) {
        throw new HttpsError(
          'not-found',
          'User profile not found'
        );
      }

      return userDoc.data();
    } catch (error) {
      console.error('Error in getUserProfile:', error);
      
      if (error instanceof HttpsError) {
        throw error;
      }
      
      throw new HttpsError(
        'internal',
        'An error occurred while getting user profile',
        error
      );
    }
  }
);

/**
 * Cloud Function to detect mutual matches and send notifications
 * Triggers when a wave document is created or updated
 */
export const onWaveCreated = onDocumentCreated(
  { document: 'waves/{waveId}', region: 'us-central1' },
  async (event) => {
    const waveData = event.data?.data();
    if (!waveData) return;

    const { senderId, receiverId, status } = waveData;

    // Only process pending waves (new waves)
    if (status !== 'pending') return;

    console.log(`🌊 New wave from ${senderId} to ${receiverId}`);

    try {
      const db = admin.firestore();

      // Check if there's a reverse wave (receiver -> sender)
      const reverseWaveQuery = await db
        .collection('waves')
        .where('senderId', '==', receiverId)
        .where('receiverId', '==', senderId)
        .where('status', '==', 'pending')
        .limit(1)
        .get();

      if (reverseWaveQuery.empty) {
        console.log('No reverse wave found - not a mutual match yet');
        return;
      }

      console.log('🎉 MUTUAL MATCH DETECTED!');

      // Get both user profiles for notification
      const [senderDoc, receiverDoc] = await Promise.all([
        db.collection('users').doc(senderId).get(),
        db.collection('users').doc(receiverId).get(),
      ]);

      if (!senderDoc.exists || !receiverDoc.exists) {
        console.error('User profile not found');
        return;
      }

      const senderProfile = senderDoc.data();
      const receiverProfile = receiverDoc.data();

      // Send notifications to both users
      await Promise.all([
        sendMatchNotification(
          receiverProfile?.fcmToken,
          senderProfile?.displayName || 'Someone',
          receiverId
        ),
        sendMatchNotification(
          senderProfile?.fcmToken,
          receiverProfile?.displayName || 'Someone',
          senderId
        ),
      ]);

      console.log('✅ Match notifications sent successfully');
    } catch (error) {
      console.error('Error processing mutual match:', error);
    }
  }
);

/**
 * Helper function to send a match notification via FCM
 */
async function sendMatchNotification(
  fcmToken: string | undefined,
  matchedUserName: string,
  userId: string
): Promise<void> {
  if (!fcmToken) {
    console.log(`No FCM token for user ${userId}, skipping notification`);
    return;
  }

  try {
    const message = {
      token: fcmToken,
      notification: {
        title: '🤝 New Match!',
        body: `You and ${matchedUserName} are now connected!`,
      },
      data: {
        type: 'mutual_match',
        matchedUserName,
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
        route: '/waves',
        tab: 'matched',
      },
      android: {
        priority: 'high' as const,
        notification: {
          channelId: 'matches',
          sound: 'default',
          priority: 'high' as const,
          icon: 'ic_notification',
          color: '#4CAF50', // Green color for friendship
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
          },
        },
      },
    };

    await admin.messaging().send(message);
    console.log(`✅ Notification sent to ${userId}`);
  } catch (error) {
    console.error(`Error sending notification to ${userId}:`, error);
  }
}
