//
//  UIControlPublisher.swift
//  MyTestingProject
//
//  Created by 楊宜濱 on 2023/2/7.
//

import Foundation
import UIKit
import Combine
extension UIControl {
    func publisher(for events:UIControl.Event)-> Publishers.UIControlPublisher<UIControl> {
        return Publishers.UIControlPublisher(control: self, event: events)
    }
}

extension UITextField {
    func publisherForTextChange() -> AnyPublisher<String?,Never> {
        return Publishers.UIControlPublisher(control: self, event: .editingChanged) // 建立 Publisher
            .map{ $0.text } // 每次得到資料後 做加工
            .eraseToAnyPublisher() //外部只在乎值 故使用完就 清除
    }
}

extension UIButton {
    func publisher()-> AnyPublisher<Bool,Never> {
        return Publishers.UIControlPublisher(control: self, event: .touchUpInside)
            .map({ $0.isSelected.toggle() ; return $0.isSelected == true })
            .eraseToAnyPublisher()
    }
}

extension CustomSegmentedControl {
    func publisher()-> AnyPublisher<Int,Never> {
        return Publishers.UIControlPublisher(control: self, event: .valueChanged)
            .map {
                return $0.selectedSegmentIndex
            }.eraseToAnyPublisher()
    }
}
