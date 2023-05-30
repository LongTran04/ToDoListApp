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
        
    let addBtn = UIBarButtonItem(barButtonSystemItem: .add, target: nil, action: nil)
    let backBtn = UIBarButtonItem(title: "Back", image: UIImage(systemName: "chevron.left"), target: nil, action: nil)
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationItem.backBarButtonItem?.isHidden = true
    }
    
    override func initialize() {
        super.initialize()
        tableView.register(UINib(nibName: "ListTaskTableViewCell", bundle: nil), forCellReuseIdentifier: ListTaskTableViewCell.identifier)
        navigationItem.rightBarButtonItem = addBtn
        navigationItem.leftBarButtonItem = backBtn
    }

    override func cellIdentifier(_ cellViewModel: SFListPage<ListTaskViewModel>.CVM) -> String {
        return ListTaskTableViewCell.identifier
    }
    
    override func bindViewAndViewModel() {
        super.bindViewAndViewModel()
        guard let viewModel = viewModel else { return }
        viewModel.pageTitleSubject ~> rx.title => disposeBag
        addBtn.rx.tap.subscribe(onNext: { [weak self] in
            self?.showAddOrEditItem()
        }) => disposeBag
        backBtn.rx.tap.subscribe(onNext: { [weak self] in
            self?.tapBackBtn()
        }) => disposeBag
    }
    
    func tapBackBtn() {
        guard let viewModel = viewModel else { return }
        viewModel.updateListTask()
        self.navigationController?.popViewController(animated: true)
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        return [deleteAction(), editAction()]
    }
    
    func deleteAction() -> UITableViewRowAction {
        let deleteAction = UITableViewRowAction(style: .destructive, title: "Delete", handler: { [weak self] (_, indexPath) in
            self?.viewModel?.delete(at: indexPath)
        })
        return deleteAction
    }
    
    func editAction() -> UITableViewRowAction {
        let editAction = UITableViewRowAction(style: .normal, title: "Edit", handler: { [weak self] (_, indexPath) in
            self?.showAddOrEditItem(atIndex: indexPath)
        })
        return editAction
    }
    
    private func showAddOrEditItem(atIndex indexPath: IndexPath? = nil) {
        guard let vm = viewModel?.getAddEditViewModel(atIndex: indexPath) else { return }
        let viewController = AddAndEditViewController(viewModel: vm)
        navigationController?.present(viewController, animated: true)
    }
    
}

class ListTaskViewModel: ListViewModel<ListTaskModel, ListTaskTableViewCellViewModel> {
    
    let pageTitleSubject = BehaviorRelay<String?>(value: "")
    let updateListTaskSubject = PublishSubject<ListTaskModel>()
    
    override func react() {
        pageTitleSubject.accept(model?.title)
        itemsSource.append(getListTaskCell(listTask: model?.listTask ?? []))
    }
    
    func getListTaskCell(listTask: [TaskModel]) -> [ListTaskTableViewCellViewModel] {
        var listTaskCell: [ListTaskTableViewCellViewModel] = []
        for item in listTask {
            listTaskCell.append(ListTaskTableViewCellViewModel(model: item))
        }
        return listTaskCell
    }
    
    func getTaskModels(listCellViewModel: [ListTaskTableViewCellViewModel]) -> [TaskModel] {
        var listTaskModel: [TaskModel] = []
        for item in listCellViewModel {
            if let model = item.model {
                listTaskModel.append(model)
            }
        }
        return listTaskModel
    }
    
    func add(with taskName: String) {
        let newTask = TaskModel(title: taskName)
        model?.listTask.append(newTask)
        let newListTaskCellViewModel = ListTaskTableViewCellViewModel(model: newTask)
        itemsSource.append(newListTaskCellViewModel)
    }
    
    func delete(at indexPath: IndexPath) {
        model?.listTask.remove(at: indexPath.row)
        itemsSource.remove(at: indexPath)
    }
    
    func edit(at indexPath: IndexPath, with text: String) {
        if let cellViewModel = itemsSource.element(atIndexPath: indexPath) as? ListTaskTableViewCellViewModel {
            cellViewModel.updateTitle(text: text)
        }
    }
    
    func updateListTask() {
        var listCellViewModel: [ListTaskTableViewCellViewModel] = []
        for index in 0..<itemsSource.countElements() {
            guard let cellViewModel = itemsSource.element(atSection: 0, row: index) as? ListTaskTableViewCellViewModel else { return }
            if !cellViewModel.rxIsTaskDone.value {
                listCellViewModel.append(cellViewModel)
            }
        }
        itemsSource.reset(listCellViewModel)
        if let model = model {
            model.listTask = getTaskModels(listCellViewModel: listCellViewModel)
            updateListTaskSubject.onNext(model)
        }
    }
    
    func getAddEditViewModel(atIndex indexPath: IndexPath? = nil) -> AddAndEditViewModel {
        let addEditModel = getAddEditModel(for: indexPath)
        return AddAndEditViewModel(model: addEditModel, delegate: self)
    }
    
    func getAddEditModel(for indexPath: IndexPath?) -> AddEditModel? {
        guard let indexPath = indexPath, let cellViewModel = itemsSource.element(atIndexPath: indexPath) as? ListTaskTableViewCellViewModel,
              let title = cellViewModel.model?.title else {
            return nil
        }
        return AddEditModel(indexPath: indexPath, title: title)
    }
    
}

extension ListTaskViewModel: AddAndEditViewModelDelegate {
    func updateData(atIndex indexPath: IndexPath?, withNewTitle title: String) {
        if let indexPath = indexPath {
            edit(at: indexPath, with: title)
        } else {
            add(with: title)
        }
    }
}
