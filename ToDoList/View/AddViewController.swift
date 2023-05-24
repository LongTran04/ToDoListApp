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
        
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func tapAddBtn(_ sender: Any) {
        let title: String = titleTextField.text ?? ""
        if title.isEmpty {
            let alert = UIAlertController(title: "Invalid Title!", message: "Please enter another title", preferredStyle: .alert)
            let alertAction = UIAlertAction(title: "OK", style: .default)
            alert.addAction(alertAction)
            self.present(alert, animated: true)
        }
        else {
            self.viewModel?.tapAddBtn(text: title)
            self.dismiss(animated: true)
        }
    }

    @IBAction func tapCancelBtn(_ sender: Any) {
        self.dismiss(animated: true)
    }
}

class AddViewModel: ViewModel<SFModel> {
    let listTaskNameSubject = PublishSubject<String>()
    
    func tapAddBtn(text: String) {
        listTaskNameSubject.onNext(text)
    }
}
