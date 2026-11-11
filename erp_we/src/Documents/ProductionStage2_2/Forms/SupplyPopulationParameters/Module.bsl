
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Items.GroupToReplaceWithAnalogs.Visible = GetFunctionalOption("UseAlternativeMaterials");

	ListOfActions = New ValueList;
	ListOfActions.Add("Action_Ship_PRIORITY_WithAssignment", PredefinedValue("Enum.SupplyOptions.Ship"));
	ListOfActions.Add("Action_ToReserve__PRIORITY_WithAssignment", PredefinedValue("Enum.SupplyOptions.FromWarehouse"));
	DefaultActionCode = "Action_Ship_PRIORITY_WithAssignment";

	AutoTitle = Not Parameters.Property("FormCaption", ThisForm.Title);
	If Parameters.Property("FillInTitleOfButton") Then
		Items.Fill.Title = Parameters.FillInTitleOfButton;
	EndIf;
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	FillInSupply = True;
	
	If ListOfActions.FindByValue(Settings["ActionCode"]) = Undefined Then
		ActionCode = DefaultActionCode;
	EndIf;
	
	ConfigureDependentFormElements(ThisForm);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers
 
&AtClient
Procedure FillInSupplyOnChange(Item)
	
	If Not ValueIsFilled(ActionCode) Then
		ActionCode = DefaultActionCode;
	EndIf;

	ConfigureDependentFormElements(ThisForm, "FillInSupply");
	
EndProcedure

&AtClient
Async Procedure HyperlinkCurActionClick(Item)
	
	Response = Await ChooseFromListAsync(ListOfActions, Items.HyperlinkCurAction);
	
	If TypeOf(Response) = Type("ValueListItem") Then
	 	ActionCode = Response.Value;
		ConfigureDependentFormElements(ThisForm, "CurrentAction1"); 
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommands

&AtClient
Procedure OK(Command)
	
	Result = SupplyPopulationParameters();
	Close(Result);
	
EndProcedure

#EndRegion

#Region Private
  
&AtClientAtServerNoContext
Procedure ConfigureDependentFormElements(Form, AttributesList = "")
	
	Items = Form.Items;
	
	Initialize = IsBlankString(AttributesList);
	AttributesStructure1 = New Structure(AttributesList);
	
	If AttributesStructure1.Property("CurrentAction1")
		Or Initialize Then
		Items.HyperlinkCurAction.Title = Form.ListOfActions.FindByValue(Form.ActionCode).Presentation;
	EndIf;
	
	If AttributesStructure1.Property("FillInSupply")
		Or Initialize Then
		Items.GroupFillInDetailsAssurance.Enabled = Form.FillInSupply;
		Items.GroupToReplaceWithAnalogs.Enabled          = Form.FillInSupply;
	EndIf;
	
EndProcedure

&AtServer
Function SupplyPopulationParameters()

	ActionCodeAnalogs = ?(ActionCode = "Action_Ship_PRIORITY_WithAssignment",  "Action_Substitutes_Ship",
		                 ?(ActionCode = "Action_ToReserve__PRIORITY_WithAssignment", "Action_Substitutes_ToReserve_",
		                    							""));
	Result = New Structure();
	
	Result.Insert("FillInSupply", FillInSupply);
	Result.Insert("ActionCode",          ActionCode);
	Result.Insert("Replace_With_Analogues",    Replace_With_Analogues);
	Result.Insert("ActionCodeAnalogs",   ActionCodeAnalogs);
	
	Return Result;
	
EndFunction

#EndRegion

