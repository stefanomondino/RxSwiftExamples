//
//  ViewController.swift
//  RxWorkshop
//
//  Created by Stefano Mondino on 14/06/17.
//  Copyright © 2017 Deltatre. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa


enum Examples {
    case apiSimple
    case autoCounter
    case clock
    case chronograph
    case image
    case query
    case map
    case form
    static var all:[Examples] {
        return [.apiSimple, .autoCounter, .clock, .chronograph, .image, .query, .map, .form]
    }
    var name:String {
        switch self {
        case .apiSimple : return "TVMaze next schedule (simple API)"
        case .autoCounter : return "Auto counter"
        case .clock : return "Digital clock"
        case .chronograph : return "Cronometro"
        case .image : return "Remote background image"
        case .query : return "Search TVMaze"
        case .map : return "Location and map"
        case .form : return "Form"
        }
    }
    
    func action(for vc:ViewController) -> ()->() {
        switch self {
        case .apiSimple : return {vc.test_api_simple()}
        case .autoCounter : return {vc.test_auto_counter()}
        case .clock : return {vc.test_clock()}
        case .chronograph : return {vc.test_cronograph_bind()}
        case .image : return { vc.test_image()}
        case .query : return { vc.test_query()}
        case .map : return {vc.performSegue(withIdentifier: "mapSegue", sender: nil)}
        case .form : return {vc.performSegue(withIdentifier: "formSegue", sender: nil)}
        }
    }
    
}

class ViewController: UIViewController {
    var disposeBag = DisposeBag()
    @IBOutlet weak var lbl_text: UILabel!
    @IBOutlet weak var txt_field: UITextField!
    @IBOutlet weak var img_background: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.lbl_text.text = "CIAO!"
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func testAction(_ sender: Any) {
        
        
        let actionSheet = UIAlertController(title: "Menu", message: "Cosa vuoi fare?", preferredStyle: .actionSheet)
        Examples.all.forEach { example in
            actionSheet.addAction(UIAlertAction(title: example.name, style: .default, handler: {[weak self] _ in
                self?.disposeBag = DisposeBag()
                example.action(for: self!)()
            }))
        }
        actionSheet.addAction(UIAlertAction(title: "Annulla", style: .cancel, handler: nil))
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    func test_api_simple() {
        self.lbl_text.text = "Caricamento in corso..."
        URLSession
            .shared
            .rx
            .json(url: URL(string:"https://api.tvmaze.com/schedule")!)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext:{[weak self] json in
                let array = json as? [[String:Any]]
                if let first = array?.first,
                    let title = first["name"] as? String
                {
                    
                    self?.lbl_text.text =  "Next episode is \(title)"
                }
            })
            .disposed(by: self.disposeBag)
    }
    
    
    func test_auto_counter() {
        self.lbl_text.text = "Guarda i log!"
        Observable<Int>
            .interval(1, scheduler: MainScheduler.instance)
            .subscribe(onNext: {
                print ($0)
            })
            .disposed(by: self.disposeBag)
    }
    
    func test_clock() {
        let dateFormatter = DateFormatter()
        self.lbl_text.text = ""
        dateFormatter.dateFormat = "HH:mm:ss"
        Observable<Int>
            .interval(0.01, scheduler: MainScheduler.instance)
            .map { _ in
                return dateFormatter.string(from: Date())
            }
            .subscribe(onNext: { [weak self] in
                self?.lbl_text.text = $0
            })
            .disposed(by: self.disposeBag)
    }
    
    func test_cronograph_bind() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss.SSS"
        Observable<Int>
            .interval(0.01, scheduler: MainScheduler.instance)
            .map { _ in
                return dateFormatter.string(from: Date())
            }
            .bind(to: lbl_text.rx.text)
            .disposed(by: self.disposeBag)
    }
    
    
    func test_image() {
        if let url = URL(string:"https://lorempixel.com/750/1336/cats/") {
            let request = URLRequest(url: url)
            URLSession.shared.rx.data(request: request).map {
                return UIImage(data: $0)
                }
                .bind(to: self.img_background.rx.image)
                .disposed(by: disposeBag)
        }
    }
    
    
    
    private func query(with query:String) -> Observable<String>{
        let query = query.addingPercentEncoding(withAllowedCharacters: CharacterSet.alphanumerics) ?? ""
        return URLSession
            .shared
            .rx
            .json(url: URL(string:"https://api.tvmaze.com/search/shows?q=\(query)")!)
            
            .observeOn(MainScheduler.instance)
            .catchErrorJustReturn("Errore")
            .map{ json in
                let array = json as? [[String:Any]]
                if let first = array?.first?["show"] as?  [String:Any],
                    let summary = first["summary"] as? String,
                    let title = first["name"] as? String
                {
               
                    return  "\(title.capitalized)\n\n\(summary)"
                }
                
                return query.characters.count > 0 ? "n/a" : "Cerca qualcosa!"
        }
    }
    
    func test_query() {
        
        self.txt_field.rx.text.asObservable()
            .debounce(1, scheduler: MainScheduler.instance)
            .map { $0 ?? ""}
            .flatMapLatest { self.query(with: $0) }
            .startWith("Caricamento in corso...")
            .bind(to:self.lbl_text.rx.text)
            .disposed(by: self.disposeBag)
    }
    
    
    let currentText = Variable("")
    func test_data_binding() {
        
        (self.txt_field.rx.textInput <-> currentText).disposed(by: disposeBag)
    }
    
    
}




