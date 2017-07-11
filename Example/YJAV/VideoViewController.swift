//
//  VideoViewController.swift
//  YJAV
//
//  Created by 张永俊 on 2017/7/10.
//  Copyright © 2017年 CocoaPods. All rights reserved.
//

import UIKit

class VideoViewController: UIViewController {

    var videoView: YJVideoLayerContainer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        videoView = YJAVPlayer.avplayer.videoContainer
        view.addSubview(videoView!)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        videoView?.frame = view.bounds
    }
    

}
