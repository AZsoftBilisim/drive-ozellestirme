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

	// Handler of the "Versioning of objects" mechanism
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	
	// Handler of the "Properties" mechanism
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	PropertyManager.OnCreateAtServer(ThisForm, AdditionalParameters);
	
	FillOperationSelectionList();
	
	TheseServices = Undefined;
	AdditionalParametersPassed = Undefined;
	If Parameters.Property("AdditionalParameters", AdditionalParametersPassed)
		And ValueIsFilled(AdditionalParametersPassed)
		And AdditionalParametersPassed.Property("TheseServices", TheseServices)
		And TypeOf(TheseServices) = Type("Structure") Then
		
		FillPropertyValues(Object,		TheseServices);
		FillPropertyValues(ThisObject,	TheseServices);
		
	Else
		Parameters.Property("AgencyServiceProducts",	AgencyServiceProducts);
		Parameters.Property("AgencyServiceCharacteristic",	AgencyServiceCharacteristic);
	EndIf;
	
	If Not ValueIsFilled(Object.Ref) Then
		If GetFormFunctionalOption("UseAgentServiceSale") And ValueIsFilled(AgencyServiceProducts) Then
			Object.UseSpecifiedAgentServices = True;	
		EndIf;	
		OnReadCreateAtServer();
	EndIf;
	
	PurchasesServer.SetModeForSelectingGroupsOfWarehouseItems(Items.Warehouse);
	
	TMCommonUseClientServer.SetFormItemProperty(Items,"GroupOfTheReturnDateCalculationMode","Visible", GetFunctionalOption("UseReusablePackage"),True);
	
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	GoodsDelivery.WhenReadingCreatingOrdersOnServer(Items, Object);

	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations

	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
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

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	OnReadCreateAtServer();
	
	PropertyManager.OnReadAtServer(ThisForm, CurrentObject);

	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);
	
	GoodsDelivery.WhenReadingCreatingOrdersOnServer(Items, Object);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If CurrentObject.UseSpecifiedAgentServices = False Then
		CurrentObject.AgentServices.Clear();
	EndIf;	
	
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
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);

EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_TermsOfPurchaseFromVendors",WriteParameters,Object.Ref);
	
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
	EndIf;
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ChoiceSource.FormName = "CommonForm.SelectAgentServices" Then
		Modified = True;
		UpdateSelectionServicesOnServer(ValueSelected);
	EndIf;
	
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
Procedure DeliveryAddressClearing(Item, StandardProcessing)
	
	DeliveryAddressOnChange(Item);
	
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

&AtClient
Procedure DeliveryAddressChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	DeliveryAddressOnChange(Item);
	
	GoodsDeliveryClient.DeliveryAddressChoiceProcessing(Items, Object, Item.Name, ValueSelected);
	
	Modified = True;
	
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

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PartnerOnChange(Item)
	
	Object.AgentServices.Clear();
	UpdateVisibilityOfAgencyServices();
	
	If Not ValueIsFilled(Object.Partner) Then
		Return;
	EndIf;
	
	WhenChangingPartnerServer();

EndProcedure

