import Testing
@testable import YoutubeInterface


@Test("Getting homescreen music items")
func TestGetHomescreenMusicItems() async throws {
  let yti = YoutubeInterface()
  let result = await yti.musicSession.getHomeScreenMusicList()
  #expect(result.count > 0)
}

@Test("Getting search result suggestion for query")
func TestGetTypeAheadSearchResult() async throws {
  let yti = YoutubeInterface()
  let result = await yti.musicSession.getTypeAheadSearchResult(query: "songs")
  #expect(!result.isEmpty)
}

@Test("Getting music search results for query")
func TestGetMusicSearchResults() async throws {
  let yti = YoutubeInterface()
  let result = await yti.musicSession.getMusicSearchResults(query: "odia songs")
  #expect(!result.isEmpty)
  #expect(result.first?.title != nil)
  #expect(result.first?.largestThumbnail != nil)
  #expect(result.first?.smallestThumbnail != nil)
  #expect(result.first?.musicId != nil)
  #expect(result.first?.runningDurationInSeconds != nil)
  #expect(result.first?.publisherTitle != nil)
}

@Test("Getting streaming URL for a music")
func TestGetMusicStreamingURL() async {
  let yti = YoutubeInterface()
  await yti.musicSession.getMusicStreamingURL(musicId: "c3XOtUOdxlE")
}
