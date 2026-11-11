
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Parameters.Property("CommandParameter") Then
		
		ParameterType = TypeOf(Parameters.CommandParameter);
		
		If ParameterType = Type("Array")
			Or ParameterType = Type("CatalogRef.Assets")
			Or ParameterType = Type("CatalogRef.SubAssets") Then
			
			FillInReportObjects(Parameters.CommandParameter);
			
		Else
			
			Cancel = True;
			
		EndIf;
		
	Else
		
		Cancel = True;
		
	EndIf;
	
	If ReportObjects.Count() = 0 Then
		Cancel = True;
	EndIf;
	
	If Not Cancel Then
		LoadSettings();
		GenerateReport();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Generate(Command)
	
	ShouldSaveSettings();
	ClearMessages();
	GenerateReport();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillInReportObjects(Parameter)
	
	Query = New Query(
		"SELECT
		|	Assets.Ref AS Ref
		|FROM
		|	Catalog.Assets AS Assets
		|WHERE
		|	Assets.Ref IN(&Parameter)
		|	AND NOT Assets.DeletionMark
		|	AND NOT Assets.IsFolder
		|
		|UNION ALL
		|
		|SELECT
		|	SubAssets.Ref
		|FROM
		|	Catalog.SubAssets AS SubAssets
		|WHERE
		|	SubAssets.Ref IN(&Parameter)
		|	AND NOT SubAssets.DeletionMark");
	Query.SetParameter("Parameter", Parameter);
	
	ReportObjects.LoadValues(Query.Execute().Unload().UnloadColumn("Ref"));
	
EndProcedure

&AtServer
Procedure GenerateReport()
	
	ReportTable.Clear();
	
	ObjectReport = FormAttributeToValue("Report");
	
	For Each Asset In ReportObjects Do
		
		ObjectReport.GenerateReport(ReportTable, Asset.Value)
		
	EndDo;
	
EndProcedure

&AtServer
Procedure ShouldSaveSettings()

	Var Settings;
	
	Settings = New Structure(
		"PassportData,
		|Subassemblies,
		|RunningTime,
		|AssetsMaintenance,
		|ClosedRMOrders,
		|CurrentDefects,
		|FixedDefects");
	FillPropertyValues(Settings, Report);
	
	Common.CommonSettingsStorageSave("Report.AssetCard", "ReportForm", Settings);
	
EndProcedure

&AtServer
Procedure LoadSettings()
	
	Var SettingsValue;
	SettingsValue = Common.CommonSettingsStorageLoad("Report.AssetCard", "ReportForm");
	
	If SettingsValue = Undefined Then
		
		Report.PassportData = True;
		Report.Subassemblies = True;
		Report.RunningTime = True;
		Report.AssetsMaintenance = True;
		Report.ClosedRMOrders = True;
		Report.CurrentDefects = True;
		Report.FixedDefects = True;
		
	ElsIf TypeOf(SettingsValue) = Type("Structure") Then
		
		FillPropertyValues(Report, SettingsValue);
		
	EndIf;

EndProcedure

#EndRegion
