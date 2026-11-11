
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	ObjectData = Catalogs.FinancialReportItems.FormWhenCreatedOnServer(ThisForm);
	IndicatorName = ObjectData.NameForPrinting;
	Items.GroupAddAttributes.Visible = Parameters.ShowRowCodeNote;
	Items.SelectItem.Visible = Parameters.ShowRowCodeNote;
	RefreshFormTitle();

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

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	RefreshFormTitle();

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

#Region Private

&AtServer
Procedure RefreshFormTitle()

	If ValueIsFilled(Object.Ref) Then
		ThisForm.Title = NStr("vi = 'Chỉ tiêu phi tiền tệ';
								|ru = 'Немонетарный показатель';
								|en = 'Non-monetary item'; fa = 'قلم غیرپولی';
								|it = 'Indice non monetario';
								|pl = 'Wskaźnik niemonetarny';
								|tr = 'Gayrinakdi gösterge'");
	Else
		ThisForm.Title = NStr("vi = 'Chỉ tiêu phi tiền tệ ( tạo)';
								|ru = 'Немонетарный показатель (создание)';
								|en = 'Non-monetary item (Create)'; fa = 'Non-monetary item (Create)';
								|it = 'Indicatore non monetario (creazione)';
								|pl = 'Wskaźnik niemonetarny (tworzenie)';
								|tr = 'Gayrinakdi gösterge (oluşturma)'"); ;
	EndIf;

EndProcedure

#EndRegion
