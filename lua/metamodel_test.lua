log("--test order of retrieval by--")

--create model classes
lQuery.model.add_class("A")
lQuery.model.add_property("A", "key")

lQuery.model.add_class("B")
lQuery.model.add_property("B", "key")

--add assoc type
lQuery.model.add_link("A", "a", "b", "B")


--create some instances for testing
a1 = lQuery.create("A", {key = "a1"})
a2 = lQuery.create("A", {key = "a2"})
a3 = lQuery.create("A", {key = "a3"})

b1 = lQuery.create("B", {key = "b1"})
b2 = lQuery.create("B", {key = "b2"})
b3 = lQuery.create("B", {key = "b3"})

--add links for a direct test
a1:link("b", b2)
a1:link("b", b1)

--add links for an inverse test
a2:link("b", b3)
a1:link("b", b3)
a3:link("b", b3)


--tests
-- retrieval by class name
log("---class name")
log("   should be a1, a2, a3\n")
lQuery("A"):log("key")

--retrieval by directly created links
log("---direct link")
log("   should be b2, b1, b3\n")
lQuery("A[key=a1]:first"):find("/b"):log("key")

--retrieval by inversely created links
log("---inverse link")
log("   should be a2, a1, a3\n")
lQuery("B[key=b3]:first"):find("/a"):log("key")

log("--end--")