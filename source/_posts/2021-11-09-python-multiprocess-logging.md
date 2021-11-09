---
title: Python 在多进程中使用 logging
date: 2021-11-09 22:16:14
categories:
 - TechChatter
tags:
 - Python
 - logging
 - multiprocess
---

这一回我想记录一下 python 的多进程日志记录

<!--more-->

众所周知 Python 的多线程有 GIL，对于计算密集型的任务，只能用多进程。随之而来的问题就是如何在多进程下进行日志输出。在 python 的[官方文档](https://docs.python.org/3/howto/logging-cookbook.html)中有提到，并且提供了例程。

官方文档中的思路是单独使用一个进程/线程来通过 `multiprocess.Queue` 来接受其他进程提交的日志，再输出。`logging.handlers` 中有专门的 `QueueHandler`，将其他进程的 `logger` 指定成 `QueueHandler` 就可以了。我对提供的例程进行了一定的修改，贴在下面

```python
# logger_ext.py
import logging
import logging.handlers
from multiprocessing import Queue

# Logging from multiprocess, check https://docs.python.org/3/howto/logging-cookbook.html
log_queue = Queue()

def logger_runloop(log_file:str=None):
    root = logging.getLogger()
    if log_file:
        h = logging.FileHandler(log_file)
    else:
        h = logging.StreamHandler()
    f = logging.Formatter('%(asctime)s %(processName)-10s %(name)s %(levelname)-8s %(message)s')
    h.setFormatter(f)
    root.addHandler(h)
    root.setLevel(logging.INFO)
    while True:
        log = log_queue.get()
        if log is None:
            break
        logger = logging.getLogger(log.name)
        logger.handle(log)

def end_log():
    log_queue.put(None)

def get_logger(logger_name:str = '') -> logging.Logger:
    root = logging.getLogger()
    if len(root.handlers) == 0:
        qh = logging.handlers.QueueHandler(log_queue)
        root.addHandler(qh)
        root.setLevel(logging.INFO)
    return logging.getLogger(logger_name)
```

然后这是调用方式

```python
#main.py

from multiprocessing import Process
from app.utils.logger_ext import logger_runloop, end_log, get_logger

# Make sure logger run loop start before you import anything else
logger_process = Process(target=logger_runloop)
logger_process.start()


logger = get_logger()
logger.info('test log')

end_log()
logger_process.join()
```
