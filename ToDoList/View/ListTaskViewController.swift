//
//  ListTaskViewController.swift
//  ToDoList
//
//  Created by Long Tran on 22/05/2023.
//

import UIKit
import RxSwift
import RxCocoa
import Action

class ListTaskViewController: SFListPage<ListTaskViewModel> {
        
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationItem.backBarButtonItem?.isHidden = true
    }
    
    override func initialize() {
        super.initialize()
        tableView.register(UINib(nibName: "ListTaskTableViewCell", bundle: nil), forCellReuseIdentifier: ListTaskTableViewCell.identifier)
        let addBtn = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(tapAddBtn))
        navigationItem.rightBarButtonItem = addBtn
        let backBtn = UIBarButtonItem(title: "Back", image: UIImage(systemName: "chevron.left"), target: self, action: #selector(tapBackBtn))
        navigationItem.leftBarButtonItem = backBtn
    }

    override func cellIdentifier(_ cellViewModel: SFListPage<ListTaskViewModel>.CVM) -> String {
        return ListTaskTableViewCell.identifier
    }
    
    override func bindViewAndViewModel() {
        super.bindViewAndViewModel()
        guard let viewModel = viewModel else { return }
        viewModel.pageTitleSubject ~> rx.title => disposeBag
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let editAction = UITableViewRowAction(style: .normal, title: "Edit", handler: { action, indexPath in
        })
        let deleteAction = UITableViewRowAction(style: .destructive, title: "Delete", handler: { action, indexPath in
            self.viewModel?.delete(at: indexPath)
        })
        return [deleteAction, editAction]
    }
    
    @objc func tapAddBtn() {
        guard let viewModel = viewModel else { return }
        let page = viewModel.getAddVC()
        self.navigationController?.present(page, animated: true)
    }
    
    @objc func tapBackBtn() {
        guard let viewModel = viewModel else { return }
        viewModel.updateListTask()
        self.navigationController?.popViewController(animated: true)
    }
    
}

class ListTaskViewModel: ListViewModel<ListTaskModel, ListTaskTableViewCellViewModel> {
    
    let pageTitleSubject = BehaviorRelay<String?>(value: "")
    let countTask = BehaviorRelay<Int?>(value: 0)
    
    override func react() {
        pageTitleSubject.accept(model?.title)
    }
    
    func getListTaskCell(listTask: [TaskModel]) -> [ListTaskTableViewCellViewModel] {
        var listTaskCell: [ListTaskTableViewCellViewModel] = []
        for item in listTask {
            listTaskCell.append(ListTaskTableViewCellViewModel(model: item))
        }
        return listTaskCell
    }
    
    func add(with taskName: String) {
        let newTask = TaskModel(title: taskName)
        let newListTaskCellViewModel = ListTaskTableViewCellViewModel(model: newTask)
        itemsSource.append(newListTaskCellViewModel)
    }
    
    func delete(at indexPath: IndexPath) {
        itemsSource.remove(at: indexPath)
    }
    
    func updateListTask() {
        countTask.accept(itemsSource.countElements())
    }
    
    func getAddVC() -> UIViewController {
        let page = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "AddListTaskViewController") as! AddViewController
        let viewModel = AddViewModel()
        page.viewModel = viewModel
        page.viewModel?.listTaskNameSubject.subscribe(onNext: { text in
            self.add(with: text)
        }).disposed(by: page.disposeBag ?? DisposeBag())
        return page
    }
    
}
