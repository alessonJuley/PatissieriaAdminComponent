//
//  UpdateProductViewController.swift
//  FinalAdminComponent
//
//  Created by Alesson Abao on 23/05/23.
//

import UIKit
import SQLite3

class UpdateProductViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate {

    // MARK: DB variables
    let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
    
    // MARK: Outlets
    @IBOutlet weak var updateProductName: UITextField!
    @IBOutlet weak var updateProductDescription: UITextView!
    @IBOutlet weak var updateProductCategory: UITextField!
    @IBOutlet weak var updateProductStock: UITextField!
    @IBOutlet weak var updateProductPrice: UITextField!
    @IBOutlet weak var updateProductImageURL: UITextField!
    @IBOutlet weak var updateProductPic: UIImageView!
    
    var selectedProduct : ProductHolder!
    var updateCurrentRowProduct: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        updateProductName.text = selectedProduct.productName
        updateProductDescription.text = selectedProduct.productDescription
        updateProductCategory.text = selectedProduct.productCategory
        updateProductStock.text = (String)(selectedProduct.productStock)
        updateProductPrice.text = (String)(selectedProduct.productPrice)
        updateProductImageURL.text = selectedProduct.productImage
        updateProductPic.image = UIImage(named: selectedProduct.productImage)
        updateCurrentRowProduct = selectedProduct.productID
        
        // disable keyboard after input
        updateProductName.delegate = self
        updateProductDescription.delegate = self
        updateProductCategory.delegate = self
        updateProductStock.delegate = self
        updateProductPrice.delegate = self
        updateProductImageURL.delegate = self
        
        // make image autoload
        let urlText = updateProductImageURL.text!
        
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
                    self.updateProductPic.image = imageProd
                }
            }
        }
        task.resume()
    }
    
    @IBAction func loadImageButton(_ sender: UIButton) {
        let urlText = updateProductImageURL.text!
        
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
                            self.updateProductPic.image = imageProd
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
    
    @IBAction func updateProductButton(_ sender: UIButton) {
        if validateForm(){
            // update data
            let updateProductStatementString = "UPDATE ProductList SET productName = ?, productDescription = ?, productCategory = ?, productStock = ?, productPrice = ?, productImage = ? WHERE productID = ?"
            
            var updateStatementQuery : OpaquePointer?
            // compile sql query and check if status is okay
            if(sqlite3_prepare_v2(dbQueue, updateProductStatementString, -1, &updateStatementQuery, nil)) == SQLITE_OK {
                // bind the values of textfield inputs to sql query
                let updateProductStock = Int32(updateProductStock.text ?? "") ?? 0
                
                let productPriceString = updateProductPrice.text ?? ""
                let updateProductPrice = Double(productPriceString) ?? 1.00

                // bind the values of textfield inputs to sql query
                sqlite3_bind_text(updateStatementQuery, 1, updateProductName.text ?? "", -1, SQLITE_TRANSIENT)
                sqlite3_bind_text(updateStatementQuery, 2, updateProductDescription.text ?? "", -1, SQLITE_TRANSIENT)
                sqlite3_bind_text(updateStatementQuery, 3, updateProductCategory.text ?? "", -1, SQLITE_TRANSIENT)
                sqlite3_bind_int(updateStatementQuery, 4, updateProductStock)
                sqlite3_bind_double(updateStatementQuery, 5, updateProductPrice)
                sqlite3_bind_text(updateStatementQuery, 6, updateProductImageURL.text ?? "" , -1, SQLITE_TRANSIENT)
                sqlite3_bind_int(updateStatementQuery, 7, Int32(updateCurrentRowProduct))

                if(sqlite3_step(updateStatementQuery)) == SQLITE_DONE{
                    
                    updateProductName.becomeFirstResponder()
                    showMessage(message: "Successfully updated product 🥳", buttonCaption: "Close", controller: self)
                }
                else{
                    showMessage(message: "Failed updating product 🙁", buttonCaption: "Close", controller: self)
                }
                sqlite3_finalize(updateStatementQuery)
            }
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
    
    
    // MARK: Validations
    func validateForm() -> Bool{
        
        // if text fields are empty
        guard let productName = updateProductName.text, !productName.isEmpty else {
            return false
        }
        guard let productDescription = updateProductDescription.text, !productDescription.isEmpty else {
            return false
        }
        guard let productStock = updateProductStock.text, !productStock.isEmpty else {
                return false
            }
        guard let productPrice = updateProductPrice.text, !productPrice.isEmpty else{
            return false
        }
        guard let productImage = updateProductImageURL.text, !productImage.isEmpty else{
            return false
        }
        
        let productCategory = updateProductCategory.text!
        
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
