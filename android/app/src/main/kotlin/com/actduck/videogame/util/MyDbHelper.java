package com.actduck.videogame.util;//package com.actduck.videogame.util;
//
//import android.content.Context;
//import android.database.sqlite.SQLiteDatabase;
//import android.database.sqlite.SQLiteOpenHelper;
//
//public class MyDbHelper extends SQLiteOpenHelper {
//    // Table Names
//    private static final String TABLE_POSTS = "posts";
//
//
//    public MyDbHelper(Context context) {
//        super(context, DATABASE_NAME, null, DATABASE_VERSION);
//    }
//
//    // Called when the database connection is being configured.
//    // Configure database settings for things like foreign key support, write-ahead logging, etc.
//    @Override
//    public void onConfigure(SQLiteDatabase db) {
//        super.onConfigure(db);
//        db.setForeignKeyConstraintsEnabled(true);
//    }
//
//    // Called when the database is created for the FIRST time.
//    // If a database already exists on disk with the same DATABASE_NAME, this method will NOT be called.
//    @Override
//    public void onCreate(SQLiteDatabase db) {
//        String CREATE_POSTS_TABLE = "CREATE TABLE " + TABLE_POSTS +
//                "(" +
//                    KEY_POST_ID + " INTEGER PRIMARY KEY," + // Define a primary key
//                    KEY_POST_USER_ID_FK + " INTEGER REFERENCES " + TABLE_USERS + "," + // Define a foreign key
//                    KEY_POST_TEXT + " TEXT" +
//                ")";
//
//        String CREATE_USERS_TABLE = "CREATE TABLE " + TABLE_USERS +
//                "(" +
//                    KEY_USER_ID + " INTEGER PRIMARY KEY," +
//                    KEY_USER_NAME + " TEXT," +
//                    KEY_USER_PROFILE_PICTURE_URL + " TEXT" +
//                ")";
//
//        db.execSQL(CREATE_POSTS_TABLE);
//        db.execSQL(CREATE_USERS_TABLE);
//    }
//
//    // Called when the database needs to be upgraded.
//    // This method will only be called if a database already exists on disk with the same DATABASE_NAME,
//    // but the DATABASE_VERSION is different than the version of the database that exists on disk.
//    @Override
//    public void onUpgrade(SQLiteDatabase db, int oldVersion, int newVersion) {
//        if (oldVersion != newVersion) {
//            // Simplest implementation is to drop all old tables and recreate them
//            db.execSQL("DROP TABLE IF EXISTS " + TABLE_POSTS);
//            db.execSQL("DROP TABLE IF EXISTS " + TABLE_USERS);
//            onCreate(db);
//        }
//    }
//}