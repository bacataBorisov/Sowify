//
//  ViewController.swift
//  Serial Over WiFi
//
//  Created by Bacata (Vasil) Borisov on 25.12.22.
//

import UIKit
import CocoaMQTT
import AVFoundation
import SwiftTooltipKit

class ViewController: UIViewController {
    
    @IBOutlet weak var configurationButtonOutlet: UIButton!
    @IBOutlet weak var configurationInfo: UILabel!
    @IBOutlet weak var playButtonAppearance: UIButton!
    @IBOutlet weak var displayNMEA: UITextView!
    @IBOutlet weak var cmdTextField: UITextField!
    @IBOutlet weak var sendCmdRPi: UIButton!
    @IBOutlet weak var rebootRPi: UIButton!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    //MARK: - Declaring Variables & Constants
    
    //get identifier
    private static var identifier: String = {
        var systemInfo = utsname()
        uname(&systemInfo)
        let mirror = Mirror(reflecting: systemInfo.machine)
        let identifier = mirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }()
    //create a unique name for every different device
    private let mqttClient = CocoaMQTT(clientID: "[\(String(describing: UIDevice.current.identifierForVendor!.uuidString))] + [\(identifier)]", host: "raspberrypi.local", port: 1883)
    
    private let topic = "getData"
    private let topic_cmd = "command"
    private let topic_feedback = "feedback"
    private let topic_warning = "warning"
    private let ser_conf_topic = "configuration"
    private let topic_mediator = "mediator"
    
    
    private var connection_flag: Bool = false
    private var play_connect_flag: Bool = false
    private var background_flag: Bool = false
    private var foreground_flag: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Enable Idle Timer (phone will not go to sleep)
        UIApplication.shared.isIdleTimerDisabled = true
        //check the mode for the initial icon view
        if self.traitCollection.userInterfaceStyle == .dark {
            cmdTextField.setLeftView(image: UIImage(systemName: "terminal")!)
        } else {
            cmdTextField.setLeftView(image: UIImage(systemName: "terminal.fill")!)
        }
        //MARK: - Shapes and Colors for the Main Window
        displayNMEA.layer.cornerRadius = 8
        displayNMEA.layer.masksToBounds = true
        displayNMEA.backgroundColor = UIColor(named: "display")
        displayNMEA.isScrollEnabled = true
        displayNMEA.font = .systemFont(ofSize: 16, weight: .semibold)
        
        //status bar
        configurationInfo.layer.cornerRadius = 8
        configurationInfo.layer.masksToBounds = true
        configurationInfo.text = "Sowify"
        configurationInfo.font = .systemFont(ofSize: 24, weight: .semibold)
        
        //cmd field attributes
        cmdTextField.delegate = self
        cmdTextField.layer.cornerRadius = 8
        cmdTextField.layer.masksToBounds = true
        
        //display screen delegate in case I need to trigger methods
        displayNMEA.delegate = self
        
        //set up mqttClient delegate to itself, so it will trigger methods
        mqttClient.delegate = self
        
        //MARK: - cmdRPi power off button gestures
        
