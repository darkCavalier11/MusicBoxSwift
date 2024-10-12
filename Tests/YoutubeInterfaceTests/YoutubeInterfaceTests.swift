import Testing
@testable import YoutubeInterface


@Test("Building request payload")
func TestBuildRequestPayload() async throws {
  let yti = YoutubeInterface()
  let header = await yti.musicSession.getClientRequestPayload()
  #expect(header != nil)
  
  let context = (header?["context"] as? [String: Any])
  #expect(context != nil)
  
  let client = context?["client"] as? [String: Any]
  #expect(client != nil)
  let visitorData = client?["visitorData"]
  #expect(visitorData != nil)
}

@Test("Getting homescreen music items")
func TestGetHomescreenMusicItems() async throws {
  let yti = YoutubeInterface()
  let result = await yti.musicSession.getHomeScreenMusicList()
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
