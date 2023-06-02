//
//  AddAndEditViewController.swift
//  ToDoList
//
//  Created by Long Tran on 29/05/2023.
//

import UIKit
import RxCocoa
import RxSwift

class AddEditListTaskViewController: SFPage<AddEditListTaskViewModel> {

    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var saveBtn: UIButton!
    @IBOutlet weak var cancelBtn: UIButton!
        
    override func bindViewAndViewModel() {
        super.bindViewAndViewModel()
        guard let viewModel = viewModel else { return }
        viewModel.rxTitleLabel <~> titleTextField.rx.text => disposeBag
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

struct AddEditListTaskModel {
    var indexPath: IndexPath
    var title: String
}

protocol AddEditListTaskViewModelDelegate: AnyObject {
    func updateData(atIndex indexPath: IndexPath?, withNewTitle title: String)
}

class AddEditListTaskViewModel: ViewModel<AddEditListTaskModel> {
    let rxResultAction = PublishSubject<Bool>()
    let rxTitleLabel = BehaviorRelay<String?>(value: nil)
    let rxSaveAction = PublishSubject<Void>()
    
    private weak var delegate: AddEditListTaskViewModelDelegate?
    
    convenience init(model: AddEditListTaskModel?, delegate: AddEditListTaskViewModelDelegate?) {
        self.init(model: model)
        self.delegate = delegate
    }
    
    override func react() {
        rxTitleLabel.accept(model?.title)
        rxSaveAction.subscribe(onNext: { [weak self] in
            self?.saveAction()
        }) => disposeBag
    }
    
    func saveAction() {
        let title = rxTitleLabel.value ?? ""
        if !title.isEmpty {
            delegate?.updateData(atIndex: model?.indexPath, withNewTitle: title)
        }
        rxResultAction.onNext(!title.isEmpty)
    }
}

extension UIAlertController {
    func errorAlert() -> UIAlertController {
        let alert = UIAlertController(title: "Invalid Title!", message: "Please enter another title", preferredStyle: .alert)
        let alertAction = UIAlertAction(title: "OK", style: .default)
        alert.addAction(alertAction)
        return alert
    }
}
