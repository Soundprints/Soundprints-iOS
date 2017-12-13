
import Foundation

class Throttle {
    private var block: (() -> Void)?
    var retainCount = 0
    var delay = 0.5
    var skipCount = 0
    var maxLimit = 0
    
    init(delay: TimeInterval = 0.5, maxLimit: Int = 0) {
        self.delay = delay
        self.maxLimit = maxLimit
    }
    
    func run(block: @escaping () -> Void) {
        retainCount += 1
        
        if maxLimit > 0 {
            skipCount += 1
        }
        
        self.block = block
        
        if maxLimit > 0 && skipCount >= maxLimit {
            skipCount = 0
            block()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            
            if var retainCount = self?.retainCount {
                retainCount -= 1
                if retainCount <= 0 {
                    block()
                    self?.block = nil
                }
                
                self?.retainCount = retainCount
            }
        }
    }
    
    func invalidate() {
        block = nil
    }
}
