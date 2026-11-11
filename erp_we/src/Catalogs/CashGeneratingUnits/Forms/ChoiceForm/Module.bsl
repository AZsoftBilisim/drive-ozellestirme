#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
// A choice of CGU belonging to the company (branch office) or the parent company.
	If Not Parameters.Filter.Property("Owner") Then
		Cancel = True;
		Return;
	EndIf;
	
	If Parameters.Filter.Property("OnlyForSpecifiedOrganization") Then
		OnlyForSpecifiedOrganization = Parameters.Filter.OnlyForSpecifiedOrganization;
	EndIf;

	Organization = Parameters.Filter.Owner;

	If Not ValueIsFilled(Organization) Then
		OnReadCreateAtServer();
	EndIf;

	SetConditionalAppearance();

EndProcedure

&AtClient
Procedure OnOpen(Cancel)

	SetSelectionByOrganization();
	SetArchiveSelection();
	
EndProcedure
#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ShowArchivedRecordsOnChange(Item)
	
	SetArchiveSelection();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure OnReadCreateAtServer()
	
	UseMultipleCompanies       = GetFunctionalOption("UseMultipleCompanies");
	
	If Not UseMultipleCompanies Then
		If Not ValueIsFilled(Organization) Then
			Organization = SettingsValueCached.GetDefaultOrganization();
		EndIf;
	Else
		Organization = GetYourFirstBusiness();
	EndIf;
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
		ListDesign = List.SettingsComposer.Settings.ConditionalAppearance;
		ListDesign.Items.Clear();
		
		FormattingArchiveLines = ListDesign.Items.Add();
		
		SelectingArchiveLines = FormattingArchiveLines.Filter.Items.Add(Type("DataCompositionFilterItem"));
		SelectingArchiveLines.LeftValue = New DataCompositionField("Archive");
		SelectingArchiveLines.ComparisonType = DataCompositionComparisonType.Equal;
		SelectingArchiveLines.RightValue = True;
		
		FormattingArchiveLines.Appearance.SetParameterValue("TextColor", WebColors.LightGray);
	
EndProcedure

// Get the first organization.
//
// Returns:
//	CatalogRef.Companies - The first organization not marked for deletion
//
&AtServer
Function GetYourFirstBusiness()

	// We will get the first non-deleted organization
	Query = New Query;
	Query.Text = "SELECT TOP 1 ALLOWED
	|	Companies.Ref AS Organization
	|FROM
	|	Catalog.Companies AS Companies
	|WHERE
	|	Companies.DeletionMark = FALSE
	|	AND Companies.Predefined = FALSE
	|	AND Companies.Status = VALUE(Enum.BusinessUnitCompanyStatuses.Valid)
	|
	|ORDER BY
	|	Companies.Description";

	Result = Query.Execute();
	Selection = Result.Select();

	While Selection.Next() Do
		Return Selection.Organization;
	EndDo;

	Return Catalogs.Companies.EmptyRef();
	
EndFunction

// Set the selection by company in the list.
// 	We select either only for the specified company, or for the company and the parent company.
&AtClient
Procedure SetSelectionByOrganization()
	
	CompaniesList = New ValueList;
	CompaniesList.Add(Organization);
	
	If Not OnlyForSpecifiedOrganization Then
		ParentCompany = GeneralPurposeTMServerCall.ObjectAttributeValue(Organization, "ParentCompany");
		CompaniesList.Add(ParentCompany);
	EndIf;
	
	SelectionsByOrganization = CommonClientServer.FindFilterItemsAndGroups(List.Filter, "Owner");
	
	For Each FilterByCompany In SelectionsByOrganization Do
		
		FilterByCompany.ComparisonType = DataCompositionComparisonType.InList;
		FilterByCompany.RightValue = CompaniesList;
		
	EndDo;
	
EndProcedure

// Set the selection by archive.
//	We show either all elements, or only those where the archive attribute is not set.
&AtClient
Procedure SetArchiveSelection()
	
	SelectionsByArchive = CommonClientServer.FindFilterItemsAndGroups(List.Filter, "Archive");
	
	ListOfArchiveStatus = New ValueList();
	ListOfArchiveStatus.Add(False);
	ListOfArchiveStatus.Add(ShowArchivedRecords);
	
	If SelectionsByArchive.Count() = 0 Then
		ArchiveSelectionElement = CommonClientServer.AddCompositionItem(List.Filter,
									"Archive",
									DataCompositionComparisonType.InList,
									ListOfArchiveStatus,
									"",
									True);
		Return;
	EndIf;
		
	For Each ArchiveSelectionElement In SelectionsByArchive Do
		ArchiveSelectionElement.ComparisonType = DataCompositionComparisonType.InList;
		ArchiveSelectionElement.RightValue = ListOfArchiveStatus;
	EndDo;

EndProcedure

#EndRegion
