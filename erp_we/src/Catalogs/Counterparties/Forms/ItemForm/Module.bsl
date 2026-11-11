#Region Variables
#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If GetFunctionalOption("UsePartnersAsCounterparties") Then
		Cancel = True;
		Return;
	EndIf;
	
	SetConditionalAppearance();

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	If Parameters.Property("BasisSeparateCounterparty") Then
		BasedOnASeparateCounterparty = True;
	EndIf;
	ColorOfHyperlink = StyleColors.HyperlinkColor;
	
	
	// Handler of the "Versioning of objects" mechanism
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	// Handler of the "Properties" subsystem
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	
	// StandardSubsystems.ContactInformation
	AdditionalCIParameters = ContactsManager.ContactInformationParameters();
	AdditionalCIParameters.Insert("ItemForPlacementName", "ContactInformationGroup");
	AdditionalCIParameters.Insert("CITitleLocation", FormItemTitleLocation.Left);
	ContactsManager.OnCreateAtServer(ThisObject, Object, AdditionalCIParameters);
	// End StandardSubsystems.ContactInformation
	
	If Object.Ref.IsEmpty() Then
		OnReadCreateAtServer();
		FillInUsingBaseDocument(Parameters);
	EndIf;
	
	SetParametersForSelectingHeadCounterparty();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	
		
	
	
	If UsePriceManagementSystem25 Then
		FillInDescriptionOfCurrentParameters();
	EndIf;
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	NationalLanguageSupportServer.OnCreateAtServer(ThisObject, Object);
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	OnReadCreateAtServer();
	
	// StandardSubsystems.ContactInformation
	ContactsManager.OnReadAtServer(ThisForm, CurrentObject);
	// End StandardSubsystems.ContactInformation
	
	PropertyManager.OnReadAtServer(ThisForm, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	NationalLanguageSupportServer.OnReadAtServer(ThisObject, CurrentObject);
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisForm, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.ContactInformation
	ContactsManager.FillCheckProcessingAtServer(ThisForm, Object, Cancel);
	// End StandardSubsystems.ContactInformation
	
	PartnersAndCounterpartiesLocalization.ProcessingFillCheckOnCounterpartyServer(Cancel, CheckedAttributes, ThisForm);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// StandardSubsystems.ContactInformation
	ContactsManager.BeforeWriteAtServer(ThisForm, CurrentObject);
	// End StandardSubsystems.ContactInformation
	
	// Handler of the "Properties" subsystem
	PropertyManager.BeforeWriteAtServer(ThisForm, CurrentObject);
	
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	NationalLanguageSupportServer.BeforeWriteAtServer(CurrentObject);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	
EndProcedure

&AtClient
Procedure OnClose()
	
	If BasedOnASeparateCounterparty And ValueIsFilled(Object.Ref) Then
		NotifyChoice(Object.Ref);
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	PartnersAndCounterpartiesLocalizationClient.BeforeRecordingCounterparty(Cancel, WriteParameters, ThisForm);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	Var Counterparty;
	
	If StrFind(EventName, "Record_") > 0 Then
		If ValueIsFilled(Parameter) And TypeOf(Parameter) = Type("Structure") Then
			
			Parameter.Property("Counterparty", Counterparty);
			If ValueIsFilled(Counterparty)
				And (Counterparty = Object.Ref) Then
					
					AvailableRegisters = PartnersAndCounterpartiesLocalizationClientServer.AvailableRegistersOfTaxesAccountingPoliciesOfCounterparties();
					RowsArray = StrSplit(EventName, "_", False);
					If RowsArray.Count() > 1 Then
						RegisterName = RowsArray[1];
						If AvailableRegisters.Find(RegisterName) <> Undefined Then
							FillInDescriptionOfCurrentParameters(RegisterName);
						EndIf;
					EndIf;
					
			EndIf;
		EndIf;
	EndIf;
	
	// Subsystem "Properties"
	If PropertyManagerClient.ProcessNotifications(ThisForm, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	
	
	
	If EventName = "ChangingContactInformation_WhenFillingInData" Then
		
		UpdateContactInformation(New Structure("UpdateConextMenu", True));
		
	EndIf;
		
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	SetFormHeader();
	AvailabilityControl(ThisForm);
	ConfigureNavigationBar();
	SetParametersForSelectingHeadCounterparty();
	
	SparkleRecordingParameters = WriteParameters;
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
	NationalLanguageSupportServer.OnReadAtServer(ThisObject, CurrentObject);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CounterpartyKindOnChange(Item)
	
	Attachable_OnChangeAttribute(Item);
	
	If IsBlankString(CounterpartyKind) Then
		
		Object.LegalEntityIndividual = PredefinedValue("Enum.LegalEntityIndividual.EmptyRef");
		Object.BranchOffice = False;
		If Object.MainCounterparty <> Object.Ref Then
			Object.MainCounterparty = Undefined;
		EndIf;
		
	ElsIf CounterpartyKind = "BranchOffice" Then
		
		Object.LegalEntityIndividual = PredefinedValue("Enum.LegalEntityIndividual.Entity");
		Object.BranchOffice = True;
		
		If Object.MainCounterparty = Object.Ref Then
			Object.MainCounterparty = Undefined;
		EndIf;
		
	Else
		LegalEntityLine = "Enum.LegalEntityIndividual." + CounterpartyKind;
		Object.LegalEntityIndividual = PredefinedValue(LegalEntityLine);
		Object.BranchOffice = False;
		
		If Object.MainCounterparty <> Object.Ref Then
			Object.MainCounterparty = Undefined;
		EndIf;
		
	EndIf;
	
	
	AvailabilityControl(ThisForm);
	ClearMarkIncomplete();
	
	
EndProcedure

&AtClient
Procedure AbbreviatedDescriptionOnChange(Item)
	Attachable_OnChangeAttribute(Item);
	PartnersAndCounterpartiesClient.AbbreviatedLegalEntityNameWhenChanged(Object.Description, Object.DescriptionFull);
EndProcedure

&AtClient
Procedure PartnerOnChange(Item)
	
	AvailabilityControl(ThisForm);
	
EndProcedure

&AtClient
Procedure MainCounterpartyOnChange(Item)
	
	Attachable_OnChangeAttribute(Item);
	ClearMarkIncomplete();
	
EndProcedure

&AtClient
Procedure GoToNameHistoryURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	If FormattedStringURL = "NameHistory" Then
		
		FormParameters = New Structure;
		FormParameters.Insert("CurFullName", Object.DescriptionFull);
		FormParameters.Insert("NameHistory",       Object.NameHistory);
		FormParameters.Insert("ReadOnly",            ReadOnly);
		FormParameters.Insert("LegalEntityIndividual",                 Object.LegalEntityIndividual);
		
		ClosingNotification1 = New CallbackDescription("HistoryOfTitlesAfterClosing", ThisObject);
		OpenForm("Catalog.Counterparties.Form.EditNameHistory", FormParameters, ThisObject,,,,ClosingNotification1);

	EndIf;
	
EndProcedure

&AtClient
Procedure TINOnChange(Item)
	
	PartnersAndCounterpartiesLocalizationClient.CheckTIN_(ThisObject);
	
	
	ClearMarkIncomplete();
	
EndProcedure

&AtClient
Procedure CRTROnChange(Item)
	
	Attachable_OnChangeAttribute(Item);
	
EndProcedure

&AtClient
Procedure OGRNOnChange(Item)
	
	PartnersAndCounterpartiesLocalizationClient.CheckOGRN(ThisObject);
	
EndProcedure

&AtClient
Procedure OGRNIEOnChange(Item)
	
	PartnersAndCounterpartiesLocalizationClient.CheckOGRN(ThisObject);
	
EndProcedure

&AtClient
Procedure RegistrationCountryOnChange(Item)  
	
	PartnersAndCounterpartiesLocalizationClientServer.ManagingAvailabilityOfNameInTranscription(ThisForm);

EndProcedure

&AtClient
Procedure DecorationSparkriskieIndexesURLProcessing(Item, FormattedStringURL, StandardProcessing)
	Return;
EndProcedure

#Region UniversalEventHandlers

&AtClient
Procedure Attachable_TextEditEnd(Item, Text, ChoiceData, Var_Parameters, StandardProcessing)
	
	PartnersAndCounterpartiesLocalizationClient.EndOfTextInput_Counterparty(Item,
		Text,
		ChoiceData,
		Var_Parameters,
		StandardProcessing,
		ThisForm);
		
EndProcedure

&AtClient
Procedure Attachable_OnChangeAttribute(Item)
	PartnersAndCounterpartiesLocalizationClient.WhenChangingBankingDetails_Counterparty(
		Item,
		ThisForm);
EndProcedure

&AtClient
Procedure Attachable_ProcessingTheFormSNavigationLink(Item, FormattedStringURL, StandardProcessing)
	
	PartnersAndCounterpartiesLocalizationClient.ProcessingNavigationLinkOfForm_Counterparty(Item,
		FormattedStringURL,
		StandardProcessing,
		ThisForm);
	
EndProcedure

&AtClient
Procedure AtEndOfChangingLocalizationDetails(TagName, AdditionalParameters) Export
	
	If AdditionalParameters.ServerCallRequired_ Then
		AtEndOfChangingLocalizationDetailsOnServer(TagName, AdditionalParameters.ProcessingParameters);
	EndIf;
	
	If TagName = "MainCounterparty" Then
		MainCounterpartyOnChange(Items.MainCounterparty);
	EndIf;
	
EndProcedure

&AtServer
Procedure AtEndOfChangingLocalizationDetailsOnServer(TagName, ProcessingParameters)
	
	PartnersAndCounterpartiesLocalization.AtEndOfChangeOfProps_Counterparty(TagName, ThisForm);
	
EndProcedure

&AtClient
Procedure Attachable_Opening(Item, StandardProcessing)
	
	NationalLanguageSupportClient.OnOpen(ThisObject, Object, Item, StandardProcessing);
	
EndProcedure

#EndRegion

#EndRegion

#Region FormTableItemsEventHandlersContactInformation

// StandardSubsystems.ContactInformation
&AtClient
Procedure Attachable_ContactInformationOnChange(Item)
	
	ContactsManagerClient.ToBeginUpdate(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure Attachable_ContactInformationStartChoice(Item, ChoiceData, StandardProcessing)
	
	OpeningParameters = New Structure("Country", Object.RegistrationCountry);
	
	Filter = New Structure("AttributeName", Item.Name);
	Rows = ThisObject.ContactInformationAdditionalAttributesDetails.FindRows(Filter); // SeeContactsManagerClientServer.DescriptionOfTheContactInformationOnTheForm
	RowData = ?(Rows.Count() = 0, Undefined, Rows[0]);
	If RowData <> Undefined Then
		If RowData.Kind = PredefinedValue("Catalog.ContactInformationKinds.InternationalAddressOfCounterparty") Then
			OpeningParameters.Insert("AllowAddressInputInFreeForm", False);
		EndIf;
		If (RowData.Kind = PredefinedValue("Catalog.ContactInformationKinds.LegalAddressOfCounterparty")
			Or RowData.Kind = PredefinedValue("Catalog.ContactInformationKinds.ActualDataCounterpartyAddress")) Then
			OpeningParameters.Insert("Country", Object.RegistrationCountry);
		EndIf;
	EndIf;
	
	ContactsManagerClient.StartSelection(ThisObject, Item, , StandardProcessing, OpeningParameters);
	
EndProcedure

&AtClient
Procedure Attachable_ContactInformationOnClick(Item, StandardProcessing)
	
	ContactsManagerClient.StartSelection(ThisObject, Item, , StandardProcessing);
	
EndProcedure
&AtClient
Procedure Attachable_ContactInformationClearing(Item, StandardProcessing)
	
	ContactsManagerClient.StartClearing(ThisObject, Item.Name);
	
EndProcedure

&AtClient
Procedure Attachable_ContactInformationExecuteCommand(Command)
	
	ContactsManagerClient.StartCommandExecution(ThisObject, Command.Name);
	
EndProcedure

&AtClient
Procedure Attachable_ContactInformationAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	ContactsManagerClient.AutoCompleteAddress(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing);
	
EndProcedure

&AtClient
Procedure Attachable_ContactInformationChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	ContactsManagerClient.ChoiceProcessing(ThisObject, ValueSelected, Item.Name, StandardProcessing);
	
EndProcedure

&AtClient
Procedure Attachable_ContactInformationURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	ContactsManagerClient.StartURLProcessing(ThisObject, Item, FormattedStringURL, StandardProcessing);
	
EndProcedure

&AtClient
Procedure Attachable_ContinueContactInformationUpdate(Result, AdditionalParameters) Export
	
	UpdateContactInformation(Result);
	
EndProcedure

&AtServer
Procedure UpdateContactInformation(Result)
	
	ContactsManager.UpdateContactInformation(ThisObject, Object, Result);
	
EndProcedure
// End StandardSubsystems.ContactInformation

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteLocalizationCommand(Command)
	
	PartnersAndCounterpartiesLocalizationClient.ExecuteLocalizationCommand(Command, ThisForm);
	
EndProcedure

&AtClient
Procedure ContinueRunningLocalizationCommand(CommandName, AdditionalParameters) Export
	
	If AdditionalParameters.ServerCallRequired_ Then
		ContinueRunningLocalizationCommandOnServer(CommandName, AdditionalParameters.ProcessingParameters);
	EndIf;
	
EndProcedure

&AtServer
Procedure ContinueRunningLocalizationCommandOnServer(CommandName, ProcessingParameters)
	
	PartnersAndCounterpartiesLocalization.ExecuteLocalizationCommand(ThisForm, CommandName, ProcessingParameters);
	
EndProcedure

// StandardSubsystems.Properties
&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
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


&AtClient
Procedure FillInByTIN(Command)
	Attachable_ExecuteLocalizationCommand(Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	PartnersAndCounterpartiesLocalization.EstablishConditionalAppearanceCounterparty(ThisForm);
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	If GetFunctionalOption("UseMultiCountryAccounting") Then
		If Object.LegalEntityIndividual <> Enums.LegalEntityIndividual.LegalEntityNonResident Then
			LegalEntityNonResident = Items.CounterpartyKind.ChoiceList.FindByValue("LegalEntityNonResident");
			If LegalEntityNonResident <> Undefined Then
				Items.CounterpartyKind.ChoiceList.Delete(LegalEntityNonResident);
			EndIf;
		EndIf;
	EndIf;
	
	PartnersAndCounterpartiesLocalization.WhenReadingCreatingOnServerCounterparty(ThisForm);
	
	ObjectChangeRight = AccessRight("Update", Metadata.Catalogs.Counterparties);
	SimplifiedInputAvailable = PartnersAndCounterparties.SimplifiedInputAvailable() Or ReadOnly;
	SetFormHeader();
	
	If Object.BranchOffice Then
		CounterpartyKind = "BranchOffice";
	ElsIf ValueIsFilled(Object.LegalEntityIndividual) Then
		CounterpartyKind = Common.EnumerationValueName(Object.LegalEntityIndividual);
	EndIf;
	
	If TMCommonUseClientServer.AnExternalUserIsAuthorized() Then
		If Object.BranchOffice Then
			ReadOnly = True;
		Else
			Items.CounterpartyKind.ChoiceList.Delete(Items.CounterpartyKind.ChoiceList.FindByValue("BranchOffice"));
		EndIf;
	EndIf;
	
	UsePriceManagementSystem25 = PriceManagementSystemServerCall.UsePriceManagementSystem25();
	
	AvailabilityControl(ThisForm);
	ConfigureNavigationBar();

EndProcedure

&AtServer
Procedure ConfigureNavigationBar()

	SettingsStructure = New Structure;
	SettingsStructure.Insert("UseIndividualCounterpartyData", 
	                           Object.LegalEntityIndividual = Enums.LegalEntityIndividual.Person Or Object.LegalEntityIndividual = Enums.LegalEntityIndividual.IndividualEntrepreneur);
	
	TMCommonUse.ConfigureFormByParameters(ThisForm, SettingsStructure);

EndProcedure

&AtServer
Procedure SetFormHeader()
	If Object.Ref.IsEmpty() Then
		Title = NStr("vi = 'Đối tác (tạo mới)';
					|ru = 'Контрагент (создание)';
					|en = 'Counterparty (Create)'; fa = 'Counterparty (Create)';
					|it = 'Contraente (creazione)';
					|pl = 'Kontrahent (tworzenie)';
					|tr = 'Cari hesap (oluşturma)'");
	Else
		Title = Object.Description + " " + NStr("ru = '(Контрагент (юридическое или физическое лицо)';
												|vi = 'Counterparty (business or person)';
												|en = 'Counterparty (business or person)'; fa = 'Counterparty (business or person)';
												|it = 'Counterparty (business or person)';
												|pl = 'Counterparty (business or person)';
												|tr = '(Cari hesap (tüzel veya gerçek kişi)'");
	EndIf;
EndProcedure

&AtServer
Procedure FillInUsingBaseDocument(Var_Parameters)
	If Var_Parameters.Property("Basis") And TypeOf(Var_Parameters.Basis) = Type("Structure") Then
		
		If Var_Parameters.Basis.Property("EppartnerSAddress") And ValueIsFilled(Var_Parameters.Basis.EppartnerSAddress) Then
			StructureOfData = New Structure;
			StructureOfData.Insert("Presentation", Var_Parameters.Basis.EppartnerSAddress);
			StructureOfData.Insert("ContactInformation", "");
			PartnersAndCounterparties.FillInContactInformationElement(ThisObject,
			                                                          PredefinedValue("Catalog.ContactInformationKinds.EmailCounterparty_"),
			                                                          StructureOfData);
		EndIf;
		
		If Var_Parameters.Basis.Property("NameAbbreviated") And ValueIsFilled(Var_Parameters.Basis.NameAbbreviated) Then
			Object.DescriptionFull = Var_Parameters.Basis.NameAbbreviated;
		EndIf;
		
		If Var_Parameters.Basis.Property("AddressPresentation") And ValueIsFilled(Var_Parameters.Basis.AddressPresentation) Then
			StructureOfData = New Structure;
			StructureOfData.Insert("Presentation", Var_Parameters.Basis.AddressPresentation);
			StructureOfData.Insert("ContactInformation", "");
			If Var_Parameters.Basis.Property("Address") Then
				StructureOfData.Insert("ContactInformation", Var_Parameters.Basis.Address);
			EndIf;
			PartnersAndCounterparties.FillInContactInformationElement(ThisObject,
				                                                          PredefinedValue("Catalog.ContactInformationKinds.ActualDataCounterpartyAddress"),
				                                                          StructureOfData);
		EndIf;
		
	EndIf;
		
EndProcedure

&AtClientAtServerNoContext
Procedure AvailabilityControl(Form)
	
	PartnersAndCounterpartiesLocalizationClientServer.ManagingElementsOfLegalDetails(Form);
	PartnersAndCounterpartiesLocalizationClientServer.ManagingCounterpartyAvailability(Form);
	PartnersAndCounterpartiesLocalizationClientServer.ManagingAvailabilityOfNameInTranscription(Form);
	PartnersAndCounterpartiesLocalizationClientServer.ManagingVisibilityOfCommitteeSVATAccountingSettings(Form);
	
	PartnersAndCounterpartiesLocalizationClientServer.UpdateTitleHistoryLines(Form.Object.NameHistory,
		Form.GoToNameHistory,
		Form.ColorOfHyperlink);
	Form.Items.AbbreviatedDescription.ReadOnly = Form.Object.NameHistory.Count() > 1;
	
	Form.Items.Partner.Visible = Not TMCommonUseClientServer.AnExternalUserIsAuthorized();
	
EndProcedure

&AtServer
Procedure SetParametersForSelectingHeadCounterparty()
	
	ParametersForSelectingHeadCounterparty = New Array;
	For Each ChoiceParameter In Items.MainCounterparty.ChoiceParameters Do
		
		ParametersForSelectingHeadCounterparty.Add(ChoiceParameter);
		
	EndDo;
	
	ParametersForSelectingHeadCounterparty.Add(New ChoiceParameter("ExcludingCounterparty", Object.Ref));
	Items.MainCounterparty.ChoiceParameters = New FixedArray(ParametersForSelectingHeadCounterparty);
	
EndProcedure

#Region PeriodicDetails

&AtClient
Procedure HistoryOfTitlesAfterClosing(Result, AdditionalParameters) Export

	ClearMessages();
	
	If TypeOf(Result) = Type("Structure")
		And Result.Property("NameHistory") Then
		
		Modified = True;
		NewHistoryOfNames = Result.NameHistory;
		NewHistoryOfNames.Sort("Period");
	
		Object.NameHistory.Clear();
		If NewHistoryOfNames.Count() > 1 Then
			For Each HistoryRow In NewHistoryOfNames Do
				RecordingHistory = Object.NameHistory.Add();
				FillPropertyValues(RecordingHistory, HistoryRow);
			EndDo;
		EndIf;
		
		NewCurName = NewHistoryOfNames[NewHistoryOfNames.Count()-1].NameAbbreviated;
		
		If NewCurName <> Object.DescriptionFull Then
			
			Object.DescriptionFull = NewCurName;
			
		EndIf;
		
		AvailabilityControl(ThisForm);
		
	EndIf;

EndProcedure

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

&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisForm);
	
EndProcedure
// End StandardSubsystems.Properties

#Region VerificationOfCounterparties

&AtClient
Procedure ValidateCounterparty(Command)
	
	
EndProcedure

#EndRegion

&AtServer
Procedure FillInDescriptionOfCurrentParameters(RegisterName = "")
	
	PartnersAndCounterpartiesLocalization.FillInDescriptionOfCurrentCounterpartyParameters(ThisObject, Object.Ref, RegisterName);
	
EndProcedure

#EndRegion

#Region Localization

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem




#EndRegion
