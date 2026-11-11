#Region Variables

&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	If PrintFormOpeningIsRequired Then
		Return;
	EndIf;
	
	// Handler of the "Versioning of objects" mechanism
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	// Handler of the "Properties" mechanism
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	PropertyManager.OnCreateAtServer(ThisForm, AdditionalParameters);
	
	UseAdvancedFeaturesOfSalesOrder = GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder");
	UseStandardTermsOfSalesWithCustomers         = GetFunctionalOption("UseStandardTermsOfSalesWithCustomers");
	UseCustomerTermsOfSales  = GetFunctionalOption("UseCustomerTermsOfSales");
	UseCustomerContracts                  = GetFunctionalOption("UseCustomerContracts");
	VarianceFromSalesTermsAndConditions                       = UserRightsCached.VarianceFromSalesTermsAndConditions();
	ProvideAgentServicesOnPurchaseToPrincipals	= GetFunctionalOption("ProvideAgentServicesOnPurchaseToPrincipals");
	UsePriceManagementSystem25                   = PriceManagementSystemServerCall.UsePriceManagementSystem25();
	ItIsAllowedToCreatePriceTypes                       = GetFunctionalOption("UseSeveralPriceTypes")
	                                                And AccessRight("Insert", Metadata.Catalogs.TypesOfPrices);
	OnlyConsignmentSales25                     = GetFunctionalOption("OnlyConsignmentSales25");
	SelectConsignmentSalesVersion                = GetFunctionalOption("SelectConsignmentSalesVersion")
	                                                Or (ValueIsFilled(Object.Ref) And Not Object.ConsignmentSales25);
	
	FillOperationSelectionList();
	SetVisibilityOfBookmarks();
	
	If Not ValueIsFilled(Object.Ref) Then
		
		OnReadCreateAtServer();
		WhenBusinessTransactionChangesServer();
		
	EndIf;
	
	If Object.BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent
		Or Object.ConsignmentSales25 Then
		
		NewLink = New ChoiceParameterLink("Filter.ConsignmentSales25", "Object.ConsignmentSales25");
		ArrayOfSelectParameterRelationships_ = New Array();
		ArrayOfSelectParameterRelationships_.Add(NewLink);
		Items.Terms.ChoiceParameterLinks = New FixedArray(ArrayOfSelectParameterRelationships_);
		
	EndIf;
	
	CopyingValue = Parameters.CopyingValue;
	DiscountsMarkupsServer.WhenCreatingDiscountSourcesOnServer(ThisObject,
									?(CopyingValue.IsEmpty(), Object.Ref, CopyingValue));
	
	Items.Terms.Visible				  = Not Object.Standard_ And UseStandardTermsOfSalesWithCustomers 
													And UseCustomerTermsOfSales;
	Items.Terms.AutoMarkIncomplete = Not Object.Standard_ And UseStandardTermsOfSalesWithCustomers 
													And UseCustomerTermsOfSales And Not VarianceFromSalesTermsAndConditions;
	
	Items.PartnersSegment.Visible = Object.Standard_ And ToUseTermsOfSales;
	Items.Partner.Visible 			= Not Object.Standard_;
	Items.Counterparty.Visible 		= Not Object.Standard_ And ToUseTermsOfSales;
	
	Items.Description.Visible 		 = ToUseTermsOfSales;
	Items.BusinessOperation.Visible = ToUseTermsOfSales;
	Items.ContactPerson.Visible 		 = ToUseTermsOfSales;
	Items.ValidityPeriodGroup.Visible  = ToUseTermsOfSales;
	Items.ProductSegment.Visible   = ToUseTermsOfSales;
	
	Items.Organization.Visible 	  = GetFunctionalOption("UseMultipleCompanies");
	Items.ContactPerson.Visible = Not Object.Standard_;
	
	TMCommonUseClientServer.SetFormItemProperty(Items,
																	"GroupOfTheReturnDateCalculationMode",
																	"Visible", 
																	GetFunctionalOption("UseReusablePackage"),
																	True);
	
	SalesServer.SetModeForSelectingGroupsOfWarehouseItems(Items.Warehouse);
	
	IsBaseVersion = GetFunctionalOption("BaseVersion");
	
	Items.MinimumOrderAmount.Visible       = UseAdvancedFeaturesOfSalesOrder;
	Items.MinimumOrderAmountCurrency.Visible = UseAdvancedFeaturesOfSalesOrder;
	
	Items.OrderFrequency.Visible           = UseAdvancedFeaturesOfSalesOrder
													And Not IsBaseVersion;
	Items.DeliveryPeriodDecoration.Visible = UseAdvancedFeaturesOfSalesOrder
													And Not IsBaseVersion;
	
	Items.ShiftingDateOfTransferOfOwnership.Visible = Object.SaleWithDeferredTransferOfTitleIsAllowed;
	Items.ShiftTransitionDateDecoration.Visible = Object.SaleWithDeferredTransferOfTitleIsAllowed;
	
	SetFlagHeaderAvailableToExternalUsers();
	
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);

	Items.GoodsPriceKind.QuickChoice = Not GetFunctionalOption("UseSeveralPriceTypes");
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	SetVisibilityOfInputCommandsBasedOn();
	
	SetAvailabilityOfCommandsForExternalUser();	
		
	// Price Type Settings
	If UseSeveralPriceTypes Then
		UpdateIndividualPriceViewPresentation();
		RefreshUseGeneralPriceViewCheckbox_();	
		UpdateUseCustomPriceViewCheckbox();
		AdjustVisibilityAvailabilityOfGeneralPriceViewSettings(ThisForm);
		AdjustVisibilityAvailabilityOfIndividualPriceViewSettings(ThisForm);
	EndIf;
	UpdatePresentationClarificationPercentDiscountsMargins();
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations

	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	If TMCommonUseClientServer.AnExternalUserIsAuthorized() Then
		PrintFormOpeningIsRequired = True;
		Return;
	EndIf;
	
	OnReadCreateAtServer();
	
	PropertyManager.OnReadAtServer(ThisForm, CurrentObject);

	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);

	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	If Object.AvailableToExternalUsers
		And Not UseSeveralPriceTypes
		And Not ValueIsFilled(Object.PricesKind) Then
		
		If Items.PriceListUsage.Enabled Then
			CommonClientServer.MessageToUser(
				NStr("vi = 'Đối với các thỏa thuận hợp lệ dành cho người sử dụng ngoài, nên sử dụng giá từ Bảng giá.';
					|ru = 'Для соглашений, доступных внешним пользователям должны использоваться цены из Прайс-листа.';
					|en = 'Prices from the price list should be used for agreements available for external users.'; fa = 'Prices from the price list should be used for agreements available for external users.';
					|it = 'Per gli accordi accessibili agli utenti esterni, è necessario utilizzare i prezzi del listino prezzi.';
					|pl = 'Do porozumień, dostępnych dla użytkowników zewnętrznych powinny być używane ceny z Cennika.';
					|tr = 'Harici kullanıcılara sunulan sözleşmeler için Fiyat Listesindeki fiyatlar kullanılmalıdır.'"), ,
				"PriceListUsage",,Cancel);
		Else
			If Not Object.PriceIncludesVAT Then
				CommonClientServer.MessageToUser(
					NStr("vi = 'Đối với các thỏa thuận hợp lệ với người sử dụng ngoài,
					           |cần sử dụng đơn giá từ Bảng giá.
					           |Tính năng chỉ ra đơn giá từ Bảng giá sẽ chỉ khả dụng khi đặt dấu hộp kiểm ""Đơn giá gồm thuế GTGT""';
					           |ru = 'Для соглашений, доступных внешним пользователям 
					           |должны использоваться цены из Прайс-листа. 
					           |Возможность указания цены из Прайс-листа будет доступна только при включенном флаге ""Цена включает НДС""';
					           |en = 'Prices from the price list should be used for agreements 
					           |available for external users. A price from the price list 
					           |can be specified only if the ""Price includes VAT"" check box is selected'; fa = 'Prices from the price list should be used for agreements 
					           |available for external users. A price from the price list 
					           |can be specified only if the ""Price includes VAT"" check box is selected';
					           |it = 'Per gli accordi accessibili agli utenti esterni, 
					           |è necessario utilizzare i prezzi del listino prezzi. 
					           |La possibilità di specificare il prezzo dal listino prezzi sarà disponibile solo se è abilitato il flag ""Prezzo IVA inclusa""';
					           |pl = 'Do porozumień, dostępnych dla użytkowników zewnętrznych
					           |powinny być używane ceny z Cennika.
					           |Możliwość wskazania ceny z Cennika będzie dostępna tylko przy włączonym zaznaczeniu ""Cena zawiera VAT""';
					           |tr = 'Harici kullanıcılara sunulan sözleşmeler için 
					           | Fiyat Listesindeki fiyatlar kullanılmalıdır. 
					           |Fiyat Listesinden fiyat belirleme olanağı, sadece ""Fiyata KDV dahildir"" bayrağı etkinleştirildiğinde kullanılabilir.'"), Object.Ref,
					"PriceIncludesVAT",
					"Object",Cancel);
			Else
				CommonClientServer.MessageToUser(
					NStr("vi = 'Đối với các thỏa thuận hợp lệ với người sử dụng ngoài 
					           |cần sử dụng đơn giá từ Bảng giá.
					           |Tính năng chỉ ra đơn giá từ Bảng giá sẽ chỉ khả dụng khi đặt dấu hộp kiểm ""Đơn giá gồm thuế GTGT""';
					           |ru = 'Для соглашений, доступных внешним пользователям
					           |должны использоваться цены из Прайс-листа.
					           |Возможность указания цены из Прайс-листа будет доступна только при выключенном флаге ""Цена включает НДС""';
					           |en = 'Prices from the price list should be used for agreements 
					           |available for external users. A price from the price list 
					           |can be specified only if the ""Price includes VAT"" check box is cleared.'; fa = 'Prices from the price list should be used for agreements 
					           |available for external users. A price from the price list 
					           |can be specified only if the ""Price includes VAT"" check box is cleared.';
					           |it = 'Per gli accordi accessibili agli utenti esterni,
					           |è necessario utilizzare i prezzi del listino prezzi. 
					           |La possibilità di specificare il prezzo dal listino prezzi sarà disponibile solo se è abilitato il flag ""Prezzo IVA inclusa""';
					           |pl = 'Do porozumień, dostępnych dla użytkowników zewnętrznych
					           |powinny być używane ceny z Cennika.
					           |Możliwość wskazania ceny z Cennika będzie dostępna tylko przy wyłączonym zaznaczeniu ""Cena zawiera VAT""';
					           |tr = 'Harici kullanıcılara sunulan sözleşmeler için
					           |Fiyat Listesindeki fiyatlar kullanılmalıdır.
					           |Fiyat Listesinden fiyat belirleme olanağı, sadece ""Fiyata KDV dahildir"" bayrağı etkinleştirildiğinde kullanılabilir.'"), Object.Ref,
					"PriceIncludesVAT",
					"Object",Cancel);
			EndIf;
		EndIf;
		
	EndIf;
		
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisForm, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// Handler of the "Properties" mechanism
	PropertyManager.BeforeWriteAtServer(ThisForm, CurrentObject);

	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);

	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	SetAvailabilityOfItemsByStatusServer();
	FillInFeatureAttribute = New Structure("Products", "ItemVariantsAreUsed");
	ProductsServer.FillInServiceDetailsForProductInCollection(
		Object.Goods,
		New Structure("FillInFeatureAttribute", FillInFeatureAttribute));
	SetFormHeader();
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);

	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	If RefreshInterface Then
		RefreshInterface = False;
		RefreshInterface();
	EndIf;

	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);

	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	ClearDiscountsMarginsUnderCommissionAgreement();
	DiscountsMarkupsServer.WhenRecordingOnServerOfSourcesOfValidityOfDiscountsMargins(CurrentObject, CopyingValue);
	
EndProcedure

// Parameters:
// 	EventName - String
// 	Parameter - Structure:
// 		* Source - Array
&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Handler of the "Properties" mechanism
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
		
	ElsIf EventName = "Write_ValidityOfDiscountsMarkups" And Parameter.Source.Find(Object.Ref) <> Undefined Then
		
		UpdateDiscountTree();
		
		
	EndIf;
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If PrintFormOpeningIsRequired Then
		
		Cancel = True;
		SelfServiceClient.PrintClientAgreement(Object.Ref);
		Return;
		
	EndIf;
	
	SetVisibilityOfPaymentInCurrency();
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// The end of the standard subsystem.Pluggable commands
	// Standard subsystems.Worksfiles
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure TermsStartChoice(Item, ChoiceData, StandardProcessing)

	AgreementSelectionParameters = SalesClient.ParametersForStartingSelectionOfAgreementWithClient();
	
	AgreementSelectionParameters.Item              = Item;
	AgreementSelectionParameters.Partner              = Object.Partner;
	AgreementSelectionParameters.Document             = Object.Terms;
	AgreementSelectionParameters.DocumentDate        = Object.Date;
	AgreementSelectionParameters.OnlyStandard        = True;
	AgreementSelectionParameters.FormDataStructure = Object;
	AgreementSelectionParameters.ConsignmentSales25 = Object.ConsignmentSales25;
	
	AdditionalParameters = New Structure;
	
	AdditionalParameters.Insert("AgreementSelectionParameters", AgreementSelectionParameters);
	AdditionalParameters.Insert("StandardProcessing", StandardProcessing);

	SalesClient.StartSelectingAgreementWithClient(AgreementSelectionParameters, StandardProcessing);

EndProcedure

&AtClient
Procedure PartnerOnChange(Item)
	
	UpdateDeliverySchedulingSelectionList();
	
	If Not ValueIsFilled (Object.Partner) Then
		Object.Terms = PredefinedValue("Catalog.TermsOfSale.EmptyRef");
		Return;
	EndIf;
	
	WhenChangingPartnerServer();
	If ValueIsFilled(Object.Terms) Then
		SalesClient.NotifyEndOfFillingInDefaultSalesConditions();
	EndIf;
	
EndProcedure

&AtClient
Procedure TermsOnChange(Item)
	
	If Not ValueIsFilled (Object.Terms) Then
		Return;
	EndIf;
	
	WhenChangingAgreementAtServer();
	UpdateDiscountTree();
	
	SalesClient.NotifyEndOfFillingInTermsOfSale();
	
EndProcedure

&AtClient
Procedure CurrencyOnChange(Item)
	
	If PriceManagementSystemClient.CurrencyConversionRequired(Object, DocumentCurrency) Then
		
		WhenChangingCurrencyServer(Object.Currency);
		PriceManagementSystemClient.NotifyAboutEndOfConversionOfAmountsIntoCurrency(DocumentCurrency, Object.Currency);
		
	EndIf;
	
	DocumentCurrency = Object.Currency;
	
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.TransferToCommissionAgent") Then
		Object.ARAPCurrency = Object.Currency;
		
		FillInPaymentInCurrencyOfFinancialAccountingGroup(
			Object.Organization,
			Object.ARAPCurrency,
			Object.ForeignCurrencyTransaction,
			Object.FinancialAccountingGroup,
			Object.ContractsAreUsed,
			Object.BusinessOperation);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure StatusOnChange(Item)
	
	DocumentStatus = Object.Status;
	
	If Object.Approved And 
		Object.Status <> PredefinedValue("Enum.StatusesOfTermsOfSales.Valid")
		And Object.Status <> PredefinedValue("Enum.StatusesOfTermsOfSales.Closed") Then
		
		Object.Approved = False;
		
	EndIf;
	
	SetAvailabilityOfItemsByStatusServer();
	
