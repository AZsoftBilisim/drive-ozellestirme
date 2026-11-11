
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);

	If Object.Ref.IsEmpty() Then
		
		If Object.EmployeeResponsible = Catalogs.Users.EmptyRef() Then
			Object.EmployeeResponsible = Users.AuthorizedUser();
		EndIf;
		
		OnCreatReadAtServer();
		
	EndIf;
	
	SetDetailsHeaders();
	Items.SupplierComplaint.ReadOnly = ValueIsFilled(Object.Basis);
	Items.ConductComplaintARAP.Visible = GetFunctionalOption("NewOnlineARAPAccounting");
	
	ARAPAccountingFormWork.FormWhenCreatedOnServer(ThisObject);
	NotifyAboutCreationOfCalculationObject = Parameters.NotifyAboutCreationOfCalculationObject;
	
	// Handler of the "Properties" mechanism
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "AdditionalAttributesPage");
	PropertyManager.OnCreateAtServer(ThisForm, AdditionalParameters);
	
	// StandardSubsystems.Interactions
	Interactions.PrepareNotifications(ThisForm, Parameters);
	// End StandardSubsystems.Interactions
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

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
	
	OnCreatReadAtServer();

	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisForm, CurrentObject);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	Notify("Write_Claim", WriteParameters, Object.Ref);
	
	// Handler of the "Interaction" subsystem
	InteractionsClient.InteractionSubjectAfterWrite(ThisForm,Object,WriteParameters,"CustomerClaims");

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
	
	SetPrivilegedMode(True);
	
	// Let's establish the subject of interaction
	If ValueIsFilled(InteractionBasis) Then
		Interactions.OnWriteSubjectFromForm(
			CurrentObject.Ref, InteractionBasis, Cancel);
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	AvailabilityControl();
	SetVisibilityOfAccountDetails();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtClient
Procedure AdditionalInformationOnChange(Item)
	ClearMarkIncomplete();
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
	
	CurTypeOfContract = Common.ObjectAttributeValue(Object.Contract, "ContractType");
	
	Items.AdditionalInfoPage.Picture = CommonClientServer.CommentPicture(Object.ProcessingResult);
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);

EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Handler of the "Properties" mechanism
	If PropertyManagerClient.ProcessNotifications(ThisForm, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations
	
	If EventName = "Write_ARAPAdjustment" Then
		UpdateTextDocumentsBasedOn();
	EndIf;

EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisForm, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
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
Procedure LongDescStartChoice(Item, ChoiceData, StandardProcessing)
	
	CommonClient.ShowCommentEditingForm(
		Item.EditText,
		ThisObject,
		"Object.ComplaintDescription",
		NStr("vi = 'Mô tả';
			|ru = 'Описание';
			|en = 'Details'; fa = 'جزئیات';
			|it = 'Descrizione';
			|pl = 'Opis';
			|tr = 'Ayrıntılar'"));
	
EndProcedure
	
&AtClient
Procedure CommentStartChoice(Item, ChoiceData, StandardProcessing)
	
	CommonClient.ShowCommentEditingForm(
		Item.EditText,
		ThisObject,
		"Object.Comment",
		NStr("vi = 'Mô tả';
			|ru = 'Описание';
			|en = 'Details'; fa = 'جزئیات';
			|it = 'Descrizione';
			|pl = 'Opis';
			|tr = 'Ayrıntılar'"));
	
EndProcedure

&AtClient
Procedure StatusOnChange(Item)
	
	AvailabilityControl();
	
	If Object.Status = PredefinedValue("Enum.CustomerComplaintStatuses.Fulfilled_")
	                     Or Object.Status = PredefinedValue("Enum.CustomerComplaintStatuses.NotFulfilled_") Then
		
		Object.EndDate = CommonClient.SessionDate();
		ClearMarkIncomplete();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ReasonForIncurrenceOnChange(Item)
	
	AvailabilityControl();
	
EndProcedure

&AtClient
Procedure BasisClick(Item, StandardProcessing)
	
	If ValueIsFilled(Object.Basis) Then
		StandardProcessing = False;
		ShowValue(, Object.Basis);
	EndIf;
	
EndProcedure

&AtClient
Procedure SupplierComplaintOnChange(Item)
	ComplaintToSupplierWhenChangesAreMadeOnServer();
EndProcedure

&AtClient
Procedure ToMakeCalculationsOnClaimsWhenChanging(Item)
	
	SetVisibilityOfAccountDetails();
	If ValueIsFilled(Object.Basis) Then
		FillInBasedOnServer();
	EndIf;
	AccessibilityTextDocumentsBasedOn();
EndProcedure

&AtClient
Procedure CounterpartyOnChange(Item)
	SetContractSelectionParameters();
	UpdateTextDocumentsBasedOn();
EndProcedure

&AtClient
Procedure ContractOnChange(Item)
	AgreementWhenModifiedOnServer();
EndProcedure

&AtClient
Procedure RegistrationDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	RegistrationDateWhenChangeWasMadeOnServer();
EndProcedure

&AtClient
Procedure TextDocumentsBasedOnURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	ClearMessages();
	
	RegistrationParameters = ParametersForRegisteringDebtAdjustmentServer(Object);
	URLProcessingDebtAdjustment(ThisObject, FormattedStringURL,  StandardProcessing, RegistrationParameters);
	
EndProcedure

&AtClient
Procedure PartnerOnChange(Item)
	UpdateTextDocumentsBasedOn();
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	UpdateTextDocumentsBasedOn();
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

// StandardSubsystems.Properties

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure

// End StandardSubsystems.Properties

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ReasonForIncurrence.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ReasonForIncurrence");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ValueList = New ValueList;
	ValueList.Add(Enums.CustomerComplaintStatuses.InProcessing);
	ValueList.Add(Enums.CustomerComplaintStatuses.Fulfilled_);
	ValueList.Add(Enums.CustomerComplaintStatuses.NotFulfilled_);
	ItemFilter.RightValue = ValueList;

	Item.Appearance.SetParameterValue("MarkIncomplete", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.EndDate.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ValueList = New ValueList;
	ValueList.Add(Enums.CustomerComplaintStatuses.Registered1);
	ValueList.Add(Enums.CustomerComplaintStatuses.InProcessing);
	ItemFilter.RightValue = ValueList;

	Item.Appearance.SetParameterValue("MarkIncomplete", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AdditionalInformation.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ValueList = New ValueList;
	ValueList.Add(Enums.CustomerComplaintStatuses.Registered1);
	ValueList.Add(Enums.CustomerComplaintStatuses.InProcessing);
	ItemFilter.RightValue = ValueList;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ProcessingResult");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("MarkIncomplete", False);

EndProcedure

&AtClient
Procedure AvailabilityControl()
	
	ClearMarkIncomplete();	
	Items.EndDate.Enabled = (Object.Status = PredefinedValue("Enum.CustomerComplaintStatuses.Fulfilled_")
	                                      Or Object.Status = PredefinedValue("Enum.CustomerComplaintStatuses.NotFulfilled_"));
	
EndProcedure

&AtClient
Procedure SetVisibilityOfAccountDetails()
	
	Items.AccountInformationPage.Visible = Object.ConductComplaintARAP;
	Items.Sum.Visible = Object.ConductComplaintARAP;
	Items.Organization.Visible = Object.ConductComplaintARAP;
	Items.Counterparty.Visible = Object.ConductComplaintARAP;
	Items.GroupAgreementCurrency.Visible = Object.ConductComplaintARAP;
	Items.LineOfBusiness.Visible = Object.ConductComplaintARAP;
	
EndProcedure

&AtServer
Procedure OnCreatReadAtServer()
	
	CurTypeOfContract = Common.ObjectAttributeValue(Object.Contract, "ContractType");
	
	Items.AdditionalInfoPage.Picture = CommonClientServer.CommentPicture(Object.ProcessingResult);
	SetUpFormUsingBankingDetails();

	UpdateTextDocumentsBasedOn();
	
EndProcedure

&AtServer
Procedure SetContractVisibility()

	Items.GroupAgreementCurrency.Visible = Object.ThisIsClaimToVendor And GetFunctionalOption("UseContractsWithVendors")
		Or Not Object.ThisIsClaimToVendor And GetFunctionalOption("UseCustomerContracts");

EndProcedure

&AtServer
Procedure SetDetailsHeaders()

	PartnersAndCounterparties.HeaderOfPropsDependingOnFOUsePartnersAsCounterparties(
		ThisObject, "PartnersAndContactPersonsPartner", NStr("vi = 'Đối tác';
															|ru = 'Контрагент';
															|en = 'Counterparty'; fa = 'طرف حساب';
															|it = 'Controparte';
															|pl = 'Counterparty';
															|tr = 'Cari hesap'"));
	PartnersAndCounterparties.HeaderOfPropsDependingOnFOUsePartnersAsCounterparties(
		ThisObject, "PartnersAndContactPersonsPartnerSRole", NStr("vi = 'Vai trò của đối tác';
																	|ru = 'Роль контрагента';
																	|en = 'Counterparty role'; fa = 'Counterparty role';
																	|it = 'Ruolo del contraente';
																	|pl = 'Rola kontrahenta';
																	|tr = 'Cari hesap rolü'"));

EndProcedure

&AtServer
Procedure AgreementWhenModifiedOnServer()
	
	If ValueIsFilled(Object.Contract) Then
		Names = "Organization,Counterparty,Partner,ARAPCurrency,LineOfBusiness,FinancialAccountingGroup,ContractType,CentralizedContract";
		Attributes = Common.ObjectAttributesValues(Object.Contract, Names);
		FillPropertyValues(Object,Attributes,,"Organization");
		If Attributes.CentralizedContract And Not ValueIsFilled(Object.Organization)
			Or Not Attributes.CentralizedContract Then
			Object.Organization = Attributes.Organization;
		EndIf;
		Object.Currency = Attributes.ARAPCurrency;
		CurTypeOfContract = Attributes.ContractType;
		Items.Currency.ReadOnly = True;
	Else
		CurTypeOfContract = Undefined;
		Items.Currency.ReadOnly = False;
	EndIf;
	
	SetHFCSelectionParameters();
	
EndProcedure

&AtServer
Procedure ComplaintToSupplierWhenChangesAreMadeOnServer()
	
	Object.FinancialAccountingGroup = Undefined;
	Object.Counterparty = Undefined;
	Object.Contract = Undefined;
	Object.Currency = Undefined;
	CurTypeOfContract = Undefined;
	
	If ValueIsFilled(Object.Partner) Then
		RelationshipWithPartner = Common.ObjectAttributesValues(Object.Partner,"Client,Vendor");
		OnlyClient = RelationshipWithPartner.Client And Not RelationshipWithPartner.Vendor;
		VendorOnly = RelationshipWithPartner.Vendor And Not RelationshipWithPartner.Client;
		If OnlyClient And Object.ThisIsClaimToVendor
			Or VendorOnly And Not Object.ThisIsClaimToVendor Then
			Object.Partner = Undefined;
		EndIf;
	EndIf;
	
	SetUpFormUsingBankingDetails();
	
EndProcedure

&AtServer
Procedure SetUpFormUsingBankingDetails()
	

	Items.Partner.Title = ?(Object.ThisIsClaimToVendor, NStr("vi = 'Nhà cung cấp';
															|ru = 'Поставщик';
															|en = 'Vendor'; fa = 'تأمین‌کننده';
															|it = 'Fornitore';
															|pl = 'Dostawca';
															|tr = 'Tedarikçi'"), NStr("vi = 'Khách hàng';
																					|ru = 'Клиент';
																					|en = 'Customer'; fa = 'مشتری';
																					|it = 'Cliente';
																					|pl = 'Klient';
																					|tr = 'Müşteri'"));
	
	If Not GetFunctionalOption("UseMultipleCompanies") 
			And Not ValueIsFilled(Object.Organization) Then
		Object.Organization = Catalogs.Companies.DefaultCompany();
	EndIf;
	SetNameHint();
	SetPartnerSelectionParameters();
	SetContractVisibility();
	SetContractSelectionParameters();
	SetHFCSelectionParameters();
	SetLbSelectionParameters();
	Items.GuiltyBusinessUnit.Visible = Not Object.ThisIsClaimToVendor;
	Items.GuiltyEmployee.Visible = Not Object.ThisIsClaimToVendor;
	Items.Currency.ReadOnly = ValueIsFilled(Object.Contract);
	
EndProcedure

&AtServer
Procedure AccessibilityTextDocumentsBasedOn()  
	RegistrationParameters = Catalogs.Complaints.DebtAdjustmentsIntroducedOnBasisOf(Catalogs.Complaints.ParametersForRegisteringDebtAdjustments(Object));
	ThereIsRightToViewDocumentOnBasisOf = AccessRight("View", Metadata.Documents.ARAPAdjustment);
	ThereIsRightToInteractivelyAddDocumentOnBasisOf = RegistrationParameters.ThereIsRightToInteractivelyAddDocumentOnBasisOf;
	VisibilityTextDocumentsBasedOn = Object.ConductComplaintARAP And ThereIsRightToViewDocumentOnBasisOf;
	AccessibilityTextDocumentsBasedOn = ThereIsRightToViewDocumentOnBasisOf And ThereIsRightToInteractivelyAddDocumentOnBasisOf;
	Items.TextDocumentsBasedOn.Visible = VisibilityTextDocumentsBasedOn;
	Items.TextDocumentsBasedOn.Enabled = AccessibilityTextDocumentsBasedOn;
EndProcedure

&AtServer
Procedure RegistrationDateWhenChangeWasMadeOnServer()
	SetNameHint();
EndProcedure

&AtServer
Procedure SetContractSelectionParameters()
	
	ContractType = New Array;
	If Object.ThisIsClaimToVendor Then
		ContractType.Add(Enums.ContractTypes.WithVendor);
		ContractType.Add(Enums.ContractTypes.PurchaseEAEU);
		ContractType.Add(Enums.ContractTypes.Import);
		ContractType.Add(Enums.ContractTypes.TransferToTolling2_5);
		ContractType.Add(Enums.ContractTypes.SubcontractingToTheEAEUCountries);
		ContractType.Add(Enums.ContractTypes.WithConsignee);
		ContractType.Add(Enums.ContractTypes.TransferToCustody);
		ContractType.Add(Enums.ContractTypes.CustomerInvoiceOutsourcedSale);
	Else
		ContractType.Add(Enums.ContractTypes.WithCustomer);
		ContractType.Add(Enums.ContractTypes.WithConsignor);
		ContractType.Add(Enums.ContractTypes.ReceiptForTolling2_5);
		ContractType.Add(Enums.ContractTypes.ReceivingForCustody);
		ContractType.Add(Enums.ContractTypes.CustomerInvoiceOutsourcedSale);
	EndIf;
	
	// Set the selection parameter
	ParametersArray = New Array;
	ParametersArray.Add(New ChoiceParameter("Filter.ContractType", ContractType));
	ParametersArray.Add(New ChoiceParameter("Filter.DeletionMark",False));
	Items.Contract.ChoiceParameters = New FixedArray(ParametersArray);
	
EndProcedure

&AtServer
Procedure SetHFCSelectionParameters()
	
	ParametersArray = New Array;
	
	If CurTypeOfContract = Enums.ContractTypes.WithVendor
		Or CurTypeOfContract = Enums.ContractTypes.PurchaseEAEU
		Or CurTypeOfContract = Enums.ContractTypes.Import
		Or CurTypeOfContract = Enums.ContractTypes.TransferToTolling
		Or CurTypeOfContract = Enums.ContractTypes.WithConsignee
		Or CurTypeOfContract = Enums.ContractTypes.TransferToCustody
		Or CurTypeOfContract = Enums.ContractTypes.CustomerInvoiceOutsourcedSale Then
		ParametersArray.Add(New ChoiceParameter("Filter.VendorsARAPAccounting", True));
	ElsIf CurTypeOfContract = Enums.ContractTypes.TransferToTolling2_5 Then
		ParametersArray.Add(New ChoiceParameter("Filter.SettlementsWithSubcontractor", True));
	ElsIf CurTypeOfContract = Enums.ContractTypes.WithCustomer
		Or CurTypeOfContract = Enums.ContractTypes.WithConsignor
		Or CurTypeOfContract = Enums.ContractTypes.ReceiptForTolling
		Or CurTypeOfContract = Enums.ContractTypes.ReceivingForCustody Then
		ParametersArray.Add(New ChoiceParameter("Filter.CustomersARAPAccounting", True));
	ElsIf CurTypeOfContract = Enums.ContractTypes.ReceiptForTolling2_5 Then
		ParametersArray.Add(New ChoiceParameter("Filter.ProvidersARAP", True));
	ElsIf Object.ThisIsClaimToVendor Then
		ParametersArray.Add(New ChoiceParameter("Filter.VendorsARAPAccounting", True));
	Else
		ParametersArray.Add(New ChoiceParameter("Filter.CustomersARAPAccounting", True));
	EndIf;
	
	Items.FinancialAccountingGroup.ChoiceParameters = New FixedArray(ParametersArray);
	
EndProcedure

&AtServer
Procedure SetNameHint()
	
	Items.Description.InputHint = Catalogs.Complaints.AutoDescription(Object);
		
EndProcedure

&AtServer
Procedure SetPartnerSelectionParameters()
	
	ParametersArray = New Array;
	ChoiceParameter = New ChoiceParameter(?(Object.ThisIsClaimToVendor, "Filter.Vendor", "Filter.Client"), True);
	ParametersArray.Add(ChoiceParameter);
	Items.Partner.ChoiceParameters = New FixedArray(ParametersArray);
	
EndProcedure

&AtServer
Procedure SetLbSelectionParameters()
	
	ParametersArray = New Array;
	ChoiceParameter = New ChoiceParameter(?(Object.ThisIsClaimToVendor, "Filter.VendorARAP", "Filter.IncomeAccounting"), True);
	ParametersArray.Add(ChoiceParameter);
	Items.LineOfBusiness.ChoiceParameters = New FixedArray(ParametersArray);
	
EndProcedure

&AtServer
Procedure FillInBasedOnServer()
	
	DocumentObject_ = FormAttributeToValue("Object");
	DocumentObject_.Fill(Object.Basis);
	ValueToFormAttribute(DocumentObject_, "Object");
	
EndProcedure

&AtServerNoContext
Function ParametersForRegisteringDebtAdjustmentServer(Val Object)
	
	Return Catalogs.Complaints.ParametersForRegisteringDebtAdjustments(Object);
	
EndFunction

&AtClient
Procedure URLProcessingDebtAdjustment(Form, Var_URL, StandardProcessing, RegistrationParameters)
	
	If Var_URL = "OpenListOfDebtAdjustments" Then
		StandardProcessing = False;
		StructureFilter = New Structure();
		StructureFilter.Insert("Ref", DebtAdjustmentsIntroducedOnBasisOf(RegistrationParameters.Ref));
		FormParameters = New Structure("Filter", StructureFilter);
		OpenForm("Document.ARAPAdjustment.ListForm", FormParameters, Form);
	ElsIf Var_URL = "OpenDebtAdjustment" Then
		StandardProcessing = False;
		Var_Key = DebtAdjustmentInputedOnBasis(
				RegistrationParameters.Ref, RegistrationParameters.Organization);
		FormParameters = New Structure("Key", Var_Key);
		OpenForm("Document.ARAPAdjustment.ObjectForm", FormParameters, Form);
	ElsIf Var_URL = "IntroduceNewDebtAdjustment" Then
		StandardProcessing = False;
		EnterDebtAdjustment(Form, RegistrationParameters);
	EndIf;
	
EndProcedure

&AtServer
Function DebtAdjustmentsIntroducedOnBasisOf(Ref)
	Return Documents.ARAPAdjustment.DebtAdjustmentsBasedOn(Ref).UnloadColumn("Ref");
EndFunction

&AtServer
Function DebtAdjustmentInputedOnBasis(Ref, Organization)
	Return Documents.ARAPAdjustment.AdjustmentOfDebtOnBasisOf(Ref, Organization);
EndFunction

&AtServer
Procedure UpdateTextDocumentsBasedOn()
	
	TextsFieldsDocumentsBasedOn.Clear();
	
	UpdateTextOfDebtAdjustment();
	TMCommonUseClientServer.UpdateTextDocumentsBasedOn(ThisObject);
	AccessibilityTextDocumentsBasedOn();
EndProcedure

&AtServer
Procedure UpdateTextOfDebtAdjustment()
	
	RegistrationParameters = Catalogs.Complaints.ParametersForRegisteringDebtAdjustments(Object);
	DebtAdjustmentBasedOn = Catalogs.Complaints.DebtAdjustmentsIntroducedOnBasisOf(RegistrationParameters);
	
	TextOfDebtAdjustment = Catalogs.Complaints.ToFormPresentationOfCommandsForFormationOfDebtAdjustmentBasedOn(Object.Ref, DebtAdjustmentBasedOn);
	
	TextsFieldsDocumentsBasedOn.Add(TextOfDebtAdjustment);
	
EndProcedure

&AtClient
Procedure EnterDebtAdjustment(Form, RegistrationParameters)
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("RegistrationParameters",  RegistrationParameters);
	AdditionalParameters.Insert("OpenExistingOne", False);
	AdditionalParameters.Insert("Form",                 Form);
	
	Notification = New CallbackDescription("IntroduceDebtAdjustmentEnd", ThisObject, AdditionalParameters);
	RunCallback(Notification, Form.Object.Ref);
	
EndProcedure

&AtClient
Procedure IntroduceDebtAdjustmentEnd(Result, AdditionalParameters) Export
	
	RegistrationParameters = AdditionalParameters.RegistrationParameters;
		
	If ValueIsFilled(RegistrationParameters.Ref) Then
		Claim = RegistrationParameters.Ref;
	Else
		Claim = AdditionalParameters.Form.Object.Ref;
	EndIf;
		
	OpeningParameters = New Structure;
	OpeningParameters.Insert("Claim", 		Claim);
	OpeningParameters.Insert("Organization",       RegistrationParameters.Organization);
	OpeningParameters.Insert("Counterparty",        RegistrationParameters.Counterparty);
	
	FormParameters = New Structure("Basis, DocumentBasis",OpeningParameters, Claim);
	OpenForm("Document.ARAPAdjustment.ObjectForm", FormParameters, AdditionalParameters.Form);
	
EndProcedure


#Region StandardSubsystems

// StandardSubsystems.Properties
&AtServer
Procedure UpdateAdditionalAttributesItems()
	PropertyManager.UpdateAdditionalAttributesItems(ThisObject);
EndProcedure

&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure
// End StandardSubsystems.Properties

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
	If Item.Name = "sh_ShamsiInput_RegistrationDate" Then
		RegistrationDateOnChange(Items.RegistrationDate);
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
