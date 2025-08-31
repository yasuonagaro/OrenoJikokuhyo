import UIKit

// Storyboard上でデザインできるUIViewの拡張
@IBDesignable
extension UIView {
    
    // Storyboard上で設定可能なボーダーの太さ
    @IBInspectable var borderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }
    
    // Storyboard上で設定可能なボーダーの色
    @IBInspectable var borderColor: UIColor? {
        get {
            return UIColor(cgColor: layer.borderColor!)
        }
        set {
            layer.borderColor = newValue?.cgColor
        }
    }
    
    // Storyboard上で設定可能な角丸の半径
    @IBInspectable var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
            //layer.masksToBounds = newValue > 0
        }
    }
    
    // Storyboard上で設定可能な影の色
    @IBInspectable var shadowColor: UIColor? {
        get {
            return UIColor(cgColor: layer.shadowColor!)
        }
        set {
            layer.shadowColor = newValue?.cgColor
        }
    }
    
    // Storyboard上で設定可能な影の不透明度
    @IBInspectable var shadowOpacity: Float {
        get {
            return layer.shadowOpacity
        }
        set {
            layer.shadowOpacity = newValue
        }
    }
    
    // Storyboard上で設定可能な影のオフセット
    @IBInspectable var shadowOffset: CGSize {
        get {
            return layer.shadowOffset
        }
        set {
            layer.shadowOffset = newValue
        }
    }
    
    // Storyboard上で設定可能な影の半径（ぼかしの度合い）
    @IBInspectable var shadowRadius: CGFloat {
        get {
            return layer.shadowRadius
        }
        set {
            layer.shadowRadius = newValue
        }
    }
}
