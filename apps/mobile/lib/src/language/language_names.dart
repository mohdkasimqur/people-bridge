/// A language's name in its own script, its English name, and whether the
/// own-script name still needs checking by a native speaker.
typedef LanguageName = ({String native, String english, bool needsReview});

/// Proposed names for the 23 app languages (Module 2.5). None is verified;
/// those with `needsReview: true` must be checked by a native speaker before
/// release. Manipuri uses Bengali script to match its translations.
const Map<String, LanguageName> languageNames = {
  'as': (native: 'অসমীয়া', english: 'Assamese', needsReview: false),
  'bn': (native: 'বাংলা', english: 'Bengali', needsReview: false),
  'brx': (native: 'बड़ो', english: 'Bodo', needsReview: true),
  'doi': (native: 'डोगरी', english: 'Dogri', needsReview: true),
  'en': (native: 'English', english: 'English', needsReview: false),
  'gu': (native: 'ગુજરાતી', english: 'Gujarati', needsReview: false),
  'hi': (native: 'हिन्दी', english: 'Hindi', needsReview: false),
  'kn': (native: 'ಕನ್ನಡ', english: 'Kannada', needsReview: false),
  'kok': (native: 'कोंकणी', english: 'Konkani', needsReview: false),
  'ks': (native: 'کٲشُر', english: 'Kashmiri', needsReview: false),
  'mai': (native: 'मैथिली', english: 'Maithili', needsReview: false),
  'ml': (native: 'മലയാളം', english: 'Malayalam', needsReview: false),
  'mni': (native: 'মৈতৈলোন্', english: 'Manipuri', needsReview: true),
  'mr': (native: 'मराठी', english: 'Marathi', needsReview: false),
  'ne': (native: 'नेपाली', english: 'Nepali', needsReview: false),
  'or': (native: 'ଓଡ଼ିଆ', english: 'Odia', needsReview: false),
  'pa': (native: 'ਪੰਜਾਬੀ', english: 'Punjabi', needsReview: false),
  'sa': (native: 'संस्कृतम्', english: 'Sanskrit', needsReview: false),
  'sat': (native: 'ᱥᱟᱱᱛᱟᱲᱤ', english: 'Santali', needsReview: true),
  'sd': (native: 'سنڌي', english: 'Sindhi', needsReview: false),
  'ta': (native: 'தமிழ்', english: 'Tamil', needsReview: false),
  'te': (native: 'తెలుగు', english: 'Telugu', needsReview: false),
  'ur': (native: 'اردو', english: 'Urdu', needsReview: false),
};
