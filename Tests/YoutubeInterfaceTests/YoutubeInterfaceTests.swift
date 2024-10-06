import Testing
@testable import YoutubeInterface


@Test("Building request payload")
func TestBuildRequestPayload() async throws {
  let yti = YoutubeInterface()
  let result = await yti.musicSession.getRequestPayload()
  #expect(result != nil)
  
  switch result {
  case .success(let header):
    #expect(header != nil)
    let musicContinuationKey = header["continuation"]
    #expect(musicContinuationKey != nil)
    
    let context = (header["context"] as? [String: Any])
    #expect(context != nil)
    
    let client = context?["client"] as? [String: Any]
    #expect(client != nil)
    let visitorData = client?["visitorData"]
    #expect(visitorData != nil)
    
  case .failure(let error):
    #expect(error != nil)
  }
}

@Test("Getting homescreen music items")
func TestGetHomescreenMusicItems() async throws {
  let yti = YoutubeInterface()
  let result = await yti.musicSession.getHomeScreenMusicList()
}
