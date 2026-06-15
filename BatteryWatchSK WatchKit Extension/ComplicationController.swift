//
//  ComplicationController.swift
//  BatteryWatchSK WatchKit Extension
//
//  Created by Сергей Костров on 21.10.2019.
//  Copyright © 2019 Сергей Костров. All rights reserved.
//
import ClockKit
import UIKit

class ComplicationController: NSObject, CLKComplicationDataSource {

    // MARK: - Helpers

    /// Цвет по уровню заряда: зелёный >50%, жёлтый 20-50%, красный <20%
    private func batteryColor(for level: Float) -> UIColor {
        if level > 0.5 { return .green }
        if level > 0.2 { return .systemYellow }
        return .systemRed
    }

    /// Текст процента заряда, например "73%". Если данных нет — "--"
    private func batteryText() -> String {
        guard Model.shared.hasIPhoneData else { return "--" }
        let pct = Int(Model.shared.iPhoneBattery * 100)
        return "\(pct)%"
    }

    private func batteryFill() -> Float {
        guard Model.shared.hasIPhoneData else { return 0.5 }
        return max(0.0, min(1.0, Model.shared.iPhoneBattery))
    }

    // MARK: - Timeline Configuration

    func getSupportedTimeTravelDirections(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimeTravelDirections) -> Void) {
        handler([])
    }

    func getTimelineStartDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        handler(Calendar.current.startOfDay(for: Date()))
    }

    func getTimelineEndDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        var date = Calendar.current.startOfDay(for: Date())
        date = Calendar.current.date(byAdding: .day, value: 9999, to: date)!
        handler(date)
    }

    func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
        handler(.hideOnLockScreen)
    }

    // MARK: - Timeline Population

    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        let text = batteryText()
        let fill = batteryFill()
        let color = batteryColor(for: Model.shared.iPhoneBattery)

        switch complication.family {

        case .graphicCircular:
            // Круглая complications с двумя строками: иконка + процент
            let template = CLKComplicationTemplateGraphicCircularStackText()
            template.line1TextProvider = CLKSimpleTextProvider(text: "📱")
            template.line2TextProvider = CLKSimpleTextProvider(text: text)
            let entry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
            handler(entry)

        case .graphicBezel:
            // Круглая с текстом по дуге
            let circularTemplate = CLKComplicationTemplateGraphicCircularStackText()
            circularTemplate.line1TextProvider = CLKSimpleTextProvider(text: "📱")
            circularTemplate.line2TextProvider = CLKSimpleTextProvider(text: text)
            let template = CLKComplicationTemplateGraphicBezelCircularText()
            template.circularTemplate = circularTemplate
            template.textProvider = CLKSimpleTextProvider(text: "iPhone Battery")
            let entry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
            handler(entry)

        case .extraLarge:
            // Большая кольцевая с процентом
            let template = CLKComplicationTemplateExtraLargeRingText()
            template.textProvider = CLKSimpleTextProvider(text: text)
            template.fillFraction = fill
            template.ringStyle = .closed
            template.tintColor = color
            let entry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
            handler(entry)

        case .utilitarianSmall:
            // Маленькая утилитарная: кольцо с процентом
            let template = CLKComplicationTemplateUtilitarianSmallRingText()
            template.textProvider = CLKSimpleTextProvider(text: text)
            template.fillFraction = fill
            template.ringStyle = .closed
            template.tintColor = color
            let entry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
            handler(entry)

        case .modularSmall:
            // Модульная маленькая: кольцо с процентом
            let template = CLKComplicationTemplateModularSmallRingText()
            template.textProvider = CLKSimpleTextProvider(text: text)
            template.fillFraction = fill
            template.ringStyle = .closed
            template.tintColor = color
            let entry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
            handler(entry)

        case .circularSmall:
            // Круговая маленькая: кольцо с процентом
            let template = CLKComplicationTemplateCircularSmallRingText()
            template.textProvider = CLKSimpleTextProvider(text: text)
            template.fillFraction = fill
            template.ringStyle = .closed
            template.tintColor = color
            let entry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
            handler(entry)

        case .utilitarianLarge:
            // Широкая утилитарная: текст с иконкой и процентом
            let template = CLKComplicationTemplateUtilitarianLargeFlat()
            template.textProvider = CLKSimpleTextProvider(text: "📱 iPhone: \(text)")
            let entry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
            handler(entry)

        case .modularLarge:
            // Большая модульная: заголовок + данные
            let template = CLKComplicationTemplateModularLargeStandardBody()
            template.headerTextProvider = CLKSimpleTextProvider(text: "📱 iPhone Battery")
            template.body1TextProvider = CLKSimpleTextProvider(text: text)
            template.body2TextProvider = CLKSimpleTextProvider(text: Model.shared.iPhoneBatteryString)
            let entry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
            handler(entry)

        default:
            handler(nil)
        }
    }

    func getTimelineEntries(for complication: CLKComplication, before date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        handler(nil)
    }

    func getTimelineEntries(for complication: CLKComplication, after date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        handler(nil)
    }

    // MARK: - Placeholder Templates

    func getLocalizableSampleTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
        switch complication.family {

        case .graphicCircular:
            let template = CLKComplicationTemplateGraphicCircularStackText()
            template.line1TextProvider = CLKSimpleTextProvider(text: "📱")
            template.line2TextProvider = CLKSimpleTextProvider(text: "85%")
            handler(template)

        case .graphicBezel:
            let circularTemplate = CLKComplicationTemplateGraphicCircularStackText()
            circularTemplate.line1TextProvider = CLKSimpleTextProvider(text: "📱")
            circularTemplate.line2TextProvider = CLKSimpleTextProvider(text: "85%")
            let template = CLKComplicationTemplateGraphicBezelCircularText()
            template.circularTemplate = circularTemplate
            template.textProvider = CLKSimpleTextProvider(text: "iPhone Battery")
            handler(template)

        case .extraLarge:
            let template = CLKComplicationTemplateExtraLargeRingText()
            template.textProvider = CLKSimpleTextProvider(text: "85%")
            template.fillFraction = 0.85
            template.ringStyle = .closed
            handler(template)

        case .utilitarianSmall:
            let template = CLKComplicationTemplateUtilitarianSmallRingText()
            template.textProvider = CLKSimpleTextProvider(text: "85%")
            template.fillFraction = 0.85
            template.ringStyle = .closed
            handler(template)

        case .modularSmall:
            let template = CLKComplicationTemplateModularSmallRingText()
            template.textProvider = CLKSimpleTextProvider(text: "85%")
            template.fillFraction = 0.85
            template.ringStyle = .closed
            handler(template)

        case .circularSmall:
            let template = CLKComplicationTemplateCircularSmallRingText()
            template.textProvider = CLKSimpleTextProvider(text: "85%")
            template.fillFraction = 0.85
            template.ringStyle = .closed
            handler(template)

        case .utilitarianLarge:
            let template = CLKComplicationTemplateUtilitarianLargeFlat()
            template.textProvider = CLKSimpleTextProvider(text: "📱 iPhone: 85%")
            handler(template)

        case .modularLarge:
            let template = CLKComplicationTemplateModularLargeStandardBody()
            template.headerTextProvider = CLKSimpleTextProvider(text: "📱 iPhone Battery")
            template.body1TextProvider = CLKSimpleTextProvider(text: "85%")
            template.body2TextProvider = CLKSimpleTextProvider(text: "📱iPhone: 85%🔋")
            handler(template)

        default:
            handler(nil)
        }
    }
}
