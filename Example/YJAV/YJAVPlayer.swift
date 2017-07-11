//
//  YJAVPlayer.swift
//  YJAV
//
//  Created by 张永俊 on 2017/7/4.
//  Copyright © 2017年 CocoaPods. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

enum YJAVPlayerState: String {
    case unknown
    case loading
    case playing
    case stopped
    case paused
    case failed
}

enum YJAVPlayerVideoGravity: String {
    case unknown
    case resizeAspect
    case resizeAspectFill
    case resize
}

class YJAVPlayer: NSObject {
    fileprivate var player: AVPlayer?
    fileprivate var forcePause: Bool = false
    
    fileprivate var resourceLoaderDelegate: AVAssetResourceLoaderDelegate?
    
    fileprivate var _state: YJAVPlayerState = .unknown {
        didSet {
            stateChangedHandler?(state)
        }
    }
    
    fileprivate override init() {
        super.init()
    }
    
    static let avplayer = YJAVPlayer()
    
    var totalTime: TimeInterval {
        guard let totalT = player?.currentItem?.duration else {return 0}
        
        if CMTIME_IS_NUMERIC(totalT) {
            return CMTimeGetSeconds(totalT)
        } else {
            return 0
        }
    }
    
    var currentTime: TimeInterval {
        guard let currentT = player?.currentItem?.currentTime() else {return 0}
        
        if CMTIME_IS_NUMERIC(currentT) {
            return CMTimeGetSeconds(currentT)
        } else {
            return 0
        }
    }
    
    var rate: Float {
        set {
            player?.rate = rate
        }
        get {
            return player?.rate ?? 0
        }
    }
    
    var muted: Bool {
        set {
            player?.isMuted = muted
        }
        get {
            return player?.isMuted ?? false
        }
    }
    
    var volume: Float {
        set {
            if volume > 1 || volume < 0 {return}
            if volume > 0 {muted = false}
            player?.volume = volume
        }
        get {
            return player?.volume ?? 0
        }
    }
    
    var loadProgress: Double {
        if totalTime == 0 {return 0}
        if let timeRange = player?.currentItem?.loadedTimeRanges.max(by: {$0.timeRangeValue.end >= $1.timeRangeValue.end})?.timeRangeValue {
            let loadTime = timeRange.end
            let loadTimeSec = CMTimeGetSeconds(loadTime)
            return loadTimeSec / totalTime
        }
        return 0
    }
    
    var progress: Double {
        if totalTime == 0 {return 0}
        return currentTime / totalTime
    }
    
    var state: YJAVPlayerState {
        return _state
    }
    
    var stateChangedHandler: ((YJAVPlayerState)->())?
    
    var currentUrl: URL? {
        return (player?.currentItem?.asset as? AVURLAsset)?.url
    }
    
    var layer: CALayer? {
        if let player = player {
            let layer = AVPlayerLayer(player: player)
            return layer
        }
        return nil
    }
    
    //提供一个默认样式
    var videoContainer: YJVideoLayerContainer? {
        let progressView = YJProgressView()
        
        let playOrPauseBtnImage: (UIControlState)->UIImage = {
            if $0 == .selected {
                return UIImage(named: "exihibitVoicePause")!
            } else {
                return UIImage(named: "exhibitVoicePlay")!
            }
        }
        let playOrPauseBtnAction: ((UIControlState)->Void)? = {
            print($0)
        }
        
        let fullScreenBtnImage: (UIControlState)->UIImage = {
            if $0 == .selected {
                return UIImage(named: "exihibitVoicePause")!
            } else {
                return UIImage(named: "exhibitVoicePlay")!
            }
        }
        let fullScreenBtnAction: ((UIControlState)->Void)? = {
            print($0)
        }
        
        var style = YJVideoLayerToolViewStyle(playOrPauseBtnImage: playOrPauseBtnImage, fullScreenBtnImage: fullScreenBtnImage)
        style.playOrPauseBtnAction = playOrPauseBtnAction
        style.fullScreenBtnAction = fullScreenBtnAction
        
        let toolView = YJVideoLayerToolView(style, progressView: progressView)
        
        return YJVideoLayerContainer(avplayer: self, toolView: toolView)
    }
    
