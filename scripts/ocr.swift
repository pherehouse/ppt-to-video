import Foundation
import Vision
import AppKit

let path = CommandLine.arguments[1]
guard let img = NSImage(contentsOfFile: path),
      let tiff = img.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let cgImage = rep.cgImage else {
  FileHandle.standardError.write("Failed to load \(path)\n".data(using: .utf8)!)
  exit(1)
}

let sem = DispatchSemaphore(value: 0)
let req = VNRecognizeTextRequest()
req.recognitionLevel = .accurate
req.usesLanguageCorrection = true
req.recognitionLanguages = ["zh-Hans", "en-US"]

let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
try? handler.perform([req])

for obs in req.results ?? [] {
  if let s = obs.topCandidates(1).first?.string {
    print(s)
  }
}
