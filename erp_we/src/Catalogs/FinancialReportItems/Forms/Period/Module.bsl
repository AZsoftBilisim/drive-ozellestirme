
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	Catalogs.FinancialReportItems.FormWhenCreatedOnServer(ThisForm);
	Title = Parameters.ItemKind;

	If PeriodValue = Undefined Then
		Items.LabelPeriodNumber.Visible = False;
	Else
		LabelPeriodNumber = NStr("vi = 'Kỳ cố định số%1';
								|ru = 'Фиксированный период №%1';
								|en = 'Fixed period No.%1'; fa = 'Fixed period No.%1';
								|it = 'Periodo di tempo №%1';
								|pl = 'Okres stały nr%1';
								|tr = 'Sabit dönem No.%1'");
		LabelPeriodNumber = StringFunctionsClientServer.SubstituteParametersToString(LabelPeriodNumber,
			String(PeriodValue + 1));
	EndIf;

	ThisForm.WindowOptionsKey = "WindowOption_" + Items.LabelPeriodNumber.Visible;
	
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

&AtClient
Procedure PeriodicityOnChange(Item)
	
	Object.NameForPrinting = String(Periodicity);
	
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