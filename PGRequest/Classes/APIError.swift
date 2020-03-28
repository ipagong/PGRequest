//
//  APIErrorable.swift
//
//  Created by ipagong on 16/10/2019.
//  Copyright © 2019 ipagong. All rights reserved.
//

import Foundation

public protocol ServiceErrorable: Codable {
    associatedtype Code: ServiceErrorCodeRawPresentable
    var code: Code     { get }
    var message: String? { get }
    
    static func globalExeception() -> Bool
}

public protocol ServiceErrorCodeRawPresentable: Codable {
    var rawValue:Int { get }
}

public struct APIError<ServiceError: ServiceErrorable>: Swift.Error {
    public let code: Code<ServiceError.Code>
    public let status: Int?
    public let message: String?

    public init(code: Code<ServiceError.Code>, status: Int? = nil, message:String? = nil) {
        self.code    = code
        self.status  = status
        self.message = message
    }
    
    internal init(data: Data, status: Int? = nil, type:ServiceError.Type) throws {
        let service = try JSONDecoder().decode(ServiceError.self, from: data)
        
        self.code = APIError.Code.service(service.code)
        self.message = service.message
        self.status = status
    }
}

extension APIError {
    func showMessagePopup() {
        let alert = UIAlertController(title: nil, message: self.message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .cancel, handler: nil))
        
        self.target?.present(alert, animated: true, completion: nil)
    }
    
    fileprivate var target:UIViewController? {
        guard let rootVc = UIApplication.shared.windows.first?.rootViewController else { return nil }
        
        var top = rootVc
        
        while let newTop = top.presentedViewController { top = newTop }
        
        guard let last = top.children.last else { return top }
        
        return last
    }
}
