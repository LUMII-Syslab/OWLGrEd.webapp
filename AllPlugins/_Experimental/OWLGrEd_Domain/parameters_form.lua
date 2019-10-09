module(..., package.seeall)
require "dialog_utilities"

function show_main_window()
	local close_button = lQuery.create("D#Button", {
		caption = "Close"
		,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.close_main_window()")
	})
	
	local form = lQuery.create("D#Form", {
		id = "main window"
		,caption = "OWL2"
		,minimumWidth = "250"
		,defaultButton = close_button
		,eventHandler = utilities.d_handler("Close", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.close_main_window()")
		,component = {
			lQuery.create("D#VerticalBox", {
				horizontalAlignment = -1
				,verticalAlignment = -1
				,component = {
					lQuery.create("D#Button", {
						caption = "Profiles..."
						,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.show_profiles_window()")
					})
					,lQuery.create("D#Button", {
						caption = "Load..."
						,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.domain_to_presentation.load_and_visualize()")
					})
				}
			})
			,lQuery.create("D#HorizontalBox", {
				horizontalAlignment = 1
				,component = close_button
			})
		}
	})
	dialog_utilities.show_form(form)
end

function show_parameters_window()
	local current_profile = get_current_profile()
	if current_profile == nil then
		return
	end
	
	lQuery("D#Event"):delete()
	local close_button = lQuery.create("D#Button", {
		caption = "Close"
		,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.close_parameters_window()")
	})

	local form = lQuery.create("D#Form", {
		id = "presentation parameters"
		,caption = "Presentation Parameters"
		,minimumWidth = "700"
		,defaultButton = close_button
		,eventHandler = utilities.d_handler("Close", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.close_parameters_window()")
		,component = {
			lQuery.create("D#TabContainer", {
				component = {
					lQuery.create("D#Tab", {
						caption = "General"
						,horizontalAlignment = -1
						,verticalAlignment = -1
						,component = {
							lQuery.create("D#GroupBox", {
								caption = "Class annotations"
								,horizontalAlignment = -1
								,verticalAlignment = -1
								,maximumWidth = 320
								,maximumHeight = 120
								,component = {
									lQuery.create("D#HorizontalBox", {
										horizontalAlignment = -1
										,verticalAlignment = -1
										,component = {
											lQuery.create("D#GroupBox", {
												caption = "Graphics"
												,horizontalAlignment = -1
												,verticalAlignment = -1
												,component = {
													lQuery.create("D#RadioButton", {
														caption = "No graphics"
														,id = "Class Annotations 0"
														,selected = is_selected("Class Annotations", "0")
														,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.set_state()")
													})
													,lQuery.create("D#RadioButton", {
														caption = "Use graphics"
														,id = "Class Annotations 1"
														,selected = is_selected("Class Annotations", "1")
														,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.set_state()")
													})
													,lQuery.create("D#RadioButton", {
														caption = "Rule:"
														,id = "Class Annotations R"
														,selected = is_selected("Class Annotations", "-1")
														,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.set_state()")
													})
													,lQuery.create("D#InputField", {
														maximumWidth = "100"
														,id = "Class Annotations R"
														,text = get_rule_text("Class Annotations")
													})
												}
											})
											--[[
											,lQuery.create("D#GroupBox", {
												caption = "Force graphics for 1st comment"
												,horizontalAlignment = -1
												,verticalAlignment = -1
												,minimumWidth = 170
												,component = {
													lQuery.create("D#RadioButton", {
														caption = "Yes"
														,id = "Class Annotations Comment 0"
														,selected = is_selected("Class Annotations Comment", "0")
														,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.set_state()")
													})
													,lQuery.create("D#RadioButton", {
														caption = "No"
														,id = "Class Annotations Comment 1"
														,selected = is_selected("Class Annotations Comment", "1")
														,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.set_state()")
													})
													,lQuery.create("D#RadioButton", {
														caption = "Rule:"
														,id = "Class Annotations Comment R"
														,selected = is_selected("Class Annotations Comment", "-1")
														,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.set_state()")
													})
													,lQuery.create("D#InputField", {
														maximumWidth = "100"
													})
												}
											})
											]]
										}
									})
								}
							})
							,lQuery.create("D#GroupBox", {
								caption = "Object Property annotations"
								,horizontalAlignment = -1
								,verticalAlignment = -1
								,maximumWidth = 320
								,maximumHeight = 120
								,component = {
									lQuery.create("D#HorizontalBox", {
										horizontalAlignment = -1
										,verticalAlignment = -1
										,component = {
											lQuery.create("D#GroupBox", {
												caption = "Graphics"
												,horizontalAlignment = -1
												,verticalAlignment = -1
												,component = {
													lQuery.create("D#RadioButton", {
														caption = "No graphics"
														,id = "Object Properties Annotations 0"
														,selected = is_selected("Object Properties Annotations", "0")
														,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.set_state()")
													})
													,lQuery.create("D#RadioButton", {
														caption = "Use graphics"
														,id = "Object Properties Annotations 1"
														,selected = is_selected("Object Properties Annotations", "1")
														,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.set_state()")
													})
													,lQuery.create("D#RadioButton", {
														caption = "Rule:"
														,id = "Object Properties Annotations R"
														,selected = is_selected("Object Properties Annotations", "-1")
														,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.set_state()")
													})
													,lQuery.create("D#InputField", {
														maximumWidth = 100
														,id = "Object Properties Annotations R"
														,text = get_rule_text("Object Properties Annotations")
													})
												}
											})
										}
									})
								}
							})
							,lQuery.create("D#GroupBox", {
								caption = "Data Property annotations"
								,horizontalAlignment = -1
								,verticalAlignment = -1
								,maximumWidth = 320
								,maximumHeight = 120
								,component = {
									lQuery.create("D#HorizontalBox", {
										horizontalAlignment = -1
										,verticalAlignment = -1
										,component = {
											lQuery.create("D#GroupBox", {
												caption = "Graphics"
												,horizontalAlignment = -1
												,verticalAlignment = -1
												,component = {
													lQuery.create("D#RadioButton", {
														caption = "No graphics"
														,id = "Data Properties Annotations 0"
														,selected = is_selected("Data Properties Annotations", "0")
														,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.set_state()")
													})
													,lQuery.create("D#RadioButton", {
														caption = "Use graphics"
														,id = "Data Properties Annotations 1"
														,selected = is_selected("Data Properties Annotations", "1")
														,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.set_state()")
													})
													,lQuery.create("D#RadioButton", {
														caption = "Rule:"
														,id = "Data Properties Annotations R"
														,selected = is_selected("Data Properties Annotations", "-1")
														,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.set_state()")
													})
													,lQuery.create("D#InputField", {
														maximumWidth = 100
														,id = "Data Properties Annotations R"
														,text = get_rule_text("Data Properties Annotations")
													})
												}
											})
										}
									})
								}
							})
							,lQuery.create("D#GroupBox", {
								caption = "Individual annotations"
								,horizontalAlignment = -1
								,verticalAlignment = -1
								,maximumWidth = 320
								,maximumHeight = 120
								,component = {
									lQuery.create("D#HorizontalBox", {
										horizontalAlignment = -1
										,verticalAlignment = -1
										,component = {
											lQuery.create("D#GroupBox", {
												caption = "Graphics"
												,horizontalAlignment = -1
												,verticalAlignment = -1
												,component = {
													lQuery.create("D#RadioButton", {
														caption = "No graphics"
														,id = "Individuals Annotations 0"
														,selected = is_selected("Individuals Annotations", "0")
														,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.set_state()")
													})
													,lQuery.create("D#RadioButton", {
														caption = "Use graphics"
														,id = "Individuals Annotations 1"
														,selected = is_selected("Individuals Annotations", "1")
														,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.set_state()")
													})
													,lQuery.create("D#RadioButton", {
														caption = "Rule:"
														,id = "Individuals Annotations R"
														,selected = is_selected("Individuals Annotations", "-1")
														,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.set_state()")
													})
													,lQuery.create("D#InputField", {
														maximumWidth = 100
														,id = "Individuals Annotations R"
														,text = get_rule_text("Individuals Annotations")
													})
												}
											})
										}
									})
								}
							})
							,lQuery.create("D#HorizontalBox", {
								horizontalAlignment = -1
								,verticalAlignment = -1
								,maximumWidth = 320
								,maximumHeight = 20
								,topMargin = 10
								,component = {
									lQuery.create("D#Label", {
										caption = "Box creation threshold:"
										,topMargin = 3
									})
									,lQuery.create("D#InputField", {
										id = "Box Creation Threshold"
										,text = get_current_value("Box Creation Threshold")
										,maximumWidth = 20
									})
								}
							})
						}
					})
					,lQuery.create("D#Tab", {
						caption = "Classes"
						,horizontalAlignment = -1
						,verticalAlignment = -1
						,component = {
							lQuery.create("D#GroupBox", {
								caption = "Class Restrictions"
								,horizontalAlignment = -1
								,verticalAlignment = -1
								,component = {
									lQuery.create("D#HorizontalBox", {
										horizontalAlignment = -1
										,verticalAlignment = -1
										,component = {
											lQuery.create("D#GroupBox", {
												caption = "Graphics"
												,horizontalAlignment = -1
												,verticalAlignment = -1
												,component = {
													lQuery.create("D#RadioButton", {
														caption = "No graphics"
														,id = "Class Restrictions 0"
														,selected = is_selected("Class Restrictions", "0")
														,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.set_state()")
													})
													,lQuery.create("D#RadioButton", {
														caption = "Use graphics"
														,id = "Class Restrictions 1"
														,selected = is_selected("Class Restrictions", "1")
														,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.set_state()")
													})
													,lQuery.create("D#RadioButton", {
														caption = "Rule:"
														,id = "Class Restrictions R"
														,selected = is_selected("Class Restrictions", "-1")
														,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.set_state()")
													})
													,lQuery.create("D#InputField", {
														maximumWidth = 100
														,id = "Class Restrictions R"
														,text = get_rule_text("Class Restrictions")
													})
												}
											})
											,lQuery.create("D#GroupBox", {
												caption = "Target Box"
												,horizontalAlignment = -1
												,verticalAlignment = -1
												,component = {
													lQuery.create("D#RadioButton", {
														caption = "Create"
														,id = "Class Restrictions Target Box 0"
														,selected = is_selected("Class Restrictions Target Box", "0")
														,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.set_state()")
													})
													,lQuery.create("D#RadioButton", {
														caption = "Existing only"
														,id = "Class Restrictions Target Box 1"
														,selected = is_selected("Class Restrictions Target Box", "1")
														,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.set_state()")
													})
													,lQuery.create("D#RadioButton", {
														caption = "Create for multiple"
														,id = "Class Restrictions Target Box 2"
														,selected = is_selected("Class Restrictions Target Box", "2")
														,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.set_state()")
													})
													,lQuery.create("D#RadioButton", {
														caption = "Rule:"
														,id = "Class Restrictions Target Box R"
														,selected = is_selected("Class Restrictions Target Box", "-1")
														,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.set_state()")
													})
													,lQuery.create("D#InputField", {
														maximumWidth = 100
														,id = "Class Restrictions Target Box R"
														,text = get_rule_text("Class Restrictions Target Box")
													})
												}
											})
											,lQuery.create("D#GroupBox", {
												caption = "Forks"
												,horizontalAlignment = -1
												,verticalAlignment = -1
												,component = {
													lQuery.create("D#RadioButton", {
														caption = "No forks"
														,id = "Class Restrictions Fork 0"
														,selected = is_selected("Class Restrictions Fork", "0")
														,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.set_state()")
													})
													,lQuery.create("D#RadioButton", {
														caption = "Create forks"
														,id = "Class Restrictions Fork 1"
														,selected = is_selected("Class Restrictions Fork", "1")
														,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.set_state()")
													})
													,lQuery.create("D#RadioButton", {
														caption = "Auto-forks"
														,id = "Class Restrictions Fork 2"
														,selected = is_selected("Class Restrictions Fork", "2")
														,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.set_state()")
													})
													,lQuery.create("D#RadioButton", {
														caption = "Rule:"
														,id = "Class Restrictions Fork R"
														,selected = is_selected("Class Restrictions Fork", "-1")
														,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.set_state()")
													})
													,lQuery.create("D#InputField", {
														maximumWidth = 100
														,id = "Class Restrictions Fork R"
														,text = get_rule_text("Class Restrictions Fork")
													})
												}
											})
											,lQuery.create("D#GroupBox", {
												caption = "Extra items"
												,horizontalAlignment = -1
												,verticalAlignment = -1
												,component = {
													lQuery.create("D#CheckBox", {
														caption = "Top-level named classes subclasses of 'Thing'"
														,id = "Class Restrictions Extra Thing"
														,checked = is_selected("Class Restrictions Extra Thing", "1")
														,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.set_checkbox_state()")
													})
													,lQuery.create("D#CheckBox", {
														caption = "Subclass relation to unions of named classes"
														,id = "Class Restrictions Unions"
														,checked = is_selected("Class Restrictions Unions", "1")
														,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.set_checkbox_state()")
													})
													,lQuery.create("D#CheckBox", {
														caption = "Subclass relation from 'and' named class"
														,id = "Class Restrictions And Named"
														,checked = is_selected("Class Restrictions And Named", "1")
														,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.set_checkbox_state()")
													})
													,lQuery.create("D#GroupBox", {
														leftMargin = 25
														,horizontalAlignment = -1
														,verticalAlignment = -1
														,component = {
															lQuery.create("D#RadioButton", {
																caption = "Create source"
																,id = "Class Restrictions And Named Source 0"
																,selected = is_selected("Class Restrictions And Named Source", "0")
																,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.set_state()")
															})
															,lQuery.create("D#RadioButton", {
																caption = "Existing source only"
																,id = "Class Restrictions And Named Source 1"
																,selected = is_selected("Class Restrictions And Named Source", "1")
																,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.set_state()")
															})
															,lQuery.create("D#RadioButton", {
																caption = "Create source from class restrictions"
																,id = "Class Restrictions And Named Source 2"
																,selected = is_selected("Class Restrictions And Named Source", "2")
																,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.set_state()")
															})
															,lQuery.create("D#RadioButton", {
																caption = "Rule:"
																,id = "Class Restrictions And Named Source R"
																,selected = is_selected("Class Restrictions And Named Source", "-1")
																,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.set_state()")
															})
															,lQuery.create("D#InputField", {
																maximumWidth = 100
																,id = "Class Restrictions And Named Source R"
																,text = get_rule_text("Class Restrictions And Named Source")
															})
														}
													})
												}
											})
										}
									})
								}
							})
							,lQuery.create("D#GroupBox", {
								caption = "Property Restrictions"
								,horizontalAlignment = -1
								,verticalAlignment = -1
								,component = {
									lQuery.create("D#HorizontalBox", {
										horizontalAlignment = -1
										,verticalAlignment = -1
										,component = {
											lQuery.create("D#GroupBox", {
												caption = "Graphics"
												,horizontalAlignment = -1
												,verticalAlignment = -1
												,component = {
													lQuery.create("D#RadioButton", {
														caption = "No graphics"
														,id = "Property Restrictions 0"
														,selected = is_selected("Property Restrictions", "0")
														,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.set_state()")
													})
													,lQuery.create("D#RadioButton", {
														caption = "Use graphics"
														,id = "Property Restrictions 1"
														,selected = is_selected("Property Restrictions", "1")
														,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.set_state()")
													})
													,lQuery.create("D#RadioButton", {
														caption = "Rule:"
														,id = "Property Restrictions R"
														,selected = is_selected("Property Restrictions", "-1")
														,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.set_state()")
													})
													,lQuery.create("D#InputField", {
														maximumWidth = 100
														,id = "Property Restrictions R"
														,text = get_rule_text("Property Restrictions")
													})
												}
											})
											,lQuery.create("D#GroupBox", {
												caption = "Target Box"
												,horizontalAlignment = -1
												,verticalAlignment = -1
												,component = {
													lQuery.create("D#RadioButton", {
														caption = "Create"
														,id = "Property Restrictions Target Box 0"
														,selected = is_selected("Property Restrictions Target Box", "0")
														,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.set_state()")
													})
													,lQuery.create("D#RadioButton", {
														caption = "Existing only"
														,id = "Property Restrictions Target Box 1"
														,selected = is_selected("Property Restrictions Target Box", "1")
														,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.set_state()")
													})
													,lQuery.create("D#RadioButton", {
														caption = "Create for multiple"
														,id = "Property Restrictions Target Box 2"
														,selected = is_selected("Property Restrictions Target Box", "2")
														,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.set_state()")
													})
													,lQuery.create("D#RadioButton", {
														caption = "Rule:"
														,id = "Property Restrictions Target Box R"
														,selected = is_selected("Property Restrictions Target Box", "-1")
														,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.set_state()")
													})
													,lQuery.create("D#InputField", {
														maximumWidth = 100
														,id = "Property Restrictions Target Box R"
														,text = get_rule_text("Property Restrictions Target Box")
													})
												}
											})
											,lQuery.create("D#Button", {
												caption = "Details..."
												,horizontalAlignment = -1
												,verticalAlignment = -1
												,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.show_details_window()")
											})
										}
									})
								}
							})
							,lQuery.create("D#GroupBox", {
								caption = "Disjoint Classes"
								,horizontalAlignment = -1
								,verticalAlignment = -1
								,minimumWidth = 650
								,component = {
									lQuery.create("D#HorizontalBox", {
										horizontalAlignment = -1
										,verticalAlignment = -1
										,component = {
											lQuery.create("D#GroupBox", {
												caption = "Graphics"
												,horizontalAlignment = -1
												,verticalAlignment = -1
												,component = {
													lQuery.create("D#RadioButton", {
														caption = "No graphics"
														,id = "Disjoint Classes 0"
														,selected = is_selected("Disjoint Classes", "0")
														,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.set_state()")
													})
													,lQuery.create("D#RadioButton", {
														caption = "Use graphics"
														,id = "Disjoint Classes 1"
														,selected = is_selected("Disjoint Classes", "1")
														,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.set_state()")
													})
													,lQuery.create("D#RadioButton", {
														caption = "Rule:"
														,id = "Disjoint Classes R"
														,selected = is_selected("Disjoint Classes", "-1")
														,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.set_state()")
													})
													,lQuery.create("D#InputField", {
														maximumWidth = 100
														,id = "Disjoint Classes R"
														,text = get_rule_text("Disjoint Classes")
													})
												}
											})
											,lQuery.create("D#GroupBox", {
												caption = "Disjoint mark at forks"
												,horizontalAlignment = -1
												,verticalAlignment = -1
												,component = {
													lQuery.create("D#RadioButton", {
														caption = "Use"
														,id = "Disjoint Classes Fork 0"
														,selected = is_selected("Disjoint Classes Fork", "0")
														,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.set_state()")
													})
													,lQuery.create("D#RadioButton", {
														caption = "Don't use"
														,id = "Disjoint Classes Fork 1"
														,selected = is_selected("Disjoint Classes Fork", "1")
														,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.set_state()")
													})
													,lQuery.create("D#RadioButton", {
														caption = "Rule:"
														,id = "Disjoint Classes Fork R"
														,selected = is_selected("Disjoint Classes Fork", "-1")
														,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.set_state()")
													})
													,lQuery.create("D#InputField", {
														maximumWidth = 100
														,id = "Disjoint Classes Fork R"
														,text = get_rule_text("Disjoint Classes Fork")
													})
												}
											})
											,lQuery.create("D#GroupBox", {
												caption = "Group binary axioms"
												,horizontalAlignment = -1
												,verticalAlignment = -1
												,component = {
													lQuery.create("D#RadioButton", {
														caption = "Yes"
														,id = "Disjoint Classes Group Binary 0"
														,selected = is_selected("Disjoint Classes Group Binary", "0")
														,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.set_state()")
													})
													,lQuery.create("D#RadioButton", {
														caption = "No"
														,id = "Disjoint Classes Group Binary 1"
														,selected = is_selected("Disjoint Classes Group Binary", "1")
														,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.set_state()")
													})
													,lQuery.create("D#RadioButton", {
														caption = "Rule:"
														,id = "Disjoint Classes Group Binary R"
														,selected = is_selected("Disjoint Classes Group Binary", "-1")
														,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.set_state()")
													})
													,lQuery.create("D#InputField", {
														maximumWidth = 100
														,id = "Disjoint Classes Group Binary R"
														,text = get_rule_text("Disjoint Classes Group Binary")
													})
												}
											})
											,lQuery.create("D#GroupBox", {
												caption = "Target for binary disjoint with named class"
												,horizontalAlignment = -1
												,verticalAlignment = -1
												,minimumWidth = 220
												,component = {
													lQuery.create("D#RadioButton", {
														caption = "Create"
														,id = "Disjoint Classes Target 0"
														,selected = is_selected("Disjoint Classes Target", "0")
														,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.set_state()")
													})
													,lQuery.create("D#RadioButton", {
														caption = "Existing only"
														,id = "Disjoint Classes Target 1"
														,selected = is_selected("Disjoint Classes Target", "1")
														,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.set_state()")
													})
													,lQuery.create("D#RadioButton", {
														caption = "Create for multiple"
														,id = "Disjoint Classes Target 2"
														,selected = is_selected("Disjoint Classes Target", "2")
														,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.set_state()")
													})
													,lQuery.create("D#RadioButton", {
														caption = "Rule:"
														,id = "Disjoint Classes Target R"
														,selected = is_selected("Disjoint Classes Target", "-1")
														,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.set_state()")
													})
													,lQuery.create("D#InputField", {
														maximumWidth = 100
														,id = "Disjoint Classes Target R"
														,text = get_rule_text("Disjoint Classes Target")
													})
												}
											})
										}
									})
								}
							})
							,lQuery.create("D#GroupBox", {
								caption = "Equivalent Classes"
								,horizontalAlignment = -1
								,verticalAlignment = -1
								,component = {
									lQuery.create("D#HorizontalBox", {
										horizontalAlignment = -1
										,verticalAlignment = -1
										,component = {
											lQuery.create("D#GroupBox", {
												caption = "Graphics"
												,horizontalAlignment = -1
												,verticalAlignment = -1
												,component = {
													lQuery.create("D#RadioButton", {
														caption = "No graphics"
														,id = "Equivalent Classes 0"
														,selected = is_selected("Equivalent Classes", "0")
														,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.set_state()")
													})
													,lQuery.create("D#RadioButton", {
														caption = "Use graphics"
														,id = "Equivalent Classes 1"
														,selected = is_selected("Equivalent Classes", "1")
														,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.set_state()")
													})
													,lQuery.create("D#RadioButton", {
														caption = "Rule:"
														,id = "Equivalent Classes R"
														,selected = is_selected("Equivalent Classes", "-1")
														,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.set_state()")
													})
													,lQuery.create("D#InputField", {
														maximumWidth = 100
														,id = "Equivalent Classes R"
														,text = get_rule_text("Equivalent Classes")
													})
												}
											})
											,lQuery.create("D#GroupBox", {
												caption = "Group binary axioms"
												,horizontalAlignment = -1
												,verticalAlignment = -1
												,component = {
													lQuery.create("D#RadioButton", {
														caption = "Yes"
														,id = "Equivalent Classes Group Binary 0"
														,selected = is_selected("Equivalent Classes Group Binary", "0")
														,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.set_state()")
													})
													,lQuery.create("D#RadioButton", {
														caption = "No"
														,id = "Equivalent Classes Group Binary 1"
														,selected = is_selected("Equivalent Classes Group Binary", "1")
														,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.set_state()")
													})
													,lQuery.create("D#RadioButton", {
														caption = "Rule:"
														,id = "Equivalent Classes Group Binary R"
														,selected = is_selected("Equivalent Classes Group Binary", "-1")
														,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.set_state()")
													})
													,lQuery.create("D#InputField", {
														maximumWidth = 100
														,id = "Equivalent Classes Group Binary R"
														,text = get_rule_text("Equivalent Classes Group Binary")
													})
												}
											})
										}
									})
								}
							})
						}
					})
					,lQuery.create("D#Tab", {
						caption = "Properties"
						,horizontalAlignment = -1
						,verticalAlignment = -1
						,component = {
							lQuery.create("D#GroupBox", {
								caption = "Object Properties"
								,horizontalAlignment = -1
								,verticalAlignment = -1
								,maximumWidth = 300
								,maximumHeight = 120
								,component = {
									lQuery.create("D#HorizontalBox", {
										horizontalAlignment = -1
										,verticalAlignment = -1
										,component = {
											lQuery.create("D#GroupBox", {
												caption = "Graphics"
												,horizontalAlignment = -1
												,verticalAlignment = -1
												,component = {
													lQuery.create("D#RadioButton", {
														caption = "No graphics"
														,id = "Object Properties 0"
														,selected = is_selected("Object Properties", "0")
														,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.set_state()")
													})
													,lQuery.create("D#RadioButton", {
														caption = "Use graphics"
														,id = "Object Properties 1"
														,selected = is_selected("Object Properties", "1")
														,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.set_state()")
													})
													,lQuery.create("D#RadioButton", {
														caption = "Rule:"
														,id = "Object Properties R"
														,selected = is_selected("Object Properties", "-1")
														,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.set_state()")
													})
													,lQuery.create("D#InputField", {
														maximumWidth = 100
														,id = "Object Properties R"
														,text = get_rule_text("Object Properties")
													})
												}
											})
											,lQuery.create("D#GroupBox", {
												caption = "Merge inverse properties"
												,horizontalAlignment = -1
												,verticalAlignment = -1
												,minimumWidth = 150
												,component = {
													lQuery.create("D#RadioButton", {
														caption = "Yes"
														,id = "Object Properties Merge 0"
														,selected = is_selected("Object Properties Merge", "0")
														,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.set_state()")
													})
													,lQuery.create("D#RadioButton", {
														caption = "No"
														,id = "Object Properties Merge 1"
														,selected = is_selected("Object Properties Merge", "1")
														,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.set_state()")
													})
													,lQuery.create("D#RadioButton", {
														caption = "Rule:"
														,id = "Object Properties Merge R"
														,selected = is_selected("Object Properties Merge", "-1")
														,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.set_state()")
													})
													,lQuery.create("D#InputField", {
														maximumWidth = 100
														,id = "Object Properties Merge R"
														,text = get_rule_text("Object Properties Merge")
													})
												}
											})
										}
									})
								}
							})
						}
					})
					,lQuery.create("D#Tab", {
						caption = "Individuals"
						,horizontalAlignment = -1
						,verticalAlignment = -1
						,component = {
							lQuery.create("D#GroupBox", {
								caption = "Class Assertions"
								,horizontalAlignment = -1
								,verticalAlignment = -1
								,maximumWidth = 400
								,maximumHeight = 120
								,component = {
									lQuery.create("D#HorizontalBox", {
										horizontalAlignment = -1
										,verticalAlignment = -1
										,component = {
											lQuery.create("D#GroupBox", {
												caption = "Graphics"
												,horizontalAlignment = -1
												,verticalAlignment = -1
												,component = {
													lQuery.create("D#RadioButton", {
														caption = "No graphics"
														,id = "Class Assertions 0"
														,selected = is_selected("Class Assertions", "0")
														,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.set_state()")
													})
													,lQuery.create("D#RadioButton", {
														caption = "Use graphics"
														,id = "Class Assertions 1"
														,selected = is_selected("Class Assertions", "1")
														,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.set_state()")
													})
													,lQuery.create("D#RadioButton", {
														caption = "Rule:"
														,id = "Class Assertions R"
														,selected = is_selected("Class Assertions", "-1")
														,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.set_state()")
													})
													,lQuery.create("D#InputField", {
														maximumWidth = 100
														,id = "Class Assertions R"
														,text = get_rule_text("Class Assertions")
													})
												}
											})
											,lQuery.create("D#GroupBox", {
												caption = "Keep text with graphics"
												,horizontalAlignment = -1
												,verticalAlignment = -1
												,minimumWidth = 150
												,component = {
													lQuery.create("D#RadioButton", {
														caption = "Yes"
														,id = "Class Assertions Text 0"
														,selected = is_selected("Class Assertions Text", "0")
														,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.set_state()")
													})
													,lQuery.create("D#RadioButton", {
														caption = "No"
														,id = "Class Assertions Text 1"
														,selected = is_selected("Class Assertions Text", "1")
														,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.set_state()")
													})
													,lQuery.create("D#RadioButton", {
														caption = "Rule:"
														,id = "Class Assertions Text R"
														,selected = is_selected("Class Assertions Text", "-1")
														,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.set_state()")
													})
													,lQuery.create("D#InputField", {
														maximumWidth = 100
														,id = "Class Assertions Text R"
														,text = get_rule_text("Class Assertions Text")
													})
												}
											})
											,lQuery.create("D#GroupBox", {
												caption = "Class Box"
												,horizontalAlignment = -1
												,verticalAlignment = -1
												,component = {
													lQuery.create("D#RadioButton", {
														caption = "Create"
														,id = "Class Assertions Class 0"
														,selected = is_selected("Class Assertions Class", "0")
														,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.set_state()")
													})
													,lQuery.create("D#RadioButton", {
														caption = "Existing only"
														,id = "Class Assertions Class 1"
														,selected = is_selected("Class Assertions Class", "1")
														,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.set_state()")
													})
													,lQuery.create("D#RadioButton", {
														caption = "Create for multiple"
														,id = "Class Assertions Class 2"
														,selected = is_selected("Class Assertions Class", "2")
														,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.set_state()")
													})
													,lQuery.create("D#RadioButton", {
														caption = "Rule:"
														,id = "Class Assertions Class R"
														,selected = is_selected("Class Assertions Class", "-1")
														,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.set_state()")
													})
													,lQuery.create("D#InputField", {
														maximumWidth = 100
														,id = "Class Assertions Class R"
														,text = get_rule_text("Class Assertions Class")
													})
												}
											})
										}
									})
								}
							})
							,lQuery.create("D#GroupBox", {
								caption = "Same individuals"
								,horizontalAlignment = -1
								,verticalAlignment = -1
								,maximumWidth = 400
								,maximumHeight = 120
								,component = {
									lQuery.create("D#HorizontalBox", {
										horizontalAlignment = -1
										,verticalAlignment = -1
										,component = {
											lQuery.create("D#GroupBox", {
												caption = "Graphics"
												,horizontalAlignment = -1
												,verticalAlignment = -1
												,component = {
													lQuery.create("D#RadioButton", {
														caption = "No graphics"
														,id = "Same Individuals 0"
														,selected = is_selected("Same Individuals", "0")
														,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.set_state()")
													})
													,lQuery.create("D#RadioButton", {
														caption = "Use graphics"
														,id = "Same Individuals 1"
														,selected = is_selected("Same Individuals", "1")
														,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.set_state()")
													})
													,lQuery.create("D#RadioButton", {
														caption = "Rule:"
														,id = "Same Individuals R"
														,selected = is_selected("Same Individuals", "-1")
														,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.set_state()")
													})
													,lQuery.create("D#InputField", {
														maximumWidth = 100
														,id = "Same Individuals R"
														,text = get_rule_text("Same Individuals")
													})
												}
											})
										}
									})
								}
							})
							,lQuery.create("D#GroupBox", {
								caption = "Different individuals"
								,horizontalAlignment = -1
								,verticalAlignment = -1
								,maximumWidth = 400
								,maximumHeight = 120
								,component = {
									lQuery.create("D#HorizontalBox", {
										horizontalAlignment = -1
										,verticalAlignment = -1
										,component = {
											lQuery.create("D#GroupBox", {
												caption = "Graphics"
												,horizontalAlignment = -1
												,verticalAlignment = -1
												,component = {
													lQuery.create("D#RadioButton", {
														caption = "No graphics"
														,id = "Different Individuals 0"
														,selected = is_selected("Different Individuals", "0")
														,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.set_state()")
													})
													,lQuery.create("D#RadioButton", {
														caption = "Use graphics"
														,id = "Different Individuals 1"
														,selected = is_selected("Different Individuals", "1")
														,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.set_state()")
													})
													,lQuery.create("D#RadioButton", {
														id = "id_1"
														,caption = "Rule:"
														,id = "Different Individuals R"
														,selected = is_selected("Different Individuals", "-1")
														,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.set_state()")
													})
													,lQuery.create("D#InputField", {
														maximumWidth = 100
														,id = "Different Individuals R"
														,text = get_rule_text("Different Individuals")
													})
												}
											})
										}
									})
								}
							})
						}
					})
					,create_custom_tab()
				}
			})
			,lQuery.create("D#HorizontalBox", {
				horizontalAlignment = 1
				,component = close_button
			})
		}
	})
	dialog_utilities.show_form(form)
end

function show_details_window()
	local close_button = lQuery.create("D#Button", {
		caption = "Close"
		,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.close_details_window()")
	})

	local form = lQuery.create("D#Form", {
		id = "details"
		,caption = "Details"
		,defaultButton = close_button
		,eventHandler = utilities.d_handler("Close", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.close_details_window()")
		,component = {
			lQuery.create("D#VerticalBox", {
				horizontalAlignment = -1
				,verticalAlignment = -1
				,component = {
					lQuery.create("D#HorizontalBox", {
						horizontalAlignment = -1
						,verticalAlignment = -1
						,component = {
							lQuery.create("D#Label", {
								caption = ""
								,minimumWidth = 125
							})
							,lQuery.create("D#Label", {
								caption = "Graphics"
								,minimumWidth = 60
							})
							,lQuery.create("D#Label", {
								caption = "Target Box"
								,minimumWidth = 100
							})
						}
					})
					,lQuery.create("D#HorizontalBox", {
						horizontalAlignment = -1
						,verticalAlignment = -1
						,component = {
							lQuery.create("D#Label", {
								caption = "Object Some Values From:"
								,topMargin = 3
								,minimumWidth = 125
							})
							,lQuery.create("D#ComboBox", {
								item = {
									lQuery.create("D#Item", {
										value = "Default"
									})
									,lQuery.create("D#Item", {
										value = "Yes"
									})
									,lQuery.create("D#Item", {
										value = "No"
									})
									,lQuery.create("D#Item", {
										value = "Rule"
									})
								}
							})
							,lQuery.create("D#ComboBox", {
								item = {
									lQuery.create("D#Item", {
										value = "Default"
									})
									,lQuery.create("D#Item", {
										value = "Create"
									})
									,lQuery.create("D#Item", {
										value = "Existing only"
									})
									,lQuery.create("D#Item", {
										value = "Create for multiple"
									})
									,lQuery.create("D#Item", {
										value = "Rule"
									})
								}
							})
						}
					})
					,lQuery.create("D#HorizontalBox", {
						horizontalAlignment = -1
						,verticalAlignment = -1
						,component = {
							lQuery.create("D#Label", {
								caption = "Object All Values From:"
								,topMargin = 3
								,minimumWidth = 125
							})
							,lQuery.create("D#ComboBox", {
								item = {
									lQuery.create("D#Item", {
										value = "Default"
									})
									,lQuery.create("D#Item", {
										value = "Yes"
									})
									,lQuery.create("D#Item", {
										value = "No"
									})
									,lQuery.create("D#Item", {
										value = "Rule"
									})
								}
							})
							,lQuery.create("D#ComboBox", {
								item = {
									lQuery.create("D#Item", {
										value = "Default"
									})
									,lQuery.create("D#Item", {
										value = "Create"
									})
									,lQuery.create("D#Item", {
										value = "Existing only"
									})
									,lQuery.create("D#Item", {
										value = "Create for multiple"
									})
									,lQuery.create("D#Item", {
										value = "Rule"
									})
								}
							})
						}
					})
					,lQuery.create("D#HorizontalBox", {
						horizontalAlignment = -1
						,verticalAlignment = -1
						,component = {
							lQuery.create("D#Label", {
								caption = "Object Min Cardinality:"
								,topMargin = 3
								,minimumWidth = 125
							})
							,lQuery.create("D#ComboBox", {
								item = {
									lQuery.create("D#Item", {
										value = "Default"
									})
									,lQuery.create("D#Item", {
										value = "Yes"
									})
									,lQuery.create("D#Item", {
										value = "No"
									})
									,lQuery.create("D#Item", {
										value = "Rule"
									})
								}
							})
							,lQuery.create("D#ComboBox", {
								item = {
									lQuery.create("D#Item", {
										value = "Default"
									})
									,lQuery.create("D#Item", {
										value = "Create"
									})
									,lQuery.create("D#Item", {
										value = "Existing only"
									})
									,lQuery.create("D#Item", {
										value = "Create for multiple"
									})
									,lQuery.create("D#Item", {
										value = "Rule"
									})
								}
							})
						}
					})
					,lQuery.create("D#HorizontalBox", {
						horizontalAlignment = -1
						,verticalAlignment = -1
						,component = {
							lQuery.create("D#Label", {
								caption = "Object Max Cardinality:"
								,topMargin = 3
								,minimumWidth = 125
							})
							,lQuery.create("D#ComboBox", {
								item = {
									lQuery.create("D#Item", {
										value = "Default"
									})
									,lQuery.create("D#Item", {
										value = "Yes"
									})
									,lQuery.create("D#Item", {
										value = "No"
									})
									,lQuery.create("D#Item", {
										value = "Rule"
									})
								}
							})
							,lQuery.create("D#ComboBox", {
								item = {
									lQuery.create("D#Item", {
										value = "Default"
									})
									,lQuery.create("D#Item", {
										value = "Create"
									})
									,lQuery.create("D#Item", {
										value = "Existing only"
									})
									,lQuery.create("D#Item", {
										value = "Create for multiple"
									})
									,lQuery.create("D#Item", {
										value = "Rule"
									})
								}
							})
						}
					})
					,lQuery.create("D#HorizontalBox", {
						horizontalAlignment = -1
						,verticalAlignment = -1
						,component = {
							lQuery.create("D#Label", {
								caption = "Object Exact Cardinality:"
								,topMargin = 3
								,minimumWidth = 125
							})
							,lQuery.create("D#ComboBox", {
								item = {
									lQuery.create("D#Item", {
										value = "Default"
									})
									,lQuery.create("D#Item", {
										value = "Yes"
									})
									,lQuery.create("D#Item", {
										value = "No"
									})
									,lQuery.create("D#Item", {
										value = "Rule"
									})
								}
							})
							,lQuery.create("D#ComboBox", {
								item = {
									lQuery.create("D#Item", {
										value = "Default"
									})
									,lQuery.create("D#Item", {
										value = "Create"
									})
									,lQuery.create("D#Item", {
										value = "Existing only"
									})
									,lQuery.create("D#Item", {
										value = "Create for multiple"
									})
									,lQuery.create("D#Item", {
										value = "Rule"
									})
								}
							})
						}
					})
					,lQuery.create("D#HorizontalBox", {
						horizontalAlignment = -1
						,verticalAlignment = -1
						,component = {
							lQuery.create("D#Label", {
								caption = "Data Min Cardinality:"
								,topMargin = 3
								,minimumWidth = 125
							})
							,lQuery.create("D#ComboBox", {
								item = {
									lQuery.create("D#Item", {
										value = "Default"
									})
									,lQuery.create("D#Item", {
										value = "Yes"
									})
									,lQuery.create("D#Item", {
										value = "No"
									})
									,lQuery.create("D#Item", {
										value = "Rule"
									})
								}
							})
							,lQuery.create("D#ComboBox", {
								item = {
									lQuery.create("D#Item", {
										value = "Default"
									})
									,lQuery.create("D#Item", {
										value = "Create"
									})
									,lQuery.create("D#Item", {
										value = "Existing only"
									})
									,lQuery.create("D#Item", {
										value = "Create for multiple"
									})
									,lQuery.create("D#Item", {
										value = "Rule"
									})
								}
							})
						}
					})
					,lQuery.create("D#HorizontalBox", {
						horizontalAlignment = -1
						,verticalAlignment = -1
						,component = {
							lQuery.create("D#Label", {
								caption = "Data Max Cardinality:"
								,topMargin = 3
								,minimumWidth = 125
							})
							,lQuery.create("D#ComboBox", {
								item = {
									lQuery.create("D#Item", {
										value = "Default"
									})
									,lQuery.create("D#Item", {
										value = "Yes"
									})
									,lQuery.create("D#Item", {
										value = "No"
									})
									,lQuery.create("D#Item", {
										value = "Rule"
									})
								}
							})
							,lQuery.create("D#ComboBox", {
								item = {
									lQuery.create("D#Item", {
										value = "Default"
									})
									,lQuery.create("D#Item", {
										value = "Create"
									})
									,lQuery.create("D#Item", {
										value = "Existing only"
									})
									,lQuery.create("D#Item", {
										value = "Create for multiple"
									})
									,lQuery.create("D#Item", {
										value = "Rule"
									})
								}
							})
						}
					})
					,lQuery.create("D#HorizontalBox", {
						horizontalAlignment = -1
						,verticalAlignment = -1
						,component = {
							lQuery.create("D#Label", {
								caption = "Data Exact Cardinality:"
								,topMargin = 3
								,minimumWidth = 125
							})
							,lQuery.create("D#ComboBox", {
								item = {
									lQuery.create("D#Item", {
										value = "Default"
									})
									,lQuery.create("D#Item", {
										value = "Yes"
									})
									,lQuery.create("D#Item", {
										value = "No"
									})
									,lQuery.create("D#Item", {
										value = "Rule"
									})
								}
							})
							,lQuery.create("D#ComboBox", {
								item = {
									lQuery.create("D#Item", {
										value = "Default"
									})
									,lQuery.create("D#Item", {
										value = "Create"
									})
									,lQuery.create("D#Item", {
										value = "Existing only"
									})
									,lQuery.create("D#Item", {
										value = "Create for multiple"
									})
									,lQuery.create("D#Item", {
										value = "Rule"
									})
								}
							})
						}
					})
				}
			})
			,lQuery.create("D#HorizontalBox", {
				horizontalAlignment = 1
				,component = close_button
			})
		}
	})
	dialog_utilities.show_form(form)
end

-----

function show_profiles_window()
	lQuery("D#Event"):delete()
	local close_button = lQuery.create("D#Button", {
		caption = "Close"
		,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.close_profiles_window()")
	})

	local form = lQuery.create("D#Form", {
		id = "parameter profiles"
		,caption = "Parameter Profiles"
		,minimumWidth = "250"
		,defaultButton = close_button
		,eventHandler = utilities.d_handler("Close", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.close_profiles_window()")
		,component = {
			lQuery.create("D#HorizontalBox", {
				horizontalAlignment = -1
				,verticalAlignment = -1
				,component = {
					lQuery.create("D#ListBox", {
						id = "param_profiles"
						,multiSelect = false
						,item = get_profiles()
						,selected = get_selected_profile_item()
						,command = {
							lQuery.create("D#Command", {
								info = "Refresh"
							})
						}
					})
					,lQuery.create("D#VerticalBox", {
						horizontalAlignment = -1
						,verticalAlignment = -1
						,component = {
							lQuery.create("D#Button", {
								caption = "Parametrs..."
								,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.show_parameters_window()")
							})
							,lQuery.create("D#Button", {
								caption = "Set as default"
								,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.set_default_profile()")
							})
							,lQuery.create("D#Button", {
								caption = "Rename"
								,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.show_rename_window()")
							})
							,lQuery.create("D#Button", {
								caption = "Delete"
								,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.show_delete_window()")
							})
							,lQuery.create("D#Button", {
								caption = "Copy"
								,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.show_copy_window()")
							})
							,lQuery.create("D#Button", {
								caption = "Add new..."
								,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.show_add_new_window()")
							})
						}
					})
				}
			})
			,lQuery.create("D#HorizontalBox", {
				horizontalAlignment = 1
				,component = close_button
			})
		}
	})
	dialog_utilities.show_form(form)
end

function get_profiles()
	local profiles = {}
	lQuery("P_OWL#ParamProfile"):each(
		function(profile)
			local item = lQuery.create("D#Item", {
				id = profile:id()
				,value = profile:attr("name")
			})
			table.insert(profiles, item)
		end)
		
	return profiles
end

function get_selected_profile()
	return lQuery("P_OWL#ParamProfile[selected = 'true']")
end

function get_selected_profile_item()
	local selected_profile = get_selected_profile():id()
	return lQuery("D#Item[id = "..selected_profile.."]")
end

function get_current_profile_item()
	return lQuery("D#ListBox[id = 'param_profiles']/selected")
end

function get_current_profile()
	local current_item = get_current_profile_item()
	local current_profile
	lQuery("P_OWL#ParamProfile"):each(
		function(profile)
			if tostring(profile:id()) == current_item:attr("id") then
				current_profile = profile
				return
			end
		end)
		
	return current_profile
end

function set_default_profile()
	local selected_profile = get_selected_profile()
	local current_profile = get_current_profile()

	if selected_profile ~= nil and current_profile ~= nil then
		selected_profile:attr("selected", "false")
		current_profile:attr("selected", "true")
		local message = "Profile '"..get_selected_profile():attr("name").."' has been set as default profile."
		show_message(message)
	end
end

function show_rename_window()
	local current_profile_item = get_current_profile_item()
	if current_profile_item:is_empty() then
		return
	end
	
	lQuery("D#Event"):delete()
	local cancel_button = lQuery.create("D#Button", {
		caption = "Cancel"
		,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.close_rename_window()")
	})

	local form = lQuery.create("D#Form", {
		id = "rename profile"
		,caption = "Rename Profile"
		,minimumWidth = "150"
		,defaultButton = cancel_button
		,eventHandler = utilities.d_handler("Close", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.close_rename_window()")
		,component = {
			lQuery.create("D#HorizontalBox", {
				horizontalAlignment = -1
				,component = {
					lQuery.create("D#InputField", {
						maximumWidth = 150
						,id = "rename profile inputfield"
						,text = current_profile_item:attr("value")
					})
					,lQuery.create("D#Button", {
						caption = "OK"
						,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.rename_profile()")
					})
					,cancel_button
				}
			})
		}
	})
	dialog_utilities.show_form(form)
end

function rename_profile()
	local current_profile = get_current_profile()

	if current_profile ~= nil then
		local new_name = lQuery("D#InputField[id = 'rename profile inputfield']"):attr("text")
		current_profile:attr("name", new_name)
		get_current_profile_item():attr("value", new_name)
		
		close_rename_window()
		refresh_list_box()
	end
end

function show_delete_window()
	local current_profile = get_current_profile()

	if current_profile == nil then
		return
	end
	
	if current_profile:attr("selected") == "false" then
	
		lQuery("D#Event"):delete()
		local cancel_button = lQuery.create("D#Button", {
			caption = "No"
			,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.close_delete_window()")
		})

		local form = lQuery.create("D#Form", {
			id = "delete profile"
			,caption = "Delete Profile"
			,minimumWidth = "350"
			,minimumHeight = "70"
			,horizontalAlignment = 0
			,verticalAlignment = 0
			,defaultButton = cancel_button
			,eventHandler = utilities.d_handler("Close", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.close_delete_window()")
			,component = {
				lQuery.create("D#VerticalBox", {
					horizontalAlignment = -1
					,verticalAlignment = -1
					,component = {
						lQuery.create("D#Label", {
							caption = "Are you sure you want to delete profile '"..current_profile:attr("name").."'?"
							,minimumWidth = 125
						})
						,lQuery.create("D#HorizontalBox", {
							horizontalAlignment = 0
							,component = {
								lQuery.create("D#Button", {
									caption = "Yes"
									,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.delete_profile()")
								})
								,cancel_button
							}
						})
					}
				})
			}
		})
		dialog_utilities.show_form(form)
	else
		local message = "Default profile '"..current_profile:attr("name").."' cannot be deleted!"
		show_message(message)
	end
end

function delete_profile()
	local current_profile = get_current_profile()
	current_profile:find("/instructionInProfile"):each(
		function(instr_in_profile)
			instr_in_profile:delete()
		end)
	current_profile:delete()
	get_current_profile_item():delete()
	
	close_delete_window()
	refresh_list_box()
end


function show_copy_window()
	local current_profile_item = get_current_profile_item()
	if current_profile_item:is_empty() then
		return
	end

	lQuery("D#Event"):delete()
	local cancel_button = lQuery.create("D#Button", {
		caption = "Cancel"
		,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.close_copy_window()")
	})

	local form = lQuery.create("D#Form", {
		id = "copy profile"
		,caption = "Copy Profile"
		,minimumWidth = "350"
		,minimumHeight = "70"
		,horizontalAlignment = 0
		,verticalAlignment = 0
		,defaultButton = cancel_button
		,eventHandler = utilities.d_handler("Close", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.close_copy_window()")
		,component = {
			lQuery.create("D#HorizontalBox", {
				horizontalAlignment = 0
				,verticalAlignment = 0
				,component = {
					lQuery.create("D#Label", {
						caption = "Enter the name of a new profile:"
						,minimumWidth = 125
					})
					,lQuery.create("D#InputField", {
						maximumWidth = 150
						,id = "copy profile inputfield"
						,text = current_profile_item:attr("value").." Copy"
					})
				}
			})
			,lQuery.create("D#HorizontalBox", {
				horizontalAlignment = 0
				,component = {
					lQuery.create("D#Button", {
						caption = "OK"
						,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.copy_profile()")
					})
					,cancel_button
				}
			})
		}
	})
	dialog_utilities.show_form(form)
end

function copy_profile()
	local input_field = lQuery("D#InputField[id = 'copy profile inputfield']")
	local current_profile = get_current_profile()
	local profile_name = input_field:attr("text")
	local param_profile = lQuery.create("P_OWL#ParamProfile", {name = profile_name, selected = "false"})
	
	if current_profile ~= nil then
		copy_profiles_instructions(current_profile, param_profile)
		add_new_item(param_profile)
		
		input_field:delete()
		close_copy_window()
		refresh_list_box()
	end
end

function copy_profiles_instructions(from_profile, to_profile)
	from_profile:find("/instructionInProfile"):each(
		function(instruction)
			local new_instruction = lQuery.create("P_OWL#InstructionInProfile", {textValue = instruction:attr("textValue")})
			new_instruction:link("instruction", instruction:find("/instruction"))
			new_instruction:link("selected", instruction:find("/selected"))
			to_profile:link("instructionInProfile", new_instruction)
		end)
end

function show_add_new_window()
	lQuery("D#Event"):delete()
	local cancel_button = lQuery.create("D#Button", {
		caption = "Cancel"
		,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.close_add_window()")
	})

	local form = lQuery.create("D#Form", {
		id = "add profile"
		,caption = "Add Profile"
		,minimumWidth = "350"
		,minimumHeight = "70"
		,horizontalAlignment = 0
		,verticalAlignment = 0
		,defaultButton = cancel_button
		,eventHandler = utilities.d_handler("Close", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.close_add_window()")
		,component = {
			lQuery.create("D#HorizontalBox", {
				horizontalAlignment = 0
				,verticalAlignment = 0
				,component = {
					lQuery.create("D#Label", {
						caption = "Enter the name of a new profile:"
						,minimumWidth = 125
					})
					,lQuery.create("D#InputField", {
						maximumWidth = 150
						,id = "add profile inputfield"
						,text = ""
					})
				}
			})
			,lQuery.create("D#HorizontalBox", {
				horizontalAlignment = 0
				,component = {
					lQuery.create("D#Button", {
						caption = "OK"
						,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.add_new_profile()")
					})
					,cancel_button
				}
			})
		}
	})
	dialog_utilities.show_form(form)
end

function add_new_profile()
	local input_field = lQuery("D#InputField[id = 'add profile inputfield']")
	local default_profile = get_selected_profile()
	local profile_name = input_field:attr("text")
	local param_profile = lQuery.create("P_OWL#ParamProfile", {name = profile_name, selected = "false"})
	
	copy_profiles_instructions(default_profile, param_profile)
	add_new_item(param_profile)
	
	input_field:delete()
	close_add_window()
	refresh_list_box()
end

function add_new_item(profile)
	local item = lQuery.create("D#Item", {
		id = profile:id()
		,value = profile:attr("name")
	})
	local list_box = lQuery("D#ListBox[id = 'param_profiles']")
	
	list_box:link("item", item)
end

function refresh_list_box()
	local list_box = lQuery("D#ListBox[id = 'param_profiles']")
	utilities.execute_cmd("D#Command", {info = "Refresh", receiver = list_box})
end

-----

function show_message(message)
	lQuery("D#Event"):delete()
	local close_button = lQuery.create("D#Button", {
		caption = "OK"
		,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.close_message_window()")
	})

	local form = lQuery.create("D#Form", {
		id = "message window"
		,caption = "Information"
		,minimumWidth = string.len(message)*6
		,minimumHeight = "70"
		,horizontalAlignment = 0
		,verticalAlignment = 0
		,defaultButton = close_button
		,eventHandler = utilities.d_handler("Close", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.close_message_window()")
		,component = {
			lQuery.create("D#VerticalBox", {
				horizontalAlignment = 0
				,verticalAlignment = 0
				,component = {
					lQuery.create("D#Label", {
						caption = message
						,minimumWidth = 125
					})
					,close_button
				}
			})
		}
	})
	dialog_utilities.show_form(form)
end

-----

function close_main_window()
	lQuery("D#Event"):delete()
	utilities.close_form("main window")
end

function close_parameters_window()
	fill_rule("Class Annotations")
	fill_rule("Object Properties Annotations")
	fill_rule("Data Properties Annotations")
	fill_rule("Individuals Annotations")
	fill_rule("Class Restrictions")
	fill_rule("Class Restrictions Target Box")
	fill_rule("Class Restrictions Fork")
	fill_rule("Class Restrictions And Named Source")
	fill_rule("Property Restrictions")
	fill_rule("Property Restrictions Target Box")
	fill_rule("Disjoint Classes")
	fill_rule("Disjoint Classes Fork")
	fill_rule("Disjoint Classes Group Binary")
	fill_rule("Disjoint Classes Target")
	fill_rule("Equivalent Classes")
	fill_rule("Equivalent Classes Group Binary")
	fill_rule("Object Properties")
	fill_rule("Object Properties Merge")
	fill_rule("Class Assertions")
	fill_rule("Class Assertions Text")
	fill_rule("Class Assertions Class")
	fill_rule("Same Individuals")
	fill_rule("Different Individuals")
	
	fill_current_value("Box Creation Threshold")
	
	fill_custom_value_fields()

	lQuery("D#Event"):delete()
	utilities.close_form("presentation parameters")
end

function close_details_window()
	lQuery("D#Event"):delete()
	utilities.close_form("details")
end

function close_profiles_window()
	lQuery("D#Event"):delete()
	utilities.close_form("parameter profiles")
end

function close_rename_window()
	lQuery("D#Event"):delete()
	utilities.close_form("rename profile")
end

function close_delete_window()
	lQuery("D#Event"):delete()
	utilities.close_form("delete profile")
end

function close_message_window()
	lQuery("D#Event"):delete()
	utilities.close_form("message window")
end

function close_copy_window()
	lQuery("D#Event"):delete()
	utilities.close_form("copy window")
end

function close_add_window()
	lQuery("D#Event"):delete()
	utilities.close_form("copy window")
end
-----

function create_custom_tab()
	if lQuery("P_OWL#Instruction"):find("[isCustom = true]"):is_not_empty() then
		return lQuery.create("D#Tab", {
				caption = "Custom"
				,horizontalAlignment = -1
				,verticalAlignment = -1
				,component = {
					add_custom_instructions()
				}
		})
	end
end

function add_custom_instructions()
	local components = lQuery("")

	lQuery("P_OWL#Instruction"):find("[isCustom = true]"):each(
		function(instruction)
			local instr_type = instruction:attr("type")
			
			if instr_type == "valueField" then
				components = components:add(add_valuefield(instruction))
			elseif instr_type == "checkBox" then
				local item = instruction:find("/instructionItem")
				local is_selected = false
				if instruction:find("/selected"):attr("value") == "1" then
					is_selected = true
				end
				
				components = components:add(add_checkbox(item, is_selected))
			elseif instr_type == "itemList" then
				components = components:add(add_radiobuttons_group_box(instruction))
			end
		end)
		
	return components
end

function add_radiobuttons_group_box(instruction)
	return lQuery.create("D#GroupBox", {
		caption = instruction:attr("id")
		,minimumWidth = 200
		,maximumHeight = 60
		,horizontalAlignment = -1
		,verticalAlignment = -1
		,component = {
			add_radiobuttons(instruction)
		}
	})
end

function add_radiobuttons(instruction)
	local buttons = lQuery("")
	local value = 0
	
	instruction:find("/instructionItem"):each(
		function(item)
			local is_selected = false
			if item:id() == instruction:find("/selected"):id() then
				is_selected = true
			end
			
			buttons = buttons:add(add_radiobutton(item, is_selected, value))
			value = value + 1
		end)
		
	return buttons
end

function add_radiobutton(item, is_selected, value)
	return lQuery.create("D#RadioButton", {
		caption = item:attr("title")
		,id = item:find("/instruction"):attr("id").." "..value
		,selected = is_selected
		,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.set_state()")
	})
end

function add_checkbox(item, is_checked)
	return lQuery.create("D#CheckBox", {
		caption = item:attr("title")
		,id = item:find("/instruction"):attr("id")
		,checked = is_checked
		,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_Domain.parameters_form.set_checkbox_state()")
	})
end

function add_valuefield(instruction)
	local label = lQuery.create("D#Label", {
		caption = instruction:attr("id")..":"
		,topMargin = 3
	})
	local input_field = lQuery.create("D#InputField", {
		id = instruction:attr("id")
		,text = get_current_value(instruction:attr("id"))
		,maximumWidth = 100
	})
	
	return lQuery.create("D#HorizontalBox", {
		horizontalAlignment = -1
		,verticalAlignment = -1
		,maximumWidth = 320
		,maximumHeight = 20
		,topMargin = 10
		,component = {
			label
			,input_field
		}
	})
end

-----

function get_instr_in_profile(property_name)
	return get_current_profile():find("/instructionInProfile:has(/instruction[id = "..property_name.."])")
end

function is_selected(property_name, property_value)
	return get_instr_in_profile(property_name):find("/selected"):attr("index") == property_value
end

function set_state()
	local component_id = lQuery("D#Event"):find("/source"):attr("id")
	local property_name = string.sub(component_id, 0, string.len(component_id)-2)
	local property_value = string.sub(component_id, -1)
	
	if property_value == "R" then -- Rule
		property_value = "-1"
	end
	
	local instr_in_profile = get_instr_in_profile(property_name)
	local old_selection = instr_in_profile:find("/selected")
	local new_selection = instr_in_profile:find("/instruction/item[index = "..property_value.."]")
	
	instr_in_profile:remove_link("selected", old_selection)
	instr_in_profile:link("selected", new_selection)
end

function set_checkbox_state()
	local property_name = lQuery("D#Event"):find("/source"):attr("id")
	local property_value
	if lQuery("D#Event"):find("/source"):attr("checked") == "true" then
		property_value = 1
	else
		property_value = 0
	end
	
	local instr_in_profile = get_instr_in_profile(property_name)
	local old_selection = instr_in_profile:find("/selected")
	local new_selection = instr_in_profile:find("/instruction/item[index = "..property_value.."]")
	
	instr_in_profile:remove_link("selected", old_selection)
	instr_in_profile:link("selected", new_selection)
end

function get_rule_text(rule_id)
	if is_selected(rule_id, "-1") then
		return get_instr_in_profile(rule_id):find("/selected"):attr("itemProc")
	else
		return ""
	end
end

function get_current_value(rule_id)
	return get_instr_in_profile(rule_id):attr("textValue")
end

function fill_rule(rule_id)
	if is_selected(rule_id, "-1") then
		local proc = lQuery("D#InputField"):find("[id = "..rule_id.." R]"):attr("text")
		get_instr_in_profile(rule_id):find("/selected"):attr("itemProc", proc)
	end
end

function fill_current_value(id)
	local value = lQuery("D#InputField"):find("[id = "..id.."]"):attr("text")
	get_instr_in_profile(id):attr("textValue", value)
end

function fill_custom_value_fields()
	lQuery("P_OWL#Instruction"):find("[isCustom = true]"):find("[type = valueField]"):each(
		function(instruction)
			fill_current_value(instruction:attr("id"))
		end)
end