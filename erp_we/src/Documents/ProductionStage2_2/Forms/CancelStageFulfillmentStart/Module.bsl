
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Items.GroupToReplaceWithAnalogs.Visible = GetFunctionalOption("UseAlternativeMaterials");
	
	ListOfActions = New ValueList;
	DefaultActionCode = "Action_Ship_PRIORITY_WithAssignment"; 
	
	AutoTitle = Not Parameters.Property("FormCaption", Title);
	
	TransferToExecution = CommonClientServer.StructureProperty(Parameters, "TransferToExecution", False);
	
	If TransferToExecution Then
		
		DefaultActionCode = "Action_ToReserve__PRIORITY_WithAssignment";
		Items.HyperlinkCurAction.Enabled = False;
		
	Else
		
		ListOfActions.Add("Action_Ship_PRIORITY_WithAssignment", PredefinedValue("Enum.SupplyOptions.Ship"));
	
	EndIf;
	
	ListOfActions.Add("Action_ToReserve__PRIORITY_WithAssignment", PredefinedValue("Enum.SupplyOptions.FromWarehouse"));
	
	Parameters.Property("Organization", Organization);
	Parameters.Property("Department", Department);
	
	NeedChoiceOfArtist = False;
	If Not Parameters.Property("NeedChoiceOfArtist", NeedChoiceOfArtist) Then
		If ValueIsFilled(Department) Then
			NeedChoiceOfArtist = Not ProductionServerCached.ProductionBusinessUnitDescription(Department).UseOperationManagement;
		Else
			NeedChoiceOfArtist = True;
		EndIf;
	EndIf;
	AssignAssignee = NeedChoiceOfArtist And Parameters.Property("CurrentPerformer", Performer) And ValueIsFilled(Performer);
	Items.LaborCostsGroup.Visible = NeedChoiceOfArtist;
	
	If IsBlankString(ActionCode) Then
		ActionCode = DefaultActionCode;
		ConfigureDependentFormElements(ThisObject, "CurrentAction1");
	EndIf;
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	FillInSupply = True;
	
	If ListOfActions.FindByValue(Settings["ActionCode"]) = Undefined Then
		ActionCode = DefaultActionCode;
	EndIf;
	
	ConfigureDependentFormElements(ThisObject);
	
EndProcedure
  
&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	If AssignAssignee And Not ValueIsFilled(Performer) Then
		Common.MessageToUser(NStr("vi = 'Chưa điền người thực hiện';
									|ru = 'Не заполнен исполнитель';
									|en = 'Assignee is required.'; fa = 'Assignee is required.';
									|it = 'Не заполнен исполнитель';
									|pl = 'Assignee is required.';
									|tr = 'Atanan doldurulmadı'"),, "Performer",, Cancel);
	EndIf;

EndProcedure

&AtServer
Procedure OnSaveDataInSettingsAtServer(Settings)
	
	If TransferToExecution Then
		Settings.Delete("ActionCode");
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers
 
&AtClient
Procedure FillInSupplyOnChange(Item)
	
	If Not ValueIsFilled(ActionCode) Then
		ActionCode = DefaultActionCode;
	EndIf;

	ConfigureDependentFormElements(ThisObject, "FillInSupply");
	
EndProcedure

&AtClient
Async Procedure HyperlinkCurActionClick(Item)
	
	Response = Await ChooseFromListAsync(ListOfActions, Items.HyperlinkCurAction);
	
	If TypeOf(Response) = Type("ValueListItem") Then
	 	ActionCode = Response.Value;
		ConfigureDependentFormElements(ThisObject, "CurrentAction1"); 
	EndIf;
	
EndProcedure

&AtClient
Procedure AssignAssigneeOnChange(Item) 
	
	ConfigureDependentFormElements(ThisObject, "AssignAssignee");
	
EndProcedure

&AtClient
Procedure PerformerOnChange(Item)
	
	ConfigureDependentFormElements(ThisObject, "AssignAssignee");

EndProcedure

&AtClient
Procedure PerformerStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	StandardProcessing = False;
	CallbackDescription = New CallbackDescription("PerformerStartChoiceCompletion", ThisObject);
	ProductionClient.OpenArtistSelectionForm(
		Organization,
		Department,
		Performer,,, 
		CallbackDescription);

EndProcedure
 
&AtClient
Procedure PerformerStartChoiceCompletion(Result, AdditionalParameters) Export
	
	Performer = Result;
	
	If Not AssignAssignee And ValueIsFilled(Performer) Then
		AssignAssignee = True;
	EndIf;
	
	ConfigureDependentFormElements(ThisObject, "AssignAssignee");
	
EndProcedure
 
&AtClient
Procedure ThereMayBeErrorInChoosingPerformerClick(Item)

	ShowMessageBox(, Item.ToolTip);

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	Close(ActionParameters());
	
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
	
	If AttributesStructure1.Property("AssignAssignee")
		Or Initialize Then
		
		// Performer
		
		Items.Performer.AutoMarkIncomplete = Form.AssignAssignee;
		Items.Performer.MarkIncomplete = Form.AssignAssignee;
		
		Items.Performer.TextColor = ?(Form.AssignAssignee Or Not ValueIsFilled(Form.Performer),
														New Color(), WebColors.DarkGray);
		Items.Performer.TitleTextColor = ?(Form.AssignAssignee, 
														New Color(),  WebColors.DarkGray); 
		// Department
		
		Items.Department.Visible = ValueIsFilled(Form.Department);
		If Items.Department.Visible Then
			If Not Form.AssignAssignee Then
				Items.Department.TextColor = WebColors.DarkGray;
			Else
				InformationAboutAPerformer = InformationAboutContractorSPlaceOfWork(
					Form.Performer, 
					Form.Department);
				Items.ThereMayBeErrorInChoosingPerformer.Visible = Not (InformationAboutAPerformer.Department = Form.Department Or Not ValueIsFilled(InformationAboutAPerformer.Department));
				Items.Department.TextColor = ?((InformationAboutAPerformer.Department = Form.Department 
															Or Not ValueIsFilled(InformationAboutAPerformer.Department)), 
														New Color(), WebColors.Red);
			EndIf;
 		EndIf;

	EndIf;
	
EndProcedure

&AtServer
Function ActionParameters()

	ActionCodeAnalogs = ?(ActionCode = "Action_Ship_PRIORITY_WithAssignment",  "Action_Substitutes_Ship",
		                 ?(ActionCode = "Action_ToReserve__PRIORITY_WithAssignment", "Action_Substitutes_ToReserve_",
		                    							""));
	Result = New Structure();
	
	Result.Insert("FillInSupply", FillInSupply);
	Result.Insert("ActionCode",          ActionCode);
	Result.Insert("Replace_With_Analogues",    Replace_With_Analogues);
	Result.Insert("ActionCodeAnalogs",   ActionCodeAnalogs);
	Result.Insert("AssignAssignee", AssignAssignee);
	Result.Insert("Performer",          ?(AssignAssignee, Performer, Undefined));
	
	Return Result;
	
EndFunction

&AtServerNoContext
Function InformationAboutContractorSPlaceOfWork(Performer, Department)
	
	SetPrivilegedMode(True);
	InformationAboutAPerformer = ProductionManagement.InformationAboutContractorSPlaceOfWork(Performer); 
	SetPrivilegedMode(False); 
	
	Return InformationAboutAPerformer;
	
EndFunction

#EndRegion

