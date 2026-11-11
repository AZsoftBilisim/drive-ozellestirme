
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	FillPropertyValues(ThisObject, Parameters.ProtocolData);
	Items.Status.ChooseType = False; // It is typed by the value from the document and the type should no longer change
	DocumentAuthor_ = Parameters.DocumentAuthor_; // Status selection parameter
	Title = Parameters.Title;
	
	If Parameters.IsNewRecord Then
		
		// Will be filled in only when saving, do not load the Form:
		Items.Date.Visible  = False;
		Items.Author.Visible = False;
		
	EndIf;
	
	If Not Parameters.ToChangeStatus Then
		
		If Parameters.IsNewRecord Then
			Items.Status.Visible = False;
		Else
			Items.Status.Type = FormFieldType.LabelField;
		EndIf;
		
	EndIf;
	
	If Not Parameters.EnableEdit Then
		ReadOnly = True;
		Items.FormButtonGroupEdit.Visible = False;
		Items.FormButtonGroupView.Visible = True;
		Items.FormClose.DefaultButton = True;
	EndIf;
	
	ProcessStatusChange();
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	AttributesNotToCheck = New Array;
	
	If ThisIsFinalStatusOfDocument Then
		AttributesNotToCheck.Add("Performer");
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, AttributesNotToCheck);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure StatusOnChange(Item)
	ProcessStatusChange();
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	ClearMessages();
	
	If Not CheckFilling() Then
		Return;
	EndIf;
		
	ReturnValue = OperationsWithDocumentProtocolClientServer.ModifiableProtocolProperties();
	FillPropertyValues(ReturnValue, ThisObject);
	Close(ReturnValue);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure ProcessStatusChange()
	
	ThisIsFinalStatusOfDocument = OperationsWithDocumentProtocol.ThisIsFinalStatusOfDocument(Status);
	Items.Performer.Enabled = Not ThisIsFinalStatusOfDocument;
	Items.Performer.AutoMarkIncomplete = Not ThisIsFinalStatusOfDocument;
	
	If ThisIsFinalStatusOfDocument Then
		Performer = Undefined;
		Items.Performer.InputHint = NStr("ru = '<не перенаправляется>';
										|vi = '<not forwarded>';
										|en = '<not forwarded>'; fa = '<not forwarded>';
										|it = '<not forwarded>';
										|pl = '<not forwarded>';
										|tr = '<yönlendirilmiyor>'");
		Items.Comment.InputHint = NStr("ru = 'Можно указать комментарий к закрытию документа';
										|vi = 'You can specify a comment to close the document';
										|en = 'You can specify a comment to close the document'; fa = 'You can specify a comment to close the document';
										|it = 'You can specify a comment to close the document';
										|pl = 'You can specify a comment to close the document';
										|tr = 'Belgenin kapatılmasına ilişkin yorum eklenebilir'");
		Items.Performer.MarkIncomplete = False;
	Else
		Items.Performer.InputHint = Undefined;
		Items.Comment.InputHint = NStr("ru = 'Можно указать комментарий к перенаправлению документа';
										|vi = 'You can specify a comment to forward the document';
										|en = 'You can specify a comment to forward the document'; fa = 'You can specify a comment to forward the document';
										|it = 'You can specify a comment to forward the document';
										|pl = 'You can specify a comment to forward the document';
										|tr = 'Belgenin yönlendirilmesine ilişkin yorum eklenebilir'");
	EndIf;
	
	If ReadOnly Then
		Items.Comment.InputHint = "";
	EndIf;
	
EndProcedure

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
