#  MusicBoxSwift

Simplified interface for build music application. `MusicBox` uses a `MusicSession` as a variable. `MusicSession` is a protocol which have all required method need for a basic music application to work. By default `URLSession` conforms `MusicSession`, which implements all of its method using YouTube web API. It mimics the action you take on the web like browsing, searching, good song recommendations etc builtin inside this package. This is for learning purpose only.  

```swift
public struct MusicBox: Sendable {
  public let musicSession: MusicSession
  
  public init(musicSession: MusicSession = URLSession.shared) {
    self.musicSession = musicSession
  }
}
```

```swift
public protocol MusicSession: Sendable {
  func getHomeScreenMusicList() async -> [MusicItem]
  func getTypeAheadSearchResult(query: String) async -> [String]
  func getMusicSearchResults(query: String) async -> [MusicItem]
  func getMusicStreamingURL(musicId: String) async -> URL?
  func getNextSuggestedMusicItems(musicId: String) async -> [MusicItem]
}
```
### Code structure
- Models
Few client payload need to store inside CoreData to facilitate YouTube's song recommendation and searching. During request this payload used as to mimic a web client and get proper response and recommedation for future.

- URLSession+extensions
This is where all the `MusicSession` methods are implementated. Each file contain one or more methods. Few additional private methods are there to bootstrap the web mimic process i.e. getting payload data for a client to use during subsequent request.

 
