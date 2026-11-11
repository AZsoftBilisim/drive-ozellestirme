#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	RecordKey = Undefined;
	RegisterName = Metadata.InformationRegisters.VATAccountingSettings.Name;
	ReadOnly = Not AccessRight("Update", Metadata.InformationRegisters.VATAccountingSettings);
	
	Organization = Parameters.Organization;
	Items.Organization.Visible = Not ValueIsFilled(Organization);
	Title = Title + " " + String(Organization);
	
	ThisIsARecordForm = Parameters.Property("Key", RecordKey);
	If Parameters.Property("CopyingValue") And ValueIsFilled(Parameters.CopyingValue) Then
		CopyRegisterEntry(Parameters.CopyingValue);
	Else
		ReadRegisterEntry(RecordKey);
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	If EventName = "Write_FinancialAccountingPolicy" Then
		GetParametersOfAccountingPolicyAndTaxSystem();
		SetElementProperties(ThisObject);
	EndIf;
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	If Record.VATBase = Enums.KindsOfVATBase.CurrentMonthRevenue
		And Record.FrequencyOfVATAllocation = Enums.Periodicity.Quarter Then
			MessageText = NStr("vi = 'Cơ sở thuế GTGT không thể có thời gian ngắn hơn định kỳ phân bổ thuế GTGT.';
								|ru = 'База НДС не может иметь меньший период, чем периодичность распределения НДС.';
								|en = 'VAT base cannot have a less period than VAT allocation frequency.'; fa = 'VAT base cannot have a less period than VAT allocation frequency.';
								|it = 'Imponibile IVA non può avere un periodo inferiore alla periodicità di ripartizione IVA.';
								|pl = 'Podstawa VAT nie może mieć okres mniejszy niż okresowość przydziału VAT.';
								|tr = 'KDV matrahı, KDV dağıtımının sıklığından daha kısa bir döneme sahip olamaz.'");
			Common.MessageToUser(MessageText, , "Record.VATBase", , Cancel);
	EndIf;
	
	If Record.VATBase = Enums.KindsOfVATBase.CurrentQuarterRevenue
		And Record.FrequencyOfVATAllocation = Enums.Periodicity.Month Then
			MessageText = NStr("vi = 'Cơ sở Thuế GTGT không thể có thời gian dài hơn tần suất phân bổ thuế GTGT.';
								|ru = 'База НДС не может иметь больший период, чем периодичность распределения НДС.';
								|en = 'VAT base cannot have a greater period than VAT allocation frequency.'; fa = 'VAT base cannot have a greater period than VAT allocation frequency.';
								|it = 'Imponibile IVA non può avere un periodo superiore alla periodicità di ripartizione IVA.';
								|pl = 'Podstawa VAT nie może mieć większy okres, niż okresowość przydziału VAT.';
								|tr = 'KDV matrahı, KDV dağıtımının sıklığından daha uzun bir döneme sahip olamaz.'");
			Common.MessageToUser(MessageText, , "Record.VATBase", , Cancel);
	EndIf;
	
	If Not ValueIsFilled(Record.VATBase) Then
		ErrorText = NStr("vi = 'Chưa điền trường ""Cơ sở thuế GTGT""';
						|ru = 'Поле ""База НДС"" не заполнено';
						|en = '""VAT base"" is required'; fa = '""VAT base"" is required';
						|it = 'Campo ""Imponibile IVA"" non è compilato';
						|pl = 'Nie wypełniono pola ""Podstawa VAT""';
						|tr = '""KDV matrahı"" alanı doldurulmadı'");
		Common.MessageToUser(ErrorText,,
			"Record.VATBase",, Cancel);
	EndIf;

	If Not ValueIsFilled(Record.FrequencyOfVATAllocation) Then
		ErrorText = NStr("vi = 'Chưa điền trường ""Định kỳ phân bổ thuế GTGT""';
						|ru = 'Поле ""Периодичность распределения НДС"" не заполнено';
						|en = '""VAT allocation frequency"" is required'; fa = '""VAT allocation frequency"" is required';
						|it = 'Campo ""Periodicità ripartizione IVA"" non è compilato';
						|pl = 'Nie wypełniono pola ""Okresowość przydziału VAT""';
						|tr = '""KDV dağıtım sıklığı"" alanı doldurulmadı'");
		Common.MessageToUser(ErrorText,,
			"Record.FrequencyOfVATAllocation",, Cancel);
	EndIf;

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
	QueryText = NStr("vi = 'Tạo cài đặt mới trên %1?';
					|ru = 'Создать новую настройку на %1?';
					|en = 'Create a new customization on the %1?'; fa = 'Create a new customization on the %1?';
					|it = 'Creare una nuova impostazione per %1?';
					|pl = 'Utwórzyć nowe ustawienie na %1?';
					|tr = '%1''de yeni bir ayar oluştur?'");
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
Procedure RecordVATPayerOnChange(Item)
	
	If Not Record.VATPayer Then
		Record.SeparateAccountingOfGoodsByVATTaxation = False;		
	EndIf;
	SetElementProperties(ThisObject);
	
EndProcedure

&AtClient
Procedure SeparateAccountingOfGoodsByVATTaxationOnChange(Item)
	SetElementProperties(ThisObject);
EndProcedure

&AtClient
Procedure RecordFrequencyOfVATAllocationOnChange(Item)
	FillInVATBaseSelectionLists(ThisObject);
EndProcedure

&AtClient
Procedure AccruePersonalIncomeTaxOnAdvancesOnChange(Item)
	
	AccruePersonalIncomeTaxOnAdvancesOnChangeServer() 
	
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

&AtServer
Procedure GetParametersOfAccountingPolicyAndTaxSystem()
	
	AccountingPolicyParameters = AccountingPoliciesTaxSettings.CurrentParametersOfTaxesAndAccountingPoliciesAsOfDate(
			"FinancialAccountingPolicy",
			Record.Organization,
			ChangeDate,
			True);
	If AccountingPolicyParameters <> Undefined Then
		InventoryValuationMethod = AccountingPolicyParameters.InventoryValuationMethod;
	Else
		InventoryValuationMethod = Enums.InventoryValuationMethods.AveragePerMonth;
	EndIf;
	
	GenerateVATChargedWhenIncludingInCost = False;
	InventoryValuationMethodIsUsedForAverageSliding = False;
	AverageSlipIsUsedInPeriodOfValidityOfVATSettings = False;

	If AccountingPolicyParameters <> Undefined Then
		InventoryValuationMethodIsUsedForAverageSliding =
			AccountingPolicyParameters.InventoryValuationMethod = Enums.InventoryValuationMethods.MovingAverage;
		GenerateVATChargedWhenIncludingInCost = InventoryValuationMethodIsUsedForAverageSliding;
		AverageSlipIsUsedInPeriodOfValidityOfVATSettings = InventoryValuationMethodIsUsedForAverageSliding;
	EndIf;
	
	If Not AverageSlipIsUsedInPeriodOfValidityOfVATSettings Then
		AverageSlipIsUsedInPeriodOfValidityOfVATSettings =
			InformationRegisters.VATAccountingSettings.AverageSlipIsUsedInPeriodOfValidityOfVATSettings(Organization, ChangeDate);
	EndIf;

	If Not GenerateVATChargedWhenIncludingInCost Then
		GenerateVATChargedWhenIncludingInCost = Record.GenerateVATChargedWhenIncludingInCost;
	EndIf;
	
EndProcedure

&AtServer
Procedure ReadRegisterEntry(RecordKey = Undefined, RecordPeriod = Undefined, CreateANewOne = False)
	GetParametersOfAccountingPolicyAndTaxSystem();
	AccountingPoliciesTaxSettings.ReadRegisterEntry(ThisObject, 
		RegisterName,
		Organization,
		CreateANewOne,
		RecordKey,
		RecordPeriod);
	
	AccruePersonalIncomeTaxOnAdvances = 
		(Record.RuleOfPrepaymentFilterToRegisterTaxInvoices <> Enums.ProcedureOfRegisteringTaxInvoicesForPrepayment.DoNotRegisterTaxInvoices);
	
	SetElementProperties(ThisObject);
	
EndProcedure

&AtClient
Procedure ReadRegisterEntryWhenChangingProps(RecordKey = Undefined, RecordPeriod = Undefined, CreateANewOne = False)
	If Not Copy Then
		ReadRegisterEntry(RecordKey, RecordPeriod, CreateANewOne);
	EndIf;
EndProcedure

&AtServer
Procedure CopyRegisterEntry(CopyingValue)
	AccountingPoliciesTaxSettings.CopyAccountingPolicy(ThisObject, CopyingValue, RegisterName);
	Copy = True;
	Modified = True;
	
	GetParametersOfAccountingPolicyAndTaxSystem();
	
	AccruePersonalIncomeTaxOnAdvances = 
		(Record.RuleOfPrepaymentFilterToRegisterTaxInvoices <> Enums.ProcedureOfRegisteringTaxInvoicesForPrepayment.DoNotRegisterTaxInvoices);
	
	SetElementProperties(ThisObject);
		
EndProcedure

&AtClient
Procedure NotifyAfterRecording()
	
	NotificationParameters = New Structure("Organization, Period", Record.Organization, Record.Period);
	EventName = "Record_" + RegisterName;
	Notify(EventName, NotificationParameters);
	
EndProcedure

&AtServer
Function WriteChangesAtServer(Close = False)
	
	Record.GenerateVATChargedWhenIncludingInCost = GenerateVATChargedWhenIncludingInCost;
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
	OpenForm("InformationRegister.VATAccountingSettings.Form.EditHistory",
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
		OpenChangeHistory_CompletionServer(Result)
	EndIf;
EndProcedure

&AtServer
Procedure OpenChangeHistory_CompletionServer(Result) Export
	ReadRegisterEntry(Result);
	GetParametersOfAccountingPolicyAndTaxSystem();
	SetElementProperties(ThisObject);
EndProcedure

&AtClientAtServerNoContext
Procedure SetElementProperties(Form)
	
	Form.Items.SeparateAccountingOfGoodsByVATTaxation.Enabled = Form.Record.VATPayer;
	Form.ReadOnly = Form.ReadOnly Or Form.BranchOffice;
	Form.Items.VATDistributionGroup.Enabled = Form.Record.SeparateAccountingOfGoodsByVATTaxation;
	Form.Items.RuleOfPrepaymentFilterToRegisterTaxInvoices.Enabled = Form.AccruePersonalIncomeTaxOnAdvances;
	Form.Items.GenerateVATChargedWhenIncludingInCost.Enabled =
		Not Form.InventoryValuationMethodIsUsedForAverageSliding;
	Form.Items.GroupGeneratesVATPresentedWhenCommentIsIncludedInCost.Visible = 
		Form.AverageSlipIsUsedInPeriodOfValidityOfVATSettings;
	
	FillInVATBaseSelectionLists(Form);
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillInVATBaseSelectionLists(Form)
	
	Form.Items.RecordVATBase.ChoiceList.Clear();
	
	ListOfVATBaseValues = New Array();
	ListOfVATBaseValues.Add(PredefinedValue("Enum.KindsOfVATBase.LastYearRevenue"));
	ListOfVATBaseValues.Add(PredefinedValue("Enum.KindsOfVATBase.CurrentYearRevenue"));
	
	If Form.Record.FrequencyOfVATAllocation = PredefinedValue("Enum.Periodicity.Month") Then
		ListOfVATBaseValues.Add(PredefinedValue("Enum.KindsOfVATBase.CurrentMonthRevenue"));
	ElsIf Form.Record.FrequencyOfVATAllocation = PredefinedValue("Enum.Periodicity.Quarter") Then
		ListOfVATBaseValues.Add(PredefinedValue("Enum.KindsOfVATBase.CurrentQuarterRevenue"));
	EndIf;
	Form.Items.RecordVATBase.ChoiceList.LoadValues(ListOfVATBaseValues);;
	
EndProcedure

&AtServer
Procedure AccruePersonalIncomeTaxOnAdvancesOnChangeServer() 
	
	If AccruePersonalIncomeTaxOnAdvances 
			And Record.RuleOfPrepaymentFilterToRegisterTaxInvoices = Enums.ProcedureOfRegisteringTaxInvoicesForPrepayment.DoNotRegisterTaxInvoices Then
		Record.RuleOfPrepaymentFilterToRegisterTaxInvoices = Enums.ProcedureOfRegisteringTaxInvoicesForPrepayment.AllExceptSettledDuringDay;
	ElsIf Not AccruePersonalIncomeTaxOnAdvances
			And Record.RuleOfPrepaymentFilterToRegisterTaxInvoices <> Enums.ProcedureOfRegisteringTaxInvoicesForPrepayment.DoNotRegisterTaxInvoices Then
		Record.RuleOfPrepaymentFilterToRegisterTaxInvoices = Enums.ProcedureOfRegisteringTaxInvoicesForPrepayment.DoNotRegisterTaxInvoices;
	EndIf;
	
	SetElementProperties(ThisObject);
	
EndProcedure

#EndRegion