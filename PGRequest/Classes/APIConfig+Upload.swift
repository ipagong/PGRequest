//
//  APIConfig+Upload.swift
//
//  Created by ipagong on 16/10/2019.
//  Copyright © 2019 ipagong. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import Alamofire

public protocol APIUploadConfig: APIConfig {
    var formData: [UploadData] { get }
}

public enum APIUploadStatus<Result> {
    case progress(Progress)
    case complete(Result)
}

public struct UploadData {
    public let data:Data
    public let fileName:String
    public let withName:FileType
    public let mimeType:MimeType
    
    public enum FileType: String {
        case photo = "photo"
    }
    
    public enum MimeType: String {
        case png = "image/png"
        case jpg = "image/jpeg"
    }
}

extension APIUploadConfig {
    public func makeRequest() -> Observable<Self.Response> {
        return Observable<Response>.create { (observer: AnyObserver<Response>) -> Disposable in
            
            APILog("\n\n")
            APILog("<----------- UPLOAD ------------>")
            APILog("")
            APILog("**** fullpath: \(self.debugFullPath)")
            APILog("")
            APILog("<------------------------------->")
            APILog("\n")
            
            let request = Self.domainConfig.manager.upload(multipartFormData: self.multiPartFormData(),
                                                           to: self.fullPath,
                                                           usingThreshold: MultipartFormData.encodingMemoryThreshold,
                                                           method: self.method,
                                                           headers: HTTPHeaders(self.fullHeaders))
                
            request
                .validate()
                .responseData(completionHandler: self.responseHandler(observer))

            return Disposables.create { request.cancel() }
        }
    }
}

extension APIUploadConfig {
    fileprivate func multiPartFormData() -> ((MultipartFormData) -> Void) {
        return { (form:MultipartFormData) -> Void in
            self.fullParamaters?.forEach{ (key, value) in
                if let data = (value as? CustomStringConvertible)?.description.data(using: .utf8) {
                    form.append(data, withName: key)
                }
            }
            
            self.formData.forEach{ form.append($0.data,
                                               withName: $0.withName.rawValue,
                                               fileName: $0.fileName,
                                               mimeType: $0.mimeType.rawValue) }
        }
    }
}

extension Data {
    fileprivate func uploadData(fileName:String,
                    type:UploadData.FileType,
                    mime:UploadData.MimeType) -> UploadData {
        return UploadData.init(data: self,
                               fileName: fileName,
                               withName: type,
                               mimeType: mime)
    }
}

extension UIImage {
    public func pngUploadData(_ type: UploadData.FileType) -> UploadData? {
        return self.pngData()?.uploadData(fileName: "photo.png", type: type, mime: .png)
    }
    
    public func jpgUploadData(_ type: UploadData.FileType) -> UploadData? {
        return self.jpegData(compressionQuality: 1.0)?.uploadData(fileName: "photo.jpeg", type: type, mime: .jpg)
    }
}
