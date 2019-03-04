//
//  ViewController.swift
//  FlappyBird
//
//  Created by NAKAGAWA KEITA on 2019/02/26.
//  Copyright © 2019 keita.nakagawa. All rights reserved.
//

import UIKit
import SpriteKit

class ViewController: UIViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    
    //SKViewに型変換
    let skView = self.view as! SKView
    
    //FPSを表示
    skView.showsFPS = true
    
    //ノードの数を表示
    skView.showsNodeCount = true
    
    //ビューと同じサイズでシーンを作成
    let scene = GameScene(size: skView.frame.size)
    
    //ビューにシーンを表示する
    skView.presentScene(scene)
  }
  
  //ステータスバーを消す
  override var prefersStatusBarHidden: Bool {
    get {
      return true 
    }
  }


}

