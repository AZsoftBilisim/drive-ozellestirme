#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);

	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
	
	ARAPAccountingFormWork.FormWhenCreatedOnServer(ThisObject);
	
	// Handler of the "Properties" subsystem
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	
	
	// Handler of the subsystem "Versioning of objects"
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	// Subsystem prohibiting editing of key details of objects	
	ObjectAttributesLock.LockAttributes(ThisObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	IntercompanyContractsLocalization.WhenCreatingElementFormOnServer(ThisObject, Cancel , StandardProcessing);
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	LocalizationRFService = GetFunctionalOption("LocalizationRFService");
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	SetVisibilityOfPaymentInCurrency();
	
	ElementManagementIsVariantOfContractCourse();
	SetTextOfHintOrderOfCreditingDocuments();
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations

	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	IntercompanyContractsLocalizationClient.OnOpen(Cancel, ThisObject);
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	OnReadCreateAtServer();
	
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	
	ConfigurationModificationOverridable.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	If FixedContractAmount And Object.Sum = 0 Then
		
		ErrorText = NStr("vi = 'Chưa điền số tiền hợp đồng.';
						|ru = 'Не заполнена сумма договора.';
						|en = 'Contract amount is required'; fa = 'Contract amount is required';
						|it = 'L''importo dell''accordo non è compilato.';
						|pl = 'Nie wypełniono kwoty umowy.';
						|tr = 'Sözleşme tutarı doldurulmadı.'");
		CommonClientServer.MessageToUser(
			ErrorText,
			Object.Ref,
			"Object.Sum",,
			Cancel);
	EndIf;
	
	If Object.ContractRateOption = Enums.ContractRateOptions.SpecifiedInContract
		And NumeratorOfContractCurrencyExchangeRate = 0 Then
		
		ErrorText = NStr("vi = 'Chưa điền tỷ giá ngoại tệ trong hợp đồng.';
						|ru = 'Не заполнен курс валюты договора.';
						|en = 'The contract exchange rate is required.'; fa = 'The contract exchange rate is required.';
						|it = 'Tasso di cambio valuta del contratto non compilato.';
						|pl = 'Nie wypełniono kursu waluty umowy.';
						|tr = 'Sözleşme döviz kuru doldurulmadı.'");
		Common.MessageToUser(
			ErrorText,
			Object.Ref,
			"NumeratorOfContractCurrencyExchangeRate",,
			Cancel);
		
	EndIf;
	
	If Object.ContractRateOption = Enums.ContractRateOptions.SpecifiedInContract
		And DenominatorOfContractCurrencyExchangeRate = 0 Then
		
		ErrorText = NStr("vi = 'Chưa điền bội số tỷ giá ngoại tệ trong hợp đồng.';
						|ru = 'Не заполнена кратность курса валюты договора.';
						|en = 'The multiplying factor of the contract exchange rate is required.'; fa = 'The multiplying factor of the contract exchange rate is required.';
						|it = 'Molteplicità del tasso di cambio valuta del contratto non compilata.';
						|pl = 'Nie wypełniono współczynnika kursu waluty umowy.';
						|tr = 'Sözleşmenin döviz kuru çarpanı girilmemiş.'");
		Common.MessageToUser(
			ErrorText,
			Object.Ref,
			"DenominatorOfContractCurrencyExchangeRate",,
			Cancel);
		
	EndIf;
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	IntercompanyContractsLocalization.FillCheckProcessingAtServer(Cancel, CheckedAttributes, ThisObject);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	IntercompanyContractsLocalization.BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters, ThisObject);
	ARAPAccountingServer.BeforeWriteAtServer(ThisObject, CurrentObject);
	
	// Handler of the "Properties" subsystem
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisObject, Cancel, CurrentObject, WriteParameters);
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	RecordValuesOfContractCurrencyExchangeRate(CurrentObject.Ref);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	SetAvailabilityOfItemsByStatusServer();
	
	RefreshFormTitle();
	ARAPAccountingFormWork.FormAfterRecordingOnServer(ThisObject, CurrentObject.AdditionalProperties);
	
	// Subsystem prohibiting editing of key details of objects	
	ObjectAttributesLock.LockAttributes(ThisObject);

	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	IntercompanyContractsLocalization.AfterWriteAtServerItemForm(ThisObject, CurrentObject, WriteParameters);

EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Subsystem "Properties"
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	
	If EventName = "ChangedStatusDependentBankingDetails"
		And Parameter.UUID = UUID Then
		If Object.Approved Then
			Object.Approved = False;
		EndIf;
		AttachIdleHandler("Attachable_WhenChangingDetailsDependingOnStatus", 0.1, True);
	EndIf;
	IntercompanyContractsLocalizationClient.NotificationProcessing(EventName, Parameter, Source, ThisObject);
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)

	ARAPAccountingClient.FormAfterRecording(ThisObject);
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisObject, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

#Region UniversalEventHandlers

&AtClient
Procedure Attachable_OnChangeAttribute(Item)
	IntercompanyContractsLocalizationClient.OnChangeAttribute(
		Item,
		ThisObject);
EndProcedure

&AtClient
Procedure Attachable_ProcessingTheFormSNavigationLink(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	IntercompanyContractsLocalizationClient.ProcessingTheFormSNavigationLink(Item,
		FormattedStringURL,
		StandardProcessing,
		ThisObject);
	
EndProcedure

&AtClient
Procedure AtEndOfChangingLocalizationDetails(TagName, AdditionalParameters) Export
	
	If AdditionalParameters.ServerCallRequired_ Then
		AtEndOfChangingLocalizationDetailsOnServer(TagName, AdditionalParameters.ProcessingParameters);
	EndIf;

EndProcedure

&AtServer
Procedure AtEndOfChangingLocalizationDetailsOnServer(TagName, ProcessingParameters)
	
	IntercompanyContractsLocalization.AtEndOfChangeOfProps(TagName, ThisObject, ProcessingParameters);
	
EndProcedure

#EndRegion

&AtClient
Procedure StatusOnChange(Item)
	
	If Object.Approved
		And Object.Status <> PredefinedValue("Enum.CounterpartyContractStatuses.Valid")
		And Object.Status <> PredefinedValue("Enum.CounterpartyContractStatuses.Closed") Then
		
		Object.Approved = False;
		
	EndIf;
	
	SetAvailabilityOfItemsByStatusServer();
	
EndProcedure

&AtClient
Procedure ContractTypeOnChange(Item)
	
	ContractTypeOnChangeServer();
	
EndProcedure

&AtClient
Procedure ValidityStartDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	StartDateOfActionWhenChangeIsMadeOnServer();
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	ClearMessages();
	OrganizationOnChangeServer();
	
EndProcedure

&AtClient
Procedure CompanyRecipientOnChange(Item)
	
	ClearMessages();
	CompanyRecipientOnChangeServer();
	
EndProcedure

&AtClient
Procedure ARAPCurrencyOnChange(Item)
	
	ClearMessages();
	ARAPCurrencyOnChangeServer();
	
EndProcedure

&AtClient
Procedure CommentStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	CommonClient.ShowCommentEditingForm(
		Item.EditText, 
		ThisObject, 
		"Object.Comment");
	
EndProcedure

&AtClient
Procedure DescriptionOnChange(Item)
	
	Items.NameForPrinting.ChoiceList.Clear();
	Items.NameForPrinting.ChoiceList.Add(Object.Description);
	
EndProcedure

&AtClient
Procedure DebtClassificationOnChange(Item)
	
	If DebtClassification = 1 Then
		Object.PaymentDueDateIsSet = True;
		Object.PaymentDueDate = 366; // The value is greater than 365 calendar days
	Else
		Object.PaymentDueDateIsSet = False;
		Object.PaymentDueDate = 0;
	EndIf;
	
EndProcedure

&AtClient
Procedure TaxRegimeInCaseOfChange(Item)
	
	Object.VATTaxationIsDeterminedInDocuments = TaxationTreatment = 1;
	
	CompleteVATTaxation();
	VATTaxationOnChangeServer();
	
EndProcedure

&AtClient
Procedure SeparateVATAccountingModeOnChange(Item)
	
	Object.PurchaseForActivityIsDeterminedInDocument = SeparateVATAccountingMode = 1;
	
	UpdatePurchaseForActivity();
	SetPropertiesOfElementsOfTaxationAndSeparateVATAccounting();
	
EndProcedure

&AtClient
Procedure LineOfBusinessOnChange(Item)
	LineOfBusinessOnChangeServer();
EndProcedure

&AtClient
Procedure VATTaxationOnChange(Item)
	
	VATTaxationOnChangeServer();
	
EndProcedure

&AtClient
Procedure ForeignCurrencyTransactionOnChange(Item)
	
	ProcessBankAccounts();
	
EndProcedure

&AtClient
Procedure ContractRateOptionOnChange(Item)
	
	ClearMessages();
	VariantOfContractCourseWhenChangedOnServer();
	
EndProcedure

&AtClient
Procedure ARAPObjectSettingsOnChange(Item)
	
	If Object.ContractRateOption = PredefinedValue("Enum.ContractRateOptions.FixedAsOfShipmentDate")
		And Object.ARAPObjectSettings = PredefinedValue("Enum.ARAPObjectSettings.ByCounterpartyContracts") Then
		Object.ContractRateOption = PredefinedValue("Enum.ContractRateOptions.Mutable");
	EndIf;
	
	ElementManagementIsVariantOfContractCourse();
	
	CalculationProcedureOnChangeATServer();
	
EndProcedure

&AtClient
Procedure InscriptionDenominatorOfContractCurrencyExchangeRateURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	Items.CourseMultiplicityEditingGroup.Visible = True;
	Items.InscriptionDenominatorOfContractCurrencyExchangeRate.Visible = False;
	
EndProcedure

&AtClient
Procedure InscriptionCourseHistoryOfContractClick(Item)
	
	If Not ValueIsFilled(Object.Ref) Or Modified Then
		ClearMessages();
		CommonClient.MessageToUser(
			NStr("vi = 'Dữ liệu vẫn chưa được ghi lại.
		|Chỉ có thể chuyển đến lịch sử tỷ giá ngoại tệ trong hợp đồng sau khi ghi lại dữ liệu.';
		|ru = 'Данные еще не записаны.
		|Переход к истории курса валюты договора возможен только после записи данных.';
		|en = 'The data has not been saved yet.
		|You can go to the contract exchange rate history only after the data is saved.'; fa = 'The data has not been saved yet.
		|You can go to the contract exchange rate history only after the data is saved.';
		|it = 'Dati non ancora salvati.
		|È possibile passare alla cronologia del tasso di cambio della valuta del contratto solo dopo che i dati sono stati salvati.';
		|pl = 'Dane nie zostały jeszcze zapisane.
		|Przejście do historii kursu waluty umowy są możliwe tylko po zapisie danych.';
		|tr = 'Veriler henüz kaydedilmemiştir.
		| Sözleşme döviz kuru geçmişine ancak veriler kaydedildikten sonra erişilebilir.'"));
		Return;
	EndIf;
	
	OpeningParameters = New Structure("Filter", New Structure("Contract", Object.Ref));
	OpenForm("InformationRegister.ARAPAccountingExchangeRatesForContracts.Form.ByContractListForm", OpeningParameters);
	
EndProcedure

&AtClient
Procedure NumeratorOfContractCurrencyExchangeRateOnChange(Item)
	Modified = True;
EndProcedure

&AtClient
Procedure DenominatorOfContractCurrencyExchangeRateOnChange(Item)
	
	Items.CourseMultiplicityEditingGroup.Visible = False;
	Items.InscriptionDenominatorOfContractCurrencyExchangeRate.Visible = True;
	Modified = True;
	ElementManagementIsVariantOfContractCourse();
	
EndProcedure

&AtClient
Procedure ProcedureOfDocumentOffsetOnChange(Item)
	SetTextOfHintOrderOfCreditingDocuments();
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_AttachedFilesPanelCommand(Command)
	 FilesOperationsClient.AttachmentsControlCommand(ThisObject, Command);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldCheckDragging(Item, DragParameters, StandardProcessing)
	 FilesOperationsClient.PreviewFieldCheckDragging(ThisObject, Item, DragParameters, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldDrag(Item, DragParameters, StandardProcessing)
	 FilesOperationsClient.PreviewFieldDrag(ThisObject, Item, DragParameters, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldClick(Item, StandardProcessing)
	 FilesOperationsClient.PreviewFieldClick(ThisObject, Item, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

#Region UniversalFormCommandHandlers
&AtClient
Procedure Attachable_ExecuteLocalizationCommand(Command)
	
	IntercompanyContractsLocalizationClient.ExecuteLocalizationCommand(Command, ThisObject);
	
EndProcedure

&AtClient
Procedure ContinueRunningLocalizationCommand(CommandName, AdditionalParameters) Export
	
	If AdditionalParameters.ServerCallRequired_ Then
		ContinueRunningLocalizationCommandOnServer(CommandName, AdditionalParameters.ProcessingParameters);
	EndIf;
	
EndProcedure

&AtServer
Procedure ContinueRunningLocalizationCommandOnServer(CommandName, ProcessingParameters)
	
	IntercompanyContractsLocalization.ExecuteLocalizationCommand(ThisObject, CommandName, ProcessingParameters);
	
EndProcedure
	
#EndRegion

&AtClient
Procedure SetDateInterval(Command)
	
	TMCommonUseClient.EditPeriod(Object, 
		New Structure("StartDate, EndDate", "ValidityStartDate", "ValidityEndDate"));
	
EndProcedure

&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)
	
	TMCommonUseClient.AllowObjectAttributeEdit(ThisObject);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Object);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Object, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure OnReadCreateAtServer()
	
	TMCommonUseClientServer.SetFormItemProperty(Items, "Change", "Enabled", False);

	If Not ValueIsFilled(Object.ARAPCurrency) Then
		Object.ARAPCurrency = IncomeAndExpensesServer.GetCurrencyOfManagementAccounting();
	EndIf;
	
	FixedContractAmount               = (Object.Sum <> 0);
	NewOnlineARAPAccounting           = GetFunctionalOption("NewOnlineARAPAccounting");
	LocalAccountingCurrency           = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	
	FillInContractCurrencyExchangeRateValues();
	
	If Object.VATTaxationIsDeterminedInDocuments Then
		TaxationTreatment = 1;
	Else
		TaxationTreatment = 0;
	EndIf;
	
	If Object.PurchaseForActivityIsDeterminedInDocument Then
		SeparateVATAccountingMode = 1;
	Else
		SeparateVATAccountingMode = 0;
	EndIf;
	
	If Object.PaymentDueDateIsSet  Then
		DebtClassification = 1;
	Else
		DebtClassification = 0;
	EndIf;
	
	SetBankAccountSelectionParameters();
	
	ConfigureParametersForSelectingCashFlowItem();
	
	SetAvailabilityOfItemsByStatusServer();
	
	ItemManagementExecutionSchedule(Items, FixedContractAmount);
	
	UpdatePurchaseForActivity(False);
	SetPropertiesOfElementsOfTaxationAndSeparateVATAccounting();
	
	FillParameters = Catalogs.IntercompanyContracts.ParametersForFillingInVATTaxation_(Object);
	VATAccountingERP.FillInSalesVATTaxSelectionList(Items.VATTaxation,
															Object.VATTaxation,
															FillParameters,
															VATAccountingCachedParameterValues);
	
	RefreshFormTitle();
	
	Items.NameForPrinting.ChoiceList.Clear();
	Items.NameForPrinting.ChoiceList.Add(Object.Description);
	
	SetConditionalAppearance();
	IntercompanyContractsLocalization.OnReadCreateAtServer(ThisObject);
EndProcedure

&AtClient
Procedure FixedContractAmountOnChange(Item)
	
	If Not FixedContractAmount Then
		Object.Sum = 0;
	EndIf;
	
	ItemManagementExecutionSchedule(Items, FixedContractAmount);
	
EndProcedure

// StandardSubsystems.Properties
&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure
// End StandardSubsystems.Properties

&AtClientAtServerNoContext
Procedure ItemManagementExecutionSchedule(Items, FixedContractAmount)
	
	Items.Sum.Enabled = FixedContractAmount;
	Items.Sum.AutoMarkIncomplete = FixedContractAmount;
	
EndProcedure

&AtServer
Procedure ElementManagementIsVariantOfContractCourse()
	
	VisibilityOfElements = 
		NewOnlineARAPAccounting
		And Object.ARAPCurrency <> LocalAccountingCurrency
		And ValueIsFilled(LocalAccountingCurrency);
	Items.GroupCourseOptionContract.Visible = VisibilityOfElements;
	If Not VisibilityOfElements Then
		Return;
	EndIf;
	
	ToolTipText = "";
	If Object.ContractRateOption = Enums.ContractRateOptions.Mutable Then
		ToolTipText = NStr("vi = 'Công nợ đang được đánh giá lại';
							|ru = 'Задолженность переоценивается';
							|en = 'Debt is under revaluation'; fa = 'Debt is under revaluation';
							|it = 'Rivalutazione debito';
							|pl = 'Trwa przeszacowanie zadłużenia';
							|tr = 'Borçluluk yeniden değerlendirilir'");
	ElsIf Object.ContractRateOption = Enums.ContractRateOptions.FixedAsOfShipmentDate Then
		ToolTipText = NStr("vi = 'Công nợ chưa được đánh giá lại';
							|ru = 'Задолженность не переоценивается';
							|en = 'Debt is not under revaluation'; fa = 'Debt is not under revaluation';
							|it = 'Il debito non viene rivalutato';
							|pl = 'Zadłużenie nie jest przeszacowane';
							|tr = 'Borçluluk yeniden değerlendirilmez'");
	ElsIf Object.ContractRateOption = Enums.ContractRateOptions.SpecifiedInContract Then
		ToolTipText = NStr("vi = 'Công nợ đang được đánh giá lại theo tỷ giá hợp đồng';
							|ru = 'Задолженность переоценивается по курсу договора';
							|en = 'Debt is under revaluation by contract rate'; fa = 'Debt is under revaluation by contract rate';
							|it = 'Il debito viene rivalutato in base al tasso di cambio del contratto';
							|pl = 'Trwa przeszacowanie według kursu umowy';
							|tr = 'Borç, sözleşmenin döviz kuru üzerinden yeniden değerlendirilir'");
	EndIf;
	
	Items.ContractRateOption.ToolTip = ToolTipText;
	
	SetSelectionListOfContractCourseOption();
	
	Items.GroupCourseSpecifiedInContract.Visible = 
		Object.ContractRateOption = Enums.ContractRateOptions.SpecifiedInContract;
	
	If Object.ContractRateOption = Enums.ContractRateOptions.SpecifiedInContract Then
		
		Items.CourseMultiplicityEditingGroup.Visible = Not Items.InscriptionDenominatorOfContractCurrencyExchangeRate.Visible;
		
		If DenominatorOfContractCurrencyExchangeRate < 10 And Int(DenominatorOfContractCurrencyExchangeRate) = DenominatorOfContractCurrencyExchangeRate Then
			Items.InscriptionDenominatorOfContractCurrencyExchangeRate.Width = 9;
			Items.InscriptionDenominatorOfContractCurrencyExchangeRate.HorizontalStretch = False;
		EndIf;
		
		LineDenominatorOfContractCurrencyExchangeRate = ?(
			DenominatorOfContractCurrencyExchangeRate = Int(DenominatorOfContractCurrencyExchangeRate),
			Format(DenominatorOfContractCurrencyExchangeRate, "NFD=0"),
			Format(DenominatorOfContractCurrencyExchangeRate, "NFD=4"));
		
		LineDenominatorOfContractCurrencyExchangeRate = New FormattedString(LineDenominatorOfContractCurrencyExchangeRate,,,, "DenominatorOfContractCurrencyExchangeRateClick");
		
		InscriptionDenominatorOfContractCurrencyExchangeRate = New FormattedString(
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = '%1 trong';
					|ru = '%1 за';
					|en = '%1 for'; fa = '%1 for';
					|it = '%1 per';
					|pl = '%1 za';
					|tr = '%1için'") + " ",
				LocalAccountingCurrency),
			LineDenominatorOfContractCurrencyExchangeRate,
			" ",
			String(Object.ARAPCurrency));
		
		Items.DenominatorOfContractCurrencyExchangeRate.Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '%1 trong';
				|ru = '%1 за';
				|en = '%1 for'; fa = '%1 for';
				|it = '%1 per';
				|pl = '%1 za';
				|tr = '%1için'"),
			LocalAccountingCurrency);
	EndIf;
	
EndProcedure

&AtServer
Procedure SetSelectionListOfContractCourseOption()
	
	NotAvailableFixedOnDateOfShipment = 
		Object.ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts;
	
	ChangeToSelectionListIsRequired = 
		Items.ContractRateOption.ChoiceList.Count() = 0
		Or (Items.ContractRateOption.ChoiceList.Count() = 2
			And Not NotAvailableFixedOnDateOfShipment)
		Or (Items.ContractRateOption.ChoiceList.Count() = 3
			And NotAvailableFixedOnDateOfShipment);
	
	If ChangeToSelectionListIsRequired Then
		Items.ContractRateOption.ChoiceList.Clear();
		Items.ContractRateOption.ChoiceList.Add(Enums.ContractRateOptions.Mutable);
		If Not NotAvailableFixedOnDateOfShipment Then
			Items.ContractRateOption.ChoiceList.Add(Enums.ContractRateOptions.FixedAsOfShipmentDate);
		EndIf;
		Items.ContractRateOption.ChoiceList.Add(Enums.ContractRateOptions.SpecifiedInContract);
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInContractCurrencyExchangeRateValues()
	
	If Object.ContractRateOption = Enums.ContractRateOptions.SpecifiedInContract Then
		ThereIsCourse = InformationRegisters.ARAPAccountingExchangeRatesForContracts.ThereAreRecordsOfContractCurrencyExchangeRate(Object.Ref);
		If ThereIsCourse And Not ClearContractCurrencyExchangeRate Then
			CourseValues = InformationRegisters.ARAPAccountingExchangeRatesForContracts.GetContractCurrencyExchangeRateValues(Object.Ref, CurrentSessionDate());
		Else
			CourseValues = ProcessingOfExchangeRatesTM.GetCurrencyRate(Object.ARAPCurrency, CurrentSessionDate(), LocalAccountingCurrency);
		EndIf;
		NumeratorOfContractCurrencyExchangeRate   = CourseValues.CourseNumerator;
		DenominatorOfContractCurrencyExchangeRate = CourseValues.CourseDenominator;
	EndIf;
	
EndProcedure

&AtServer
Procedure RecordValuesOfContractCurrencyExchangeRate(ReferenceToRecordedElement)
	
	If ClearContractCurrencyExchangeRate Then
		InformationRegisters.ARAPAccountingExchangeRatesForContracts.ClearCourseHistoryByContract(ReferenceToRecordedElement);
	EndIf;
	If Object.ContractRateOption = Enums.ContractRateOptions.SpecifiedInContract Then
		InformationRegisters.ARAPAccountingExchangeRatesForContracts.RecordValuesOfContractCurrencyExchangeRate(
			ReferenceToRecordedElement, 
			CurrentSessionDate(),
			NumeratorOfContractCurrencyExchangeRate,
			DenominatorOfContractCurrencyExchangeRate);
	EndIf;
	
EndProcedure

&AtServer
Procedure CheckContractCurrencyExchangeRate()
	
	If InformationRegisters.ARAPAccountingExchangeRatesForContracts.ThereAreRecordsOfContractCurrencyExchangeRate(Object.Ref) Then
		If NewOnlineARAPAccounting
			And Object.ARAPCurrency <> LocalAccountingCurrency
			And ValueIsFilled(LocalAccountingCurrency)
			And Object.ContractRateOption = Enums.ContractRateOptions.SpecifiedInContract Then
			Common.MessageToUser(NStr("vi = 'Lịch sử tỷ giá tiền tệ hạch toán trong hợp đồng sẽ bị xóa và điền lại bởi các giá trị khi ghi lại hợp đồng.';
										|ru = 'История курса валюты расчетов договора будет очищена и заполнена новыми значениями при записи договора.';
										|en = 'The exchange rate history of AR/AP under the contract will be cleared and filled with new values when saving the contract.'; fa = 'The exchange rate history of AR/AP under the contract will be cleared and filled with new values when saving the contract.';
										|it = 'La cronologia del tasso di cambio della valuta del contratto verrà cancellata e compilata con i nuovi valori dopo il salvataggio del contratto.';
										|pl = 'Historia kursu waluty rozliczeń umowy zostanie wyczyszczona i wypełniona w nowe wartości podczas zapisywania umowy.';
										|tr = 'Sözleşme mutabakatının para biriminin geçmişi temizlenecek ve sözleşme kaydedildiğinde yeni değerlerle doldurulacaktır.'"));
		Else
			Common.MessageToUser(NStr("vi = 'Lịch sử tỷ giá tiền tệ hạch toán trong hợp đồng sẽ bị xóa khi ghi lại hợp đồng.';
										|ru = 'История курса валюты расчетов договора будет очищена при записи договора.';
										|en = 'The exchange rate history of AR/AP under the contract will be cleared when saving the contract.'; fa = 'The exchange rate history of AR/AP under the contract will be cleared when saving the contract.';
										|it = 'La cronologia del tasso di cambio della valuta del contratto verrà cancellata dopo la registrazione del contratto.';
										|pl = 'Historia kursu waluty rozliczeń umowy zostanie wyczyszczona podczas zapisywania umowy.';
										|tr = 'Sözleşme mutabakatının döviz kurunun geçmişi, sözleşme kaydedildiğinde silinecektir.'"));
		EndIf;
		ClearContractCurrencyExchangeRate = True;
	EndIf;
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();
	
EndProcedure

#Region OnChangeAttributes

&AtServer
Procedure ContractTypeOnChangeServer()
	
	RefreshFormTitle();
	
	UpdatePurchaseForActivity();
	CompleteVATTaxation();
	VATTaxationOnChangeServer();
	AtEndOfChangingLocalizationDetailsOnServer("ContractType", Undefined);
	ObjectsFillingByStatistics.FillInSubordinateDetailsOfObject(Object, "ARAPObjectSettings");

EndProcedure

&AtServer
Procedure ARAPCurrencyOnChangeServer()
	
	Object.ForeignCurrencyTransaction = ARAPAccountingServer.GetPaidInDefaultCurrency();
	
	ProcessBankAccounts();
	SetVisibilityOfPaymentInCurrency();
	
	CheckContractCurrencyExchangeRate();
	CheckCurrenciesOfLocalAccountingAndExchangeRateOptionOfContract();
	FillInContractCurrencyExchangeRateValues();
	ElementManagementIsVariantOfContractCourse();
	
EndProcedure

&AtServer
Procedure LineOfBusinessOnChangeServer()
	
	If Not ValueIsFilled(Object.LineOfBusiness) Then
		Return;
	EndIf;
	
	DetailsOfAppointment = "CostAccounting, VATTaxationIsDeterminedInDocuments";
	DestinationDetailsValues = Common.ObjectAttributesValues(Object.LineOfBusiness, DetailsOfAppointment);
	
	If DestinationDetailsValues.CostAccounting
		And Object.ContractType = Enums.TypesOfIntercompanyContracts.PurchaseAndSale Then
		
		Object.PurchaseForActivityIsDeterminedInDocument = DestinationDetailsValues.VATTaxationIsDeterminedInDocuments;
		SeparateVATAccountingMode = ?(Object.PurchaseForActivityIsDeterminedInDocument, 1, 0);
		
		UpdatePurchaseForActivity();
	EndIf;
	
	SetPropertiesOfElementsOfTaxationAndSeparateVATAccounting();
	
EndProcedure

&AtServer
Procedure OrganizationOnChangeServer()
	
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	
	SetParametersForSelectingRecipientOrganization();
	CheckAndClearRecipientSOrganization();
	
	CompleteVATTaxation();
	VATTaxationOnChangeServer();
	
	ProcessBankAccounts();
	SetVisibilityOfPaymentInCurrency();
	
	CheckContractCurrencyExchangeRate();
	CheckCurrenciesOfLocalAccountingAndExchangeRateOptionOfContract();
	ElementManagementIsVariantOfContractCourse();
	
EndProcedure

&AtServer
Procedure StartDateOfActionWhenChangeIsMadeOnServer()
	
	UpdatePurchaseForActivity();
	CompleteVATTaxation();
	VATTaxationOnChangeServer();
	
EndProcedure

&AtServer
Procedure VariantOfContractCourseWhenChangedOnServer()
	
	CheckContractCurrencyExchangeRate();
	If Not (ValueIsFilled(NumeratorOfContractCurrencyExchangeRate) And ValueIsFilled(DenominatorOfContractCurrencyExchangeRate)) Then
		FillInContractCurrencyExchangeRateValues();
	EndIf;
	ElementManagementIsVariantOfContractCourse();
	
EndProcedure

&AtServer
Procedure CalculationProcedureOnChangeATServer()
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "ARAPObjectSettings")
	
EndProcedure

&AtServer
Procedure SetParametersForSelectingRecipientOrganization()
	
	ParametersArray = New Array;
	
	If ValueIsFilled(Object.Organization) Then
		
		ParametersArray.Add(New ChoiceParameter("Filter.LocalAccountingCurrency",
				LocalAccountingCurrency));
		ParametersArray.Add(New ChoiceParameter("Filter.RegistrationCountry",
				Common.ObjectAttributeValue(Object.Organization, "RegistrationCountry")));
		
	EndIf;
	
	Items.CompanyRecipient.ChoiceParameters = New FixedArray(ParametersArray);
	
EndProcedure

&AtServer
Procedure CheckAndClearRecipientSOrganization()
	
	If ValueIsFilled(Object.Organization)
		And ValueIsFilled(Object.CompanyRecipient) Then
		
		CheckStructure = Catalogs.Companies.CountriesOfRegistrationAndCurrenciesOfRegulatedAccountingCoincide(Object.Organization, Object.CompanyRecipient);
		If Not CheckStructure.CurrenciesDoNotMatch Or Not CheckStructure.CountriesMatch Then
			Object.CompanyRecipient = Undefined;
		EndIf;
		
	EndIf
	
EndProcedure

&AtServer
Procedure CompanyRecipientOnChangeServer()
	
	FillInOrganizationSDefaultBankAccount(Object.CompanyRecipient, Object.ForeignCurrencyTransaction, Object.BankAccountOfBeneficiary, LocalAccountingCurrency);
	
	ObjectsFillingByStatistics.FillInSubordinateDetailsOfObject(Object, "CompanyRecipient", , True);
	
	UpdatePurchaseForActivity();
	SetPropertiesOfElementsOfTaxationAndSeparateVATAccounting();
	
	CheckContractCurrencyExchangeRate();
	CheckCurrenciesOfLocalAccountingAndExchangeRateOptionOfContract();
	ElementManagementIsVariantOfContractCourse();
	
EndProcedure

&AtServer
Procedure VATTaxationOnChangeServer()
	
	If Not VATAccountingERPClientServer.DisplayNDSInResultsOfSalesDocument(Object.VATTaxation) 
		And Not Object.VATTaxationIsDeterminedInDocuments Then
		Object.VATRate = Catalogs.VATRates.EXCLUDINGVAT;
	Else
		VATAccountingERP.FillInVATRateForPayments_(Object.VATRate, Object.VATTaxation, Object.Organization, Object.ValidityEndDate);
	EndIf;
	
	SetPropertiesOfElementsOfTaxationAndSeparateVATAccounting();
	
EndProcedure

&AtServer
Procedure ProcessBankAccounts()
	
	SetBankAccountSelectionParameters();
	
	If Not BankAccountCorrespondsToPaymentProcedure(Object.BankAccount) Then
		Object.BankAccount = Undefined;
	EndIf;
	FillInOrganizationSDefaultBankAccount(Object.Organization, Object.ForeignCurrencyTransaction, Object.BankAccount, LocalAccountingCurrency);
	
	ObjectsFillingByStatistics.FillInSubordinateDetailsOfObject(Object, "Organization", , True);
	
	If Not BankAccountCorrespondsToPaymentProcedure(Object.BankAccountOfBeneficiary) Then
		Object.BankAccountOfBeneficiary = Undefined;
	EndIf;
	FillInOrganizationSDefaultBankAccount(Object.CompanyRecipient, Object.ForeignCurrencyTransaction, Object.BankAccountOfBeneficiary, LocalAccountingCurrency);
	
	ObjectsFillingByStatistics.FillInSubordinateDetailsOfObject(Object, "CompanyRecipient", , True);
	
EndProcedure

&AtServer
Procedure SetVisibilityOfPaymentInCurrency()
	Items.ForeignCurrencyTransaction.Visible = Not Object.ARAPCurrency = LocalAccountingCurrency Or Object.ForeignCurrencyTransaction;
EndProcedure

#EndRegion

#Region ControlOfInconsistentChanges

// Parameters:
//	Item - FormField - FormItem
&AtClient
Procedure ControlOfNonConsistentChangesHandleEventOnChange(Item)
	If Item.Name = "CompanyRecipient" Then
		CompanyRecipientOnChange(Item);
	ElsIf Item.Name = "Organization" Then
		OrganizationOnChange(Item);
	ElsIf Item.Name = "ARAPCurrency" Then
		ARAPCurrencyOnChange(Item);
	ElsIf Item.Name = "ForeignCurrencyTransaction" Then
		ForeignCurrencyTransactionOnChange(Item);
	ElsIf Item.Name = "ContractType" Then
		ContractTypeOnChange(Item);
	ElsIf Item.Name = Items.ValidityStartDate.Name Then
		ValidityStartDateOnChange(Item);
	ElsIf Item.Name = "ARAPObjectSettings" Then 
		ARAPObjectSettingsOnChange(Item);
	ElsIf Item.Name = "ContractRateOption" Then 
		ContractRateOptionOnChange(Item);
	ElsIf Item.Name = "NumeratorOfContractCurrencyExchangeRate" Then 
		NumeratorOfContractCurrencyExchangeRateOnChange(Item);
	ElsIf Item.Name = "DenominatorOfContractCurrencyExchangeRate" Then 
		DenominatorOfContractCurrencyExchangeRateOnChange(Item);
	Else
		TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisObject, Item);
	EndIf;
EndProcedure

// Parameters:
//	Command - FormCommand - 
&AtClient
Procedure ControlOfNonConsistentChangesHandleCommandEvent(Command)
	If Command.Name = "SetDateInterval" Then
		SetDateInterval(Command);
	Else
		TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisObject, Command);
	EndIf;
EndProcedure

&AtClient
Procedure ControlOfNonConsistentChangesHandleEventBeforeStartingChange(Item, Cancel)
	
	TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure ControlOfNonConsistentChangesHandleEventBeforeDeletion(Item, Cancel)
	
	TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure ControlOfNonConsistentChangesHandleEventBeforeStartingAdding(Item, Cancel, Copy, Parent, Var_Group)
	
	TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisObject, Item);
	
EndProcedure

// Parameters:
//	Item - FormField - FormItem
&AtClient
Procedure Attachable_WhenChanging_SetAvailabilityOfItemsByStatusServer(Item)
	
	If TMCommonUseClient.WhenActingOnStatusDependentElement(ThisObject) Then
		Return;
	EndIf;
	
	If StructureOfActionsControlOfNonAgreedChanges.OnChange.Property(Item.Name) Then
		ControlOfNonConsistentChangesHandleEventOnChange(Item);
	EndIf;

EndProcedure

// Parameters:
//	Command - FormCommand - 
&AtClient
Procedure Attachable_Command_SetAvailabilityOfItemsByStatusServer(Command)
	
	If TMCommonUseClient.WhenActingOnStatusDependentElement(ThisObject) Then
		Return;
	EndIf;
	
	If StructureOfActionsControlOfNonAgreedChanges.Commands.Property(Command.Name) Then
		ControlOfNonConsistentChangesHandleCommandEvent(Command);
	EndIf;
	
EndProcedure

// Parameters:
//	Item - FormField - FormItem
&AtClient
Procedure Attachable_BeforeStartingChange_SetAvailabilityOfItemsByStatusServer(Item, Cancel)
	
	If TMCommonUseClient.WhenActingOnStatusDependentElement(ThisObject) Then
		Return;
	EndIf;
	
	If StructureOfActionsControlOfNonAgreedChanges.BeforeRowChange.Property(Item.Name) Then
		ControlOfNonConsistentChangesHandleEventBeforeStartingChange(Item, Cancel);
	EndIf;
	
EndProcedure

// Parameters:
//	Item - FormField - FormItem
&AtClient
Procedure Attachable_BeforeDeleting_SetAvailabilityOfItemsByStatusServer(Item, Cancel)
	
	If TMCommonUseClient.WhenActingOnStatusDependentElement(ThisObject) Then
		Return;
	EndIf;
	
	Name = Item.Name;
	If StructureOfActionsControlOfNonAgreedChanges.BeforeDeleteRow.Property(Name) Then
		ControlOfNonConsistentChangesHandleEventBeforeDeletion(Item, Cancel);
	EndIf;
	
EndProcedure

// Parameters:
//	Item - FormField - FormItem
&AtClient
Procedure Attachable_BeforeYouStartAdding_SetAvailabilityOfItemsByStatusServer(Item, Cancel, Copy, Parent, Var_Group)
	
	If TMCommonUseClient.WhenActingOnStatusDependentElement(ThisObject) Then
		Return;
	EndIf;
	
	Name = Item.Name;
	If StructureOfActionsControlOfNonAgreedChanges.BeforeAddRow.Property(Name) Then
		ControlOfNonConsistentChangesHandleEventBeforeStartingAdding(Item, Cancel, Copy, Parent, Var_Group);
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_WhenChangingDetailsDependingOnStatus()
	
	SetAvailabilityOfItemsByStatusServer();
	TMCommonUseClient.AfterChangingPropsDependentOnStatus(ThisObject);
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure SetAvailabilityOfItemsByStatusServer()
	
	ItemArray = New Array;
	
	// Header Controls
	ItemArray.Add("Date");
	ItemArray.Add("Number");
	ItemArray.Add("ValidityStartDate");
	ItemArray.Add("ValidityEndDate");
	ItemArray.Add("CompanyRecipient");
	ItemArray.Add("Organization");
	ItemArray.Add("ARAPCurrency");
	ItemArray.Add("ForeignCurrencyTransaction");
	ItemArray.Add("ContractType");
	ItemArray.Add("ARAPObjectSettings");
	ItemArray.Add("SetDateInterval");
	
	TMCommonUse.SetSubscriptionForFormElementChangeEvents(ThisObject, ItemArray);
	
EndProcedure

&AtServer
Procedure SetBankAccountSelectionParameters()

	ParametersArray = New Array;
	
	If Not Object.ForeignCurrencyTransaction Then
		ParametersArray.Add(New ChoiceParameter("Filter.CashCurrency", LocalAccountingCurrency));
	Else
		ParametersArray.Add(New ChoiceParameter("Filter.CashCurrency", New FixedArray(ForeignCurrencies())));
	EndIf;
	
	ParametersArray.Add(New ChoiceParameter("SelectingAccountsOfParentCompany", Undefined));
	ParametersArray.Add(New ChoiceParameter("Filter.Closed", False));
	
	AccountSelectionParameters = New FixedArray(ParametersArray);
	Items.BankAccount.ChoiceParameters            = AccountSelectionParameters;
	Items.BankAccountOfBeneficiary.ChoiceParameters  = AccountSelectionParameters;
	
EndProcedure

&AtServer
Function ForeignCurrencies()
	
	Query = New Query("
	|SELECT
	|	Currencies.Ref AS Ref
	|FROM
	|	Catalog.Currencies AS Currencies
	|WHERE
	|	Currencies.Ref <> &LocalAccountingCurrency
	|");
	Query.SetParameter("LocalAccountingCurrency", LocalAccountingCurrency);
	
	Return Query.Execute().Unload().UnloadColumn("Ref");
	
EndFunction

&AtServer
Function BankAccountCorrespondsToPaymentProcedure(BankAccount)

	Respond = True;
	
	If ValueIsFilled(BankAccount) Then
		
		AccountCurrency = Common.ObjectAttributeValue(BankAccount, "CashCurrency");
		
		If Object.ForeignCurrencyTransaction Then
			Respond = AccountCurrency <> LocalAccountingCurrency;
		Else
			Respond = AccountCurrency = LocalAccountingCurrency;
		EndIf;
		
	EndIf;
	
	Return Respond;
	
EndFunction

&AtServerNoContext
Procedure FillInOrganizationSDefaultBankAccount(AccountHolder, ForeignCurrencyTransaction, InvoiceToFillIn, LocalAccountingCurrency)
	
	If ValueIsFilled(InvoiceToFillIn)
	 Or Not ValueIsFilled(AccountHolder) Then
		Return;
	EndIf;
	
	ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(AccountHolder);
	ParametersOfAccount.ExcludeCurrencyAccounts = ForeignCurrencyTransaction;
	ParametersOfAccount.Currency = LocalAccountingCurrency;
	
	InvoiceToFillIn = Catalogs.CompaniesBankAccounts.GetDefaultBankAccount(ParametersOfAccount);
	
EndProcedure

&AtServer
Procedure RefreshFormTitle()
	
	If Object.ContractType = Enums.TypesOfIntercompanyContracts.PurchaseAndSale Then
		TypePresentation = NStr("vi = 'Hợp đồng mua bán';
								|ru = 'Договор купли-продажи';
								|en = 'Purchase and sale contract'; fa = 'قرارداد خرید و فروش';
								|it = 'Accordo di compravendita';
								|pl = 'Umowa kupna-sprzedaży';
								|tr = 'Alış-satış sözleşmesi'");
	ElsIf Object.ContractType = Enums.TypesOfIntercompanyContracts.Consignment Then
		TypePresentation = NStr("vi = 'Hợp đồng ký gửi';
								|ru = 'Договор комиссии';
								|en = 'Cross-company sales contract'; fa = 'قرارداد فروش بین‌شرکتی';
								|it = 'Accordo di commissione';
								|pl = 'Umowa komisowa';
								|tr = 'Komisyon sözleşmesi'");
	Else
		TypePresentation = Title;
	EndIf;
	
	If Object.ContractType = Enums.TypesOfIntercompanyContracts.PurchaseAndSale Then
		Items.CompanyGroup.Title = NStr("vi = 'Nhà cung cấp';
										|ru = 'Поставщик';
										|en = 'Vendor'; fa = 'تأمین‌کننده';
										|it = 'Fornitore';
										|pl = 'Dostawca';
										|tr = 'Tedarikçi'");
		Items.GroupOrganizationRecipient.Title = NStr("vi = 'Khách hàng';
														|ru = 'Покупатель';
														|en = 'Customer'; fa = 'مشتری';
														|it = 'Acquirente';
														|pl = 'Nabywca';
														|tr = 'Müşteri'");
		Items.FinancialAccountingGroup.Title = NStr("vi = 'Nhóm kế toán hạch toán với khách hàng';
													|ru = 'Группа учета расчетов с покупателем';
													|en = 'Group of AR/AP accounting with customer'; fa = 'Group of AR/AP accounting with customer';
													|it = 'Il gruppo contabile dell''acquirente';
													|pl = 'Grupa ewidencji rozliczeń z nabywcą';
													|tr = 'Alıcı ile hesaplaşma muhasebesi grubu'");
		Items.FinancialAccountingGroupOfRecipient.Title = NStr("vi = 'Nhóm kế toán hạch toán với nhà cung cấp';
																|ru = 'Группа учета расчетов с поставщиком';
																|en = 'Group of AR/AP accounting with vendor'; fa = 'Group of AR/AP accounting with vendor';
																|it = 'Il gruppo contabile del fornitore';
																|pl = 'Grupa ewidencji rozliczeń z dostawcą';
																|tr = 'Sağlayıcı ile hesaplaşma muhasebesi grubu'");
	Else
		Items.CompanyGroup.Title = NStr("vi = 'Người đặt ký gửi';
										|ru = 'Комитент';
										|en = 'Consignor'; fa = 'امانت‌گذار';
										|it = 'Committente';
										|pl = 'Komitent';
										|tr = 'Gönderici'");
		Items.GroupOrganizationRecipient.Title = NStr("vi = 'Người nhận bán ký gửi';
														|ru = 'Комиссионер';
														|en = 'Consignee'; fa = 'امانت‌دار';
														|it = 'Commissionario';
														|pl = 'Komisant';
														|tr = 'Konsinye'");
		Items.FinancialAccountingGroup.Title = NStr("vi = 'Nhóm kế toán hạch toán với người nhận ký gửi';
													|ru = 'Группа учета расчетов с комиссионером';
													|en = 'Group of AR/AP accounting with consignee'; fa = 'گروه حسابداری دریافتنی/پرداختنی با امانت‌دار';
													|it = 'Il gruppo contabile del commissionario';
													|pl = 'Grupa ewidencji rozliczeń z komisantem';
													|tr = 'Konsinye ile hesaplaşma muhasebesi grubu'");
		Items.FinancialAccountingGroupOfRecipient.Title = NStr("vi = 'Nhóm kế toán hạch toán với người đặt ký gửi';
																|ru = 'Группа учета расчетов с комитентом';
																|en = 'Group of AR/AP accounting with consignor'; fa = 'گروه حسابداری دریافتنی/پرداختنی با امانت‌گذار';
																|it = 'Il gruppo contabile del committente';
																|pl = 'Grupa ewidencji rozliczeń z komitentem';
																|tr = 'Gönderici ile hesaplaşma muhasebesi grubu'");
	EndIf;

	If Not ValueIsFilled(Object.Ref) Then
		Title = TypePresentation + " (" + NStr("vi = 'tạo';
												|ru = 'создание';
												|en = 'create'; fa = 'ایجاد';
												|it = 'создание';
												|pl = 'create';
												|tr = 'oluşturma'") + ")";
	Else
		Title = Object.Description + " (" + TypePresentation + ")";
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisObject);
	
EndProcedure

&AtServer
Procedure ConfigureParametersForSelectingCashFlowItem()
	
	ChoiceParametersArray = New Array;
	
	ChoiceParameter = New ChoiceParameter("Filter.BusinessOperation", Enums.BusinessTransactions.CashReceiptFromCustomer);
	ChoiceParametersArray.Add(ChoiceParameter);
	Items.CashFlowItem.ChoiceParameters = New FixedArray(ChoiceParametersArray);
	
	ChoiceParametersArray.Clear();
	
	ChoiceParameter = New ChoiceParameter("Filter.BusinessOperation", Enums.BusinessTransactions.PaymentToVendor);
	ChoiceParametersArray.Add(ChoiceParameter);
	Items.CashFlowItemOfRecipient.ChoiceParameters = New FixedArray(ChoiceParametersArray);
	
EndProcedure

&AtServer
Procedure CompleteVATTaxation()
	
	FillParameters = Catalogs.IntercompanyContracts.ParametersForFillingInVATTaxation_(Object);
	
	If ValueIsFilled(Object.VATTaxation)
		And Object.VATTaxationIsDeterminedInDocuments Then
		
		Object.VATTaxation = Undefined;
		
	ElsIf Not Object.VATTaxationIsDeterminedInDocuments Then
		VATAccountingERP.FillInSalesVATTaxation(Object.VATTaxation,
													FillParameters,
													VATAccountingCachedParameterValues);
	EndIf;
	
	VATAccountingERP.FillInSalesVATTaxSelectionList(Items.VATTaxation,
															Object.VATTaxation,
															FillParameters,
															VATAccountingCachedParameterValues);
	
	SetPropertiesOfElementsOfTaxationAndSeparateVATAccounting();
	
EndProcedure

&AtServer
Procedure SetPropertiesOfElementsOfTaxationAndSeparateVATAccounting()
	
	Items.VATTaxation.Enabled     = Not Object.VATTaxationIsDeterminedInDocuments;
	Items.PurchaseForActivity.Enabled = Not Object.PurchaseForActivityIsDeterminedInDocument;
	
	Items.VATRate.Enabled = Object.VATTaxationIsDeterminedInDocuments
										Or VATAccountingERPClientServer.DisplayNDSInResultsOfSalesDocument(Object.VATTaxation);
	
	Items.SeparateVATAccountingGroup.Visible = (Object.ContractType = Enums.TypesOfIntercompanyContracts.PurchaseAndSale);
	
EndProcedure

&AtServer
Procedure UpdatePurchaseForActivity(FillInTypeOfActivity = True)
	
	FillParameters = Catalogs.IntercompanyContracts.ParametersForFillingInVATActivityType(Object);
	
	If ValueIsFilled(Object.PurchaseForActivity)
		And Object.PurchaseForActivityIsDeterminedInDocument Then
		
		Object.PurchaseForActivity = Undefined;
		
	ElsIf FillInTypeOfActivity
		And Not Object.PurchaseForActivityIsDeterminedInDocument Then
		
		VATAccountingERP.FillInTypeOfActivityVAT(Object.PurchaseForActivity, FillParameters,
			VATAccountingCachedParameterValues);
		
	EndIf;
	
	VATAccountingERP.FillInActivitySelectionList(Items.PurchaseForActivity,
														Object.PurchaseForActivity,
														FillParameters,
														VATAccountingCachedParameterValues);
	
	VisibilitySeparateVATAccountingMode = Items.PurchaseForActivity.Visible;
	
	Items.TheModeOfSeparateAccountingOfNDSIsDeterminedByTheValue.Visible = VisibilitySeparateVATAccountingMode;
	Items.SeparateVATAccountingMode.Visible = VisibilitySeparateVATAccountingMode;
	
EndProcedure

&AtServer
Procedure CheckCurrenciesOfLocalAccountingAndExchangeRateOptionOfContract()
	
	If Object.ARAPCurrency = LocalAccountingCurrency Then
		Object.ContractRateOption = Enums.ContractRateOptions.Mutable;
	EndIf;
	
EndProcedure

&AtServer
Procedure SetTextOfHintOrderOfCreditingDocuments()
	ToolTipText = "";
	If Object.OffsetOrderOfPaymentsAndInvoices = PredefinedValue("Enum.OffsetOrdersOfPaymentsAndInvoices.ByDocumentDateAndType") Then
		ToolTipText = NStr("vi = 'Theo ngày và dạng chứng từ – các khoản thanh toán trả sau sẽ được phân bổ trước cho các hóa đơn có ngày kết chuyển chứng từ nhỏ nhất, các hóa đơn sẽ bù trừ các khoản tạm ứng có ngày kết chuyển chứng từ nhỏ nhất.
		|Các chứng từ trong ngày sẽ được tính theo dạng: thứ nhất, chuyển khoản tạm ứng và công nợ, hóa đơn, trả lại hàng hóa và điều chỉnh hóa đơn, thanh toán, trả lại tiền, v.v.';
		|ru = 'По дате и виду документа – постоплаты будут сначала распределяться на накладные с минимальной датой проведения документа, накладные будут зачитывать авансы с минимальной датой документа.
		|Документы в пределах дня будут зачитываться по виду: сначала переносы авансов и задолженности, накладные, возвраты товаров и корректировки накладных, оплаты, возвраты ДС и пр.';
		|en = 'By document date and kind: postpayments are first allocated to invoices with the earliest document posting date. Invoices offset prepayments with the earliest document date.
		|Documents within one day are offset by their kind: first, prepayment and debt offsets, invoices, returns of goods and invoice adjustments, payments, refunds, and so on.'; fa = 'By document date and kind: postpayments are first allocated to invoices with the earliest document posting date. Invoices offset prepayments with the earliest document date.
		|Documents within one day are offset by their kind: first, prepayment and debt offsets, invoices, returns of goods and invoice adjustments, payments, refunds, and so on.';
		|it = 'По дате и виду документа – постоплаты будут сначала распределяться на накладные с минимальной датой проведения документа, накладные будут зачитывать авансы с минимальной датой документа.
		|Документы в пределах дня будут зачитываться по виду: сначала переносы авансов и задолженности, накладные, возвраты товаров и корректировки накладных, оплаты, возвраты ДС и пр.';
		|pl = 'By document date and kind: postpayments are first allocated to invoices with the earliest document posting date. Invoices offset prepayments with the earliest document date.
		|Documents within one day are offset by their kind: first, prepayment and debt offsets, invoices, returns of goods and invoice adjustments, payments, refunds, and so on.';
		|tr = 'Belge tarihi ve saatine göre, ertelenmiş ödemeler ilk olarak minimum belge tarihine sahip faturalara tahsis edilecek, faturalar minimum belge tarihine sahip avanslardan mahsup edilecektir.
		|Ürünlerin iadesi ve faturalarda yapılan ayarlamalar, ödemeler, iadeler vs., türü ve numarasına göre değerlendirilecektir.'");
	ElsIf Object.OffsetOrderOfPaymentsAndInvoices = PredefinedValue("Enum.OffsetOrdersOfPaymentsAndInvoices.ByDocumentDateAndTime") Then
		ToolTipText = NStr("vi = 'Theo ngày và thời gian chứng từ – các khoản thanh toán trả sau sẽ được phân bổ trước cho các hóa đơn có ngày kết chuyển chứng từ nhỏ nhất, các hóa đơn sẽ bù trừ các khoản tạm ứng có ngày kết chuyển chứng từ nhỏ nhất.
		|Các chứng từ trong ngày sẽ được tính theo thời gian kết chuyển, dạng và số thứ tự.';
		|ru = 'По дате и времени документа – постоплаты будут сначала распределяться на накладные с минимальной датой проведения документа, накладные будут зачитывать авансы с минимальной датой документа.
		|Документы в пределах дня будут зачитываться по времени проведения, типу и номеру.';
		|en = 'By document date and time: postpayments are first allocated to invoices with the earliest document posting date. Invoices offset prepayments with the earliest document date.
		|Documents within one day are offset by posting time, type, and number.'; fa = 'By document date and time: postpayments are first allocated to invoices with the earliest document posting date. Invoices offset prepayments with the earliest document date.
		|Documents within one day are offset by posting time, type, and number.';
		|it = 'По дате и времени документа – постоплаты будут сначала распределяться на накладные с минимальной датой проведения документа, накладные будут зачитывать авансы с минимальной датой документа.
		|Документы в пределах дня будут зачитываться по времени проведения, типу и номеру.';
		|pl = 'By document date and time: postpayments are first allocated to invoices with the earliest document posting date. Invoices offset prepayments with the earliest document date.
		|Documents within one day are offset by posting time, type, and number.';
		|tr = 'Belge tarihi ve saatine göre, ertelenmiş ödemeler ilk olarak minimum belge tarihine sahip faturalara tahsis edilecek, faturalar minimum belge tarihine sahip avanslardan mahsup edilecektir.
		|Gün içerisindeki belgeler bekletme zamanı, türü ve numarasına göre değerlendirilecektir.'");
	ElsIf Object.OffsetOrderOfPaymentsAndInvoices = PredefinedValue("Enum.OffsetOrdersOfPaymentsAndInvoices.ByPlannedRepaymentDate") Then
		ToolTipText = NStr("vi = 'Đến ngày trả nợ theo kế hoạch - các khoản trả sau sẽ được phân bổ trước cho các hóa đơn có ngày thanh toán nhỏ nhất, các hóa đơn sẽ bù trừ các khoản tạm ứng có ngày trả nợ nhỏ nhất.
		|Các chứng từ trong ngày sẽ được đọc theo kiểu và số.';
		|ru = 'По плановой дате погашения – постоплаты будут сначала распределяться на накладные с минимальной датой платежа, накладные будут зачитывать авансы с минимальной датой погашения.
		|Документы в пределах дня будут зачитываться по типу и номеру.';
		|en = 'By planned repayment date: postpayments are first allocated to invoices with the earliest payment date. Invoices offset prepayments with the earliest repayment date.
		|Documents within one day are offset by type and number.'; fa = 'By planned repayment date: postpayments are first allocated to invoices with the earliest payment date. Invoices offset prepayments with the earliest repayment date.
		|Documents within one day are offset by type and number.';
		|it = 'По плановой дате погашения – постоплаты будут сначала распределяться на накладные с минимальной датой платежа, накладные будут зачитывать авансы с минимальной датой погашения.
		|Документы в пределах дня будут зачитываться по типу и номеру.';
		|pl = 'By planned repayment date: postpayments are first allocated to invoices with the earliest payment date. Invoices offset prepayments with the earliest repayment date.
		|Documents within one day are offset by type and number.';
		|tr = 'Belge tarihi ve saatine göre, ertelenmiş ödemeler ilk olarak minimum belge tarihine sahip faturalara tahsis edilecek, faturalar minimum belge tarihine sahip avanslardan mahsup edilecektir.
		|Gün içerisindeki belgeler bekletme zamanı, türü ve numarasına göre değerlendirilecektir.'");
	Else
		ToolTipText = Constants.OffsetOrderOfPaymentsAndInvoices.Get();
	EndIf;
	Items.OffsetOrderOfPaymentsAndInvoices.ToolTip = ToolTipText;
EndProcedure

#EndRegion

#EndRegion

#Region Localization

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure

// End IntegrationWith1CDocumentManagementSubsystem

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
	If Item.Name = "sh_ShamsiInput_ValidityStartDate" Then
		ValidityStartDateOnChange(Items.ValidityStartDate);
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