&AtClient
Procedure StatusOnChange(Item)
	
	If AgreementStatus <> Object.Status
		And Object.Status = PredefinedValue("Enum.StatusesOfTermsOfPurchase.Closed") 
		And (Object.ValidityEndDate > BegOfDay(CommonClient.SessionDate()) 
			Or Not ValueIsFilled(Object.ValidityEndDate))Then
			
		If Object.ValidityEndDate > BegOfDay(CommonClient.SessionDate()) Then
			QueryText = NStr("vi = 'Cần đóng thỏa thuận sao cho ngày hết hiệu lực tương ứng với ngày đóng.
				|Điều chỉnh ngày hết hiệu lực?';
				|ru = 'При закрытии соглашения необходимо, чтобы дата окончания действия соответствовала дате закрытия.
				|Скорректировать дату окончания действия?';
				|en = 'Upon closing the agreement, the expiration date should match the closing date.
				|Correct the expiration date?'; fa = 'Upon closing the agreement, the expiration date should match the closing date.
				|Correct the expiration date?';
				|it = 'Quando si chiude un accordo, è necessario che la data di scadenza corrisponda alla data di chiusura.
				|Correggere la data di scadenza?';
				|pl = 'Przy zamknięciu umowy należy, aby data wygaśnięcia odpowiadała dacie zamknięcia. 
				|Skorygować datę wygaśnięcia działania?';
				|tr = 'Anlaşmayı kapatırken, son geçerlilik tarihinin bitiş tarihine karşılık gelmesi gerekir.
				| Son geçerlilik tarihi ayarlansın mı?'");
		Else
			QueryText = NStr("vi = 'Cần đóng thỏa thuận sao cho ngày hết hiệu lực được điền.
				|Điều chỉnh ngày hết hiệu lực?';
				|ru = 'При закрытии соглашения необходимо, чтобы дата окончания действия была заполнена.
				|Скорректировать дату окончания действия?';
				|en = 'When closing the agreement, the expiration date should be fill in. 
				|Correct the expiration date?'; fa = 'When closing the agreement, the expiration date should be fill in. 
				|Correct the expiration date?';
				|it = 'Alla chiusura del contratto, è necessario che la data di scadenza sia compilata.
				|Correggere la data di scadenza?';
				|pl = 'Przy zamknięciu porozumienia data wygaśnięcia musi być wypełniona.
				|Skorygować datę wygaśnięcia?';
				|tr = 'Anlaşmayı kapatırken son geçerlilik tarihi girilmelidir.
				| Son geçerlilik tarihi ayarlansın mı?'");
		EndIf;
		ShowQueryBox(New CallbackDescription("StatusOnChangeCompletion", ThisObject), QueryText, QuestionDialogMode.YesNo);
		Return;
		
	EndIf;
	
	StatusWhenChangingFragment();
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
		Object.RemunerationPercentage  = Metadata.Catalogs.TermsOfPurchaseFromVendors.Attributes.RemunerationPercentage.FillValue;
		Object.KeepCommissionFee = Metadata.Catalogs.TermsOfPurchaseFromVendors.Attributes.KeepCommissionFee.FillValue;
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
Procedure ContractsAreUsedOnChange(Item)
	
	Object.ContractsAreUsed = Boolean(ContractsAreUsed);
	
	ConfigureCounterpartyAgreementsAndSettlementElements();
	FillInCalculationProcedure();
	SetVisibilityOfPaymentInCurrency();
	
EndProcedure

&AtClient
Procedure WarehouseOnChange(Item)
	
	SetVisibilityOfOptionForIssuingIncomingOrdersForGoods();
	
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
	FormParameters.Insert("PaymentMethod",               Object.PaymentMethod);
	FormParameters.Insert("DeliveryTime",              Object.DeliveryTime);
	FormParameters.Insert("ARAPObjectSettings",           ?(Not Object.ContractsAreUsed, Object.ARAPObjectSettings, Undefined));
	FormParameters.Insert("Calendar",                 Object.Calendar);
	FormParameters.Insert("BusinessOperation",     Object.BusinessOperation);
	FormParameters.Insert("PackageDepositIsRequired",      Object.ReturnReusablePackage And Object.PackageDepositIsRequired);
	FormParameters.Insert("UUID",   UUID);
	FormParameters.Insert("AddressInTempStorage", PutItInTemporaryStorageOnServer());
	PaymentParameters = Undefined;

	OpenForm("Catalog.TermsOfPurchaseFromVendors.Form.PaymentMethod", FormParameters, ThisForm,,,, New CallbackDescription("TheLabelPaymentClickCompletion", ThisObject), FormWindowOpeningMode.LockWholeInterface);
	
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
Procedure ReturnReusablePackageOnChange(Item)
	
	If Not Object.ReturnReusablePackage Then
		Object.PackageDepositIsRequired = False;
	EndIf;
	
	UpdateAvailabilityOfReturnContainerItems(ThisForm);
	
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

&AtClient
Procedure GoToAllServicesClick(Item)
	FormParameters = New Structure("UUID, Principal, IsPick",
							UUID, Object.Partner, False);
	OpenForm("CommonForm.SelectAgentServices", FormParameters, ThisForm);
EndProcedure

&AtClient
Procedure GoToSelectedServices(Item)
	AddressInStorage = PutServicesInStorage(
			Object.AgentServices,
			UUID);

	FormParameters = New Structure("UUID, Principal, IsPick",
						AddressInStorage, Object.Partner, True);
	OpenForm("CommonForm.SelectAgentServices", FormParameters, ThisForm);
EndProcedure

&AtClient
Procedure ServicesTypesOnChange(Item)
	UpdateVisibilityOfAgencyServices();
EndProcedure

&AtClient
Procedure CounterpartyOnChange(Item)
	
	Object.AgentServices.Clear();
	UpdateVisibilityOfAgencyServices();
	
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
Procedure StatusOnChangeCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		
		Object.ValidityEndDate = BegOfDay(CommonClient.SessionDate());
		
	EndIf;
	
	StatusWhenChangingFragment();
	
EndProcedure

&AtClient
Procedure StatusWhenChangingFragment()
	
	AgreementStatus = Object.Status;
	
	If Object.Approved
		And Object.Status <> PredefinedValue("Enum.StatusesOfTermsOfPurchase.Valid")
		And Object.Status <> PredefinedValue("Enum.StatusesOfTermsOfPurchase.Closed") Then
		
		Object.Approved = False;
		
	EndIf;
	
	SetAvailabilityOfItemsByStatusServer();
EndProcedure

&AtClient
Procedure ForeignCurrencyTransactionOnChange(Item)
	
	FillInFinancialAccountingGroup_(Object.Organization, Object.ARAPCurrency, Object.BusinessOperation, Object.FinancialAccountingGroup);
	
EndProcedure

&AtClient
Procedure SplitReportByDocumentsWhenChangesAreMade(Item)
	Object.SplitReportByDocuments = ToSplitReport;
	If ToSplitReport Then
		ContractsAreUsed = 1;
		Object.ContractsAreUsed = True;
	EndIf;
	ConfigureCounterpartyAgreementsAndSettlementElements();
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	LocalAccountingCurrency = SettingsValueClientServerCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	SetVisibilityOfPaymentInCurrency();
EndProcedure

&AtClient
Procedure CurrencyOnChange(Item)
	
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ConsignmentProcurement") Then
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

// End StandardSubsystems.AdditionalReportsAndDataProcessors

&AtClient
Procedure SetDateIntervalExecute(Command)
	
	TMCommonUseClient.EditPeriod(Object, 
		New Structure("StartDate, EndDate", "ValidityStartDate", "ValidityEndDate"));
	
EndProcedure

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
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
	ItemField.Field = New DataCompositionField(Items.Organization.Name);

	SelectionGroupAnd = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupAnd.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = SelectionGroupAnd.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Organization");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	ItemFilter.RightValue = True;
	
	ItemFilter = SelectionGroupAnd.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = PredefinedValue("Enum.BusinessTransactions.AgentServicesDelivery");

	ItemFilter = SelectionGroupAnd.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ValueList = New ValueList;
	ValueList.Add(PredefinedValue("Enum.StatusesOfTermsOfPurchase.Valid"));
	ValueList.Add(PredefinedValue("Enum.StatusesOfTermsOfPurchase.Closed"));
	ItemFilter.RightValue = ValueList;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True); 
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Organization.Name);

	SelectionGroupAnd = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupAnd.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = SelectionGroupAnd.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Organization");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	ItemFilter.RightValue = True;
	
	SelectionGroupOr = SelectionGroupAnd.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupOr.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = PredefinedValue("Enum.BusinessTransactions.AgentServicesDelivery");

	ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ValueList = New ValueList;
	ValueList.Add(PredefinedValue("Enum.StatusesOfTermsOfPurchase.Valid"));
	ValueList.Add(PredefinedValue("Enum.StatusesOfTermsOfPurchase.Closed"));
	ItemFilter.RightValue = ValueList;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False); 
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Organization.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Organization");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False); 
	
EndProcedure

#Region OnChangeAttributes

&AtServer
Procedure WhenChangingPartnerServer()
	
	CatalogObject = FormAttributeToValue("Object");
	CatalogObject.FillDefaultAttributes();
	ValueToFormAttribute(CatalogObject, "Object");
	
	FillInAndSetDeliveryAttributesServer("Partner");


EndProcedure

