
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	Catalogs.FinancialReportItems.FormWhenCreatedOnServer(ThisForm);
	
	If Not ValueIsFilled(BudgetBalanceItem) Then
		Title = NStr("vi = '<Các chỉ tiêu ngân sách có số dư hoặc phát sinh>';
					|ru = '<Показатели бюджетов, по которым есть остатки или обороты>';
					|en = '<Items of budgets with balance or turnovers>'; fa = '<Items of budgets with balance or turnovers>';
					|it = '<Indicatori di bilancio, in base ai quali vi sono saldi o fatturati>';
					|pl = '<Wskaźniki budżetów, dla których istnieją ostatki lub obroty>';
					|tr = '<Bakiyeleri veya ciroları olan bütçe dengesi kalemleri>'");
	Else
		Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '%1: %2';
				|ru = '%1: %2';
				|en = '%1: %2'; fa = '%1: %2';
				|it = '%1: %2';
				|pl = '%1: %2';
				|tr = '%1: %2'"),
			Parameters.ItemKind,
			BudgetBalanceItem);
	EndIf;

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	Catalogs.FinancialReportItems.FormBeforeWritingToServer(ThisForm, CurrentObject, Cancel);
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, StandardProcessing)
	
	If ValueIsFilled(ItemAddressInStorage) Then
		StandardProcessing = False;
	EndIf;
	
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

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CompleteEditing(Command)
	
	FinancialReportingClient.FinishEditingReportElement(ThisForm);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion
