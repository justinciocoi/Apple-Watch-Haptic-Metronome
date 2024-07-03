//
//  ContentView.swift
//  HaptikMetronome Watch App
//
//  Created by Justin Ciocoi on 7/2/24.
//

import SwiftUI
import SwiftUI_Apple_Watch_Decimal_Pad
import WatchKit

//General View
struct ContentView: View {
    @StateObject var metronomeModel = MetronomeModel()
    @State private var showingInput = false
    @State public var presentingModal: Bool = false
    
    var body: some View {
        
        //Displays Current BPM
        VStack {
            Text("BPM:")
                .font(.title2)
            Text(String(metronomeModel.bpm))
                .font(.title)
        }
        .padding()
        .offset(y: 40)
        
        
        VStack {
            //Button for starting and stopping the metronome
            Button(action: {
                WKInterfaceDevice.current().play(.start)
                metronomeModel.isPlaying.toggle()
                if metronomeModel.isPlaying {
                    metronomeModel.startMetronome()
                } else {
                    metronomeModel.stopMetronome()
                }
            }) {
                Text(metronomeModel.isPlaying ? "Stop Metronome" : "Start Metronome")
            }
            .padding()
            .buttonStyle(NoPaddingButtonStyle())
            .background(metronomeModel.isPlaying ? Color.red : Color.blue)
            .cornerRadius(8)
            .offset(y: 10)
            
            //Button to enter BPM Input View
            Button(action: {
                WKInterfaceDevice.current().play(.click)
                showingInput.toggle()
            }) {
                Text("Enter BPM")
            }
            .padding()
            .sheet(isPresented: $showingInput) {
                BPMInputView(bpm: $metronomeModel.bpm, presentingModal: $presentingModal)
            }
            .buttonStyle(NoPaddingButtonStyle())
            .background(.gray)
            .cornerRadius(8)
            .offset(y:30)
            
            //Button to Increase BPM by 5
            Button(action: {
                WKInterfaceDevice.current().play(.click)
                if metronomeModel.bpm<240{
                    metronomeModel.bpm+=5
                }
            }) {
                Text("+")
                    .font(.title)
                    .fontWeight(.bold)
                    .offset(x: -1, y: -2)
                    .foregroundColor(.green)
            }
            .clipShape(Circle())
            .offset(x: 65, y: -135)
            .frame(width: 45)
            
            //Button to Decrease BPM by 5
            Button(action: {
                WKInterfaceDevice.current().play(.click)
                if metronomeModel.bpm>30{
                    metronomeModel.bpm-=5
                }
                
            }) {
                Text("_")
                    .font(.title)
                    .fontWeight(.bold)
                    .offset(y: -14)
                    .foregroundColor(.red)
            }
            .clipShape(Circle())
            .offset(x: -65, y: -192)
            .frame(width: 45)
        }
        .offset(y: 30)
    }
}

struct BPMInputView: View {
    @Binding var bpm: Int
    @State private var inputText: String = ""
    @Binding public var presentingModal: Bool
    
    var body: some View {
            VStack {
                Text("Enter BPM")
                    .font(.headline)
                    .padding()

                DigiTextView(
                    placeholder: "click to enter",
                    text: $inputText,
                    presentingModal: false
                )
                .padding()

                Button(action: {
                    WKInterfaceDevice.current().play(.click)
                    if let newBPM = Int(inputText), newBPM >= 30 && newBPM <= 240 {
                        bpm = newBPM
                        presentingModal = false // Close the sheet
                    }
                }) {
                    Text("Set BPM")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding()
                .buttonStyle(NoPaddingButtonStyle())
            }
            .padding()
        }
}

struct NoPaddingButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(0) // Set padding to 0
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.2 : 1.0)
    }
}

func scheduleBackgroundRefresh() {
    let preferredDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes later
    WKExtension.shared().scheduleBackgroundRefresh(withPreferredDate: preferredDate, userInfo: nil) { error in
        if let error = error {
            print("Error scheduling background refresh: \(error.localizedDescription)")
        }
    }
}

import Combine

class MetronomeModel: ObservableObject {
    @Published var bpm: Int = 60
    @Published var isPlaying: Bool = false
    var timer: Timer? = nil
    
    func startMetronome() {
        let interval = 60.0 / Double(bpm)
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            WKInterfaceDevice.current().play(.start)
        }
        scheduleBackgroundRefresh()
    }
    
    func stopMetronome() {
        timer?.invalidate()
        timer = nil
    }
    
    private func scheduleBackgroundRefresh() {
        let preferredDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes later
        WKExtension.shared().scheduleBackgroundRefresh(withPreferredDate: preferredDate, userInfo: nil) { error in
            if let error = error {
                print("Error scheduling background refresh: \(error.localizedDescription)")
            }
        }
    }
}

class ExtensionDelegate: NSObject, WKExtensionDelegate {
    var metronomeModel = MetronomeModel()
    
    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        for task in backgroundTasks {
            if let refreshTask = task as? WKApplicationRefreshBackgroundTask {
                // Start the metronome in the background
                metronomeModel.startMetronome()
                refreshTask.setTaskCompletedWithSnapshot(false)
            }
        }
    }
}




#Preview {
    ContentView(presentingModal: false)
}




