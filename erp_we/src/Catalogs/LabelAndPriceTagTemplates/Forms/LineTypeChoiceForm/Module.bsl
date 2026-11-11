
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	If TypeOf(Parameters.LineType) = Type("SpreadsheetDocumentCellLineType") Then
		Types = SpreadsheetDocumentCellLineType;
	ElsIf TypeOf(Parameters.LineType) = Type("SpreadsheetDocumentDrawingLineType") Then
		Types = SpreadsheetDocumentDrawingLineType;
	EndIf;
	
	For Each Type In Types Do
		Items.LineType.ChoiceList.Add(Type);
	EndDo;
	
	LineType = Parameters.LineType;
	Width = Parameters.Width;
	
	If Width = 0 Then
		Width = 1;
	EndIf;
	
	If LineType = SpreadsheetDocumentCellLineType.None
		Or LineType = SpreadsheetDocumentCellLineType.Double
		Or LineType = SpreadsheetDocumentDrawingLineType.None Then
		Items.Width.Enabled = False;
	Else
		Items.Width.Enabled = True;
	EndIf;

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure LineTypeOnChange(Item)
	
	If LineType = SpreadsheetDocumentCellLineType.None
		Or LineType = SpreadsheetDocumentCellLineType.Double
		Or LineType = SpreadsheetDocumentDrawingLineType.None Then
		Items.Width.Enabled = False;
		Width = 1;
	Else
		Items.Width.Enabled = True;
	EndIf;
	
	If LineType = SpreadsheetDocumentCellLineType.Double Then
		Items.Width.MaxValue = 1;
	Else
		Items.Width.MaxValue = 3;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	Close(New Structure("LineType, Width", LineType, Width));
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion
