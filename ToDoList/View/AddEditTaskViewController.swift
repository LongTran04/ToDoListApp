//
//  AddEditTaskViewController.swift
//  ToDoList
//
//  Created by Long Tran on 31/05/2023.
//

import UIKit
import RxCocoa
import RxSwift

class AddEditTaskViewController: SFPage<AddEditTaskViewModel> {

    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var timeTextField: UITextField!
    @IBOutlet weak var saveBtn: UIButton!
    @IBOutlet weak var cancelBtn: UIButton!
    let datePicker = UIDatePicker()
    
    override func initialize() {
        super.initialize()
        datePicker.datePickerMode = .time
        datePicker.frame.size = CGSize(width: 0, height: 300)
        datePicker.preferredDatePickerStyle = .wheels
        timeTextField.inputView = datePicker
    }
    
    override func bindViewAndViewModel() {
        super.bindViewAndViewModel()
        guard let viewModel = viewModel else { return }
        viewModel.rxTitleLabel <~> titleTextField.rx.text => disposeBag
        viewModel.rxTimeLabel <~> timeTextField.rx.text => disposeBag
        datePicker.rx.date <~> viewModel.rxTime => disposeBag
        saveBtn.rx.tap.subscribe(onNext: { [weak self] in
            self?.viewModel?.rxSaveAction.onNext(())
        }) => disposeBag
        cancelBtn.rx.tap.subscribe(onNext: { [weak self] in
            self?.dismiss(animated: true)
        }) => disposeBag
        viewModel.rxResultAction.subscribe(onNext: { [weak self] addStatus in
            if addStatus {
                self?.dismiss(animated: true)
            } else {
                self?.present(UIAlertController().errorAlert(), animated: true)
            }
        }) => disposeBag
    }
    
}

struct AddEditTaskModel {
    var indexPath: IndexPath
    var title: String
    var time: Date
}

protocol AddEditTaskViewModelDelegate: AnyObject {
    func updateData(atIndex indexPath: IndexPath?, withNewTitle title: String, withNewTime time: Date)
}

class AddEditTaskViewModel: ViewModel<AddEditTaskModel> {
    let rxSaveAction = PublishSubject<Void>()
    let rxResultAction = PublishSubject<Bool>()
    let rxTitleLabel = BehaviorRelay<String?>(value: nil)
    let rxTimeLabel = BehaviorRelay<String?>(value: nil)
    let rxTime = BehaviorRelay<Date>(value: Date())
    
    private weak var delegate: AddEditTaskViewModelDelegate?
    
    convenience init(model: AddEditTaskModel?, delegate: AddEditTaskViewModelDelegate?) {
        self.init(model: model)
        self.delegate = delegate
    }
    
    override func react() {
        rxTitleLabel.accept(model?.title)
        rxTime.accept(model?.time ?? Date())
        rxTime.map { $0.dateToString() }.bind(to: rxTimeLabel) => disposeBag
        rxSaveAction.subscribe(onNext: { [weak self] in
            self?.saveAction()
        }) => disposeBag
    }

    func saveAction() {
        let title = rxTitleLabel.value ?? ""
        let time = rxTime.value
        if !title.isEmpty {
            delegate?.updateData(atIndex: model?.indexPath, withNewTitle: title, withNewTime: time)
        }
        rxResultAction.onNext(!title.isEmpty)
    }
}

extension Date {
    func dateToString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: self)
    }
    
    func dateToInt() -> Int {
        let timeInterval = self.timeIntervalSince1970
        return Int(timeInterval)
    }
}
