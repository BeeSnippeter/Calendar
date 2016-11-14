
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
 *  The CalendarManager class provides some methods for accessing and manipulating calendar events
 */

import UIKit
import EventKit


typealias Completion = (_ success: Bool, _ error: Error?) -> Void
typealias GetCalendarsCompleteHandle = (_ calendars: [EKCalendar]?, _ success: Bool,_ error: Error?) -> Void
typealias GetCalendarCompleteHandle = (_ calendar: EKCalendar?, _ success: Bool,_ error: Error?) -> Void
typealias GetEventsCompleteHandle = (_ events: [EKEvent]?, _ success: Bool, _ error: Error?) -> Void

/**
 *  Classification error type
 */
enum CalendarManagerError: Error {
  case accessDenied
  case cannotSaveNewCalendar
  case calendarExisted
  case calendarNotFound
  case cannotSaveNewEvent
  
  case eventNotFound
  case cannotEditEvent
}

class CalendarManager {
  
  
  static var eventStore = EKEventStore()
  
  /*
   * @name: checkCalendarAuthorization:completeHandle
   * @desc: This function check authorization's status
   * @author: Hong Thai, Ngo
   * @params: completeHandle: Will be called and return status/error...
   * @return: nil
   */
  private static func checkCalendarAuthorization (completeHandle:@escaping Completion) {
    let status = EKEventStore.authorizationStatus(for: .event)
    switch status {
    case .notDetermined:
      requestAccessToCalendar(completeHandel: { (success, error) in
        completeHandle(success, error)
      })
      break
    case .authorized:
      completeHandle(true, nil)             //completion(success, error?)
      break
    case .restricted, .denied:
      completeHandle(false, CalendarManagerError.accessDenied)
      
      break
    }
  }
  
  
  /*
   * @name: requestAccessToCalendar: completeHandle
   * @desc: This function request user allow this app access to Calendar
   * @author: Hong Thai, Ngo
   * @params: completionHandle: will be called and return the status
   * @return: nil
   */
  private static func requestAccessToCalendar(completeHandel:@escaping Completion) {
    eventStore.requestAccess(to: .event, completion: {
      (accessGranted: Bool, error: Error?) in
      completeHandel(accessGranted, error)
    })
    
  }
  
  
  // MARK: - Calendar's region
  
  /*
   * @name: getAllCalendar:completionHandle
   * @desc: This function gets all calendar from device
   * @author: HongThai, Ngo
   * @params: competionHandle: will be called when this task finsish and return all calendars on device
   * @return: nil
   */
  private static func getAllCalendar (completionHandle:@escaping GetCalendarsCompleteHandle) {
    checkCalendarAuthorization { (success, error) in
      DispatchQueue.main.async(execute: {
        let calendars = self.eventStore.calendars(for: .event)
        completionHandle(calendars, success, error)
      })
    }
  }
  
  /*
   * @name: getCalendarBy: name, completionHandle
   * @desc: This function gets specific calendar by name
   * @author: HongThai, Ngo
   * @params: - name: name of calendar
              - completionHandle: will be called when this task finish and return calendar if it exist
   * @return: nil
   */
  static func getCalendarBy(_ name: String, completionHandle: @escaping GetCalendarCompleteHandle) {
    getAllCalendar { (calendars, success, error) in
      guard let cals = calendars else {
        completionHandle(nil, success, error)
        return
      }
      for cal in cals {
        if cal.title == name {
          completionHandle(cal, success, error)
          return
        }
      }
      completionHandle(nil, success, error)
    }
  }
  
