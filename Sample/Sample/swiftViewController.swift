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
        logInWindow(true)
        p()
    }

    func p() {
        t.schedule(deadline: .now(), repeating: DispatchTimeInterval.seconds(1), leeway: DispatchTimeInterval.microseconds(1))
        t.setEventHandler {
            print("asdeasdve北京欢迎你aaaaasdfsdfg欢迎你*^(*&R()8y23rkvwdåß∂çåß∂ƒœ∑¥øµ≤åß∫∂çø…ƒπœ∑¬µ√÷“æ˙¡ª•§")
            print("asdfasdf".cString(using: String.Encoding.ascii))
        }
        t.resume()
    }
}
