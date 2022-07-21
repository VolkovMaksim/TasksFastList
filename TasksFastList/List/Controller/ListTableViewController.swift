//
//  ListTableViewController.swift
//  TasksFastList
//
//  Created by Maksim Volkov on 21.07.2022.
//

import UIKit
import CoreData

class ListTableViewController: UITableViewController {

    @IBOutlet weak var navigationBar: UINavigationItem!
    var listOfNotes: [Note] = []
    
    // MARK: - Add new Note
    
    @IBAction func addNewNote(_ sender: UIBarButtonItem) {
        // создаем всплывающее окно с полем для ввода записи
        let alertController = UIAlertController(title: "Новая запись", message: "Что будем добавлять?", preferredStyle: .alert)
        // создаем кнопку "Добавить"
        let okAction = UIAlertAction(title: "Добавить", style: .default) { action in
            let textField = alertController.textFields?.first
            if let newNoteTitle = textField?.text {
                if !newNoteTitle.isEmpty {
                    self.newNote(withTitle: newNoteTitle)
                    self.tableView.reloadData()
                } else {
                    let alertControllerEmptyTitle = UIAlertController(title: "Ошибка!", message: "Вы не ввели текст", preferredStyle: .alert)
                    let cancelActionEmptyTitle = UIAlertAction(title: "Понятно", style: .default) { _ in}
                    alertControllerEmptyTitle.addAction(cancelActionEmptyTitle)
                    self.present(alertControllerEmptyTitle, animated: true)
                }
            }
        }
        // создаем кнопку "Отмена"
        let cancelAction = UIAlertAction(title: "Отмена", style: .cancel) { _ in}
        // добавляем поле ввода в AlertController
        alertController.addTextField { _ in }
        // добавляем кнопки в AlertController
        alertController.addAction(cancelAction)
        alertController.addAction(okAction)
        // выводим на дисплей AlertController
        present(alertController, animated: true)
    }
    // MARK: - New Note
    
