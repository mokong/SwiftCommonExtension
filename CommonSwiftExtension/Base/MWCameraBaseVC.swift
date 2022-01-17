//
//  MWCameraBaseVC.swift
//  MWWaterMarkCamera
//
//  Created by Horizon on 11/1/2022.
//

import UIKit
import AVFoundation
import CoreMotion

/// 相机基类
class MWCameraBaseVC: UIViewController {

    // MARK: - properties
    // 禁止点击聚焦区域
    var unableFocusRects: [String] = []
    // 默认摄像头
    fileprivate var devicePosition: AVCaptureDevice.Position = .back
    // 默认闪光灯模式
    fileprivate var torchMode: AVCaptureDevice.TorchMode = .auto
    // 拍摄分辨率
    fileprivate var sessionPreset: AVCaptureSession.Preset = .high {
        didSet {
            updateSessionPreset()
        }
    }
    
    // 画面拉伸方式
    fileprivate var videoGravity: AVLayerVideoGravity = .resizeAspectFill {
        didSet {
            previewLayer?.videoGravity = videoGravity
        }
    }
    
    // 系统是否支持旋转
    fileprivate var isSysRotateOn: Bool = false
    
    // 输入设备和输出设备之间的数据传递
    fileprivate var session: AVCaptureSession?
    // 拍摄输入流
    fileprivate var captureInput: AVCaptureDeviceInput?
    // 拍摄输出流
    fileprivate var photoOutput: AVCapturePhotoOutput?
    // 视频输出流
    fileprivate var videoOutput: AVCaptureVideoDataOutput?
    // 预览图层，显示相机拍摄到的画面
    fileprivate var previewLayer: AVCaptureVideoPreviewLayer?
    
    // 拍摄生成的预览照片
    fileprivate var takedImageView: UIImageView?
    fileprivate var takedImage: UIImage?

    // 设置不能连续相应点击，否则连续相应过程中会出现屏幕中间部分变暗
    fileprivate var isSwitchingCamera: Bool = false
    // 是否正在生成照片
    fileprivate var isTakingPhoto: Bool = false
    // 最新设备方向
    fileprivate var lastestDeviceOrientation: UIDeviceOrientation = UIDevice.current.orientation
    
    // 缩放比例
    fileprivate var beginPinchScale: CGFloat = 1.0
    fileprivate var lastScaleFactor: CGFloat = 1.0
    
    // MARK: - view life cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        modalPresentationStyle = .fullScreen
        
