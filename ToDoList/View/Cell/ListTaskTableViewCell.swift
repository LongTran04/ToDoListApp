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
    @IBOutlet weak var timeLabel: UILabel!
    
    override func bindViewAndViewModel() {
        guard let viewModel = viewModel else { return }
        viewModel.rxTaskName ~> taskNameLabel.rx.text => disposeBag
        viewModel.rxTimeLabel ~> timeLabel.rx.text => disposeBag
        viewModel.rxImageBtn ~> checkBtn.rx.image(for: .normal) => disposeBag
        viewModel.rxTimeColor ~> timeLabel.rx.textColor => disposeBag
        checkBtn.rx.tap.subscribe(onNext: { [weak self] in
            self?.viewModel?.tapCheckBtn()
        }) => disposeBag
    }
}

protocol ListTaskTableViewCellViewModelDelegate: AnyObject {
    func checkTaskDone()
}

class ListTaskTableViewCellViewModel: CellViewModel<TaskModel> {
    
    let rxImageBtn = BehaviorRelay<UIImage?>(value: nil)
    let rxTaskName = BehaviorRelay<String?>(value: nil)
    let rxIsTaskDone = BehaviorRelay<Bool>(value: false)
    let rxTimeLabel = BehaviorRelay<String?>(value: nil)
    let rxTime = BehaviorRelay<Date?>(value: nil)
    let rxTimeColor = BehaviorRelay<UIColor?>(value: nil)
    let rxIsNotiPush = BehaviorRelay<Bool?>(value: nil)
    
    private weak var delegate: ListTaskTableViewCellViewModelDelegate?
    
    convenience init(model: TaskModel?, delegate: ListTaskTableViewCellViewModelDelegate?) {
        self.init(model: model)
        self.delegate = delegate
    }
    
    override func react() {
        rxTaskName.accept(model?.title)
        rxTime.accept(model?.time)
        rxTime.map { $0?.dateToString() }.bind(to: rxTimeLabel) => disposeBag
        rxTime.map { [weak self] time in
            self?.getTimeColor(time: time ?? Date())
        }.bind(to: rxTimeColor) => disposeBag
        rxIsNotiPush.accept(model?.isPushNoti)
        rxIsTaskDone.map { isDone -> UIImage? in
            let imageName: String = isDone ? "circle.inset.filled" : "circle"
            return UIImage(systemName: imageName)
        }.bind(to: rxImageBtn) => disposeBag
    }
    
    func getTimeColor(time: Date) -> UIColor {
        if time > Date() {
            if Calendar.current.date(byAdding: .minute, value: -30, to: time) ?? Date() > Date() {
                return .black
            }
            else {
                return .orange
            }
        }
        else {
            return .red
        }
    }
    
    func tapCheckBtn() {
        self.toggleState()
        self.delegate?.checkTaskDone()
    }
    
    func toggleState() {
        let currentValue = rxIsTaskDone.value
        rxIsTaskDone.accept(!currentValue)
    }
    
    func updateCell(text: String, time: Date) {
        model?.title = text
        model?.time = time
        rxTaskName.accept(text)
        rxTime.accept(time)
    }
    
    func updateTimeColor(_ cellState: CellState) {
        var color = UIColor()
        switch cellState {
        case CellState.normal:
            color = .black
        case CellState.nearTime:
            color = .orange
        default:
            color = .red
        }
        rxTimeColor.accept(color)
    }
    
    func pushNotiDone() {
        model?.isPushNoti = true
        rxIsNotiPush.accept(true)
    }

}
