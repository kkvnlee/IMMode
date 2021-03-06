#Key_Value存储


##[MMKV](https://github.com/tencent/mmkv/tree/v1.0.16)

MMKV 是基于 mmap 内存映射的 key-value 组件，底层序列化/反序列化使用 protobuf 实现.

###MMKV 原理

- 内存准备

	通过 mmap 内存映射文件，提供一段可供随时写入的内存块，App 只管往里面写数据，由操作系统负责将内存回写到文件，不必担心 crash 导致数据丢失。
- 数据组织

	数据序列化方面我们选用 protobuf 协议，pb 在性能和空间占用上都有不错的表现。
- 写入优化
	考虑到主要使用场景是频繁地进行写入更新，我们需要有增量更新的能力。我们考虑将增量 kv 对象序列化后，append 到内存末尾。
- 空间增长

	使用 append 实现增量更新带来了一个新的问题，就是不断 append 的话，文件大小会增长得不可控。我们需要在性能和空间上做个折中。
	
###适用场景

1、高性能 实时写入。由于通过mmap内存映射，是由操作系统将数据写入文件，不必担心crash，所以写数据更加安全，使用于重要数据写入本地的操作；
2、一般情况下，访问效率要比SQLite读写效率高两倍，也可以使用于频繁读写的模块。

不适合大文件操作，MMKV 在内存里缓存了所有的 key-value，在总大小比较大的情况下（例如 100M+），App 可能会爆内存，触发重整回写时，写入速度也会变慢。


####mmap
文件映射是将文件的磁盘扇区映射到进程的虚拟内存空间的过程。一旦被映射，您的应用程序就会访问这个文件，就好像它完全驻留在内存中一样（不占用内存，使用的是虚拟内存）。当您从映射的文件指针读取数据时，将在适当的数据中的内核页面并将其返回给您的应用程序。
