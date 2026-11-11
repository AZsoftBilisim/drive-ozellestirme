#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	LargestTaxpayerStorageId = New UUID();

	If Parameters.Property("FillingValues") And Parameters.FillingValues.Property("CompanyType") Then
		CompanyType = Parameters.FillingValues.CompanyType;
	ElsIf Object.LegalEntityIndividual = Enums.LegalEntityIndividual.Entity
		And Not Object.BranchOffice Then
		CompanyType = "BusinessEntity";
	ElsIf Object.LegalEntityIndividual = Enums.LegalEntityIndividual.Entity
		And Object.BranchOffice Then
		CompanyType = "BranchOffice";
	ElsIf Object.LegalEntityIndividual = Enums.LegalEntityIndividual.IndividualEntrepreneur Then 
		CompanyType = "IndividualEntrepreneur";
	Else Raise NStr("vi = 'Không thể xác định dạng doanh nghiệp. Hãy liên hệ với người quản trị.';
					|ru = 'Невозможно определить вид организации. Обратитесь к администратору.';
					|en = 'Cannot determine company kind. Please contact the administrator.'; fa = 'Cannot determine company kind. Please contact the administrator.';
					|it = 'Impossibile determinare il tipo dell''organizzazione. Contattare l''amministratore.';
					|pl = 'Nie można określić rodzaju firmy. Skontaktuj się z administratorem.';
					|tr = 'İş yeri türü tanımlanamadı. Yöneticiyle iletişime geçin.'");
	EndIf;
	
	FillInDetailsOfParentOrganization();
	DataSelectionFormIsOpened = False;

	ManagingFormOnServer();
	
	// Setting up a list of parent organizations to select from
	Items.ParentCompany.ChoiceList.LoadValues(ParentOrganizationsOfSeparateDivision());
	
	// Exclude the editable organization from the list of parent organizations
	If Parameters.Key.IsEmpty() Then
		CurOrganizationElement	= Items.ParentCompany.ChoiceList.FindByValue(Object.Ref);
		If CurOrganizationElement <> Undefined Then
			Items.ParentCompany.ChoiceList.Delete(CurOrganizationElement);
		EndIf;
	EndIf;
	LogoAddress 			= ?(Object.Logo.IsEmpty(), 			"", ImageNavigationLink(Object.Logo, UUID));
	FacsimileStampAddress = ?(Object.FacsimileStamp.IsEmpty(), "", ImageNavigationLink(Object.FacsimileStamp, UUID));
	
	BaseVersion = GetFunctionalOption("BaseVersion");
	
	Items.GroupRightSideOfTheLegalEntityCodes.Visible = Not BaseVersion;
	Items.RightSideOfTheIndividualEntrepreneurValueTitles.Visible = Not BaseVersion;
	
	ManagementCompany = Object.Ref = Catalogs.Companies.ManagementCompany;
	Items.CompanyType.Visible = Not ManagementCompany;
	If ManagementCompany Then
		Items.LocalAccountingCurrency.Title = NStr("vi = 'Tiền tệ cơ sở';
													|ru = 'Базовая валюта';
													|en = 'Base currency'; fa = 'ارز پایه';
													|it = 'Valuta di riferimento';
													|pl = 'Waluta podstawowa';
													|tr = 'Temel para birimi'");
	EndIf;
	
	If AccessRight("InteractiveInsert", Metadata.Catalogs.Companies) Then
		Items.FormCopy.Visible = Not BaseVersion;
	EndIf;
	
	NameOfIndividual = GetIndividualSFullName(Object.IndividualEntrepreneur);
	
	IndividualEntrepreneurSFullName	= StringFunctionsClientServer.SubstituteParametersToString("%1 %2 %3",
		NameOfIndividual.LastName, NameOfIndividual.Name, NameOfIndividual.MiddleName);
	
	AbbreviatedDescription	= Object.AbbreviatedDescription;
	
	If Not GetFunctionalOption("UseBranchOfficesWithSeparateBalanceSheets") And Not CompanyType = "BranchOffice" Then
		ListItem = Items.CompanyType.ChoiceList.FindByValue("BranchOffice");
		If ListItem <> Undefined Then
			Items.CompanyType.ChoiceList.Delete(ListItem);	
		EndIf;
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	// StandardSubsystems.ContactInformation
	AdditionalCIParameters = ContactsManager.ContactInformationParameters();
	AdditionalCIParameters.Insert("ItemForPlacementName", "ContactInformationGroup");
	AdditionalCIParameters.Insert("DeferredInitialization", True);
	
	ContactsManager.OnCreateAtServer(ThisObject, Object, AdditionalCIParameters);
	// End StandardSubsystems.ContactInformation	
	
	// StandardSubsystems.Properties
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	// End StandardSubsystems.Properties
	
	// Handler of the subsystem prohibiting editing of object details
	ObjectAttributesLock.LockAttributes(ThisObject);
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	CompaniesLocalization.WhenCreatingElementFormOnServer(ThisObject, Cancel, StandardProcessing);
	
	// Filling in an Organization by TIN with data from the Unified State Register of Legal Entities/EGRIP
	OnCreatReadAtServer();
	// The end of Filling in the Organization by TIN with data from the Unified State Register of Legal Entities/EGRIP
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations
	
	NationalLanguageSupportServer.OnCreateAtServer(ThisObject, Object);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
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

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	ClearMessages();
	
	If ChoiceSource.FormName = "DataProcessor.FilesOperations.Form.AttachedFiles"
		And ValueIsFilled(ValueSelected) Then
		
		If LogoOperations Then
			
			Object.Logo = ValueSelected;
			LogoAddress = ImageNavigationLink(Object.Logo, UUID)
			
		ElsIf FacsimileOperations Then
			
			Object.FacsimileStamp = ValueSelected;
			FacsimileStampAddress = ImageNavigationLink(Object.FacsimileStamp, UUID)
			
		EndIf;
		
	ElsIf TypeOf(ChoiceSource) = Type("ClientApplicationForm")
		And ChoiceSource.FormName = "Catalog.Companies.Form.FormToEditNameHistory" Then
		
		SetNameAfterEditingHistory(ValueSelected.NameHistory);
	
	EndIf;

	CompaniesClientLocalization.ChoiceProcessing(ValueSelected, ChoiceSource, ThisObject);
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// StandardSubsystems.ContactInformation
	ContactsManager.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.ContactInformation

	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	CompaniesLocalization.OnReadAtServer(ThisObject, CurrentObject);
	
	NationalLanguageSupportServer.OnReadAtServer(ThisObject, CurrentObject);
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.ContactInformation
	ContactsManager.FillCheckProcessingAtServer(ThisObject, Object, Cancel);
	// End StandardSubsystems.ContactInformation
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
	CompaniesLocalization.FillCheckProcessingAtServer(Cancel, CheckedAttributes, ThisObject);
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	ClearMessages();
	
	If DataSelectionFormIsOpened Then
		Cancel = True;
	EndIf;
	
	CompaniesClientLocalization.BeforeWrite(Cancel, WriteParameters, ThisObject);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// StandardSubsystems.ContactInformation
	ContactsManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.ContactInformation
	
	// StandardSubsystems.Properties
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	CompaniesLocalization.BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters, ThisObject);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	NationalLanguageSupportServer.BeforeWriteAtServer(CurrentObject);
	
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	CompaniesLocalization.OnWriteAtServer(Cancel, CurrentObject, WriteParameters, ThisObject);
	FormEvents.OnWriteAtServer(ThisObject, Cancel, CurrentObject, WriteParameters);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	ManagingFormOnServer();
	// Handler of the subsystem prohibiting editing of object details
	ObjectAttributesLock.LockAttributes(ThisObject);
	
	CompaniesLocalization.AfterWriteAtServer(CurrentObject, WriteParameters, ThisObject);
	
	NationalLanguageSupportServer.OnReadAtServer(ThisObject, CurrentObject);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_File" Then
		
		If LogoOperations Then
			
			Modified = True;
			FileRef = ?(TypeOf(Source) = Type("Array"), Source[0], Source);
		
			Object.Logo = FileRef;
			LogoAddress = ImageNavigationLink(Object.Logo, UUID);
			
		ElsIf FacsimileOperations Then
			
			Modified = True;
			FileRef = ?(TypeOf(Source) = Type("Array"), Source[0], Source);
			
			Object.FacsimileStamp = FileRef;
			FacsimileStampAddress = ImageNavigationLink(Object.FacsimileStamp, UUID);
			
		EndIf;
	
	ElsIf EventName = "InstallationOfMainBankAccount" Then
		
		If Object.Ref = Parameter.Organization Then
			
			Object.MainBankAccount = Parameter.MainBankAccount;
			Modified = True;
			Notify("ChangingMainBankAccount", Object.MainBankAccount, ThisObject);
			
		EndIf;
		
	EndIf;
	
	If StrFind(EventName, "Record_") > 0 Then
		If ValueIsFilled(Parameter) And TypeOf(Parameter) = Type("Structure") Then
			If Parameter.Property("Organization") 
				And (Parameter.Organization = Object.Ref 
					Or Parameter.Organization = Object.ParentCompany) Then
					AvailableRegisters = AvailableRegistersOfTaxesAndAccountingPolicies();
					RowsArray = StrSplit(EventName, "_", False);
					If RowsArray.Count() > 1 Then
						RegisterName = RowsArray[1];
						If AvailableRegisters.Find(RegisterName) <> Undefined Then
							FillInDescriptionOfCurrentParameters(RegisterName);
							DependentRegister = CompaniesClientLocalization.DependentRegister(RegisterName); 
							If ValueIsFilled(DependentRegister) Then 
								FillInDescriptionOfCurrentParameters(DependentRegister);
							EndIf;
						EndIf;
					EndIf;
			EndIf;
		EndIf;
	EndIf;
	
	If EventName = "RecordingSettingsAndAccountingPolicies" Then
		
		FillInDescriptionOfCurrentParameters();
		
	EndIf;
	
	CompaniesClientLocalization.NotificationProcessing(EventName, Parameter, Source, ThisObject);
	
	
	// StandardSubsystems.Properties 
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End Of The Standard Subsystem.Properties
	// Standard subsystems.Remotefile
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_Companies", , Object.Ref);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
	CompaniesClientLocalization.AfterWrite(WriteParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If DataSelectionFormIsOpened Then
		Cancel = True;
	EndIf;
	CompaniesClientLocalization.BeforeClose(Cancel, Exit, WarningText, StandardProcessing, ThisObject);
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	CompaniesClientLocalization.OnClose(Exit, ThisObject);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

#Region UniversalEventHandlers

&AtClient
Procedure Attachable_TextEditEnd(Item, Text, ChoiceData, Var_Parameters, StandardProcessing)
	
	CompaniesClientLocalization.EndOfTextEntry_Organization(Item,
		Text,
		ChoiceData,
		Var_Parameters,
		StandardProcessing,
		ThisObject);
		
EndProcedure

&AtClient
Procedure Attachable_OnChangeAttribute(Item)
	
	CompaniesClientLocalization.OnChangeAttribute(
		Item,
		ThisObject);
EndProcedure

&AtClient
Procedure Attachable_ProcessingTheFormSNavigationLink(Item, FormattedStringURL, StandardProcessing)
	
	CompaniesClientLocalization.ProcessingNavigationLinkOf_OrganizationForm(Item,
		FormattedStringURL,
		StandardProcessing,
		ThisObject);
	
EndProcedure

&AtClient
Procedure OpenVATAccountingSettingsURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	If FormattedStringURL = "OpenVATAccountingSettings" Then
		CompaniesClientLocalization.CheckThatItIsNotNewElement(ThisObject,
			NStr("vi = 'Tùy chỉnh kế toán GTGT';
				|ru = 'Настройки учета НДС';
				|en = 'VAT accounting settings'; fa = 'تنظیمات حسابداری مالیات بر ارزش افزوده';
				|it = 'Impostazioni di contabilità IVA';
				|pl = 'Ustawienia ewidencji VAT';
				|tr = 'KDV muhasebesi ayarları'"),
			New CallbackDescription("OpenVATAccountingSettingsItemRecorded", 
				ThisObject,
				New Structure("Form", ThisObject)));
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenVATAccountingSettingsItemRecorded(Result, AdditionalParameters) Export
	
	Form = AdditionalParameters.Form;
	OpenForm("InformationRegister.VATAccountingSettings.RecordForm",
		New Structure("Organization", ThisObject.Object.Ref),
		Form,,,,
		,
		FormWindowOpeningMode.LockOwnerWindow);
		
EndProcedure

&AtClient
Procedure Attachable_Click(Item, StandardProcessing)
	CompaniesClientLocalization.Click_Organization(Item,
		StandardProcessing,
		ThisObject);
EndProcedure

&AtClient
Procedure Attachable_StartChoice(Item, ChoiceData, StandardProcessing)
	CompaniesClientLocalization.StartSelecting_Organization(Item, ChoiceData, StandardProcessing, ThisObject);
EndProcedure

&AtClient
Procedure Attachable_AutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	CompaniesClientLocalization.AutoComplete_Companies(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing, ThisObject);
	
EndProcedure

&AtClient
Procedure AtEndOfChangingLocalizationDetails(TagName, AdditionalParameters) Export
	
	If AdditionalParameters.ServerCallRequired_ Then
		AtEndOfChangingLocalizationDetailsOnServer(TagName, AdditionalParameters.ProcessingParameters);
	EndIf;
	
	If TagName = "AbbreviatedDescription" Then
		AbbreviatedDescriptionOnChange(Items.AbbreviatedDescription);
	EndIf;
	
EndProcedure

&AtServer
Procedure AtEndOfChangingLocalizationDetailsOnServer(TagName, ProcessingParameters)
		
	CompaniesLocalization.AtEndOfChangeOfProps(TagName, ThisObject, ProcessingParameters);
	If ValueIsFilled(ProcessingParameters) 
		And ProcessingParameters.Property("ProcedureName")
		And ProcessingParameters.ProcedureName = "ManagingFormOnServer" Then
		
		ManagingFormOnServer();
		
	EndIf;
EndProcedure

&AtClient
Procedure Attachable_Opening(Item, StandardProcessing)
	
	NationalLanguageSupportClient.OnOpen(ThisObject, Object, Item, StandardProcessing);
	
EndProcedure

#EndRegion

&AtClient
Procedure CompanyTypeOnChange(Item)
	ChangeTypeOfOrganizationOnServer();
EndProcedure

&AtClient
Procedure LogoAddressClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	LockFormDataForEdit();
	
	ManagingFlagsForWorkingWithImages(True, False);
	AddImageOnClient();
	
EndProcedure 

&AtClient
Procedure FacsimileStampAddressClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	LockFormDataForEdit();
	
	ManagingFlagsForWorkingWithImages(False, True);
	AddImageOnClient();
	
EndProcedure

// StandardSubsystems.ContactInformation

&AtClient
Procedure Attachable_ContactInformationOnChange(Item)
	ContactsManagerClient.ToBeginUpdate(ThisObject, Item);
EndProcedure

// Parameters:
// 	Item - FormField -
// 	ChoiceData - Arbitrary - 
// 	StandardProcessing - Boolean - 
&AtClient
Procedure Attachable_ContactInformationStartChoice(Item, ChoiceData, StandardProcessing)
	
	OpeningParameters = New Structure;
	
	Filter = New Structure("AttributeName", Item.Name);
	Rows = ThisObject.ContactInformationAdditionalAttributesDetails.FindRows(Filter);
	RowData = ?(Rows.Count() = 0, Undefined, Rows[0]);
	If RowData <> Undefined Then
		If RowData.Kind = PredefinedValue(
			"Catalog.ContactInformationKinds.InternationalAddressOfCompany") Then
			OpeningParameters.Insert("AllowAddressInputInFreeForm", False);
			OpeningParameters.Insert("Country", Object.RegistrationCountry);
		EndIf;
		If (RowData.Kind = PredefinedValue("Catalog.ContactInformationKinds.LegalAddressOfCompany")
			Or RowData.Kind = PredefinedValue("Catalog.ContactInformationKinds.ActualDataAddressOfCompany")
			Or RowData.Kind = PredefinedValue(
			"Catalog.ContactInformationKinds.ActualAddressOfBranchOffice")) Then
			OpeningParameters.Insert("Country", Object.RegistrationCountry);
		EndIf;
	EndIf;
	
	ContactsManagerClient.StartSelection(ThisObject, Item,, StandardProcessing, OpeningParameters);
	
EndProcedure

&AtClient
Procedure Attachable_ContactInformationOnClick(Item, StandardProcessing)
	ContactsManagerClient.StartSelection(ThisObject, Item,, StandardProcessing);
EndProcedure

// Parameters:
// 	Item - FormField -
// 	StandardProcessing - Boolean - 
&AtClient
Procedure Attachable_ContactInformationClearing(Item, StandardProcessing)
	ContactsManagerClient.StartClearing(ThisObject, Item.Name);
EndProcedure

// Parameters:
// 	Command - FormCommand -
&AtClient
Procedure Attachable_ContactInformationExecuteCommand(Command)
	ContactsManagerClient.StartCommandExecution(ThisObject, Command.Name);
EndProcedure

&AtClient
Procedure Attachable_ContactInformationAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	ContactsManagerClient.AutoCompleteAddress(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing);
	
EndProcedure


// Parameters:
// 	Item - FormField -
// 	ValueSelected - Arbitrary -
// 	StandardProcessing - Boolean -
&AtClient
Procedure Attachable_ContactInformationChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	ContactsManagerClient.ChoiceProcessing(ThisObject, ValueSelected, Item.Name, StandardProcessing);
	
EndProcedure

&AtServer
Procedure ContactInformationWhenChangingPages()
	
	ContactsManager.ExecuteDeferredInitialization(ThisObject, Object);
	
EndProcedure

&AtClient
Procedure Attachable_ContactInformationURLProcessing(Item, FormattedStringURL, StandardProcessing)
    ContactsManagerClient.StartURLProcessing(ThisObject, Item, FormattedStringURL, StandardProcessing);
EndProcedure

&AtClient
Procedure Attachable_ContinueContactInformationUpdate(Result, AdditionalParameters) Export
	UpdateContactInformation(Result);
EndProcedure
// End StandardSubsystems.ContactInformation

&AtClient
Procedure PrefixOnChange(Item)
	
	If Find(Object.Prefix, "-") > 0 Then
		ShowMessageBox(Undefined, NStr("vi = 'Trong tiền tố của doanh nghiệp không thể sử dụng ký tự ""-"".';
										|ru = 'Нельзя в префиксе организации использовать символ ""-"".';
										|en = 'Cannot use ""-"" in the company prefix.'; fa = 'Cannot use ""-"" in the company prefix.';
										|it = 'Non è possibile utilizzare il simbolo ""-"" nel prefisso di un''organizzazione.';
										|pl = 'W prefiksie firmy nie można używać symbolu ""-"".';
										|tr = 'İş yeri ön ekinde ""-"" karakteri kullanılamaz.'"));
		Object.Prefix = StrReplace(Object.Prefix, "-", "");
	EndIf;
	
EndProcedure

&AtClient
Procedure AbbreviatedDescriptionOnChange(Item)
	
	If IsBlankString(Object.DescriptionFull) Then
		Object.DescriptionFull = Object.AbbreviatedDescription;
	EndIf;
	
	If IsBlankString(Object.Description) Then
		Object.Description	= Object.AbbreviatedDescription;
	EndIf;
	
	CompaniesClientLocalization.OnChangeAttribute(Item, ThisObject);
	SetCurrentValueOfHistoryOfNames();
	
EndProcedure

&AtClient
Procedure DescriptionInternationalOnChange(Item)
	SetCurrentValueOfHistoryOfNames()
EndProcedure

&AtClient
Procedure DescriptionFullOnChange(Item)
	SetCurrentValueOfHistoryOfNames()
EndProcedure

&AtClient
Procedure PagesCompanyParametersOnCurrentPageChange(Item, CurrentPage)
	
	// StandardSubsystems.ContactInformation
	If CurrentPage.Name = ContactInformationParameters.ContactInformationGroup.GroupForPlacement
		And ContactInformationParameters.ContactInformationGroup.DeferredInitialization 
		And Not ContactInformationParameters.ContactInformationGroup.DeferredInitializationExecuted Then
		
		ContactInformationWhenChangingPages();
		
	EndIf;
	// End StandardSubsystems.ContactInformation
	
EndProcedure

&AtClient
Procedure CompanyTypeClearing(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure TINTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	CompaniesClientLocalization.CheckTIN_(Text, Object);
EndProcedure

&AtClient
Procedure NameHistoryClick(Item)
	
	FormParameters = New Structure;
	FormParameters.Insert("CompanyIndividual", Object.CompanyIndividual);
	FormParameters.Insert("NameHistory",Object.NameHistory);
	FormParameters.Insert("ReadOnly", ReadOnly);
	
	OpenForm("Catalog.Companies.Form.FormToEditNameHistory", FormParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure MainBankAccountOnChange(Item)
	
	Notify("ChangingMainBankAccount", Object.MainBankAccount, ThisObject);
	
EndProcedure

&AtClient
Procedure SpecialApplicantFeatureDPSOnChange(Item)
	
	CompaniesClientLocalization.OnChangeAttribute(Item, ThisObject);
	
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

// Attachable execute the localization command.
// 
// Parameters:
//  Command - FormCommand - Command
&AtClient
Procedure Attachable_ExecuteLocalizationCommand(Command)
	
	CompaniesClientLocalization.ExecuteLocalizationCommand(Command, ThisObject);
	
EndProcedure

&AtClient
Procedure ContinueRunningLocalizationCommand(CommandName, AdditionalParameters) Export
	
	If AdditionalParameters.ServerCallRequired_ Then
		ContinueRunningLocalizationCommandOnServer(CommandName, AdditionalParameters.ProcessingParameters);
	EndIf;
	
EndProcedure

&AtServer
Procedure ContinueRunningLocalizationCommandOnServer(CommandName, ProcessingParameters)
	
	CompaniesLocalization.ExecuteLocalizationCommand(ThisObject, CommandName, ProcessingParameters);
	If ValueIsFilled(ProcessingParameters) And ProcessingParameters.Property("ProcedureName") Then
		If ProcessingParameters.ProcedureName = "ContactInformationWhenChangingPages" Then
			ContactInformationWhenChangingPages();
		EndIf;
	EndIf;
	
EndProcedure
	
#EndRegion

&AtClient
Procedure OpenTheAccountingPolicyOfFinancialAccountingURLProcessing(Item, FormattedStringURL, StandardProcessing)
	StandardProcessing = False;
	If FormattedStringURL = "OpenTheAccountingPolicyOfFinancialAccounting" Then
		CompaniesClientLocalization.CheckThatItIsNotNewElement(ThisObject,
			NStr("vi = 'Chính sách kế toán tài chính';
				|ru = 'Учетная политика финансового учета';
				|en = 'Financial accounting policy'; fa = 'رویه حسابداری مالی';
				|it = 'Politica contabile della contabilità finanziaria';
				|pl = 'Polityka ewidencyjna ewidencji finansowej';
				|tr = 'Finansal muhasebe politikası'"),
			New CallbackDescription("OpenAccountingPolicyForFinancialAccountingItemRecorded", 
				ThisObject,
				New Structure("Form", ThisObject)));
	EndIf;
EndProcedure

&AtClient
Procedure OpenAccountingPolicyForFinancialAccountingItemRecorded(Result, AdditionalParameters) Export
	
	Form = AdditionalParameters.Form;
	OpenForm("InformationRegister.FinancialAccountingPolicy.RecordForm",
		New Structure("Organization", ThisObject.Object.Ref),
		Form,,,,
		,
		FormWindowOpeningMode.LockOwnerWindow);
		
EndProcedure

&AtClient
Procedure AddLogoImage(Command)
	
	If Not ValueIsFilled(Object.Ref) Then
		
		QueryText = NStr("vi = 'Để chọn hình ảnh, cần ghi lại đối tượng. Ghi lại?';
						|ru = 'Для выбора изображения необходимо записать объект. Записать?';
						|en = 'To select an image, save the object. Save it?'; fa = 'To select an image, save the object. Save it?';
						|it = 'Per la selezione dell''immagine è necessario scrivere l''oggetto. Scriverlo?';
						|pl = 'Aby wybrać obraz, należy zapisać obiekt. Zapisać?';
						|tr = 'Bir görsel seçmek için nesneyi kaydedin. Nesneyi kaydetmek istiyor musunuz?'");
		ShowQueryBox(New CallbackDescription("AddLogoImageCompletion", ThisObject), QueryText, QuestionDialogMode.YesNo);
		Return;
		
	EndIf;
	
	AddLogoImageFragment();
EndProcedure

&AtClient
Procedure AddLogoImageCompletion(QuestionResult, AdditionalParameters) Export
    
    Response = QuestionResult;
    
    If Response = DialogReturnCode.Yes Then
        Write();
    Else
        Return
    EndIf;
    
    
    AddLogoImageFragment();

EndProcedure

&AtClient
Procedure AddLogoImageFragment()
    
    ManagingFlagsForWorkingWithImages(True, False);
    
    FileID = New UUID;
    FilesOperationsClient.AddFiles(Object.Ref, FileID);

EndProcedure

&AtClient
Procedure ChangeLogoImage(Command)
	
	ClearMessages();
	
	If ValueIsFilled(Object.Logo) Then
		
		FilesOperationsClient.OpenFileForm(Object.Logo);
		
	Else
		
		MessageText = NStr("vi = 'Không có hình ảnh để chỉnh sửa';
							|ru = 'Отсутствует изображение для редактирования';
							|en = 'No image for editing'; fa = 'No image for editing';
							|it = 'Manca l''immagine per la modifica';
							|pl = 'Brak obrazu do edycji';
							|tr = 'Düzenlenecek görüntü yok'");
		CommonClientServer.MessageToUser(MessageText,, "LogoAddress");
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ClearLogoImage(Command)
	
	Object.Logo = Undefined;
	LogoAddress = "";
	
EndProcedure

&AtClient
Procedure ViewLogoImage(Command)
	
	ManagingFlagsForWorkingWithImages(True, False);
	ViewAttachedFile();
	
EndProcedure

&AtClient
Procedure TheLogoFromTheAttachedFiles(Command)
	
	ManagingFlagsForWorkingWithImages(True, False);
	SelectAnImageFromAttachedFiles();
	
EndProcedure

&AtClient
Procedure AddFacsimileImage(Command)
	
	If Not ValueIsFilled(Object.Ref) Then
		
		QueryText = NStr("vi = 'Để chọn hình ảnh, cần ghi lại đối tượng. Ghi lại?';
						|ru = 'Для выбора изображения необходимо записать объект. Записать?';
						|en = 'To select an image, save the object. Save it?'; fa = 'To select an image, save the object. Save it?';
						|it = 'Per la selezione dell''immagine è necessario scrivere l''oggetto. Scriverlo?';
						|pl = 'Aby wybrać obraz, należy zapisać obiekt. Zapisać?';
						|tr = 'Bir görsel seçmek için nesneyi kaydedin. Nesneyi kaydetmek istiyor musunuz?'");
		ShowQueryBox(New CallbackDescription("AddFacsimileImageCompletion", ThisObject), QueryText, QuestionDialogMode.YesNo);
		Return;
		
	EndIf;
	
	AddImageFacsimileFragment();
EndProcedure

&AtClient
Procedure AddFacsimileImageCompletion(QuestionResult, AdditionalParameters) Export
    
    Response = QuestionResult;
    
    If Response = DialogReturnCode.Yes Then
        Write();
    Else
        Return
    EndIf;
    
    
    AddImageFacsimileFragment();

EndProcedure

&AtClient
Procedure AddImageFacsimileFragment()
    
    Var FileID;
    
    ManagingFlagsForWorkingWithImages(False, True);
    
    FileID = New UUID;
    FilesOperationsClient.AddFiles(Object.Ref, FileID);

EndProcedure

&AtClient
Procedure ChangeFacsimileImage(Command)
	
	ClearMessages();
	
	If ValueIsFilled(Object.FacsimileStamp) Then
		
		FilesOperationsClient.OpenFileForm(Object.FacsimileStamp);
		
	Else
		
		MessageText = NStr("vi = 'Không có hình ảnh để chỉnh sửa';
							|ru = 'Отсутствует изображение для редактирования';
							|en = 'No image for editing'; fa = 'No image for editing';
							|it = 'Manca l''immagine per la modifica';
							|pl = 'Brak obrazu do edycji';
							|tr = 'Düzenlenecek görüntü yok'");
		CommonClientServer.MessageToUser(MessageText,, "LogoAddress");
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ClearFacsimileImage(Command)
	
	Object.FacsimileStamp = Undefined;
	FacsimileStampAddress = "";
	
EndProcedure

&AtClient
Procedure ViewFacsimileImage(Command)
	
	ManagingFlagsForWorkingWithImages(False, True);
	ViewAttachedFile();
	
EndProcedure

&AtClient
Procedure FacsimileFromAttachedFiles(Command)
	
	ManagingFlagsForWorkingWithImages(False, True);
	SelectAnImageFromAttachedFiles();
	
EndProcedure // Facsimile of Connected files()

&AtClient
Procedure FacsimileStampWizard(Command)
	
	CommandParameter = New Array;
	CommandParameter.Add(Object.Ref);
	
	StructureOfAdditionalParameters = New Structure("FormCaption", NStr("vi = 'Làm thế nào để tạo dấu chữ ký và in?';
																		|ru = 'Как создать факсимильную подпись и печать?';
																		|en = 'How to create facsimile signature and stamp?'; fa = 'How to create facsimile signature and stamp?';
																		|it = 'Come creare una firma e un timbro facsimile?';
																		|pl = 'Jak utworzyć podpis i pieczęć faksymilową?';
																		|tr = 'Faks imzası ve kaşesi nasıl oluşturulur?'"));
	PrintManagementClient.ExecutePrintCommand("Catalog.Companies", "PrintAssistantFaxPrintingJob", CommandParameter, Undefined, StructureOfAdditionalParameters);
	
EndProcedure

&AtClient
Procedure PreviewOfProformaInvoice(Command)
	
	If Not ValueIsFilled(Object.Ref) Or Modified Then
		
		QueryText = NStr("vi = 'Dữ liệu vẫn chưa được ghi lại.
		|Chỉ có thể chuyển đến xem trước hóa đơn thanh toán sau khi ghi lại dữ liệu.
		|Dữ liệu sẽ được ghi lại.';
		|ru = 'Данные еще не записаны.
		|Переход к предварительному просмотру счета на оплату доступен только после записи данных.
		|Данные будут записаны.';
		|en = 'Data is not recorded yet.
		|You can preview the commercial invoice only after the data is recorded.
		|Data will be recorded.'; fa = 'Data is not recorded yet.
		|You can preview the commercial invoice only after the data is recorded.
		|Data will be recorded.';
		|it = 'I dati non sono ancora stati scritti.
		|Il passaggio all''anteprima della fattura è disponibile solo dopo la scrittura dei dati.
		|I dati verranno scritti.';
		|pl = 'Dane nie zostały jeszcze zapisane.
		|Przejście do podglądu rachunku do płatności jest dostępne tylko po zapisaniu danych.
		|Dane zostaną zapisane.';
		|tr = 'Veriler henüz kaydedilmedi.
		|Ticari faturanın ön görüntülemesine geçiş, yalnızca veriler kaydedildikten sonra mümkündür.
		|Veriler kaydedilecektir.'");
		
		ShowQueryBox(New CallbackDescription("PreviewOfProformaInvoiceCompletion", ThisObject), QueryText, QuestionDialogMode.OKCancel);
        Return;
		
	EndIf;
	
	PreviewInvoiceForPaymentFragment();
EndProcedure

&AtClient
Procedure PreviewOfProformaInvoiceCompletion(QuestionResult, AdditionalParameters) Export
    
    If QuestionResult = DialogReturnCode.Cancel Then
        Return;
    EndIf;
    
    ItemRecorded = Write();
    
    If Not ItemRecorded Then
        Return;
    EndIf;
    
    
    PreviewInvoiceForPaymentFragment();

EndProcedure

&AtClient
Procedure PreviewInvoiceForPaymentFragment()
    
    Var CommandParameter, StructureOfAdditionalParameters;
    
    CommandParameter = New Array;
    CommandParameter.Add(Object.Ref);
    
    StructureOfAdditionalParameters = New Structure("FormCaption", NStr("vi = 'Xem trước mẫu in ""Hóa đơn thanh toán"".';
																		|ru = 'Предварительный просмотр печатной формы ""Счет на оплату"".';
																		|en = 'Preview ""Commercial invoice"" print form'; fa = 'Preview ""Commercial invoice"" print form';
																		|it = 'Anteprima del modello di stampa ""Fattura per il pagamento"".';
																		|pl = 'Podgląd formularza wydruku ""Rachunek do płatności"".';
																		|tr = '""Ticari fatura"" yazdırma formu önizleme.'"));
    PrintManagementClient.ExecutePrintCommand("DataProcessor.PrintCommercialInvoices", "PreviewOfPrintedInvoiceForm", CommandParameter, Undefined, StructureOfAdditionalParameters);

EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

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


// Handler for a command created by the mechanism that prohibits editing key details.
//
&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)
	
	If Not Object.Ref.IsEmpty() Then
		
		UnlockFormParameters = New Structure;
		UnlockFormParameters.Insert("BranchOffice", Object.BranchOffice);

		OpenForm("Catalog.Companies.Form.AttributeUnlocking", UnlockFormParameters,,,,, 
			New CallbackDescription("Attachable_AllowObjectAttributeEditCompletion", ThisObject), 
			FormWindowOpeningMode.LockOwnerWindow);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_AllowObjectAttributeEditCompletion(Result, AdditionalParameters) Export
    
    If TypeOf(Result) = Type("Array") And Result.Count() > 0 Then
        
        ObjectAttributesLockClient.SetFormItemEnabled(ThisObject, Result);
        
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
	ItemField.Field = New DataCompositionField(Items.ParentCompany);

	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ParentCompany");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BranchOffice");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("MarkIncomplete", True);

EndProcedure

&AtServerNoContext
Function GetIndividualSFullName(IndividualEntrepreneur)
	
	Return PersonsTM.FullName(IndividualEntrepreneur);
	
EndFunction



// StandardSubsystems.Properties
&AtServer
Procedure UpdateAdditionalAttributesItems()

	PropertyManager.UpdateAdditionalAttributesItems(ThisObject);

EndProcedure

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure
// End StandardSubsystems.Properties

&AtServer
Procedure ManagingFormOnServer()
	
	EnterpriseManagement = Not GetFunctionalOption("TradeManagement");
	
	TMCommonUseClientServer.SetFormItemProperty(
			Items, 
			"GroupTypeOfOrganization",
			"Enabled", 
			AccessRight("Update", Metadata.Catalogs.Companies));
	
	If CompanyType = "BusinessEntity" Then
		
		Items.Description.InputHint = NStr("vi = 'ví dụ, Công ty TNHH 1C Việt Nam';
											|ru = 'например, Стройснаб ООО';
											|en = 'for example, LIGHT LLC'; fa = 'for example, LIGHT LLC';
											|it = 'ad esempio, CostForn SRL';
											|pl = 'na przykład, Srtojsnab Sp. z o.o.';
											|tr = 'örneğin, Stroysnab Limited Şirketi'");
		Items.AbbreviatedDescription.InputHint = NStr("vi = 'ví dụ, Công ty TNHH 1C Việt Nam';
														|ru = 'например, ООО ""Стройснаб""';
														|en = 'for example, LIGHT'; fa = 'for example, LIGHT';
														|it = 'ad esempio, SRL CostForn';
														|pl = 'na przykład, Sp. z o.o. ""Strojsnab""';
														|tr = 'örneğin, ""Stroysnab"" Lti. Şti.'");
		Items.DescriptionFull.InputHint = NStr("vi = 'ví dụ, Công ty trách nhiệm hữu hạn 1C Việt Nam';
												|ru = 'например, Общество с ограниченной ответственностью Стройснаб';
												|en = 'for example, LIGHT Limited Liability Company'; fa = 'for example, LIGHT Limited Liability Company';
												|it = 'ad esempio, la società a responsabilità limitata CostForn';
												|pl = 'na przykład, Spółka z ograniczoną odpowiedzialnością Strojsnab';
												|tr = 'örneğin, Stroysnab Limited Şirketi'");
		Items.LocalAccountingCurrency.Visible = True;
		
	ElsIf CompanyType = "BranchOffice" Then
		
		Items.Description.InputHint = NStr("vi = 'ví dụ, chi nhánh Hà Nội';
											|ru = 'например, Филиал ТД (Тамбов)';
											|en = 'for example, trading house Branch office (Tambov)'; fa = 'for example, trading house Branch office (Tambov)';
											|it = 'ad esempio, la filiale della Casa Commerciale (Tambov)';
											|pl = 'na przykład, Filia DH (Tambow)';
											|tr = 'örneğin, Ticaret Evi şubesi (Tambov)'");
		Items.AbbreviatedDescription.InputHint = NStr("vi = 'ví dụ, chi nhánh Hà Nội';
														|ru = 'например, ТД Филиал (Тамбов)';
														|en = 'for example, Tambov trading house branch office'; fa = 'for example, Tambov trading house branch office';
														|it = 'ad esempio, la filiale della Casa Commerciale (Tambov)';
														|pl = 'na przykład, DH Filia (Tambow)';
														|tr = 'örneğin, Ticaret Evi şubesi (Tambov)'");
		Items.DescriptionFull.InputHint = NStr("vi = 'ví dụ, Trading house ""Complex"" - bộ phận độc lập';
												|ru = 'например, Торговый дом ""Комплексный"" - обособленное подразделение';
												|en = 'for example, All-Inclusive Shopping Center - branch office'; fa = 'for example, All-Inclusive Shopping Center - branch office';
												|it = 'ad esempio, la casa commerciale ""Kompleksni"" - reparto esterno';
												|pl = 'na przykład, Dom Handlowy ""Kompleksowy"" - odrębny dział';
												|tr = 'örneğin, ""Kompleksnıy"" Ticaret evi ayrı departmanı'");
		Items.LocalAccountingCurrency.Visible = False;
		
	ElsIf CompanyType = "IndividualEntrepreneur" Then
		
		Items.Description.InputHint = NStr("vi = 'ví dụ: Nguyễn Hòa Bình';
											|ru = 'например, Иванова Наталья Игнатьевна';
											|en = 'for example, Jane Olsen'; fa = 'for example, Jane Olsen';
											|it = 'ad esempio, Ivanova Natalia Ignatievna';
											|pl = 'na przykład, Iwanowa Natalia Ignatiewna';
											|tr = 'örneğin, İvanova Natalya İgnatiyevna'");
		Items.AbbreviatedDescription.InputHint = NStr("vi = 'ví dụ:CNKD Nguyễn Hòa Bình';
														|ru = 'например, ИП Иванова Наталья Игнатьевна';
														|en = 'for example, IE Jane Olsen'; fa = 'for example, IE Jane Olsen';
														|it = 'ad esempio, l''Imprenditore Individuale Ivanova Natalia Ignatievna';
														|pl = 'na przykład, PI Iwanowa Natalia Ignatiewna';
														|tr = 'örneğin, İvanova Natalya İgnatiyevna Şahıs Şirketi'");
		Items.DescriptionFull.InputHint = NStr("vi = 'ví dụ: Cá nhân kinh doanh Nguyễn Hòa Bình';
												|ru = 'например, Индивидуальный предприниматель Иванова Наталья Игнатьевна';
												|en = 'for example, Individual entrepreneur Olsen'; fa = 'for example, Individual entrepreneur Olsen';
												|it = 'ad esempio, l''imprenditore individuale Ivanova Natalia Ignatievna';
												|pl = 'na przykład, przedsiębiorca indywidualny Iwanowa Natalia Ignatiewna';
												|tr = 'örneğin, İvanova Natalya İgnatiyevna Şahıs Şirketi'");
		Items.LocalAccountingCurrency.Visible = True;
		
	EndIf;
		
	TMCommonUseClientServer.SetFormItemProperty(
			Items,
			"ParentCompany",
			"Visible",
			(CompanyType = "BranchOffice" And GetFunctionalOption("UseBranchOfficesWithSeparateBalanceSheets")));
	
	TMCommonUseClientServer.SetPropertyOfFormElements(
			Items,
			"TransactionsUsingParentCompanyAreAllowed",
			"Visible",
			(CompanyType = "BranchOffice"));
	
	TMCommonUseClientServer.SetPropertyOfFormElements(
				Items, 
				"IndividualEnterpreneurGroup",
				"Visible", 
				CompanyType = "IndividualEntrepreneur");
		

	If Not EnterpriseManagement Then
		TMCommonUseClientServer.SetPropertyOfFormElements(Items, "GroupAccountingPolicyAndOtherSettings",
																	"Title", NStr("vi = 'Chính sách kế toán';
																					|ru = 'Учетная политика';
																					|en = 'Accounting policy'; fa = 'رویه حسابداری';
																					|it = 'Politica contabile';
																					|pl = 'Polityka ewidencyjna';
																					|tr = 'Muhasebe politikası'"));
	EndIf;
	
	If Object.Ref = Catalogs.Companies.ManagementCompany Then
		Items.NameHistory.Visible = False;
		Items.Status.Visible = False;
	EndIf;
	
	SetTitleOfHyperlinkNameHistory();
	
	CompaniesLocalization.ManagingFormOnServer(ThisObject);
	
EndProcedure

&AtServer
Procedure ChangeTypeOfOrganizationOnServer()
	
	Object.LocalAccountingCurrency = Catalogs.Currencies.EmptyRef();
	
	If CompanyType = "BusinessEntity" Then
		Object.LegalEntityIndividual = PredefinedValue("Enum.LegalEntityIndividual.Entity");
		Object.BranchOffice = False;

		Object.ParentCompany = Object.Ref;
		Object.IndividualEntrepreneur = Catalogs.Persons.EmptyRef();
		Object.NumericCodeForTaxInvoices = "";
		Object.TransactionsUsingParentCompanyAreAllowed = False;
	ElsIf CompanyType = "IndividualEntrepreneur" Then
		Object.LegalEntityIndividual = PredefinedValue("Enum.LegalEntityIndividual.IndividualEntrepreneur");
		Object.BranchOffice = False;

		Object.ParentCompany = Object.Ref;
		Object.NumericCodeForTaxInvoices = "";
		Object.TransactionsUsingParentCompanyAreAllowed = False;

	ElsIf CompanyType = "BranchOffice" Then
		Object.LegalEntityIndividual = PredefinedValue("Enum.LegalEntityIndividual.Entity");
		Object.BranchOffice = True;
		Object.ParentCompany = Catalogs.Companies.EmptyRef();
		Object.IndividualEntrepreneur = Catalogs.Persons.EmptyRef();
	Else
		Raise NStr("vi = 'Đã xảy ra lỗi khi thay đổi kiểu doanh nghiệp. Hãy liên hệ với người quản trị.';
					|ru = 'Произошла ошибка при изменении типа организации. Обратитесь к администратору.';
					|en = 'An error occurred when changing the company type. Please contact the administrator.'; fa = 'An error occurred when changing the company type. Please contact the administrator.';
					|it = 'Si è verificato un errore durante la modifica del tipo dell''organizzazione. Rivolgetevi all''amministratore.';
					|pl = 'Podczas zmiany typu firmy zaistniał błąd. Skontaktuj się z administratorem.';
					|tr = 'İş yeri türü değişikliğinde hata oluştu. Yöneticiye iletişime geç.'");
	EndIf;
	AtEndOfChangingLocalizationDetailsOnServer("CompanyType", Undefined);
	Modified = True;
	
	ManagingFormOnServer();
	
EndProcedure

&AtClient
Procedure ManagingFlagsForWorkingWithImages(ThisIsLogoJob = False, ThisIsFacsimileJob = False)
	
	LogoOperations = ThisIsLogoJob;
	FacsimileOperations = ThisIsFacsimileJob;
	
EndProcedure

&AtClient
Procedure SelectAnImageFromAttachedFiles()
	
	ImageSelectionParameters = New Structure;
	ImageSelectionParameters.Insert("FileOwner", Object.Ref);
	ImageSelectionParameters.Insert("CloseOnChoice", True);
	ImageSelectionParameters.Insert("ChoiceMode", True);
	
	OpenForm("DataProcessor.FilesOperations.Form.AttachedFiles", ImageSelectionParameters, ThisObject);
	
EndProcedure 

&AtClient
Procedure ViewAttachedFile()
	
	ClearMessages();
	
	ObjectAttributeName = "";
	
	If LogoOperations Then
		
		ObjectAttributeName = "Logo";
		
	ElsIf FacsimileOperations Then
		
		ObjectAttributeName = "FacsimileStamp";
		
	EndIf;
	
	If Not IsBlankString(ObjectAttributeName)
		And ValueIsFilled(Object[ObjectAttributeName]) Then
		
		FileData = GetFileData(ThisObject.Object[ObjectAttributeName], UUID);
		FilesOperationsClient.OpenFile(FileData);
		
	Else
		
		MessageText = NStr("vi = 'Không có hình ảnh để xem';
							|ru = 'Отсутствует изображение для просмотра';
							|en = 'No preview image'; fa = 'No preview image';
							|it = 'Manca l''immagine per la visualizzazione';
							|pl = 'Brak obrazu do przeglądania';
							|tr = 'Önizleme görüntüsü yok'");
		CommonClientServer.MessageToUser(MessageText,, "PictureAddress");
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function GetFileData(PicturesFile, UUID)
	
	Return FilesOperations.FileData(PicturesFile, UUID);
	
EndFunction

&AtServerNoContext
Function ImageNavigationLink(PicturesFile, FormIdentifier)
	
	SetPrivilegedMode(True);
	
	Try
		PictureAddress = FilesOperations.FileData(PicturesFile, FormIdentifier).RefToBinaryFileData;
	Except
		CommonClientServer.MessageToUser(BriefErrorDescription(ErrorInfo()));
		PictureAddress = "";
	EndTry;
	
	Return PictureAddress;
	
EndFunction

&AtClient
Procedure AddImageOnClient()
	
	If Not ValueIsFilled(Object.Ref) Then
		
		QueryText = NStr("vi = 'Để chọn hình ảnh, cần ghi lại đối tượng. Ghi lại?';
						|ru = 'Для выбора изображения необходимо записать объект. Записать?';
						|en = 'To select an image, save the object. Save it?'; fa = 'To select an image, save the object. Save it?';
						|it = 'Per la selezione dell''immagine è necessario scrivere l''oggetto. Scriverlo?';
						|pl = 'Aby wybrać obraz, należy zapisać obiekt. Zapisać?';
						|tr = 'Bir görsel seçmek için nesneyi kaydedin. Nesneyi kaydetmek istiyor musunuz?'");
		ShowQueryBox(New CallbackDescription("AddImageOnClientCompletion", ThisObject), QueryText, QuestionDialogMode.YesNo);
		Return;
		
	EndIf;
	
	AddImageOnFragmentClient();
EndProcedure

&AtClient
Procedure AddImageOnClientCompletion(QuestionResult, AdditionalParameters) Export
    
    Response = QuestionResult;
    
    If Response = DialogReturnCode.Yes Then
        If Not Write() Then
            Return;
        EndIf;
    Else
        Return;
    EndIf;
    
    
    AddImageOnFragmentClient();

EndProcedure

&AtClient
Procedure AddImageOnFragmentClient()
    
    Var FileID, ObjectAttributeName;
    
    If LogoOperations Then
        
        ObjectAttributeName = "Logo";
        
    ElsIf FacsimileOperations Then
        
        ObjectAttributeName = "FacsimileStamp";
        
    EndIf;
    
    If ValueIsFilled(Object[ObjectAttributeName]) Then
        
        ViewAttachedFile();
        
    ElsIf ValueIsFilled(Object.Ref) Then
        
        FileID = New UUID;
        
        FilesOperationsClient.AddFiles(Object.Ref, FileID, ProductsClient.FilterImageFiles());
        
    EndIf;

EndProcedure 

////////////////////////////////////////////////////////////////////////////////
// Filling in the description of the organization parameters

&AtServer
Function ParentOrganizationsOfSeparateDivision()

	Query = New Query;
	Query.Text =
	"SELECT ALLOWED
	|	Companies.Ref,
	|	Companies.Description AS Description
	|FROM
	|	Catalog.Companies AS Companies
	|WHERE
	|	Companies.ParentCompany = Companies.Ref
	|	AND Companies.CompanyIndividual = VALUE(Enum.CompanyIndividual.BusinessEntity)
	|	AND Companies.Ref <> VALUE(Catalog.Companies.ManagementCompany)
	|
	|ORDER BY
	|	Description";
	
	Result = Query.Execute().Unload().UnloadColumn("Ref");
	
	Return Result;
	
EndFunction

&AtServer
Procedure FillInDetailsOfParentOrganization()
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	CASE
	|		WHEN Companies.CompanyIndividual = VALUE(Enum.CompanyIndividual.BusinessEntity)
	|				AND Companies.BranchOffice
	|			THEN Companies.ParentCompany
	|		ELSE Companies.Ref
	|	END AS ParentCompany
	|FROM
	|	Catalog.Companies AS Companies
	|WHERE
	|	Companies.Ref = &Organization";
	
	Query.SetParameter("Organization", Object.Ref);
	
	DataParentOrganization = Query.Execute().Select();
	While DataParentOrganization.Next() Do
		ParentCompany = DataParentOrganization.ParentCompany;	
	EndDo;
	
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

&AtServer
Procedure OnCreatReadAtServer()
	FillInDescriptionOfCurrentParameters();
	Items.RegistrationCountry.Visible = GetFunctionalOption("UseMultiCountryAccounting") Or Not ValueIsFilled(Object.RegistrationCountry);
	CompaniesLocalization.OnCreatReadAtServer(ThisObject);
EndProcedure

// The end of Filling in the Organization by INN with data from the Unified State Register of Legal Entities/EGRIP

&AtServer
Procedure FillInDescriptionOfCurrentParameters(RegisterName = "")
	MatchingElements = Catalogs.Companies.ComplianceOfFormElementsWithTaxAccountingPolicyParameters();
	AccountingPoliciesTaxSettings.ManagingVisibilityOfAccountingPolicyElements(ThisObject, MatchingElements, Object.Ref);
	AccountingPoliciesTaxSettings.FillInDescriptionOfCurrentParameters(ThisObject, Object.Ref, RegisterName);
	CompaniesLocalization.AccountingPolicyWhenServerChanges(ThisObject);
EndProcedure

&AtClient
Function AvailableRegistersOfTaxesAndAccountingPolicies()
	ArrayOfRegisters = New Array();
	ArrayOfRegisters.Add("FinancialAccountingPolicy");
	ArrayOfRegisters.Add("VATAccountingSettings");
	CompaniesClientLocalization.AvailableRegistersOfTaxesAndAccountingPolicies(ArrayOfRegisters);
	Return ArrayOfRegisters;
EndFunction

&AtServer
Procedure SetNameAfterEditingHistory(RecordSet)
	
	Modified = True;
	
	RecordSet.Sort("Period");
	
	Object.NameHistory.Clear();
	For Each SetRecord In RecordSet Do
		RecordingHistory = Object.NameHistory.Add();
		FillPropertyValues(RecordingHistory, SetRecord);
	EndDo;
	
	NumberOfHistoryEntries = RecordSet.Count();
	If NumberOfHistoryEntries > 0 Then
		CurrentEntry = RecordSet[RecordSet.Count()-1];
		Object.AbbreviatedDescription = CurrentEntry.AbbreviatedDescription;
		Object.DescriptionFull = CurrentEntry.DescriptionFull;
		Object.DescriptionInternational = CurrentEntry.DescriptionInternational;
	Else
		Object.AbbreviatedDescription = "";
		Object.DescriptionFull = "";
		Object.DescriptionInternational = "";
	EndIf;
	
	SetTitleOfHyperlinkNameHistory();
	
EndProcedure

&AtServer
Procedure SetTitleOfHyperlinkNameHistory()
	
	NameHistory = Object.NameHistory;
	If NameHistory.Count() > 1 Then
		NamingPeriod = NameHistory[NameHistory.Count()-1].Period;
		TitleTemplate1 = NStr("vi = 'Thực hiện từ %1';
								|ru = 'Действует с %1';
								|en = 'Valid from %1'; fa = 'Valid from %1';
								|it = 'In vigore dal %1';
								|pl = 'Obowiązuje od %1';
								|tr = '%1 itibarıyla geçerli'");
		TitleText = StrTemplate(TitleTemplate1, Format(NamingPeriod, "DLF=D;"));
	Else
		TitleText = NStr("vi = 'Lịch sử';
						|ru = 'История';
						|en = 'History'; fa = 'سابقه';
						|it = 'История';
						|pl = 'History';
						|tr = 'Geçmiş'");
	EndIf;
	Items.NameHistory.Title = TitleText;
	
EndProcedure

&AtClient
Procedure SetCurrentValueOfHistoryOfNames()
	
	NameHistory = Object.NameHistory;
	RecordsCount = NameHistory.Count();
	
	If RecordsCount = 0 Then
		HistoryRow = NameHistory.Add();
	Else
		HistoryRow = NameHistory[RecordsCount - 1];
	EndIf;
	
	HistoryRow.AbbreviatedDescription = Object.AbbreviatedDescription;
	HistoryRow.DescriptionFull = Object.DescriptionFull;
	HistoryRow.DescriptionInternational = Object.DescriptionInternational;
	
EndProcedure

// StandardSubsystems.ContactInformation
&AtServer
Procedure UpdateContactInformation(Result)
	ContactsManager.UpdateContactInformation(ThisObject, Object, Result);
EndProcedure

// End StandardSubsystems.ContactInformation

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
