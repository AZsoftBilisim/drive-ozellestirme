#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If Parameters.Property("OnlyCompaniesWithBranches") And Parameters.OnlyCompaniesWithBranches Then
		OnlyCompaniesWithBranches = True;
	EndIf;
	
	DisplayOrganizationSelection = True;
	
	If Parameters.Property("Filter") Then 
	
		If Parameters.Filter.Property("CompaniesList") Then
			CommonClientServer.SetDynamicListFilterItem(List, "Owner",
				Parameters.Filter.CompaniesList, DataCompositionComparisonType.InList, , True,
				DataCompositionSettingsItemViewMode.Inaccessible);
			DisplayOrganizationSelection = False;
		EndIf;
			
		If Parameters.Filter.Property("ListOfBanks") Then
			CommonClientServer.SetDynamicListFilterItem(List, "Bank",
				Parameters.Filter.ListOfBanks, DataCompositionComparisonType.InList, , True,
				DataCompositionSettingsItemViewMode.Inaccessible);
		EndIf;
		
		If Parameters.Filter.Property("Owner") Then
			
			If Parameters.Property("IncludeBranchAccounts") And Parameters.IncludeBranchAccounts Then
				IncludeBranchAccounts = True;
				CompanyFilter = Parameters.Filter.Owner;
				SetFilterWithBranches();
				Parameters.Filter.Delete("Owner");
			ElsIf ValueIsFilled(Parameters.Filter.Owner) Then
				DisplayOrganizationSelection = False;
			EndIf;
			
		EndIf;
		
	EndIf;
	
	CommonClientServer.SetDynamicListFilterItem(
		List, "Closed", False, DataCompositionComparisonType.Equal, , ?(Not DisplayClosedAccounts, True, False),
		DataCompositionSettingsItemViewMode.Inaccessible);
	
	If Parameters.Property("VisibilityOfFilterByOrganization") Then
		DisplayOrganizationSelection = Parameters.VisibilityOfFilterByOrganization;
	EndIf;
	
	MultipleCompanies = GetFunctionalOption("UseMultipleCompanies");
	Items.Organization.Visible = MultipleCompanies;
	Items.CompanyFilter.Visible = DisplayOrganizationSelection
											And MultipleCompanies;
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	CashServerLocalization.AddBankAccountCreationCommands(ThisObject, Metadata.Catalogs.CompaniesBankAccounts);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

 &AtClient
Procedure CompanyFilterOnChange(Item)

	If IncludeBranchAccounts Then
		SetFilterWithBranches();
	Else
		CommonClientServer.SetDynamicListFilterItem(
			List, "Owner", CompanyFilter, , , ValueIsFilled(CompanyFilter));
	EndIf;

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.List);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_CreateBankAccount(Command)
	CashClientLocalization.OpenBankAccountCreation(List, Command);
EndProcedure

&AtClient
Procedure Show_ClosedAccounts(Command)

	Items.FormShow_ClosedAccounts.Check = Not DisplayClosedAccounts;
	DisplayClosedAccounts = Not DisplayClosedAccounts;
	CommonClientServer.SetDynamicListFilterItem(
		List, "Closed", False, DataCompositionComparisonType.Equal, , ?(Not DisplayClosedAccounts, True, False),
		DataCompositionSettingsItemViewMode.Inaccessible);

EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetFilterWithBranches()
	
	ArrayWithBranches = Catalogs.Companies.ArrayOfInterconnectedOrganizations(CompanyFilter);
	ArrayWithBranches.Add(CompanyFilter);
	CompaniesList = New ValueList;
	CompaniesList.LoadValues(ArrayWithBranches);
	CommonClientServer.SetDynamicListFilterItem(List, "Owner",
		CompaniesList, DataCompositionComparisonType.InList, , 
		ValueIsFilled(CompanyFilter) Or OnlyCompaniesWithBranches,
		DataCompositionSettingsItemViewMode.Inaccessible);
	
EndProcedure

#EndRegion
