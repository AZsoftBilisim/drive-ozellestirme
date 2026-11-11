
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	PurchaseOrder = Undefined;
	
	If Parameters.Property("CommandParameter", PurchaseOrder) 
			Or Parameters.Property("PurchaseOrder", PurchaseOrder) Then
		
		If TypeOf(PurchaseOrder) = Type("DocumentRef.PurchaseOrder") Then
			OrderDocuments.Add(Parameters.Partner);
		ElsIf TypeOf(PurchaseOrder) = Type("Array") Then
			OrderDocuments.LoadValues(PurchaseOrder);
		EndIf;
		
	Else
		
		Cancel = True;
		
	EndIf;
	
	GenerateReport();

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Generate(Command)
	GenerateReport();
EndProcedure

#EndRegion

#Region Private

#Region Other

&AtServer
Procedure GenerateReport()

	ReportTable.Clear();
	ObjectReport = FormAttributeToValue("Report");
	
	For Each DocumentOrderNumber__1 In OrderDocuments Do
		
		ObjectReport.GenerateReport(ReportTable, DocumentOrderNumber__1.Value)
		
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion
