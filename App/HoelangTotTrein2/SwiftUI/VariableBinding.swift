//
//  VariableBinding.swift
//  HoelangTotTrein2
//
//  Created by Tomas Harkema on 07/08/2019.
//  Copyright © 2019 Tomas Harkema. All rights reserved.
//

import Bindable
import Combine

public class VariableBindable<T>: ObservableObject {
  private let disposeBag: DisposeBag
  let variable: Variable<T>
  @Published var value: T

  static func constant(value: T) -> VariableBindable<T> {
    return .init(constant: value)
  }
  
  public init(variable: Variable<T>) {
    self.disposeBag = DisposeBag()
    self.variable = variable
    
    value = variable.value
    variable.subscribe { [weak self] event in
      self?.value = event.value
    }.disposed(by: disposeBag)
  }
  
  init(constant: T) {
    self.disposeBag = DisposeBag()
    value = constant
    let source = VariableSource(value: constant)
    variable = source.variable
  }
}
