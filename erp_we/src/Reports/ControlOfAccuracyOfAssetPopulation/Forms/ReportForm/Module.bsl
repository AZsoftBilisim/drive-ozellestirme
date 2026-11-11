
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Parameters.Property("Asset") Then
		
		Report.Asset = Parameters.Asset;
		
	Else
		
		Cancel = True;
		
	EndIf;
	
	If Not Cancel Then
		GenerateReport();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ResultDetailProcessing(Item, Details, StandardProcessing)
	
	StandardProcessing = False;
	
	FormPath = "Catalog.Assets.ObjectForm";
	If TypeOf(Details) = Type("CatalogRef.SubAssets") Then
		FormPath = "Catalog.SubAssets.ObjectForm";
	EndIf;
	
	OpenForm(
		FormPath,
		New Structure(
			"Key, ReportAboutErrors",
			Details, True));
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Generate(Command)
	GenerateReport();
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure GenerateReport()
	
	ReportTable.Clear();
	
	ObjectReport = FormAttributeToValue("Report");
	ObjectReport.GenerateReport(ReportTable)
	
EndProcedure

#EndRegion
