//
//  cascade.swift
//  RxSwiftExtDemo
//
//  Created by Florent Pillet on 17/04/16.
//  Copyright © 2016 RxSwift Community. All rights reserved.
//

import Foundation
import RxSwift

extension Observable where Element : ObservableType {
	
	typealias T = Element.E
	
	/**
	Cascade through a sequence of observables: every observable that sends a `next` value becomes the "current"
	observable (like in `switchLatest`), and the subscription to all previous observables in the sequence is disposed.
	
	This allows subscribing to multiple observable sequences while irrevocably switching to the next when it starts emitting. If any of the
	currently subscribed-to sequences errors, the error is propagated to the observer and the sequence terminates.
	
	- parameter observables: a sequence of observables which will all be immediately subscribed to
	- returns: An observable sequence that contains elements from the latest observable sequence that emitted elements
	*/
	
	@warn_unused_result(message="http://git.io/rxs.uo")
	public static func cascade<S : SequenceType where S.Generator.Element == Element, S.Generator.Element.E == T>(observables : S) -> Observable<T> {
		let flow = Array(observables)
		if flow.isEmpty {
			return Observable<T>.empty()
		}
		
		return Observable<T>.create { observer in
			var current = 0, initialized = false
			var subscriptions = [Disposable?](count: flow.count, repeatedValue: nil)

			let lock = NSRecursiveLock()
			lock.lock()
			defer { lock.unlock() }
			
			for i in 0 ..< flow.count {
				let index = i
				var complete = false
				let disposable = flow[index].subscribe { event in
					
					lock.lock()
					defer { lock.unlock() }
					
					switch event {
					case .Next(let element):
						while current < index {
							subscriptions[current]?.dispose()
							subscriptions[current] = nil
							current += 1
						}
						observer.onNext(element)
						
					case .Completed:
						complete = true
						if index >= current {
							if (initialized) {
								subscriptions[index]?.dispose()
								subscriptions[index] = nil
								for next in current ..< subscriptions.count {
									if subscriptions[next] != nil {
										return
									}
								}
								observer.onCompleted()
							}
						}
						
					case .Error(let error):
						observer.onError(error)
					}
				}
				if !complete {
					subscriptions[index] = disposable
				}
				else {
					disposable.dispose()
				}
			}
			initialized = true
			
			for i in 0 ..< flow.count {
				if subscriptions[i] != nil {
					return AnonymousDisposable {
						subscriptions.forEach { $0?.dispose() }
					}
				}
			}

			observer.onCompleted()
			return NopDisposable.instance
		}
	}
}

extension ObservableType {
	
	/**
	Cascade through a sequence of observables: every observable that sends a `next` value becomes the "current"
	observable (like in `switchLatest`), and the subscription to all previous observables in the sequence is disposed.
	
	This allows subscribing to multiple observable sequences while irrevocably switching to the next when it starts emitting. If any of the
	currently subscribed-to sequences errors, the error is propagated to the observer and the sequence terminates.
	
	- parameter observables: a sequence of observables which will all be immediately subscribed to
	- returns: An observable sequence that contains elements from the latest observable sequence that emitted elements
	*/
	@warn_unused_result(message="http://git.io/rxs.uo")
	public func cascade<S : SequenceType where S.Generator.Element == Self>(next : S) -> Observable<E> {
		return Observable.cascade([self.asObservable()] + Array(next).map { $0.asObservable() })
	}
	
}