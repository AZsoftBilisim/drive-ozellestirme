#Region Variables

&AtClient
Var CloseAfterWrite;

&AtClient
Var ParametersForRecording Export;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	AutoTitle = False;
	TradeManagement = GetFunctionalOption("TradeManagement");
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
	
	ARAPAccountingFormWork.FormWhenCreatedOnServer(ThisObject);
	NotifyAboutCreationOfCalculationObject = Parameters.NotifyAboutCreationOfCalculationObject;
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	OnReadCreateAtServer();
	
	// StandardSubsystems.PeriodClosingDates
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.PeriodClosingDates

	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If VATAccountingERPClient.FinishedEditingInvoiceReceived(ValueSelected, ChoiceSource)
		Or VATAccountingERPClient.FinishedEditingInvoiceIssued(ValueSelected, ChoiceSource) Then
		CustomizeInvoicePresentation();
	EndIf;
	
	VATAccountingERPClient.ProcessingChangesInStateOfVATPaymentOnInvoice(
		ChoiceSource,
		ValueSelected,
		Items.InvoicePaymentStatus);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If (EventName = "Write_AdjustingPurchaseBeforeEnteringBalance"
		Or EventName = "Write_AdjustingImplementationBeforeEnteringBalances")
		And TypeOf(Parameter) = Type("Structure")
		And Parameter.Property("DocumentBasis")
		And Parameter.DocumentBasis = Object.Ref Then
		UpdateFlagThereAreAdjustments();
	EndIf;
	
	If EventName = "WhenChangingAgreement"
		And Source = ThisObject Then
		Modified = True;
		If ValueIsFilled(Object.Ref) Then
			Attachable_WhenChanging_SetAvailabilityOfItemsByStatusServer(Items[Parameter]);
		Else
			ContractOnChange(Items[Parameter]);
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	TypeOfValueEnteringBalances = VATAccountingLocalization.TypeOfValueEnteringBalances(Object.Ref);
	NotPaymentOfNDSVBudgetIsRequired = Not (TypeOfValueEnteringBalances = Enums.AssetKinds.CustomsPayments
		Or TypeOfValueEnteringBalances = Enums.AssetKinds.CustomsUnion);
	
	VATAccountingERP.SetTitleOfStateOfVATPaymentOnInvoice(
		Object.Ref,
		Items.InvoicePaymentStatus,
		NotPaymentOfNDSVBudgetIsRequired);
		
	ARAPAccountingFormWork.FormAfterRecordingOnServer(ThisObject, CurrentObject.AdditionalProperties);
	
	SetVisibilityOfPaymentStatusOnInvoice(NotPaymentOfNDSVBudgetIsRequired);
	CustomizeInvoicePresentation();
	SetHeader();
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);
	
	If NotExecuteCheck1BeforeWrite Then
		NotExecuteCheck1BeforeWrite = False;
		Return;
	EndIf;
	
	TMCommonUseClient.RecordObjectIfNecessary(ThisObject, WriteParameters, Cancel);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_SourceDocument", WriteParameters, Object.Ref);
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisObject, WriteParameters);
	
	TMCommonUseClient.PerformActionsAfterRecording(ThisObject, Object, WriteParameters);
	
	If CloseAfterWrite Then
		Close();
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	CloseAfterWrite = True;
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Not Exit 
		And ValueIsFilled(Object.Ref)
		And NotifyAboutCreationOfCalculationObject Then
		ARAPAccountingClient.FormWhenClosing(ThisObject);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	DateOnChangeServer();
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	OrganizationOnChangeServer();
	
EndProcedure

&AtClient
Procedure PartnerOnChange(Item)
	
	PartnerOnChangeServer();
	
EndProcedure

&AtClient
Procedure CounterpartyOnChange(Item)
	
	CounterpartyOnChangeServer();
	
EndProcedure

