//
//  ListTaskTableViewCell.swift
//  ToDoList
//
//  Created by Long Tran on 22/05/2023.
//

import UIKit
import RxSwift
import RxCocoa

class ListTaskTableViewCell: TableCell<ListTaskTableViewCellViewModel> {

    @IBOutlet weak var taskNameLabel: UILabel!
    @IBOutlet weak var checkBtn: UIButton!
    
    override func bindViewAndViewModel() {
        guard let viewModel = viewModel else { return }
        viewModel.taskNameSubject ~> taskNameLabel.rx.text => disposeBag
        viewModel.rxImage.bind(to: checkBtn.rx.image(for: .normal)) => disposeBag
        checkBtn.rx.tap.subscribe(onNext: { [weak self] in
            self?.viewModel?.toggleState()
        }) => disposeBag
    }
}

class ListTaskTableViewCellViewModel: CellViewModel<TaskModel> {
    
    let rxImage = BehaviorRelay<UIImage?>(value: nil)
    let taskNameSubject = BehaviorRelay<String?>(value: "")
    let rxIsTaskDone = BehaviorRelay<Bool>(value: false)
    
    override func react() {
        taskNameSubject.accept(model?.title)
        rxIsTaskDone.map { isDone -> UIImage? in
            let imageName: String = isDone ? "circle.inset.filled" : "circle"
            return UIImage(systemName: imageName)
        }.bind(to: rxImage) => disposeBag
    }
    
    func toggleState() {
        let currentValue = rxIsTaskDone.value
        rxIsTaskDone.accept(!currentValue)
    }
}
