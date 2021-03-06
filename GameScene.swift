//
//  GameScene.swift
//  FlappyBird
//
//  Created by NAKAGAWA KEITA on 2019/02/26.
//  Copyright © 2019 keita.nakagawa. All rights reserved.
//

import SpriteKit
import AVFoundation

class GameScene: SKScene,SKPhysicsContactDelegate {
  
  var scrollNode:SKNode!
  var wallNode:SKNode!
  var bird:SKSpriteNode!
  var starNode:SKNode!
  var player:AVAudioPlayer!
  
  let action = SKAction.playSoundFileNamed("jump13.mp3", waitForCompletion: true)
  
  
  //衝突判定カテゴリー
  let birdCategory: UInt32 = 1 << 0
  let groundCategory: UInt32 = 1 << 1
  let wallCategory: UInt32 = 1 << 2
  let scoreCategory: UInt32 = 1 << 3
  let itemCategory: UInt32 = 1 << 4
  
  //スコア用
  var score = 0
  var itemScore = 0
  var scoreLabelNode:SKLabelNode!
  var bestScoreLabelNode:SKLabelNode!
  var itemScoreLabelNode:SKLabelNode!
  var bestItemScoreLabelNode:SKLabelNode!
  let userDefaults:UserDefaults = UserDefaults.standard

  //SKView上にシーンが表示された時に呼ばれるメソッド
  override func didMove(to view: SKView) {
    
    //重力を設定
    physicsWorld.gravity = CGVector(dx: 0, dy: -4)
    physicsWorld.contactDelegate = self
    
    //背景色を設定
    backgroundColor = UIColor(red: 0.15, green: 0.75, blue: 0.90, alpha: 1)
    
    //スクロールするスプライトの親ノード
    scrollNode = SKNode()
    addChild(scrollNode)
    
    //壁用のノード
    wallNode = SKNode()
    scrollNode.addChild(wallNode)
    
    //星のノード
    starNode = SKNode()
    scrollNode.addChild(starNode)
    
    setupGround()
    setupCloud()
    setupWall()
    setupBird()
    setupStar()
    
    setupScoreLabel()
    
  }
  
  func setupGround() {
    //地面の画像を読み込む
    let groundTexture = SKTexture(imageNamed: "ground")
    groundTexture.filteringMode = .nearest
    
    //必要な枚数を計算
    let needNumber = Int(self.frame.size.width / groundTexture.size().width) + 2
    
    //スクロールするアクションを作成
    //左方向に画像一枚分スクロールさせるアクション
    let moveGound = SKAction.moveBy(x: -groundTexture.size().width, y: 0, duration: 5)
    
    //元の位置に戻すアクション
    let resetGround = SKAction.moveBy(x: groundTexture.size().width, y: 0, duration: 0)
    
    // 左にスクロール->元の位置->左にスクロールと無限に繰り返すアクション
    let repeatScrollGround = SKAction.repeatForever(SKAction.sequence([moveGound, resetGround]))
    
    //groundのスプライトを配置する
    for i in 0..<needNumber {
      let sprite = SKSpriteNode(texture: groundTexture)
      
      //スプライトの表示する位置を指定する
      sprite.position = CGPoint(
         x: groundTexture.size().width / 2 + groundTexture.size().width * CGFloat(i),
         y: groundTexture.size().height / 2
      )
      
      //スプライトにアクションを設定する
      sprite.run(repeatScrollGround)
      
      //スプライトに物理演算を設定する
      sprite.physicsBody = SKPhysicsBody(rectangleOf: groundTexture.size())
      
      //衝突のカテゴリー設定
      sprite.physicsBody?.categoryBitMask = groundCategory
      
      //衝突の時に動かないように設定する
      sprite.physicsBody?.isDynamic = false
      
      
      //スプライトを追加する
      scrollNode.addChild(sprite)
    }
  
  }

