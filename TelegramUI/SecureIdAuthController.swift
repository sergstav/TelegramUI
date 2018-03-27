import Foundation
import Display
import AsyncDisplayKit
import SwiftSignalKit
import Postbox
import TelegramCore

final class SecureIdAuthControllerInteraction {
    let updateState: ((SecureIdAuthControllerState) -> SecureIdAuthControllerState) -> Void
    let present: (ViewController, Any?) -> Void
    let checkPassword: (String) -> Void
    
    fileprivate init(updateState: @escaping ((SecureIdAuthControllerState) -> SecureIdAuthControllerState) -> Void, present: @escaping (ViewController, Any?) -> Void, checkPassword: @escaping (String) -> Void) {
        self.updateState = updateState
        self.present = present
        self.checkPassword = checkPassword
    }
}

final class SecureIdAuthController: ViewController {
    private var controllerNode: SecureIdAuthControllerNode {
        return self.displayNode as! SecureIdAuthControllerNode
    }
    
    private let account: Account
    private var presentationData: PresentationData
    
    private var didPlayPresentationAnimation = false
    
    private let challengeDisposable = MetaDisposable()
    private var formDisposable: Disposable?
    
    private var state: SecureIdAuthControllerState
    
    private let hapticFeedback = HapticFeedback()
    
    init(account: Account, peerId: PeerId, scope: String, publicKey: String) {
        self.account = account
        self.presentationData = account.telegramApplicationContext.currentPresentationData.with { $0 }
        
        self.state = SecureIdAuthControllerState(encryptedFormData: nil, formData: nil, verificationState: nil)
        
        super.init(navigationBarPresentationData: NavigationBarPresentationData(presentationData: self.presentationData))
        
        self.statusBar.statusBarStyle = self.presentationData.theme.rootController.statusBar.style.style
        
        self.title = self.presentationData.strings.SecureId_Title
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: self.presentationData.strings.Common_Cancel, style: .plain, target: self, action: #selector(self.cancelPressed))
        
        self.challengeDisposable.set((twoStepAuthData(account.network)
        |> deliverOnMainQueue).start(next: { [weak self] data in
            if let strongSelf = self {
                strongSelf.updateState { state in
                    var state = state
                    if data.currentSalt != nil {
                        state.verificationState = .passwordChallenge(.none)
                    } else {
                        state.verificationState = .noChallenge
                    }
                    return state
                }
            }
        }))
        
        self.formDisposable = (requestSecureIdForm(postbox: account.postbox, network: account.network, peerId: peerId, scope: scope, publicKey: publicKey)
        |> mapToSignal { form -> Signal<SecureIdEncryptedFormData, RequestSecureIdFormError> in
            return account.postbox.modify { modifier -> Signal<SecureIdEncryptedFormData, RequestSecureIdFormError> in
                guard let accountPeer = modifier.getPeer(account.peerId), let servicePeer = modifier.getPeer(form.peerId) else {
                    return .fail(.generic)
                }
                return .single(SecureIdEncryptedFormData(form: form, accountPeer: accountPeer, servicePeer: servicePeer))
            }
            |> mapError { _ in return RequestSecureIdFormError.generic }
            |> switchToLatest
        }
        |> deliverOnMainQueue).start(next: { [weak self] formData in
            if let strongSelf = self {
                strongSelf.updateState { state in
                    var state = state
                    state.encryptedFormData = formData
                    return state
                }
            }
        }, error: { [weak self] _ in
            if let strongSelf = self {
                let errorText = strongSelf.presentationData.strings.Login_UnknownError
                strongSelf.present(standardTextAlertController(theme: AlertControllerTheme(presentationTheme: strongSelf.presentationData.theme), title: nil, text: errorText, actions: [TextAlertAction(type: .defaultAction, title: strongSelf.presentationData.strings.Common_OK, action: {})]), in: .window(.root))
            }
        })
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self.challengeDisposable.dispose()
        self.formDisposable?.dispose()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !self.didPlayPresentationAnimation {
            self.didPlayPresentationAnimation = true
            self.controllerNode.animateIn()
        }
    }
    
    override func dismiss(completion: (() -> Void)? = nil) {
        self.controllerNode.animateOut(completion: { [weak self] in
            self?.presentingViewController?.dismiss(animated: false, completion: nil)
            completion?()
        })
    }
    
