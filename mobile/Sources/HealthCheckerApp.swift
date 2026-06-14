import SwiftUI

@main
struct HealthCheckerApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(model)
                .preferredColorScheme(.dark)
        }
    }
}

/// Routes between the linear steps of the flow.
struct RootView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            switch model.step {
            case .disclaimer:
                DisclaimerView()
            case .loadingModel:
                ModelLoadingView()
            case .instructions:
                InstructionsView()
            case .recording:
                RecordingView(recorder: model.recorder)
            case .analyzing:
                AnalyzingView()
            case .result(let result):
                ResultView(result: result)
            case .error(let message):
                ErrorView(message: message)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: stepID)
    }

    /// A cheap discriminator so the cross-fade animates on step changes.
    private var stepID: Int {
        switch model.step {
        case .disclaimer: return 0
        case .loadingModel: return 1
        case .instructions: return 2
        case .recording: return 3
        case .analyzing: return 4
        case .result: return 5
        case .error: return 6
        }
    }
}
