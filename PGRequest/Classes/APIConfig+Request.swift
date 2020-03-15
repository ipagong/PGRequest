//
//  APIConfig+Request.swift
//
//  Created by ipagong on 16/10/2019.
//  Copyright © 2019 ipagong. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import Alamofire

extension APIConfig {
    
    internal func makeRequest() -> Observable<Self.Response> {
        return Observable<Response>.create { (observer: AnyObserver<Response>) -> Disposable in
            
            APILog("\n\n")
            APILog("<----------- REQUEST ----------->")
            APILog("")
            APILog("**** fullpath  : \(self.debugFullPath)")
            APILog("**** parameter : \(self.parameters?.params ?? [:])")
            APILog("")
            APILog("<------------------------------->")
            APILog("\n")
            
            let request = Self.domainConfig.manager.request(self.fullPath,
                                                            method: self.method,
                                                            parameters: self.fullParamaters,
                                                            encoding: self.encoding,
                                                            headers: self.fullHeaders)
            
            request
                .validate()
                .responseData(completionHandler: self.responseHandler(observer))
            
            return Disposables.create { request.cancel() }
            }
    }
}

extension APIConfig {
    internal func responseHandler(_ observer: AnyObserver<Self.Response>) -> ((DataResponse<Data>) -> Void) {
        return { (response:DataResponse<Data>) -> Void in
            switch response.result {
            case .success(let data):
                do {
                    if let description = String(data: data, encoding: .utf8) {
                        APILog("\n\n")
                        APILog("<----------- Response : \(String(describing: Self.Response.self)) ----------->")
                        APILog("")
                        APILog(description)
                        APILog("")
                        APILog("<------------------------------->")
                        APILog("\n")
                    }
                    
                    let response = try self.parse(data)
                    observer.onNext(response)
                    observer.onCompleted()
                    
                } catch let error {
                    observer.onError(APIError<ServiceError>.init(code: .common(.inconsistantModelParseFailed),
                                                                 message: error.localizedDescription))
                }
            case .failure(let error):
                if let errorData = response.data { APILog(String(data: errorData, encoding: .utf8)! ) }
                observer.onError(self.failHandler(error: error, response: response))
            }
        }
    }
    
    private func failHandler(error:Error, response:DataResponse<Data>) -> APIError<ServiceError> {
        guard error.isCanceled == false else {
            return APIError.init(code: .common(.opertaionCanceled))
        }
        
        guard let afError = error as? AFError else {
            APILog("\n\n")
            APILog("<---- OS ERROR FAIL CODE ----->")
            APILog("")
            APILog("**** error: \(error)")
            APILog("")
            APILog("<------------------------------->")
            APILog("\n")
            return APIError.init(code: .common(.networkError))
        }
        
        guard case let .responseValidationFailed(reason: .unacceptableStatusCode(code: status)) = afError else {
            return APIError.init(code: .common(.malformedRequest))
        }
        
        switch status {
        case 503 :
            return APIError.init(code: .common(.serviceExternalUnavailable), status: status, message: afError.localizedDescription)
        case (500..<600) :
            APILog("\n\n")
            APILog("<---- HTTP ERROR FAIL CODE ----->")
            APILog("")
            APILog("**** http status: \(status)")
            APILog("")
            APILog("<------------------------------->")
            APILog("\n")
            return APIError.init(code: .common(.internalServerError), status: status, message: afError.localizedDescription)
        default:
            guard let data = response.data, let error = try? APIError.init(data: data, status: status, type: Self.serviceError.self) else {
                return APIError.init(code: .common(.http), status: nil, message: afError.localizedDescription)
            }
            
            return error
        }
    }

}

extension Observable {
    internal func globalException<T: APIConfig>(_ target:T) -> Observable {
        return self
            .do(onNext: { (data) in
                APILog("\n\n")
                APILog("<--------- API SUCCESS --------->")
                APILog("")
                APILog("***** success: [\(target.method)] \(target.path)")
                APILog("***** header: \(target.fullHeaders)")
                APILog("***** parameter: \(String(describing: target.fullParamaters))")
                APILog("***** data: \(data)")
                APILog("")
                APILog("<------------------------------->")
                APILog("\n")
                
            }, onError: { (error) in
                APILog("\n\n")
                APILog(">-------- API FAILED ---------<")
                APILog("")
                APILog("***** failed: [\(target.method)] \(target.path)")
                APILog("***** header: \(target.fullHeaders)")
                APILog("***** parameter: \(String(describing: target.fullParamaters))")
                APILog("***** error: \(error)")
                APILog("")
                APILog(">-------------------------------<")
                APILog("\n")
            })
            .catchError { (error) -> Observable<Element> in
                guard let apiError = error as? APIError<T.ServiceError> else { throw error }
                
                if T.serviceError.globalExeception() == true {
                    throw APIError<T.ServiceError>.init(code: .common(.globalException),
                                                         status: apiError.status,
                                                         message: apiError.message)
                } else {
                    throw apiError
                }
            }
    }
}

extension Error {
    fileprivate var isCanceled:Bool {
        return (self as NSError).domain == NSURLErrorDomain && (self as NSError).code == NSURLErrorCancelled
    }
}