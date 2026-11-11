#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// When opening from the directory of the organization, fill in from the parameters of opening the form.
	Parameters.Filter.Property("Owner", Organization);
	
	If ValueIsFilled(Organization) Then
		Items.Organization.ReadOnly = True;
	Else
		// Opened from the VNA Reference panel
		OnReadCreateAtServer();
	EndIf;

	VisibilityManagement();
	SetConditionalAppearance();
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)

	SetSelectionInList();
	SetArchiveSelection();

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers
// Create a group.
// Opens the form for creating a new CGU group, and sets the owner in it - the parent company.
// 
// Parameters:
//  Command - FormCommand - Command
&AtClient
Procedure CreateFolder(Command)
	CreateGroupItem("Catalog.CashGeneratingUnits.Form.FolderForm", True);
EndProcedure

// Create a new CGU.
// Opens the form for creating a new CGU, and sets the owner in it - the parent company.
// 
// Parameters:
//  Command - FormCommand - Command
&AtClient
Procedure Create(Command)
	CreateGroupItem("Catalog.CashGeneratingUnits.Form.ItemForm", False);
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure OrganizationOnChange(Item)
	
	SetSelectionInList();
	
EndProcedure

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
Procedure VisibilityManagement()
	
	UseMultipleCompanies = GetFunctionalOption("UseMultipleCompanies");
	Items.Organization.Visible = UseMultipleCompanies;
	
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
// CatalogRef.Companies - The first organization not marked for deletion
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

&AtServer
Function GetParentOrganization()
	
	Return GeneralPurposeTMServerCall.ObjectAttributeValue(Organization, "ParentCompany");
	
EndFunction

&AtClient
Procedure CreateGroupItem(Var_FormName, CreateFolder)
	
	ParametersOfNewElement = New Structure;
	ParametersOfNewElement.Insert("Owner", Organization);
	ParametersOfNewElement.Insert("CurrentCompany", Organization);
		
	FillingValues = New Structure();
	FillingValues.Insert("FillingValues", ParametersOfNewElement);
	FillingValues.Insert("IsFolder", CreateFolder);
	
	OpenForm(Var_FormName, FillingValues, ThisObject);
						
EndProcedure

#Region Initialize
// Set the selection in the list by the list of companies.
// The CGU belonging to the parent company and the branch office are selected.
&AtServer
Procedure SetSelectionInList()
	
	ParentCompany = GetParentOrganization();
	
	CompaniesList = New ValueList;
	CompaniesList.Add(Organization);
	If CompaniesList.FindByValue(ParentCompany) = Undefined Then
		CompaniesList.Add(ParentCompany);
	EndIf;
	
	SelectionsByOrganization = CommonClientServer.FindFilterItemsAndGroups(List.Filter, "Owner");
	
	If SelectionsByOrganization.Count() = 0 Then
		CommonClientServer.AddCompositionItem(List.Filter,
										"Owner",
										DataCompositionComparisonType.InList,
										CompaniesList,
										"",
										True);
		Return;
	EndIf;
	
	For Each FilterByCompany In SelectionsByOrganization Do
		FilterByCompany.ComparisonType = DataCompositionComparisonType.InList;
		FilterByCompany.RightValue = CompaniesList;
	EndDo;

EndProcedure

// Set the selection by archive.
// Either all CGU are selected, or only those that do not have the Archive attribute.
&AtServer
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
#EndRegion