#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Variables

Var CurContainer; // DataProcessorObject.ExportImportDataContainerManager
Var CurSerializer;
Var CurLinks; // Array of AnyRef

#EndRegion

#Region Internal

// Initialize.
// 
// Parameters:
//  Container - DataProcessorObject.ExportImportDataContainerManager
//  Serializer - XDTOSerializer
Procedure Initialize(Container, Serializer) Export
	
	CurContainer = Container;
	CurSerializer = Serializer;
	
	CurLinks = New Array();
	
EndProcedure

Procedure RecreateLinkWhenUploading(Val Ref) Export
	
	CurLinks.Add(Ref);
	
	If CurLinks.Count() > FileLinkLimit() Then
		RecordReCreatedLinks();
	EndIf;
	
EndProcedure

Procedure Close() Export
	
	RecordReCreatedLinks();
	
EndProcedure

#EndRegion

#Region Private

Function FileLinkLimit()
	
	Return 34000;
	
EndFunction

Procedure RecordReCreatedLinks()
	
	If CurLinks.Count() = 0 Then
		Return;
	EndIf;
	
	FileName = CurContainer.CreateFile(ExportImportDataInternal.ReferenceRebuilding(), ExportImportDataInternal.CustomData());
	ExportImportData.WriteObjectToFile(CurLinks, FileName, CurSerializer);
	
	CurLinks.Clear();
	
EndProcedure

#EndRegion

#EndIf