&AtServer
Procedure WhenBusinessTransactionChangesServer()

	If Object.BusinessOperation = Enums.BusinessTransactions.ConsignmentProcurement
		Or Object.BusinessOperation = Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale Then
		
		If Object.BusinessOperation = Enums.BusinessTransactions.ConsignmentProcurement Then
			Object.PercentRateOfManualDiscount          = Metadata.Catalogs.TermsOfPurchaseFromVendors.Attributes.PercentRateOfManualDiscount.FillValue;
			Object.MaximumPercentageForManualMarkup         = Metadata.Catalogs.TermsOfPurchaseFromVendors.Attributes.MaximumPercentageForManualMarkup.FillValue;
		Else
			Object.ContractsAreUsed = True;
			ContractsAreUsed = 1;
		EndIf;
		
		Object.ReturnReusablePackage = False;
		Object.PackageDepositIsRequired = False;
		
		ArrayOfRowsToDelete_1 = New Array;
		For Each PaymentLine_ In Object.PaymentScheduleSteps Do
			If PaymentLine_.PaymentOption <> Enums.OptionsForControllingPaymentToSupplier.CreditAfterShipment
				And PaymentLine_.PaymentOption <> Enums.OptionsForControllingPaymentToSupplier.CreditAfterReceipt Then
				ArrayOfRowsToDelete_1.Add(PaymentLine_);
			EndIf;
		EndDo;
		
		For Each RowToDelete In ArrayOfRowsToDelete_1 Do
			Object.PaymentScheduleSteps.Delete(RowToDelete);
		EndDo;
		
		NumberOfStages = Object.PaymentScheduleSteps.Count();
		If NumberOfStages = 1 Then
			Object.PaymentScheduleSteps[0].PaymentPercentage = 100;
		ElsIf NumberOfStages = 0
				And GetFunctionalOption("UseSimplifiedPaymentSchemeInPurchasing") Then
			StageString_ = Object.PaymentScheduleSteps.Add();
			StageString_.PaymentOption  = Enums.OptionsForControllingPaymentToSupplier.CreditAfterShipment;
			StageString_.CalculateFrom  = Enums.PaymentDateCalculationOptions.FromShipmentDate;
			StageString_.PaymentPercentage = 100;
		EndIf;
		
		TheLabelPayment = PaymentStepsClientServer.InscriptionStagesPaymentForAgreements(ThisForm);
		
		Object.ARAPCurrency = Object.Currency;
		
		FillInPaymentInCurrencyOfFinancialAccountingGroup(
			Object.Organization,
			Object.ARAPCurrency,
			Object.ForeignCurrencyTransaction,
			Object.FinancialAccountingGroup,
			Object.ContractsAreUsed,
			Object.BusinessOperation);
			
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.PurchaseByImport 
		Or Object.BusinessOperation = Enums.BusinessTransactions.ImportFromEAEU Then
		
		Object.ReturnReusablePackage = False;
		Object.PackageDepositIsRequired = False;
		Object.ForeignCurrencyTransaction = True;
		FillInFinancialAccountingGroup_(Object.Organization, Object.ARAPCurrency, Object.BusinessOperation, Object.FinancialAccountingGroup);
		
	Else
		
		Object.CommissionFeeCalculationMethod = Metadata.Catalogs.TermsOfPurchaseFromVendors.Attributes.CommissionFeeCalculationMethod.FillValue;
		Object.RemunerationPercentage       = Metadata.Catalogs.TermsOfPurchaseFromVendors.Attributes.RemunerationPercentage.FillValue;
		Object.KeepCommissionFee      = Metadata.Catalogs.TermsOfPurchaseFromVendors.Attributes.KeepCommissionFee.FillValue;
		
	EndIf;
	
	SetVisibilityOfElementsByOperationServer();
	SetMarkForEmptySupplierPriceType();
	FillInCalculationProcedure();
	ConfigureCounterpartyAgreementsAndSettlementElements();
	UpdateAvailabilityOfReturnContainerItems(ThisForm);
	UpdateVisibilityOfAgencyServices();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure OnReadCreateAtServer()
	
	AgreementStatus = Object.Status;
	CalculatePackageReturnDateAccordingToCalendar = Number(Object.CalculatePackageReturnDateAccordingToCalendar);
	
	UsePurchaseOrders = GetFunctionalOption("UsePurchaseOrders");
	
	
	SetAvailabilityOfItemsByStatusServer();
	SetVisibilityOfElementsByOperationServer();
	SetMarkForEmptySupplierPriceType();
	SetVisibilityOfOptionForIssuingIncomingOrdersForGoods();
	TheLabelPayment = PaymentStepsClientServer.InscriptionStagesPaymentForAgreements(ThisForm);
	ContractsAreUsed = Number(Object.ContractsAreUsed);
	ConfigureCounterpartyAgreementsAndSettlementElements();
	UpdateAvailabilityOfReturnContainerItems(ThisForm);
	CalculateNumberOfAgencyServices();
	EstablishVisibilityOfAgencyServices();
	SetParametersForSelectingCashFlowItem();
	
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
	ItemArray.Add("Currency");
	ItemArray.Add("ARAPCurrency");
	ItemArray.Add("PriceIncludesVAT");
	ItemArray.Add("Warehouse");
	ItemArray.Add("ShipmentDueDate");
	ItemArray.Add("BusinessOperation");
	ItemArray.Add("PercentRateOfManualDiscount");
	ItemArray.Add("MaximumPercentageForManualMarkup");
	ItemArray.Add("ControlPurchasePrices");
	ItemArray.Add("PaymentMethod");
	ItemArray.Add("ForeignCurrencyTransaction");
	ItemArray.Add("Calendar");
	ItemArray.Add("ContractsAreUsed");
	ItemArray.Add("PaymentScheduleSteps");
	ItemArray.Add("SetDateInterval");
	ItemArray.Add("ReturnReusablePackage");
	ItemArray.Add("ReusablePackageReturnCycleLength");
	ItemArray.Add("CalculatePackageReturnDateAccordingToCalendar");
	ItemArray.Add("NotCalculatePackageReturnDateAccordingToCalendar");
	ItemArray.Add("PackageDepositIsRequired");
	
	TMCommonUse.SetSubscriptionForFormElementChangeEvents(ThisObject, ItemArray);
	
EndProcedure

