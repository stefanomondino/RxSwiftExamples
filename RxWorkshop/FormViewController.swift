//
//  FormViewController.swift
//  RxWorkshop
//
//  Created by Stefano Mondino on 15/06/17.
//  Copyright © 2017 Deltatre. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class Form {
    let username = Variable("testuser")
    let password = Variable("testpassword")
    let isValid:Observable<Bool>
    let title:Observable<String>
    init() {
        
        isValid = Observable.combineLatest(username.asObservable(),password.asObservable()) { user, password in
            user.characters.count > 5 && password.characters.count > 5
        }
        
        title = isValid
            .map { "Form \($0 ? "valido" : "invalido" )"}
        
    }
    func clear() {
        self.username.value = ""
        self.password.value = ""
    }
}

class FormViewController: UIViewController {
    
    @IBOutlet weak var txt_username:UITextField!
    @IBOutlet weak var txt_password:UITextField!
    @IBOutlet weak var btn_confirm:UIButton!
    var disposeBag = DisposeBag()
    let form = Form()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        (txt_username.rx.textInput <-> form.username).disposed(by: disposeBag)
        (txt_password.rx.textInput <-> form.password).disposed(by: disposeBag)
        form.isValid.bind(to: btn_confirm.rx.isEnabled).disposed(by: disposeBag)
        
        form.title.bind(to: self.rx.title).disposed(by: disposeBag)
        
        btn_confirm.rx.tap.asObservable().subscribe(onNext:{ [weak self] _ in
            self?.form.clear()
        }).disposed(by: disposeBag)
    }

    

}
