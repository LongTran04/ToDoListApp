//
//  AddAndEditViewController.swift
//  ToDoList
//
//  Created by Long Tran on 29/05/2023.
//

import UIKit
import RxCocoa
import RxSwift

class AddAndEditViewController: SFPage<AddAndEditViewModel> {

    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var saveBtn: UIButton!
    @IBOutlet weak var cancelBtn: UIButton!
        
    override func bindViewAndViewModel() {
        super.bindViewAndViewModel()
        guard let viewModel = viewModel else { return }
        viewModel.titleLabelSubject <~> titleTextField.rx.text => disposeBag
        saveBtn.rx.tap.subscribe(onNext: { [weak self] in
            self?.viewModel?.tapSaveBtn()
        }) => disposeBag
        cancelBtn.rx.tap.subscribe(onNext: { [weak self] in
            self?.dismiss(animated: true)
        }) => disposeBag
        viewModel.resultActionSubject.subscribe(onNext: { [weak self] addStatus in
            if addStatus {
                self?.dismiss(animated: true)
            } else {
                self?.showErrorAlert()
            }
        }) => disposeBag
    }
    
    private func showErrorAlert() {
        let alert = UIAlertController(title: "Invalid Title!", message: "Please enter another title", preferredStyle: .alert)
        let alertAction = UIAlertAction(title: "OK", style: .default)
        alert.addAction(alertAction)
        self.present(alert, animated: true)
    }

}

struct AddEditModel {
    var indexPath: IndexPath
    var title: String
}

protocol AddAndEditViewModelDelegate: AnyObject {
    func updateData(atIndex indexPath: IndexPath?, withNewTitle title: String)
}

class AddAndEditViewModel: ViewModel<AddEditModel> {
    let saveSubject = PublishSubject<String>()
    let resultActionSubject = PublishSubject<Bool>()
    let titleLabelSubject = BehaviorRelay<String?>(value: nil)
    
    private weak var delegate: AddAndEditViewModelDelegate?
    
    convenience init(model: AddEditModel?, delegate: AddAndEditViewModelDelegate?) {
        self.init(model: model)
        self.delegate = delegate
    }
    
    override func react() {
        titleLabelSubject.accept(model?.title)
        saveSubject.subscribe(onNext: { [weak self] text in
            self?.delegate?.updateData(atIndex: self?.model?.indexPath, withNewTitle: text)
        }) => disposeBag
    }
    
    func tapSaveBtn() {
        let title = titleLabelSubject.value ?? ""
        let isTitleEmpty = title.isEmpty
        if isTitleEmpty == false {
            saveSubject.onNext(title)
        }
        resultActionSubject.onNext(!isTitleEmpty)
    }
}