        configCamera()
        loadCameraDefaultSettings()
        initCameraSubviews()
        observeDeviceMotion()
        session?.startRunning()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        session?.startRunning()
        updateFocusCurson(with: self.view.center)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.layer.bounds
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
    }
    
    deinit {
        if session?.isRunning == true {
            session?.stopRunning()
        }
        
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: AVAudioSession.SetActiveOptions.notifyOthersOnDeactivation)
        } catch {
            print(error)
        }
        
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - init
    init() {
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
        sessionPreset = .hd1280x720
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func configCamera() {
        session = AVCaptureSession()
        
        // 设置相机画面输入流
        let deviceSession = AVCaptureDevice.DiscoverySession.init(deviceTypes: getDeviceType(), mediaType: AVMediaType.video, position: devicePosition)
        if deviceSession.devices.count > 0, let device = deviceSession.devices.first {
            do {
                captureInput = try AVCaptureDeviceInput(device: device)
                // 将输入添加到 session
                if session?.canAddInput(captureInput!) == true {
                    session?.addInput(captureInput!)
                }
            } catch {
                print(error)
            }
        }
        
        // 设置相机画面输出流
        photoOutput = AVCapturePhotoOutput()
        if session?.canAddOutput(photoOutput!) == true {
            session?.addOutput(photoOutput!)
        }
        
        // 创建摄像数据输出流并将其添加到会话对象上，---> 用于识别光线强弱
        videoOutput = AVCaptureVideoDataOutput()
        videoOutput?.setSampleBufferDelegate(self, queue: DispatchQueue.main)
        if session?.canAddOutput(videoOutput!) == true {
            session?.addOutput(videoOutput!)
        }
        
        // 设置拍摄质量
        updateSessionPreset()
        
        // 预览层
        previewLayer = AVCaptureVideoPreviewLayer(session: session!)
        view.layer.masksToBounds = true
        previewLayer?.videoGravity = .resizeAspect
        view.layer.insertSublayer(previewLayer!, at: 0)
    }
    
    fileprivate func loadCameraDefaultSettings() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(adjustFocusPoint(_:)))
        tap.delegate = self
        self.view.addGestureRecognizer(tap)
        
        let pinchGes = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchGesture(_:)))
        self.view.addGestureRecognizer(pinchGes)
        
        UIDevice.cameraAuthorization { granted in
            if !granted {
                UIDevice.noAuthHandle(with: .video, on: self)
            }
        }

        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord)
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print(error)
        }
    }
    
    fileprivate func initCameraSubviews() {
        setupTakedImageView()
    }
    
    fileprivate func setupTakedImageView() {
        let tempImageView = UIImageView(frame: UIScreen.main.bounds)
        tempImageView.backgroundColor = UIColor.black
        tempImageView.isHidden = true
        tempImageView.contentMode = .scaleAspectFit
        self.view.addSubview(tempImageView)
        
        self.takedImageView = tempImageView
    }
        
    // MARK: - utils
    
    /// 切换摄像头
    func switchCamera() {
        if isSwitchingCamera {
            return
        }
        
        isSwitchingCamera = true
        
        DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + 0.38) { // 0.8s 后，可再次点击
            self.isSwitchingCamera = false
        }
        
        guard let position = captureInput?.device.position else {
            return
        }
        
        let animation = CATransition()
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        animation.duration = 0.3
        animation.type = CATransitionType(rawValue: "oglFlip")
        
        var newVideoInput: AVCaptureDeviceInput?
        var needPosition: AVCaptureDevice.Position?
        if position == .back {
            needPosition = .front
            animation.subtype = CATransitionSubtype.fromRight
        }
        else {
            needPosition = .back
            animation.subtype = CATransitionSubtype.fromLeft
        }
        
        let deviceSession = AVCaptureDevice.DiscoverySession.init(deviceTypes: getDeviceType(), mediaType: AVMediaType.video, position: needPosition!)
        if deviceSession.devices.count > 0, let device = deviceSession.devices.first {
            do {
                newVideoInput = try AVCaptureDeviceInput(device: device)
                session?.beginConfiguration()
                session?.removeInput(captureInput!)
                
                if newVideoInput?.device.supportsSessionPreset(sessionPreset) == true {
                    session?.sessionPreset = sessionPreset
                }
                else {
                    session?.sessionPreset = .hd1280x720
                }
                
                if session?.canAddInput(newVideoInput!) == true {
                    session?.addInput(newVideoInput!)
                    captureInput = newVideoInput
                }
                else if session?.canAddInput(captureInput!) == true {
                    session?.addInput(captureInput!)
                }
                session?.commitConfiguration()
                previewLayer?.add(animation, forKey: nil)
            } catch {
                print(error)
            }
        }
        
    }
    
    /// 设置闪光灯
    func updateTorchMode(_ mode: AVCaptureDevice.TorchMode) {
        guard let device = captureInput?.device else {
            return
        }

        if device.hasTorch {
            do {
                try device.lockForConfiguration()
                device.torchMode = mode
                device.unlockForConfiguration()
            } catch {
                print(error)
            }
        }
    }
