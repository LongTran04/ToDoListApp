//
//  AddListTaskViewController.swift
//  ToDoList
//
//  Created by Long Tran on 23/05/2023.
//

import UIKit
import RxCocoa
import RxSwift

class AddViewController: SFPage<AddViewModel> {

    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var addBtn: UIButton!
    @IBOutlet weak var cancelBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let viewModel = viewModel else { return }
        titleTextField.rx.text.bind(to: viewModel.titleLabelSubject) => disposeBag
        addBtn.rx.tap.subscribe(onNext: {
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
//        titleTextField.rx.text.bind(to: viewModel.titleLabelSubject) => disposeBag
//        addBtn.rx.tap.subscribe(onNext: {
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
//    }
    
    private func showErrorAlert() {
        let alert = UIAlertController(title: "Invalid Title!", message: "Please enter another title", preferredStyle: .alert)
        let alertAction = UIAlertAction(title: "OK", style: .default)
        alert.addAction(alertAction)
        self.present(alert, animated: true)
    }
    

}

class AddViewModel: ViewModel<SFModel> {
    let addSubject = PublishSubject<String>()
    let resultActionSubject = PublishSubject<Bool>()
    let titleLabelSubject = BehaviorRelay<String?>(value: nil)
    
    func tapAddBtn() {
        let title = titleLabelSubject.value ?? ""
        let isTitleEmpty = title.isEmpty
        if isTitleEmpty == false {
            addSubject.onNext(title)
        }
        resultActionSubject.onNext(!isTitleEmpty)
    }
}
