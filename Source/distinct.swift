//
//  distinct.swift
//  Pods
//
//  Created by Segii Shulga on 5/4/16.
//
//

import Foundation
import RxSwift

extension Observable where Element: Hashable {
    /**
     Suppress duplicate items emitted by an Observable
     - seealso: [distinct operator on reactivex.io](http://reactivex.io/documentation/operators/distinct.html)
     - returns: An observable sequence only containing the distinct contiguous elements, based on equality operator, from the source sequence.
     */
    public func distinct() -> Observable<Element> {
        var cache = Set<Element>()
        return flatMap { element -> Observable<Element> in
            if cache.contains(element) {
                return Observable<Element>.empty()
            } else {
                cache.insert(element)
                return Observable<Element>.just(element)
            }
        }
    }
}

extension Observable where Element: Equatable {
    /**
     Suppress duplicate items emitted by an Observable
     - seealso: [distinct operator on reactivex.io](http://reactivex.io/documentation/operators/distinct.html)
     - returns: An observable sequence only containing the distinct contiguous elements, based on equality operator, from the source sequence.
     */
    public func distinct() -> Observable<Element> {
        var cache = [Element]()
        return flatMap { element -> Observable<Element> in
            if cache.contains(element) {
                return Observable<Element>.empty()
            } else {
                cache.append(element)
                return Observable<Element>.just(element)
            }
        }
    }
}