  func setupCloud() {
    //雲の画像を読み込む
    let cloudTexture = SKTexture(imageNamed: "cloud")
    cloudTexture.filteringMode = .nearest
    
    //必要な枚数を計算
    let needCloudNumber = Int(self.frame.size.width / cloudTexture.size().width) + 2
    
    //スクロールするアクションを作成
    //左方向に画像一枚分スクロールさせるアクション
    let moveCloud = SKAction.moveBy(x: -cloudTexture.size().width, y: 0, duration: 20)
    
    //元の位置に戻すアクション
    let resetCloud = SKAction.moveBy(x: cloudTexture.size().width, y: 0, duration: 0)
    
    //左にスクロール->元の位置->左にスクロールと無限に繰り返すアクション
    let repeatScrollCloud = SKAction.repeatForever(SKAction.sequence([moveCloud,resetCloud]))
    
    //スプライトを配置する
    for i in 0..<needCloudNumber {
      let sprite = SKSpriteNode(texture: cloudTexture)
      sprite.zPosition = -100 //一番後ろになるようにする
      
      //スプライトの表示する位置を指定する
      sprite.position = CGPoint(
      x: cloudTexture.size().width / 2 + cloudTexture.size().width * CGFloat(i),
      y: self.size.height - cloudTexture.size().height / 2
      )
      
      //スプライトにアニメーションを設定する
      sprite.run(repeatScrollCloud)
      
      //スプライトを追加する
      scrollNode.addChild(sprite)
    }
    
  }
  
