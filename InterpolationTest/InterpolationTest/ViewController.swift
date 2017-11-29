//
//  ViewController.swift
//  InterpolationTest
//
//  Created by Hsin Miao on 11/27/17.
//  Copyright © 2017 Hsin Miao. All rights reserved.
//

import UIKit
import Accelerate

class ViewController: UIViewController {
	@IBOutlet var imageView: UIImageView?

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.

		let url1 = URL(string: "https://imgur.com/34d1Tef.jpg")!
		let url2 = URL(string: "https://imgur.com/uVACNxB.jpg")!
		let data1 = try! Data(contentsOf: url1)
		let data2 = try! Data(contentsOf: url2)
		if let image1 = UIImage(data: data1) {
			if let image2 = UIImage(data: data2) {
				imageView?.animationImages = generateInterpolatedImages(img1: image1, img2: image2, num: 10)
				imageView?.animationDuration = 1
				imageView?.startAnimating()
			}
		}
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	func generateInterpolatedImages(img1: UIImage, img2: UIImage, num: Int) -> [UIImage] {
		var images = [UIImage]()
		guard num > 0 else {
			return images
		}
		for i in 1...num {
			let ratio = Float(i) / Float(num+1)
			if let interpolatedImage = interpolateImage(img1: img1, img2: img2, ratio: ratio) {
				images.append(interpolatedImage)
			}
		}
		return images
	}

	func imageFromBitmap(bitmap: Data, width: Int, height: Int) -> UIImage? {
		let cfdata = NSData(data: bitmap) as CFData
		let provider: CGDataProvider! = CGDataProvider(data: cfdata)
		guard provider != nil else {
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
		guard cgimage != nil else {
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
				var pixelFloatAry1 = [Float](repeating: 0.0, count: len)
				var pixelFloatAry2 = [Float](repeating: 0.0, count: len)
				vDSP_vfltu8(pixelDataAry1, 1, &pixelFloatAry1, 1, vDSP_Length(len))
				vDSP_vfltu8(pixelDataAry2, 1, &pixelFloatAry2, 1, vDSP_Length(len))

				// Vector-Scalar Multiplication
				var weightedPixelAry1 = [Float](repeating: 0.0, count: len)
				var weightedPixelAry2 = [Float](repeating: 0.0, count: len)
				var weight1 = ratio
				var weight2 = 1 - ratio
				vDSP_vsmul(&pixelFloatAry1, 1, &weight1, &weightedPixelAry1, 1, vDSP_Length(len))
				vDSP_vsmul(&pixelFloatAry2, 1, &weight2, &weightedPixelAry2, 1, vDSP_Length(len))

				// Vector Addition
				var resultPixelFloatAry = [Float](repeating: 0.0, count: len)
				vDSP_vadd(weightedPixelAry1, 1, weightedPixelAry2, 1, &resultPixelFloatAry, 1, vDSP_Length(len))

				// Convert UnsafePointer<Float> to UnsafePointer<UInt8>
				let resultPixelUint8Ary = UnsafeMutablePointer<UInt8>.allocate(capacity: len)
				vDSP_vfixu8(resultPixelFloatAry, 1, resultPixelUint8Ary, 1, vDSP_Length(len))

				let resultBitmap = Data(bytes: resultPixelUint8Ary, count: len)
				let resultImg = imageFromBitmap(bitmap: resultBitmap, width: Int(img1.size.width), height: Int(img1.size.height))

				return resultImg
			}
		}
		return nil
	}
}
