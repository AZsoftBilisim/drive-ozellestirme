#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ExecutionIsAllowed = Parameters.ExecutionIsAllowed;
	RCView          = Parameters.RCView;
	WorkCenter   = Parameters.WorkCenter;
	Operation       = Parameters.Operation;
	Product        = Parameters.Product;
	Performer    = Parameters.Performer;
	Stage           = Parameters.Stage;
	Lot         = Parameters.Lot;
	ProductionArea        = Parameters.ProductionArea;
	Department  = Parameters.Department;
	
	ReadDivisionParameters();
	
	Settings = DataProcessors.ExecutionOfOperations2_2.GetUserSettings();
	
	If Settings <> Undefined Then
	
		Items.ProductionArea.Enabled      = Not ValueIsFilled(Settings.ProductionArea);
		Items.WorkCenter.Enabled = Not ValueIsFilled(Settings.WorkCenter);
		Items.Performer.Enabled  = Not ValueIsFilled(Settings.Performer);
		
		Items.RCView.Visible = Items.WorkCenter.Enabled;
	EndIf;
	
	CustomizeFormElements();
	
	ProductionManagementClientServer.SetArtistType(Performer,
		UseTeamWorkOrders,
		ProductionServer.AccountingOfLaborCostsInContextOfEmployeesIsUsed(CurrentSessionDate()));
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure WorkCenterOnChange(Item)
	RCView = GetRCView(WorkCenter);
EndProcedure

&AtClient
Procedure RCViewOnChange(Item)
	
	If GetRCView(WorkCenter) = RCView Then
		Return
	EndIf;
	
	WorkCenter = Undefined;
EndProcedure

&AtClient
Procedure PerformerStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	
	CallbackDescription = New CallbackDescription("PerformerStartChoiceCompletion", ThisObject);
	
	ProductionClient.OpenArtistSelectionForm(
		Undefined,
		Department,
		Performer,
		Undefined,
		,
		CallbackDescription);
	
EndProcedure

&AtClient
Procedure ProductionAreaOnChange(Item)
	EstablishLinksOfWorkCenterSelectionParameters();
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SetFilters(Command)
	
	FilterParameters = New Structure();
	
	FilterParameters.Insert("ExecutionIsAllowed", ExecutionIsAllowed);
	FilterParameters.Insert("RCView", RCView);
	FilterParameters.Insert("WorkCenter", WorkCenter);
	FilterParameters.Insert("Performer", Performer);
	FilterParameters.Insert("Operation", Operation);
	FilterParameters.Insert("Product", Product);
	FilterParameters.Insert("Lot", Lot);
	FilterParameters.Insert("Stage", Stage);
	FilterParameters.Insert("ProductionArea", ProductionArea);
	
	Close(FilterParameters);
EndProcedure

&AtClient
Procedure ClearFilters(Command)
	
	If Items.WorkCenter.Visible Then
		RCView        = Undefined;
		WorkCenter = Undefined;
		
		FormOwner.RCView        = Undefined;
		FormOwner.WorkCenter = Undefined;
	EndIf;
	
	If Items.Performer.Visible Then
		
		If TypeOf(Performer) = Type("CatalogRef.Persons") Then
			Performer = PredefinedValue("Catalog.Persons.EmptyRef");
		ElsIf TypeOf(Performer) = Type("CatalogRef.Teams") Then 
			Performer = PredefinedValue("Catalog.Teams.EmptyRef");
		EndIf;
		
		FormOwner.Performer = Undefined;
	EndIf;
	
	If Items.ProductionArea.Visible Then
		ProductionArea = Undefined;
		
		FormOwner.ProductionArea = Undefined;
	EndIf;
	
	Operation = Undefined;
	Product  = Undefined;
	Stage     = Undefined;
	Lot   = Undefined;
	
	FormOwner.Operation = Undefined;
	FormOwner.Product  = Undefined;
	FormOwner.Stage     = Undefined;
	FormOwner.Lot   = Undefined;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure CustomizeFormElements()
	
	// Relationships of site selection parameters
	ParametersArray = New Array;
	
	ParametersArray.Add(New ChoiceParameterLink("Filter.Owner", "Department"));
	
	Items.ProductionArea.ChoiceParameterLinks = New FixedArray(ParametersArray);
	
	// Work Center Selection Options
	ChoiceParameters = New Array;
	
	ChoiceParameters.Add(New ChoiceParameter("Filter.Department", Department));
	
	Items.WorkCenter.ChoiceParameters = New FixedArray(ChoiceParameters);
	
	Items.ProductionArea.Visible = Common.ObjectAttributeValue(
		Department,
		"UseProductionSites");
	
EndProcedure

&AtServerNoContext
Function GetRCView(WorkCenter)
	Return Common.ObjectAttributeValue(WorkCenter, "WorkCenterType");
EndFunction

&AtServer
Procedure ReadDivisionParameters()
	
	If Department.IsEmpty() Then
		Return;
	EndIf;
	
	FillPropertyValues(
		ThisForm,
		ProductionServer.ProductionBusinessUnitDescription(Department),
		"UseTeamWorkOrders, UseAreas");
EndProcedure

&AtClient
Procedure PerformerStartChoiceCompletion(Result, Var_Parameters) Export
	
	If ValueIsFilled(Result) Then
		
		Performer = Result;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure EstablishLinksOfWorkCenterSelectionParameters()
	
	ParametersArray = New Array;
	
	If ValueIsFilled(ProductionArea) Then
		ParametersArray.Add(New ChoiceParameterLink("Filter.ProductionArea", "ProductionArea"));
	EndIf;
	
	Items.WorkCenter.ChoiceParameterLinks = New FixedArray(ParametersArray);
	
EndProcedure

#EndRegion