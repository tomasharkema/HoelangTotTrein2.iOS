//
//  ComplicationController.swift
//  HLTT Extension
//
//  Created by Tomas Harkema on 20-04-16.
//  Copyright © 2016 Tomas Harkema. All rights reserved.
//

import ClockKit
import WatchKit

class ComplicationController: NSObject, CLKComplicationDataSource {

    // MARK: - Timeline Configuration
    
    func getSupportedTimeTravelDirections(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimeTravelDirections) -> Void) {
        handler([])
    }
    
    func getTimelineStartDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        handler(nil)
    }
    
    func getTimelineEndDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        handler(nil)
    }
    
    func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
        handler(.showOnLockScreen)
    }
    
    // MARK: - Timeline Population
    
    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: (@escaping (CLKComplicationTimelineEntry?) -> Void)) {
      guard let myDelegate = WKExtension.shared().delegate as? ExtensionDelegate else {
        return
      }
      myDelegate.requestInitialState { _ in
        handler(self.getTemplateForFamily(complication).map { CLKComplicationTimelineEntry(date: Date(), complicationTemplate: $0) })
      }
    }
    
    func getTimelineEntries(for complication: CLKComplication, before date: Date, limit: Int, withHandler handler: (@escaping ([CLKComplicationTimelineEntry]?) -> Void)) {
        // Call the handler with the timeline entries prior to the given date
        handler(nil)
    }
    
    func getTimelineEntries(for complication: CLKComplication, after date: Date, limit: Int, withHandler handler: (@escaping ([CLKComplicationTimelineEntry]?) -> Void)) {
        // Call the handler with the timeline entries after to the given date
        handler(nil)
    }
    
    // MARK: - Update Scheduling
    
    func getNextRequestedUpdateDate(handler: @escaping (Date?) -> Void) {
        // Call the handler with the date when you would next like to be given the opportunity to update your complication content
        handler(Date(timeIntervalSinceNow: 60))
    }
    
    // MARK: - Placeholder Templates
    
    func getPlaceholderTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
        // This method will be called once per supported complication, and the results will be cached
        handler(getTemplateForFamily(complication))
    }

  fileprivate func getTemplateForFamily(_ complication: CLKComplication) -> CLKComplicationTemplate? {
    
    let delayString: String
    if let delay = App.preferenceStore.persistedAdvices?.first, let delayMessage = delay.vertrekVertraging {
      delayString = delayMessage
    } else {
      delayString = "✅"
    }

    let template: CLKComplicationTemplate?
    switch complication.family {

    case .modularSmall:
      let modularTemplate = CLKComplicationTemplateModularSmallSimpleText()
      modularTemplate.textProvider = CLKSimpleTextProvider(text: delayString)
      template = modularTemplate

    case .circularSmall:

      let modularTemplate = CLKComplicationTemplateCircularSmallSimpleText()
      modularTemplate.textProvider = CLKSimpleTextProvider(text: delayString)
      template = modularTemplate

    case .utilitarianSmall:
      let modularTemplate = CLKComplicationTemplateUtilitarianSmallFlat()
      modularTemplate.textProvider = CLKSimpleTextProvider(text: delayString)
      template = modularTemplate

    case .utilitarianLarge:
      let modularTemplate = CLKComplicationTemplateUtilitarianLargeFlat()
      modularTemplate.textProvider = CLKSimpleTextProvider(text: delayString)
      template = modularTemplate

    default:
      template = nil
    }

    return template
  }
}
