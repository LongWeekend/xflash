package com.longweekendmobile.android.xflash.model;

//  LWEDatabase.java
//  Xflash
//
//  Created by Todd Presson on 1/5/12.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//  public void onCreate(SQLiteDatabase  )      @over
//
//  public void asynchCopyDatabaseFromAPK() 
//  public boolean checkDatabase() 
//  public boolean closeDatabase() 
//  public String databaseVersion() 
//  public boolean attachDatabase()
//  public boolean detachDatabase()
//  public boolean tableExists(String  ) throws Exception
//
//  public static void logQueryFail(String INTAG,String inException,String inMethod)
//
//  private void logQueryFail(String  ,String  )
//  private class AsyncCopy extends AsyncTask<Void, Void, Boolean>

import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.OutputStream;

import android.content.Context;
import android.content.Intent;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.database.sqlite.SQLiteException;
import android.database.sqlite.SQLiteOpenHelper;
import android.os.AsyncTask;
import android.util.Log;

public class LWEDatabase extends SQLiteOpenHelper
{
    // debug log tag
    private final String MYTAG = "XFlash LWEDatabase";

    // our broadcast intent names
    public static final String COPY_START = "com.longweekendmobile.android.xflash.COPY_START";
    public static final String COPY_START2 = "com.longweekendmobile.android.xflash.COPY_START2";
    public static final String COPY_START3 = "com.longweekendmobile.android.xflash.COPY_START3";
    public static final String COPY_START4 = "com.longweekendmobile.android.xflash.COPY_START4";
    public static final String COPY_SUCCESS = "com.longweekendmobile.android.xflash.COPY_SUCCESS";
    public static final String COPY_FAILURE = "com.longweekendmobile.android.xflash.COPY_FAILURE";
    public static final String DATABASE_READY = "com.longweekendmobile.android.xflash.DATABASE_READY";
                        
    // the Android default onboard database location
    private static final String DB_PATH = "/data/data/com.longweekendmobile.android.xflash/databases/";
    
    // TODO change these from mp3 when files are cut up
    public static final String DB_NAME = "jFlash.mp3";
    public static final String DB_CARD = "jFlash-CARD-1.1.mp3";
    public static final String DB_FTS = "jFlash-FTS-1.1.mp3";
    public static final String DB_EX= "jFlash-EX-1.2.mp3";
    private static final String CARD_ATTACH_NAME = "LWEDATABASETMP";
    private static final String FTS_ATTACH_NAME = "LWEDATABASEFTS"; 
    private static final String EX_ATTACH_NAME = "LWEDATABASEEX"; 
    
    // copy of application context necessary for intent broadcasts
    private final Context myContext;
   
 
    public LWEDatabase(Context context)
    {
        // SQLiteOpenHelper( main context, database name, CursorFactory, int version )
        super(context,DB_NAME,null,1);
        
        // the context passed in the the full Application context
        this.myContext = context;
    }


    @Override
    public void onCreate(SQLiteDatabase db)
    {
        // it is necessary to override this from the SQLiteOpenHelper class
        // it would only be used if we needed to create the tables
        // and insert rows fresh at runtime

        // since we are using a packaged database, this is unnecessary
    }


    // will copy both Xflash databases from the APK to the phone so they 
    // are available uncompressed and writable
    public void asynchCopyDatabaseFromAPK()
    {
        // does the copied database alread exist?
        boolean dbExist = checkDatabase();

        if( dbExist )
        {
            // do nothing - the database has already been copied over
            // on a previous run
            Log.d(MYTAG,"in LWEDatabase.asynchCopy() -- database exists");
            
            Intent myIntent = new Intent(DATABASE_READY);
            myContext.sendBroadcast(myIntent);
        }
        else
        {
            Log.d(MYTAG,"in LWEDatabase.asynchCopy() -- database doesn't exist");
            
            // this will create an empty db in our app's system path
            // which we can overwrite with our database
            getReadableDatabase();

            // fire our Asynch process that will actually
            // copy over the database files
            AsyncCopy tempCopy = new AsyncCopy();
            tempCopy.execute();

        }  // end else clause for if( dbExist )
    
    }  // end asynchCopyDatabase() declaration


    // Check if the database already exists to avoid re-copying the file each time
    // you open the application - return true if it exists, false if it doesn't
    //
    //      *** actually only checks for jFlash.db ***
    public boolean checkDatabase()
    {
        boolean doesExist = false;

        try
        {
            String myPath = DB_PATH + DB_NAME;
            File myFile = new File(myPath);
            
            if( myFile.exists() )
            {
                doesExist = true;
            }
        } 
        catch( SQLiteException e )
        {
            // database does't exist yet.
            Log.d(MYTAG,"checkDatabase() - DB does not exist yet");
        }
        
        return doesExist;

    } 

