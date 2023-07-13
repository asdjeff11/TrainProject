//
//  RestfulQueue.swift
//  MyTestingProject
//
//  Created by 楊宜濱 on 2022/9/2.
//

import Foundation

class TaskQueue {
    var list:[IndexPath:URLSessionTask] = [:]
    let thread = DispatchQueue(label: "checker",attributes: .concurrent )
    let semaphore = DispatchSemaphore(value: 1)
    
    func addTask(indexPath:IndexPath, task:URLSessionTask) {
        semaphore.wait()
        defer {
            semaphore.signal()
        }
        
        thread.async {
            if ( self.list[indexPath] != nil ) { return }
            self.list[indexPath] = task
            task.resume()
        }
    }
    
    func removeTask(indexPath:IndexPath) {
        semaphore.wait()
        defer {
            semaphore.signal()
        }
        
        thread.async {
            self.list.removeValue(forKey: indexPath)
        }
    }
    
    func removeAllTask() {
        semaphore.wait()
        defer {
            semaphore.signal()
        }
        thread.async {
            for (_,myTask) in self.list {
                myTask.cancel()
            }
            self.list.removeAll()
        }
    }
    
    func checkIsEmpty()->Bool {
        semaphore.wait()
        defer {
            semaphore.signal()
        }
        return ( self.list.isEmpty)
    }
    
}
