/*
<sqlitecompress.c>

http://lserinol.googlepages.com/sqlitecompress

Currently (as sqlite version 3.5.5) has no built-in compression support. 
But you can easily add this feature by yourself. Sqlite has a feature called Loadable Extensions.
Loadable extensions let's you add new features to Sqlite.

First off all, you have to enable loadable extension support when you compile sqlite. 
All you have to do is edit "Makefile.in" file in source directory and  comment out following line:
 # TCC += -DSQLITE_OMIT_LOAD_EXTENSION=1

Now you can compile and install your sqlite package.
After that copy sqlite compression extension file in to sqlite's source directory (eg. sqlite-3.5.5/src).

Then  compile it:
gcc -I`pwd` -shared src/compress.c -o mycompress.so -lz 

now you can copy mycompress.so file in to /lib directory.

This extension adds 2 new functions called mycompress and myuncompress. Now, run sqlite to test it.

# load extension 
sqlite> .load mycompress.so

sqlite> create table test(name varchar(20),surname varchar(20)); 
sqlite> insert into test values(sqlite_compress('This is a sample text'),sqlite_compress('This is a sample text')); 
sqlite> select * from test;
sqlite> select sqlite_uncompress(name),sqlite_uncompress(surname) from test;

Ok, now we have compression support for sqlite database. 
Also, it's possible to use this functions in your applications which is written in C language.
*/

#include <stdlib.h>
#import "sqlite3ext.h"
#include <zlib.h>
#include <assert.h>
SQLITE_EXTENSION_INIT1

static void compressFunc( sqlite3_context *context, int argc, sqlite3_value **argv)
{
  int nIn, nOut;
  long int nOut2;
  const unsigned char *inBuf;
  unsigned char *outBuf;
  assert( argc==1 );
  nIn = sqlite3_value_bytes(argv[0]);
  inBuf = sqlite3_value_blob(argv[0]);
  nOut = 13 + nIn + (nIn+999)/1000;
  outBuf = malloc( nOut+4 );
  outBuf[0] = nIn>>24 & 0xff;
  outBuf[1] = nIn>>16 & 0xff;
  outBuf[2] = nIn>>8 & 0xff;
  outBuf[3] = nIn & 0xff;
  nOut2 = (long int)nOut;
  compress(&outBuf[4], &nOut2, inBuf, nIn);
  sqlite3_result_blob(context, outBuf, nOut2+4, free);
}

static void uncompressFunc( sqlite3_context *context, int argc, sqlite3_value **argv)
{
  unsigned int nIn, nOut, rc;
  const unsigned char *inBuf;
  unsigned char *outBuf;
  long int nOut2;

  assert( argc==1 );
  nIn = sqlite3_value_bytes(argv[0]);
  if( nIn<=4 ){
    return;
  }
  inBuf = sqlite3_value_blob(argv[0]);
  nOut = (inBuf[0]<<24) + (inBuf[1]<<16) + (inBuf[2]<<8) + inBuf[3];
  outBuf = malloc( nOut );
  nOut2 = (long int)nOut;
  rc = uncompress(outBuf, &nOut2, &inBuf[4], nIn);
  if( rc!=Z_OK ){
    free(outBuf);
  }else{
    sqlite3_result_blob(context, outBuf, nOut2, free);
  }
}


int sqlite3_extension_init(sqlite3 *db,char **pzErrMsg,const sqlite3_api_routines *pApi)
{
  SQLITE_EXTENSION_INIT2(pApi)
  sqlite3_create_function(db, "sqlite_compress", 1, SQLITE_UTF8, 0, &compressFunc, 0, 0);
  sqlite3_create_function(db, "sqlite_uncompress", 1, SQLITE_UTF8, 0, uncompressFunc, 0, 0);
  return 0;
}
