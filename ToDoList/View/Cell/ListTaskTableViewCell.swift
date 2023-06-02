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
    func pushNoti()
}

class ListTaskTableViewCellViewModel: CellViewModel<TaskModel> {
    
    let rxImageBtn = BehaviorRelay<UIImage?>(value: nil)
    let rxTaskName = BehaviorRelay<String?>(value: "")
    let rxIsTaskDone = BehaviorRelay<Bool>(value: false)
    let rxTimeLabel = BehaviorRelay<String?>(value: nil)
    let rxTime = BehaviorRelay<Date?>(value: nil)
    let rxTimeColor = BehaviorRelay<UIColor?>(value: nil)
    
    private weak var delegate: ListTaskTableViewCellViewModelDelegate?
    
    convenience init(model: TaskModel?, delegate: ListTaskTableViewCellViewModelDelegate?) {
        self.init(model: model)
        self.delegate = delegate
    }
    
    override func react() {
        rxTaskName.accept(model?.title)
        rxTimeLabel.accept(model?.time.dateToString())
        rxTime.accept(model?.time)
        rxTime.map { time -> UIColor? in
            let color: UIColor = (time ?? Date() > Date()) ? .black : .red
            return color
        }.bind(to: rxTimeColor) => disposeBag
        rxIsTaskDone.map { isDone -> UIImage? in
            let imageName: String = isDone ? "circle.inset.filled" : "circle"
            return UIImage(systemName: imageName)
        }.bind(to: rxImageBtn) => disposeBag
        countDownObservable()
    }
    
    func countDownObservable() {
        let countDownPushNoti = Observable<Int>.timer(RxTimeInterval.seconds(getCountDownTimePushNoti()), scheduler: MainScheduler.instance)
        let countDown = Observable<Int>.timer(RxTimeInterval.seconds(getCountDownTime()), scheduler: MainScheduler.instance)
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            countDownPushNoti.subscribe(onNext: { [weak self] _ in
                self?.rxTimeColor.accept(.orange)
                guard let time = self?.getCountDownTimePushNoti() else { return }
                if time >= 0 {
                    self?.delegate?.pushNoti()
                }
            }) => self.disposeBag
            countDown.subscribe(onNext: { [weak self] _ in
                self?.rxTime.accept(Date())
            }) => self.disposeBag
        }
    }
    
    func getCountDownTimePushNoti() -> Int {
        guard let dueTime = Calendar.current.date(byAdding: .minute, value: -30, to: rxTime.value ?? Date()) else {
            return Int()
        }
        return dueTime.dateToInt() - Date().dateToInt()
    }
    
    func getCountDownTime() -> Int {
        return (rxTime.value ?? Date()).dateToInt() - Date().dateToInt()
    }
    
    func tapCheckBtn() {
        self.toggleState()
        self.delegate?.checkTaskDone()
    }
    
    func toggleState() {
        let currentValue = rxIsTaskDone.value
        rxIsTaskDone.accept(!currentValue)
    }
    
    func update(text: String, time: Date) {
        model?.title = text
        model?.time = time
        rxTaskName.accept(text)
        rxTimeLabel.accept(time.dateToString())
        rxTime.accept(time)
        countDownObservable()
    }

}