    // стучимся в AppDelegate и сохраняем наши данные в CoreData
    private func newNote(withTitle title: String) {
        // добываем контекст
        let context = getContext()
        // добираемся до Entity
        guard let entity = NSEntityDescription.entity(forEntityName: "Note", in: context) else { return }
        // получаем объект сущности
        let entityObject = Note(entity: entity, insertInto: context)
        // помещаем заголовок в объекта сущности для отображения в табличке
        entityObject.name = title
        entityObject.done = false
        // пробуем сохранить контекст
        do {
            try context.save()
            // добавляем объект в массив на 0
            listOfNotes.insert(entityObject, at: 0)
            updateCountTasks()
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }
    
    // MARK: - Get Context
    
    // получаем контекст
    private func getContext() -> NSManagedObjectContext {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.persistentContainer.viewContext
    }
    
    // MARK: - saveContext
    
    private func saveContext() {
        let context = getContext()
        
        do {
            try context.save()
//            print("Сохранение контекста")
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }
    
    private func updateCountTasks() {
        var doneTask = 0
        for item in listOfNotes {
            if item.done {
                doneTask += 1
            }
        }
        navigationItem.title = "\(doneTask) \\ \(listOfNotes.count)"
    }
    
    // MARK: - viewWillAppear
    
    // метод, без которого не будет отображения элементов таблицы после перезапуска приложения
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let context = getContext()
        // создаем запрос, через который можем получить все объекты, хранящиеся в Entity Note
        let fetchRequest: NSFetchRequest<Note> = Note.fetchRequest()
        // изменяем порядок отображения после перезапуска: true новые - внизу, false - новые - сверху
        let sortDescriptor = NSSortDescriptor(key: "index", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        // сохраняем в массив перечень элементов из CoreData
        do {
            listOfNotes = try context.fetch(fetchRequest)
            updateCountTasks()
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }
    
    // MARK: - viewDidLoad
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.estimatedRowHeight = 44
        self.tableView.tableFooterView = UIView()
        self.navigationItem.leftBarButtonItem = self.editButtonItem
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listOfNotes.count
    }

    //    этот метод позволяет изменить размер ячейки
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    // MARK: - cellForRowAt
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Note", for: indexPath)
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.font = UIFont(name: "Helvetica", size: 20)
        if listOfNotes[indexPath.row].done == false {
            cell.textLabel?.text = listOfNotes[indexPath.row].name!
            listOfNotes[indexPath.row].index = Int16(indexPath.row)
            let attributeString = NSMutableAttributedString(string: (cell.textLabel?.text)!)
            attributeString.addAttribute(NSAttributedString.Key.strikethroughStyle, value: 0, range: NSMakeRange(0, attributeString.length))
            cell.textLabel?.textColor = .black
            cell.textLabel?.attributedText = attributeString
            saveContext()
            return cell
        } else {
            cell.textLabel?.text = listOfNotes[indexPath.row].name!
            listOfNotes[indexPath.row].index = Int16(indexPath.row)
            let attributeString = NSMutableAttributedString(string: (cell.textLabel?.text)!)
            attributeString.addAttribute(NSAttributedString.Key.strikethroughStyle, value: 2, range: NSMakeRange(0, attributeString.length))
            cell.textLabel?.textColor = .lightGray
            cell.textLabel?.attributedText = attributeString
            saveContext()
            return cell
        }
    }
    
    // MARK: - editingStyle
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // получаем контекст
            let context = getContext()
            let element = listOfNotes.remove(at: indexPath.row)
            context.delete(element)
            tableView.deleteRows(at: [indexPath], with: .none)
            // сохраняем контекст
            do {
                try context.save()
                updateCountTasks()
            } catch let error as NSError {
                print(error.localizedDescription)
            }
        }
    }

    // MARK: - moveRowAt
    
    // метод реализации логики кнопки перемещения
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        // получаем контекст
        let context = getContext()
        // listOfNotes: [Note] - массив c сущностями, в котором содержатся все отображаемые в tableView элементы
        let element = listOfNotes[sourceIndexPath.row]
        let indexOfSource = sourceIndexPath
        let indexOfDestination = destinationIndexPath
        // добавляем элемент в нужную ячейку
        if element.done {
            listOfNotes.remove(at: sourceIndexPath.row)
            listOfNotes.insert(element, at: destinationIndexPath.row)
            listOfNotes[destinationIndexPath.row].index = Int16(destinationIndexPath.row)
            let attributeString = NSMutableAttributedString(string: element.name!)
            attributeString.addAttribute(NSAttributedString.Key.strikethroughStyle, value: 2, range: NSMakeRange(0, attributeString.length))
            tableView.cellForRow(at: destinationIndexPath)?.textLabel?.textColor = .lightGray
            tableView.cellForRow(at: destinationIndexPath)?.textLabel?.attributedText = attributeString
            tableView.cellForRow(at: destinationIndexPath)?.textLabel?.text = listOfNotes[destinationIndexPath.row].name
        } else {
            listOfNotes.remove(at: sourceIndexPath.row)
            listOfNotes.insert(element, at: destinationIndexPath.row)
            let attributeString = NSMutableAttributedString(string: element.name!)
            attributeString.addAttribute(NSAttributedString.Key.strikethroughStyle, value: 0, range: NSMakeRange(0, attributeString.length))
            tableView.cellForRow(at: destinationIndexPath)?.textLabel?.textColor = .black
            tableView.cellForRow(at: destinationIndexPath)?.textLabel?.attributedText = attributeString
            tableView.cellForRow(at: destinationIndexPath)?.textLabel?.text = listOfNotes[destinationIndexPath.row].name
        }
        self.tableView.reloadRows(at: [indexOfSource], with: .none)
        self.tableView.reloadRows(at: [indexOfDestination], with: .none)
        // обновить tableView
        tableView.reloadData()
        // сохраняем контекст
        do {
            try context.save()
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }
 
    // MARK: - checkMark

    private func checkMark(bool: Bool) -> Bool {
        return bool
    }
    
    // MARK: - leadingSwipeActionsConfigurationForRowAt
    
    // добавляем действие при свайпе ячейки слева направо
    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let done = doneAction(at: indexPath)
        return UISwipeActionsConfiguration(actions: [done])
    }
    
    // MARK: - Done Action
    
    // создаем функцию для контекстной кнопки Done
    func doneAction (at indexPath: IndexPath) -> UIContextualAction {
        
        if listOfNotes[indexPath.row].done == false {
            // сначала создадим объект типа UIContextualAction
            let action = UIContextualAction(style: .destructive, title: "Done") { (action, view, completion) in
                // создаем атрибут для зачеркивания текста
                let attributeString = NSMutableAttributedString(string: self.listOfNotes[indexPath.row].name!)
                attributeString.addAttribute(NSAttributedString.Key.strikethroughStyle, value: 2, range: NSMakeRange(0, attributeString.length))
                self.tableView.cellForRow(at: indexPath)?.textLabel?.textColor = .lightGray
                self.tableView.cellForRow(at: indexPath)?.textLabel?.attributedText = attributeString
                // меняем значение Done на true
                self.listOfNotes[indexPath.row].done = true
                completion(true)
                // сохраняем контекст (сохраняем значение Done в контексте)
                self.saveContext()
                self.updateCountTasks()
            }
            action.backgroundColor = .systemGreen
            action.image = UIImage(systemName: "checkmark.circle")
            return action
        } else {
            let unAction = UIContextualAction(style: .destructive, title: "Undone") { (action, view, completion) in
                // меняем значение Done на false
                self.listOfNotes[indexPath.row].done = false
                // сбрасываем зачеркивание ячейки
                let attributeString = NSMutableAttributedString(string: self.listOfNotes[indexPath.row].name!)
                attributeString.addAttribute(NSAttributedString.Key.strikethroughStyle, value: 0, range: NSMakeRange(0, attributeString.length))
                self.tableView.cellForRow(at: indexPath)?.textLabel?.textColor = .black
                self.tableView.cellForRow(at: indexPath)?.textLabel?.attributedText = attributeString
                completion(true)
                // сохраняем контекст (сохраняем значение Done в контексте)
                self.saveContext()
                self.updateCountTasks()
            }
            unAction.image = UIImage(systemName: "pencil.slash")
            return unAction
        }
    }
}
