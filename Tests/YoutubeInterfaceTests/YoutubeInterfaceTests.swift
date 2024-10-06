import Testing
@testable import YoutubeInterface


@Test("Building request payload")
func TestBuildRequestPayload() async throws {
  let yti = YoutubeInterface()
  let header = await yti.musicSession.getRequestPayload()
  #expect(header != nil)
  let musicContinuationKey = header?["continuation"]
  #expect(musicContinuationKey != nil)
  
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
