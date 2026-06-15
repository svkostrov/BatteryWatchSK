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

    /// Цвет индикатора по уровню заряда.
    /// Примечание: systemRed/systemYellow недоступны в watchOS — используем базовые UIColor.
    private func batteryColor(for level: Float) -> UIColor {
        if level > 0.5 { return .green }
        if level > 0.2 { return UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1.0) }
        return .red
    }

    private func batteryText() -> String {
        guard Model.shared.hasIPhoneData else { return "--" }
        return "\(Int(Model.shared.iPhoneBattery * 100))%"
    }

    private func batteryFill() -> Float {
        guard Model.shared.hasIPhoneData else { return 0.5 }
        return max(0.0, min(1.0, Model.shared.iPhoneBattery))
    }

    // MARK: - Timeline Configuration

    func getSupportedTimeTravelDirections(for complication: CLKComplication,
                                          withHandler handler: @escaping (CLKComplicationTimeTravelDirections) -> Void) {
        handler([])
    }

    func getTimelineStartDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        handler(Calendar.current.startOfDay(for: Date()))
    }

    func getTimelineEndDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        handler(Calendar.current.date(byAdding: .day, value: 9999, to: Calendar.current.startOfDay(for: Date()))!)
    }

    func getPrivacyBehavior(for complication: CLKComplication,
                             withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
        handler(.hideOnLockScreen)
    }

    // MARK: - Timeline Population

    func getCurrentTimelineEntry(for complication: CLKComplication,
                                  withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        handler(makeEntry(for: complication.family, sampleMode: false))
    }

    func getTimelineEntries(for complication: CLKComplication, before date: Date, limit: Int,
                             withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        handler(nil)
    }

    func getTimelineEntries(for complication: CLKComplication, after date: Date, limit: Int,
                             withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        handler(nil)
    }

    // MARK: - Placeholder Templates

    func getLocalizableSampleTemplate(for complication: CLKComplication,
                                       withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
        handler(makeEntry(for: complication.family, sampleMode: true)?.complicationTemplate)
    }

    // MARK: - Template Factory

    /// Единая фабрика шаблонов.
    /// sampleMode=true — показывать 85% в превью настроек циферблата.
    private func makeEntry(for family: CLKComplicationFamily, sampleMode: Bool) -> CLKComplicationTimelineEntry? {
        let text  = sampleMode ? "85%" : batteryText()
        let fill  = sampleMode ? Float(0.85) : batteryFill()
        let color = sampleMode ? UIColor.green : batteryColor(for: Model.shared.iPhoneBattery)

        let template: CLKComplicationTemplate

        switch family {

        case .graphicCircular:
            template = CLKComplicationTemplateGraphicCircularStackText(
                line1TextProvider: CLKSimpleTextProvider(text: "📱"),
                line2TextProvider: CLKSimpleTextProvider(text: text)
            )

        case .graphicBezel:
            let inner = CLKComplicationTemplateGraphicCircularStackText(
                line1TextProvider: CLKSimpleTextProvider(text: "📱"),
                line2TextProvider: CLKSimpleTextProvider(text: text)
            )
            template = CLKComplicationTemplateGraphicBezelCircularText(
                circularTemplate: inner,
                textProvider: CLKSimpleTextProvider(text: "iPhone Battery")
            )

        case .extraLarge:
            let t = CLKComplicationTemplateExtraLargeRingText(
                textProvider: CLKSimpleTextProvider(text: text),
                fillFraction: fill,
                ringStyle: .closed
            )
            t.tintColor = color
            template = t

        case .utilitarianSmall:
            let t = CLKComplicationTemplateUtilitarianSmallRingText(
                textProvider: CLKSimpleTextProvider(text: text),
                fillFraction: fill,
                ringStyle: .closed
            )
            t.tintColor = color
            template = t

        case .modularSmall:
            let t = CLKComplicationTemplateModularSmallRingText(
                textProvider: CLKSimpleTextProvider(text: text),
                fillFraction: fill,
                ringStyle: .closed
            )
            t.tintColor = color
            template = t

        case .circularSmall:
            let t = CLKComplicationTemplateCircularSmallRingText(
                textProvider: CLKSimpleTextProvider(text: text),
                fillFraction: fill,
                ringStyle: .closed
            )
            t.tintColor = color
            template = t

        case .utilitarianLarge:
            template = CLKComplicationTemplateUtilitarianLargeFlat(
                textProvider: CLKSimpleTextProvider(text: "📱 iPhone: \(text)")
            )

        case .modularLarge:
            template = CLKComplicationTemplateModularLargeStandardBody(
                headerTextProvider: CLKSimpleTextProvider(text: "📱 iPhone Battery"),
                body1TextProvider: CLKSimpleTextProvider(text: text),
                body2TextProvider: CLKSimpleTextProvider(
                    text: sampleMode ? "📱iPhone: 85%🔋" : Model.shared.iPhoneBatteryString
                )
            )

        default:
            return nil
        }

        return CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
    }
}
