//
//  NetworkManager.swift
//  SideDishApp
//
//  Created by 박진섭 on 2022/04/18.
//
import Foundation

struct NetworkManager: NetworkManagable {
    
    var session: URLSession

    init(session: URLSession) {
        self.session = session
    }
    
}