&AtServer
Procedure SetVisibilityOfElementsByOperationServer()
	
	Var ArrayOfAllProps;
	Var ArrayOfOperationDetails;
	
	Catalogs.TermsOfPurchaseFromVendors.FillInNamesOfBusinessTransactionDetails(
		Object.BusinessOperation, 
		ArrayOfAllProps, 
		ArrayOfOperationDetails);
	
	CashServer.SetVisibilityOfElementsByArray(
		Items,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
	
	ItemArray = New Array();
	ItemArray.Add("CommissionFeeCalculationMethod");
	ItemArray.Add("PercentageReward");
	ItemArray.Add("KeepCommissionFee");
	
	If Object.BusinessOperation = Enums.BusinessTransactions.ConsignmentProcurement Then
		TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Visible", True);
		CommissionFeeCalculationMethodOnChangeServer();
		TMCommonUseClientServer.SetFormItemProperty(Items, "CommandToSwitchToPriceConditions", "Visible", False);
		TMCommonUseClientServer.SetFormItemProperty(Items, "AgencyServiceSettingsGroup", "Visible", False);
		TMCommonUseClientServer.SetFormItemProperty(Items, "Warehouse", "Visible", True);
		TMCommonUseClientServer.SetFormItemProperty(Items, "ShipmentDueDate", "Visible", True);
		TMCommonUseClientServer.SetFormItemProperty(Items, "MinimumOrderAmountGroup", "Visible", True);
		TMCommonUseClientServer.SetFormItemProperty(Items, "GroupReturnRefundPeriod", "Visible", True);
		TMCommonUseClientServer.SetFormItemProperty(Items, "ReusablePackageReturnCycleLength", "Visible", True);
		TMCommonUseClientServer.SetFormItemProperty(Items, "PackageDepositIsRequired", "Visible", True);
		TMCommonUseClientServer.SetFormItemProperty(Items, "GroupOfTheReturnDateCalculationMode", "Visible", True);
		TMCommonUseClientServer.SetFormItemProperty(Items, "RegisterSupplierPricesAutomatically", "Visible", True);
		TMCommonUseClientServer.SetFormItemProperty(Items, "ShippingTimeDecoration", "Visible", True);
		TMCommonUseClientServer.SetFormItemProperty(Items, "ControlPurchasePrices", "Visible", True);
		TMCommonUseClientServer.SetFormItemProperty(Items, "SplitReportGroup", "Visible", True);
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale Then
		TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Visible", False);
		TMCommonUseClientServer.SetFormItemProperty(Items, "CommandToSwitchToPriceConditions", "Visible", False);
		TMCommonUseClientServer.SetFormItemProperty(Items, "AgencyServiceSettingsGroup", "Visible", False);
		TMCommonUseClientServer.SetFormItemProperty(Items, "Warehouse", "Visible", True);
		TMCommonUseClientServer.SetFormItemProperty(Items, "ShipmentDueDate", "Visible", True);
		TMCommonUseClientServer.SetFormItemProperty(Items, "MinimumOrderAmountGroup", "Visible", True);
		TMCommonUseClientServer.SetFormItemProperty(Items, "GroupReturnRefundPeriod", "Visible", True);
		TMCommonUseClientServer.SetFormItemProperty(Items, "ReusablePackageReturnCycleLength", "Visible", True);
		TMCommonUseClientServer.SetFormItemProperty(Items, "PackageDepositIsRequired", "Visible", True);
		TMCommonUseClientServer.SetFormItemProperty(Items, "GroupOfTheReturnDateCalculationMode", "Visible", True);
		TMCommonUseClientServer.SetFormItemProperty(Items, "RegisterSupplierPricesAutomatically", "Visible", True);
		TMCommonUseClientServer.SetFormItemProperty(Items, "ShippingTimeDecoration", "Visible", True);
		TMCommonUseClientServer.SetFormItemProperty(Items, "ControlPurchasePrices", "Visible", False);
		TMCommonUseClientServer.SetFormItemProperty(Items, "SplitReportGroup", "Visible", False);
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.AgentServicesDelivery Then
		TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Visible", True);
		CommissionFeeCalculationMethodOnChangeServer();
		TMCommonUseClientServer.SetFormItemProperty(Items, "AgencyServiceSettingsGroup", "Visible", True);
		TMCommonUseClientServer.SetFormItemProperty(Items, "Warehouse", "Visible", False);
		TMCommonUseClientServer.SetFormItemProperty(Items, "ShipmentDueDate", "Visible", False);
		TMCommonUseClientServer.SetFormItemProperty(Items, "MinimumOrderAmountGroup", "Visible", False);
		TMCommonUseClientServer.SetFormItemProperty(Items, "GroupReturnRefundPeriod", "Visible", False);
		TMCommonUseClientServer.SetFormItemProperty(Items, "ReusablePackageReturnCycleLength", "Visible", False);
		TMCommonUseClientServer.SetFormItemProperty(Items, "PackageDepositIsRequired", "Visible", False);
		TMCommonUseClientServer.SetFormItemProperty(Items, "GroupOfTheReturnDateCalculationMode", "Visible", False);
		TMCommonUseClientServer.SetFormItemProperty(Items, "RegisterSupplierPricesAutomatically", "Visible", False);
		TMCommonUseClientServer.SetFormItemProperty(Items, "ShippingTimeDecoration", "Visible", False);
		TMCommonUseClientServer.SetFormItemProperty(Items, "ControlPurchasePrices", "Visible", False);
		TMCommonUseClientServer.SetFormItemProperty(Items, "SplitReportGroup", "Visible", True);
	Else
		TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Visible", False);
		TMCommonUseClientServer.SetFormItemProperty(Items, "CommandToSwitchToPriceConditions", "Visible", True);
		TMCommonUseClientServer.SetFormItemProperty(Items, "AgencyServiceSettingsGroup", "Visible", False);
		TMCommonUseClientServer.SetFormItemProperty(Items, "Warehouse", "Visible", True);
		TMCommonUseClientServer.SetFormItemProperty(Items, "ShipmentDueDate", "Visible", True);
		TMCommonUseClientServer.SetFormItemProperty(Items, "MinimumOrderAmountGroup", "Visible", True);
		TMCommonUseClientServer.SetFormItemProperty(Items, "GroupReturnRefundPeriod", "Visible", True);
		TMCommonUseClientServer.SetFormItemProperty(Items, "ReusablePackageReturnCycleLength", "Visible", True);
		TMCommonUseClientServer.SetFormItemProperty(Items, "PackageDepositIsRequired", "Visible", True);
		TMCommonUseClientServer.SetFormItemProperty(Items, "GroupOfTheReturnDateCalculationMode", "Visible", True);
		TMCommonUseClientServer.SetFormItemProperty(Items, "RegisterSupplierPricesAutomatically", "Visible", True);
		TMCommonUseClientServer.SetFormItemProperty(Items, "ShippingTimeDecoration", "Visible", True);
		TMCommonUseClientServer.SetFormItemProperty(Items, "ControlPurchasePrices", "Visible", True);
		TMCommonUseClientServer.SetFormItemProperty(Items, "SplitReportGroup", "Visible", False);
	EndIf;
	
EndProcedure

&AtServer
Procedure SetMarkForEmptySupplierPriceType()
	
	If Object.BusinessOperation = Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale Then
		Items.TypeOfSupplierSPrices.AutoMarkIncomplete = True;
	Else
		Items.TypeOfSupplierSPrices.AutoMarkIncomplete = False;
		Items.TypeOfSupplierSPrices.MarkIncomplete = False;
	EndIf;

EndProcedure

&AtServer
Procedure FillOperationSelectionList()
	
	If Not GetFormFunctionalOption("UsePurchaseCommission") Then
		
		ListItem = Items.BusinessOperation.ChoiceList.FindByValue(Enums.BusinessTransactions.ConsignmentProcurement);
		If ListItem <> Undefined Then
			Items.BusinessOperation.ChoiceList.Delete(ListItem);
		EndIf;
		
	EndIf;
	
	If Not GetFormFunctionalOption("UseImports") Then
		
		ListItem = Items.BusinessOperation.ChoiceList.FindByValue(Enums.BusinessTransactions.PurchaseByImport);
		If ListItem <> Undefined Then
			Items.BusinessOperation.ChoiceList.Delete(ListItem);
		EndIf;
		
		ListItem = Items.BusinessOperation.ChoiceList.FindByValue(Enums.BusinessTransactions.ImportFromEAEU);
		If ListItem <> Undefined Then
			Items.BusinessOperation.ChoiceList.Delete(ListItem);
		EndIf;
		
	EndIf;
	
	If Not GetFormFunctionalOption("UseAgentServiceSale") Then
		
		ListItem = Items.BusinessOperation.ChoiceList.FindByValue(Enums.BusinessTransactions.AgentServicesDelivery);
		If ListItem <> Undefined Then
			Items.BusinessOperation.ChoiceList.Delete(ListItem);
		EndIf;
		
	EndIf;
	
	UseCustodyDuringPurchase = GetFormFunctionalOption(
		"UseCustodyDuringPurchase");
	
	If Not UseCustodyDuringPurchase Then
		
		ListItem = Items.BusinessOperation.ChoiceList.FindByValue(Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale);
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
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisForm);
	
