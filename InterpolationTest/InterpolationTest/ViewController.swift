//
//  ViewController.swift
//  InterpolationTest
//
//  Created by Hsin Miao on 11/27/17.
//  Copyright © 2017 Hsin Miao. All rights reserved.
//

import UIKit
import Accelerate

struct PixelData {
    var a: UInt8 = 0
    var r: UInt8 = 0
    var g: UInt8 = 0
    var b: UInt8 = 0
}

class ViewController: UIViewController {
	@IBOutlet var imageView: UIImageView?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
 
        let url = URL(string: "https://imgur.com/34d1Tef.jpg")!
        let url2 = URL(string: "https://imgur.com/uVACNxB.jpg")!
        let data = try! Data(contentsOf: url)
        let data2 = try! Data(contentsOf: url2)
        if let image2 = UIImage(data: data2) {
            let image = UIImage(data: data)
            /*
            var pixels = [PixelData]()
            
            for i in 0...Int(image.size.height)-1 {
                for j in 0...Int(image.size.width)-1 {
                    let colorAtPixel = image.getPixelColor(pos: CGPoint(x: i, y: j))
                    pixels.append(colorAtPixel)
                }
                print(i)
            }
             */
			var images = [UIImage]()
            for i in 1...9 {
                let start = DispatchTime.now()
            let ratio = Float(i) / Float(10)
            let pixels = interpolateImage(img1: image!, img2: image2, ratio: ratio)
                let end = DispatchTime.now()
            //let final = imageFromBitmap(pixels: pixels, width: Int((image?.size.width)!), height: Int((image?.size.height)!))
                let end2 = DispatchTime.now()
                let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds // <<<<< Difference in nano seconds (UInt64)
                let timeInterval = Double(nanoTime) / 1_000_000_000
                let nanoTime2 = end2.uptimeNanoseconds - end.uptimeNanoseconds // <<<<< Difference in nano seconds (UInt64)
                let timeInterval2 = Double(nanoTime2) / 1_000_000_000
                print("Time: \(timeInterval), \(timeInterval2) seconds")
				images.append(pixels!)
            }
			imageView?.animationImages = images
			imageView?.animationDuration = 2
			imageView?.startAnimating()
        }
 
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func convert(cmage: CIImage) -> UIImage {
        let context: CIContext = CIContext.init(options: nil)
        let cgImage: CGImage = context.createCGImage(cmage, from: cmage.extent)!
        let image: UIImage = UIImage.init(cgImage: cgImage)
        return image
    }
   
    
    func imageFromBitmap(pixels: Data, width: Int, height: Int) -> UIImage? {
        assert(width > 0)
        
        assert(height > 0)
        
        //let pixelDataSize = MemoryLayout<PixelData>.size
        //assert(pixelDataSize == 4)
        
        //assert(pixels.count == Int(width * height))
        
        //let data: Data = pixels.withUnsafeBufferPointer {
            //return Data(buffer: $0)
        //}
        
        let cfdata = NSData(data: pixels) as CFData
        let provider: CGDataProvider! = CGDataProvider(data: cfdata)
        if provider == nil {
            print("CGDataProvider is not supposed to be nil")
            return nil
        }
        let cgimage: CGImage! = CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            provider: provider,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
        )
        if cgimage == nil {
            print("CGImage is not supposed to be nil")
            return nil
        }
        return UIImage(cgImage: cgimage)
    }

	func interpolateImage(img1: UIImage, img2: UIImage, ratio: Float) -> UIImage? {
        if let pixelData1 = img1.cgImage?.dataProvider?.data {
            if let pixelData2 = img2.cgImage?.dataProvider?.data {
				// The sequence is R, G, B, A.
                let pixelDataAry1: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData1)
                let pixelDataAry2: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData2)
                let len = Int(img1.size.height) * Int(img1.size.width) * 4

				// Convert UnsafePointer<UInt8> to UnsafePointer<Float>
				var pixelFloatAry1 = [Float](repeating : 0.0, count : len)
				var pixelFloatAry2 = [Float](repeating : 0.0, count : len)
				vDSP_vfltu8(pixelDataAry1, 1, &pixelFloatAry1, 1, vDSP_Length(len))
				vDSP_vfltu8(pixelDataAry2, 1, &pixelFloatAry2, 1, vDSP_Length(len))

				// Vector-Scalar Multiplication
				var weightedPixelAry1 = [Float](repeating : 0.0, count : len)
				var weightedPixelAry2 = [Float](repeating : 0.0, count : len)
				var weight1 = ratio
				var weight2 = 1 - ratio
				vDSP_vsmul(&pixelFloatAry1, 1, &weight1, &weightedPixelAry1, 1, vDSP_Length(len))
				vDSP_vsmul(&pixelFloatAry2, 1, &weight2, &weightedPixelAry2, 1, vDSP_Length(len))

				// Vector Addition
                var resultPixelFloatAry = [Float](repeating : 0.0, count : len)
                vDSP_vadd(weightedPixelAry1, 1, weightedPixelAry2, 1, &resultPixelFloatAry, 1, vDSP_Length(len))

				// Convert UnsafePointer<Float> to UnsafePointer<UInt8>
				let resultPixelUint8Ary = UnsafeMutablePointer<UInt8>.allocate(capacity: len)
				vDSP_vfixu8(resultPixelFloatAry, 1, resultPixelUint8Ary, 1, vDSP_Length(len))

				let resultData = Data(bytes: resultPixelUint8Ary, count: len)
				let resultImg = imageFromBitmap(pixels: resultData, width: Int(img1.size.width), height: Int(img1.size.height))

                return resultImg
            }
        }
		return nil
    }
}

