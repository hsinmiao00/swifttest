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
			imageView?.animationDuration = 1
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
        if let pixelData = img1.cgImage?.dataProvider?.data {
            if let pixelData2 = img2.cgImage?.dataProvider?.data {
                let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
                let data2: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData2)
                
                /*
                for i in 0...Int(img1.size.height)-1 {
                    for j in 0...Int(img1.size.width)-1 {
                       
                        let pixelInfo: Int = ((Int(img1.size.width) * i) + j) * 4
                        let r = UInt8(data[pixelInfo+0])
                        let g = UInt8(data[pixelInfo+1])
                        let b = UInt8(data[pixelInfo+2])
                        let a = UInt8(data[pixelInfo+3])
                        let r2 = UInt8(data2[pixelInfo+0])
                        let g2 = UInt8(data2[pixelInfo+1])
                        let b2 = UInt8(data2[pixelInfo+2])
                        let a2 = UInt8(data2[pixelInfo+3])
                        
                        let rr = UInt8( Float(r) * ratio + Float(r2) * (1-ratio))
                        let gg = UInt8( Float(g) * ratio + Float(g2) * (1-ratio))
                        let bb = UInt8( Float(b) * ratio + Float(b2) * (1-ratio))
                        let aa = UInt8( Float(a) * ratio + Float(a2) * (1-ratio))
                        let p = PixelData(a: aa, r: rr, g: gg, b: bb)
                        //pixels.append(p)
                        
                    }
                    //print(i)
                }
*/
				let start = DispatchTime.now()
                let len = Int(img1.size.height) * Int(img1.size.width) * 4
                var vvresult = [Float](repeating : 0.0, count : len)

                var v1 = [Float](repeating : 0.0, count : len)
                var v2 = [Float](repeating : 0.0, count : len)
				var v3 = [Float](repeating : 0.0, count : len)
				var v4 = [Float](repeating : 0.0, count : len)

				var s1 = ratio
				var s2 = 1 - ratio
                vDSP_vfltu8(data, 1, &v1, 1, vDSP_Length(len))
                vDSP_vfltu8(data2, 1, &v2, 1, vDSP_Length(len))

				vDSP_vsmul(&v1, 1, &s1, &v3, 1, vDSP_Length(len))
				vDSP_vsmul(&v2, 1, &s2, &v4, 1, vDSP_Length(len))

                vDSP_vadd(v3, 1, v4, 1, &vvresult, 1, vDSP_Length(len))

				let result = UnsafeMutablePointer<UInt8>.allocate(capacity: len)
				vDSP_vfixu8(vvresult, 1, result, 1, vDSP_Length(len))

				let end = DispatchTime.now()

				/*
				pixels = [PixelData](repeating: PixelData(), count: len / 4)
				var cnt: Int = 0
				for i in 0...Int(img1.size.height)-1 {
					for j in 0...Int(img1.size.width)-1 {
						let pixelInfo: Int = ((Int(img1.size.width) * i) + j) * 4
						let r = UInt8(vvresult[pixelInfo+0])
						let g = UInt8(vvresult[pixelInfo+1])
						let b = UInt8(vvresult[pixelInfo+2])
						let a = UInt8(vvresult[pixelInfo+3])
						let p = PixelData(a: a, r: r, g: g, b: b)
						pixels[cnt] = p
						cnt = cnt + 1

					}

}
*/
				//let bitmap2 = imageFromBitmap2(pixels: pixels, width: Int(img1.size.width), height: Int(img1.size.height))
				//print(data[0], data[1], data[2], data[3])
				//print(result[0], result[1], result[2], result[3])
				let fdata = Data(bytes: result, count: len)
				let bitmap = imageFromBitmap(pixels: fdata, width: Int(img1.size.width), height: Int(img1.size.height))
				//print(bitmap)
                let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds // <<<<< Difference in nano seconds (UInt64)
                let timeInterval = Double(nanoTime) / 1_000_000_000 // Technically could overflow for long running tests
                
                print("Inner Time \(timeInterval) seconds")
				//UIImageWriteToSavedPhotosAlbum(bitmap!, self, nil, nil)
				//usleep(500000)
                return bitmap
                
            }
        }
        //return pixels
		return nil
    }
}

