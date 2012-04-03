package com.longweekendmobile.android.xflash.model;

//  LWEDatabase.java
//  Xflash
//
//  Created by Todd Presson on 1/5/12.
//  Copyright 2012 Long Weekend LLC. All rights reserved.
//
//  public void onCreate(SQLiteDatabase  )      @over
//
//  public LWEDatabase(Context  )
//  public LWEDatabase(Context  ,String  ,SQLiteDatabase.CursorFactory  ,int  )
//
//  public static int getDBStatus()
//
//  public void setLocation(int  )
//  public void asynchCopyDatabaseFromAPK() 
//  public boolean checkDatabase() 
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
import android.content.SharedPreferences;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.database.sqlite.SQLiteOpenHelper;
import android.os.AsyncTask;
import android.util.Log;

import com.longweekendmobile.android.xflash.XFApplication;

public class LWEDatabase extends SQLiteOpenHelper
{
    // debug log tag
    private final String MYTAG = "XFlash LWEDatabase";

    // database status constants
    public static final int DATABASE_NO_EXIST = 0;
    public static final int DATABASE_SDCARD = 1;
    public static final int DATABASE_PHONE = 2;

    // our broadcast intent names
    public static final String COPY_START = "com.longweekendmobile.android.xflash.COPY_START";
    public static final String COPY_START2 = "com.longweekendmobile.android.xflash.COPY_START2";
    public static final String COPY_START3 = "com.longweekendmobile.android.xflash.COPY_START3";
    public static final String COPY_START4 = "com.longweekendmobile.android.xflash.COPY_START4";
    public static final String COPY_SUCCESS = "com.longweekendmobile.android.xflash.COPY_SUCCESS";
    public static final String COPY_FAILURE = "com.longweekendmobile.android.xflash.COPY_FAILURE";
    public static final String DATABASE_READY = "com.longweekendmobile.android.xflash.DATABASE_READY";
                        
    // the Android default onboard database location
    private static final String PHONE_PATH = "/data/data/com.longweekendmobile.android.xflash/databases/";
    
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
   
    private int DBlocation;
 
    @Override
    public void onCreate(SQLiteDatabase db)
    {
        // it is necessary to override this from the SQLiteOpenHelper class
        // it would only be used if we needed to create the tables
        // and insert rows fresh at runtime

        // since we are using a packaged database, this is unnecessary
    }


    // constructor -- initialize the database to the local private phone space
    public LWEDatabase(Context context)
    {
        super(context,DB_NAME,null,1);
        
        this.myContext = context;
    }


    // constructor -- initialize the database to the SD card
    public LWEDatabase(Context context, String inPath, SQLiteDatabase.CursorFactory f, int version)
    {
        // this is ugly
        super(context,inPath,null,1);
        
        this.myContext = context;
    }

    // return the database location in Preferences, default to no-exist
    public static int getDBStatus()
    {
        // get a Context, get the SharedPreferences
        XFApplication tempInstance = XFApplication.getInstance();
        SharedPreferences settings = tempInstance.getSharedPreferences(XFApplication.XFLASH_PREFNAME,0);

        // load all settings to user set or default
        int dbStatus = settings.getInt("db_status",DATABASE_NO_EXIST);

        return dbStatus;

    }  // end getDBStatus()


