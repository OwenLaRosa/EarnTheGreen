//
//  YahooFinance.swift
//  Earn the Green
//
//  Created by Owen LaRosa on 8/7/15.
//  Copyright (c) 2015 Owen LaRosa. All rights reserved.
//

import Foundation

/// Swift implementation of the Yahoo! Finance API used to search for and download stock data.
class YahooFinance: NSObject {
    
    /// General method for HTTP GET requests. Completion handler provides the resulting data in NSData format. Error is returned as the localized description. Returns an NSURLSessionTask instance.
    func downloadJSONData(url: String, completionHandler: (data: NSData?, error: String?) -> Void) -> NSURLSessionTask {
        let session = NSURLSession.sharedSession()
        let request = NSMutableURLRequest(URL: NSURL(string: url)!)
        request.HTTPMethod = "GET"
        
        let task = session.dataTaskWithRequest(request) {data, response, error in
            if error != nil {
                completionHandler(data: nil, error: error!.localizedDescription)
            } else {
                completionHandler(data: data, error: nil)
            }
        }
        task.resume()
        
        return task
    }
    
    /// Helper method for converting JSON data into an NSDictionary. If the parsing fails, the completion handler contains the error's localized description.
    func parseJSONData(data: NSData, completionHandler: (result: NSDictionary?, error: String?) -> Void) {
        do {
            let parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments) as! NSDictionary
            completionHandler(result: parsedResult, error: nil)
        } catch let parsingError as NSError {
            print(parsingError.localizedDescription)
            completionHandler(result: nil, error: parsingError.localizedDescription)
        }
    }
    
    /// Gets the data associated with the specified ticker. Completion handler contains the data in parsed format and the error's localized description if retrieving the data fails.
    func getInformationForTicker(ticker: String, completionHandler: (data: [String: AnyObject]?, error: String?) -> Void) -> NSURLSessionTask {
        let queryURL = "http://query.yahooapis.com/v1/public/yql?q=select%20*%20from%20yahoo.finance.quotes%20where%20symbol%20in%20%28%22\(ticker)%22%29&env=store://datatables.org/alltableswithkeys&format=json"
        let task = downloadJSONData(queryURL) {data, downloadError in
            if downloadError != nil {
                completionHandler(data: nil, error: downloadError)
            } else {
                self.parseJSONData(data!) {result, parsingError in
                    let info = result!.valueForKey("query") as! [String: AnyObject]
                    if (info["count"] as! Int) == 1 {
                        let tickerInfo = info["results"] as! [String: AnyObject]
                        let quote = tickerInfo["quote"] as! [String: AnyObject]
                        completionHandler(data: quote, error: nil)
                    } else {
                        print(info["count"] as! Int)
                        completionHandler(data: nil, error: parsingError)
                    }
                }
            }
        }
        return task
    }
    
    /// Completion handler contains the search results of asset data for the query or the error's localized description if retrieving the data fails.
    func getTickerForSearch(query: String, completionHandler: (data: [String: AnyObject]?, error: String?) -> Void) -> NSURLSessionTask {
        let queryURL = "http://d.yimg.com/autoc.finance.yahoo.com/autoc?query=\(Helpers().formatStringForSearch(query))&callback=YAHOO.Finance.SymbolSuggest.ssCallback"
        let task = downloadJSONData(queryURL) {data, downloadError in
            if downloadError != nil {
                completionHandler(data: nil, error: downloadError)
            } else {
                let newData = data?.subdataWithRange(NSMakeRange(39, data!.length - 40)) // exclude last character and non-JSON data
                self.parseJSONData(newData!) {result, parsingError in
                    if parsingError != nil {
                        completionHandler(data: nil, error: parsingError)
                    } else {
                        let resultSet = result!.valueForKey("ResultSet") as! [String: AnyObject]
                        let searchResults = resultSet["Result"] as! [[String: AnyObject]]
                        if searchResults.count != 0 {
                            completionHandler(data: searchResults[0], error: nil)
                        } else {
                            completionHandler(data: nil, error: "No results found for query: \(query)")
                        }
                    }
                }
            }
        }
        return task
    }
    
    // MARK: - Convenience Methods
    
    class func sharedInstance() -> YahooFinance {
        
        struct Singleton {
            static var sharedInstance = YahooFinance()
        }
        
        return Singleton.sharedInstance
    }
    
}