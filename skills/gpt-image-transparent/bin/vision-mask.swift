// vision-mask — Apple Vision foreground mask (macOS 14+).
// Usage: vision-mask <image> <mask.png>
// Writes an 8-bit grayscale mask at the source size: white = subject, black = background.
import CoreImage
import Foundation
import Vision

let args = CommandLine.arguments
guard args.count == 3 else {
    FileHandle.standardError.write("usage: vision-mask <image> <mask.png>\n".data(using: .utf8)!)
    exit(2)
}
let inURL = URL(fileURLWithPath: args[1])
let outURL = URL(fileURLWithPath: args[2])

guard let src = CIImage(contentsOf: inURL) else {
    FileHandle.standardError.write("cannot read image: \(inURL.path)\n".data(using: .utf8)!)
    exit(1)
}
let W = src.extent.width, H = src.extent.height
// orientation .up: work on the pixels as stored, like CIImage and the Python side do
// (otherwise Vision applies the EXIF rotation and the mask no longer lines up)
let handler = VNImageRequestHandler(url: inURL, orientation: .up, options: [:])
let request = VNGenerateForegroundInstanceMaskRequest()
do {
    try handler.perform([request])
} catch {
    FileHandle.standardError.write("vision failed: \(error)\n".data(using: .utf8)!)
    exit(1)
}
guard let obs = request.results?.first, !obs.allInstances.isEmpty else {
    FileHandle.standardError.write("vision found no foreground subject\n".data(using: .utf8)!)
    exit(3)
}
let buffer = try obs.generateScaledMaskForImage(forInstances: obs.allInstances, from: handler)
var mask = CIImage(cvPixelBuffer: buffer)
let sx = W / mask.extent.width, sy = H / mask.extent.height
if sx != 1 || sy != 1 {
    mask = mask.transformed(by: CGAffineTransform(scaleX: sx, y: sy))
}
try CIContext().writePNGRepresentation(of: mask, to: outURL, format: .L8,
                                       colorSpace: CGColorSpaceCreateDeviceGray())
print("instances:", obs.allInstances.count)
