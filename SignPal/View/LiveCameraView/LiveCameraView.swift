import SwiftUI

struct LiveCameraView: View {
    @StateObject private var model = ContentViewModel() // Provides the camera frame
    @EnvironmentObject var classificationViewModel: ClassificationViewModel // Access the updated VM

    var body: some View {
        VStack {
            ZStack {
                FrameView(image: model.frame) // Your existing frame view
                    .ignoresSafeArea()
                ErrorView(error: model.error) // Your existing error view

                // --- Feedback Overlay (New) ---
                if classificationViewModel.showFeedback && classificationViewModel.isLearningActive {
                    VStack {
                        if classificationViewModel.isCorrectSign {
                            Image(systemName: "checkmark.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .foregroundColor(.green)
                                .padding()
                                .background(.ultraThinMaterial, in: Circle())

                        } else {
                             Text("Try Again!")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .padding()
                                .foregroundColor(.white)
                                .background(Color.red.opacity(0.8))
                                .cornerRadius(10)
                             // Optionally show the detected sign if different
                             if !classificationViewModel.name.isEmpty && classificationViewModel.name != "No hand detected" && classificationViewModel.name != "Could not process hand" {
                                 Text("Detected: \(classificationViewModel.name)")
                                     .font(.title2)
                                     .padding(.top, 5)
                                     .foregroundColor(.white)
                             }
                        }
                        Spacer() // Push feedback to top or adjust layout
                    }
                    .padding(.top, 50) // Adjust padding as needed
                    .animation(.easeInOut, value: classificationViewModel.showFeedback)
                    .onTapGesture {
                        // Allow tapping feedback away?
                        // classificationViewModel.showFeedback = false
                    }
                }
            } // ZStack for Camera Feed

            // --- Control Area ---
            VStack {
                if classificationViewModel.isLearningActive {
                    // --- Learning Mode UI ---
                    HStack(alignment: .center, spacing: 20) {
                         // Target Letter Display
                         Text(classificationViewModel.currentTargetLetter)
                             .font(.system(size: 80, weight: .bold))
                             .frame(width: 100, height: 100)
                             .padding()
                             .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 15))


                         // Example Sign Image Display
                         // Ensure you have images named e.g., "asl_a_sign.png" in Assets
                         if let imageName = classificationViewModel.signImages[classificationViewModel.currentTargetLetter] {
                              Image(imageName) // Load from Assets
                                  .resizable()
                                  .scaledToFit()
                                  .frame(width: 120, height: 120) // Adjust size
                                  .padding()
                                  .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 15))

                         } else {
                              // Placeholder if image is missing
                              Rectangle()
                                  .fill(Color.gray.opacity(0.3))
                                  .frame(width: 120, height: 120)
                                  .cornerRadius(15)
                                  .overlay(Text("No Image").foregroundColor(.white))
                                  .padding()
                         }
                    }
                    .padding(.top)

                    // Button to Stop Learning
                    Button("Stop Learning") {
                        classificationViewModel.stopLearningSession()
                    }
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.red)
                    .cornerRadius(10)
                    .padding(.bottom)

                } else {
                     // --- Original UI / Mode Selection ---
                     Button("Start Learning Mode") {
                          classificationViewModel.startLearningSession()
                     }
                     .padding()
                     .foregroundColor(.white)
                     .background(Color.blue) // Use your app's accent color
                     .cornerRadius(10)
                     .padding(.bottom)

                     // Keep original classification button if needed for a different mode
                     /*
                     Button(classificationViewModel.onLoop == false ? "Start Live Classifying" : "Stop Live Classifying") {
                         if model.frame != nil {
                             // Toggle continuous classification (non-learning)
                             classificationViewModel.onLoop.toggle()
                             if classificationViewModel.onLoop {
                                 classificationViewModel.text = "" // Reset text
                                 classificationViewModel.callFunc() // Start loop
                             }
                         }
                     }
                     .padding()
                     .foregroundColor(.white)
                     .background(Color.green) // Use your app's accent color
                     .cornerRadius(10)
                     .padding(.bottom)

                     // Display continuous text output if needed
                     if !classificationViewModel.text.isEmpty && classificationViewModel.onLoop {
                         Text("Output: \(classificationViewModel.text)")
                             .padding()
                     }
                     */
                }

                // Displaying raw classification confidence/name (Optional, for debugging)
                /*
                 HStack {
                     if !classificationViewModel.name.isEmpty {
                          Text("Detected: \(classificationViewModel.name)")
                               .padding()
                               .background(.gray.opacity(0.2), in: RoundedRectangle(cornerRadius: 8))
                     }
                     if !classificationViewModel.classificationLabel.isEmpty {
                           Text("Conf: \(classificationViewModel.classificationLabel)")
                              .padding()
                              .background(.gray.opacity(0.2), in: RoundedRectangle(cornerRadius: 8))
                      }
                 }
                 .padding(.bottom)
                 */

            } // VStack for Controls
             .padding(.horizontal)

        } // Main VStack
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(classificationViewModel.isLearningActive ? "Learning Mode" : "Live Camera")
        .onAppear {
             // Reset state when view appears if needed, or rely on explicit start/stop
            // classificationViewModel.stopLearningSession() // Ensure clean state initially?
        }
        .onDisappear {
            // Stop processes when navigating away
             classificationViewModel.stopLearningSession() // Stop learning
             classificationViewModel.onLoop = false // Stop any classification loop
        }
    }
}

//struct LiveCameraView_Previews: PreviewProvider {
//    static var previews: some View {
//        LiveCameraView()
//    }
//}
