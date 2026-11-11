#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	PickUpResearch(ThisObject, Parameters.ListOfStudies);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersDocuments

&AtClient
Procedure DocumentsSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.Documents.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	FormParameters = New Structure("Key", CurrentData.ResearchProject);
	OpenForm("Document.GoodsQualityResearch.Form.DocumentForm",FormParameters,ThisObject)
	
EndProcedure

#EndRegion

#Region Private

#Region Filter

&AtServer
Procedure PickUpResearch(Form, ListOfStudies)
	
	For Each String In ListOfStudies Do
		NewRow = Documents.Add();
		FillPropertyValues(NewRow, String);
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion