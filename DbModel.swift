// Copyright (c) 2019 auhuro

import Foundation
import SQLite3

let SQLITE_STATIC = unsafeBitCast(0, to: sqlite3_destructor_type.self)
let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

class DBModel {
    typealias EachHandler = (OpaquePointer?) -> Any?
    typealias BindHandler = (OpaquePointer?) -> Void
    typealias CallbackResult = [Any?]
    typealias CallbackResultHandler = (CallbackResult) -> Void
    
    static func open(dbPath: String, db: inout OpaquePointer?, readonly: Bool = true) -> Bool {
        let flags = readonly ? SQLITE_OPEN_READONLY : (SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE)
        let rc = sqlite3_open_v2(dbPath, &db, flags | SQLITE_OPEN_FULLMUTEX, nil)
        if rc != SQLITE_OK  {
            print("Unable to open db")
            
            return false
        }
        return true
    }
    
    static func bindString(db: OpaquePointer, q: OpaquePointer?, pos:Int, value: String) {
        let itemName = value as NSString
        let rc = sqlite3_bind_text(q, Int32(pos), itemName.utf8String, -1, SQLITE_TRANSIENT)
        if (rc != SQLITE_OK) {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("error: bindString = \(rc), value = \(value) error: \(errmsg)")
            
        }
    }
    static func bindBlob(db: OpaquePointer, q: OpaquePointer?, pos:Int, value: Data?) {
        if (value == nil) {
            let data = value as? NSData
            let c = data!.count
            let d = data!.bytes
            let rc = sqlite3_bind_blob(q, Int32(pos), d, c, SQLITE_TRANSIENT)
        } else {
            let rc = sqlite3_bind_zeroblob(q, Int32(pos), 0)
        }
        if (rc != SQLITE_OK) {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("error: bindString = \(rc), value = \(value) error: \(errmsg)")
            
        }
    }
    
    
    static func bindInt(q: OpaquePointer?, pos:Int, value: Int) {
        let rc = sqlite3_bind_int(q, Int32(pos), Int32(value))
        if (rc != SQLITE_OK) {
            print("error: bindString = \(rc), value = \(value)")
            
        }
    }
    static func bindDouble(q: OpaquePointer?, pos:Int, value: Double) {
        sqlite3_bind_double(q, Int32(pos), value);
    }
    
    // MARK: - Gets.
    static func queryGetInt(queryStatement: OpaquePointer?, position: Int) -> Int {
        return Int(sqlite3_column_int(queryStatement, Int32(position)))
    }
    
    static func queryGetString(queryStatement: OpaquePointer?, position: Int) -> String? {
        let c = sqlite3_column_text(queryStatement, Int32(position))
        if (c == nil) {
            return nil
        }
        return String(cString: UnsafePointer(c!))
    }
    
    // MARK: - Query.
    static func queryPrepare(db: OpaquePointer, queryString: String) -> OpaquePointer? {
        var queryStatement: OpaquePointer? = nil
        // 1.
        if sqlite3_prepare_v2(db, queryString, -1, &queryStatement, nil) != SQLITE_OK {
            self.print_error(db: db)
            return nil
        }
        // 2
        return queryStatement;
    }
    static func queryPrepareBindAndRun(db: OpaquePointer
        , queryString: String
        , bind: BindHandler
        ) -> Bool
    {
        let statement: OpaquePointer? = self.queryPrepare(db: db, queryString: queryString)
        bind(statement)
        let rc = sqlite3_step(statement)
        let res = (rc == SQLITE_OK)
        sqlite3_finalize(statement)
        return res
    }

    static func queryPrepareBindAndRunArray(db: OpaquePointer
        , queryString: String
        , bind: BindHandler
        , each: EachHandler
        ) -> CallbackResult
    {
        var array: [Any?] = []
        let statement: OpaquePointer? = self.queryPrepare(db: db, queryString: queryString)
        bind(statement)
        
        
        var rc = sqlite3_step(statement)
        if (rc != SQLITE_ROW) {
            print("error: query result is \(rc) bind 100 is expected"); // TODO: remove this.
        }
        
        
        while (rc == SQLITE_ROW) {
            let itemInArray: Any? = each(statement)
            array.append(itemInArray)
            
            
            rc = sqlite3_step(statement)
            if (rc != SQLITE_ROW) {
                // print("error: B query result is \(rc) bind 100 is expected"); // TODO: remove this.
            }
        }
        sqlite3_finalize(statement);
        return array
    }
    
    static func queryPrepareBindAndRunArray_async(db: OpaquePointer
        , queryString: String
        , bind: BindHandler
        , each: EachHandler
        , callback: CallbackResultHandler
        ) -> Void
    {
        var array: [Any?] = []
        let statement: OpaquePointer? = self.queryPrepare(db: db, queryString: queryString)
        bind(statement)
        var rc = sqlite3_step(statement)
        while (rc == SQLITE_ROW) {
            let itemInArray: Any? = each(statement)
            array.append(itemInArray)
            rc = sqlite3_step(statement)
        }
        sqlite3_finalize(statement);
        callback(array)
    }
    
    func filterLimit(offset: Int, limit: Int) -> String {
        if (limit == 0) {
            return ""
        }
        return "LIMIT " + String(limit)  + " OFFSET " + String(offset)
    }
    
    static func print_error(db: OpaquePointer) {
        let s: UnsafePointer<Int8>? = sqlite3_errmsg(db)
        guard let ss = s else {
            return
        }
        let sss = String(cString: ss)
        print("\(sss)")
    }
}
