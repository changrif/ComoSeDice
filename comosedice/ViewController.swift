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
import AVFoundation
import AVKit
import Vision

class ViewController: UIViewController, ARSCNViewDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {

    @IBOutlet weak var sceneView: ARSCNView!
    var translation: String!
    var fromCoreML: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        sceneView.delegate = self
        
        let defaults = UserDefaults.standard
        
        defaults.set(false, forKey: "color")
        defaults.set(7, forKey: "language")
        defaults.set("es", forKey: "code")
        defaults.synchronize()
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        
        sceneView.session.run(configuration)
        startAVSesh()
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

    @IBAction func addText(_ sender: Any) {
        removeAllChildren();
        let defaults = UserDefaults.standard
        let text = self.fromCoreML.components(separatedBy: ",").first!
        
        let params = GoogleTranslateParams(source: "en", target: "\(String(describing: defaults.object(forKey: "code")!))", text: "\(text)")
        print("\(String(describing: defaults.object(forKey: "code")!))")
        let translator = GoogleTranslate()
        translator.apiKey = "AIzaSyCdj72ab4LiZ8eRP7D8hazt71E-dbSDBP0"
        translator.translate(params: params) { (result) in
            self.translation = "\(result)"
            self.addToScreen(text: self.translation)
            let synthesizer = AVSpeechSynthesizer()
            let utterance = AVSpeechUtterance(string: text)
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
        node.position = SCNVector3(0, 0.02, -0.1)
        node.scale = SCNVector3(0.001, 0.001, 0.001)
        node.geometry = text
        
        sceneView.scene.rootNode.addChildNode(node)
    }
    
    func startAVSesh()  {
        let captureSession = AVCaptureSession()
        guard let captureDevice = AVCaptureDevice.default(for: .video) else{return}
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else{return}
        captureSession.addInput(input)
        captureSession.startRunning()
        
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQ"))
        captureSession.addOutput(dataOutput)
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // print(“camera was able to capture frame”,Date())
        
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else{return}
        
        guard let model = try? VNCoreMLModel(for: MobileNet().model) else{return}
        let request = VNCoreMLRequest(model: model) {
            (finishedReq, err) in
            guard let results = finishedReq.results as? [VNClassificationObservation] else{return}
            guard let observation = results.first else {return}
            self.fromCoreML = observation.identifier
            print("\(observation.identifier)")
        }
        
        
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
    }
}
