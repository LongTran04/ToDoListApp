//
//  ListTaskModel.swift
//  ToDoList
//
//  Created by Long Tran on 22/05/2023.
//

import Foundation
import ObjectMapper

class ListTaskModel: SFModel {
    var title: String = ""
    var listTask: [TaskModel] = []
    
    convenience init(title: String) {
        self.init(JSON: ["title" : title])!
    }
    
    override func mapping(map: Map) {
        title <- map["title"]
    }
}
