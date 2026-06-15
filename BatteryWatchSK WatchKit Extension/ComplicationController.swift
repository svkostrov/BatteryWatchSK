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

    private func batteryText() -> String {
        guard Model.shared.hasIPhoneData else { return "--" }
        return "\(Int(Model.shared.iPhoneBattery * 100))%"
    }

    private func batteryFill() -> Float {
        guard Model.shared.hasIPhoneData else { return 0.0 }
        return max(0.0, min(1.0, Model.shared.iPhoneBattery))
    }

    /// Цветная шкала заряда — красный < 20%, жёлтый 20–50%, зелёный > 50%.
    /// Используем базовые UIColor (systemRed/systemYellow недоступны в watchOS).
    private func makeGaugeProvider(fill: Float) -> CLKSimpleGaugeProvider {
        return CLKSimpleGaugeProvider(
            style: .fill,
            gaugeColors: [
                .red,
                UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1.0),  // yellow
                .green
            ],
            gaugeColorLocations: [0.0, 0.2, 0.5] as [NSNumber],
            fillFraction: fill
        )
    }

    // MARK: - Complication Descriptors (watchOS 7+ replacement for CLKComplicationSupportedFamilies plist key)

    func getComplicationDescriptors(handler: @escaping ([CLKComplicationDescriptor]) -> Void) {
        let supported: [CLKComplicationFamily] = [
            .graphicCorner, .graphicCircular, .graphicBezel, .graphicRectangular,
            .extraLarge, .modularLarge, .modularSmall,
            .utilitarianLarge, .utilitarianSmall, .circularSmall
        ]
        handler([
            CLKComplicationDescriptor(
                identifier: "BatteryWatchSK_iPhoneBattery",
                displayName: "iPhone Battery",
                supportedFamilies: supported
            )
        ])
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

    /// sampleMode=true — показывать 85% в превью настроек циферблата.
    private func makeEntry(for family: CLKComplicationFamily, sampleMode: Bool) -> CLKComplicationTimelineEntry? {
        let text = sampleMode ? "85%" : batteryText()
        let fill = sampleMode ? Float(0.85) : batteryFill()
        // Короткий вариант без % — для узких слотов (кольцо уже показывает уровень визуально)
        let shortText = sampleMode ? "85" : (Model.shared.hasIPhoneData ? "\(Int(Model.shared.iPhoneBattery * 100))" : "--")

        let template: CLKComplicationTemplate

        switch family {

        // ─────────────────────────────────────────────────────────────────
        // Graphic families (watchOS 6+) — лучшее визуальное представление
        // ─────────────────────────────────────────────────────────────────

        case .graphicCircular:
            // Число в центре + "%" внизу (без emoji — они плохо рендерятся в маленьких слотах).
            template = CLKComplicationTemplateGraphicCircularOpenGaugeSimpleText(
                gaugeProvider: makeGaugeProvider(fill: fill),
                bottomTextProvider: CLKSimpleTextProvider(text: "%"),
                centerTextProvider: CLKSimpleTextProvider(text: shortText)
            )

        case .graphicCorner:
            // Угловые слоты на Wayfinder/Ultra — без emoji, только данные.
            template = CLKComplicationTemplateGraphicCornerGaugeText(
                gaugeProvider: makeGaugeProvider(fill: fill),
                outerTextProvider: CLKSimpleTextProvider(text: text)
            )

        case .graphicBezel:
            let inner = CLKComplicationTemplateGraphicCircularOpenGaugeSimpleText(
                gaugeProvider: makeGaugeProvider(fill: fill),
                bottomTextProvider: CLKSimpleTextProvider(text: "%"),
                centerTextProvider: CLKSimpleTextProvider(text: shortText)
            )
            template = CLKComplicationTemplateGraphicBezelCircularText(
                circularTemplate: inner,
                textProvider: CLKSimpleTextProvider(text: "iPhone Battery")
            )

        case .graphicRectangular:
            template = CLKComplicationTemplateGraphicRectangularStandardBody(
                headerTextProvider: CLKSimpleTextProvider(text: "📱 iPhone Battery"),
                body1TextProvider: CLKSimpleTextProvider(text: text),
                body2TextProvider: CLKSimpleTextProvider(text: "")
            )

        // ─────────────────────────────────────────────────────────────────
        // Classic families
        // ─────────────────────────────────────────────────────────────────

        case .extraLarge:
            let t = CLKComplicationTemplateExtraLargeRingText(
                textProvider: CLKSimpleTextProvider(text: text),
                fillFraction: fill,
                ringStyle: .closed
            )
            t.tintColor = fill > 0.5 ? .green : fill > 0.2 ? UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1.0) : .red
            template = t

        case .utilitarianSmall:
            let t = CLKComplicationTemplateUtilitarianSmallRingText(
                textProvider: CLKSimpleTextProvider(text: text),
                fillFraction: fill,
                ringStyle: .closed
            )
            t.tintColor = fill > 0.5 ? .green : fill > 0.2 ? UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1.0) : .red
            template = t

        case .utilitarianLarge:
            template = CLKComplicationTemplateUtilitarianLargeFlat(
                textProvider: CLKSimpleTextProvider(text: "📱 iPhone: \(text)")
            )

        case .modularSmall:
            let t = CLKComplicationTemplateModularSmallRingText(
                textProvider: CLKSimpleTextProvider(text: text),
                fillFraction: fill,
                ringStyle: .closed
            )
            t.tintColor = fill > 0.5 ? .green : fill > 0.2 ? UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1.0) : .red
            template = t

        case .modularLarge:
            template = CLKComplicationTemplateModularLargeStandardBody(
                headerTextProvider: CLKSimpleTextProvider(text: "📱 iPhone Battery"),
                body1TextProvider: CLKSimpleTextProvider(text: text),
                body2TextProvider: CLKSimpleTextProvider(text: "")
            )

        case .circularSmall:
            let t = CLKComplicationTemplateCircularSmallRingText(
                textProvider: CLKSimpleTextProvider(text: text),
                fillFraction: fill,
                ringStyle: .closed
            )
            t.tintColor = fill > 0.5 ? .green : fill > 0.2 ? UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1.0) : .red
            template = t

        default:
            return nil
        }

        return CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
    }
}
