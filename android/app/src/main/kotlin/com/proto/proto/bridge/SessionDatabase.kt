package com.proto.proto.bridge

import android.content.ContentValues
import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper

class SessionDatabase(context: Context) :
    SQLiteOpenHelper(context, "proto.db", null, 1) {

    override fun onCreate(db: SQLiteDatabase) {
        db.execSQL(
            """
            CREATE TABLE sessions (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                startTime INTEGER NOT NULL,
                endTime INTEGER NOT NULL,
                durationMinutes INTEGER NOT NULL,
                blockedCount INTEGER NOT NULL
            )
            """.trimIndent()
        )
    }

    override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) {}

    fun insert(
        startTime: Long,
        endTime: Long,
        durationMinutes: Int,
        blockedCount: Int
    ) {
        val cv = ContentValues().apply {
            put("startTime", startTime)
            put("endTime", endTime)
            put("durationMinutes", durationMinutes)
            put("blockedCount", blockedCount)
        }
        writableDatabase.insert("sessions", null, cv)
    }

    fun getAll(): List<Map<String, Any>> {
        val results = mutableListOf<Map<String, Any>>()
        val cursor = readableDatabase.query(
            "sessions", null, null, null, null, null, "startTime DESC"
        )
        cursor.use {
            while (it.moveToNext()) {
                results.add(
                    mapOf(
                        "id" to it.getInt(0),
                        "startTime" to it.getLong(1),
                        "endTime" to it.getLong(2),
                        "durationMinutes" to it.getInt(3),
                        "blockedCount" to it.getInt(4)
                    )
                )
            }
        }
        return results
    }
}
