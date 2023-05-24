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
    
    let vm = HomeViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel = vm
    }
    
    override func initialize() {
        super.initialize()
        tableView.register(UINib(nibName: "HomeTableViewCell", bundle: nil), forCellReuseIdentifier: HomeTableViewCell.identifier)
        navigationController?.navigationBar.prefersLargeTitles = true
        let addBtn = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(tapAddBtn))
        navigationItem.rightBarButtonItem = addBtn
    }

    override func cellIdentifier(_ cellViewModel: SFListPage<HomeViewModel>.CVM) -> String {
        return HomeTableViewCell.identifier
    }
    
    override func bindViewAndViewModel() {
        super.bindViewAndViewModel()
        guard let viewModel = viewModel else { return }
        viewModel.pageTitleSubject ~> rx.title => disposeBag
    }
    
    override func selectedItemDidChange(_ cellViewModel: SFListPage<HomeViewModel>.CVM) {
        guard let viewModel = viewModel else { return }
        let page = viewModel.selectListTaskPage(cellViewModel)
        navigationController?.pushViewController(page, animated: true)
    }
    
    @objc func tapAddBtn() {
        guard let viewModel = viewModel else { return }
        let page = viewModel.getAddVC()
        self.navigationController?.present(page, animated: true)
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
    
}

class HomeViewModel: ListViewModel<ToDoListModel, HomeTableViewCellViewModel> {
    
    let pageTitleSubject = BehaviorRelay<String?>(value: "Today Task")
    var listTaskPages: [ListTaskViewController] = []
    
    override func react() {
        let listTaskModels = getListTaskModels()
        itemsSource.append(getHomeTableViewCellViewModels(models: listTaskModels))
        listTaskPages = getListTaskPages(models: listTaskModels)
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
    
    func getListTaskPage(model: ListTaskModel) -> ListTaskViewController {
        let viewModel = ListTaskViewModel(model: model)
        let page = ListTaskViewController(viewModel: viewModel)
        return page
    }
    
    func getListTaskPages(models: [ListTaskModel]) -> [ListTaskViewController] {
        var listPage: [ListTaskViewController] = []
        for item in models {
            listPage.append(getListTaskPage(model: item))
        }
        return listPage
    }
    
    func selectListTaskPage(_ cellViewModel: HomeTableViewCellViewModel) -> UIViewController {
        var page: ListTaskViewController = ListTaskViewController()
        for item in listTaskPages {
            if cellViewModel.model == item.viewModel?.model {
                page = item
            }
        }
        page.viewModel?.countTask.subscribe(onNext: { index in
            self.updateCountTask(cellViewModel, countTask: index ?? 0)
        }).disposed(by: disposeBag ?? DisposeBag())
        return page
    }
    
    func add(with listTaskName: String) {
        let newListTaskModel = ListTaskModel(title: listTaskName)
        let newHomeCellViewModel = HomeTableViewCellViewModel(model: newListTaskModel)
        listTaskPages.append(getListTaskPage(model: newListTaskModel))
        itemsSource.append(newHomeCellViewModel)
    }
    
    func delete(at indexPath: IndexPath) {
        itemsSource.remove(at: indexPath)
    }
    
    func updateCountTask(_ cellViewModel: HomeTableViewCellViewModel, countTask: Int) {
        let contTask: String = countTask.description
        cellViewModel.countTaskSubject.accept(contTask)
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

