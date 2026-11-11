
#Region FormEventHandlers

&AtClient
Procedure BeforeClose(Cancel, StandardProcessing)
	
	If ValueIsFilled(ItemAddressInStorage) Then
		StandardProcessing = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	Catalogs.FinancialReportItems.FormWhenCreatedOnServer(ThisForm);
	Title = Parameters.ItemKind;

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	SubstitutionParameters = GetReportSubstitutionParameters();
	AddSubstitutionParameterCommands(SubstitutionParameters);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	Catalogs.FinancialReportItems.FormBeforeWritingToServer(ThisForm, CurrentObject, Cancel);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CommentStartChoice(Item, ChoiceData, StandardProcessing)
	
	CommonClient.ShowCommentEditingForm(
		Item.EditText, 
		ThisObject, 
		"Object.Comment");
	
EndProcedure

&AtClient
Procedure TextBlockOnChange(Item)
	
	Object.NameForPrinting = TrimAll(StrGetLine(Text, 1));
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CompleteEditing(Command)
	
	AdditionalProperties = New Structure("PresentationIsForPrintingOnly", "");
	
	FinancialReportingClient.FinishEditingReportElement(ThisForm, AdditionalProperties);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure AddSubstitutionParameterCommands(SubstitutionParameters)
	
	NameOfCommandAction = "Attachable_AddSubstitutionTemplate";
	
	For Each ParameterNameAndPresentation In SubstitutionParameters Do
		
		FormCommand = ThisForm.Commands.Add(ParameterNameAndPresentation.Name);
		FormCommand.Action = NameOfCommandAction;
		
		NewFormButton = Items.Add(ParameterNameAndPresentation.Name, Type("FormButton"), Items.AddParameter);
		NewFormButton.CommandName = ParameterNameAndPresentation.Name;
		NewFormButton.Title = ParameterNameAndPresentation.Presentation;
		
	EndDo;
	
EndProcedure

&AtServer
Function GetReportSubstitutionParameters()
	
	ParametersArray = FinancialReportingClientServer.OrderedVariablesOfFinancialStatements();
		
	Return ParametersArray;
	
EndFunction


// The command to connect. Adds a wildcard template.
// 
// Parameters:
// 	Command - FormCommand -
&AtClient
Procedure Attachable_AddSubstitutionTemplate(Command)
	 
	InsertTextInTitle("["+ Command.Name +"]");
	
EndProcedure

&AtClient
Procedure InsertTextInTitle(TextForInsert, Move = 0)
	
	RowStart = 0;
	RowEnd = 0;
	ColumnStart = 0;
	ColumnEnd = 0;
	
	Items.TextBlock.GetTextSelectionBounds(RowStart, ColumnStart, RowEnd, ColumnEnd);
	
	If (ColumnEnd = ColumnStart) And (ColumnEnd + StrLen(TextForInsert)) > Items.TextBlock.Width / 8 Then
		Items.TextBlock.SelectedText = "";
	EndIf;
	
	Items.TextBlock.SelectedText = TextForInsert;
	
	If Not Move = 0 Then
		Items.TextBlock.GetTextSelectionBounds(RowStart, ColumnStart, RowEnd, ColumnEnd);
		Items.TextBlock.SetTextSelectionBounds(RowStart, ColumnStart - Move, RowEnd, ColumnEnd - Move);
	EndIf;
	CurrentItem = Items.TextBlock;
	
EndProcedure

#EndRegion

