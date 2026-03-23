//
//  OnboardingView.swift
//  Iridium
//

import SwiftUI

struct OnboardingView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @State private var currentStep = 0
    var onComplete: () -> Void

    private let totalSteps = 4

    var body: some View {
        VStack(spacing: 0) {
            // Step content
            Group {
                switch currentStep {
                case 0:
                    welcomeStep
                case 1:
                    accessibilityStep
                case 2:
                    positionStep
                case 3:
                    privacyStep
                default:
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            // Navigation bar
            HStack {
                if currentStep > 0 {
                    Button("Back") {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            currentStep -= 1
                        }
                    }
                    .buttonStyle(.bordered)
                }

                Spacer()

                // Step indicators
                HStack(spacing: 6) {
                    ForEach(0..<totalSteps, id: \.self) { index in
                        Circle()
                            .fill(index == currentStep ? Color.accentColor : Color.secondary.opacity(0.3))
                            .frame(width: 7, height: 7)
                    }
                }

                Spacer()

                if currentStep < totalSteps - 1 {
                    HStack(spacing: 8) {
                        Button("Skip") {
                            completeOnboarding()
                        }
                        .buttonStyle(.borderless)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier(AccessibilityID.Onboarding.skipButton)

                        Button("Continue") {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                currentStep += 1
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .accessibilityIdentifier(AccessibilityID.Onboarding.continueButton)
                    }
                } else {
                    Button("Get Started") {
                        completeOnboarding()
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier(AccessibilityID.Onboarding.getStartedButton)
                }
            }
            .padding()
        }
        .frame(width: 520, height: 420)
    }

    // MARK: - Steps

    private var welcomeStep: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "sparkle")
                .font(.system(size: 56))
                .foregroundStyle(.tint)

            Text("Welcome to Iridium")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("A smart, privacy-first app launcher for your Mac.")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 12) {
                featureRow(icon: "brain", title: "Intelligent Suggestions", description: "Iridium learns which apps you need based on what you're doing.")
                featureRow(icon: "rectangle.split.2x1", title: "Window Management", description: "Snap windows into tiled layouts with keyboard shortcuts.")
                featureRow(icon: "lock.shield", title: "Privacy First", description: "Everything is processed locally. No data leaves your Mac.")
            }
            .padding(.horizontal, 40)
            .padding(.top, 8)

            Spacer()
        }
        .padding()
    }

    private var accessibilityStep: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "hand.raised.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.orange)

            Text("Accessibility Permission")
                .font(.title)
                .fontWeight(.bold)

            Text("Iridium needs accessibility access to manage windows and read browser tabs for smarter suggestions.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            HStack(spacing: 8) {
                if coordinator.accessibilityManager.isAccessibilityGranted {
                    Label("Permission Granted", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.headline)
                } else {
                    Label("Permission Required", systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .font(.headline)
                }
            }
            .padding(.top, 4)

            if !coordinator.accessibilityManager.isAccessibilityGranted {
                VStack(spacing: 8) {
                    Button("Grant Accessibility Access") {
                        coordinator.accessibilityManager.promptForPermission()
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Open System Settings") {
                        coordinator.accessibilityManager.openAccessibilityPreferences()
                    }
                    .buttonStyle(.bordered)

                    Button("Re-check Permission") {
                        coordinator.accessibilityManager.checkPermission()
                    }
                    .buttonStyle(.link)
                    .font(.caption)
                }
            }

            Text("You can skip this step and grant permission later in Settings.")
                .font(.caption)
                .foregroundStyle(.tertiary)

            Spacer()
        }
        .padding()
    }

    private var positionStep: some View {
        VStack(spacing: 16) {
            @Bindable var settings = coordinator.settings

            Spacer()

            Image(systemName: "macwindow.on.rectangle")
                .font(.system(size: 48))
                .foregroundStyle(.tint)

            Text("Suggestion Panel Position")
                .font(.title)
                .fontWeight(.bold)

            Text("Choose where the suggestion panel appears when Iridium has a recommendation for you.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Picker("Position", selection: $settings.suggestionPosition) {
                ForEach(SuggestionPosition.allCases) { position in
                    Text(position.rawValue).tag(position)
                }
            }
            .pickerStyle(.radioGroup)
            .padding(.top, 8)

            // Mini preview
            positionPreview(position: settings.suggestionPosition)
                .frame(width: 200, height: 125)
                .padding(.top, 4)

            Spacer()
        }
        .padding()
    }

    private var privacyStep: some View {
        VStack(spacing: 16) {
            @Bindable var settings = coordinator.settings

            Spacer()

            Image(systemName: "lock.shield.fill")
                .font(.system(size: 48))
                .foregroundStyle(.green)

            Text("Your Privacy Matters")
                .font(.title)
                .fontWeight(.bold)

            Text("Iridium processes everything on your Mac. No clipboard data, browsing history, or personal information is ever stored or sent anywhere.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            VStack(alignment: .leading, spacing: 12) {
                Toggle("Learn from my app choices", isOn: $settings.enablePersistentLearning)
                    .toggleStyle(.switch)

                Text("When enabled, Iridium remembers which apps you pick most often to improve suggestions over time. Only app selection counts are stored — never clipboard content.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 40)
            .padding(.top, 8)

            Spacer()
        }
        .padding()
    }

    // MARK: - Helpers

    private func featureRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func positionPreview(position: SuggestionPosition) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondary.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.secondary.opacity(0.3), lineWidth: 1)
                )

            // Menu bar
            Rectangle()
                .fill(Color.secondary.opacity(0.15))
                .frame(height: 8)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 1)
                .offset(y: -58)

            // Panel indicator
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.accentColor.opacity(0.6))
                .frame(width: 40, height: 50)
                .offset(panelOffset(for: position))
        }
    }

    private func panelOffset(for position: SuggestionPosition) -> CGSize {
        switch position {
        case .nearCursor:
            return CGSize(width: -20, height: 10)
        case .topRight:
            return CGSize(width: 70, height: -30)
        case .bottomRight:
            return CGSize(width: 70, height: 30)
        }
    }

    private func completeOnboarding() {
        coordinator.settings.hasCompletedOnboarding = true
        onComplete()
    }
}
