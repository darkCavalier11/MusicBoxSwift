import Testing
@testable import YoutubeInterface


@Test
func TestbuildRequestHeader() async throws {
  let yti = YoutubeInterface()
  let result = await yti.internalConfigurationRequestManager.getRequestHeader()
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