    // set the database location for reference when copying/attaching
    public void setLocation(int inLocation)
    {
        if( ( inLocation < DATABASE_NO_EXIST ) || ( inLocation > DATABASE_PHONE ) )
        {
            throw new RuntimeException("Bad value in LWEDatabase.setLocation(" + inLocation + ")");
        }

        DBlocation = inLocation;

        // set the location in Preferences
        XFApplication tempInstance = XFApplication.getInstance();
        SharedPreferences settings = tempInstance.getSharedPreferences(XFApplication.XFLASH_PREFNAME,0);

        SharedPreferences.Editor editor = settings.edit();
        editor.putInt("db_status",inLocation);
        editor.commit();

    }  // end setLocation()



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
            Intent myIntent = new Intent(DATABASE_READY);
            myContext.sendBroadcast(myIntent);
        }
        else
        {
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
        try
        {
            File checkFile = null;
            
            // get a File object pointing to the appropriate database location
            if( DBlocation == DATABASE_PHONE )
            {
                String myPath = PHONE_PATH + DB_NAME;
                checkFile  = new File(myPath);
            }
            else
            {
                File sdRoot = myContext.getExternalFilesDir(null);
                checkFile = new File(sdRoot,DB_NAME);
            }

            boolean doesExist = checkFile.exists();

            return doesExist;
        } 
        catch(Exception e)
        {
            Log.d(MYTAG,"checkDatabase() - caught exception:  " + e.toString() );
            throw new RuntimeException("problem: LWEDatabase.checkDatabase() - check Log");
        }
        
    }  // end checkDatabase()


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


    // Attaches auxiliary databases by database name
    // Returns true on success, false on failure (even if it failed because
    // the database is already attached)
    public boolean attachDatabase(String toAttach)
    {
        SQLiteDatabase tempDao = this.getWritableDatabase();
        boolean databaseIsOpen = tempDao.isOpen();

        String attachPath = null;
        
        if( DBlocation == DATABASE_PHONE )
        {
            attachPath = PHONE_PATH;  
        }
        else
        {
            File sdRoot = myContext.getExternalFilesDir(null);
            attachPath = sdRoot + "/";
        }

        // if the database is open
        if( databaseIsOpen )
        {
            String query = null;
            
            if( toAttach == DB_CARD )
            {
                query = "ATTACH DATABASE \"" + attachPath + DB_CARD + "\" AS " + CARD_ATTACH_NAME;
            }
            else if( toAttach == DB_FTS )
            {
                query = "ATTACH DATABASE \"" + attachPath + DB_FTS + "\" AS " + FTS_ATTACH_NAME;
            }
            else if( toAttach == DB_EX )
            {
                query = "ATTACH DATABASE \"" + attachPath + DB_EX + "\" AS " + EX_ATTACH_NAME;
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


    // detaches auxiliary databases - return true on success, false on failure
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

            File sdRoot = myContext.getExternalFilesDir(null);
        
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

                        if( DBlocation == DATABASE_PHONE )
                        {
                            outFileName = PHONE_PATH + DB_NAME;
                        }
                        else
                        {
                            outFileName = sdRoot + "/" + DB_NAME;
                        }
                    }
                    else if( dbCycle == 1 )
                    {
                        myIntent = new Intent(COPY_START2);
                        myContext.sendBroadcast(myIntent);
                        myInput = myContext.getAssets().open(DB_CARD);
                        
                        if( DBlocation == DATABASE_PHONE )
                        {
                            outFileName = PHONE_PATH + DB_CARD;
                        }
                        else
                        {
                            outFileName = sdRoot + "/" + DB_CARD;
                        }
                    }
                    else if( dbCycle == 2 )
                    {
                        myIntent = new Intent(COPY_START3);
                        myContext.sendBroadcast(myIntent);
                        myInput = myContext.getAssets().open(DB_FTS);
                        
                        if( DBlocation == DATABASE_PHONE )
                        {
                            outFileName = PHONE_PATH + DB_FTS;
                        }
                        else
                        {
                            outFileName = sdRoot + "/" + DB_FTS;
                        }
                    }
                    else
                    {
                        myIntent = new Intent(COPY_START4);
                        myContext.sendBroadcast(myIntent);
                        myInput = myContext.getAssets().open(DB_EX);
                        
                        if( DBlocation == DATABASE_PHONE )
                        {
                            outFileName = PHONE_PATH + DB_EX;
                        }
                        else
                        {
                            outFileName = sdRoot + "/" + DB_EX;
                        }
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
                Log.d(MYTAG,t.toString());
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

        }  // end onPostExecute()
    
    }  // end AsyncCopy declaration


    @Override
    public void onUpgrade(SQLiteDatabase db, int oldVersion, int newVersion)
    {

    }

}  // end LWEDatabase class declaration




