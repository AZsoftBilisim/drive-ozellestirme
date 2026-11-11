
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		
		Return;
		
	EndIf;
	
	UploadFormSettings();
	
	If Parameters.Property("RouteSheet") Then
		
		Report.RouteSheet = Parameters.RouteSheet;
		GenerateReport();
		
	Else
		
		SetReportState(Items.SpreadsheetDocumentField, False);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure RouteSheetOnChange(Item)
	
	SetReportState(Items.SpreadsheetDocumentField, False);
	SaveFormSettingsClient();
	
EndProcedure

&AtClient
Procedure ShowNestedRoutesOnChange(Item)
	
	SetReportState(Items.SpreadsheetDocumentField, False);
	SaveFormSettingsClient();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Generate(Command)
	
	ClearMessages();
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	GenerateReport();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure GenerateReport()
	
	ReportObject = FormAttributeToValue("Report");
	ReportObject.GenerateReport(SpreadsheetDocumentField);
	
	SetReportState(Items.SpreadsheetDocumentField, True);
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetReportState(SpreadsheetDocumentField, Generated1)
	
	If Not Generated1 Then
		State = "Irrelevance";
	Else
		State = "DontUse";
	EndIf;
	
	CommonClientServer.SetSpreadsheetDocumentFieldState(SpreadsheetDocumentField, State);
	
EndProcedure

&AtServer
Procedure UploadFormSettings()
	
	Settings = Common.CommonSettingsStorageLoad(
		FormKey(),
		FormSettingsKey());
	
	If TypeOf(Settings) = Type("Structure") Then
		
		FillPropertyValues(Report, Settings);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SaveFormSettingsClient()
	
	Settings = New Structure;
	Settings.Insert("RouteSheet", Report.RouteSheet);
	Settings.Insert("ShowOperationsOfNestedRoutes", Report.ShowOperationsOfNestedRoutes);
	
	SaveFormSettingsServer(Settings);
	
EndProcedure

&AtServerNoContext
Procedure SaveFormSettingsServer(Settings)
	
	Common.CommonSettingsStorageSave(
		FormKey(),
		FormSettingsKey(),
		Settings);
	
EndProcedure

&AtServerNoContext
Function FormKey()
	
	Return "Report.RouteSheetChart.ReportForm";
	
EndFunction

&AtServerNoContext
Function FormSettingsKey()
	
	Return "Main_";
	
EndFunction

#EndRegion
