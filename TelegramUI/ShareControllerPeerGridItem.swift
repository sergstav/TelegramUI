import Foundation
import Display
import TelegramCore
import SwiftSignalKit
import AsyncDisplayKit
import Postbox

final class ShareControllerInteraction {
    var selectedPeerIds = Set<PeerId>()
    var selectedPeers: [Peer] = []
    let togglePeer: (Peer) -> Void
    
    init(togglePeer: @escaping (Peer) -> Void) {
        self.togglePeer = togglePeer
    }
}

final class ShareControllerGridSection: GridSection {
    let height: CGFloat = 33.0
    
    private let title: String
    
    var hashValue: Int {
        return 1
    }
    
    init(title: String) {
        self.title = title
    }
    
    func isEqual(to: GridSection) -> Bool {
        if let to = to as? ShareControllerGridSection {
            return self.title == to.title
        } else {
            return false
        }
    }
    
    func node() -> ASDisplayNode {
        return ShareControllerGridSectionNode(title: self.title)
    }
}

private let sectionTitleFont = Font.medium(12.0)

final class ShareControllerGridSectionNode: ASDisplayNode {
    let backgroundNode: ASDisplayNode
    let titleNode: ASTextNode
    
    init(title: String) {
        self.backgroundNode = ASDisplayNode()
        self.backgroundNode.isLayerBacked = true
        self.backgroundNode.backgroundColor = UIColor(rgb: 0xf7f7f7)
        
        self.titleNode = ASTextNode()
        self.titleNode.isLayerBacked = true
        self.titleNode.attributedText = NSAttributedString(string: title.uppercased(), font: sectionTitleFont, textColor: UIColor(rgb: 0x8e8e93))
        self.titleNode.maximumNumberOfLines = 1
        self.titleNode.truncationMode = .byTruncatingTail
        
        super.init()
        
        self.addSubnode(self.backgroundNode)
        self.addSubnode(self.titleNode)
    }
    
    override func layout() {
        super.layout()
        
        let bounds = self.bounds
        
        self.backgroundNode.frame = CGRect(origin: CGPoint(x: 0.0, y: 0.0), size: CGSize(width: bounds.size.width, height: 27.0))
        
        let titleSize = self.titleNode.measure(CGSize(width: bounds.size.width - 24.0, height: CGFloat.greatestFiniteMagnitude))
        self.titleNode.frame = CGRect(origin: CGPoint(x: 9.0, y: 6.0), size: titleSize)
    }
}

final class ShareControllerPeerGridItem: GridItem {
    let account: Account
    let peer: Peer
    let chatPeer: Peer?
    let controllerInteraction: ShareControllerInteraction
    
    let section: GridSection?
    
    init(account: Account, peer: Peer, chatPeer: Peer?, controllerInteraction: ShareControllerInteraction, sectionTitle: String? = nil) {
        self.account = account
        self.peer = peer
        self.chatPeer = chatPeer
        self.controllerInteraction = controllerInteraction
        
        if let sectionTitle = sectionTitle {
            self.section = ShareControllerGridSection(title: sectionTitle)
        } else {
            self.section = nil
        }
    }
    
    func node(layout: GridNodeLayout) -> GridItemNode {
        let node = ShareControllerPeerGridItemNode()
        node.controllerInteraction = self.controllerInteraction
        node.setup(account: self.account, peer: self.peer, chatPeer: self.chatPeer)
        return node
    }
    
    func update(node: GridItemNode) {
        guard let node = node as? ShareControllerPeerGridItemNode else {
            assertionFailure()
            return
        }
        node.controllerInteraction = self.controllerInteraction
        node.setup(account: self.account, peer: self.peer, chatPeer: self.chatPeer)
    }
}

final class ShareControllerPeerGridItemNode: GridItemNode {
    private var currentState: (Account, Peer, Peer?)?
    private let peerNode: SelectablePeerNode
    
    var controllerInteraction: ShareControllerInteraction?
    
    override init() {
        self.peerNode = SelectablePeerNode()
        
        super.init()
        
        self.peerNode.toggleSelection = { [weak self] in
            if let strongSelf = self {
                if let (_, peer, chatPeer) = strongSelf.currentState {
                    let mainPeer = chatPeer ?? peer
                    strongSelf.controllerInteraction?.togglePeer(mainPeer)
                }
            }
        }
        self.addSubnode(self.peerNode)
    }
    
    func setup(account: Account, peer: Peer, chatPeer: Peer?) {
        if self.currentState == nil || self.currentState!.0 !== account || !arePeersEqual(self.currentState!.1, peer) {
            self.peerNode.setup(account: account, peer: peer, chatPeer: chatPeer)
            self.currentState = (account, peer, chatPeer)
            self.setNeedsLayout()
        }
        self.updateSelection(animated: false)
    }
    
    func updateSelection(animated: Bool) {
        var selected = false
        if let controllerInteraction = self.controllerInteraction, let (_, peer, chatPeer) = self.currentState {
            let mainPeer = chatPeer ?? peer
            selected = controllerInteraction.selectedPeerIds.contains(mainPeer.id)
        }
        
        self.peerNode.updateSelection(selected: selected, animated: animated)
    }
    
    override func layout() {
        super.layout()
        
        let bounds = self.bounds
        self.peerNode.frame = bounds
    }
    
    func animateIn() {
        self.peerNode.layer.animatePosition(from: CGPoint(x: 0.0, y: 60.0), to: CGPoint(), duration: 0.42, timingFunction: kCAMediaTimingFunctionSpring, additive: true)
    }
}