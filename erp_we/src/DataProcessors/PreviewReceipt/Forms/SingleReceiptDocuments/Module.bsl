
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	ArrayOfDocumentsForSingleReceipt = Parameters.SingleReceiptDocuments;
	For Each DocumentData In ArrayOfDocumentsForSingleReceipt Do
		SingleReceiptDocumentsLine = SingleReceiptDocuments.Add();
		SingleReceiptDocumentsLine.Document = DocumentData.Document;
		SingleReceiptDocumentsLine.Sum = DocumentData.Sum;
	EndDo;
	
EndProcedure

&AtClient
Procedure SingleReceiptDocumentsSelection(Item, RowSelected, Field, StandardProcessing)
	StandardProcessing = False;

	ValueForDisplay = Undefined;
	If TypeOf(RowSelected) = Type("Array") Then
		If RowSelected.Count() = 1 Then
			ValueForDisplay = SingleReceiptDocuments[RowSelected[0]].Document;
		Else
			Return;
		EndIf;
	Else
		ValueForDisplay = SingleReceiptDocuments[RowSelected].Document;
	EndIf;
	
	If ValueIsFilled(ValueForDisplay) Then
		ShowValue(Undefined, ValueForDisplay);
	EndIf;
EndProcedure

#EndRegion