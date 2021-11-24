//
//  SearchScope.swift
//  iTunesSearch
//
//  Created by Eric Davis on 23/11/2021.
//

import Foundation


enum SearchScope: CaseIterable {
    case all, podcast, movies, music, apps, books
    
    
    var title: String {
        switch self {
        case .all: return "All"
        case .podcast: return "Podcast"
        case .movies: return "Movies"
        case .music: return "Music"
        case .apps: return "Apps"
        case .books: return "Books"
        }
    }
    
    var mediaType: String {
        switch self {
        case .all: return "all"
        case .podcast: return "podcast"
        case .movies: return "movie"
        case .music: return "music"
        case .apps: return "software"
        case .books: return "ebook"
        }
    }
    
}
