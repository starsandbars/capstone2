//
//  SymptomPDFRenderer.swift
//  capstone2
//
//  Created by Xiaojing Meng on 3/11/26.
//

import UIKit
import SwiftUI

// MARK: - PDF Renderer using UIGraphicsPDFRenderer
class SymptomPDFRenderer {
    let gen: PDFDataGenerator

    // Layout constants
    let pageWidth:  CGFloat = 595   // A4
    let pageHeight: CGFloat = 842
    let margin:     CGFloat = 48
    var contentWidth: CGFloat { pageWidth - margin * 2 }

    // Colors
    let teal      = UIColor(red: 0.165, green: 0.612, blue: 0.561, alpha: 1)
    let tealLight = UIColor(red: 0.165, green: 0.612, blue: 0.561, alpha: 0.08)
    let red       = UIColor(red: 0.906, green: 0.298, blue: 0.235, alpha: 1)
    let amber     = UIColor(red: 0.902, green: 0.494, blue: 0.133, alpha: 1)
    let green     = UIColor(red: 0.153, green: 0.682, blue: 0.376, alpha: 1)
    let darkText  = UIColor(red: 0.1,   green: 0.1,   blue: 0.1,   alpha: 1)
    let grayText  = UIColor(red: 0.45,  green: 0.45,  blue: 0.45,  alpha: 1)
    let lightGray = UIColor(red: 0.94,  green: 0.94,  blue: 0.93,  alpha: 1)
    let border    = UIColor(red: 0.88,  green: 0.88,  blue: 0.87,  alpha: 1)

    // State
    var currentY: CGFloat = 0
    var context: UIGraphicsPDFRendererContext!
    var currentPage: Int = 0

    init(generator: PDFDataGenerator) {
        self.gen = generator
    }

