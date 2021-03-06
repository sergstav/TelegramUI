import Foundation
import AsyncDisplayKit
import Postbox
import Display
import TelegramCore
import SwiftSignalKit

private let titleFont: UIFont = {
    if #available(iOS 8.2, *) {
        return UIFont.systemFont(ofSize: 14.0, weight: UIFont.Weight.medium)
    } else {
        return CTFontCreateWithName("HelveticaNeue-Medium" as CFString, 14.0, nil)
    }
}()
private let textFont = Font.regular(14.0)

enum ChatMessageReplyInfoType {
    case bubble(incoming: Bool)
    case standalone
}

class ChatMessageReplyInfoNode: ASDisplayNode {
    private let contentNode: ASDisplayNode
    private let lineNode: ASImageNode
    private var titleNode: TextNode?
    private var textNode: TextNode?
    private var imageNode: TransformImageNode?
    private var overlayIconNode: ASImageNode?
    private var previousMediaReference: AnyMediaReference?
    
    override init() {
        self.contentNode = ASDisplayNode()
        self.contentNode.displaysAsynchronously = true
        self.contentNode.isLayerBacked = true
        self.contentNode.contentMode = .left
        self.contentNode.contentsScale = UIScreenScale
        
        self.lineNode = ASImageNode()
        self.lineNode.displaysAsynchronously = false
        self.lineNode.displayWithoutProcessing = true
        self.lineNode.isLayerBacked = true
        
        super.init()
        
        self.addSubnode(self.contentNode)
        self.contentNode.addSubnode(self.lineNode)
    }
    
    class func asyncLayout(_ maybeNode: ChatMessageReplyInfoNode?) -> (_ theme: PresentationTheme, _ strings: PresentationStrings, _ account: Account, _ type: ChatMessageReplyInfoType, _ message: Message, _ constrainedSize: CGSize) -> (CGSize, () -> ChatMessageReplyInfoNode) {
        
        let titleNodeLayout = TextNode.asyncLayout(maybeNode?.titleNode)
        let textNodeLayout = TextNode.asyncLayout(maybeNode?.textNode)
        let imageNodeLayout = TransformImageNode.asyncLayout(maybeNode?.imageNode)
        let previousMediaReference = maybeNode?.previousMediaReference
        
