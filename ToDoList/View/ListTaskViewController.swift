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
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound], completionHandler: { success, error in
        })
        UNUserNotificationCenter.current().delegate = self
    }

    override func cellIdentifier(_ cellViewModel: SFListPage<ListTaskViewModel>.CVM) -> String {
        return ListTaskTableViewCell.identifier
    }
    
    override func bindViewAndViewModel() {
        super.bindViewAndViewModel()
        guard let viewModel = viewModel else { return }
        viewModel.rxPageTitle ~> rx.title => disposeBag
        addBtn.rx.tap.subscribe(onNext: { [weak self] in
            self?.showAddOrEditItem()
        }) => disposeBag
        backBtn.rx.tap.subscribe(onNext: { [weak self] in
            self?.tapBackBtn()
        }) => disposeBag
    }
    
    func tapBackBtn() {
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
        let viewController = AddEditTaskViewController(viewModel: vm)
        viewController.modalPresentationStyle = .fullScreen
        navigationController?.present(viewController, animated: true)
    }
    
}

extension ListTaskViewController: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}


class ListTaskViewModel: ListViewModel<ListTaskModel, ListTaskTableViewCellViewModel> {
    
    let rxPageTitle = BehaviorRelay<String?>(value: "")
    let rxUpdateListTask = PublishSubject<Int>()
    
    override func react() {
        rxPageTitle.accept(model?.title)
        itemsSource.reset([getListTaskCell(listTask: model?.listTask ?? [])])
    }
    
    func getListTaskCell(listTask: [TaskModel]) -> [ListTaskTableViewCellViewModel] {
        return listTask.map {
            ListTaskTableViewCellViewModel(model: $0, delegate: self)
        }
    }
    
    func getTaskModels(listCellViewModel: [ListTaskTableViewCellViewModel]) -> [TaskModel] {
        return listCellViewModel.map {
            TaskModel(title: $0.model?.title ?? "", time: $0.model?.time ?? Date())
        }
    }
    
    func add(with taskName: String, and time: Date) {
        let newTask = TaskModel(title: taskName, time: time)
        model?.listTask.append(newTask)
        rxUpdateListTask.onNext(model?.listTask.count ?? 0)
        let newListTaskCellViewModel = ListTaskTableViewCellViewModel(model: newTask, delegate: self)
        itemsSource.append(newListTaskCellViewModel)
        let indexPath = IndexPath(row: (model?.listTask.count ?? 0) - 1, section: 0)
        countDownTask(time, with: taskName, at: indexPath)
    }
    
    func delete(at indexPath: IndexPath) {
        model?.listTask.remove(at: indexPath.row)
        rxUpdateListTask.onNext(model?.listTask.count ?? 0)
        itemsSource.remove(at: indexPath)
    }
    
    func edit(at indexPath: IndexPath, with taskName: String, and time: Date) {
        if let cellViewModel = itemsSource.element(atIndexPath: indexPath) as? ListTaskTableViewCellViewModel {
            cellViewModel.update(text: taskName, time: time)
        }
        countDownTask(time, with: taskName, at: indexPath)
    }
    
    func getAddEditViewModel(atIndex indexPath: IndexPath? = nil) -> AddEditTaskViewModel {
        let addEditModel = getAddEditModel(for: indexPath)
        return AddEditTaskViewModel(model: addEditModel, delegate: self)
    }
    
    func getAddEditModel(for indexPath: IndexPath?) -> AddEditTaskModel? {
        guard let indexPath = indexPath, let cellViewModel = itemsSource.element(atIndexPath: indexPath) as? ListTaskTableViewCellViewModel,
              let title = cellViewModel.model?.title, let time = cellViewModel.model?.time else {
            return nil
        }
        return AddEditTaskModel(indexPath: indexPath, title: title, time: time)
    }
    
    func countDownTask(_ time: Date, with title: String, at indexPath: IndexPath) {
        let countDownPushNoti = Observable<Int>.timer(RxTimeInterval.seconds(time.getCountDownTimePushNoti()), scheduler: MainScheduler.instance)
        let countDown = Observable<Int>.timer(RxTimeInterval.seconds(time.getCountDownTime()), scheduler: MainScheduler.instance)
        guard let cellViewModel = self.itemsSource.element(atIndexPath: indexPath) as? ListTaskTableViewCellViewModel else { return }
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            countDownPushNoti.subscribe(onNext: { [weak self] _ in
                if time.getCountDownTimePushNoti() >= 0 {
                    self?.pushNoti(with: title)
                }
                cellViewModel.updateTimeColor(.orange)
            }) => self.disposeBag
            countDown.subscribe(onNext: { [weak self] _ in
                cellViewModel.updateTimeColor(.red)
            }) => self.disposeBag
        }
    }
    
    func pushNoti(with title: String) {
        print("push noti")
        let content = UNMutableNotificationContent()
        content.title = "To Do List"
        content.subtitle = model?.title ?? ""
        content.sound = .defaultRingtone
        content.body = "You have 30 minutes left to complete task \(title)"
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let requestIdentifier = "notification"
        let request = UNNotificationRequest(identifier: requestIdentifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: { (error) in
            if let error = error {
                print("Notification Error: ", error)
            }
        })
    }
    
}

extension ListTaskViewModel: AddEditTaskViewModelDelegate {
    func updateData(atIndex indexPath: IndexPath?, withNewTitle title: String, withNewTime time: Date) {
        if let indexPath = indexPath {
            edit(at: indexPath, with: title, and: time)
        } else {
            add(with: title, and: time)
        }
    }
}

extension ListTaskViewModel: ListTaskTableViewCellViewModelDelegate {
    func checkTaskDone() {
        var listCellViewModel: [ListTaskTableViewCellViewModel] = []
        for index in 0..<itemsSource.countElements() {
            guard let cellViewModel = itemsSource.element(atSection: 0, row: index) as? ListTaskTableViewCellViewModel else { return }
            if !cellViewModel.rxIsTaskDone.value {
                listCellViewModel.append(cellViewModel)
            }
        }
        if let model = model {
            model.listTask = getTaskModels(listCellViewModel: listCellViewModel)
            rxUpdateListTask.onNext(model.listTask.count)
        }
    }
}
