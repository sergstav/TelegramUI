import Foundation
import Display

private func generateShareButtonImage(theme: PresentationTheme) -> UIImage? {
    return generateTintedImage(image: UIImage(bundleImageName: "Chat List/NavigationShare"), color: theme.rootController.navigationBar.accentTextColor)
}

func generateIndefiniteActivityIndicatorImage(color: UIColor, diameter: CGFloat = 22.0) -> UIImage? {
    return generateImage(CGSize(width: diameter, height: diameter), rotatedContext: { size, context in
        context.clear(CGRect(origin: CGPoint(), size: size))
        context.setFillColor(color.cgColor)
        let _ = try? drawSvgPath(context, path: "M11,22 C17.0751322,22 22,17.0751322 22,11 C22,4.92486775 17.0751322,0 11,0 C4.92486775,0 0,4.92486775 0,11 C0,12.4564221 0.28362493,13.8747731 0.827833595,15.1935223 C1.00609922,15.6255031 1.50080164,15.8311798 1.93278238,15.6529142 C2.36476311,15.4746485 2.57043984,14.9799461 2.39217421,14.5479654 C1.93209084,13.4330721 1.69230769,12.233965 1.69230769,11 C1.69230769,5.85950348 5.85950348,1.69230769 11,1.69230769 C16.1404965,1.69230769 20.3076923,5.85950348 20.3076923,11 C20.3076923,16.1404965 16.1404965,20.3076923 11,20.3076923 C10.5326821,20.3076923 10.1538462,20.6865283 10.1538462,21.1538462 C10.1538462,21.621164 10.5326821,22 11,22 Z ")
    })
}

