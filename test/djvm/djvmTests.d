import djvm;
import jni;

version(unittest) {

	DJvm testVm;

 	DJvm getOrCreate() {
		if (testVm is null) {
			testVm = new DJvm("");
		}
		return testVm;
	}

	// Interact with ByteBuffer (in every VM and has get / put to test both ways)
	unittest {
		DJvm djvm = getOrCreate();
		JClass bbCls = djvm.findClass("java.nio.ByteBuffer");

		JStaticMethod allocate = bbCls.getStaticMethod("allocate", JniSig!(["int"], "java.nio.ByteBuffer"));
		jobject buffer = allocate.callObject(1024);

		JMethod putInt = bbCls.getMethod("putInt", JniSig!(["int"], "java.nio.ByteBuffer"));
		JMethod getInt = bbCls.getMethod("getInt", JniSig!([], "int"));
		JMethod flip = bbCls.getMethod("flip", JniSig!([], "java.nio.Buffer"));

		putInt.callObject(buffer, 1234);
		flip.callObject(buffer);
		int result = getInt.callInt(buffer);

		assert(1234 == result, "Did not get out what I put in");
	}

	// Test error handling on bad lookups
	unittest {
		DJvm djvm = getOrCreate();
		JClass badCls = djvm.findClass("java.does.not.Exist");

		assert(badCls is null);

		JClass bbCls = djvm.findClass("java.nio.ByteBuffer");

	}

	// Test out the signature generator
	unittest {
		auto sig = JniSig!(["int"], "void");
		assert(sig == "(I)V", "Did not get out what I put in: " ~ sig);
	}

	// Test out the type generator
	unittest {
		auto classType = JniType!("java.io.PrintStream");
		assert(classType == "Ljava/io/PrintStream;", "Did not get out what I put in: " ~ classType);
	}
}
