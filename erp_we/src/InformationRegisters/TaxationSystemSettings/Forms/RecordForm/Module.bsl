#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	RecordKey = Undefined;
	ThisIsARecordForm = Parameters.Property("Key", RecordKey);
	Organization = Parameters.Organization;

	Items.Organization.Visible = Not ValueIsFilled(Organization);
	Title = Title + " " + String(Organization);
	
	RegisterName = Metadata.InformationRegisters.TaxationSystemSettings.Name;
	ReadOnly = Not AccessRight("Update", Metadata.InformationRegisters.TaxationSystemSettings);
	If Parameters.Property("CopyingValue") And ValueIsFilled(Parameters.CopyingValue) Then
		CopyRegisterEntry(Parameters.CopyingValue);
	Else
		ReadRegisterEntry(RecordKey);
	EndIf;
		
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	If Record.TaxationSystem = Enums.TaxationSystems.Shared3
		And ValueIsFilled(Record.Organization) Then
		
		LegalEntityIndividual = Common.ObjectAttributeValue(Record.Organization,
			"LegalEntityIndividual");
		
		If LegalEntityIndividual = PredefinedValue("Enum.LegalEntityIndividual.IndividualEntrepreneur") Then
			MessageText = NStr("vi = 'Đối với cá nhân kinh doanh, sử dụng chỉ hệ thống thuế giản lược.';
								|ru = 'Для индивидуального предпринимателя доступна только упрощенная система налогообложения.';
								|en = 'For an individual entrepreneur simplified taxation system is available only.'; fa = 'For an individual entrepreneur simplified taxation system is available only.';
								|it = 'Per l''imprenditore individuale è disponibile solo il regime fiscale semplificato.';
								|pl = 'Dla przedsiębiorcy indywidualnego jest dostępny tylko uproszczony system opodatkowania.';
								|tr = 'Şahıs şirketi için yalnızca basitleştirilmiş vergilendirme sistemi mevcuttur.'");
			Common.MessageToUser(MessageText, , "Record.TaxationSystem", , Cancel);
		EndIf;
	EndIf;
	Return
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Modified And Exit Then
		Cancel = True;
		Return;
	EndIf;
	
	If Modified Then
		
		Cancel = True;
		AskQuestionFormModified("QuestionBeforeClosingCompletion");
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ChangeDateOnChange(Item)
	QueryText = NStr("vi = 'Tạo cài đặt mới trên %1? Nếu không, sẽ thay đổi kỳ hiện tại.';
					|ru = 'Создать новую настройку на %1? Иначе будет изменен период существующей.';
					|en = 'Create a new customization on the %1? Otherwise, the period of the current will be changed.'; fa = 'Create a new customization on the %1? Otherwise, the period of the current will be changed.';
					|it = 'Creare una nuova impostazione per %1? Altrimenti sarà modificato il periodo di quella esistente.';
					|pl = 'Utwórz nowe ustawienie na %1? Inaczej zostanie zmieniony okres istniejącego.';
					|tr = '%1 için yeni bir ayar oluştur? Aksi takdirde, mevcut olanın süresi değiştirilecektir.'");
	QueryText = StrTemplate(QueryText, Format(BegOfMonth(ChangeDate),"DLF=D"));
	ShowQueryBox(New CallbackDescription("ChangeDateOnChangeCompletion", ThisObject), QueryText, QuestionDialogMode.YesNo);
EndProcedure

&AtClient
Procedure ChangeDateOnChangeCompletion(Response, AdditionalParameters) Export
	
	If Response = DialogReturnCode.No Then
		ReadRegisterEntryWhenChangingProps(,ChangeDate);
	ElsIf Response = DialogReturnCode.Yes Then
		ReadRegisterEntryWhenChangingProps(,ChangeDate, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	Organization = Record.Organization;
	ReadRegisterEntryWhenChangingProps(,ChangeDate);
EndProcedure

&AtClient
Procedure DateOfTransferToSTSOnChange(Item)
	
	If ValueIsFilled(Record.DateOfTransferToSTS) Then
		Record.DateOfTransferToSTS = BegOfYear(Record.DateOfTransferToSTS);
	EndIf;
	
EndProcedure

&AtClient
Procedure TaxationSystemOnChange(Item)
	SetItemsVisibility(ThisForm);
EndProcedure

&AtClient
Procedure PTSIsAppliedOnChange(Item)
	SetItemsAvailability();
EndProcedure

&AtClient
Procedure ASTSIsAppliedOnChange(Item)
	SetItemsVisibility(ThisObject);
	SetItemsAvailability();
EndProcedure

&AtClient
Procedure PayerOfAdditionalIncomeTaxFromHydrocarbonProductionAITOnChange(Item)
	SetItemsVisibility(ThisObject)
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure WriteAndClose(Command)
	If WriteChanges(True) Then
		Close();
	EndIf;
EndProcedure

&AtClient
Procedure Write(Command)
	WriteChanges();
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ReadRegisterEntryWhenChangingProps(RecordKey = Undefined, RecordPeriod = Undefined, CreateANewOne = False)
	If Not Copy Then
		ReadRegisterEntry(RecordKey, RecordPeriod, CreateANewOne);
	EndIf;
EndProcedure

&AtServer
Procedure ReadRegisterEntry(RecordKey = Undefined, RecordPeriod = Undefined, CreateANewOne = False)
	AccountingPoliciesTaxSettings.ReadRegisterEntry(ThisObject, 
		RegisterName,
		Organization,
		CreateANewOne,
		RecordKey,
		RecordPeriod);
	CurrentFinancialAccountingParameters = AccountingPoliciesTaxSettings.CurrentTaxAccountingPolicySettings(
		"FinancialAccountingPolicy", Organization, EndOfQuarter(ChangeDate), False);
	If ValueIsFilled(CurrentFinancialAccountingParameters) Then
		InventoryValuationMethod = CurrentFinancialAccountingParameters.InventoryValuationMethod;
	EndIf;
	SetItemsVisibility(ThisObject);
EndProcedure

&AtServer
Procedure CopyRegisterEntry(CopyingValue)
	AccountingPoliciesTaxSettings.CopyAccountingPolicy(ThisObject, CopyingValue, RegisterName);
	SetItemsVisibility(ThisObject);
	Copy = True;
	Modified = True;
EndProcedure

&AtClient
Procedure NotifyAfterRecording()
	
	NotificationParameters = New Structure("Organization, Period", Record.Organization, Record.Period);
	EventName = "Record_" + RegisterName;
	Notify(EventName, NotificationParameters);
	
EndProcedure

&AtServer
Function WriteChangesAtServer(Close = False)
	RecordingSuccessful = AccountingPoliciesTaxSettings.RecordChangingRegisterEntries(ThisObject, Close);
	Return RecordingSuccessful;
EndFunction

&AtClient
Function WriteChanges(Close = False)
	ClearMessages();
	RecordingSuccessful = WriteChangesAtServer(Close);
	If RecordingSuccessful Then
		NotifyAfterRecording();
	EndIf;
	Return RecordingSuccessful;
EndFunction

&AtClient
Procedure HistoryDescriptionURLProcessing(Item, FormattedStringURL, StandardProcessing)
	StandardProcessing = False;
	If FormattedStringURL = "ChangeHistory" Then
		If Modified Then
			AskQuestionFormModified("OpenChangeHistory_Continued");
		Else
			OpenChangeHistory_();
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure AskQuestionFormModified(NameOfAlert)
	
	QueryText = NStr("vi = 'Đã thay đổi dữ liệu. Lưu lại thay đổi?';
					|ru = 'Данные были изменены. Сохранить изменения?';
					|en = 'The data has changed. Do you want to save the changes?'; fa = 'The data has changed. Do you want to save the changes?';
					|it = 'I dati sono stati modificati. Salvare le modifiche?';
					|pl = 'Dane zostały zmienione. Chcesz zapisać zmiany?';
					|tr = 'Veriler değiştirildi. Değişiklikler kaydedilsin mi?'");
	Notification = New CallbackDescription(NameOfAlert, ThisObject);
	ShowQueryBox(Notification, QueryText, QuestionDialogMode.YesNoCancel);
	
EndProcedure

&AtClient
Procedure QuestionBeforeClosingCompletion(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.No Then
		
		Modified = False;
		Close();
		
	ElsIf Result = DialogReturnCode.Yes Then
		If Not WriteChanges(True) Then
			Return;
		EndIf;
		Modified = False;
		Close();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenChangeHistory_()
	OpenForm("InformationRegister.TaxationSystemSettings.Form.EditHistory",
		New Structure("ReadOnly, Organization", ReadOnly, Organization),
		ThisForm,,,,
		New CallbackDescription("OpenChangeHistory_Completion", ThisObject));
EndProcedure

&AtClient
Procedure OpenChangeHistory_Continued(Result, AdditionalParameters) Export
	If Result = DialogReturnCode.No Then
		OpenChangeHistory_();
	ElsIf Result = DialogReturnCode.Yes Then
		If Not WriteChanges(False) Then
			Return;
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure OpenChangeHistory_Completion(Result, AdditionalParameters) Export
	If ValueIsFilled(Result) Then
		ReadRegisterEntry(Result);
	EndIf;
EndProcedure

&AtClientAtServerNoContext
Procedure SetItemsVisibility(Form)
	
	Items = Form.Items;
	LegalEntityIndividual = GeneralPurposeTMServerCall.ObjectAttributeValue(Form.Record.Organization, "LegalEntityIndividual");
	SoleProprietor = LegalEntityIndividual = PredefinedValue("Enum.LegalEntityIndividual.IndividualEntrepreneur");
	
	STSIsApplied = Form.Record.TaxationSystem = PredefinedValue("Enum.TaxationSystems.Simplified");
	Items.DateOfTransferToSTS.Visible = STSIsApplied;
	Items.NotificationDate.Visible = STSIsApplied;
	Items.NotificationNumber.Visible = STSIsApplied;
	Items.ASTSIsApplied.Visible = STSIsApplied;
	Items.PTSIsApplied.Visible = SoleProprietor;
	Items.PTSIsApplied.Visible = STSIsApplied And SoleProprietor;
	
	Form.Items.DecorationWarningNDD.Visible = Form.Record.PayerOfAdditionalIncomeTaxFromHydrocarbonProductionAIT
		And Form.InventoryValuationMethod <> PredefinedValue("Enum.InventoryValuationMethods.FIFORollingValuation")
		And Form.InventoryValuationMethod <> PredefinedValue("Enum.InventoryValuationMethods.EmptyRef");
	Form.ReadOnly = Form.ReadOnly Or Form.BranchOffice;
	
EndProcedure

&AtServer
Procedure SetItemsAvailability()

	Items.ASTSIsApplied.Enabled = Not Record.PTSIsApplied;
	Items.PTSIsApplied.Enabled = Not Record.ASTSIsApplied;

EndProcedure

#EndRegion