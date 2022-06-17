import UIKit
import CoreData

class ViewController: UIViewController {
    
    let coreDataStack = CoreDataStack()
    
    let tableView = UITableView()
    
    let searchBar = UISearchBar()
    
    lazy var fetchRsultsController: NSFetchedResultsController<Item> = {
        let fetchRquest = Item.fetchRequest()
        
        let sort = NSSortDescriptor(key: #keyPath(Item.createdAt), ascending: true)
        fetchRquest.sortDescriptors = [sort]
        
        
        let fetchResultsController = NSFetchedResultsController(fetchRequest: fetchRquest, managedObjectContext: coreDataStack.managedContext, sectionNameKeyPath: nil, cacheName: nil)
        
        return fetchResultsController
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getItems()
        setUpSearchBarLayout()
        setUpTableViewLayout()
        configureTableView()
        configureNavigationBar()
        fetchRsultsController.delegate = self
    }
    
    private func setUpSearchBarLayout() {
        searchBar.searchBarStyle = .prominent
        searchBar.placeholder = "Search for item..."
        searchBar.sizeToFit()
        searchBar.delegate = self
        
        tableView.tableHeaderView = searchBar
        
        
    }

    private func setUpTableViewLayout() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
    
    private func configureTableView() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    private func configureNavigationBar() {
        let addButton = UIBarButtonItem(image: UIImage(systemName: "plus.circle"), style: .done, target: self, action: #selector(addButtonTapped))
        
        navigationItem.rightBarButtonItem = addButton
    }
    
    @objc func addButtonTapped() {
        showAlert()
    }
    
    
    private func showAlert() {
        let alert = UIAlertController(title: "Write task", message: nil, preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Write down your task"
        }
        
        
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { _ in
            guard let textField = alert.textFields?.first,
            let text = textField.text, !text.isEmpty else { return }
            
            self.save(with: text)
            

            self.tableView.reloadData()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addAction(cancelAction)
        alert.addAction(saveAction)
        
        present(alert, animated: true)
        
    }
    
    func getItems() {
        do {
            try fetchRsultsController.performFetch()
        } catch {
            print("I can fetch items")
        }
    }
    
    func getItems(for name: String) {
        var predicate: NSPredicate?
        
        if !name.isEmpty {
            predicate = NSPredicate(format: "name contains[c] '\(name)'")
        } else {
            predicate = nil
        }
        
        fetchRsultsController.fetchRequest.predicate = predicate
        
        
        do {
            try fetchRsultsController.performFetch()
        } catch {
            print("I can't fetch items")
        }
        
    }
    
    func save(with name: String) {
        let context = coreDataStack.managedContext
        
        let item = Item(context: context)
        item.name = name
        item.createdAt = Date()
    
        
        coreDataStack.save()
    }
}


extension ViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchRsultsController.sections?.first?.numberOfObjects ?? 0
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
        
        let item = fetchRsultsController.object(at: indexPath)
        
        cell.textLabel?.text = item.name
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            deleteItem(at: indexPath)
        }
    }
    
    func deleteItem(at indexPath: IndexPath) {
        let item = fetchRsultsController.object(at: indexPath)
        let context = coreDataStack.managedContext
        
        context.delete(item)
        
        do {
            try context.save()
        } catch {
            print("I can't save")
        }
    }
}

extension ViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        getItems(for: searchText)
        
        tableView.reloadData()
    }
}

extension ViewController: NSFetchedResultsControllerDelegate{
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.reloadData()
    }
    
}

