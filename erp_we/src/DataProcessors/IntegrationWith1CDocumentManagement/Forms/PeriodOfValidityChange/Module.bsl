#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.ReadOnly Then
		ReadOnly = True;
		Items.Cancel.Visible = False;
		Items.ChangeExpirationDate.Visible = False;
		Items.Close.Visible = True;
	EndIf;
	
	Parameters.Property("Document", Document);
	Parameters.Property("DocumentID", DocumentID);
	Parameters.Property("DocumentType", DocumentType);
	Parameters.Property("ValidityStartDate", ValidityStartDate);
	Parameters.Property("ValidityEndDate", ValidityEndDate);
	Parameters.Property("ExtensionProcedure", ExtensionProcedure);
	Parameters.Property("ExtensionProcedureID", ExtensionProcedureID);
	Parameters.Property("ExtensionProcedureType", ExtensionProcedureType);
	Parameters.Property("Permanent", Permanent);
	
	Items.ValidityEndDate.Enabled = Not Permanent;
	Items.ExtensionProcedure.Enabled = Not Permanent;
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	If Not Permanent Then
		If Not ValueIsFilled(ExtensionProcedure) Then
			Message = New UserMessage;
			Message.Text = CommonClientServer.FillingErrorText(,, NStr("vi = 'Trình tự gia hạn';
																		|ru = 'Порядок продления';
																		|en = 'Extension procedure'; fa = 'رویه تمدید';
																		|it = 'Ordine di proroga';
																		|pl = 'Tryb przedłużenia';
																		|tr = 'Uzatma prosedürü'"));
			Message.Field = "ExtensionProcedure";
			Message.Message();
			Cancel = True;
		EndIf;
		If Not ValueIsFilled(ExtensionProcedure) Then
			Message = New UserMessage;
			Message.Text = CommonClientServer.FillingErrorText(,, NStr("vi = 'Ngày kết thúc hiệu lực';
																		|ru = 'Дата окончания действия';
																		|en = 'Expiration date'; fa = 'تاریخ انقضا';
																		|it = 'Data di fine validità';
																		|pl = 'Data wygaśnięcia';
																		|tr = 'Geçerlilik bitiş tarihi'"));
			Message.Field = "ValidityEndDate";
			Message.Message();
			Cancel = True;
		EndIf;
	EndIf;
	
EndProcedure


#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PermanentOnChange(Item)
	
	If Permanent Then
		ValidityEndDate = '00010101';
		Items.ValidityEndDate.Enabled = False;
		Items.ExtensionProcedure.Enabled = False;
		ExtensionProcedure = "";
		IntegrationWith1CDocumentManagementClient.ClearReferenceProps("ExtensionProcedure", ThisObject);
	Else
		Items.ValidityEndDate.Enabled = True;
		Items.ExtensionProcedure.Enabled = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure ExtensionProcedureStartChoice(Item, ChoiceData, StandardProcessing)
	
	IntegrationWith1CDocumentManagementClient.SelectAValueFromTheDropDownList(
		"DMProlongationProcedure", "ExtensionProcedure", ThisObject);
	
EndProcedure

&AtClient
Procedure ExtensionProcedureTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			"DMProlongationProcedure", ChoiceData, Text, StandardProcessing);
		
		If ChoiceData.Count() = 1 Then
			IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
				"ExtensionProcedure", ChoiceData[0].Value, StandardProcessing, ThisObject);
			StandardProcessing = True;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure ExtensionProcedureAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			"DMProlongationProcedure",
			ChoiceData,
			Text,
			StandardProcessing);
	EndIf;
	
EndProcedure

&AtClient
Procedure ExtensionProcedureChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
		"ExtensionProcedure", ValueSelected, StandardProcessing, ThisObject);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ChangeExpirationDate(Command)
	
	ClearMessages();
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	ClosingParameters = New Structure;
	ClosingParameters.Insert("ValidityStartDate", ValidityStartDate);
	ClosingParameters.Insert("ValidityEndDate", ValidityEndDate);
	ClosingParameters.Insert("ExtensionProcedure", ExtensionProcedure);
	ClosingParameters.Insert("ExtensionProcedureID", ExtensionProcedureID);
	ClosingParameters.Insert("ExtensionProcedureType", ExtensionProcedureType);
	ClosingParameters.Insert("Permanent", Permanent);
	
	Close(ClosingParameters);
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Close();
	
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