//
//    func configFlashMode() {
//        guard let device = captureInput?.device else {
//            return
//        }
//
//        if device.isFlashModeSupported(flashMode),
//           device.hasFlash == true {
//            do {
//                try device.lockForConfiguration()
//                device.flashMode = flashMode
//                device.unlockForConfiguration()
//            } catch {
//                print(error)
//            }
//        }
//    }
    
    /// 亮度回调
    func handleBrightnessChanged(_ brightneddValue: CGFloat) {
        
    }
    
    /// 监控设备方向
    fileprivate func observeDeviceMotion() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleDeviceOrientationChange),
                                               name: UIDevice.orientationDidChangeNotification,
                                               object: nil)
    }
    
    /// 处理设备方向改变
    @objc fileprivate func handleDeviceOrientationChange() {
        let deviceOrientation = UIDevice.current.orientation
        if deviceOrientation == .unknown {
            return
        }
        
        // 能进入这个通知处理方法，说明系统支持旋转
        isSysRotateOn = true
        
        let lastRotateValue = customRotateValue(from: lastestDeviceOrientation)
        let rotateValue = customRotateValue(from: deviceOrientation)
        
        let degree = (rotateValue - lastRotateValue) * .pi / 2.0
        
        deviceOrientationChange(degree)
    }
    
    func onTakePicture() {
        
    }
    
    // MARK: - action
    
    
    // MARK: - other
    
    
    fileprivate func updateSessionPreset() {
        if session?.canSetSessionPreset(sessionPreset) == true {
            session?.sessionPreset = sessionPreset
        }
        else {
            session?.sessionPreset = .hd1280x720
        }
    }
    
    // MARK: - 设置聚焦点
    /// 设置聚焦点
    @objc fileprivate func adjustFocusPoint(_ tap: UITapGestureRecognizer) {
        if session?.isRunning != true {
            return
        }
        
        let point = tap.location(in: self.view)
        for rect in unableFocusRects {
            let unableFocusRect = NSCoder.cgRect(for: rect)
            if unableFocusRect.contains(point) {
                return
            }
        }
        
        updateFocusCurson(with: point)
    }
    
    /// 设置聚焦光标位置
    fileprivate func updateFocusCurson(with point: CGPoint) {
        // 将 UI 坐标转化为摄像头坐标
        let cameraPoint = previewLayer?.captureDevicePointConverted(fromLayerPoint: point)
        focus(with: AVCaptureDevice.FocusMode.autoFocus, exposureMode: AVCaptureDevice.ExposureMode.autoExpose, at: cameraPoint!)
        cameraTapActionFoucus(point, cameraPoint: cameraPoint!)
    }
    
    func cameraTapActionFoucus(_ point: CGPoint, cameraPoint: CGPoint) {
        
    }
    
    /// 设置聚焦点
    fileprivate func focus(with focusMode: AVCaptureDevice.FocusMode, exposureMode: AVCaptureDevice.ExposureMode, at point: CGPoint) {
        guard let device = captureInput?.device else {
            return
        }
        
        do {
            //注意改变设备属性前一定要首先调用lockForConfiguration:调用完之后使用unlockForConfiguration方法解锁
            try device.lockForConfiguration()
            
            // 设置聚焦模式
            if device.isFocusModeSupported(focusMode) {
                device.focusMode = focusMode
            }
            
            // 设置聚焦点
            if device.isFocusPointOfInterestSupported {
                device.focusPointOfInterest = point
            }
            
            // 曝光模式
            if device.isExposureModeSupported(exposureMode) {
                device.exposureMode = exposureMode
            }
            
            // 曝光点
            if device.isExposurePointOfInterestSupported {
                device.exposurePointOfInterest = point
            }
            
            device.unlockForConfiguration()
        } catch {
            print(error)
        }
    }
    
    func getDeviceType() -> [AVCaptureDevice.DeviceType] {
        var list = [AVCaptureDevice.DeviceType.builtInWideAngleCamera, AVCaptureDevice.DeviceType.builtInTelephotoCamera]
        if #available(iOS 10.2, *) {
            list.append(AVCaptureDevice.DeviceType.builtInDualCamera)
        }
        
        if #available(iOS 11.1, *) {
            list.append(AVCaptureDevice.DeviceType.builtInTrueDepthCamera)
        }
        return list
    }
    
    func takeImageCompletion(_ image: UIImage?) {
        takedImageView?.isHidden = false
        takedImage = image
        takedImageView?.image = image
        session?.stopRunning()
        
        cameraTakePicture(image, position: captureInput?.device.position)
    }
    
    func cameraTakePicture(_ image: UIImage?, position: AVCaptureDevice.Position?) {
        
    }
    
    func generateImage(with imageData: Data?) -> UIImage? {
        guard let data = imageData, let input = captureInput else {
            return nil
        }
        
        let position = input.device.position
        if position == AVCaptureDevice.Position.back {
            let tImage = UIImage(data: data)
            if isSysRotateOn {
                let imgOrientation = UIImage.getUIImageOrientation(from: position)
                let resultImage = UIImage(cgImage: tImage!.cgImage!, scale: 1.0, orientation: imgOrientation)
                return resultImage
            }
            else {
                return tImage
            }
        }
        else {
            let imgOrientation = UIImage.Orientation.leftMirrored
            let tImage = UIImage(data: data)
            let resultImage = UIImage(cgImage: tImage!.cgImage!, scale: 1.0, orientation: imgOrientation)
            return resultImage
        }
    }
    
    func onDismiss() {
        if presentedViewController != nil {
            dismiss(animated: true, completion: nil)
        }
        else {
            navigationController?.popViewController(animated: true)
        }
    }
    
    fileprivate func updateVideoZoomFactor(_ zoomFactor: CGFloat) {
        guard let device = captureInput?.device else {
            return
        }
        
        do {
            try device.lockForConfiguration()
            
            var validZoomValue = zoomFactor
            if validZoomValue <= 1.0 {
                validZoomValue = 1.0
            }
            
            if validZoomValue > device.activeFormat.videoMaxZoomFactor {
                validZoomValue = device.activeFormat.videoMaxZoomFactor
            }
            
            device.videoZoomFactor = validZoomValue
            
            device.unlockForConfiguration()
        } catch {
            print(error)
        }
    }
    
    // 设备方向旋转的处理方法
    func deviceOrientationChange(_ angle: Double) {
        
    }
    
    fileprivate func customRotateValue(from deviceOrientation: UIDeviceOrientation) -> Double {
        var customValue = 1.0
        switch deviceOrientation {
        case .portrait:
            customValue = 1.0
        case .landscapeLeft:
            customValue = 2.0
        case .portraitUpsideDown:
            customValue = 3.0
        case .landscapeRight:
            customValue = 4.0
        default:
            break
        }
        return customValue
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }


}

