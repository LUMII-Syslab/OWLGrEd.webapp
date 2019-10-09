import java.lang.Class;
import java.lang.reflect.Method;
import java.io.*;

public class JavaClassExecuterPipe {
	public static void main(String args[]) {
		java.util.Scanner scanner = new java.util.Scanner(System.in, "UTF-8").useDelimiter("\\x00");
		try {
			for (;;) {
				String className = scanner.next();
				
				//System.err.println("got className: " + className);
				

				String publicStaticMethodName = scanner.next();
				//System.err.println("got publicStaticMethodName: " + publicStaticMethodName);

				String stringArg = scanner.next();
				//System.err.println("got stringArg: " + stringArg);

				// TODO add exception catching
				try {
					Class c = Class.forName(className);
					Method m = c.getMethod(publicStaticMethodName, String.class);
					Object returned_obj = m.invoke(null, stringArg);

					String res = returned_obj.toString();
					// System.err.println("res is: " + res);
					
					System.out.print("no_error\0");

					// result string is returned through System.out.println
					// the "\0" at the end signifies that result is finished transmitting
					PrintWriter out = new PrintWriter(new OutputStreamWriter(System.out, "UTF-8"));
					out.print(res + "\0");
					out.flush();
				} catch (Throwable t) {
					System.err.println("exception in java pipe " + t);

					// pass details to lua
					System.out.print("error\0");
					t.printStackTrace(System.out);
					System.out.print("\0");
				}
			}
		} catch(Throwable t) {
			System.err.println("terminal exception in java pipe, closing " + t);

			// pass details to lua
			System.out.print("terminal_error\0");
			t.printStackTrace(System.out);
			System.out.print("\0");
		}
		finally {
			scanner.close();
		}
	}
}