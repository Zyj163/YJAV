//
//  YJAVHelper.swift
//  YJAV
//
//  Created by 张永俊 on 2017/7/4.
//  Copyright © 2017年 CocoaPods. All rights reserved.
//

import Foundation


extension URL {
    
    private func changeScheme(_ scheme: String) -> URL? {
        var components = URLComponents(string: absoluteString)
        components?.scheme = scheme
        return components?.url
    }
    
    func streamingURL() -> URL? {
        return changeScheme("streaming")
    }
    
    func httpURL() -> URL? {
        return changeScheme("http")
    }
}

extension TimeInterval {
    var format: String {
        return String(format: "%02d:%02d", Int(self) / 60, Int(self) % 60)
    }
}
