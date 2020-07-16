//
//  SystemFont.swift
//  Scroll Data
//
//  Created by Aydemir on 11/26/18.
//  Copyright © 2018 Arman Aydemir. All rights reserved.
//

import UIKit

class SystemFont {
    
    private let basicFont: UIFont
    
    init?(fontName: String){
        guard let font = UIFont(name: fontName, size: UIFont.systemFontSize)
            else { return nil }
        self.basicFont = font
    }
    
    func getFont(withTextStyle textStyle: UIFont.TextStyle) -> UIFont?{
        let style = UIFont.preferredFont(forTextStyle: textStyle)
        guard let des = self.basicFont.fontDescriptor.withSymbolicTraits(style.fontDescriptor.symbolicTraits) else { return nil }
        return UIFont.init(descriptor: des, size: style.pointSize)
    }
    
    func fontToFit(text: String, inSize size: CGSize, spacing: CGFloat) -> UIFont {
        let constraintRect = CGSize(width: size.width, height: .greatestFiniteMagnitude)
        var font_size = self.basicFont.pointSize
        var attributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: self.basicFont]
        var aString = NSAttributedString.init(string: text, attributes: attributes)
        var boundingBox = aString.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, context: nil)
        var font = UIFont.init(descriptor: self.basicFont.fontDescriptor, size: font_size)
        while ceil(boundingBox.height) <= size.height {
            font_size += 0.1
            font = UIFont.init(descriptor: self.basicFont.fontDescriptor, size: font_size)
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = spacing
            attributes = [NSAttributedString.Key.font: font, NSAttributedString.Key.paragraphStyle: paragraphStyle]
            aString = NSAttributedString.init(string: text, attributes: attributes)
            boundingBox = aString.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, context: nil)
        }
        return font
    }
    
    func fontToFitLine(text: String, inSize size: CGSize, spacing: CGFloat) -> UIFont {
        let constraintRect = CGSize(width: size.width, height: .greatestFiniteMagnitude)
        var font_size = CGFloat(8.0) //self.basicFont.pointSize
        var font = UIFont.init(descriptor: self.basicFont.fontDescriptor, size: font_size)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = spacing
        var attributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: font, NSAttributedString.Key.paragraphStyle: paragraphStyle]
        var aString = NSAttributedString.init(string: text, attributes: attributes)
        var boundingBox = aString.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, context: nil)
//        print(font.capHeight)
//        print(font.xHeight)
//        print(boundingBox.height)
//        print("---")
//
        while boundingBox.height <= font.lineHeight {
            font_size += 0.1
            font = UIFont.init(descriptor: self.basicFont.fontDescriptor, size: font_size)
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = spacing
            attributes = [NSAttributedString.Key.font: font, NSAttributedString.Key.paragraphStyle: paragraphStyle]
            aString = NSAttributedString.init(string: text, attributes: attributes)
            boundingBox = aString.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, context: nil)
        }
        font_size -= 0.1
        font = UIFont.init(descriptor: self.basicFont.fontDescriptor, size: font_size)
        return font
    }
    
}


extension UIFont {
    
    func withTextStyle(_ textStyle: UIFont.TextStyle) -> UIFont? {
        let style = UIFont.preferredFont(forTextStyle: textStyle)
        guard let des = self.fontDescriptor.withSymbolicTraits(style.fontDescriptor.symbolicTraits) else { return nil }
        return UIFont.init(descriptor: des, size: style.pointSize)
    }
}
