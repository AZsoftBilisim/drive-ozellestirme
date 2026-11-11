#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	NewRecord = Parameters.Key.IsEmpty();
	
	If NewRecord Then
		Record.User = Parameters.User;
		Record.OpenedForm = Parameters.OpenedForm;
		
		OpeningMode = "UsingParameter";
		
		OnReadCreateAtServer();
	EndIf;
	
	SetArtistType();
	
EndProcedure

// Parameters:
// 	CurrentObject - InformationRegisterRecordManager.ConfigureFormOpeningOnStartingApplication - 
&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	OpeningMode = ?(CurrentObject.OpenByDefault,"Default","UsingParameter");
	
	ParametersStructure = CurrentObject.Parameters.Get();
	
	If TypeOf(ParametersStructure) = Type("Structure") Then
		
		Department = ?(ParametersStructure.Property("Department"), ParametersStructure.Department, Undefined);
		ProductionArea       = ?(ParametersStructure.Property("ProductionArea"), ParametersStructure.ProductionArea, Undefined);
		WorkMode   = ?(ParametersStructure.Property("WorkMode"), ParametersStructure.WorkMode, Undefined);
		WorkCenter  = ?(ParametersStructure.Property("WorkCenter"), ParametersStructure.WorkCenter, Undefined);
		Performer   = ?(ParametersStructure.Property("Performer"), ParametersStructure.Performer, Undefined);
		
		YouCanChangeTheDepartment = ?(ParametersStructure.Property("YouCanChangeTheDepartment"),
										ParametersStructure.YouCanChangeTheDepartment,
										False);
		
		Items.YouCanChangeTheDepartment.Enabled = Not ValueIsFilled(WorkCenter);
		
	EndIf;
	
	ChangeSiteAccessibility();
	
	OnReadCreateAtServer();
	
EndProcedure

// Parameters:
// 	Cancel - Boolean - 
// 	CurrentObject - InformationRegisterRecordManager.ConfigureFormOpeningOnStartingApplication - 
// 	WriteParameters - Structure - 
&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("Department", Department);
	ParametersStructure.Insert("ProductionArea", ProductionArea);
	ParametersStructure.Insert("WorkMode", WorkMode);
	ParametersStructure.Insert("WorkCenter", WorkCenter);
	ParametersStructure.Insert("Performer", Performer);
	ParametersStructure.Insert("YouCanChangeTheDepartment", YouCanChangeTheDepartment);
	
	CurrentObject.Parameters = New ValueStorage(ParametersStructure);
	CurrentObject.ParameterPresentationText = 
		Common.ObjectAttributeValue(Department, "Description")
		+ ?(ProductionArea.IsEmpty(),"", " / " + Common.ObjectAttributeValue(ProductionArea, "Description"));
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	DimensionStructure = New Structure;
	DimensionStructure.Insert("User", Record.User);
	DimensionStructure.Insert("OpenedForm", Record.OpenedForm);
	
	Notify("Write_ConfigureFormOpeningOnStartingApplication", WriteParameters, DimensionStructure);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DepartmentOnChange(Item)
	
	ChangeSiteAccessibility();
	
	SetArtistType();
	
EndProcedure

&AtClient
Procedure OpeningModeWhenChanging(Item)
	Record.OpenByDefault = OpeningMode = "Default";
EndProcedure

&AtClient
Procedure WorkCenterOnChange(Item)
	
	Items.YouCanChangeTheDepartment.Enabled = Not ValueIsFilled(WorkCenter);
	
	If ValueIsFilled(WorkCenter) Then
		YouCanChangeTheDepartment = False;
	EndIf;
	
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

#Region Private

#Region Other

&AtServer
Procedure OnReadCreateAtServer()
	
	StructureOfFormParameters = OpenFormsOnApplicationStartClientServerOverridable.FormSettings(Record.OpenedForm);
	LaunchParameter = StructureOfFormParameters.LaunchParameter;
	
EndProcedure

&AtServer
Procedure ChangeSiteAccessibility()
	
	UseAreas = GetFunctionalOption(
		"UseProductionSites",
		New Structure("Department", Department));
	
	Items.ProductionArea.Enabled = UseAreas;
	
EndProcedure

&AtServer
Procedure SetArtistType()
	
	If Department.IsEmpty() Then
		Items.Performer.Enabled = False;
		Return;
	Else
		Items.Performer.Enabled = True;
	EndIf;
	
	Settings = ProductionServer.ProductionBusinessUnitDescription(Department);
	
	ProductionManagementClientServer.SetArtistType(Performer,
		Settings.UseTeamWorkOrders,
		ProductionServer.AccountingOfLaborCostsInContextOfEmployeesIsUsed(CurrentSessionDate()));
	
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
	
	ParametersArray.Add(New ChoiceParameterLink("Filter.Department", "Department"));
	
	If ValueIsFilled(ProductionArea) Then
		ParametersArray.Add(New ChoiceParameterLink("Filter.ProductionArea", "ProductionArea"));
	EndIf;
	
	Items.WorkCenter.ChoiceParameterLinks = New FixedArray(ParametersArray);
	
EndProcedure

#EndRegion

#EndRegion
