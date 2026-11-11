
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	If Not ValueIsFilled(Object.Ref) Then
		
		If Not ValueIsFilled(Object.ARAPCurrency) Then
			Object.ARAPCurrency = IncomeAndExpensesServer.GetCurrencyOfManagementAccounting();
		EndIf;
		
		OnReadCreateAtServer();
		
	EndIf;
	
	#Region UniversalMechanisms
	
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
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations

	#EndRegion

	SetVisibilityOfInputCommandsBasedOn_();

	ItemsAndDimensionsSelectionParameters = Catalogs.LeaseContract.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	Items.RegisterImportApplications.Visible = (Object.ContractType = Enums.TypesOfLeaseContracts.Leasing);
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	
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
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	PropertyManager.OnReadAtServer(ThisForm, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	ItemsAndDimensionsSelectionParameters = Catalogs.LeaseContract.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	OnReadCreateAtServer();
	
	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisForm, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// Handler of the "Properties" subsystem
	PropertyManager.BeforeWriteAtServer(ThisForm, CurrentObject);

	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	Items.CommentPage.Picture = CommonClientServer.CommentPicture(Object.Comment);

	SetFormHeader();
	SetVisibilityOfInputCommandsBasedOn_();

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	// Subsystem prohibiting editing of key details of objects	
	ObjectAttributesLock.LockAttributes(ThisForm);
	
	IncomeAndExpensesServer.AfterWriteAtServer(ThisObject);
	
	FormEvents.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Subsystem "Properties"
	If PropertyManagerClient.ProcessNotifications(ThisForm, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	
	If EventName = "Write_SigningOfLeaseContract"
		Or EventName = "Write_LeaseTermAdjustment" Then
		WhenYouChangeTermsOfLeaseOnServer();
	EndIf;
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtServer
Procedure WhenYouChangeTermsOfLeaseOnServer()
	
	FillInTermsOfAgreement();
	
	ConfigureDependentFormElementsOnServer("TermsOfAgreement_");
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)

	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

#Region PageGeneral

&AtClient
Procedure ContractTypeOnChange(Item)
	
	ChangedBankingDetails = Item.Name;
	
	If Object.ContractType = PredefinedValue("Enum.TypesOfLeaseContracts.Leasing") Then
		
		Object.RecognizeLeasedItemsInLocalAccounting = True;
		Object.RecognizeLeasedAssetsInManagementAccounting = True;
		OptionOfReflectionInAccounting = PredefinedValue("Enum.OptionsOfPostingInNonCurrentAssetsAccounting.ManagementAndLocalAccounting");
		
		ChangedBankingDetails = ChangedBankingDetails + ",RecognizeLeasedItemsInLocalAccounting,RecognizeLeasedAssetsInManagementAccounting";
		
	ElsIf Object.ContractType = PredefinedValue("Enum.TypesOfLeaseContracts.Lease") Then
		Object.AssetHolder = PredefinedValue("Enum.LeasedAssetHolder.Lessor");
		Object.RegisterImportApplications = False;
		ChangedBankingDetails = ChangedBankingDetails + ",AssetHolder,RegisterImportApplications";
	EndIf;
	
	ChangedBankingDetails = ChangedBankingDetails + ",ContractType";
	
	ConfigureDependentFormElements(ChangedBankingDetails);
	FillInTaxationOnServer();
	
EndProcedure

&AtClient
Procedure DescriptionOnChange(Item)
	
	ConfigureDependentFormElements(Item);

EndProcedure

&AtClient
Procedure ValidityStartDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	ConfigureDependentFormElements(Item);

EndProcedure

&AtClient
Procedure ValidityEndDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	ConfigureDependentFormElements(Item);

EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	OrganizationOnChangeServer();
	
EndProcedure

&AtClient
Procedure CounterpartyOnChange(Item)
	
	CounterpartyOnChangeServer();
	
EndProcedure

&AtClient
Procedure PartnerOnChange(Item)
	
	PartnerOnChangeServer();
		
EndProcedure

&AtClient
Procedure ContactPersonOnChange(Item)
	
	If Object.ContactPerson.IsEmpty() Then
		Return;
	EndIf;
	
	ContactPersonOnChangeServer();
	
EndProcedure

&AtClient
Procedure StatusOnChange(Item)
	
	If Object.Approved
		And Object.Status <> PredefinedValue("Enum.CounterpartyContractStatuses.Valid")
		And Object.Status <> PredefinedValue("Enum.CounterpartyContractStatuses.Closed") Then
		
		Object.Approved = False;
	EndIf;
	
	StatusChangedOnServer();
	
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	
EndProcedure

&AtClient
Procedure ForeignExchangeControlUniqueNumberOnChange(Item)

	
EndProcedure 

&AtClient
Procedure ForeignCounterpartyIncomeKindOnChange(Item)
	


EndProcedure

#EndRegion

#Region PageSettlements

&AtClient
Procedure AssetHolderOnChange(Item)
	
	ConfigureDependentFormElements(Item);
	FillInTaxationOnServer();
	
EndProcedure

&AtClient
Procedure ARAPCurrencyOnChange(Item)
	
	ARAPCurrencyOnChangeServer();
	
EndProcedure

&AtClient
Procedure ForeignCurrencyTransactionOnChange(Item)
	
	ProcessBankAccounts();
	ConfigureDependentFormElements(Item);
	
EndProcedure

&AtClient
Procedure HasSecurityDepositOnChange(Item)
	
	ConfigureDependentFormElements(Item);
	
EndProcedure

&AtClient
Procedure ThereIsBuyoutOfLeasedAssetsOnChange(Item)
	
	ConfigureDependentFormElements(Item);
	
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	
EndProcedure

&AtClient
Procedure OptionOfReflectionInAccountingOnChange(Item)
	
	If Not ValueIsFilled(OptionOfReflectionInAccounting) Then
		OptionOfReflectionInAccounting = PredefinedValue("Enum.OptionsOfPostingInNonCurrentAssetsAccounting.ManagementAndLocalAccounting");
	EndIf;

	Object.RecognizeLeasedItemsInLocalAccounting = 
		OptionOfReflectionInAccounting = PredefinedValue("Enum.OptionsOfPostingInNonCurrentAssetsAccounting.ManagementAndLocalAccounting")
		Or OptionOfReflectionInAccounting = PredefinedValue("Enum.OptionsOfPostingInNonCurrentAssetsAccounting.InLocalAccounting");
		
	Object.RecognizeLeasedAssetsInManagementAccounting = 
		OptionOfReflectionInAccounting = PredefinedValue("Enum.OptionsOfPostingInNonCurrentAssetsAccounting.ManagementAndLocalAccounting")
		Or OptionOfReflectionInAccounting = PredefinedValue("Enum.OptionsOfPostingInNonCurrentAssetsAccounting.InManagementAccounting");
		
	ConfigureDependentFormElements("RecognizeLeasedItemsInLocalAccounting,RecognizeLeasedAssetsInManagementAccounting");
	
EndProcedure

&AtClient
Procedure TheDecorationOfTheTermsOfTheContractURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	If Object.Status <> PredefinedValue("Enum.CounterpartyContractStatuses.Valid") Then
		WarningText = NStr("vi = 'Để lập chứng từ, hợp đồng phải có trạng thái ""Có hiệu lực""';
							|ru = 'Для оформления документа у договора должен быть статус ""Действует""';
							|en = 'The contract must have a ""Valid"" status to register a document'; fa = 'The contract must have a ""Valid"" status to register a document';
							|it = 'Per l''esecuzione del documento, l''accordo deve avere stato ""Attivo""';
							|pl = 'Aby utworzyć dokument umowa powinna mieć status ""Jest ważny""';
							|tr = 'Belgeyi yürütmek için sözleşmenin ""Geçerli"" statüsünde olması gerekir'");
		ShowMessageBox(, WarningText);
		Return;
	EndIf;
	
	If FormattedStringURL = "#Create" Then
		
		StandardProcessing = False;
	
		If Not ValueIsFilled(Object.Ref) Then
			
			QueryText = NStr("vi = 'Chỉ có thể lập chứng từ sau khi ghi lại hợp đồng.
					|Ghi lại và tiếp tục?';
					|ru = 'Оформление документа возможно только после записи договора.
					|Записать и продолжить?';
					|en = 'Document registration is only available after saving the contract.
					|Save and continue?'; fa = 'Document registration is only available after saving the contract.
					|Save and continue?';
					|it = 'L''esecuzione del documento è possibile solamente dopo la registrazione dell''accordo.
					|Registrare e continuare?';
					|pl = 'Utworzenie dokumentu jest niemożliwe tylko po zapisywaniu umowy.
					|Zapisać i kontynuować?';
					|tr = 'Belge ancak doküman kaydedildikten sonra tamamlanabilir.
					|Kaydedilip devam edilsin mi?'");
			
			CallbackDescription = New CallbackDescription("TextOfAgreementTermsAndConditionsClickFinish", ThisObject);
			ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo,, DialogReturnCode.Yes);
			
		Else
			TextOfAgreementTermsAndConditionsClickFinish(DialogReturnCode.Yes, Undefined);
		EndIf;
		
	EndIf;

EndProcedure

&AtClient
Procedure RegisterImportApplicationsOnChange(Item)

	FillInTaxationOnServer();
	ConfigureDependentFormElements(Item);

EndProcedure

&AtClient
Procedure VATTaxationOnChange(Item)
	
	ConfigureDependentFormElements(Item);
	
EndProcedure

#EndRegion

#Region AccountInformationPage

&AtClient
Procedure ExpenseItemServicesStartChoice(Item, ChoiceData, StandardProcessing)
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure ExpenseItemServicesOnChange(Item)
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
EndProcedure

&AtClient
Procedure ExpensesDimensionServicesStartChoice(Item, ChoiceData, StandardProcessing)
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure ExpensesDimensionServicesAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
EndProcedure

&AtClient
Procedure ExpensesDimensionServicesTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
EndProcedure

&AtClient
Procedure ExpenseItemInterestStartChoice(Item, ChoiceData, StandardProcessing)
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure ExpenseItemInterestOnChange(Item)
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
EndProcedure

&AtClient
Procedure ExpensesDimensionInterestStartChoice(Item, ChoiceData, StandardProcessing)
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure ExpensesDimensionInterestAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
EndProcedure

&AtClient
Procedure ExpensesDimensionInterestTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
EndProcedure

#EndRegion

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OpenPaymentSchedule(Command)
	OpenPaymentAndAccrualSchedule("ServicePaymentSchedule");
EndProcedure

&AtClient
Procedure OpenTheAccrualSchedule(Command)
	OpenPaymentAndAccrualSchedule("ServiceAccrualSchedule");
EndProcedure

&AtClient
Procedure OpenTheInterestAccrualSchedule(Command)
	OpenPaymentAndAccrualSchedule("InterestAccrualSchedule");
EndProcedure

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

&AtClient
Procedure SetDateInterval(Command)
	
	NotificationAfterSelection = New CallbackDescription("SetDateIntervalCompletion", ThisObject);
	TMCommonUseClient.EditPeriod(
		Object, 
		New Structure("StartDate, EndDate", "ValidityStartDate", "ValidityEndDate"),
		NotificationAfterSelection);
	
EndProcedure

&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)
	
	ProcedureParameters = TMCommonUseClient.PermissionParametersForEditingItemDetails();
	ProcedureParameters.OnlyVisible = False;
	
	TMCommonUseClient.AllowObjectAttributeEdit(ThisObject, ProcedureParameters);
	
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure

#EndRegion

#Region Private

#Region OnChangeAttributes

&AtClient
Procedure ConfigureDependentFormElements(Val ChangedDetailsOrElement = "")

	If TypeOf(ChangedDetailsOrElement) = Type("String") Then
		ChangedBankingDetails = ChangedDetailsOrElement;
	Else
		ChangedBankingDetails = ChangedDetailsOrElement.Name;
	EndIf;

	StructureOfChangedProps = New Structure(ChangedBankingDetails);

	If RequiresServerCallToConfigureFormElements(StructureOfChangedProps) Then
		ConfigureDependentFormElementsOnServer(ChangedBankingDetails)
	Else
		ConfigureDependentFormElementsOnClientOnServer(ThisObject, ChangedBankingDetails);
	EndIf;

EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElementsOnClientOnServer(Val Form, Val ChangedBankingDetails = "")
	
	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	
	WhenChangingDetailsOnClientOnServer(Form, StructureOfChangedProps);
	
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	Object = Form.Object;
	Items = Form.Items;
	FormServiceParameters = Form.FormServiceParameters;
	
	AuxiliaryAttributes = New Structure;
	AuxiliaryAttributes.Insert("LeaseAccountingAccordingToFSB25_2018IsUsed", FormServiceParameters.LeaseAccountingAccordingToFSB25_2018IsUsed);
	AuxiliaryAttributes.Insert("FALocalAccountingIsConductedIndependently", FormServiceParameters.FALocalAccountingIsConductedIndependently);
	
	ItemDetailsParameters = LeasedAssetAccountingClientServer.PropertyValuesForDependentDetails_LeaseAgreements(
									Object, AuxiliaryAttributes, ChangedBankingDetails);
									
	TMCommonUseClientServer.ConfigureDependentFormElements(Form, ItemDetailsParameters);
	
	If Not UpdateAll Then
		TMCommonUseClientServer.ClearUnusedProps(Object, ItemDetailsParameters);
	EndIf;
	
	TermsOfAgreementAreSpecified = ValueIsFilled(Form.SigningOfLeaseContract);
	
	AccountingForBalanceSheet = 
		Object.AssetHolder = PredefinedValue("Enum.LeasedAssetHolder.Lessor")
		And Not FormServiceParameters.LeaseAccountingAccordingToFSB25_2018IsUsed;
	
	WithoutDiscounting =
		Object.MethodForDeterminingCostOfAssets =
			PredefinedValue("Enum.MethodsOfDeterminingLeasedAssetCost.ByContractAmount");
	
	#Region PageGeneral
	
	If StructureOfChangedProps.Property("Description")
		Or UpdateAll Then
			
		Items.NameForPrinting.ChoiceList.Clear();
		Items.NameForPrinting.ChoiceList.Add(Object.Description);
	EndIf;
	
	If StructureOfChangedProps.Property("ContractType")
		Or UpdateAll Then
			
		PropertyValue = 
			(Object.ContractType = PredefinedValue("Enum.TypesOfLeaseContracts.Leasing"));
			
		Items.RegisterImportApplications.Visible = PropertyValue;
		
		CostDeterminationSelectionList = Items.MethodForDeterminingCostOfAssets.ChoiceList;
		CostDeterminationSelectionList.Clear();
		If Not PropertyValue Then
			CostDeterminationSelectionList.Add(
				PredefinedValue("Enum.MethodsOfDeterminingLeasedAssetCost.Discounting"),
				NStr("vi = 'Được tính theo tỷ lệ';
					|ru = 'Рассчитывается по ставке';
					|en = 'Calculated at rate'; fa = 'Calculated at rate';
					|it = 'Рассчитывается по ставке';
					|pl = 'Calculated at rate';
					|tr = 'Şu oranda hesaplanmaktadır'"));
		EndIf;
		CostDeterminationSelectionList.Add(
			PredefinedValue("Enum.MethodsOfDeterminingLeasedAssetCost.Manually"),
			NStr("vi = 'Chỉ định thủ công';
				|ru = 'Указывается вручную';
				|en = 'Specified manually'; fa = 'مشخص‌شده به صورت دستی';
				|it = 'Si specifica manualmente';
				|pl = 'Podaje się ręcznie';
				|tr = 'Manuel olarak belirtilir'"));
		CostDeterminationSelectionList.Add(
			PredefinedValue("Enum.MethodsOfDeterminingLeasedAssetCost.ByContractAmount"),
			NStr("vi = 'Bằng số tiền hợp đồng';
				|ru = 'Равна сумме договора';
				|en = 'Equal to contract amount'; fa = 'برابر با مبلغ قرارداد';
				|it = 'Равна сумме договора';
				|pl = 'Equal to contract amount';
				|tr = 'Sözleşme tutarına eşittir'"));
		
	EndIf;
	
	#EndRegion
	
	#Region ContractParameters
	
	If StructureOfChangedProps.Property("RegisterImportApplications")
		Or UpdateAll Then
			
		PropertyValue = Not Object.RegisterImportApplications;
			
		Items.VATTaxation.Visible = PropertyValue;
			
	EndIf;
	
	If StructureOfChangedProps.Property("VATTaxation")
		Or UpdateAll Then 
			
		Items.AgencyAgreementKind.Visible = FormServiceParameters.ThisIsLocalizationOfRussianFederation;
		
		ThisIsTaxAgent = (Object.VATTaxation = PredefinedValue("Enum.VATTaxationTypes.VATTaxAgent"));
	
		Items.AgencyAgreementKind.Enabled            = ThisIsTaxAgent;
		Items.RegisterImportApplications.Visible = Not ThisIsTaxAgent;
		
	EndIf;
	
	If StructureOfChangedProps.Property("KeepAccountingOfPrepaymentsForCurrentRentalPaymentsBrokenDownByPaymentDocuments")
		Or StructureOfChangedProps.Property("ForeignCurrencyTransaction")
		Or UpdateAll Then
			
		Items.KeepAccountingOfPrepaymentsForCurrentRentalPaymentsBrokenDownByPaymentDocuments.Visible   = FormServiceParameters.ThisIsLocalizationOfRussianFederation
																									And FormServiceParameters.LeaseAccountingAccordingToFSB25_2018IsUsed;
			
		PropertyValue = Not (Object.VATTaxation = PredefinedValue("Enum.VATTaxationTypes.VATTaxAgent")
							Or Object.ForeignCurrencyTransaction);
			
		Items.KeepAccountingOfPrepaymentsForCurrentRentalPaymentsBrokenDownByPaymentDocuments.Enabled = PropertyValue;
			
	EndIf;
	
	#EndRegion
	
	#Region SettlementsUnderContract
	
	If StructureOfChangedProps.Property("ContractType")
		Or StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("TermsOfAgreement_")
		Or UpdateAll Then
		
		PropertyValue = 
			TermsOfAgreementAreSpecified
			And (FormServiceParameters.LeaseAccountingAccordingToFSB25_2018IsUsed 
				Or Not AccountingForBalanceSheet);

		Items.TermsOfTheAgreementAmount.Visible = PropertyValue;
		Items.TermsOfTheAgreementAmountCurrency.Visible = PropertyValue;
		
		Items.TermsOfTheContractAmountOfRentalServices.Visible = PropertyValue;
		Items.TermsOfTheContractAmountOfRentalServicesCurrency.Visible = PropertyValue;
		Items.TermsOfTheAgreementDateOfTheFirstPayment.Visible = PropertyValue;
		
		Items.TermsOfTheAgreementAmountOfVAT.Visible = PropertyValue;
		Items.TermsOfTheAgreementAmountOfNDSVALYUTA.Visible = PropertyValue;
		
	EndIf;
		
	If StructureOfChangedProps.Property("TermsOfAgreement_")
		Or StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("HasSecurityDeposit")
		Or UpdateAll Then

		PropertyValue = 
			TermsOfAgreementAreSpecified 
			And Object.HasSecurityDeposit
			And (FormServiceParameters.LeaseAccountingAccordingToFSB25_2018IsUsed 
				Or Not AccountingForBalanceSheet);
		
		Items.TermsOfTheAgreementAmountOfTheSecurityPayment.Visible = PropertyValue;
		Items.TermsOfTheAgreementAmountOfTheSecurityPaymentCurrency.Visible = PropertyValue;
		Items.TermsOfTheAgreementDateOfTheFirstSecurityPayment.Visible = PropertyValue;
		
	EndIf;
		
	If StructureOfChangedProps.Property("TermsOfAgreement_")
		Or StructureOfChangedProps.Property("ThereIsBuyoutOfLeasedAssets")
		Or UpdateAll Then
		
		PropertyValue = 
			TermsOfAgreementAreSpecified 
			And Object.ThereIsBuyoutOfLeasedAssets
			And (FormServiceParameters.LeaseAccountingAccordingToFSB25_2018IsUsed 
				Or Not AccountingForBalanceSheet);
		
		Items.TermsOfTheContractTheAmountOfPurchaseOfRentalItems.Visible = PropertyValue;
		Items.TermsOfTheAgreementTheAmountOfPurchaseOfRentalItemsCurrency.Visible = PropertyValue;
		Items.TermsOfTheAgreementPurchaseDate.Visible = PropertyValue;

	EndIf;
	
	#EndRegion
	
	#Region PeriodicPayments

	If StructureOfChangedProps.Property("TermsOfAgreement_")
		Or StructureOfChangedProps.Property("Organization")
		Or UpdateAll Then
			
		PropertyValue =
			TermsOfAgreementAreSpecified
			And (FormServiceParameters.LeaseAccountingAccordingToFSB25_2018IsUsed 
				Or Not AccountingForBalanceSheet);
				
		Items.TermsOfTheAgreementFrequencyOfPayments.Visible = PropertyValue;
		Items.TermsOfTheAgreementFrequencyOfAccruals.Visible = PropertyValue;
		
		//
		PropertyValue = 
			TermsOfAgreementAreSpecified 
			And Form.TheTermsOfTheContractConducted;
			
		Items.OpenPaymentSchedule.Visible = PropertyValue;
		Items.OpenTheAccrualSchedule.Visible = PropertyValue;
		
		//
		PropertyValue = 
			TermsOfAgreementAreSpecified 
			And ValueIsFilled(Form.TermsOfTheAgreementFrequencyOfPayments)
			And Form.TermsOfTheAgreementFrequencyOfPayments <> PredefinedValue("Enum.ScheduleTimeFence.Custom");
		Items.TermsOfTheContractPaymentForRentalServices.Visible = PropertyValue;
		Items.TermsOfTheContractPaymentForRentalServicesCurrency.Visible = PropertyValue;
		
		//
		PropertyValue = 
			TermsOfAgreementAreSpecified 
			And ValueIsFilled(Form.TermsOfTheAgreementFrequencyOfAccruals_3)
			And Form.TermsOfTheAgreementFrequencyOfAccruals_3 <> PredefinedValue("Enum.ScheduleTimeFence.Custom");
		Items.TermsOfTheContractAccrualOfRentalServices.Visible = PropertyValue;
		Items.TermsOfTheContractAccrualOfRentalServicesCurrency.Visible = PropertyValue;
	
	EndIf;
	
	#EndRegion
	
	#Region Discounting
	
	If StructureOfChangedProps.Property("TermsOfAgreement_")
		Or UpdateAll Then
		
		PropertyValue = TermsOfAgreementAreSpecified And Not WithoutDiscounting;
		
		Items.TermsOfTheContractTheCostOfRentalItems.Visible = PropertyValue;
		Items.TermsOfTheContractCostOfRentalItemsCurrency.Visible = PropertyValue;
		
	EndIf;

	If StructureOfChangedProps.Property("TermsOfAgreement_")
		Or StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("ValidityStartDate")
		Or StructureOfChangedProps.Property("ValidityEndDate")
		Or UpdateAll Then
		
		PropertyValue = 
			TermsOfAgreementAreSpecified
			And Not WithoutDiscounting
			And AuxiliaryAttributes.LeaseAccountingAccordingToFSB25_2018IsUsed;
		
		Items.TermsOfTheAgreementInterestRate.Visible = PropertyValue;
		Items.TermsOfTheContractInterestRateDecoration.Visible = PropertyValue;
		
		Items.TermsOfTheAgreementAmountOfInterest.Visible = PropertyValue;
		Items.TermsOfTheAgreementAmountOfInterestCurrency.Visible = PropertyValue;
		
		Items.DiscountingGroup.Title =
			?(PropertyValue, NStr("vi = 'Chiết khấu';
									|ru = 'Дисконтирование';
									|en = 'Discounting'; fa = 'تنزیل';
									|it = 'Sconto';
									|pl = 'Dyskontowanie';
									|tr = 'İskonto'"), NStr("vi = 'Đối tượng thuê';
																|ru = 'Предметы аренды';
																|en = 'Rental objects'; fa = 'موضوعات اجاره';
																|it = 'Elementi di affitto';
																|pl = 'Przedmioty dzierżawy';
																|tr = 'Kiralık kalemler'"));
		
		//
		PropertyValue = 
			TermsOfAgreementAreSpecified
			And AuxiliaryAttributes.LeaseAccountingAccordingToFSB25_2018IsUsed
			And Form.TheTermsOfTheContractConducted;
			
		Items.OpenTheInterestAccrualSchedule.Visible = PropertyValue;
		
	EndIf;
	
	If StructureOfChangedProps.Property("ContractType")
		Or StructureOfChangedProps.Property("AssetHolder")
		Or StructureOfChangedProps.Property("Organization")
		Or UpdateAll Then
		
		If FormServiceParameters.LeaseAccountingAccordingToFSB25_2018IsUsed Then
			
			If Object.ContractType = PredefinedValue("Enum.TypesOfLeaseContracts.Leasing") Then
				ItemTitle = NStr("vi = 'Số tiền đầu tư của bên cho thuê';
								|ru = 'Сумма вложений лизингодателя';
								|en = 'Amount of lessor''s investments'; fa = 'مبلغ سرمایه‌گذاری موجر';
								|it = 'Importo investimenti locatore';
								|pl = 'Wartość inwestycji leasingodawcy';
								|tr = 'Kiralayanın yatırım tutarı'");
			Else
				ItemTitle = NStr("vi = 'Giá trị các đối tượng thuê';
								|ru = 'Стоимость предметов аренды';
								|en = 'Rental objects cost'; fa = 'بهای اقلام اجاره‌ای';
								|it = 'Costo degli elementi di affitto';
								|pl = 'Wartość przedmiotów dzierżawy';
								|tr = 'Kiralanan varlık maliyeti'"); 
			EndIf;
				
		Else
			
			If Object.AssetHolder = PredefinedValue("Enum.LeasedAssetHolder.Lessor") Then
				ItemTitle = NStr("vi = 'Giá trị thế chấp';
								|ru = 'Залоговая стоимость';
								|en = 'Collateral value'; fa = 'ارزش وثیقه';
								|it = 'Costo di cauzione';
								|pl = 'Wartość kaucyjna';
								|tr = 'Teminat değeri'");
			Else
				ItemTitle = NStr("vi = 'Số tiền đầu tư của bên cho thuê';
								|ru = 'Сумма вложений лизингодателя';
								|en = 'Amount of lessor''s investments'; fa = 'مبلغ سرمایه‌گذاری موجر';
								|it = 'Importo investimenti locatore';
								|pl = 'Wartość inwestycji leasingodawcy';
								|tr = 'Kiralayanın yatırım tutarı'");
			EndIf;	
	
		EndIf;
		
		Items.TermsOfTheContractTheCostOfRentalItems.Title = ItemTitle;

	EndIf;
	
	#EndRegion
	
	
EndProcedure

&AtServer
Procedure ConfigureDependentFormElementsOnServer(Val ChangedBankingDetails = "")

	WhenChangingBankingDetailsOnServer(ChangedBankingDetails);
	
	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	If StructureOfChangedProps.Property("Organization") 
		Or UpdateAll Then
		
		SetFormFunctionalOptionParameters(New Structure("Organization", Object.Organization));
		
	EndIf;
	
	If StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("ValidityStartDate")
		Or UpdateAll Then
			
		PropertyValue = AccountingPoliciesTaxSettingsCached.FALocalAccountingIsConductedIndependently(
			Object.Organization, EndOfMonth(?(Object.ValidityStartDate <> '000101010000', Object.ValidityStartDate, CurrentSessionDate())));
		
		NonCurrentAssetsInternal.SetStructureProperty(
			"FALocalAccountingIsConductedIndependently",
			PropertyValue,
			FormServiceParameters);
			
	EndIf;
		
	If StructureOfChangedProps.Property("ValidityStartDate")
		Or UpdateAll Then
		
		NonCurrentAssetsInternal.SetStructureProperty(
			"VNAManagementIsUsed_2_4",
			NonCurrentAssets.VNAManagementIsUsed_2_4(Object.ValidityStartDate),
			FormServiceParameters);
		
	EndIf;

	If StructureOfChangedProps.Property("ValidityStartDate")
		Or StructureOfChangedProps.Property("ValidityEndDate")
		Or StructureOfChangedProps.Property("Organization")
		Or UpdateAll Then
			
		If ValueIsFilled(Object.ValidityEndDate) Then
			CheckDate = Object.ValidityEndDate;
		Else
			CheckDate = ?(Object.ValidityStartDate < CurrentSessionDate(), '000101010000', Object.ValidityStartDate);
		EndIf;
			
		NonCurrentAssetsInternal.SetStructureProperty(
			"LeaseAccountingAccordingToFSB25_2018IsUsed",
			LeasedAssetAccounting.LeaseAccountingAccordingToFSB25_2018IsUsed(Object.Organization, CheckDate, False),
			FormServiceParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("ValidityStartDate")
		Or StructureOfChangedProps.Property("ValidityEndDate")
		Or StructureOfChangedProps.Property("Organization") Then
		
		If Not FormServiceParameters.LeaseAccountingAccordingToFSB25_2018IsUsed 
			And Object.ContractType = Enums.TypesOfLeaseContracts.Lease Then
			Object.ContractType = Enums.TypesOfLeaseContracts.Leasing;
			ChangedBankingDetails = ChangedBankingDetails + ",ContractType";
		EndIf;
		
	EndIf;
	
	NonCurrentAssetsInternal.SetStructureProperty(
			"ThisIsLocalizationOfRussianFederation",
			GetFunctionalOption("LocalizationRFService"),
			FormServiceParameters);
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, ChangedBankingDetails);
	
EndProcedure

&AtClient
Function RequiresServerCallToConfigureFormElements(StructureOfChangedProps)

	Return StructureOfChangedProps.Count() = 0
		Or StructureOfChangedProps.Property("ValidityStartDate")
		Or StructureOfChangedProps.Property("ValidityEndDate")
		Or StructureOfChangedProps.Property("Organization");

EndFunction

&AtClientAtServerNoContext
Procedure WhenChangingDetailsOnClientOnServer(Form, StructureOfChangedProps)
	
	If StructureOfChangedProps.Count() = 0 Then
		Return;
	EndIf;
	
	Object = Form.Object;
	FormServiceParameters = Form.FormServiceParameters;

	If Not FormServiceParameters.FALocalAccountingIsConductedIndependently
		And (Not Object.RecognizeLeasedItemsInLocalAccounting
			Or Object.RecognizeLeasedAssetsInManagementAccounting) Then
				
		Object.RecognizeLeasedItemsInLocalAccounting = True;
		Object.RecognizeLeasedAssetsInManagementAccounting = True;
		Form.OptionOfReflectionInAccounting = PredefinedValue("Enum.OptionsOfPostingInNonCurrentAssetsAccounting.ManagementAndLocalAccounting");
		
		StructureOfChangedProps.Insert("RecognizeLeasedItemsInLocalAccounting");
		StructureOfChangedProps.Insert("RecognizeLeasedAssetsInManagementAccounting");
		
	EndIf;
	
	If Not Object.ThereIsBuyoutOfLeasedAssets
		And Object.ThereIsPrepaymentOfBuyoutValue Then
		
		Object.ThereIsPrepaymentOfBuyoutValue = False;
		StructureOfChangedProps.Insert("ThereIsPrepaymentOfBuyoutValue");
	EndIf;

	If Not FormServiceParameters.LeaseAccountingAccordingToFSB25_2018IsUsed
		And Object.ContractType = PredefinedValue("Enum.TypesOfLeaseContracts.Lease") Then
		
		Object.ContractType = PredefinedValue("Enum.TypesOfLeaseContracts.Leasing");
		StructureOfChangedProps.Insert("ContractType");
	EndIf;
	
	If Object.ContractType = PredefinedValue("Enum.TypesOfLeaseContracts.Leasing")
		And Object.MethodForDeterminingCostOfAssets = PredefinedValue("Enum.MethodsOfDeterminingLeasedAssetCost.Discounting") Then

		Object.MethodForDeterminingCostOfAssets = PredefinedValue("Enum.MethodsOfDeterminingLeasedAssetCost.Manually");
		StructureOfChangedProps.Insert("MethodForDeterminingCostOfAssets");
	EndIf;
	
	If StructureOfChangedProps.Property("RegisterImportApplications") 
		And Object.RegisterImportApplications Then
		
		Object.VATTaxation = PredefinedValue("Enum.VATTaxationTypes.SaleIsNotSubjectToVAT");
		StructureOfChangedProps.Insert("VATTaxation");
		
	EndIf;
	
	If StructureOfChangedProps.Property("VATTaxation") Then 
		
		ThisIsTaxAgent = (Object.VATTaxation = PredefinedValue("Enum.VATTaxationTypes.VATTaxAgent"));
	
		If ThisIsTaxAgent Then 
			Object.KeepAccountingOfPrepaymentsForCurrentRentalPaymentsBrokenDownByPaymentDocuments = True;
		Else
			StructureOfChangedProps.Insert("AgencyAgreementKind");
		EndIf;
		
		StructureOfChangedProps.Insert("KeepAccountingOfPrepaymentsForCurrentRentalPaymentsBrokenDownByPaymentDocuments");
		
	EndIf;
	
	If StructureOfChangedProps.Property("ForeignCurrencyTransaction") 
		And Object.ForeignCurrencyTransaction Then 
		
		Object.KeepAccountingOfPrepaymentsForCurrentRentalPaymentsBrokenDownByPaymentDocuments = Object.ForeignCurrencyTransaction;
		StructureOfChangedProps.Insert("KeepAccountingOfPrepaymentsForCurrentRentalPaymentsBrokenDownByPaymentDocuments");
		
	EndIf;
	
	If StructureOfChangedProps.Property("AssetHolder")
		And Object.AssetHolder = PredefinedValue("Enum.LeasedAssetHolder.Leaseholder")
		And Object.VATTaxation = PredefinedValue("Enum.VATTaxationTypes.VATTaxAgent") Then 
		
		Object.VATTaxation = PredefinedValue("Enum.VATTaxationTypes.SaleIsNotSubjectToVAT");
		StructureOfChangedProps.Insert("VATTaxation");
		
		ThisIsTaxAgent = (Object.VATTaxation = PredefinedValue("Enum.VATTaxationTypes.VATTaxAgent"));
	
		If Object.VATTaxation <> PredefinedValue("Enum.VATTaxationTypes.VATTaxAgent") Then 
			StructureOfChangedProps.Insert("KeepAccountingOfPrepaymentsForCurrentRentalPaymentsBrokenDownByPaymentDocuments");
		EndIf;
		
	EndIf;
			
EndProcedure

&AtServer
Procedure WhenChangingBankingDetailsOnServer(ChangedBankingDetails)
	
	StructureOfChangedProps = New Structure(ChangedBankingDetails);

	If StructureOfChangedProps.Property("Organization") Then
		LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
		FillInOrganizationSDefaultBankAccount(Object.Organization, Object.ForeignCurrencyTransaction, Object.BankAccount);
		ObjectsFillingByStatistics.FillInSubordinateDetailsOfObject(Object, "Organization", , True);
	EndIf;
	
EndProcedure

&AtServer
Procedure StatusChangedOnServer()
	
	If Not ValueIsFilled(Object.ValidityStartDate)
		And Object.Status = PredefinedValue("Enum.CounterpartyContractStatuses.Valid") Then
		Object.ValidityStartDate = CurrentSessionDate();
	EndIf;
	
	If Not ValueIsFilled(Object.ValidityEndDate)
		And Object.Status = PredefinedValue("Enum.CounterpartyContractStatuses.Closed") Then
		Object.ValidityEndDate = CurrentSessionDate();
	EndIf;
	
	SetAvailabilityOfItemsByStatusServer();
	
	ConfigureDependentFormElementsOnServer("Status");
	
EndProcedure

&AtServer
Procedure PartnerOnChangeServer()
	
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Object.Partner, Object.Counterparty);
	PartnersAndCounterparties.FillInDefaultPartnerContactPerson(Object.Partner, Object.ContactPerson);
	If ValueIsFilled(Object.Counterparty) Then
		FillInCounterpartySDefaultBankAccount(Object.Organization, Object.Counterparty, Object.ForeignCurrencyTransaction,
			Object.CounterpartyBankAccount);
	Else
		Object.CounterpartyBankAccount = Catalogs.CounterpartyBankAccounts.EmptyRef();
	EndIf;
	ObjectsFillingByStatistics.FillInSubordinateDetailsOfObject(Object, "Counterparty", , True);
	CounterpartyLegEntInd = Common.ObjectAttributeValue(Object.Counterparty, "LegalEntityIndividual");
	
	ConfigureDependentFormElementsOnServer("Counterparty");
	
EndProcedure

&AtServer
Procedure ContactPersonOnChangeServer()
	
	OwnerOfContactPerson = Common.ObjectAttributeValue(Object.ContactPerson, "Owner");
	If OwnerOfContactPerson <> Object.Partner Then
		Object.Partner = OwnerOfContactPerson;
		PartnerOnChangeServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessBankAccounts()
	
	SetBankAccountSelectionParameters();
	
	If Not BankAccountCorrespondsToPaymentProcedure(Object.Organization, Object.BankAccount, Object.ForeignCurrencyTransaction) Then
		Object.BankAccount = Undefined;
	EndIf;
	FillInOrganizationSDefaultBankAccount(Object.Organization, Object.ForeignCurrencyTransaction, Object.BankAccount);
	
	ObjectsFillingByStatistics.FillInSubordinateDetailsOfObject(Object, "Organization", , True);
	
	If Not BankAccountCorrespondsToPaymentProcedure(Object.Organization, Object.CounterpartyBankAccount, Object.ForeignCurrencyTransaction) Then
		Object.CounterpartyBankAccount = Undefined;
	EndIf;
	FillInCounterpartySDefaultBankAccount(Object.Organization, Object.Counterparty, Object.ForeignCurrencyTransaction, Object.CounterpartyBankAccount);
	
	ObjectsFillingByStatistics.FillInSubordinateDetailsOfObject(Object, "Counterparty", , True);
	
EndProcedure

&AtClient
Procedure SetDateIntervalCompletion(Period, AdditionalParameters) Export
	
	ConfigureDependentFormElements("ValidityStartDate,ValidityEndDate");
	
EndProcedure

&AtServer
Procedure FillInTaxationOnServer()
	
	FillParameters = Catalogs.LeaseContract.ParametersForFillingInVATTaxationPurchases(Object);
	FillParameters.RentalServiceTaxAgent = FillParameters.RentalServiceTaxAgent
														And FormServiceParameters.LeaseAccountingAccordingToFSB25_2018IsUsed;
	VATAccountingERP.FillInListOfVATTaxChoices(
		Items.VATTaxation,
		Object.VATTaxation,
		FillParameters);
	
EndProcedure

&AtServer
Procedure CounterpartyOnChangeServer()

	CounterpartyLegEntInd = Common.ObjectAttributeValue(Object.Counterparty, "LegalEntityIndividual");
	FillInTaxationOnServer();
	FillInCounterpartySDefaultBankAccount(Object.Organization, Object.Counterparty, Object.ForeignCurrencyTransaction, Object.CounterpartyBankAccount);
	ObjectsFillingByStatistics.FillInSubordinateDetailsOfObject(Object, "Counterparty", , True);
	
	EstablishVisibilityOfTypeOfIncomeOfForeignCounterparty();
	
	ConfigureDependentFormElementsOnServer("Counterparty");

EndProcedure

&AtServer
Procedure OrganizationOnChangeServer()

	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	ConfigureDependentFormElementsOnServer("Organization");
	ProcessBankAccounts();

EndProcedure

#EndRegion

#Region ControlOfInconsistentChanges

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
	ElsIf Item.Name = "Date" Then
		ConfigureDependentFormElements(Item);
	Else
		TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisForm, Item);
	EndIf;
EndProcedure

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
// 	Item - FormField - 
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
// 	Command - FormCommand - 
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
// 	Item - FormField - 
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
// 	Item - FormField - 
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
// 	Item - FormField - 
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
	SetVisibilityOfInputCommandsBasedOn_();
	
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion

#Region StandardSubsystems

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

#EndRegion

#Region Other

&AtServer
Procedure OnReadCreateAtServer()
	
	Items.CommentPage.Picture = CommonClientServer.CommentPicture(Object.Comment);
	
	If Object.RecognizeLeasedAssetsInManagementAccounting And Object.RecognizeLeasedItemsInLocalAccounting Then
		OptionOfReflectionInAccounting = Enums.OptionsOfPostingInNonCurrentAssetsAccounting.ManagementAndLocalAccounting;
	ElsIf Object.RecognizeLeasedAssetsInManagementAccounting Then
		OptionOfReflectionInAccounting = Enums.OptionsOfPostingInNonCurrentAssetsAccounting.InManagementAccounting;
	ElsIf Object.RecognizeLeasedItemsInLocalAccounting Then
		OptionOfReflectionInAccounting = Enums.OptionsOfPostingInNonCurrentAssetsAccounting.InLocalAccounting;
	EndIf; 
	
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	
	SetBankAccountSelectionParameters();
	
	SetFormHeader();
	FillInTermsOfAgreement(); 
	EstablishVisibilityOfTypeOfIncomeOfForeignCounterparty();
	
	CounterpartyLegEntInd = Common.ObjectAttributeValue(Object.Counterparty, "LegalEntityIndividual");
	
	ConfigureDependentFormElementsOnServer();
	FillInTaxationOnServer();
	
EndProcedure

&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisForm);
	
EndProcedure

&AtServer
Procedure ARAPCurrencyOnChangeServer()
	
	Object.ForeignCurrencyTransaction = ARAPAccountingServer.GetPaidInDefaultCurrency();
	ProcessBankAccounts();
	
	ConfigureDependentFormElementsOnServer("ARAPCurrency,ForeignCurrencyTransaction");
	
EndProcedure

&AtServerNoContext
Function BankAccountCorrespondsToPaymentProcedure(Organization, BankAccount, ForeignCurrencyTransaction)

	Respond = True;
	
	If ValueIsFilled(BankAccount) Then
		
		AccountCurrency = Common.ObjectAttributeValue(BankAccount, "CashCurrency");
		
		If ForeignCurrencyTransaction Then
			Respond = AccountCurrency <> SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
		Else
			Respond = AccountCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
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
Procedure FillInCounterpartySDefaultBankAccount(Organization, Counterparty, ForeignCurrencyTransaction, CounterpartyBankAccount)
	
	If (ValueIsFilled(CounterpartyBankAccount)
			And Counterparty = Common.ObjectAttributeValue(CounterpartyBankAccount,"Owner"))
		Or Not ValueIsFilled(Counterparty) Then
		Return;
	EndIf;
	
	ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	
	CounterpartyBankAccount = Catalogs.CounterpartyBankAccounts.GetDefaultBankAccount(
		Counterparty, ComplCurrency, , ForeignCurrencyTransaction);
	
EndProcedure

&AtServer
Procedure SetBankAccountSelectionParameters()

	ParametersArray = New Array;
	
	If Not Object.ForeignCurrencyTransaction Then
		ParametersArray.Add(New ChoiceParameter("Filter.CashCurrency", SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization)));
	Else
		ParametersArray.Add(New ChoiceParameter("Filter.CashCurrency", New FixedArray(ForeignCurrencies(Object.Organization))));
	EndIf;
	
	ParametersArray.Add(New ChoiceParameter("SelectingAccountsOfParentCompany", Undefined));
	ParametersArray.Add(New ChoiceParameter("Filter.Closed", False));
	
	AccountSelectionParameters = New FixedArray(ParametersArray);
	Items.BankAccount.ChoiceParameters = AccountSelectionParameters;
	Items.CounterpartyBankAccount.ChoiceParameters = AccountSelectionParameters;
	
EndProcedure

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
	Query.SetParameter("LocalAccountingCurrency", SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization));
	
	Return Query.Execute().Unload().UnloadColumn("Ref");
	
EndFunction

&AtServer
Procedure SetAvailabilityOfItemsByStatusServer()
	
	ItemArray = New Array;
	
	// Header Controls
	ItemArray.Add("Date");
	ItemArray.Add("Number");
	ItemArray.Add("Partner");
	ItemArray.Add("Counterparty");
	ItemArray.Add("Organization");
	ItemArray.Add("ARAPCurrency");
	ItemArray.Add("ForeignCurrencyTransaction");
	
	TMCommonUse.SetSubscriptionForFormElementChangeEvents(ThisObject, ItemArray);
	
EndProcedure

&AtServer
Procedure FillInTermsOfAgreement()
	
	ReadTermsOfAgreement();
	
	If Not ValueIsFilled(SigningOfLeaseContract) Then
		StringText = StrTemplate(NStr("vi = 'Ký hợp đồng: <a href = ""%1"">lập</a>';
										|ru = 'Заключение договора: <a href = ""%1"">оформить</a>';
										|en = 'Signing the contract: <a href = ""%1"">register</a>'; fa = 'Signing the contract: <a href = ""%1"">register</a>';
										|it = 'Заключение договора: <a href = ""%1"">оформить</a>';
										|pl = 'Signing the contract: <a href = ""%1"">register</a>';
										|tr = 'Sözleşmenin imzalanması: <a href = ""%1"">düzenle</a>'"), "#Create");
		LabelTitle = NonCurrentAssetsClientServer.FormattedString(StringText);
		Items.TheDecorationOfTheTermsOfTheContract.Title = LabelTitle;
	EndIf;
	
	SetVisibilityOfInputCommandsBasedOn_();
	
EndProcedure

&AtServer
Procedure ReadTermsOfAgreement()
	
	SigningOfLeaseContract = Documents.SigningOfLeaseContract.EmptyRef();
	TermsOfTheAgreementChangeOfTerms = Documents.LeaseTermAdjustment.EmptyRef();
	
	If Not ValueIsFilled(Object.Ref) Then
		Return;
	EndIf;

	QueryText = 
	"SELECT TOP 1
	|	SigningOfLeaseContract.Ref,
	|	SigningOfLeaseContract.LeaseItemsCost,
	|	SigningOfLeaseContract.SecurityDepositAmount,
	|	SigningOfLeaseContract.LeaseServicesAmount,
	|	SigningOfLeaseContract.AmountOfLeaseAssetsByuout,
	|	SigningOfLeaseContract.InterestAmount,
	|	SigningOfLeaseContract.VATAmount,
	|	SigningOfLeaseContract.VATRate,
	|	SigningOfLeaseContract.LeaseStartDate,
	|	SigningOfLeaseContract.DateOfFirstPayment,
	|	SigningOfLeaseContract.DateOfFirstSecurityPayment,
	|	SigningOfLeaseContract.BuyoutDate,
	|	SigningOfLeaseContract.InterestRate,
	|	SigningOfLeaseContract.PaymentFrequency,
	|	SigningOfLeaseContract.AccrualFrequency,
	|	SigningOfLeaseContract.PaymentForLeaseService,
	|	SigningOfLeaseContract.AccrualOfLeaseService,
	|	SigningOfLeaseContract.TermYears,
	|	SigningOfLeaseContract.TermMonths,
	|	SigningOfLeaseContract.TermDays
	|INTO TTConclusionOfLeaseAgreement
	|FROM
	|	Document.SigningOfLeaseContract AS SigningOfLeaseContract
	|WHERE
	|	NOT SigningOfLeaseContract.Posted
	|	AND SigningOfLeaseContract.Contract = &Contract
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CAST(TermsOfLeaseContractsSliceFirst.Recorder AS Document.LeaseTermAdjustment) AS Ref
	|INTO TTContractTransferDocuments
	|FROM
	|	InformationRegister.TermsOfLeaseContracts.SliceFirst(, &Contract = Contract) AS TermsOfLeaseContractsSliceFirst
	|WHERE
	|	TermsOfLeaseContractsSliceFirst.Recorder REFS Document.LeaseTermAdjustment
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TermsOfLeaseContracts.Period AS Period,
	|	TermsOfLeaseContracts.Recorder AS Recorder
	|FROM
	|	InformationRegister.TermsOfLeaseContracts AS TermsOfLeaseContracts
	|WHERE
	|	TermsOfLeaseContracts.Contract = &Contract
	|	AND TermsOfLeaseContracts.Recorder REFS Document.LeaseTermAdjustment
	|	AND NOT TermsOfLeaseContracts.Recorder IN
	|				(SELECT
	|					TTContractTransferDocuments.Ref AS Ref
	|				FROM
	|					TTContractTransferDocuments AS TTContractTransferDocuments)
	|
	|ORDER BY
	|	Period
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TermsOfLeaseContractsSliceLast.Period AS Period,
	|	TermsOfLeaseContractsSliceLast.Recorder AS Recorder
	|FROM
	|	InformationRegister.TermsOfLeaseContracts.SliceLast(, Contract = &Contract
	|	AND State = VALUE(Enum.CounterpartyContractStates.Closed)) AS TermsOfLeaseContractsSliceLast
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ISNULL(TermsOfLeaseContracts.LeaseServicesAmount, TTConclusionOfLeaseAgreement.LeaseServicesAmount)
	|		+ ISNULL(TermsOfLeaseContracts.SecurityDepositAmount, TTConclusionOfLeaseAgreement.SecurityDepositAmount)
	|		+ ISNULL(TermsOfLeaseContracts.AmountOfLeaseAssetsByuout, TTConclusionOfLeaseAgreement.AmountOfLeaseAssetsByuout) AS TermsOfTheAgreementAmount,
	|
	|	ISNULL(TermsOfLeaseContracts.LeaseItemsCost, TTConclusionOfLeaseAgreement.LeaseItemsCost) AS TermsOfTheContractTheCostOfRentalItems,
	|	ISNULL(TermsOfLeaseContracts.SecurityDepositAmount, TTConclusionOfLeaseAgreement.SecurityDepositAmount) AS TermsOfTheAgreementAmountOfTheSecurityPayment,
	|	ISNULL(TermsOfLeaseContracts.LeaseServicesAmount, TTConclusionOfLeaseAgreement.LeaseServicesAmount) AS TermsOfTheContractAmountOfRentalServices,
	|	ISNULL(TermsOfLeaseContracts.AmountOfLeaseAssetsByuout, TTConclusionOfLeaseAgreement.AmountOfLeaseAssetsByuout) AS TermsOfTheContractTheAmountOfPurchaseOfRentalItems,
	|	ISNULL(TermsOfLeaseContracts.InterestAmount, TTConclusionOfLeaseAgreement.InterestAmount) AS TermsOfTheAgreementAmountOfInterest,
	|	ISNULL(TermsOfLeaseContracts.VATAmount, TTConclusionOfLeaseAgreement.VATAmount) AS TermsOfTheAgreementAmountOfVAT,
	|	ISNULL(TermsOfLeaseContracts.VATRate, TTConclusionOfLeaseAgreement.VATRate) AS TermsOfAgreement_VATRate,
	|	ISNULL(TermsOfLeaseContracts.LeaseStartDate, TTConclusionOfLeaseAgreement.LeaseStartDate) AS TermsOfAgreement_StartDateOfLease,
	|	ISNULL(TermsOfLeaseContracts.DateOfFirstPayment, TTConclusionOfLeaseAgreement.DateOfFirstPayment) AS TermsOfTheAgreementDateOfTheFirstPayment,
	|	ISNULL(TermsOfLeaseContracts.DateOfFirstSecurityPayment, TTConclusionOfLeaseAgreement.DateOfFirstSecurityPayment) AS TermsOfTheAgreementDateOfTheFirstSecurityPayment,
	|	ISNULL(TermsOfLeaseContracts.BuyoutDate, TTConclusionOfLeaseAgreement.BuyoutDate) AS TermsOfTheAgreementPurchaseDate,
	|	ISNULL(TermsOfLeaseContracts.InterestRate, TTConclusionOfLeaseAgreement.InterestRate) AS TermsOfTheAgreementInterestRate,
	|	ISNULL(TermsOfLeaseContracts.PaymentFrequency, TTConclusionOfLeaseAgreement.PaymentFrequency) AS TermsOfTheAgreementFrequencyOfPayments,
	|	ISNULL(TermsOfLeaseContracts.AccrualFrequency, TTConclusionOfLeaseAgreement.AccrualFrequency) AS TermsOfTheAgreementFrequencyOfAccruals_3,
	|	ISNULL(TermsOfLeaseContracts.PaymentForLeaseService, TTConclusionOfLeaseAgreement.PaymentForLeaseService) AS TermsOfTheContractPaymentForRentalServices,
	|	ISNULL(TermsOfLeaseContracts.AccrualOfLeaseService, TTConclusionOfLeaseAgreement.AccrualOfLeaseService) AS TermsOfTheContractAccrualOfRentalServices,
	|	ISNULL(TermsOfLeaseContracts.TermYears, TTConclusionOfLeaseAgreement.TermYears) AS TermsOfAgreement_TermOfYears,
	|	ISNULL(TermsOfLeaseContracts.TermMonths, TTConclusionOfLeaseAgreement.TermMonths) AS TermsOfAgreement_TermMonths,
	|	ISNULL(TermsOfLeaseContracts.TermDays, TTConclusionOfLeaseAgreement.TermDays) AS TermsOfAgreement_TermOfDays,
	|	ISNULL(TermsOfContractFirst.Recorder, TTConclusionOfLeaseAgreement.Ref) AS DocumentSigningOfLeaseContract,
	|	TermsOfLeaseContracts.Recorder AS TermsOfTheAgreementChangeOfTerms,
	|	ISNULL(TermsOfContractFirst.Period, DATETIME(1, 1, 1)) AS ContractTermsFirst_Period,
	|	NOT TermsOfContractFirst.Recorder IS NULL AS TheTermsOfTheContractConducted
	|FROM
	|	Catalog.LeaseContract AS LeaseContract
	|		LEFT JOIN InformationRegister.TermsOfLeaseContracts.SliceLast(, Contract = &Contract) AS TermsOfLeaseContracts
	|		ON TermsOfLeaseContracts.Contract = LeaseContract.Ref
	|		LEFT JOIN InformationRegister.TermsOfLeaseContracts.SliceFirst(, Contract = &Contract) AS TermsOfContractFirst
	|		ON TermsOfContractFirst.Contract = LeaseContract.Ref
	|		LEFT JOIN TTConclusionOfLeaseAgreement AS TTConclusionOfLeaseAgreement
	|		ON TRUE
	|WHERE
	|	LeaseContract.Ref = &Contract";
	
	Query = New Query(QueryText);
	Query.SetParameter("Contract", Object.Ref);
	
	SetPrivilegedMode(True);
	Results = Query.ExecuteBatch();
	SetPrivilegedMode(False);

	Result = Results[Results.UBound()];
	If Result.IsEmpty() Then
		Return;
	EndIf;
	
	Selection = Result.Select();
	Selection.Next();
	
	FillPropertyValues(ThisObject, Selection);
	SigningOfLeaseContract = Selection.DocumentSigningOfLeaseContract;
	
	If ValueIsFilled(SigningOfLeaseContract) Then
		
		LabelTitle = New Array;

		If Not Selection.TheTermsOfTheContractConducted Then
			LabelText = StrTemplate(
				NStr("vi = 'Ký hợp đồng: <a href = ""%1"">đã lập nhưng chưa kết chuyển</a>';
					|ru = 'Заключение договора: <a href = ""%1"">оформлено, но не проведено</a>';
					|en = 'Signing the contract: <a href = ""%1"">registered but not posted</a>'; fa = 'Signing the contract: <a href = ""%1"">registered but not posted</a>';
					|it = 'Заключение договора: <a href = ""%1"">оформлено, но не проведено</a>';
					|pl = 'Signing the contract: <a href = ""%1"">registered but not posted</a>';
					|tr = 'Sözleşmenin imzalanması: <a href = ""%1"">düzenlendi ama kaydedilmedi</a>'"), 
				GetURL(SigningOfLeaseContract));
			LabelText = NonCurrentAssetsClientServer.FormattedString(LabelText);
		Else
			LabelText = StrTemplate(
				NStr("vi = 'Ký hợp đồng: <a href = ""%1"">đã lập%2</a>';
					|ru = 'Заключение договора: <a href = ""%1"">оформлено %2</a>';
					|en = 'Signing the contract: <a href = ""%1"">registered %2</a>'; fa = 'Signing the contract: <a href = ""%1"">registered %2</a>';
					|it = 'Заключение договора: <a href = ""%1"">оформлено %2</a>';
					|pl = 'Signing the contract: <a href = ""%1"">registered %2</a>';
					|tr = 'Sözleşmenin imzalanması: <a href = ""%1"">düzenlendi%2</a>'"), 
				GetURL(SigningOfLeaseContract),
				Format(Selection.ContractTermsFirst_Period, "DLF=D"));
			LabelText = NonCurrentAssetsClientServer.FormattedString(LabelText);
		EndIf;
		LabelTitle.Add(LabelText);
		
		LabelTitle.Add(" ("); 
		If Selection.TermsOfAgreement_TermOfYears + Selection.TermsOfAgreement_TermMonths + Selection.TermsOfAgreement_TermOfDays > 0 Then
			
			EndDate = NonCurrentAssetsClientServer.EndDateByDeadline(
						Selection.TermsOfAgreement_StartDateOfLease, 
						Selection.TermsOfAgreement_TermOfYears, 
						Selection.TermsOfAgreement_TermMonths, 
						Selection.TermsOfAgreement_TermOfDays);
						
			StringTermPresentation = NonCurrentAssetsClientServer.StringTermPresentation(
									Selection.TermsOfAgreement_TermOfYears,
									Selection.TermsOfAgreement_TermMonths,
									Selection.TermsOfAgreement_TermOfDays);
									
			TitleText = StrTemplate(
				NStr("vi = 'thời hạn thuê: từ %1 đến %2, %3';
					|ru = 'срок аренды: с %1 по %2, %3';
					|en = 'rental period: from %1 to %2, %3'; fa = 'rental period: from %1 to %2, %3';
					|it = 'periodo affitto: da %1 a %2, %3';
					|pl = 'okres dzierżawy: od %1 do %2, %3';
					|tr = 'Kiralama süresi: %1 itibarıyla %2 tarihine kadar, %3'"), 
				Format(Selection.TermsOfAgreement_StartDateOfLease, "DLF=D;"), 
				Format(EndDate, "DLF=D;"),
				StringTermPresentation);
			
			LabelTitle.Add(TitleText);
			
		Else
			LabelTitle.Add(NStr("vi = 'chưa chỉ ra thời hạn thuê';
								|ru = 'срок аренды не указан';
								|en = 'rental period is not specified'; fa = 'rental period is not specified';
								|it = 'periodo affitto non indicato';
								|pl = 'okres dzierżawy nie jest podany';
								|tr = 'kira süresi belirtilmemiştir'"));
		EndIf;
		LabelTitle.Add(")");
		 
		ResultModificationOfContract = Results[Results.UBound()-2];
		If Not ResultModificationOfContract.IsEmpty() Then
			LabelTitle.Add(Chars.LF);
			LabelTitle.Add(NStr("vi = 'Đã thay đổi điều khoản hợp đồng:';
								|ru = 'Условия договора изменены:';
								|en = 'The contract terms have been changed:'; fa = 'The contract terms have been changed:';
								|it = 'Le condizioni dell''accordo sono state modificate:';
								|pl = 'Warunki umowy zostały zmienione:';
								|tr = 'Sözleşme şartları değiştirilmiştir:'"));
			LabelTitle.Add(" ");
			ThisIsFirstDocument = True;
			SamplingChanges = ResultModificationOfContract.Select();
			While SamplingChanges.Next() Do
				If ThisIsFirstDocument Then
					ThisIsFirstDocument = False;
				Else
					LabelTitle.Add(", ");
				EndIf;
				LabelTitle.Add(New FormattedString
					(Format(SamplingChanges.Period, "DLF=D;"),,,, GetURL(SamplingChanges.Recorder)));
			EndDo;
		EndIf;
		ResultTerminationOfContract = Results[Results.UBound()-1];
		If Not ResultTerminationOfContract.IsEmpty() Then
			LabelTitle.Add(Chars.LF);
			LabelTitle.Add(NStr("vi = 'Hợp đồng bị ngừng:';
								|ru = 'Договор прекращен:';
								|en = 'The contract is terminated:'; fa = 'The contract is terminated:';
								|it = 'Договор прекращен:';
								|pl = 'The contract is terminated:';
								|tr = 'Sözleşme feshedildi:'"));
			LabelTitle.Add(" ");
			SamplingTermination = ResultTerminationOfContract.Select();
			SamplingTermination.Next();
			LabelTitle.Add(New FormattedString
				(Format(SamplingTermination.Period, "DLF=D;"),,,, GetURL(SamplingTermination.Recorder)));
		EndIf;
		
	Else
		StringText = StrTemplate(NStr("vi = 'Ký hợp đồng: <a href = ""%1"">lập</a>';
										|ru = 'Заключение договора: <a href = ""%1"">оформить</a>';
										|en = 'Signing the contract: <a href = ""%1"">register</a>'; fa = 'Signing the contract: <a href = ""%1"">register</a>';
										|it = 'Заключение договора: <a href = ""%1"">оформить</a>';
										|pl = 'Signing the contract: <a href = ""%1"">register</a>';
										|tr = 'Sözleşmenin imzalanması: <a href = ""%1"">düzenle</a>'"), "#Create");
		LabelTitle = NonCurrentAssetsClientServer.FormattedString(StringText);
	EndIf;			
	
	Items.TheDecorationOfTheTermsOfTheContract.Title = New FormattedString(LabelTitle);
	
EndProcedure

&AtClient
Procedure TextOfAgreementTermsAndConditionsClickFinish(QuestionResult, AdditionalParameters) Export
	
	If Not ValueIsFilled(Object.Ref) Then
		
		If QuestionResult <> DialogReturnCode.Yes Then
			Return;
		EndIf;
		
		If Not Write() Then
			Return;
		EndIf;
		
	EndIf;
	
	If ValueIsFilled(SigningOfLeaseContract) Then
		FormParameters = New Structure;
		FormParameters.Insert("Key", SigningOfLeaseContract);
	Else
		FormParameters = New Structure;
		FormParameters.Insert("Basis", Object.Ref);
	EndIf;

	OpenForm("Document.SigningOfLeaseContract.ObjectForm", FormParameters);
	
EndProcedure

&AtClient
Procedure OpenPaymentAndAccrualSchedule(ChartName)
	
	FormParameters = New Structure;
	FormParameters.Insert("ChartName", ChartName);
	FormParameters.Insert("Contract", Object.Ref);
	FormParameters.Insert("GetData", True);
	
	OpenForm("Catalog.LeaseContract.Form.PaymentAndAccrualSchedule", FormParameters);
	
EndProcedure

&AtServer
Procedure SetVisibilityOfInputCommandsBasedOn_()

	If AttachableCommandsParameters = Undefined Then
		Return;
	EndIf;
	
	SettingsAddress = AttachableCommandsParameters.CommandsTableAddress;
	CommandsTable = GetFromTempStorage(SettingsAddress);
	
	QueryText = 
	"SELECT
	|	TermsOfLeaseContracts.State
	|FROM
	|	InformationRegister.TermsOfLeaseContracts.SliceLast(, Contract = &Ref) AS TermsOfLeaseContracts";
	
	Query = New Query(QueryText);
	Query.SetParameter("Ref", Object.Ref);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	StateOfAgreement = Enums.CounterpartyContractStates.EmptyRef();
	
	If Selection.Next() Then
		StateOfAgreement = Selection.State;
	EndIf;
	
	ContractIsValid = 
		StateOfAgreement = Enums.CounterpartyContractStates.Valid
		And Object.Status =Enums.CounterpartyContractStatuses.Valid;
		 
	ContractIsClosed = 
		(StateOfAgreement = Enums.CounterpartyContractStates.Closed); 
	
	If AccessRight("Insert", Metadata.Documents.SigningOfLeaseContract) Then
		NonCurrentAssetsInternal.SetVisibilityOfInputCommandBasedOn(
			Items, "SigningOfLeaseContract", CommandsTable, Not ContractIsValid And Not ContractIsClosed);
	EndIf; 
		
	If AccessRight("Insert", Metadata.Documents.FixedAssetsInitialRecognition2_4) Then
		NonCurrentAssetsInternal.SetVisibilityOfInputCommandBasedOn(
			Items, "FixedAssetsInitialRecognition2_4", CommandsTable, ContractIsValid);
	EndIf; 
	
	If AccessRight("Insert", Metadata.Documents.LeaseTermAdjustment) Then
		NonCurrentAssetsInternal.SetVisibilityOfInputCommandBasedOn(
			Items, "LeaseTermAdjustment", CommandsTable, ContractIsValid);
	EndIf; 
	
	If AccessRight("Insert", Metadata.Documents.VendorInvoiceLeasedAssets) Then
		NonCurrentAssetsInternal.SetVisibilityOfInputCommandBasedOn(
			Items, "VendorInvoiceLeasedAssets", CommandsTable, ContractIsValid);
	EndIf; 
	
	If AccessRight("Insert", Metadata.Documents.LeaseTermination) Then
		NonCurrentAssetsInternal.SetVisibilityOfInputCommandBasedOn(
			Items, "LeaseTermination", CommandsTable, ContractIsValid);
	EndIf; 
	
EndProcedure

&AtServer
Procedure SetFormHeader()
	
	If Object.ContractType = PredefinedValue("Enum.TypesOfLeaseContracts.Lease") Then
		NewTitle = NStr("vi = 'Hợp đồng thuê';
						|ru = 'Договор аренды';
						|en = 'Rental contract'; fa = 'قرارداد اجاره';
						|it = 'Contratto di affitto';
						|pl = 'Umowa dzierżawy';
						|tr = 'Kiralama sözleşmesi'");
	ElsIf Object.ContractType = PredefinedValue("Enum.TypesOfLeaseContracts.Leasing") Then
		NewTitle = NStr("vi = 'Hợp đồng leasing';
						|ru = 'Договор лизинга';
						|en = 'Financial lease contract'; fa = 'قرارداد اجاره مالی';
						|it = 'Contratto di leasing';
						|pl = 'Umowa leasingu';
						|tr = 'Finansal kiralama sözleşmesi'");
	Else
		NewTitle = NStr("vi = 'Hợp đồng thuê (leasing)';
						|ru = 'Договор аренды (лизинга)';
						|en = 'Rental (financial lease) contract'; fa = 'قرارداد اجاره (اجاره مالی)';
						|it = 'Contratto di affitto (leasing)';
						|pl = 'Umowa dzierżawy (leasingu)';
						|tr = 'Kiralama sözleşmesi (finansal kiralama)'");
	EndIf;
	
	If ValueIsFilled(Object.Ref) Then
		NewTitle = TrimAll(Object.Description) + " (" + NewTitle + ")";
	Else
		NewTitle = NewTitle + " " + NStr("vi = '(tạo)';
										|ru = '(создание)';
										|en = '(Create)'; fa = '(Create)';
										|it = '(creazione)';
										|pl = '(utworzenie)';
										|tr = '(oluştur)'");
	EndIf;
		
	Title = NewTitle;
	
EndProcedure

&AtServer
Procedure EstablishVisibilityOfTypeOfIncomeOfForeignCounterparty()

EndProcedure


#EndRegion

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
	ElsIf Item.Name = "sh_ShamsiInput_ValidityEndDate" Then
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
