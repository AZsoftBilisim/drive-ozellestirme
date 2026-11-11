
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	ToUseTermsOfSales		 = GetFunctionalOption("ToUseTermsOfSales");
	UseSeveralPriceTypes			 = GetFunctionalOption("UseSeveralPriceTypes");
	UsePriceManagementSystem25 			 = PriceManagementSystemServerCall.UsePriceManagementSystem25();
	ItIsAllowedToCreatePriceTypes				 = UseSeveralPriceTypes
												And AccessRight("Insert", Metadata.Catalogs.TypesOfPrices);
	EstablishPricingVisibility();

	PartnersAndCounterparties.PartnerElementFormWhenCreatedOnServer(ThisForm, Cancel, StandardProcessing);
	
	If Object.LegalEntityIndividual = Enums.IndividualCompany.Person_ Then
		Items.PagesPublicNameCompanyIndividual.CurrentPage = Items.PagePublicNameIndividual;
	Else
		Items.PagesPublicNameCompanyIndividual.CurrentPage = Items.PublicCompanyNamePage;
	EndIf;
	
	ShipmentIsProhibited = SegmentsServer.PartnerIsIncludedInShipmentBanSegments(Object.Ref);
	
	If ShipmentIsProhibited Then
		Items.BanPageGroup.CurrentPage = Items.GroupShipmentProhibited;
	Else
		Items.BanPageGroup.CurrentPage = Items.ShipmentPermittedGroup;
	EndIf;
	
	// StandardSubsystems.Versioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.Versioning
	
	// StandardSubsystems.ContactInformation
	AdditionalCIParameters = ContactsManager.ContactInformationParameters();
	AdditionalCIParameters.Insert("ItemForPlacementName", "ContactInformationGroup");
	AdditionalCIParameters.Insert("CITitleLocation", FormItemTitleLocation.Left);
	AdditionalCIParameters.Insert("DeferredInitialization", True);
	ContactsManager.OnCreateAtServer(ThisObject, Object, AdditionalCIParameters);
	// End StandardSubsystems.ContactInformation
	
	// StandardSubsystems.Properties
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization", True);
	PropertyManager.OnCreateAtServer(ThisForm, AdditionalParameters);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AccessManagement
	If AccessRight("Update", Metadata.Catalogs.Partners)
		Or AccessRight("Insert", Metadata.Catalogs.Partners) Then
		AccessManagement.OnCreateAccessValueForm(ThisForm);
	EndIf;
	// End StandardSubsystems.AccessManagement
	
	// StandardSubsystems.Interactions
	Interactions.PrepareNotifications(ThisForm, Parameters, False);
	// End StandardSubsystems.Interactions
	
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
	
	// Price Type Settings
	If UseSeveralPriceTypes Then
		UpdateIndividualPriceViewPresentation();
		RefreshUseGeneralPriceViewCheckbox();
		UpdateUseCustomPriceViewCheckbox();
		AdjustVisibilityAvailabilityOfGeneralPriceViewSettings(ThisForm);
		AdjustVisibilityAvailabilityOfIndividualPriceViewSettings(ThisForm);
	EndIf;
	// End of Setting Up Price types
	
	If Not ValueIsFilled(Object.Ref) Then
		
		OnReadCreateAtServer();
		
	EndIf;
	
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

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	PartnersAndCounterparties.WhatIsShapeOfElementWhenReadOnServer(ThisForm, CurrentObject); 
	
	// StandardSubsystems.ContactInformation
	ContactsManager.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.ContactInformation
	
	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisForm, CurrentObject);
	// End StandardSubsystems.Properties
	
	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	OnReadCreateAtServer();
	
	NationalLanguageSupportServer.OnReadAtServer(ThisObject, CurrentObject);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Handler of the "Properties" mechanism
	If PropertyManagerClient.ProcessNotifications(ThisForm, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	
	If EventName = "AddingPartnerToSegment"
		Or EventName = "RemovingPartnerFromSegment" Then
		
		UpdateShipmentBan(Object.Ref, ShipmentIsProhibited);
		SetAvailabilityOfShipmentBan();
		
	EndIf;
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.ContactInformation
	ContactsManager.FillCheckProcessingAtServer(ThisObject, Object, Cancel);
	// End StandardSubsystems.ContactInformation

	RetailSales.FillCheckProcessingAtServer(ThisObject, Cancel, CheckedAttributes);
		
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisForm, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// Handler of the "Properties" mechanism
	PropertyManager.BeforeWriteAtServer(ThisForm, CurrentObject);
	
	// StandardSubsystems.ContactInformation
	ContactsManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.ContactInformation

	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	NationalLanguageSupportServer.BeforeWriteAtServer(CurrentObject);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement

	// StandardSubsystems.ContactInformation
	ContactsManager.AfterWriteAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.ContactInformation
	
	PartnersAndCounterparties.PartnerFormOfItemAfterRecordingOnServer(ThisForm, CurrentObject, WriteParameters);

	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
	NationalLanguageSupportServer.OnReadAtServer(ThisObject, CurrentObject);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	InteractionsClient.ContactAfterWrite(ThisForm, Object, WriteParameters, "Partners");
	Notify("Write_Partners", Object.Ref);

	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands

EndProcedure

&AtClient
Procedure LabelsTemplateStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	FormParameters = New Structure();
	Filter = New Structure();
	Filter.Insert("Purpose",PredefinedValue("Enum.AssignmentsOfTemplatesOfPriceTagsAndLabels.LabelForDelivery"));
	FormParameters.Insert("Filter",Filter);
	LabelsTemplate = Undefined;

	OpenForm("Catalog.LabelAndPriceTagTemplates.ChoiceForm", FormParameters,,,,, New CallbackDescription("LabelsTemplateStartChoiceCompletion", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure LabelsTemplateStartChoiceCompletion(Result, AdditionalParameters) Export
    
    LabelsTemplate = Result;
    If LabelsTemplate=Undefined Then
        Return;
    EndIf;
    
    Object.LabelsTemplate =  LabelsTemplate;

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ChannelOfInitialRequestOnChange(Item)
	
	PartnersAndCounterpartiesClient.PartnerElementFormChannelOfPrimaryInterestWhenModified(ThisForm, Item);
	
EndProcedure 

&AtClient
Procedure DescriptionOnChange(Item)
	
	PartnersAndCounterpartiesClient.PartnerElementFormNameWhenChanged(ThisForm, Item);
	
EndProcedure

&AtClient
Procedure FlagIndicatesThePartnerWhenChanging(Item)
	
	PartnersAndCounterpartiesClient.PartnerElementFormFlagPartnerAttributeWhenChanging(ThisForm, Item);
	UpdateAdditionalAttributesItems();
	SetAvailabilityOfShipmentBan();
	EstablishPricingVisibility();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure CommentsStartChoice(Item, ChoiceData, StandardProcessing)
	
	PartnersAndCounterpartiesClient.PartnerElementFormCommentsStartSelection(ThisForm, Item, ChoiceData, StandardProcessing)
	
EndProcedure

&AtClient
Procedure BusinessRegionOnChange(Item)
	
	PartnersAndCounterpartiesClient.PartnerFormOfBusinessRegionElementWhenChanged(ThisForm, Item);
	
EndProcedure

&AtClient
Procedure DescriptionFullOnChange(Item)
	
	If IsBlankString(Object.Description) Then
		Object.Description = Object.DescriptionFull;
	EndIf;
	
EndProcedure

&AtClient
Procedure CompanyPrivatePersonInCaseOfChange(Item)
	
	ThisIsPrivatePerson = Object.LegalEntityIndividual = PredefinedValue("Enum.IndividualCompany.Person_");
	
	Items.Gender.Enabled                             = ThisIsPrivatePerson;
	Items.BirthDate.Enabled                    = ThisIsPrivatePerson;
	Items.OptionOfSendingElectronicReceipt.Enabled = ThisIsPrivatePerson;
	
	If ThisIsPrivatePerson Then
		Items.PagesPublicNameCompanyIndividual.CurrentPage = Items.PagePublicNameIndividual;
	Else
		Items.PagesPublicNameCompanyIndividual.CurrentPage = Items.PublicCompanyNamePage;
	EndIf;
	
EndProcedure

&AtClient
Procedure CompanyPrivatePersonCleaning(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

#Region SubsystemProceduresContactInformation

// StandardSubsystems.ContactInformation

&AtClient
Procedure Attachable_ContactInformationOnChange(Item)
	ContactsManagerClient.ToBeginUpdate(ThisObject, Item);
EndProcedure

&AtClient
Procedure Attachable_ContactInformationStartChoice(Item, ChoiceData, StandardProcessing)
	ContactsManagerClient.StartSelection(ThisObject, Item, , StandardProcessing);
EndProcedure

&AtClient
Procedure Attachable_ContactInformationOnClick(Item, StandardProcessing)
	ContactsManagerClient.StartSelection(ThisObject, Item,, StandardProcessing);
EndProcedure

// Handler for clearing contact information
// 
// Parameters:
// 	Item              - FormField - element of the form containing contact information.
// 	StandardProcessing - Boolean - indicates standard event handling.
//
&AtClient
Procedure Attachable_ContactInformationClearing(Item, StandardProcessing)
	ContactsManagerClient.StartClearing(ThisObject, Item.Name);
EndProcedure

// Handler for executing the "Contact information" subsystem command"
// 
// Parameters:
// 	Command - FormCommand -executed command
//
&AtClient
Procedure Attachable_ContactInformationExecuteCommand(Command)
	ContactsManagerClient.StartCommandExecution(ThisObject, Command.Name);
EndProcedure

&AtClient
Procedure Attachable_ContactInformationAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	ContactsManagerClient.AutoCompleteAddress(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing);
	
EndProcedure

// Event handler handling the selection of the "Contact information" subsystem"
// 
// Parameters:
// 	Item              - FormField - the form element where the event occurred.
// 	ValueSelected    - Structure - selected contact information.
// 	StandardProcessing - Boolean - indicates standard event handling.
//
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
// End StandardSubsystems.ContactInformation

&AtClient
Procedure GroupPagesOnCurrentPageChange(Item, CurrentPage)
	
	// StandardSubsystems.Properties
	If CurrentPage.Name = "GroupAdditionalAttributes"
		And Not ThisObject.PropertiesParameters.DeferredInitializationExecuted Then
		
		PropertiesExecuteDeferredInitialization();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.ContactInformation
	If CurrentPage.Name = ContactInformationParameters.ContactInformationGroup.GroupForPlacement
		And Not ContactInformationParameters.ContactInformationGroup.DeferredInitializationExecuted Then
		
		ContactInformationWhenChangingPages();
		
	EndIf;
	// End StandardSubsystems.ContactInformation
	
	If CurrentPage = Items.ContactInformationGroup Then
		
		CommandName = Commands.OpenListOfDeliveryPoints.Name;
		
		If Items.Find(CommandName) = Undefined Then
			
			DeliveryOfGoodsWhenChangingPage(CommandName);
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

&AtClient
Procedure UseGeneralViewOfPricesWhenChangingOnClient()

	If Not UseTheGeneralViewOfPrices Then
		
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
			CommonClientServer.MessageToUser(
				NStr("vi = 'Đã xảy ra lỗi khi vô hiệu hóa bảng giá riêng';
					|ru = 'Возникла ошибка при отключении индивидуального прайс листа';
					|en = 'An error occurred while disabling the individual price list'; fa = 'An error occurred while disabling the individual price list';
					|it = 'Si è verificato un errore durante la disabilitazione del listino prezzi individuale';
					|pl = 'Wystąpił błąd podczas wyłączenia indywidualnego cennika';
					|tr = 'Özelleştirilmiş fiyat listesi devre dışı bırakılırken hata oluştu'") + " "+  ShutdownResult.ErrorDescription,
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

&AtClient
Procedure UseTheGeneralViewOfPricesOnChange(Item)
	
	UseGeneralViewOfPricesWhenChangingOnClient();
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

&AtClient
Procedure Attachable_Opening(Item, StandardProcessing)
	
	NationalLanguageSupportClient.OnOpen(ThisObject, Object, Item, StandardProcessing);
	
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
Procedure OpenShipmentProhibitionSegmentForm(Command)
	
	ClearMessages();
	
	If Not ValueIsFilled(Object.Ref) Then
		
		QueryText = NStr("vi = 'Dữ liệu vẫn chưa được ghi lại.
		|Chỉ có thể chuyển đến cấm giao hàng sau khi ghi lại dữ liệu.
		|Dữ liệu sẽ được ghi lại.';
		|ru = 'Данные еще не записаны.
		|Переход к запрету отгрузки возможен только после записи данных.
		|Данные будут записаны.';
		|en = 'The data is not recorded. 
		|You can go to delivery block only after the data is recorded.
		|The data will be recorded.'; fa = 'The data is not recorded. 
		|You can go to delivery block only after the data is recorded.
		|The data will be recorded.';
		|it = 'Dati non ancora registrati.
		|Il passaggio al divieto di spedizione è possibile solo dopo la registrazione dei dati.
		|I dati verranno registrati.';
		|pl = 'Dane nie zostały jeszcze zapisane.
		|Przejście do zakazu wysyłki jest możliwe tylko po zapisaniu danych.
		|Dane zostaną zapisane.';
		|tr = 'Veriler henüz kaydedilmedi.
		|Teslimat engeline geçiş sadece verilerin kaydından sonra mümkündür.
		|Veriler kaydedilecektir.'");
		
		ShowQueryBox(New CallbackDescription("OpenShipmentProhibitionSegmentFormCompletion", ThisObject), QueryText, QuestionDialogMode.OKCancel);
		Return;
		
	EndIf;
	
	OpenForm("Catalog.Partners.Form.FormOfSegmentsOfShipmentProhibition", New Structure("Partner", Object.Ref));
	
EndProcedure

&AtClient
Procedure OpenShipmentProhibitionSegmentFormCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Cancel Then
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
	
	OpenForm("Catalog.Partners.Form.FormOfSegmentsOfShipmentProhibition", New Structure("Partner", Object.Ref));
	
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

&AtClient
Procedure OpenListOfDeliveryPoints(Command)
	
	ClearMessages();
	
	If Not ValueIsFilled(Object.Ref)
	 Or Modified Then
		
		QueryText = NStr("vi = 'Dữ liệu chưa được ghi lại.
		|Chỉ có thể chuyển đến các điểm giao hàng sau khi ghi lại phần tử.
		|Ghi lại phần tử?';
		|ru = 'Данные еще не записаны.
		|Переход к точкам доставки возможен только после записи элемента.
		|Записать элемент?';
		|en = 'The data is not saved yet.
		|You can go to delivery points only after the item is saved.
		|Save it?'; fa = 'The data is not saved yet.
		|You can go to delivery points only after the item is saved.
		|Save it?';
		|it = 'The data is not saved yet.
		|You can go to delivery points only after the item is saved.
		|Save it?';
		|pl = 'The data is not saved yet.
		|You can go to delivery points only after the item is saved.
		|Save it?';
		|tr = 'Veriler henüz kaydedilmedi.
		|Teslimat noktalarına geçiş yalnızca öğe kaydedildikten sonra mümkündür.
		| Öğe kaydedilsin mi?'");
		
		CallbackOnCompletion = New CallbackDescription("OpenDeliveryPointsEndForm", ThisObject);
		
		ShowQueryBox(CallbackOnCompletion, QueryText, QuestionDialogMode.YesNo);
		
	Else
		
		OpenListOfSubordinateDeliveryPoints();
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

// StandardSubsystems.Properties

&AtServer
Procedure PropertiesExecuteDeferredInitialization()
	PropertyManager.FillAdditionalAttributesInForm(ThisObject);
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

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AccessGroup.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("RecordLevelAccessRestrictionsAreUsed");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("MarkIncomplete", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.BirthDate.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Gender.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.LegalEntityIndividual");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Enabled", False);

EndProcedure

&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisForm);
	
EndProcedure

&AtClient
Procedure SetAvailabilityOfShipmentBan()
	
	If UseShipmentProhibition And Object.Client Then
		If ShipmentIsProhibited Then
			Items.BanPageGroup.CurrentPage = Items.GroupShipmentProhibited;
		Else
			Items.BanPageGroup.CurrentPage = Items.ShipmentPermittedGroup;
		EndIf;
	Else
		Items.BanPageGroup.CurrentPage = Items.GroupEmpty;
	EndIf;
	
EndProcedure

&AtServer
Procedure EstablishPricingVisibility()
	
	PricingVisibility = UseSeveralPriceTypes 
												And Object.Client
												And UsePriceManagementSystem25
												And Not ToUseTermsOfSales;
	
	Items.PricingGroup.Visible = PricingVisibility;
	Items.GroupGeneralViewOfPrices.Visible = PricingVisibility;
	Items.GroupIndividualTypeOfPrices.Visible = PricingVisibility;
	Items.HyperlinkGoToPriceList.Visible = PricingVisibility;
	Items.HyperlinkGoPriceChangeHistory.Visible = PricingVisibility;
	
EndProcedure

&AtServerNoContext
Procedure UpdateShipmentBan(Partner, ShipmentIsProhibited)
	
	ShipmentIsProhibited = SegmentsServer.PartnerIsIncludedInShipmentBanSegments(Partner);
	
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

&AtServer
Procedure RefreshUseGeneralPriceViewCheckbox()

	UseTheGeneralViewOfPrices = ValueIsFilled(Object.PricesKind);
	
EndProcedure

&AtServer
Procedure UpdateUseCustomPriceViewCheckbox()

	UseAnIndividualViewOfThePrice = ValueIsFilled(Object.SpecialPriceType);
	
EndProcedure

&AtClientAtServerNoContext
Procedure AdjustVisibilityAvailabilityOfGeneralPriceViewSettings(Form)
	
	Form.Items.PricesKind.Enabled = (Form.UseTheGeneralViewOfPrices And Not Form.Items.UseTheGeneralViewOfPrices.ReadOnly);
	
EndProcedure

&AtClientAtServerNoContext
Procedure AdjustVisibilityAvailabilityOfIndividualPriceViewSettings(Form)
	
	Form.Items.SpecialPriceTypePresentation.Enabled	= (Form.UseAnIndividualViewOfThePrice 
												And Not Form.Items.UseAnIndividualViewOfThePrice.ReadOnly)
												And Form.ItIsAllowedToCreatePriceTypes;
	Form.Items.UseAnIndividualViewOfThePrice.Enabled = Form.ItIsAllowedToCreatePriceTypes;
	
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
		ArrayOfTexts.Add(New FormattedString(NStr("vi = 'Dạng giá riêng (chưa tùy chỉnh)';
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
	
//	Display the user's notification("Creating an individual view of the price", , , , the status of the user's notification.Information );
	TransferResult = CreateIPLServer();
	
	If TransferResult.Result Then
		
		Read();
		UpdateIndividualPriceViewPresentation();
		ShowValue(Undefined, Object.SpecialPriceType);
		
	Else
		
		ClearMessages();
		CommonClientServer.MessageToUser(
			NStr("vi = 'Đã xảy ra lỗi khi tạo bảng giá riêng';
				|ru = 'Возникла ошибка при создании индивидуального прайс листа';
				|en = 'An error occurred while generating the individual price list'; fa = 'An error occurred while generating the individual price list';
				|it = 'Возникла ошибка при создании индивидуального прайс листа';
				|pl = 'An error occurred while generating the individual price list';
				|tr = 'Özelleştirilmiş fiyat listesi oluşturulurken hata oluştu'") + " " + TransferResult.ErrorDescription,
			Object.Ref,
			);
			
	EndIf;
	
EndProcedure

&AtServer
Function CreateIPLServer()
	
	TransferResult = SettingPricesServer.CreateIPL(Object.Ref, CurrentSessionDate());
	
	Return TransferResult;
	
EndFunction

// StandardSubsystems.ContactInformation
&AtServer
Procedure ContactInformationWhenChangingPages()
	
	ContactsManager.ExecuteDeferredInitialization(ThisObject, Object);
	
EndProcedure

&AtServer
Procedure UpdateContactInformation(Result)
	
	ContactsManager.UpdateContactInformation(ThisObject, Object, Result);
	
EndProcedure
// End StandardSubsystems.ContactInformation

&AtServer
Procedure DeliveryOfGoodsWhenChangingPage(CommandName)
	
	GoodsDelivery.AddCommandToNavigateToListOfDeliveryPoints(
		ThisObject,
		Items.ContactInformationGroup.Name,
		CommandName);
	
EndProcedure

&AtClient
Procedure OpenListOfSubordinateDeliveryPoints()
	
	Filter = New Structure;
	Filter.Insert("Owner", Object.Ref);
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("Filter", Filter);
	
	OpenForm("Catalog.DeliveryPoints.Form.OwnerDeliveryPoints", OpeningParameters);
	
EndProcedure

&AtClient
Procedure OpenDeliveryPointsEndForm(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		
		Try
			
			ItemRecorded = Write();
			
		Except
			
			ItemRecorded = False;
			
			Information = ErrorInfo();
			MessageText = NStr("vi = 'Không thể ghi lại phần tử';
								|ru = 'Не удалось записать элемент';
								|en = 'Cannot save the item'; fa = 'Cannot save the item';
								|it = 'Cannot save the item';
								|pl = 'Cannot save the item';
								|tr = 'Öğe kaydedilemedi'");
			Refinement = CommonClientServer.ExceptionClarification(Information, MessageText);
			ErrorPresentation = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			
			Raise(Refinement.Text, Refinement.Category,, ErrorPresentation, Information);
			
		EndTry;
		
		If ItemRecorded Then
			
			OpenListOfSubordinateDeliveryPoints();
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	GoodsDelivery.FillInDeliveryPlanningSelectionList(Items.DeliveryPlanning.ChoiceList, Object);
	
	If GoodsDeliveryClientServer.UsedDelivery25() Then
		
		TMCommonUseClientServer.SetFormItemProperty(Items, "DeliveryZone", "Visible", False);
		TMCommonUseClientServer.SetFormItemProperty(Items, "LabelsTemplate", "Visible", False);
		
	EndIf;
	
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
