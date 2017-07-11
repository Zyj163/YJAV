//
//  YJVideoLayer.swift
//  YJAV
//
//  Created by 张永俊 on 2017/7/7.
//  Copyright © 2017年 CocoaPods. All rights reserved.
//

import AVFoundation
import UIKit

class YJVideoLayerContainer: UIView {
    weak var avplayer: YJAVPlayer?
    
    var toolView: UIView
    
    var toolViewH: CGFloat = 44
    
    var avlayer: AVPlayerLayer
    
    init?(avplayer: YJAVPlayer, toolView: UIView) {
        
        guard let avlayer = avplayer.layer as? AVPlayerLayer else {
            return nil
        }
        
        self.toolView = toolView
        self.avlayer = avlayer
        super.init(frame: CGRect.zero)
        self.avplayer = avplayer
        setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI() {
        
        layer.addSublayer(avlayer)
        
        addSubview(toolView)
    }
    
    override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)
        
        avlayer.frame = bounds
        avlayer.backgroundColor = UIColor.red.cgColor
        
        let y = avlayer.videoRect.maxY - toolViewH
        
        toolView.frame = CGRect(x: 0, y: y, width: bounds.width, height: toolViewH)
    }
}

struct YJVideoLayerToolViewStyle {
    
    var insetLeft: CGFloat = 10
    var insetRight: CGFloat = 10
    var spaceBetweenPlayOrPauseBtnAndProgressView: CGFloat = 5
    var spaceBetweenProgressViewAndFullScreenBtn: CGFloat = 5
    
    var playOrPauseBtnImage: (UIControlState)->UIImage
    var playOrPauseBtnAction: ((UIControlState)->Void)?
    
    var fullScreenBtnImage: (UIControlState)->UIImage
    var fullScreenBtnAction: ((UIControlState)->Void)?
    
    init(playOrPauseBtnImage: @escaping (UIControlState)->UIImage, fullScreenBtnImage: @escaping (UIControlState)->UIImage) {
        self.playOrPauseBtnImage = playOrPauseBtnImage
        self.fullScreenBtnImage = fullScreenBtnImage
    }
}

class YJVideoLayerToolView: UIView {
    
    var style: YJVideoLayerToolViewStyle
    
    private var playOrPauseBtn = UIButton()
    
    fileprivate var progressView: YJProgressViewable
    
    private var fullScreenBtn = UIButton()
    
    init<P: UIView>(_ style: YJVideoLayerToolViewStyle, progressView: P) where P: YJProgressViewable {
        self.style = style
        self.progressView = progressView
        super.init(frame: CGRect.zero)
        
        setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(playOrPauseBtn)
        addSubview(progressView as! UIView)
        addSubview(fullScreenBtn)
        
        playOrPauseBtn.addTarget(self, action: #selector(clickOnPlayOrPause(_:)), for: .touchUpInside)
        fullScreenBtn.addTarget(self, action: #selector(clickOnFullScreen(_:)), for: .touchUpInside)
        
        playOrPauseBtn.setImage(style.playOrPauseBtnImage(.normal), for: .normal)
        playOrPauseBtn.setImage(style.playOrPauseBtnImage(.selected), for: .selected)
        
        fullScreenBtn.setImage(style.fullScreenBtnImage(.normal), for: .normal)
        fullScreenBtn.setImage(style.fullScreenBtnImage(.selected), for: .normal)
        
        playOrPauseBtn.sizeToFit()
        fullScreenBtn.sizeToFit()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        playOrPauseBtn.frame.origin.x = style.insetLeft
        playOrPauseBtn.frame.origin.y = (bounds.height - playOrPauseBtn.bounds.height) * 0.5
        
        let progressView: UIView = self.progressView as! UIView
        progressView.frame.origin.x = playOrPauseBtn.frame.maxX + style.spaceBetweenPlayOrPauseBtnAndProgressView
        progressView.frame.size.height = bounds.height
        progressView.frame.origin.y = 0
        
        fullScreenBtn.frame.origin.x = bounds.width - style.insetRight - fullScreenBtn.bounds.width
        fullScreenBtn.frame.origin.y = (bounds.height - fullScreenBtn.bounds.height) * 0.5
        
        progressView.frame.size.width = fullScreenBtn.frame.minX - progressView.frame.minX - style.spaceBetweenProgressViewAndFullScreenBtn
    }
    
    func clickOnPlayOrPause(_ sender: UIButton) {
        style.playOrPauseBtnAction?(sender.state)
    }
    
    func clickOnFullScreen(_ sender: UIButton) {
        style.fullScreenBtnAction?(sender.state)
    }
}

extension YJVideoLayerToolView: YJProgressViewable {
    
    func changeLoadProgress(_ progress: Float) {
        progressView.changeLoadProgress(progress)
    }
    
    func changePlayProgress(_ progress: Float) {
        progressView.changePlayProgress(progress)
    }
}

protocol YJProgressViewable {
    func changeLoadProgress(_ progress: Float)
    func changePlayProgress(_ progress: Float)
}

struct YJProgressViewStyle {
    var backgroundProgressColor: UIColor = .lightGray
    var loadProgressColor: UIColor = .gray
    var playProgressColor: UIColor = .darkGray
    
    var progressLineHeight: CGFloat = 2
    
    var sliderImage: UIImage?
    
    var playProgressSliderValueChanged: ((Float)->Void)?
}

class YJProgressView: UIView, YJProgressViewable {
    private var style: YJProgressViewStyle
    
    private var loadProgress: Float = 0
    
    private let backgroundProgressView = UIView()
    private let loadProgressView = UIView()
    private let playProgressSlider = UISlider()
    
    init(_ style: YJProgressViewStyle = YJProgressViewStyle()) {
        self.style = style
        super.init(frame: CGRect.zero)
        setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        addSubview(backgroundProgressView)
        addSubview(loadProgressView)
        addSubview(playProgressSlider)
        
        backgroundProgressView.backgroundColor = style.backgroundProgressColor
        loadProgressView.backgroundColor = style.loadProgressColor
        playProgressSlider.minimumTrackTintColor = style.playProgressColor
        playProgressSlider.maximumTrackTintColor = .clear
        
        playProgressSlider.addTarget(self, action: #selector(sliderChanged(_:)), for: .valueChanged)
    }
    
    func initial() {
        playProgressSlider.value = 0
        loadProgress = 0
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let h: CGFloat = style.progressLineHeight
        let x: CGFloat = 10
        let y: CGFloat = (bounds.height - h) * 0.5
        let w: CGFloat = bounds.width - x * 2
        
        let pframe = CGRect(x: x, y: y, width: w, height: h)
        backgroundProgressView.frame = pframe
        playProgressSlider.frame = pframe
        
        loadProgressView.frame = CGRect(x: x, y: y, width: w * CGFloat(loadProgress), height: h)
    }
    
    func changeLoadProgress(_ progress: Float) {
        if progress > 1 || progress < 0 { return }
        
        loadProgress = progress
        
        let h: CGFloat = style.progressLineHeight
        let x: CGFloat = 10
        let y: CGFloat = (bounds.height - h) * 0.5
        let w: CGFloat = bounds.width - x * 2
        loadProgressView.frame = CGRect(x: x, y: y, width: w * CGFloat(loadProgress), height: h)
    }
    
    func changePlayProgress(_ progress: Float) {
        if progress > 1 || progress < 0 { return }
        
        playProgressSlider.value = progress
    }
    
    func sliderChanged(_ sender: UISlider) {
        style.playProgressSliderValueChanged?(sender.value)
    }
}
















