import SwiftUI
import SwiftData

// MARK: - Export Range
enum ExportRange: String, CaseIterable {
    case week  = "pdf.range.week"
    case month = "pdf.range.month"
    case all   = "pdf.range.all"
}

// MARK: - PDF Language
struct PDFLanguage: Identifiable, Hashable {
    let id: String
    let displayName: String
    let flag: String

    static let all: [PDFLanguage] = [
        PDFLanguage(id: "en",      displayName: "English",   flag: "🇬🇧"),
        PDFLanguage(id: "es",      displayName: "Español",   flag: "🇪🇸"),
        PDFLanguage(id: "fr",      displayName: "Français",  flag: "🇫🇷"),
        PDFLanguage(id: "zh-Hans", displayName: "中文",       flag: "🇨🇳"),
        PDFLanguage(id: "pt-BR",   displayName: "Português", flag: "🇧🇷"),
    ]

    static var appLanguageMatch: PDFLanguage {
        let current = UserDefaults.standard.string(forKey: "selectedLanguage")
            ?? Locale.current.language.languageCode?.identifier ?? "en"
        return all.first { current.hasPrefix($0.id) || $0.id.hasPrefix(current) } ?? all[0]
    }
}

// MARK: - PDF Export View
struct PDFExportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \SymptomEntry.date, order: .reverse) private var entries: [SymptomEntry]

    @State private var selectedRange: ExportRange = .week
    @State private var selectedLanguage: PDFLanguage = PDFLanguage.appLanguageMatch
    @State private var isGenerating = false
    @State private var pdfURL: URL? = nil
    @State private var showingShareSheet = false
    @AppStorage("patientName") private var storedName = ""
    @State private var patientName = ""



    var filteredEntries: [SymptomEntry] {
        let calendar = Calendar.current
        let now = Date()
        switch selectedRange {
        case .week:
            let cutoff = calendar.date(byAdding: .day, value: -7, to: now)!
            return entries.filter { $0.date >= cutoff }
        case .month:
            let cutoff = calendar.date(byAdding: .day, value: -30, to: now)!
            return entries.filter { $0.date >= cutoff }
        case .all:
            return entries
        }
    }

    var pdfBundle: Bundle {
        guard let path = Bundle.main.path(forResource: selectedLanguage.id, ofType: "lproj"),
              let bundle = Bundle(path: path) else { return .main }
        return bundle
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {

                    // Header
                    VStack(spacing: 10) {
                        Image(systemName: "doc.richtext")
                            .font(.system(size: 44))
                            .foregroundStyle(Color("accentTeal"))
                            .padding(20)
                            .background(Color("accentTeal").opacity(0.1))
                            .clipShape(Circle())

                        Text("pdf.export.title")
                            .font(.custom("Georgia", size: 22))
                            .fontWeight(.semibold)
                            .foregroundStyle(Color("textPrimary"))

                        Text("pdf.export.subtitle")
                            .font(.system(size: 14))
                            .foregroundStyle(Color("textSecondary"))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 8)

                    // Patient name
                    VStack(alignment: .leading, spacing: 8) {
                        label(NSLocalizedString("pdf.export.name", comment: ""))
                        TextField(NSLocalizedString("pdf.export.name.placeholder", comment: ""), text: $patientName)
                            .font(.system(size: 16))
                            .padding(14)
                            .background(Color("chipBackground"))
                            .clipShape(RoundedRectangle(cornerRadius: 13))
                    }

                    // Date range
                    VStack(alignment: .leading, spacing: 10) {
                        label(NSLocalizedString("pdf.export.range", comment: ""))
                        HStack(spacing: 10) {
                            ForEach(ExportRange.allCases, id: \.self) { range in
                                Button {
                                    withAnimation(.spring(response: 0.25)) { selectedRange = range }
                                } label: {
                                    Text(NSLocalizedString(range.rawValue, comment: ""))
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(selectedRange == range ? .white : Color("textSecondary"))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(selectedRange == range ? Color("accentTeal") : Color("chipBackground"))
                                        .clipShape(RoundedRectangle(cornerRadius: 11))
                                }
                            }
                        }
                    }

                    // PDF Language picker
                    VStack(alignment: .leading, spacing: 10) {
                        VStack(alignment: .leading, spacing: 3) {
                            label(NSLocalizedString("pdf.language.picker", comment: ""))
                            Text("pdf.language.hint")
                                .font(.system(size: 12))
                                .foregroundStyle(Color("textTertiary"))
                        }

                        HStack(spacing: 8) {
                            ForEach(PDFLanguage.all) { lang in
                                Button {
                                    withAnimation(.spring(response: 0.25)) { selectedLanguage = lang }
                                } label: {
                                    VStack(spacing: 4) {
                                        Text(lang.flag)
                                            .font(.system(size: 22))
                                        Text(lang.displayName)
                                            .font(.system(size: 10, weight: .semibold))
                                            .foregroundStyle(selectedLanguage == lang ? .white : Color("textSecondary"))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(selectedLanguage == lang ? Color("accentTeal") : Color("chipBackground"))
                                    .clipShape(RoundedRectangle(cornerRadius: 11))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 11)
                                            .stroke(selectedLanguage == lang ? Color.clear : Color("borderColor"), lineWidth: 1)
                                    )
                                }
                            }
                        }

                    }

                    // Preview summary
                    previewCard

                    // Generate button
                    Button {
                        generatePDF()
                    } label: {
                        HStack(spacing: 10) {
                            if isGenerating {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(.white)
                                    .scaleEffect(0.85)
                            } else {
                                Image(systemName: "arrow.up.doc.fill")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            Text(buttonLabel)
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(filteredEntries.isEmpty ? Color("accentTeal").opacity(0.4) : Color("accentTeal"))
                                .shadow(color: Color("accentTeal").opacity(0.35), radius: 12, y: 4)
                        )
                    }
                    .disabled(filteredEntries.isEmpty || isGenerating)

                    if filteredEntries.isEmpty {
                        Text("pdf.export.nodata")
                            .font(.system(size: 13))
                            .foregroundStyle(Color("textTertiary"))
                            .multilineTextAlignment(.center)
                    }

                    Spacer().frame(height: 20)
                }
                .padding(.horizontal, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("button.close", comment: "")) { dismiss() }
                        .foregroundStyle(Color("textSecondary"))
                }
            }
            .background(Color("backgroundPrimary"))
            .onAppear { if patientName.isEmpty { patientName = storedName } }

        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = pdfURL {
                ShareSheet(activityItems: [url])
            }
        }

    }

    var buttonLabel: String {
        if isGenerating { return NSLocalizedString("pdf.export.generating", comment: "") }
        return NSLocalizedString("pdf.export.generate", comment: "")
    }

    // MARK: - Generate PDF
    func generatePDF() {
        isGenerating = true
        DispatchQueue.global(qos: .userInitiated).async {
            let generator = PDFDataGenerator(
                entries: filteredEntries,
                patientName: patientName,
                range: selectedRange,
                pdfBundle: pdfBundle
            )
            let renderer = SymptomPDFRenderer(generator: generator)
            let url = renderer.render()
            DispatchQueue.main.async {
                self.pdfURL = url
                self.isGenerating = false
                self.showingShareSheet = url != nil
            }
        }
    }

    // MARK: - Preview card
    var previewCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("pdf.export.preview")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color("textPrimary"))
                Spacer()
                Text(String(format: NSLocalizedString("pdf.export.entries", comment: ""), filteredEntries.count))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color("accentTeal"))
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(Color("accentTeal").opacity(0.1))
                    .clipShape(Capsule())
            }

            Divider()

            let generator = PDFDataGenerator(entries: filteredEntries, patientName: patientName,
                                             range: selectedRange, pdfBundle: pdfBundle)

            if let top = generator.mostConcerningSymptom {
                previewRow(icon: "exclamationmark.triangle.fill",
                           iconColor: Color("severityHigh"),
                           title: NSLocalizedString("pdf.export.concerning", comment: ""),
                           value: "\(NSLocalizedString(top.name, comment: top.name)) — avg \(String(format: "%.1f", top.avgSeverity))/10")
            }

            previewRow(icon: "heart.fill",
                       iconColor: Color("accentTeal"),
                       title: NSLocalizedString("pdf.export.avgmood", comment: ""),
                       value: String(format: "%.1f / 10", generator.avgMentalHealth))

            previewRow(icon: "list.bullet",
                       iconColor: Color("accentTeal"),
                       title: NSLocalizedString("pdf.export.unique", comment: ""),
                       value: String(format: NSLocalizedString("pdf.export.tracked", comment: ""),
                                     generator.uniqueSymptomCount))

            previewRow(icon: "calendar",
                       iconColor: Color("accentTeal"),
                       title: NSLocalizedString("pdf.export.daterange", comment: ""),
                       value: generator.dateRangeLabel)
        }
        .padding(16)
        .background(Color("cardBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
    }

    func previewRow(icon: String, iconColor: Color, title: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(iconColor)
                .frame(width: 28)
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color("textSecondary"))
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color("textPrimary"))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }

    func label(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(Color("textTertiary"))
            .textCase(.uppercase)
            .tracking(0.7)
    }
}

// MARK: - Share Sheet wrapper
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ uvc: UIActivityViewController, context: Context) {}
}