    // Closes an active database connection
    // At the moment it returns true no matter what
    public boolean closeDatabase()
    {
        SQLiteDatabase tempDao = this.getWritableDatabase();
        tempDao.close();

        return true;
    }

    // Gets open database's version - proprietary to LWE databases (uses version table)
    // return String of the current version, or nil if the database is not open
    public String databaseVersion()
    {
        int tempColumn;
        String tempString;
        Cursor myCursor;
        SQLiteDatabase tempDao = this.getWritableDatabase();

        tempString = "SELECT * FROM main.version LIMIT 1";  
        myCursor = tempDao.rawQuery(tempString,null);
        
        try
        {
            myCursor.moveToFirst();
            tempColumn = myCursor.getColumnIndex("version");
            tempString = myCursor.getString(tempColumn);
            myCursor.close();
        } 
        catch ( Throwable t )
        {
            tempString = null;
            logQueryFail( t.toString() , "databaseVersion()" );
        }

        return tempString;
    
    }  // end databaseVersion() declaration


    // Attaches the accessory jFlash-CARD database
    // Returns true on success, false on failure (even if it failed because
    // the database is already attached)
    public boolean attachDatabase(String toAttach)
    {
        SQLiteDatabase tempDao = this.getWritableDatabase();
        boolean databaseIsOpen = tempDao.isOpen();

        // if the database is open
        if( databaseIsOpen )
        {
            String query = null;
            
            if( toAttach == DB_CARD )
            {
                query = "ATTACH DATABASE \"" + DB_PATH + DB_CARD + "\" AS " + CARD_ATTACH_NAME;
            }
            else if( toAttach == DB_FTS )
            {
                query = "ATTACH DATABASE \"" + DB_PATH + DB_FTS + "\" AS " + FTS_ATTACH_NAME;
            }
            else if( toAttach == DB_EX )
            {
                query = "ATTACH DATABASE \"" + DB_PATH + DB_EX + "\" AS " + EX_ATTACH_NAME;
            }
            else
            {
                Log.d(MYTAG,"ERROR!  Attempted to attach non-existant DB:  " + toAttach);
            }
            
            // do the actual attach
            try
            {
                tempDao.execSQL(query);

                return true;
            } 
            catch (Throwable t)
            {
                Log.d(MYTAG,"ERROR in attachDatabase()");
                Log.d(MYTAG,"      exception:  " + t.toString() );  
                Log.d(MYTAG,".");

                return false;
            }
        }
        else
        {
            Log.d(MYTAG,"ERROR - attempt to call attachDatabase()");
            Log.d(MYTAG,"      - when database is closed");
            Log.d(MYTAG,".");
            
            return false;
        }

    }  // end attachDatabase() declaration


    // detaches the accessory jFlash-CARD database
    // return true on success, false on failure
    public boolean detachDatabase(String toDetach)
    {
        SQLiteDatabase tempDao = this.getWritableDatabase();
        boolean databaseIsOpen = tempDao.isOpen();

        // if the database is open 
        if( databaseIsOpen )
        {
            String query = null;
            
            if( toDetach == DB_CARD )
            {
                query = "DETACH DATABASE \"" + CARD_ATTACH_NAME + "\"";
            }
            else if( toDetach == DB_FTS )
            {
                query = "DETACH DATABASE \"" + FTS_ATTACH_NAME + "\"";
            }
            else if( toDetach == DB_EX )
            {
                query = "DETACH DATABASE \"" + EX_ATTACH_NAME + "\"";
            }
            else
            {
                Log.d(MYTAG,"ERROR!  Attempted to detach non-existant DB:  " + toDetach);
            }

            // do the actual detach
            try
            {
                tempDao.execSQL(query);

                return true;
            } 
            catch (Throwable t)
            {
                Log.d(MYTAG,"ERROR in detachDatabase()");
                Log.d(MYTAG,"Exception:  " + t.toString() );    
                
                return false;
            }
                
        }  // end if( database is open and jFlash-CARD is attached)
        else
        {
            Log.d(MYTAG,"ERROR - attempt to call detachDatabase()");
            Log.d(MYTAG,"      - when database is closed");
        
            return false;
        }

    }  // end detachDatabase() declaration

    
    // detach all attached databases
    public void detachAll()
    {
        String query = "DETACH DATABASE \"" + CARD_ATTACH_NAME + "\"";

        try
        {
                this.getWritableDatabase().execSQL(query);
        } 
        catch (Throwable t)
        {
            Log.d(MYTAG,"ERROR in detachAll()");
            Log.d(MYTAG,"Exception:  " + t.toString() );    
        }

    }  // end detachAll()


