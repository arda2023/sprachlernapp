/// Presentation-only artwork keys. Library IDs and content packs stay unchanged.
/// Only inventoried stories may use generated artwork; no category-wide image
/// or guessed title match is used for unknown stories.
String? storyCoverAssetKey(String storyId, String topic) {
  if (topic == 'Alltag' || topic == 'Wirtschaft') return null;
  final parts = storyId.split(':');
  if (parts.length != 3 ||
      parts[0] != 'library' ||
      !_languages.contains(parts[1]) ||
      !_artwork.contains(parts[2])) {
    return null;
  }
  return 'assets/story_covers/${parts[2]}.png';
}

const _languages = {'en', 'es', 'it', 'nb', 'pt-BR'};
const _artwork = {
  'video_04',
  'video_05',
  'video_06',
  'video_10',
  'video_11',
  'video_12',
  'video_13',
  'video_14',
  'video_15',
  'video_16',
  'video_19',
  'video_20',
  'video_21',
  'video_22',
  'video_23',
  'video_24',
  'video_25',
  'video_26',
  'video_27',
  'video_28',
  'video_29',
  'video_30',
  'video_31',
  'video_32',
  'video_33',
  'video_34',
  'video_35',
  'video_36',
  'video_38',
  'video_39',
  'video_40',
  'travel_01',
  'travel_02',
  'travel_03',
  'travel_04',
  'travel_05',
  'restaurant_01',
  'restaurant_02',
  'restaurant_03',
  'restaurant_04',
  'restaurant_05',
  'work_01',
  'work_02',
  'work_03',
};
