//
//  ViewController.swift
//  YJAV
//
//  Created by Zyj163.com on 07/04/2017.
//  Copyright (c) 2017 Zyj163.com. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var currentTimeLabel: UILabel!
    
    @IBOutlet weak var totalTimeLabel: UILabel!
    
    @IBOutlet weak var rateLabel: UILabel!
    
    @IBOutlet weak var loadProgressLabel: UILabel!
    
    @IBOutlet var loadProgress: UIProgressView!
    
    @IBOutlet weak var playProgressSlider: UISlider!
    
    @IBOutlet weak var rateSlider: UISlider!
    
    @IBOutlet weak var mutedSwitch: UISwitch!
    
    @IBOutlet weak var stateLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 10.0, *) {
            let timer = Timer(timeInterval: 1, repeats: true) {[weak self] (timer) in
                self?.currentTimeLabel.text = YJAVPlayer.avplayer.currentTime.format
                self?.totalTimeLabel.text = YJAVPlayer.avplayer.totalTime.format
                self?.playProgressSlider.value = Float(YJAVPlayer.avplayer.progress)
                self?.loadProgressLabel.text = "\(YJAVPlayer.avplayer.loadProgress)"
                self?.loadProgress.progress = Float(YJAVPlayer.avplayer.loadProgress)
                self?.mutedSwitch.isOn = YJAVPlayer.avplayer.muted
                self?.rateSlider.value = YJAVPlayer.avplayer.rate
                self?.rateLabel.text = "\(YJAVPlayer.avplayer.rate)"
            }
            RunLoop.current.add(timer, forMode: .commonModes)
        } else {
            // Fallback on earlier versions
        }
        YJAVPlayer.avplayer.stateChangedHandler = {[weak self] (state) in
            self?.stateLabel.text = state.rawValue
        }
    }
    
    @IBAction func play(_ sender: Any) {
        if let url = URL(string: "http://120.25.226.186:32812/resources/videos/minion_01.mp4") {
            YJAVPlayer.avplayer.play(url, isCache: false)
        }
    }
    
    @IBAction func pause(_ sender: Any) {
        YJAVPlayer.avplayer.pause()
    }
    
    @IBAction func stop(_ sender: Any) {
        YJAVPlayer.avplayer.stop()
    }
    
    @IBAction func resume(_ sender: Any) {
        YJAVPlayer.avplayer.resume()
    }
    
    @IBAction func muted(_ sender: UISwitch) {
        YJAVPlayer.avplayer.muted = sender.isOn
    }
    
    @IBAction func seekForward(_ sender: Any) {
        YJAVPlayer.avplayer.seek(timeDif: 10)
    }
    
    @IBAction func seekBack(_ sender: Any) {
        YJAVPlayer.avplayer.seek(timeDif: -10)
    }
    
    @IBAction func changePlayProgress(_ sender: UISlider) {
        YJAVPlayer.avplayer.seek(progress: sender.value)
    }
    
    @IBAction func changeRate(_ sender: UISlider) {
        YJAVPlayer.avplayer.rate = sender.value
    }
    
    @IBAction func showMovie(_ sender: Any) {
//        if let videoContainner = YJAVPlayer.avplayer.videoContainer {
//            
//            let movieVc = UIViewController()
//            
//            movieVc.view.addSubview(videoContainner)
//            
//            videoContainner.frame = view.bounds
//            
//            navigationController?.pushViewController(movieVc, animated: true)
//        }
        
        let movieVc = VideoViewController()
        navigationController?.pushViewController(movieVc, animated: true)
    }
}

