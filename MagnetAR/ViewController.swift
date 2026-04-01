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
    
    //グローバル変数
    //ノードを生成する間隔を調節
    var weight_i = 0
    var weight = -1
    
    //生成位置
    //position
    var position = SCNVector3(0,0,0)
    var position_s_x = 0.0
    var position_s_y = 0.0
    var position_s_z = 0.0
    var cameraz1st = 0.05//カメラからの距離
    
    //磁気センサ
    let motionManager = CMMotionManager()//デバイスのモーションセンサを使う
    //磁気データ（３軸）
    var mx = 0.0
    var my = 0.0
    var mz = 0.0
    var fukaku = 0.0//磁気ベクトルの伏角
    var kakudo = 0.0
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
    
    var isChanging = false//CHANGEボタンの入切
    var CHANGEcount = 0//場合分け
    
    var isLength = false//ABSボタンの入切
    var lengthcount = 0//場合分け
    
    var existentNode: SCNNode?
    
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

        motionManager.startDeviceMotionUpdates(using: .xMagneticNorthZVertical)//真北の使用をONにして磁気センサを使う
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
    
    @IBAction func REC(_ sender: Any) {
       
        
        RECcount = RECcount + 1
        if RECcount < 2{
            REC_start_action()
            isTouching = true
            isChanging = true
            CHANGEcount = CHANGEcount + 1
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
            Thread.sleep(forTimeInterval: 0.0001)
        }
        NodeNumber = 0
        Thread.sleep(forTimeInterval: 0.01)
    }
    
    @IBAction func CHANGE(_ sender: Any) {
        CHANGEcount = CHANGEcount + 1
        if CHANGEcount < 2
        {//self.CHANGE.layer.cornerRadius = 15
            self.CHANGE.layer.backgroundColor = CHANGEColor
            isChanging = true
        }else{//self.CHANGE.layer.cornerRadius = 3
            isChanging = false
            CHANGEcount = 0
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

    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        if isTouching == true {
            if weight_i < weight {
                //ノードの生成速度を落とすために、一定の値を越えるまで空の関数を回し続ける
                Empty()
                weight_i = weight_i + 1
            }else{
                Draw()
                weight_i = 0
            }
        }
    }
    
    func Empty(){}
    
    func Draw(){
        guard let camera = sceneView.pointOfView else{
            return
    }
        let deviceNode = SCNNode()//デバイスを設定
        let cameraPos = SCNVector3(0,0,-cameraz1st)//カメラのポジションを取得
        position = camera.convertPosition(cameraPos, to: nil)


        
        //magnet
        if let magnetoData = motionManager.deviceMotion?.magneticField{
        mx = round(100000*magnetoData.field.x)/100000
        my = round(100000*magnetoData.field.y)/100000
        mz = round(100000*magnetoData.field.z)/100000


            
            
        //magneto calc
        magneto_abs = sqrt(mx*mx + my*my + mz*mz)
        let magneto_abs_xy = sqrt(mx*mx + my*my)
        var fai = 0.0
        var sita = 0.0
        if mz != 0{
            fai = atan(magneto_abs_xy/mz)
        }
        if mx != 0{
            sita = atan(my/mx)
        }
            
  
            if isTouching == true && isChanging == false && isLength == true {
       
                magneto_abs = magneto_abs/20
    
                let Point_m = SCNCylinder(radius: 0.00090, height: CGFloat(magneto_abs))
                Point_m.firstMaterial?.diffuse.contents = UIColor.black

                let Point_mNode = SCNNode(geometry: Point_m)
                Point_mNode.position = SCNVector3(0.0,magneto_abs/2,0.0)
     
                magneto_abs = magneto_abs/2
    
                let length_m = SCNCylinder(radius: 0.00088, height: CGFloat(magneto_abs))
                length_m.firstMaterial?.diffuse.contents = UIColor.black
        
                let length_mNode = SCNNode(geometry: length_m)
                length_mNode.position = SCNVector3(0,0,0)
        
                let vector_mNode = SCNNode()
                vector_mNode.addChildNode(Point_mNode)
                vector_mNode.addChildNode(length_mNode)
                
                vector_mNode.pivot = SCNMatrix4MakeTranslation(0.0, -Float(magneto_abs)/2, 0.0)
      
                if mz>0{
          
                    if mx>0{
                        vector_mNode.eulerAngles = SCNVector3(3.141592/2,fai,sita)
                    }else{
                        vector_mNode.eulerAngles = SCNVector3(3.141592/2,-fai,sita)
                    }
                    
                }else{
                    
                    if mx>0{
                        vector_mNode.eulerAngles = SCNVector3(-3.141592/2,fai,sita)
                    }else{
                        vector_mNode.eulerAngles = SCNVector3(-3.141592/2,-fai,sita)
                    }
       
                }
       
                magneto_abs = magneto_abs * 40
       
                deviceNode.addChildNode(vector_mNode)
                deviceNode.name = "Node"
                deviceNode.eulerAngles = camera.eulerAngles
                deviceNode.position = position
                objectNode.addChildNode(deviceNode)
       
                NodeNumber = NodeNumber + 1
       
                if my != 0.0{
                    magtext = round(magneto_abs*1000)/1000
                    let magtext_1 = "\(magtext)"
                    magnetoLabel.text = String(magtext_1)
                }

            }
        
            if isTouching == true && isChanging == false && isLength == false{
            
                let Point_m = SCNCylinder(radius: 0.00016, height: CGFloat(magneto_length))
                Point_m.firstMaterial?.diffuse.contents = UIColor.black

                let Point_mNode = SCNNode(geometry: Point_m)
                Point_mNode.position = SCNVector3(0.0,magneto_length/2,0.0)
                
                let length_m = SCNCylinder(radius: 0.00015, height: CGFloat(magneto_length))
                length_m.firstMaterial?.diffuse.contents = UIColor.black

                let length_mNode = SCNNode(geometry: length_m)
                length_mNode.position = SCNVector3(0,0,0)
                
                let vector_mNode = SCNNode()
                vector_mNode.addChildNode(Point_mNode)
                vector_mNode.addChildNode(length_mNode)

                vector_mNode.pivot = SCNMatrix4MakeTranslation(0.0, -Float(magneto_length)/2, 0.0)
                
                if mz>0{
                    if mx>0{
                        vector_mNode.eulerAngles = SCNVector3(3.141592/2,fai,sita)
                    }else{
                        vector_mNode.eulerAngles = SCNVector3(3.141592/2,-fai,sita)
                    }
                }else{
                    if mx>0{
                        vector_mNode.eulerAngles = SCNVector3(-3.141592/2,fai,sita)
                    }else{
                        vector_mNode.eulerAngles = SCNVector3(-3.141592/2,-fai,sita)
                    }
                }
                
                deviceNode.addChildNode(vector_mNode)
                deviceNode.name = "Node"
                deviceNode.eulerAngles = camera.eulerAngles
                deviceNode.position = position
                objectNode.addChildNode(deviceNode)
            
                NodeNumber = NodeNumber + 1
                
                if my != 0.0{
                    magtext = round(magneto_abs*1000)/1000
                    let magtext_1 = "\(magtext)"
                    
                    magnetoLabel.text = String(magtext_1)
                }
                
            }
            
            if isTouching == true && isChanging == true && isLength == true{
                
                magneto_abs = magneto_abs/20
                
                let Point_m = SCNCylinder(radius: 0.00895, height: CGFloat(magneto_abs))
                Point_m.firstMaterial?.diffuse.contents = MagnetoColor

                let Point_mNode = SCNNode(geometry: Point_m)
                Point_mNode.position = SCNVector3(0.0,magneto_abs/2,0.0)
                
                magneto_abs = magneto_abs/2 * 1.1
                
                let length_m = SCNCylinder(radius: 0.00940, height: CGFloat(magneto_abs))
                length_m.firstMaterial?.diffuse.contents = CylinderColor
                
                let length_mNode = SCNNode(geometry: length_m)
                length_mNode.position = SCNVector3(0,0,0)
                
                let vector_mNode = SCNNode()
                vector_mNode.addChildNode(Point_mNode)
                vector_mNode.addChildNode(length_mNode)
                
                vector_mNode.pivot = SCNMatrix4MakeTranslation(0.0, -Float(magneto_abs)/2, 0.0)
                
                if mz>0{
                    if mx>0{
                        vector_mNode.eulerAngles = SCNVector3(3.141592/2,fai,sita)
                    }else{
                        vector_mNode.eulerAngles = SCNVector3(3.141592/2,-fai,sita)
                    }
                    
                }else{
                    
                    if mx>0{
                        vector_mNode.eulerAngles = SCNVector3(-3.141592/2,fai,sita)
                    }else{
                        vector_mNode.eulerAngles = SCNVector3(-3.141592/2,-fai,sita)
                    }
                    
                }
        
                magneto_abs = magneto_abs * 20 * 2 / 1.1
                
                deviceNode.addChildNode(vector_mNode)
                deviceNode.name = "Node"
                deviceNode.eulerAngles = camera.eulerAngles
                deviceNode.position = position
                objectNode.addChildNode(deviceNode)
            
                NodeNumber = NodeNumber + 1
                
                if my != 0.0{
                    magtext = round(magneto_abs*1000)/1000
                    let magtext_1 = "\(magtext)"
                    magnetoLabel.text = String(magtext_1)
                }
                
            }
            
            if isTouching == true && isChanging == true && isLength == false{
                
                let Point_m = SCNCylinder(radius: 0.00028, height: CGFloat(magneto_length))
                Point_m.firstMaterial?.diffuse.contents = MagnetoColor

                let Point_mNode = SCNNode(geometry: Point_m)
                Point_mNode.position = SCNVector3(0.0,magneto_length/2,0.0)
            
                let length_m = SCNCylinder(radius: 0.00027, height: 0.0135)
                length_m.firstMaterial?.diffuse.contents = CylinderColor
        
                let length_mNode = SCNNode(geometry: length_m)
                length_mNode.position = SCNVector3(0,0,0)
                
                let vector_mNode = SCNNode()
                vector_mNode.addChildNode(Point_mNode)
                vector_mNode.addChildNode(length_mNode)

                vector_mNode.pivot = SCNMatrix4MakeTranslation(0.0, -Float(magneto_length)/2, 0.0)
                
               
                
                
                
                
                if mz>0{
                
                    if mx>0{
                        vector_mNode.eulerAngles = SCNVector3(3.141592/2,fai,sita)
                    }else{
                        vector_mNode.eulerAngles = SCNVector3(3.141592/2,-fai,sita)
                    }
                
                }else{
                    
                    if mx>0{
                        vector_mNode.eulerAngles = SCNVector3(-3.141592/2,fai,sita)
                    }else{
                        vector_mNode.eulerAngles = SCNVector3(-3.141592/2,-fai,sita)
                    }
                    
                }
                
               
                
                
                
                
                
                deviceNode.addChildNode(vector_mNode)
                deviceNode.name = "Node"
                deviceNode.eulerAngles = camera.eulerAngles
                deviceNode.position = position
                objectNode.addChildNode(deviceNode)
            
                NodeNumber = NodeNumber + 1
                
             
                
                if my != 0.0{
                    magtext = round(magneto_abs*1000)/1000
                    let magtext_1 = "\(magtext)"
                    
                    magnetoLabel.text = String(magtext_1)
                }
                
            }
                
            
            
            guard isTouching else {
        return
        
    }
            func makeobject(){
            let Point_m = SCNCylinder(radius: 0.00028, height: CGFloat(magneto_length))
            Point_m.firstMaterial?.diffuse.contents = MagnetoColor

            let Point_mNode = SCNNode(geometry: Point_m)
            Point_mNode.position = SCNVector3(0.0,magneto_length/2,0.0)
        
            let length_m = SCNCylinder(radius: 0.00027, height: 0.0135)
            length_m.firstMaterial?.diffuse.contents = CylinderColor
    
            let length_mNode = SCNNode(geometry: length_m)
            length_mNode.position = SCNVector3(0,0,0)
            
            let vector_mNode = SCNNode()
            vector_mNode.addChildNode(Point_mNode)
            vector_mNode.addChildNode(length_mNode)

            vector_mNode.pivot = SCNMatrix4MakeTranslation(0.0, -Float(magneto_length)/2, 0.0)
            
           
            
            
            
            
            if mz>0{
            
                if mx>0{
                    vector_mNode.eulerAngles = SCNVector3(3.141592/2,fai,sita)
                }else{
                    vector_mNode.eulerAngles = SCNVector3(3.141592/2,-fai,sita)
                }
            
            }else{
                
                if mx>0{
                    vector_mNode.eulerAngles = SCNVector3(-3.141592/2,fai,sita)
                }else{
                    vector_mNode.eulerAngles = SCNVector3(-3.141592/2,-fai,sita)
                }
                
            }
            
           
            
            
            
            
            
            deviceNode.addChildNode(vector_mNode)
            deviceNode.name = "Node"
            deviceNode.eulerAngles = camera.eulerAngles
            deviceNode.position = position
            objectNode.addChildNode(deviceNode)
        
            NodeNumber = NodeNumber + 1
            
         
            
            if my != 0.0{
                magtext = round(magneto_abs*1000)/1000
                let magtext_1 = "\(magtext)"
                
                magnetoLabel.text = String(magtext_1)
            }
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

