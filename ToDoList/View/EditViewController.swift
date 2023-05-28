//
//  EditViewController.swift
//  ToDoList
//
//  Created by Long Tran on 25/05/2023.
//

import UIKit
import RxCocoa
import RxSwift

class EditViewController: SFPage<EditViewModel> {

    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var saveBtn: UIButton!
    @IBOutlet weak var cancelBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let viewModel = viewModel else { return }
        viewModel.titleLabelSubject <~> titleTextField.rx.text => disposeBag
        saveBtn.rx.tap.subscribe(onNext: {
            viewModel.tapAddBtn()
        }) => disposeBag
        cancelBtn.rx.tap.subscribe(onNext: {
            self.dismiss(animated: true)
        }) => disposeBag
        viewModel.resultActionSubject.subscribe(onNext: { [weak self] addStatus in
            if addStatus {
                self?.dismiss(animated: true)
            } else {
                self?.showErrorAlert()
            }
        }) => disposeBag
    }
    
//    override func bindViewAndViewModel() {
//        super.bindViewAndViewModel()
//        guard let viewModel = viewModel else { return }
//        viewModel.titleLabelSubject <~> titleTextField.rx.text => disposeBag
//        saveBtn.rx.tap.subscribe(onNext: {
//            viewModel.tapAddBtn()
//        }) => disposeBag
//        cancelBtn.rx.tap.subscribe(onNext: {
//            self.dismiss(animated: true)
//        }) => disposeBag
//        viewModel.resultActionSubject.subscribe(onNext: { [weak self] addStatus in
//            if addStatus {
//                self?.dismiss(animated: true)
//            } else {
//                self?.showErrorAlert()
//            }
//        }) => disposeBag
//
//    }
    
    private func showErrorAlert() {
        let alert = UIAlertController(title: "Invalid Title!", message: "Please enter another title", preferredStyle: .alert)
        let alertAction = UIAlertAction(title: "OK", style: .default)
        alert.addAction(alertAction)
        self.present(alert, animated: true)
    }

}

class EditViewModel: ViewModel<SFModel> {
    let editSubject = PublishSubject<String>()
    let resultActionSubject = PublishSubject<Bool>()
    let titleLabelSubject = BehaviorRelay<String?>(value: nil)
    
    func tapAddBtn() {
        let title = titleLabelSubject.value ?? ""
        let isTitleEmpty = title.isEmpty
        if isTitleEmpty == false {
            editSubject.onNext(title)
        }
        resultActionSubject.onNext(!isTitleEmpty)
    }
    
}
