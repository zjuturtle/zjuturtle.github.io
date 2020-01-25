---
title: JNI 的多线程回调
date: 2020-01-25 19:11:07
categories:
 - JavaManor
tags:
 - Java
 - JNI

---

在工作中遇到一些 JNI 调用，这里记录一下。需求比较复杂，从 Java 端看，它需要向 JNI 传递一个 Interface 的回调接口对象，然后 JNI 内部去回调它。调用链是：JAVA->JNI->CPP->JAVA(回调)。从上层的 java 代码上看是这样子的

<!--more-->

```java
package com.example;

public Interface ICallBackJava {
    int callBackJava(int[] data);
}

public class FooJava {
    public FooJava(ICallBackJava cb) {
        // 初始化逻辑，需要向 JNI 传递实现 ICallBackJava 接口的对象
    }
    
    public void addInput(int[] data) {
       // 向 JNI 输入一些数据，输入后会异步调用 ICallBackJava 的回调
    }
    
    public void destroy() {
        // 销毁该 FooJava 相关的资源
    }
}

// 以下是调用片段
FooJava foo = new FooJava((data) -> {
                System.out.println("data="+Arrays.toString(data));
                return 0;
            });
int[] input = new int[]{0, 1, 3, 4};
foo.addInput(input);
foo.destroy();
```

## 预备知识

### JNI_OnLoad 函数

如果在 JNI 的 C++ 实现中包含了这个函数，则会在调用 System.loadLibrary 函数的时候会自动调用，在这里可以做一些初始化工作。一个常用的操作是缓存 JavaVM 用于其他线程获取 JNIEnv

### JavaVM 和 JNIEnv

JavaVM是虚拟机在JNI中的表示，一个JVM中只有一个JavaVM对象，这个对象是线程共享的。一般而言，一个程序中只会有一个 JavaVM。JNIEnv类型是一个指向全部JNI方法的指针。该指针只在创建它的线程有效，不能跨线程传递

### Global Reference 和 Local Reference

在 JNI 中使用的引用分为两类：Global/Local Reference 。Local Reference 仅在本地调用期间有效，而 Global Reference 则在显式销毁前都一直有效。

所有传递给 JNI 方法的引用都是 Local 的，并且所有 JNI 返回的引用也都是 Local 的。在程序中我们可以通过 Local Reference 来创造 Global Reference（使用 env->NewGlobalRef 方法），当然也可以把 Global Reference 作为返回值。要注意的是， Local Reference 只在创建它的线程有效，是不能跨线程的，所以最好不要缓存 Local Reference。

## JNI 实现

我个人倾向于将 JNI 的包装类中所有的方法都变成 static 方法（类似于 C 风格），java 端的 JNI 包装类如下

```java
package com.example;

public class ExampleJni {
    static {
        System.loadLibrary("example_jni");
    }
    
    public static native long create(ICallBackJava cb);
    public static native void addInput(long ptr, int[] data);
    public static native void destroy(long ptr);
}

```

对应的 JNI 的头文件我就不详细写了，我们直接来看实现，以及各参数的说明。

```c++
// com_example_ExampleJni.cpp

// 这里专门搞了一个类存储 Java 传过来的对象
struct FooCpp {
    void* callBackObject;
};

static JavaVM *jvm;
static jclass iCallBackClazz;

jint JNI_OnLoad(JavaVM* vm, void* reserved){
    // 把 JavaVM 存下来，在回调函数中通过它来得到 JNIEnv
    jvm = vm;
    JNIEnv *env;
    if (vm->GetEnv(reinterpret_cast<void**>(&env), JNI_VERSION_1_8) != JNI_OK) {
        return JNI_ERR;
    }
    
    // 把回调函数的 jclass 通过 GlobalRef 的方式存下来，因为 jclass (是 Local Reference)不能跨线程
    iCallBackClazz = (jclass)env->NewGlobalRef(env->FindClass("com/example/ICallBackJava"));
    return JNI_VERSION_1_8;
}

int callBackCppFunc(void* usrPtr, int *data, int length) {
    // 通过 JavaVM 获得当前线程的 JNIEnv
    JNIEnv *env;
    jvm->AttachCurrentThread(reinterpret_cast<void **>(&env), nullptr);
    jmethodID cbMethodId = env->GetMethodID(iCallBackClazz, "callBackJava", "([II)I");

    // 将 data 数组转换为 java 中的 int 数组
    jintArray dataArr = env->NewIntArray(dataLength);
    env->SetIntArrayRegion(dataArr, 0, length, data);
    env->CallIntMethod((jobject)usrPtr, cbMethodId, dataArr);

    // 这个必须和 AttachCurrentThread 方法成对出现
    jvm->DetachCurrentThread();
    return 0;    
}

JNIEXPORT jlong JNICALL Java_com_example_create(JNIEnv *env, jclass jclazz, jobject callback) {
    // 将 callBack 对象存起来，注意这里用的是 Global reference。同时 new 了一个 FooCpp 对象，并将其指针（转成了 long）返回
    FooCpp* ptr = new FooCpp;
    ptr->callBackObject = env->NewGlobalRef(callback);
    return (long)ptr;
}

JNIEXPORT void JNICALL Java_com_example_addInput(JNIEnv *env, jclass jclazz, jlong ptr, jintArray data) {
    int* data = (int*)env->GetIntArrayElements(data, nullptr);
    int length = env->GetArrayLength(data);
    
    // 实际上下面这个回调也可以在其他线程进行，这里就直接调用了
    callBackCppFunc((void*)ptr, data, length);
}

JNIEXPORT void JNICALL Java_com_example_destory(JNIEnv *env, jclass jclazz, jlong ptr) {
    FooCpp* fooPtr = (FooCpp*)ptr;
    // 在 create 中创建的 Global Reference 需要销毁
    env->DeleteGlobalRef((jobject)fooPtr->callBackObject);
    delete fooPtr;
}

```

## Java 端实现

```java
public class FooJava {
    private long fooPtr;
    public FooJava(ICallBackJava cb) {
        this.fooPtr = ExampleJni.create(cb);
    }
    
    public void addInput(int[] data) {
       ExampleJni.addInput(this.fooPtr, data);
    }
    
    // 让外部可以显式调用销毁函数，直接在 JNI 层 delete 
    public void destroy() {
        ExampleJni.destroy(this.fooPtr);
        fooPtr = 0L;
    }
}
```

## 参考资料

[Oracle JNI](https://docs.oracle.com/javase/7/docs/technotes/guides/jni/spec/design.html)
