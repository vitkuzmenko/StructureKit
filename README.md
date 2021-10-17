![StructureKit: Perfect Table/Collection Building](structurekit.png)

StructureKit is an simplest way to control very very hard tables or collections.

## Features

- 🙉 Forget exceptions like `attempt to insert, delete, move etc...`
- 🙊 Forget `numberOfRows, numberOfItems, cellForRow etc...`
- 🙈 Forget `insertRows, deleteRows etc...`
- 😌 Most simplest building table or collection views
- 🤩 Automatic diff calculation for animations (insert, delete, move, update)
- 🙀 Super easy creating and controlling collections with different cell types
- 🤨 Does not store in memory previously used models for diff calculation
- 🤗 Using one `cellModel` for both `tableView` and `collectionView`

## Getting Started

### Installation

```ruby
pod 'StructureKit'
```

### Model

Make some models

```swift
// City will be used as cell
struct City {
	let title: String
}

// Country will be used as section
struct Country {
	let title: String
	let cities: [City]
}
```

Declare `City` model for using in `tableView`.

I recommend to create cell viewModel, but for simple demonstration, we use directly data entity.

Implement `StructurableIdentifable` for identify model in diffing calculation (`insert`, `delete`, `move`)

```swift
extension City: StructurableIdentifable {
    
    func identifyHash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
    
}
```
Implement `StructurableForTableView` for using in `tableView` and configure cell with model data. 

```swift
extension City: StructurableForTableView {
    
    // Reuse identifier will be registered as class name
    func configure(tableViewCell cell: CityTableViewCell) {
        cell.textLabel?.text = name
    }
    
}
```
### ViewController

Implementing `viewController` with `tableView`

```swift
class TableViewController: UIViewController {

    var countries: [Country] = []

    @IBOutlet var tableView: UITableView!
    
    let structureController = StructureController()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        loadCountries()
        configureTableView()
        makeStructure()
    }
    
    func loadCountries() {
        // some data loading
        self.countries = [
            Country(title: "USA", cities: [City(title: "New York"), City(title: "Los Angeles"), City(title: "Cupertino")]),
            Country(title: "Russia", cities: [City(title: "Moscow"), City(title: "Rostov-on-Don"), City(title: "Yeysk")])
        ]
    }
    
    // Register tableView and cell types in StructureController
    func configureTableView() {
    	// You can make registration once per instance
        structureController.register(tableView, cellModelTypes: [
            City.self
        ])
    }
    
    // Create table structure
    func makeStructure() {
        let structure = countries.map { country in
            var section = StructureSection(
                identifier: country.title,
                rows: country.cities
            )
            section.header = .text(country.name)
            return section
        }
        structureController.set(structure: structure)
    }
    
}

```
**Done!**
