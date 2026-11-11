#Region Variables
#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	UseSeveralPriceTypes            = GetFunctionalOption("UseSeveralPriceTypes");
	ItIsAllowedToCreatePriceTypes				 = UseSeveralPriceTypes
												And AccessRight("Insert", Metadata.Catalogs.TypesOfPrices);
	EstablishPricingVisibility();
	
	PartnersAndCounterparties.PartnerElementFormWhenCreatedOnServer(ThisForm, Cancel, StandardProcessing);
	
	ColorOfHyperlink        = StyleColors.HyperlinkColor;
	SimplifiedInputAvailable = PartnersAndCounterparties.SimplifiedInputAvailable() Or ReadOnly;
	
	If Object.Ref.IsEmpty() Then
		
		If ValueIsFilled(Parameters.CopyingValue) Then
			
			Query = New Query;
			Query.Text = "
			|SELECT ALLOWED TOP 1
			|	Counterparties.LegalEntityIndividual
			|FROM
			|	Catalog.Counterparties AS Counterparties
			|		INNER JOIN Catalog.Partners AS Partners
			|		ON Counterparties.Partner = Partners.Ref
			|WHERE
			|	Partners.Ref = &FillValue";
			
			Query.SetParameter("FillValue", Parameters.CopyingValue);
			
			Selection = Query.Execute().Select();
			If Selection.Next() Then
				LegalEntityIndividual =  Selection.LegalEntityIndividual;
			Else
				LegalEntityIndividual = Enums.LegalEntityIndividual.Entity;
			EndIf;
			
		Else
			LegalEntityIndividual = Enums.LegalEntityIndividual.Entity;
		EndIf;
		
		WhenCreatingAndReadingOnServer();
		
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
	ContactsManager.OnCreateAtServer(ThisObject, Object, AdditionalCIParameters);
	
	AdditionalCIParameters.Insert("ItemForPlacementName", "GroupContactInformationOfTheCounterparty");
	AdditionalCIParameters.Insert("CITitleLocation", FormItemTitleLocation.Left);
	AdditionalCIParameters.Insert("HiddenKinds",  TMCommonUseCached.ArrayOfExcludedTypesOfCounterpartyCIForOutputInPartnerForm());
	ContactsManager.OnCreateAtServer(ThisObject, PartnerSCounterparty, AdditionalCIParameters);
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
	
	
	CompanyIndividual = ?(Object.LegalEntityIndividual = Enums.IndividualCompany.Company, 
				Enums.CompanyIndividual.BusinessEntity,
				Enums.CompanyIndividual.Individual);
	
	
	
	
	If UsePriceManagementSystem25 Then
		FillInDescriptionOfCurrentParameters();
	EndIf;
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	// Price Type Settings
	If UseSeveralPriceTypes Then
		UpdateIndividualPriceViewPresentation();
		RefreshUseGeneralPriceViewCheckbox();
		UpdateUseCustomPriceViewCheckbox();
		AdjustVisibilityAvailabilityOfGeneralPriceViewSettings(ThisForm);
		AdjustVisibilityAvailabilityOfIndividualPriceViewSettings(ThisForm);
	EndIf;
	// End of Setting Up Price types  
	
	
	NationalLanguageSupportServer.OnCreateAtServer(ThisObject, Object);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	PartnersAndCounterparties.FillInPartnerCounterpartyDetails(ThisObject, CurrentObject.Ref);
	
	WhenCreatingAndReadingOnServer();
	PartnersAndCounterparties.WhatIsShapeOfElementWhenReadOnServer(ThisForm, CurrentObject);
	
	// StandardSubsystems.ContactInformation
	ContactsManager.OnReadAtServer(ThisObject, CurrentObject);
	ContactsManager.OnReadAtServer(ThisObject, PartnerSCounterparty, "GroupContactInformationOfTheCounterparty");
	// End StandardSubsystems.ContactInformation
	
	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisForm, CurrentObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	NationalLanguageSupportServer.OnReadAtServer(ThisObject, CurrentObject);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	Var Counterparty;
	
	If StrFind(EventName, "Record_") > 0 Then
		If ValueIsFilled(Parameter) And TypeOf(Parameter) = Type("Structure") Then
			
			Parameter.Property("Counterparty", Counterparty);
			If ValueIsFilled(Counterparty)
				And (Counterparty = PartnerSCounterparty) Then
					
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
	
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject)
	
	// Handler of the "Properties" mechanism
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	
	// Handler of the "Contact information" mechanism
	ContactsManager.BeforeWriteAtServer(ThisObject, CurrentObject, Cancel);
	
	NationalLanguageSupportServer.BeforeWriteAtServer(CurrentObject);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement

	PartnersAndCounterparties.PartnerFormOfItemAfterRecordingOnServer(ThisForm, CurrentObject, WriteParameters);
	RecordPartnerSCounterparty();
	AvailabilityControl(ThisForm);
	SetElementFormTitle();
	
	SparkleRecordingParameters = New Structure("CounterpartyRef", PartnerSCounterparty);
	
	
	// StandardSubsystems.ContactInformation
	ContactsManager.AfterWriteAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.ContactInformation
	
	PartnersAndCounterpartiesLocalization.AfterRecordingOnServerFormOfCounterpartySDetailsElement(CurrentObject, WriteParameters, ThisForm);
	
	NationalLanguageSupportServer.OnReadAtServer(ThisObject, CurrentObject);
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	PartnersAndCounterpartiesLocalizationClient.BeforeRecordingCounterparty(Cancel, WriteParameters, ThisForm);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	InteractionsClient.ContactAfterWrite(ThisForm, Object, WriteParameters, "Partners");
	Notify("Write_Partners", Object.Ref);
	NotifyChanged(PartnerSCounterparty);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	PartnersAndCounterparties.CheckWhetherCounterpartyIsFilledInCorrectly(ThisForm, PartnerSCounterparty, Cancel);
	
	// StandardSubsystems.ContactInformation
	ContactsManager.FillCheckProcessingAtServer(ThisForm, Object, Cancel);
	// End StandardSubsystems.ContactInformation
	
	RetailSales.FillCheckProcessingAtServer(ThisObject, Cancel, CheckedAttributes);
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisForm, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
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

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure GroupPagesOnCurrentPageChange(Item, CurrentPage)
	
	// StandardSubsystems.Properties
	If CurrentPage.Name = "GroupAdditionalAttributes"
		And Not ThisObject.PropertiesParameters.DeferredInitializationExecuted Then
		
		PropertiesExecuteDeferredInitialization();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
	If CurrentPage = Items.ContactInformationGroup Then
		
		CommandName = Commands.OpenListOfDeliveryPoints.Name;
		
		If Items.Find(CommandName) = Undefined Then
			
			DeliveryOfGoodsWhenChangingPage(CommandName);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ChannelOfInitialRequestOnChange(Item)
	
	PartnersAndCounterpartiesClient.PartnerElementFormChannelOfPrimaryInterestWhenModified(ThisForm, Item);
	
