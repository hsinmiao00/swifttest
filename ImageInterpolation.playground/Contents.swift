//: Playground - noun: a place where people can play

import UIKit

func getDocumentsDirectory() -> URL {
	let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
	return paths[0]
}

extension UIImage {
	func getPixelColor(pos: CGPoint) -> PixelData {
		if let pixelData = self.cgImage?.dataProvider?.data {
			let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)

			let pixelInfo: Int = ((Int(self.size.width) * Int(pos.y)) + Int(pos.x)) * 4

			let r = UInt8(data[pixelInfo+0])
			let g = UInt8(data[pixelInfo+1])
			let b = UInt8(data[pixelInfo+2])
			let a = UInt8(data[pixelInfo+3])

			return PixelData(a: a, r: r, g: g, b: b)
		} else {
			//IF something is wrong I returned WHITE, but change as needed
			return PixelData()
		}
	}
}

struct PixelData {
	var a: UInt8 = 0
	var r: UInt8 = 0
	var g: UInt8 = 0
	var b: UInt8 = 0
}

func imageFromBitmap(pixels: [PixelData], width: Int, height: Int) -> UIImage? {
	assert(width > 0)

	assert(height > 0)

	let pixelDataSize = MemoryLayout<PixelData>.size
	assert(pixelDataSize == 4)

	assert(pixels.count == Int(width * height))

	let data: Data = pixels.withUnsafeBufferPointer {
		return Data(buffer: $0)
	}

	let cfdata = NSData(data: data) as CFData
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
		bytesPerRow: width * pixelDataSize,
		space: CGColorSpaceCreateDeviceRGB(),
		bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue),
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

let url = URL(string: "https://imgur.com/CrlakYs.jpg")!
let url2 = URL(string: "https://imgur.com/DXEzZ6I.jpg")!
let data2 = try! Data(contentsOf: url2)
if let image = UIImage(data: data2) {

	var pixels = [PixelData]()
	for i in 0...Int(image.size.height) {
		for j in 0...Int(image.size.width) {
			let colorAtPixel = image.getPixelColor(pos: CGPoint(x: i, y: j))
			pixels.append(colorAtPixel)
		}
	}
	let final = imageFromBitmap(pixels: pixels, width: Int(image.size.width), height: Int(image.size.height))
	if let data = UIImageJPEGRepresentation((final)!, 0.8) {
		let filename = getDocumentsDirectory().appendingPathComponent("copy.png")
		print(filename)
		try? data.write(to: filename)
	}
}
