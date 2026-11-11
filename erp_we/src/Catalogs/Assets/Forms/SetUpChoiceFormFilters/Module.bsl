
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
	
	AddSelectionValue(Items.FilterStatus, "Status", FilterStatus, SettingsResult);
	AddSelectionValue(Items.SelectionGroupOfOsspisc, "OSGroup", SelectionGroupOfOsspisc, SettingsResult);
	AddSelectionValue(Items.FilterOperatingBusinessUnit, "OperatingBusinessUnit", FilterOperatingBusinessUnit, SettingsResult);
	AddSelectionValue(Items.FilterRMBusinessUnit, "RMBusinessUnit", FilterRMBusinessUnit, SettingsResult);
	AddSelectionValue(Items.FilterStateList, "State", FilterStateList, SettingsResult);
	AddSelectionValue(Items.FilterOrganization, "Organization", FilterOrganization, SettingsResult);
	AddSelectionValue(Items.FilterDepartment, "Department", FilterDepartment, SettingsResult);
	AddSelectionValue(Items.FilterFinanciallyLiablePerson, "FINANCIALLYLIABLEPERSON", FilterFinanciallyLiablePerson, SettingsResult);
	AddSelectionValue(Items.FilterDepreciationGroupList, "DepreciationGroup", FilterDepreciationGroupList, SettingsResult);
	AddSelectionValue(Items.FilterResidualPeriodOfUse, "ResidualPeriodOfUseTypeOfAccounting", FilterResidualPeriodOfUseTypeOfAccounting, SettingsResult);
	
	If FilterResidualPeriodOfUseTypeOfAccounting = "ACC" Then
		AddSelectionValue(Items.FilterResidualPeriodOfUse, "ResidualLifetimeAC", FilterResidualPeriodOfUse, SettingsResult);
		AddSelectionValue(Items.FilterResidualPeriodOfUse, "ResidualLifetimeMA", 0, SettingsResult);
	Else
		AddSelectionValue(Items.FilterResidualPeriodOfUse, "ResidualLifetimeAC", 0, SettingsResult);
		AddSelectionValue(Items.FilterResidualPeriodOfUse, "ResidualLifetimeMA", FilterResidualPeriodOfUse, SettingsResult);
	EndIf;
	
	Close(SettingsResult);
	
EndProcedure

&AtClient
Procedure PurgeFilters(Command)

	FilterStatus = PredefinedValue("Enum.AssetStatuses.EmptyRef"); 
	FilterStateList.Clear();
	FilterOrganization = PredefinedValue("Catalog.Companies.EmptyRef");
	FilterDepartment = PredefinedValue("Catalog.BusinessStructure.EmptyRef");
	FilterFinanciallyLiablePerson = PredefinedValue("Catalog.Persons.EmptyRef");
	FilterOperatingBusinessUnit = PredefinedValue("Catalog.BusinessStructure.EmptyRef");
	SelectionGroupOfOsspisc.Clear();
	FilterDepreciationGroupList.Clear();
	FilterResidualPeriodOfUse = 0;
	FilterRMBusinessUnit = PredefinedValue("Catalog.BusinessStructure.EmptyRef");
		
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
	
	CompleteQuickSelection("Status", ChoiceParameters.Filter, FilterStatus);
	CompleteQuickSelection("State", ChoiceParameters.Filter, FilterStateList);
	CompleteQuickSelection("Organization", ChoiceParameters.Filter, FilterOrganization);
	CompleteQuickSelection("Department", ChoiceParameters.Filter, FilterDepartment);
	CompleteQuickSelection("FINANCIALLYLIABLEPERSON", ChoiceParameters.Filter, FilterFinanciallyLiablePerson);
	CompleteQuickSelection("OSGroup", ChoiceParameters.Filter, SelectionGroupOfOsspisc);
	CompleteQuickSelection("DepreciationGroup", ChoiceParameters.Filter, FilterDepreciationGroupList);
	CompleteQuickSelection("OperatingBusinessUnit", ChoiceParameters.Filter, FilterOperatingBusinessUnit);
	CompleteQuickSelection("RMBusinessUnit", ChoiceParameters.Filter, FilterRMBusinessUnit);
	
	FilterResidualPeriodOfUseTypeOfAccounting = "MA";
	CompleteQuickSelection("ResidualPeriodOfUseTypeOfAccounting", ChoiceParameters.Filter, FilterResidualPeriodOfUseTypeOfAccounting);
	
	If FilterResidualPeriodOfUseTypeOfAccounting = "ACC" Then
		CompleteQuickSelection("ResidualLifetimeAC", ChoiceParameters.Filter, FilterResidualPeriodOfUse);
	Else
		CompleteQuickSelection("ResidualLifetimeMA", ChoiceParameters.Filter, FilterResidualPeriodOfUse);
	EndIf;
	
