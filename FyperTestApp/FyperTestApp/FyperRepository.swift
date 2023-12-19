//
//  FyperRepository.swift
//  FyperTestApp
//
//  Created by Mark Bourke on 12/12/2023.
//

import Foundation
import Macros

protocol FyperRepositoryProtocol {

}

@Singleton(exposeAs: FyperRepositoryProtocol)
final class FyperRepository: FyperRepositoryProtocol {
    
	@Inject
    init() {
        
    }
}