EndProcedure 

&AtClient
Procedure DescriptionOnChange(Item)
	
	PartnersAndCounterpartiesClient.PartnerElementFormNameWhenChanged(ThisForm,Item);
	
EndProcedure

&AtClient
Procedure FlagIndicatesThePartnerWhenChanging(Item)
	
	PartnersAndCounterpartiesClient.PartnerElementFormFlagPartnerAttributeWhenChanging(ThisForm, Item);
	UpdateAdditionalAttributesItems();
	SetAvailabilityOfShipmentBan();
	EstablishPricingVisibility();
	
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
Procedure CounterpartyKindOnChange(Item)
	
	Attachable_OnChangeAttribute(Item);
	
	If IsBlankString(CounterpartyKind) Then
		
		LegalEntityIndividual = PredefinedValue("Enum.LegalEntityIndividual.EmptyRef");
		BranchOffice = False;
		If MainCounterparty <> PartnerSCounterparty Then
			MainCounterparty = Undefined;
		EndIf;
		
	ElsIf CounterpartyKind = "BranchOffice" Then
		
		LegalEntityIndividual = PredefinedValue("Enum.LegalEntityIndividual.Entity");
		BranchOffice = True;
		
		If MainCounterparty = PartnerSCounterparty Then
			MainCounterparty = Undefined;
		EndIf;
		
	Else
		
		LegalEntityIndividual = PredefinedValue("Enum.LegalEntityIndividual." + CounterpartyKind);
		BranchOffice = False;
		
		If MainCounterparty <> PartnerSCounterparty Then
			MainCounterparty = Undefined;
		EndIf;
		
	EndIf;
	
	If LegalEntityIndividual = PredefinedValue("Enum.LegalEntityIndividual.Person") Then
		Object.LegalEntityIndividual = PredefinedValue("Enum.IndividualCompany.Person_");
	Else
		Object.LegalEntityIndividual = PredefinedValue("Enum.IndividualCompany.Company");
	EndIf;
	
	
	AvailabilityControl(ThisObject);
	ClearMarkIncomplete();
	
	
