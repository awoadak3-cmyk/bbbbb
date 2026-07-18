import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var vm: AppViewModel
    @State private var repoText: String = ""
    @State private var branchText: String = "main"
    @State private var tokenText: String = ""

    var body: some View {
        ZStack {
            AuroraColor.deepBlack.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("مصدر البيانات").font(.system(size: 18, weight: .bold)).foregroundStyle(.white)

                    field("owner/repo", text: $repoText)
                    field("الفرع (branch)", text: $branchText)
                    field("GitHub Token (اختياري، لطلبات الإضافة)", text: $tokenText, secure: true)

                    Button {
                        vm.settings.updateRepo(repoText)
                        vm.settings.settings.branch = branchText.isEmpty ? "main" : branchText
                        vm.settings.settings.token = tokenText
                        vm.settings.save()
                        Task { await vm.loadInitial() }
                    } label: {
                        Text("حفظ وتحديث")
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AuroraColor.brandRed, in: RoundedRectangle(cornerRadius: 14))
                    }

                    Divider().background(Color.white.opacity(0.1))

                    Text("عن التطبيق").font(.system(size: 18, weight: .bold)).foregroundStyle(.white)
                    Text("AuroraStream لـ iOS — نسخة كاملة بلغة Swift/SwiftUI، تقرأ نفس بيانات مستودع GitHub اللي يستخدمها إصدار أندرويد.")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .padding(20)
            }
        }
        .onAppear {
            repoText = vm.settings.settings.repo
            branchText = vm.settings.settings.branch
            tokenText = vm.settings.settings.token
        }
    }

    private func field(_ label: String, text: Binding<String>, secure: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.system(size: 12)).foregroundStyle(.white.opacity(0.5))
            Group {
                if secure {
                    SecureField("", text: text)
                } else {
                    TextField("", text: text)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
            }
            .foregroundStyle(.white)
            .padding(12)
            .background(AuroraColor.surfaceDark, in: RoundedRectangle(cornerRadius: 10))
        }
    }
}
