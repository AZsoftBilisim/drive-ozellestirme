
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	DocumentKindList.Clear();
	If Parameters.Property("DocumentKindList") Then
		For Each Item In Parameters.DocumentKindList Do

			NewItem = DocumentKindList.Add();
			FillPropertyValues(NewItem, Item);

		EndDo;
	EndIf;

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Save(Command)

	Close(DocumentKindList);

EndProcedure

#EndRegion
