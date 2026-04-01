// MagnetAR codes
//  Created by Shunsuke Taira 2021/11/23
//
//インポート
import UIKit
import SceneKit
import ARKit
import CoreMotion

//クラスの宣言
class ViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet var sceneView: ARSCNView!//ARシーンビューの読み込み
    @IBOutlet weak var REC: UIButton!//RECボタン
    @IBOutlet weak var DEL: UIButton!//CLEARボタン
    @IBOutlet weak var CHANGE: UIButton!//色を変えるボタン
    @IBOutlet weak var SHOWABS: UIButton!//地磁気測定用のver.
    @IBOutlet weak var magnetoLabel: UILabel!//磁気量のラベル
    @IBOutlet weak var unit: UILabel!//単位μTを表示
    @IBOutlet weak var SS: UIButton! // SS
    //グローバル変数
    //ノードを生成する間隔を調節（太さによる可視化を廃止→生成速度による磁場の強さの可視化を試みる）
    //var weight_i = 0
    //var weight = -1
    //生成位置
    //position
    var position = SCNVector3(0,0,0)
    //この辺はもう使わなくなった
    //var position_s_x = 0.0
    //var position_s_y = 0.0
    //var position_s_z = 0.0
    var cameraz1st = 0.15//カメラからの距離。０だと生成したオブジェクトが見えないので少し奥側に生成位置を設定する（Swiftでは手前側がz軸の＋方向。）
    
    //磁気センサ
    let motionManager = CMMotionManager()//デバイスのモーションセンサを使う
    //磁気データ（３軸）
    var mx = 0.0
    var my = 0.0
    var mz = 0.0
    //var fukaku = 0.0//磁気ベクトルの伏角
    //var kakudo = 0.0
    var magtext = 0.0//磁気量
    
    //矢印の描画
    var magneto_abs = 0.0//磁気ベクトルの大きさ
    var magneto_length = 0.0095//長さ固定時の長さ
    let MagnetoColor = UIColor(red: 255/255,green: 0/255,blue: 0/255,alpha: 1.0)//矢印の三角形部分の色（N極）
    let CylinderColor = UIColor(red: 0/255, green: 50/255, blue: 255/255,alpha: 1.0)//矢印の棒部分の色（S極）
    let CHANGEColor = CGColor(red: 0/255, green:255/255, blue: 0/255,alpha:0.5)
    let ABSColor = CGColor(red: 0/255, green:255/255, blue: 0/255,alpha:0.5)
    let DefaltColor = CGColor(red: 255/255, green:255/255, blue: 255/255,alpha:0.3)
    let objectNode = SCNNode()//親ノード
    var NodeNumber :Int = 0//ノードの番号
    //Button
    var isTouching = false//RECボタンの入切
    var RECcount = 0//場合分け用の変数
    
    var isChanging = true//CHANGEボタンの入切
    //var CHANGEcount = 1//場合分け
    
    var isLength = false//ABSボタンの入切
    var lengthcount = 0//場合分け
    
    //var existentNode: SCNNode?
    
    override func viewDidLoad() {//260401 .frameを削除（UI改善のため、手動指定からAuto Layoutにするため）
        super.viewDidLoad()
        sceneView.delegate = self
        //ラベルのデザイン
        //magnetoLabel.frame = CGRect(x: 25, y: 26, width: 100, height: 41)
        //unit.frame = CGRect(x: 125, y: 26, width: 80, height: 41)
        //ボタンのデザイン
        REC.layer.cornerRadius = 32.5//角を丸くする
        //REC.frame = CGRect(x: (self.view.frame.size.width)/2.0 - 32.5, y: (self.view.frame.size.height) - 90, width: 65, height: 65)
        DEL.layer.cornerRadius = 6.25//角を丸くする
        //DEL.frame = CGRect(x: (self.view.frame.size.width)/2.0 - 137.5, y: (self.view.frame.size.height) - 80, width: 50, height: 50)
        self.DEL.layer.borderColor = UIColor.white.cgColor//外枠の色を指定
        self.DEL.layer.borderWidth = 1.0//外枠の太さを指定
        CHANGE.layer.cornerRadius = 22.5//角を丸くする
        //CHANGE.frame = CGRect(x: (self.view.frame.size.width)/2.0 - 75, y: (self.view.frame.size.height) - 125, width: 45, height: 45)
        self.CHANGE.layer.borderColor = UIColor.white.cgColor//外枠の色を指定
        self.CHANGE.layer.borderWidth = 1.0//外枠の太さを指定
        self.CHANGE.backgroundColor = UIColor(red:0/255, green:255/255, blue:0/255, alpha:0.5)
        SHOWABS.layer.cornerRadius = 22.5//角を丸くする
        //SHOWABS.frame = CGRect(x: (self.view.frame.size.width)/2.0 + 32.5, y: (self.view.frame.size.height) - 125, width: 45, height: 45)
        self.SHOWABS.layer.borderColor = UIColor.white.cgColor//外枠の色を指定
        self.SHOWABS.layer.borderWidth = 1.0//外枠の太さを指定
        
        motionManager.startDeviceMotionUpdates(using: .xMagneticNorthZVertical)//真北の使用をONにして磁気センサを使う→実際の地磁気の北を、
        sceneView.scene = SCNScene()
        sceneView.scene.rootNode.addChildNode(objectNode)
        motionManager.startMagnetometerUpdates()
        motionManager.magnetometerUpdateInterval = 0.1//データを取得する間隔

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARWorldTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        motionManager.stopMagnetometerUpdates()
        sceneView.session.pause()
    }
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let height = self.SS.bounds.height
        self.SS.layer.cornerRadius = height / 2.0      // これだけでOK
        self.SS.layer.masksToBounds = true
        
        // 以下は変わらず
        self.SS.layer.borderColor = UIColor.white.cgColor
        self.SS.layer.borderWidth = 1.0
        self.SS.backgroundColor = UIColor(red: 0, green: 255/255, blue: 0, alpha: 0.5)
    }
    @IBAction func REC(_ sender: Any) {
        
        
        RECcount = RECcount + 1
        if RECcount < 2{
            REC_start_action()
            isTouching = true
            //isChanging = true
            //CHANGEcount = CHANGEcount + 1
        }else{
            REC_stop_action()
            isTouching = false
            RECcount = 0
            
            
        }
    }
    
    func REC_start_action(){
        UIView.animate(withDuration: 0.2){
            self.REC.setTitle("STOP", for: .normal)
            self.REC.layer.cornerRadius = 6.25
            self.unit.text = "μT"
        }
    }
    
    func REC_stop_action(){
        UIView.animate(withDuration: 0.2){
            self.REC.setTitle("REC", for: .normal)
            self.REC.layer.cornerRadius = 32.5
            // self.unit.text = "　"
        }
    }
    
    @IBAction func DEL(_ sender: Any) {
        let NodeN = objectNode.childNodes.count
        //全Nodeを消去
        for _ in 0..<NodeN  {
            let dell_node = objectNode.childNode(withName: "Node", recursively: true)
            dell_node?.removeFromParentNode()
            self.magnetoLabel.text = "0.0"
            //Thread.sleep(forTimeInterval: 0.0001)
        }
        NodeNumber = 0
       // Thread.sleep(forTimeInterval: 0.01)
    }
    
    @IBAction func CHANGE(_ sender: Any) {
        // 今の状態を反転させる (trueならfalseへ、falseならtrueへ)
        isChanging = !isChanging
        
        if isChanging {
            // ON（カラーモード）になった時
            self.CHANGE.layer.backgroundColor = CHANGEColor
        } else {
            // OFF（黒モード）になった時
            self.CHANGE.layer.backgroundColor = DefaltColor
        }
    }
    
    @IBAction func SHOWABS(_ sender: Any) {
        
        lengthcount = lengthcount + 1
        if lengthcount < 2{
            // self.SHOWABS.layer.cornerRadius = 15
            self.SHOWABS.layer.backgroundColor = ABSColor
            isLength = true
        }else{//self.SHOWABS.layer.cornerRadius = 3
            self.SHOWABS.layer.backgroundColor = DefaltColor
            isLength = false
            lengthcount = 0
        }
    }
    
    @IBAction func SS(_ sender: Any) {
        // 1. スクリーンショットに映したくないボタンを一時的に隠す
            let buttonsToHide = [REC, DEL, CHANGE, SHOWABS, SS] // SSボタン自身も隠す
            buttonsToHide.forEach { $0?.isHidden = true }
            
            // 2. 画面全体のレンダリング（ラベルを含めるため）
            // UIの描画が更新されるのをわずかに待つため、メインスレッドで実行
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                
                // 3. 画面全体のコンテキストから画像を生成
                UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, false, 0.0)
                self.view.drawHierarchy(in: self.view.bounds, afterScreenUpdates: true)
                let screenshotImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                
                // 4. 隠していたボタンを元に戻す
                buttonsToHide.forEach { $0?.isHidden = false }
                
                if let image = screenshotImage {
                    // 5. 写真ライブラリに保存する
                    UIImageWriteToSavedPhotosAlbum(image, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil)
                    
                    // 6. 撮った瞬間の視覚的フィードバック（一瞬白く光らせる）
                    let flashView = UIView(frame: self.view.frame)
                    flashView.backgroundColor = .white
                    self.view.addSubview(flashView)
                    UIView.animate(withDuration: 0.3, animations: {
                        flashView.alpha = 0
                    }, completion: { _ in
                        flashView.removeFromSuperview()
                    })
                }
            }
        }
    
    // 保存完了時に呼ばれる関数（エラーチェック用）
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            print("保存エラー: \(error.localizedDescription)")
        } else {
            // 成功したらiPhoneを軽く振動させて知らせる（触覚フィードバック）
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }
    
    var lastDrawTime: TimeInterval = 0
    //let drawInterval: TimeInterval = 0.085//0.2秒に１回生成する→動的計算に移行したためコメントアウト
    
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        if isTouching == true {
            // 最新の磁気データを取得して magneto_abs を更新（描画間隔の計算に使用）
            if let magnetoData = motionManager.deviceMotion?.magneticField {
                let field = magnetoData.field
                magneto_abs = sqrt(field.x * field.x + field.y * field.y + field.z * field.z)
            }

            // 生成間隔（インターバル）を計算
            // デフォルト(50μT以下)で0.1秒、磁気が強くなるほど短くなり、最大0.02秒まで加速
            // 計算式: 10Hz(0.1s)から50Hz(0.02s)の間で線形補完
            let frequency = 10.0 + max(0, (magneto_abs - 50.0) * 0.2) // 50μT超から加速開始
            let currentInterval = 1.0 / min(50.0, max(10.0, frequency)) // 0.1s〜0.02sに制限

            // 前回の生成から一定時間が経過していたら実行
            if time - lastDrawTime > currentInterval {
                Draw()
                lastDrawTime = time
            }
        }
    }
    
    //func Empty(){} いらなくなった。関数を挟んで速度調整はあんまり良くなさそう
    
    // 磁力線のベクトルノードを生成する共通関数
    func createVectorNode(tipHeight: Double, tipRadius: Double, tipColor: UIColor,
                          bodyHeight: Double, bodyRadius: Double, bodyColor: UIColor,
                          mx: Double, my: Double, mz: Double) -> SCNNode {
        
        let vectorRoot = SCNNode()
        
        // 1. 先端部分（赤色：N極・北方向）の作成
        let pointGeo = SCNCylinder(radius: CGFloat(tipRadius), height: CGFloat(tipHeight))
        pointGeo.firstMaterial?.diffuse.contents = tipColor
        let pointNode = SCNNode(geometry: pointGeo)
        // Y軸のプラス方向（上）に配置
        pointNode.position = SCNVector3(0.0, tipHeight / 2 + bodyHeight / 2, 0.0)
        
        // 2. 胴体部分（青色：S極・南方向）の作成
        let bodyGeo = SCNCylinder(radius: CGFloat(bodyRadius), height: CGFloat(bodyHeight))
        bodyGeo.firstMaterial?.diffuse.contents = bodyColor
        let bodyNode = SCNNode(geometry: bodyGeo)
        bodyNode.position = SCNVector3(0, 0, 0)
        
        // 3. ルートノードに結合
        vectorRoot.addChildNode(pointNode)
        vectorRoot.addChildNode(bodyNode)
        
        // 4. 【最重要】クォータニオンを使ったスマートな回転処理
        // センサーから取得した磁界の向きを正規化（長さを1にした方向ベクトル）する
        let targetVector = simd_normalize(simd_float3(Float(mx), Float(my), Float(mz)))
        
        // 生成したばかりの円柱オブジェクトが向いている初期のローカル方向（Y軸のプラス方向）
        let upVector = simd_float3(0, 1, 0)
        
        // upVectorからtargetVectorへ向けるための「回転量（クォータニオン）」を自動計算
        let rotation = simd_quaternion(upVector, targetVector)
        
        // オブジェクトに回転を適用する
        vectorRoot.simdOrientation = rotation
        
        return vectorRoot
    }
    
    func Draw() {
        guard let camera = sceneView.pointOfView else { return }
        
        // 1. カメラとデバイスの位置計算
        let cameraPos = SCNVector3(0, 0, -cameraz1st)
        position = camera.convertPosition(cameraPos, to: nil)
        
        // 2. 磁気データの取得
        guard let magnetoData = motionManager.deviceMotion?.magneticField else { return }
        
        // SceneKitのsimd_quaternionに渡すため、ここでは丸め処理を行わず生データを使います
        // （表示用のラベルのみ丸め処理を行うのがベストプラクティスです）
        let raw_mx = magnetoData.field.x
        let raw_my = magnetoData.field.y
        let raw_mz = magnetoData.field.z
        
        // 3. 磁気計算（絶対値のみ計算）
        magneto_abs = sqrt(raw_mx*raw_mx + raw_my*raw_my + raw_mz*raw_mz)
        
        // 4. 描画判定
        guard isTouching else { return }
        
        var tipH = 0.0, tipR = 0.0, bodyH = 0.0, bodyR = 0.0
            var tipC = UIColor.black, bodyC = UIColor.black
            
            if !isChanging {
                // 【黒色モード】
                tipC = .black
                bodyC = .black
                if isLength {
                    // --- 黒・大きい ---
                    tipH = 0.15          // 10cm固定
                    tipR = 0.0020       // 太さはそのまま
                    bodyH = tipH        // 比率 1:1
                    bodyR = 0.0020
                } else {
                    // --- 黒・小さい ---
                    tipH = magneto_length*2 // 固定長 (0.0095)
                    tipR = 0.0010         // 太さはそのまま
                    bodyH = tipH          // 比率 1:1
                    bodyR = 0.0010
                }
            } else {
                // 【カラフルモード】
                tipC = MagnetoColor    // 赤
                bodyC = CylinderColor  // 青
                if isLength {
                    // --- カラー・大きい ---
                    tipH = 0.15          // 10cm固定
                    tipR = 0.0020
                    bodyH = tipH        // 比率 1:1
                    bodyR = 0.0020
                } else {
                    // --- カラー・小さい ---
                    tipH = magneto_length*2
                    tipR = 0.0010
                    bodyH = tipH        // 0.0135から変更して 1:1 に
                    bodyR = 0.0010
                }
            }
        // 6. ノードの生成と追加
        // 角度（fai, sita）の代わりに、磁力ベクトルのx, y, zをそのまま渡す
        let vector_mNode = createVectorNode(tipHeight: tipH, tipRadius: tipR, tipColor: tipC,
                                            bodyHeight: bodyH, bodyRadius: bodyR, bodyColor: bodyC,
                                            mx: raw_mx, my: raw_my, mz: raw_mz)
        
        let deviceNode = SCNNode()
        deviceNode.addChildNode(vector_mNode)
        deviceNode.name = "Node"
        
        // デバイスノードの姿勢をカメラと完全に一致させる
        // （これにより、子ノードであるvector_mNodeがカメラ相対のセンサーデータで正しく回転する）
        deviceNode.eulerAngles = camera.eulerAngles
        deviceNode.position = position
        
        objectNode.addChildNode(deviceNode)
        NodeNumber += 1
        
        // 7. ラベルの更新（表示するときだけ丸め処理を行う）
        // 改良後の Draw() 関数内のラベル更新部分
        if my != 0.0 {
            magtext = round(magneto_abs * 1000) / 1000
            
            // UIの更新をメインスレッドに渡す
            DispatchQueue.main.async {
                self.magnetoLabel.text = "\(self.magtext)"
            }
        }
    }
        
        // MARK: - ARSCNViewDelegate
        
        /*
         // Override to create and configure nodes for anchors added to the view's session.
         func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
         let node = SCNNode()
         
         return node
         }
         */
        
        func session(_ session: ARSession, didFailWithError error: Error) {
            // Present an error message to the user
            
        }
        
        func sessionWasInterrupted(_ session: ARSession) {
            // Inform the user that the session has been interrupted, for example, by presenting an overlay
            
        }
        
        func sessionInterruptionEnded(_ session: ARSession) {
            // Reset tracking and/or remove existing anchors if consistent tracking is required
            
        }
        
        
    }
    

