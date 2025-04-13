import Foundation
import UIKit
import CoreML
import Vision
import SwiftUI

class ClassificationViewModel: ObservableObject {

    @Published var classificationLabel: String = ""
    @Published var name: String = "" // Keep this for the raw model output
    @Published var text: String = "" // This might be less relevant in learning mode
    var onLoop = false
    let mlmodel: SignAlphabet
    private var model = ContentViewModel()

    let alphabetSequence = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".map { String($0) }
    @Published var currentLetterIndex: Int = 0
    @Published var currentTargetLetter: String = "A"
    @Published var isLearningActive: Bool = false
    @Published var showFeedback: Bool = false
    @Published var isCorrectSign: Bool = false
    private var handPoseRequest = VNDetectHumanHandPoseRequest()

    // Example: A dictionary to map letters to image names
    let signImages: [String: String] = [
        "A": "asl_a_sign", "B": "asl_b_sign", "C": "asl_c_sign",
        "D": "asl_d_sign", "E": "asl_e_sign", "F": "asl_f_sign",
        "G": "asl_g_sign", "H": "asl_h_sign", "I": "asl_i_sign",
        "J": "asl_j_sign", "K": "asl_k_sign", "L": "asl_l_sign",
        "M": "asl_m_sign", "N": "asl_n_sign", "O": "asl_o_sign",
        "P": "asl_p_sign", "Q": "asl_q_sign", "R": "asl_r_sign",
        "S": "asl_s_sign", "T": "asl_t_sign", "U": "asl_u_sign",
        "V": "asl_v_sign", "W": "asl_w_sign", "X": "asl_x_sign",
        "Y": "asl_y_sign", "Z": "asl_z_sign"
    ]

    init() {
        do {
            self.mlmodel = try SignAlphabet(configuration: MLModelConfiguration())
        } catch {
            fatalError("Failed to load SignAlphabet model: \(error)")
        }
    }
    
    func startLearningSession() {
        isLearningActive = true
        currentLetterIndex = 0
        currentTargetLetter = alphabetSequence[currentLetterIndex]
        showFeedback = false
        isCorrectSign = false
        if !onLoop {
             onLoop = true
             callFunc()
        }
    }

    func stopLearningSession() {
        isLearningActive = false
        onLoop = false
        showFeedback = false
        isCorrectSign = false
        // Reset labels if desired
        classificationLabel = ""
        name = ""
    }

    func advanceToNextLetter() {
        showFeedback = false
        isCorrectSign = false
        if currentLetterIndex < alphabetSequence.count - 1 {
            currentLetterIndex += 1
            currentTargetLetter = alphabetSequence[currentLetterIndex]
        } else {
            print("Congratulations! Alphabet complete.")
            stopLearningSession()
        }
    }

    // Modify classifyImage to handle learning logic
    func classifyImage(tmpImage: UIImage) {
        // --- Image Preprocessing ---
        let image = tmpImage
        // Ensure resizeImageTo exists and works correctly
        guard let resizedImage = image.resizeImageTo(size: CGSize(width: 224, height: 224)) else {
             print("Error: Failed to resize image.")
             // Update state if in learning mode
             if isLearningActive {
                self.name = "Resize Error"
                self.classificationLabel = ""
                self.isCorrectSign = false
                self.showFeedback = true
             }
             return
        }
        // Ensure convertToBuffer exists and works correctly
        guard let buffer = resizedImage.convertToBuffer() else {
             print("Error: Failed to convert image to buffer.")
             if isLearningActive {
                self.name = "Buffer Error"
                self.classificationLabel = ""
                self.isCorrectSign = false
                self.showFeedback = true
             }
             return
        }

        // --- Vision Hand Pose Request Setup ---
        handPoseRequest.maximumHandCount = 1 // Detect only one hand

        // Use the CVPixelBuffer directly if the model expects it,
        // or use original image data if required by VNImageRequestHandler.
        // Using image data is common for VNImageRequestHandler.
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
             print("Error: Failed to get JPEG data from image.")
              if isLearningActive {
                self.name = "Data Error"
                self.classificationLabel = ""
                self.isCorrectSign = false
                self.showFeedback = true
             }
            return
        }
        let handler = VNImageRequestHandler(data: imageData, options: [:])

