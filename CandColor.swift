import UIKit

enum CandColor: Int {
    case none = 0, red, orange, yellow, green, blue, violet
    
    var uiColor: UIColor? {
        switch self {
        case .red: return UIColor(red: 235/255, green: 64/255, blue: 52/255, alpha: 1)
        case .orange: return UIColor(red: 245/255, green: 150/255, blue: 39/255, alpha: 1)
        case .yellow: return UIColor(red: 255/255, green: 218/255, blue: 68/255, alpha: 1)
        case .green: return UIColor(red: 80/255, green: 200/255, blue: 120/255, alpha: 1)
        case .blue: return UIColor(red: 66/255, green: 135/255, blue: 245/255, alpha: 1)
        case .violet: return UIColor(red: 148/255, green: 87/255, blue: 235/255, alpha: 1)
        default: return nil
        }
    }
}
