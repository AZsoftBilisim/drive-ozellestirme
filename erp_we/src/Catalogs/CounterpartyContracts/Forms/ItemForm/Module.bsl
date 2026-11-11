
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	Parameters.Property("VerificationWhenCreatingContract", VerificationWhenCreatingContract);
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	ARAPAccountingFormWork.FormWhenCreatedOnServer(ThisObject);
	NotifyAboutCreationOfCalculationObject = Parameters.NotifyAboutCreationOfCalculationObject;
	
	If Not ValueIsFilled(Object.Ref) Then
		
		If Not CheckPartnerFlagsClientVendor(Object.Partner, Object.BusinessOperation, True) Then
			Cancel = True;
		EndIf;
	
		If Parameters.Property("FillingText")
				And ValueIsFilled(Parameters.FillingText) Then
			Object.Description = Parameters.FillingText;
		EndIf;
		
		If Not ValueIsFilled(Object.PurchaseRegistrationOption) Then
			Object.PurchaseRegistrationOption = Enums.PurchaseRegistrationOptions.NotSeparate;
		EndIf;
		
		If Not ValueIsFilled(Object.OptionForRegisteringServiceReceiptDocuments) Then
			Object.OptionForRegisteringServiceReceiptDocuments = Enums.OptionsForRegisteringServiceDocuments.ReceiptOfServicesNotUsed;
		EndIf;
		
		If Not ValueIsFilled(Object.OptionOfDeterminingExecutionScheduleInContract) Then
			Object.OptionOfDeterminingExecutionScheduleInContract = Enums.OptionsForDeterminingExecutionScheduleInContract.SalesOrderCustomerInvoices;
		EndIf;
		
		OnReadCreateAtServer();
		
		If Object.ContractType = Enums.ContractTypes.WithConsignee
			And OnlyConsignmentSales25 Then
			Object.ConsignmentSales25 = True;
		EndIf;
		
		If ValueIsFilled(Object.CommissionAgentPartner) Then
			CommissionAgentPartnerWhenChangesAreMadeOnServer();
		EndIf;
		
		If ValueIsFilled(Object.ContractWithCommissionAgent) Then
			AgreementWithCommissionAgentInCaseOfChangesOnServer();
		EndIf;
		
		ContractTypeOnChangeServer();
		
		SetValuesForDiscountingDetails();
		
	EndIf;
	
	If GetFunctionalOption("TradeManagement") Then
		ItemForDelete = Items.OptionForRegisteringServiceReceiptDocuments.ChoiceList.FindByValue(
			Enums.OptionsForRegisteringServiceDocuments.ReceiptOfServicesIsReversed);
			
		If Not ItemForDelete = Undefined Then
			Items.OptionForRegisteringServiceReceiptDocuments.ChoiceList.Delete(ItemForDelete);
		EndIf;
	EndIf;
	
	Items.CommentPage.Picture = CommonClientServer.CommentPicture(Object.Comment);
	
	// Handler of the "Properties" subsystem
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	PropertyManager.OnCreateAtServer(ThisForm, AdditionalParameters);
	
	// Handler of the subsystem "Versioning of objects"
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	// Subsystem prohibiting editing of key details of objects	
	ObjectAttributesLock.LockAttributes(ThisForm);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	
	GoodsDelivery.WhenReadingCreatingOrdersOnServer(Items, Object);
	
	CounterpartyContractsLocalization.WhenCreatingElementFormOnServer(ThisForm, Cancel, StandardProcessing);
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	ManagingDiscountItems();
	ElementManagementIsVariantOfContractCourse();
	
	LocalizationRFService = GetFunctionalOption("LocalizationRFService");
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	SetVisibilityOfPaymentInCurrency();
	SetTextOfHintOrderOfCreditingDocuments();
	
	Items.GroupContractAmount.Visible = Not (Object.ContractType = Enums.ContractTypes.SalesViaCommissionAgent
		Or Object.ConsignmentSales25);
		
	// StandardSubsystems.FilesOperations
	SetUpWorkListOfFiles();
	// End StandardSubsystems.FilesOperations
	
	// StandardSubsystems.SourceDocumentsOriginalsRecording
	SourceDocumentsOriginalsRecording.OnCreateAtServerDocumentForm(ThisObject);
	// End StandardSubsystems.SourceDocumentsOriginalsRecording 
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
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
	
	
	CounterpartyContractsClientLocalization.OnOpen(Cancel, ThisForm);

	// StandardSubsystems.FilesOperations
	If YouHaveRightToAddFile Then
		ScanCommandAvailable = FilesOperationsInternalClient.ScanAvailable();
		Items.AddFileFromScanner.Visible = ScanCommandAvailable;
		Items.ListContextMenuAddFileFromScanner.Visible = ScanCommandAvailable;
	EndIf;
	
	#If Not MobileClient Then
	AddPreviewFieldForPDFDocument();
	#EndIf
	
	SetFileCommandsAvailability();
	// End StandardSubsystems.FilesOperations
	
	SetHintForSeparatePurchasingOfWorksAndServices();
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	OnReadCreateAtServer();
	
	ARAPAccountingFormWork.FormWhenReadingOnServer(ThisForm);
	
	PropertyManager.OnReadAtServer(ThisForm, CurrentObject);
	
	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);
	
	GoodsDelivery.WhenReadingCreatingOrdersOnServer(Items, Object);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands  
	

EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array();
	
	If FixedContractAmount And Object.Sum = 0 Then
		
		ErrorText = NStr("vi = 'Chưa điền số tiền hợp đồng.';
						|ru = 'Не заполнена сумма договора.';
						|en = 'Contract amount is required'; fa = 'Contract amount is required';
						|it = 'L''importo dell''accordo non è compilato.';
						|pl = 'Nie wypełniono kwoty umowy.';
						|tr = 'Sözleşme tutarı doldurulmadı.'");
		Common.MessageToUser(
			ErrorText,
			Object.Ref,
			"Object.Sum",,
			Cancel);
	EndIf;
	
	If ApplyInstallmentDiscountRate Then
		
		If Object.DiscountRate = 0 Then
		
			ErrorText = NStr("vi = 'Chưa điền tỷ lệ tính chiết khấu.';
							|ru = 'Не заполнена ставка дисконтирования.';
							|en = 'The discounting rate is not filled in.'; fa = 'The discounting rate is not filled in.';
							|it = 'Aliquota di sconto non compilata.';
							|pl = 'Nie wypełniono stawki dyskontowania.';
							|tr = 'İskonto oranı girilmemiş.'");
			Common.MessageToUser(
				ErrorText,
				Object.Ref,
				"Object.DiscountRate",,
				Cancel);
		EndIf;
				
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
	
	UsePurchaseDesign = UsePurchaseDesign();
	
	AcceptanceOptionIsRequiredForFillingIn = (UseWarehouseManagemantSystemForGoodsReceipt
												Or UseGoodsInTransitFromVendors
												Or UseUninvoicedDeliveries)
												And UsePurchaseDesign;
	
	If Not AcceptanceOptionIsRequiredForFillingIn Then
		
		NotCheckedAttributeArray.Add("ExecutionOfAnOrder");
		NotCheckedAttributeArray.Add("GoodsReceipt");
		
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisForm, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
	CounterpartyContractsLocalization.FillCheckProcessingAtServer(Cancel, CheckedAttributes, ThisForm);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	CounterpartyContractsLocalization.BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters, ThisForm);
	ARAPAccountingServer.BeforeWriteAtServer(ThisForm, CurrentObject);
	
	// Handler of the "Properties" subsystem
	PropertyManager.BeforeWriteAtServer(ThisForm, CurrentObject);
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(
		ThisObject,
		CurrentObject,
		WriteParameters);
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
	
	Items.CommentPage.Picture = CommonClientServer.CommentPicture(Object.Comment);
	
	SetAvailabilityOfItemsByStatusServer();
	
	RefreshFormTitle();
	ARAPAccountingFormWork.FormAfterRecordingOnServer(ThisForm, CurrentObject.AdditionalProperties);
	SetNumberOfBranches(Items.DecorationBranches, Object.BranchOffices_.Count());
	
	// Subsystem prohibiting editing of key details of objects	
	ObjectAttributesLock.LockAttributes(ThisForm);

	FormEvents.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
	CounterpartyContractsLocalization.AfterWriteAtServer(CurrentObject, WriteParameters, ThisForm); 
	

	// StandardSubsystems.FilesOperations
	AdjustVisibilityOfCommandsToCreateListOfFiles();
	// End StandardSubsystems.FilesOperations
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Subsystem "Properties"
	If PropertyManagerClient.ProcessNotifications(ThisForm, EventName, Parameter) Then
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
	
	If EventName = "Write_ContractSchedule" Then
		If Object.Ref = Parameter.Contract Then
			
			Object.ContractSchedule = Source;
			Object.Sum = Parameter.ContractAmount;
			
			ChangingExecutionScheduleOnServer();
		EndIf;
	EndIf;
	
	If ARAPAccountingClient.NeedAlertProcessingCall(ThisForm, EventName, Parameter) Then
		ChangedPaymentServer(EventName, Parameter);
	EndIf;
	
	CounterpartyContractsClientLocalization.NotificationProcessing(EventName, Parameter, Source, ThisForm);
	
	
	// StandardSubsystems.FilesOperations
	WorkingWithFilesHandlingAlerts(EventName, Parameter, Source);
	// End StandardSubsystems.FilesOperations

	// StandardSubsystems.SourceDocumentsOriginalsRecording
	SourceDocumentsOriginalsRecordingClient.NotificationHandlerDocumentForm(EventName, ThisObject);
	// End StandardSubsystems.SourceDocumentsOriginalsRecording

EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	RecordMade = True;
	ARAPAccountingClient.FormAfterRecording(ThisForm);
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
		
EndProcedure

&AtClient
Procedure OnClose(Exit)
	If Not Exit And ValueIsFilled(Object.Ref) Then
		If VerificationWhenCreatingContract Then
			AdditionalParameters = CallbackDescriptionOnClose.AdditionalParameters;
			AdditionalParameters.Insert("Contract", Object.Ref)
		EndIf;
		If NotifyAboutCreationOfCalculationObject Then
			ARAPAccountingClient.FormWhenClosing(ThisObject);
		EndIf;
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

#Region UniversalEventHandlers

&AtClient
Procedure Attachable_OnChangeAttribute(Item)
	CounterpartyContractsClientLocalization.OnChangeAttribute(
		Item,
		ThisForm);
EndProcedure

&AtClient
Procedure Attachable_ProcessingTheFormSNavigationLink(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	CounterpartyContractsClientLocalization.ProcessingTheFormSNavigationLink(Item,
		FormattedStringURL,
		StandardProcessing,
		ThisForm);
	
EndProcedure

&AtClient
Procedure AtEndOfChangingLocalizationDetails(TagName, AdditionalParameters) Export
	
	If AdditionalParameters.ServerCallRequired_ Then
		AtEndOfChangingLocalizationDetailsOnServer(TagName, AdditionalParameters.ProcessingParameters);
	EndIf;

EndProcedure

&AtServer
Procedure AtEndOfChangingLocalizationDetailsOnServer(TagName, ProcessingParameters)
	
	CounterpartyContractsLocalization.AtEndOfChangeOfProps(TagName, ThisForm, ProcessingParameters);
	
EndProcedure

#EndRegion

&AtClient
Procedure StatusOnChange(Item)
	
	If Object.Approved And 
		Object.Status <> PredefinedValue("Enum.CounterpartyContractStatuses.Valid")
		And Object.Status <> PredefinedValue("Enum.CounterpartyContractStatuses.Closed") Then
		
		Object.Approved = False;
		
	EndIf;
	
	SetAvailabilityOfItemsByStatusServer();
	
EndProcedure

&AtClient
Procedure ContractTypeStartChoice(Item, ChoiceData, StandardProcessing)
	TypesArray = New Array;


	AvailableTypesOfContracts = Undefined;
	If TypesArray.Find(Object.ContractType) <> Undefined Then
		AvailableTypesOfContracts = AvailableTypesOfContracts(Object.ContractType, StandardProcessing)
	EndIf;
	
	If AvailableTypesOfContracts <> Undefined Then
		ChoiceData = AvailableTypesOfContracts;
	EndIf;
	Return;
	
EndProcedure

&AtClient
Procedure ContractTypeOnChange(Item)
	
	// To fill in the order of calculations based on the statistics of the purpose of the Contract, it is necessary to clear it
	Object.ARAPObjectSettings = Undefined;
	ContractTypeOnChangeServer();
	
EndProcedure

&AtClient
Procedure PartnerOnChange(Item)
	
	PartnerWhenChangesAreMadeOnServer();
	
EndProcedure

&AtServer
Procedure PartnerWhenChangesAreMadeOnServer()
	
	InitialContractWithSelfEmployed = Object.ContractWithSelfEmployedPerson;
	
	If Not Object.ContractType = Enums.ContractTypes.SalesViaCommissionAgent Then
	
		PartnerOnChangeServer(Object.Partner, 
									Object.Counterparty, 
									Object.ForeignCurrencyTransaction, 
									Object.CounterpartyBankAccount, 
									Object.ContactPerson, 
									CounterpartyLegEntInd,
									Object.Organization);
	
	Else
	
		CounterpartyBankAccount = Undefined;
		ContactPerson = Undefined;
		CounterpartyLegEntIndClient = Undefined;
		
		PartnerOnChangeServer(Object.Partner, 
								Object.Counterparty, 
								False, 
								CounterpartyBankAccount, 
								ContactPerson, 
								CounterpartyLegEntIndClient,
								Object.Organization);
	
		If Object.ConsignmentSales25 Then
			SetParametersForSelectingTypeOfPricesOnServer();
		EndIf;
	
	EndIf;
	
	ObjectsFillingByStatistics.FillInSubordinateDetailsOfObject(Object, "Counterparty");
	
	AtEndOfChangingLocalizationDetailsOnServer("Counterparty", Undefined);
	
	If InitialContractWithSelfEmployed <> Object.ContractWithSelfEmployedPerson Then
		SetPropertiesOfElementsOfTaxationAndSeparateVATAccounting();
	EndIf;
	
EndProcedure

&AtClient
Procedure PartnerChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	ClearMessages();
	StandardProcessing = CheckPartnerFlagsClientVendor(ValueSelected, Object.BusinessOperation, Not ValueIsFilled(Object.Ref));

EndProcedure

&AtClient
Procedure ContactPersonOnChange(Item)
	
	If Object.ContactPerson.IsEmpty() Then
		Return;
	EndIf;
	
	ContactPersonOnChangeServer(Object.Partner, 
										Object.Counterparty, 
										Object.ForeignCurrencyTransaction, 
										Object.CounterpartyBankAccount, 
										Object.ContactPerson, 
										CounterpartyLegEntInd,
										Object.Organization);
	
EndProcedure

&AtClient
Procedure CounterpartyOnChange(Item)
	Attachable_OnChangeAttribute(Item);
	CounterpartyWhenChangesAreMadeOnServer();
EndProcedure

&AtServer
Procedure CounterpartyWhenChangesAreMadeOnServer()
	
	CounterpartyOnChangeServer(Object.Counterparty, Object.ForeignCurrencyTransaction, Object.CounterpartyBankAccount, CounterpartyLegEntInd, Object.Organization);
	
	ObjectsFillingByStatistics.FillInSubordinateDetailsOfObject(Object, "Counterparty");
	
	GeneralTaxationAndTypeOfActivity();
	
	AtEndOfChangingLocalizationDetailsOnServer("Counterparty", Undefined);
	
EndProcedure

&AtClient
Procedure ValidityEndDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	ValidityEndDateOnChangeServer();
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	ClearMessages();
	OrganizationOnChangeServer();
	
EndProcedure

&AtClient
Procedure ARAPCurrencyOnChange(Item)
	
	ClearMessages();
	ARAPCurrencyOnChangeServer();
	
EndProcedure

&AtClient
Procedure DescriptionOnChange(Item)
	Items.NameForPrinting.ChoiceList.Clear();
	Items.NameForPrinting.ChoiceList.Add(Object.Description);
EndProcedure

&AtClient
Procedure DebtClassificationOnChange(Item)
	
	EstablishDebtClassification(DebtClassification);
	
EndProcedure

&AtClient
Procedure ARAPObjectSettingsOnChange(Item)
	
	ARAPObjectSettingsOnChangeServer();
	
EndProcedure

&AtClient
Procedure FixedContractAmountOnChange(Item)
	
	RegularPaymentsOption = PredefinedValue("Enum.OptionsForDeterminingExecutionScheduleInContract.RegularPayments");
	OptionOrdersInvoices = PredefinedValue("Enum.OptionsForDeterminingExecutionScheduleInContract.SalesOrderCustomerInvoices");
	
	If Not FixedContractAmount
		And Not Object.OptionOfDeterminingExecutionScheduleInContract = RegularPaymentsOption Then
		Object.ExecutionScheduleIsSpecified = False;
		Object.OptionOfDeterminingExecutionScheduleInContract = OptionOrdersInvoices;
		Object.Sum = 0;
		SumOnChangeServer();
	EndIf;
	
	ItemManagementExecutionSchedule();
	
EndProcedure

&AtClient
Procedure SumOnChange(Item)
	SumOnChangeServer();
EndProcedure

&AtClient
Procedure ApplyInstallmentDiscountRateOnChange(Item)
	
	If Not ApplyInstallmentDiscountRate Then
		Object.DiscountRate = 0;
		Object.ApplicationDiscountingPeriod = 0;
	Else
		SetValuesForDiscountingDetails();
		If Object.DiscountRate = 0 And Not ApplyInstallmentDiscountRate Then
			// If there are no default values, then the bid value is 0
			// Set the forced flag
			ApplyInstallmentDiscountRate = True;
		EndIf;
	EndIf;
	
	ManagingDiscountItems(True);
	
EndProcedure

&AtClient
Procedure ContractRateOptionOnChange(Item)
	
	ClearMessages();
	VariantOfContractCourseWhenChangedOnServer();
	
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
Procedure LabelExecutionScheduleClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	If Not ValueIsFilled(Object.Ref) Or Modified Then
		ClearMessages();
		CommonClient.MessageToUser(
			NStr("vi = 'Vẫn chưa ghi lại hợp đồng. Chỉ có thể chuyển sang soạn lịch biểu sau khi ghi lại hợp đồng và thiết lập trạng thái ""Có hiệu lực"".';
				|ru = 'Договор еще не записан. Переход к редактированию графика возможен только после записи договора и установки статуса ""Действует"".';
				|en = 'The contract is not saved yet. You can edit the schedule only after saving the contract and setting status ""Valid"".'; fa = 'The contract is not saved yet. You can edit the schedule only after saving the contract and setting status ""Valid"".';
				|it = 'L''accordo non è ancora stato scritto. Il passaggio alla redazione del grafico è possibile solamente dopo la scrittura dell''accordo e dopo aver impostato lo stato ""Attivo"".';
				|pl = 'Umowa nie została jeszcze zapisana. Przejście do edycji harmonogramu jest możliwe tylko po zapisaniu umowy i ustawieniu statusu ""Aktualna"".';
				|tr = 'Sözleşme henüz kaydedilmemiştir. Program yalnızca sözleşme kaydedildikten ve ""Aktif"" durumu ayarlandıktan sonra düzenlenebilir.'"));
		Return;
	ElsIf Not ValueIsFilled(Object.Date)
		And Not ValueIsFilled(Object.ContractSchedule) Then
		ClearMessages();
		CommonClient.MessageToUser(
			NStr("vi = 'Để nhập lịch biểu, hãy chỉ ra ngày hợp đồng.';
				|ru = 'Для ввода графика укажите дату договора.';
				|en = 'To enter the schedule, specify the contract date.'; fa = 'To enter the schedule, specify the contract date.';
				|it = 'Per inserire il grafico, indicare la data dell''accordo.';
				|pl = 'W celu wprowadzenia harmonogramu podaj datę umowy.';
				|tr = 'Bir program takvimi girmek için sözleşme tarihini girin.'"));
		Return;
	EndIf;
	
	StructureFilter = New Structure;
	StructureFilter.Insert("Contract", Object.Ref);
	
	ParametersStructure1 = New Structure("Basis", StructureFilter);
	ParametersStructure1.Insert("Sum", Object.Sum);
	ParametersStructure1.Insert("Key", Object.ContractSchedule);
	
	OpenForm("Document.ContractSchedule.ObjectForm", ParametersStructure1, ThisForm);
	
EndProcedure

&AtClient
Procedure CalculationsClick(Item, StandardProcessing)
	
	ARAPAccountingClient.CalculationsClick(ThisForm, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ProcedureOfDocumentOffsetOnChange(Item)
	SetTextOfHintOrderOfCreditingDocuments();
EndProcedure

&AtClient
Procedure TextAllowedCreditBalanceClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	DataOnSaleAmount = New Structure("AmountARAP, Organization", Object.Sum, Object.Organization);
	SalesClient.OpenShipmentBanDecryptionReport(Object.Ref, DataOnSaleAmount, Object.Ref, NewOnlineARAPAccounting);
	
EndProcedure

&AtClient
Procedure TaxRegimeInCaseOfChange(Item)
	
	TaxRegimeInCaseOfChangeServer();
	
EndProcedure

&AtClient
Procedure SeparateVATAccountingModeOnChange(Item)
	
	Object.PurchaseForActivityIsDeterminedInDocument = ?(SeparateVATAccountingMode = 1, True, False);
	GeneralTaxationAndTypeOfActivity();
	SetPropertiesOfElementsOfTaxationAndSeparateVATAccounting();
	
EndProcedure

&AtClient
Procedure VATTaxationOnChange(Item)
	
	VATTaxationOnChangeServer();
	
EndProcedure

&AtClient
Procedure LineOfBusinessOnChange(Item)
	
	LineOfBusinessOnChangeServer();
	
EndProcedure

&AtClient
Procedure UsePaperworkForSeparatePurchasesOfGoodsOnChange(Item)
	
	If UsePaperworkForSeparatePurchasesOfGoods Then
		If UseGoodsInTransitFromVendors Then
			Object.PurchaseRegistrationOption = PredefinedValue("Enum.PurchaseRegistrationOptions.GoodsInTransit");
		ElsIf UseUninvoicedDeliveries Then	
			Object.PurchaseRegistrationOption = PredefinedValue("Enum.PurchaseRegistrationOptions.UninvoicedDeliveriesOfGoodsAndServices");
		EndIf;
	Else
		Object.PurchaseRegistrationOption = PredefinedValue("Enum.PurchaseRegistrationOptions.NotSeparate");
	EndIf;
	
	UsePaperworkForSeparatePurchasesOfGoodsOnChangeServer();
	
EndProcedure

&AtClient
Procedure PurchaseRegistrationOptionOnChange(Item)
	
	PurchaseRegistrationOptionOnChangeServer();
	
EndProcedure

&AtClient
Procedure ExecutionOfAnOrderOnChange(Item)
	
	Modified = True;
	WhenChangingAcceptanceSettingsServer();
	
EndProcedure

&AtClient
Procedure GoodsReceiptOnChange(Item)
	
	Modified = True;
	WhenChangingAcceptanceSettingsServer();
	
EndProcedure

&AtClient
Procedure UsePaperworkForSeparateProcurementOfServicesOnChange(Item)
	
	If UsePaperworkForSeparateProcurementOfServices Then
		Object.OptionForRegisteringServiceReceiptDocuments = PredefinedValue("Enum.OptionsForRegisteringServiceDocuments.ReceiptOfServicesIsInvoiced");
	Else
		Object.OptionForRegisteringServiceReceiptDocuments = PredefinedValue("Enum.OptionsForRegisteringServiceDocuments.ReceiptOfServicesNotUsed");
	EndIf;
	
	UsePaperworkForSeparateProcurementOfServicesOnChangeServer();
	
	If Object.MonthlyReceiptOfServices And Not Object.MonthlyReceiptOfServices = Object.OptionForRegisteringServiceReceiptDocuments = 
		PredefinedValue("Enum.OptionsForRegisteringServiceDocuments.ReceiptOfServicesIsReversed") Then
		Object.MonthlyReceiptOfServices = False;
	EndIf;
	
	SetHintForSeparatePurchasingOfWorksAndServices();
	
EndProcedure

&AtClient
Procedure OptionForRegisteringServiceReceiptDocumentsOnChange(Item)
	
	SetHintForSeparatePurchasingOfWorksAndServices();
	OptionForRegisteringServiceReceiptDocumentsOnChangeServer();
	
	If Object.MonthlyReceiptOfServices And Not Object.OptionForRegisteringServiceReceiptDocuments = 
		PredefinedValue("Enum.OptionsForRegisteringServiceDocuments.ReceiptOfServicesIsReversed") Then
		Object.MonthlyReceiptOfServices = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure RegistrationOfReceiptOfServicesOnChange(Item)
	
	Modified = True;
	OnChangingServiceAcceptanceSettingsServer();	
	
EndProcedure

&AtClient
Procedure AcceptanceOfServicesOnChange(Item)
	
	Modified = True;
	OnChangingServiceAcceptanceSettingsServer();	
	
EndProcedure

&AtClient
Procedure CommissionAgentPartnerOnChange(Item)
	
	Attachable_OnChangeAttribute(Item);
	CommissionAgentPartnerWhenChangesAreMadeOnServer();
	
EndProcedure

&AtServer
Procedure CommissionAgentPartnerWhenChangesAreMadeOnServer()
	
	CounterpartyBankAccount = Undefined;
	ContactPerson = Undefined;
	CounterpartyLegEntIndClient = Undefined;
	
	PartnerOnChangeServer(Object.CommissionAgentPartner, 
							Object.CounterpartyCommissionAgent, 
							False, 
							CounterpartyBankAccount, 
							ContactPerson, 
							CounterpartyLegEntIndClient,
							Object.Organization);
	
	SetDefaultContractWithCommissionAgent();
	
EndProcedure

&AtClient
Procedure LandlordPartnerOnChange(Item)
	
	Attachable_OnChangeAttribute(Item);
	LandlordPartnerOnChangeServer(LandlordPartner, LessorCounterparty);
	
EndProcedure

&AtClient
Procedure CounterpartyCommissionAgentOnChange(Item)
	
	Attachable_OnChangeAttribute(Item);
	SetDefaultContractWithCommissionAgent();
	
EndProcedure

&AtClient
Procedure ContractWithCommissionAgentOnChange(Item)
	Attachable_OnChangeAttribute(Item);
	AgreementWithCommissionAgentInCaseOfChangesOnServer();
EndProcedure

&AtClient
Procedure ContractWithCommissionAgentCreating(Item, StandardProcessing)
	
	ClearMessages();
	
	If Not ValueIsFilled(Object.Ref) Then
		
		CommonClient.MessageToUser(
			NStr("vi = 'Vẫn chưa ghi lại hợp đồng. Trước khi tạo hợp đồng với người nhận ký gửi, cần ghi lại hợp đồng này với khách hàng.';
				|ru = 'Договор еще не записан. Перед созданием договора с комиссионером необходимо записать данный договор с клиентом.';
				|en = 'The contract is not saved yet. Before creating a contract with a consignee, save this contract with a customer.'; fa = 'The contract is not saved yet. Before creating a contract with a consignee, save this contract with a customer.';
				|it = 'Accordo ancora non registrato. Prima della creazione dell''accordo con il commissionario è necessario registrare questo accordo con il cliente.';
				|pl = 'Kontrakt nie jest jeszcze zapisany. Przed utworzeniem kontraktu z komisantem należy zapisać ten kontrakt z nabywcą.';
				|tr = 'Sözleşme henüz yazılı hale getirilmemiştir. Komisyoncu ile bir anlaşma yapmadan önce, bu anlaşma müşteri ile yazılı hale getirilmelidir.'"));
		StandardProcessing = False;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure AgreementWithCommissionAgentInCaseOfChangesOnServer()
	
	If ValueIsFilled(Object.ContractWithCommissionAgent) Then
		ContractWithCommissionAgent = Common.ObjectAttributesValues(Object.ContractWithCommissionAgent, 
			"ARAPObjectSettings, ConductARAPAccountingThroughEndCustomers, ARAPCurrency, GroupOfFinancialARAPAccountingWithEndCustomer, FinancialAccountingGroup, VATRate");
		Object.ARAPObjectSettings = ContractWithCommissionAgent.ARAPObjectSettings;
		
		If ContractWithCommissionAgent.ConductARAPAccountingThroughEndCustomers Then
			FinancialAccountingGroup = ContractWithCommissionAgent.GroupOfFinancialARAPAccountingWithEndCustomer;
		Else
			FinancialAccountingGroup = ContractWithCommissionAgent.FinancialAccountingGroup;
		EndIf;
		ForeignCurrencyTransaction = ARAPAccountingServer.GetPaidInDefaultCurrency(Object.ARAPCurrency, Object.Organization);
		GFInCurrency = Common.ObjectAttributeValue(FinancialAccountingGroup, "ARAPInCurrency");
		If Object.ARAPCurrency = ContractWithCommissionAgent.ARAPCurrency 
			Or ForeignCurrencyTransaction And ValueIsFilled(GFInCurrency) And GFInCurrency Then
			Object.FinancialAccountingGroup = FinancialAccountingGroup;
		Else
			Object.FinancialAccountingGroup = Catalogs.FinancialAccountingGroupsOfARAP.EmptyRef();
 		EndIf;
		
		If Not ValueIsFilled(Object.ARAPCurrency) Then
			Object.ARAPCurrency = ContractWithCommissionAgent.ARAPCurrency;
		EndIf;
		Object.VATRate = ContractWithCommissionAgent.VATRate;
		Object.ConductARAPAccountingThroughEndCustomers = ContractWithCommissionAgent.ConductARAPAccountingThroughEndCustomers;
	Else
		Object.ConductARAPAccountingThroughEndCustomers = False;
	EndIf;

	ElementManagementIsVariantOfContractCourse();

	ARAPAccountingFormWork.WhenChangingParametersOfMechanism(ThisForm);
	
EndProcedure

#Region Delivery

&AtClient
Procedure DeliveryMethodOnChange(Item)
	
	FillInAndSetDeliveryAttributesServer(Item.Name);
	
EndProcedure

&AtClient
Procedure MethodPlaceOfDeliveryCarrierIfChanged(Item)
	
	FillInAndSetDeliveryAttributesServer(Item.Name);
	
EndProcedure

&AtClient
Procedure DeliveryAddressOnChange(Item)
	
	NamesOfDetailsOfDeliveryAddresses = GoodsDeliveryClientServer.NamesOfDetailsOfDeliveryAddresses(
																		GetNameOfDeliveryAddressDetails(Item));
	
	GoodsDeliveryClient.WhenChangingAddressPresentation(
		Item,
		Object[NamesOfDetailsOfDeliveryAddresses.NameOfDetailsOfDeliveryAddress],
		Object[NamesOfDetailsOfDeliveryAddresses.AttributeNameOfDeliveryAddressFieldValues]);

EndProcedure

&AtClient
Procedure DeliveryAddressStartChoice(Item, ChoiceData, StandardProcessing)
	
	NamesOfDetailsOfDeliveryAddresses = GoodsDeliveryClientServer.NamesOfDetailsOfDeliveryAddresses(
																		GetNameOfDeliveryAddressDetails(Item));
	
	GoodsDeliveryClient.OpenAddressSelectionFormAndProcessResult(
		Item,
		Object,
		NamesOfDetailsOfDeliveryAddresses,
		StandardProcessing);
	
EndProcedure

&AtClientAtServerNoContext
Function GetNameOfDeliveryAddressDetails(Item)
	
	If StrFind(Item.Name, "DeliveryAddressOfCarrier") > 0 Then
		NameOfAddressDetails = "DeliveryAddressOfCarrier";
	Else
		NameOfAddressDetails = "DeliveryAddress";
	EndIf;
	
	Return NameOfAddressDetails;
	
EndFunction

&AtClient
Procedure DeliveryAddressClearing(Item, StandardProcessing)
	
	DeliveryAddressOnChange(Item);
	
EndProcedure

&AtClient
Procedure DeliveryAddressChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	DeliveryAddressOnChange(Item);
	
	GoodsDeliveryClient.DeliveryAddressChoiceProcessing(Items, Object, Item.Name, ValueSelected);
	
	Modified = True;
	
EndProcedure

&AtClient
Procedure SupplementDeliveryInformationWithContacts(Command)
	SupplementDeliveryInformationWithContactsServer();
EndProcedure

#EndRegion

&AtClient
Procedure ForeignCurrencyTransactionOnChange(Item)
	
	ForeignCurrencyTransactionOnChangeServer();
	
EndProcedure

&AtClient
Procedure DepartmentOnChange(Item)
	
	ClearMessages();
	OrganizationOnChangeServer();
	
EndProcedure

&AtClient
Procedure CentralizedContractOnChange(Item)
	
	Items.DecorationBranches.Enabled = Object.CentralizedContract;
	Items.TransferAndOffsetOfPaymentsBetweenBranchOfficesIsAllowed.Visible = Object.CentralizedContract;
	
EndProcedure

&AtClient
Procedure DecorationBranchesClick(Item)
	
	FormParameters = New Structure("BranchOffices_", Object.BranchOffices_);
	FormParameters.Insert("Organization", Object.Organization);
	HandlingSavingListOfBranches = New CallbackDescription("FinishEditingListOfBranches", ThisObject);
	OpenForm("Catalog.CounterpartyContracts.Form.BranchOffices", FormParameters, ThisObject,
		UUID,,, HandlingSavingListOfBranches, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure ConductARAPAccountingThroughEndCustomersOnChange(Item)
	
	MakePaymentsThroughEndCustomersOnChangesAtServer();
	
EndProcedure

&AtClient
Procedure SplitReportToPurchasingCommitteeOnChange(Item)
	Object.SplitReportByDocuments = ToSplitReport;
EndProcedure

&AtClient
Procedure DecorationEDOStateClick(Item)
	
	
EndProcedure

#Region FilesOperations

&AtClient
Procedure DecorationSyncDateURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	If FormattedStringURL = "OpenJournal" Then
		
		StandardProcessing = False;
		FilterParameters = EventLogFilterData(Account);
		EventLogClient.OpenEventLog(FilterParameters, ThisObject);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_OriginalStateDecorationClick()

	// StandardSubsystems.SourceDocumentsOriginalsRecording
	SourceDocumentsOriginalsRecordingClient.OpenStateSelectionMenu(ThisObject, Items.OriginalStateDecoration);
	//End StandardSubsystems.SourceDocumentsOriginalsRecording

EndProcedure

#EndRegion

&AtClient
Procedure ContractWithSelfEmployedPersonOnChange(Item)

	Return;

EndProcedure

&AtClient
Procedure ForeignCounterpartyIncomeKindOnChange(Item)
	
	
EndProcedure

&AtClient
Procedure ForeignExchangeControlUniqueNumberOnChange(Item)


EndProcedure

&AtClient
Procedure OptionOfDeterminingExecutionScheduleInContractOnChange(Item)
	
	OptionContract = PredefinedValue("Enum.OptionsForDeterminingExecutionScheduleInContract.Contract");
	RegularPaymentsOption = PredefinedValue("Enum.OptionsForDeterminingExecutionScheduleInContract.RegularPayments");
	
	Object.ExecutionScheduleIsSpecified = (Object.OptionOfDeterminingExecutionScheduleInContract = OptionContract
		Or Object.OptionOfDeterminingExecutionScheduleInContract = RegularPaymentsOption);
	
	ItemManagementExecutionSchedule();
	SetVisibilityOfRegularPayments();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

// StandardSubsystems.FilesOperations
#Region FilesOperations

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
		If Items.List.ChoiceMode Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	
	CurrentData = CurrentFileListData();
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If CurrentData.IsFolder Then
		ShowValue(, RowSelected);
		Return;
	EndIf;
	
	If Field.Name = "EDSentReceived" And Not CurrentData.FileBeingEdited  
		And (CurrentData.Extension = "pdf" Or CurrentData.Extension = "xml") Then
		Return;
	EndIf;
	
	HowToOpen = FilesOperationsInternalClient.PersonalFilesOperationsSettings().ActionOnDoubleClick;
	
	If HowToOpen = "OpenCard" Then
		ShowValue(, RowSelected);
		Return;
	EndIf;
	
	FileGettingParameters = FilesOperationsClient.ParametersForAsynchronousFileReceipt("SelectModeAndEditFile");
	FileGettingParameters.AttachedFile				= RowSelected;
	FileGettingParameters.OwnerForm					= ThisObject;
	FileGettingParameters.CheckForFileInArchive	= False;

	FileGettingParameters.MethodParameters.FilePreviousURL = FilePreviousURL;
	
	ActionParameters = FileGettingParameters.ActionParameters;
	ActionParameters.OwnerForm						= ThisObject;
	ActionParameters.CommandEditAvailability	= Items.FormEdit.Enabled;

	FilesOperationsClient.OpenFile(FileGettingParameters);
	
EndProcedure

&AtClient
Procedure ListOnActivateRow(Item)
	
	UpdateFileCommandAvailability();
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.StartCommandUpdate(ThisObject);
	EndIf;
	// End StandardSubsystems.AttachableCommands

EndProcedure

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	Cancel = True;
	
	If Copy Then
		
		If Not FileCommandsAvailable() Then
			Return;
		EndIf;
		
		CurrentData = CurrentFileListData();
		
		FormParameters = New Structure;
		FormParameters = New Structure("CopyingValue", CurrentData);
		
		If CurrentData.IsFolder Then
			OpenForm("DataProcessor.FilesOperations.Form.FilesGroup", FormParameters);
		Else
			FilesOperationsClient.CopyAttachedFile(Object.Ref, CurrentData.Ref, FormParameters);
		EndIf;
		
	Else
		
		AppendFile();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ListBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	OpenFileCard();
	
EndProcedure

&AtClient
Procedure ListDragCheck(Item, DragParameters, StandardProcessing, String, Field)
	
	StandardProcessing = False;
	If FilesBeingEditedInCloudService Then
		DragParameters.Action = DragAction.Cancel;
		DragParameters.Value = Undefined;
	EndIf;
	
EndProcedure

&AtClient
Procedure ListDrag(Item, DragParameters, StandardProcessing, String, Field)
	
	OwnerCatalogFiles = False;
	
	FileNamesArray = New Array;
	If TypeOf(DragParameters.Value) = Type("Array")
		And DragParameters.Value.Count() > 0 Then
		
		FileToDrag = DragParameters.Value[0];
		If TypeOf(FileToDrag) <> Type("File") Then
			
			FilesOwnerMaps = FilesOwnerMaps(Object.Ref, FileToDrag);
			If TypeOf(FileToDrag) = Type("CatalogRef.CounterpartyContractsAttachedFiles")
				And FilesOwnerMaps Then
				Return;
			EndIf;
			
		EndIf;
		
		StandardProcessing = False;
		For Each FileToDrag In DragParameters.Value Do
			
			If TypeOf(FileToDrag) = Type("File")
				And FileToDrag.IsFile() Then
				
				FileNamesArray.Add(FileToDrag.FullName);
				OwnerCatalogFiles = True;
			Else
				FileNamesArray.Add(FileToDrag);
			EndIf;
			
		EndDo;
		
	ElsIf TypeOf(DragParameters.Value) = Type("File")
		And DragParameters.Value.IsFile() Then
		
		StandardProcessing = False;
		FileNamesArray.Add(DragParameters.Value.FullName);
		OwnerCatalogFiles = True;
		
	EndIf;
	
	If FileNamesArray.Count() > 0 Then
		If OwnerCatalogFiles = True Then
			FilesOperationsInternalClient.AddFilesWithDrag(
				Object.Ref, UUID, FileNamesArray);
		Else
			
			Action = ?(DragParameters.Action = DragAction.Copy,
				"Copy", "Move");
			TransferOrCopyAttachedFiles(FileNamesArray, Object.Ref, Action);
			
			NotifyChanged(Object.Ref);
			Notify("Write_File", New Structure("IsNew, FileOwner", True, Object.Ref),
				FileNamesArray);
			
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure ListOnChange(Item)
	
	NotifyChanged(Object.Ref);
	
	EventParameters = New Structure;
	EventParameters.Insert("Event", "FileDataChanged");
	EventParameters.Insert("IsNew", False);
	
	Notify("Write_File", EventParameters, Item.SelectedRows);
	
EndProcedure

#EndRegion  
//End StandardSubsystems.FilesOperations
	
#EndRegion

#Region FormCommandsEventHandlers

#Region UniversalFormCommandHandlers

&AtClient
Procedure Attachable_ExecuteLocalizationCommand(Command)
	
	CounterpartyContractsClientLocalization.ExecuteLocalizationCommand(Command, ThisForm);
	
EndProcedure

&AtClient
Procedure ContinueRunningLocalizationCommand(CommandName, AdditionalParameters) Export
	
	If AdditionalParameters.ServerCallRequired_ Then
		ContinueRunningLocalizationCommandOnServer(CommandName, AdditionalParameters.ProcessingParameters);
	EndIf;
	
EndProcedure

&AtServer
Procedure ContinueRunningLocalizationCommandOnServer(CommandName, ProcessingParameters)
	
	CounterpartyContractsLocalization.ExecuteLocalizationCommand(ThisForm, CommandName, ProcessingParameters);
	
EndProcedure
	
#EndRegion

&AtClient
Procedure SetDateInterval(Command)
	
	TMCommonUseClient.EditPeriod(Object, 
		New Structure("StartDate, EndDate", "ValidityStartDate", "ValidityEndDate"));
	
EndProcedure

&AtClient
Procedure PaymentSettlement(Command)
	
	ARAPAccountingClient.PaymentSettlement(ThisForm);
	
EndProcedure

&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)
	
	EditParameters = TMCommonUseClient.PermissionParametersForEditingItemDetails();
	EditParameters.OnlyVisible = False;
	TMCommonUseClient.AllowObjectAttributeEdit(ThisForm, EditParameters);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
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


// StandardSubsystems.FilesOperations
#Region FilesOperations

///////////////////////////////////////////////////////////////////////////////////
// File Command Handlers

&AtClient
Procedure Add(Command)
	
	AppendFile();
	
EndProcedure

&AtClient
Procedure AddFileByTemplate(Command)
	
	AddingOptions = New Structure;
	AddingOptions.Insert("HandlerResults_1",          Undefined);
	AddingOptions.Insert("FileOwner",                 Object.Ref);
	AddingOptions.Insert("OwnerForm",                 ThisObject);
	AddingOptions.Insert("FilesStorageCatalogName", "CounterpartyContractsAttachedFiles");
	FilesOperationsInternalClient.AddBasedOnTemplate(AddingOptions);
	
EndProcedure

&AtClient
Procedure AddContractTemplateFile(Command)
	
	OpenForm("Catalog.CounterpartyContractsAttachedFiles.Form.ChoiceFormOfContractTemplate",
		New Structure("AccountingObject", Object.Ref), ThisForm);
	
EndProcedure

&AtClient
Procedure AddFileFromScanner(Command)
	
	DCParameterValue = List.Parameters.FindParameterValue(New DataCompositionParameter("FilesOwner"));
	If DCParameterValue = Undefined Then
		FileOwner = Undefined;
	Else
		FileOwner = DCParameterValue.Value;
	EndIf;

	AddingOptions = New Structure;
	AddingOptions.Insert("HandlerResults_1", Undefined);
	AddingOptions.Insert("FileOwner", FileOwner);
	AddingOptions.Insert("OwnerForm", ThisObject);
	AddingOptions.Insert("NotOpenCardAfterCreateFromFile", True);
	AddingOptions.Insert("IsFile", False);
	FilesOperationsInternalClient.AddFromScanner(AddingOptions);
	
EndProcedure

&AtClient
Procedure OpenFileForViewing(Command)
	
	OpenFile();
	
EndProcedure

&AtClient
Procedure OpenFileDirectory(Command)
	
	If Not FileCommandsAvailable() Then
		Return;
	EndIf;
	
	CurrentData = CurrentFileListData();
	
	If CurrentData.Encrypted Then
		// The file may be modified in another session.
		NotifyChanged(CurrentData.Ref);
		Return;
	EndIf;
	CurrentData = CurrentFileListData();
	FileRef = CurrentData.Ref;
	
	FileData = FilesOperationsInternalServerCall.FileDataToOpen(FileRef,
		Undefined, UUID, Undefined, Undefined);
	FilesOperationsClient.OpenFileDirectory(FileData);

	
EndProcedure

&AtClient
Procedure Refresh(Command)
	
	Items.List.Refresh();
	
	AttachIdleHandler("UpdateFileCommandAvailability", 0.1, True);
	
EndProcedure

&AtClient
Procedure UpdateFromFileOnHardDrive(Command)
	
	If Not FileCommandsAvailable() Then
		Return;
	EndIf;
	
	CurrentData = CurrentFileListData();
	
	If CurrentData.Encrypted Or CurrentData.SignedWithDS Or CurrentData.FileBeingEdited Then
		Return;
	EndIf;
		
	If WhetherToSendEDIFile(CurrentData.Ref) Then
		CompletionDetails = New CallbackDescription("UpdateFromFileOnHardDriveCompletion", ThisObject);	
		AskQuestionToUserWhenChangingFile(CompletionDetails); 
	Else
		UpdateFromFileOnHardDriveCompletion(New Structure("Value", DialogReturnCode.Yes));
	EndIf;

EndProcedure

&AtClient
Procedure SaveAs(Command)
	
	If Not FileCommandsAvailable() Then
		Return;
	EndIf;
	
	CurrentData = CurrentFileListData();
	
	If CurrentData.Encrypted
		Or (CurrentData.FileBeingEdited And CurrentData.CurrentUserEditsFile) Then
		Return;
	EndIf;
	
	FileGettingParameters = FilesOperationsClient.ParametersForAsynchronousFileReceipt("SaveAs", "FilesOperationsInternal.FileDataToSaveAsync");
	FileGettingParameters.AttachedFile				= CurrentData.Ref;
	FileGettingParameters.OwnerForm					= ThisObject;
	FileGettingParameters.CheckForFileInArchive	= False;
	
	FileGettingParameters.ActionParameters.UUID = UUID;
	
	FilesOperationsClient.SaveFileAs(FileGettingParameters);
	
EndProcedure

&AtClient
Procedure Copy(Command)
	
	Items.List.CopyRow();
	
EndProcedure

&AtClient
Procedure SetDeletionMark(Command)

	SelectedRows = SelectedLinesOfFileList();

	If SelectedRows.Count() = 0 Or Not StandardSubsystemsClient.IsDynamicListItem(Items.List) Then
		Return;
	EndIf;
	
	CurrentData = CurrentFileListData();
	If SelectedRows.Count() = 1 Then
		QuestionTemplate = ?(CurrentData.DeletionMark,
			NStr("vi = 'Bỏ dấu xóa ""%1""?';
				|ru = 'Снять с ""%1"" пометку на удаление?';
				|en = 'Do you want to remove the deletion mark from ""%1""?'; fa = 'Do you want to remove the deletion mark from ""%1""?';
				|it = 'Rimuovere il contrassegno per cancellazione da ""%1""?';
				|pl = 'Usunąć z ""%1"" zaznaczenie do usunięcia?';
				|tr = '""%1"" için silme işareti kaldırılsın mı?'"),
			NStr("vi = 'Đặt dấu xóa ""%1""?';
				|ru = 'Пометить ""%1"" на удаление?';
				|en = 'Do you want to mark ""%1"" for deletion?'; fa = 'Do you want to mark ""%1"" for deletion?';
				|it = 'Contrassegnare ""%1"" per cancellazione?';
				|pl = 'Zaznaczyć ""%1"" do usunięcia?';
				|tr = '""%1"" silinmek üzere işaretlensin mi?'"));
		QueryText = StringFunctionsClientServer.SubstituteParametersToString(QuestionTemplate, CurrentData.Description);
	Else
		QueryText = ?(CurrentData.DeletionMark,
			NStr("vi = 'Bỏ dấu xóa các tệp được chọn?';
				|ru = 'Снять с выбранных файлов пометку на удаление?';
				|en = 'Do you want to clear the deletion mark from the selected files?'; fa = 'Do you want to clear the deletion mark from the selected files?';
				|it = 'Снять с выбранных файлов пометку на удаление?';
				|pl = 'Do you want to clear the deletion mark from the selected files?';
				|tr = 'Silinmek üzere seçili dosyaların işareti kaldırılsın mı?'"),
			NStr("vi = 'Đặt dấu xóa các tệp được chọn?';
				|ru = 'Пометить выбранные файлы на удаление?';
				|en = 'Do you want to mark the selected files for deletion?'; fa = 'Do you want to mark the selected files for deletion?';
				|it = 'Пометить выбранные файлы на удаление?';
				|pl = 'Do you want to mark the selected files for deletion?';
				|tr = 'Seçilen dosyalar silinmek üzere işaretlensin mi?'"));
	EndIf;
	
	AdditionalParameters = New Structure("Files", SelectedRows);
	Notification = New CallbackDescription("SetDeletionMarkCompletion", ThisObject, AdditionalParameters);
	ShowQueryBox(Notification, QueryText, QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure OpenFileProperties(Command)
	
	OpenFileCard();
	
EndProcedure

&AtClient
Procedure Send(Command)
	
	OnSendFilesViaEmail(SendOptions, Items.List.SelectedRows, Object.Ref, UUID);
	
	FilesOperationsInternalClient.SendFilesViaEmail(
		Items.List.SelectedRows, UUID, SendOptions);
	
EndProcedure

&AtClient
Procedure Print(Command)
	
	SelectedRows = Items.List.SelectedRows;
	If SelectedRows.Count() > 0 Then
		FilesOperationsClient.PrintFiles(SelectedRows, ThisObject.UUID);
	EndIf;
	
EndProcedure

&AtClient
Procedure PrintWithStamp(Command)
	
	CurrentData = CurrentFileListData();
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If CurrentData.Extension = "mxl" 
		Or CurrentData.Extension = "docx" Then
		
		FilesOperationsInternalClient.DoPrintFileWithStamp(CurrentData.Ref, UUID);
		
	EndIf;
EndProcedure

&AtClient
Procedure Preview(Command)
	
	Preview = Not Preview;
	Items.Preview.Check = Preview;
	SetPreviewVisibility(Preview);
	SavePreviewOption(Type("CatalogRef.CounterpartyContractsAttachedFiles"), Preview);
	
	#If WebClient Then
	UpdatePreview1();
	#EndIf
	
EndProcedure

&AtClient
Procedure SyncSettings(Command)
	
	SyncSetup = SynchronizationSettingsParameters(Object.Ref);
	
	If ValueIsFilled(SyncSetup.Account) Then
		ValueType = Type("InformationRegisterRecordKey.FileSynchronizationSettings");
		WriteParameters = New Array(1);
		WriteParameters[0] = SyncSetup;
		
		RecordKey = New(ValueType, WriteParameters);
	
		WriteParameters = New Structure;
		WriteParameters.Insert("Key", RecordKey);
	Else
		WriteParameters = SyncSetup;
	EndIf;
	
	OpenForm("InformationRegister.FileSynchronizationSettings.Form.SimpleRecordFormSettings", WriteParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure CreateFolder(Command)
	
	FormParameters = New Structure;
	
	CurrentData = CurrentFileListData();
	If CurrentData <> Undefined And CurrentData.FileOwner <> Object.Ref Then
		CurrentData = Undefined;
	EndIf;
	
	If CurrentData <> Undefined Then
		FormParameters.Insert("Parent", CurrentData.Ref);
	Else
		FormParameters.Insert("Parent", Object.Ref);
	EndIf;
	
	FormParameters.Insert("FileOwner",  Object.Ref);
	FormParameters.Insert("IsNewGroup", True);
	FormParameters.Insert("FilesStorageCatalogName", "CounterpartyContractsAttachedFiles");
	
	OpenForm("DataProcessor.FilesOperations.Form.FilesGroup", FormParameters);
	
EndProcedure

&AtClient
Procedure ImportFiles(Command)
	#If WebClient Then
		WarningText =  NStr("vi = 'Việc nhập tệp không được hỗ trợ trong web-client.
		                                  |Hãy sử dụng lệnh ""Tạo mới"" trong danh sách tệp.';
		                                  |ru = 'В Веб-клиенте импорт файлов не поддерживается.
		                                  |Используйте команду ""Создать"" в списке файлов.';
		                                  |en = 'The web client does not support file upload.
		                                  |Please use the ""Create"" button in the file list.'; fa = 'The web client does not support file upload.
		                                  |Please use the ""Create"" button in the file list.';
		                                  |it = 'Nel Web-client l''upload dei file non è supportato.
		                                  |Utilizzate il comando ""Creare"" nell''elenco dei file.';
		                                  |pl = 'W kliencie Web import plików nie jest obsługiwany.
		                                  | Użyj polecenia ""Nowy"" na liście plików.';
		                                  |tr = 'Web istemcide dosya içe aktarma desteklenmez. 
		                                  |Dosyalar listesinde Oluştur komutunu kullanın.'");
		ShowMessageBox(, WarningText);
		Return;
	#EndIf
	
	FileNamesArray = FilesOperationsInternalClient.FilesToImport();
	
	If FileNamesArray.Count() = 0 Then
		Return;
	EndIf;
	
	DCParameterValue = List.Parameters.FindParameterValue(New DataCompositionParameter("FilesOwner"));
	If DCParameterValue = Undefined Then
		FileOwner = Undefined;
	Else
		FileOwner = DCParameterValue.Value;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("FolderForAdding", FileOwner);
	FormParameters.Insert("FileNamesArray", FileNamesArray);
	CurrentData = CurrentFileListData();
	FilesGroup = Undefined;
	If CurrentData <> Undefined And CurrentData.IsFolder Then
		FilesGroup = CurrentData.Ref;
	ElsIf CurrentData <> Undefined Then
		FilesGroup = FileGroup_(CurrentData.Ref);
	EndIf;
	FormParameters.Insert("FilesGroup", FilesGroup);
	OpenForm("DataProcessor.FilesOperations.Form.LoadFiles", FormParameters);
EndProcedure

&AtClient
Procedure ImportFolder(Command)
	
	#If WebClient Then
		WarningText = NStr("vi = 'Nhập thư mục không khả dụng trong ứng dụng khách web.
			                             |Sử dụng lệnh ""Tạo mới"" trong danh sách tệp.';
			                             |ru = 'В веб-клиенте импорт папок недоступен.
			                             |Используйте команду ""Создать"" в списке файлов.';
			                             |en = 'The web client does not support folder upload.
			                             |Please use the ""Create"" button in the file list.'; fa = 'The web client does not support folder upload.
			                             |Please use the ""Create"" button in the file list.';
			                             |it = 'Nel web-client l''upload delle cartelle non è disponibile.
			                             |Utilizzate il comando ""Creare"" nell''elenco dei file.';
			                             |pl = 'Importowanie folderów nie jest dostępne w kliencie Web.
			                             | Użyj polecenia ""Nowy"" na liście plików.';
			                             |tr = 'Web istemcide klasörler içe aktarılamaz.
			                             |Dosyalar listesinde Oluştur komutunu kullanın.'");
		ShowMessageBox(, WarningText);
		Return;
	#EndIf
	
	OpenFileDialog = New FileDialog(FileDialogMode.ChooseDirectory);
	OpenFileDialog.FullFileName = "";
	OpenFileDialog.Filter = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Tất cả tệp (%1)|%1';
																							|ru = 'Все файлы (%1)|%1';
																							|en = 'All files (%1)|%1'; fa = 'All files (%1)|%1';
																							|it = 'Все файлы (%1)|%1';
																							|pl = 'All files (%1)|%1';
																							|tr = 'Tüm dosyalar (%1)|%1'"), GetAllFilesMask());
	OpenFileDialog.Multiselect = False;
	OpenFileDialog.Title = NStr("vi = 'Hãy chọn thư mục';
								|ru = 'Выберите каталог';
								|en = 'Select directory'; fa = 'Select directory';
								|it = 'Scegliete la directory';
								|pl = 'Wybierz katalog';
								|tr = 'Dizini seçin'");
	If Not OpenFileDialog.Choose() Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("FolderForAdding", Object.Ref);
	FormParameters.Insert("DirectoryOnHardDrive", OpenFileDialog.Directory);
	FormParameters.Insert("FilesStorageCatalogName", "CounterpartyContractsAttachedFiles");
	CurrentData = CurrentFileListData();
	FilesGroup = Undefined;
	If CurrentData <> Undefined And CurrentData.IsFolder Then
		FilesGroup = CurrentData.Ref;
	ElsIf CurrentData <> Undefined Then
		FilesGroup = FileGroup_(CurrentData.Ref);
	EndIf;
	FormParameters.Insert("FilesGroup", FilesGroup);
	
	OpenForm("DataProcessor.FilesOperations.Form.ImportingFolder", FormParameters);
	
EndProcedure

&AtClient
Procedure SaveFolder(Command)
	
	CurrentData = CurrentFileListData();
	
	If CurrentData = Undefined Or Not CurrentData.IsFolder Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("ExportFolder", CurrentData.Ref);
	FormParameters.Insert("FilesStorageCatalogName",  "CounterpartyContractsAttachedFiles");
	FormParameters.Insert("FileVersionsStorageCatalogName", "");
	OpenForm("DataProcessor.FilesOperations.Form.SavingFolder", FormParameters);
	
EndProcedure

&AtClient
Procedure CompareFiles(Command)
	
	SelectedRowsCount = Items.List.SelectedRows.Count();
	
	If SelectedRowsCount = 2 Then
		
		Ref1 = Items.List.SelectedRows[0];
		Ref2 = Items.List.SelectedRows[1];
		
		CurrentData = CurrentFileListData();
		Extension = Lower(CurrentData.Extension);
		
		FilesOperationsInternalClient.CompareFiles(UUID, Ref1, Ref2, Extension);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure MoveToGroupCommand(Command)
	If Items.List.SelectedRows.Count() > 0 Then
		OpeningParameters = New Structure;
		OpeningParameters.Insert("FilesOwner", Object.Ref);
		OpeningParameters.Insert("FilesToMove", Items.List.SelectedRows);
		OpenForm("DataProcessor.FilesOperations.Form.SelectGroup", OpeningParameters, ThisObject);
	EndIf;
EndProcedure

//////////////////////////////////////////////////////////////////////////////////
// Command handlers to support EP and encryption.

&AtClient
Procedure Sign(Command)
	
	If Not FileCommandsAvailable() Then
		Return;
	EndIf;
	
	CurrentData = CurrentFileListData();
	
	If CurrentData.FileBeingEdited
		Or CurrentData.Encrypted Then
		Return;
	EndIf;

	CallbackDescription = New CallbackDescription("AddSignaturesCompeltion", ThisObject);
	AdditionalParameters = New Structure("ResultProcessing", CallbackDescription);
	FilesOperationsClient.SignFile(CurrentData.Ref, UUID, AdditionalParameters);
	
EndProcedure

&AtClient
Procedure SaveWithDigitalSignature(Command)
	
	If Not FileCommandsAvailable() Then
		Return;
	EndIf;
	
	CurrentData = CurrentFileListData();
	
	If CurrentData.Encrypted Then
		Return;
	EndIf;
	
	FilesOperationsInternalClient.SaveFileWithSignature(
		CurrentData.Ref, UUID);
	
EndProcedure

&AtClient
Procedure AddDSFromFile(Command)
	
	If Not FileCommandsAvailable() Then
		Return;
	EndIf;
	
	CurrentData = CurrentFileListData();
	
	If CurrentData.FileBeingEdited
		Or CurrentData.Encrypted Then
		Return;
	EndIf;
	
	AttachedFile = CurrentData.Ref;
	
	FilesOperationsInternalClient.AddSignatureFromFile(
		AttachedFile,
		UUID,
		New CallbackDescription("AddSignaturesCompeltion", ThisObject));
	
EndProcedure

&AtClient
Procedure Encrypt(Command)
	
	If Not FileCommandsAvailable() Then
		Return;
	EndIf;
	
	CurrentData = CurrentFileListData();
	
	If CurrentData.FileBeingEdited
		Or CurrentData.Encrypted Then
		Return;
	EndIf;
	
	FileData = FilesOperationsInternalServerCall.GetFileDataAndVersionsCount(CurrentData.Ref);
	
	If ValueIsFilled(FileData.BeingEditedBy)
		Or FileData.Encrypted Then
		// The file may be modified in another session.
		NotifyChanged(CurrentData.Ref);
		Return;
	EndIf;
	
	HandlerParameters = New Structure;
	HandlerParameters.Insert("FileData",  FileData);
	HandlerParameters.Insert("ObjectRef", CurrentData.Ref);
	Handler = New CallbackDescription("EncryptAfterEncryptAtClient", ThisObject, HandlerParameters);
	
	FilesOperationsInternalClient.Encrypt(Handler, FileData, UUID);
	
EndProcedure

&AtClient
Procedure EncryptAfterEncryptAtClient(Result, ExecutionParameters) Export
	If Not Result.Success Then
		Return;
	EndIf;
	
	WorkingDirectoryName = FilesOperationsInternalClient.UserWorkingDirectory();
	
	FilesArrayInWorkingDirectoryToDelete = New Array;
	
	EncryptServer(
		Result.DataArrayToStoreInDatabase,
		Result.ThumbprintsArray,
		FilesArrayInWorkingDirectoryToDelete,
		WorkingDirectoryName,
		ExecutionParameters.ObjectRef);
	
	FilesOperationsInternalClient.InformOfEncryption(
		FilesArrayInWorkingDirectoryToDelete,
		ExecutionParameters.FileData.Owner,
		ExecutionParameters.ObjectRef);
	
	SetFileCommandsAvailability();
	
EndProcedure

&AtServer
Procedure EncryptServer(DataArrayToStoreInDatabase, ThumbprintsArray, 
	FilesArrayInWorkingDirectoryToDelete,
	WorkingDirectoryName, ObjectRef)
	
	EncryptionInformationWriteParameters = FilesOperationsInternal.EncryptionInformationWriteParameters();
	EncryptionInformationWriteParameters.WorkingDirectoryName = WorkingDirectoryName;
	EncryptionInformationWriteParameters.DataArrayToStoreInDatabase = DataArrayToStoreInDatabase;
	EncryptionInformationWriteParameters.ThumbprintsArray = ThumbprintsArray;
	EncryptionInformationWriteParameters.FilesArrayInWorkingDirectoryToDelete = FilesArrayInWorkingDirectoryToDelete;
	
	FilesOperationsInternal.WriteEncryptionInformation(
		ObjectRef, EncryptionInformationWriteParameters);
	
EndProcedure

&AtClient
Procedure Decrypt(Command)
	
	If Not FileCommandsAvailable() Then
		Return;
	EndIf;
	
	CurrentData = CurrentFileListData();
	
	If Not CurrentData.Encrypted Then
		Return;
	EndIf;
	
	ObjectRef = CurrentData.Ref;
	FileData = FilesOperationsInternalServerCall.GetFileDataAndVersionsCount(ObjectRef);
	
	HandlerParameters = New Structure;
	HandlerParameters.Insert("FileData", FileData);
	HandlerParameters.Insert("ObjectRef", ObjectRef);
	Handler = New CallbackDescription("DecryptAfterDecryptAtClient", ThisObject, HandlerParameters);
	
	FilesOperationsInternalClient.Decrypt(
		Handler,
		FileData.Ref,
		UUID,
		FileData);
		
EndProcedure

&AtClient
Procedure DecryptAfterDecryptAtClient(Result, ExecutionParameters) Export
	
	If Result = False Or Not Result.Success Then
		Return;
	EndIf;
	
	WorkingDirectoryName = FilesOperationsInternalClient.UserWorkingDirectory();
	
	DecryptServer(
		Result.DataArrayToStoreInDatabase,
		WorkingDirectoryName,
		ExecutionParameters.ObjectRef);
	
	FilesOperationsInternalClient.InformOfDecryption(
		ExecutionParameters.FileData.Owner,
		ExecutionParameters.ObjectRef);
	
	SetFileCommandsAvailability();
	
EndProcedure

&AtServer
Procedure DecryptServer(DataArrayToStoreInDatabase, 
	WorkingDirectoryName, ObjectRef)
	
	EncryptionInformationWriteParameters = FilesOperationsInternal.EncryptionInformationWriteParameters();
	EncryptionInformationWriteParameters.Encrypt = False;
	EncryptionInformationWriteParameters.WorkingDirectoryName = WorkingDirectoryName;
	EncryptionInformationWriteParameters.DataArrayToStoreInDatabase = DataArrayToStoreInDatabase;
	
	FilesOperationsInternal.WriteEncryptionInformation(
		ObjectRef, EncryptionInformationWriteParameters);
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////////
// Command handlers to support file collaboration.

&AtClient
Procedure Edit(Command)
	
	If Not FileCommandsAvailable() Then
		Return;
	EndIf;
	
	CurrentData = CurrentFileListData();
	
	If (CurrentData.FileBeingEdited And Not CurrentData.CurrentUserEditsFile)
		Or CurrentData.Encrypted
		Or CurrentData.SignedWithDS Then
		Return;
	EndIf;

	If WhetherToSendEDIFile(CurrentData.Ref) Then
		CompletionDetails = New CallbackDescription("EditCompletion", ThisObject);		
		AskQuestionToUserWhenChangingFile(CompletionDetails); 
	Else
		EditCompletion(New Structure("Value", DialogReturnCode.Yes));
	EndIf;

EndProcedure

&AtClient
Procedure EndEdit(Command)
	
	FilesArray = New Array;
	For Each ListItem In Items.List.SelectedRows Do
		
		RowData = ListLineData(ListItem);
		If Not RowData.FileBeingEdited
			Or Not RowData.CurrentUserEditsFile Then
			
			Continue;
		EndIf;
		
		FilesArray.Add(RowData.Ref);
		
	EndDo;
	
	If FilesArray.Count() > 1 Then
		FormParameters = New Structure;
		FormParameters.Insert("FilesArray", FilesArray);
		FormParameters.Insert("HaveFileVersions", False);
		FormParameters.Insert("BeingEditedBy", RowData.EditedByUser);
		
		OpenForm("DataProcessor.FilesOperations.Form.FinishingEditing", FormParameters, ThisObject);
	ElsIf FilesArray.Count() = 1 Then 
		Handler = New CallbackDescription("SetFileCommandsAvailability", ThisObject);
		FileUpdateParameters = FilesOperationsInternalClient.FileUpdateParameters(Handler, RowData.Ref, UUID);
		FileUpdateParameters.Insert("CreateNewVersion", False);
		FilesOperationsInternalClient.EndEditAndNotify(FileUpdateParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure Release(Command)
	
	If Not FileCommandsAvailable() Then
		Return;
	EndIf;
	
	FilesOperationsInternalClient.UnlockFiles(Items.List);
	SetFileCommandsAvailability();
	
EndProcedure

&AtClient
Procedure Lock(Command)
	
	If Not FileCommandsAvailable() Then
		Return;
	EndIf;
	
	CurrentData = CurrentFileListData();
	
	If WhetherToSendEDIFile(CurrentData.Ref) Then
		CompletionDetails = New CallbackDescription("LockCompletion", ThisObject);		
		AskQuestionToUserWhenChangingFile(CompletionDetails); 
	Else
		LockCompletion(New Structure("Value", DialogReturnCode.Yes));
	EndIf;
	
EndProcedure

&AtClient
Procedure Delete(Command)
	
	If Items.List.CurrentRow = Undefined Then
		Return;
	EndIf;
	
	CurrentData = CurrentFileListData();
	
	FilesOperationsInternalClient.DeleteData(
		New CallbackDescription("AfterDeleteData", ThisObject),
		CurrentData.Ref, UUID);
	
EndProcedure

&AtClient
Procedure ShowMarkedFiles(Command)
	
	FilesOperationsInternalClient.ChangeFilterByDeletionMark(List.Filter, Items.ShowMarkedFiles);
	
EndProcedure

#EndRegion
// End StandardSubsystems.FilesOperations  

#EndRegion

#Region Private

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

#Region OnChangeAttributes

&AtServer
Procedure SetAvailabilityPurchasingOption()

	UsePaperworkForSeparatePurchasesOfGoods = Not Object.PurchaseRegistrationOption = Enums.PurchaseRegistrationOptions.NotSeparate;
	
	Items.PurchaseRegistrationOption.Enabled = UsePaperworkForSeparatePurchasesOfGoods;
	
	FillInListOfOptionsForPurchasing();
	
EndProcedure

&AtServer
Procedure FillInListOfOptionsForPurchasing()
	
	UninvoicedDeliveriesOfGoodsAndServices = Enums.PurchaseRegistrationOptions.UninvoicedDeliveriesOfGoodsAndServices;
	
	FoundItem = Items.PurchaseRegistrationOption.ChoiceList.FindByValue(UninvoicedDeliveriesOfGoodsAndServices);
	
	If Object.BusinessOperation = Enums.BusinessTransactions.ImportGoodsInTransit Then
		If FoundItem <> Undefined Then
			Items.PurchaseRegistrationOption.ChoiceList.Delete(FoundItem);
		EndIf;
	ElsIf UseUninvoicedDeliveries Then
		If FoundItem = Undefined Then
			Items.PurchaseRegistrationOption.ChoiceList.Add(UninvoicedDeliveriesOfGoodsAndServices,
				NStr("vi = 'Theo sơ đồ ""Giao hàng không có hóa đơn""';
					|ru = 'По схеме ""Неотфактурованные поставки товаров""';
					|en = '""Goods received not invoiced"" '; fa = '«کالاهای دریافتی بدون فاکتور»';
					|it = '""Goods received not invoiced"" ';
					|pl = '""Goods received not invoiced"" ';
					|tr = '""Faturasız teslimat ürünler"" şemasına göre'"));
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure SetAvailabilityOptionForProcessingDocumentsForServices(EstablishAcceptanceOfServices = True)

	UsePaperworkForSeparateProcurementOfServices = Object.OptionForRegisteringServiceReceiptDocuments = Enums.OptionsForRegisteringServiceDocuments.ReceiptOfServicesIsReversed
		Or Object.OptionForRegisteringServiceReceiptDocuments = Enums.OptionsForRegisteringServiceDocuments.ReceiptOfServicesIsInvoiced;
	
	Items.OptionForRegisteringServiceReceiptDocuments.Enabled = UsePaperworkForSeparateProcurementOfServices;
	
	If Not (Object.BusinessOperation = Enums.BusinessTransactions.ImportFromEAEU
		Or Object.BusinessOperation = Enums.BusinessTransactions.ImportFromEAEUInvoicedDelivery
		Or Object.BusinessOperation = Enums.BusinessTransactions.PurchaseFromSupplier
		Or Object.BusinessOperation = Enums.BusinessTransactions.ImportFromEAEUGoodsInTransit
		Or Object.BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorGoodsInTransit
		Or Object.BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt) Then
		Object.OptionForRegisteringServiceReceiptDocuments = Enums.OptionsForRegisteringServiceDocuments.ReceiptOfServicesNotUsed;
		Items.UsePaperworkForSeparateProcurementOfServices.Enabled = False;
		Items.OptionForRegisteringServiceReceiptDocuments.Enabled = False; 
	Else
		Items.UsePaperworkForSeparateProcurementOfServices.Enabled = True;
		Items.OptionForRegisteringServiceReceiptDocuments.Enabled = UsePaperworkForSeparateProcurementOfServices;
	EndIf;
	
	SetAvailabilityRegistrationOfReceiptOfServices();
	SetServiceAcceptanceParameters(EstablishAcceptanceOfServices);

EndProcedure

&AtServer
Procedure SetAvailabilityRegistrationOfReceiptOfServices()

    Items.RegistrationOfReceiptOfServices.Enabled = Items.OptionForRegisteringServiceReceiptDocuments.Enabled;

EndProcedure

&AtServer
Procedure ContractTypeOnChangeServer()

	OldBusinessOperation		= Object.BusinessOperation;
	Object.BusinessOperation	= Catalogs.CounterpartyContracts.BusinessOperation(Object.ContractType,
																								Object.PurchaseRegistrationOption);
	
	If OldBusinessOperation <> Object.BusinessOperation Then
		Object.FinancialAccountingGroup = Catalogs.FinancialAccountingGroupsOfARAP.EmptyRef();
		Object.GroupOfFinancialARAPAccountingWithEndCustomer = Catalogs.FinancialAccountingGroupsOfARAP.EmptyRef();
	EndIf;
	
	ProcurementOperations = PurchasesServer.BusinessOperationsOnMain(Enums.BusinessTransactions.PurchaseFromSupplier);
	ImportOperations = PurchasesServer.BusinessOperationsOnMain(Enums.BusinessTransactions.PurchaseByImport);
	
	PartnerDetails_ = Common.ObjectAttributesValues(Object.Partner, "Client, Vendor");
	
	If ValueIsFilled(Object.Partner)
		And (Not PartnerDetails_.Client
			And (Object.BusinessOperation = Enums.BusinessTransactions.SaleToCustomer
				Or Object.BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent
				Or Object.BusinessOperation = Enums.BusinessTransactions.TollManufacturing2_5
				Or Object.BusinessOperation = Enums.BusinessTransactions.TransferToStorageWithRightOfSale)
		   Or Not PartnerDetails_.Vendor
			And (ProcurementOperations.Find(Object.BusinessOperation) <> Undefined
				Or ImportOperations.Find(Object.BusinessOperation) <> Undefined
				Or Object.BusinessOperation = Enums.BusinessTransactions.ProductionByToller2_5
				Or Object.BusinessOperation = Enums.BusinessTransactions.ProductionAtProcessorInEAEUCountries2_5
				Or Object.BusinessOperation = Enums.BusinessTransactions.TollManufacturing2_5
				Or Object.BusinessOperation = Enums.BusinessTransactions.ConsignmentProcurement
				Or Object.BusinessOperation = Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale)) Then
		
		Object.Partner		= Catalogs.Partners.EmptyRef();
		Object.Counterparty	= Catalogs.Counterparties.EmptyRef();
		Object.CounterpartyBankAccount = Catalogs.CounterpartyBankAccounts.EmptyRef();
		PartnerWhenChangesAreMadeOnServer();
		
	EndIf;
	
	EstablishVisibilityOfDebtControl(ThisForm);
	
	If Object.BusinessOperation <> Enums.BusinessTransactions.SaleToCustomer Then
		Object.LimitDebtAmount = False;
	EndIf;
	
	If Object.ContractType <> Enums.ContractTypes.WithCustomer Then
		Object.ShipmentIsProhibitedInCaseOfARAPOverdue = False;
	EndIf;
	
	GeneralTaxationAndTypeOfActivity();
	
	If Object.ContractType <> Enums.ContractTypes.ReceivingForCustody
		And Object.ContractType <> Enums.ContractTypes.CustomerInvoiceOutsourcedSale
		And Object.ContractType <> Enums.ContractTypes.ReceiptForTolling2_5 Then
		Object.RegistrationOfWriteOffOfInventoryShortageAcceptedForStorage = Enums.RegistrationOfWriteOffOfGoodsAcceptedForStorage.EmptyRef();
		Object.RegistrationOfWriteOffOfGoodsAcceptedForStorageToProduction = Enums.RegistrationOfWriteOffOfGoodsAcceptedForStorage.EmptyRef();
	Else
		Object.RegistrationOfWriteOffOfInventoryShortageAcceptedForStorage = Enums.RegistrationOfWriteOffOfGoodsAcceptedForStorage.RegisterBuyback;
		Object.RegistrationOfWriteOffOfGoodsAcceptedForStorageToProduction = Enums.RegistrationOfWriteOffOfGoodsAcceptedForStorage.RegisterBuyback;
	EndIf;
	
	If Not (Object.ContractType = Enums.ContractTypes.Import
		Or Object.ContractType = Enums.ContractTypes.PurchaseEAEU
		Or Object.ContractType = Enums.ContractTypes.WithVendor) Then
		
		Object.PurchaseRegistrationOption = Enums.PurchaseRegistrationOptions.NotSeparate;
		
		InitializeProcurementOption();
		
	EndIf;

	If UsePaperworkForSeparatePurchasesOfGoods
		And Object.ContractType = Enums.ContractTypes.Import Then
		
		Object.PurchaseRegistrationOption = Enums.PurchaseRegistrationOptions.GoodsInTransit;
		
		InitializeProcurementOption();
		
	EndIf;
	
	If Object.ContractType = Enums.ContractTypes.WithConsignee Then
		If OnlyConsignmentSales25 Or Not ToUseTermsOfSales Or Not SelectConsignmentSalesVersion Then
			Object.ConsignmentSales25 = ?(ValueIsFilled(Object.Ref), Object.ConsignmentSales25, True);
			Object.ExecutionScheduleIsSpecified = False;
			Object.OptionOfDeterminingExecutionScheduleInContract = Enums.OptionsForDeterminingExecutionScheduleInContract.SalesOrderCustomerInvoices;
			Object.Sum = 0;
		EndIf;
	ElsIf Object.ContractType = Enums.ContractTypes.WithConsignor
		Or Object.ContractType = Enums.ContractTypes.ReceivingForCustody 
		Or Object.ContractType = Enums.ContractTypes.TransferToCustody 
		Or Object.ContractType = Enums.ContractTypes.SalesViaCommissionAgent
		Or Object.ContractType = Enums.ContractTypes.ReceiptForTolling2_5 Then
		Object.ExecutionScheduleIsSpecified = False;
		Object.OptionOfDeterminingExecutionScheduleInContract = Enums.OptionsForDeterminingExecutionScheduleInContract.SalesOrderCustomerInvoices;
	Else
		Object.ConsignmentSales25 = False;
		Object.SalesPriceType = Catalogs.TypesOfPrices.EmptyRef();
		Object.PriceTypeAccountingPriceType = Catalogs.TypesOfPrices.EmptyRef();
	EndIf;
	
	If Not Object.ContractType = Enums.ContractTypes.SalesViaCommissionAgent Then
		Object.ContractWithCommissionAgent = Catalogs.CounterpartyContracts.EmptyRef();
		Object.CounterpartyCommissionAgent = Catalogs.Counterparties.EmptyRef();
		Object.CommissionAgentPartner = Catalogs.Partners.EmptyRef();
		Object.GroupOfFinancialARAPAccountingWithEndCustomer = Catalogs.FinancialAccountingGroupsOfARAP.EmptyRef();
	EndIf;
	
	GoodsDelivery.WhenReadingCreatingOrdersOnServer(Items, Object);
	ObjectsFillingByStatistics.FillInSubordinateDetailsOfObject(Object, "ContractType");
	
	FillInPartnerSelectionParameters();
	FillInListOfOptionsForDeterminingExecutionScheduleInContract(
		Items.OptionOfDeterminingExecutionScheduleInContract.ChoiceList, Object.ContractType);
	ConfigureListForSelectingOrderOfCalculations();
	ConfigureParametersForSelectingCashFlowItem();
	SetPropertiesOfElementsOfTaxationAndSeparateVATAccounting();
	RefreshFormTitle();
	ItemManagementExecutionSchedule();
	EstablishVisibilityOfBusinessDirection();
	SetVisibilityOfSeparatePurchaseOptions();
	SetVisibilityOrderOfDebitingAcceptedGoods(ThisForm);
	SetVisibilityOfReportBreakdownForPrincipal(ThisForm);
	SetVisibilityNewCommissionScheme();
	EstablishVisibilityOfGoodsQualityControl();
	SetAvailabilityPurchasingOption();
	SetAvailabilityOptionForProcessingDocumentsForServices();
	If Object.ContractType = Enums.ContractTypes.Sublease Then
		Items.SubleaseGroup.Visible = True;
	Else
		Object.LeaseContracts = Catalogs.LeaseContract.EmptyRef();
		Items.SubleaseGroup.Visible = False;
	EndIf;	
	EstablishVisibilityOfCentralizedContract();
	ElementManagementIsVariantOfContractCourse();
	AtEndOfChangingLocalizationDetailsOnServer("ContractType", Undefined);
	
	ARAPAccountingFormWork.WhenChangingParametersOfMechanism(ThisForm);
	
	Object.RevalueGoodsAndServicesForConsignmentNotification = 
			Object.ContractType = Enums.ContractTypes.WithConsignor
			Or Object.ContractType = Enums.ContractTypes.CustomerInvoiceOutsourcedSale;
	
	VATAccountingERP.FillInVATRateForPayments_(Object.VATRate, Object.VATTaxation, Object.Organization, Object.ValidityEndDate);
	SetPropertiesOfElementsOfTaxationAndSeparateVATAccounting();
	AtEndOfChangingLocalizationDetailsOnServer("VATTaxation", Undefined);
	
	SetValuesForDiscountingDetails();
	ManagingDiscountItems();
	VATTaxationOnChangeServer();
	
	UseEDO = False;
	UseLabeling = False;
	If (Not UseEDO) Or (Not UseLabeling) Or Object.ContractWithSelfEmployedPerson Then 
		Items.LocalizationGroupOptionForDisposalOfMarkedProducts.Visible = False;
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	SetHeaderOfIPField();
	
EndProcedure

&AtServer
Procedure FillInPartnerSelectionParameters()
	
	ArrayOfPartnerSelectionParameters = New Array;
	
	ProcurementOperations = PurchasesServer.BusinessOperationsOnMain(Enums.BusinessTransactions.PurchaseFromSupplier);
	ImportOperations = PurchasesServer.BusinessOperationsOnMain(Enums.BusinessTransactions.PurchaseByImport);
	OperationsInEAEUCountries = PurchasesServer.BusinessOperationsOnMain(Enums.BusinessTransactions.ImportFromEAEU);
	ProductionOperationsAtProcessor2_5 = PurchasesServer.BusinessOperationsOnMain(Enums.BusinessTransactions.ProductionByToller2_5);
	
	If Object.BusinessOperation = Enums.BusinessTransactions.SaleToCustomer
		Or Object.BusinessOperation = Enums.BusinessTransactions.TollManufacturing2_5
		Or Object.BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent
		Or Object.BusinessOperation = Enums.BusinessTransactions.TransferToStorageWithRightOfSale
		Or Object.BusinessOperation = Enums.BusinessTransactions.DeliveryForPrincipal
		Or Object.BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgent Then
		
		ArrayOfPartnerSelectionParameters.Add(New ChoiceParameter("Filter.Client", True));
		
	EndIf;
		
	If ProcurementOperations.Find(Object.BusinessOperation) <> Undefined
		Or ImportOperations.Find(Object.BusinessOperation) <> Undefined
		Or OperationsInEAEUCountries.Find(Object.BusinessOperation) <> Undefined
		Or Object.BusinessOperation = Enums.BusinessTransactions.ConsignmentProcurement
		Or ProductionOperationsAtProcessor2_5.Find(Object.BusinessOperation) <> Undefined
		Or Object.BusinessOperation = Enums.BusinessTransactions.TollManufacturing2_5
		Or Object.BusinessOperation = Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale Then
		
		ArrayOfPartnerSelectionParameters.Add(New ChoiceParameter("Filter.Vendor", True));
		
	EndIf;
	
	Items.Partner.ChoiceParameters = New FixedArray(ArrayOfPartnerSelectionParameters);
	
EndProcedure

&AtServerNoContext
Procedure PartnerOnChangeServer(Partner, Counterparty, ForeignCurrencyTransaction, CounterpartyBankAccount, ContactPerson, CounterpartyLegEntInd, Organization)
	
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
	PartnersAndCounterparties.FillInDefaultPartnerContactPerson(Partner, ContactPerson);
	FillInCounterpartySDefaultBankAccount(Counterparty, ForeignCurrencyTransaction, CounterpartyBankAccount, Organization);
	CounterpartyLegEntInd = Common.ObjectAttributeValue(Counterparty, "LegalEntityIndividual");
	
EndProcedure

&AtServerNoContext
Function CheckPartnerFlagsClientVendor(Partner, BusinessOperation, IsNew)
	
	Return Catalogs.CounterpartyContracts.CheckPartnerFlagsClientVendor(Partner, BusinessOperation,
		IsNew, True);

EndFunction

&AtServer
Procedure ARAPCurrencyOnChangeServer()
	
	PaymentCurrencyLocal = ?(Object.ForeignCurrencyTransaction, False, Undefined);
					
	Object.ForeignCurrencyTransaction = ARAPAccountingServer.GetPaidInDefaultCurrency(PaymentCurrencyLocal, Object.Organization);
	
	SetDefaultContractWithCommissionAgent();
	ProcessBankAccounts();
	
	SetVisibilityOfPaymentInCurrency();
	SetValuesForDiscountingDetails();
	
	CheckContractCurrencyExchangeRate();
	If Object.ARAPCurrency = LocalAccountingCurrency Then
		Object.ContractRateOption = Enums.ContractRateOptions.Mutable;
	EndIf;
	FillInContractCurrencyExchangeRateValues();
	ElementManagementIsVariantOfContractCourse();
	
	AtEndOfChangingLocalizationDetailsOnServer("Currency", Undefined);
	
EndProcedure

&AtClient
Procedure LimitDebtAmountOnChange(Item)
	
	EstablishVisibilityOfDebtControl(ThisForm);
	
EndProcedure

&AtServerNoContext
Procedure ContactPersonOnChangeServer(Partner, Counterparty, ForeignCurrencyTransaction, CounterpartyBankAccount, ContactPerson, CounterpartyLegEntInd, Organization)
	
	OwnerOfContactPerson = Common.ObjectAttributeValue(ContactPerson, "Owner");
	If OwnerOfContactPerson <> Partner Then
		Partner = OwnerOfContactPerson;
		PartnerOnChangeServer(Partner, Counterparty, ForeignCurrencyTransaction, CounterpartyBankAccount, ContactPerson, CounterpartyLegEntInd, Organization);
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure CounterpartyOnChangeServer(Counterparty, ForeignCurrencyTransaction, CounterpartyBankAccount, CounterpartyLegEntInd, Organization)
	
	FillInCounterpartySDefaultBankAccount(Counterparty, ForeignCurrencyTransaction, CounterpartyBankAccount, Organization);
	CounterpartyLegEntInd = Common.ObjectAttributeValue(Counterparty, "LegalEntityIndividual");
	
EndProcedure

&AtServer
Procedure ARAPObjectSettingsOnChangeServer()
	
	If (Object.ARAPObjectSettings <> Enums.ARAPObjectSettings.ByCounterpartyContracts 
		And Object.ARAPObjectSettings <> Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice)
		Or (Object.ContractType = Enums.ContractTypes.WithConsignee
			And Object.ConsignmentSales25) Then
		Object.ExecutionScheduleIsSpecified = False;
		Object.OptionOfDeterminingExecutionScheduleInContract = Enums.OptionsForDeterminingExecutionScheduleInContract.SalesOrderCustomerInvoices;
	EndIf;
	
	If Object.ContractRateOption = Enums.ContractRateOptions.FixedAsOfShipmentDate
		And Not AvailabilityOfFixedRateOnDateOfShipment() Then
		Object.ContractRateOption = Enums.ContractRateOptions.Mutable;
	EndIf;
	
	ItemManagementExecutionSchedule();
	EstablishVisibilityOfCentralizedContract();
	ElementManagementIsVariantOfContractCourse();
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "ARAPObjectSettings");
	
EndProcedure

&AtServer
Procedure VATTaxationOnChangeServer()
	
	If ValueIsFilled(Object.VATTaxation) Then
		If ValueIsFilled(Object.VATRate) Then
			If Not VATAccountingERP.VATRateIsCorrect(Object.VATRate, Object.VATTaxation, Object.Organization, Object.ValidityEndDate) Then
				Object.VATRate = Catalogs.VATRates.EmptyRef();
			EndIf;
		EndIf;
		
		VATAccountingERP.FillInVATRateForPayments_(Object.VATRate,
			Object.VATTaxation,
			Object.Organization,
			Object.ValidityEndDate
		);
	EndIf;
	
	SetPropertiesOfElementsOfTaxationAndSeparateVATAccounting();
	AtEndOfChangingLocalizationDetailsOnServer("VATTaxation", Undefined);
	
EndProcedure

&AtServer
Procedure LineOfBusinessOnChangeServer()
	
	If Not ValueIsFilled(Object.LineOfBusiness) Then
		Return;
	EndIf;
	
	DetailsOfAppointment = "VATTaxationIsDeterminedInDocuments";
	DestinationDetailsValues = Common.ObjectAttributesValues(Object.LineOfBusiness, DetailsOfAppointment);
	
	If Enums.ContractTypes.ThisIsSalesContract(Object.ContractType) Then
		
		Object.VATTaxationIsDeterminedInDocuments = DestinationDetailsValues.VATTaxationIsDeterminedInDocuments;
		GeneralTaxationAndTypeOfActivity();
		
		If Object.VATTaxationIsDeterminedInDocuments Then
			TaxationTreatment = 1;
		Else
			TaxationTreatment = 0;
		EndIf;
		
		Items.VATTaxation.Enabled = Not Object.VATTaxationIsDeterminedInDocuments;
		
	ElsIf Enums.ContractTypes.ThisIsPurchaseContract(Object.ContractType) Then
		
		Object.PurchaseForActivityIsDeterminedInDocument = DestinationDetailsValues.VATTaxationIsDeterminedInDocuments;
		GeneralTaxationAndTypeOfActivity();
		
		If Object.PurchaseForActivityIsDeterminedInDocument Then
			SeparateVATAccountingMode = 1;
		Else
			SeparateVATAccountingMode = 0;
		EndIf;
		
		Items.PurchaseForActivity.Enabled = Not Object.PurchaseForActivityIsDeterminedInDocument;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure TaxRegimeInCaseOfChangeServer()
	
	Object.VATTaxationIsDeterminedInDocuments = ?(TaxationTreatment = 1, True, False);
	GeneralTaxationAndTypeOfActivity();
	VATTaxationOnChangeServer();
	
EndProcedure

&AtServer
Procedure ProcessBankAccounts()
	
	BankAccountSelectionOptions = BankAccountSelectionOptions(Object.ForeignCurrencyTransaction, Object.Organization);
	Items.BankAccount.ChoiceParameters            = BankAccountSelectionOptions;
	Items.CounterpartyBankAccount.ChoiceParameters = BankAccountSelectionOptions;
	
	If Not BankAccountCorrespondsToPaymentProcedure(Object.BankAccount, Object.ForeignCurrencyTransaction, Object.Organization) Then
		Object.BankAccount = Undefined;
	EndIf;
	FillInOrganizationSDefaultBankAccount(Object.Organization, Object.ForeignCurrencyTransaction, Object.BankAccount);
	
	ObjectsFillingByStatistics.FillInSubordinateDetailsOfObject(Object, "Organization", , True);
	
	If Not BankAccountCorrespondsToPaymentProcedure(Object.CounterpartyBankAccount, Object.ForeignCurrencyTransaction, Object.Organization) Then
		Object.CounterpartyBankAccount = Undefined;
	EndIf;
	FillInCounterpartySDefaultBankAccount(Object.Counterparty, Object.ForeignCurrencyTransaction, Object.CounterpartyBankAccount, Object.Organization);
	
	ObjectsFillingByStatistics.FillInSubordinateDetailsOfObject(Object, "Counterparty", , True);
	
EndProcedure

&AtServer
Procedure SumOnChangeServer()
	ARAPAccountingFormWork.WhenChangingParametersOfMechanism(ThisForm);
EndProcedure

&AtClient
Procedure NewCommissionSchemeForChanges(Item)
	
	ContractTypeOnChangeServer();
	
EndProcedure

&AtClient
Procedure AccountingTypeOfPricesStartChoice(Item, StandardProcessing)
	
	SetParametersForSelectingTypeOfPricesOnServer("PriceTypeAccountingPriceType");
	
EndProcedure

&AtClient
Procedure SalesPriceTypeStartChoice(Item, StandardProcessing)
	
	SetParametersForSelectingTypeOfPricesOnServer("SalesPriceType");
	
EndProcedure

&AtServer
Procedure VariantOfContractCourseWhenChangedOnServer()
	
	CheckContractCurrencyExchangeRate();
	If Not (ValueIsFilled(NumeratorOfContractCurrencyExchangeRate) And ValueIsFilled(DenominatorOfContractCurrencyExchangeRate)) Then
		FillInContractCurrencyExchangeRateValues();
	EndIf;
	ElementManagementIsVariantOfContractCourse();
	
EndProcedure

&AtClient
Procedure InscriptionDenominatorOfContractCurrencyExchangeRateURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	Items.CourseMultiplicityEditingGroup.Visible = True;
	Items.InscriptionDenominatorOfContractCurrencyExchangeRate.Visible = False;
	
EndProcedure

&AtServerNoContext
Procedure LandlordPartnerOnChangeServer(LandlordPartner, LessorCounterparty)
	
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(LandlordPartner, LessorCounterparty);
	
EndProcedure

&AtServer
Procedure ForeignCurrencyTransactionOnChangeServer()

	ProcessBankAccounts();
	AtEndOfChangingLocalizationDetailsOnServer("Currency", Undefined);

EndProcedure

&AtServer
Procedure OptionForRegisteringServiceReceiptDocumentsOnChangeServer()
	
	SetAvailabilityMonthlyReceiptOfServices();
	
	OnChangingServiceAcceptanceSettingsServer();
	
	SetAvailabilityRegistrationOfReceiptOfServices();
	
	AtEndOfChangingLocalizationDetailsOnServer("UsePaperworkForSeparateProcurementOfServices", Undefined);
	
EndProcedure

&AtServer
Procedure SetAvailabilityMonthlyReceiptOfServices()

	Items.MonthlyReceiptOfServices.Enabled = Object.OptionForRegisteringServiceReceiptDocuments =
		Enums.OptionsForRegisteringServiceDocuments.ReceiptOfServicesIsReversed;

EndProcedure

&AtClient
Procedure SetHintForSeparatePurchasingOfWorksAndServices()

	If Object.OptionForRegisteringServiceReceiptDocuments = PredefinedValue("Enum.OptionsForRegisteringServiceDocuments.ReceiptOfServicesIsReversed") Then
		Items.UsePaperworkForSeparateProcurementOfServices.ToolTip = NStr("vi = 'Việc tiếp nhận dịch vụ mà không có chứng từ gốc được ghi nhận bằng chứng từ ""Tiếp nhận dịch vụ vào bộ phận"". 
			|Khi tiếp nhận các chứng từ gốc, việc tiếp nhận được đảo ngược và ghi nhận lại bằng chứng từ 
			|""Mua hàng hóa và dịch vụ"" có giao dịch kinh tế ""Mua hàng từ nhà cung cấp"".';
			|ru = 'Поступление услуг без первичных документов регистрируется документом ""Поступление услуг в подразделение"". 
			|При поступлении первичных документов поступление услуг сторнируется и регистрируется документ 
			|""Приобретение товаров и услуг"" с хозяйственной операцией ""Закупка у поставщика"".';
			|en = 'The receipt of services without source documents is recorded in the ""Receipt of services to business unit"" document. 
			|When you receive the source documents, the receipt of services is reversed and the ""Vendor invoice"" document 
			|with the ""Purchase from vendor"" business transaction is registered.'; fa = 'The receipt of services without source documents is recorded in the ""Receipt of services to business unit"" document. 
			|When you receive the source documents, the receipt of services is reversed and the ""Vendor invoice"" document 
			|with the ""Purchase from vendor"" business transaction is registered.';
			|it = 'The receipt of services without source documents is recorded in the ""Receipt of services to business unit"" document. 
			|When you receive the source documents, the receipt of services is reversed and the ""Vendor invoice"" document 
			|with the ""Purchase from vendor"" business transaction is registered.';
			|pl = 'The receipt of services without source documents is recorded in the ""Receipt of services to business unit"" document. 
			|When you receive the source documents, the receipt of services is reversed and the ""Vendor invoice"" document 
			|with the ""Purchase from vendor"" business transaction is registered.';
			|tr = 'Birincil belgeler olmadan hizmet girişi, ""Departmana hizmet girişi"" belgesiyle kaydedilir. 
			| Birincil belgeler geldiğinde, hizmet girişi ters kaydedilir ve 
			| ""Ürün ve hizmet alımı"" belgesi, ""Tedarikçiden satın alma"" ticari işlemiyle kaydedilir.'");
	ElsIf Object.OptionForRegisteringServiceReceiptDocuments = PredefinedValue("Enum.OptionsForRegisteringServiceDocuments.ReceiptOfServicesIsInvoiced") Then
		Items.UsePaperworkForSeparateProcurementOfServices.ToolTip = NStr("vi = 'Việc tiếp nhận công việc và dịch vụ mà không có chứng từ gốc được ghi nhận bằng chứng từ ""Tiếp nhận dịch vụ vào bộ phận"",  
			|mà theo đó sau này sẽ thực hiện ""lập hóa đơn"" có sử dụng chứng từ ""Mua hàng hóa và dịch vụ"" 
			|với giao dịch kinh tế ""Mua hàng từ nhà cung cấp (hóa đơn giao hàng)"". Điều chỉnh chi phí được phản ánh cho 
			|chênh lệch giữa các lần mua hàng và tiếp nhận.';
			|ru = 'Поступление работ и услуг без первичных документов регистрируется документом ""Поступление услуг в подразделение"",  
			|по которому в дальнейшем производится ""фактуровка"" с использованием документа ""Приобретение товаров и услуг"" 
			|с хозяйственной операцией ""Закупка у поставщика (фактуровка поставки)"". Отраженные расходы корректируются на 
			|разницу между приобретением и поступлением.';
			|en = 'The receipt of works and services without source documents is registered in the ""Receipt of services to business unit"" document, 
			|which is used for further ""invoicing"" with the ""Vendor invoice"" document 
			|with the ""Purchase from vendor (invoiced delivery)"" business transaction. The recorded expenses are adjusted for the 
			|difference between the invoice and receipt.'; fa = 'The receipt of works and services without source documents is registered in the ""Receipt of services to business unit"" document, 
			|which is used for further ""invoicing"" with the ""Vendor invoice"" document 
			|with the ""Purchase from vendor (invoiced delivery)"" business transaction. The recorded expenses are adjusted for the 
			|difference between the invoice and receipt.';
			|it = 'The receipt of works and services without source documents is registered in the ""Receipt of services to business unit"" document, 
			|which is used for further ""invoicing"" with the ""Vendor invoice"" document 
			|with the ""Purchase from vendor (invoiced delivery)"" business transaction. The recorded expenses are adjusted for the 
			|difference between the invoice and receipt.';
			|pl = 'The receipt of works and services without source documents is registered in the ""Receipt of services to business unit"" document, 
			|which is used for further ""invoicing"" with the ""Vendor invoice"" document 
			|with the ""Purchase from vendor (invoiced delivery)"" business transaction. The recorded expenses are adjusted for the 
			|difference between the invoice and receipt.';
			|tr = 'Birincil belgeler olmaksızın iş ve hizmet girişi, ""Departmana hizmet girişi"" belgesi ile kaydedilir; 
			| bu belge üzerinden daha sonra, ""Tedarikçiden satın alma (teslimat faturalandırması)"" ticari işlemini içeren ""Ürün ve hizmet alımı""
			| belgesi kullanılarak faturalandırma yapılır. Yansıtılan giderler, alım ile giriş arasındaki 
			|fark tutarında düzeltilir.'");
	Else
		Items.UsePaperworkForSeparateProcurementOfServices.ToolTip = NStr("vi = 'Đối với việc mua sắm riêng biệt công việc và dịch vụ, có các tùy chọn sau: ""Tiếp nhận dịch vụ được lập hóa đơn"" và 
			|""Tiếp nhận dịch vụ được đảo ngược (""phương pháp dồn tích"")';
			|ru = 'Для раздельной закупки работ, услуг доступны следующие варианты: ""Поступление услуг фактурируется"" и 
			|""Поступление услуг сторнируется ""метод начисления""';
			|en = 'The following options are available for unbilled inventory for works and services: ""Receipt of services is invoiced"" and 
			|""Receipt of services is reversed (accrual method)""'; fa = 'The following options are available for unbilled inventory for works and services: ""Receipt of services is invoiced"" and 
			|""Receipt of services is reversed (accrual method)""';
			|it = 'The following options are available for unbilled inventory for works and services: ""Receipt of services is invoiced"" and 
			|""Receipt of services is reversed (accrual method)""';
			|pl = 'The following options are available for unbilled inventory for works and services: ""Receipt of services is invoiced"" and 
			|""Receipt of services is reversed (accrual method)""';
			|tr = 'İş ve hizmetlerin ayrı satın alınması için şu seçenekler mevcuttur: ""Hizmet girişi faturalandırılır"" ve 
			| ""Hizmet alımı ''tahakkuk yöntemi'' ile ters kaydedilir ""'");
	EndIf;

EndProcedure

#EndRegion

#Region Delivery

&AtServer
Procedure SupplementDeliveryInformationWithContactsServer()
	GoodsDelivery.SupplementDeliveryInformationWithContacts(Object);
EndProcedure

&AtServer
Procedure FillInAndSetDeliveryAttributesServer(FormItemName)
	
	GoodsDelivery.FillInDeliveryDetails(Items, FormItemName, Object);
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure OnReadCreateAtServer()
	
	TMCommonUseClientServer.SetFormItemProperty(Items, "Change", "Enabled", False);

	ParentCompany = Object.Organization = Common.ObjectAttributeValue(Object.Organization, "ParentCompany");
	CounterpartyLegEntInd = Common.ObjectAttributeValue(Object.Counterparty, "LegalEntityIndividual");
	DebtClassification = ?(Object.PaymentDueDateIsSet And Object.PaymentDueDate > 365, 1, 0);
	
	If Not ValueIsFilled(Object.ARAPCurrency) Then
		Object.ARAPCurrency = IncomeAndExpensesServer.GetCurrencyOfManagementAccounting();
	EndIf;
	
	If Not ValueIsFilled(Object.GoodsReceiptOption) Then
		Object.GoodsReceiptOption = Constants.GoodsReceiptOption.Get();
	EndIf;
	
	If Not ValueIsFilled(Object.ServiceReceiptOption) Then
		Object.ServiceReceiptOption = Constants.GoodsReceiptOption.Get();
	EndIf;	
	
	UseWarehouseManagemantSystemForGoodsReceipt = GetFunctionalOption("UseWarehouseManagemantSystemForGoodsReceipt");
	UseGoodsInTransitFromVendors    = GetFunctionalOption("UseGoodsInTransitFromVendors");
	UseUninvoicedDeliveries   = GetFunctionalOption("UseUninvoicedDeliveries");
	NewOnlineARAPAccounting          = GetFunctionalOption("NewOnlineARAPAccounting");
	UseMultipleCompanies        = GetFunctionalOption("UseMultipleCompanies");
	UseBranchOfficesWithSeparateBalanceSheets = GetFunctionalOption("UseBranchOfficesWithSeparateBalanceSheets");
	ToUseTermsOfSales        = GetFunctionalOption("ToUseTermsOfSales");
	SelectConsignmentSalesVersion        = GetFunctionalOption("SelectConsignmentSalesVersion")
												Or (ValueIsFilled(Object.Ref) And Not Object.ConsignmentSales25);
	OnlyConsignmentSales25             = GetFunctionalOption("OnlyConsignmentSales25")
												Or Not ToUseTermsOfSales Or Not SelectConsignmentSalesVersion;
	LocalAccountingCurrency          = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	
	
	FixedContractAmount = (Object.Sum <> 0);
	ApplyInstallmentDiscountRate = (Object.DiscountRate <> 0);
	FillInContractCurrencyExchangeRateValues();
	
	InitializeProcurementOption();
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
	
	If Object.SplitReportByDocuments Then
		ToSplitReport = 1;
	Else
		ToSplitReport = 0;
	EndIf;
	
	PurchasesServer.FillInAcceptanceOptionsSettings(Object.GoodsReceiptOption, RegisterReceipt, GoodsReceipt);
	PurchasesServer.FillInListOfContractAcceptanceOptions(Items.RegisterReceipt,
																	Items.GoodsReceipt,
																	Object.PurchaseRegistrationOption);
																	
	PurchasesServer.FillInAcceptanceOptionsSettings(Object.ServiceReceiptOption, RegistrationOfReceiptOfServices, AcceptanceOfServices);
	PurchasesServer.FillInListOfOptionsForAcceptingServicesUnderContracts(Items.RegistrationOfReceiptOfServices,
																	Items.AcceptanceOfServices,
																	Object.OptionForRegisteringServiceReceiptDocuments);	
	
	If Items.RegistrationOfReceiptOfServices.ChoiceList.FindByValue(RegistrationOfReceiptOfServices) = Undefined Then
		If Items.RegistrationOfReceiptOfServices.ChoiceList.Count() > 0 Then
			RegistrationOfReceiptOfServices = Items.RegistrationOfReceiptOfServices.ChoiceList[0].Value;
		EndIf;
	EndIf;
	
	BankAccountSelectionParameters = BankAccountSelectionOptions(Object.ForeignCurrencyTransaction, Object.Organization);
	Items.BankAccount.ChoiceParameters            = BankAccountSelectionParameters;
	Items.CounterpartyBankAccount.ChoiceParameters = BankAccountSelectionParameters;
	FillInPartnerSelectionParameters();
	FillInListOfOptionsForDeterminingExecutionScheduleInContract(
		Items.OptionOfDeterminingExecutionScheduleInContract.ChoiceList, Object.ContractType);
	
	SetAvailabilityOfItemsByStatusServer();
	
	ConfigureListForSelectingOrderOfCalculations();
	EstablishVisibilityOfDebtControl(ThisForm);
	SetPropertiesOfElementsOfTaxationAndSeparateVATAccounting();
	ItemManagementExecutionSchedule();
	EstablishVisibilityOfCentralizedContract();

	EstablishVisibilityOfBusinessDirection();
	SetVisibilityOfSeparatePurchaseOptions();
	SetHeadersForProductAcceptanceDetails();
	SetVisibilityOrderOfDebitingAcceptedGoods(ThisForm);
	SetVisibilityOfReportBreakdownForPrincipal(ThisForm);
	SetVisibilityNewCommissionScheme();
	EstablishVisibilityOfGoodsQualityControl();
	SetVisibilityOfRegularPayments();
	If Object.ContractType = Enums.ContractTypes.Sublease Then 
		Items.SubleaseGroup.Visible = True;
		RentalAttributes = Common.ObjectAttributesValues(Object.LeaseContracts, "Partner, Counterparty");
		LandlordPartner = RentalAttributes.Partner;
		LessorCounterparty = RentalAttributes.Counterparty;
	Else
		Items.SubleaseGroup.Visible = False;
	EndIf;
	RefreshFormTitle();
	
	Items.NameForPrinting.ChoiceList.Clear();
	Items.NameForPrinting.ChoiceList.Add(Object.Description);
	
	If ReadOnly Then
		Items.FixedContractAmount.ReadOnly = True;
		Items.DebtClassification.ReadOnly = True;
		Items.ApplyInstallmentDiscountRate. ReadOnly = True;
	EndIf;
	
	Items.RegisterReceipt.Enabled = AccessRight("Edit", Metadata.Catalogs.CounterpartyContracts);
	Items.GoodsReceipt.Enabled   = AccessRight("Edit", Metadata.Catalogs.CounterpartyContracts);
	
	Items.RegistrationOfReceiptOfServices.Enabled = AccessRight("Edit", Metadata.Catalogs.CounterpartyContracts);
	Items.AcceptanceOfServices.Enabled = AccessRight("Edit", Metadata.Catalogs.CounterpartyContracts);	
	
	SetAvailabilityMonthlyReceiptOfServices();
	
	SetDeliveryAvailability();
	GeneralTaxationAndTypeOfActivity(False);
	
	If Object.ConsignmentSales25
		Or Object.ContractType = Enums.ContractTypes.SalesViaCommissionAgent Then
		Items.GroupContractAmount.Visible = False;
	EndIf;
	
	SetAvailabilityPurchasingOption();
	SetAvailabilityOptionForProcessingDocumentsForServices(False);
	
	InitializeListOfOptionsForPurchasingWorksAndServices();
	InitializeListOfOptionsForSelectingOptionForPurchasingGoods();
	
	SetAcceptanceAvailability();
	SetConditionalAppearance();
	CounterpartyContractsLocalization.OnReadCreateAtServer(ThisForm);
	
	ConfigureParametersForSelectingCashFlowItem();
	
	SetHeaderOfIPField();
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();
	SetConditionalDesignOfDivision();
	LinesOfBusinessServer.EstablishConditionalAppearanceOfDirectionOfActivity(ThisForm);
	CounterpartyContractsLocalization.SetConditionalAppearance(ThisForm);
EndProcedure

&AtServer
Procedure SetConditionalDesignOfDivision()
	
	Item = ThisObject.ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Department.Name);
	
	SelectionGroupOr = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupOr.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	
	ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ContractType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ContractTypes.ReceiptForTolling2_5;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Department");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	Item = ThisObject.ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Department.Name);
	
	SelectionGroupOr = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupOr.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	SelectionGroupAnd = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupAnd.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	
	ItemFilter = SelectionGroupAnd.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ContractType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.ContractTypes.ReceiptForTolling2_5;
	
	ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Department");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);

EndProcedure
&AtServer
Procedure SetAvailabilityOfItemsByStatusServer()
	
	ItemArray = New Array;
	
	// Header Controls
	ItemArray.Add("Date");
	ItemArray.Add("Number");
	ItemArray.Add("Partner");
	ItemArray.Add("ValidityStartDate");
	ItemArray.Add("ValidityEndDate");
	ItemArray.Add("Counterparty");
	ItemArray.Add("Organization");
	ItemArray.Add("ARAPCurrency");
	ItemArray.Add("ForeignCurrencyTransaction");
	ItemArray.Add("ContractType");
	ItemArray.Add("ARAPObjectSettings");
	ItemArray.Add("SetDateInterval");
	ItemArray.Add("LimitDebtAmount");
	ItemArray.Add("AllowableAmountPayable");
	ItemArray.Add("CommissionScheme");
	ItemArray.Add("ConductARAPAccountingThroughEndCustomers");
	ItemArray.Add("PriceTypeAccountingPriceType");
	ItemArray.Add("SalesPriceType");
	
	TMCommonUse.SetSubscriptionForFormElementChangeEvents(ThisObject, ItemArray);
	
	ItemArray = New Array;
	ItemArray.Add("LimitDebtAmount");
	ItemArray.Add("AllowableAmountPayable");
	ItemArray.Add("ShipmentIsProhibitedInCaseOfARAPOverdue");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items,
		ItemArray,
		"ReadOnly", Not UserRightsCached.VarianceFromSalesTermsAndConditions());
	
EndProcedure

&AtServerNoContext
Function BankAccountSelectionOptions(ForeignCurrencyTransaction, Organization)

	ParametersArray = New Array;
	
	If Not ForeignCurrencyTransaction Then
		ParametersArray.Add(New ChoiceParameter("Filter.CashCurrency",
					SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization)));
	Else
		ParametersArray.Add(New ChoiceParameter("Filter.CashCurrency", New FixedArray(ForeignCurrencies(Organization))));
	EndIf;
	
	ParametersArray.Add(New ChoiceParameter("SelectingAccountsOfParentCompany", Undefined));
	ParametersArray.Add(New ChoiceParameter("Filter.Closed", False));
	
	Return New FixedArray(ParametersArray);
	
EndFunction

&AtServerNoContext
Function ForeignCurrencies(Organization)
	
	Query = New Query("
	|SELECT
	|	Currencies.Ref AS Ref
	|FROM
	|	Catalog.Currencies AS Currencies
	|WHERE
	|	Currencies.Ref <> &LocalAccountingCurrency
	|");
	Query.SetParameter("LocalAccountingCurrency", 
					SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization));
	
	Return Query.Execute().Unload().UnloadColumn("Ref");
	
EndFunction

&AtServerNoContext
Function BankAccountCorrespondsToPaymentProcedure(BankAccount, ForeignCurrencyTransaction, Organization)

	Respond = True;
	
	If ValueIsFilled(BankAccount) Then
		
		AccountCurrency = Common.ObjectAttributeValue(BankAccount, "CashCurrency");
		LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
		
		If ForeignCurrencyTransaction Then
			Respond = AccountCurrency <> LocalAccountingCurrency;
		Else
			Respond = AccountCurrency = LocalAccountingCurrency;
		EndIf;
		
	EndIf;
	
	Return Respond;
	
EndFunction

&AtServerNoContext
Procedure FillInOrganizationSDefaultBankAccount(Organization, ForeignCurrencyTransaction, BankAccount)
	
	If ValueIsFilled(BankAccount)
	 Or Not ValueIsFilled(Organization) Then
		Return;
	EndIf;
	
	ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(Organization);
	ParametersOfAccount.ExcludeCurrencyAccounts = ForeignCurrencyTransaction;
	ParametersOfAccount.Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	
	BankAccount = Catalogs.CompaniesBankAccounts.GetDefaultBankAccount(ParametersOfAccount);
	
EndProcedure

&AtServerNoContext
Procedure FillInCounterpartySDefaultBankAccount(Counterparty, ForeignCurrencyTransaction, CounterpartyBankAccount, Organization)
	
	If (ValueIsFilled(CounterpartyBankAccount)
		And Counterparty = Common.ObjectAttributeValue(CounterpartyBankAccount,"Owner")) Then
		Return;
	ElsIf Not ValueIsFilled(Counterparty) Then
		CounterpartyBankAccount = Catalogs.CounterpartyBankAccounts.EmptyRef();
		Return;
	EndIf;
	
	ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	
	CounterpartyBankAccount = Catalogs.CounterpartyBankAccounts.GetDefaultBankAccount(
		Counterparty, ComplCurrency, , ForeignCurrencyTransaction);
	
EndProcedure

&AtServer
Procedure RefreshFormTitle()
	
	If Not ValueIsFilled(Object.Ref) Then
		ThisForm.Title = "";
		ThisForm.AutoTitle = True;
	Else
		ThisForm.AutoTitle = False;
		ThisForm.Title = Object.Description;
		If ValueIsFilled(Object.ContractType) Then
			ThisForm.Title = Object.Description + " (" + Object.ContractType + ")";
		EndIf; 
	EndIf;
	
	PartnersAndCounterparties.TitleOfPartnerElementDependingOnBusinessOperation(
		ThisObject, "Partner", Object.BusinessOperation);
	PartnersAndCounterparties.HeaderOfCounterpartySAccountElementDependingOnBusinessOperation(
		ThisObject, "CounterpartyBankAccount", Object.BusinessOperation);
	
EndProcedure

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure

&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisForm);
	
EndProcedure

&AtClientAtServerNoContext
Procedure EstablishVisibilityOfDebtControl(Form)
	
	ArrayOfElementNames = New Array;
	ArrayOfElementNames.Add("LimitDebtAmount");
	ArrayOfElementNames.Add("AllowableAmountPayable");
	ArrayOfElementNames.Add("TheInscriptionIsTheCurrencyOfMutualSettlements");
	ArrayOfElementNames.Add("ShipmentIsProhibitedInCaseOfARAPOverdue");
	ArrayOfElementNames.Add("DebtControlGroup");
	TMCommonUseClientServer.SetPropertyOfFormElements(
		Form.Items,
		ArrayOfElementNames,
		"Visible",
		Form.Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.SaleToCustomer"));
	
	TMCommonUseClientServer.SetFormItemProperty(
		Form.Items,
		"AllowableAmountPayable",
		"Enabled",
		Form.Object.LimitDebtAmount);
	
EndProcedure

&AtServer
Procedure ConfigureListForSelectingOrderOfCalculations()
	
	ProcurementOperations = PurchasesServer.BusinessOperationsOnMain(Enums.BusinessTransactions.PurchaseFromSupplier);
	ImportOperations = PurchasesServer.BusinessOperationsOnMain(Enums.BusinessTransactions.PurchaseByImport);
	OperationsInEAEUCountries = PurchasesServer.BusinessOperationsOnMain(Enums.BusinessTransactions.ImportFromEAEU);
	ThisIsNewCommission = ?(ValueIsFilled(Object.Ref), Object.ConsignmentSales25, OnlyConsignmentSales25
		Or Object.ConsignmentSales25);
	
	ChoiceList = Items.ARAPObjectSettings.ChoiceList;
	ChoiceList.Clear();
	
	ChoiceList.Add(Enums.ARAPObjectSettings.ByCounterpartyContracts);
	
	If (Object.BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent And (Not ThisIsNewCommission
		Or Not Object.ConductARAPAccountingThroughEndCustomers))
		Or Object.BusinessOperation = Enums.BusinessTransactions.ConsignmentProcurement Then
			
		If Object.BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent
			And ThisIsNewCommission Then
			ChoiceList.Add(Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice, NStr("vi = 'Ứng trước theo hợp đồng, công nợ theo hóa đơn (chỉ giao hàng)';
																								|ru = 'Аванс по договорам, долг по накладным (только реализация)';
																								|en = 'Invoice for debt, Contract for prepayment (sales only)'; fa = 'Invoice for debt, Contract for prepayment (sales only)';
																								|it = 'Anticipo da accordi, debito su fatture (solo vendita)';
																								|pl = 'Zaliczka z tytułu kontraktów, dług z tytułu faktur (tylko sprzedaż)';
																								|tr = 'Sözleşme avansı, irsaliye borcu (sadece satışlar)'"));
			ChoiceList.Add(Enums.ARAPObjectSettings.ByOrders, NStr("vi = 'Theo bảng kê của người nhận ký gửi/bán hàng thông qua người nhận ký gửi';
																	|ru = 'По отчетам комиссионера/реализациям через комиссионера';
																	|en = 'By consignment issue notifications/sales via consignee'; fa = 'By consignment issue notifications/sales via consignee';
																	|it = 'Per report di commissionario/vendite tramite commissionario';
																	|pl = 'Według raportów komisanta/sprzedaży przez komisanta';
																	|tr = 'Komisyon acentesi raporları / komisyon acentesi aracılığıyla gerçekleşen satışlar'"));
		Else
			ChoiceList.Add(Enums.ARAPObjectSettings.ByOrders, NStr("vi = 'Theo bảng kê ký gửi';
																	|ru = 'По отчетам по комиссии';
																	|en = 'By commission reports'; fa = 'By commission reports';
																	|it = 'Secondo i report sulla commissione';
																	|pl = 'Wg raportów komisowych';
																	|tr = 'Komisyon raporlarına göre'"));
		EndIf;
		
		If ChoiceList.FindByValue(Object.ARAPObjectSettings) = Undefined Then
			Object.ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts;
		EndIf;
		
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent
		And ThisIsNewCommission And Object.ConductARAPAccountingThroughEndCustomers Then
		
		ChoiceList.Add(Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice, NStr("vi = 'Ứng trước theo hợp đồng, công nợ theo hóa đơn (chỉ giao hàng)';
																							|ru = 'Аванс по договорам, долг по накладным (только реализация)';
																							|en = 'Invoice for debt, Contract for prepayment (sales only)'; fa = 'Invoice for debt, Contract for prepayment (sales only)';
																							|it = 'Anticipo da accordi, debito su fatture (solo vendita)';
																							|pl = 'Zaliczka z tytułu kontraktów, dług z tytułu faktur (tylko sprzedaż)';
																							|tr = 'Sözleşme avansı, irsaliye borcu (sadece satışlar)'"));

		If ChoiceList.FindByValue(Object.ARAPObjectSettings) = Undefined Then
			Object.ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts;
		EndIf;
		
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.SaleToCustomer
		And Not GetFunctionalOption("UseSalesOrders") Then
		ChoiceList.Add(Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice);
		ChoiceList.Add(Enums.ARAPObjectSettings.ByARAPDocuments);
	ElsIf (ProcurementOperations.Find(Object.BusinessOperation) <> Undefined
		Or ImportOperations.Find(Object.BusinessOperation) <> Undefined
		Or OperationsInEAEUCountries.Find(Object.BusinessOperation) <> Undefined)
		And Not GetFunctionalOption("UsePurchaseOrders") Then
		
		ChoiceList.Add(Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice);
		ChoiceList.Add(Enums.ARAPObjectSettings.ByARAPDocuments);
		
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale
		Or Object.BusinessOperation = Enums.BusinessTransactions.TransferToStorageWithRightOfSale Then
		
		If Object.BusinessOperation = Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale Then
			ChoiceList.Add(Enums.ARAPObjectSettings.ByOrders,
									NStr("vi = 'Theo chứng từ mua lại và ghi giảm hàng hóa từ kho';
										|ru = 'По документам выкупа и списания товаров с хранения';
										|en = 'By purchase invoices — VMI and VMI adjustments'; fa = 'By purchase invoices — VMI and VMI adjustments';
										|it = 'Secondo i documenti di riscatto e cancellazione delle merci dallo stoccaggio';
										|pl = 'Zgodnie z dokumentami wykupu i umorzenia towarów z magazynu';
										|tr = 'Depodaki malların itfası ve gider yazılması hakkında'"));
		Else
			ChoiceList.Add(Enums.ARAPObjectSettings.ByOrders,
									NStr("vi = 'Theo chứng từ mua lại hàng hóa';
										|ru = 'По документам выкупа товаров хранителем';
										|en = 'According to ""Sales invoice — VMI sold"" documents'; fa = 'According to ""Sales invoice — VMI sold"" documents';
										|it = 'Secondo i documenti di riscatto delle merci da parte del custode';
										|pl = 'Zgodnie z dokumentami zakupu towarów przez powiernika';
										|tr = 'Уmanetçiye mal itfa belgesine ilişkin'"));
		EndIf;
		
		If Object.ARAPObjectSettings = Enums.ARAPObjectSettings.ByARAPDocuments Then
			Object.ARAPObjectSettings = Enums.ARAPObjectSettings.ByOrders;
		EndIf;
		
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.DeliveryForPrincipal Then
		
		ChoiceList.Add(Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice);
		ChoiceList.Add(Enums.ARAPObjectSettings.ByARAPDocuments);
		If Constants.OptionOfGoodsAssignmentInSales.Get() = Enums.OptionsOfGoodsAssignmentInSales.SalesOrder Then
			ChoiceList.Add(Enums.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice);
			ChoiceList.Add(Enums.ARAPObjectSettings.ByOrders);
		EndIf;
		
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgent Then
		
		ChoiceList.Add(Enums.ARAPObjectSettings.ByOrders, NStr("vi = 'Theo bảng kê của người nhận ký gửi/bán hàng thông qua người nhận ký gửi';
																|ru = 'По отчетам комиссионера/реализациям через комиссионера';
																|en = 'By consignment issue notifications/sales via consignee'; fa = 'By consignment issue notifications/sales via consignee';
																|it = 'Per report di commissionario/vendite tramite commissionario';
																|pl = 'Według raportów komisanta/sprzedaży przez komisanta';
																|tr = 'Komisyon acentesi raporları / komisyon acentesi aracılığıyla gerçekleşen satışlar'"));
		ChoiceList.Add(Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice);
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.TollManufacturing2_5 Then
		
		If GetFunctionalOption("UseMaterialProviderOrder2_5") Then
			ChoiceList.Add(Enums.ARAPObjectSettings.ByOrders);
			ChoiceList.Add(Enums.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice);
		EndIf;
		
		ChoiceList.Add(Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice);
		ChoiceList.Add(Enums.ARAPObjectSettings.ByARAPDocuments);
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.RenderRentalServices Then
		ChoiceList.Add(Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice);
		ChoiceList.Add(Enums.ARAPObjectSettings.ByARAPDocuments);
	Else
		ChoiceList.Add(Enums.ARAPObjectSettings.ByOrders);
		ChoiceList.Add(Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice);
		ChoiceList.Add(Enums.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice);
		ChoiceList.Add(Enums.ARAPObjectSettings.ByARAPDocuments);
	EndIf;
	
	If ChoiceList.FindByValue(Object.ARAPObjectSettings) = Undefined Then
		Object.ARAPObjectSettings = ChoiceList[0].Value;
	EndIf;
	
EndProcedure

&AtServer
Procedure ConfigureParametersForSelectingCashFlowItem()
	
	TypesOfContractsBuyer = New Array;
	TypesOfContractsBuyer.Add(Enums.ContractTypes.WithCustomer);
	TypesOfContractsBuyer.Add(Enums.ContractTypes.WithConsignee);
	TypesOfContractsBuyer.Add(Enums.ContractTypes.ReceiptForTolling2_5);
	TypesOfContractsBuyer.Add(Enums.ContractTypes.TransferToCustody);
	
	TypesOfContractsSupplier = New Array;
	TypesOfContractsSupplier.Add(Enums.ContractTypes.WithVendor);
	TypesOfContractsSupplier.Add(Enums.ContractTypes.WithConsignor);
	TypesOfContractsSupplier.Add(Enums.ContractTypes.TransferToTolling2_5);
	TypesOfContractsSupplier.Add(Enums.ContractTypes.SubcontractingToTheEAEUCountries);
	TypesOfContractsSupplier.Add(Enums.ContractTypes.Import);
	TypesOfContractsSupplier.Add(Enums.ContractTypes.PurchaseEAEU);
	TypesOfContractsSupplier.Add(Enums.ContractTypes.ReceivingForCustody);
	
	ChoiceParametersArray = New Array;
	
	If TypesOfContractsBuyer.Find(Object.ContractType) <> Undefined Then
		ChoiceParameter = New ChoiceParameter("Filter.BusinessOperation", Enums.BusinessTransactions.CashReceiptFromCustomer);
		ChoiceParametersArray.Add(ChoiceParameter);
	Else
		
		BusinessTransactionList = New Array;
		
		If TypesOfContractsSupplier.Find(Object.ContractType) <> Undefined Then
			BusinessTransactionList.Add(Enums.BusinessTransactions.PaymentToVendor);
		EndIf;
		
		CashServer.AddListOfBusinessOperationsToSelectionParameters(
			ChoiceParametersArray, BusinessTransactionList);
		
	EndIf;
	
	Items.CashFlowItem.ChoiceParameters = New FixedArray(ChoiceParametersArray);
	
EndProcedure

&AtServer
Procedure SetPropertiesOfElementsOfTaxationAndSeparateVATAccounting()
	
	Items.AgencyAgreementKind.Visible = Object.ContractType = Enums.ContractTypes.WithVendor;
	
	Items.VATTaxation.Enabled     = Not Object.VATTaxationIsDeterminedInDocuments;
	Items.PurchaseForActivity.Enabled = Not Object.PurchaseForActivityIsDeterminedInDocument;
	Items.AgencyAgreementKind.Enabled = (Object.VATTaxation = Enums.VATTaxationTypes.VATTaxAgent);
	Items.VATRate.Enabled = Object.VATTaxationIsDeterminedInDocuments 
									Or (Object.VATTaxation = Enums.VATTaxationTypes.SaleIsSubjectToVAT)
									Or (Object.VATTaxation = Enums.VATTaxationTypes.PreferentialVATTaxationOnSTS);
	
	Items.SeparateVATAccountingGroup.Visible = 
		(Object.ContractType = Enums.ContractTypes.WithVendor
		Or Object.ContractType = Enums.ContractTypes.PurchaseEAEU
		Or Object.ContractType = Enums.ContractTypes.Import
		Or Object.ContractType = Enums.ContractTypes.TransferToTolling2_5
		Or Object.ContractType = Enums.ContractTypes.SubcontractingToTheEAEUCountries
		Or Object.ContractType = Enums.ContractTypes.ReceivingForCustody);
		
	Items.GroupTaxationOfVAT.Visible = 
		Not (Object.ContractType = Enums.ContractTypes.EmptyRef()
			Or Object.ContractType = Enums.ContractTypes.Import
			Or Object.ContractType = Enums.ContractTypes.SubcontractingToTheEAEUCountries
			Or Object.ContractType = Enums.ContractTypes.PurchaseEAEU
			Or Object.ContractType = Enums.ContractTypes.SalesViaCommissionAgent
			Or (Object.ContractType = Enums.ContractTypes.WithVendor
			And Object.ContractWithSelfEmployedPerson));
	
	Items.LocalizationGroupFillingInSection7.Visible = GetFunctionalOption("UseVATDeclarationSection7Filling");
	
EndProcedure

&AtServer
Procedure EstablishVisibilityOfBusinessDirection()
	
	Visible = False;
	If ValueIsFilled(Object.ContractType) Then
		
		If LinesOfBusinessServer.EconomicOperationGeneratesIncome(Object.BusinessOperation) 
			And GetFunctionalOption("UseIncomeAccountingByLinesOfBusiness") Then
			
			Visible = True;
			
		ElsIf LinesOfBusinessServer.BusinessTransactionFormsAsset(Object.BusinessOperation)
			And GetFunctionalOption("UseCostAccountingByLinesOfBusiness") Then
			Visible = True;
			
		EndIf;
		
	EndIf;
	
	Items.LineOfBusiness.Visible = Visible;
	
EndProcedure

&AtServer
Procedure ItemManagementExecutionSchedule()
	
	ContractTypes = New Array;
	ContractTypes.Add(Enums.ContractTypes.WithCustomer);
	ContractTypes.Add(Enums.ContractTypes.WithVendor);
	ContractTypes.Add(Enums.ContractTypes.TransferToTolling2_5);
	ContractTypes.Add(Enums.ContractTypes.SubcontractingToTheEAEUCountries);
	ContractTypes.Add(Enums.ContractTypes.Import);
	ContractTypes.Add(Enums.ContractTypes.PurchaseEAEU);
	
	ThisIsContractWithClient =
		Object.ContractType = Enums.ContractTypes.WithCustomer
		Or Object.ContractType = Enums.ContractTypes.ReceiptForTolling2_5
		Or False;
	
	ChartVisibility = (ContractTypes.Find(Object.ContractType) <> Undefined)
		And (Object.ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts
			Or Object.ARAPObjectSettings = Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice)
		And Not (GetFunctionalOption("UseSimplifiedPaymentSchemeInSales")
				And ThisIsContractWithClient)
		And Not (GetFunctionalOption("UseSimplifiedPaymentSchemeInPurchasing")
				And Not ThisIsContractWithClient);
	
	DependentElements = New Array;
	DependentElements.Add(Items.OptionOfDeterminingExecutionScheduleInContract);
	DependentElements.Add(Items.LabelExecutionSchedule);
	
	For Each DependentElement In DependentElements Do
		DependentElement.Visible = ChartVisibility;
	EndDo;
	Items.Sum.Enabled = FixedContractAmount;
	Items.Sum.AutoMarkIncomplete = FixedContractAmount;
	
	OptionContract = Enums.OptionsForDeterminingExecutionScheduleInContract.Contract;
	
	Items.LabelExecutionSchedule.Visible = Items.LabelExecutionSchedule.Visible
		And (Object.OptionOfDeterminingExecutionScheduleInContract = OptionContract);
	
	Items.FixedContractAmount.Title = ?(Object.OptionOfDeterminingExecutionScheduleInContract = OptionContract,
		NStr("vi = 'Đã ấn định số tiền trong hợp đồng';
			|ru = 'Сумма договора фиксирована';
			|en = 'Contract amount is fixed'; fa = 'مبلغ قرارداد ثابت است';
			|it = 'L''importo del contratto è fisso';
			|pl = 'Wartość umowy zatwierdzona';
			|tr = 'Sözleşme tutarı sabitlendi'"), NStr("vi = 'Số tiền hợp đồng (để tham khảo)';
														|ru = 'Сумма договора (справочно)';
														|en = 'Contract amount (for information)'; fa = 'Contract amount (for information)';
														|it = 'Contract amount (for information)';
														|pl = 'Contract amount (for information)';
														|tr = 'Sözleşme tutarı (referans)'"));
	
	LabelExecutionSchedule = Documents.ContractSchedule.GraphView(Object.ContractSchedule);
	
EndProcedure

&AtServer
Procedure ChangedPaymentServer(EventName, Parameter)
	
	ARAPAccountingFormWork.NotificationProcessing(ThisForm, EventName, Parameter);
	
EndProcedure

&AtServer
Procedure ChangingExecutionScheduleOnServer()
	
	Write();
	ItemManagementExecutionSchedule();
	
EndProcedure

&AtServer
Procedure OrganizationOnChangeServer()
	
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	
	ProcessBankAccounts();
	
	GeneralTaxationAndTypeOfActivity();
	VATTaxationOnChangeServer();
	ParentCompany = Object.Organization = Common.ObjectAttributeValue(Object.Organization, "ParentCompany");
	Object.BranchOffices_.Clear();
	EstablishVisibilityOfCentralizedContract();
	SetDefaultContractWithCommissionAgent();
	SetValuesForDiscountingDetails();
	ManagingDiscountItems();
	VATTaxationOnChangeServer();
	SetVisibilityOfPaymentInCurrency();
	
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	CheckContractCurrencyExchangeRate();
	If Object.ARAPCurrency = LocalAccountingCurrency Then
		Object.ContractRateOption = Enums.ContractRateOptions.Mutable;
	EndIf;
	ElementManagementIsVariantOfContractCourse();
	
	AtEndOfChangingLocalizationDetailsOnServer("Organization", Undefined);
	
EndProcedure

&AtServer
Procedure MakePaymentsThroughEndCustomersOnChangesAtServer()
	
	ThisIsContractWithCommissionAgent = ?(Object.ContractType = PredefinedValue("Enum.ContractTypes.WithConsignee"),
		True, False);
		
	ThisIsNewCommission = ThisIsContractWithCommissionAgent
		And ?(ValueIsFilled(Object.Ref), Object.ConsignmentSales25, OnlyConsignmentSales25
		Or Object.ConsignmentSales25);
		
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, "GroupOfFinancialARAPAccountingWithEndCustomer",
		"Visible", ThisIsNewCommission And Object.ConductARAPAccountingThroughEndCustomers);
	
	ConfigureListForSelectingOrderOfCalculations();
	ARAPAccountingFormWork.WhenChangingParametersOfMechanism(ThisObject);
	
	ElementManagementIsVariantOfContractCourse();
	
EndProcedure

&AtServer
Procedure ValidityEndDateOnChangeServer()
	
	GeneralTaxationAndTypeOfActivity();
	VATTaxationOnChangeServer();
	
EndProcedure

&AtServer
Procedure EstablishDebtClassification(DebtClassification)
	
	If DebtClassification = 1 Then
		Object.PaymentDueDateIsSet = True;
		Object.PaymentDueDate = 366; // The value is greater than 365 calendar days
	Else
		Object.PaymentDueDateIsSet = False;
		Object.PaymentDueDate = 0;
	EndIf;
	ThisForm.Modified = True;
	
EndProcedure

&AtServer
Procedure SetVisibilityOfSeparatePurchaseOptions()
	
	ContractIsAvailableForTwoWayPurchases			= Object.ContractType = Enums.ContractTypes.Import
														Or Object.ContractType = Enums.ContractTypes.PurchaseEAEU
														Or Object.ContractType = Enums.ContractTypes.WithVendor;
	SeparatePurchaseRegistrationIsAvailable				= UseGoodsInTransitFromVendors
														Or UseUninvoicedDeliveries;
	UseSeparatePurchaseRegistrationOptions	= UseGoodsInTransitFromVendors
														And UseUninvoicedDeliveries;
														
	VisibilityOfPurchaseParameters = ContractIsAvailableForTwoWayPurchases And SeparatePurchaseRegistrationIsAvailable;
														
	Items.GroupOptionForPurchasingGoods.Visible = VisibilityOfPurchaseParameters;
	Items.GroupOptionForPurchasingServices.Visible 	 = VisibilityOfPurchaseParameters And UseUninvoicedDeliveries;
	Items.MonthlyReceiptOfServices.Visible 		     = VisibilityOfPurchaseParameters And UseUninvoicedDeliveries;
	
	If Not UseSeparatePurchaseRegistrationOptions Then
		FillInListOfOptionsForMakingPurchasesForGoodsOnWay();
	EndIf;
	
	VisibilityOfAcceptanceOptions = UsePurchaseDesign() 
		And (UseWarehouseManagemantSystemForGoodsReceipt Or SeparatePurchaseRegistrationIsAvailable);
	
	Items.GroupAcceptanceOptions.Visible = VisibilityOfAcceptanceOptions;
	Items.GroupOptionForMakingASeparatePurchase.ShowTitle = VisibilityOfPurchaseParameters;
	Items.GroupAcceptanceOptions.ShowTitle = Not VisibilityOfPurchaseParameters And VisibilityOfAcceptanceOptions;
	
EndProcedure

&AtServer
Procedure FillInListOfOptionsForMakingPurchasesForGoodsOnWay()
	
	If UseGoodsInTransitFromVendors Then
		FoundItem = Items.PurchaseRegistrationOption.ChoiceList.FindByValue(
			Enums.PurchaseRegistrationOptions.UninvoicedDeliveriesOfGoodsAndServices);
	ElsIf UseUninvoicedDeliveries Then 
		FoundItem = Items.PurchaseRegistrationOption.ChoiceList.FindByValue(
			Enums.PurchaseRegistrationOptions.GoodsInTransit);
	EndIf;
	
	If FoundItem <> Undefined Then
		Items.PurchaseRegistrationOption.ChoiceList.Delete(FoundItem);
	EndIf;
	
EndProcedure

&AtServer
Procedure InitializeProcurementOption()
	
	If Object.PurchaseRegistrationOption = Enums.PurchaseRegistrationOptions.NotSeparate Then
		UsePaperworkForSeparatePurchasesOfGoods = False;
	Else
		UsePaperworkForSeparatePurchasesOfGoods = True;
	EndIf;
	
EndProcedure

&AtServer
Procedure UsePaperworkForSeparatePurchasesOfGoodsOnChangeServer()
	
	InitializeListOfOptionsForSelectingOptionForPurchasingGoods();
	SetAvailabilityPurchasingOption();
	SetAcceptanceAvailability();
	
	AtEndOfChangingLocalizationDetailsOnServer("UsePaperworkForSeparatePurchasesOfGoods", Undefined);
	
EndProcedure

&AtServer
Procedure UsePaperworkForSeparateProcurementOfServicesOnChangeServer()
	
	InitializeListOfOptionsForPurchasingWorksAndServices();
	SetAvailabilityOptionForProcessingDocumentsForServices(False);
	
	SetAvailabilityMonthlyReceiptOfServices();
	
	AtEndOfChangingLocalizationDetailsOnServer("UsePaperworkForSeparateProcurementOfServices", Undefined);
	
EndProcedure

&AtServer
Procedure PurchaseRegistrationOptionOnChangeServer()
	
	SetAvailabilityMonthlyReceiptOfServices();
	
	WhenChangingAcceptanceSettingsServer();
	SetAvailabilityRegistrationOfReceiptOfServices();
	
	AtEndOfChangingLocalizationDetailsOnServer("PurchaseRegistrationOption", Undefined);
	
EndProcedure

&AtServer
Procedure InitializeListOfOptionsForSelectingOptionForPurchasingGoods()

	If UsePaperworkForSeparatePurchasesOfGoods Then
		If Not Items.PurchaseRegistrationOption.ChoiceList.Count() = 0 Then
			ListItem = Items.PurchaseRegistrationOption.ChoiceList.Get(0);
			
			If ListItem.Value = Enums.PurchaseRegistrationOptions.NotSeparate Then
				Items.PurchaseRegistrationOption.ChoiceList.Delete(ListItem);
			EndIf;
		EndIf;
	Else
		If Not Items.PurchaseRegistrationOption.ChoiceList.Count() = 0 Then
			ListItem = Items.PurchaseRegistrationOption.ChoiceList.Get(0);
			
			If Not ListItem.Value = Enums.PurchaseRegistrationOptions.NotSeparate Then
				Items.PurchaseRegistrationOption.ChoiceList.Insert(0, 
					Enums.PurchaseRegistrationOptions.NotSeparate, " ");
			EndIf;
		EndIf;
	EndIf;
	
	PurchasesServer.FillInListOfContractAcceptanceOptions(Items.RegisterReceipt,
																	Items.GoodsReceipt,
																	Object.PurchaseRegistrationOption);

EndProcedure

&AtServer
Procedure SetServiceAcceptanceParameters(EstablishAcceptanceOfServices = True)
	
	UsePaperworkForSeparateProcurementOfServices = ValueIsFilled(Object.OptionForRegisteringServiceReceiptDocuments) 
		And Not Object.OptionForRegisteringServiceReceiptDocuments = Enums.OptionsForRegisteringServiceDocuments.ReceiptOfServicesNotUsed;
	
	If UsePaperworkForSeparateProcurementOfServices And RegistrationOfReceiptOfServices <> "ByContract" Then
		Items.AcceptanceOfServices.Enabled = True; 
		
	Else
		Items.AcceptanceOfServices.Enabled = False;
		If Items.AcceptanceOfServices.Visible And Not RegistrationOfReceiptOfServices = "ByContract" Then
			AcceptanceOfServices = "Divided"; 
		ElsIf Items.AcceptanceOfServices.Visible And RegistrationOfReceiptOfServices = "ByContract" Then
			AcceptanceOfServices = "NotDivided";
			If Not Object.Ref.IsEmpty() And EstablishAcceptanceOfServices Then
				AcceptanceOfServices = "NotDivided";
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure OnChangingServiceAcceptanceSettingsServer(EstablishAcceptanceOfServices = True)

	PurchasesServer.FillInListOfOptionsForAcceptingServicesUnderContracts(Items.RegistrationOfReceiptOfServices,
																	Items.AcceptanceOfServices,
																	Object.OptionForRegisteringServiceReceiptDocuments);
	
	If Items.RegistrationOfReceiptOfServices.ChoiceList.Count() = 1 Then
		RegistrationOfReceiptOfServices = Items.RegistrationOfReceiptOfServices.ChoiceList[0].Value;
	EndIf;
	
	Object.ServiceReceiptOption = PurchasesServer.GetOptionsForAcceptanceBySettings(RegistrationOfReceiptOfServices, AcceptanceOfServices);
	
	If Object.PurchaseRegistrationOption = Enums.PurchaseRegistrationOptions.UninvoicedDeliveriesOfGoods
		And (Object.ServiceReceiptOption = Enums.GoodsReceiptOptions.ByContractsAfterInvoices
			Or Object.ServiceReceiptOption = Enums.GoodsReceiptOptions.SplitByInvoicesOnly) Then
		
		If Object.ServiceReceiptOption = Enums.GoodsReceiptOptions.ByContractsAfterInvoices Then
			Object.ServiceReceiptOption = Enums.GoodsReceiptOptions.ByContractsAfterOrdersOrInvoices;
		ElsIf Object.ServiceReceiptOption = Enums.GoodsReceiptOptions.SplitByInvoicesOnly Then
			Object.ServiceReceiptOption = Enums.GoodsReceiptOptions.DividedByOrdersAndInvoices;
		EndIf;
		
		PurchasesServer.FillInAcceptanceOptionsSettings(Object.ServiceReceiptOption, RegistrationOfReceiptOfServices, AcceptanceOfServices);
		
	EndIf;
	
	If Items.RegistrationOfReceiptOfServices.ChoiceList.FindByValue(RegistrationOfReceiptOfServices) = Undefined Then
		RegistrationOfReceiptOfServices = "";
	EndIf;
	
	SetServiceAcceptanceParameters(EstablishAcceptanceOfServices);	

EndProcedure

&AtServer
Procedure InitializeListOfOptionsForPurchasingWorksAndServices()

	If UsePaperworkForSeparateProcurementOfServices Then
		If Not Items.OptionForRegisteringServiceReceiptDocuments.ChoiceList.Count() = 0 Then
			ListItem = Items.OptionForRegisteringServiceReceiptDocuments.ChoiceList.Get(0);
			
			If ListItem.Value = Enums.OptionsForRegisteringServiceDocuments.ReceiptOfServicesNotUsed Then
				Items.OptionForRegisteringServiceReceiptDocuments.ChoiceList.Delete(ListItem);
			EndIf;
		EndIf;
	Else
		If Not Items.OptionForRegisteringServiceReceiptDocuments.ChoiceList.Count() = 0 Then
			ListItem = Items.OptionForRegisteringServiceReceiptDocuments.ChoiceList.Get(0);
			
			If Not ListItem.Value = Enums.OptionsForRegisteringServiceDocuments.ReceiptOfServicesNotUsed Then
				Items.OptionForRegisteringServiceReceiptDocuments.ChoiceList.Insert(0, 
					Enums.OptionsForRegisteringServiceDocuments.ReceiptOfServicesNotUsed, " ");
			EndIf;
		EndIf;
	EndIf;
		
EndProcedure

&AtServer
Procedure SetAcceptanceAvailability()
	
	If RegisterReceipt = "ByContract" Then
		Items.GoodsReceipt.Enabled = False;
		GoodsReceipt = "NotDivided";
	Else
		Items.GoodsReceipt.Enabled = True;
	EndIf;
	
EndProcedure

&AtServer
Procedure WhenChangingAcceptanceSettingsServer();
	
	PurchasesServer.FillInListOfContractAcceptanceOptions(Items.RegisterReceipt,
																	Items.GoodsReceipt,
																	Object.PurchaseRegistrationOption);
	
	If Items.RegisterReceipt.ChoiceList.Count() = 1 Then
		RegisterReceipt = Items.RegisterReceipt.ChoiceList[0].Value;
	EndIf;
	
	Object.GoodsReceiptOption = PurchasesServer.GetOptionsForAcceptanceBySettings(RegisterReceipt, GoodsReceipt);
	
	If Object.PurchaseRegistrationOption = Enums.PurchaseRegistrationOptions.UninvoicedDeliveriesOfGoods
		And (Object.GoodsReceiptOption = Enums.GoodsReceiptOptions.ByContractsAfterInvoices
			Or Object.GoodsReceiptOption = Enums.GoodsReceiptOptions.SplitByInvoicesOnly) Then
		
		If Object.GoodsReceiptOption = Enums.GoodsReceiptOptions.ByContractsAfterInvoices Then
			Object.GoodsReceiptOption = Enums.GoodsReceiptOptions.ByContractsAfterOrdersOrInvoices;
		ElsIf Object.GoodsReceiptOption = Enums.GoodsReceiptOptions.SplitByInvoicesOnly Then
			Object.GoodsReceiptOption = Enums.GoodsReceiptOptions.DividedByOrdersAndInvoices;
		EndIf;
		
		PurchasesServer.FillInAcceptanceOptionsSettings(Object.GoodsReceiptOption, RegisterReceipt, GoodsReceipt);
		
	EndIf;
	
	If Object.DeliveryMethod = Enums.TransportMethods.DeterminedInReference
		And Catalogs.CounterpartyContracts.AgreementIsUsedDuringAcceptance(Object.GoodsReceiptOption) Then
		
		Object.DeliveryMethod = Enums.TransportMethods.EmptyRef();
		
		GoodsDelivery.WhenReadingCreatingOrdersOnServer(Items, Object);
		
	EndIf;
	
	If Items.RegisterReceipt.ChoiceList.FindByValue(RegisterReceipt) = Undefined Then
		RegisterReceipt = "";
	EndIf;
	
	SetAcceptanceAvailability();
	SetDeliveryAvailability();

EndProcedure

&AtServer
Procedure SetDeliveryAvailability()
	
	ThisIsContractOrderForAcceptance = Catalogs.CounterpartyContracts.AgreementIsUsedDuringAcceptance(Object.GoodsReceiptOption);
	
	AvailableShippingMethods = AvailableShippingMethods(ThisIsContractOrderForAcceptance);
	
	Items.DeliveryMethod.ChoiceList.LoadValues(AvailableShippingMethods);
	
EndProcedure

&AtServer
Function AvailableShippingMethods(ThisIsContractOrderForAcceptance)
	
	ReturnedArray = New Array();
	
	If Not ThisIsContractOrderForAcceptance Then
		ReturnedArray.Add(Enums.TransportMethods.DeterminedInReference);
	EndIf;
	
	ReturnedArray.Add(Enums.TransportMethods.ByVendorToOurWarehouse);
	ReturnedArray.Add(Enums.TransportMethods.ByCarrierToOurWarehouse);
	ReturnedArray.Add(Enums.TransportMethods.ByCarrierToTransferPoint);
	ReturnedArray.Add(Enums.TransportMethods.OurOwnDeliveryFromSenderAddress);
	ReturnedArray.Add(Enums.TransportMethods.FromSenderDeterminedByDeliveryService);
	
	Return ReturnedArray;
	
EndFunction

&AtServer
Function UsePurchaseDesign()
	
	UsePurchaseDesign = Object.ContractType = Enums.ContractTypes.WithVendor
		Or Object.ContractType = Enums.ContractTypes.PurchaseEAEU
		Or Object.ContractType = Enums.ContractTypes.Import
		Or Object.ContractType = Enums.ContractTypes.ReceivingForCustody;
	
	Return UsePurchaseDesign;
	
EndFunction

&AtClientAtServerNoContext
Procedure SetVisibilityOrderOfDebitingAcceptedGoods(Form)
	
	Form.Items.RegistrationOfWriteOffOfInventoryShortageAcceptedForStorage.Visible = ?(
		Form.Object.ContractType = PredefinedValue("Enum.ContractTypes.ReceivingForCustody")
			Or Form.Object.ContractType = PredefinedValue("Enum.ContractTypes.ReceiptForTolling2_5")
			Or Form.Object.ContractType = PredefinedValue("Enum.ContractTypes.CustomerInvoiceOutsourcedSale"),
		True,
		False);
	Form.Items.RegistrationOfWriteOffOfGoodsAcceptedForStorageToProduction.Visible =
		?(Form.Object.ContractType = PredefinedValue("Enum.ContractTypes.ReceivingForCustody"),
		True,
		False);
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
Procedure SetTextOfHintOrderOfCreditingDocuments()
	ToolTipText = "";
	If Object.OffsetOrderOfPaymentsAndInvoices = PredefinedValue("Enum.OffsetOrdersOfPaymentsAndInvoices.ByDocumentDateAndType") Then
		ToolTipText = NStr("vi = 'Theo ngày và dạng chứng từ – các khoản thanh toán trả sau sẽ được phân bổ trước cho các hóa đơn có ngày kết chuyển chứng từ nhỏ nhất, các hóa đơn sẽ bù trừ các khoản tạm ứng có ngày kết chuyển chứng từ nhỏ nhất.
		|Các chứng từ trong ngày sẽ được tính theo dạng: thứ nhất, chuyển khoản tạm ứng và công nợ, hóa đơn,
		|trả lại hàng hóa và điều chỉnh hóa đơn, thanh toán, trả lại tiền, v.v.';
		|ru = 'По дате и виду документа – постоплаты будут сначала распределяться на накладные с минимальной датой проведения документа, накладные будут зачитывать авансы с минимальной датой документа.
		|Документы в пределах дня будут зачитываться по виду: сначала переносы авансов и задолженности, накладные,
		|возвраты товаров и корректировки накладных, оплаты, возвраты ДС и пр.';
		|en = 'By document date and kind: postpayments are first allocated to invoices with the earliest document posting date. Invoices offset prepayments with the earliest document date.
		|Documents within one day are offset by their kind: first, prepayment and debt offsets, invoices,
		|returns of goods and invoice adjustments, payments, refunds, and so on.'; fa = 'By document date and kind: postpayments are first allocated to invoices with the earliest document posting date. Invoices offset prepayments with the earliest document date.
		|Documents within one day are offset by their kind: first, prepayment and debt offsets, invoices,
		|returns of goods and invoice adjustments, payments, refunds, and so on.';
		|it = 'По дате и виду документа – постоплаты будут сначала распределяться на накладные с минимальной датой проведения документа, накладные будут зачитывать авансы с минимальной датой документа.
		|Документы в пределах дня будут зачитываться по виду: сначала переносы авансов и задолженности, накладные,
		|возвраты товаров и корректировки накладных, оплаты, возвраты ДС и пр.';
		|pl = 'By document date and kind: postpayments are first allocated to invoices with the earliest document posting date. Invoices offset prepayments with the earliest document date.
		|Documents within one day are offset by their kind: first, prepayment and debt offsets, invoices,
		|returns of goods and invoice adjustments, payments, refunds, and so on.';
		|tr = 'Belge tarihi ve saatine göre, ertelenmiş ödemeler ilk olarak minimum belge tarihine sahip faturalara tahsis edilecek, faturalar minimum belge tarihine sahip avanslardan mahsup edilecektir.
		|Ürünlerin iadesi ve faturalarda
		|yapılan ayarlamalar, ödemeler, iadeler vs., türü ve numarasına göre değerlendirilecektir.'");
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

&AtServer
Procedure SetSelectionListOfContractCourseOption()
	
	AvailableFixedOnDateOfShipment = AvailabilityOfFixedRateOnDateOfShipment();
	
	ChangeToSelectionListIsRequired = 
		Items.ContractRateOption.ChoiceList.Count() = 0
		Or (Items.ContractRateOption.ChoiceList.Count() = 2
			And AvailableFixedOnDateOfShipment)
		Or (Items.ContractRateOption.ChoiceList.Count() = 3
			And Not AvailableFixedOnDateOfShipment);
	
	If ChangeToSelectionListIsRequired Then
		Items.ContractRateOption.ChoiceList.Clear();
		Items.ContractRateOption.ChoiceList.Add(Enums.ContractRateOptions.Mutable);
		If AvailableFixedOnDateOfShipment Then
			Items.ContractRateOption.ChoiceList.Add(Enums.ContractRateOptions.FixedAsOfShipmentDate);
		EndIf;
		Items.ContractRateOption.ChoiceList.Add(Enums.ContractRateOptions.SpecifiedInContract);
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetVisibilityOfReportBreakdownForPrincipal(Form)
	
	Form.Items.SplitReportToPurchasingCommittee.Visible = ?(
		Form.Object.ContractType = PredefinedValue("Enum.ContractTypes.CustomerInvoiceOutsourcedSale") , True, False);
		
EndProcedure

&AtServer
Procedure SetVisibilityNewCommissionScheme()
	
	ThisIsContractWithCommissionAgent = ?(Object.ContractType = PredefinedValue("Enum.ContractTypes.WithConsignee"),
		True, False);
	ThisIsContractWithEndClient = ?(Object.ContractType = PredefinedValue("Enum.ContractTypes.SalesViaCommissionAgent"),
		True, False);
		
	ThisIsNewCommission = ThisIsContractWithCommissionAgent
		And ?(ValueIsFilled(Object.Ref), Object.ConsignmentSales25, OnlyConsignmentSales25
		Or Object.ConsignmentSales25);
		
	Items.GroupCommissionSale.Visible = ThisIsContractWithCommissionAgent;
	
	Items.CommissionScheme.Visible = ?(
		ThisIsContractWithCommissionAgent And SelectConsignmentSalesVersion
		And Not OnlyConsignmentSales25 And ToUseTermsOfSales, True, False);
		
	Items.GroupOfSettingsForCommissionSalePriceTypes.Visible = ThisIsNewCommission;
		
	Items.ConductARAPAccountingThroughEndCustomers.Visible = ThisIsNewCommission;
		
	Items.AccountingTypeOfPrices.Visible = ThisIsNewCommission;
	Items.SalesPriceType.Visible = ThisIsNewCommission;
		
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, 
		"LocalizationGroupOptionForDisposalOfMarkedProducts, ItIsAllowedToWorkWithSubsidiaryPartners",
			"Visible", Not ThisIsContractWithEndClient);
	Items.GroupPaymentProcedure.ReadOnly = ThisIsContractWithEndClient;
	
	Items.CashFlowItem.Visible = Not ThisIsContractWithEndClient;
	Items.LineOfBusiness.Visible = Not ThisIsContractWithEndClient;
	ChangingClientSFinancialAccountingGroup = ThisIsContractWithCommissionAgent Or (ThisIsContractWithEndClient
		And Object.ConductARAPAccountingThroughEndCustomers);
	Items.GroupOfFinancialARAPAccountingWithEndCustomer.ReadOnly = Not ChangingClientSFinancialAccountingGroup;
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, "BankAccount, CounterpartyBankAccount, ContactPerson, CreditPaymentForm",
			"Visible", Not ThisIsContractWithEndClient);
	
	Items.CommissionAgentGroup.Visible = ThisIsContractWithEndClient;
	
	If ThisIsNewCommission Then
		SetParametersForSelectingTypeOfPricesOnServer();
	EndIf;
	
	Items.CompanyGroup.Title = NStr("vi = 'Dữ liệu của doanh nghiệp';
									|ru = 'Данные организации';
									|en = 'Company data'; fa = 'Company data';
									|it = 'Dati azienda';
									|pl = 'Dane firmy';
									|tr = 'İş yeri verileri'");
	Items.CompanyGroup.ShowTitle = ThisIsContractWithEndClient;
	
	Items.PartnerCounterpartyGroup.Title = NStr("vi = 'Dữ liệu khách hàng';
												|ru = 'Данные клиента';
												|en = 'Customer data'; fa = 'داده‌های مشتری';
												|it = 'Dati cliente';
												|pl = 'Dane klienta';
												|tr = 'Müşteri verileri'");
	Items.PartnerCounterpartyGroup.ShowTitle = ThisIsContractWithEndClient;
	
	Items.FinancialAccountingGroup.Title = ?(ThisIsNewCommission, NStr("vi = 'Nhóm kế toán tài chính hạch toán với người nhận ký gửi';
																		|ru = 'Группа фин. учета расчетов с комиссионером';
																		|en = 'Group of financial AR/AP accounting with a consignee'; fa = 'Group of financial AR/AP accounting with a consignee';
																		|it = 'Gruppo contabilità fin. dei calcoli con il commissionario';
																		|pl = 'Grupa ewidencji finansowej rozliczeń z komisantem';
																		|tr = 'Konsinye ile alacak/borç muhasebesi grubu'"), "");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, "GroupOfFinancialARAPAccountingWithEndCustomer",
			"Visible", ThisIsNewCommission And Object.ConductARAPAccountingThroughEndCustomers);
	
	Items.GroupContractAmount.Visible = Not (Object.ContractType = Enums.ContractTypes.SalesViaCommissionAgent
		Or ThisIsNewCommission);
	
	ConfigureCommissionSchemeSelectionList();
	
	SetPropertiesOfOutdatedCommissionUsageComment();
	
EndProcedure

&AtServer
Procedure EstablishVisibilityOfGoodsQualityControl()
	
	ItemVisibility = False;
	If Object.ContractType = Enums.ContractTypes.WithVendor
		Or Object.ContractType = Enums.ContractTypes.TransferToTolling2_5
		Or Object.ContractType = Enums.ContractTypes.SubcontractingToTheEAEUCountries
		Or Object.ContractType = Enums.ContractTypes.ReceivingForCustody
		Or Object.ContractType = Enums.ContractTypes.WithConsignor
		Or Object.ContractType = Enums.ContractTypes.PurchaseEAEU
		Or Object.ContractType = Enums.ContractTypes.CustomerInvoiceOutsourcedSale
		Or Object.ContractType = Enums.ContractTypes.Import
		Or Object.ContractType = Enums.ContractTypes.WithConsignor
		Or Object.ContractType = Enums.ContractTypes.ReceiptForTolling2_5 Then
		ItemVisibility = True;
	EndIf;
	
	TMCommonUseClientServer.SetFormItemProperty(
		Items,
		"GoodsQualityIsGuaranteedByVendor",
		"Visible",
		ItemVisibility);
	
EndProcedure

&AtServer
Procedure SetHeadersForProductAcceptanceDetails()
	
	SeparatePurchaseRegistrationIsAvailable = UseGoodsInTransitFromVendors
											Or UseUninvoicedDeliveries;
	
	ProductAcceptanceHeader			= ?(SeparatePurchaseRegistrationIsAvailable,
										NStr("vi = 'Lập chứng từ tiếp nhận và nhập hàng vào kho';
											|ru = 'Оформление поступлений и приемки на склад';
											|en = 'Register goods receipts at the warehouse'; fa = 'Register goods receipts at the warehouse';
											|it = 'Оформление поступлений и приемки на склад';
											|pl = 'Register goods receipts at the warehouse';
											|tr = 'Depoya kabul ve teslim alım düzenlemesi'"),
										NStr("vi = 'Lập chứng từ tiếp nhận và nhập hàng vào kho hai pha';
											|ru = 'Оформление поступлений и приемки на ордерный склад';
											|en = 'Register goods receipts at the warehouse with warehouse management enabled'; fa = 'Register goods receipts at the warehouse with warehouse management enabled';
											|it = 'Оформление поступлений и приемки на ордерный склад';
											|pl = 'Register goods receipts at the warehouse with warehouse management enabled';
											|tr = 'Depoya kabul ve teslim alım düzenlemesi'"));
	
	TitleReceiptProcessing	= ?(SeparatePurchaseRegistrationIsAvailable,
										NStr("vi = 'Cho phép lập chứng từ tiếp nhận và phiếu kho';
											|ru = 'Оформление поступления и ордера доступно';
											|en = 'You can register the receipt and the order'; fa = 'You can register the receipt and the order';
											|it = 'Оформление поступления и ордера доступно';
											|pl = 'You can register the receipt and the order';
											|tr = 'Sipariş ve teslim alım düzenlemesi mevcuttur'"),
										NStr("vi = 'Cho phép lập phiếu';
											|ru = 'Оформление ордера доступно';
											|en = 'Goods receipt registration is available'; fa = 'ثبت دریافت کالا در دسترس است';
											|it = 'La registrazione del mandato è disponibile';
											|pl = 'Dostępne jest sporządzenie zlecenia';
											|tr = 'Sipariş düzenlemesi mevcuttur'"));
	
	HintRegistrationOfReceipt	= ?(SeparatePurchaseRegistrationIsAvailable,
										NStr("vi = 'Có thể lập phiếu nhập kho và tiếp nhận sau khi lập đơn hàng, 
												   |hoặc sau khi lập hóa đơn hoặc theo hợp đồng, chưa lập chứng từ nào.';
												   |ru = 'Оформление приходного ордера и поступления товаров может происходить после оформления заказа, 
												   |либо после оформления накладной или по договору, без оформления каких-либо документов.';
												   |en = 'You can register goods receipt or uninvoiced receipt after the order or the invoice is registered
												   |or under the contract without registering any documents.'; fa = 'You can register goods receipt or uninvoiced receipt after the order or the invoice is registered
												   |or under the contract without registering any documents.';
												   |it = 'Оформление приходного ордера и поступления товаров может происходить после оформления заказа, 
												   |либо после оформления накладной или по договору, без оформления каких-либо документов.';
												   |pl = 'You can register goods receipt or uninvoiced receipt after the order or the invoice is registered
												   |or under the contract without registering any documents.';
												   |tr = 'Ambar giriş fişi ve malların teslim alınması, siparişin verilmesinden sonra
												   | veya irsaliyenin düzenlenmesinden sonra ya da herhangi bir evrak işi olmaksızın düzenlenebilir.'"),
										NStr("vi = 'Có thể lập phiếu nhập kho sau khi lập đơn hàng,
												   |hoặc sau khi lập hóa đơn hoặc theo hợp đồng, chưa lập chứng từ nào.';
												   |ru = 'Оформление приходного ордера может происходить после оформления заказа,
												   |либо после оформления накладной или по договору, без оформления каких-либо документов.';
												   |en = 'You can register goods receipt after the order or the invoice is registered
												   |or under the contract without registering any documents.'; fa = 'You can register goods receipt after the order or the invoice is registered
												   |or under the contract without registering any documents.';
												   |it = 'Оформление приходного ордера может происходить после оформления заказа,
												   |либо после оформления накладной или по договору, без оформления каких-либо документов.';
												   |pl = 'You can register goods receipt after the order or the invoice is registered
												   |or under the contract without registering any documents.';
												   |tr = 'Ambar giriş fişi, siparişin verilmesinden sonra
												   | veya irsaliyenin düzenlenmesinden sonra ya da herhangi bir evrak işi olmaksızın düzenlenebilir.'"));
	ProductAcceptanceHint			= ?(SeparatePurchaseRegistrationIsAvailable,
										NStr("vi = 'Có thể gom nhóm nhập hàng vào kho theo hợp đồng,
												   |hoặc chia tách theo chứng từ.';
												   |ru = 'Приемку товаров на складе можно сгруппировать по договору,
												   |либо разделить по документам.';
												   |en = 'You can group the receipt of goods at warehouse by a contract
												   |or split it by documents.'; fa = 'You can group the receipt of goods at warehouse by a contract
												   |or split it by documents.';
												   |it = 'Приемку товаров на складе можно сгруппировать по договору,
												   |либо разделить по документам.';
												   |pl = 'You can group the receipt of goods at warehouse by a contract
												   |or split it by documents.';
												   |tr = 'Ambara mal girişi sözleşmeye göre gruplandırılabilir 
												   |veya belgelere göre ayrılabilir.'"),
										NStr("vi = 'Có thể gom nhóm nhập hàng vào kho hai pha theo hợp đồng,
												   |hoặc chia tách theo chứng từ.';
												   |ru = 'Приемку товаров на ордерном складе можно сгруппировать по договору,
												   |либо разделить по документам.';
												   |en = 'You can group the receipt of goods at warehouse (when warehouse management is enabled) by a contract
												   |or split it by documents.'; fa = 'You can group the receipt of goods at warehouse (when warehouse management is enabled) by a contract
												   |or split it by documents.';
												   |it = 'Приемку товаров на ордерном складе можно сгруппировать по договору,
												   |либо разделить по документам.';
												   |pl = 'You can group the receipt of goods at warehouse (when warehouse management is enabled) by a contract
												   |or split it by documents.';
												   |tr = 'Malların düzenli bir depoda girişi sözleşmeye göre gruplandırılabilir 
												   |veya belgeye göre ayrılabilir.'"));
	
	Items.GroupAcceptanceOptions.Title = ProductAcceptanceHeader;
	Items.RegisterReceipt.Title = TitleReceiptProcessing;
	
	Items.RegisterReceipt.ToolTip	= HintRegistrationOfReceipt;
	Items.GoodsReceipt.ToolTip			= ProductAcceptanceHint;
	
EndProcedure

&AtServer
Procedure EstablishVisibilityOfCentralizedContract()
	
	Items.GroupBranches.Visible = NewOnlineARAPAccounting 
		And ParentCompany And UseMultipleCompanies
		And UseBranchOfficesWithSeparateBalanceSheets
		And (Object.ContractType = Enums.ContractTypes.WithCustomer
			Or Object.ContractType = Enums.ContractTypes.WithVendor
			Or Object.ContractType = Enums.ContractTypes.WithConsignee
			Or Object.ContractType = Enums.ContractTypes.ReceiptForTolling2_5
			Or Object.ContractType = Enums.ContractTypes.TransferToTolling2_5
			Or Object.ContractType = Enums.ContractTypes.TransferToCustody
			Or Object.ContractType = Enums.ContractTypes.CustomerInvoiceOutsourcedSale);
	If Not Items.GroupBranches.Visible And Object.CentralizedContract Then
		Object.CentralizedContract = False;
	EndIf;
	Items.DecorationBranches.Enabled = Object.CentralizedContract;
	Items.TransferAndOffsetOfPaymentsBetweenBranchOfficesIsAllowed.Visible = Object.CentralizedContract;
	SetNumberOfBranches(Items.DecorationBranches, Object.BranchOffices_.Count());
	
EndProcedure

&AtClient
Procedure FinishEditingListOfBranches(Result, AdditionalParameters = Undefined) Export
	
	If TypeOf(Result) = Type("FormDataCollection") Then
		Object.BranchOffices_.Clear();
		For Each Page1 In Result Do
			NewFillLine = Object.BranchOffices_.Add();
			FillPropertyValues(NewFillLine, Page1);
		EndDo;
		SetNumberOfBranches(Items.DecorationBranches, Object.BranchOffices_.Count());
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetNumberOfBranches(DecorationBranches, NumberOfBranches_)
	
	DecorationBranches.Title = NStr("vi = 'Có chi nhánh';
									|ru = 'Доступен филиалам';
									|en = 'Available to branch offices'; fa = 'در دسترس شعب';
									|it = 'Disponibile per le filiali';
									|pl = 'Dostępny dla filii';
									|tr = 'Şubeler tarafından kullanılabilir'");
	If NumberOfBranches_ > 0 Then
		DecorationBranches.Title = DecorationBranches.Title + " (" + NumberOfBranches_ + ")";
	EndIf;
	
EndProcedure

&AtServer
Procedure GeneralTaxationAndTypeOfActivity(RedefineTaxationAndTypeOfActivity = True)
	
	If Enums.ContractTypes.ThisIsSalesContract(Object.ContractType) Then
		FillParameters = Catalogs.CounterpartyContracts.ParametersForFillingInSalesVATTaxation(Object);
		If Object.VATTaxationIsDeterminedInDocuments
			And ValueIsFilled(Object.VATTaxation) Then
			Object.VATTaxation = Enums.VATTaxationTypes.EmptyRef();
		ElsIf Not Object.VATTaxationIsDeterminedInDocuments
			And RedefineTaxationAndTypeOfActivity Then
			VATAccountingERP.FillInSalesVATTaxation(Object.VATTaxation,
															FillParameters,
															VATAccountingCachedParameterValues);
		EndIf;
		VATAccountingERP.FillInSalesVATTaxSelectionList(Items.VATTaxation,
																	Object.VATTaxation,
																	FillParameters,
																	VATAccountingCachedParameterValues); 
	ElsIf Enums.ContractTypes.ThisIsPurchaseContract(Object.ContractType) Then
		FillParameters = Catalogs.CounterpartyContracts.ParametersForFillingInVATTaxationPurchases(Object);
		If Object.VATTaxationIsDeterminedInDocuments
			And ValueIsFilled(Object.VATTaxation) Then
			Object.VATTaxation = Enums.VATTaxationTypes.EmptyRef();
		ElsIf Not Object.VATTaxationIsDeterminedInDocuments
			And RedefineTaxationAndTypeOfActivity Then
			VATAccountingERP.FillInVATTaxationPurchases(Object.VATTaxation,
															FillParameters,
															VATAccountingCachedParameterValues);
		EndIf;
		VATAccountingERP.FillInListOfVATTaxChoices(Items.VATTaxation,
																	Object.VATTaxation,
																	FillParameters,
																	VATAccountingCachedParameterValues);
		
		FillParameters = Catalogs.CounterpartyContracts.ParametersForFillingInVATActivityType(Object);
		If Object.PurchaseForActivityIsDeterminedInDocument
			And ValueIsFilled(Object.PurchaseForActivity) Then
			Object.PurchaseForActivity = Enums.VATTaxationTypes.EmptyRef();
		ElsIf Not Object.PurchaseForActivityIsDeterminedInDocument
			And RedefineTaxationAndTypeOfActivity Then
			VATAccountingERP.FillInTypeOfActivityVAT(Object.PurchaseForActivity,
													FillParameters,
													VATAccountingCachedParameterValues);
		EndIf;
		VATAccountingERP.FillInActivitySelectionList(Items.PurchaseForActivity,
															Object.PurchaseForActivity,
															FillParameters,
															VATAccountingCachedParameterValues);
		
		ChoosingTypeOfVATActivity = Items.PurchaseForActivity.Visible;
		Items.TheModeOfSeparateAccountingOfNDSIsDeterminedByTheValue.Visible = ChoosingTypeOfVATActivity;
		Items.SeparateVATAccountingMode.Visible = ChoosingTypeOfVATActivity;
	EndIf;
	
EndProcedure

&AtServer
Procedure SetValuesForDiscountingDetails()
	
	If Enums.ContractTypes.ThisIsPurchaseContract(Object.ContractType) Then
		AccountingPolicySettingsOfFinAccounting = AccountingPoliciesTaxSettings.CurrentParametersOfTaxesAndAccountingPoliciesAsOfDate(
			"FinancialAccountingPolicy",
			Object.Organization);
		Object.DiscountRate = InformationRegisters.DiscountRates.GetDefaultDiscountRate(
			AccountingPolicySettingsOfFinAccounting.Period, 
			AccountingPolicySettingsOfFinAccounting.Organization, 
			Object.ARAPCurrency);
		ApplyInstallmentDiscountRate = Object.DiscountRate <> 0;
		Object.ApplicationDiscountingPeriod = AccountingPolicySettingsOfFinAccounting.ApplicationDiscountingPeriod;
	EndIf;
	
EndProcedure

&AtServer
Procedure ManagingDiscountItems(DiscountingDisabled=False)
	
	VisibilityOfDiscountDetails = False;
	If Enums.ContractTypes.ThisIsPurchaseContract(Object.ContractType) Then
		AccountingPolicySettingsOfFinAccounting = AccountingPoliciesTaxSettings.CurrentParametersOfTaxesAndAccountingPoliciesAsOfDate("FinancialAccountingPolicy", Object.Organization);
		VisibilityOfDiscountDetails = AccountingPolicySettingsOfFinAccounting.AccountingForDiscountedAccountsPayableToVendors;
		VisibilityOfDiscountDetails = VisibilityOfDiscountDetails And GetFunctionalOption("NewOnlineARAPAccounting");
		If Not VisibilityOfDiscountDetails Then
			If Object.DiscountRate > 0 Then
				VisibilityOfDiscountDetails = True;
				Items.GroupDiscountingDisabled.Visible = True;
			ElsIf DiscountingDisabled Then
				VisibilityOfDiscountDetails = True;
				Items.GroupDiscountingDisabled.Visible = False;
			EndIf;
		EndIf;
	EndIf;
	
	Items.DiscountingGroup.Visible = VisibilityOfDiscountDetails;
	Items.GroupDiscountPeriod.Visible = VisibilityOfDiscountDetails;
	
	Items.DiscountRate.Enabled = ApplyInstallmentDiscountRate;
	Items.DiscountRate.AutoMarkIncomplete = ApplyInstallmentDiscountRate;
	Items.ApplicationDiscountingPeriod.Enabled = ApplyInstallmentDiscountRate;
	Items.DaysDecoration.Enabled = ApplyInstallmentDiscountRate; 
	Items.DecorationPercent.Enabled = ApplyInstallmentDiscountRate;
	
EndProcedure
&AtServerNoContext
Function AvailableTypesOfContracts(TypeOfContractBeforeChange, StandardProcessing)
	
	ChoiceParameters = New Structure;
	AvailableTypes = Enums.ContractTypes.GetChoiceData(ChoiceParameters);
	If AvailableTypes.FindByValue(TypeOfContractBeforeChange) = Undefined Then
		StandardProcessing = False;
		AvailableTypes.Add(TypeOfContractBeforeChange);
		AvailableTypes.SortByValue();
	Else
		AvailableTypes = Undefined;
	EndIf;
	
	Return AvailableTypes;
	
EndFunction
&AtServer
Procedure SetVisibilityOfPaymentInCurrency()
	Items.ForeignCurrencyTransaction.Visible = Object.ARAPCurrency <> LocalAccountingCurrency Or Object.ForeignCurrencyTransaction;
EndProcedure

&AtServer
Procedure SetParametersForSelectingTypeOfPricesOnServer(PriceKindName = "")
	
	SalesPriceType = Object.SalesPriceType;
	PriceTypeAccountingPriceType = Object.PriceTypeAccountingPriceType;
	
	ChoiceParametersArray = New Array;
	ChoiceParametersArray.Add(New ChoiceParameter("OutputAnArbitraryTypeOfPrices", True));
	ChoiceParametersArray.Add(New ChoiceParameter("Filter.UseWhileSellingToCustomers", True));
	ChoiceParametersArray.Add(New ChoiceParameter("Filter.Status", Enums.StatusesOfPriceTypeValidity.Valid));
	
	If ValueIsFilled(PriceTypeAccountingPriceType) And (PriceKindName = "" Or PriceKindName = "SalesPriceType") Then
		
		ChoiceParametersArray.Add(New ChoiceParameter("Filter.PriceIncludesVAT", Common.ObjectAttributeValue(PriceTypeAccountingPriceType, "PriceIncludesVAT")));
		
	ElsIf ValueIsFilled(SalesPriceType) And (PriceKindName = "" Or PriceKindName = "PriceTypeAccountingPriceType") Then
		
		ChoiceParametersArray.Add(New ChoiceParameter("Filter.PriceIncludesVAT", Common.ObjectAttributeValue(SalesPriceType, "PriceIncludesVAT")));
		
	EndIf;
	
	PriceTypesSelectionParameters = New FixedArray(ChoiceParametersArray);
	
	If PriceKindName = "PriceTypeAccountingPriceType" Then
		Items.AccountingTypeOfPrices.ChoiceParameters = PriceTypesSelectionParameters;
	Else
		Items.SalesPriceType.ChoiceParameters = PriceTypesSelectionParameters;
	EndIf;
	
EndProcedure

&AtServer
Procedure ConfigureCommissionSchemeSelectionList()
	
	ChoiceList = Items.CommissionScheme.ChoiceList;
	ChoiceList.Clear();
	ChoiceList.Add(False,   ConsignmentSalesServer.PostfixCommissionSchemes20());
	ChoiceList.Add(True, ConsignmentSalesServer.PostfixCommissionSchemes25());
	
EndProcedure

&AtServer
Procedure SetDefaultContractWithCommissionAgent()
	
	If Object.ContractType = Enums.ContractTypes.SalesViaCommissionAgent Then
		Object.ContractWithCommissionAgent = ConsignmentSalesServer.GetContractWithCommissionAgentByDefault(Object);
		AgreementWithCommissionAgentInCaseOfChangesOnServer();
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
Function AvailabilityOfFixedRateOnDateOfShipment()
	
	CalculationsFee25 = (Object.ConsignmentSales25 And Not Object.ConductARAPAccountingThroughEndCustomers
		Or Object.ContractType = Enums.ContractTypes.SalesViaCommissionAgent);
	
	Return Not (Object.ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts
			Or Object.ARAPObjectSettings = Enums.ARAPObjectSettings.ByOrders And Not CalculationsFee25);
	
EndFunction

&AtServer
Procedure SetHeaderOfIPField()
	
	Items.PaymentID.Title =
		?(Catalogs.CounterpartyContracts.ThisIsContractWithClient(Object.ContractType),
		NStr("vi = 'ID thanh toán (đối với thanh toán đầu vào)';
			|ru = 'УИП (для входящих платежей)';
			|en = 'UIP (for incoming payments)'; fa = 'UIP (برای دریافت‌ها)';
			|it = 'UIP (for incoming payments)';
			|pl = 'UIP (for incoming payments)';
			|tr = 'BÖT (gelen ödemeler için)'"),
		NStr("vi = 'ID thanh toán (đối với thanh toán đầu ra)';
			|ru = 'УИП (для исходящих платежей)';
			|en = 'UIP (for outgoing payments)'; fa = 'UIP (for outgoing payments)';
			|it = 'UIP (for outgoing payments)';
			|pl = 'UIP (for outgoing payments)';
			|tr = 'BÖT (gelen ödemeler için)'"));
	
EndProcedure

&AtServer
Procedure SetPropertiesOfOutdatedCommissionUsageComment()
	
	Items.CommentUsingOutdatedCommission.Title = ConsignmentSalesServer.CommentUsingOutdatedCommission();
	Items.GroupCommentUsingOutdatedCommission.Visible = Not Object.ConsignmentSales25
		And Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.TransferToCommissionAgent");
	
EndProcedure
	
#EndRegion

#Region ControlOfInconsistentChanges

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure ControlOfNonConsistentChangesHandleEventOnChange(Item)
	If Item.Name = "Partner" Then
		PartnerOnChange(Item);
	ElsIf Item.Name = "Counterparty" Then
		CounterpartyOnChange(Item);
	ElsIf Item.Name = "Organization" Then
		OrganizationOnChange(Item);
	ElsIf Item.Name = "ARAPCurrency" Then
		ARAPCurrencyOnChange(Item);
	ElsIf Item.Name = "ForeignCurrencyTransaction" Then
		ForeignCurrencyTransactionOnChange(Item);
	ElsIf Item.Name = "ContractType" Then
		ContractTypeOnChange(Item);
	ElsIf Item.Name = "ARAPObjectSettings" Then
		ARAPObjectSettingsOnChange(Item);
	ElsIf Item.Name = "LimitDebtAmount" Then
		LimitDebtAmountOnChange(Item);
	ElsIf Item.Name = "CommissionScheme" Then
		NewCommissionSchemeForChanges(Item);
	ElsIf Item.Name = "PriceTypeAccountingPriceType" Then
		SetParametersForSelectingTypeOfPricesOnServer("PriceTypeAccountingPriceType");
	ElsIf Item.Name = "SalesPriceType" Then
		SetParametersForSelectingTypeOfPricesOnServer("SalesPriceType");
	ElsIf Item.Name = "ConductARAPAccountingThroughEndCustomers" Then
		ConductARAPAccountingThroughEndCustomersOnChange(Item);
	ElsIf Item.Name = "ValidityEndDate" Then
		ValidityEndDateOnChange(Item);
	ElsIf Item.Name = "ContractRateOption" Then
		ContractRateOptionOnChange(Item);
	ElsIf Item.Name = "NumeratorOfContractCurrencyExchangeRate" Then
		NumeratorOfContractCurrencyExchangeRateOnChange(Item);
	ElsIf Item.Name = "DenominatorOfContractCurrencyExchangeRate" Then
		DenominatorOfContractCurrencyExchangeRateOnChange(Item);
	Else
		TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisForm, Item);
	EndIf;
EndProcedure

// Parameters:
//	Command - FormCommand - 
&AtClient
Procedure ControlOfNonConsistentChangesHandleCommandEvent(Command)
	If Command.Name = "SetDateInterval" Then
		SetDateInterval(Command);
	Else
		TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisForm, Command);
	EndIf;
EndProcedure

&AtClient
Procedure ControlOfNonConsistentChangesHandleEventBeforeStartingChange(Item, Cancel)
	TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisForm, Item);
EndProcedure

&AtClient
Procedure ControlOfNonConsistentChangesHandleEventBeforeDeletion(Item, Cancel)
	TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisForm, Item);
EndProcedure

&AtClient
Procedure ControlOfNonConsistentChangesHandleEventBeforeStartingAdding(Item, Cancel, Copy, Parent, Var_Group)
	TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisForm, Item);
EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure Attachable_WhenChanging_SetAvailabilityOfItemsByStatusServer(Item)
	
	If TMCommonUseClient.WhenActingOnStatusDependentElement(ThisForm) Then
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
	
	If TMCommonUseClient.WhenActingOnStatusDependentElement(ThisForm) Then
		Return;
	EndIf;
	
	If StructureOfActionsControlOfNonAgreedChanges.Commands.Property(Command.Name) Then
		ControlOfNonConsistentChangesHandleCommandEvent(Command);
	EndIf;
	
EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure Attachable_BeforeStartingChange_SetAvailabilityOfItemsByStatusServer(Item, Cancel)
	
	If TMCommonUseClient.WhenActingOnStatusDependentElement(ThisForm) Then
		Return;
	EndIf;
	
	If StructureOfActionsControlOfNonAgreedChanges.BeforeRowChange.Property(Item.Name) Then
		ControlOfNonConsistentChangesHandleEventBeforeStartingChange(Item, Cancel);
	EndIf;
	
EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure Attachable_BeforeDeleting_SetAvailabilityOfItemsByStatusServer(Item, Cancel)
	
	If TMCommonUseClient.WhenActingOnStatusDependentElement(ThisForm) Then
		Return;
	EndIf;
	
	Name = Item.Name;
	If StructureOfActionsControlOfNonAgreedChanges.BeforeDeleteRow.Property(Name) Then
		ControlOfNonConsistentChangesHandleEventBeforeDeletion(Item, Cancel);
	EndIf;
	
EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure Attachable_BeforeYouStartAdding_SetAvailabilityOfItemsByStatusServer(Item, Cancel, Copy, Parent, Var_Group)
	
	If TMCommonUseClient.WhenActingOnStatusDependentElement(ThisForm) Then
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
	TMCommonUseClient.AfterChangingPropsDependentOnStatus(ThisForm);
	
EndProcedure

#EndRegion

// StandardSubsystems.FilesOperations
#Region FilesOperations

&AtClient
Procedure AfterDeleteData(Result, AdditionalParameters) Export
	
	Items.List.Refresh(); 
	
	If Items.ShowMarkedFiles.Check = True Then
		ShowMarkedFiles(True);
	EndIf;
	
	UpdateFileListHeader();

EndProcedure

&AtClient
Procedure AppendFile()
	
	CurrentData = CurrentFileListData();
	FilesGroup = Undefined;
	If CurrentData <> Undefined And CurrentData.IsFolder Then
		FilesGroup = CurrentData.Ref;
	ElsIf CurrentData <> Undefined Then
		FilesGroup = FileGroup_(CurrentData.Ref);
	EndIf;

	FilesOperationsClient.AddFiles(Object.Ref, UUID, , FilesGroup);

EndProcedure

&AtClient
Procedure OpenFile()
	
	If Not FileCommandsAvailable() Then
		Return;
	EndIf;
	
	CurrentData = CurrentFileListData();
	
	If CurrentData.Encrypted Then
		Return;
	EndIf;  	
	
	If RestrictedExtensions.FindByValue(CurrentData.Extension) <> Undefined Then
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("CurrentData", CurrentData);
		Notification = New CallbackDescription("OpenFileAfterConfirm", ThisObject, AdditionalParameters);
		FormParameters = New Structure("Key", "BeforeOpenFile");
		FormParameters.Insert("FileName",
			CommonClientServer.GetNameWithExtension(CurrentData.Description, CurrentData.Extension));
		OpenForm("CommonForm.SecurityWarning", FormParameters, , , , , Notification);
		Return;
	EndIf;
	
	FileBeingEdited = CurrentData.FileBeingEdited And CurrentData.CurrentUserEditsFile;
	
	FileData = FilesOperationsInternalServerCall.FileDataToOpen(CurrentData.Ref, Undefined, UUID);
	If FileData.Encrypted Then
		// The file may be modified in another session.
		NotifyChanged(CurrentData.Ref);
		Return;
	EndIf;
	
	FilesOperationsClient.OpenFile(FileData, FileBeingEdited);
	
EndProcedure

&AtClient
Procedure OpenFileCard()
	
	If Not FileCommandsAvailable() Then
		Return;
	EndIf;
	
	CurrentData = CurrentFileListData();
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("Key",              CurrentData.Ref);
	FormParameters.Insert("ReadOnly",    ReadOnly);
	FormParameters.Insert("SendOptions", SendOptions);
	
	If CurrentData.IsFolder Then
		OpenForm("DataProcessor.FilesOperations.Form.FilesGroup", FormParameters);
	Else
		FilesOperationsClient.OpenFileForm(CurrentData.Ref,, FormParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenFileAfterConfirm(Result, AdditionalParameters) Export
	
	If Result <> Undefined And Result = "Continue" Then
		
		CurrentData = AdditionalParameters.CurrentData; // See DataProcessorObject.DuplicateObjectsDetection.DuplicatesGroups
		
		FileBeingEdited = CurrentData.FileBeingEdited And CurrentData.CurrentUserEditsFile;
		
		FileData = FilesOperationsInternalServerCall.FileDataToOpen(CurrentData.Ref, Undefined, UUID);
		If FileData.Encrypted Then
			// The file may be modified in another session.
			NotifyChanged(CurrentData.Ref);
			Return;
		EndIf;
		
		FilesOperationsClient.OpenFile(FileData, FileBeingEdited);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AskQuestionToUserWhenChangingFile(CompletionDetails)
	
	QueryText = 
			NStr("vi = 'Sử dụng tệp đã chọn trong trao đổi quản lý văn bản điện tử.
			|Khi thay đổi hoặc thay thế tệp, sẽ hủy bỏ văn bản điện tử.
			|
			|Tiếp tục?';
			|ru = 'Выбранный файл используется в обмене по ЭДО.
			|При изменении или замене файла электронный документ будет аннулирован.
			|
			|Продолжить?';
			|en = 'The selected file is used in the exchange via EDI.
			|If you change or replace the file, the electronic document will be canceled.
			|
			|Continue?'; fa = 'The selected file is used in the exchange via EDI.
			|If you change or replace the file, the electronic document will be canceled.
			|
			|Continue?';
			|it = 'Выбранный файл используется в обмене по ЭДО.
			|При изменении или замене файла электронный документ будет аннулирован.
			|
			|Продолжить?';
			|pl = 'The selected file is used in the exchange via EDI.
			|If you change or replace the file, the electronic document will be canceled.
			|
			|Continue?';
			|tr = 'Seçilen dosya EDI değişiminde kullanılmaktadır.
			|Dosyanın değiştirilmesi veya yenilenmesi durumunda elektronik belge iptal edilecektir.
			|
			|Devam edilsin mi?'");
			
	QuestionParameters = StandardSubsystemsClient.QuestionToUserParameters();
	QuestionParameters.Title = NStr("vi = 'Thay đổi tệp đã gửi theo Quản lý văn bản điện tử';
									|ru = 'Изменение файла отправленного по ЭДО';
									|en = 'Change the file sent via EDI'; fa = 'Change the file sent via EDI';
									|it = 'Изменение файла отправленного по ЭДО';
									|pl = 'Change the file sent via EDI';
									|tr = 'EDI aracılığıyla gönderilen dosyanın değiştirilmesi'");
	QuestionParameters.PromptDontAskAgain = False;
	QuestionParameters.LockWholeInterface = True;
		
	StandardSubsystemsClient.ShowQuestionToUser(
		CompletionDetails, 
		QueryText, 
		QuestionDialogMode.YesNo, 
		QuestionParameters);
			
EndProcedure

&AtClient
Procedure EditCompletion(Result, Var_Parameters = Undefined) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
		
	If Result.Value = DialogReturnCode.Yes Then 
		
		CurrentData = CurrentFileListData();
			
		FilesOperationsInternalClient.EditWithNotification(Undefined, CurrentData.Ref);
			
	EndIf;

EndProcedure


&AtClient
Procedure LockCompletion(Result, Var_Parameters = Undefined) Export

	If Result = Undefined Then
		Return;
	EndIf;

	If Result.Value = DialogReturnCode.Yes Then 
		FilesCount = Items.List.SelectedRows.Count();
		If FilesCount = 1 Then
			Handler = New CallbackDescription("SetFileCommandsAvailability", ThisObject);
			FilesOperationsInternalClient.LockWithNotification(Handler, Items.List.CurrentRow);
		ElsIf FilesCount > 1 Then
			
			FilesArray = New Array;
			For Each ListItem In Items.List.SelectedRows Do
				
				RowData = ListLineData(ListItem);
				If ValueIsFilled(RowData.EditedByUser) Then
					Continue;
				EndIf;
					
				FilesArray.Add(RowData.Ref);
					
			EndDo;
				
			Handler = New CallbackDescription("SetFileCommandsAvailability", ThisObject, FilesArray);
			FilesOperationsInternalClient.LockWithNotification(Handler, FilesArray);
				
		EndIf;
	EndIf;

EndProcedure

&AtClient
Procedure UpdateFromFileOnHardDriveCompletion(Result, Var_Parameters = Undefined) Export
	
	If Result = Undefined Then
		Return;
	EndIf;

	If Result.Value = DialogReturnCode.Yes Then
		
		FileData = FilesOperationsInternalServerCall.FileDataAndWorkingDirectory(Items.List.CurrentRow);
		FilesOperationsInternalClient.UpdateFromFileOnHardDriveWithNotification(Undefined, FileData, UUID);
	
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure TransferOrCopyAttachedFiles(Val FileNamesArray, Val FileOwner, Val Action)
	
	FileToDragOwner = Common.ObjectAttributeValue(FileNamesArray[0], "FileOwner");
	If TypeOf(FileToDragOwner) <> TypeOf(FileOwner) Then
		Return;
	EndIf;
	
	If Action = "Move" Then
		FilesOperationsInternalServerCall.MoveFiles(FileNamesArray, FileOwner);
	ElsIf Action = "Copy" Then
		FilesOperationsInternalServerCall.DoCopyAttachedFiles(FileNamesArray, FileOwner);
	EndIf;

EndProcedure

// Returns:
//   FormDataStructure:
//     * Ref - CatalogRef
//   FormDataCollectionItem:
//     * Ref - CatalogRef
//
&AtClient
Function ListLineData(ListItem)
	
	Return Items.List.RowData(ListItem);
	
EndFunction

&AtServer
Procedure SetUpWorkListOfFiles()
	
	SetUpDynamicListOfFiles();	
	
	AdjustVisibilityOfCommandsToCreateListOfFiles();
	
	MetadataOfCatalogWithFiles =	Metadata.Catalogs.CounterpartyContractsAttachedFiles;
		
	ShowSizeColumn = FilesOperationsInternal.ShowSizeColumn();
	If Not ShowSizeColumn Then
		Items.ListSize.Visible = False;
	EndIf;
	
	SendOptions = FilesOperationsInternal.PrepareSendingParametersStructure();
	
	FilesSettings = FilesOperationsInternal.FilesSettings();   
	
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then 
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		HasRightToUseTemplates = ModuleAccessManagement.HasRight("Read", Catalogs.FilesFolders.Templates);
	Else
		HasRightToUseTemplates = AccessRight("Read", Metadata.Catalogs.Files) And AccessRight("Read", Metadata.Catalogs.FilesFolders)
	EndIf; 
	
	If Not HasRightToUseTemplates Or FilesSettings.DontCreateFilesByTemplate.Find(Metadata.Catalogs.CounterpartyContracts) <> Undefined Then
		Items.AddFileByTemplate.Visible = False;
		Items.ListContextMenuAddFileByTemplate.Visible = False;
	EndIf;
	
	OnChangeUseOfSigningOrEncryptionAtServer();
	
	UpdateCloudServiceNote();
	
	Items.SyncSettings.Visible = AccessRight("Edit", Metadata.Catalogs.FileSynchronizationAccounts);
	ThereIsDigitalSignatureOfFiles = Common.SubsystemExists("StandardSubsystems.DigitalSignature");
	Items.PrintWithStamp.Visible = ThereIsDigitalSignatureOfFiles;
	Items.CompareFiles.Visible = Not Common.IsLinuxClient() And Not Common.IsWebClient();
	
	RestrictedExtensions = FilesOperationsInternal.DeniedExtensionsList();

	YouHaveRightToAddFile = True;
	If Not AccessRight("InteractiveInsert", MetadataOfCatalogWithFiles) Then
		Items.AddFromFileOnHardDrive.Visible                             = False;
		Items.AddFileByTemplate.Visible                              = False;
		Items.AddFileFromScanner.Visible                              = False;
		Items.AddContractTemplateFile.Visible                      = False;
		Items.ListContextMenuAddContractTemplateFile.Visible = False;
		Items.ListContextMenuCommandsGroupAdd.Visible          = False;
		Items.ListContextMenuCreateFolder.Visible                 = False;
		Items.CreateFolder.Visible                                      = False;
		Items.ListContextMenuCreateFolder.Visible                 = False;
		Items.FormCopy.Visible                                   = False;
		Items.ListContextMenuCopy.Visible                   = False;

		YouHaveRightToAddFile = False;
	EndIf;

	FormButtonItemNames = DetermineFormButtonItemNames();
	
	If Not AccessRight("Edit", MetadataOfCatalogWithFiles) Or ReadOnly Then
		
		CommandsNames = ObjectChangeCommandsNames();
		For Each FormItemName In FormButtonItemNames Do
			
			FormItem = Items.Find(FormItemName);
			If CommandsNames[FormItem.CommandName] <> Undefined Then
				FormItem.Visible = False;
			EndIf;
			
		EndDo;

		Items.AddContractTemplateFile.Visible = False;
		Items.ListContextMenuAddContractTemplateFile.Visible = False;

	EndIf;
	
	UsePreview1 = Common.CommonSettingsStorageLoad(Type("CatalogRef.CounterpartyContractsAttachedFiles"), "Preview");
	If UsePreview1 <> Undefined Then
		Preview = UsePreview1;
	EndIf;
	
	Items.FileDataURL.Visible = Preview;
	Items.Preview.Check       = Preview;
	
	PreviewEnabledExtensions = FilesOperationsInternal.ExtensionsListForPreview();

	SetConditionalAppearanceOfFileList();
	
	FilesOperationsInternal.SetFilterByDeletionMark(List.Filter);
	
	// StandardSubsystems.AttachableCommands
	If Common.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommands = Common.CommonModule("AttachableCommands");
		PlacementParameters = ModuleAttachableCommands.PlacementParameters();
		Types = New Array;
		Types.Add(Type("CatalogRef.CounterpartyContractsAttachedFiles"));
		PlacementParameters.Sources = New TypeDescription(Types);
		PlacementParameters.GroupsPrefix = "Files";
		PlacementParameters.CommandBar  = Items.List.CommandBar;
		ModuleAttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands     
	
	If Common.IsMobileClient() Then
		Items.AddSubmenu.Representation = ButtonRepresentation.Picture;
		Items.AddFileFromScanner.Title = NStr("vi = 'Từ camera thiết bị...';
												|ru = 'С камеры устройства...';
												|en = 'From device camera…'; fa = 'From device camera…';
												|it = 'Dalla cella del dispositivo...';
												|pl = 'Z kamery urządzenia...';
												|tr = 'Cihazın kamerasından...'");
	EndIf;
	
EndProcedure  

&AtServer
Procedure SetUpDynamicListOfFiles()
	
	ListProperties = Common.DynamicListPropertiesStructure();
	
	QueryText = 
	"SELECT
	|	Files.Ref AS Ref,
	|	Files.DeletionMark AS DeletionMark,
	|	CASE
	|		WHEN Files.DeletionMark = TRUE
	|			THEN ISNULL(Files.PictureIndex, 2) + 1
	|		ELSE ISNULL(Files.PictureIndex, 2)
	|	END AS PictureIndex,
	|	Files.Description AS Description,
	|	CAST(Files.LongDesc AS STRING(500)) AS LongDesc,
	|	Files.Author AS Author,
	|	Files.CreationDate AS CreationDate,
	|	Files.ChangedBy AS WasEditedBy,
	|	DATEADD(Files.UniversalModificationDate, SECOND, &SecondsToLocalTime) AS ChangeDate,
	|	CAST(Files.Size / 1024 AS NUMBER(10, 0)) AS Size,
	|	Files.SignedWithDS AS SignedWithDS,
	|	Files.Encrypted AS Encrypted,
	|	CASE
	|		WHEN Files.SignedWithDS
	|				AND Files.Encrypted
	|			THEN 2
	|		WHEN Files.Encrypted
	|			THEN 1
	|		WHEN Files.SignedWithDS
	|			THEN 0
	|		ELSE -1
	|	END AS SignedEncryptedPictureNumber,
	|	CASE
	|		WHEN NOT Files.BeingEditedBy IN (&EmptyUsers)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS FileBeingEdited,
	|	CASE
	|		WHEN Files.BeingEditedBy = &CurrentUser
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS CurrentUserEditsFile,
	|	CASE
	|		WHEN NOT Files.BeingEditedBy IN (&EmptyUsers)
	|				AND Files.BeingEditedBy <> &CurrentUser
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS AnotherUserEditsFile,
	|	Files.Extension AS Extension,
	|	CASE
	|		WHEN FilesSynchronizationWithCloudServiceStatuses.Account <> UNDEFINED
	|				AND Files.BeingEditedBy = UNDEFINED
	|			THEN FilesSynchronizationWithCloudServiceStatuses.Account
	|		ELSE Files.BeingEditedBy
	|	END AS BeingEditedBy,
	|	Files.BeingEditedBy AS EditedByUser,
	|	Files.IsFolder AS IsFolder,
	|	FALSE AS IsInternal,
	|	Files.FileOwner AS FileOwner,
	|	Files.StoreVersions AS StoreVersions
	|FROM
	|	&CatalogName AS Files
	|		LEFT JOIN InformationRegister.FilesSynchronizationWithCloudServiceStatuses AS FilesSynchronizationWithCloudServiceStatuses
	|		ON Files.Ref = FilesSynchronizationWithCloudServiceStatuses.File
	|WHERE
	|	Files.FileOwner = &FilesOwner
	|	AND Files.FileOwner <> VALUE(Catalog.CounterpartyContracts.EmptyRef)";
	
	FullCatalogName = "Catalog.CounterpartyContractsAttachedFiles";
	
	ListProperties.MainTable  = FullCatalogName;
	ListProperties.DynamicDataRead = True; 
	
	
	ListProperties.QueryText = StrReplace(QueryText, "&CatalogName", FullCatalogName);
	Common.SetDynamicListProperties(Items.List, ListProperties);
	
	EmptyUsers = New Array;
	EmptyUsers.Add(Undefined);
	EmptyUsers.Add(Catalogs.Users.EmptyRef());
	EmptyUsers.Add(Catalogs.ExternalUsers.EmptyRef());
	EmptyUsers.Add(Catalogs.FileSynchronizationAccounts.EmptyRef());
		
	List.Parameters.SetParameterValue("FilesOwner",      Object.Ref);
	List.Parameters.SetParameterValue("CurrentUser", Users.AuthorizedUser());
	List.Parameters.SetParameterValue("EmptyUsers",  EmptyUsers);
	
	UniversalDate = CurrentSessionDate();
	List.Parameters.SetParameterValue("SecondsToLocalTime",
		ToLocalTime(UniversalDate, SessionTimeZone()) - UniversalDate);
		
	UpdateFileListHeader();
		
EndProcedure
	
&AtServer
Procedure AdjustVisibilityOfCommandsToCreateListOfFiles()
	
	If Object.Ref.IsEmpty() Then
		
		Items.AddSubmenu.Visible = False;
		Items.ListContextMenuCommandsGroupAdd.Visible = False;
		Items.AddContractTemplateFile.Visible = False;      
		Items.ListContextMenuAddContractTemplateFile.Visible = False; 
		Items.CreateFolder.Visible = False;
		
		Items.FormImportGroup.Visible = False;
		Items.ImportFiles.Visible = False;
		Items.ImportFolder.Visible = False;
		
	Else
		
		Items.AddSubmenu.Visible = True;
		Items.ListContextMenuCommandsGroupAdd.Visible = True;
		Items.AddContractTemplateFile.Visible = True;
		Items.ListContextMenuAddContractTemplateFile.Visible = True;
		Items.CreateFolder.Visible = True;
		
		Items.FormImportGroup.Visible = False;
		Items.ImportFiles.Visible = False;
		Items.ImportFolder.Visible = False;
		
	EndIf;

EndProcedure

&AtClient
Procedure WorkingWithFilesHandlingAlerts(EventName, Parameter, Source)
	
	CurrentData = CurrentFileListData();
	
	If Upper(EventName) = Upper("Write_ConstantsSet")
		And (Upper(Source) = Upper("UseDigitalSignature")
		Or Upper(Source) = Upper("UseEncryption")) Then
		
		AttachIdleHandler("SigningOrEncryptionUsageOnChange", 0.3, True);
		Return;
	ElsIf EventName = "Write_File" Then
		
	
		If Not ValueIsFilled(Source)
			Or (TypeOf(Source) = Type("Array")
			And Source.Count() = 0) Then 
			SetUpDynamicListOfFiles();
			Items.List.Refresh();
			Return;
		EndIf;
		
		FileRef = ?(TypeOf(Source) = Type("Array"), Source[0], Source);
		If TypeOf(FileRef) <> Type("CatalogRef.CounterpartyContractsAttachedFiles") Then
			Return;
		EndIf;
		
		If Parameter.Property("IsNew") And Parameter.IsNew Then
			
			Items.List.CurrentRow = FileRef;
			SetFileCommandsAvailability();
			
		ElsIf FileCommandsAvailable() And CurrentData <> Undefined 
			And FileRef = CurrentData.Ref Then
			SetFileCommandsAvailability();
		EndIf;
		UpdateFileListHeader();
		Items.List.Refresh();
	ElsIf EventName = "Write_FilesFolders" Then
		SetFileCommandsAvailability();
		Items.List.Refresh();
	EndIf;

EndProcedure

&AtServer
Procedure UpdateCloudServiceNote()
	
	NoteVisibility = False;
	
	If GetFunctionalOption("UseFileSync") Then
		
		SynchronizationInfo = FilesOperationsInternal.SynchronizationInfo(Object.Ref);
		If SynchronizationInfo <> Undefined  Then
			
			FilesBeingEditedInCloudService = True;
			Account = SynchronizationInfo.Account;
			NoteVisibility = True;
			
			Items.DecorationNote.Title = StringFunctions.FormattedString(
				NStr("vi = 'Các tệp được quản lý trong dịch vụ đám mây <a href=""%1""> %2 </a>.';
					|ru = 'Работа с файлами ведется в облачном сервисе <a href=""%1"">%2</a>.';
					|en = 'The files are stored in cloud service <a href=""%1"">%2</a>.'; fa = 'The files are stored in cloud service <a href=""%1"">%2</a>.';
					|it = 'Работа с файлами ведется в облачном сервисе <a href=""%1"">%2</a>.';
					|pl = 'The files are stored in cloud service <a href=""%1"">%2</a>.';
					|tr = 'Dosyalarla çalışma bulut hizmetinde yürütülüyor <a href=""%1"">%2</a>.'"),
				SynchronizationInfo.FolderAddressInCloudService, SynchronizationInfo.AccountDescription1);
			
			Items.DecorationPictureSyncStatus.Visible = Not SynchronizationInfo.IsSynchronized;
			Items.DecorationSyncDate.ToolTipRepresentation =?(SynchronizationInfo.IsSynchronized, 
				ToolTipRepresentation.None, ToolTipRepresentation.Button);
			
			Items.DecorationSyncDate.Title = StringFunctions.FormattedString(
				NStr("vi = 'Đã đồng bộ: <a href=""%1"">%2</a>';
					|ru = 'Синхронизировано: <a href=""%1"">%2</a>';
					|en = 'Synchronized on: <a href=""%1"">%2</a>'; fa = 'Synchronized on: <a href=""%1"">%2</a>';
					|it = 'Синхронизировано: <a href=""%1"">%2</a>';
					|pl = 'Synchronized on: <a href=""%1"">%2</a>';
					|tr = 'Senkronize edildi: <a href=""%1"">%2</a>'"),
				"OpenJournal", Format(SynchronizationInfo.SynchronizationDate, "DLF=DD"));
			
		EndIf;
		
	EndIf;
	
	Items.CloudServiceNoteGroup.Visible = NoteVisibility;
	
EndProcedure

&AtClient
Procedure SetFileCommandsAvailability(Result = Undefined, ExecutionParameters = Undefined) Export
	
	CurrentData = CurrentFileListData();
	
	CommandsNames = New Map;
	If CurrentData = Undefined And Not FilesBeingEditedInCloudService Then
		
		CommandsNames.Insert("AddFileFromHardDrive", True);
		CommandsNames.Insert("AddFileFromScanner", True);
		CommandsNames.Insert("AddFileByTemplate", True);   
		CommandsNames.Insert("AddContractTemplateFile", True);
		CommandsNames.Insert("ImportFiles", True);
		CommandsNames.Insert("UploadFolderOfFiles", True);
		
	ElsIf CurrentData <> Undefined 
		And TypeOf(Items.List.CurrentRow) = Type("CatalogRef.CounterpartyContractsAttachedFiles") Then
		
		AbilityToUnlockFile = FilesOperationsInternalClient.AbilityToUnlockFile(
			CurrentData.Ref,
			CurrentData.CurrentUserEditsFile,
			CurrentData.EditedByUser); 
			
		IndicatesFileIsCurrentlyBeingEditedByEDI = False;
		If ValueIsFilled(FileIsCurrentlyBeingEditedByEDI) 
			And CurrentData.Ref = FileIsCurrentlyBeingEditedByEDI Then
			IndicatesFileIsCurrentlyBeingEditedByEDI = True;
		EndIf;
		
		IndicatesThatFileIsCurrentlyBeingSentToEDI = False;
	
		CommandsNames = AvailableCommands(CurrentData, FilesBeingEditedInCloudService,
			AbilityToUnlockFile, UsersClient.AuthorizedUser(),
			IndicatesFileIsCurrentlyBeingEditedByEDI, IndicatesThatFileIsCurrentlyBeingSentToEDI);
			
	EndIf;
	
	If CurrentData <> Undefined Then
		Items.PrintWithStamp.Visible = ThereIsDigitalSignatureOfFiles
			And (CurrentData.Extension = "mxl") Or (CurrentData.Extension = "docx")
			And CurrentData.SignedWithDS;
	EndIf;
	
	For Each FormItemName In FormButtonItemNames Do
		
		FormItem = Items.Find(FormItemName);
		If CommandsNames[FormItem.CommandName] = True Or CommandsNames[FormItem.Name] = True Then
			
			If Not FormItem.Enabled Then
				FormItem.Enabled = True;
			EndIf;
			
		ElsIf FormItem.Enabled Then
			FormItem.Enabled = False;
		EndIf;
	EndDo;
	
	AttachIdleHandler("UpdatePreview1", 0.1, True);

EndProcedure

&AtClientAtServerNoContext
Function NamesOfFormCommands()
	
	Result = ObjectChangeCommandsNames();

	// Commands available to any user reading files.
	Result.Insert("OpenFileDirectory", True);
	Result.Insert("OpenFileForViewing", True);
	Result.Insert("SaveAs", True);
	
	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Function ObjectChangeCommandsNames()
	
	Result = New Map;
	
	// Commands that depend on the State of objects.
	Result.Insert("EndFileEditing", True);
	Result.Insert("LockFile", True);
	Result.Insert("UnlockFile", True);
	Result.Insert("EditFile", True);
	Result.Insert("SetFileDeletionMark", True);
	Result.Insert("DeleteFile", True);
	Result.Insert("ContextMenuMarkForDeletion", True);
	
	Result.Insert("SignFile", True);
	Result.Insert("AddDSFromFile", True);
	Result.Insert("SaveFileTogetherBOT", True);
	
	Result.Insert("EncryptFile", True);
	Result.Insert("DecryptFile", True);
	
	Result.Insert("FilePrint", True);
	Result.Insert("PrintingWithFileStamp", True);
	
	Result.Insert("SendFile", True);
	
	Result.Insert("UpdateFromFileOnHardDrive", True);
	
	// Commands that are independent of the State of objects.
	Result.Insert("AddFileFromHardDrive", True);
	Result.Insert("AddFromFileOnHardDrive", True);
	Result.Insert("AddFileByTemplate", True); 
	Result.Insert("AddContractTemplateFile", True);
	Result.Insert("AddFileFromScanner", True);
	Result.Insert("OpenFileProperties", True);
	Result.Insert("CopyAttachedFile", True);
	Result.Insert("ImportFiles", True);
	Result.Insert("UploadFolderOfFiles", True);
	
	Result.Insert("MoveToGroupOfFiles", True);
	
	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Function AvailableCommands(CurrentFileData, FilesBeingEditedInCloudService, AbilityToUnlockFile, 
	AuthorizedUser, IndicatesFileIsCurrentlyBeingEditedByEDI, IndicatesThatFileIsCurrentlyBeingSentToEDI)
	
	CommandsNames = NamesOfFormCommands();
	
	CurrentUserEditsFile  = CurrentFileData.CurrentUserEditsFile;
	CurrentUserIsAuthor            = CurrentFileData.Author = AuthorizedUser;
	FileBeingEdited                   = CurrentFileData.FileBeingEdited;
	FileSigned                        = CurrentFileData.SignedWithDS;
	FileEncrypted                      = CurrentFileData.Encrypted;
	IndicatesFileIsCurrentlyBeingEditedByEDI = IndicatesFileIsCurrentlyBeingEditedByEDI;
	IndicatesThatFileIsCurrentlyBeingSentToEDI       = IndicatesThatFileIsCurrentlyBeingSentToEDI;
	
	If FileBeingEdited Then
		
		If CurrentUserEditsFile Then
			CommandsNames["UpdateFromFileOnHardDrive"] = False;
		Else
			CommandsNames["EndFileEditing"] = False;
			If Not AbilityToUnlockFile Then
				CommandsNames["UnlockFile"] = False;
			EndIf;
			CommandsNames["EditFile"] = False;
		EndIf;
		
		CommandsNames["LockFile"] = False;
		CommandsNames["SetFileDeletionMark"] = False;
		CommandsNames["ContextMenuMarkForDeletion"] = False;

		CommandsNames["SignFile"] = False;
		CommandsNames["AddDSFromFile"] = False;
		CommandsNames["SaveFileTogetherBOT"] = False;
		
		CommandsNames["OpenFileProperties"] = False;
		
		CommandsNames["UpdateFromFileOnHardDrive"] = False;
		CommandsNames["SaveAs"] = False;
		
		CommandsNames["EncryptFile"] = False;
		CommandsNames["DecryptFile"] = False;
		
		CommandsNames["DeleteFile"] = False;
		
	Else
		CommandsNames["EndFileEditing"] = False;
		CommandsNames["UnlockFile"] = False;
	EndIf;
	
	If IndicatesFileIsCurrentlyBeingEditedByEDI Or IndicatesThatFileIsCurrentlyBeingSentToEDI Then
		
		CommandsNames["EndFileEditing"] = False;
		If Not AbilityToUnlockFile Then
			CommandsNames["UnlockFile"] = False;
		EndIf;
		CommandsNames["EditFile"] = False;
		
		CommandsNames["LockFile"] = False;
		CommandsNames["SetFileDeletionMark"] = False;
		CommandsNames["ContextMenuMarkForDeletion"] = False;
		
		CommandsNames["OpenFileProperties"] = False;
		 
		CommandsNames["SignFile"] = False;
		CommandsNames["AddDSFromFile"] = False;
		CommandsNames["SaveFileTogetherBOT"] = False;
		
		CommandsNames["UpdateFromFileOnHardDrive"] = False;
		CommandsNames["SaveAs"] = False;
		
		CommandsNames["EncryptFile"] = False;
		CommandsNames["DecryptFile"] = False;
		
		CommandsNames["DeleteFile"] = False;
	EndIf;

	If CurrentFileData.IsFolder Then
		CommandsNames["EditFile"] = False;
		CommandsNames["SignFile"] = False;
		CommandsNames["AddDSFromFile"] = False;
		CommandsNames["SaveFileTogetherBOT"] = False;
		CommandsNames["EncryptFile"] = False;
		CommandsNames["DecryptFile"] = False;
		CommandsNames["UpdateFromFileOnHardDrive"] = False;
		CommandsNames["CopyAttachedFile"] = False;
		CommandsNames["OpenFileDirectory"] = False;
		CommandsNames["OpenFileForViewing"] = False;
		CommandsNames["SaveAs"] = False;
		CommandsNames["LockFile"] = False;
		CommandsNames["SendFile"] = False;
		CommandsNames["PrintingWithFileStamp"] = False;
		CommandsNames["FilePrint"] = False;
		CommandsNames["DeleteFile"] = False;
	EndIf;
	
	If FileSigned Then
		CommandsNames["EndFileEditing"] = False;
		CommandsNames["UnlockFile"] = False;
		CommandsNames["EditFile"] = False;
		CommandsNames["UpdateFromFileOnHardDrive"] = False;
		CommandsNames["LockFile"] = False;
	EndIf;
	
	If FileEncrypted Then
		CommandsNames["SignFile"] = False;
		CommandsNames["AddDSFromFile"] = False;
		CommandsNames["SaveFileTogetherBOT"] = False;
		
		CommandsNames["EndFileEditing"] = False;
		CommandsNames["UnlockFile"] = False;
		CommandsNames["EditFile"] = False;
		CommandsNames["LockFile"] = False;
		
		CommandsNames["UpdateFromFileOnHardDrive"] = False;
		
		CommandsNames["EncryptFile"] = False;
		
		CommandsNames["OpenFileDirectory"] = False;
		CommandsNames["OpenFileForViewing"] = False;
		CommandsNames["SaveAs"] = False;
	Else
		CommandsNames["DecryptFile"] = False;
	EndIf;
	
	If FilesBeingEditedInCloudService Then
		
		CommandsNames["AddFileFromHardDrive"] = False;
		CommandsNames["AddFromFileOnHardDrive"] = False;
		CommandsNames["AddFileByTemplate"] = False;
		CommandsNames["AddContractTemplateFile"] = False;
		CommandsNames["AddFileFromScanner"] = False;
		CommandsNames["CopyAttachedFile"] = False;
		
		CommandsNames["CreateGroupOfFiles"] = False;
		CommandsNames["MoveToGroupOfFiles"] = False;
		CommandsNames["SetFileDeletionMark"] = False;
		CommandsNames["ContextMenuMarkForDeletion"] = False;
		CommandsNames["LockFile"] = False;
		CommandsNames["UnlockFile"] = False;
		
		CommandsNames["ImportFiles"] = False;
		CommandsNames["UploadFolderOfFiles"] = False;
		
		CommandsNames["DeleteFile"] = False;
		
		CommandsNames["SignFile"] = False;
		CommandsNames["AddDSFromFile"] = False;
		CommandsNames["EncryptFile"] = False;
		CommandsNames["DecryptFile"] = False;
		
	EndIf;
	
	If Not CurrentUserIsAuthor Then
		CommandsNames["DeleteFile"] = False;
	EndIf;
	
	Return CommandsNames;
	
EndFunction

// Continue with the procedure to Sign Dobavitsya.
&AtClient
Procedure AddSignaturesCompeltion(Success, Context) Export
	
	If Success = True Then
		SetFileCommandsAvailability();
	EndIf;
	
EndProcedure

&AtClient
Procedure SigningOrEncryptionUsageOnChange()
	
	OnChangeUseOfSigningOrEncryptionAtServer();
	
EndProcedure

&AtServer
Procedure OnChangeUseOfSigningOrEncryptionAtServer()
	
	FilesOperationsInternal.CryptographyOnCreateFormAtServer(ThisObject);
	
EndProcedure

&AtServerNoContext
Procedure SavePreviewOption(FileCatalogType, Preview)
	Common.CommonSettingsStorageSave(Type("CatalogRef.CounterpartyContractsAttachedFiles"), "Preview", Preview);
EndProcedure

&AtServerNoContext
Procedure OnSendFilesViaEmail(SendOptions, Val FilesToSend, FilesOwner, UUID)
	FilesOperationsOverridable.OnSendFilesViaEmail(SendOptions, FilesToSend, FilesOwner, UUID);
EndProcedure

&AtServerNoContext
Procedure SetClearDeletionMark(OwnerFiles)
	
	DeletionMark = Undefined;
	For Each FileRef In OwnerFiles Do
		
		BeginTransaction();
		Try
			Block = New DataLock();
			LockItem = Block.Add(FileRef.Metadata().FullName());
			LockItem.SetValue("Ref", FileRef);
			Block.Lock();

			FileObject1 = FileRef.GetObject();
			If DeletionMark = Undefined Then
				DeletionMark = Not FileObject1.DeletionMark;
			EndIf;
			FileObject1.SetDeletionMark(DeletionMark);

			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;
	EndDo;
	
EndProcedure

&AtServer
Procedure AddPreviewFieldForPDFDocument() 
	
	AttributesToBeAdded = New Array;
	NewAttribute = New FormAttribute("PDFDocument", New TypeDescription("PDFDocument")); 
	AttributesToBeAdded.Add(NewAttribute);	
	ThisObject.ChangeAttributes(AttributesToBeAdded);
	
	NewItem = ThisObject.Items.Add("PDFDocument", Type("FormField"), Items.GroupFiles);
	NewItem.Type = FormFieldType.PDFDocumentField;
	NewItem.Visible = Preview;	
	NewItem.TitleLocation = FormItemTitleLocation.None;
	NewItem.DataPath = "PDFDocument";
	
EndProcedure

&AtClient
Procedure SetPreviewVisibility(UsePreview1)
	
	CurrentData = CurrentFileListData();
	If CurrentData <> Undefined And CurrentData.Extension = "pdf" Then
		#If Not MobileClient Then
		 Items.PDFDocument.Visible = UsePreview1; 
		#EndIf 
	Else
		Items.FileDataURL.Visible = UsePreview1;
	EndIf;
	Items.Preview.Check = UsePreview1;

EndProcedure

&AtClient
Procedure UpdatePreview1()
	
	If Not Preview Then
		Return;
	EndIf;
	
	CurrentData = CurrentFileListData();
	If CurrentData <> Undefined And PreviewEnabledExtensions.FindByValue(CurrentData.Extension) <> Undefined Then
		
		Items.FileDataURL.Visible = True; 
		#If Not MobileClient Then
		Items.PDFDocument.Visible = False; 
		#EndIf 
			
		Try
			FileData = FilesOperationsInternalServerCall.FileDataToOpen(CurrentData.Ref, Undefined, UUID,, FileDataURL);
			FileDataURL = FileData.RefToBinaryFileData;
		Except
			// If the file does not exist, an exception will be thrown.
			FileDataURL         = Undefined;
			NonselectedPictureText = NStr("vi = 'Xem trước không được phép theo nguyên nhân:';
											|ru = 'Предварительный просмотр недоступен по причине:';
											|en = 'Preview is not available. Reason:'; fa = 'Preview is not available. Reason:';
											|it = 'L''anteprima non è disponibile a causa di:';
											|pl = 'Podgląd jest niedostępny z powodu:';
											|tr = 'Ön izleme aşağıdaki nedenle imkansız:'") 
											+ Chars.LF + ErrorProcessing.BriefErrorDescription(ErrorInfo());
		EndTry;
		
	ElsIf CurrentData <> Undefined And CurrentData.Extension = "pdf" Then 
		
		#If Not MobileClient Then 
		Try
			Items.PDFDocument.Visible = True;
			Items.FileDataURL.Visible = False;
		
			FileData = FilesOperationsInternalServerCall.FileDataToOpen(CurrentData.Ref, Undefined, UUID,, FileDataURL);
			FileDataURL = FileData.RefToBinaryFileData;  
			FileBinaryData = GetFromTempStorage(FileDataURL);
			Stream = FileBinaryData.OpenStreamForRead();
			ThisObject["PDFDocument"].Read(Stream);

		Except
			Items.FileDataURL.Visible = True;
			Items.PDFDocument.Visible = False; 
		
			// If the file does not exist, an exception will be thrown.
			FileDataURL         = Undefined;
			NonselectedPictureText = NStr("vi = 'Xem trước không được phép theo nguyên nhân:';
											|ru = 'Предварительный просмотр недоступен по причине:';
											|en = 'Preview is not available. Reason:'; fa = 'Preview is not available. Reason:';
											|it = 'L''anteprima non è disponibile a causa di:';
											|pl = 'Podgląd jest niedostępny z powodu:';
											|tr = 'Ön izleme aşağıdaki nedenle imkansız:'") 
											+ Chars.LF + ErrorProcessing.BriefErrorDescription(ErrorInfo());
		EndTry;
		
		#Else
		Items.FileDataURL.Visible = True;
		FileDataURL         = Undefined;
		NonselectedPictureText = NStr("vi = 'Không có dữ liệu để xem trước';
										|ru = 'Нет данных для предварительного просмотра';
										|en = 'No data to preview'; fa = 'No data to preview';
										|it = 'Non ci sono dati per un''anteprima';
										|pl = 'Brak danych do podglądu';
										|tr = 'Ön gösterilecek veri yok'");
		#EndIf 
		
	Else
		
		Items.FileDataURL.Visible = True;
		#If Not MobileClient Then
		Items.PDFDocument.Visible = False;
		#EndIf
	
		FileDataURL         = Undefined;
		NonselectedPictureText = NStr("vi = 'Không có dữ liệu để xem trước';
										|ru = 'Нет данных для предварительного просмотра';
										|en = 'No data to preview'; fa = 'No data to preview';
										|it = 'Non ci sono dati per un''anteprima';
										|pl = 'Brak danych do podglądu';
										|tr = 'Ön gösterilecek veri yok'");
		
	EndIf;
	
	If Not ValueIsFilled(FileDataURL) Then
		Items.FileDataURL.NonselectedPictureText = NonselectedPictureText;
	EndIf;

EndProcedure

&AtClient
Procedure ListSelectionAfterEditModeChoice(Result, ExecutionParameters) Export
	
	If Result = "Edit" Then
		Handler = New CallbackDescription("SelectionListAfterEditFile", ThisObject, ExecutionParameters);
		FilesOperationsInternalClient.EditFile(Handler, ExecutionParameters.FileData);
	ElsIf Result = "Open" Then
		FilesOperationsClient.OpenFile(ExecutionParameters.FileData, False);
	EndIf;
	
EndProcedure 

 // Parameters:
//   Result - Undefined
//   ExecutionParameters - Structure:
//     * FileData - See FilesOperations.FileData
//
&AtClient
Procedure SelectionListAfterEditFile(Result, ExecutionParameters) Export
	
	NotifyChanged(ExecutionParameters.FileData.Ref);
	
	SetFileCommandsAvailability();
	
EndProcedure

&AtClient
Procedure SetDeletionMarkCompletion(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		SetClearDeletionMark(AdditionalParameters.Files);
		FileWriteNotificationParameters = FilesOperationsInternalClient.FileWriteNotificationParameters("FileDataChanged");
		Notify("Write_File", FileWriteNotificationParameters, AdditionalParameters.Files);
		Items.List.Refresh();
	EndIf;
	
EndProcedure

&AtServer
Procedure SetConditionalAppearanceOfFileList()
	
	List.ConditionalAppearance.Items.Clear();
	
	// Formatting of a file occupied for editing by another user.
	
	Item = List.ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AnotherUserEditsFile");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	
	// The design of the file occupied for editing by the current user.
	
	Item = List.ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("CurrentUserEditsFile");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.FileLockedByCurrentUser);
	
	// Hiding groups of files that belong to other owner objects
	Item = List.ConditionalAppearance.Items.Add();
		
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("FileOwner");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Object.Ref;
		
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("IsFolder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
		
	Item.Appearance.SetParameterValue("Visible", False);
	Item.Appearance.SetParameterValue("Show", False);
	
	// Service files
	
	Item = List.ConditionalAppearance.Items.Add();
	Item.Use = True;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	
	Filter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	Filter.Use = True;
	Filter.ComparisonType = DataCompositionComparisonType.Equal;
	Filter.LeftValue = New DataCompositionField("IsInternal");
	Filter.RightValue = True;
	
	// The Color Of The Hyperlink Of The Edi State
	Item = List.ConditionalAppearance.Items.Add(); 
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.EDSentReceived.Name);
	
	FilterElement = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue = New DataCompositionField("EDSentReceived"); 
	FilterElement.ComparisonType = DataCompositionComparisonType.Filled;
	FilterElement.Use = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.HyperlinkColor);
	Item.Use = True;

EndProcedure

&AtServer
Procedure UpdateFileListHeader()
	
	AttachedFilesCount = FilesOperationsInternalServerCall.AttachedFilesCount(Object.Ref);
	If AttachedFilesCount > 0 And Not Object.Ref.IsEmpty() Then
		Items.FilesPage.Title = NStr("vi = 'Tệp';
									|ru = 'Файлы';
									|en = 'Files'; fa = 'فایل‌ها';
									|it = 'Файлы';
									|pl = 'Files';
									|tr = 'Dosyalar'") + " (" + Format(AttachedFilesCount, "NG=") + ")";
	Else
		Items.FilesPage.Title = NStr("vi = 'Tệp';
									|ru = 'Файлы';
									|en = 'Files'; fa = 'فایل‌ها';
									|it = 'Файлы';
									|pl = 'Files';
									|tr = 'Dosyalar'");
	EndIf; 
	
EndProcedure

&AtClient
Function CurrentFileListData()
	
	If Not StandardSubsystemsClient.IsDynamicListItem(Items.List) 
		Or Items.List.CurrentData.FileOwner <> Object.Ref Then
		Return Undefined;
	EndIf;
	
	Return Items.List.CurrentData;
	
EndFunction

&AtClient
Function SelectedLinesOfFileList()
	
	SelectedRows = New Array;
	For Each SelectedRow In Items.List.SelectedRows Do
		
		If TypeOf(SelectedRow) <> Type("DynamicListGroupRow") Then
			
			RowData = Items.List.RowData(SelectedRow);
			If RowData.FileOwner = Object.Ref Then
				SelectedRows.Add(SelectedRow);
			EndIf;
		
		EndIf;
	
	EndDo;
	
	Return SelectedRows;
			
EndFunction

&AtClient
Function FileCommandsAvailable()
	
	Return FilesOperationsInternalClient.FileCommandsAvailable(Items);
	
EndFunction

&AtServer
Function SynchronizationSettingsParameters(FileOwner)
	
	FileOwnerType = Common.MetadataObjectID(Type("CatalogRef.CounterpartyContractsAttachedFiles"));
	
	Filter = New Structure(
	"FileOwner, FileOwnerType, Account",
		FileOwner,
		FileOwnerType,
		Catalogs.FileSynchronizationAccounts.EmptyRef());
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	FileSynchronizationSettings.FileOwner,
		|	FileSynchronizationSettings.FileOwnerType,
		|	FileSynchronizationSettings.Account
		|FROM
		|	InformationRegister.FileSynchronizationSettings AS FileSynchronizationSettings
		|WHERE
		|	FileSynchronizationSettings.FileOwner = &FileOwner
		|	AND FileSynchronizationSettings.FileOwnerType = &FileOwnerType";
	
	Query.SetParameter("FileOwner", FileOwner);
	Query.SetParameter("FileOwnerType", FileOwnerType);
	
	QueryResult = Query.Execute();
	
	SelectionDetailRecords = QueryResult.Select();
	
	If SelectionDetailRecords.Count() = 1 Then
		While SelectionDetailRecords.Next() Do
			Filter.Account = SelectionDetailRecords.Account;
		EndDo;
	EndIf;
	
	Return Filter;
	
EndFunction

&AtServerNoContext
Function EventLogFilterData(Service)
	Return FilesOperationsInternal.EventLogFilterData(Service);
EndFunction

&AtServer
Function DetermineFormButtonItemNames()
	
	NamesOfFormCommands = NamesOfFormCommands();
	ItemsNames = New Array;
	
	For Each FormItem In Items Do
		
		If TypeOf(FormItem) <> Type("FormButton") Then
			Continue;
		EndIf;
		
		If NamesOfFormCommands[FormItem.CommandName] <> Undefined 
			Or NamesOfFormCommands[FormItem.Name] <> Undefined Then
			ItemsNames.Add(FormItem.Name);
		EndIf;
		
	EndDo;
	Return New FixedArray(ItemsNames);
	
EndFunction

&AtClient
Procedure UpdateFileCommandAvailability()
	
	SetFileCommandsAvailability();
	
EndProcedure

&AtServerNoContext
Function FilesOwnerMaps(FilesOwner, FileToDrag)
	
	Return FilesOwner = Common.ObjectAttributeValue(FileToDrag, "FileOwner");
	
EndFunction

&AtServerNoContext
Function FileGroup_(File)
	Return Common.ObjectAttributeValue(File, "Parent");
EndFunction

&AtServerNoContext
Function WhetherToSendEDIFile(File)
	Return Common.ObjectAttributeValue(File, "EDSentReceived");
EndFunction

#EndRegion
 // End StandardSubsystems.FilesOperations
 
#Region RegularPayments

&AtServer
Procedure SetVisibilityOfRegularPayments()
	
	RegularPaymentsOption = Enums.OptionsForDeterminingExecutionScheduleInContract.RegularPayments;

	CommonClientServer.SetFormItemProperty(Items, "RegularPaymentsGroup", "Visible",
		(Object.OptionOfDeterminingExecutionScheduleInContract = RegularPaymentsOption));
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillInListOfOptionsForDeterminingExecutionScheduleInContract(ChoiceList, ContractType)
	
	ChoiceList.Clear();
	ChoiceList.Add(
		PredefinedValue("Enum.OptionsForDeterminingExecutionScheduleInContract.SalesOrderCustomerInvoices"));
	ChoiceList.Add(
		PredefinedValue("Enum.OptionsForDeterminingExecutionScheduleInContract.Contract"));
	
	If ARAPAccountingClientServer.TypesOfContractsWithSupplier().FindByValue(ContractType) <> Undefined Then
		ChoiceList.Add(
			PredefinedValue("Enum.OptionsForDeterminingExecutionScheduleInContract.RegularPayments"));
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region Localization

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(
		Command,
		ThisObject,
		Object);
	
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
	If Item.Name = "sh_ShamsiInput_ValidityEndDate" Then
		ValidityEndDateOnChange(Items.ValidityEndDate);
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
