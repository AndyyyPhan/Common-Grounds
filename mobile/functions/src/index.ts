import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

// Initialize Firebase Admin
admin.initializeApp();

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
export const findNearbyMatches = functions.https.onCall(
  async (data: FindMatchesRequest, context): Promise<FindMatchesResponse> => {
    const startTime = Date.now();
    
    // Validate authentication
    if (!context.auth) {
      throw new functions.https.HttpsError(
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
    if (currentUserUid !== context.auth.uid) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Can only find matches for authenticated user'
      );
    }

    try {
      const db = admin.firestore();
      
      // Get current user profile
      const currentUserDoc = await db.collection('users').doc(currentUserUid).get();
      if (!currentUserDoc.exists) {
        throw new functions.https.HttpsError(
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
        throw new functions.https.HttpsError(
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
      const currentInterestsSet = new Set(currentUserProfile.interests);

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
      
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }
      
      throw new functions.https.HttpsError(
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
export const getUserProfile = functions.https.onCall(
  async (data: { uid: string }, context) => {
    // Validate authentication
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated'
      );
    }

    const { uid } = data;
    const db = admin.firestore();
    
    try {
      const userDoc = await db.collection('users').doc(uid).get();
      
      if (!userDoc.exists) {
        throw new functions.https.HttpsError(
          'not-found',
          'User profile not found'
        );
      }

      return userDoc.data();
    } catch (error) {
      console.error('Error in getUserProfile:', error);
      
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }
      
      throw new functions.https.HttpsError(
        'internal',
        'An error occurred while getting user profile',
        error
      );
    }
  }
);
