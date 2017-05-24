//
//  swiftViewController.swift
//  Sample
//
//  Created by 赵国庆 on 2017/5/24.
//  Copyright © 2017年 kagenZhao. All rights reserved.
//

import UIKit
import LogInWindow

class swiftViewController: UIViewController {
    let t = DispatchSource.makeTimerSource();

    override func viewDidLoad() {
        super.viewDidLoad()
//        logInWindow(true)
//        p()
    }

    func p() {
        t.scheduleRepeating(deadline: .now(), interval: DispatchTimeInterval.seconds(1), leeway: DispatchTimeInterval.microseconds(1))
        t.setEventHandler {
            print("北京欢迎你 aaaaasdfsdfg *^(*&R()8y23rkvwd")
        }
        t.resume()
    }
}
