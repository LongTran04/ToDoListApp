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
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func prepareForReuse() {
        checkBtn.setImage(UIImage(systemName: "circle"), for: .normal)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    override func bindViewAndViewModel() {
        guard let viewModel = viewModel else { return }
        viewModel.taskNameSubject ~> taskNameLabel.rx.text => disposeBag
    }
    
    @IBAction func tapCheckBtn(_ sender: Any) {
        guard let viewModel = viewModel else { return }
        viewModel.setIsTaskDone()
        checkBtn.setImage(UIImage(systemName: (viewModel.getImageNameBtn())), for: .normal)
    }
}

class ListTaskTableViewCellViewModel: CellViewModel<TaskModel> {
    
    let taskNameSubject = BehaviorRelay<String?>(value: "")
    var isTaskDone = false
    
    override func react() {
        taskNameSubject.accept(model?.title)
    }
    
    func getImageNameBtn() -> String {
        if isTaskDone {
            return "circle.inset.filled"
        }
        else {
            return "circle"
        }
    }
    
    func setIsTaskDone() {
        if isTaskDone {
            isTaskDone = false
        }
        else {
            isTaskDone = true
        }
    }
}
