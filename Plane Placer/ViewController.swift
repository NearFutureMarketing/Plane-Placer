//  Plane Placer
// A simple loading screen to keep the user aware of any planes that may have been detected.
//  Designed, Developed, & Distributed by Casey on 12/18/17.
//  Copyright © 2017 Near Future Marketing. All rights reserved. www.nearfuture.marketing
//  You may use this code freely in any project.

import UIKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var resetButton: ARSCNView!
    @IBOutlet weak var consoleLabel: UILabel!
    var rootPlanePlaced = false
    let configuration = ARWorldTrackingConfiguration()

    
    override var prefersStatusBarHidden: Bool {
        return true
        //Most AR projects look better with a hidden status bar; battery life becomes harder to track.
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.delegate = self
        let scene = SCNScene()
        // Set the scene to the view
        sceneView.scene = scene
        // Do any additional setup a)fter loading the view, typically from a nib.
        updateDetectedSurfaces()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Create a session configuration
        configuration.planeDetection = .horizontal
        // Run the view's session
        sceneView.session.run(configuration)
    }

    @IBAction func resetPressed(_ sender: Any) {
        //Clears the scene & world origin.
        rootPlanePlaced = false
        self.sceneView.session.pause()
        self.sceneView.scene.rootNode.enumerateChildNodes { (newChildNode, _) in
            newChildNode.removeFromParentNode()
        }
        self.sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        viewDidLoad()
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        // Update content only for plane anchors and nodes matching the setup created in `renderer(_:didAdd:for:)`.
        guard let planeAnchor = anchor as?  ARPlaneAnchor,
            let planeNode = node.childNodes.first,
            let plane = planeNode.geometry as? SCNPlane
            else { return }
        
        // Plane estimation may shift the center of a plane relative to its anchor's transform.
        planeNode.simdPosition = float3(planeAnchor.center.x, 0, planeAnchor.center.z)
        
        /*
         Plane estimation may extend the size of the plane, or combine previously detected
         planes into a larger one. In the latter case, `ARSCNView` automatically deletes the
         corresponding node for one plane, then calls this method to update the size of
         the remaining plane.
         */
        plane.width = CGFloat(planeAnchor.extent.x)
        plane.height = CGFloat(planeAnchor.extent.z)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        // Create a SceneKit plane to visualize the plane anchor using its position and extent.
        let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
        let planeNode = SCNNode(geometry: plane)
        planeNode.simdPosition = float3(planeAnchor.center.x, 0, planeAnchor.center.z)
        /*
         `SCNPlane` is vertically oriented in its local coordinate space, so
         rotate the plane to match the horizontal orientation of `ARPlaneAnchor`.
         */
        planeNode.eulerAngles.x = -.pi / 2
        
        // Make the plane visualization semitransparent to clearly show real-world placement.
        planeNode.geometry?.firstMaterial?.diffuse.contents = UIColor.yellow
        planeNode.opacity = 0.13
        /*
         Add the plane visualization to the ARKit-managed node so that it tracks
         changes in the plane anchor as plane estimation continues.
         */
        node.addChildNode(planeNode)
        
        if rootPlanePlaced != true {
            rootPlanePlaced = true
        }
    }
    
    @objc func updateDetectedSurfaces() {
        if rootPlanePlaced == true && consoleLabel.text != "Surface detected!" {
            consoleLabel.text = "Surface detected!"
        } else if rootPlanePlaced == false {
            switch consoleLabel.text! {
            case "No surfaces detected.": consoleLabel.text = "No surfaces detected.."
            case "No surfaces detected..": consoleLabel.text = "No surfaces detected..."
            default: consoleLabel.text = "No surfaces detected."
            }
            let consoleRefreshTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.updateDetectedSurfaces), userInfo: nil, repeats: false)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if consoleLabel.text == "Surface detected!" {
            consoleLabel.text = "Created by Casey Pollock (2017)"
        }
    }
}