        //Tap function will call when user tap on button
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector (tap))
        //Long function will call when user long press on button.
        let longGesture = UILongPressGestureRecognizer(target: self, action: #selector(long))
        tapGesture.numberOfTapsRequired = 1
        //tapGesture.cancelsTouchesInView = false
        sendCmdRPi.addGestureRecognizer(tapGesture)
        sendCmdRPi.addGestureRecognizer(longGesture)
        
        let tapGestureReboot = UITapGestureRecognizer(target: self, action: #selector (tapReboot))
        //Long function will call when user long press on button.
        let longGestureReboot = UILongPressGestureRecognizer(target: self, action: #selector(longReboot))
        tapGestureReboot.numberOfTapsRequired = 1
        //tapGestureReboot.cancelsTouchesInView = false
        
        rebootRPi.addGestureRecognizer(tapGestureReboot)
        rebootRPi.addGestureRecognizer(longGestureReboot)
        
        //application DID move to background - it is very important, because
        //there is a difference between willResign and didEnter background
        
        let _: Void = NotificationCenter.default.addObserver(self, selector:#selector(appMovedToBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        
        //Mark:- application DID move to foreground
        
        let _: Void = NotificationCenter.default.addObserver(self, selector:#selector(appMovedToForeground),name: UIApplication.willEnterForegroundNotification, object: nil)
        
        let _: Void = NotificationCenter.default.addObserver(self, selector:#selector(appTerminating),name: UIApplication.willTerminateNotification, object: nil)
        
    }
    
    //MARK: User Actions
    
    //MARK: - Background Method Implementation
    
    @objc func appMovedToBackground() {
        
        //Print statement used during development / debugging
        //print("App moved to background!")
        mqttClient.disconnect()
        background_flag = true
        //disable idle timer
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    //MARK: - Foreground Method Implementation
    
    @objc func appMovedToForeground() {
        //Print statement used during development / debugging
        //print("App moved to foreground!")
        _ = mqttClient.connect(timeout: 20)
        connection_flag = true
        foreground_flag = true
        //enable idle timer
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    @objc func appTerminating() {
        
        //Print statement used during development / debugging
        //print("app is terminating")
        
        //Close the connection before the app exits
        mqttClient.disconnect()
    }
    
    //MARK: - User Tap Gestures for Reboot and Shutdown
    
    //Single Tap Shutdown Hint Pop-Up
    @objc func tap() {
        
        sendCmdRPi.tooltip("hold for power off", orientation: .top, configuration: {configuration in
            configuration.labelConfiguration.font = .systemFont(ofSize: 18, weight: .semibold)
            configuration.labelConfiguration.textColor = UIColor(named: "running")!
            
            return configuration
        })
    }
    //Long Tap Shutdown - Action
    @objc func long() {
        UIDevice.vibration()
        mqttClient.publish(topic_mediator, withString: "shutdown", qos: .qos2)
    }
    
    //Single Tap Gesture Reboot Hint Pop-Up
    @objc func tapReboot() {
        
        rebootRPi.tooltip("hold for reboot", orientation: .top, configuration: {configuration in
            configuration.labelConfiguration.font = .systemFont(ofSize: 18, weight: .semibold)
            configuration.labelConfiguration.textColor = UIColor(named: "running")!
            
            return configuration
        })
    }
    //Long Tap Reboot - Action
    @objc func longReboot() {
        UIDevice.vibration()
        mqttClient.publish(topic_mediator, withString: "reboot", qos: .qos2)
    }
    
    
    func stopBlink(_: UIButton) {
        
    }
    //change attributes when dark and light modes are toggled
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        
        if self.traitCollection.userInterfaceStyle == .dark {
            
            cmdTextField.setLeftView(image: UIImage(systemName: "terminal")!)
        } else {
            
            cmdTextField.setLeftView(image: UIImage(systemName: "terminal.fill")!)
        }
    }
    
    //Dismiss the Keyboard
    @IBAction func userTapped(_ sender: UITapGestureRecognizer) {
        cmdTextField.resignFirstResponder()
    }
    //Clear the Screen
    @IBAction func clearScreenPressed(_ sender: UIButton) {
        displayNMEA.text = ""
    }
    
    //Play / Pause Button
    @IBAction func connectButtonPressed(_ sender: UIButton) {
        
        //Check initial conditions
        if SerialDataSettings.flag == true {
            // hold / resume screen
            if sender.isSelected == false {
                if mqttClient.connState == .connected {
                    
                    mqttClient.subscribe(topic_warning)
                    mqttClient.subscribe(topic_feedback)
                    mqttClient.subscribe(topic)
                    
                    mqttClient.publish(ser_conf_topic, withString: "\(SerialDataSettings.ser_configuration[0]),\(SerialDataSettings.ser_configuration[1]),\(SerialDataSettings.ser_configuration[2]),\(SerialDataSettings.ser_configuration[3]),\(SerialDataSettings.ser_configuration[4])")
                    
                    sender.isSelected = true
                    
                    //Buttons border
                    playButtonAppearance.layer.borderWidth = 1.5
                    playButtonAppearance.layer.cornerRadius = 6
                    playButtonAppearance.layer.borderColor = UIColor(named: "running")?.cgColor
                    
                    //remove the blink from the button
                    playButtonAppearance.layer.removeAllAnimations()
                    playButtonAppearance.alpha = 1
                    
                } else {
                    _ = mqttClient.connect(timeout: 20)
                    play_connect_flag = true
                    
                }
                
            } else {
                mqttClient.unsubscribe(topic)
                self.playButtonAppearance.alpha = 0
                UIView.animate(withDuration: 0.80, delay: 0.0, options: [.curveEaseIn, .repeat, .autoreverse, .allowUserInteraction], animations: {() -> Void in
                    self.playButtonAppearance.alpha = 1.0
                })
                sender.isSelected = false
            }
        } else {
            
            playButtonAppearance.tooltip("choose IOIOI settings", orientation: .top, configuration: {configuration in
                configuration.labelConfiguration.font = .systemFont(ofSize: 18, weight: .semibold)
                configuration.labelConfiguration.textColor = UIColor(named: "running")!
                
                return configuration
            })
        }
    }
    
    //going to the second VC to select serial settings
    @IBAction func configurationButtonPressed(_ sender: UIButton) {
        
        playButtonAppearance.isSelected = false
        mqttClient.unsubscribe(topic)
        
        //implement prepare for segue - without sending any values
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "serial_configuration", sender: nil)
        }
    }
    
    //MARK: - Functions Go Here
    
    //Prepare for Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "serial_configuration" {
            
            _ = segue.destination as! SerialConfiguration
        }
    }
}//END OF VIEW CONTROLLER

//MARK: Extensions Start Here

//MARK: TextField Icon on the Left
extension UITextField {
    func setLeftView(image: UIImage) {
        let iconView = UIImageView(frame: CGRect(x: 5, y: 0, width: 50, height: 35))
        iconView.image = image
        let iconContainerView: UIView = UIView(frame: CGRect(x: 5, y: 0, width: 50, height: 35))
        iconContainerView.addSubview(iconView)
        leftView = iconContainerView
        leftViewMode = .always
        self.tintColor = .lightGray
    }
}
//MARK: UITextField Delegate Methods
extension ViewController: UITextFieldDelegate {
    //create extension for this later - return true if the textfield has to be editable
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return true
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if let text = cmdTextField.text {
            updateScreen(display: displayNMEA, message: text)
            mqttClient.publish(topic_cmd, withString: "\(text)" + "\r")
        }
        //dismiss the keyboard on pressing enter and clear the textfield
        textField.resignFirstResponder()
        textField.text = ""
        return true
    }
}