EndProcedure

&AtClient
Procedure MainCounterpartyOnChange(Item)
	
	Attachable_OnChangeAttribute(Item);
	ClearMarkIncomplete();
	
EndProcedure

&AtClient
Procedure DescriptionFullOnChange(Item)
	
	Attachable_OnChangeAttribute(Item);
	PartnersAndCounterpartiesClient.AbbreviatedLegalEntityNameWhenChanged(Object.Description, Object.DescriptionFull);
	
EndProcedure

&AtClient
Procedure RegistrationCountryOnChange(Item)   
	
	
EndProcedure

&AtClient
Procedure LabelsTemplateStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	FormParameters = New Structure();
	Filter = New Structure();
	Filter.Insert("Purpose",PredefinedValue("Enum.AssignmentsOfTemplatesOfPriceTagsAndLabels.LabelForDelivery"));
	FormParameters.Insert("Filter",Filter);
	LabelsTemplate = Undefined;

	OpenForm("Catalog.LabelAndPriceTagTemplates.ChoiceForm",FormParameters,,,,, New CallbackDescription("LabelsTemplateStartChoiceCompletion", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure LabelsTemplateStartChoiceCompletion(Result, AdditionalParameters) Export
    
    LabelsTemplate = Result;
    If LabelsTemplate=Undefined Then
        Return;
    EndIf;
    
    Object.LabelsTemplate =  LabelsTemplate;

EndProcedure

&AtClient
Procedure GoToNameHistoryURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	If FormattedStringURL = "NameHistory" Then
		
		FormParameters = New Structure;
		FormParameters.Insert("CurFullName", Object.DescriptionFull);
		FormParameters.Insert("NameHistory",       NameHistory);
		FormParameters.Insert("ReadOnly",            ReadOnly);
		FormParameters.Insert("LegalEntityIndividual",                 LegalEntityIndividual);
		
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
					|tr = 'Özelleştirilmiş fiyat listesi devre dışı bırakılırken hata oluştu'") + " " + ShutdownResult.ErrorDescription,
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

#EndRegion

#Region FormTableItemsEventHandlersContactInformation

// StandardSubsystems.ContactInformation

&AtClient
Procedure Attachable_ContactInformationOnChange(Item)
	ContactsManagerClient.ToBeginUpdate(ThisObject, Item);
EndProcedure

// Event handler start selecting the "Contact information" subsystem"
// 
// Parameters:
// 	Item              - FormField - the form element where the event occurred.
// 	ChoiceData         - Structure - data used for selection.
// 	StandardProcessing - Boolean - indicates standard event handling.
//
&AtClient
Procedure Attachable_ContactInformationStartChoice(Item, ChoiceData, StandardProcessing)
	
	OpeningParameters = New Structure("Country", RegistrationCountry);
	
	Filter = New Structure("AttributeName", Item.Name);
	Rows = ThisObject.ContactInformationAdditionalAttributesDetails.FindRows(Filter); // SeeContactsManagerClientServer.DescriptionOfTheContactInformationOnTheForm
	RowData = ?(Rows.Count() = 0, Undefined, Rows[0]);
	If RowData <> Undefined Then
		If RowData.Kind = PredefinedValue("Catalog.ContactInformationKinds.InternationalAddressOfCounterparty") Then
			OpeningParameters.Insert("AllowAddressInputInFreeForm", False);
		EndIf;
		If (RowData.Kind = PredefinedValue("Catalog.ContactInformationKinds.LegalAddressOfCounterparty")
			Or RowData.Kind = PredefinedValue("Catalog.ContactInformationKinds.ActualDataCounterpartyAddress")) Then
			OpeningParameters.Insert("Country", RegistrationCountry);
		EndIf;
	EndIf;
	
	ContactsManagerClient.StartSelection(ThisObject, Item,, StandardProcessing, OpeningParameters);
	
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

&AtClient
Procedure FillInByTIN(Command)
	
	Attachable_ExecuteLocalizationCommand(Command);
	

EndProcedure

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

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	PartnersAndCounterpartiesLocalization.EstablishConditionalAppearanceCounterparty(ThisForm);
	
EndProcedure

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
&AtServer
Procedure UpdateAdditionalAttributesItems()
	PropertyManager.UpdateAdditionalAttributesItems(ThisForm);
EndProcedure
// End StandardSubsystems.Properties

&AtClientAtServerNoContext
Procedure AvailabilityControl(Form)
	
	PartnersAndCounterpartiesLocalizationClientServer.ManagingElementsOfLegalDetails(Form);
	PartnersAndCounterpartiesLocalizationClientServer.ManagingCounterpartyAvailability(Form);
	PartnersAndCounterpartiesLocalizationClientServer.ManagingVisibilityOfCommitteeSVATAccountingSettings(Form);
	
	PartnersAndCounterpartiesLocalizationClientServer.UpdateTitleHistoryLines(Form.NameHistory,
		Form.GoToNameHistory,
		Form.ColorOfHyperlink);
	SelfServiceClientServer.ManagingPagesOfLegalEntitiesWhenChangesOccur(Form, Form.LegalEntityIndividual);

	Form.Items.FullNameCompany.ReadOnly    = Form.NameHistory.Count() > 1;
	Form.Items.FullNamePrivatePerson.ReadOnly = Form.NameHistory.Count() > 1;
	
EndProcedure

&AtServer
Procedure RecordPartnerSCounterparty()
	
	CreateCounterparty = PartnerSCounterparty.IsEmpty();
	
	If CreateCounterparty Then
		CounterpartyObject = Catalogs.Counterparties.CreateItem();
	Else
		CounterpartyObject = PartnerSCounterparty.GetObject();
	EndIf;
	
	ContactsManager.BeforeWriteAtServer(ThisObject, CounterpartyObject);
	
	CounterpartyObject.Description = Object.Description;
	CounterpartyObject.DescriptionFull        = Object.DescriptionFull;
	CounterpartyObject.DescriptionInternational = DescriptionInternational;  
	CounterpartyObject.NameInLetters = NameInLetters;
	CounterpartyObject.Partner                   = Object.Ref;
	CounterpartyObject.LegalEntityIndividual                 = LegalEntityIndividual;
	CounterpartyObject.BranchOffice = BranchOffice;
	CounterpartyObject.RegistrationCountry         = RegistrationCountry;
	CounterpartyObject.RegistrationNumber      = RegistrationNumber;
	CounterpartyObject.TaxNumber            = TaxNumber;
	CounterpartyObject.TIN                       = TIN;
	CounterpartyObject.NameHistory.Load(NameHistory.Unload());
	
	If Not ValueIsFilled(MainCounterparty) And Not BranchOffice Then
		
		If CreateCounterparty Then
			NewRef = Catalogs.Counterparties.GetRef();
			CounterpartyObject.SetNewObjectRef(NewRef);
			MainCounterparty = CounterpartyObject.GetNewObjectRef();
		Else
			MainCounterparty = PartnerSCounterparty;
		EndIf;
		
	EndIf;
	CounterpartyObject.MainCounterparty = MainCounterparty;
	PartnersAndCounterparties.FillInContactInformationOfPartnerCounterparty(CounterpartyObject, ThisObject, Object.ContactInformation);
	PartnersAndCounterpartiesLocalization.BeforeRecordingPartnerSCounterparty(CounterpartyObject, ThisForm);
	CounterpartyObject.Write();
	
	PartnerSCounterparty = CounterpartyObject.Ref;
	
EndProcedure 

&AtServer
Procedure WhenCreatingAndReadingOnServer()
	
	UsePriceManagementSystem25 = PriceManagementSystemServerCall.UsePriceManagementSystem25();
	
	If GetFunctionalOption("UseMultiCountryAccounting") Then
		If Object.LegalEntityIndividual <> Enums.LegalEntityIndividual.LegalEntityNonResident Then
			LegalEntityNonResident = Items.CounterpartyKind.ChoiceList.FindByValue("LegalEntityNonResident");
			If LegalEntityNonResident <> Undefined Then
				Items.CounterpartyKind.ChoiceList.Delete(LegalEntityNonResident);
			EndIf;
		EndIf;
	EndIf;

	PartnersAndCounterpartiesLocalization.WhenReadingCreatingOnServerCounterparty(ThisForm);
	ObjectChangeRight = AccessRight("Update", Metadata.Catalogs.Partners);
	
	If Not ValueIsFilled(LegalEntityIndividual) Then
		LegalEntityIndividual = ?(Object.LegalEntityIndividual = Enums.IndividualCompany.Company, 
				Enums.LegalEntityIndividual.Entity,
				Enums.LegalEntityIndividual.Person);
	EndIf;
	
	If BranchOffice Then
		CounterpartyKind = "BranchOffice";
	ElsIf ValueIsFilled(LegalEntityIndividual) Then
		CounterpartyKind = Common.EnumerationValueName(LegalEntityIndividual);
	EndIf;
	
	AvailabilityControl(ThisForm);
	SetElementFormTitle();
	
	GoodsDelivery.FillInDeliveryPlanningSelectionList(Items.DeliveryPlanning.ChoiceList, Object);
	UsedDelivery25 = GoodsDeliveryClientServer.UsedDelivery25();
	If UsedDelivery25 Then
		
		TMCommonUseClientServer.SetFormItemProperty(Items, "LabelsTemplate", "Visible", False);
		
	EndIf;
	
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

&AtServerNoContext
Procedure UpdateShipmentBan(Partner, ShipmentIsProhibited)
	
	ShipmentIsProhibited = SegmentsServer.PartnerIsIncludedInShipmentBanSegments(Partner);
	
EndProcedure

&AtServer
Procedure SetElementFormTitle()

	If Object.Ref.IsEmpty() Then
		
		Title = NStr("vi = 'Đối tác (tạo mới)';
					|ru = 'Контрагент (создание)';
					|en = 'Counterparty (Create)'; fa = 'Counterparty (Create)';
					|it = 'Contraente (creazione)';
					|pl = 'Kontrahent (tworzenie)';
					|tr = 'Cari hesap (oluşturma)'");
		
	Else
		
		Title = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '%1 (Đối tác)';
																				|ru = '%1 (Контрагент)';
																				|en = '%1 (Counterparty)'; fa = '%1 (Counterparty)';
																				|it = '%1 (Controparte)';
																				|pl = '%1 (Kontrahent)';
																				|tr = '%1 (Cari hesap)'"), Object.Description);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure EstablishPricingVisibility()
	
	Items.PricingGroup.Visible = UseSeveralPriceTypes 
												And Object.Client
												And UsePriceManagementSystem25;
	
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
													|en = 'customize'; fa = 'customize';
													|it = 'impostare';
													|pl = 'customize';
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
													|en = 'customize'; fa = 'customize';
													|it = 'impostare';
													|pl = 'customize';
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

#Region PeriodicDetails

&AtClient
Procedure HistoryOfTitlesAfterClosing(Result, AdditionalParameters) Export

	Var MessageText;
	
	ClearMessages();
	
	If TypeOf(Result) = Type("Structure") 
		And Result.Property("NameHistory") Then
		
		Modified = True;
		NewHistoryOfNames = Result.NameHistory;
		NewHistoryOfNames.Sort("Period");
	
		NameHistory.Clear();
		If NewHistoryOfNames.Count() > 1 Then
			For Each HistoryRow In NewHistoryOfNames Do
				RecordingHistory = NameHistory.Add();
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

#Region VerificationOfCounterparties

&AtClient
Procedure ValidateCounterparty(Command)
	
	
EndProcedure


#EndRegion

&AtServer
Procedure UpdateContactInformation(Result)
	
	ContactsManager.UpdateContactInformation(ThisObject, Object, Result);
	
EndProcedure

&AtServer
Procedure FillInDescriptionOfCurrentParameters(RegisterName = "")
	
	PartnersAndCounterpartiesLocalization.FillInDescriptionOfCurrentCounterpartyParameters(ThisObject, PartnerSCounterparty, RegisterName);
	
EndProcedure

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
