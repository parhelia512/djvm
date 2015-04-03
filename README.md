djvm
====

[![Gitter](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/jamesmahler/djvm?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

Copyright 2015 James Mahler  
Licensed under the terms of the MIT license - See [LICENSE](LICENSE)

Allows for access to Java JVM from D.  Provide D'esk interfaces as the C interaction into JNI is messy to say the least.  This is a slow work in progress.

Motivation
----------
The main motivation behind this is to provide simple access to things that run on the JVM.  Two possibilities that come up immediately are JDBC and Hadoop.  Using JNI from C/C++ to embed a JVM into an application is one of the ways to provide database access.  To utilize technologies like HSQLDB, I believe it is currently the only way.

Getting Started
---------------
Requirements:
* Java VM (if using package manager, make sure to install -dev packages)
* dmd
* LD_LIBRARY_PATH pointing to jvm install (/usr/lib/jvm/java-7-openjdk-amd64/jre/lib/amd64/server for example)

Compiling (For now I just do this in the source/djvm directory):
* dub

Example
-------
Here is an example usage of the D api:
```d
DJvm djvm = new DJvm("");
scope(exit) {
	djvm.destroyJvm();
}

JClass systemCls = djvm.findClass("java.lang.System");
JClass printCls = djvm.findClass("java.io.PrintStream");

JStaticField field = systemCls.getStaticField("out", JniType!("java.io.PrintStream"));
jobject obj = field.getObject();

JMethod method = printCls.getMethod("println", JniSig!(["int"], "void"));
method.callVoid(obj, 100);
```

Work
----
- [x] Port JNI example from C to D
- [x] Get a jni.d that compiles
- [x] Fix seg faults
- [x] Use dub
- [x] Unit tests using ByteBuffer to check bi-directional
- [ ] Clean up dub to work on other boxes to run tests (this should be dmd sc.ini not in dub to do link flags)
- [x] Make pretty wrapper
- [ ] Tons of error handling (aka nulls on unsuccessful finds instead of segfaults on usage)
- [ ] Make pretty JDBC wrapper

