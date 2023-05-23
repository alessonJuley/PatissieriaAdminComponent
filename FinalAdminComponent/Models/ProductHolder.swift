//
//  ProductHolder.swift
//  FinalAdminComponent
//
//  Created by Alesson Abao on 22/05/23.
//

import Foundation
import UIKit

// pop-up message function
func showMessage(message: String, buttonCaption: String, controller: UIViewController)
{
    let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
    let action = UIAlertAction(title: buttonCaption, style: .default)
    
    alert.addAction(action)
    controller.present(alert, animated: true, completion: nil)
}

class ProductHolder{
    var productID: Int!
    var productName: String!
    var productDescription: String!
    var productCategory: String?
    var productStock: Int!
    var productPrice: Double!
    var productImage: String!
    
    public init(productID: Int!, productName: String!, productDescription: String!, productCategory: String?, productStock: Int!, productPrice: Double!, productImage: String!) {
        self.productID = productID
        self.productName = productName
        self.productDescription = productDescription
        self.productCategory = productCategory
        self.productStock = productStock
        self.productPrice = productPrice
        self.productImage = productImage
    }
}
