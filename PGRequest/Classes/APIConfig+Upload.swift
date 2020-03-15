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

protocol APIUploadConfig : APIConfig {
    var formData: [UploadData] { get }
}

enum APIUploadStatus<Result> {
    case progress(Progress)
    case complete(Result)
}

struct UploadData {
    let data:Data
    let fileName:String
    let withName:FileType
    let mimeType:MimeType
    
    enum FileType : String {
        case photo = "photo"
    }
    
    enum MimeType : String {
        case png = "image/png"
        case jpg = "image/jpeg"
    }
}

extension APIUploadConfig {
    func makeRequest() -> Observable<Self.Response> {
        return Observable<Response>.create { (observer: AnyObserver<Response>) -> Disposable in
            
            APILog("\n\n")
            APILog("<----------- UPLOAD ------------>")
            APILog("")
            APILog("**** fullpath : \(self.debugFullPath)")
            APILog("")
            APILog("<------------------------------->")
            APILog("\n")
            
            var request:DataRequest?
            
            Self.domainConfig.manager.upload(multipartFormData: self.multiPartFormData(),
                                             usingThreshold: SessionManager.multipartFormDataEncodingMemoryThreshold,
                                             to: self.fullPath,
                                             method: self.method,
                                             headers: self.fullHeaders) { result in
                                                switch result {
                                                case .success(let upload, _, _):
                                                    request = upload.validate().responseData(completionHandler: self.responseHandler(observer))
                                                    
                                                case .failure(let error):
                                                    observer.onError(APIError<ServiceError>.init(code: .common(.malformedRequest), message: error.localizedDescription))
                                                }}
            
            return Disposables.create { request?.cancel() }
        }
    }
}

extension APIUploadConfig {
    func multiPartFormData() -> ((MultipartFormData) -> Void) {
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
    func uploadData(fileName:String,
                    type:UploadData.FileType,
                    mime:UploadData.MimeType) -> UploadData {
        return UploadData.init(data: self,
                               fileName: fileName,
                               withName: type,
                               mimeType: mime)
    }
}

extension UIImage {
    func pngUploadData(_ type: UploadData.FileType) -> UploadData? {
        return self.pngData()?.uploadData(fileName: "photo.png", type: type, mime: .png)
    }
    
    func jpgUploadData(_ type: UploadData.FileType) -> UploadData? {
        return self.jpegData(compressionQuality: 1.0)?.uploadData(fileName: "photo.jpeg", type: type, mime: .jpg)
    }
}
