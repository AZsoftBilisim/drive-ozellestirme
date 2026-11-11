
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("CommandParameter") Then
		ScriptObject = Parameters.CommandParameter; 
	Else
		Cancel = True;
		Return;
	EndIf;
	
	If TypeOf(ScriptObject) = Type("CatalogRef.AccessGroupProfiles") Then
		ObjectForScripts = ScriptObject; 
	ElsIf TypeOf(ScriptObject) = Type("CatalogRef.MetadataObjectIDs") Then
		ObjectForScripts = ScriptObject;
	Else
		ObjectForScripts = Common.MetadataObjectID(ScriptObject.Metadata());
		If Not ValueIsFilled(ObjectForScripts) Then
			Cancel = True;
			Return;
		EndIf;
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

&AtServer
Procedure GenerateReport()
	
	ReportTable.Clear();
	ObjectReport =  FormAttributeToValue("Report");
		
	ObjectReport.GenerateReport(ReportTable, ObjectForScripts)
	
EndProcedure

#EndRegion



