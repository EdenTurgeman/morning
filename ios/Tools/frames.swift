// Pulls exact frames out of a simctl recording.
//
// `xcrun simctl io … recordVideo` gives a real 60fps capture; backgrounded
// `simctl io screenshot` calls do not — each takes ~0.5s to start, so their
// timestamps drift past whatever you were trying to catch. This is how a
// 0.44s transition gets looked at honestly.
//
//   swift frames.swift <video.mp4> <outDir> <t0> <t1> …   (times in seconds)

import AVFoundation
import CoreImage
import Foundation

let args = CommandLine.arguments
guard args.count >= 4 else {
    FileHandle.standardError.write(Data("usage: frames.swift <video> <outDir> <t…>\n".utf8))
    exit(2)
}

let asset = AVURLAsset(url: URL(fileURLWithPath: args[1]))
let outDir = URL(fileURLWithPath: args[2])
let times = args[3...].compactMap(Double.init)

let generator = AVAssetImageGenerator(asset: asset)
generator.appliesPreferredTrackTransform = true
// Exact frames, not the nearest keyframe — the whole point is sub-100ms timing.
generator.requestedTimeToleranceBefore = .zero
generator.requestedTimeToleranceAfter = .zero

let context = CIContext()
let sem = DispatchSemaphore(value: 0)

Task {
    for t in times {
        do {
            let (cg, actual) = try await generator.image(at: CMTime(seconds: t, preferredTimescale: 600))
            let url = outDir.appendingPathComponent(String(format: "t%.2f.png", t))
            let ci = CIImage(cgImage: cg)
            try context.writePNGRepresentation(
                of: ci, to: url, format: .RGBA8, colorSpace: ci.colorSpace ?? CGColorSpaceCreateDeviceRGB()
            )
            print(String(format: "%.2f → %.3f  %@", t, actual.seconds, url.lastPathComponent))
        } catch {
            print(String(format: "%.2f  FAILED  %@", t, "\(error)"))
        }
    }
    sem.signal()
}

sem.wait()