extension MWCameraBaseVC: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    @objc func handlePinchGesture(_ gesture: UIPinchGestureRecognizer) {
        if gesture.state == .ended {
            beginPinchScale = 0.0
            lastScaleFactor = captureInput!.device.videoZoomFactor
        }
        else {
            if beginPinchScale == 0.0 {
                beginPinchScale = gesture.scale
            }
            
            let zoomFactor = gesture.scale + lastScaleFactor - beginPinchScale
            updateVideoZoomFactor(zoomFactor)
        }
    }
}

extension MWCameraBaseVC: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        let time = CMTimeGetSeconds(output.recordedDuration)
        if time < 0.3 {
            // 视频长度小于0.3s，则作为拍照处理
            onTakePicture()
            return
        }
        
        session?.stopRunning()
    }
    
}

extension MWCameraBaseVC: AVCapturePhotoCaptureDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        <#code#>
    }
}

extension MWCameraBaseVC: AVCaptureVideoDataOutputSampleBufferDelegate {
    @available(iOS 11.0, *)
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if error == nil {
            let imageData = photo.fileDataRepresentation()
            let image = generateImage(with: imageData)
            takeImageCompletion(image)
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        if error == nil {
            let imageData = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: photoSampleBuffer!, previewPhotoSampleBuffer: previewPhotoSampleBuffer)
            let image = generateImage(with: imageData)
            takeImageCompletion(image)
        }
    }
}