//MARK: - Vibration & Sound
extension UIDevice {
    static func soundConnect() {
        
        // With vibration
        let systemSoundID: SystemSoundID = 1003
        AudioServicesPlaySystemSound(systemSoundID)
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }
    
    static func soundDisconnect() {
        
        // With vibration
        let systemSoundID: SystemSoundID = 1004
        AudioServicesPlaySystemSound(systemSoundID)
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }
    
    static func vibration() {
        AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
    }
}
//MARK: - Update Screen & AutoScroll

extension ViewController: UITextViewDelegate {
    
    //tells the delegate that the UITextView is not editable
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        return false
    }
    
    func updateScreen(display: UITextView, message: String) {
        
        //displayNMEA.isEditable = false
        displayNMEA.text = ("\(displayNMEA.text ?? "")\(message)\n")
        
        //Scroll to the Bottom
        if displayNMEA.text.count > 0 {
            let top = NSMakeRange(Int((displayNMEA.bounds.height - displayNMEA.contentSize.height)), 0)
            displayNMEA.scrollRangeToVisible(top)
        }
    }
}


//MARK: - CocoaMQTT Protocol Delegates

extension ViewController: CocoaMQTTDelegate {
    
    //Handling messages' topics
    
    func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16) {
        
        let messageDecoded = String(bytes: message.payload, encoding: .utf8)
        
        if let messageDecodedSafe = messageDecoded {
            
            //Receive the configuration back from the RPi & display it in the label field
            
            if message.topic == topic_feedback {
                configurationInfo.text = messageDecodedSafe
                configurationInfo.backgroundColor = UIColor(named: "running")
                configurationInfo.textColor = .systemBackground
            } else if message.topic == topic_warning {
                configurationInfo.text = messageDecodedSafe
                configurationInfo.backgroundColor = UIColor(named: "warning")
                configurationInfo.textColor = .systemBackground
                playButtonAppearance.isSelected = false
            } else {
                updateScreen(display: displayNMEA, message: messageDecodedSafe)
            }
        } else {
            updateScreen(display: displayNMEA, message: "Could not decode message!")
        }
        
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
        
    }
    
    func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError err: Error?) {
        
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didStateChangeTo state: CocoaMQTTConnState) {
        if state == .connecting {
            
            //Print statement used during development / debugging
            //print("didEnter .connecting state")
            
            if foreground_flag == true {
                
                //Print statement used during development / debugging
                //print("connecting")
                
                //Start spinner activity indicator
                activityIndicator.startAnimating()
                foreground_flag = false
                
            } else {
                
                //Print statement used during development / debugging
                //print("connecting")
                
                //Start spinner activity indicator
                activityIndicator.startAnimating()
                
                configurationInfo.text = "{Trying to Connect}"
                configurationInfo.backgroundColor = UIColor(named: "warning")
            }
            
            
        } else if state == .disconnected {
            
            //Print statement used during development / debugging
            //print("disconnected")
            
            //Stop the status bar animation - if it comes from the background - stop everything, else try to reconnect
            if background_flag == true {
                
                //reset flags
                connection_flag = false
                background_flag = false
                
            } else {
                _ = mqttClient.connect(timeout: 20)
            }
            
        } else {
            
            //Print statement used during development / debugging
            //print("connected")
            
            //stop the spinner - activity indicator
            activityIndicator.stopAnimating()
            UIDevice.soundConnect()
            
            if SerialDataSettings.flag == true {
                
                if playButtonAppearance.isSelected == false {
                    playButtonAppearance.isSelected = false
                    self.playButtonAppearance.alpha = 0
                    UIView.animate(withDuration: 0.80, delay: 0.0, options: [.curveEaseIn, .repeat, .autoreverse, .allowUserInteraction], animations: {() -> Void in
                        self.playButtonAppearance.alpha = 1.0
                    })
                    
                    mqttClient.subscribe(topic_warning)
                    mqttClient.subscribe(topic_feedback)
                    mqttClient.publish(ser_conf_topic, withString: "\(SerialDataSettings.ser_configuration[0]),\(SerialDataSettings.ser_configuration[1]),\(SerialDataSettings.ser_configuration[2]),\(SerialDataSettings.ser_configuration[3]),\(SerialDataSettings.ser_configuration[4])")
                    
                    //playButtonAppearance.blink()
                    
                } else {
                    playButtonAppearance.isSelected = true
                    //remove the blink from the button
                    playButtonAppearance.layer.removeAllAnimations()
                    playButtonAppearance.alpha = 1
                    
                    mqttClient.subscribe(topic_warning)
                    mqttClient.subscribe(topic_feedback)
                    mqttClient.subscribe(topic)
                    
                    mqttClient.publish(ser_conf_topic, withString: "\(SerialDataSettings.ser_configuration[0]),\(SerialDataSettings.ser_configuration[1]),\(SerialDataSettings.ser_configuration[2]),\(SerialDataSettings.ser_configuration[3]),\(SerialDataSettings.ser_configuration[4]) ")
                    
                    //Buttons borders - it gives cerftain weight to the play button
                    playButtonAppearance.layer.borderWidth = 1.5
                    playButtonAppearance.layer.cornerRadius = 6
                    playButtonAppearance.layer.borderColor = UIColor(named: "running")?.cgColor
                    
                    //reset the flag that came from the play button
                    play_connect_flag = false
                }
                
            } else {
                configurationInfo.text = "Serial Over Wi-Fy"
                configurationInfo.font = .systemFont(ofSize: 24, weight: .semibold)
                configurationInfo.backgroundColor = UIColor(named: "running")
            }
        }
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopics success: NSDictionary, failed: [String]) {
        
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
        
        //print("message send \(message.topic)")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {
        
        //print(".didReceive publish ACK \(id)")
        
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopics topics: [String]) {
        
    }
    
    func mqttDidPing(_ mqtt: CocoaMQTT) {
        //print("didSend .ping")
    }
    
    func mqttDidReceivePong(_ mqtt: CocoaMQTT) {
        //print("didReceive .pong")
    }
}


