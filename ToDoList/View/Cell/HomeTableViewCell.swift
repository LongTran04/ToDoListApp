//
//  HomeTableViewCell.swift
//  ToDoList
//
//  Created by Long Tran on 22/05/2023.
//

import UIKit
import RxCocoa
import RxSwift

class HomeTableViewCell: TableCell<HomeTableViewCellViewModel> {

    @IBOutlet weak var titleListTaskLabel: UILabel!
    @IBOutlet weak var countTaskLabel: UILabel!
    
    override func bindViewAndViewModel() {
        guard let viewModel = viewModel else { return }
        viewModel.titleSubject ~> titleListTaskLabel.rx.text => disposeBag
        viewModel.countTaskSubject ~> countTaskLabel.rx.text => disposeBag
    }
    
}

class HomeTableViewCellViewModel: CellViewModel<ListTaskModel> {
    
    let titleSubject = BehaviorRelay<String?>(value: "")
    let countTaskSubject = BehaviorRelay<String?>(value: "")
    
    override func react() {
        titleSubject.accept(model?.title)
        countTaskSubject.accept(model?.listTask.count.description)
    }
    
    func updateCountTask(with model: ListTaskModel) {
        self.model?.listTask = model.listTask
        countTaskSubject.accept(model.listTask.count.description)
    }
    
    func updateTitle(text: String) {
        model?.title = text
        titleSubject.accept(text)
    }
}