    func render() -> URL? {
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))
        let fileName = "SymptomReport_\(Date().timeIntervalSince1970).pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try renderer.writePDF(to: url) { ctx in
                self.context = ctx
                self.beginPage()
                self.drawCoverHeader()
                self.drawSummaryBox()
                self.drawKeyMetrics()
                self.drawSymptomTable()
                self.drawDailyLog()
                self.drawFooter()
            }
            return url
        } catch {
            return nil
        }
    }

    // MARK: - Page management
    func beginPage() {
        context.beginPage()
        currentPage += 1
        currentY = margin
    }

    func checkPageBreak(needing height: CGFloat) {
        if currentY + height > pageHeight - margin - 30 {
            drawPageNumber()
            beginPage()
        }
    }

    func drawPageNumber() {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9),
            .foregroundColor: grayText
        ]
        let text = "Page \(currentPage)"
        let size = (text as NSString).size(withAttributes: attrs)
        (text as NSString).draw(at: CGPoint(x: pageWidth - margin - size.width,
                                             y: pageHeight - margin + 8), withAttributes: attrs)
    }

    // MARK: - Cover Header
    func drawCoverHeader() {
        // Teal header band
        let bandHeight: CGFloat = 120
        let bandRect = CGRect(x: 0, y: 0, width: pageWidth, height: bandHeight)
        teal.setFill()
        UIBezierPath(rect: bandRect).fill()

        // Subtle diagonal stripe pattern
        UIColor.white.withAlphaComponent(0.05).setStroke()
        let path = UIBezierPath()
        var x: CGFloat = -bandHeight
        while x < pageWidth + bandHeight {
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x + bandHeight, y: bandHeight))
            x += 24
        }
        path.lineWidth = 1
        path.stroke()

        // App name
        let appAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .semibold),
            .foregroundColor: UIColor.white.withAlphaComponent(0.75),
            .kern: 1.5
        ]
        ("SYMPTOM TRACKER" as NSString).draw(at: CGPoint(x: margin, y: 22), withAttributes: appAttrs)

        // Report title
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: "Georgia-Bold", size: 26) ?? UIFont.boldSystemFont(ofSize: 26),
            .foregroundColor: UIColor.white
        ]
        ("Symptom Report" as NSString).draw(at: CGPoint(x: margin, y: 44), withAttributes: titleAttrs)

        // Date range
        let subAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 13, weight: .medium),
            .foregroundColor: UIColor.white.withAlphaComponent(0.85)
        ]
        (gen.dateRangeLabel as NSString).draw(at: CGPoint(x: margin, y: 78), withAttributes: subAttrs)

        // Patient name if provided
        if !gen.patientName.isEmpty {
            let nameAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.white.withAlphaComponent(0.7)
            ]
            let nameText = "Patient: \(gen.patientName)"
            let nameSize = (nameText as NSString).size(withAttributes: nameAttrs)
            (nameText as NSString).draw(at: CGPoint(x: pageWidth - margin - nameSize.width, y: 78),
                                        withAttributes: nameAttrs)
        }

        // Generated timestamp at bottom right of band
        let tsAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9),
            .foregroundColor: UIColor.white.withAlphaComponent(0.55)
        ]
        let ts = "Generated \(gen.generatedLabel)"
        let tsSize = (ts as NSString).size(withAttributes: tsAttrs)
        (ts as NSString).draw(at: CGPoint(x: pageWidth - margin - tsSize.width, y: 100),
                               withAttributes: tsAttrs)

        currentY = bandHeight + 24
    }

    // MARK: - Summary Box
    func drawSummaryBox() {
        let text = gen.overallSummary
        let textAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: darkText
        ]
        let boundingRect = CGRect(x: 0, y: 0, width: contentWidth - 32, height: 200)
        let textHeight = (text as NSString).boundingRect(with: boundingRect.size,
                                                          options: .usesLineFragmentOrigin,
                                                          attributes: textAttrs, context: nil).height
        let boxHeight = textHeight + 44

        checkPageBreak(needing: boxHeight + 16)

        // Box background
        let boxRect = CGRect(x: margin, y: currentY, width: contentWidth, height: boxHeight)
        tealLight.setFill()
        UIBezierPath(roundedRect: boxRect, cornerRadius: 10).fill()

        // Left accent bar
        let accentRect = CGRect(x: margin, y: currentY, width: 4, height: boxHeight)
        teal.setFill()
        UIBezierPath(roundedRect: accentRect, cornerRadius: 2).fill()

        // "Clinical Summary" label
        let labelAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10, weight: .bold),
            .foregroundColor: teal,
            .kern: 1.0
        ]
        ("CLINICAL SUMMARY" as NSString).draw(at: CGPoint(x: margin + 16, y: currentY + 14),
                                               withAttributes: labelAttrs)

        // Summary text
        (text as NSString).draw(in: CGRect(x: margin + 16, y: currentY + 30,
                                           width: contentWidth - 32, height: textHeight + 4),
                                withAttributes: textAttrs)

        currentY += boxHeight + 20
    }

    // MARK: - Key Metrics Row
    func drawKeyMetrics() {
        checkPageBreak(needing: 90)

        let sectionTitle = "AT A GLANCE"
        drawSectionTitle(sectionTitle)

        let metrics: [(String, String, UIColor)] = [
            ("Days Logged",    "\(gen.entries.count)",                      teal),
            ("Symptoms Found", "\(gen.uniqueSymptomCount)",                 teal),
            ("Avg Mood",       String(format: "%.1f/10", gen.avgMentalHealth), moodColor(gen.avgMentalHealth)),
            ("Most Severe",    gen.topSymptoms.first.map { String(format: "%.1f", $0.avgSeverity) } ?? "N/A",
                               severityColor(gen.topSymptoms.first?.avgSeverity ?? 0))
        ]

        let cardW: CGFloat = (contentWidth - 12 * 3) / 4
        let cardH: CGFloat = 64

        for (i, metric) in metrics.enumerated() {
            let x = margin + CGFloat(i) * (cardW + 12)
            let cardRect = CGRect(x: x, y: currentY, width: cardW, height: cardH)
            lightGray.setFill()
            UIBezierPath(roundedRect: cardRect, cornerRadius: 8).fill()

            // Value
            let valAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 20),
                .foregroundColor: metric.2
            ]
            let valSize = (metric.1 as NSString).size(withAttributes: valAttrs)
            (metric.1 as NSString).draw(at: CGPoint(x: x + (cardW - valSize.width) / 2, y: currentY + 10),
                                         withAttributes: valAttrs)

            // Label
            let lblAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 9, weight: .medium),
                .foregroundColor: grayText
            ]
            let lblSize = (metric.0 as NSString).size(withAttributes: lblAttrs)
            (metric.0 as NSString).draw(at: CGPoint(x: x + (cardW - lblSize.width) / 2, y: currentY + 36),
                                         withAttributes: lblAttrs)
        }

        currentY += cardH + 24
    }

    // MARK: - Symptom Table
    func drawSymptomTable() {
        guard !gen.topSymptoms.isEmpty else { return }
        checkPageBreak(needing: 120)
        drawSectionTitle("SYMPTOM SUMMARY")

        // Table header
        let cols: [(String, CGFloat)] = [
            ("Symptom",   0.32),
            ("Category",  0.20),
            ("Times",     0.10),
            ("Avg Sev",   0.13),
            ("Max Sev",   0.13),
            ("Trend",     0.12)
        ]

        let headerH: CGFloat = 26
        let rowH:    CGFloat = 28

        // Header bg
        let headerRect = CGRect(x: margin, y: currentY, width: contentWidth, height: headerH)
        UIColor(red: 0.22, green: 0.22, blue: 0.22, alpha: 1).setFill()
        UIBezierPath(roundedRect: headerRect, cornerRadius: 6).fill()

        var colX = margin
        for (title, fraction) in cols {
            let colW = contentWidth * fraction
            let hAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 9, weight: .bold),
                .foregroundColor: UIColor.white,
                .kern: 0.5
            ]
            (title.uppercased() as NSString).draw(at: CGPoint(x: colX + 6, y: currentY + 8),
                                                   withAttributes: hAttrs)
            colX += colW
        }
        currentY += headerH

        // Rows
        for (idx, stat) in gen.topSymptoms.enumerated() {
            checkPageBreak(needing: rowH + 4)

            let rowRect = CGRect(x: margin, y: currentY, width: contentWidth, height: rowH)
            let bgColor = idx % 2 == 0 ? UIColor.white : lightGray
            bgColor.setFill()
            UIBezierPath(roundedRect: rowRect, cornerRadius: 0).fill()

            // Bottom border
            border.setStroke()
            let linePath = UIBezierPath()
            linePath.move(to: CGPoint(x: margin, y: currentY + rowH))
            linePath.addLine(to: CGPoint(x: margin + contentWidth, y: currentY + rowH))
            linePath.lineWidth = 0.5
            linePath.stroke()

            let cellAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11),
                .foregroundColor: darkText
            ]
            let smallAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10),
                .foregroundColor: grayText
            ]

            let trendColor = stat.trend == "Worsening" ? red : stat.trend == "Improving" ? green : grayText
            let trendAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10, weight: .semibold),
                .foregroundColor: trendColor
            ]
            let sevColor = severityColor(stat.avgSeverity)
            let sevAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 11),
                .foregroundColor: sevColor
            ]

            let cellY = currentY + (rowH - 14) / 2
            var cx = margin

            let values: [(String, [NSAttributedString.Key: Any], CGFloat)] = [
                (stat.name,                     cellAttrs, contentWidth * 0.32),
                (stat.category.rawValue,         smallAttrs, contentWidth * 0.20),
                ("\(stat.occurrences)x",         smallAttrs, contentWidth * 0.10),
                (String(format: "%.1f", stat.avgSeverity), sevAttrs, contentWidth * 0.13),
                ("\(stat.maxSeverity)/10",       smallAttrs, contentWidth * 0.13),
                (stat.trend,                     trendAttrs, contentWidth * 0.12)
            ]

            for (val, attrs, width) in values {
                (val as NSString).draw(at: CGPoint(x: cx + 6, y: cellY), withAttributes: attrs)
                cx += width
            }

            currentY += rowH
        }

        currentY += 20
    }

    // MARK: - Daily Log
    func drawDailyLog() {
        guard !gen.dailySnapshots.isEmpty else { return }
        checkPageBreak(needing: 80)
        drawSectionTitle("DAILY LOG")

        let df = DateFormatter(); df.dateFormat = "EEE, MMM d"

        for snap in gen.dailySnapshots {
            let entryHeight: CGFloat = snap.symptoms.isEmpty ? 52 : CGFloat(52 + snap.symptoms.count * 18 + (snap.notes.isEmpty ? 0 : 22))
            checkPageBreak(needing: entryHeight + 10)

            // Date header row
            let dateRect = CGRect(x: margin, y: currentY, width: contentWidth, height: 26)
            lightGray.setFill()
            UIBezierPath(roundedRect: dateRect, cornerRadius: 6).fill()

            let dateAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11, weight: .semibold),
                .foregroundColor: darkText
            ]
            (df.string(from: snap.date) as NSString).draw(at: CGPoint(x: margin + 10, y: currentY + 6),
                                                           withAttributes: dateAttrs)

            // Mood indicator
            let moodText = "Mood: \(snap.mentalHealth)/10"
            let mColor = moodColor(Double(snap.mentalHealth))
            let moodAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10, weight: .semibold),
                .foregroundColor: mColor
            ]
            let moodSize = (moodText as NSString).size(withAttributes: moodAttrs)
            (moodText as NSString).draw(
                at: CGPoint(x: margin + contentWidth - moodSize.width - 10, y: currentY + 7),
                withAttributes: moodAttrs)

            currentY += 28

            if snap.symptoms.isEmpty {
                let emptyAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.italicSystemFont(ofSize: 11),
                    .foregroundColor: UIColor(red: 0.7, green: 0.7, blue: 0.7, alpha: 1)
                ]
                ("No symptoms logged" as NSString).draw(at: CGPoint(x: margin + 10, y: currentY + 4),
                                                        withAttributes: emptyAttrs)
                currentY += 22
            } else {
                for symptom in snap.symptoms {
                    let dot = "•"
                    let dotAttrs: [NSAttributedString.Key: Any] = [
                        .font: UIFont.systemFont(ofSize: 11),
                        .foregroundColor: grayText
                    ]
                    (dot as NSString).draw(at: CGPoint(x: margin + 10, y: currentY + 3), withAttributes: dotAttrs)

                    let symAttrs: [NSAttributedString.Key: Any] = [
                        .font: UIFont.systemFont(ofSize: 11),
                        .foregroundColor: darkText
                    ]
                    (symptom.name as NSString).draw(at: CGPoint(x: margin + 22, y: currentY + 3),
                                                    withAttributes: symAttrs)

                    // Severity bar
                    let barX = margin + contentWidth * 0.45
                    let barW = contentWidth * 0.35
                    let barH: CGFloat = 6
                    let barY = currentY + 7

                    border.setFill()
                    UIBezierPath(roundedRect: CGRect(x: barX, y: barY, width: barW, height: barH),
                                 cornerRadius: 3).fill()

                    let fillW = barW * CGFloat(symptom.severity) / 10.0
                    severityColor(Double(symptom.severity)).setFill()
                    UIBezierPath(roundedRect: CGRect(x: barX, y: barY, width: fillW, height: barH),
                                 cornerRadius: 3).fill()

                    let sevLbl = "\(symptom.severity)/10"
                    let sevAttrs: [NSAttributedString.Key: Any] = [
                        .font: UIFont.boldSystemFont(ofSize: 10),
                        .foregroundColor: severityColor(Double(symptom.severity))
                    ]
                    (sevLbl as NSString).draw(at: CGPoint(x: barX + barW + 6, y: currentY + 3),
                                              withAttributes: sevAttrs)

                    currentY += 18
                }
            }

            // Notes
            if !snap.notes.isEmpty {
                let noteAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.italicSystemFont(ofSize: 10),
                    .foregroundColor: grayText
                ]
                ("Note: \(snap.notes)" as NSString).draw(
                    in: CGRect(x: margin + 10, y: currentY, width: contentWidth - 20, height: 20),
                    withAttributes: noteAttrs)
                currentY += 18
            }

            currentY += 10
        }
    }

    // MARK: - Footer
    func drawFooter() {
        drawPageNumber()

        let footerY = pageHeight - margin + 4
        let footerAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8),
            .foregroundColor: UIColor(red: 0.75, green: 0.75, blue: 0.75, alpha: 1)
        ]
        let disclaimer = "This report is for informational purposes only and does not constitute medical advice. Please share with your healthcare provider."
        let disclaimerWidth = contentWidth
        let disclaimerSize = (disclaimer as NSString).boundingRect(
            with: CGSize(width: disclaimerWidth, height: 40),
            options: .usesLineFragmentOrigin,
            attributes: footerAttrs, context: nil)
        (disclaimer as NSString).draw(in: CGRect(x: margin, y: footerY,
                                                  width: disclaimerWidth, height: disclaimerSize.height),
                                      withAttributes: footerAttrs)
    }

    // MARK: - Helpers
    func drawSectionTitle(_ title: String) {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10, weight: .bold),
            .foregroundColor: teal,
            .kern: 1.2
        ]
        (title as NSString).draw(at: CGPoint(x: margin, y: currentY), withAttributes: attrs)
        currentY += 16

        // Underline
        teal.withAlphaComponent(0.25).setStroke()
        let line = UIBezierPath()
        line.move(to: CGPoint(x: margin, y: currentY))
        line.addLine(to: CGPoint(x: margin + contentWidth, y: currentY))
        line.lineWidth = 1
        line.stroke()
        currentY += 10
    }

    func severityColor(_ val: Double) -> UIColor {
        if val <= 3 { return green }
        if val <= 6 { return amber }
        return red
    }

    func moodColor(_ val: Double) -> UIColor {
        if val >= 7 { return green }
        if val >= 4 { return amber }
        return red
    }
}
