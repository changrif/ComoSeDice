//
//  ViewController.swift
//  comosedice
//
//  Created by Chandler Griffin on 10/28/17.
//  Copyright © 2017 Chandler Griffin. All rights reserved.
//

import UIKit
import ARKit
import SceneKit
import Vision
import ROGoogleTranslate

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet weak var sceneView: ARSCNView!
    var translation: String!
    var fromCoreML: String!
    
    var latestPrediction : String = ""
    var visionRequests = [VNRequest]()
    let dispatchQueueML = DispatchQueue(label: "com.hw.dispatchqueueml")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        runAR()
        
        let defaults = UserDefaults.standard
        
        defaults.set(false, forKey: "color")
        defaults.set(7, forKey: "language")
        defaults.set("es", forKey: "code")
        defaults.synchronize()
        
        guard let selectedModel = try? VNCoreMLModel(for: MobileNet().model) else {
            fatalError("Could not load model.")
        }
        
        let classificationRequest = VNCoreMLRequest(model: selectedModel, completionHandler: classificationCompleteHandler)
        classificationRequest.imageCropAndScaleOption = VNImageCropAndScaleOption.centerCrop
        visionRequests = [classificationRequest]
        
        loopCoreMLUpdate()
    }
    
    func classificationCompleteHandler(request: VNRequest, error: Error?) {
        if error != nil {
            print("Error: " + (error?.localizedDescription)!)
            return
        }
        guard let observations = request.results else {
            print("No results")
            return
        }
        
        let classifications = observations[0...1]
            .flatMap({ $0 as? VNClassificationObservation })
            .map({ "\($0.identifier) \(String(format:"- %.2f", $0.confidence))" })
            .joined(separator: "\n")
        
        
        DispatchQueue.main.async {
            print(classifications)
            print("--")
            
            var debugText:String = ""
            debugText += classifications
            print(debugText)
            
            var objectName:String = "…"
            objectName = classifications.components(separatedBy: "-")[0]
            objectName = objectName.components(separatedBy: ",")[0]
            self.latestPrediction = objectName
            
        }
    }
    
    func loopCoreMLUpdate() {
        dispatchQueueML.async {
            self.updateCoreML()
            
            self.loopCoreMLUpdate()
        }
        
    }
    
    func updateCoreML() {
        let pixbuff : CVPixelBuffer? = (sceneView.session.currentFrame?.capturedImage)
        if pixbuff == nil { return }
        let ciImage = CIImage(cvPixelBuffer: pixbuff!)

        let imageRequestHandler = VNImageRequestHandler(ciImage: ciImage, options: [:])

        do {
            try imageRequestHandler.perform(self.visionRequests)
        } catch {
            print(error)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(true)
        removeAllChildren()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func removeAllChildren()    {
        sceneView.scene.rootNode.enumerateChildNodes { (node, stop) -> Void in
            node.removeFromParentNode()
        }
    }
    
    func runAR()    {
        sceneView.delegate = self
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        
        sceneView.session.run(configuration)
    }

    @IBAction func addText(_ sender: Any) {
        removeAllChildren();
        self.fromCoreML = latestPrediction
        let defaults = UserDefaults.standard
        let params = ROGoogleTranslateParams(source: "en", target: "\(String(describing: defaults.object(forKey: "code")!))", text: "\(self.fromCoreML!)")
        print("\(String(describing: defaults.object(forKey: "code")!))")
        let translator = ROGoogleTranslate()
        translator.apiKey = "AIzaSyCdj72ab4LiZ8eRP7D8hazt71E-dbSDBP0"
        translator.translate(params: params) { (result) in
            self.translation = "\(result)"
            self.addToScreen(text: self.translation)
            
            let synthesizer = AVSpeechSynthesizer()
            let utterance = AVSpeechUtterance(string: self.fromCoreML)
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            synthesizer.speak(utterance)
        }
    }
    
    func addToScreen(text: String)   {
        let text = SCNText(string: "\(text)", extrusionDepth: 1)
        let defaults = UserDefaults.standard
        let material = SCNMaterial()
        
        if(defaults.bool(forKey: "color"))  {
            material.diffuse.contents = UIColor.white
        }   else    {
            material.diffuse.contents = UIColor.black
        }
        text.materials = [material]
        
        let node = SCNNode()
        node.position = SCNVector3(0, 0, 0)
        node.scale = SCNVector3(0.002, 0.002, 0.002)
        node.geometry = text

        
        sceneView.scene.rootNode.addChildNode(node)
        node.simdPosition = self.sceneView.pointOfView!.simdPosition + (self.sceneView.pointOfView?.simdWorldFront)! * 0.5
    }
}