EndProcedure

&AtClient
Procedure FrequentOnChange(Item)
	
	WhenRegularityChangesServer();
	
EndProcedure

&AtClient
Procedure PeriodOnChange(Item)
	
	CalculatePeriodOfRegularAgreement();
	DescriptionOfRegularConditions = DescriptionOfRegularConditions(Object.NumberOfPeriods, Object.Period, Object.DocumentAmount, DocumentCurrency);
	
EndProcedure

&AtClient
Procedure NumberOfPeriodsOnChange(Item)
	
	CalculatePeriodOfRegularAgreement();
	DescriptionOfRegularConditions = DescriptionOfRegularConditions(Object.NumberOfPeriods, Object.Period, Object.DocumentAmount, DocumentCurrency);
	
EndProcedure

&AtClient
Procedure DocumentAmountOnChange(Item)
	
	DescriptionOfRegularConditions = DescriptionOfRegularConditions(Object.NumberOfPeriods, Object.Period, Object.DocumentAmount, DocumentCurrency);
	
EndProcedure

&AtClient
Procedure BusinessOperationOnChange(Item)
	
	WhenBusinessTransactionChangesServer();
	
EndProcedure

&AtServer
Procedure CommissionFeeCalculationMethodOnChangeServer()
	
	ItemArray = New Array();
	ItemArray.Add("RemunerationPercentage");
	ItemArray.Add("KeepCommissionFee");
	
	If Object.CommissionFeeCalculationMethod = Enums.CommissionFeeCalculationMethods.NotCalculating Or
		Not ValueIsFilled(Object.CommissionFeeCalculationMethod) Then
		Object.RemunerationPercentage  = Metadata.Catalogs.TermsOfSale.Attributes.RemunerationPercentage.FillValue;
		Object.KeepCommissionFee = Metadata.Catalogs.TermsOfSale.Attributes.KeepCommissionFee.FillValue;
		TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled", False);
	Else
		TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled", True);
	EndIf;

	If Object.CommissionFeeCalculationMethod = Enums.CommissionFeeCalculationMethods.ArbitraryAmount Then
		TMCommonUseClientServer.SetPropertyOfFormElements(Items, "RemunerationPercentage", "Visible", False);
	Else
		TMCommonUseClientServer.SetPropertyOfFormElements(Items, "RemunerationPercentage", "Visible", True);
	EndIf;
	
EndProcedure

&AtClient
Procedure CommissionFeeCalculationMethodOnChange(Item)
	
	CommissionFeeCalculationMethodOnChangeServer();
	
EndProcedure

&AtClient
Procedure ValidityStartDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	If ValueIsFilled(Object.ValidityStartDate) Then
		CalculatePeriodOfRegularAgreement();
	EndIf;
	
EndProcedure

&AtClient
Procedure ContractsAreUsedOnChange(Item)
	
	Object.ContractsAreUsed = Boolean(ContractsAreUsed);
	
	ContractsAreUsedOnChangeServer();
	
	FillInCalculationProcedure();
	SetVisibilityOfPaymentInCurrency();
	
EndProcedure

&AtClient
Procedure CommentStartChoice(Item, ChoiceData, StandardProcessing)
	
	CommonClient.ShowCommentEditingForm(
		Item.EditText, 
		ThisObject, 
		"Object.Comment");
	
EndProcedure

&AtClient
Procedure LimitDiscountAdjustmentsOnChange(Item)
	
	UpdateVisibilityOfManualDiscountRestrictionElements(ThisObject);
	
EndProcedure

&AtClient
Procedure SaleWithDeferredTransferOfTitleIsAllowedOnChange(Item)
	
	If Not Object.SaleWithDeferredTransferOfTitleIsAllowed Then
		Object.DeadlineOfTransferOfTitleToGoods = 0;
	EndIf;
	
	UpdateVisibilityOfPropertyTransferShift(ThisForm);
	
EndProcedure

&AtClient
Procedure ReturnReusablePackageOnChange(Item)
	
	If Not Object.ReturnReusablePackage Then
		Object.PackageDepositIsRequired = False;
	EndIf;
	
	UpdateAvailabilityOfReturnContainerItems(ThisForm);
	
EndProcedure

&AtClient
Procedure AvailableToExternalUsersOnChange(Item)
	
	UpdateAvailabilityOfGeneralPriceView();
	
	UpdateAvailabilityOfSalesPlansItems(ThisForm);
	
EndProcedure

&AtClient
Procedure PlanningScenarioOnChange(Item)
	
	UpdateAvailabilityOfSalesPlansItems(ThisForm);

EndProcedure

&AtClient
Procedure ThePriceListViewIsUsedWhenChangingThePrice(Item)
	
	If PriceListUsage = 1 Then
		Object.PricesKind = PriceTypePriceList;
	Else
		Object.PricesKind = Undefined;
	EndIf;
	
EndProcedure

&AtClient
Procedure PriceIncludesVATOnChange(Item)
	
	If Not UseSeveralPriceTypes Then
		SetAvailabilityOfPriceList();
	EndIf;
	
EndProcedure

&AtClient
Procedure OptionForDisplayingDiscountsOnChange(Item)
	
	UpdateDiscountTree();
	
EndProcedure

&AtClient
Procedure SliceDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	UpdateDiscountTree();
	
EndProcedure

&AtClient
Procedure SplitGoodsIssueNotesByReferencesOnChange(Item)
	Object.SplitGoodsIssueNotesByReferences = Boolean(SplitGoodsIssueNotesByReferencesNumber);
EndProcedure

&AtClient
Procedure ARAPCurrencyOnChange(Item)
	
	FillInPaymentInCurrencyOfFinancialAccountingGroup(
		Object.Organization,
		Object.ARAPCurrency,
		Object.ForeignCurrencyTransaction,
		Object.FinancialAccountingGroup,
		Object.ContractsAreUsed,
		Object.BusinessOperation);
	SetVisibilityOfPaymentInCurrency();
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	LocalAccountingCurrency = SettingsValueClientServerCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	SetVisibilityOfPaymentInCurrency();
EndProcedure


&AtClient
Procedure ForeignCurrencyTransactionOnChange(Item)
	
	FillInFinancialAccountingGroup_(Object.Organization, Object.ARAPCurrency, Object.BusinessOperation, Object.FinancialAccountingGroup);
	
EndProcedure

&AtClient
Procedure UseTheGeneralViewOfThePriceOnChange(Item)
	
	UseGeneralViewOfPriceWhenChangingOnClient();
	AdjustVisibilityAvailabilityOfGeneralPriceViewSettings(ThisForm);
	
EndProcedure

&AtClient
Procedure UseAnIndividualViewOfThePriceOnChange(Item)
	
	UseIndividualViewOfPriceWhenChangingOnClient();
	AdjustVisibilityAvailabilityOfIndividualPriceViewSettings(ThisForm);
	
EndProcedure

&AtClient
Function HyperlinkClickParameters(TagName, Hyperlink = "")
	
	If TagName = "HyperlinkGoToPriceList" Then
		
		TypesOfPrices = New Array();
		TypesOfPrices.Add(Object.PricesKind);
		TypesOfPrices.Add(Object.SpecialPriceType);
		
		FormParameters = New Structure;
		FormParameters.Insert("TypesOfPrices",  TypesOfPrices);
		
		HyperlinkClickParameters = New Structure;
		HyperlinkClickParameters.Insert("FormName", "DataProcessor.PriceList.Form.Form");
		HyperlinkClickParameters.Insert("FormParameters",FormParameters);
		
	ElsIf TagName = "HyperlinkGoPriceChangeHistory" Then
		
		TypesOfPrices = New Array();
		TypesOfPrices.Add(Object.PricesKind);
		TypesOfPrices.Add(Object.SpecialPriceType);
		
		FormParameters = New Structure;
		FormParameters.Insert("TypesOfPrices",  TypesOfPrices);
		
		HyperlinkClickParameters = New Structure;
		If UsePriceManagementSystem25 Then
			HyperlinkClickParameters.Insert("FormName", "InformationRegister.ItemsPrices25.Form.ListForm");
		Else	
			HyperlinkClickParameters.Insert("FormName", "InformationRegister.ItemsPrices.Form.ListForm");
		EndIf;
		HyperlinkClickParameters.Insert("FormParameters", FormParameters);
			
	EndIf;
	
	If Not HyperlinkClickParameters.Property("FormWindowOpeningMode") Then
		HyperlinkClickParameters.Insert("FormWindowOpeningMode", FormWindowOpeningMode.Independent);
	EndIf;
	HyperlinkClickParameters.Insert("TagName", TagName);
	HyperlinkClickParameters.Insert("Hyperlink", Hyperlink);
	
	Return HyperlinkClickParameters
	
EndFunction

&AtClient
Procedure HyperlinkGoToPriceListURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	HyperlinkClickParameters = HyperlinkClickParameters(Item.Name);
	HyperlinkGoToFormParametersAndQuestion(HyperlinkClickParameters);
	
EndProcedure

&AtClient
Procedure HyperlinkGoPriceChangeHistoryURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	HyperlinkClickParameters = HyperlinkClickParameters(Item.Name);
	HyperlinkGoToFormParametersAndQuestion(HyperlinkClickParameters);
	
EndProcedure

