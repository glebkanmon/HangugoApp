import Foundation

/// Composition root for the app.
///
/// The container owns factories for stateful services (SRS/Known/SelectedTags) so that
/// each feature can work with its own in-memory instance while persisting to the same storage.
final class AppContainer {

    // MARK: - Core

    let wordsLoader: WordsLoading

    // MARK: - Factories

    private let makeSRSStore: () -> SRSStore
    private let makeKnownStore: () -> KnownWordsStore
    private let makeSelectedTagsStore: () -> SelectedTagsStore

    let makeLLMProvider: () -> LLMProvider
    let speechService: SpeechService

    // MARK: - Init

    init(
        wordsLoader: WordsLoading = BundledWordsLoaderAdapter(),
        makeSRSStore: @escaping () -> SRSStore = { FileSRSStore() },
        makeKnownStore: @escaping () -> KnownWordsStore = { FileKnownWordsStore() },
        makeSelectedTagsStore: @escaping () -> SelectedTagsStore = { FileSelectedTagsStore() },
        makeLLMProvider: @escaping () -> LLMProvider = { DeepSeekProviderDirect(apiKey: Secrets.deepSeekApiKey) },
        speechService: SpeechService = .shared
    ) {
        self.wordsLoader = wordsLoader
        self.makeSRSStore = makeSRSStore
        self.makeKnownStore = makeKnownStore
        self.makeSelectedTagsStore = makeSelectedTagsStore
        self.makeLLMProvider = makeLLMProvider
        self.speechService = speechService
    }

    // MARK: - Feature services

    func makeSRSService() -> SRSService {
        SRSService(store: makeSRSStore())
    }

    func makeKnownWordsService() -> KnownWordsService {
        KnownWordsService(store: makeKnownStore())
    }

    func makeSelectedTagsService() -> SelectedTagsService {
        SelectedTagsService(store: makeSelectedTagsStore())
    }
}
