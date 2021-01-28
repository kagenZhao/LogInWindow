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

    override func viewDidLoad() {
        super.viewDidLoad()
        logInWindow(true)
        p()
    }

    func p() {
        print("print: 0123456789")
        print("print: abcdefghigklmnopqrstuvwxyz")
        print("print: 北京欢迎你")
        print("print: *^(*&()åß∂çåß∂ƒœ∑¥øµ≤åß∫∂çø…ƒπœ∑¬µ√÷“æ˙¡ª•§")
        print("print: 예사소리/평음い　うけ か　さ た　 に ぬ の ま み め も り る")
        print("print: ", "asd0123".cString(using: String.Encoding.ascii)!)
    }
}
