import Foundation
import Display
import AsyncDisplayKit
import TelegramCore
import SwiftSignalKit
import Postbox

final class BotCheckoutController: ViewController {
    private var controllerNode: BotCheckoutControllerNode {
        return self.displayNode as! BotCheckoutControllerNode
    }
    
    private let _ready = Promise<Bool>()
    override var ready: Promise<Bool> {
        return self._ready
    }
    
    private let account: Account
    private let invoice: TelegramMediaInvoice
    private let messageId: MessageId
    
    private var presentationData: PresentationData
    
    private var didPlayPresentationAnimation = false
    
    init(account: Account, invoice: TelegramMediaInvoice, messageId: MessageId) {
        self.account = account
        self.invoice = invoice
        self.messageId = messageId
        
        self.presentationData = account.telegramApplicationContext.currentPresentationData.with { $0 }
        
        super.init(navigationBarPresentationData: NavigationBarPresentationData(presentationData: self.presentationData))
        
        self.statusBar.statusBarStyle = self.presentationData.theme.rootController.statusBar.style.style
        
        var title = self.presentationData.strings.Checkout_Title
        if invoice.flags.contains(.isTest) {
            title += " (Test)"
        }
        self.title = title
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: self.presentationData.strings.Common_Cancel, style: .plain, target: self, action: #selector(self.cancelPressed))
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadDisplayNode() {
        let displayNode = BotCheckoutControllerNode(navigationBar: self.navigationBar!, updateNavigationOffset: { [weak self] offset in
            if let strongSelf = self {
                strongSelf.navigationOffset = offset
            }
        }, account: self.account, invoice: self.invoice, messageId: self.messageId, present: { [weak self] c, a in
            self?.present(c, in: .window(.root), with: a)
        }, dismissAnimated: { [weak self] in
            self?.dismiss()
        })
        
        //displayNode.enableInteractiveDismiss = true
        
        displayNode.dismiss = { [weak self] in
            self?.presentingViewController?.dismiss(animated: false, completion: nil)
        }
        
        self.displayNode = displayNode
        super.displayNodeDidLoad()
        self._ready.set(displayNode.ready)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let presentationArguments = self.presentationArguments as? ViewControllerPresentationArguments, !self.didPlayPresentationAnimation {
            self.didPlayPresentationAnimation = true
            if case .modalSheet = presentationArguments.presentationAnimation {
                self.controllerNode.animateIn()
            }
        }
    }
    
    override public func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)
        
        self.controllerNode.containerLayoutUpdated(layout, navigationBarHeight: self.navigationHeight, transition: transition)
    }
    
    override func dismiss(completion: (() -> Void)? = nil) {
        self.controllerNode.animateOut(completion: completion)
    }
    
    @objc func cancelPressed() {
        self.dismiss()
    }
}
