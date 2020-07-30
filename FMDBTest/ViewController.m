//
//  ViewController.m
//  FMDBTest
//
//  Created by huxinguang on 2016/12/21.
//  Copyright © 2016年 huxinguang. All rights reserved.
//

#import "ViewController.h"
#import "CBCourseModel.h"

#import <objc/runtime.h>

@interface ViewController (){

    NSMutableArray *dataArr;
    
    
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *dbPath = [documentPath stringByAppendingPathComponent:@"comblive.db"];
    
    FMDatabase *db = [FMDatabase databaseWithPath:dbPath];
    if (![db open]) {
        NSLog(@"Could not open db.");
        return ;
    }
    
    NSLog(@"*********%@",dbPath);

    dataArr = [[NSMutableArray alloc]init];
    
    NSDate *date1 = [NSDate date];
    
    for (int i = 0; i < 1000; i++) {//数组插入1000条数据耗时大约0.0012秒
        CBCourseModel *cm = [[CBCourseModel alloc]init];
        cm.course_id = i;
        cm.name = [NSString stringWithFormat:@"课程%d",i];
        cm.update_time = 10000000000+i;
        [dataArr addObject:cm];
    }
    
    NSDate *date2 = [NSDate date];
    NSTimeInterval time = [date2 timeIntervalSince1970] - [date1 timeIntervalSince1970];
    
    NSLog(@"插入数组用时%.8f秒",time);
    
    //3.使用如下语句，如果打开失败，可能是权限不足或者资源不足。通常打开完操作操作后，需要调用 close 方法来关闭数据库。在和数据库交互 之前，数据库必须是打开的。如果资源或权限不足无法打开或创建数据库，都会导致打开失败。
    if ([db open])
    {
        //4.创建表
        BOOL result = [db executeUpdate:@"CREATE TABLE IF NOT EXISTS t_course (id integer PRIMARY KEY AUTOINCREMENT, name text, course_id integer,update_time long long);"];
        if (result)
        {
            NSLog(@"创建表成功");
        }
    }
    
    [db close];
    
    //**********************************不使用事务*****************************
 
//    [db open];
//    for (int i = 0; i < dataArr.count; i++) {//数据库插入1000条数据耗时大约0.65秒
//        BOOL result = [db executeUpdate:[NSString stringWithFormat:@"INSERT INTO t_course(name,course_id,update_time) VALUES('姓名%d',%d,%lld)",i,i,(100000000000+(long long)i)]];
//        if (!result) {
//            NSLog(@"插入%d失败",i);
//        }
//    }
//    
//    [db close];
//    
    
    
    //***********************************使用事务******************************
    //当批量更新数据库的时候应该利用事务处理,使用事务处理就是将所有任务执行完成以后将结果一次性提交到数据库，如果此过程出现异常则会执行回滚操作，这样节省了大量的重复提交环节所浪费的时间
    [db open];
    [db beginTransaction];
    BOOL needRollBack = NO;
    @try {
        for (int i = 0; i<dataArr.count; i++) {//数据库插入1000条数据耗时大约0.01秒
            CBCourseModel *cm = dataArr[i];
            BOOL result = [db executeUpdate:[NSString stringWithFormat:@"INSERT INTO t_course(name,course_id,update_time) VALUES('%@',%d,%lld)",cm.name,cm.course_id,cm.update_time]];
            if (!result) {
                NSLog(@"插入失败1");
            }
        }
    }
    
    @catch (NSException *exception) {
        needRollBack = YES;
        [db rollback];
    }
    
    @finally {
        if (!needRollBack) {
            if ([db commit]) {
                NSLog(@"更新提交成功");
            }
        }
    }
    
    [db close];
    
    NSDate *date3 = [NSDate date];
    time = [date3 timeIntervalSince1970] - [date2 timeIntervalSince1970];
    NSLog(@"插入数据库用时%.8f秒",time);
    
    
    
    //根据条件查询
    
    [db open];
//    FMResultSet *resultSet = [db executeQuery:[NSString stringWithFormat:@"SELECT * FROM t_course WHERE course_id<%d;",10]];
    FMResultSet *resultSet = [db executeQuery:[NSString stringWithFormat:@"SELECT * FROM t_course WHERE course_id<%d ORDER BY course_id DESC;",10]];
    
    //遍历结果集合
    NSMutableArray *filteredArr = [[NSMutableArray alloc]init];
    
    while ([resultSet  next])
    {
        CBCourseModel *cm = [[CBCourseModel alloc]init];
        cm.course_id = [resultSet intForColumn:@"course_id"];
        cm.name = [resultSet stringForColumn:@"name"];
        cm.update_time = [resultSet longLongIntForColumn:@"update_time"];
        [filteredArr addObject:cm];
    }
    [resultSet close];
    
    NSDate *date4 = [NSDate date];
    time = [date4 timeIntervalSince1970] - [date3 timeIntervalSince1970];
    NSLog(@"查询数据库用时%.8f秒",time);
    
    //更新
    [db open];
    BOOL result = [db executeUpdate:[NSString stringWithFormat:@"UPDATE t_course SET name='%@' WHERE course_id=%d",@"course 0",0]];
    if (result) {
        NSLog(@"更新成功");
    }
    [db close];
    //删除
    [db open];
    result = [db executeUpdate:[NSString stringWithFormat:@"DELETE FROM t_course WHERE course_id=%d",1]];
    if (result) {
        NSLog(@"删除成功");
    }
    [db close];
    
    
    
}




- (NSArray *)getProperties:(Class)cls{

    // 获取当前类的所有属性
    unsigned int count;// 记录属性个数
    objc_property_t *properties = class_copyPropertyList(cls, &count);
    // 遍历
    NSMutableArray *mArray = [NSMutableArray array];
    for (int i = 0; i < count; i++) {
        // objc_property_t 属性类型
        objc_property_t property = properties[i];
        // 获取属性的名称 C语言字符串
        const char *cName = property_getName(property);
        // 转换为Objective C 字符串
        NSString *name = [NSString stringWithCString:cName encoding:NSUTF8StringEncoding];
        [mArray addObject:name];
    }
    
    free(properties);
    
    return mArray;
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
