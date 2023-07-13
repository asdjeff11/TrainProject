//
//  CompositionViewModel.swift
//  MyTestingProject
//
//  Created by 楊宜濱 on 2023/7/6.
//

import Foundation

protocol CompositionDelegate:AnyObject {
    func deleteCallBack(model:itemModel)
}

class CompositionViewModel {
    private var items:[Int:[itemModel]] = [:]
    
    weak var delegate:CompositionDelegate?
    
    func setUpData() {
        for i in 0...3 {
            items[i] = Array(0...29).map({ itemModel(n: $0, section: i)})
        }
    }
    
    func getItems(section:Int)->[itemModel] {
        items[section] ?? []
    }
    
    func deleteOne() {
        let section = items.compactMap({ $0.value.isEmpty ? nil : $0.key })
        guard let random_Section = section.randomElement(),
              let random_cell = items[random_Section]?[0]
              //let index = items[random_Section]?.firstIndex(of: random_cell)
        else { return }
        
        items[random_Section]?.remove(at: 0)
        delegate?.deleteCallBack(model:random_cell)
    }
}