  func setupWall() {
    //壁の画像を呼び込む
    let wallTexture = SKTexture(imageNamed: "wall")
    wallTexture.filteringMode = .linear
    
    //移動する距離を計算
    let movingDistance = CGFloat(self.frame.size.width + wallTexture.size().width)
    
    //画面外まで移動するアクションを作成
    let moveWall = SKAction.moveBy(x: -movingDistance, y: 0, duration: 4)
    
    //自身を取り除くアクションを作成
    let removeWall = SKAction.removeFromParent()
    
    //二つのアニメーションを順に実行するアクションを作成
    let wallAnimation = SKAction.sequence([moveWall,removeWall])
    
    //鳥の画像サイズを取得
    let birdSize = SKTexture(imageNamed: "bird_a").size()
    
    //鳥が通り抜ける隙間の長さを鳥のサイズの三倍とする
    let slit_length = birdSize.height * 3
    
    //隙間位置の上下の振れ幅を鳥のサイズの三倍とする
    let random_y_range = birdSize.height * 3
    
    //下の壁のY軸下限位置（中央位置から下方向の最大振れ幅で下の壁を表示する位置を計算）
    let groundSize = SKTexture(imageNamed: "ground").size()
    let center_y = groundSize.height + (self.frame.size.height - groundSize.height) / 2
    let under_wall_lowest_y = center_y - slit_length / 2 - wallTexture.size().height / 2 - random_y_range / 2
    
    //壁を生成するアクションを作成
    let createWallAnimation = SKAction.run({
      //壁関連のノードを乗せるノードを作成
      let wall = SKNode()
      wall.position = CGPoint(x: self.frame.size.width + wallTexture.size().width / 2 , y: 0)
      wall.zPosition = -50 //雲より手前、地面より奥
      
      //0~random_y_rangeまでのランダム値を生成
      let random_y = CGFloat.random(in: 0..<random_y_range)
      //Y軸の下限にランダムな値を足して、下の壁のY軸座標を決定
      let under_wall_y = under_wall_lowest_y + random_y
      
      //下側の壁を作成
      let under = SKSpriteNode(texture: wallTexture)
      under.position = CGPoint(x: 0, y: under_wall_y)
      
      //スプライトに物理演算を設定する
      under.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
      under.physicsBody?.categoryBitMask = self.wallCategory
      
      //衝突の時に動かないように設定する
      under.physicsBody?.isDynamic = false
      
      wall.addChild(under)
      
      //上側の壁を作成
      let upper = SKSpriteNode(texture: wallTexture)
      upper.position = CGPoint(x: 0, y: under_wall_y + wallTexture.size().height + slit_length)
      
      //スプライトに物理演算を設定する
      upper.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
      upper.physicsBody?.categoryBitMask = self.wallCategory
      
      //衝突の時に動かないように設定する
      upper.physicsBody?.isDynamic = false
      
      
      wall.addChild(upper)
      
      //スコアアップ用のノード
      let scoreNode = SKNode()
      scoreNode.position = CGPoint(x: upper.size.width + birdSize.width / 2, y: self.frame.height / 2)
      scoreNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: upper.size.width, height: self.frame.size.height))
      scoreNode.physicsBody?.isDynamic = false
      scoreNode.physicsBody?.categoryBitMask = self.scoreCategory
      scoreNode.physicsBody?.contactTestBitMask = self.birdCategory
      
      wall.addChild(scoreNode)
      
      wall.run(wallAnimation)
      
      self.wallNode.addChild(wall)
    })
    
    //次の壁作成までの時間待ちのアクションを作成
    let waitAnimation = SKAction.wait(forDuration: 2)
    
    //壁を作成->時間待ち->壁を作成を無限に繰り返すアクションを作成
    let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createWallAnimation,waitAnimation]))
    
    wallNode.run(repeatForeverAnimation)
  }
  
  func setupStar() {
    //星の画像を読み込む
    let starTexture = SKTexture(imageNamed: "star")
    starTexture.filteringMode = .linear
    
    //移動する距離を計算
    let movingDistance = CGFloat(self.frame.size.width + starTexture.size().width + starTexture.size().width * 2)
    
    //画面外まで移動するアクションを作成
    let moveStar = SKAction.moveBy(x: -movingDistance, y: 0, duration: 2)
    
    //自身を取り除くアクションを作成
    let removeStar = SKAction.removeFromParent()
    
    //二つのアニメーションを順に実行するアクションを作成
    let starAnimation = SKAction.sequence([moveStar,removeStar])
    
    //星の画像サイズを取得
    let starSize = SKTexture(imageNamed: "star").size()
    
    //アイテム出現の上下の振れ幅を鳥のサイズの三倍とする
    let random_y_range = starSize.height * 3
    
    //星のY軸下限位置（中央位置から下方向の最大振れ幅で下の壁を表示する位置を計算）
    let groundSize = SKTexture(imageNamed: "ground").size()
    let center_y = groundSize.height + (self.frame.size.height + groundSize.height) / 2
    let under_star_lowest_y = center_y - groundSize.height * 2
    
    //星を生成するアクションを作成
    let createStarAnimation = SKAction.run({
      //星関連のノードを乗せるノードを作成
      let star = SKNode()
      star.position = CGPoint(x: self.frame.size.width + starTexture.size().width * 2, y: 0)
      star.zPosition = -80
      
      //0~random_y_rangeまでのランダム値を生成
      let random_y = CGFloat.random(in: 0..<random_y_range)
      //y軸の下限にランダムな値を足して、星のy軸座標を決定
      let under_star_y = under_star_lowest_y + random_y
      
      //星を作成
      let item = SKSpriteNode(texture: starTexture)
      item.position = CGPoint(x: 0, y: under_star_y)
      
      //スプライトに物理演算を設定する
      item.physicsBody = SKPhysicsBody(circleOfRadius: starSize.height / 2)
      
      //衝突時に動かないように設定
      item.physicsBody?.isDynamic = false
      
      star.addChild(item)
      
      //スコアアップ用のノード
    
      item.physicsBody?.categoryBitMask = self.itemCategory
      item.physicsBody?.contactTestBitMask = self.birdCategory
    
      
      star.run(starAnimation)
      
      self.starNode.addChild(star)
      
    })
    
    let waitAnimation = SKAction.wait(forDuration: 6)
    
    let repeatFoeverAnimation = SKAction.repeatForever(SKAction.sequence([createStarAnimation,waitAnimation]))
    
    starNode.run(repeatFoeverAnimation)
    
    
  }
  
  func setupBird() {
    //鳥の画像を二種類読み込む
    let birdTextureA = SKTexture(imageNamed: "bird_a")
    birdTextureA.filteringMode = .linear
    let birdTextureB = SKTexture(imageNamed: "bird_b")
    birdTextureB.filteringMode = .linear
    
    //二種類のテクスチャを交互に変更するアニメーションを作成
    let textureAnimation = SKAction.animate(with: [birdTextureA, birdTextureB], timePerFrame: 0.2)
    let flap = SKAction.repeatForever(textureAnimation)
    
    //スプライトを作成
    bird = SKSpriteNode(texture: birdTextureA)
    bird.position = CGPoint(x: self.frame.size.width * 0.2, y: self.frame.size.height * 0.7)
    
    //物理演算を設定
    bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height / 2)
    
    //衝突した時に回転させない
    bird.physicsBody?.allowsRotation = false
    
    //衝突のカテゴリー設定
    bird.physicsBody?.categoryBitMask = birdCategory
    bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
    bird.physicsBody?.contactTestBitMask = groundCategory | wallCategory
    
    //アニメーションを設定
    bird.run(flap)
    
    //スプライトを追加する
    addChild(bird)
  }
  
  
  
  //画面タップした時に呼ばれる
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    if scrollNode.speed > 0 {
    //鳥の速度を０にする
    bird.physicsBody?.velocity = CGVector.zero
    
    //鳥に縦方向の力を与える
    bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 15))
    } else if bird.speed == 0 {
      restart()
    }
  }
  
  //SKphysicsContactDelegateのメソッド。衝突した時に呼ばれる
  func didBegin(_ contact: SKPhysicsContact) {
    //ゲームオーバーの時は何もしない
    if scrollNode.speed <= 0 {
      return
    }
    
    if (contact.bodyA.categoryBitMask & itemCategory) == itemCategory || (contact.bodyB.categoryBitMask & itemCategory) == itemCategory {
      if contact.bodyA.categoryBitMask == itemCategory {
        contact.bodyA.node?.removeFromParent()
      }else{
      contact.bodyB.node?.removeFromParent()
      }
      //アイテムスコア用の物体と衝突した
      print("ItemScoreUp")
      itemScore += 1
      itemScoreLabelNode.text = "Item Score:\(itemScore)"
      
      self.run(action)
      
      //ベストアイテムスコア更新か確認する
      var bestItemScore = userDefaults.integer(forKey: "BEST ITEM")
      if itemScore > bestItemScore {
        bestItemScore = itemScore
        bestItemScoreLabelNode.text = "Best Item Score:\(bestItemScore)"
        userDefaults.set(bestItemScore,forKey:"BEST ITEM")
        userDefaults.synchronize()
      }
    }else if (contact.bodyA.categoryBitMask & scoreCategory) == scoreCategory || (contact.bodyB.categoryBitMask & scoreCategory) == scoreCategory {
      //スコア用の物体と衝突した
      print("ScoreUp")
      score += 1
      scoreLabelNode.text = "Score:\(score)"
      
      //ベストスコア更新か確認する
      var bestScore = userDefaults.integer(forKey: "BEST")
      if score > bestScore {
        bestScore = score
        bestScoreLabelNode.text = "Best Score:\(bestScore)"
        userDefaults.set(bestScore,forKey: "BEST")
        userDefaults.synchronize()
      }
    } else  {
      //壁か地面と衝突した
      print("GameOver")
      
      //スクロールを停止させる
      scrollNode.speed = 0
      
      bird.physicsBody?.collisionBitMask = groundCategory
      
      let roll = SKAction.rotate(byAngle: CGFloat(Double.pi) * CGFloat(bird.position.y) * 0.01 ,duration: 1)
      bird.run(roll,completion:{
        self.bird.speed = 0
      })
    }
  }
 
  func restart() {
    score = 0
    scoreLabelNode.text = String("Score:\(score)")
    itemScore = 0
    itemScoreLabelNode.text = String("Item score:\(itemScore)")
    
    bird.position = CGPoint(x: self.frame.size.width * 0.2 , y: self.frame.size.height * 0.7)
    bird.physicsBody?.velocity = CGVector.zero
    bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
    bird.zRotation = 0
    
    wallNode.removeAllChildren()
    
    bird.speed = 1
    scrollNode.speed = 1
  }
  
  func setupScoreLabel() {
    score = 0
    scoreLabelNode = SKLabelNode()
    scoreLabelNode.fontColor = UIColor.black
    scoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 60)
    scoreLabelNode.zPosition = 100
    scoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
    scoreLabelNode.text = "Score:\(score)"
    self.addChild(scoreLabelNode)
    
    bestScoreLabelNode = SKLabelNode()
    bestScoreLabelNode.fontColor = UIColor.black
    bestScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 90)
    bestScoreLabelNode.zPosition = 100
    bestScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
    
    let bestScore = userDefaults.integer(forKey: "BEST")
    bestScoreLabelNode.text = "Best Score:\(bestScore)"
    self.addChild(bestScoreLabelNode)
    
    itemScore = 0
    itemScoreLabelNode = SKLabelNode()
    itemScoreLabelNode.fontColor = UIColor.black
    itemScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 120)
    itemScoreLabelNode.zPosition = 100
    itemScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
    itemScoreLabelNode.text = "Item Score:\(itemScore)"
    self.addChild(itemScoreLabelNode)
    
    bestItemScoreLabelNode = SKLabelNode()
    bestItemScoreLabelNode.fontColor = UIColor.black
    bestItemScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 150)
    bestItemScoreLabelNode.zPosition = 100
    bestItemScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
    
    let bestItemScore = userDefaults.integer(forKey: "BEST ITEM")
    bestItemScoreLabelNode.text = "Best Item Score:\(bestItemScore)"
    self.addChild(bestItemScoreLabelNode)
    
  }
}
