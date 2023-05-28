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
        addBtn.rx.tap.subscribe(onNext: {
            self.tapAddBtn()
        }) => disposeBag
    }
    
    func tapAddBtn() {
        guard let viewModel = viewModel else { return }
        let page = viewModel.getAddVC()
        navigationController?.present(page, animated: true)
    }
    
    override func selectedItemDidChange(_ cellViewModel: SFListPage<HomeViewModel>.CVM) {
        guard let viewModel = viewModel else { return }
        let page = viewModel.getListTaskViewController(cellViewModel)
        navigationController?.pushViewController(page, animated: true)
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
        
    func getListTaskViewController(_ cellViewModel: HomeTableViewCellViewModel) -> ListTaskViewController {
        let viewModel = ListTaskViewModel(model: cellViewModel.model)
        let page = ListTaskViewController(viewModel: viewModel)
        page.viewModel?.updateListTaskSubject.subscribe(onNext: { [weak self] model in
            self?.updateCountTask(cellViewModel, model: model)
        }) => disposeBag
        return page
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
        let cellViewModel = itemsSource.element(atIndexPath: indexPath) as! HomeTableViewCellViewModel
        cellViewModel.model?.title = text
        cellViewModel.titleSubject.accept(text)
    }
    
    func updateCountTask(_ cellViewModel: HomeTableViewCellViewModel, model: ListTaskModel) {
        let countTask: String = model.listTask.count.description
        cellViewModel.countTaskSubject.accept(countTask)
        cellViewModel.model?.listTask = model.listTask
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
        let model = (itemsSource.element(atIndexPath: indexPath) as! HomeTableViewCellViewModel).model
        let viewModel = EditViewModel(model: model)
        page.viewModel = viewModel
        page.viewModel?.titleLabelSubject.accept(model?.title ?? "")
        page.viewModel?.editSubject.subscribe(onNext: { [weak self] text in
            self?.edit(at: indexPath, with: text)
        }) => disposeBag
        return page
    }
}

