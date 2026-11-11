
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Parameters.Property("CommandParameter") Then
		DocumentSales = Parameters.CommandParameter;
	ElsIf Parameters.Property("DocumentSales") Then
		DocumentSales = Parameters.DocumentSales;
	Else 
		Cancel = True;
	EndIf;
	
	If Not ValueIsFilled(DocumentSales) Then
		Cancel = True;
	EndIf;
	
	If Not Cancel Then
		GenerateReport();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Generate(Command)
	ClearMessages();
	GenerateReport();
EndProcedure 

#EndRegion

#Region Private

&AtServer
Procedure GenerateReport()
	
	ReportTable.Clear();
	SalesServer.GenerateReportDeviationsFromSalesConditions(DocumentSales,ReportTable);
	
EndProcedure

#EndRegion
