//
//  ComplicationController.swift
//  HLTT Extension
//
//  Created by Tomas Harkema on 20-04-16.
//  Copyright © 2016 Tomas Harkema. All rights reserved.
//

import ClockKit

class ComplicationController: NSObject, CLKComplicationDataSource {
    
    // MARK: - Timeline Configuration
    
    func getSupportedTimeTravelDirectionsForComplication(complication: CLKComplication, withHandler handler: (CLKComplicationTimeTravelDirections) -> Void) {
        handler([])
    }
    
    func getTimelineStartDateForComplication(complication: CLKComplication, withHandler handler: (NSDate?) -> Void) {
        handler(nil)
    }
    
    func getTimelineEndDateForComplication(complication: CLKComplication, withHandler handler: (NSDate?) -> Void) {
        handler(nil)
    }
    
    func getPrivacyBehaviorForComplication(complication: CLKComplication, withHandler handler: (CLKComplicationPrivacyBehavior) -> Void) {
        handler(.ShowOnLockScreen)
    }
    
    // MARK: - Timeline Population
    
    func getCurrentTimelineEntryForComplication(complication: CLKComplication, withHandler handler: ((CLKComplicationTimelineEntry?) -> Void)) {

      handler(getTemplateForFamily(complication).map { CLKComplicationTimelineEntry(date: NSDate(), complicationTemplate: $0) })
    }
    
    func getTimelineEntriesForComplication(complication: CLKComplication, beforeDate date: NSDate, limit: Int, withHandler handler: (([CLKComplicationTimelineEntry]?) -> Void)) {
        // Call the handler with the timeline entries prior to the given date
        handler(nil)
    }
    
    func getTimelineEntriesForComplication(complication: CLKComplication, afterDate date: NSDate, limit: Int, withHandler handler: (([CLKComplicationTimelineEntry]?) -> Void)) {
        // Call the handler with the timeline entries after to the given date
        handler(nil)
    }
    
    // MARK: - Update Scheduling
    
    func getNextRequestedUpdateDateWithHandler(handler: (NSDate?) -> Void) {
        // Call the handler with the date when you would next like to be given the opportunity to update your complication content
        handler(NSDate(timeIntervalSinceNow: 60))
    }
    
    // MARK: - Placeholder Templates
    
    func getPlaceholderTemplateForComplication(complication: CLKComplication, withHandler handler: (CLKComplicationTemplate?) -> Void) {
        // This method will be called once per supported complication, and the results will be cached
      handler(getTemplateForFamily(complication))
    }

  private func getTemplateForFamily(complication: CLKComplication) -> CLKComplicationTemplate? {
    let template: CLKComplicationTemplate?
    switch complication.family {

    case .ModularSmall:
      let modularTemplate = CLKComplicationTemplateModularSmallSimpleText()
      modularTemplate.textProvider = CLKSimpleTextProvider(text: "+3 min")
      template = modularTemplate

    case .CircularSmall:

      let modularTemplate = CLKComplicationTemplateCircularSmallSimpleText()
      modularTemplate.textProvider = CLKSimpleTextProvider(text: "+3 min")
//      modularTemplate.fillFraction = 0.7
//      modularTemplate.ringStyle = CLKComplicationRingStyle.Closed
      template = modularTemplate

    case .UtilitarianSmall:
      let modularTemplate = CLKComplicationTemplateUtilitarianSmallFlat()
      modularTemplate.textProvider = CLKSimpleTextProvider(text: "+3 min")
//      modularTemplate.fillFraction = 0.7
//      modularTemplate.ringStyle = CLKComplicationRingStyle.Closed
      template = modularTemplate

    default:
      template = nil
    }

    return template
  }
}
