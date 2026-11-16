const _editorialLanguages = {'en', 'es', 'it', 'nb', 'pt-BR'};

String freeLinglossaStoryId(String language) => 'library:$language:linglossa';

/// The same free editorial story across the supported learning languages.
bool isFreeStoryId(String id) =>
    _editorialLanguages.any((language) => freeLinglossaStoryId(language) == id);
