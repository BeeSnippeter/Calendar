
/**
 * Copyright (c) 2016 BeeSnippeter
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

/**
 *  Abstract:
 *  Just for test.
 */

import UIKit
import EventKit

class ViewController: UIViewController {
  
  let CALENDAR_NAME = "CALENDAR_MANAGE"
  
  var startDate: Date {
    get {
      var dateComponents = DateComponents()
      dateComponents.year = -1;
      let today = Date()
      let calendar = NSCalendar.current
      guard let oneYearAgo = calendar.date(byAdding: dateComponents, to: today) else {return Date()}
      return oneYearAgo
    }
  }
  var endDate: Date {
    get {
      var dateComponents = DateComponents()
      dateComponents.year = 1;
      let today = Date()
      let calendar = NSCalendar.current
      guard let oneYearFromNow = calendar.date(byAdding: dateComponents, to: today) else {return Date()}
      return oneYearFromNow
    }
  }

    override func viewDidLoad() {
      super.viewDidLoad()
//      CalendarManager.getAllEvents(startDate, endDate, completionHandle:{
//        (events, success, Error) in
//        print("events: \(events)")
//      })
      
//      CalendarManager.createCalendarBy(CALENDAR_NAME, completionHandle: {
//        (success, error) in
//        if success {
//          print("Save Success")
//        } else {
//          print("Save Error: \(error)")
//        }
//      })
      
      
      /*
      let event = EKEvent(eventStore: CalendarManager.eventStore)
      event.title = "From hongthai.ng with love"
      
      let startDate = Date()
      let endDate = startDate.addingTimeInterval(2 * 60 * 60)
      
      event.startDate = startDate
      event.endDate = endDate
      
      let alarm = EKAlarm(relativeOffset: -1 * 60 * 60) //1 hour
      event.alarms = [alarm]
      
      
      CalendarManager.createEventForCalendar(CALENDAR_NAME, event: event, completionHandle: {
        (success, error) in
        if success {
          self.printListEvents()
        } else {
          print("Add event error: \(error)")
        }
        
      })
      
      */
      self.printListEvents()
      
      CalendarManager.getEventsFromCalendar(CALENDAR_NAME, fromDate: startDate, toDate: endDate, completionHandle: {
        (events, success, error) in
        CalendarManager.deleteEvent((events?[0].eventIdentifier)!, completeHandle: { (success, error) in
          if success {
            print("Delete success")
          } else {
            print("Delete error: \(error)")
          }
        })
      })
      
      
      
      
      
      
    }
  
  func printListEvents() {
    CalendarManager.getEventsFromCalendar(CALENDAR_NAME, fromDate: startDate, toDate: endDate, completionHandle: {
      (events, success, error) in
      print("Events: \(events)")
    })
  }


}

