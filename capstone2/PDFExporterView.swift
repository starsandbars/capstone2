//
//  PDFExporterView.swift
//  capstone2
//
//  Created by Xiaojing Meng on 3/11/26.
//
import SwiftUI
import SwiftData

// MARK: - Export Range
enum ExportRange: String, CaseIterable {
    case week  = "Last 7 Days"
    case month = "Last 30 Days"
    case all   = "All Time"
}

// MARK: - PDF Export View (sheet)
struct PDFExportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \SymptomEntry.date, order: .reverse) private var entries: [SymptomEntry]

    @State private var selectedRange: ExportRange = .week
    @State private var isGenerating = false
    @State private var pdfURL: URL? = nil
    @State private var showingShareSheet = false
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

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {

                    // Header illustration
                    VStack(spacing: 10) {
                        Image(systemName: "doc.richtext")
                            .font(.system(size: 44))
                            .foregroundStyle(Color("accentTeal"))
                            .padding(20)
                            .background(Color("accentTeal").opacity(0.1))
                            .clipShape(Circle())

                        Text("Export Symptom Report")
                            .font(.custom("Georgia", size: 22))
                            .fontWeight(.semibold)
                            .foregroundStyle(Color("textPrimary"))

                        Text("Generate a PDF summary to share with your care team.")
                            .font(.system(size: 14))
                            .foregroundStyle(Color("textSecondary"))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 8)

                    // Patient name (optional)
                    VStack(alignment: .leading, spacing: 8) {
                        label("Your Name (optional)")
                        TextField("e.g. Jane Smith", text: $patientName)
                            .font(.system(size: 16))
                            .padding(14)
                            .background(Color("chipBackground"))
                            .clipShape(RoundedRectangle(cornerRadius: 13))
                    }

                    // Date range selector
                    VStack(alignment: .leading, spacing: 10) {
                        label("Date Range")
                        HStack(spacing: 10) {
                            ForEach(ExportRange.allCases, id: \.self) { range in
                                Button {
                                    withAnimation(.spring(response: 0.25)) { selectedRange = range }
                                } label: {
                                    Text(range.rawValue)
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
                            Text(isGenerating ? "Generating…" : "Generate & Share PDF")
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
                        Text("No entries found for the selected date range.")
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
                    Button("Close") { dismiss() }
                        .foregroundStyle(Color("textSecondary"))
                }
            }
            .background(Color("backgroundPrimary"))
        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = pdfURL {
                ShareSheet(activityItems: [url])
            }
        }
    }

    // MARK: - Preview card
    var previewCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Report Preview")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color("textPrimary"))
                Spacer()
                Text("\(filteredEntries.count) entries")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color("accentTeal"))
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(Color("accentTeal").opacity(0.1))
                    .clipShape(Capsule())
            }

            Divider()

            let generator = PDFDataGenerator(entries: filteredEntries, patientName: patientName, range: selectedRange)

            // Concerning symptoms
            if let top = generator.mostConcerningSymptom {
                previewRow(icon: "exclamationmark.triangle.fill",
                           iconColor: Color("severityHigh"),
                           title: "Most Concerning",
                           value: "\(top.name) — avg severity \(String(format: "%.1f", top.avgSeverity))/10")
            }

            previewRow(icon: "heart.fill",
                       iconColor: Color("accentTeal"),
                       title: "Avg Mental Health",
                       value: String(format: "%.1f / 10", generator.avgMentalHealth))

            previewRow(icon: "list.bullet",
                       iconColor: Color("accentTeal"),
                       title: "Unique Symptoms",
                       value: "\(generator.uniqueSymptomCount) tracked")

            previewRow(icon: "calendar",
                       iconColor: Color("accentTeal"),
                       title: "Date Range",
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

    // MARK: - Generate PDF
    func generatePDF() {
        isGenerating = true
        DispatchQueue.global(qos: .userInitiated).async {
            let generator = PDFDataGenerator(entries: filteredEntries, patientName: patientName, range: selectedRange)
            let renderer = SymptomPDFRenderer(generator: generator)
            let url = renderer.render()
            DispatchQueue.main.async {
                self.pdfURL = url
                self.isGenerating = false
                self.showingShareSheet = url != nil
            }
        }
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