&AtClient
Procedure SourceDocumentTypeOnChange(Item)
	
	If PreviousPrimaryDocumentType <> Object.SourceDocumentType Then
		If PartnerSelectionParametersAreChanging(PreviousPrimaryDocumentType, Object.SourceDocumentType) Then
			Object.Partner = PredefinedValue("Catalog.Partners.EmptyRef");
			ClearCounterpartyWhenClearingPartner();
		EndIf;
		PreviousPrimaryDocumentType = Object.SourceDocumentType;
		AttachableCommandsClient.StartCommandUpdate(ThisObject);
		SourceDocumentTypeOnChangeServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure SourceDocumentTypeClearing(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure ARAPObjectSettingsOnChange(Item)
	
	ARAPObjectSettingsOnChangeServer();
	
EndProcedure

&AtClient
Procedure DocumentAmountOnChange(Item)
	
	Object.SumCompl = FillInLocalAmountsServer(Object.Organization, Object.DocumentAmount, LocalAccountingCurrency, Object.Currency, Object.Date, Object.Contract);
	FillInManAmounts();
	ClearAmountOfSettlements();
	
EndProcedure

&AtClient
Procedure CurrencyOnChange(Item)
	
	CurrencyOnChangeServer();
	
EndProcedure

&AtClient
Procedure ARAPCurrencyOnChange(Item)
	
	ARAPCurrencyOnChangeServer();
	
EndProcedure

&AtClient
Procedure ARAPObjectSettingsClearing(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure ContractCreating(Item, StandardProcessing)
	
	SalesClient.OpenContractCreationForm(ThisObject, Item, "Object.Contract", Object.Partner, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ContractOnChange(Item)
	
	ContractOnChangeServer();
	
EndProcedure

&AtClient
Procedure DepartmentOnChange(Item)
	
	DepartmentOnChangeServer();
	
EndProcedure

&AtClient
Procedure TextInvoiceURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	ClearMessages();
	
	If Object.SourceDocumentType = PredefinedValue("Enum.SourceDocumentTypes.SaleToCustomer")
		Or Object.SourceDocumentType = PredefinedValue("Enum.SourceDocumentTypes.GoodsShipmentToCustomer") Then
		RegistrationParameters = ParametersForRegisteringInvoicesIssuedServer(Object);
		VATAccountingERPClient.ProcessingNavigationLinkInvoicesIssued(
			ThisObject,
			FormattedStringURL,
			StandardProcessing,
			RegistrationParameters);
	ElsIf Not Object.SourceDocumentType = PredefinedValue("Enum.SourceDocumentTypes.VMIProcurement") Then
		RegistrationParameters = ParametersForRegisteringInvoicesReceivedServer(Object);
		VATAccountingERPClient.ProcessingNavigationLinkInvoicesReceived(
			ThisObject,
			FormattedStringURL,
			StandardProcessing,
			RegistrationParameters);
	EndIf;

EndProcedure

&AtClient
Procedure SupplierContractTypeOnChange(Item)
	
	WhenChangingSupplierContractTypes();
	
EndProcedure

&AtClient
Procedure LineOfBusinessOnChange(Item)
	
	LineOfBusinessOnChangeServer();
	
EndProcedure

&AtClient
Procedure LabelCurrenciesClick(Item, StandardProcessing)
	
	Notification = New CallbackDescription("LabelCurrenciesClickCompletion", ThisObject);
	ARAPAccountingClient.CurrencyAndExchangeRateOfDocument(ThisObject, Item, StandardProcessing, Notification);
	
EndProcedure

&AtClient
Procedure LabelCurrenciesClickCompletion(ClosingResult, AdditionalParameters) Export
	
	If ClosingResult = Undefined Then 
		Return;
	EndIf;
	
	If TypeOf(ClosingResult) = Type("Structure") Then
		
		ChangedBankingDetails = ClosingResult.OldValuesOfChangedProps;
		
		If ChangedBankingDetails.Count() > 0 Then
			
			LabelCurrenciesClickCompletionServer(ClosingResult);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure LabelCurrenciesClickCompletionServer(ClosingResult)
	
	ChangedBankingDetails = ClosingResult.OldValuesOfChangedProps;
	
	If ClosingResult.RecalculateDocumentAmounts Then
		Object.DocumentAmount = ClosingResult.DocumentAmount;
		CurrencyOnChangeServer();
	EndIf;
	
	If ChangedBankingDetails.Property("ARAPCurrency") Then
		ARAPCurrencyOnChangeServer();
	EndIf;
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, ChangedBankingDetails, True);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtServerNoContext
Function HaveRightToAddAdjustments(SourceDocumentType)
	
	If SourceDocumentType = Enums.SourceDocumentTypes.PurchaseFromVendor Then
		Return AccessRight("Insert", Metadata.Documents.PurchaseAdjustment);
	ElsIf SourceDocumentType = Enums.SourceDocumentTypes.SaleToCustomer Then
		Return AccessRight("Insert", Metadata.Documents.SaleAdjustment);
	EndIf;
	
EndFunction
&AtClient
Procedure InvoicePaymentStatus(Command)
	
	VATAccountingERPClient.OpenInvoiceVATPaymentStateForm(Object.Ref, ThisObject);
	
EndProcedure
#EndRegion

#Region CommandEventHandlers

&AtClient
Procedure PostAndClose(Command)
	
	CloseAfterWrite = True;
	Write(New Structure("WriteMode", DocumentWriteMode.Posting));
	
EndProcedure

#EndRegion

#Region Private

#Region ControlOfInconsistentChanges

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure ControlOfNonConsistentChangesHandleEventOnChange(Item)
	
	If Item.Name = "Partner" Then
		PartnerOnChange(Item);
	ElsIf Item.Name = "Date" Then
		DateOnChange(Item);
	ElsIf Item.Name = "Contract" Then
		ContractOnChange(Item);
	ElsIf Item.Name = "Currency" Then
		CurrencyOnChange(Item);
	ElsIf Item.Name = "Organization" Then
		OrganizationOnChange(Item);
	ElsIf Item.Name = "Counterparty" Then
		CounterpartyOnChange(Item);
	ElsIf Item.Name = "SourceDocumentType" Then
		SourceDocumentTypeOnChange(Item);
	ElsIf Item.Name = "ARAPObjectSettings" Then
		ARAPObjectSettingsOnChange(Item);
	ElsIf Item.Name = "Department" Then
		DepartmentOnChange(Item);
	Else
		TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisObject, Item);
	EndIf;
	
EndProcedure

&AtClient
Function PerformChecksBeforeChangingStatus()
	
	Var ThereAreInvoices_1;
	
	PropsCanBeChanged = False;
	UseDebitNotes = True;
	
	AdditionalParameters = New Structure;
	Notification = New CallbackDescription(
			"QuestionResultCompletion", ThisObject, AdditionalParameters);
	
	ClearMessages();
	
	UseAdjustments = False;
	If Object.SourceDocumentType = PredefinedValue("Enum.SourceDocumentTypes.PurchaseFromVendor") Then
		UseAdjustments = UseDebitNotes;
	ElsIf Object.SourceDocumentType = PredefinedValue("Enum.SourceDocumentTypes.SaleToCustomer") Then
		UseAdjustments = UseCreditNotes;
	EndIf;
	
	If UseAdjustments Then
		
		CheckForAdjustmentsAndInvoices(ThereAreAdjustingEntries, ThereAreInvoices_1);
		
		If Not HaveRightToAddAdjustments(Object.SourceDocumentType) And (ThereAreAdjustingEntries Or ThereAreInvoices_1) Then
			
			If ThereAreAdjustingEntries Then
				MessageText = NStr("vi = 'Trên cơ sở chứng từ đã nhập điều chỉnh.
					|Không đủ quyền để tạo điều chỉnh.';
					|ru = 'На основании документа введена корректировка.
					|Недостаточно прав для создания корректировки.';
					|en = 'Adjustment is entered based on the document.
					|Insufficient rights to create an adjustment.'; fa = 'Adjustment is entered based on the document.
					|Insufficient rights to create an adjustment.';
					|it = 'Nel documento di base è stata inserita una correzione.
					|Diritti insufficienti per creare una correzione.';
					|pl = 'Na podstawie dokumentu wprowadzono korektę.
					|Nie wystarcza praw do utworzenia korekty.';
					|tr = 'Belge bazında bir düzeltme girildi.
					|Düzeltme oluşturmak için erişim yetkisi mevcut değil.'");
			Else
				MessageText = NStr("vi = 'Trên cơ sở chứng từ có ghi nhận hóa đơn GTGT.
					|Không đủ quyền để tạo điều chỉnh.';
					|ru = 'На основании документа зарегистрирован счет-фактура.
					|Недостаточно прав для создания корректировки.';
					|en = 'Tax invoice is registered based on the document.
					|Insufficient rights to create an adjustment.'; fa = 'Tax invoice is registered based on the document.
					|Insufficient rights to create an adjustment.';
					|it = 'Nel documento di base è registrata una fattura.
					|Diritti insufficienti per creare una correzione.';
					|pl = 'Na podstawie dokumentu zarejestrowano fakturę.
					|Niewystarczające uprawnienia do utworzenia korekty.';
					|tr = 'Belge esasında vergi faturası kaydedildi.
					|Düzeltme oluşturmak için erişim yetkisi eksik.'");
			EndIf;
			
			CommonClient.MessageToUser(MessageText);
			
		ElsIf ThereAreAdjustingEntries And UseAdjustments Then
			
			ButtonsList = New ValueList;
			ButtonsList.Add("EnterTheAdjustment", NStr("vi = 'Nhập điều chỉnh';
														|ru = 'Ввести корректировку';
														|en = 'Enter the adjustment'; fa = 'Enter the adjustment';
														|it = 'Inserire rettifica';
														|pl = 'Wprowadź korektę';
														|tr = 'Bir düzenleme yapın'"));
			ButtonsList.Add("UndoChanges", NStr("vi = 'Hủy bỏ';
												|ru = 'Отмена';
												|en = 'Cancel'; fa = 'انصراف';
												|it = 'Annulla';
												|pl = 'Cancel';
												|tr = 'İptal'"));
			
			ShowQueryBox(
				Notification,
				NStr("vi = 'Trên cơ sở chứng từ đã nhập điều chỉnh.
					|Cấm thay đổi chứng từ gốc.';
					|ru = 'На основании документа введена корректировка.
					|Изменение исходного документа запрещено.';
					|en = 'Adjustment is generated based on the document.
					|The source document cannot be changed.'; fa = 'Adjustment is generated based on the document.
					|The source document cannot be changed.';
					|it = 'È stata inserita una rettifica sulla base del documento.
					|È vietato modificare il documento originale.';
					|pl = 'Na podstawie dokumentu wprowadzono korektę.
					|Zmiana dokumentu źródłowego jest zabroniona.';
					|tr = 'Belge temelinde düzeltme girildi.
					|Orijinal belgenin değiştirilmesi yasaktır.'"),
				ButtonsList,
				,
				"EnterTheAdjustment");
		Else
		
			RunCallback(Notification, "ChangeAttribute");
			PropsCanBeChanged = True;
		
		EndIf;
		
	Else
		
		RunCallback(Notification, "ChangeAttribute");
		PropsCanBeChanged = True;
		
	EndIf;
	
	Return PropsCanBeChanged;
	
EndFunction

&AtClient
Procedure QuestionResultCompletion(ResponseCode, AdditionalParameters) Export
	
	If ResponseCode = "EnterTheAdjustment" Then // "Enter an adjustment"
		
		If Object.SourceDocumentType = PredefinedValue("Enum.SourceDocumentTypes.PurchaseFromVendor") Then
			OpenForm("Document.PurchaseAdjustment.Form.DocumentFormBeforeBalanceEntry", New Structure("Basis", Object.Ref));
		ElsIf Object.SourceDocumentType = PredefinedValue("Enum.SourceDocumentTypes.SaleToCustomer") Then
			OpenForm("Document.SaleAdjustment.Form.DocumentFormBeforeBalanceEntry", New Structure("Basis", Object.Ref));
		EndIf;

	EndIf;
	
EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure Attachable_WhenChanging_SetAvailabilityOfItemsByStatusServer(Item)
	
	If Not PerformChecksBeforeChangingStatus() Then
		TMCommonUseClient.ReturnPreviousPropsValue(ThisObject, Item);
		Return;
	Else
		TMCommonUseClient.SaveAttributeValue(ThisObject, Item);
	EndIf;
	
	If TMCommonUseClient.WhenActingOnStatusDependentElement(ThisObject) Then
		Return;
	EndIf;
	
	If StructureOfActionsControlOfNonAgreedChanges.OnChange.Property(Item.Name) Then
		ControlOfNonConsistentChangesHandleEventOnChange(Item);
	EndIf;
	
EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure Attachable_Clicking_SetAvailabilityOfItemsByStatusServer(Item)
	
	If TMCommonUseClient.WhenActingOnStatusDependentElement(ThisObject) Then
		Return;
	EndIf;
	
	If StructureOfActionsControlOfNonAgreedChanges.Click.Property(Item.Name) Then
		ControlOfNonConsistentChangesHandlePushEvent(Item);
	EndIf;

EndProcedure

&AtClient
Procedure ControlOfNonConsistentChangesHandlePushEvent(Item)
	TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisObject, Item);
EndProcedure

&AtClient
Procedure Attachable_WhenChangingDetailsDependingOnStatus()
	
	SetAvailabilityOfItemsByStatusServer();
	TMCommonUseClient.AfterChangingPropsDependentOnStatus(ThisObject);
	
EndProcedure

#EndRegion

&AtServer
Procedure WhenChangingSupplierContractTypes()
	
	SetContractType();
	ContractOnChangeServer();
	
	ARAPAccountingFormWork.WhenChangingParametersOfMechanism(ThisObject);
	
	SetContractSelectionParameters();
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	DataCompositionClientServer.AddFieldToCreate(
		Item.Fields, 
		Items.Contract.Name);
		
	DataCompositionClientServer.AddFilter(
		Item.Filter, 
		"Object.Contract", 
		Undefined, 
		DataCompositionComparisonType.NotFilled);
		
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	DataCompositionClientServer.AddFilter(
		FilterGroup1, 
		"Object.ARAPObjectSettings", 
		Enums.ARAPObjectSettings.ByCounterpartyContracts, 
		DataCompositionComparisonType.Equal);
	
	DataCompositionClientServer.AddFilter(
		FilterGroup1, 
		"Object.SourceDocumentType", 
		Enums.SourceDocumentTypes.VMIProcurement, 
		DataCompositionComparisonType.Equal);
	
	DataCompositionClientServer.AddFilter(
		FilterGroup1,
		"Object.SourceDocumentType",
		Enums.SourceDocumentTypes.GoodsShipmentToCustomer,
		DataCompositionComparisonType.Equal);
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	DataCompositionClientServer.AddFieldToCreate(
		Item.Fields, 
		Items.Contract.Name);
		
	DataCompositionClientServer.AddFilter(
		Item.Filter, 
		"Object.Contract", 
		Undefined, 
		DataCompositionComparisonType.Filled);
		
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	DataCompositionClientServer.AddFieldToCreate(
		Item.Fields, 
		Items.IncomingDocumentDate.Name);
	
	DataCompositionClientServer.AddFilter(
		Item.Filter, 
		"Object.IncomingDocumentNumber", 
		Undefined, 
		DataCompositionComparisonType.NotFilled);
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	DataCompositionClientServer.AddFieldToCreate(
		Item.Fields, 
		Items.IncomingDocumentNumber.Name);
	
	DataCompositionClientServer.AddFilter(
		Item.Filter, 
		"Object.IncomingDocumentDate", 
		Undefined, 
		DataCompositionComparisonType.NotFilled);
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
EndProcedure

&AtServer
Procedure SetAvailabilityOfItemsByStatusServer()
	
	ItemArray = New Array;
	
	// Header Controls
	ItemArray.Add("SourceDocumentType");
	ItemArray.Add("Date");
	ItemArray.Add("Partner");
	ItemArray.Add("Terms");
	ItemArray.Add("Contract");
	ItemArray.Add("Currency");
	ItemArray.Add("Organization");
	ItemArray.Add("Counterparty");
	ItemArray.Add("VATTaxation");
	ItemArray.Add("ARAPObjectSettings");
	ItemArray.Add("Department");
	
	TMCommonUse.SetSubscriptionForFormElementChangeEvents(ThisObject, ItemArray);
	
EndProcedure

&AtServer
Procedure SetLBEditingOption()
	
	LBAvailabilityParameters = LinesOfBusinessServer.ParametersLBEditingCapability();
	
	LBAvailabilityParameters.Contract           = Object.Contract;
	LBAvailabilityParameters.ARAPObjectSettings   = ?(AccordingToOrdersThisIsAccordingToDocuments, Enums.ARAPObjectSettings.ByARAPDocuments, Object.ARAPObjectSettings);
	
	LinesOfBusinessServer.SetLBEditingOption(ThisObject, LBAvailabilityParameters);
	
EndProcedure

#Region BSPServiceProceduresAndFunctions

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion

&AtServer
Procedure OnReadCreateAtServer()
	
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	ManagementAccountingCurrency = SettingsValueCached.ManagementAccountingCurrency();
	
	UseDebitNotes = GetFunctionalOption("UseDebitNotes");
	UseCreditNotes = GetFunctionalOption("UseCreditNotes");
	UsePartnersAsCounterparties = GetFunctionalOption("UsePartnersAsCounterparties");
	
	PurchasesServer.FillInSelectionListNameOfIncomingDocument(ThisObject, Object.Counterparty);
	
	TypeOfValueEnteringBalances     = VATAccountingLocalization.TypeOfValueEnteringBalances(Object.Ref);
	NotPaymentOfNDSVBudgetIsRequired = Not (TypeOfValueEnteringBalances = Enums.AssetKinds.CustomsPayments
		Or TypeOfValueEnteringBalances = Enums.AssetKinds.CustomsUnion);
		
	ARAPCurrency = Object.ARAPCurrency;
	PreviousPrimaryDocumentType = Object.SourceDocumentType;
	ContractType = Enums.ContractTypes.EmptyRef();
	
	If ValueIsFilled(Object.Contract) Then
		If TypeOf(Object.Contract) = Type("CatalogRef.CounterpartyContracts")
			Or TypeOf(Object.Contract) = Type("CatalogRef.IntercompanyContracts") Then
			ContractType = Common.ObjectAttributeValue(Object.Contract, "ContractType");
			AccordingToOrdersThisIsAccordingToDocuments = ContractType = Enums.ContractTypes.WithConsignee
			                           Or ContractType = Enums.ContractTypes.WithConsignor
			                           Or ContractType = Enums.TypesOfIntercompanyContracts.Consignment
			                           Or ContractType = Enums.ContractTypes.TransferToCustody
			                           Or ContractType = Enums.ContractTypes.ReceivingForCustody;
		ElsIf TypeOf(Object.Contract) = Type("CatalogRef.LeaseContract") Then
			SupplierContractType = 1;
		EndIf;
	EndIf;
	
	CompleteVATTaxation();

	VATAccountingERP.SetTitleOfStateOfVATPaymentOnInvoice(
		Object.Ref,
		Items.InvoicePaymentStatus,
		NotPaymentOfNDSVBudgetIsRequired);
		
	ARAPAccountingFormWork.FormWhenReadingOnServer(ThisObject);
	
	SetVisibilityOfPaymentStatusOnInvoice(NotPaymentOfNDSVBudgetIsRequired);
	SetPartnerSelectionParameters();
	SetCounterpartySelectionParameters();
	SetContractSelectionParameters();
	SetParametersForSelectingFinancialAccountingGroup();
	SetParametersForSelectingDirectionOfActivity();
	FillInListOfChoosingOrderOfCalculations();
	FillInPrimaryDocumentTypeSelectionList();
	SetHeader();
	CustomizeInvoicePresentation();
	FormControl();
	SetAvailabilityOfItemsByStatusServer();
	UpdateFlagThereAreAdjustments();
	
EndProcedure

&AtServer
Procedure CustomizeInvoicePresentation()
	
	Items.TextInvoice.ToolTip = "";
	
	If Object.SourceDocumentType = Enums.SourceDocumentTypes.SaleToCustomer Then
		RegistrationParameters = Documents.SourceDocument.ParametersForRegisteringInvoicesIssued(Object);
		InvoicesIssuedOnBasisOf = VATAccountingERP.InvoicesIssuedOnBasisOf(RegistrationParameters);
		
		TextInvoice = SalesServer.CreatePresentationOfInvoiceGenerationCommandsBasedOn(
			Object.Ref, InvoicesIssuedOnBasisOf);
	
	ElsIf Object.SourceDocumentType = Enums.SourceDocumentTypes.GoodsShipmentToCustomer Then
		
		RegistrationParameters = Documents.SourceDocument.ParametersForRegisteringInvoicesIssued(Object);
		InvoicesIssuedOnBasisOf = VATAccountingERP.InvoicesIssuedOnBasisOf(RegistrationParameters);
		
		TextInvoice = SalesServer.CreatePresentationOfInvoiceGenerationCommandsBasedOn(
			Object.Ref, InvoicesIssuedOnBasisOf);
		
	ElsIf Not Object.SourceDocumentType = Enums.SourceDocumentTypes.VMIProcurement Then
		RegistrationParameters = Documents.SourceDocument.ParametersForRegisteringInvoicesReceived(Object);
		InvoicesReceivedOnBasisOf = VATAccountingERP.InvoicesReceivedOnBasisOf(RegistrationParameters);
		
		TextInvoice = InvoicesReceivedOnBasisOf.Presentation;
		
	Else
		TextInvoice = Undefined;
	EndIf;

	MaximumTextWidthInvoice = 77;
	LineLengthTextInvoice = StrLen(TextInvoice);
	Items.TextInvoice.MaxWidth = Round(
		Min(LineLengthTextInvoice, MaximumTextWidthInvoice) * 0.75,
		0);
	
EndProcedure

&AtServer
Procedure FormControl()
	
	DocumentAttributes = Documents.SourceDocument.ArrayOfDetailsByPrimaryDocumentType(Object.SourceDocumentType);
	
	CashServer.SetVisibilityOfElementsByArray(
		Items,
		DocumentAttributes.ArrayOfAllProps,
		DocumentAttributes.ArrayOfDetailsForType);
		
	If DocumentAttributes.ArrayOfDetailsForType.Find("FinancialAccountingGroup") <> Undefined Then
		Items.FinancialAccountingGroup.Visible = (Object.ARAPObjectSettings = Enums.ARAPObjectSettings.ByARAPDocuments
			Or Object.ARAPObjectSettings = Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice
			Or Object.ARAPObjectSettings = Enums.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice
			Or Object.ARAPObjectSettings = Enums.ARAPObjectSettings.ByOrders
				And AccordingToOrdersThisIsAccordingToDocuments);
	EndIf;
	
	If DocumentAttributes.ArrayOfDetailsForType.Find("LineOfBusiness") <> Undefined Then
		SetLBEditingOption();
	EndIf;
	
	Items.ARAPObjectSettings.Enabled = Not ValueIsFilled(Object.Contract);
	
	If UsePartnersAsCounterparties
		And Object.Partner <> Catalogs.Partners.OurEnterprise
		And Object.SourceDocumentType <> Enums.SourceDocumentTypes.PurchaseViaAdvanceHolder Then
		
		Items.Counterparty.Visible = False;
		
	EndIf;

	ContractVisibility = False;
	If Object.SourceDocumentType = Enums.SourceDocumentTypes.PaymentFromCustomer
		Or Object.SourceDocumentType = Enums.SourceDocumentTypes.ReportToMaterialProvider
		Or Object.SourceDocumentType = Enums.SourceDocumentTypes.SaleToCustomer
		Or Object.SourceDocumentType = Enums.SourceDocumentTypes.GoodsShipmentToCustomer
		Or Object.SourceDocumentType = Enums.SourceDocumentTypes.CustomerBonusCertificate
		Or Object.SourceDocumentType = Enums.SourceDocumentTypes.SaleAdjustment Then
		
		If Object.Partner = Catalogs.Partners.OurEnterprise Then
			ContractVisibility = GetFunctionalOption("UseIntercompanyContracts");
		Else
			ContractVisibility = GetFunctionalOption("UseCustomerContracts");
		EndIf;
		
	ElsIf Object.SourceDocumentType = Enums.SourceDocumentTypes.PaymentToVendor 
		Or Object.SourceDocumentType = Enums.SourceDocumentTypes.VendorBonusCertificate
		Or Object.SourceDocumentType = Enums.SourceDocumentTypes.PurchaseFromVendor 
		Or Object.SourceDocumentType = Enums.SourceDocumentTypes.SubcontractorReport 
		Or Object.SourceDocumentType = Enums.SourceDocumentTypes.PurchaseAdjustment Then
		
		If Object.Partner = Catalogs.Partners.OurEnterprise Then
			ContractVisibility = GetFunctionalOption("UseIntercompanyContracts");
		Else
			ContractVisibility = GetFunctionalOption("UseContractsWithVendors");
		EndIf;
	ElsIf Object.SourceDocumentType = Enums.SourceDocumentTypes.VMIProcurement Then
		ContractVisibility = True;
	Else
		ContractVisibility= False;
	EndIf;
	Items.Contract.Visible = ContractVisibility;
	
	If TradeManagement Then
		
		Items.SupplierContractType.Visible = False;
		SupplierContractType = 0;
		
	ElsIf ContractVisibility = False
		Or Not (Object.SourceDocumentType = Enums.SourceDocumentTypes.PurchaseFromVendor
				Or Object.SourceDocumentType = Enums.SourceDocumentTypes.PaymentToVendor
				Or Object.SourceDocumentType = Enums.SourceDocumentTypes.SubcontractorReport
				Or Object.SourceDocumentType = Enums.SourceDocumentTypes.PurchaseAdjustment) Then
		
		Items.SupplierContractType.Visible = False;
		
	Else
		
		Items.SupplierContractType.Visible = True;
		
	EndIf;
	
	Items.SumCompl.Enabled = (Object.Currency <> LocalAccountingCurrency);
	Items.SumMan.Enabled = (Object.Currency <> ManagementAccountingCurrency);
	
EndProcedure

&AtServer
Procedure SetVisibilityOfPaymentStatusOnInvoice(NotPaymentOfNDSVBudgetIsRequired)
	Items.PaymentConfirmed.Visible = Not NotPaymentOfNDSVBudgetIsRequired;
EndProcedure

&AtServer
Procedure SourceDocumentTypeOnChangeServer()
	
	Object.LineOfBusiness = Catalogs.LinesOfBusiness.EmptyRef();
	
	If	SupplierContractType = 1
			And Not (Object.SourceDocumentType = Enums.SourceDocumentTypes.PurchaseFromVendor
					Or Object.SourceDocumentType = Enums.SourceDocumentTypes.PaymentToVendor
					Or Object.SourceDocumentType = Enums.SourceDocumentTypes.SubcontractorReport
					Or Object.SourceDocumentType = Enums.SourceDocumentTypes.PurchaseAdjustment) Then
		
		SupplierContractType = 0;
	EndIf;
	
	SetContractType();
	SetPartnerSelectionParameters();
	SetCounterpartySelectionParameters();
	SetContractSelectionParameters();
	SetParametersForSelectingFinancialAccountingGroup();
	SetParametersForSelectingDirectionOfActivity();
	ClearCounterpartyWhenClearingPartner();
	
	CompleteVATTaxation();
	FillInListOfChoosingOrderOfCalculations(False);
	
	ARAPAccountingFormWork.WhenChangingParametersOfMechanism(ThisObject);
	
	SetHeader();
	CustomizeInvoicePresentation();
	FormControl();
	
EndProcedure

&AtServer
Procedure DateOnChangeServer()
	
	CompleteVATTaxation();
	
EndProcedure

&AtServer
Procedure OrganizationOnChangeServer()
	
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	If Not ValueIsFilled(Object.Currency) Then
		Object.Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	EndIf;
	
	SetContractType();
	SetContractSelectionParameters();
	FormControl();
	CustomizeInvoicePresentation();
	
	CompleteVATTaxation();
	
EndProcedure

&AtServer
Procedure ARAPObjectSettingsOnChangeServer()
	
	If Object.ARAPObjectSettings <> Enums.ARAPObjectSettings.ByARAPDocuments Then
		Object.FinancialAccountingGroup = Undefined;
		Object.LineOfBusiness = Undefined;
	EndIf;
	
	SetContractSelectionParameters();
	FormControl();
	
EndProcedure

&AtServer
Procedure CurrencyOnChangeServer()
	
	FillInLocalAmounts();
	FillInManAmounts();
	ClearAmountOfSettlements();
	SetContractType();
	SetContractSelectionParameters();
	FormControl();
	
EndProcedure

&AtServer
Procedure ARAPCurrencyOnChangeServer()
	
	If ARAPCurrency <> Object.ARAPCurrency Then
		Object.Contract = Catalogs.CounterpartyContracts.EmptyRef();
	EndIf;
	
	ClearAmountOfSettlements();
	SetContractType();
	SetContractSelectionParameters();
	FormControl();
	
EndProcedure

&AtServer
Procedure PartnerOnChangeServer()
	
	If Object.Partner = Catalogs.Partners.OurEnterprise Then
		If TypeOf(Object.Counterparty) <> Type("CatalogRef.Companies") Then
			Object.Counterparty = Catalogs.Companies.EmptyRef();
		EndIf;
	Else
		PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Object.Partner, Object.Counterparty);
	EndIf;
	
	SetContractType();
	SetContractSelectionParameters();
	FillInListOfChoosingOrderOfCalculations();
	
	CustomizeInvoicePresentation();
	FormControl()
	
EndProcedure

&AtServer
Procedure CounterpartyOnChangeServer()
	
	If TypeOf(Object.Counterparty) = Type("CatalogRef.Companies") 
		And Object.Partner <> Catalogs.Partners.OurEnterprise Then
		Object.Partner = Catalogs.Partners.OurEnterprise;
	EndIf;
	
	CompleteVATTaxation();
	SetContractType();
	SetContractSelectionParameters();
	FormControl();
	PurchasesServer.FillInSelectionListNameOfIncomingDocument(ThisObject, Object.Counterparty);
	
EndProcedure

&AtServer
Procedure ContractOnChangeServer()
	
	AccordingToOrdersThisIsAccordingToDocuments = False;
	ContractType = Enums.ContractTypes.EmptyRef();
	
	If ValueIsFilled(Object.Contract) Then
		
		If TypeOf(Object.Contract) = Type("CatalogRef.CounterpartyContracts")
			Or TypeOf(Object.Contract) = Type("CatalogRef.IntercompanyContracts") Then
			
			ContractDetails_ = "VATTaxation, FinancialAccountingGroup, ARAPObjectSettings, ARAPCurrency, ContractType";
			If TypeOf(Object.Contract) = Type("CatalogRef.CounterpartyContracts") Then
				ContractDetails_ = "Department, LineOfBusiness, VATTaxation, FinancialAccountingGroup, ARAPObjectSettings, ARAPCurrency, ContractType";
			EndIf;
			
			ContractDetails_ =
				Common.ObjectAttributesValues(
					Object.Contract,
					ContractDetails_);
			
			SettlementProcedureForContracts = ContractDetails_.ARAPObjectSettings;
			
			If Object.ARAPObjectSettings <> SettlementProcedureForContracts Then
				Object.ARAPObjectSettings = SettlementProcedureForContracts;
			EndIf;
			
			If TypeOf(Object.Contract) = Type("CatalogRef.CounterpartyContracts") Then
				Object.Department = ContractDetails_.Department;
				Object.LineOfBusiness = ContractDetails_.LineOfBusiness;
				Object.FinancialAccountingGroup = ContractDetails_.FinancialAccountingGroup;
				
				If Object.SourceDocumentType = Enums.SourceDocumentTypes.CustomerBonusCertificate
				 Or Object.SourceDocumentType = Enums.SourceDocumentTypes.VendorBonusCertificate Then
					
					// For the act of premium always calculations on invoices
					Object.ARAPObjectSettings = Enums.ARAPObjectSettings.ByARAPDocuments;
					
				EndIf;
				
			EndIf;
			
			ContractType = ContractDetails_.ContractType;
			AccordingToOrdersThisIsAccordingToDocuments = ContractDetails_.ContractType = Enums.ContractTypes.WithConsignee
			                           Or ContractDetails_.ContractType = Enums.ContractTypes.WithConsignor
			                           Or ContractDetails_.ContractType = Enums.TypesOfIntercompanyContracts.Consignment
			                           Or ContractDetails_.ContractType = Enums.ContractTypes.TransferToCustody
			                           Or ContractDetails_.ContractType = Enums.ContractTypes.ReceivingForCustody;
		ElsIf TypeOf(Object.Contract) = Type("CatalogRef.LeaseContract") Then
			Object.ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts;
			
			ContractDetails_ = "ARAPCurrency";
			ContractDetails_ =
				Common.ObjectAttributesValues(
					Object.Contract,
					ContractDetails_);
		EndIf;
		
		If Object.ARAPCurrency <> ContractDetails_.ARAPCurrency Then
			Object.ARAPCurrency = ContractDetails_.ARAPCurrency;
			ARAPCurrency = Object.ARAPCurrency;
			
			AttributesArray = New Array;
			AttributesArray.Add("ARAPCurrency");
			AttributesArray.Add("AmountARAP");
			AttributesArray.Add("Contract");
			ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, AttributesArray);
		EndIf;
		
	EndIf;
	
	SetParametersForSelectingFinancialAccountingGroup();
	CompleteVATTaxation();
	
	FormControl();
	
EndProcedure

&AtServer
Procedure LineOfBusinessOnChangeServer()
	
	CompleteVATTaxation();
	
EndProcedure

&AtServer
Procedure DepartmentOnChangeServer()
	
	CompleteVATTaxation();
	
EndProcedure

&AtServer
Procedure SetContractType()
	
	If Object.Partner = Catalogs.Partners.OurEnterprise Then
		
		If TypeOf(Object.Contract) <> Type("CatalogRef.IntercompanyContracts") Then
			Object.Contract = Catalogs.IntercompanyContracts.EmptyRef();
		EndIf;
		
	ElsIf SupplierContractType = 0
		Or Object.SourceDocumentType = Enums.SourceDocumentTypes.ReportToMaterialProvider
		Or Object.SourceDocumentType = Enums.SourceDocumentTypes.VMIProcurement Then
		
		If TypeOf(Object.Contract) <> Type("CatalogRef.CounterpartyContracts") Then
			Object.Contract = Catalogs.CounterpartyContracts.EmptyRef();
		EndIf;
		
	Else
		If TypeOf(Object.Contract) <> Type("CatalogRef.LeaseContract") Then
			Object.Contract = Catalogs.LeaseContract.EmptyRef();
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInLocalAmounts()
	
	Object.SumCompl = ProcessingOfExchangeRatesTM.ConvertToCurrency(
							Object.DocumentAmount,
							SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization),
							Object.Currency,
							LocalAccountingCurrency,
							Object.Date);
							
EndProcedure

&AtServer
Procedure FillInManAmounts()
	
	Object.SumMan = ProcessingOfExchangeRatesTM.ConvertToCurrency(
							Object.DocumentAmount,
							SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization),
							Object.Currency,
							ManagementAccountingCurrency,
							Object.Date);
	
	ARAPAccountingClientServer.UpdateHyperlinkText(ThisObject);
	
EndProcedure

&AtServer
Procedure ClearAmountOfSettlements()
	
	Object.AmountARAP = 0;
	
	ARAPAccountingClientServer.UpdateHyperlinkText(ThisObject);
	
EndProcedure

&AtServerNoContext
Function FillInLocalAmountsServer(Organization, DocumentAmount, CurrencyReg, Currency, Date, Contract)
	
	ContractRateOption = Enums.ContractRateOptions.Mutable;
	If ValueIsFilled(Contract)
		And (TypeOf(Contract) = Type("CatalogRef.CounterpartyContracts")
			Or TypeOf(Contract) = Type("CatalogRef.IntercompanyContracts"))Then
		ContractRateOption = Common.ObjectAttributeValue(Contract, "ContractRateOption");
	EndIf;
	
	If ContractRateOption = Enums.ContractRateOptions.SpecifiedInContract Then
		ParametersOfContractCourseOption = ProcessingOfExchangeRatesTM.ParametersOfContractCourseOption();
		ParametersOfContractCourseOption.ContractRateOption = ContractRateOption;
		ParametersOfContractCourseOption.ARAPCurrency = Currency;
		ParametersOfContractCourseOption.Contract              = Contract;
		ConversionFactor_ = ProcessingOfExchangeRatesTM.GetConversionFactorFromCurrencyToCurrency(
								Currency, 
								CurrencyReg, 
								Date,,
								ParametersOfContractCourseOption); 
		SumCompl = Round(DocumentAmount * ConversionFactor_, 2, 1);
	Else
		SumCompl = ProcessingOfExchangeRatesTM.ConvertToCurrency(
								DocumentAmount,
								SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization),
								Currency,
								CurrencyReg,
								Date);
	EndIf;
	
	Return SumCompl;
	
EndFunction

&AtServer
Procedure SetHeader()
	
	If ValueIsFilled(Object.Ref) Then
		Title = StrTemplate(NStr("vi = '%1 %2 ngày %3';
								|ru = '%1 %2 от %3';
								|en = '%1 %2 dated %3'; fa = '%1 %2 dated %3';
								|it = '%1 %2 del %3';
								|pl = '%1 %2 z dnia %3';
								|tr = '%3 tarihli %1 %2'"), Object.SourceDocumentType, TrimAll(Object.Number), Object.Date);
		TMCommonUseClientServer.ProcessingReceivingPresentationOfIncomingDocument(
			Object, Title, Undefined, "SourceDocument");
	Else
		Title = StrTemplate(NStr("vi = '%1 (tạo mới)';
								|ru = '%1 (создание)';
								|en = '%1 (Create)'; fa = '%1 (Create)';
								|it = '%1 (creazione)';
								|pl = '%1 (utworzenie)';
								|tr = '%1 (oluşturma)'"), Object.SourceDocumentType);
	EndIf;
	
EndProcedure

&AtServer
Procedure SetPartnerSelectionParameters()
	
	ParametersArray = New Array;
	If Object.SourceDocumentType = Enums.SourceDocumentTypes.PaymentFromCustomer
		Or Object.SourceDocumentType = Enums.SourceDocumentTypes.SaleToCustomer
		Or Object.SourceDocumentType = Enums.SourceDocumentTypes.GoodsShipmentToCustomer
		Or Object.SourceDocumentType = Enums.SourceDocumentTypes.CustomerBonusCertificate
		Or Object.SourceDocumentType = Enums.SourceDocumentTypes.SaleAdjustment Then
		ParametersArray.Add(New ChoiceParameter("Filter.Client", True));
	ElsIf Object.SourceDocumentType = Enums.SourceDocumentTypes.VMIProcurement
		Or Object.SourceDocumentType = Enums.SourceDocumentTypes.ReportToMaterialProvider
		Or False Then
		ParametersArray.Add(New ChoiceParameter("Filter.Client", True));
		ParametersArray.Add(New ChoiceParameter("Filter.Vendor", True));
	Else
		ParametersArray.Add(New ChoiceParameter("Filter.Vendor", True));
	EndIf;
	If GetFunctionalOption("UseCustomerInvoiceIntercompany")
		And Not Object.SourceDocumentType = Enums.SourceDocumentTypes.VMIProcurement Then
		ParametersArray.Add(New ChoiceParameter("SetSelectionByPartnerTypeAsOR", True));
		ParametersArray.Add(New ChoiceParameter("Filter.OurEnterprise", True));
	EndIf;
	Items.Partner.ChoiceParameters = New FixedArray(ParametersArray);
	
EndProcedure

&AtServer
Procedure SetCounterpartySelectionParameters()
	
	If Object.SourceDocumentType = Enums.SourceDocumentTypes.PurchaseViaAdvanceHolder Then
		Items.Counterparty.ChoiceParameterLinks = New FixedArray(New Array);
		Items.Counterparty.TypeRestriction = New TypeDescription("CatalogRef.Counterparties");
	Else
		ParametersArray = New Array;
		ParametersArray.Add(New ChoiceParameterLink("Filter.Partner", "Object.Partner"));
		Items.Counterparty.ChoiceParameterLinks = New FixedArray(ParametersArray);
	EndIf;
	
EndProcedure

&AtServer
Procedure ClearCounterpartyWhenClearingPartner()
	
	If Not ValueIsFilled(Object.Partner) Then
		If TypeOf(Object.Counterparty) = Type("CatalogRef.Counterparties") Then
			Object.Counterparty = Catalogs.Counterparties.EmptyRef();
		Else
			Object.Counterparty = Catalogs.Companies.EmptyRef();
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure SetContractSelectionParameters()
	
	ArrayOfContractSelectionParameters = New Array;
	
	If ValueIsFilled(Object.ARAPCurrency) Then
		ArrayOfContractSelectionParameters.Add(New ChoiceParameter("Filter.ARAPCurrency", Object.ARAPCurrency));
	EndIf;
	
	If SupplierContractType = 0
		And Object.SourceDocumentType <> Enums.SourceDocumentTypes.CustomerBonusCertificate
		And Object.SourceDocumentType <> Enums.SourceDocumentTypes.VendorBonusCertificate
		And Object.SourceDocumentType <> Enums.SourceDocumentTypes.VMIProcurement Then
		ArrayOfContractSelectionParameters.Add(New ChoiceParameter("Filter.ARAPObjectSettings", Object.ARAPObjectSettings));
	EndIf;
	
	If Object.Partner = Catalogs.Partners.OurEnterprise Then
		
		If Object.SourceDocumentType = Enums.SourceDocumentTypes.PaymentFromCustomer
			Or Object.SourceDocumentType = Enums.SourceDocumentTypes.SaleToCustomer
			Or Object.SourceDocumentType = Enums.SourceDocumentTypes.GoodsShipmentToCustomer Then
			ArrayOfContractSelectionParameters.Add(New ChoiceParameter("Filter.Organization",           Object.Organization));
			ArrayOfContractSelectionParameters.Add(New ChoiceParameter("Filter.CompanyRecipient", Object.Counterparty));
		Else
			ArrayOfContractSelectionParameters.Add(New ChoiceParameter("Filter.Organization",           Object.Counterparty));
			ArrayOfContractSelectionParameters.Add(New ChoiceParameter("Filter.CompanyRecipient", Object.Organization));
		EndIf;
		
	Else
		
		ArrayOfContractTypes = New Array;
		If Object.SourceDocumentType  = Enums.SourceDocumentTypes.PaymentFromCustomer
			Or Object.SourceDocumentType = Enums.SourceDocumentTypes.SaleToCustomer
			Or Object.SourceDocumentType = Enums.SourceDocumentTypes.GoodsShipmentToCustomer
			Or Object.SourceDocumentType = Enums.SourceDocumentTypes.SaleAdjustment Then
			
			ArrayOfContractTypes = ARAPAccountingClientServer.TypesOfContractsWithClient().UnloadValues();
			ArrayOfContractTypes.Add(PredefinedValue("Enum.ContractTypes.WithConsignor"));
			If Not Object.SourceDocumentType  = Enums.SourceDocumentTypes.PaymentFromCustomer Then
			EndIf;
			ArrayOfContractSelectionParameters.Add(New ChoiceParameter("ShowSalesThroughCommissionAgent", True));
			
		ElsIf Object.SourceDocumentType = Enums.SourceDocumentTypes.CustomerBonusCertificate Then
			
			ArrayOfContractTypes.Add(PredefinedValue("Enum.ContractTypes.WithCustomer"));
			
		ElsIf Object.SourceDocumentType = Enums.SourceDocumentTypes.VendorBonusCertificate Then
			
			ArrayOfContractTypes.Add(PredefinedValue("Enum.ContractTypes.WithVendor"));
			ArrayOfContractTypes.Add(PredefinedValue("Enum.ContractTypes.PurchaseEAEU"));
			ArrayOfContractTypes.Add(PredefinedValue("Enum.ContractTypes.Import"));
			ArrayOfContractTypes.Add(PredefinedValue("Enum.ContractTypes.ReceivingForCustody"));
			
		ElsIf Object.SourceDocumentType = Enums.SourceDocumentTypes.VMIProcurement
			Or Object.SourceDocumentType = Enums.SourceDocumentTypes.ReportToMaterialProvider
			Or False Then
			ArrayOfContractTypes.Add(PredefinedValue("Enum.ContractTypes.ReceiptForTolling2_5"));
		
		Else
			
			ArrayOfContractTypes = ARAPAccountingClientServer.TypesOfContractsWithSupplier().UnloadValues();
			If Object.SourceDocumentType = Enums.SourceDocumentTypes.PurchaseFromVendor Then
				ArrayOfContractTypes.Add(PredefinedValue("Enum.ContractTypes.CustomerInvoiceOutsourcedSale"));
			Else
				ArrayOfContractTypes.Add(PredefinedValue("Enum.ContractTypes.WithConsignee"));
				ArrayOfContractSelectionParameters.Add(New ChoiceParameter("ShowTransfersForCommission", True));
			EndIf;
		EndIf;
			
		If SupplierContractType = 0
			Or Object.SourceDocumentType = Enums.SourceDocumentTypes.ReportToMaterialProvider
			Or Object.SourceDocumentType  = Enums.SourceDocumentTypes.VMIProcurement Then
			ArrayOfContractSelectionParameters.Add(New ChoiceParameter("Filter.ContractType", New FixedArray(ArrayOfContractTypes)));
		EndIf;
		
		ArrayOfContractSelectionParameters.Add(New ChoiceParameter("Filter.Organization", Object.Organization));
		ArrayOfContractSelectionParameters.Add(New ChoiceParameter("Filter.Partner",     Object.Partner));
		ArrayOfContractSelectionParameters.Add(New ChoiceParameter("Filter.Counterparty",  Object.Counterparty));
		
	EndIf;
	
	If Object.SourceDocumentType  = Enums.SourceDocumentTypes.PaymentFromCustomer
		Or Object.SourceDocumentType = Enums.SourceDocumentTypes.PaymentToVendor Then
		ArrayOfContractSelectionParameters.Add(New ChoiceParameter("AllowSelectionOfBranchContracts", True));
	EndIf;
	
	Items.Contract.ChoiceParameters = New FixedArray(ArrayOfContractSelectionParameters);
	
EndProcedure

&AtServer
Procedure SetParametersForSelectingFinancialAccountingGroup()
	
	ArrayOfParametersForSelectingFinancialAccountingGroup = New Array;
	
	If Object.SourceDocumentType  = Enums.SourceDocumentTypes.PaymentFromCustomer
		Or Object.SourceDocumentType = Enums.SourceDocumentTypes.SaleToCustomer
		Or Object.SourceDocumentType = Enums.SourceDocumentTypes.GoodsShipmentToCustomer
		Or Object.SourceDocumentType = Enums.SourceDocumentTypes.CustomerBonusCertificate
		Or Object.SourceDocumentType = Enums.SourceDocumentTypes.SaleAdjustment Then
		If ContractType = Enums.ContractTypes.WithConsignee Then
			ArrayOfParametersForSelectingFinancialAccountingGroup.Add(New ChoiceParameter("Filter.CommissionAgentsARAPAccounting", True));
		ElsIf ContractType = Enums.ContractTypes.CustomerInvoiceOutsourcedSale Then
			ArrayOfParametersForSelectingFinancialAccountingGroup.Add(New ChoiceParameter("Filter.PurchaseSettlementsWithConsignors", True));
		Else
			ArrayOfParametersForSelectingFinancialAccountingGroup.Add(New ChoiceParameter("Filter.CustomersARAPAccounting", True));
		EndIf;
	ElsIf Object.SourceDocumentType  = Enums.SourceDocumentTypes.VMIProcurement
		Or Object.SourceDocumentType  = Enums.SourceDocumentTypes.ReportToMaterialProvider
		Or False Then
		ArrayOfParametersForSelectingFinancialAccountingGroup.Add(New ChoiceParameter("Filter.ProvidersARAP", True));
	ElsIf Object.SourceDocumentType  = Enums.SourceDocumentTypes.SubcontractorReport Then
		ArrayOfParametersForSelectingFinancialAccountingGroup.Add(New ChoiceParameter("Filter.SettlementsWithSubcontractor", True));
	Else
		If ContractType = Enums.ContractTypes.WithConsignor Then
			ArrayOfParametersForSelectingFinancialAccountingGroup.Add(New ChoiceParameter("Filter.ConsignorsARAPAccounting", True));
		Else
			ArrayOfParametersForSelectingFinancialAccountingGroup.Add(New ChoiceParameter("Filter.VendorsARAPAccounting", True));
		EndIf;
	EndIf;
	
	Items.FinancialAccountingGroup.ChoiceParameters = New FixedArray(ArrayOfParametersForSelectingFinancialAccountingGroup);
	
EndProcedure

&AtServer
Procedure SetParametersForSelectingDirectionOfActivity()
	
	ArrayOfParametersForSelectingDirectionOfActivity = New Array;
	ArrayOfParametersForSelectingDirectionOfActivity.Add(New ChoiceParameter("Filter.Status", Enums.LineOfBusinessStatuses.Used));
	
	If Object.SourceDocumentType = Enums.SourceDocumentTypes.PurchaseFromVendor Then
		ArrayOfParametersForSelectingDirectionOfActivity.Add(New ChoiceParameter("Filter.CostsOrVendorsARAPAccounting", True));
	ElsIf Object.SourceDocumentType = Enums.SourceDocumentTypes.SaleToCustomer
		Or Object.SourceDocumentType = Enums.SourceDocumentTypes.GoodsShipmentToCustomer Then
		ArrayOfParametersForSelectingDirectionOfActivity.Add(New ChoiceParameter("Filter.IncomeAccounting", True));
	ElsIf Object.SourceDocumentType = Enums.SourceDocumentTypes.VMIProcurement
		Or Object.SourceDocumentType  = Enums.SourceDocumentTypes.ReportToMaterialProvider
		Or False Then
		ArrayOfParametersForSelectingDirectionOfActivity.Add(New ChoiceParameter("Filter.CostAccounting", True));
	EndIf;
	
	Items.LineOfBusiness.ChoiceParameters = New FixedArray(ArrayOfParametersForSelectingDirectionOfActivity);
	
EndProcedure

&AtServer
Procedure FillInPrimaryDocumentTypeSelectionList()
	
	Enums.SourceDocumentTypes.FillInSelectionData(Items.SourceDocumentType.ChoiceList);
	
EndProcedure

&AtServer
Procedure FillInListOfChoosingOrderOfCalculations(CheckFilling = True)
	
	ChoiceList = Items.ARAPObjectSettings.ChoiceList;
	ChoiceList.Clear();
	ChoiceList.Add(Enums.ARAPObjectSettings.ByARAPDocuments, NStr("vi = 'Theo hóa đơn';
																	|ru = 'По расчетным документам';
																	|en = 'By AR/AP documents'; fa = 'By AR/AP documents';
																	|it = 'In base ai documenti contabili';
																	|pl = 'Wg dokumentów rozliczeniowych';
																	|tr = 'Alacak/Borç belgelerine göre'"));
	ChoiceList.Add(Enums.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice, NStr("vi = 'Ứng trước theo đơn hàng, công nợ theo hóa đơn';
																						|ru = 'Аванс по заказам, долг по накладным';
																						|en = 'Invoice for debt, Order for prepayment'; fa = 'فاکتور برای بدهی، سفارش برای پیش‌پرداخت';
																						|it = 'Pagamento anticipato per ordini, debito per fatture';
																						|pl = 'Zaliczka wg zamówień, dług wg listów przewozowych';
																						|tr = 'Sipariş avansı, irsaliye borcu'"));
	ChoiceList.Add(Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice, NStr("vi = 'Ứng trước theo hợp đồng, công nợ theo hóa đơn';
																						|ru = 'Аванс по договорам, долг по накладным';
																						|en = 'Invoice for debt, Contract for prepayment'; fa = 'فاکتور برای بدهی، قرارداد برای پیش‌پرداخت';
																						|it = 'Pagamento anticipato in base agli accordi, debito per fatture';
																						|pl = 'Zaliczka wg umów, dług wg listów przewozowych';
																						|tr = 'Sözleşme avansı, irsaliye borcu'"));
	
	If Object.Partner = Catalogs.Partners.OurEnterprise Then
		If GetFunctionalOption("UseIntercompanyContracts") Then
			ChoiceList.Add(Enums.ARAPObjectSettings.ByCounterpartyContracts, NStr("vi = 'Theo hợp đồng';
																					|ru = 'По договорам';
																					|en = 'By contracts'; fa = 'بر اساس قراردادها';
																					|it = 'In base ai contratti';
																					|pl = 'Wg umów';
																					|tr = 'Sözleşmelere göre'"));
		EndIf;
	Else
		ChoiceList.Add(Enums.ARAPObjectSettings.ByCounterpartyContracts, NStr("vi = 'Theo hợp đồng';
																				|ru = 'По договорам';
																				|en = 'By contracts'; fa = 'بر اساس قراردادها';
																				|it = 'In base ai contratti';
																				|pl = 'Wg umów';
																				|tr = 'Sözleşmelere göre'"));
		DescriptionOfCalculationProcedure = New Array();
		DescriptionOfCalculationProcedure.Add(NStr("vi = 'Theo đơn hàng';
													|ru = 'По заказам';
													|en = 'By orders'; fa = 'بر اساس سفارش‌ها';
													|it = 'Per ordini';
													|pl = 'Wg zamówień';
													|tr = 'Siparişlere göre'"));
		If Object.SourceDocumentType = Enums.SourceDocumentTypes.PurchaseFromVendor
			Or Object.SourceDocumentType = Enums.SourceDocumentTypes.PaymentToVendor
			Or Object.SourceDocumentType = Enums.SourceDocumentTypes.PurchaseAdjustment Then
			If GetFunctionalOption("UsePurchaseCommission") Then
				DescriptionOfCalculationProcedure.Add(NStr("vi = 'bảng kê ký gửi';
															|ru = 'отчетам по комиссии';
															|en = 'commission reports'; fa = 'commission reports';
															|it = 'отчетам по комиссии';
															|pl = 'commission reports';
															|tr = 'komisyon raporları'"));
			EndIf;
			If GetFunctionalOption("UseCustodyDuringPurchase") Then
				DescriptionOfCalculationProcedure.Add(NStr("vi = 'chứng từ mua lại và ghi giảm hàng hóa từ kho';
															|ru = 'документам выкупа и списания товаров с хранения';
															|en = 'purchase invoices — VMI and VMI adjustments'; fa = 'purchase invoices — VMI and VMI adjustments';
															|it = 'документам выкупа и списания товаров с хранения';
															|pl = 'purchase invoices — VMI and VMI adjustments';
															|tr = 'ürünlerin itfasına ve VMI düzeltmesine ilişkin belgeler'"));
			EndIf;
		ElsIf Object.SourceDocumentType = Enums.SourceDocumentTypes.SaleToCustomer
			Or Object.SourceDocumentType = Enums.SourceDocumentTypes.GoodsShipmentToCustomer
			Or Object.SourceDocumentType = Enums.SourceDocumentTypes.PaymentFromCustomer
			Or Object.SourceDocumentType = Enums.SourceDocumentTypes.SaleAdjustment Then 
			If GetFunctionalOption("UseSalesCommission") Then
				DescriptionOfCalculationProcedure.Add(NStr("vi = 'bảng kê của người nhận ký gửi';
															|ru = 'отчетам комиссионера';
															|en = 'consignment issue notifications'; fa = 'consignment issue notifications';
															|it = 'отчетам комиссионера';
															|pl = 'consignment issue notifications';
															|tr = 'konsinye raporları'"));
				DescriptionOfCalculationProcedure.Add(NStr("vi = 'bán hàng thông qua người nhận ký gửi';
															|ru = 'реализациям через комиссионера';
															|en = 'sales via consignee'; fa = 'sales via consignee';
															|it = 'реализациям через комиссионера';
															|pl = 'sales via consignee';
															|tr = 'konsinye aracılığıyla satış'"));
			EndIf;
			If GetFunctionalOption("UseCustody") Then
				DescriptionOfCalculationProcedure.Add(NStr("vi = 'chứng từ mua hàng hàng hóa của bên cất giữ';
															|ru = 'документам выкупа товаров хранителем';
															|en = 'sales invoices — VMI sold'; fa = 'sales invoices — VMI sold';
															|it = 'документам выкупа товаров хранителем';
															|pl = 'sales invoices — VMI sold';
															|tr = 'satış faturası - satılan VMI belgeleri'"));
			EndIf;
		EndIf;
		ChoiceList.Add(Enums.ARAPObjectSettings.ByOrders, StrConcat(DescriptionOfCalculationProcedure, " / "));
	EndIf;
	
	If CheckFilling Then 
		If ChoiceList.FindByValue(Object.ARAPObjectSettings) = Undefined Then
			Object.ARAPObjectSettings = Undefined;
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure CompleteVATTaxation()
	
	FillParameters = Documents.SourceDocument.ParametersForFillingInVATTaxation_(Object);
	If FillParameters.Sale Then
		VATAccountingERP.FillInSalesVATTaxation(Object.VATTaxation, FillParameters, VATAccountingCachedParameterValues);
		VATAccountingERP.FillInSalesVATTaxSelectionList(Items.VATTaxation, Object.VATTaxation, FillParameters, VATAccountingCachedParameterValues);
	ElsIf FillParameters.Purchase Then
		VATAccountingERP.FillInVATTaxationPurchases(Object.VATTaxation, FillParameters, VATAccountingCachedParameterValues);
		VATAccountingERP.FillInListOfVATTaxChoices(Items.VATTaxation, Object.VATTaxation, FillParameters, VATAccountingCachedParameterValues);
	Else
		Items.VATTaxation.ChoiceList.Clear();
	EndIf;
	
EndProcedure

&AtServerNoContext
Function ParametersForRegisteringInvoicesReceivedServer(Val Object)
	
	Return Documents.SourceDocument.ParametersForRegisteringInvoicesReceived(Object);
	
EndFunction

&AtServerNoContext
Function ParametersForRegisteringInvoicesIssuedServer(Val Object)
	
	Return Documents.SourceDocument.ParametersForRegisteringInvoicesIssued(Object);
	
EndFunction	

&AtClient
Procedure Attachable_ProcessObjectEntry()
	
	TMCommonUseClient.ProcessObjectEntryInForm(ThisObject, ParametersForRecording);
	
EndProcedure

&AtServer
Procedure UpdateFlagThereAreAdjustments()
	
	ThereAreInvoices_ = False;
	CheckForAdjustmentsAndInvoices(ThereAreAdjustingEntries, ThereAreInvoices_);
	Items.SupplierContractType.Enabled = Not ThereAreAdjustingEntries;
	
EndProcedure

&AtServer
Procedure CheckForAdjustmentsAndInvoices(ThereAreAdjustingEntries, ThereAreInvoices_1)
	
	ThereAreInvoices_1 = False;
	ThereArePurchaseAdjustments = False;
	ThereAreImplementationAdjustments = False;
	
	If UseDebitNotes Then
		PurchasesServer.CheckForAdjustmentsAndInvoices(Object.Ref, Object.Ref, ThereArePurchaseAdjustments, ThereAreInvoices_1);
	EndIf;
	If UseCreditNotes Then
		SalesServer.CheckForAdjustments(Object.Ref, Object.Ref, ThereAreImplementationAdjustments);
	EndIf;
	
	ThereAreAdjustingEntries = ThereArePurchaseAdjustments Or ThereAreImplementationAdjustments;
	
EndProcedure

&AtClient
Function PartnerSelectionParametersAreChanging(OldDocumentType, NewDocumentType)
	
	TypesWithCommonSelections = New Array;
	
	TypesArray = New Array;
	TypesArray.Add(PredefinedValue("Enum.SourceDocumentTypes.PaymentFromCustomer"));
	TypesArray.Add(PredefinedValue("Enum.SourceDocumentTypes.SaleToCustomer"));
	TypesArray.Add(PredefinedValue("Enum.SourceDocumentTypes.GoodsShipmentToCustomer"));
	TypesArray.Add(PredefinedValue("Enum.SourceDocumentTypes.CustomerBonusCertificate"));
	TypesArray.Add(PredefinedValue("Enum.SourceDocumentTypes.SaleAdjustment"));
	TypesWithCommonSelections.Add(TypesArray);
	
	TypesArray = New Array;
	TypesArray.Add(PredefinedValue("Enum.SourceDocumentTypes.VMIProcurement"));
	TypesArray.Add(PredefinedValue("Enum.SourceDocumentTypes.VMIProcurement"));
	TypesWithCommonSelections.Add(TypesArray);
	
	TypesArray = New Array;
	TypesArray.Add(PredefinedValue("Enum.SourceDocumentTypes.PaymentToVendor"));
	TypesArray.Add(PredefinedValue("Enum.SourceDocumentTypes.PurchaseFromVendor"));
	TypesArray.Add(PredefinedValue("Enum.SourceDocumentTypes.VendorBonusCertificate"));
	TypesArray.Add(PredefinedValue("Enum.SourceDocumentTypes.PurchaseAdjustment"));
	TypesArray.Add(PredefinedValue("Enum.SourceDocumentTypes.SubcontractorReport"));
	TypesWithCommonSelections.Add(TypesArray);
	
	Result = True;
	
	For Each TypesArray In TypesWithCommonSelections Do
		If TypesArray.Find(OldDocumentType) <> Undefined
			And TypesArray.Find(NewDocumentType) <> Undefined Then
			Result = False;
			Break;
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

#EndRegion

#Region Initialize

CloseAfterWrite = False;

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
	If Item.Name = "sh_ShamsiInput_Date" Then
		DateOnChange(Items.Date);
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
