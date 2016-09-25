//
//  Table.h
//  STReader
//
//  Created by StriEver on 16/8/19.
//  Copyright © 2016年 StriEver. All rights reserved.
//

#ifndef Table_h
#define Table_h
#import "DBDefine.h"
//#define ST_TB_CREATE_BOOKINFO   @"CREATE TABLE IF NOT EXISTS bookInfoTable(bookId text  primary key,name text,localPath tetx,readerCount int,smallFontPage int, midFontPage int,plusFontPage int,fileName BLOB)"

#define ST_DB_CREATE_BOOKCHAPTERINFO @"CREATE TABLE IF NOT EXISTS bookChapterInfo (bookId text primary key, bookName tetx,Chapter integer,SecChapter integer,currentPageIdx integer)"

#define ST_TB_CREATE_CFG     @"CREATE TABLE IF NOT EXISTS readerCfg (cfgId  text , state INTEGER ,fontSize Single)"
/*
 "file_version" : "1",
 "id" : 15,
 "hot_sort" : 10010,
 "pic" : "GC\/M00\/01\/44\/CqIjt1fWYaaAewLAAAGsjM1gnJU06.jpeg",
 "name" : "温病条辨",
 "path" : "GC\/M00\/01\/9A\/CqIjt1fY6YuATRynAAWZ_RDaSqw2552.gc"
 */
#define ST_TB_CREATE_BOOKINFO  @"CREATE TABLE IF NOT EXISTS bookInfoTable (bookId text primary key,file_version text,hot_sort text,pic text,name text,path text,time double)"
#endif /* Table_h */
