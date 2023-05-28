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
        addBtn.rx.tap.subscribe(onNext: {
            self.tapAddBtn()
        }) => disposeBag
        backBtn.rx.tap.subscribe(onNext: {
            self.tapBackBtn()
        }) => disposeBag
    }
    
    func tapAddBtn() {
        guard let viewModel = viewModel else { return }
        let page = viewModel.getAddVC()
        navigationController?.present(page, animated: true)
    }
    
    func tapBackBtn() {
        guard let viewModel = viewModel else { return }
        viewModel.updateListTask()
        navigationController?.popViewController(animated: true)
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let editAction = UITableViewRowAction(style: .normal, title: "Edit", handler: { action, indexPath in
            guard let viewModel = self.viewModel else { return }
            let page = viewModel.getEditVC(at: indexPath)
            self.navigationController?.present(page, animated: true)
        })
        let deleteAction = UITableViewRowAction(style: .destructive, title: "Delete", handler: { action, indexPath in
            self.viewModel?.delete(at: indexPath)
        })
        return [deleteAction, editAction]
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
            listTaskModel.append(item.model!)
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
        let cellViewModel = itemsSource.element(atIndexPath: indexPath) as! ListTaskTableViewCellViewModel
        cellViewModel.taskNameSubject.accept(text)
    }
    
    func updateListTask() {
        var listCellViewModel: [ListTaskTableViewCellViewModel] = []
        itemsSource.forEach { (_, sectionList) in
            sectionList.forEach({ (_, cvm) in
                if !cvm.rxIsTaskDone.value {
                    listCellViewModel.append(cvm)
                }
            })
        }
        itemsSource.reset(listCellViewModel)
        model?.listTask = getTaskModels(listCellViewModel: listCellViewModel)
        updateListTaskSubject.onNext(model!)
    }
    
    func getAddVC() -> UIViewController {
        let page = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "AddViewController") as! AddViewController
        let viewModel = AddViewModel()
        page.viewModel = viewModel
        page.viewModel?.addSubject.subscribe(onNext: { [weak self] text in
            self?.add(with: text)
        }) => disposeBag
        return page
    }
    
    func getEditVC(at indexPath: IndexPath) -> UIViewController {
        let page = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "EditViewController") as! EditViewController
        let model = (itemsSource.element(atIndexPath: indexPath) as! ListTaskTableViewCellViewModel).model
        let viewModel = EditViewModel(model: model)
        page.viewModel = viewModel
        page.viewModel?.titleLabelSubject.accept(model?.title ?? "")
        page.viewModel?.editSubject.subscribe(onNext: { [weak self] text in
            self?.edit(at: indexPath, with: text)
        }) => disposeBag
        return page
    }
    
}
