
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	FillInReports();
	
	SetSearchGroupVisibility(Items);

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersSelectedReports

&AtClient
Procedure SelectedReportsEnabledOnChange(Item)
	
	SelectedUser = Items.SelectedReports.CurrentData;
	
	RowToRefresh = Reports.FindByID(SelectedUser.ReportLineID);
	RowToRefresh.Enabled = SelectedUser.Enabled;
	
	If Not SelectedUser.Enabled Then
		
		SelectedReports.Delete(SelectedReports.IndexOf(SelectedUser));
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CompleteEditing(Command)
	
	If Items.ReportSelectionPage.CurrentPage = Items.SelectedReportPage Then
		For Each SelectedReport In SelectedReports Do
			CurrentData = Reports.FindByID(SelectedReport.ReportLineID);
			CurrentData.Enabled = SelectedReport.Enabled;
			
		EndDo; 
	Else
		SelectedReports.Clear();
		
		FillInListOfSelectedReports();
		
	EndIf;
	
	StorageAddressForSelectedReports = StorageAddressForSelectedReports();
	
	Close(StorageAddressForSelectedReports);
	
EndProcedure

&AtClient
Procedure SelectAllCommand(Command)
	
	// Let's set the availability mark
	For Each ReportVariant In Reports Do 
		ReportVariant.Enabled = True;
		
	EndDo;
	
	UpdateListOfSelectedReports();
	
EndProcedure

&AtClient
Procedure ShowOnlySelectedReports(Command)
	
	OnlySelectedOnes = Items.FormShowOnlySelectedReports.Check;
	
	If OnlySelectedOnes Then
		
		For Each SelectedUser In SelectedReports Do 
			
			CurrentData = Reports.FindByID(SelectedUser.ReportLineID);
			CurrentData.Enabled = SelectedUser.Enabled;
			
		EndDo;
		
		Items.ReportSelectionPage.CurrentPage = Items.PageOfReports;
		
	Else
		
		SelectedReports.Clear();
		
		FillInListOfSelectedReports();
		
		Items.ReportSelectionPage.CurrentPage = Items.SelectedReportPage;
		
	EndIf;
	
	Items.FormShowOnlySelectedReports.Check = Not OnlySelectedOnes;
	
	SetSearchGroupVisibility(Items);
	
EndProcedure

&AtClient
Procedure ClearAll(Command)
	
	// Remove the availability mark
	For Each ReportVariant In Reports Do 
		ReportVariant.Enabled = False;
		
	EndDo;
	
	UpdateListOfSelectedReports();
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

// Places a table of values with the selected reports in temporary storage
// and returns the address.
// 
// Returns:
//	String - the address of the value storage of the value table in the temporary storage.
//
&AtServer 
Function StorageAddressForSelectedReports()
	
	SelectedReportsObject = FormAttributeToValue("SelectedReports");
	
	StorageAddressForSelectedReports = PutToTempStorage(New ValueStorage(SelectedReportsObject));
	
	Return StorageAddressForSelectedReports;
	
EndFunction

&AtServer 
Procedure FillInReports()
	
	Query = New Query;
	Query.SetParameter("ReportsOptions", Parameters.ReportsOptions.Unload(,"ReportVariant"));
	Query.SetParameter("DIsabledApplicationOptions", ReportsOptionsCached.DIsabledApplicationOptions());
	Query.Text = "SELECT ALLOWED
	|	Variants.Ref AS ReportVariant,
	|	COUNT(Variants.Ref) AS Count
	|INTO ReportsOptions
	|FROM
	|	Catalog.ReportsOptions AS Variants
	|		LEFT JOIN Catalog.PredefinedReportsOptions AS PredefinedReportsOptions
	|		ON Variants.PredefinedOption = PredefinedReportsOptions.Ref
	|			AND (NOT PredefinedReportsOptions.Ref IN (&DIsabledApplicationOptions))
	|WHERE
	|	Variants.Ref IN(&ReportsOptions)
	|	AND NOT Variants.PredefinedOption IN (&DIsabledApplicationOptions)
	|	AND NOT Variants.DeletionMark
	|
	|GROUP BY
	|	Variants.Ref
	|
	|INDEX BY
	|	ReportVariant
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ReportsOptions.Ref AS ReportVariant,
	|	CASE
	|		WHEN ReportOptionsInUnsavedCalculationOption.Count = 1
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS Enabled
	|FROM
	|	Catalog.ReportsOptions AS ReportsOptions
	|		LEFT JOIN ReportsOptions AS ReportOptionsInUnsavedCalculationOption
	|		ON ReportsOptions.Ref = ReportOptionsInUnsavedCalculationOption.ReportVariant
	|WHERE
	|	NOT ReportsOptions.PredefinedOption IN (&DIsabledApplicationOptions)
	|	AND NOT ReportsOptions.DeletionMark
	|
	|ORDER BY
	|	ReportsOptions.Description";
	QueryResult = Query.Execute();
	
	If Not QueryResult.IsEmpty() Then
		ReportsFromRequest = QueryResult.Unload();
		
		For Each ReportFromRequest In ReportsFromRequest Do
			NewVersionOfReport = Reports.Add();
			
			FillPropertyValues(NewVersionOfReport, ReportFromRequest);
			
		EndDo;
		
	EndIf;
	
EndProcedure

&AtClient 
Procedure FillInListOfSelectedReports()
	
	For Each Report In Reports Do
		
		If Report.Enabled Then
			ReportLineID = Report.GetID();
			
			NewSelectedUser = SelectedReports.Add();
			NewSelectedUser.ReportVariant = Report.ReportVariant;
			NewSelectedUser.Enabled = True;
			NewSelectedUser.ReportLineID = ReportLineID;
			
		EndIf;
		
	EndDo;
	
	SelectedReports.Sort("ReportVariant");
	
EndProcedure

&AtClient 
Procedure UpdateListOfSelectedReports()
	
	SelectedReports.Clear();
	
	FillInListOfSelectedReports();
	
EndProcedure

&AtClientAtServerNoContext 
Procedure SetSearchGroupVisibility(Items)
	
	OnlySelectedOnes = Items.FormShowOnlySelectedReports.Check;
	
	Items.SearchGroupForAllReports.Visible = Not OnlySelectedOnes;
	Items.SearchGroupBySelected.Visible = OnlySelectedOnes;

EndProcedure

#EndRegion
