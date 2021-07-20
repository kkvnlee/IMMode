//
//  CJLOrderFile.m
//  GRGame
//
//  Created by xunni zou on 2021/3/30.
//  Copyright © 2021 duoyi. All rights reserved.
//

#import "CJLOrderFile.h"
#import <dlfcn.h>
#import <libkern/OSAtomicQueue.h>
#import <pthread.h>

//原子队列，其目的是保证写入安全，线程安全
static  OSQueueHead queue = OS_ATOMIC_QUEUE_INIT;
static BOOL collectFinished = NO;

//定义符号结构体，以链表的形式
typedef struct {
    void *pc;
    void *next;
}CJLNode;

/*
 - start：起始位置
 - stop：并不是最后一个符号的地址，而是整个符号表的最后一个地址，最后一个符号的地址=stop-4（因为是从高地址往低地址读取的，且stop是一个无符号int类型，占4个字节）。stop存储的值是符号的
 */
void __sanitizer_cov_trace_pc_guard_init(uint32_t *start,
                                                    uint32_t *stop) {
    static uint64_t N;
    if (start == stop || *start) return;
    printf("INIT: %p - %p\n", start, stop);
    for (uint32_t *x = start; x < stop; x++) {
        *x = ++N;
    }

}

/*
 可以全面hook方法、函数、以及block调用，用于捕捉符号，是在多线程进行的，这个方法中只存储pc，以链表的形式

 - guard 是一个哨兵，告诉我们是第几个被调用的
 */
void __sanitizer_cov_trace_pc_guard(uint32_t *guard) {
//    if (!*guard) return;//将load方法过滤掉了，所以需要注释掉

    //获取PC
    /*
     - PC 当前函数返回上一个调用的地址
     - 0 当前这个函数地址，即当前函数的返回地址
     - 1 当前函数调用者的地址，即上一个函数的返回地址
    */
    void *PC = __builtin_return_address(0);
    //创建node，并赋值
    CJLNode *node = malloc(sizeof(CJLNode));
    *node = (CJLNode){PC, NULL};

    //加入队列
    //符号的访问不是通过下标访问，是通过链表的next指针，所以需要借用offsetof（结构体类型，下一个的地址即next）
    OSAtomicEnqueue(&queue, node, offsetof(CJLNode, next));
}

extern void getOrderFile(void(^completion)(NSString *orderFilePath)){

    collectFinished = YES;
    __sync_synchronize();
    NSString *functionExclude = [NSString stringWithFormat:@"_%s", __FUNCTION__];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //创建符号数组
        NSMutableArray<NSString *> *symbolNames = [NSMutableArray array];

        //while循环取符号
        while (YES) {
            //出队
            CJLNode *node = OSAtomicDequeue(&queue, offsetof(CJLNode, next));
            if (node == NULL) break;

            //取出PC,存入info
            Dl_info info;
            dladdr(node->pc, &info);
//            printf("%s \n", info.dli_sname);

            if (info.dli_sname) {
                //判断是不是OC方法，如果不是，需要加下划线存储，反之，则直接存储
                NSString *name = @(info.dli_sname);
                BOOL isObjc = [name hasPrefix:@"+["] || [name hasPrefix:@"-["];
                NSString *symbolName = isObjc ? name : [@"_" stringByAppendingString:name];
                [symbolNames addObject:symbolName];
            }

        }

        if (symbolNames.count == 0) {
            if (completion) {
                completion(nil);
            }
            return;
        }

        //取反（队列的存储是反序的）
        NSEnumerator *emt = [symbolNames reverseObjectEnumerator];

        //去重
        NSMutableArray<NSString *> *funcs = [NSMutableArray arrayWithCapacity:symbolNames.count];
        NSString *name;
        while (name = [emt nextObject]) {
            if (![funcs containsObject:name]) {
                [funcs addObject:name];
            }
        }

        //去掉自己
        [funcs removeObject:functionExclude];

        //将数组变成字符串
        NSString *funcStr = [funcs componentsJoinedByString:@"\n"];
        NSLog(@"Order:\n%@", funcStr);

        //字符串写入文件
        NSString *filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"cjl.order"];
        NSData *fileContents = [funcStr dataUsingEncoding:NSUTF8StringEncoding];
        BOOL success = [[NSFileManager defaultManager] createFileAtPath:filePath contents:fileContents attributes:nil];
        if (completion) {
            completion(success ? filePath : nil);
        }
    });
}
