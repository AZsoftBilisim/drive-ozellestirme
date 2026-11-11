
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	Catalogs.FinancialReportItems.FormWhenCreatedOnServer(ThisForm);
	Title = NStr("vi = 'Ngân sách có thể chỉnh sửa';
				|ru = 'Редактируемое значение бюджета';
				|en = 'Edited budget value'; fa = 'Edited budget value';
				|it = 'Valore di bilancio modificabile';
				|pl = 'Edytowana wartość budżetu';
				|tr = 'Bütçe değerinin düzenlenmesi'");
	
	LineIDOfReportItem = Parameters.LineIDOfReportItem;
	EditedValues = Parameters.EditedValues;
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	PrintNameBeforeChanges = Object.NameForPrinting;

EndProcedure

&AtClient
Procedure BeforeClose(Cancel, StandardProcessing)
	
	If ValueIsFilled(ItemAddressInStorage) Then
		StandardProcessing = False;
	EndIf;
	
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

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	Errors = Undefined;
	
	ArrayOfPropsNames = GetFromTempStorage(EditedValues);
	
	If Object.NameForPrinting <> PrintNameBeforeChanges 
		And ArrayOfPropsNames.Find(Object.NameForPrinting) <> Undefined Then
		ErrorText = NStr("vi = 'Tên của mục ""Giá trị có thể chỉnh sửa"" phải là duy nhất';
						|ru = 'Наименование элемента ""Редактируемое значение"" должно быть уникально';
						|en = 'Name of the ""Edited value"" item should be unique'; fa = 'Name of the ""Edited value"" item should be unique';
						|it = 'La denominazione dell''elemento ""Valore modificabile"" deve essere unica';
						|pl = 'Nazwa elementu ""Edytowana wartość"" musi być unikalna';
						|tr = '""Değerin düzenlenmesi"" öğesinin tanımı benzersiz olmalıdır'");
		CommonClientServer.AddUserError(Errors,
			"Object.NameForPrinting",
			ErrorText, "");
		CommonClientServer.ReportErrorsToUser(Errors, Cancel);
	EndIf;
	
EndProcedure

#EndRegion
