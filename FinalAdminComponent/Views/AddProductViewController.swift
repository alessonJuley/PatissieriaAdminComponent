//
//  AddProductViewController.swift
//  FinalAdminComponent
//
//  Created by Alesson Abao on 23/05/23.
//

import UIKit
import SQLite3

class AddProductViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate {
    
    // MARK: DB variables
    let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
    
    // MARK: Outlets
    @IBOutlet weak var addProductName: UITextField!
    @IBOutlet weak var addProductDescription: UITextView!
    @IBOutlet weak var addProductCategory: UITextField!
    @IBOutlet weak var addProductStock: UITextField!
    @IBOutlet weak var addProductPrice: UITextField!
    @IBOutlet weak var addProductImageURL: UITextField!
    @IBOutlet weak var addProductPic: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // disable keyboard after input
        addProductName.delegate = self
        addProductDescription.delegate = self
        addProductCategory.delegate = self
        addProductStock.delegate = self
        addProductPrice.delegate = self
        addProductImageURL.delegate = self
    }
    
    // MARK: Action buttons
    @IBAction func loadImageButton(_ sender: UIButton) {
        let urlText = addProductImageURL.text!
        
        if urlText.isEmpty{
            showMessage(message: "Input image url before loading", buttonCaption: "Close", controller: self)
        }
        else{
            
            if isImageURL(_urlString: urlText){
                let imgURL = URL(string: urlText)
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
                            self.addProductPic.image = imageProd
                        }
                    }
                }
                task.resume()
            }
            else{
                showMessage(message: "Invalid image url 🙁", buttonCaption: "Close", controller: self)
            }
        }
    }
    
    @IBAction func addProductButton(_ sender: UIButton) {
        if validateForm(){
            
            // insert data
            let insertProductStatementString = "INSERT INTO ProductList (productName, productDescription, productCategory, productStock, productPrice, productImage) VALUES (?, ?, ?, ?, ?, ?)"
            var insertStatementQuery : OpaquePointer?
            
            if(sqlite3_prepare_v2(dbQueue, insertProductStatementString, -1, &insertStatementQuery, nil)) == SQLITE_OK {
                // convert textfield inputs to appropriate type in db
                let productStock = Int32(addProductStock.text ?? "") ?? 0
                
                let productPriceString = addProductPrice.text ?? ""
                let productPrice = Double(productPriceString) ?? 1.00

                // bind the values of textfield inputs to sql query
                sqlite3_bind_text(insertStatementQuery, 1, addProductName.text ?? "", -1, SQLITE_TRANSIENT)
                sqlite3_bind_text(insertStatementQuery, 2, addProductDescription.text ?? "", -1, SQLITE_TRANSIENT)
                sqlite3_bind_text(insertStatementQuery, 3, addProductCategory.text ?? "", -1, SQLITE_TRANSIENT)
                sqlite3_bind_int(insertStatementQuery, 4, productStock)
                sqlite3_bind_double(insertStatementQuery, 5, productPrice)
                sqlite3_bind_text(insertStatementQuery, 6, addProductImageURL.text ?? "" , -1, SQLITE_TRANSIENT)

                if(sqlite3_step(insertStatementQuery)) == SQLITE_DONE{
                    // check for duplication and delete duplicate
                    if(deleteDuplicateProduct() == true){
                        showMessage(message: "The product you are trying to insert is a duplication. Deleting product.", buttonCaption: "Close", controller: self)
                        print("[AddProductViewController>addProductButton] Deleted duplicate 🥳")
                        resetForm()
                    }
                    else if(deleteDuplicateProduct() == false){
                        showMessage(message: "Duplicated product failed to delete 😔", buttonCaption: "Close", controller: self)
                        print("[AddProductViewController>addProductButton] Duplicate deletion failed 😔")
                    }
                    else{
                        resetForm()
                        addProductName.becomeFirstResponder()
                        showMessage(message: "Successfully added product 🥳", buttonCaption: "Close", controller: self)
                    }
                }
                else{
                    showMessage(message: "Failed adding product 🙁", buttonCaption: "Close", controller: self)
                }
                sqlite3_finalize(insertStatementQuery)
            }
            
            // ================================FOR TESTING========================================
            let selectStatementString = "SELECT productID, productName, productStock, productPrice, productImage FROM ProductList"
            
            var selectStatementQuery: OpaquePointer?
            
            var showData: String!
            showData = ""
            
            if sqlite3_prepare_v2(dbQueue, selectStatementString, -1, &selectStatementQuery, nil) == SQLITE_OK {
                while sqlite3_step(selectStatementQuery) == SQLITE_ROW{
                    let id = String(cString: sqlite3_column_text(selectStatementQuery, 0))
                    let name = String(cString: sqlite3_column_text(selectStatementQuery, 1))
                    let stock = Int(sqlite3_column_int(selectStatementQuery, 2))
                    let price = Double(sqlite3_column_double(selectStatementQuery, 3))
                    let url = String(cString: sqlite3_column_text(selectStatementQuery, 4))
                    
                    // ===========================FOR TESTING===========================
                    let rowData = "[AddProductViewController>addProductButton]THIS IS ADD PRODUCT BUTTON ADD PRODUCTVC " + "ID: \(id)\t\tname: \(name)\t\tstock: \(stock)\t\tprice: \(price)\t\turl: \(url)\n"
                    
                    showData += rowData
                    print(showData ?? "This is showData")
                    // ===========================FOR TESTING===========================
                }
                sqlite3_finalize(selectStatementQuery)
            }
            // ================================FOR TESTING========================================
        }
        else{
            showMessage(message: "Form must be filled", buttonCaption: "Try again", controller: self)
        }
    }
    
    // MARK: deleteDuplicateProduct
    func deleteDuplicateProduct() -> Bool{
        var checkSuccess : Bool = false
        
        let deleteDuplicateProduct = sqlite3_exec(dbQueue, "DELETE FROM ProductList WHERE productID NOT IN (SELECT MIN(productID) FROM ProductList GROUP BY productName)", nil, nil, nil)
        
        
        if(deleteDuplicateProduct != SQLITE_OK){
            print("[AddProductViewController>deleteDuplicateProduct] Cannot delete duplicate in ProductList table 🙁")
            checkSuccess = false
        }
        else{
            print("[AddProductViewController>deleteDuplicateProduct] ProductList table duplicate deleted 🥳")
            checkSuccess = true
        }
        
        return checkSuccess
    }
    
    // MARK: Form Validation
    func validateForm() -> Bool{
        
        // if text fields are empty
        guard let productName = addProductName.text, !productName.isEmpty else {
            return false
        }
        guard let productDescription = addProductDescription.text, !productDescription.isEmpty else {
            return false
        }
        guard let productStock = addProductStock.text, !productStock.isEmpty else {
            return false
        }
        guard let productPrice = addProductPrice.text, !productPrice.isEmpty else{
            return false
        }
        guard let productImage = addProductImageURL.text, !productImage.isEmpty else{
            return false
        }
        let productCategory = addProductCategory.text!
        
        // If inputs are not empty, these are more validation
        if !doStringContainsNumber(_string: productStock){
            print("stock should be a number")
            return false
        }
        else if !doStringContainsNumber(_string: productPrice){
            print("price should be a number")
            return false
        }
        else if !containsOnlyLetters(str: productName){
            print("product name should only contain letters")
            return false
        }
        else if !isImageURL(_urlString: productImage){
            print("image url invalid")
            return false
        }
        else if isValidCategory(_category: productCategory) == false{
            print("product category invalid")
            return false
        }
        return true
    }
    
    func isValidCategory( _category : String) -> Bool{
        var validStatus: Bool = false
        
        if _category == "" || _category.lowercased() == "popular" || _category.lowercased() == "gluten-free"{
            print("product category valid 🥳")
            validStatus = true
        }
        else{
            print("product category invalid 😔")
            validStatus = false
        }
        
        return validStatus
    }
    
    func doStringContainsNumber( _string : String) -> Bool{

        let numberRegEx  = ".*[0-9]+.*"
        let testCase = NSPredicate(format:"SELF MATCHES %@", numberRegEx)
        let containsNumber = testCase.evaluate(with: _string)

        return containsNumber
    }

    func containsOnlyLetters(str: String) -> Bool {
      let letterCharacterSet = CharacterSet.letters
      return str.rangeOfCharacter(from: letterCharacterSet) != nil
    }

    func isImageURL( _urlString: String) -> Bool {
        let urlRegEx  = "((http|https)://)(www.)?[a-zA-Z0-9@:%._\\+~#?&//=]{2,256}\\.[a-z]{2,6}\\b([-a-zA-Z0-9@:%._\\+~#?&//=]*)"
        let testCase = NSPredicate(format:"SELF MATCHES %@", urlRegEx)
        let containsUrl = testCase.evaluate(with: _urlString)

        return containsUrl
    }
    
    
    // MARK: Frontend Functions
    // reset form
    func resetForm(){
        addProductName.text = ""
        addProductDescription.text = ""
        addProductCategory.text = ""
        addProductStock.text = ""
        addProductPrice.text = ""
        addProductImageURL.text = ""
        addProductPic.image = nil
    }
    
    // dismiss keyboard when user clicks outside textbox
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    // dismiss keyboard when user clicks return in keyboard
    func textFieldShouldReturn(_ textField: UITextField) -> Bool{
        textField.resignFirstResponder()
        return true
    }
}