    override func loadDisplayNode() {
        let interaction = SecureIdAuthControllerInteraction(updateState: { [weak self] f in
            self?.updateState(f)
        }, present: { [weak self] c, a in
            self?.present(c, in: .window(.root), with: a)
        }, checkPassword: { [weak self] password in
            if let strongSelf = self {
                if let verificationState = strongSelf.state.verificationState, case let .passwordChallenge(challengeState) = verificationState {
                    switch challengeState {
                        case .none, .invalid:
                            break
                        case .checking:
                            return
                    }
                    strongSelf.updateState { state in
                        var state = state
                        state.verificationState = .passwordChallenge(.checking)
                        return state
                    }
                    strongSelf.challengeDisposable.set((accessSecureId(network: strongSelf.account.network, password: password)
                    |> deliverOnMainQueue).start(next: { context in
                        if let strongSelf = self, let verificationState = strongSelf.state.verificationState, case .passwordChallenge(.checking) = verificationState {
                            strongSelf.updateState { state in
                                var state = state
                                state.verificationState = .verified(context)
                                state.formData = state.encryptedFormData.flatMap({ decryptedSecureIdForm(context: context, form: $0.form) })
                                return state
                            }
                        }
                    }, error: { error in
                        if let strongSelf = self {
                            let errorText: String
                            switch error {
                                case let .passwordError(passwordError):
                                    switch passwordError {
                                        case .invalidPassword:
                                            errorText = strongSelf.presentationData.strings.LoginPassword_InvalidPasswordError
                                        case .limitExceeded:
                                            errorText = strongSelf.presentationData.strings.LoginPassword_FloodError
                                        case .generic:
                                            errorText = strongSelf.presentationData.strings.Login_UnknownError
                                    }
                                case .generic:
                                    errorText = strongSelf.presentationData.strings.Login_UnknownError
                                case .secretPasswordMismatch:
                                    errorText = strongSelf.presentationData.strings.Login_UnknownError
                            }
                            strongSelf.present(standardTextAlertController(theme: AlertControllerTheme(presentationTheme: strongSelf.presentationData.theme), title: nil, text: errorText, actions: [TextAlertAction(type: .defaultAction, title: strongSelf.presentationData.strings.Common_OK, action: {})]), in: .window(.root))
                            
                            if let verificationState = strongSelf.state.verificationState, case .passwordChallenge(.checking) = verificationState {
                                strongSelf.updateState { state in
                                    var state = state
                                    state.verificationState = .passwordChallenge(.invalid)
                                    return state
                                }
                            }
                        }
                    }))
                }
            }
        })
        
        self.displayNode = SecureIdAuthControllerNode(account: self.account, presentationData: presentationData, requestLayout: { [weak self] transition in
            self?.requestLayout(transition: transition)
        }, interaction: interaction)
        self.controllerNode.updateState(self.state, transition: .immediate)
    }
    
    override func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)
        
        self.controllerNode.containerLayoutUpdated(layout, navigationBarHeight: self.navigationHeight, transition: transition)
    }
    
    private func updateState(_ f: (SecureIdAuthControllerState) -> SecureIdAuthControllerState) {
        let state = f(self.state)
        if state != self.state {
            var previousHadProgress = false
            if let verificationState = self.state.verificationState, case .passwordChallenge(.checking) = verificationState {
                previousHadProgress = true
            }
            var updatedHasProgress = false
            if let verificationState = state.verificationState, case .passwordChallenge(.checking) = verificationState {
                updatedHasProgress = true
            }
            
            self.state = state
            if self.isNodeLoaded {
                self.controllerNode.updateState(self.state, transition: .animated(duration: 0.3, curve: .spring))
            }
            
            if previousHadProgress != updatedHasProgress {
                if updatedHasProgress {
                    let item = UIBarButtonItem(customDisplayNode: ProgressNavigationButtonNode(theme: self.presentationData.theme))
                    self.navigationItem.rightBarButtonItem = item
                } else {
                    self.navigationItem.rightBarButtonItem = nil
                }
            }
        }
    }
    
    @objc private func cancelPressed() {
        self.dismiss()
    }
}