    var videoGravity: YJAVPlayerVideoGravity {
        get {
            if let layer = layer as? AVPlayerLayer {
                return YJAVPlayerVideoGravity(rawValue: layer.videoGravity) ?? .unknown
            }
            return .unknown
        }
        set {
            if let layer = layer as? AVPlayerLayer, videoGravity != .unknown {
                layer.videoGravity = videoGravity.rawValue
            }
        }
    }
}

extension YJAVPlayer {
    func play(_ url: URL, isCache: Bool) {
        if let currentUrl = (player?.currentItem?.asset as? AVURLAsset)?.url,
            (currentUrl == url || url.streamingURL() == currentUrl) {
            resume()
            return
        }
        
        if let _ = player?.currentItem {
            removeObserver()
            return
        }
        
        guard let url = isCache ? url.streamingURL() : url else {return}
        
        //1.资源的请求
        let asset = AVURLAsset(url: url)
        
        if isCache {
            resourceLoaderDelegate = YJResourceLoaderDelegate()
            asset.resourceLoader.setDelegate(resourceLoaderDelegate, queue: nil)
        }
        
        //2.资源的组织
        let item = AVPlayerItem(asset: asset)
        
        item.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: .new, context: nil)
        item.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.isPlaybackLikelyToKeepUp), options: .new, context: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(notifyPlayEnd(_:)), name: .AVPlayerItemDidPlayToEndTime, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(notifyPlayInterrupt(_:)), name: .AVPlayerItemPlaybackStalled, object: nil)
        
        //3.资源的播放
        player = AVPlayer(playerItem: item)
    }
    
    func resume() {
        guard let player = player else {return}
        
        player.play()
        forcePause = false
        if let item = player.currentItem, item.isPlaybackLikelyToKeepUp {
            _state = .playing
        }
    }
    
    func pause() {
        guard let player = player else {return}
        
        player.pause()
        forcePause = true
        _state = .paused
    }
    
    func stop() {
        player?.pause()
        if let _ = player {
            _state = .stopped
            removeObserver()
        }
        player = nil
    }
    
    func seek(progress: Float) {
        if progress < 0 || progress > 1 {return}
        guard let player = player else {return}
        if totalTime == 0 {return}
        
        let toTimeSec = totalTime * Float64(progress)
        
        let currentTime = CMTimeMake(Int64(toTimeSec), 1)
        
        player.seek(to: currentTime, completionHandler: { (finish) in
            if finish {
                print("确定加载这个时间点的资源")
            } else {
                print("放弃加载这个时间点的资源，因为可能有连续多次seek的情况")
            }
        })
    }
    
    func seek(timeDif: TimeInterval) {
        if totalTime == 0 {return}
        let toTimeSec = currentTime + timeDif
        seek(progress: Float(toTimeSec / totalTime))
    }
}

extension YJAVPlayer {
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath(AVPlayerItem.status) {
            if let state = change?[.newKey] as? AVPlayerItemStatus {
                switch state {
                case .readyToPlay:
                    resume()
                case .failed:
                    _state = .failed
                default:
                    _state = .unknown
                }
            }
        } else if keyPath == #keyPath(AVPlayerItem.isPlaybackLikelyToKeepUp) {
            if let ptk = change?[.newKey] as? Bool, ptk == true {
                if !forcePause {
                    resume()
                }
            } else {
                _state = .loading
            }
        }
    }
    
    func removeObserver() {
        player?.currentItem?.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status))
        player?.currentItem?.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.isPlaybackLikelyToKeepUp))
        NotificationCenter.default.removeObserver(self)
    }
    
    func notifyPlayEnd(_ notify: Notification) {
        stop()
    }
    
    func notifyPlayInterrupt(_ notify: Notification) {
        pause()
    }
}