        // --- Perform Detection and Classification ---
        do {
            // Perform the request
            try handler.perform([handPoseRequest])

            // Check for hand pose observation
            guard let observation = handPoseRequest.results?.first else {
                print("Info: No hand detected in the frame.")
                 if isLearningActive {
                    self.name = "No hand detected"
                    self.classificationLabel = "" // Clear confidence
                    self.isCorrectSign = false // Not correct if no hand
                    // Decide if you want to show "Try Again" or just nothing
                    self.showFeedback = true // Show feedback indicating no hand
                 } else {
                    // Update state for non-learning mode if needed
                    self.name = "No hand detected"
                    self.classificationLabel = ""
                 }
                return // Stop processing if no hand is found
            }

            let keypointsMultiArray = try observation.keypointsMultiArray()

            // Perform prediction with the ML model
            let handPosePrediction = try mlmodel.prediction(poses: keypointsMultiArray)
            let predictedSign = handPosePrediction.label // The model's classification
            let confidence = handPosePrediction.labelProbabilities[predictedSign] ?? 0.0 // Confidence score

            DispatchQueue.main.async {
                self.name = predictedSign
                self.classificationLabel = confidence.format(f: ".2") // Format confidence
            }


            // --- Learning Mode Logic ---
            if isLearningActive {
                 // --- Add Detailed Debugging (Runs on the same thread as classification) ---
                 print("--- Learning Check ---")
                 print("Target Letter: \(currentTargetLetter)")
                 print("Predicted Sign Raw: '\(predictedSign)'")
                 print("Predicted Sign Uppercased: '\(predictedSign.uppercased())'")
                 print("Confidence: \(confidence)")
                 let isMatch = predictedSign.uppercased() == currentTargetLetter.uppercased()
                 let confidenceThreshold = 0.5 // Define threshold clearly
                 let isConfident = confidence > confidenceThreshold
                 print("Is Match? \(isMatch)")
                 print("Is Confident? \(isConfident) (Threshold: \(confidenceThreshold))")
                 // --- End Debugging ---

                // Check if the detected sign matches the target letter AND meets confidence
                if isMatch && isConfident {
                     print("✅ Correct Sign Detected!")
                     DispatchQueue.main.async {
                         self.isCorrectSign = true
                         self.showFeedback = true
                     }

                    // Advance after delay - ensure this doesn't interfere with rapid checks
                     DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        
                         if self.isLearningActive && self.isCorrectSign && self.currentTargetLetter.uppercased() == predictedSign.uppercased() {
                              print("Advancing to next letter from \(self.currentTargetLetter)")
                              self.advanceToNextLetter()
                         } else {
                             print("Skipping advance: State changed (isLearningActive: \(self.isLearningActive), isCorrectSign: \(self.isCorrectSign), currentTarget: \(self.currentTargetLetter), predictedSign: \(predictedSign))")
                         }
                     }
                } else {
                     print("❌ Incorrect Sign or Low Confidence.")
                     // Determine why it failed for feedback
                     if !isMatch {
                         print("Reason: Predicted sign ('\(predictedSign)') does not match target ('\(currentTargetLetter)').")
                     } else if !isConfident {
                         print("Reason: Confidence (\(confidence)) below threshold (\(confidenceThreshold)).")
                     }
                     DispatchQueue.main.async {
                         self.isCorrectSign = false
                         self.showFeedback = true
                     }
                }
            }

            if !isLearningActive && onLoop {
                 let confidenceThresholdContinuous = 0.8 // Separate threshold?
                 if confidence > confidenceThresholdContinuous {
                      DispatchQueue.main.async { // Ensure UI updates happen on main thread
                          if self.name == "del" {
                              if !self.text.isEmpty { self.text.removeLast() }
                          } else if self.name == "space" {
                              self.text.append(" ")
                          } else if self.name != "nothing" { // Avoid appending "nothing"
                              self.text.append(predictedSign)
                          }
                      }
                 }
            }

        } catch {
            print("Error during Vision processing or ML prediction: \(error)")
            // Update state on the main thread for UI changes
             DispatchQueue.main.async {
                 if self.isLearningActive {
                     self.isCorrectSign = false
                     self.showFeedback = true
                 }
                self.name = "Processing Error"
                self.classificationLabel = ""
             }
        }
    }

    // Keep or modify callFunc as needed for the learning loop
    func callFunc() {
        guard onLoop else { return } // Stop if loop is turned off

        // Use a slightly shorter delay for responsiveness in learning?
        let delay = isLearningActive ? 1.0 : 2.0

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self, self.onLoop else { return }

            if let frame = self.model.frame {
                self.classifyImage(tmpImage: UIImage(cgImage: frame))
                self.callFunc()
            } else {
                print("No frame available, retrying...")
                self.callFunc()
            }
        }
    }
}
