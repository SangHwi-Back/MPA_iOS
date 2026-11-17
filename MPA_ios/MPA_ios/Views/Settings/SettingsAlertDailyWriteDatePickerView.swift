//
//  [NO AC] Spec: specs/settings/SCREEN_SPEC.md
//
//  SettingsAlertDailyWriteDatePickerView.swift
//  MPA_ios
//

import SwiftUI

/// "매일 쓰기 알림" sheet. Edits a copy of the setting; ✓ applies it, ✕ or dragging down discards it.
struct SettingsAlertDailyWriteDatePickerView: View {

    let onConfirm: (_ isOn: Bool, _ hour: Int, _ minute: Int) -> Void
    let onCancel: () -> Void

    @State private var isOn: Bool
    @State private var isAfternoon: Bool
    /// 1…12.
    @State private var hour12: Int
    @State private var minute: Int

    private static let minutes = Array(stride(from: 0, to: 60, by: 5))

    init(
        isOn: Bool,
        hour: Int,
        minute: Int,
        onConfirm: @escaping (_ isOn: Bool, _ hour: Int, _ minute: Int) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.onConfirm = onConfirm
        self.onCancel = onCancel
        _isOn = State(initialValue: isOn)
        _isAfternoon = State(initialValue: hour >= 12)
        _hour12 = State(initialValue: hour % 12 == 0 ? 12 : hour % 12)
        _minute = State(initialValue: minute - minute % 5)
    }

    private var hour24: Int {
        (hour12 % 12) + (isAfternoon ? 12 : 0)
    }

    var body: some View {
        VStack(spacing: 16) {
            header

            Toggle("알림 받기", isOn: $isOn.animation())
                .font(.system(size: 17))
                .foregroundStyle(Color.TEXT_PRIMARY)
                .tint(Color.BRAND_PRIMARY)
                .accessibilityIdentifier(AccessibilityID.AlertDailyWriteDatePicker.toggle)
                .padding(.horizontal, 24)
                .frame(minHeight: 76)
                .background(Color.SURFACE, in: .rect(cornerRadius: SettingsLayout.phoneCardRadius))

            if isOn {
                timePicker
                    .transition(.opacity)
            }

            Text("매일 이 시간에 오늘 일기를 쓰도록 알려 드려요. 알림에는 일기 내용이 표시되지 않아요.")
                .font(.system(size: 13))
                .lineSpacing(3)
                .foregroundStyle(Color.TEXT_SECONDARY)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.top, 20)
        .background(Color.CONTAINER.ignoresSafeArea())
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(AccessibilityID.AlertDailyWriteDatePicker.screen)
    }

    private var header: some View {
        ZStack {
            Text("매일 쓰기 알림")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.TEXT_PRIMARY)
                .accessibilityAddTraits(.isHeader)

            HStack {
                closeButton
                Spacer()
                confirmButton
            }
        }
    }

    private var closeButton: some View {
        Button(action: onCancel) {
            Image(systemName: "xmark")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Color.TEXT_PRIMARY)
                .frame(width: 44, height: 44)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .accessibilityLabel("닫기")
        .accessibilityIdentifier(AccessibilityID.AlertDailyWriteDatePicker.cancel)
    }

    private var confirmButton: some View {
        Button {
            onConfirm(isOn, hour24, minute)
        } label: {
            Image(systemName: "checkmark")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.BRAND_ON_PRIMARY)
                .frame(width: 44, height: 44)
        }
        .buttonStyle(.glassProminent)
        .buttonBorderShape(.circle)
        .tint(Color.BRAND_PRIMARY)
        .accessibilityLabel("저장")
        .accessibilityIdentifier(AccessibilityID.AlertDailyWriteDatePicker.confirm)
    }

    private var timePicker: some View {
        ReminderTimeWheel(isAfternoon: $isAfternoon, hour12: $hour12, minute: $minute, minutes: Self.minutes)
            .accessibilityIdentifier(AccessibilityID.AlertDailyWriteDatePicker.timePicker)
            .frame(height: 190)
            .padding(.horizontal, 8)
            .background(Color.SURFACE, in: .rect(cornerRadius: SettingsLayout.phoneCardRadius))
    }
}

/// One `UIPickerView` with three columns, so a single selection band spans 오전/오후, hour and minute.
/// Three SwiftUI wheel pickers would each draw their own band.
private struct ReminderTimeWheel: UIViewRepresentable {
    @Binding var isAfternoon: Bool
    @Binding var hour12: Int
    @Binding var minute: Int
    let minutes: [Int]

    private static let hours = Array(1...12)

    func makeUIView(context: Context) -> UIPickerView {
        let picker = UIPickerView()
        picker.dataSource = context.coordinator
        picker.delegate = context.coordinator
        picker.accessibilityLabel = "알림 시각"
        return picker
    }

    func updateUIView(_ picker: UIPickerView, context: Context) {
        context.coordinator.parent = self
        picker.selectRow(isAfternoon ? 1 : 0, inComponent: 0, animated: false)
        picker.selectRow(Self.hours.firstIndex(of: hour12) ?? 0, inComponent: 1, animated: false)
        picker.selectRow(minutes.firstIndex(of: minute) ?? 0, inComponent: 2, animated: false)
    }

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    final class Coordinator: NSObject, UIPickerViewDataSource, UIPickerViewDelegate {
        var parent: ReminderTimeWheel

        init(parent: ReminderTimeWheel) { self.parent = parent }

        func numberOfComponents(in pickerView: UIPickerView) -> Int { 3 }

        func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
            switch component {
            case 0: return 2
            case 1: return ReminderTimeWheel.hours.count
            default: return parent.minutes.count
            }
        }

        func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat { 44 }

        func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
            let label = (view as? UILabel) ?? UILabel()
            label.textAlignment = .center
            label.font = .systemFont(ofSize: 22)
            switch component {
            case 0: label.text = row == 0 ? "오전" : "오후"
            case 1: label.text = "\(ReminderTimeWheel.hours[row])"
            default: label.text = String(format: "%02d", parent.minutes[row])
            }
            return label
        }

        func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
            switch component {
            case 0: parent.isAfternoon = row == 1
            case 1: parent.hour12 = ReminderTimeWheel.hours[row]
            default: parent.minute = parent.minutes[row]
            }
        }
    }
}

#Preview("alertDailyWriteDatePicker") {
    Color.SUNKEN
        .ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            SettingsAlertDailyWriteDatePickerView(isOn: true, hour: 21, minute: 30, onConfirm: { _, _, _ in }, onCancel: {})
                .presentationDetents([.medium, .large])
        }
}
