
public class UserFieldsParameter {
	public String type;
	public String name;
	public String namespace;
	public String path;
	public String requireValue;
	public String createValue;
	
	public UserFieldsParameter(String type, String name, String namespace,
			String path, String requireValue, String createValue) {
		super();
		this.type = type;
		this.name = name;
		this.namespace = namespace;
		this.path = path;
		this.requireValue = requireValue;
		this.createValue = createValue;
	}

	public UserFieldsParameter(String type, String name, String namespace, String path) {
		super();
		this.type = type;
		this.name = name;
		this.namespace = namespace;
		this.path = path;
	}
	
	public String getType() {
		return type;
	}
	public void setType(String type) {
		this.type = type;
	}
	public String getName() {
		return name;
	}
	public void setName(String name) {
		this.name = name;
	}
	public String getNamespace() {
		return namespace;
	}
	public void setNamespace(String namespace) {
		this.namespace = namespace;
	}
	public String getPath() {
		return path;
	}
	public void setPath(String path) {
		this.path = path;
	}
	public String getRequireValue() {
		return requireValue;
	}
	public void setRequireValue(String requireValue) {
		this.requireValue = requireValue;
	}
	public String getCreateValue() {
		return createValue;
	}
	public void setCreateValue(String createValue) {
		this.createValue = createValue;
	}
	
}