  /*
   * @name: createCalendarBy: name, completionHandle
   * @desc: This function creates a new calendar
   * @author: Hong Thai, Ngo
   * @params: - name: name of new calendar
              - completionHandle: will be called when finish this task and return status of this task
   * @return: nil
   */
  static func createCalendarBy(_ name: String, completionHandle: @escaping Completion) {
    getCalendarBy(name, completionHandle: {
      (calendar, success, error) in
      if success {
        if calendar != nil {
          completionHandle(false, CalendarManagerError.calendarExisted)
        } else {
          let newCalendar = EKCalendar(for: .event, eventStore: self.eventStore)
          newCalendar.title = name
          let sourceInEventStore = self.eventStore.sources
          newCalendar.source = sourceInEventStore.filter({ (source) -> Bool in
            source.sourceType.rawValue == EKSourceType.local.rawValue
          }).first!
          do {
            try self.eventStore.saveCalendar(newCalendar, commit: true)
            completionHandle(true, nil)
          } catch  {
            completionHandle(false, CalendarManagerError.cannotSaveNewCalendar)
          }
        }
      } else {
        completionHandle(false, error)
      }
    })
  }
  
  //End Calendar's region
  
  
  // MARK: - Events's region
  static func getAllEvents (_ fromDate: Date, _ toDate : Date, completionHandle: @escaping GetEventsCompleteHandle) {
    getAllCalendar { (calendars, success, error) in
      if success {
        DispatchQueue.main.async(execute: { 
          let predicate = self.eventStore.predicateForEvents(withStart: fromDate, end: toDate, calendars: calendars)
          completionHandle(self.eventStore.events(matching: predicate), success, error)
        })
      } else {
        completionHandle(nil, false, error)
        
      }
    }
  }
  static func getEventsFromCalendar (_ calendarName: String, fromDate: Date, toDate: Date, completionHandle: @escaping GetEventsCompleteHandle) {
    getCalendarBy(calendarName, completionHandle: {calendar, success, error  in
      if error != nil {
        completionHandle(nil, false, error)
      } else {
        guard let cal = calendar else {
          completionHandle(nil, false, CalendarManagerError.calendarNotFound)
          return
        }
        DispatchQueue.main.async(execute: {
          let predicate = self.eventStore.predicateForEvents(withStart: fromDate, end: toDate, calendars: [cal])
          completionHandle(self.eventStore.events(matching: predicate), success, error)
        })
      }
    })
  }
  
  static func createEventForCalendar (_ calendarName:String, event: EKEvent, completionHandle:@escaping Completion) {
    getCalendarBy(calendarName, completionHandle: {calendar, success, error  in
      if error != nil {
        completionHandle(false, error)
      } else {
        guard let cal = calendar else {
          completionHandle(false, CalendarManagerError.calendarNotFound)
          return
        }
        
        event.calendar = cal
        do {
          try self.eventStore.save(event, span: EKSpan.thisEvent)
          completionHandle(true, nil)
        } catch {
          completionHandle(false, error)
        }
      }
    })
  }
  
  static func deleteEvent (_ identifier: String, completeHandle: Completion) {
    guard let eventToRemove = self.eventStore.event(withIdentifier: identifier) else {
      completeHandle(false, CalendarManagerError.eventNotFound)
      return
    }
    do {
      try self.eventStore.remove(eventToRemove, span: EKSpan.thisEvent)
      completeHandle(true, nil)
    } catch {
       completeHandle(false, error)
    }
  }
  
  static func editEvent (_ identifier: String, newEvent: EKEvent, completeHandle: Completion) {
    guard let eventToEdit = self.eventStore.event(withIdentifier: identifier) else {
      completeHandle(false, CalendarManagerError.eventNotFound)
      return
    }
    do {
      eventToEdit.title = newEvent.title
      eventToEdit.startDate = newEvent.startDate
      eventToEdit.endDate = newEvent.endDate
      eventToEdit.notes = newEvent.notes
      eventToEdit.alarms = newEvent.alarms
      try self.eventStore.save(eventToEdit, span: EKSpan.thisEvent)
      completeHandle(true, nil)
    } catch {
      completeHandle(false, CalendarManagerError.cannotEditEvent)
    }
  }
  
  //End Events's region
  
  //TODO: - Reminder's region
  
  
}













