//
//  TaskModel.swift
//  ToDoList
//
//  Created by Long Tran on 22/05/2023.
//

import Foundation
import ObjectMapper

class TaskModel: SFModel {
    var title: String = ""
    var time: Date = Date()
    
    convenience init(title: String, time: Date) {
        self.init(JSON: ["title" : title, "time" : time])!
    }
    
    override func mapping(map: Map) {
        title <- map["title"]
        time <- map["time"]
    }
}
