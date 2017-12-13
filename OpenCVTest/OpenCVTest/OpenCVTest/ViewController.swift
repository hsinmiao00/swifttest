//
//  ViewController.swift
//  OpenCVTest
//
//  Created by Hsin Miao on 12/12/17.
//  Copyright © 2017 Hsin Miao. All rights reserved.
//

import UIKit
import Foundation
import AVFoundation

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    private var captureSession: AVCaptureSession?
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer?

    override func viewDidLoad() {
        super.viewDidLoad()

        let captureDevice = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera, for: AVMediaType.video,position: AVCaptureDevice.Position.back)
        if captureDevice!.isFocusModeSupported(.continuousAutoFocus) {
            do {
                try captureDevice!.lockForConfiguration()
                captureDevice!.focusMode = .continuousAutoFocus
                captureDevice!.unlockForConfiguration()
            } catch {
                print(error)
            }
        }

        do {
            let input = try AVCaptureDeviceInput(device: captureDevice!)
            captureSession = AVCaptureSession()
            captureSession?.sessionPreset = AVCaptureSession.Preset.photo
            captureSession?.addInput(input)

            let output = AVCaptureVideoDataOutput()
            output.setSampleBufferDelegate(self, queue: DispatchQueue.main)
            captureSession?.addOutput(output)

            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
            videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
            videoPreviewLayer?.frame = view.layer.bounds
            view.layer.addSublayer(videoPreviewLayer!)

            captureSession?.startRunning()
        } catch {
            print(error)
            return
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let frameImage = UIImageFromCMSamleBuffer(buffer: sampleBuffer)
        let grayImage = OpenCVWrapper.toGray(frameImage)
    }

}

func UIImageFromCMSamleBuffer(buffer: CMSampleBuffer) -> UIImage {
    let pixelBuffer: CVImageBuffer = CMSampleBufferGetImageBuffer(buffer)!
    let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
    let pixelBufferWidth = CGFloat(CVPixelBufferGetWidth(pixelBuffer))
    let pixelBufferHeight = CGFloat(CVPixelBufferGetHeight(pixelBuffer))
    let imageRect: CGRect = CGRect(x: 0, y: 0, width: pixelBufferWidth, height: pixelBufferHeight)
    let ciContext = CIContext.init()
    let cgimage = ciContext.createCGImage(ciImage, from: imageRect )

    let image = UIImage(cgImage: cgimage!)
    return image
}

