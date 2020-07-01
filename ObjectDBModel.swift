import Foundation
import SQLite3
class ObjectDBModel {
static let shared = ObjectDBModel()
    var db: OpaquePointer? = nil
		private init(){
			let documentsPath: String = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
				let dbPath: String = documentsPath.appending("/O.sqlite")
				print("dbPath = \(dbPath)")
				if true {
					try? FileManager.default.removeItem(atPath: dbPath)
				}
			let shouldCreate = FileManager.default.fileExists(atPath: dbPath) == false
				// TODO: Check version.
				DBModel.open(dbPath: dbPath, db: &self.db, readonly: false)
				if (shouldCreate) {
					dbCreate()
				}
		}
		private func dbCreate() {
			_ = DBModel.queryPrepareBindAndRun(db: self.db!, queryString: "DROP TABLE IF EXISTS object", bind:{_ in})

				_ = DBModel.queryPrepareBindAndRun(db: self.db!, queryString: "CREATE TABLE IF NOT EXISTS object ("
						+ " id INTEGER PRIMARY KEY NOT NULL UNIQUE"
						+ " , externalId TEXT NOT NULL"
						+ " , blobField BLOB NOT NULL"
						+ " , label TEXT NULL"
						+ " , blobResult BLOB NULL"
						+ ")", bind:{_ in})
        _ = DBModel.queryPrepareBindAndRun(db: self.db!, queryString: "INSERT INTO object (externalId, blobField) VALUES (?,?)", bind:{statement in
            DBModel.bindString(db: self.db!, q: statement, pos: 1, value: "second_purchase")
            DBModel.bindString(db: self.db!, q: statement, pos: 2, value: "v 0.123 0.234 0.345 1.0")
		}
		func object_get(dbId: Int) -> ObjectDbObject?  {
			let a = DBModel.queryPrepareBindAndRunArray(db: self.db!, queryString:
					"SELECT s.id, s.externalId, s.label FROM object AS s WHERE s.id = ?"
					, bind: { statement in
						DBModel.bindInt(q: statement, pos: 1, value: dbId)
					}) { (statement) -> Any? in
						return (
								DBModel.queryGetInt(queryStatement: statement, position: 0) // id
								, DBModel.queryGetString(queryStatement: statement, position: 1) // externalId
								//                , DBModel.queryGetString(queryStatement: statement, position: 2) // externalId
								, DBModel.queryGetString(queryStatement: statement, position: 2) // s.label
								)
			}
			if a.count == 0 {
					return nil
			}
			let b = a.map{ oo -> ObjectDbObject in
				let o: (Int, String, String?) = oo as! (Int, String, String?)
					let dbId = o.0 as Int
					let externalId = o.1 as String
					//            let serverOrderId = o.2 as String
					let label = o.2 as String?
					return ObjectDbObject(dbId: dbId, externalIdId: externalId, label: label)
			}
			return b[0]
		}

}
