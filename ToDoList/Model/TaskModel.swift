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
    
    convenience init(title: String) {
        self.init(JSON: ["title" : title])!
    }
    
    override func mapping(map: Map) {
        title <- map["title"]
    }
}
