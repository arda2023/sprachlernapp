import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'dart:io';

import '../../data/offline_translation/offline_dictionary.dart';

final offlineDictionaryProvider = Provider<OfflineDictionary>(
  (ref) => OfflineDictionary(
    directory: () async => Directory(
      '${(await getApplicationSupportDirectory()).path}/offline_dictionary',
    ),
    asset: (name) async =>
        (await rootBundle.load('assets/offline_dictionary/$name')).buffer
            .asUint8List(),
  ),
);
