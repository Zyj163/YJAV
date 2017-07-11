//
//  YJResourceLoaderDelegate.swift
//  YJAV
//
//  Created by 张永俊 on 2017/7/5.
//  Copyright © 2017年 CocoaPods. All rights reserved.
//

import UIKit
import AVFoundation
import YJDownloader

class YJResourceLoaderDelegate: NSObject {
    
    fileprivate var item: YJDownloaderItem?
    
    fileprivate lazy var downloader: YJDownloader = YJDownloader(tmpPath: YJFileTool.tmp(), cachePath: YJFileTool.cache())
    
    fileprivate lazy var requests: [AVAssetResourceLoadingRequest] = [AVAssetResourceLoadingRequest]()
    
    fileprivate var totalSize: UInt64 = 0
    
    fileprivate var loadedSize: UInt64 = 0
    
    fileprivate var mimeType: String?
}

extension YJResourceLoaderDelegate: AVAssetResourceLoaderDelegate {
    //当外界需要播放一段资源时，会跑一个请求到该代理，到时候只需要根据请求信息，抛数据出去即可
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        
        guard let url = loadingRequest.request.url?.httpURL() else { return true }
        
        //查看本地文件
        if YJFileTool.exists(YJFileTool.cache().appending("/\(url.lastPathComponent)")) {
            //读取本地文件并抛出去
            handleLoaded(loadingRequest)
            return true
        }
        
        requests.append(loadingRequest)
        
        guard let requestOffset = loadingRequest.dataRequest?.requestedOffset else { return true }
        guard let currentOffset = loadingRequest.dataRequest?.currentOffset else {return true}
        
        //第一次下载
        if item == nil {
            item = YJDownloaderItem(url)
            item?.stateChanged = { [weak self] (_, newState) in
                switch newState {
                case .downloading(let receiveSize):
                    self?.loadedSize = receiveSize + (self?.loadedSize ?? 0)
                    self?.handleLoading()
                default:
                    break
                }
            }
            item?.receiveTotalSize = { [weak self] (totalSize) in
                self?.totalSize = totalSize
            }
            item?.getMimeType = {[weak self] (mimeType) in
                self?.mimeType = mimeType
            }
            downloader.yj_download(item!, immediately: true)
            return true
        }
        
        if requestOffset < Int64(downloader.lastOffset) || requestOffset > currentOffset {
            //重新下载
            downloader.yj_destroy()
            loadedSize = 0
            downloader.download(url, offset: UInt64(requestOffset))
        } else {
            downloader.download(url, offset: UInt64(currentOffset))
        }
        
        return true
    }
}

extension YJResourceLoaderDelegate {
    fileprivate func handleLoaded(_ loadingRequest: AVAssetResourceLoadingRequest) {
        guard let url = loadingRequest.request.url else { return }
        
        let cacheFile = YJFileTool.cache().appending("/\(url.lastPathComponent)")
        let totalSize = YJFileTool.size(cacheFile)
        
        loadingRequest.contentInformationRequest?.contentLength = Int64(totalSize)
        loadingRequest.contentInformationRequest?.isByteRangeAccessSupported = true
        
        
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: cacheFile), options: .mappedIfSafe) else { return }
        guard let requestOffset = loadingRequest.dataRequest?.requestedOffset else { return }
        guard let requestLength = loadingRequest.dataRequest?.requestedLength else { return }
        
        let offset = Data.Index(requestOffset)
        let lengtgh = Data.Index(requestOffset + Int64(requestLength))
        let range = Range(uncheckedBounds: (offset, offset + lengtgh))
        let subdata = data.subdata(in: range)
        
        //抛出数据
        loadingRequest.dataRequest?.respond(with: subdata)
        
        //结束本次请求
        loadingRequest.finishLoading()
    }
    
    fileprivate func handleLoading() {
        if totalSize == 0 { return }
        var finishedRequests = [Int]()
        
        for (i, loadingRequest) in requests.enumerated() {
            //填充内容信息头
            guard let url = loadingRequest.request.url else { return }
            loadingRequest.contentInformationRequest?.contentLength = Int64(totalSize)
            loadingRequest.contentInformationRequest?.contentType = mimeType
            loadingRequest.contentInformationRequest?.isByteRangeAccessSupported = true
            
            //填充数据
            let tmpFile = YJFileTool.tmp().appending("/\(url.lastPathComponent)")
            var data = try? Data(contentsOf: URL(fileURLWithPath: tmpFile), options: .mappedIfSafe)
            if data == nil {
                let cacheFile = YJFileTool.cache().appending("/\(url.lastPathComponent)")
                data = try? Data(contentsOf: URL(fileURLWithPath: cacheFile), options: .mappedIfSafe)
            }
            guard let realData = data else { return }
            guard let dataRequest = loadingRequest.dataRequest else { return }
            let requestOffset = dataRequest.requestedOffset
            let requestLength = dataRequest.requestedLength
            
            let responseOffset = requestOffset - Int64(downloader.lastOffset)
            let responseLength = min((downloader.lastOffset + loadedSize - UInt64(requestOffset)), UInt64(requestLength))
            
            let offset = Data.Index(responseOffset)
            let lengtgh = Data.Index(responseOffset + Int64(responseLength))
            let range = Range(uncheckedBounds: (offset, offset + lengtgh))
            let subdata = realData.subdata(in: range)
            
            dataRequest.respond(with: subdata)
            
            if UInt64(requestLength) == responseLength {
                loadingRequest.finishLoading()
                finishedRequests.append(i)
            }
        }
        finishedRequests.forEach { requests.remove(at: $0) }
    }
}