EndProcedure

&AtServer
Procedure ConfigureDependentFormElementsOnServer()
	
	If FormServiceParameters.FALocalAccountingIsConductedIndependently Then
		Items.FilterResidualPeriodOfUseTypeOfAccounting.ChoiceList.Add("ACC", NStr("vi = 'KTDN';
																					|ru = 'БУ';
																					|en = 'LA'; fa = 'محلی';
																					|it = 'БУ';
																					|pl = 'LA';
																					|tr = 'Genel Muhasebe'"));
	EndIf;

	If Not FormServiceParameters.UseRMManagement  Then

		Items.FilterStatus.Visible = False;
		
	EndIf; 
	
	If Not AccessRight("Read", Metadata.InformationRegisters.FALocation)
		Or Not FormServiceParameters.UseMultipleCompanies
		Or InformationDisplayMode = "NotShow" Then

		Items.FilterOrganization.Visible = False;
		
	EndIf; 
	
	If Not AccessRight("Read", Metadata.InformationRegisters.FALocation)
		Or Not FormServiceParameters.UseBusinessUnits
		Or InformationDisplayMode = "NotShow" Then

		Items.FilterDepartment.Visible = False;
		
	EndIf; 
	
	If Not AccessRight("Read", Metadata.InformationRegisters.FALocation)
		Or InformationDisplayMode = "NotShow" Then

		Items.FilterFinanciallyLiablePerson.Visible = False;
		
	EndIf; 
	
	If Not NonCurrentAssetsInternal.ThereAreRightsToReadStateOfFA()
		Or InformationDisplayMode = "NotShow" Then
		
		Items.FilterStateList.Visible = False;
	
	EndIf;
	
	If Not AccessRight("Read", Metadata.InformationRegisters.AccountingProcedureForOSBU)
		Or InformationDisplayMode = "NotShow"
		Or Not FormServiceParameters.LocalFAAccounting Then
		
		Items.FilterDepreciationGroupList.Visible = False;
	
	EndIf;

	If Not AccessRight("Read", Metadata.InformationRegisters.AccountingProcedureForOSBU)
			And Not AccessRight("Read", Metadata.InformationRegisters.FixedAssetsAccountingProcedureManagementAccounting)
		Or InformationDisplayMode = "NotShow" Then
		
		Items.FilterResidualPeriodOfUse.Visible = False;
		Items.DecorationInscriptionMonths.Visible = False;
	
	EndIf;
	
	If Not AccessRight("Read", Metadata.InformationRegisters.AccountingProcedureForOSBU)
			And Not AccessRight("Read", Metadata.InformationRegisters.FixedAssetsAccountingProcedureManagementAccounting)
		Or InformationDisplayMode = "NotShow"
		Or Items.FilterResidualPeriodOfUseTypeOfAccounting.ChoiceList.Count() < 2 Then
		
		Items.FilterResidualPeriodOfUseTypeOfAccounting.Visible = False;
	
	EndIf;
	
	If Not FormServiceParameters.UseBusinessUnits Then

		Items.FilterOperatingBusinessUnit.Visible = False;
		Items.FilterRMBusinessUnit.Visible = False;
		
	EndIf; 
	
	ChoiceParameters = New Array;
	
	ChoiceParameterValue = New Array();
	ChoiceParameterValue.Add(Enums.FixedAssetsStates.Recognized_);
	If FormServiceParameters.LocalFAAccounting Then
		ChoiceParameterValue.Add(Enums.FixedAssetsStates.EnteredInOffBalanceAccounting);
	EndIf;
	ChoiceParameterValue.Add(Enums.FixedAssetsStates.TakenOffBooks);
	ChoiceParameterValue.Add(Enums.FixedAssetsStates.NotRecognized_);
	
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
