import djvm;
import jni;

version(unittest) {

	unittest {
		DJvm djvm = new DJvm("");

		auto sig = JniSig!(["int"], "void");
		assert(sig == "(I)V", "Did not get out what I put in: " ~ sig);
		
		auto classType = JniType!("java.io.PrintStream");
		assert(classType == "Ljava/io/PrintStream;", "Did not get out what I put in: " ~ classType);
	}
}