        return { theme, strings, account, type, message, constrainedSize in
            let titleString = message.author?.displayTitle ?? ""
            let (textString, isMedia) = descriptionStringForMessage(message, strings: strings, accountPeerId: account.peerId)
            
            let titleColor: UIColor
            let lineImage: UIImage?
            let textColor: UIColor
                
            switch type {
                case let .bubble(incoming):
                    titleColor = incoming ? theme.chat.bubble.incomingAccentTextColor : theme.chat.bubble.outgoingAccentTextColor
                    lineImage = incoming ? PresentationResourcesChat.chatBubbleVerticalLineIncomingImage(theme) : PresentationResourcesChat.chatBubbleVerticalLineOutgoingImage(theme)
                    if isMedia {
                        textColor = incoming ? theme.chat.bubble.incomingSecondaryTextColor : theme.chat.bubble.outgoingSecondaryTextColor
                    } else {
                        textColor = incoming ? theme.chat.bubble.incomingPrimaryTextColor : theme.chat.bubble.outgoingPrimaryTextColor
                    }
                case .standalone:
                    titleColor = theme.chat.serviceMessage.serviceMessagePrimaryTextColor
                    lineImage = PresentationResourcesChat.chatServiceVerticalLineImage(theme)
                    textColor = titleColor
            }
            
            var leftInset: CGFloat = 10.0
            
            var overlayIcon: UIImage?
            
            var updatedMediaReference: AnyMediaReference?
            var imageDimensions: CGSize?
            var hasRoundImage = false
            if !message.containsSecretMedia {
                for media in message.media {
                    if let image = media as? TelegramMediaImage {
                        updatedMediaReference = .message(message: MessageReference(message), media: image)
                        if let representation = largestRepresentationForPhoto(image) {
                            imageDimensions = representation.dimensions
                        }
                        break
                    } else if let file = media as? TelegramMediaFile, file.isVideo {
                        updatedMediaReference = .message(message: MessageReference(message), media: file)
                        
                        if let dimensions = file.dimensions {
                            imageDimensions = dimensions
                        } else if let representation = largestImageRepresentation(file.previewRepresentations), !file.isSticker {
                            imageDimensions = representation.dimensions
                        }
                        if !file.isInstantVideo && !file.isAnimated {
                            overlayIcon = PresentationResourcesChat.chatBubbleReplyThumbnailPlayImage(theme)
                        }
                        if file.isInstantVideo {
                            hasRoundImage = true
                        }
                        break
                    }
                }
            }
            
            var applyImage: (() -> TransformImageNode)?
            if let imageDimensions = imageDimensions {
                leftInset += 36.0
                let boundingSize = CGSize(width: 30.0, height: 30.0)
                var radius: CGFloat = 2.0
                var imageSize = imageDimensions.aspectFilled(boundingSize)
                if hasRoundImage {
                    radius = boundingSize.width / 2.0
                    imageSize.width += 2.0
                    imageSize.height += 2.0
                }
                applyImage = imageNodeLayout(TransformImageArguments(corners: ImageCorners(radius: radius), imageSize: imageSize, boundingSize: boundingSize, intrinsicInsets: UIEdgeInsets()))
            }
            
            var mediaUpdated = false
            if let updatedMediaReference = updatedMediaReference, let previousMediaReference = previousMediaReference {
                mediaUpdated = !updatedMediaReference.media.isEqual(to: previousMediaReference.media)
            } else if (updatedMediaReference != nil) != (previousMediaReference != nil) {
                mediaUpdated = true
            }
            
            var updateImageSignal: Signal<(TransformImageArguments) -> DrawingContext?, NoError>?
            if let updatedMediaReference = updatedMediaReference, mediaUpdated && imageDimensions != nil {
                if let imageReference = updatedMediaReference.concrete(TelegramMediaImage.self) {
                    updateImageSignal = chatMessagePhotoThumbnail(account: account, photoReference: imageReference)
                } else if let fileReference = updatedMediaReference.concrete(TelegramMediaFile.self) {
                    if fileReference.media.isVideo {
                        updateImageSignal = chatMessageVideoThumbnail(account: account, fileReference: fileReference)
                    } else if let iconImageRepresentation = smallestImageRepresentation(fileReference.media.previewRepresentations) {
                        updateImageSignal = chatWebpageSnippetFile(account: account, fileReference: fileReference, representation: iconImageRepresentation)
                    }
                }
            }
            
            let maximumTextWidth = max(0.0, constrainedSize.width - leftInset)
            
            let contrainedTextSize = CGSize(width: maximumTextWidth, height: constrainedSize.height)
            
            let (titleLayout, titleApply) = titleNodeLayout(TextNodeLayoutArguments(attributedString: NSAttributedString(string: titleString, font: titleFont, textColor: titleColor), backgroundColor: nil, maximumNumberOfLines: 1, truncationType: .end, constrainedSize: contrainedTextSize, alignment: .natural, cutout: nil, insets: UIEdgeInsets()))
            let (textLayout, textApply) = textNodeLayout(TextNodeLayoutArguments(attributedString: NSAttributedString(string: textString, font: textFont, textColor: textColor), backgroundColor: nil, maximumNumberOfLines: 1, truncationType: .end, constrainedSize: contrainedTextSize, alignment: .natural, cutout: nil, insets: UIEdgeInsets()))
            
            let size = CGSize(width: max(titleLayout.size.width, textLayout.size.width) + leftInset, height: titleLayout.size.height + textLayout.size.height)
            
            return (size, {
                let node: ChatMessageReplyInfoNode
                if let maybeNode = maybeNode {
                    node = maybeNode
                } else {
                    node = ChatMessageReplyInfoNode()
                }
                
                node.previousMediaReference = updatedMediaReference
                
                let titleNode = titleApply()
                let textNode = textApply()
                
                if node.titleNode == nil {
                    titleNode.isLayerBacked = true
                    node.titleNode = titleNode
                    node.contentNode.addSubnode(titleNode)
                }
                
                if node.textNode == nil {
                    textNode.isLayerBacked = true
                    node.textNode = textNode
                    node.contentNode.addSubnode(textNode)
                }
                
                var imageFrame: CGRect?
                if let applyImage = applyImage {
                    let imageNode = applyImage()
                    if node.imageNode == nil {
                        imageNode.isLayerBacked = true
                        node.addSubnode(imageNode)
                        node.imageNode = imageNode
                    }
                    imageFrame = CGRect(origin: CGPoint(x: 8.0, y: 3.0), size: CGSize(width: 30.0, height: 30.0))
                    imageNode.frame = CGRect(origin: CGPoint(x: 8.0, y: 3.0), size: CGSize(width: 30.0, height: 30.0))
                    
                    if let updateImageSignal = updateImageSignal {
                        imageNode.setSignal(updateImageSignal)
                    }
                } else if let imageNode = node.imageNode {
                    imageNode.removeFromSupernode()
                    node.imageNode = nil
                }
                
                if let overlayIcon = overlayIcon, let imageFrame = imageFrame {
                    let overlayIconNode: ASImageNode
                    if let current = node.overlayIconNode {
                        overlayIconNode = current
                    } else {
                        overlayIconNode = ASImageNode()
                        overlayIconNode.isLayerBacked = true
                        overlayIconNode.displayWithoutProcessing = true
                        overlayIconNode.displaysAsynchronously = false
                        node.overlayIconNode = overlayIconNode
                        node.addSubnode(overlayIconNode)
                    }
                    overlayIconNode.image = overlayIcon
                    overlayIconNode.frame = CGRect(origin: CGPoint(x: imageFrame.minX + floor((imageFrame.size.width - overlayIcon.size.width) / 2.0), y: imageFrame.minY + floor((imageFrame.size.height - overlayIcon.size.height) / 2.0)), size: overlayIcon.size)
                } else if let overlayIconNode = node.overlayIconNode {
                    overlayIconNode.removeFromSupernode()
                    node.overlayIconNode = nil
                }
                
                titleNode.frame = CGRect(origin: CGPoint(x: leftInset, y: 0.0), size: titleLayout.size)
                textNode.frame = CGRect(origin: CGPoint(x: leftInset, y: titleLayout.size.height), size: textLayout.size)
                
                node.lineNode.image = lineImage
                node.lineNode.frame = CGRect(origin: CGPoint(x: 1.0, y: 3.0), size: CGSize(width: 2.0, height: max(0.0, size.height - 4.0)))
                
                node.contentNode.frame = CGRect(origin: CGPoint(), size: size)
                
                return node
            })
        }
    }
}
