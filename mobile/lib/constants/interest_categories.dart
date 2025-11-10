// Interest categories and taxonomy for matching algorithm
// Follows industry best practices from Hinge, Bumble, and TikTok

// Category definitions with emojis for UI
enum InterestCategory {
  academic('Academic', '📚'),
  sports('Sports & Fitness', '🏃'),
  entertainment('Entertainment', '🎮'),
  creative('Arts & Creative', '🎵'),
  social('Food & Social', '🍕'),
  lifestyle('Lifestyle', '🌱');

  final String displayName;
  final String emoji;

  const InterestCategory(this.displayName, this.emoji);

  String get fullDisplayName => '$emoji $displayName';
}

// Category weights for matching algorithm
// Equal weights - friendships form around any shared passion
const Map<InterestCategory, double> kCategoryWeights = {
  InterestCategory.academic: 0.167, // ~16.7%
  InterestCategory.sports: 0.167, // ~16.7%
  InterestCategory.social: 0.167, // ~16.7%
  InterestCategory.entertainment: 0.167, // ~16.7%
  InterestCategory.creative: 0.166, // ~16.6%
  InterestCategory.lifestyle: 0.166, // ~16.6%
};

// Predefined interests organized by category
const Map<InterestCategory, List<String>> kCategorizedInterests = {
  InterestCategory.academic: [
    'Study Buddy',
    'Research',
    'Hackathons',
    'Coding',
    'Startups',
    'Entrepreneurship',
    'Data Science',
    'Debate',
    'Reading',
    'Languages',
    'Physics',
    'Chemistry',
    'Biology',
    'Engineering',
    'Math',
  ],
  InterestCategory.sports: [
    'Basketball',
    'Gym',
    'Volleyball',
    'Running',
    'Pickleball',
    'Soccer',
    'Tennis',
    'Swimming',
    'Cycling',
    'Hiking',
    'Rock Climbing',
    'Yoga',
    'Martial Arts',
    'Dance',
    'Frisbee',
  ],
  InterestCategory.entertainment: [
    'Gaming',
    'Board Games',
    'Movies',
    'Anime',
    'TV Shows',
    'Podcasts',
    'Streaming',
    'Esports',
    'Comics',
    'Sci-Fi',
    'Fantasy',
    'Horror',
  ],
  InterestCategory.creative: [
    'Music',
    'Concerts',
    'Photography',
    'Art',
    'Painting',
    'Drawing',
    'Writing',
    'Poetry',
    'Theater',
    'Film Making',
    'DJing',
    'Singing',
    'Instruments',
  ],
  InterestCategory.social: [
    'Coffee',
    'Boba',
    'Foodie',
    'Cooking',
    'Baking',
    'Restaurants',
    'Parties',
    'Clubs',
    'Bars',
    'Karaoke',
    'Social Events',
  ],
  InterestCategory.lifestyle: [
    'Travel',
    'Volunteering',
    'Sustainability',
    'Fashion',
    'Pets',
    'Meditation',
    'Nature',
    'Camping',
    'Gardening',
    'Crafts',
  ],
};

// Flatten all interests into a single list for backward compatibility
final List<String> kAllInterests = kCategorizedInterests.values
    .expand((interests) => interests)
    .toList();

// Synonym mapping for interest normalization
// Maps common variations to canonical interest names
const Map<String, String> kInterestSynonyms = {
  // Academic
  'cs': 'Coding',
  'programming': 'Coding',
  'computer science': 'Coding',
  'software': 'Coding',
  'study': 'Study Buddy',
  'studying': 'Study Buddy',
  'homework': 'Study Buddy',
  'entrepreneur': 'Entrepreneurship',
  'startup': 'Startups',
  'science': 'Research',

  // Sports
  'bball': 'Basketball',
  'hoops': 'Basketball',
  'vball': 'Volleyball',
  'working out': 'Gym',
  'fitness': 'Gym',
  'weightlifting': 'Gym',
  'lifting': 'Gym',
  'jogging': 'Running',
  'cardio': 'Running',
  'football': 'Soccer',
  'biking': 'Cycling',
  'climb': 'Rock Climbing',
  'climbing': 'Rock Climbing',
  'ultimate': 'Frisbee',
  'ultimate frisbee': 'Frisbee',

  // Entertainment
  'video games': 'Gaming',
  'games': 'Gaming',
  'gamer': 'Gaming',
  'tabletop': 'Board Games',
  'film': 'Movies',
  'films': 'Movies',
  'cinema': 'Movies',
  'tv': 'TV Shows',
  'television': 'TV Shows',
  'shows': 'TV Shows',
  'manga': 'Anime',

  // Creative
  'musician': 'Music',
  'concert': 'Concerts',
  'live music': 'Concerts',
  'photo': 'Photography',
  'photos': 'Photography',
  'artist': 'Art',
  'sketch': 'Drawing',
  'sketching': 'Drawing',
  'writer': 'Writing',
  'author': 'Writing',
  'poet': 'Poetry',
  'dj': 'DJing',
  'producer': 'Music',
  'guitar': 'Instruments',
  'piano': 'Instruments',
  'drums': 'Instruments',

  // Social
  'cafe': 'Coffee',
  'coffee shops': 'Coffee',
  'bubble tea': 'Boba',
  'bbt': 'Boba',
  'food': 'Foodie',
  'eating out': 'Foodie',
  'cook': 'Cooking',
  'chef': 'Cooking',
  'baker': 'Baking',
  'dining': 'Restaurants',
  'party': 'Parties',
  'clubbing': 'Clubs',
  'nightlife': 'Clubs',
  'socializing': 'Social Events',

  // Lifestyle
  'traveling': 'Travel',
  'trips': 'Travel',
  'volunteer': 'Volunteering',
  'service': 'Volunteering',
  'eco': 'Sustainability',
  'environment': 'Sustainability',
  'green': 'Sustainability',
  'style': 'Fashion',
  'animals': 'Pets',
  'dogs': 'Pets',
  'cats': 'Pets',
  'mindfulness': 'Meditation',
  'outdoors': 'Nature',
  'outdoor': 'Nature',
};

// Helper to get category for a given interest
InterestCategory? getCategoryForInterest(String interest) {
  for (final entry in kCategorizedInterests.entries) {
    if (entry.value.contains(interest)) {
      return entry.key;
    }
  }
  return null;
}

// Helper to get all interests for a category
List<String> getInterestsForCategory(InterestCategory category) {
  return kCategorizedInterests[category] ?? [];
}

// Helper to get interest count per category
int getTotalInterestCount() {
  return kAllInterests.length;
}