    // Checks for the existence of a table name in the sqlite_master table
    // If database is not open, throws an exception
    public boolean tableExists(String tableName) throws Exception
    {
        SQLiteDatabase tempDao = this.getWritableDatabase();
        boolean databaseIsOpen = tempDao.isOpen();

        if( databaseIsOpen )
        {
            int i = 0;
            String[] selectionArgs = new String[] { tableName };
            String query = "SELECT name FROM sqlite_master WHERE type='table' AND name = ?";

            Cursor myCursor = tempDao.rawQuery(query,selectionArgs);

            try
            {
                i = myCursor.getCount();
            } 
            catch (Throwable t)
            {
                // if the query itself fails
                logQueryFail( t.toString() , "tableExists()" );     
                
                return false;
            }
            
            // if we got a valid Cursor and there is at least one row in it
            if( i > 0 )
            {
                myCursor.close();

                return true;
            }
            else
            {
                // if the query returns normally, but with 0 rows
                throw new Exception("EX: table " + tableName + " does not exist!");
            }

        }  // end if( dao.isOpen() )
        else
        {
            Log.d(MYTAG,"ERROR: - tableExists()");
            Log.d(MYTAG,"       - database is not open");

            return false;
        }
    
    }  // end tableExists(String tableName) declaration

    
    // internal method for debugging
    private void logQueryFail(String exception,String method)
    {
        Log.d(MYTAG,"SQL error in " + method );
        Log.d(MYTAG,"most likely NullPointerException from SQL syntax error");
        Log.d(MYTAG,"Exception:  " + exception );
    }

    // public method for use by Peer classes
    public static void logQueryFail(String INTAG,String inException,String inMethod)
    {
        Log.d(INTAG,"SQL error in:  " + inMethod);
        Log.d(INTAG,"    most likely from SQL syntax error");
        Log.d(INTAG,"    EX:  " + inException);
    }


    // our Async class for copying the database files across
    // in the background
    private class AsyncCopy extends AsyncTask<Void, Void, Boolean>
    {
        @Override
        protected Boolean doInBackground(Void... unused)
        {
            // variable to return to onPostExecute(boolen didWork)
            boolean didWork = false;

            // variables necessary for copy operation
            InputStream myInput;
            String outFileName;
            OutputStream myOutput;
            byte[] buffer;
            int length;
            Intent myIntent;

            // this is the actual copy process
            try
            {
                // go through twice, once for each database
                for(int dbCycle = 0; dbCycle < 4; dbCycle++)
                {
                    // pick the right filename to open
                    // fire Intent for UI update
                    if( dbCycle == 0 )
                    {
                        myIntent = new Intent(COPY_START);
                        myContext.sendBroadcast(myIntent);
            
                        // open an empty db to fill
                        myInput = myContext.getAssets().open(DB_NAME);

                        // Path to the just created empty db
                        outFileName = DB_PATH + DB_NAME;
                    }
                    else if( dbCycle == 1 )
                    {
                        myIntent = new Intent(COPY_START2);
                        myContext.sendBroadcast(myIntent);
                        myInput = myContext.getAssets().open(DB_CARD);
                        outFileName = DB_PATH + DB_CARD;
                    }
                    else if( dbCycle == 2 )
                    {
                        myIntent = new Intent(COPY_START3);
                        myContext.sendBroadcast(myIntent);
                        myInput = myContext.getAssets().open(DB_FTS);
                        outFileName = DB_PATH + DB_FTS;
                    }
                    else
                    {
                        myIntent = new Intent(COPY_START4);
                        myContext.sendBroadcast(myIntent);
                        myInput = myContext.getAssets().open(DB_EX);
                        outFileName = DB_PATH + DB_EX;
                    }

                    // open the empty db as the output stream
                    myOutput = new FileOutputStream(outFileName);

                    // transfer bytes from the inputfile to the outputfile
                    buffer = new byte[1024];
                    while ( ( length = myInput.read(buffer) ) > 0 )
                    {
                        myOutput.write(buffer,0,length);
                    }

                    // close the streams
                    myOutput.flush();
                    myOutput.close();
                    myInput.close();
                
                }  // end for loop

                // if we made it here we went through both
                // files without throwing an exception
                didWork = true;
            } 
            catch ( Throwable t )
            {
                Log.d(MYTAG,"asyncCopy fail");
            }
            
            return didWork;

        }  // end doInBackground()

        @Override 
        protected void onPostExecute(Boolean result)
        {
            Intent myIntent;

            // when we're done copying (or on copy fail)
            // send a system broadcast of the result
            if( result )
            {
                myIntent = new Intent(COPY_SUCCESS);
                myContext.sendBroadcast(myIntent);
                    
                myIntent = new Intent(DATABASE_READY);
                myContext.sendBroadcast(myIntent);
            }
            else
            {
                myIntent = new Intent(COPY_FAILURE);
                myContext.sendBroadcast(myIntent);
            }   
            
            Log.d(MYTAG,"copy successful onPostExecute");
        }
    
    }  // end AsyncCopy declaration


    @Override
    public void onUpgrade(SQLiteDatabase db, int oldVersion, int newVersion)
    {

    }

}  // end LWEDatabase class declaration




