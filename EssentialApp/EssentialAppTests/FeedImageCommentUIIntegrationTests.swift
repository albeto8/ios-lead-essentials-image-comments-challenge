//
//  FeedImageCommentUIIntegrationTests.swift
//  EssentialAppTests
//
//  Created by Mario Alberto Barragán Espinosa on 09/02/21.
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import XCTest
import UIKit
import EssentialFeed

final class FeedImageCommentViewController: UITableViewController {
	private var loader: FeedImageCommentLoader?
	private var url: URL?
	
	convenience init(loader: FeedImageCommentLoader, url: URL) {
		self.init()
		self.loader = loader
		self.url = url
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		refreshControl = UIRefreshControl()
		refreshControl?.addTarget(self, action: #selector(load), for: .valueChanged)
		refreshControl?.beginRefreshing()
		load()
	}
	
	@objc private func load() {
		_ = loader?.loadImageCommentData(from: url!) { [weak self] _ in 
			self?.refreshControl?.endRefreshing()
		}
	}
}

class FeedImageCommentUIIntegrationTests: XCTestCase {
	
	func test_init_doesNotLoadFeedImageComments() {
		let (_, loader) = makeSUT()
		
		XCTAssertEqual(loader.loadedImageCommentURLs.count, 0)
	}
	
	func test_viewDidLoad_loadsComments() {
		let (sut, loader) = makeSUT()
		
		sut.loadViewIfNeeded()
		
		XCTAssertEqual(loader.loadedImageCommentURLs, [anyURL()])
	}
	
	func test_pullToRefresh_loadsComments() {
		let (sut, loader) = makeSUT()
		sut.loadViewIfNeeded()

		sut.simulateUserInitiatedFeedCommentReload()

		XCTAssertEqual(loader.loadedImageCommentURLs, [anyURL(), anyURL()])
	}
	
	func test_viewDidLoad_showsLoadingIndicator() {
		let (sut, _) = makeSUT()

		sut.loadViewIfNeeded()

		XCTAssertEqual(sut.isShowingLoadingIndicator, true)
	}
	
	func test_viewDidLoad_hidesLoadingIndicatorOnLoaderCompletion() {
		let (sut, loader) = makeSUT()

		sut.loadViewIfNeeded()
		loader.completeFeedCommentLoading()

		XCTAssertEqual(sut.isShowingLoadingIndicator, false)
	}
	
	func test_pullToRefresh_showsLoadingIndicator() {
		let (sut, _) = makeSUT()

		sut.simulateUserInitiatedFeedCommentReload()

		XCTAssertEqual(sut.isShowingLoadingIndicator, true)
	}
	
	func test_pullToRefresh_hidesLoadingIndicatorOnLoaderCompletion() {
		let (sut, loader) = makeSUT()

		sut.simulateUserInitiatedFeedCommentReload()
		loader.completeFeedCommentLoading()

		XCTAssertEqual(sut.isShowingLoadingIndicator, false)
	}
	
	// MARK: - Helpers
	
	private func makeSUT(url: URL = anyURL(), file: StaticString = #file, line: UInt = #line) -> (sut: FeedImageCommentViewController, loader: LoaderSpy) {
		let loader = LoaderSpy()
		let sut = FeedImageCommentViewController(loader: loader, url: url)
		trackForMemoryLeaks(loader, file: file, line: line)
		trackForMemoryLeaks(sut, file: file, line: line)
		return (sut, loader)
	}
	
	class LoaderSpy: FeedImageCommentLoader {
		
		// MARK:- FeedImageCommentLoader
		
		private struct TaskSpy: FeedImageCommentLoaderTask {
			let cancelCallback: () -> Void
			func cancel() {
				cancelCallback()
			}
		}
		
		private var imageCommentRequests = [(url: URL, completion: (FeedImageCommentLoader.Result) -> Void)]()
		
		var loadedImageCommentURLs: [URL] {
			return imageCommentRequests.map { $0.url }
		}
				
		func loadImageCommentData(from url: URL, completion: @escaping (Result<[FeedImageComment], Error>) -> Void) -> FeedImageCommentLoaderTask {
			imageCommentRequests.append((url, completion))
			return TaskSpy { }
		}
		
		func completeFeedCommentLoading(with feedComments: [FeedImageComment] = [], at index: Int = 0) {
			imageCommentRequests[index].completion(.success(feedComments))
		}
	}
}


private extension FeedImageCommentViewController {
	func simulateUserInitiatedFeedCommentReload() {
		refreshControl?.simulatePullToRefresh()
	}
	
	var isShowingLoadingIndicator: Bool {
		return refreshControl?.isRefreshing == true
	}
}
