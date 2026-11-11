
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;

	InitializingFormWhenCreatingItOnServer();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CompleteConfiguration(Command)
	
	SettingsResult = New Structure;
	
	AddSelectionValue(Items.FilterStateList, "State", FilterStateList, SettingsResult);
	AddSelectionValue(Items.FilterOrganization, "Organization", FilterOrganization, SettingsResult);
	AddSelectionValue(Items.FilterDepartment, "Department", FilterDepartment, SettingsResult);
	AddSelectionValue(Items.FilterKindOfAccountingObject, "KindOfAccountingObject", FilterKindOfAccountingObject, SettingsResult);
	
	Close(SettingsResult);
	
EndProcedure

&AtClient
Procedure PurgeFilters(Command)

	FilterStateList.Clear();
	FilterOrganization = PredefinedValue("Catalog.Companies.EmptyRef");
	FilterDepartment = PredefinedValue("Catalog.BusinessStructure.EmptyRef");
	FilterKindOfAccountingObject = PredefinedValue("Enum.IntangibleAssetsAccountingItemKinds.EmptyRef");
		
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure InitializingFormWhenCreatingItOnServer()
	
	InformationDisplayMode = Parameters.InformationDisplayMode;
	
	FormServiceParameters = New FixedStructure(New Structure(Parameters.FormServiceParameters));
	
	FillInSelections();
	
	ConfigureDependentFormElementsOnServer();
	
EndProcedure

&AtServer
Procedure FillInSelections()
	
	ChoiceParameters = FormServiceParameters.ChoiceParameters;
	
	CompleteQuickSelection("State", ChoiceParameters.Filter, FilterStateList);
	CompleteQuickSelection("Organization", ChoiceParameters.Filter, FilterOrganization);
	CompleteQuickSelection("Department", ChoiceParameters.Filter, FilterDepartment);
	CompleteQuickSelection("KindOfAccountingObject", ChoiceParameters.Filter, FilterKindOfAccountingObject);
		
EndProcedure

&AtServer
Procedure ConfigureDependentFormElementsOnServer()
	
	If Not AccessRight("Read", Metadata.InformationRegisters.IntangibleAssetsRegistrationPlace)
		Or Not FormServiceParameters.UseMultipleCompanies
		Or InformationDisplayMode = "NotShow" Then

		Items.FilterOrganization.Visible = False;
		
	EndIf; 
	
	If Not AccessRight("Read", Metadata.InformationRegisters.IntangibleAssetsRegistrationPlace)
		Or Not FormServiceParameters.UseBusinessUnits
		Or InformationDisplayMode = "NotShow" Then

		Items.FilterDepartment.Visible = False;
		
	EndIf; 
		
	If Not AccessRight("Read", Metadata.InformationRegisters.IABookkeepingProcedureBookkeepingAndTaxAccounting) 
		Or Not AccessRight("Read", Metadata.InformationRegisters.IntangibleAssetsAccountingProcedureManagementAccounting)
		Or InformationDisplayMode = "NotShow" Then
		
		Items.FilterStateList.Visible = False;
	
	EndIf;
		
	ChoiceParameters = New Array;
	
	ChoiceParameterValue = New Array();
	ChoiceParameterValue.Add(Enums.IntangibleAssetsStates.PostedInFinancialAccounting);
	ChoiceParameterValue.Add(Enums.IntangibleAssetsStates.Received);
	ChoiceParameterValue.Add(Enums.IntangibleAssetsStates.WrittenOff_);
	ChoiceParameterValue.Add(Enums.IntangibleAssetsStates.NotPostedInFinancialAccounting);
	
	ChoiceParameters.Add(New ChoiceParameter("Filter.Ref", ChoiceParameterValue));
	
	Items.FilterStateList.ChoiceParameters = New FixedArray(ChoiceParameters);
	
EndProcedure

&AtServer
Procedure CompleteQuickSelection(FilterName, ListFilter, FilterElement)

	FilterValue = CommonClientServer.StructureProperty(ListFilter, FilterName, Undefined);
	
	If Not ValueIsFilled(FilterValue) Then
		Return;
	EndIf;
	
	If TypeOf(FilterElement) = Type("ValueList") Then
		
		If TypeOf(FilterValue) = Type("FixedArray") 
			Or TypeOf(FilterValue) = Type("Array") Then
		
			For Each Item In FilterValue Do
				FilterElement.Add(Item);
			EndDo;
		
		Else
			
			FilterElement.Add(FilterValue);
			
		EndIf;
	
	Else

		FilterElement = FilterValue;

	EndIf;
		
EndProcedure

&AtClient
Procedure AddSelectionValue(FilterElement, FilterName, FilterValue, SettingsResult)
	
	If Not FilterElement.Visible Then
		Return;
	EndIf;
		
	If TypeOf(FilterValue) = Type("ValueList") Then
		SettingsResult.Insert(FilterName, FilterValue.UnloadValues());
	Else
		SettingsResult.Insert(FilterName, FilterValue);
	EndIf;
	
EndProcedure

#EndRegion