EndProcedure

&AtServer
Procedure SetVisibilityOfOptionForIssuingIncomingOrdersForGoods()
	
	If Not ValueIsFilled(Object.Warehouse) Then
		SetFormFunctionalOptionParameters(New Structure("Warehouse", Undefined));
	Else
		WarehouseGroup_ = Catalogs.Warehouses.ThisGroupAndWarehousesAreUsedByWTCProcurementDocuments(Object.Warehouse);
		If WarehouseGroup_ Then
			SetFormFunctionalOptionParameters(New Structure("Warehouse", Undefined));
		Else
			SetFormFunctionalOptionParameters(New Structure("Warehouse", Object.Warehouse));
		EndIf;
	EndIf;
	
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

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisForm, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
	If Object.BusinessOperation = Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale Then
		
		For Each PaymentScheduleStage In Object.PaymentScheduleSteps Do
			
			If PaymentScheduleStage.PaymentOption <> Enums.OptionsForControllingPaymentToSupplier.CreditAfterShipment
				And PaymentScheduleStage.PaymentOption <> Enums.OptionsForControllingPaymentToSupplier.CreditAfterReceipt Then
				
				ErrorText = NStr("vi = 'Không nên sử dụng phương án kiểm soát thanh toán ""%PaymentOption%""';
								|ru = 'Вариант контроля оплаты ""%PaymentOption%"" нельзя использовать';
								|en = 'Cannot use the %PaymentOption% payment control option'; fa = 'Cannot use the %PaymentOption% payment control option';
								|it = 'Impossibile utilizzare la variante di controllo di pagamento ""%PaymentOption%""';
								|pl = 'Wariant kontroli płatności ""%PaymentOption%"" nie może być użyty';
								|tr = 'Ödeme kontrolü seçeneği ""%PaymentOption% kullanılamaz'") + Chars.LF;
				ErrorText = ErrorText + NStr("vi = 'khi giao dịch kinh doanh được thiết lập ""Chấp nhận lưu trữ với quyền bán""';
											|ru = 'при установленной хозяйственной операции ""Прием на хранение с правом продажи""';
											|en = 'when the ""VMI procurement"" business transaction is set'; fa = 'when the ""VMI procurement"" business transaction is set';
											|it = 'con l''operazione economica impostata ""Accettazione all''immagazzinamento con permesso di vendita""';
											|pl = 'przy ustawionej operacji gospodarczej ""Przyjęcie na przechowywanie z prawem sprzedaży""';
											|tr = '""satış hakkı ile depolanan mallar"" olarak tanımlanan bir ticari faaliyetin kurulması durumunda'");
				ErrorText = StrReplace(ErrorText, "%PaymentOption%", PaymentScheduleStage.PaymentOption);
				
				Common.MessageToUser(
					ErrorText,
					,
					"TheLabelPayment",
					,
					Cancel);
				
			EndIf;
			
		EndDo;
	
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.ConsignmentProcurement Then
	
		For Each PaymentScheduleStage In Object.PaymentScheduleSteps Do
			
			If PaymentScheduleStage.PaymentOption <> Enums.OptionsForControllingPaymentToSupplier.CreditAfterShipment
				And PaymentScheduleStage.PaymentOption <> Enums.OptionsForControllingPaymentToSupplier.CreditAfterReceipt Then
				
				ErrorText = NStr("vi = 'Không nên sử dụng phương án kiểm soát thanh toán ""%PaymentOption%""';
								|ru = 'Вариант контроля оплаты ""%PaymentOption%"" нельзя использовать';
								|en = 'Cannot use the %PaymentOption% payment control option'; fa = 'Cannot use the %PaymentOption% payment control option';
								|it = 'Impossibile utilizzare la variante di controllo di pagamento ""%PaymentOption%""';
								|pl = 'Wariant kontroli płatności ""%PaymentOption%"" nie może być użyty';
								|tr = 'Ödeme kontrolü seçeneği ""%PaymentOption% kullanılamaz'") + Chars.LF;
				ErrorText = ErrorText + NStr("vi = 'khi thiết lập giao dịch kinh tế ""Tiếp nhận vào ký gửi""';
											|ru = 'при установленной хозяйственной операции ""Прием на комиссию""';
											|en = 'when ""Consignment procurement"" is set'; fa = 'when ""Consignment procurement"" is set';
											|it = 'con l''operazione economica impostata ""Accettazione alla commissione""';
											|pl = 'przy ustawionej operacji gospodarczej ""Przyjęcie do komisu""';
											|tr = '""konsinye tedarik"" iş operasyonunun kurulumunda'");
				ErrorText = StrReplace(ErrorText, "%PaymentOption%", PaymentScheduleStage.PaymentOption);
				
				Common.MessageToUser(
					ErrorText,
					,
					"TheLabelPayment",
					,
					Cancel);
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure FillInFinancialAccountingGroup_(Organization, ARAPCurrency, BusinessOperation, FinancialAccountingGroup)
	
	FinancialAccountingGroup = Catalogs.FinancialAccountingGroupsOfARAP.GetDefaultFinancialAccountingGroup(Organization, ARAPCurrency, BusinessOperation);
	
EndProcedure

&AtServer
Procedure ConfigureCounterpartyAgreementsAndSettlementElements()
	
	AvailabilityUseOfContracts = True;
	If Object.BusinessOperation = Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale Then
		VisibilityOfCalculationOrder   = False;
		AvailabilityOfCalculationProcedure = False;
		TextContractsOfCounterpartiesAreUsed = NStr("vi = 'Không sử dụng hợp đồng, trình tự hạch toán:';
													|ru = 'Договоры не используются, порядок расчетов:';
													|en = 'Contracts are not used, payment terms:'; fa = 'قراردادها استفاده نمی‌شوند، شرایط پرداخت:';
													|it = 'Contratti non si utilizzano, modalità di regolamenti:';
													|pl = 'Umowy nie dotyczą, sposób rozliczeń:';
													|tr = 'Sözleşmeler kullanılmıyor, uzlaşma prosedürü:'");
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.ConsignmentProcurement
			  Or Object.BusinessOperation = Enums.BusinessTransactions.AgentServicesDelivery Then
		VisibilityOfCalculationOrder   = False;
		AvailabilityOfCalculationProcedure = False;
		TextContractsOfCounterpartiesAreUsed = NStr("vi = 'Không sử dụng hợp đồng, trình tự hạch toán theo bảng kê ký gửi';
													|ru = 'Договоры не используются, порядок расчетов по отчетам по комиссии';
													|en = 'Contracts are not used, payment terms by commission reports'; fa = 'Contracts are not used, payment terms by commission reports';
													|it = 'Gli accordi non si utilizzano, l''ordine dei conti viene fatto secondo i report sulla commissione';
													|pl = 'Umowy nie są używane, procedura rozliczeń dla raportów dotyczących komisu';
													|tr = 'Sözleşmeler kullanılmıyor, komisyon raporlarının karara bağlanması için uzlaşma prosedürü'");
	ElsIf Not UsePurchaseOrders Then
		VisibilityOfCalculationOrder   = False;
		AvailabilityOfCalculationProcedure = False;
		TextContractsOfCounterpartiesAreUsed = NStr("vi = 'Không sử dụng hợp đồng, trình tự hạch toán theo hóa đơn';
													|ru = 'Договоры не используются, порядок расчетов по накладным';
													|en = 'Contracts are not used, payment terms by invoices'; fa = 'Contracts are not used, payment terms by invoices';
													|it = 'Gli accordi non si utilizzano, l''ordine dei conti viene fatto secondo le bolle';
													|pl = 'Umowy nie są używane, procedura rozliczeń faktur';
													|tr = 'Sözleşmeler kullanılmıyor, irsaliye uzlaşma prosedürü'");
	ElsIf Object.ContractsAreUsed Then
		VisibilityOfCalculationOrder   = True;
		AvailabilityOfCalculationProcedure = False;
		TextContractsOfCounterpartiesAreUsed = NStr("vi = 'Không sử dụng hợp đồng, trình tự hạch toán:';
													|ru = 'Договоры не используются, порядок расчетов:';
													|en = 'Contracts are not used, payment terms:'; fa = 'قراردادها استفاده نمی‌شوند، شرایط پرداخت:';
													|it = 'Contratti non si utilizzano, modalità di regolamenti:';
													|pl = 'Umowy nie dotyczą, sposób rozliczeń:';
													|tr = 'Sözleşmeler kullanılmıyor, uzlaşma prosedürü:'");
	Else
		VisibilityOfCalculationOrder   = True;
		AvailabilityOfCalculationProcedure = True;
		TextContractsOfCounterpartiesAreUsed = NStr("vi = 'Không sử dụng hợp đồng, trình tự hạch toán:';
													|ru = 'Договоры не используются, порядок расчетов:';
													|en = 'Contracts are not used, payment terms:'; fa = 'قراردادها استفاده نمی‌شوند، شرایط پرداخت:';
													|it = 'Contratti non si utilizzano, modalità di regolamenti:';
													|pl = 'Umowy nie dotyczą, sposób rozliczeń:';
													|tr = 'Sözleşmeler kullanılmıyor, uzlaşma prosedürü:'");
	EndIf;
	
	AvailabilityUseOfContracts = True;
	If Object.BusinessOperation = Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale
		Or (Object.BusinessOperation = Enums.BusinessTransactions.ConsignmentProcurement
			Or Object.BusinessOperation = Enums.BusinessTransactions.AgentServicesDelivery)
			And Object.SplitReportByDocuments Then
		AvailabilityUseOfContracts = False;
	EndIf;
	
	Items.ContractsAreUsed.ReadOnly   = Not AvailabilityUseOfContracts;
	Items.NotContractsAreUsed.ReadOnly = Not AvailabilityUseOfContracts;
	
	Items.ARAPObjectSettings.Visible   = VisibilityOfCalculationOrder;
	Items.ARAPObjectSettings.Enabled = AvailabilityOfCalculationProcedure;
	
	Items.NotContractsAreUsed.ChoiceList.Clear();
	Items.NotContractsAreUsed.ChoiceList.Add(0, TextContractsOfCounterpartiesAreUsed);
	
	Items.ForeignCurrencyTransaction.Enabled = Not Object.ContractsAreUsed;
	Items.ARAPCurrency.Enabled = Not Object.ContractsAreUsed
												And Not Object.BusinessOperation = Enums.BusinessTransactions.ConsignmentProcurement
												And Not Object.BusinessOperation = Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale;
	
	If Object.ContractsAreUsed Then
		Items.FinancialAccountingGroup.Enabled = False;
		Items.FinancialAccountingGroup.InputHint = NStr("vi = '<được đặt trong hợp đồng>';
														|ru = '<задается в договоре>';
														|en = '<to be specified in contract>'; fa = '<to be specified in contract>';
														|it = '<viene impostato nel contratto>';
														|pl = '<jest zadawane w umowie>';
														|tr = '<sözleşmede belirtilen>'");
		
		Items.CashFlowItem.Enabled = False;
		Items.CashFlowItem.InputHint = NStr("vi = '<được đặt trong hợp đồng>';
											|ru = '<задается в договоре>';
											|en = '<to be specified in contract>'; fa = '<to be specified in contract>';
											|it = '<viene impostato nel contratto>';
											|pl = '<jest zadawane w umowie>';
											|tr = '<sözleşmede belirtilen>'");
		
		Items.LineOfBusiness.Enabled = False;
		Items.LineOfBusiness.InputHint = NStr("vi = '<được đặt trong hợp đồng>';
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
	
	If Object.BusinessOperation = Enums.BusinessTransactions.ConsignmentProcurement And
		Not Object.ContractsAreUsed Then
		Object.ARAPCurrency = Object.Currency;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInCalculationProcedure()
	
	If Object.ContractsAreUsed Then
		Object.ARAPObjectSettings = Enums.ARAPObjectSettings.EmptyRef();
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.ConsignmentProcurement 
			  Or Object.BusinessOperation = Enums.BusinessTransactions.AgentServicesDelivery 
			  Or Not UsePurchaseOrders Then
		Object.ARAPObjectSettings = Enums.ARAPObjectSettings.ByARAPDocuments;
	ElsIf Not ValueIsFilled(Object.ARAPObjectSettings) Then
		Object.ARAPObjectSettings = Enums.ARAPObjectSettings.ByOrders;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateAvailabilityOfReturnContainerItems(Form)
	
	ItemArray = New Array();
	ItemArray.Add("CalculatePackageReturnDateAccordingToCalendar");
	ItemArray.Add("NotCalculatePackageReturnDateAccordingToCalendar");
	ItemArray.Add("ReusablePackageReturnCycleLength");
	ItemArray.Add("PackageDepositIsRequired");
	ItemArray.Add("ScheduleOfPackageReturn");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(
		Form.Items,
		ItemArray,
		"Enabled",
		Form.Object.ReturnReusablePackage);
	
	TMCommonUseClientServer.SetFormItemProperty(
		Form.Items,
		"ReturnReusablePackage",
		"Enabled",
		Form.Object.BusinessOperation <> PredefinedValue("Enum.BusinessTransactions.PurchaseByImport")
		And Form.Object.BusinessOperation <> PredefinedValue("Enum.BusinessTransactions.ImportFromEAEU")
		And Form.Object.BusinessOperation <> PredefinedValue("Enum.BusinessTransactions.ConsignmentProcurement")
		And Form.Object.BusinessOperation <> PredefinedValue("Enum.BusinessTransactions.ReceivingForStorageWithRightOfSale"));
		
	Form.Items.ScheduleOfPackageReturn.Enabled = Form.Object.CalculatePackageReturnDateAccordingToCalendar And Form.Object.ReturnReusablePackage;
	
EndProcedure

&AtServer
Procedure FillProductionCalendarOnServer()
	
	CalendarSchedules.FillBusinessCalendarInForm(ThisForm, "Object.ScheduleOfPackageReturn");
	
EndProcedure

&AtServer
Procedure UpdateVisibilityOfAgencyServices()
	
	Object.SplitReportByDocuments = ToSplitReport;
	
	If ServicesTypes = "ForSelectedServices" Then
		Object.UseSpecifiedAgentServices = True;
		TMCommonUseClientServer.SetFormItemProperty(Items,"BlankDecoration","Visible", True);
		TMCommonUseClientServer.SetFormItemProperty(Items,"GoToSelectedServices","Visible", True);
		TMCommonUseClientServer.SetFormItemProperty(Items,"GoToAllServices","Visible", False);
		If ValueIsFilled(AgencyServiceProducts) Then
			Object.AgentServices.Clear();
			NewRow = Object.AgentServices.Add();
			NewRow.Products   = AgencyServiceProducts;
			NewRow.Characteristic = AgencyServiceCharacteristic;
		EndIf;
	Else
		Object.UseSpecifiedAgentServices = False;
		TMCommonUseClientServer.SetFormItemProperty(Items,"BlankDecoration","Visible", False);
		TMCommonUseClientServer.SetFormItemProperty(Items,"GoToAllServices","Visible", True);
		TMCommonUseClientServer.SetFormItemProperty(Items,"GoToSelectedServices","Visible", False);
	EndIf;
	CalculateNumberOfAgencyServices();
EndProcedure

&AtServer
Procedure UpdateSelectionServicesOnServer(AddressInTempStorage)
	
	Object.AgentServices.Clear();
	TableAgencyServices = GetFromTempStorage(AddressInTempStorage);
	For Each CurRow In TableAgencyServices Do
		FilterParameters = New Structure;
		FilterParameters.Insert("Products", CurRow.Products);
		FilterParameters.Insert("Characteristic", CurRow.Characteristic);
		FoundRows = Object.AgentServices.FindRows(FilterParameters); 
		
		If FoundRows.Count() = 0 Then
			NewRow = Object.AgentServices.Add();
			FillPropertyValues(NewRow, CurRow);
		EndIf;
	EndDo;
	
	CalculateNumberOfSelectedServices();
	
EndProcedure

&AtServer
Function PutServicesInStorage(Val Services, Var_UUID)

	AddressInStorage = PutToTempStorage(
		Services.Unload(,"Products, Characteristic"),
		Var_UUID);
		
	Return AddressInStorage;
	
EndFunction

&AtServer
Procedure CalculateNumberOfAgencyServices()
	
	CalculateNumberOfSelectedServices();
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	Products.Ref AS Products,
	|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS Characteristic,
	|	FALSE AS Selected
	|FROM
	|	Catalog.Products AS Products
	|WHERE
	|	NOT Products.IsFolder
	|	AND Products.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.DontUse)
	|	AND Products.Principal = &Principal
	|
	|UNION ALL
	|
	|SELECT
	|	Products.Ref,
	|	ItemsCharacteristics.Ref,
	|	FALSE
	|FROM
	|	Catalog.ItemsCharacteristics AS ItemsCharacteristics
	|		INNER JOIN Catalog.Products AS Products
	|		ON (CASE
	|				WHEN Products.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems)
	|					THEN Products.Ref
	|				WHEN Products.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind)
	|					THEN Products.ProductKind
	|				WHEN Products.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind)
	|					THEN Products.ItemVariantsOwner
	|				ELSE UNDEFINED
	|			END = ItemsCharacteristics.Owner)
	|WHERE
	|	Products.UseVariants IN (VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems), VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind), VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind))
	|	AND ItemsCharacteristics.Principal = &Principal";
	
	Query.SetParameter("Principal", Object.Partner);
	Selection = Query.Execute().Select();
	
	TitleText = NStr("vi = 'Chuyển đến (%Count% chiếc.)';
					|ru = 'Перейти (%Count% шт.)';
					|en = 'Go to (%Count% pcs)'; fa = 'Go to (%Count% pcs)';
					|it = 'Andare a (%Count% pz.)';
					|pl = 'Przejdź (%Count% szt.)';
					|tr = 'Git (%Count% parça.)'");
	TitleText = StrReplace(TitleText, "%Count%", Selection.Count());
	TMCommonUseClientServer.SetFormItemProperty(Items, "GoToAllServices", "Title", TitleText);
	
EndProcedure

&AtServer
Procedure CalculateNumberOfSelectedServices()
	
	TMCommonUseClientServer.SetFormItemProperty(Items,"GoToSelectedServices",
				"Title", NStr("vi = 'Chuyển đến (';
								|ru = 'Перейти (';
								|en = 'Go to ('; fa = 'Go to (';
								|it = 'Andare a (';
								|pl = 'Przejdź (';
								|tr = 'Git ('") +Object.AgentServices.Count()+ " " + NStr("vi = 'chiếc.)';
																							|ru = 'шт.)';
																							|en = 'pcs.)'; fa = 'pcs.)';
																							|it = 'pz.)';
																							|pl = 'pcs.)';
																							|tr = 'parça.)'"));
	
EndProcedure

&AtServer
Procedure EstablishVisibilityOfAgencyServices()
	If Object.UseSpecifiedAgentServices Then
		ServicesTypes = "ForSelectedServices";
	Else
		ServicesTypes = "ForAllServices";
	EndIf;
	
	ToSplitReport = ?(Object.SplitReportByDocuments, 1, 0);
	
	UpdateVisibilityOfAgencyServices();
EndProcedure

&AtServerNoContext
Procedure FillInPaymentInCurrencyOfFinancialAccountingGroup(Organization, Currency, ForeignCurrencyTransaction, FinancialAccountingGroup, ContractsAreUsed, BusinessOperation)
	
	If Not ContractsAreUsed Then
		ForeignCurrencyTransaction = ARAPAccountingServer.GetPaidInDefaultCurrency();
	EndIf;
	
	FillInFinancialAccountingGroup_(Organization, Currency, BusinessOperation, FinancialAccountingGroup);
	
EndProcedure

&AtClient
Procedure SetVisibilityOfPaymentInCurrency()
	Items.ForeignCurrencyTransaction.Visible = 
		Object.ARAPCurrency <> LocalAccountingCurrency
		Or Object.ForeignCurrencyTransaction;
EndProcedure

&AtServer
Procedure SetParametersForSelectingCashFlowItem()

	ParametersList = New Array;
	
	BusinessTransactionList = New Array;
	BusinessTransactionList.Add(Enums.BusinessTransactions.PaymentToVendor);
	
	CashServer.AddListOfBusinessOperationsToSelectionParameters(
		ParametersList, BusinessTransactionList);
	
	Items.CashFlowItem.ChoiceParameters = New FixedArray(ParametersList);

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
	ElsIf Item.Name = "ARAPCurrency" Then
		ARAPCurrencyOnChange(Item);
	ElsIf Item.Name = "Warehouse" Then
		WarehouseOnChange(Item);
	ElsIf Item.Name = "BusinessOperation" Then
		BusinessOperationOnChange(Item);
	ElsIf Item.Name = "ForeignCurrencyTransaction" Then
		ForeignCurrencyTransactionOnChange(Item);
	ElsIf Item.Name = "ContractsAreUsed" Then
		ContractsAreUsedOnChange(Item);
	ElsIf Item.Name = "ReturnReusablePackage" Then
		ReturnReusablePackageOnChange(Item);
	ElsIf Item.Name = "CalculatePackageReturnDateAccordingToCalendar" Then
		CalculatePackageReturnDateAccordingToCalendarOnChange(Item);
	ElsIf Item.Name = "NotCalculatePackageReturnDateAccordingToCalendar" Then
		CalculatePackageReturnDateAccordingToCalendarOnChange(Item);
	ElsIf Item.Name = "Organization" Then
		OrganizationOnChange(Item);
	ElsIf Item.Name = "Currency" Then
		CurrencyOnChange(Item);
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
	Else
		TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisForm, Command);
	EndIf;
EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure ControlOfNonConsistentChangesHandlePushEvent(Item)
	TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisForm, Item);
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
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure Attachable_Clicking_SetAvailabilityOfItemsByStatusServer(Item)
	
	If TMCommonUseClient.WhenActingOnStatusDependentElement(ThisForm) Then
		Return;
	EndIf;
	
	If StructureOfActionsControlOfNonAgreedChanges.Click.Property(Item.Name) Then
		ControlOfNonConsistentChangesHandlePushEvent(Item);
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

&AtClient
Procedure DeliveryMethodOnChange(Item)
	
	FillInAndSetDeliveryAttributesServer(Item.Name);
	
EndProcedure

&AtServer
Procedure FillInAndSetDeliveryAttributesServer(FormItemName)
	
	GoodsDelivery.FillInDeliveryDetails(Items, FormItemName, Object);
	
EndProcedure

&AtClient
Procedure SupplementDeliveryInformationWithContacts(Command)
	SupplementDeliveryInformationWithContactsServer();
EndProcedure

&AtServer
Procedure SupplementDeliveryInformationWithContactsServer()
	GoodsDelivery.SupplementDeliveryInformationWithContacts(Object);
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
