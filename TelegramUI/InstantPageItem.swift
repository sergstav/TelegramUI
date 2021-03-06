import Foundation
import Postbox
import TelegramCore
import AsyncDisplayKit

protocol InstantPageItem {
    var frame: CGRect { get set }
    var wantsNode: Bool { get }
    var medias: [InstantPageMedia] { get }
    
    func matchesAnchor(_ anchor: String) -> Bool
    func drawInTile(context: CGContext)
    func node(account: Account, strings: PresentationStrings, theme: InstantPageTheme, openMedia: @escaping (InstantPageMedia) -> Void, openPeer: @escaping (PeerId) -> Void) -> (InstantPageNode & ASDisplayNode)?
    func matchesNode(_ node: InstantPageNode) -> Bool
    func linkSelectionRects(at point: CGPoint) -> [CGRect]
    
    func distanceThresholdGroup() -> Int?
    func distanceThresholdWithGroupCount(_ count: Int) -> CGFloat
}