struct PresentationResourcesRootController {
    static func navigationIndefiniteActivityImage(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.rootNavigationIndefiniteActivity.rawValue, { theme in
            generateIndefiniteActivityIndicatorImage(color: theme.rootController.navigationBar.accentTextColor)
        })
    }
    
    static func tabContactsIcon(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.rootTabContactsIcon.rawValue, { theme in
            return generateTintedImage(image: UIImage(bundleImageName: "Chat List/Tabs/IconContacts"), color: theme.rootController.tabBar.iconColor)
        })
    }
    
    static func tabContactsSelectedIcon(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.rootTabContactsSelectedIcon.rawValue, { theme in
            return generateTintedImage(image: UIImage(bundleImageName: "Chat List/Tabs/IconContactsSelected"), color: theme.rootController.tabBar.selectedIconColor)
        })
    }
    
    static func tabChatsIcon(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.rootTabChatsIcon.rawValue, { theme in
            return generateTintedImage(image: UIImage(bundleImageName: "Chat List/Tabs/IconChats"), color: theme.rootController.tabBar.iconColor)
        })
    }
    
    static func tabChatsSelectedIcon(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.rootTabChatsSelectedIcon.rawValue, { theme in
            return generateTintedImage(image: UIImage(bundleImageName: "Chat List/Tabs/IconChatsSelected"), color: theme.rootController.tabBar.selectedIconColor)
        })
    }
    
    static func tabSettingsIcon(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.rootTabSettingsIcon.rawValue, { theme in
            return generateTintedImage(image: UIImage(bundleImageName: "Chat List/Tabs/IconSettings"), color: theme.rootController.tabBar.iconColor)
        })
    }
    
    static func tabSettingsSelectedIcon(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.rootTabSettingsSelectedIcon.rawValue, { theme in
            return generateTintedImage(image: UIImage(bundleImageName: "Chat List/Tabs/IconSettingsSelected"), color: theme.rootController.tabBar.selectedIconColor)
        })
    }
    
    static func navigationComposeIcon(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.navigationComposeIcon.rawValue, { theme in
            return generateTintedImage(image: UIImage(bundleImageName: "Chat List/ComposeIcon"), color: theme.rootController.navigationBar.accentTextColor)
        })
    }
    
    static func navigationShareIcon(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.navigationShareIcon.rawValue, generateShareButtonImage)
    }
    
    static func navigationCallIcon(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.navigationCallIcon.rawValue, { theme in
            return generateTintedImage(image: UIImage(bundleImageName: "Chat/Info/CallButton"), color: theme.rootController.navigationBar.accentTextColor)
        })
    }
    
    static func navigationPlayerCloseButton(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.navigationPlayerCloseButton.rawValue, { theme in
            return generateImage(CGSize(width: 12.0, height: 12.0), contextGenerator: { size, context in
                context.clear(CGRect(origin: CGPoint(), size: size))
                context.setStrokeColor(theme.rootController.navigationBar.controlColor.cgColor)
                context.setLineWidth(2.0)
                context.setLineCap(.round)
                context.move(to: CGPoint(x: 1.0, y: 1.0))
                context.addLine(to: CGPoint(x: size.width - 1.0, y: size.height - 1.0))
                context.strokePath()
                context.move(to: CGPoint(x: size.width - 1.0, y: 1.0))
                context.addLine(to: CGPoint(x: 1.0, y: size.height - 1.0))
                context.strokePath()
            })
        })
    }
    
    static func navigationPlayerPlayIcon(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.navigationPlayerPlayIcon.rawValue, { theme in
            return generateTintedImage(image: UIImage(bundleImageName: "GlobalMusicPlayer/MinimizedPlay"), color: theme.rootController.navigationBar.accentTextColor)
        })
    }
    
    static func navigationPlayerPauseIcon(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.navigationPlayerPauseIcon.rawValue, { theme in
            return generateTintedImage(image: UIImage(bundleImageName: "GlobalMusicPlayer/MinimizedPause"), color: theme.rootController.navigationBar.accentTextColor)
        })
    }
    
    static func navigationPlayerMaximizedPlayIcon(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.navigationPlayerMaximizedPlayIcon.rawValue, { theme in
            return generateTintedImage(image: UIImage(bundleImageName: "GlobalMusicPlayer/Play"), color: theme.rootController.navigationBar.primaryTextColor)
        })
    }
    
    static func navigationPlayerMaximizedPauseIcon(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.navigationPlayerMaximizedPauseIcon.rawValue, { theme in
            return generateTintedImage(image: UIImage(bundleImageName: "GlobalMusicPlayer/Pause"), color: theme.rootController.navigationBar.primaryTextColor)
        })
    }
    
    static func navigationPlayerMaximizedPreviousIcon(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.navigationPlayerMaximizedPreviousIcon.rawValue, { theme in
            return generateTintedImage(image: UIImage(bundleImageName: "GlobalMusicPlayer/Previous"), color: theme.rootController.navigationBar.primaryTextColor)
        })
    }
    
    static func navigationPlayerMaximizedNextIcon(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.navigationPlayerMaximizedNextIcon.rawValue, { theme in
            return generateTintedImage(image: UIImage(bundleImageName: "GlobalMusicPlayer/Next"), color: theme.rootController.navigationBar.primaryTextColor)
        })
    }
    
    static func navigationPlayerMaximizedShuffleIcon(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.navigationPlayerMaximizedShuffleIcon.rawValue, { theme in
            return generateTintedImage(image: UIImage(bundleImageName: "GlobalMusicPlayer/Shuffle"), color: theme.rootController.navigationBar.primaryTextColor)
        })
    }
    
    static func navigationPlayerMaximizedRepeatIcon(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.navigationPlayerMaximizedRepeatIcon.rawValue, { theme in
            return generateTintedImage(image: UIImage(bundleImageName: "GlobalMusicPlayer/Repeat"), color: theme.rootController.navigationBar.primaryTextColor)
        })
    }
    
    static func navigationPlayerHandleIcon(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.navigationPlayerHandleIcon.rawValue, { theme in
            return generateStretchableFilledCircleImage(diameter: 7.0, color: theme.rootController.navigationBar.controlColor)
        })
    }
}