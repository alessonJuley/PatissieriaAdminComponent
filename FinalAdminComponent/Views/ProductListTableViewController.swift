//
//  ProductListTableViewController.swift
//  FinalAdminComponent
//
//  Created by Alesson Abao on 23/05/23.
//

import UIKit
import SQLite3

class ProductListTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    // object that will hold all the data
    var products = [ProductHolder]()
    var selectedProductID: Int = 0
    
    // MARK: Outlets
    @IBOutlet weak var productTableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        productTableView.dataSource = self
        productTableView.delegate = self
        
        loadSavedProducts()
    }
    
    // MARK: Action Buttons
    @IBAction func reloadProductsButton(_ sender: UIButton) {
        loadSavedProducts()
    }
    
    @IBAction func alphabeticalSortButton(_ sender: UIButton) {
        loadAlphabeticalProducts()
    }
    
    @IBAction func lowStockSortButton(_ sender: UIButton) {
        loadLowStockProducts()
    }
    
    @IBAction func lowToHighPriceSortButton(_ sender: UIButton) {
        loadLowHighPriceProducts()
    }
    
    // MARK: TableView Area
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return products.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = productTableView.dequeueReusableCell(withIdentifier: "productCell", for: indexPath) as! ProductListTableViewCell
        
        let thisProduct = products[indexPath.row]
        
        cell.productNameLabel.text = thisProduct.productName
        cell.productStockLabel.text = "Stock: " + (String)(thisProduct.productStock)
        cell.productPriceLabel.text = "Price: $" + (String)(thisProduct.productPrice)
        
        cell.productPic.image = UIImage(named: thisProduct.productImage)
        
        let urlText = thisProduct.productImage

        let imgURL = URL(string: urlText!)
        // make URL request object to send over the network
        let urlRequest = URLRequest(url: imgURL!)
        
        let task = URLSession.shared.dataTask(with: urlRequest)
        {
            (data,response,error)
            in
            if(error == nil)
            {
                let picData = try! Data(contentsOf: imgURL!)
                let imageProd = UIImage(data: picData)
                
                DispatchQueue.main.async { [self] in
                    cell.productPic.image = imageProd
                }
            }
        }
        task.resume()
        
        return cell
    }
    
    // MARK: Product Detail Segue
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.performSegue(withIdentifier: "productUpdate", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "productUpdate"){
            let indexPath = self.productTableView.indexPathForSelectedRow!
            let tableViewDetail = segue.destination as? UpdateProductViewController

            let selectedProduct = products[indexPath.row]
            tableViewDetail!.selectedProduct = selectedProduct
            self.productTableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    // MARK: Delete Product
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        .delete
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete{
            // delete from sqlite
            let deleteProductStatementString = "DELETE FROM ProductList WHERE productID = ?"
            var deleteStatementQuery: OpaquePointer?
            
            if sqlite3_prepare_v2(dbQueue, deleteProductStatementString, -1, &deleteStatementQuery, nil) == SQLITE_OK {
                let selectedProduct = products[indexPath.row]
                selectedProductID = selectedProduct.productID
                
                sqlite3_bind_int(deleteStatementQuery, 1, Int32(selectedProductID))
                
                if sqlite3_step(deleteStatementQuery) == SQLITE_DONE {
                    print("Successfully deleted product 🥳")
                    products.remove(at: indexPath.row) // Remove the product from the array after successful deletion from SQLite
                    tableView.deleteRows(at: [indexPath], with: .fade)
                    tableView.reloadData() // Update the table view
                } else {
                    print("Failed deleting product 🙁")
                }
                
                sqlite3_finalize(deleteStatementQuery)
            }
        }
    }
    
    // MARK: loadSavedProducts
    // ===============================SQL LOAD SAVED PRODUCTS START===============================
    var showData = ""
    
    func loadSavedProducts(){
        products = []
        
        let selectStatementString = "SELECT productID, productName, productDescription, productCategory, productStock, productPrice, productImage FROM ProductList"
        var selectStatementQuery: OpaquePointer?

        if sqlite3_prepare_v2(dbQueue, selectStatementString, -1, &selectStatementQuery, nil) == SQLITE_OK {
            while sqlite3_step(selectStatementQuery) == SQLITE_ROW{
                let productID = Int(sqlite3_column_int(selectStatementQuery, 0))
                let productName = String(cString: sqlite3_column_text(selectStatementQuery, 1))
                let productDescription = String(cString: sqlite3_column_text(selectStatementQuery, 2))
                let productCategory = String(cString: sqlite3_column_text(selectStatementQuery, 3))
                let productStock = Int(sqlite3_column_int(selectStatementQuery, 4))
                let productPrice = Double(sqlite3_column_double(selectStatementQuery, 5))
                let productImage = String(cString: sqlite3_column_text(selectStatementQuery, 6))
                
                let savedProduct = ProductHolder(
                    productID: productID,
                    productName: productName,
                    productDescription: productDescription,
                    productCategory: productCategory,
                    productStock: productStock,
                    productPrice: productPrice,
                    productImage: productImage
                )
                
                // ============================FOR TESTING============================
                let rowData = "THIS IS PRODUCT TABLE CONTROLLER LOAD SAVED PRODUCTS " + "ID: \(productID)\t\tname: \(productName)\t\tstock: \(productStock)\t\tprice: \(productPrice)\t\turl: \(productImage)\n"
                showData += rowData
                
                print(showData)
                // ============================FOR TESTING============================
                products.append(savedProduct)
            }
            sqlite3_finalize(selectStatementQuery)
        }
        productTableView.reloadData()
    }
    // ===============================SQL LOAD SAVED PRODUCTS END=================================
    
    // MARK: loadAlphabeticalProducts
    // ===============================SQL LOAD ALPHABETICAL PRODUCTS START========================
    func loadAlphabeticalProducts(){
        
        products = []
        
        let selectProductNameQuery = "SELECT * FROM ProductList ORDER BY productName ASC"
        var selectProductNameStatementQuery: OpaquePointer?
        
        if sqlite3_prepare_v2(dbQueue, selectProductNameQuery, -1, &selectProductNameStatementQuery, nil) == SQLITE_OK {
            while sqlite3_step(selectProductNameStatementQuery) == SQLITE_ROW {
                let productID = Int(sqlite3_column_int(selectProductNameStatementQuery, 0))
                let productName = String(cString: sqlite3_column_text(selectProductNameStatementQuery, 1))
                let productDescription = String(cString: sqlite3_column_text(selectProductNameStatementQuery, 2))
                let productCategory = String(cString: sqlite3_column_text(selectProductNameStatementQuery, 3))
                let productStock = Int(sqlite3_column_int(selectProductNameStatementQuery, 4))
                let productPrice = Double(sqlite3_column_double(selectProductNameStatementQuery, 5))
                let productImage = String(cString: sqlite3_column_text(selectProductNameStatementQuery, 6))
                
                let alphabeticalProduct = ProductHolder(
                    productID: productID,
                    productName: productName,
                    productDescription: productDescription,
                    productCategory: productCategory,
                    productStock: productStock,
                    productPrice: productPrice,
                    productImage: productImage
                )
                products.append(alphabeticalProduct)
            }
            sqlite3_finalize(selectProductNameStatementQuery)
        }
        productTableView.reloadData()
    }
    // ===============================SQL LOAD ALPHABETICAL PRODUCTS END===========================
    
    // MARK: loadLowStockProducts
    // ===============================SQL LOAD LOW STOCK PRODUCTS START============================
    func loadLowStockProducts(){
        
        products = []
        
        let selectProductStockQuery = "SELECT * FROM ProductList WHERE productStock <= 5 ORDER BY productStock ASC"
        var selectProductStockStatementQuery: OpaquePointer?
        
        if sqlite3_prepare_v2(dbQueue, selectProductStockQuery, -1, &selectProductStockStatementQuery, nil) == SQLITE_OK {
            while sqlite3_step(selectProductStockStatementQuery) == SQLITE_ROW {
                let productID = Int(sqlite3_column_int(selectProductStockStatementQuery, 0))
                let productName = String(cString: sqlite3_column_text(selectProductStockStatementQuery, 1))
                let productDescription = String(cString: sqlite3_column_text(selectProductStockStatementQuery, 2))
                let productCategory = String(cString: sqlite3_column_text(selectProductStockStatementQuery, 3))
                let productStock = Int(sqlite3_column_int(selectProductStockStatementQuery, 4))
                let productPrice = Double(sqlite3_column_double(selectProductStockStatementQuery, 5))
                let productImage = String(cString: sqlite3_column_text(selectProductStockStatementQuery, 6))
                
                let lowStockProduct = ProductHolder(
                    productID: productID,
                    productName: productName,
                    productDescription: productDescription,
                    productCategory: productCategory,
                    productStock: productStock,
                    productPrice: productPrice,
                    productImage: productImage
                )
                products.append(lowStockProduct)
            }
            sqlite3_finalize(selectProductStockStatementQuery)
        }
        productTableView.reloadData()
    }
    // ===============================SQL LOAD LOW STOCK PRODUCTS END==============================
    
    // MARK: loadLowHighPriceProducts
    // ===============================SQL LOAD LOW TO HIGH PRICE PRODUCTS START====================
    func loadLowHighPriceProducts(){
        
        products = []
        
        let selectPriceQuery = "SELECT * FROM ProductList ORDER BY productPrice ASC"
        var selectPriceStatementQuery: OpaquePointer?
        
        if sqlite3_prepare_v2(dbQueue, selectPriceQuery, -1, &selectPriceStatementQuery, nil) == SQLITE_OK {
            while sqlite3_step(selectPriceStatementQuery) == SQLITE_ROW {
                let productID = Int(sqlite3_column_int(selectPriceStatementQuery, 0))
                let productName = String(cString: sqlite3_column_text(selectPriceStatementQuery, 1))
                let productDescription = String(cString: sqlite3_column_text(selectPriceStatementQuery, 2))
                let productCategory = String(cString: sqlite3_column_text(selectPriceStatementQuery, 3))
                let productStock = Int(sqlite3_column_int(selectPriceStatementQuery, 4))
                let productPrice = Double(sqlite3_column_double(selectPriceStatementQuery, 5))
                let productImage = String(cString: sqlite3_column_text(selectPriceStatementQuery, 6))
                
                let lowHighPriceProduct = ProductHolder(
                    productID: productID,
                    productName: productName,
                    productDescription: productDescription,
                    productCategory: productCategory,
                    productStock: productStock,
                    productPrice: productPrice,
                    productImage: productImage
                )
                products.append(lowHighPriceProduct)
            }
            sqlite3_finalize(selectPriceStatementQuery)
        }
        productTableView.reloadData()
    }
    // ===============================SQL LOAD LOW TO HIGH PRICE PRODUCTS END======================
}
