//
//  ViewController.swift
//  ToDoList
//
//  Created by Long Tran on 22/05/2023.
//

import UIKit
import RxSwift
import RxCocoa
import Action

class HomeViewController: SFListPage<HomeViewModel> {
    
    let homeViewModel = HomeViewModel()
    let addBtn = UIBarButtonItem(barButtonSystemItem: .add, target: nil, action: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.viewModel = homeViewModel
    }
    
    override func initialize() {
        super.initialize()
        tableView.register(UINib(nibName: "HomeTableViewCell", bundle: nil), forCellReuseIdentifier: HomeTableViewCell.identifier)
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.rightBarButtonItem = addBtn
    }

    override func cellIdentifier(_ cellViewModel: SFListPage<HomeViewModel>.CVM) -> String {
        return HomeTableViewCell.identifier
    }
    
    override func bindViewAndViewModel() {
        super.bindViewAndViewModel()
        guard let viewModel = viewModel else { return }
        viewModel.pageTitleSubject ~> rx.title => disposeBag
        addBtn.rx.tap.subscribe(onNext: { [weak self] in
            self?.showAddOrEditItem()
        }) => disposeBag
    }
    
    override func selectedItemDidChange(_ cellViewModel: SFListPage<HomeViewModel>.CVM) {
        guard let vm = viewModel?.getListTaskViewModel(cellViewModel) else { return }
        let page = ListTaskViewController(viewModel: vm)
        navigationController?.pushViewController(page, animated: true)
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

class HomeViewModel: ListViewModel<ToDoListModel, HomeTableViewCellViewModel> {
    
    let pageTitleSubject = BehaviorRelay<String?>(value: "Today Task")
    
    override func react() {
        let listTaskModels = getListTaskModels()
        itemsSource.append(getHomeTableViewCellViewModels(models: listTaskModels))
    }
    
    func getListTaskModels() -> [ListTaskModel] {
        let listTaskModels: [ListTaskModel] = [
            ListTaskModel(title: "Work"),
            ListTaskModel(title: "Home")
        ]
        return listTaskModels
    }
    
    func getHomeTableViewCellViewModels(models: [ListTaskModel]) -> [HomeTableViewCellViewModel] {
        var listCellViewModel: [HomeTableViewCellViewModel] = []
        for item in models {
            let cellViewModel = HomeTableViewCellViewModel(model: item)
            listCellViewModel.append(cellViewModel)
        }
        return listCellViewModel
    }
        
    func getListTaskViewModel(_ cellViewModel: HomeTableViewCellViewModel) -> ListTaskViewModel {
        let viewModel = ListTaskViewModel(model: cellViewModel.model)
        viewModel.updateListTaskSubject.subscribe(onNext: { [weak self] model in
            self?.updateCell(at: cellViewModel, with: model)
        }) => disposeBag
        return viewModel
    }
    
    func add(with listTaskName: String) {
        let newListTaskModel = ListTaskModel(title: listTaskName)
        let newHomeCellViewModel = HomeTableViewCellViewModel(model: newListTaskModel)
        itemsSource.append(newHomeCellViewModel)
    }
    
    func delete(at indexPath: IndexPath) {
        itemsSource.remove(at: indexPath)
    }
    
    func edit(at indexPath: IndexPath, with text: String) {
        if let cellViewModel = itemsSource.element(atIndexPath: indexPath) as? HomeTableViewCellViewModel {
            cellViewModel.updateTitle(text: text)
        }
    }
    
    func updateCell(at cellViewModel: HomeTableViewCellViewModel,with model: ListTaskModel) {
        cellViewModel.updateCountTask(with: model)
    }
    
    func getAddEditViewModel(atIndex indexPath: IndexPath? = nil) -> AddAndEditViewModel {
        let addEditModel = getAddEditModel(for: indexPath)
        return AddAndEditViewModel(model: addEditModel, delegate: self)
    }
    
    func getAddEditModel(for indexPath: IndexPath?) -> AddEditModel? {
        guard let indexPath = indexPath, let cellViewModel = itemsSource.element(atIndexPath: indexPath) as? HomeTableViewCellViewModel,
              let title = cellViewModel.model?.title else {
            return nil
        }
        return AddEditModel(indexPath: indexPath, title: title)
    }

}

extension HomeViewModel: AddAndEditViewModelDelegate {
    func updateData(atIndex indexPath: IndexPath?, withNewTitle title: String) {
        if let indexPath = indexPath {
            edit(at: indexPath, with: title)
        } else {
            add(with: title)
        }
    }
}
