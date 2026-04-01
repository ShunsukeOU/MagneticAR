// MagnetAR codes
//  Created by Shunsuke Taira 2021/11/23
//　Last update 2026/04/01
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
    //生成位置
    var position = SCNVector3(0,0,0)
    var cameraz1st = 0.15//カメラからの距離
    
    //磁気センサ
    let motionManager = CMMotionManager()//デバイスのモーションセンサを使う
    //磁気データ（３軸）
    var mx = 0.0
    var my = 0.0
    var mz = 0.0
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
    var lastDrawTime: TimeInterval = 0

    override func viewDidLoad() {//260401 .frameを削除（UI改善のため、手動指定からAuto Layoutにするため）
        super.viewDidLoad()
        sceneView.delegate = self
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
            //self.magnetoLabel.text = "0.0"
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
        //スクリーンショットに映したくないボタンを一時的に隠す
        let buttonsToHide = [REC, DEL, CHANGE, SHOWABS, SS]
        buttonsToHide.forEach { $0?.isHidden = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, false, 0.0)
            self.view.drawHierarchy(in: self.view.bounds, afterScreenUpdates: true)
            let screenshotImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            //隠していたボタンを元に戻す
            buttonsToHide.forEach { $0?.isHidden = false }
                
            if let image = screenshotImage {
                UIImageWriteToSavedPhotosAlbum(image, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil)
                //画面を一瞬白く光らせる
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
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            print("保存エラー: \(error.localizedDescription)")
        } else {
            let generator = UINotificationFeedbackGenerator()//触覚フィードバック
            generator.notificationOccurred(.success)
        }
    }
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        // 磁気データの取得（インターバル計算のために常に最新値が必要）
        if let magnetoData = motionManager.deviceMotion?.magneticField {
            let field = magnetoData.field
            mx = field.x
            my = field.y
            mz = field.z
            magneto_abs = sqrt(mx*mx + my*my + mz*mz)
        }

        if isTouching == true {
            let frequency = 10.0 + max(0, (magneto_abs - 50.0) * 0.2)
            let currentInterval = 1.0 / min(50.0, max(10.0, frequency))

            //オブジェクト生成のタイミング（ここで表示も更新する）
            if time - lastDrawTime > currentInterval {
                Draw() // 矢印の生成
                lastDrawTime = time
                let displayValue = magneto_abs
                DispatchQueue.main.async {
                    self.magnetoLabel.text = String(format: "%.2f", displayValue)//計算した時速密度を小数点第二位まで表示させる
                }
            }
        } else {
            DispatchQueue.main.async {
                if self.magnetoLabel.text != "0.00" {
                    self.magnetoLabel.text = "0.00"
                }
            }
        }
    }
    //磁力線のベクトルノードを生成する共通関数
    func createVectorNode(tipHeight: Double, tipRadius: Double, tipColor: UIColor,
                          bodyHeight: Double, bodyRadius: Double, bodyColor: UIColor,
                          mx: Double, my: Double, mz: Double) -> SCNNode {
        
        let vectorRoot = SCNNode()
        let pointGeo = SCNCylinder(radius: CGFloat(tipRadius), height: CGFloat(tipHeight))
        pointGeo.firstMaterial?.diffuse.contents = tipColor
        let pointNode = SCNNode(geometry: pointGeo)
        pointNode.position = SCNVector3(0.0, tipHeight / 2 + bodyHeight / 2, 0.0)
        
        let bodyGeo = SCNCylinder(radius: CGFloat(bodyRadius), height: CGFloat(bodyHeight))
        bodyGeo.firstMaterial?.diffuse.contents = bodyColor
        let bodyNode = SCNNode(geometry: bodyGeo)
        bodyNode.position = SCNVector3(0, 0, 0)
        
        vectorRoot.addChildNode(pointNode)
        vectorRoot.addChildNode(bodyNode)
        
        let targetVector = simd_normalize(simd_float3(Float(mx), Float(my), Float(mz)))
        
        let upVector = simd_float3(0, 1, 0)
        
        let rotation = simd_quaternion(upVector, targetVector)
        vectorRoot.simdOrientation = rotation
        
        return vectorRoot
    }
    
    func Draw() {
        guard let camera = sceneView.pointOfView else { return }
        
        //カメラとデバイスの位置計算
        let cameraPos = SCNVector3(0, 0, -cameraz1st)
        position = camera.convertPosition(cameraPos, to: nil)
        
        //磁気データの取得
        guard let magnetoData = motionManager.deviceMotion?.magneticField else { return }
        
        let raw_mx = magnetoData.field.x
        let raw_my = magnetoData.field.y
        let raw_mz = magnetoData.field.z
        
        magneto_abs = sqrt(raw_mx*raw_mx + raw_my*raw_my + raw_mz*raw_mz)
        
        guard isTouching else { return }
        
        var tipH = 0.0, tipR = 0.0, bodyH = 0.0, bodyR = 0.0
            var tipC = UIColor.black, bodyC = UIColor.black
            
            if !isChanging {
                // 【黒色モード】
                tipC = .black
                bodyC = .black
                if isLength {
                    //黒大
                    tipH = 0.15
                    tipR = 0.0020
                    bodyH = tipH
                    bodyR = 0.0020
                } else {
                    //黒小
                    tipH = magneto_length*2
                    tipR = 0.0010
                    bodyH = tipH
                    bodyR = 0.0010
                }
            } else {
                tipC = MagnetoColor
                bodyC = CylinderColor
                if isLength {
                    tipH = 0.15
                    tipR = 0.0020
                    bodyH = tipH
                    bodyR = 0.0020
                } else {
                    tipH = magneto_length*2
                    tipR = 0.0010
                    bodyH = tipH
                    bodyR = 0.0010
                }
            }
        let vector_mNode = createVectorNode(tipHeight: tipH, tipRadius: tipR, tipColor: tipC,
                                            bodyHeight: bodyH, bodyRadius: bodyR, bodyColor: bodyC,
                                            mx: raw_mx, my: raw_my, mz: raw_mz)
        
        let deviceNode = SCNNode()
        deviceNode.addChildNode(vector_mNode)
        deviceNode.name = "Node"
        
        //デバイスノードの姿勢をカメラと完全に一致させる
        //これにより、子ノードであるvector_mNodeがカメラ相対のセンサーデータで正しく回転する
        deviceNode.eulerAngles = camera.eulerAngles
        deviceNode.position = position
        
        objectNode.addChildNode(deviceNode)
        NodeNumber += 1
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
    