&AtClient
Procedure HyperlinkGoToFormParametersAndQuestion(HyperlinkClickParameters)
	
	ClearMessages();
	
	If Not ValueIsFilled(Object.Ref)
		Or Modified Then
		
		QueryText = NStr("vi = 'Dữ liệu vẫn chưa được ghi lại.
		|Chỉ có thể chuyển đến thông tin bổ sung sau khi ghi lại phần tử.
		|Ghi lại phần tử?';
		|ru = 'Данные еще не записаны.
		|Переход к дополнительной информации возможен только после записи элемента.
		|Записать элемент?';
		|en = 'The data is not saved yet.
		|You can go to additional information only after the item is saved.
		|Save it?'; fa = 'The data is not saved yet.
		|You can go to additional information only after the item is saved.
		|Save it?';
		|it = 'I dati non sono ancora stati registrati.
		|Il passaggio all''informazione aggiuntiva è possibile solo dopo la registrazione dell''elemento.
		|Registrare l''elemento?';
		|pl = 'Dane nie zostały jeszcze zapisane.
		|Przejście do informacji dodatkowej jest możliwe tylko po zapisaniu elementu.
		|Zapisać element?';
		|tr = 'Veriler henüz kaydedilmedi.
		|Ek bilgilere geçiş sadece öğenin kaydından sonra mümkündür.
		|Öğe kaydedilsin mi?'");
		
		ShowQueryBox(New CallbackDescription("HyperlinkGoQuestionCompletion", ThisObject, HyperlinkClickParameters), QueryText, QuestionDialogMode.YesNo);
		Return;
		
	EndIf;
	
	GoHyperlink(HyperlinkClickParameters);
EndProcedure

&AtClient
Procedure HyperlinkGoQuestionCompletion(QuestionResult, AdditionalParameters) Export
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	Try
		ItemRecorded = Write();
	Except
		Return;
	EndTry;
	
	If Not ItemRecorded Then
		Return;
	EndIf;
	
	HyperlinkClickParameters = HyperlinkClickParameters(AdditionalParameters.TagName,
																		AdditionalParameters.Hyperlink);
	GoHyperlink(HyperlinkClickParameters);
EndProcedure

&AtClient
Procedure GoHyperlink(HyperlinkClickParameters)
	
	If HyperlinkClickParameters.Property("FormName") Then
		OpenForm(HyperlinkClickParameters.FormName,
			HyperlinkClickParameters.FormParameters, , ThisForm.UUID, , , ,
			HyperlinkClickParameters.FormWindowOpeningMode);
	Else
		ExceptionText = NStr("vi = 'Chưa xác định thao tác theo đường dẫn.';
							|ru = 'Не определено действие по гиперссылке.';
							|en = 'Hyperlink action is not identified.'; fa = 'Hyperlink action is not identified.';
							|it = 'Azione ipertestuale non definita.';
							|pl = 'Nie określono działania hiperłącza.';
							|tr = 'Köprü eylemi tanımlanmadı.'");
		Raise ExceptionText;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure GoodsSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field = Items.GoodsPrice Then
		
		CurrentData = Items.Goods.CurrentData;
		If ValueIsFilled(CurrentData.PriceKind) And Not Object.Approved Then
			ClearMessages();
			CommonClientServer.MessageToUser(
				NStr("vi = 'Để soạn đơn giá, hãy xóa dạng giá';
					|ru = 'Для редактирования цены очистите вид цены';
					|en = 'To edit the price, clear the price type'; fa = 'To edit the price, clear the price type';
					|it = 'Для редактирования цены очистите вид цены';
					|pl = 'To edit the price, clear the price type';
					|tr = 'Fiyatı düzenlemek için fiyat türünü temizleyin'"),
				Object.Ref,
				CommonClientServer.PathToTabularSection("Object.Goods", CurrentData.LineNumber, "PriceKind"),);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsProductsOnChange(Item)

	CurrentRow = Items.Goods.CurrentData;

	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentRow.Package);

	StructureOfActions.Insert("ProductsOnChangeOverridable", New Structure("FormName, TabularSectionName",
		ThisForm.FormName, "Goods"));

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

EndProcedure

&AtClient
Procedure GoodsPriceKindOnChange(Item)
	
	Items.Goods.CurrentData.Price = 0;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersDiscountsMarkups

&AtClient
Procedure DiscountsMarkupsSelection(Item, RowSelected, Field, StandardProcessing)
	
	If ValueIsFilled(Items.DiscountsMarkups.CurrentData.Ref) Then
		ShowValue(Undefined, Items.DiscountsMarkups.CurrentData.Ref);
	EndIf;
	
EndProcedure

&AtClient
Procedure DiscountsMarkupsOnActivateRow(Item)
	
	AttachIdleHandler("UpdatePresentationOfDiscountMarkUpUsage", 0.1, True);
	
EndProcedure

&AtClient
Procedure DiscountsMarkupsBeforeExpand(Item, String, Cancel)
	
	DiscountsMarkupsClient.SaveWhetherTreeNodeIsExpandedInList(String, Items.DiscountsMarkups, ExpandedTreeNodes, True);
	
EndProcedure

&AtClient
Procedure DiscountsMarkupsBeforeCollapse(Item, String, Cancel)
	
	DiscountsMarkupsClient.SaveWhetherTreeNodeIsExpandedInList(String, Items.DiscountsMarkups, ExpandedTreeNodes, False);
	
EndProcedure

&AtClient
Procedure InformationOnDiscountValidityURLProcessing(Item, Var_URL, StandardProcessing)
	
	StandardProcessing = False;
	If Var_URL = "ConfigureDiscounts" Then
			
			OpenForm("Catalog.DiscountsMarkups.ListForm", ,ThisObject);
			
	EndIf;
	
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

&AtClient
Procedure SetDateIntervalExecute(Command)
	
	TMCommonUseClient.EditPeriod(Object, 
		New Structure("StartDate, EndDate", "ValidityStartDate", "ValidityEndDate"));
	
EndProcedure

&AtClient
Procedure PopulateAPriceTypeOfTheSelectedLinesGoods(Command)
	
	If Object.Goods.Count() = 0 Then
		
		ShowMessageBox(Undefined, NStr("vi = 'Trong chứng từ chưa điền danh sách ""Hàng hóa"". Không thể điền dạng giá';
										|ru = 'В документе не заполнен список ""Товары"". Вид цен не может быть заполнен';
										|en = 'The ""Goods"" list in the document is not filled in. Cannot fill in price type'; fa = 'The ""Goods"" list in the document is not filled in. Cannot fill in price type';
										|it = 'Nel documento non è compilato l''elenco ""Prodotti"". Il tipo dei prezzi non può essere compilato';
										|pl = 'W dokumencie nie jest wypełniona lista ""Товары"". Rodzaj cen nie może być wypełniony';
										|tr = '""Ürünler"" listesi belgede doldurulmadı. Fiyat türü doldurulamaz'"));
		Return;
		
	EndIf;
	
	PriceSelectionOptions = EnterprisePricesFillingClient.NewFillOptionsSelectPriceType();
	PriceSelectionOptions.CallbackDescription = 
		New CallbackDescription( "PopulateAPriceTypeOfTheSelectedLinesGoodsCompletion", ThisObject);
	PriceSelectionOptions.PriceIncludesVAT = Object.PriceIncludesVAT;
	PriceSelectionOptions.UseWhileSellingToCustomers = True;
	EnterprisePricesFillingClient.ChooseTypeOfPrices(PriceSelectionOptions);
	
EndProcedure

&AtClient
Procedure PopulateAPriceTypeOfTheSelectedLinesGoodsCompletion(PricesKind, AdditionalParameters) Export
	
	If ValueIsFilled(PricesKind) Then
		
		PopulateAPriceTypeOfTheSelectedLinesGoodsServer(PricesKind);
		
		ShowUserNotification(
			NStr("vi = 'Dạng giá đã điền';
				|ru = 'Вид цен заполнен';
				|en = 'Price type is filled in'; fa = 'Price type is filled in';
				|it = 'Il tipo dei prezzi è compilato';
				|pl = 'Rodzaj cen został wypełniony';
				|tr = 'Fiyat türü dolduruldu'"),
			,
			StrReplace(NStr("vi = 'Dạng giá ""%PricesKind%"" trong bảng Hàng hóa đã điền.';
							|ru = 'Вид цен ""%PricesKind%"" в таблице Товары заполнен.';
							|en = 'The ""%PricesKind%"" price type in the Goods table is filled in.'; fa = 'The ""%PricesKind%"" price type in the Goods table is filled in.';
							|it = 'Il tipo dei prezzi ""%PricesKind%"" nella tabella Merci è compilato.';
							|pl = 'Rodzaj cen ""%PricesKind%"" w tabeli Wiersze pozycji został wypełniony.';
							|tr = 'Ürünler tablosundaki ""%PricesKind%"" fiyat türü dolduruldu.'"), "%PricesKind%", PricesKind),
			PictureLib.Information32);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInThePriceViewOfTheSelectedLinesPriceGroups(Command)
	
	If Object.PriceGroups.Count() = 0 Then
		
		ShowMessageBox(Undefined, NStr("vi = 'Trong chứng từ chưa điền danh sách ""Nhóm giá"". Không thể điền dạng giá';
										|ru = 'В документе не заполнен список ""Ценовые группы"". Вид цен не может быть заполнен';
										|en = 'The ""Price groups"" list in the document is not filled in. Cannot fill in price type'; fa = 'The ""Price groups"" list in the document is not filled in. Cannot fill in price type';
										|it = 'Nel documento non è compilato l''elenco ""Gruppi dei prezzi"". Il tipo dei prezzi non può essere compilato';
										|pl = 'W dokumencie nie jest wypełniona lista ""Grupy cenowe"". Rodzaj cen nie może być wypełniony';
										|tr = '""Fiyat Grubu"" listedi belgede doldurulmadı. Fiyat türü doldurulamaz'"));
		Return;
		
	EndIf;
	
	PriceSelectionOptions = EnterprisePricesFillingClient.NewFillOptionsSelectPriceType();
	PriceSelectionOptions.CallbackDescription = 
		New CallbackDescription( "FillInThePriceViewOfTheSelectedLinesPriceGroupsCompletion", ThisObject);
	PriceSelectionOptions.PriceIncludesVAT = Object.PriceIncludesVAT;
	PriceSelectionOptions.UseWhileSellingToCustomers = True;
	EnterprisePricesFillingClient.ChooseTypeOfPrices(PriceSelectionOptions);
	
EndProcedure

&AtClient
Procedure FillInThePriceViewOfTheSelectedLinesPriceGroupsCompletion(PricesKind, AdditionalParameters) Export
	
	If ValueIsFilled(PricesKind) Then
		
		FillInThePriceViewOfTheSelectedLinesPriceGroupsServer(PricesKind);
		
		ShowUserNotification(
			NStr("vi = 'Dạng giá đã điền';
				|ru = 'Вид цен заполнен';
				|en = 'Price type is filled in'; fa = 'Price type is filled in';
				|it = 'Il tipo dei prezzi è compilato';
				|pl = 'Rodzaj cen został wypełniony';
				|tr = 'Fiyat türü dolduruldu'"),
			,
			StrReplace(NStr("vi = 'Dạng giá ""%PricesKind%"" trong bảng Nhóm giá đã điền.';
							|ru = 'Вид цен ""%PricesKind%"" в таблице Ценовые группы заполнен.';
							|en = 'The ""%PricesKind%"" price type in the Price groups table is filled in.'; fa = 'The ""%PricesKind%"" price type in the Price groups table is filled in.';
							|it = 'Il tipo dei prezzi ""%PricesKind%"" nella tabella Gruppi dei prezzi è compilato.';
							|pl = 'Rodzaj cen ""%PricesKind%"" w tabeli Grupy cen został wypełniony.';
							|tr = 'Fiyat Grubu tablosundaki ""%PricesKind%"" fiyat türü dolduruldu.'"),"%PricesKind%",PricesKind),
			PictureLib.Information32);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure

&AtClient
Procedure AddGoodsByPicking(Command)
	
	FormParameters = New Structure("UUID", UUID);
	AddressInTempStorage = Undefined;

	OpenForm("DataProcessor.GoodsSelectionByPicking.Form.Form", FormParameters, ThisForm,,,, New CallbackDescription("AddGoodsByPickingCompletion", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure AddGoodsByPickingCompletion(Result, AdditionalParameters) Export
    
    AddressInTempStorage = Result;
    If ValueIsFilled(AddressInTempStorage) Then
        AddProductsBySelectionOnServer(AddressInTempStorage);
    EndIf;

EndProcedure

&AtClient
Procedure TheLabelPaymentClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	Try
		LockFormDataForEdit();
	Except
		ShowMessageBox(Undefined, BriefErrorDescription(ErrorInfo()));
		Return;
	EndTry;
	
	FormParameters = New Structure();
	FormParameters.Insert("PaymentMethod",                  Object.PaymentMethod);
	FormParameters.Insert("ARAPObjectSettings",              ?(Not Object.ContractsAreUsed, Object.ARAPObjectSettings, Undefined));
	FormParameters.Insert("AvailableToExternalUsers", Object.AvailableToExternalUsers);
	FormParameters.Insert("Calendar",                    Object.Calendar);
	FormParameters.Insert("BusinessOperation",        Object.BusinessOperation);
	FormParameters.Insert("PackageDepositIsRequired",         Object.ReturnReusablePackage And Object.PackageDepositIsRequired);
	FormParameters.Insert("UUID",      UUID);
	FormParameters.Insert("AddressInTempStorage",    PutItInTemporaryStorageOnServer());
	PaymentParameters = Undefined;

	OpenForm("Catalog.TermsOfSale.Form.PaymentMethod", FormParameters, ThisForm,,,, New CallbackDescription("TheLabelPaymentClickCompletion", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure TheLabelPaymentClickCompletion(Result, AdditionalParameters) Export
    
    PaymentParameters = Result;
    
    If PaymentParameters <> Undefined Then
        
        Modified = True;
        Object.Approved  = False;
        Object.PaymentMethod = PaymentParameters.PaymentMethod;
        Object.Calendar   = PaymentParameters.Calendar;
        Object.PaymentScheduleSteps.Clear();
        If ValueIsFilled(PaymentParameters.AddressInTempStorage) Then
            FillInPaymentStagesFromTemporaryStorageServer(PaymentParameters.AddressInTempStorage);
        EndIf;
        TheLabelPayment = PaymentStepsClientServer.InscriptionStagesPaymentForAgreements(ThisForm);
        SetAvailabilityOfItemsByStatusServer();
        
    EndIf;

EndProcedure

&AtClient
Procedure CalculatePackageReturnDateAccordingToCalendarOnChange(Item)
	Object.CalculatePackageReturnDateAccordingToCalendar = Boolean(CalculatePackageReturnDateAccordingToCalendar);
	
	Items.ScheduleOfPackageReturn.Enabled = Object.CalculatePackageReturnDateAccordingToCalendar And Object.ReturnReusablePackage;
	Items.ScheduleOfPackageReturn.AutoMarkIncomplete = Object.CalculatePackageReturnDateAccordingToCalendar;
	
	If Object.CalculatePackageReturnDateAccordingToCalendar Then
		FillProductionCalendarOnServer();
	Else
		Object.ScheduleOfPackageReturn = PredefinedValue("Catalog.BusinessCalendars.EmptyRef");
	EndIf;
	
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
Procedure RefinementPercentagesOfDiscountsMarkupsViewNavigationLinkProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	TypeOfCall = "ClarificationOfPercentagesOfDiscountsMargins";
	AddressInStorage = PlaceRowsOfTablePartInStorage(TypeOfCall);
	AdditionalParameters = New Structure();
	ParametersStructure = New Structure("AddressInStorage, TypeOfCall, AdditionalParameters", AddressInStorage, TypeOfCall, AdditionalParameters);
	NotificationAfterClarification = New CallbackDescription("ConfiguringConstraintsEnd", ThisObject);
	
	OpenForm("CommonForm.SettingsFormOfPriceGroupsSpecification", ParametersStructure, ThisForm,,,, NotificationAfterClarification, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure ConfiguringConstraintsEnd(Result, AdditionalParameters) Export
	
	If Not Result = Undefined Then
		FillInConstraintsSettings(Result);
		
		Modified = True;
	EndIf;

EndProcedure


// Filling in the tab part of the group's price list
// 
// Parameters:
// 	Var_Parameters - Structure
&AtServer 
Procedure FillInConstraintsSettings(Var_Parameters)
	
	TypeOfCall = Var_Parameters.TypeOfCall;
	AdditionalParameters = Var_Parameters.AdditionalParameters;
	
	If AdditionalParameters.Count() Then
		FillPropertyValues(Object, AdditionalParameters);
	EndIf;
	
	TransmittedTable = GetFromTempStorage(Var_Parameters.AddressInStorage);	

	If TypeOfCall = "ClarificationOfPercentagesOfDiscountsMargins" Then
		 
		CurrentTable = Object.PriceGroups;
		ImportTabularSection(TransmittedTable, CurrentTable);
		
		UpdatePresentationClarificationPercentDiscountsMargins();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ImportTabularSection(TransmittedTable, CurrentTable)
	CurrentTable.Clear();
	CurrentTable.Load(TransmittedTable);
EndProcedure

&AtServer
Procedure UpdatePresentationClarificationPercentDiscountsMargins()
	
	If Object.PriceGroups.Count() = 0 Then
		ClarificationOfPercentagesOfDiscountsMarginsPresentation = New FormattedString(NStr("vi = 'Làm rõ % chiết khấu (phụ thu) tối đa theo nhóm giá';
																							|ru = 'Уточнить максимальные % скидок (наценок) по ценовым группам';
																							|en = 'Specify the maximum % of discounts (markups) by price groups'; fa = 'Specify the maximum % of discounts (markups) by price groups';
																							|it = 'Specificare le percentuali massime di sconto (maggiorazione) per gruppi di prezzo';
																							|pl = 'Uściślij maksymalny % rabatów (marż) wg grup cenowych';
																							|tr = 'Fiyat gruplarına göre maksimum % indirimleri (zamları) netleştir'"),,,,"Change");
	Else
		ClarificationOfPercentagesOfDiscountsMarginsPresentation = New FormattedString(NStr("vi = 'Có làm rõ % chiết khấu (phụ thu) tối đa theo nhóm giá';
																							|ru = 'Есть уточнения максимальных % скидок (наценок) по ценовым группам';
																							|en = 'There are maximum discounts (markups) % specifications by price groups'; fa = 'There are maximum discounts (markups) % specifications by price groups';
																							|it = 'Vi sono indicazioni di percentuali massime di sconto (maggiorazione) per gruppi di prezzo';
																							|pl = 'Są uściślenia maksymalnych % rabatów (marż) wg grup cenowych';
																							|tr = 'Fiyat gruplarına göre maksimum % indirim (zam) iyileştirmesi mevcut'"),,,,"Change");
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ValidityStartDate.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Frequent");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ValidityStartDate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("MarkIncomplete", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ValidityStartDate.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Frequent");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ValidityStartDate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("MarkIncomplete", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AgreementAmount.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Frequent");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DocumentAmount");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("MarkIncomplete", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AgreementAmount.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Frequent");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DocumentAmount");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("MarkIncomplete", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.NumberOfPeriods.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Frequent");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.NumberOfPeriods");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("MarkIncomplete", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.NumberOfPeriods.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Frequent");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.NumberOfPeriods");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("MarkIncomplete", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Period.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Frequent");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Period");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("MarkIncomplete", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Period.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Frequent");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Period");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("MarkIncomplete", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Organization.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.AvailableToExternalUsers");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Organization");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("MarkIncomplete", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Organization.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.AvailableToExternalUsers");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Organization");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("MarkIncomplete", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PricesKind.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.AvailableToExternalUsers");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.PricesKind");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("MarkIncomplete", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PricesKind.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.AvailableToExternalUsers");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.PricesKind");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("MarkIncomplete", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PaymentSchedule.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.AvailableToExternalUsers");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.PaymentSchedule");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("MarkIncomplete", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PaymentSchedule.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.AvailableToExternalUsers");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.PaymentSchedule");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("MarkIncomplete", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PlanProfile.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.AvailableToExternalUsers");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.PlanProfile");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("MarkIncomplete", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PlanProfile.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.AvailableToExternalUsers");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.PlanProfile");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("MarkIncomplete", True);

	//

	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisForm);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPrice.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.PriceKind");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("ReadOnly", True);

	//

	EnterprisePricesFillingServer.EstablishConditionalAppearanceOfPriceTypes(ThisForm);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPrice.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.PriceKind");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<Không sử dụng>';
													|ru = '<Не используется>';
													|en = '<Not used>'; fa = '<استفاده نمی‌شود>';
													|it = '<non viene utilizzato>';
													|pl = '<Nie używa się>';
													|tr = '<Kullanılmayan>'"));

	//

	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisForm);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPrice.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.PriceKind");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Price");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("MarkIncomplete", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPrice.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.PriceKind");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Price");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("MarkIncomplete", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PriceGroupsPricesKind.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.LimitDiscountAdjustments");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	
	DiscountsMarkupsServer.SetConditionalAppearanceOfDiscountSourceForm(ConditionalAppearance, Items);
	
EndProcedure

#Region OnChangeAttributes

&AtServer
Procedure WhenChangingPartnerServer()
	
	Terms = Object.Terms;
	
	CatalogObject = FormAttributeToValue("Object");
	CatalogObject.FillInDefaultSalesConditions();
	ValueToFormAttribute(CatalogObject, "Object");
	
	If Terms <> Object.Terms Then
		WhenChangingAgreementAtServer(False);
	EndIf;
	
EndProcedure

&AtServer
Procedure WhenChangingAgreementAtServer(FillIn_TermsOfSales = True)
	
	If FillIn_TermsOfSales Then
		CatalogObject = FormAttributeToValue("Object");
		CatalogObject.FillInTermsOfSalesUnderAgreement();
		If Object.Ref.IsEmpty() Then
			CopyingValue = Object.Terms;	
		Else
			CatalogObject.FillInDiscountsAndSurchargesByAgreement();
		EndIf;
		ValueToFormAttribute(CatalogObject, "Object");
	EndIf;
	
	CalculatePackageReturnDateAccordingToCalendar = Number(Object.CalculatePackageReturnDateAccordingToCalendar);
	ContractsAreUsed = Number(Object.ContractsAreUsed);
	
	SetVisibilityOfElementsByRegularityOfServer();
	SetVisibilityOfElementsByOperationServer();
	UpdateVisibilityOfManualDiscountRestrictionElements(ThisObject);
	UpdateAvailabilityOfReturnContainerItems(ThisObject);
	UpdateVisibilityOfPropertyTransferShift(ThisObject);
	
	If Not UseSeveralPriceTypes Then
		PriceListUsage = ?(ValueIsFilled(Object.PricesKind), 1, 0);
		SetAvailabilityOfPriceList();
	EndIf;
	
	FillInFeatureAttribute = New Structure("Products", "ItemVariantsAreUsed");
	ProductsServer.FillInServiceDetailsForProductInCollection(
		Object.Goods,
		New Structure("FillInFeatureAttribute", FillInFeatureAttribute));
	
	TheLabelPayment = PaymentStepsClientServer.InscriptionStagesPaymentForAgreements(ThisForm);
	ConfigureCounterpartyAgreementsAndSettlementElements();
	
EndProcedure

&AtServer
Procedure WhenChangingCurrencyServer(NewCurrency)

	OldCurrency = DocumentCurrency;
	
	DocumentDate               = ?(ValueIsFilled(Object.Date), Object.Date, CurrentSessionDate());
	StructureOfOldCurrencyRates = ProcessingOfExchangeRatesTM.GetCurrencyRate(OldCurrency, DocumentDate);
	StructureOfNewCurrencyRates  = ProcessingOfExchangeRatesTM.GetCurrencyRate(NewCurrency,  DocumentDate);
	
	PriceManagementSystem.ConvertAmountsToCurrencyProducts(
		Object,
		OldCurrency,
		NewCurrency,
		StructureOfOldCurrencyRates,
		StructureOfNewCurrencyRates,
		False);
	
EndProcedure

&AtServer
Procedure WhenRegularityChangesServer()

	If Object.Frequent Then
		
		Object.Period             = Metadata.Catalogs.TermsOfSale.Attributes.Period.FillValue;
		Object.NumberOfPeriods = Metadata.Catalogs.TermsOfSale.Attributes.NumberOfPeriods.FillValue;
		Object.DocumentAmount     = Metadata.Catalogs.TermsOfSale.Attributes.DocumentAmount.FillValue;
		
	EndIf;
	
	SetVisibilityOfElementsByRegularityOfServer();
	
EndProcedure

&AtServer
Procedure WhenBusinessTransactionChangesServer()
	
	If Object.BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent
		Or Object.BusinessOperation = Enums.BusinessTransactions.TransferToStorageWithRightOfSale Then
		
		If ValueIsFilled(Object.PaymentSchedule) Then
			
			Query = New Query;
			Query.Text =
			"SELECT
			|	PaymentSchedules.OnlyCreditSteps AS OnlyCreditSteps
			|FROM
			|	Catalog.PaymentSchedules AS PaymentSchedules
			|WHERE
			|	PaymentSchedules.Ref = &PaymentSchedule";
			
			Query.SetParameter("PaymentSchedule", Object.PaymentSchedule);
			
			QueryResult = Query.Execute();
			
			Selection = QueryResult.Select();
			Selection.Next();
			
			If Not Selection.OnlyCreditSteps Then
				Object.PaymentSchedule = Catalogs.PaymentSchedules.EmptyRef();
			EndIf;
			
		EndIf;
		
		ArrayOfRowsToDelete_1 = New Array;
		
		For Each PaymentLine_ In Object.PaymentScheduleSteps Do
			If PaymentLine_.PaymentOption <> Enums.CustomerPaymentControlOptions.CreditAfterShipment 
				And PaymentLine_.PaymentOption <> Enums.CustomerPaymentControlOptions.CreditPlanned Then
				ArrayOfRowsToDelete_1.Add(PaymentLine_);
			EndIf;
		EndDo;
		
		For Each RowToDelete In ArrayOfRowsToDelete_1 Do
			Object.PaymentScheduleSteps.Delete(RowToDelete);
		EndDo;
		
		NumberOfStages = Object.PaymentScheduleSteps.Count();
		
		If NumberOfStages =1 Then
			Object.PaymentScheduleSteps[0].PaymentPercentage = 100;
		ElsIf NumberOfStages = 0
			And Not ValueIsFilled(Object.PaymentSchedule)
			And GetFunctionalOption("UseSimplifiedPaymentSchemeInSales") Then
			
			StageString_ = Object.PaymentScheduleSteps.Add();
			StageString_.PaymentOption  = Enums.CustomerPaymentControlOptions.CreditAfterShipment;
			StageString_.CalculateFrom  = Enums.PaymentDateCalculationOptions.FromShipmentDate;
			StageString_.PaymentPercentage = 100;
			
		EndIf;
		
		If Object.BusinessOperation = Enums.BusinessTransactions.TransferToStorageWithRightOfSale Then
			Object.AvailableToExternalUsers = False;
			
			ContractsAreUsed        = 1;
			Object.ContractsAreUsed = True;
			
		EndIf;
		
		Object.PackageDepositIsRequired     = False;
		Object.LimitDiscountAdjustments = False;
		
		If Object.BusinessOperation = Enums.BusinessTransactions.TransferToStorageWithRightOfSale
			And Object.ReturnReusablePackage Then
			Object.ReturnReusablePackage = False;
			UpdateAvailabilityOfReturnContainerItems(ThisObject);
		EndIf;

		Object.ARAPCurrency     = Object.Currency;
		
		Object.PercentRateOfManualDiscount  = Metadata.Catalogs.TermsOfSale.Attributes.PercentRateOfManualDiscount.FillValue;
		Object.MaximumPercentageForManualMarkup = Metadata.Catalogs.TermsOfSale.Attributes.MaximumPercentageForManualMarkup.FillValue;
		
		TheLabelPayment = PaymentStepsClientServer.InscriptionStagesPaymentForAgreements(ThisForm);
		
		Object.SaleWithDeferredTransferOfTitleIsAllowed = False;
		
		FillInPaymentInCurrencyOfFinancialAccountingGroup(Object.Organization,
													Object.ARAPCurrency,
													Object.ForeignCurrencyTransaction,
													Object.FinancialAccountingGroup,
													Object.ContractsAreUsed,
													Object.BusinessOperation);
		
	EndIf;
	
	If Object.BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent Then
		
		If OnlyConsignmentSales25 Or Not SelectConsignmentSalesVersion Then
			Object.ConsignmentSales25 = True;
		EndIf;
		
		If Object.ConsignmentSales25 Then
			Object.AvailableToExternalUsers = False;
			ContractsAreUsed = 1;
			Object.ContractsAreUsed = True;
			
			Object.PricesKind = Undefined;
			RefreshUseGeneralPriceViewCheckbox_();
			AdjustVisibilityAvailabilityOfGeneralPriceViewSettings(ThisObject);
			
			If ValueIsFilled(Object.SpecialPriceType) Then
				DisableIndividualPriceViewServer();
			EndIf;
			UpdateUseCustomPriceViewCheckbox();
			AdjustVisibilityAvailabilityOfIndividualPriceViewSettings(ThisObject);
		EndIf;
		
		If Object.ConsignmentSales25 
			 And Object.ReturnReusablePackage Then
			Object.ReturnReusablePackage = False;
			Object.PackageDepositIsRequired         = False;
			
			UpdateAvailabilityOfReturnContainerItems(ThisForm);
		EndIf;
		
	Else
		Object.ConsignmentSales25 = False;
	EndIf;
	
	If Object.BusinessOperation <> Enums.BusinessTransactions.TransferToCommissionAgent Then
		Object.CommissionFeeCalculationMethod = Metadata.Catalogs.TermsOfSale.Attributes.CommissionFeeCalculationMethod.FillValue;
		Object.RemunerationPercentage       = Metadata.Catalogs.TermsOfSale.Attributes.RemunerationPercentage.FillValue;
		Object.KeepCommissionFee      = Metadata.Catalogs.TermsOfSale.Attributes.KeepCommissionFee.FillValue;
	EndIf;
	
	If Object.BusinessOperation = Enums.BusinessTransactions.DeliveryForPrincipal Then
		Object.EnableAssigmentSupplyForOrders = True;
		ContractsAreUsed = True;
		Object.ContractsAreUsed = True;
	EndIf;
	
	If Object.BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent
		Or Object.ConsignmentSales25 Then
		NewLink = New ChoiceParameterLink("Filter.ConsignmentSales25", "Object.ConsignmentSales25");
		ArrayOfSelectParameterRelationships_ = New Array();
		ArrayOfSelectParameterRelationships_.Add(NewLink);
		Items.Terms.ChoiceParameterLinks = New FixedArray(ArrayOfSelectParameterRelationships_);
	Else
		Items.Terms.ChoiceParameterLinks = New FixedArray(New Array());
	EndIf;
	
	If Object.BusinessOperation <> Enums.BusinessTransactions.SaleToCustomer Then
		Object.DeadlineOfTransferOfTitleToGoods = 0;
	EndIf;
	
	FillInCalculationProcedure();
	SetVisibilityOfElementsByOperationServer();
	ConfigureCounterpartyAgreementsAndSettlementElements();
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure ContractsAreUsedOnChangeServer()
	
	If Not Object.ContractsAreUsed Then
		
		Object.ARAPCurrency = Object.Currency;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure UseGeneralViewOfPriceWhenChangingOnClient()

	If Not UseTheGeneralViewOfThePrice Then
		
		Object.PricesKind = PredefinedValue("Catalog.TypesOfPrices.EmptyRef");
		
	EndIf;
		
EndProcedure

&AtClient
Procedure UseIndividualViewOfPriceWhenChangingOnClient()

	If UseAnIndividualViewOfThePrice Then
	
		If Not ValueIsFilled(Object.Ref) Then
			
			Return;
			
		EndIf;

		ShutdownResult = FindIndividualViewOfPrices();
	
	Else
		
		If Object.SpecialPriceType.IsEmpty() Then
			
			Return;
			
		EndIf;
		
		ShutdownResult = DisableIndividualPriceViewServer();
		
		If Not ShutdownResult.Result Then
			
			UseAnIndividualViewOfThePrice = True;
			
			ClearMessages();
			CommonClient.MessageToUser(
				StrTemplate(NStr("vi = 'Đã xảy ra lỗi khi vô hiệu hóa bảng giá riêng %1';
								|ru = 'Возникла ошибка при отключении индивидуального прайс листа %1';
								|en = 'An error occurred while disabling the individual price list %1'; fa = 'An error occurred while disabling the individual price list %1';
								|it = 'Возникла ошибка при отключении индивидуального прайс листа %1';
								|pl = 'An error occurred while disabling the individual price list %1';
								|tr = 'Özelleştirilmiş %1 fiyat listesi devre dışı bırakılırken hata oluştu'"), ShutdownResult.ErrorDescription),
				Object.Ref,
				);
			
		EndIf;
		
	EndIf;
		
EndProcedure

&AtServer
Function DisableIndividualPriceViewServer()
	
	ShutdownResult = Catalogs.TypesOfPrices.DisableIndividualPriceView(Object.SpecialPriceType);

	If ShutdownResult.Result Then
		
		Object.SpecialPriceType = Catalogs.TypesOfPrices.EmptyRef();
		UpdateIndividualPriceViewPresentation();
		
	EndIf;
		
	Return ShutdownResult;
	
EndFunction

&AtServer
Function FindIndividualViewOfPrices()
	
	SearchResult = Catalogs.TypesOfPrices.FindIndividualViewOfPrices(Object.Ref);
	
	If SearchResult.Result Then
		Object.SpecialPriceType = SearchResult.Ref;
		UpdateIndividualPriceViewPresentation();
	EndIf;
			
	Return SearchResult;
	
EndFunction

#EndRegion

#Region Other

&AtServer
Procedure FillOperationSelectionList()
	
	If Not GetFormFunctionalOption("UseSalesCommission") Then
		
		ListItem = Items.BusinessOperation.ChoiceList.FindByValue(Enums.BusinessTransactions.TransferToCommissionAgent);
		If ListItem <> Undefined Then
			Items.BusinessOperation.ChoiceList.Delete(ListItem);
		EndIf;
		
	EndIf;
	
	UseTransferForSafekeeping = GetFormFunctionalOption(
		"UseTransferToCustodyWithRightOfSale");
	
	If Not UseTransferForSafekeeping Then
		
		ListItem = Items.BusinessOperation.ChoiceList.FindByValue(Enums.BusinessTransactions.TransferToStorageWithRightOfSale);
		If ListItem <> Undefined Then
			Items.BusinessOperation.ChoiceList.Delete(ListItem);
		EndIf;
		
	EndIf;
	
	If Not ProvideAgentServicesOnPurchaseToPrincipals Then
		ListItem = Items.BusinessOperation.ChoiceList.FindByValue(
			Enums.BusinessTransactions.DeliveryForPrincipal);

		If ListItem <> Undefined Then
			Items.BusinessOperation.ChoiceList.Delete(ListItem);
		EndIf;	
	EndIf;
	
	OnlyOperation = Items.BusinessOperation.ChoiceList.Count() = 1;
	TMCommonUseClientServer.SetFormItemProperty(
		Items,
		"BusinessOperation",
		"ReadOnly",
		OnlyOperation And ValueIsFilled(Object.BusinessOperation));
	
EndProcedure

&AtServer
Procedure SetVisibilityOfBookmarks()
	
	Items.PageClarificationByPriceGroups.Visible 					= Not UsePriceManagementSystem25;
	Items.ProductClarificationPage.Visible 							= Not UsePriceManagementSystem25;
	Items.GroupClarificationPercentagesOfDiscountsMarkupsByPriceGroups.Visible = UsePriceManagementSystem25;
	
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateAvailabilityOfSalesPlansItems(Form)
	
	FormItems = Form.Items;
	
	FormItems.PlanProfile.Enabled = ValueIsFilled(Form.Object.PlanningScenario);
	
	FormItems.PagesPurchasePlans.CurrentPage = FormItems.PagePurchasePlansVisible;
	
EndProcedure

&AtClient 
Procedure UpdateAvailabilityOfGeneralPriceView()
	
	UseTheGeneralViewOfThePrice = ValueIsFilled(Object.PricesKind) Or Object.AvailableToExternalUsers;

	AdjustVisibilityAvailabilityOfGeneralPriceViewSettings(ThisForm);

EndProcedure	

&AtServer
Procedure OnReadCreateAtServer()
	
	DocumentCurrency = Object.Currency;
	DocumentStatus = Object.Status;
	CalculatePackageReturnDateAccordingToCalendar = Number(Object.CalculatePackageReturnDateAccordingToCalendar);
	SplitGoodsIssueNotesByReferencesNumber = Number(Object.SplitGoodsIssueNotesByReferences);
	
	UseSalesOrders       = GetFunctionalOption("UseSalesOrders");
	ToUseTermsOfSales = GetFunctionalOption("ToUseTermsOfSales");
	UseSeveralPriceTypes    = GetFunctionalOption("UseSeveralPriceTypes");
	UseDiscountsMarkups        = AccessRight("Read", Metadata.Catalogs.DiscountsMarkups);
	VisibilityOfPaymentStages            = Not GetFunctionalOption("UsePaymentSchedules");
	UseCustomerContracts   = GetFunctionalOption("UseCustomerContracts");
	OnlyConsignmentSales25      = GetFunctionalOption("OnlyConsignmentSales25");
	SelectConsignmentSalesVersion = GetFunctionalOption("SelectConsignmentSalesVersion")
	                                   Or (ValueIsFilled(Object.Ref) And Not Object.ConsignmentSales25);
	
	Items.TheLabelPayment.Visible           = VisibilityOfPaymentStages;
	Items.PaymentSchedule.Visible            = Not VisibilityOfPaymentStages;
	Items.GroupGeneralViewOfThePrice.Visible      = UseSeveralPriceTypes;
	Items.GroupIndividualTypeOfPrice.Visible= UseSeveralPriceTypes;
	Items.PriceListUsage.Visible = Not UseSeveralPriceTypes;
	Items.GroupDiscountsMarkups.Visible     = UseDiscountsMarkups;
	Items.SetTheDiscountStatus.Visible  = AccessRight("Update", Metadata.InformationRegisters.ValidityOfDiscountsMarkups);
	Items.CommissionScheme.Visible      = Not OnlyConsignmentSales25 And UseCustomerContracts And SelectConsignmentSalesVersion;
	
	SetVisibilityOfElementsByRegularityOfServer();
	SetVisibilityOfElementsByOperationServer();
	SetAvailabilityOfItemsByStatusServer();
	SetVisibilityOfCommands();
	
	ConfigureCommissionSchemeSelectionList();
	SetUpSelectionListToSplitSpendingOrdersByOrders();
	
	FillInFeatureAttribute = New Structure("Products", "ItemVariantsAreUsed");
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods,
		New Structure("FillInFeatureAttribute", FillInFeatureAttribute));
	
	ContractsAreUsed = Number(Object.ContractsAreUsed);
	TheLabelPayment = PaymentStepsClientServer.InscriptionStagesPaymentForAgreements(ThisForm);
	
	If Not UseSeveralPriceTypes Then
		PriceTypePriceList         = Catalogs.TypesOfPrices.DefaultPriceType(Undefined);
		PriceListUsage = ?(ValueIsFilled(Object.PricesKind), 1, 0);
		
		SetAvailabilityOfPriceList();
	EndIf;
	
	ConfigureCounterpartyAgreementsAndSettlementElements();
	
	UpdateAvailabilityOfReturnContainerItems(ThisForm);
	UpdateAvailabilityOfSalesPlansItems(ThisForm);
	
	WarehouseWhenChangedOnServer();
	SetFormHeader();
	
	UpdateDeliverySchedulingSelectionList();
	
EndProcedure

&AtServer
Procedure SetAvailabilityOfItemsByStatusServer()
	
	ItemArray = New Array;
	
	// Header Controls
	ItemArray.Add("Date");
	ItemArray.Add("Number");
	ItemArray.Add("Partner");
	ItemArray.Add("PartnersSegment");
	ItemArray.Add("Terms");
	ItemArray.Add("Frequent");
	ItemArray.Add("Period");
	ItemArray.Add("NumberOfPeriods");
	ItemArray.Add("AgreementAmount");
	ItemArray.Add("ValidityStartDate");
	ItemArray.Add("ValidityEndDate");
	ItemArray.Add("Counterparty");
	ItemArray.Add("Organization");
	ItemArray.Add("Currency");
	ItemArray.Add("PriceIncludesVAT");
	ItemArray.Add("PricesKind");
	ItemArray.Add("PaymentSchedule");
	ItemArray.Add("ForeignCurrencyTransaction");
	ItemArray.Add("Warehouse");
	ItemArray.Add("DeliveryPeriodDays");
	ItemArray.Add("ProductSegment");
	ItemArray.Add("BusinessOperation");
	ItemArray.Add("PercentRateOfManualDiscount");
	ItemArray.Add("MaximumPercentageForManualMarkup");
	ItemArray.Add("LimitDiscountAdjustments");
	ItemArray.Add("PriceGroups");
	ItemArray.Add("Goods");
	ItemArray.Add("AvailableToExternalUsers");
	ItemArray.Add("ContractsAreUsed");
	ItemArray.Add("ARAPObjectSettings");
	ItemArray.Add("UsedInSalesRepresentativesWork");
	ItemArray.Add("ReturnReusablePackage");
	ItemArray.Add("ReusablePackageReturnCycleLength");
	ItemArray.Add("CalculatePackageReturnDateAccordingToCalendar");
	ItemArray.Add("PackageDepositIsRequired");
	
	ItemArray.Add("SetDateInterval");
	ItemArray.Add("PriceGroupsFillInThePriceViewOfTheSelectedLinesPriceGroups");
	ItemArray.Add("GoodsPopulateAPriceTypeOfTheSelectedLinesGoods");
	ItemArray.Add("GoodsAddGoodsByPicking");
	
	TMCommonUse.SetSubscriptionForFormElementChangeEvents(ThisObject, ItemArray);
	
EndProcedure

&AtServer
Procedure SetAvailabilityOfPriceList()
	
	PriceListVATAttribute = Common.ObjectAttributeValue(PriceTypePriceList, "PriceIncludesVAT");
	Items.PriceListUsage.Enabled = (PriceListVATAttribute = Object.PriceIncludesVAT);
	
EndProcedure

&AtServer
Procedure SetVisibilityOfElementsByRegularityOfServer()
	
	ItemArray = New Array();
	ItemArray.Add("Period");
	ItemArray.Add("NumberOfPeriods");
	ItemArray.Add("DescriptionOfRegularConditions");
	ItemArray.Add("AgreementAmount");
	ItemArray.Add("AgreementAmountCurrency");

	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Visible", Object.Frequent);
	
	If Object.Frequent Then
		DescriptionOfRegularConditions = DescriptionOfRegularConditions(Object.NumberOfPeriods, Object.Period, Object.DocumentAmount, DocumentCurrency);
	Else
		DescriptionOfRegularConditions = "";
	EndIf;
	
EndProcedure

&AtServer
Procedure SetVisibilityOfElementsByOperationServer()
	
	Var ArrayOfAllProps;
	Var ArrayOfOperationDetails;
	
	Catalogs.TermsOfSale.FillInNamesOfBusinessTransactionDetails(
		Object.BusinessOperation,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
	
	CashServer.SetVisibilityOfElementsByArray(
		Items,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
	
	ParametersArray = New Array;
	If Object.BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent
		Or Object.BusinessOperation = Enums.BusinessTransactions.TransferToStorageWithRightOfSale Then
		ParametersArray.Add(New ChoiceParameter("Filter.OnlyCreditSteps", True));
	EndIf;
	Items.PaymentSchedule.ChoiceParameters = New FixedArray(ParametersArray);
	
	ItemArray = New Array;
	ItemArray.Add("CommissionFeeCalculationMethod");
	ItemArray.Add("PercentageReward");
	ItemArray.Add("KeepCommissionFee");
	
	If Not OnlyConsignmentSales25 And GetFunctionalOption("UseCustomerContracts")
		And SelectConsignmentSalesVersion Then
		ItemArray.Add("CommissionScheme");
	EndIf;
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items,
									ItemArray,
									"Visible",
									Object.BusinessOperation = TransferTransferToCommission());
	
	TMCommonUseClientServer.SetPropertyOfFormElements(
		Items,
		"DescriptionOfCommissionCalculationForCommissionAgentSReport",
		"Visible",
		Object.ConsignmentSales25
			And Object.BusinessOperation = TransferTransferToCommission());
	
	TMCommonUseClientServer.SetPropertyOfFormElements(
		Items,
		"GroupPriceTypePriceListUsage",
		"Visible",
		Not (Object.ConsignmentSales25
			And Object.BusinessOperation = TransferTransferToCommission()));
		
	Items.PriceIncludesVAT.WarningOnEditRepresentation = ?( Object.ConsignmentSales25
			And Object.BusinessOperation = TransferTransferToCommission(),
			WarningOnEditRepresentation.DontShow, WarningOnEditRepresentation.Show);
		
	TMCommonUseClientServer.SetPropertyOfFormElements(
		Items,
		"AvailableToExternalUsers",
		"Visible",
		Object.BusinessOperation <> Enums.BusinessTransactions.TransferToStorageWithRightOfSale);
	
	TMCommonUseClientServer.SetFormItemProperty(
		Items,
		"SaleWithDeferredTransferOfTitleIsAllowed",
		"Visible",
		Object.BusinessOperation = Enums.BusinessTransactions.SaleToCustomer
		Or (Object.BusinessOperation = TransferTransferToCommission() And Object.ConsignmentSales25));
	
	If UseDiscountsMarkups Then
		TMCommonUseClientServer.SetPropertyOfFormElements(
			Items,
			"GroupDiscountsMarkups",
			"Visible",
			Object.BusinessOperation <> TransferTransferToCommission()
			And Object.BusinessOperation <> Enums.BusinessTransactions.TransferToStorageWithRightOfSale);
	EndIf;
	
	If Object.BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent Then
		CommissionFeeCalculationMethodOnChangeServer();
	EndIf;
	
	ProductsServer.SetProductSelectionParameters(Object.BusinessOperation, Items.GoodsProducts, True);
	
	UpdateAvailabilityOfSalesPlansItems(ThisObject);
	UpdateVisibilityOfManualDiscountRestrictionElements(ThisObject);
	UpdateVisibilityOfPropertyTransferShift(ThisObject);
	
	Items.ReturnReusablePackage.Enabled = (Not Object.BusinessOperation = Enums.BusinessTransactions.DeliveryForPrincipal)
		And Not (Object.BusinessOperation = TransferTransferToCommission() And Object.ConsignmentSales25)
		And Not (Object.BusinessOperation = TransferTransferForStorage());
	
	SetPropertiesOfOutdatedCommissionUsageComment();
	
EndProcedure

&AtServer
Procedure SetVisibilityOfCommands()
	
	ItemArray = New Array();
	ItemArray.Add("FormCopy");
	ItemArray.Add("FormDelete");
	ItemArray.Add("FormSetDeletionMark");
	ItemArray.Add("FormButtonsGroup");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Visible", GetFunctionalOption("ToUseTermsOfSales"));
	
EndProcedure

&AtServer
Procedure SetAvailabilityOfCommandsForExternalUser()
	
	ItemArray = New Array();
	ItemArray.Add("PriceGroupsFillInThePriceViewOfTheSelectedLinesPriceGroups");
	ItemArray.Add("GoodsPopulateAPriceTypeOfTheSelectedLinesGoods");
	ItemArray.Add("SetDateInterval");
	
	CommandsAvailability = AccessRight("Update", Metadata.Catalogs.TermsOfSale);
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Visible", CommandsAvailability);
	
EndProcedure

&AtServer
Procedure PopulateAPriceTypeOfTheSelectedLinesGoodsServer(PricesKind)

	For Each CurrentRow In Items.Goods.SelectedRows Do
		
		TableRow = Object.Goods.FindByID(CurrentRow);
		
		If TableRow = Undefined Then
			Continue;
		EndIf;
		
		TableRow.PriceKind = PricesKind;
		If TableRow.Price <> 0 Then
			TableRow.Price = 0;
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisForm);
	
EndProcedure

&AtServer
Procedure AddProductsBySelectionOnServer(AddressInTempStorage)
	
	GoodsTable = GetFromTempStorage(AddressInTempStorage);
	
	For Each CurRow In GoodsTable Do
		
		FilterParameters = New Structure;
		FilterParameters.Insert("Products", CurRow.Products);
		FilterParameters.Insert("Characteristic", CurRow.Characteristic);
		FoundRows = Object.Goods.FindRows(FilterParameters); 
		
		If FoundRows.Count() = 0 Then
			
			NewRow = Object.Goods.Add();
			FillPropertyValues(NewRow, CurRow);
			
		EndIf;
		
	EndDo;
	FillInFeatureAttribute = New Structure("Products", "ItemVariantsAreUsed");
	ProductsServer.FillInServiceDetailsForProductInCollection(
		Object.Goods,
		New Structure("FillInFeatureAttribute", FillInFeatureAttribute));
	
EndProcedure

&AtServer
Procedure FillInThePriceViewOfTheSelectedLinesPriceGroupsServer(PricesKind)

	For Each CurrentRow In Items.PriceGroups.SelectedRows Do
		
		TableRow = Object.PriceGroups.FindByID(CurrentRow);
		
		If TableRow = Undefined Then
			Continue;
		EndIf;
		
		TableRow.PricesKind = PricesKind;
		
	EndDo;
	
EndProcedure

&AtServerNoContext
Procedure FillInFinancialAccountingGroup_(Organization, ARAPCurrency, BusinessOperation, FinancialAccountingGroup)
	
	FinancialAccountingGroup = Catalogs.FinancialAccountingGroupsOfARAP.GetDefaultFinancialAccountingGroup(Organization, ARAPCurrency, BusinessOperation);
	
EndProcedure

&AtClientAtServerNoContext
Function DescriptionOfRegularConditions(NumberOfPeriods, Period, DocumentAmount, DocumentCurrency)
	
	// Checking for the fullness of the details
	If NumberOfPeriods = 0 Or Period = PredefinedValue("Enum.Periodicity.EmptyRef") Then
		Return "";
	EndIf;
	
	MatchingPeriods = New Map;
	
	PresentationOfNumberOfPeriods = "";
	Remainder10              = NumberOfPeriods % 10;
	Remainder100             = NumberOfPeriods % 100;
	PeriodAsString                   = String(Period);
	
	MatchingPeriods.Insert("Day",      NStr("vi = 'mỗi ngày';
											|ru = 'каждый день';
											|en = 'every day'; fa = 'every day';
											|it = 'ogni giorno';
											|pl = 'codziennie';
											|tr = 'her gün'"));
	MatchingPeriods.Insert("Week",    NStr("vi = 'mỗi tuần';
											|ru = 'каждую неделю';
											|en = 'every week'; fa = 'every week';
											|it = 'ogni settimana';
											|pl = 'co tydzień';
											|tr = 'her hafta'"));
	MatchingPeriods.Insert("TenDays",    NStr("vi = 'mỗi mười ngày';
												|ru = 'каждую декаду';
												|en = 'every ten-day period'; fa = 'every ten-day period';
												|it = 'ogni decade';
												|pl = 'co dziesięć dni';
												|tr = 'her on gün'"));
	MatchingPeriods.Insert("Month",     NStr("vi = 'mỗi tháng';
											|ru = 'каждый месяц';
											|en = 'every month'; fa = 'every month';
											|it = 'ogni mese';
											|pl = 'co miesiąc';
											|tr = 'her ay'"));
	MatchingPeriods.Insert("Quarter",   NStr("vi = 'mỗi quý';
											|ru = 'каждый квартал';
											|en = 'every quarter'; fa = 'every quarter';
											|it = 'ogni trimestre';
											|pl = 'co kwartał';
											|tr = 'her çeyrek'"));
	MatchingPeriods.Insert("HalfYear", NStr("vi = 'cứ 6 tháng';
											|ru = 'каждое полугодие';
											|en = 'each half-year'; fa = 'each half-year';
											|it = 'ogni semestre';
											|pl = 'co pół roku';
											|tr = 'her yarıyıl'"));
	MatchingPeriods.Insert("Year",       NStr("vi = 'mỗi năm';
												|ru = 'каждый год';
												|en = 'every year'; fa = 'every year';
												|it = 'ogni anno';
												|pl = 'corocznie';
												|tr = 'her yıl'"));
	
	If Remainder10 = 1 
		And NumberOfPeriods <> 11 
		And Remainder100 <> 11 Then
		
		PresentationOfNumberOfPeriods = String(NumberOfPeriods) + " " + NStr("vi = 'kỳ.';
																			|ru = 'периода.';
																			|en = 'period.'; fa = 'period.';
																			|it = 'del periodo.';
																			|pl = 'okresu.';
																			|tr = 'dönemin.'");
		
	Else
		
		PresentationOfNumberOfPeriods = String(NumberOfPeriods) + " " + NStr("vi = 'kỳ.';
																			|ru = 'периодов.';
																			|en = 'periods.'; fa = 'periods.';
																			|it = 'dei periodi.';
																			|pl = 'okresów.';
																			|tr = 'dönem.'");
		
	EndIf;
	
	DescriptionOfRegularConditions = NStr("vi = 'Cần giao hàng %PeriodAsString% với số tiền là %DocumentAmount% %DocumentCurrency% trong %PresentationOfNumberOfPeriods%';
											|ru = 'Поставки товаров должны осуществляться %PeriodAsString% на сумму %DocumentAmount% %DocumentCurrency% в течение %PresentationOfNumberOfPeriods%';
											|en = 'Goods should be delivered %PeriodAsString% in the amount of %DocumentAmount% %DocumentCurrency% during %PresentationOfNumberOfPeriods%'; fa = 'Goods should be delivered %PeriodAsString% in the amount of %DocumentAmount% %DocumentCurrency% during %PresentationOfNumberOfPeriods%';
											|it = 'Le consegne delle merci devono effettuarsi %PeriodAsString% per la somma %DocumentAmount% %DocumentCurrency% per %PresentationOfNumberOfPeriods%';
											|pl = 'Dostawy towarów powinny być wykonywane %PeriodAsString% na kwotę %DocumentAmount%%DocumentCurrency% w przeciągu %PresentationOfNumberOfPeriods%';
											|tr = 'Ürünlerin teslimatı, %PresentationOfNumberOfPeriods% içindeki %PeriodAsString% kapsamında %DocumentAmount% %DocumentCurrency% tutarında yapılmalıdır'");
	DescriptionOfRegularConditions = StrReplace(DescriptionOfRegularConditions, "%PresentationOfNumberOfPeriods%", PresentationOfNumberOfPeriods);
	DescriptionOfRegularConditions = StrReplace(DescriptionOfRegularConditions, "%PeriodAsString%",                   MatchingPeriods.Get(PeriodAsString));
	DescriptionOfRegularConditions = StrReplace(DescriptionOfRegularConditions, "%DocumentAmount%",                  DocumentAmount);
	DescriptionOfRegularConditions = StrReplace(DescriptionOfRegularConditions, "%DocumentCurrency%",                 DocumentCurrency);
	
	Return DescriptionOfRegularConditions;
	
EndFunction

&AtClient
Procedure CalculatePeriodOfRegularAgreement()
	
	If Object.Frequent And ValueIsFilled (Object.Period) And
		ValueIsFilled (Object.NumberOfPeriods) Then
		
		If Not ValueIsFilled(Object.ValidityStartDate) And ValueIsFilled(Object.Date) Then
			Object.ValidityStartDate = Object.Date;
		EndIf;
		
		If ValueIsFilled(Object.ValidityStartDate) Then
		
			StartDateOfNearestPeriod  = TMCommonUseClientServer.CalculateStartDateOfNearestPeriod(Object.ValidityStartDate, Object.Period);
			Object.ValidityEndDate = TMCommonUseClientServer.CalculatePeriodEndDate(StartDateOfNearestPeriod, Object.Period, Object.NumberOfPeriods);
			
		EndIf;
			
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateVisibilityOfManualDiscountRestrictionElements(Form)
	
	LimitDiscountAdjustments = Form.Object.LimitDiscountAdjustments
								And (Form.Object.BusinessOperation <> PredefinedValue("Enum.BusinessTransactions.TransferToCommissionAgent")
									Or Form.Object.BusinessOperation <> PredefinedValue("Enum.BusinessTransactions.TransferToStorageWithRightOfSale"));
	
	ItemArray = New Array();
	ItemArray.Add("PercentRateOfManualDiscount");
	ItemArray.Add("MaximumPercentageForManualMarkup");
	ItemArray.Add("PriceGroupsPercentRateOfManualDiscount");
	ItemArray.Add("PriceGroupsMaximumPercentageForManualMarkup");
	ItemArray.Add("ClarificationOfPercentagesOfDiscountsMarginsPresentation");

	TMCommonUseClientServer.SetPropertyOfFormElements(
		Form.Items,
		ItemArray,
		"Visible",
		LimitDiscountAdjustments);
	
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateVisibilityOfPropertyTransferShift(Form)
	
	MaybeShift = Form.Object.SaleWithDeferredTransferOfTitleIsAllowed
		And Form.Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.SaleToCustomer");
	
	Form.Items.ShiftingDateOfTransferOfOwnership.Visible  = MaybeShift;
	Form.Items.ShiftTransitionDateDecoration.Visible = MaybeShift;
	
EndProcedure

&AtServer
Function PutItInTemporaryStorageOnServer()
	
	Return PutToTempStorage(Object.PaymentScheduleSteps.Unload());
	
EndFunction

&AtServer
Procedure FillInPaymentStagesFromTemporaryStorageServer(AddressInTempStorage)
	
	PaymentSteps = GetFromTempStorage(AddressInTempStorage);
	
	For Each CurRow In PaymentSteps Do
		NewRow = Object.PaymentScheduleSteps.Add();
		FillPropertyValues(NewRow, CurRow);
	EndDo;
	
EndProcedure

&AtClient
Procedure ContactPersonOnChange(Item)
	
	If Object.ContactPerson.IsEmpty() Then
		Return;
	ElsIf Not Object.Partner.IsEmpty() Then
		Return;
	EndIf;
	
	PartnerChanged_ = False;
	ContactPersonOnChangeServer(PartnerChanged_);
	
	If Not PartnerChanged_ Then
		Return;
	EndIf;
	
	If Not ValueIsFilled (Object.Partner) Then
		
		Object.Terms = PredefinedValue("Catalog.TermsOfSale.EmptyRef");
		
	Else
		
		If ValueIsFilled(Object.Terms) Then
			SalesClient.NotifyEndOfFillingInDefaultSalesConditions();
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ContactPersonOnChangeServer(PartnerChanged_)
	
	OwnerOfContactPerson = Common.ObjectAttributeValue(Object.ContactPerson, "Owner");
	If OwnerOfContactPerson <> Object.Partner Then
		Object.Partner = OwnerOfContactPerson;
		WhenChangingPartnerServer();
		PartnerChanged_ = True;
	EndIf;
	
EndProcedure

&AtServer
Procedure ConfigureCounterpartyAgreementsAndSettlementElements()
	
	UseMultipleCurrencies = GetFunctionalOption("UseMultipleCurrencies");
	TextContractsOfCounterpartiesAreUsed = NStr("vi = 'Cần chỉ ra hợp đồng, trình tự hạch toán được xác định trong hợp đồng';
												|ru = 'Требуется указание договора, порядок расчетов определяется в договоре';
												|en = 'Specify a contract, AR/AP accounting is determined in the contract'; fa = 'قرارداد را مشخص کنید؛ حسابداری دریافتنی/پرداختنی در قرارداد تعیین می‌شود';
												|it = 'È richiesta l''indicazione del contratto, modalità di regolamenti è determinata nel contratto';
												|pl = 'Obowiązkowo podaj nazwę umowy, sposób rozliczeń jest ustalany umową';
												|tr = 'Sözleşme göstergesi gereklidir, uzlaşma prosedürü sözleşmede tanımlanmıştır'");
	AvailabilityOfNonUseContracts = True;
	If Object.BusinessOperation = Enums.BusinessTransactions.TransferToStorageWithRightOfSale Then
		VisibilityOfCalculationOrder   = False;
		AvailabilityOfCalculationProcedure = False;
		AvailabilityOfNonUseContracts = False;
		TextContractsOfCounterpartiesAreUsed = NStr("vi = 'Khi chuyển sang lưu trữ, việc sử dụng hợp đồng là bắt buộc';
													|ru = 'При передаче на хранение использование договора является обязательным';
													|en = 'The contract is required for VMI fill-up'; fa = 'The contract is required for VMI fill-up';
													|it = 'При передаче на хранение использование договора является обязательным';
													|pl = 'The contract is required for VMI fill-up';
													|tr = 'Depolama için aktarırken sözleşmenin kullanılması zorunludur'");
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent
		And Not Object.ConsignmentSales25 Then
		VisibilityOfCalculationOrder   = False;
		AvailabilityOfCalculationProcedure = False;
		TextOfUseOfTransferToStorage = NStr("vi = 'Không sử dụng hợp đồng, trình tự hạch toán theo hóa đơn';
											|ru = 'Договоры не используются, порядок расчетов по накладным';
											|en = 'Contracts are not used, payment terms by invoices'; fa = 'Contracts are not used, payment terms by invoices';
											|it = 'Gli accordi non si utilizzano, l''ordine dei conti viene fatto secondo le bolle';
											|pl = 'Umowy nie są używane, procedura rozliczeń faktur';
											|tr = 'Sözleşmeler kullanılmıyor, irsaliye uzlaşma prosedürü'")
												+ ?(UseMultipleCurrencies, ":", "");
		
		TextContractsOfCounterpartiesAreNotUsed = ?(Object.BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent,
												NStr("vi = 'Không sử dụng hợp đồng, trình tự hạch toán theo bảng kê ký gửi';
													|ru = 'Договоры не используются, порядок расчетов по отчетам по комиссии';
													|en = 'Contracts are not used, payment terms by commission reports'; fa = 'Contracts are not used, payment terms by commission reports';
													|it = 'Gli accordi non si utilizzano, l''ordine dei conti viene fatto secondo i report sulla commissione';
													|pl = 'Umowy nie są używane, procedura rozliczeń dla raportów dotyczących komisu';
													|tr = 'Sözleşmeler kullanılmıyor, komisyon raporlarının karara bağlanması için uzlaşma prosedürü'"),
												TextOfUseOfTransferToStorage);
		
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent
		And Object.ConsignmentSales25 Then
		VisibilityOfCalculationOrder   = False;
		AvailabilityOfCalculationProcedure = False;
		AvailabilityOfNonUseContracts = False;
		TextOfObligationToUseContract = NStr("vi = 'Khi chuyển sang ký gửi %1, việc sử dụng hợp đồng là bắt buộc';
											|ru = 'При передаче на комиссию %1 использование договора является обязательным';
											|en = 'The contract is required %1 for consignment sales'; fa = 'The contract is required %1 for consignment sales';
											|it = 'При передаче на комиссию %1 использование договора является обязательным';
											|pl = 'The contract is required %1 for consignment sales';
											|tr = '%1 komisyonuna transfer sırasında sözleşmenin kullanılması zorunludur'");
		TextContractsOfCounterpartiesAreUsed = StringFunctionsClientServer.SubstituteParametersToString(TextOfObligationToUseContract,
			ConsignmentSalesServer.PostfixCommissionSchemes25());
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.DeliveryForPrincipal Then
		VisibilityOfCalculationOrder   = False;
		AvailabilityOfCalculationProcedure = False;
		AvailabilityOfNonUseContracts = False;
		TextContractsOfCounterpartiesAreUsed = NStr("vi = 'Khi giao hàng theo bên đặt ký gửi, việc sử dụng hợp đồng là bắt buộc';
													|ru = 'При поставке под принципала использование договора является обязательным';
													|en = 'The contract is required for procurement outsourcing'; fa = 'The contract is required for procurement outsourcing';
													|it = 'При поставке под принципала использование договора является обязательным';
													|pl = 'The contract is required for procurement outsourcing';
													|tr = 'Tedarik dış kaynak kullanımı kapsamında sözleşmenin kullanılması zorunludur'");
	ElsIf Not UseSalesOrders Then
		VisibilityOfCalculationOrder   = False;
		AvailabilityOfCalculationProcedure = False;
		TextContractsOfCounterpartiesAreNotUsed = NStr("vi = 'Không sử dụng hợp đồng, trình tự hạch toán theo hóa đơn';
														|ru = 'Договоры не используются, порядок расчетов по накладным';
														|en = 'Contracts are not used, payment terms by invoices'; fa = 'Contracts are not used, payment terms by invoices';
														|it = 'Gli accordi non si utilizzano, l''ordine dei conti viene fatto secondo le bolle';
														|pl = 'Umowy nie są używane, procedura rozliczeń faktur';
														|tr = 'Sözleşmeler kullanılmıyor, irsaliye uzlaşma prosedürü'");
	ElsIf Object.ContractsAreUsed Then
		VisibilityOfCalculationOrder   = True;
		AvailabilityOfCalculationProcedure = False;
		TextContractsOfCounterpartiesAreNotUsed = NStr("vi = 'Không sử dụng hợp đồng, trình tự hạch toán:';
														|ru = 'Договоры не используются, порядок расчетов:';
														|en = 'Contracts are not used, payment terms:'; fa = 'قراردادها استفاده نمی‌شوند، شرایط پرداخت:';
														|it = 'Contratti non si utilizzano, modalità di regolamenti:';
														|pl = 'Umowy nie dotyczą, sposób rozliczeń:';
														|tr = 'Sözleşmeler kullanılmıyor, uzlaşma prosedürü:'");
	Else
		VisibilityOfCalculationOrder   = True;
		AvailabilityOfCalculationProcedure = True;
		TextContractsOfCounterpartiesAreNotUsed = NStr("vi = 'Không sử dụng hợp đồng, trình tự hạch toán:';
														|ru = 'Договоры не используются, порядок расчетов:';
														|en = 'Contracts are not used, payment terms:'; fa = 'قراردادها استفاده نمی‌شوند، شرایط پرداخت:';
														|it = 'Contratti non si utilizzano, modalità di regolamenti:';
														|pl = 'Umowy nie dotyczą, sposób rozliczeń:';
														|tr = 'Sözleşmeler kullanılmıyor, uzlaşma prosedürü:'");
	EndIf;
	
	Items.IndentCalculationOrder.Visible = UseMultipleCurrencies
												Or VisibilityOfCalculationOrder;
	
	Items.ContractsAreUsed.ReadOnly   = Not AvailabilityOfNonUseContracts;
	Items.NotContractsAreUsed.Visible = AvailabilityOfNonUseContracts;
	
	Items.ARAPObjectSettings.Visible = VisibilityOfCalculationOrder;
	Items.ARAPObjectSettings.Enabled = AvailabilityOfCalculationProcedure;
	
	Items.ContractsAreUsed.ChoiceList.Clear();
	Items.ContractsAreUsed.ChoiceList.Add(1, TextContractsOfCounterpartiesAreUsed);
	
	Items.NotContractsAreUsed.ChoiceList.Clear();
	Items.NotContractsAreUsed.ChoiceList.Add(0, TextContractsOfCounterpartiesAreNotUsed);
	
	Items.ForeignCurrencyTransaction.Enabled        = Not Object.ContractsAreUsed;
	Items.ARAPCurrency.Enabled = Not Object.ContractsAreUsed
												And Not Object.BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent;
	
	Items.GroupPaymentProcedurePayment.Visible = AvailabilityOfNonUseContracts;
	
	If Object.ContractsAreUsed Then
		Items.FinancialAccountingGroup.Enabled = False;
		Items.FinancialAccountingGroup.InputHint = NStr("vi = '<đặt trong hợp đồng>';
														|ru = '<задается в договоре>';
														|en = '<to be specified in contract>'; fa = '<to be specified in contract>';
														|it = '<viene impostato nel contratto>';
														|pl = '<jest zadawane w umowie>';
														|tr = '<sözleşmede belirtilen>'");
		
		Items.CashFlowItem.Enabled = False;
		Items.CashFlowItem.InputHint = NStr("vi = '<đặt trong hợp đồng>';
											|ru = '<задается в договоре>';
											|en = '<to be specified in contract>'; fa = '<to be specified in contract>';
											|it = '<viene impostato nel contratto>';
											|pl = '<jest zadawane w umowie>';
											|tr = '<sözleşmede belirtilen>'");
		
		Items.LineOfBusiness.Enabled = False;
		Items.LineOfBusiness.InputHint = NStr("vi = '<đặt trong hợp đồng>';
												|ru = '<задается в договоре>';
												|en = '<to be specified in contract>'; fa = '<to be specified in contract>';
												|it = '<viene impostato nel contratto>';
												|pl = '<jest zadawane w umowie>';
												|tr = '<sözleşmede belirtilen>'");
	Else
		Items.FinancialAccountingGroup.Enabled = True;
		Items.FinancialAccountingGroup.InputHint = "";
		
		Items.CashFlowItem.Enabled = True;
		Items.CashFlowItem.InputHint = "";
		
		Items.LineOfBusiness.Enabled = True;
		Items.LineOfBusiness.InputHint = "";
	EndIf;

	If Object.ContractsAreUsed Then
		Object.ForeignCurrencyTransaction = ARAPAccountingServer.GetPaidInDefaultCurrency();
		Object.ARAPCurrency = Catalogs.Currencies.EmptyRef();
		Object.FinancialAccountingGroup = Catalogs.FinancialAccountingGroupsOfARAP.EmptyRef();
		Object.CashFlowItem = Catalogs.CashFlowReportItems.EmptyRef();
		Object.LineOfBusiness = Catalogs.LinesOfBusiness.EmptyRef();
	EndIf;
	
	DeliveryForPrincipal = Object.BusinessOperation = Enums.BusinessTransactions.DeliveryForPrincipal;
	Items.EnableAssigmentSupplyForOrders.Enabled = Not DeliveryForPrincipal;
	Items.AvailableToExternalUsers.Visible = ?(Object.BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent 
		And Object.ConsignmentSales25, False, True);
	
EndProcedure

&AtServer
Procedure FillInCalculationProcedure()
	
	If UseCustomerContracts And Object.ContractsAreUsed Then
		Object.ARAPObjectSettings = Enums.ARAPObjectSettings.EmptyRef();
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent
		Or Not UseSalesOrders Then
		Object.ARAPObjectSettings = Enums.ARAPObjectSettings.ByARAPDocuments;
	ElsIf Not ValueIsFilled(Object.ARAPObjectSettings) Then
		Object.ARAPObjectSettings = Enums.ARAPObjectSettings.ByOrders;
	EndIf;
	
	ConfigureCounterpartyAgreementsAndSettlementElements();
	
EndProcedure

&AtServer
Procedure FillProductionCalendarOnServer()
	
	CalendarSchedules.FillBusinessCalendarInForm(ThisForm, "Object.ScheduleOfPackageReturn");
	
EndProcedure

&AtServer
Procedure BuildDiscountMarkUpTree()
	
	DiscountsMarkupsServer.BuildDiscountMarkUpTreeInForm(
	                                            ThisObject,
	                                            ?(CopyingValue.IsEmpty(),Object.Ref, CopyingValue));
	InformationOnDiscountNumber = DiscountsMarkupsServer.InformationOnDiscountNumber(
	                                            ?(CopyingValue.IsEmpty(),Object.Ref, CopyingValue),
	                                            SliceDate);
	UpdateUsageOfDiscountsMarkups(ActivatedDiscountMarkup);
	
EndProcedure

&AtServer
Procedure SetVisibilityOfInputCommandsBasedOn()
	AttachableCommandsClientServer.UpdateCommands(ThisForm, Object);
EndProcedure

&AtServerNoContext
Procedure FillInPaymentInCurrencyOfFinancialAccountingGroup(Organization, Currency, ForeignCurrencyTransaction, FinancialAccountingGroup, ContractsAreUsed, BusinessOperation)
	
	If Not ContractsAreUsed Then
		ForeignCurrencyTransaction = ARAPAccountingServer.GetPaidInDefaultCurrency();
	EndIf;
	
	FillInFinancialAccountingGroup_(Organization, Currency, BusinessOperation, FinancialAccountingGroup);
	
EndProcedure


&AtServer
Procedure RefreshUseGeneralPriceViewCheckbox_()

	UseTheGeneralViewOfThePrice = ValueIsFilled(Object.PricesKind);
	
EndProcedure

&AtServer
Procedure UpdateUseCustomPriceViewCheckbox()

	UseAnIndividualViewOfThePrice = ValueIsFilled(Object.SpecialPriceType);
	
EndProcedure


&AtClientAtServerNoContext
Procedure AdjustVisibilityAvailabilityOfGeneralPriceViewSettings(Form)
	
	Form.Items.PricesKind.Enabled = (Form.UseTheGeneralViewOfThePrice And Not Form.Items.UseTheGeneralViewOfThePrice.ReadOnly);
	
EndProcedure

&AtClientAtServerNoContext
Procedure AdjustVisibilityAvailabilityOfIndividualPriceViewSettings(Form)
	
	Form.Items.SpecialPriceTypePresentation.Enabled	= (Form.UseAnIndividualViewOfThePrice 
												And Not Form.Items.UseAnIndividualViewOfThePrice.ReadOnly)
												And Form.ItIsAllowedToCreatePriceTypes;
	Form.Items.UseAnIndividualViewOfThePrice.Enabled = Form.ItIsAllowedToCreatePriceTypes;
	
EndProcedure

&AtServer
Function PlaceRowsOfTablePartInStorage(TypeOfCall)
	
	If TypeOfCall = "ClarificationOfPercentagesOfDiscountsMargins" Then
		 
		Table = Object.PriceGroups.Unload(, "PriceGroup, PercentRateOfManualDiscount, MaximumPercentageForManualMarkup");
		
	EndIf;
	
	Return PutToTempStorage(Table, ThisForm.UUID);

EndFunction

&AtServer
Procedure ConfigureCommissionSchemeSelectionList()
	
	ChoiceList = Items.CommissionScheme.ChoiceList;
	ChoiceList.Clear();
	ChoiceList.Add(False,   ConsignmentSalesServer.PostfixCommissionSchemes20());
	ChoiceList.Add(True, ConsignmentSalesServer.PostfixCommissionSchemes25());
	
EndProcedure

&AtClient
Procedure SetVisibilityOfPaymentInCurrency()
	Items.ForeignCurrencyTransaction.Visible = 
		Object.ARAPCurrency <> LocalAccountingCurrency
		Or Object.ForeignCurrencyTransaction;
EndProcedure

&AtServer
Procedure SetUpSelectionListToSplitSpendingOrdersByOrders()
	
	ChoiceList = Items.SplitGoodsIssueNotesByReferences.ChoiceList;
	ChoiceList.Clear();
	
	ChoiceList.Add(1, NStr("vi = 'theo đơn hàng và hóa đơn';
							|ru = 'с разбиением по заказам и накладным';
							|en = 'By orders and invoices'; fa = 'بر اساس سفارش‌ها و فاکتورها';
							|it = 'suddiviso per ordini e documenti di trasporto';
							|pl = 'z podziałem wg zamówień i faktur';
							|tr = '; siparişlere ve faturalara göre bölünmüş olarak'"));
	UsedDelivery25 = GoodsDeliveryClientServer.UsedDelivery25();
	If UsedDelivery25 Then
		
		ChoiceList.Add(0, NStr("vi = 'phân chia theo đối tác';
								|ru = 'с разбиением по партнерам';
								|en = 'broken down by partners'; fa = 'broken down by partners';
								|it = 'broken down by partners';
								|pl = 'broken down by partners';
								|tr = 'ortaklara göre bölerek'"));
		
	Else
		
		ChoiceList.Add(0, NStr("vi = 'gom nhóm theo bạn hàng và nhiệm vụ vận chuyển';
								|ru = 'с группировкой по партнерам и заданиям на перевозку';
								|en = 'By customers and itineraries'; fa = 'بر اساس مشتریان و مسیرهای سفر';
								|it = 'raggruppati per partner e ordini di trasporto';
								|pl = 'z grupowaniem wg partnerw i zadań transportowych';
								|tr = '; iş ortaklarına ve taşıma planına göre gruplandırmayla'"));
		
	EndIf;
	
EndProcedure

#EndRegion

#Region ControlOfInconsistentChanges

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure ControlOfNonConsistentChangesHandleEventOnChange(Item)
	If Item.Name = "Partner" Then
		PartnerOnChange(Item);
	ElsIf Item.Name = "Terms" Then
		TermsOnChange(Item);
	ElsIf Item.Name = "Frequent" Then
		FrequentOnChange(Item);
	ElsIf Item.Name = "Period" Then
		PeriodOnChange(Item);
	ElsIf Item.Name = "NumberOfPeriods" Then
		NumberOfPeriodsOnChange(Item);
	ElsIf Item.Name = "AgreementAmount" Then
		DocumentAmountOnChange(Item);
	ElsIf Item.Name = "ValidityStartDate" Then
		ValidityStartDateOnChange(Item);
	ElsIf Item.Name = "Currency" Then
		CurrencyOnChange(Item);
	ElsIf Item.Name = "PriceIncludesVAT" Then
		PriceIncludesVATOnChange(Item);
	ElsIf Item.Name = "ForeignCurrencyTransaction" Then
		ForeignCurrencyTransactionOnChange(Item);
	ElsIf Item.Name = "BusinessOperation" Then
		BusinessOperationOnChange(Item);
	ElsIf Item.Name = "LimitDiscountAdjustments" Then
		LimitDiscountAdjustmentsOnChange(Item);
	ElsIf Item.Name = "GoodsProducts" Then
		GoodsProductsOnChange(Item);
	ElsIf Item.Name = "GoodsPriceKind" Then
		GoodsPriceKindOnChange(Item);
	ElsIf Item.Name = "AvailableToExternalUsers" Then
		AvailableToExternalUsersOnChange(Item);
	ElsIf Item.Name = "ContractsAreUsed" Then
		ContractsAreUsedOnChange(Item);
	ElsIf Item.Name = "ReturnReusablePackage" Then
		ReturnReusablePackageOnChange(Item);
	ElsIf Item.Name = "CalculatePackageReturnDateAccordingToCalendar" Then
		CalculatePackageReturnDateAccordingToCalendarOnChange(Item);
	ElsIf Item.Name = "Warehouse" Then
		WarehouseOnChange(Item);
	ElsIf Item.Name = "SaleWithDeferredTransferOfTitleIsAllowed" Then
		SaleWithDeferredTransferOfTitleIsAllowedOnChange(Item);
	ElsIf Item.Name = "Organization" Then
		OrganizationOnChange(Item);
	Else
		TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisForm, Item);
	EndIf;
EndProcedure

// Parameters:
//	Command - FormCommand - 
&AtClient
Procedure ControlOfNonConsistentChangesHandleCommandEvent(Command)
	If Command.Name = "SetDateInterval" Then
		SetDateIntervalExecute(Command);
	ElsIf Command.Name = "FillInThePriceViewOfTheSelectedLinesPriceGroups" Then
		FillInThePriceViewOfTheSelectedLinesPriceGroups(Command);
	ElsIf Command.Name = "PopulateAPriceTypeOfTheSelectedLinesGoods" Then
		PopulateAPriceTypeOfTheSelectedLinesGoods(Command);
	ElsIf Command.Name = "AddGoodsByPicking" Then
		AddGoodsByPicking(Command);
	Else
		TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisForm, Command);
	EndIf;
EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure ControlOfNonConsistentChangesHandleEventBeforeStartingChange(Item, Cancel)
	TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisForm, Item);
EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure ControlOfNonConsistentChangesHandleEventBeforeDeletion(Item, Cancel)
	
	TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisForm, Item);
	
EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
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

&AtClientAtServerNoContext
Procedure UpdateAvailabilityOfReturnContainerItems(Form)
	
	ItemArray = New Array();
	ItemArray.Add("CalculatePackageReturnDateAccordingToCalendar");
	ItemArray.Add("NotCalculatePackageReturnDateAccordingToCalendar");
	ItemArray.Add("ReusablePackageReturnCycleLength");
	ItemArray.Add("PackageDepositIsRequired");
	ItemArray.Add("ScheduleOfPackageReturn");
	
	ReturnReusablePackage = Form.Object.ReturnReusablePackage;
	
	If Form.Object.BusinessOperation = TransferTransferToCommission()
	 	 And Form.Object.ConsignmentSales25 Then
		ReturnReusablePackage = False;
	EndIf;
	
	TMCommonUseClientServer.SetPropertyOfFormElements(
		Form.Items,
		ItemArray,
		"Enabled",
		ReturnReusablePackage);
	
	Form.Items.ScheduleOfPackageReturn.Enabled = Form.Object.CalculatePackageReturnDateAccordingToCalendar
								And Form.Object.ReturnReusablePackage;
	
EndProcedure

&AtServerNoContext
Function TransferTransferToCommission()
	
	Return Enums.BusinessTransactions.TransferToCommissionAgent;
	
EndFunction

&AtServerNoContext
Function TransferTransferForStorage()
	
	Return Enums.BusinessTransactions.TransferToStorageWithRightOfSale;
	
EndFunction

&AtClient
Procedure UpdatePresentationOfDiscountMarkUpUsage()
	
	CurrentData = Items.DiscountsMarkups.CurrentData;
	DiscountMarkup = ?(CurrentData = Undefined Or CurrentData.IsFolder, Undefined, CurrentData.Ref);
	
	If DiscountMarkup <> ActivatedDiscountMarkup Then
		UpdateUsageOfDiscountsMarkups(DiscountMarkup);
		ActivatedDiscountMarkup = ?(CurrentData = Undefined, Undefined, CurrentData.Ref);
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateUsageOfDiscountsMarkups(DiscountMarkup)
	
	UsingMarkUpDiscount = DiscountsMarkupsServer.UsingMarkUpDiscount(DiscountMarkup, SliceDate);
	DiscountsMarkupsServer.CreateInformationLabelUsingDiscountsMargins(InformationOnDiscountValidity,
	                                                                                UsingMarkUpDiscount,
	                                                                                "ConfigureDiscounts");
	
EndProcedure

&AtClient
Procedure UpdateDiscountTree()
	
	BuildDiscountMarkUpTree();
	DiscountsMarkupsClient.ExpandDiscountTreeRecursively(DiscountsMarkups, Items.DiscountsMarkups, ExpandedTreeNodes);
	DiscountsMarkupsClient.PositionOnValueInTree(ActivatedDiscountMarkup, DiscountsMarkups, Items.DiscountsMarkups, "Ref");
	
EndProcedure

&AtServer
Procedure SetFlagHeaderAvailableToExternalUsers()

	ExternalUsersAreUsed = GetFunctionalOption("UseExternalUsers");
	SharingWithSiteIsUsed        = SystemSettingsLocalization.UseExchangeWithSite();
	
	If ExternalUsersAreUsed And SharingWithSiteIsUsed Then
		Items.AvailableToExternalUsers.Title = NStr("vi = 'Cho phép đối với người sử dụng ngoài và để trao đổi với website';
													|ru = 'Доступно внешним пользователям и для обмена с сайтом';
													|en = 'Available to external users and to exchange with website'; fa = 'Available to external users and to exchange with website';
													|it = 'Disponibile per utenti esterni e per la condivisione con il sito';
													|pl = 'Dostępne dla użytkowników zewnętrznych i do wymiany ze stroną www';
													|tr = 'Harici kullanıcılar tarafından kullanılabilir ve web sitesiyle paylaşılabilir'");
	ElsIf SharingWithSiteIsUsed Then
		Items.AvailableToExternalUsers.Title = NStr("vi = 'Cho phép để trao đổi với Website';
													|ru = 'Доступно для обмена с сайтом';
													|en = 'Available for exchange with the site'; fa = 'Available for exchange with the site';
													|it = 'Disponibile per la condivisione con il sito';
													|pl = 'Dostępne do wymiany ze stroną www';
													|tr = 'Web sitesiyle paylaşılabilir'");
	EndIf;

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

#EndRegion

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

&AtClient
Procedure DiscountMarkupValidityHistory(Command)
	
	DiscountsMarkupsClient.OpenStatusChangeHistoryForm(ThisForm);
	
EndProcedure

&AtClient
Procedure SetStatusValid(Command)
	
	DiscountsMarkupsClient.OpenStatusSettingForm(
		ThisForm,
		PredefinedValue("Enum.DiscountValidityStatuses.Valid"),
		Object.Ref);
	
EndProcedure

&AtClient
Procedure SetTheStatusNotValid(Command)
	
	DiscountsMarkupsClient.OpenStatusSettingForm(
		ThisForm,
		PredefinedValue("Enum.DiscountValidityStatuses.NotValid"),
		Object.Ref);
	
EndProcedure

&AtClient
Procedure WarehouseOnChange(Item)
	WarehouseWhenChangedOnServer();
EndProcedure

&AtServer
Procedure WarehouseWhenChangedOnServer()
	
	BreakSpendingOrdersByOrdersVisibility = True;
	
	If Not GetFunctionalOption("UseWarehouseManagemantSystemForGoodsIssue") Then
		
		BreakSpendingOrdersByOrdersVisibility = False;
		
	ElsIf ValueIsFilled(Object.Warehouse) Then 
	
		Query = New Query; 
		Query.Text = 
		"SELECT ALLOWED
		|	Warehouses.Ref
		|FROM
		|	Catalog.Warehouses AS Warehouses
		|WHERE
		|	CASE
		|			WHEN CAST(&Warehouse AS Catalog.Warehouses).IsFolder
		|				THEN Warehouses.Ref IN HIERARCHY (&Warehouse)
		|			ELSE Warehouses.Ref = &Warehouse
		|		END
		|	AND Warehouses.UseWarehouseManagemantSystemForGoodsIssue
		|	AND Warehouses.StartDateOfWarehouseManagemantSystemForGoodsIssue <= &CurrentDate";
		
		Query.SetParameter("Warehouse", 			Object.Warehouse);
		Query.SetParameter("CurrentDate", 	CurrentSessionDate());
		
		// If the selected warehouse is not an order warehouse or there are no order warehouses in the warehouse group, 
		// i.e. the request is empty, then we will hide the grouping of expense orders.
		BreakSpendingOrdersByOrdersVisibility = Not Query.Execute().IsEmpty();
		
	EndIf;
	
	Items.SplitGoodsIssueNotesByReferences.Visible = BreakSpendingOrdersByOrdersVisibility;
	
	If Not BreakSpendingOrdersByOrdersVisibility Then 
		Object.SplitGoodsIssueNotesByReferences = False;
		SplitGoodsIssueNotesByReferencesNumber = 0;
	EndIf;
	
EndProcedure

&AtServer
Procedure SetFormHeader()
	
	// document title
	If Object.Standard_ Then
		
		If ValueIsFilled(Object.Number) And ValueIsFilled(Object.Date) And ToUseTermsOfSales Then
			TitleText = NStr("vi = 'Thỏa thuận chung về điều kiện bán hàng %Number% ngày %Date%';
							|ru = 'Типовое соглашение об условиях продаж %Number% от %Date%';
							|en = 'Standard terms of sale %Number% dated %Date%'; fa = 'Standard terms of sale %Number% dated %Date%';
							|it = 'Accordo tipico sulle condizioni di vendita %Number% dal %Date%';
							|pl = 'Typowe porozumienie o warunkach sprzedaży %Number% z dn. %Date%';
							|tr = '%Date% tarihli %Number% standart satış şart ve hükümleri'");
			TitleText = StrReplace(TitleText, "%Number%", Object.Number);
			TitleText = StrReplace(TitleText, "%Date%",  Object.Date);
		ElsIf Not ToUseTermsOfSales Then
			TitleText = Object.Description;
		Else
			TitleText = NStr("vi = 'Thỏa thuận chung về điều kiện bán hàng';
							|ru = 'Типовое соглашение об условиях продаж';
							|en = 'Standard terms of sale'; fa = 'Standard terms of sale';
							|it = 'Accordo tipico sulle condizioni di vendita';
							|pl = 'Typowe porozumienie o warunkach sprzedaży';
							|tr = 'Standart satış şart ve hükümleri'");
		EndIf;
		
	Else
		
		If ValueIsFilled(Object.Number) And ValueIsFilled(Object.Date) Then 
			TitleText = NStr("vi = 'Thỏa thuận riêng về điều kiện bán hàng %Number% ngày %Date%';
							|ru = 'Индивидуальное соглашение об условиях продаж %Number% от %Date%';
							|en = 'Special terms of sales %Number% dated %Date%'; fa = 'Special terms of sales %Number% dated %Date%';
							|it = 'Accordo individuale sulle condizioni di vendita %Number% dal %Date%';
							|pl = 'Indywidualne porozumienie o warunkach sprzedaży %Number% z dn. %Date%';
							|tr = '%Date% tarihli %Number% özelleştirilmiş satış şart ve hükümleri'");
			TitleText = StrReplace(TitleText, "%Number%", Object.Number);
			TitleText = StrReplace(TitleText, "%Date%",  Object.Date);
		Else
			TitleText = NStr("vi = 'Thỏa thuận riêng về điều kiện bán hàng';
							|ru = 'Индивидуальное соглашение об условиях продаж';
							|en = 'Special terms of sales'; fa = 'شرایط ویژه فروش';
							|it = 'Accordo individuale sulle condizioni di vendita';
							|pl = 'Indywidualna umowa o warunkach sprzedaży';
							|tr = 'Özelleştirilmiş satış şart ve hükümleri'");
		EndIf;
		
	EndIf;
	
	If Not ValueIsFilled(Object.Ref) Then
		Template = NStr("vi = '%1 (tạo mới)';
						|ru = '%1 (создание)';
						|en = '%1 (Create)'; fa = '%1 (Create)';
						|it = '%1 (creazione)';
						|pl = '%1 (utworzenie)';
						|tr = '%1 (oluşturma)'");
		TitleText = StringFunctionsClientServer.SubstituteParametersToString(Template, TitleText);
	EndIf;
	
	ThisForm.Title = TitleText;
	
EndProcedure


&AtServer
Procedure UpdateIndividualPriceViewPresentation()
	If ValueIsFilled(Object.SpecialPriceType) Then
		ArrayOfTexts = New Array;

		ArrayOfTexts.Add(New FormattedString(NStr("vi = 'Dạng giá riêng';
													|ru = 'Индивидуальный вид цены';
													|en = 'Special price type'; fa = 'نوع قیمت ویژه';
													|it = 'Tipo di prezzo individuale';
													|pl = 'Indywidualny rodzaj ceny';
													|tr = 'Özelleştirilmiş fiyat türü'")));
		
		ArrayOfTexts.Add(" (");
		ArrayOfTexts.Add(New FormattedString(NStr("vi = 'tùy chỉnh';
													|ru = 'настроить';
													|en = 'configure'; fa = 'configure';
													|it = 'impostare';
													|pl = 'configure';
													|tr = 'ayarla'"),,,,"OpenIVC"));
		ArrayOfTexts.Add(")");
		
	Else
		ArrayOfTexts = New Array;
		ArrayOfTexts.Add(New FormattedString(NStr("vi = 'Dạng giá riêng (không tùy chỉnh)';
													|ru = 'Индивидуальный вид цены (не настроен)';
													|en = 'Special price type (not configured)'; fa = 'Special price type (not configured)';
													|it = 'Tipo di prezzo individuale (non impostato)';
													|pl = 'Indywidualny rodzaj ceny (nie ustawiono)';
													|tr = 'Özelleştirilmiş fiyat türü (ayarlanmadı)'")));

		ArrayOfTexts.Add(" (");
		ArrayOfTexts.Add(New FormattedString(NStr("vi = 'tùy chỉnh';
													|ru = 'настроить';
													|en = 'configure'; fa = 'configure';
													|it = 'impostare';
													|pl = 'configure';
													|tr = 'ayarla'"),,,,"CreateIVC"));
		ArrayOfTexts.Add(")");
	EndIf;
	
	SpecialPriceTypePresentation = New FormattedString(ArrayOfTexts);
EndProcedure

&AtClient
Procedure SpecialPriceTypePresentationURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	If FormattedStringURL = "CreateIVC" Then

		If Not ValueIsFilled(Object.Ref)
			Or Modified Then
		
			QueryText = NStr("vi = 'Dữ liệu đã chỉnh sửa.
			|Chỉ có thể tùy chỉnh bảng giá riêng sau khi ghi lại phần tử.
			|Ghi lại phần tử?';
			|ru = 'Данные модифицированы.
			|Настройка индивидуального прайс-листа возможна только после записи элемента.
			|Записать элемент?';
			|en = 'The data has been modified.
			|Configuring an individual price list is only available after saving element.
			|Save the item?'; fa = 'The data has been modified.
			|Configuring an individual price list is only available after saving element.
			|Save the item?';
			|it = 'Dati modificati. 
			|L''impostazione del listino prezzi individuale è possibile solamente dopo la registrazione dell''elemento. 
			|Registrare elemento?';
			|pl = 'Dane zostały zmodyfikowane.
			|Ustawienie indywidualnego cennika jest możliwe tylko po zapisywaniu elementu.
			|Zapisać element?';
			|tr = 'Veriler değiştirildi.
			|Özelleştirilmiş fiyat listesi ayarı sadece öğenin kaydından sonra mümkündür.
			|Öğe kaydedilsin mi?'");
			
			ShowQueryBox(New CallbackDescription("CreateIVCQuestionCompletion", ThisObject), QueryText, QuestionDialogMode.YesNo);
			Return;
			
		EndIf;
	
		CreateIVCCompletion();
		
	ElsIf FormattedStringURL = "OpenIVC" Then
			 	
		ShowValue(Undefined, Object.SpecialPriceType);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CreateIVCQuestionCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.No Then
		Return;
	EndIf;
	
	Try
		ItemRecorded = Write();
	Except
		Return;
	EndTry;
	
	If Not ItemRecorded Then
		Return;
	EndIf;
	
	CreateIVCCompletion();

	
EndProcedure

&AtClient
Procedure CreateIVCCompletion()
	
	TransferResult = CreateIPLServer();
	
	If TransferResult.Result Then
		
		Read();
		UpdateIndividualPriceViewPresentation();
		ShowValue(Undefined, Object.SpecialPriceType);
		
	Else
		
		ClearMessages();
		CommonClient.MessageToUser(
			StrTemplate(NStr("vi = 'Đã xảy ra lỗi khi tạo bảng giá riêng %1';
							|ru = 'Возникла ошибка при создании индивидуального прайс листа %1';
							|en = 'An error occurred while generating the individual price list %1'; fa = 'An error occurred while generating the individual price list %1';
							|it = 'Возникла ошибка при создании индивидуального прайс листа %1';
							|pl = 'An error occurred while generating the individual price list %1';
							|tr = 'Özelleştirilmiş %1 fiyat listesi oluşturulurken hata oluştu'"), TransferResult.ErrorDescription),
			Object.Ref,
			);
			
	EndIf;
	
EndProcedure

&AtServer
Function CreateIPLServer()
	
	TransferResult = SettingPricesServer.CreateIPL(Object.Ref, CurrentSessionDate());
	
	Return TransferResult;
	
EndFunction

&AtServer
Procedure ClearDiscountsMarginsUnderCommissionAgreement()
	
	If Object.BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent 
		And ValueIsFilled(Object.Ref) 
		And DiscountsMarkups.GetItems().Count() > 0 Then
		
		RecordSet = InformationRegisters.ValidityOfDiscountsMarkups.CreateRecordSet();
		RecordSet.Filter.Source.Set(Object.Ref);
		RecordSet.Read();
		RecordSet.Clear();
		RecordSet.Write(True);
		
		BuildDiscountMarkUpTree();
	EndIf;
	
EndProcedure

&AtServer
Procedure SetPropertiesOfOutdatedCommissionUsageComment()
	
	Items.CommentUsingOutdatedCommission.Title = ConsignmentSalesServer.CommentUsingOutdatedCommission();
	Items.GroupCommentUsingOutdatedCommission.Visible = Not Object.ConsignmentSales25
		And Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.TransferToCommissionAgent");
	
EndProcedure
	
&AtServer
Procedure UpdateDeliverySchedulingSelectionList()
	
	GoodsDelivery.FillInDeliveryPlanningSelectionList(Items.DeliveryPlanning.ChoiceList, Object);
	
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
	If Item.Name = "sh_ShamsiInput_ValidityStartDate" Then
		ValidityStartDateOnChange(Items.ValidityStartDate);
	ElsIf Item.Name = "sh_ShamsiInput_F_SliceDate" Then
		SliceDateOnChange(Items.SliceDate);
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
