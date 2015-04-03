import std.string;
import std.array;
import core.stdc.stdarg;

import jni;

// Mixin helper methods

private string getJtype(string type) {
	if (type == "Void") {
		return "void";
	}
	return "j" ~ toLower(type);
}

private string generateFieldMethods(string[] types, string extra) {
	string rtn = "";
	foreach (ref string type; types) {
		rtn ~= getJtype(type) ~ " get" ~ type ~ "() { return (*env).Get" ~ extra ~ type ~ "Field(env, cls, fieldId); }\n";
		rtn ~= "void set" ~ type ~ "(" ~ getJtype(type) ~ " value) { return (*env).Set" ~ extra ~ type ~ "Field(env, cls, fieldId, value); }\n";
	}
	return rtn;
}

private string generateMethodCalls(string[] types, string extra, string extraMethodArgs, string callArg) {
	string rtn = "";
	foreach (ref string type; types) {
		rtn ~= getJtype(type) ~ " call" ~ type ~ "(" ~ extraMethodArgs ~ "...) {\n";
		rtn ~= "va_list args;\n";
		rtn ~= "va_start(args, __va_argsave);\n";
		if (type == "Void") {
			rtn ~= "(*env).Call" ~ extra ~ type ~ "MethodV(env, " ~ callArg	~ ", methodId, args);\n";
		} else {
			rtn ~= "return (*env).Call" ~ extra ~ type ~ "MethodV(env, " ~ callArg ~ ", methodId, args);\n";
		}
		rtn ~= "}\n";
	}
	return rtn;
}

string typeToJniType(string type) {
	string rtn = "";
	if (type[$-1] == ']' && type[$-2] == '[') {
		rtn ~= "[";
		type = type[0 .. $-2];
	}

	switch (type) {
		case "boolean":
			return rtn ~ "Z";
		case "byte":
			return rtn ~ "B";
		case "char":
			return rtn ~ "C";
		case "short":
			return rtn ~ "S";
		case "int":
			return rtn ~ "I";
		case "long":
			return rtn ~ "J";
		case "float":
			return rtn ~ "F";
		case "double":
			return rtn ~ "D";
		case "void":
			return "V";
		default:
			return rtn ~ "L" ~ type.replace(".", "/") ~ ";";
	}
}

template JniType(string type) {
	const JniType = typeToJniType(type);
}

template JniSig(string[] args, string returnType) {
	string toJni() {
		string rtn = "(";

		foreach (ref string arg; args) {
			rtn ~= typeToJniType(arg);
		}
		rtn ~= ")" ~ typeToJniType(returnType);

		return rtn;
	}

	const JniSig = toJni();
}

// Wrapped types

class JMethod {
	private JavaVM* jvm;
	private JNIEnv* env;
	private jclass cls;
	private jmethodID methodId;

	this(JavaVM* jvm, JNIEnv* env, jclass cls, jmethodID methodId) {
		this.jvm = jvm;
		this.env = env;
		this.cls = cls;
		this.methodId = methodId;
	}

	mixin(generateMethodCalls(["Void", "Object", "Boolean", "Byte", "Char", "Short", "Int", "Long", "Float", "Double"], "", "jobject obj, ", "obj"));
}

class JStaticMethod {
	private JavaVM* jvm;
	private JNIEnv* env;
	private jclass cls;
	private jmethodID methodId;

	this(JavaVM* jvm, JNIEnv* env, jclass cls, jmethodID methodId) {
		this.jvm = jvm;
		this.env = env;
		this.cls = cls;
		this.methodId = methodId;
	}

	mixin(generateMethodCalls(["Void", "Object", "Boolean", "Byte", "Char", "Short", "Int", "Long", "Float", "Double"], "Static", "", "cls"));
}


class JField {
	private JavaVM* jvm;
	private JNIEnv* env;
	private jclass cls;
	private jfieldID fieldId;

	this(JavaVM* jvm, JNIEnv* env, jclass cls, jfieldID fieldId) {
		this.jvm = jvm;
		this.env = env;
		this.cls = cls;
		this.fieldId = fieldId;
	}

	mixin(generateFieldMethods(["Object", "Boolean", "Byte", "Char", "Short", "Int", "Long", "Float", "Double"], ""));
}

class JStaticField {
	private JavaVM* jvm;
	private JNIEnv* env;
	private jclass cls;
	private jfieldID fieldId;

	this(JavaVM* jvm, JNIEnv* env, jclass cls, jfieldID fieldId) {
		this.jvm = jvm;
		this.env = env;
		this.cls = cls;
		this.fieldId = fieldId;
	}

	mixin(generateFieldMethods(["Object", "Boolean", "Byte", "Char", "Short", "Int", "Long", "Float", "Double"], "Static"));
}

class JClass {
	private JavaVM* jvm;
	private JNIEnv* env;
	private jclass cls;

	this(JavaVM* jvm, JNIEnv* env, jclass cls) {
		this.jvm = jvm;
		this.env = env;
		this.cls = cls;
	}

	JField getField(string name, string signature) {
		jfieldID fid = (*env).GetFieldID(env, cls, toStringz(name), toStringz(signature));
		if (fid is null) {
			return null;
		}
		return new JField(jvm, env, cls, fid);
	}

	JStaticField getStaticField(string name, string signature) {
		jfieldID fid = (*env).GetStaticFieldID(env, cls, toStringz(name), toStringz(signature));
		if (fid is null) {
			return null;
		}
		return new JStaticField(jvm, env, cls, fid);
	}

	JMethod getMethod(string name, string signature) {
		jmethodID mid = (*env).GetMethodID(env, cls, toStringz(name), toStringz(signature));
		if (mid is null) {
			return null;
		}
		return new JMethod(jvm, env, cls, mid);
	}
	
	JStaticMethod getStaticMethod(string name, string signature) {
		jmethodID mid = (*env).GetStaticMethodID(env, cls, toStringz(name), toStringz(signature));
		if (mid is null) {
			return null;
		}
		return new JStaticMethod(jvm, env, cls, mid);
	}
}

class DJvm {
	private JavaVM* jvm;
	private JNIEnv* env;

	this(string classpath) {
		JavaVMInitArgs vm_args;
		JavaVMOption[] options = new JavaVMOption[1];
		options[0].optionString = cast(char*) toStringz("-Djava.class.path=" ~ classpath);

		vm_args.version_ = JNI_VERSION_1_6;
		vm_args.nOptions = 1;
		vm_args.options = options.ptr;
		vm_args.ignoreUnrecognized = false;

		JNI_CreateJavaVM(&jvm, cast(void**) &env, &vm_args);
	}

	JClass findClass(string name) {
		jclass cls = (*env).FindClass(env, toStringz(name.replace(".", "/")));
		if (cls is null) {
			return null;
		}
		return new JClass(jvm, env, cls);
	}

	void destroyJvm() {
		(*jvm).DetachCurrentThread(jvm);
		(*jvm).DestroyJavaVM(jvm);
	}
}
