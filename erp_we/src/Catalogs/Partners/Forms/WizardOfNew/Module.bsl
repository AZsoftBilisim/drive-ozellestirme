#Region Variables

&AtClient
Var ClosingInProgress;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	If Parameters.Property("ChoiceMode") And Parameters.ChoiceMode Then
		ForSelection = True;
	EndIf;

	SimplifiedInputAvailable              = PartnersAndCounterparties.SimplifiedInputAvailable();
	ObjectChangeRight               = True;
	UseBusinessRegions           = GetFunctionalOption("UseBusinessRegions");
	RecordInitialRequest         = GetFunctionalOption("RecordInitialRequest");
	OnlyPartnersAreUsed          = GetFunctionalOption("UsePartnersAsCounterparties");
	UseAdditionalBankingDetails_3 = GetFunctionalOption("UseAdditionalAttributesAndInfo");
	ThisIsBasic                          = GetFunctionalOption("BaseVersion");
	
	RightToEditSegmentComposition = AccessRight("Update", Metadata.InformationRegisters.SegmentPartners);
	
	IssueBankAccountsWhenCreatingOnServer();
	
	Items.WizardPages.PagesRepresentation = FormPagesRepresentation.None;
	Items.PagesCompanyPrivatePerson.PagesRepresentation = FormPagesRepresentation.None;
	Items.ThePageWillBeCreated.PagesRepresentation = FormPagesRepresentation.None;
	Items.DecorationPrimaryInformationDownload.Visible = Not ThisIsBasic;
	OpenAfterCreation = True;
	
	MainManager                = Users.CurrentUser();
	CurrencyOfComplianceAccounting                 = SettingsValueCached.DefaultBaseCurrency();
	CashCurrency           = CurrencyOfComplianceAccounting;
	
	YouHaveTheRightToIncludeItInTheSegment = SegmentsServer.YouHaveRightToChangeCompositionOfSegments("Partners");
	Items.Segment.Visible            = YouHaveTheRightToIncludeItInTheSegment;
	Items.SegmentPrivatePerson.Visible = YouHaveTheRightToIncludeItInTheSegment;
	
	If Parameters.Property("ReturnTheLinkToTheCounterparty") Then
		ReturnTheLinkToTheCounterparty = Parameters.ReturnTheLinkToTheCounterparty;
	EndIf;
		
	If Parameters.Property("ListFilterByPartnerType") Then
		
		For Each ListItem In Parameters.ListFilterByPartnerType Do
			If ListItem.Value <> "OurEnterprise" Then
				ThisObject[ListItem.Value] = True;
			EndIf;
		EndDo;
		
	ElsIf Parameters.Property("ChoiceParameters")  Then
		
		If Parameters.ChoiceParameters.Property("Client")
			And Parameters.ChoiceParameters.Client Then
			
			Client = True;
			
		EndIf;
		
		If Parameters.ChoiceParameters.Property("Vendor")
			And Parameters.ChoiceParameters.Vendor Then
			
			Vendor = True;
			
		EndIf;
		
		If Parameters.ChoiceParameters.Property("Competitor")
			And Parameters.ChoiceParameters.Competitor Then
			
			Competitor = True;
			
		EndIf;
		
		If Parameters.ChoiceParameters.Property("OtherRelations")
			And Parameters.ChoiceParameters.OtherRelations Then
			
			OtherRelations = True;
			
		EndIf;
		
		If Parameters.ChoiceParameters.Property("Carrier")
			And Parameters.ChoiceParameters.Carrier Then
			
			Carrier = True;
			
		EndIf;
		
		If Parameters.ChoiceParameters.Property("ServedBySalesRepresentatives")
			And Parameters.ChoiceParameters.ServedBySalesRepresentatives Then
			
			ServedBySalesRepresentatives = True;
			
		EndIf;
		
	EndIf;
	
	If ServedBySalesRepresentatives Then
		Client = True;
	EndIf;
	
	If Carrier Then
		Vendor = True;
	EndIf;
	
	FillPropertyValues(PartnerTheObjectOfAdditionalDetails, ThisObject, "Client, Competitor, Vendor, OtherRelations");
	AdditionalDetailsElementsNeedToBeUpdated = True;
	UpdateDependentDetailsOfPartnerAttribute(ThisObject);
	
	If Parameters.Property("Basis") And TypeOf(Parameters.Basis) = Type("Structure") Then
		
		If Parameters.Basis.Property("Description") Then
			
			If OnlyPartnersAreUsed Then
				Name1 = Parameters.Basis["Description"];
			Else
				FullDescr = Parameters.Basis["Description"];
			EndIf;
			
		ElsIf Parameters.Basis.Property("LongDesc") Then
			
			If OnlyPartnersAreUsed Then
				FullLegalName = Parameters.Basis["LongDesc"];
			Else
				FullDescr = Parameters.Basis["LongDesc"];
			EndIf;
			
		EndIf;
		
		If Parameters.Basis.Property("EppartnerSAddress") Then
			EppartnerSAddress = Parameters.Basis.EppartnerSAddress;
		EndIf;
		
		If Parameters.Basis.Property("NameAbbreviated") Then
			FullLegalName = Parameters.Basis.NameAbbreviated;
		EndIf;
		
		If Parameters.Basis.Property("LegalAddress") Then
			
			LegalAddress = Parameters.Basis.LegalAddress;
			ValuesOfContactInformationFieldsServer(LegalAddress,
			                                        LegalAddressFieldValues,
			                                        Catalogs.ContactInformationKinds.LegalAddressOfCounterparty);
			SpecifyLegalDetails = True;
			
		EndIf;
		
		If SpecifyLegalDetails Then
			NameOfTheCounterparty = ?(OnlyPartnersAreUsed, FullLegalName, FullDescr);
		EndIf;
		
	ElsIf Parameters.Property("CounterpartyFoundation") And TypeOf(Parameters.CounterpartyFoundation) = Type("Structure") Then
		
		FillInBasedOnCounterparty(Parameters.CounterpartyFoundation,Cancel);
		If Cancel Then
			Return;
		EndIf;
		
	ElsIf Parameters.Property("IntroducingNewRetailBuyer") And Parameters.IntroducingNewRetailBuyer Then
		
		WhenCreatingNewRetailBuyer();
		
	ElsIf ValueIsFilled(Parameters.BasisSeparateCounterparty) Then
		
		WhenCreatingNewHeadCounterparty();
		
	ElsIf Not Parameters.Property("WorkingWithCounterpartiesCreatingFromCounterpartyProfile")
		And Parameters.Property("FillingText")
		And Not IsBlankString(Parameters.FillingText) Then
		
		If OnlyPartnersAreUsed Then
			FullLegalName = Parameters.FillingText;
		Else
			FullDescr = Parameters.FillingText;
		EndIf;
		
	EndIf;
	
	// Consider the possibility of creating from interaction
	Interactions.PrepareNotifications(ThisObject,Parameters,False);
	
	ProcessElementsForEditingContactInformation();

	PartnersAndCounterpartiesLocalization.WhenCreatingNewFormOnServer(ThisObject, Cancel, StandardProcessing);
	
	// access groups
	AccessManagement.OnCreateAccessValueForm(ThisObject, "AccessGroup",, Type("CatalogRef.Partners"), True);
	PartnerAccessGroupsAreUsed = Catalogs.PartnerAccessGroups.AccessGroupsAreUsed();
	If Not PartnerAccessGroupsAreUsed Then
		Items.AccessGroupPrivatePerson.Visible = False;
	EndIf;
	
	//OnlyPartnersAreUsed
	If OnlyPartnersAreUsed Then
	
		SpecifyLegalDetails = Not BasedOnRetailCustomerData;
		Items.PagesSpecifyLegalDetailsCounterpartyBasis.Visible  = False;
		Items.PagesSpecifyCreateCounterpartyBaseObject.Visible   = False;
		Items.WorkingNamePrivatePerson.Visible                   = False;
		Items.AbbreviatedLegalEntityNameOfTheCounterparty.Visible                    = False;
		Items.FillInByNameAccordingToTheUnifiedStateRegisters.Visible = False;
		Items.ActionWithTheCounterparty.Visible                            = False;
		Items.SpecifyTheCounterpartySBankAccount.Title                 = NStr("vi = 'Chỉ ra dữ liệu tài khoản ngân hàng.';
																				|ru = 'Указать данные банковского счета.';
																				|en = 'Specify bank account details.'; fa = 'Specify bank account details.';
																				|it = 'Specificare i dettagli del conto bancario.';
																				|pl = 'Wskaż dane rachunku bankowego.';
																				|tr = 'Banka hesap bilgilerini belirt.'");
		Items.PagesNameOfThePartner.CurrentPage = Items.PageSocrJurName;
		
		Items.ActionBasedOnResultsFound.ChoiceList.Delete(1);
		Items.ActionBasedOnResultsFound.ChoiceList.Get(0).Presentation = NStr("vi = 'Không ghi nhận đối tác mới, sử dụng đối tác đã tìm thấy.';
																				|ru = 'Не регистрировать нового контрагента, использовать найденного.';
																				|en = 'Do not register a new counterparty, use a found one.'; fa = 'Do not register a new counterparty, use a found one.';
																				|it = 'Non registrare un nuovo contraente, usare quello trovato.';
																				|pl = 'Nie rejestruj nowego kontrahenta, używaj znalezionego.';
																				|tr = 'Yeni cari hesabı kaydetme, bulunanı kullan.'");
		Items.ActionBasedOnResultsFound.ChoiceList.Get(1).Presentation = NStr("vi = 'Tiếp tục ghi nhận đối tác mới.';
																				|ru = 'Продолжить регистрацию нового контрагента.';
																				|en = 'Continue registering the new counterparty.'; fa = 'Continue registering the new counterparty.';
																				|it = 'Continuare la registrazione di un nuovo contraente.';
																				|pl = 'Kontynuuj rejestrację nowego kontrahenta.';
																				|tr = 'Yeni cari hesap kaydına devam et.'");
		
	EndIf;
	
	PageVisibilityPrimaryInformation();
	
	SetHeaders();
	
	DetermineWhetherContactInformationIsMandatory();
	
	// StandardSubsystems.Properties
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ItemForPlacementName",   "GroupAdditionalAttributes");
	AdditionalParameters.Insert("CommandBarItemName", "ChangingTheCompositionOfAdditionalBankingDetails");
	AdditionalParameters.Insert("Object", PartnerTheObjectOfAdditionalDetails);
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	// End StandardSubsystems.Properties
	
	LegalEntityIndividual = PartnerSLegalEntityType(ThisIsACompany);
	
	If GetFunctionalOption("UseMultiCountryAccounting") Then
		Items.TypeOfLegalEntityFace.ChoiceList.Delete(1);
	EndIf;
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	AddtlLanguagesAreUsed = False;
	If Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport.Print") Then
		PrintManagementModuleNationalLanguageSupport = Common.CommonModule("PrintManagementNationalLanguageSupport");
		AddtlLanguagesAreUsed = PrintManagementModuleNationalLanguageSupport.AdditionalLanguagesOfPrintedFormsAreUsed();
	EndIf;
	
	If AddtlLanguagesAreUsed
		Or Not Metadata.Languages.Count() = 1 Then
		
		MultilanguageAttributesParameters = New Structure;
		
		If OnlyPartnersAreUsed Then
			
			MultilanguageAttributesParameters.Insert("AbbreviatedLegalNamePartnersOnly", "Description");
			
			Items["AbbreviatedLegalNamePartnersOnly"].OpenButton = True;
			Items["AbbreviatedLegalNamePartnersOnly"].SetAction("Opening", "Attachable_Opening");
			
		Else
			
			MultilanguageAttributesParameters.Insert("PublicName", "Description");
			MultilanguageAttributesParameters.Insert("AbbreviatedLegalEntityNameOfTheCounterparty", "Description");
			
			Items["PublicName"].OpenButton = True;
			Items["PublicName"].SetAction("Opening", "Attachable_Opening");
			
			Items["AbbreviatedLegalEntityNameOfTheCounterparty"].OpenButton = True;
			Items["AbbreviatedLegalEntityNameOfTheCounterparty"].SetAction("Opening", "Attachable_Opening");
			
		EndIf;
		
		MultilanguageAttributesParameters.Insert("WorkingNamePrivatePerson", "Description");
		Items["WorkingNamePrivatePerson"].OpenButton = True;
		Items["WorkingNamePrivatePerson"].SetAction("Opening", "Attachable_Opening");
		
	EndIf;
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	ClearMarkIncomplete();
	
	SetVisibilityOfDeliveryZone();
	
	ManagingBasementPages();
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Not Exit And Not ClosingInProgress Then
		
		If CreationCompleted Then
			Return;
		EndIf;
		
		NecessityOfQuestion = False;
		
		If Items.WizardPages.CurrentPage = Items.PageFound And ActionBasedOnResultsFound = 0 Then
			NecessityOfQuestion = False;
		ElsIf Items.WizardPages.CurrentPage <> Items.PrimaryInformationPage Then
			NecessityOfQuestion = True;
		Else
			If ThisIsACompany = 0 Then
				If ValueIsFilled(Name1) Or ValueIsFilled(PartnerSPhoneNumber) Or ValueIsFilled(EppartnerSAddress) Then
					NecessityOfQuestion = True;
				ElsIf SpecifyLegalDetails And TypeOfCompany = 1 Then
					If ValueIsFilled(NameOfTheCounterparty) Then
						NecessityOfQuestion = True;
					EndIf
				ElsIf SpecifyTheContactPersonSDetails And (ValueIsFilled(LastNameKL) Or ValueIsFilled(KLName) Or ValueIsFilled(PatronymicKL)
					Or ValueIsFilled(PhoneNumberKL) Or ValueIsFilled(EPCLAddress) Or ValueIsFilled(MobilePhoneKL) Or
					ValueIsFilled(Role)) Then
					NecessityOfQuestion = True;
				EndIf;
			Else
				If ValueIsFilled(PartnerSLastName) Or ValueIsFilled(PartnerName_3) Or ValueIsFilled(PartnerSMiddleName)
					Or ValueIsFilled(EppartnerSAddressIndividual) Or ValueIsFilled(PartnerSPhoneNumberIndividual) Then
					NecessityOfQuestion = True;
				EndIf;
			EndIf;
		EndIf;
		
		If Not NecessityOfQuestion Then
			NecessityOfQuestion = PartnersAndCounterpartiesLocalizationClient.NeedForQuestionBeforeClosing(ThisObject);
		EndIf;
		
		If NecessityOfQuestion Then
			Cancel = True;
			ShowQueryBox(New CallbackDescription("BeforeCloseCompletion", ThisObject), NStr("vi = 'Thông tin đã nhập sẽ bị mất. Vẫn đóng?';
																							|ru = 'Введенная информация будет потеряна. Все равно закрыть?';
																							|en = 'The entered data will be lost. Close anyway?'; fa = 'The entered data will be lost. Close anyway?';
																							|it = 'Le informazioni inserite verranno perse. Chiudere lo stesso?';
																							|pl = 'Wprowadzona informacja zostanie utracona. Zamknąć mimo wszystko?';
																							|tr = 'Girilen bilgiler kaybolacaktır. Yine de kapatılsın mı?'"),QuestionDialogMode.YesNo);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeCloseCompletion(QuestionResult, AdditionalParameters) Export
	Response = QuestionResult;
	If Response = DialogReturnCode.Yes Then
		ClosingInProgress = True;
		Close();
	EndIf;
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "AfterInputStringsInDifferentLanguages"
		And ThisObject.UUID = Parameter.UUID Then
		
		If OnlyPartnersAreUsed Then
			
			FullLegalName = PartnerTheObjectOfAdditionalDetails.Description;
			
		Else
			
			If ChangingNameOfPartnerSCounterparty = "Partner" Then
				
				FullDescr = PartnerTheObjectOfAdditionalDetails.Description;
				ChangingNameOfPartnerSCounterparty = "";
				
				If ThisIsACompany = 1 Then
					
					CounterpartyForInternationalAttributes.Description = PartnerTheObjectOfAdditionalDetails.Description;
					CounterpartyForInternationalAttributes.DescriptionLanguage1 = PartnerTheObjectOfAdditionalDetails.DescriptionLanguage1;
					CounterpartyForInternationalAttributes.DescriptionLanguage2 = PartnerTheObjectOfAdditionalDetails.DescriptionLanguage2;
					
				EndIf;
				
			ElsIf ChangingNameOfPartnerSCounterparty = "Counterparty" Then
				
				FullLegalName = CounterpartyForInternationalAttributes.Description;
				ChangingNameOfPartnerSCounterparty = "";
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

#Region ContactInformationHandlers

#Region ContactInformationOfContactPerson

&AtClient
Procedure PhoneNumberKLStartChoice(Item, ChoiceData, StandardProcessing)
		
	StandardProcessing = False;
	
	ProcessingEventOfKIPhoneElement(
		Item,
		PredefinedValue("Catalog.ContactInformationKinds.ContactPersonSPhoneNumber"),
		"PhoneNumberKL",
		"PhoneNumberOfFieldValues",
		"StartChoice");
	
EndProcedure

&AtClient
Procedure PhoneNumberKLOnChange(Item)
	
	ProcessingEventOfKIPhoneElement(
		Item,
		PredefinedValue("Catalog.ContactInformationKinds.ContactPersonSPhoneNumber"),
		"PhoneNumberKL",
		"PhoneNumberOfFieldValues",
		"OnChange");
	
EndProcedure

&AtClient
Procedure PhoneNumberKLClearing(Item, StandardProcessing)
	
	ProcessingEventOfKIPhoneElement(
		Item,
		PredefinedValue("Catalog.ContactInformationKinds.ContactPersonSPhoneNumber"),
		"PhoneNumberKL",
		"PhoneNumberOfFieldValues",
		"Clearing");
	
EndProcedure

&AtClient
Procedure MobilePhoneKLStartChoice(Item, ChoiceData, StandardProcessing)
		
	StandardProcessing = False;
	
	ProcessingEventOfKIPhoneElement(
		Item,
		PredefinedValue("Catalog.ContactInformationKinds.ContactPersonSMobilePhoneNumber"),
		"MobilePhoneKL",
		"MobilePhoneNumberFieldValues",
		"StartChoice");
	
EndProcedure   

&AtClient
Procedure MobilePhoneKLOnChange(Item)
	
	ProcessingEventOfKIPhoneElement(
		Item,
		PredefinedValue("Catalog.ContactInformationKinds.ContactPersonSMobilePhoneNumber"),
		"MobilePhoneKL",
		"MobilePhoneNumberFieldValues",
		"OnChange");
	
EndProcedure

&AtClient
Procedure MobilePhoneKLClearing(Item, StandardProcessing)
	
	ProcessingEventOfKIPhoneElement(
		Item,
		PredefinedValue("Catalog.ContactInformationKinds.ContactPersonSMobilePhoneNumber"),
		"MobilePhoneKL",
		"MobilePhoneNumberFieldValues",
		"Clearing");
	
EndProcedure

&AtClient
Procedure EPCLAddressOnChange(Item)
	ClearMarkIncomplete();
EndProcedure

#EndRegion

#Region CompanyContactInformation

&AtClient
Procedure PartnerSPhoneNumberStartChoice(Item, ChoiceData, StandardProcessing)
		
	StandardProcessing = False;
	
	ProcessingEventOfKIPhoneElement(
		Item,
		PredefinedValue("Catalog.ContactInformationKinds.PartnerSPhoneNumber"),
		"PartnerSPhoneNumber",
		"PartnerPhoneFieldValues",
		"StartChoice");
	
EndProcedure

&AtClient
Procedure PartnerSPhoneNumberOnChange(Item)
	
	ProcessingEventOfKIPhoneElement(
		Item,
		PredefinedValue("Catalog.ContactInformationKinds.PartnerSPhoneNumber"),
		"PartnerSPhoneNumber",
		"PartnerPhoneFieldValues",
		"OnChange");
	
EndProcedure

&AtClient
Procedure PartnerSPhoneNumberClearing(Item, StandardProcessing)
	
	ProcessingEventOfKIPhoneElement(
		Item,
		PredefinedValue("Catalog.ContactInformationKinds.PartnerSPhoneNumber"),
		"PartnerSPhoneNumber",
		"PartnerPhoneFieldValues",
		"Clearing");
	
EndProcedure

&AtClient
Procedure EppartnerSAddressOnChange(Item)
	ClearMarkIncomplete();
EndProcedure

&AtClient
Procedure ActualAddressOnChange(Item)
	
	ProcessingEventOfKiAddressElement(Item,
	                                PredefinedValue("Catalog.ContactInformationKinds.ActualDataCounterpartyAddress"),
	                                "ActualAddress",
	                                "PhysicalAddressFieldValues",
	                                "OnChange");
	
	SetVisibilityOfDeliveryZone();
	
EndProcedure

&AtClient
Procedure ActualAddressStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	ProcessingEventOfKiAddressElement(Item,
	                                PredefinedValue("Catalog.ContactInformationKinds.ActualDataCounterpartyAddress"),
	                                "ActualAddress",
	                                "PhysicalAddressFieldValues",
	                                "StartChoice");
	
EndProcedure

&AtClient
Procedure ActualAddressClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	ProcessingEventOfKiAddressElement(Item,
	                                PredefinedValue("Catalog.ContactInformationKinds.ActualDataCounterpartyAddress"),
	                                "ActualAddress",
	                                "PhysicalAddressFieldValues",
	                                "Clearing");
	
	SetVisibilityOfDeliveryZone();
	
EndProcedure

&AtClient
Procedure LegalAddressStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	ProcessingEventOfKiAddressElement(Item,
	                                PredefinedValue("Catalog.ContactInformationKinds.LegalAddressOfCounterparty"),
	                                "LegalAddress",
	                                "LegalAddressFieldValues",
	                                "StartChoice");
	
EndProcedure

&AtClient
Procedure LegalAddressClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	ProcessingEventOfKiAddressElement(Item,
	                                PredefinedValue("Catalog.ContactInformationKinds.LegalAddressOfCounterparty"),
	                                "LegalAddress",
	                                "LegalAddressFieldValues",
	                                "Clearing");
	
EndProcedure

&AtClient
Procedure LegalAddressOnChange(Item)
	
	StandardProcessing = False;
	ProcessingEventOfKiAddressElement(Item,
	                                PredefinedValue("Catalog.ContactInformationKinds.LegalAddressOfCounterparty"),
	                                "LegalAddress",
	                                "LegalAddressFieldValues",
	                                "OnChange");
	
EndProcedure

#EndRegion

#Region ContactInformationPrivatePerson

&AtClient
Procedure PartnerSPhoneNumberIndividualStartChoice(Item, ChoiceData, StandardProcessing)
		
	StandardProcessing = False;
	
	ProcessingEventOfKIPhoneElement(
		Item,
		PredefinedValue("Catalog.ContactInformationKinds.PartnerSPhoneNumber"),
		"PartnerSPhoneNumberIndividual",
		"PartnerSPhoneNumberIndividualFieldValues",
		"StartChoice");
	
EndProcedure

&AtClient
Procedure PartnerSPhoneNumberIndividualOnChange(Item)
	
	ProcessingEventOfKIPhoneElement(
		Item,
		PredefinedValue("Catalog.ContactInformationKinds.PartnerSPhoneNumber"),
		"PartnerSPhoneNumberIndividual",
		"PartnerSPhoneNumberIndividualFieldValues",
		"OnChange");
	
EndProcedure

&AtClient
Procedure PartnerSPhoneNumberIndividualClearing(Item, StandardProcessing)
	
	ProcessingEventOfKIPhoneElement(
		Item,
		PredefinedValue("Catalog.ContactInformationKinds.PartnerSPhoneNumber"),
		"PartnerSPhoneNumberIndividual",
		"PartnerSPhoneNumberIndividualFieldValues",
		"Clearing");
	
EndProcedure

&AtClient
Procedure TheActualAddressOfAPrivatePersonStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	ProcessingEventOfKiAddressElement(Item,
	                                PredefinedValue("Catalog.ContactInformationKinds.ActualDataCounterpartyAddress"),
	                                "ActualAddress",
	                                "PhysicalAddressFieldValues",
	                                "StartChoice");
	
EndProcedure

&AtClient
Procedure TheActualAddressOfAPrivatePersonClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	ProcessingEventOfKiAddressElement(Item,
	                                PredefinedValue("Catalog.ContactInformationKinds.ActualDataCounterpartyAddress"),
	                                "ActualAddress",
	                                "PhysicalAddressFieldValues",
	                                "Clearing");
	
	SetVisibilityOfDeliveryZone();
	
EndProcedure

&AtClient
Procedure TheActualAddressOfAPrivatePersonOnChange(Item)
	
	ProcessingEventOfKiAddressElement(Item,
	                                PredefinedValue("Catalog.ContactInformationKinds.ActualDataCounterpartyAddress"),
	                                "ActualAddress",
	                                "PhysicalAddressFieldValues",
	                                "OnChange");
	
	SetVisibilityOfDeliveryZone();
	
EndProcedure

#EndRegion

#Region ContactInformationOfHeadCounterparty

&AtClient
Procedure ActualAddressOfTheHeadCounterpartyOnChange(Item)
	
	ProcessingEventOfKiAddressElement(Item,
	                                PredefinedValue("Catalog.ContactInformationKinds.ActualDataCounterpartyAddress"),
	                                "ActualAddressOfTheHeadCounterparty",
	                                "ActualAddressOfTheHeadCounterpartyFieldValues",
	                                "OnChange");
	
EndProcedure

&AtClient
Procedure ActualAddressOfTheHeadCounterpartyStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	ProcessingEventOfKiAddressElement(Item,
	                                PredefinedValue("Catalog.ContactInformationKinds.ActualDataCounterpartyAddress"),
	                                "ActualAddressOfTheHeadCounterparty",
	                                "ActualAddressOfTheHeadCounterpartyFieldValues",
	                                "StartChoice");
	
EndProcedure

&AtClient
Procedure ActualAddressOfTheHeadCounterpartyClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	ProcessingEventOfKiAddressElement(Item,
	                                PredefinedValue("Catalog.ContactInformationKinds.ActualDataCounterpartyAddress"),
	                                "ActualAddressOfTheHeadCounterparty",
	                                "ActualAddressOfTheHeadCounterpartyFieldValues",
	                                "Clearing");
	
EndProcedure

&AtClient
Procedure LegalAddressOfMainCounterpartyOnChange(Item)
	
	StandardProcessing = False;
	ProcessingEventOfKiAddressElement(Item,
	                                PredefinedValue("Catalog.ContactInformationKinds.LegalAddressOfCounterparty"),
	                                "LegalAddressOfMainCounterparty",
	                                "LegalAddressOfTheHeadCounterpartyFieldValues",
	                                "OnChange");
	
EndProcedure

&AtClient
Procedure LegalAddressOfMainCounterpartyStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	ProcessingEventOfKiAddressElement(Item,
	                                PredefinedValue("Catalog.ContactInformationKinds.LegalAddressOfCounterparty"),
	                                "LegalAddressOfMainCounterparty",
	                                "LegalAddressOfTheHeadCounterpartyFieldValues",
	                                "StartChoice");
	
EndProcedure

&AtClient
Procedure LegalAddressOfMainCounterpartyClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	ProcessingEventOfKiAddressElement(Item,
	                                PredefinedValue("Catalog.ContactInformationKinds.LegalAddressOfCounterparty"),
	                                "LegalAddressOfMainCounterparty",
	                                "LegalAddressOfTheHeadCounterpartyFieldValues",
	                                "Clearing");
	
EndProcedure

#EndRegion

&AtClient
Procedure Attachable_Opening(Item, StandardProcessing)
	
	If Item.Name = "AbbreviatedLegalEntityNameOfTheCounterparty" Then
		
		NationalLanguageSupportClient.OnOpen(ThisObject, CounterpartyForInternationalAttributes, Item, StandardProcessing);
		ChangingNameOfPartnerSCounterparty = "Counterparty";
		
	Else
		
		NationalLanguageSupportClient.OnOpen(ThisObject, PartnerTheObjectOfAdditionalDetails, Item, StandardProcessing);
		ChangingNameOfPartnerSCounterparty = "Partner";
		
	EndIf;
	
EndProcedure

#EndRegion

#Region BankDetailsProcessors

#Region PartnerSBankAccount

&AtClient
Procedure SpecifyTheCounterpartySBankAccountOnChange(Item)
	
	AvailabilityManagementCheckingAccount(SpecifyTheCounterpartySBankAccount);
	
EndProcedure

&AtClient
Procedure AccountNumberOnChange(Item)
	
	AccountNumberOnChangeClient();
	
EndProcedure

&AtClient
Procedure AccountNumberTextEditEnd(Item, Text, ChoiceData, Var_Parameters, StandardProcessing)
	
	MessageText = "";
	ClearMessages();
	Currency1 = CashCurrency <> CurrencyOfComplianceAccounting;
	
	Text = Upper(StrReplace(StrReplace(TrimAll(Text), " ", ""), ".", ""));
	
	If Not IsBlankString(Text) And Not ForeignBank And Not InternationalBankAccountDetails
		And Not CashClientServerLocalization.CheckIfAccountNumberIsCorrect(Text, Currency1, MessageText) Then
		PartnersAndCounterpartiesClient.OutputUserMessage(MessageText, OnlyPartnersAreUsed, "AccountNumber");
	EndIf;
	
EndProcedure

&AtClient
Procedure ThisIsAnIBANOnChange(Item)

	WhenChangingIBAN();
	
EndProcedure

&AtClient
Procedure BankOnChange(Item)
	
	WhenChangingBank();
	
EndProcedure

&AtClient
Procedure BankIndicationMethodOnChange(Item)
	
	WhenChangingManuallyChangeBankDetails()
	
EndProcedure

&AtClient
Procedure BankInGroupOnChange(Item)
	
	WhenChangingBank();
	
EndProcedure

&AtClient
Procedure BankBICOnChange(Item)
	
	FillInMainBankDetails(ThisObject)

EndProcedure

&AtClient
Procedure BankCorrAccountOnChange(Item)
	
	FillInMainBankDetails(ThisObject)

EndProcedure

&AtClient
Procedure BankAccountForPaymentsOnChange(Item)

	FillInMainBankDetails(ThisObject)

EndProcedure

&AtClient
Procedure BankDescriptionOnChange(Item)
	
	FillInMainBankDetails(ThisObject);
	
EndProcedure

&AtClient
Procedure BankSWIFTCodeOnChange(Item)
	
	FillInMainBankDetails(ThisObject)

EndProcedure

&AtClient
Procedure BankNameIntOnChange(Item)

	FillInMainBankDetails(ThisObject);

EndProcedure

&AtClient
Procedure CashCurrencyOnChange(Item)
	
	ClearMarkIncomplete();
	ItemManagementBankAccount(ThisObject);
	
EndProcedure

&AtClient
Procedure SettlementBankUsedOnChange(Item)
	
	WhenChangingBankIsUsedForCalculations();
	
EndProcedure

&AtClient
Procedure TransferBankOnChange(Item)
	
	WhenChangingBankForSettlements();
	
EndProcedure

&AtClient
Procedure MethodOfSpecifyingBankForSettlementsOnChange(Item)
	
	WhenChangingManuallyChangingBankDetailsForSettlements()
	
EndProcedure

&AtClient
Procedure BankForSettlementsInGroupOnChange(Item)
	
	WhenChangingBankForSettlements();
	
EndProcedure

&AtClient
Procedure TransferBankBICOnChange(Item)

	FillInMainBankDetailsForSettlements(ThisObject)

EndProcedure

&AtClient
Procedure TransferBankDescriptionOnChange(Item)
	
	FillInMainBankDetailsForSettlements(ThisObject)

EndProcedure

&AtClient
Procedure BankSWIFTCodeForPaymentsOnChange(Item)
	
	FillInMainBankDetailsForSettlements(ThisObject)

EndProcedure

&AtClient
Procedure BankNameForPaymentsIntOnChange(Item)
	
	FillInMainBankDetailsForSettlements(ThisObject)

EndProcedure

#EndRegion

#Region BankAccountOfHeadCounterparty

&AtClient
Procedure SpecifyTheBankAccountOfTheMainCounterpartyOnChange(Item)
	
	AvailabilityManagementCheckingAccount(SpecifyTheBankAccountOfTheMainCounterparty, True);
	
EndProcedure

&AtClient
Procedure AccountNumberHeadCounterpartyOnChange(Item)
	
	AccountNumberOnChangeClient(True);
	
EndProcedure

&AtClient
Procedure AccountNumberHeadCounterpartyEndOfTextEntry(
	Item,
	Text,
	ChoiceData,
	Var_Parameters,
	StandardProcessing)
	
	MessageText = "";
	ClearMessages();
	Currency1 = (CurrencyOfCashHeadCounterparty <> CurrencyOfComplianceAccounting);
	
	If Not IsBlankString(Text) And Not ForeignBankHeadCounterparty And Not InternationalBankAccountDetails 
		And Not CashClientServerLocalization.CheckIfAccountNumberIsCorrect(Text, Currency1, MessageText) Then
		PartnersAndCounterpartiesClient.OutputUserMessage(
			MessageText, OnlyPartnersAreUsed, "AccountNumberHeadCounterparty");
	EndIf;
	
EndProcedure

&AtClient
Procedure ThisIsIbanHeadCounterpartyOnChange(Item)

	WhenChangingIBAN(True);
	
EndProcedure

&AtClient
Procedure ParentCounterpartyBankOnChange(Item)
	
	WhenChangingBank(True);

EndProcedure

&AtClient
Procedure MethodOfSpecifyingBankHeadCounterpartyOnChange(Item)
	
	WhenChangingManuallyChangeBankDetails(True)
	
EndProcedure

&AtClient
Procedure BankInGroupIsMainCounterpartyOnChange(Item)
	
	WhenChangingBank(True);
	
EndProcedure

&AtClient
Procedure BikbankParentCounterpartyOnChange(Item)
	
	FillInMainBankDetails(ThisObject, True)

EndProcedure

&AtClient
Procedure CorrespondentAccountOfTheBankHeadContractorOnChange(Item)
	
	FillInMainBankDetails(ThisObject, True)

EndProcedure

&AtClient
Procedure BankAccountForSettlementsHeadCounterpartyOnChange(Item)

	FillInMainBankDetails(ThisObject, True)

EndProcedure

&AtClient
Procedure NameOfTheBankHeadCounterpartyOnChange(Item)
	
	FillInMainBankDetails(ThisObject, True);
	
EndProcedure

&AtClient
Procedure SwiftBankHeadCounterpartyOnChange(Item)
	
	FillInMainBankDetails(ThisObject, True)

EndProcedure

&AtClient
Procedure BankNameInternationalHeadCounterpartyOnChange(Item)

	FillInMainBankDetails(ThisObject, True);

EndProcedure

&AtClient
Procedure CurrencyOfCashHeadCounterpartyOnChange(Item)
	
	ClearMarkIncomplete();
	ItemManagementBankAccount(ThisObject, True);
	
EndProcedure

&AtClient
Procedure UsedByTheBankForSettlementsHeadCounterpartyOnChange(Item)
	
	WhenChangingBankIsUsedForCalculations(True);
	
EndProcedure

&AtClient
Procedure BankForSettlementsHeadCounterpartyOnChange(Item)
	
	WhenChangingBankForSettlements(True);
	
EndProcedure

&AtClient
Procedure MethodOfSpecifyingBankForSettlementsHeadCounterpartyOnChange(Item)
	
	WhenChangingManuallyChangingBankDetailsForSettlements(True)
	
EndProcedure

&AtClient
Procedure BankForSettlementsInGroupHeadCounterpartyOnChange(Item)
	
	WhenChangingBankForSettlements(True);
	
EndProcedure

&AtClient
Procedure BikbankForSettlementsHeadCounterpartyOnChange(Item)

	FillInMainBankDetailsForSettlements(ThisObject, True)

EndProcedure

&AtClient
Procedure NameOfTheBankForSettlementsHeadCounterpartyOnChange(Item)
	
	FillInMainBankDetailsForSettlements(ThisObject, True)

EndProcedure


&AtClient
Procedure SwiftBankForSettlementsHeadCounterpartyOnChange(Item)
	
	FillInMainBankDetailsForSettlements(ThisObject, True)

EndProcedure

&AtClient
Procedure NameOfBankForSettlementsInternationalHeadCounterpartyOnChange(Item)
	
	FillInMainBankDetailsForSettlements(ThisObject, True)

EndProcedure

#EndRegion

#EndRegion

#Region EventHandlersForFormTableElements

#Region TableFound

&AtClient
Procedure TheTreeWasFoundChoice(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData =  Items.TableFound.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	ShowValue(Undefined, CurrentData.Partner);
	
EndProcedure

&AtClient
Procedure TreeFoundWhenActivatingAString(Item)
	
	AttachIdleHandler("FillInPartnerComparisonTree", 0.2, True);
	
EndProcedure

#EndRegion

#Region PartnerComparisonTree

&AtClient
Procedure PartnerComparisonTreeSelection(Item, RowSelected, Field, StandardProcessing)
	
		
	StandardProcessing = False;
	
	CurrentData =  Items.PartnerComparisonTree.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	ShowValue(Undefined, CurrentData.FoundByReference);
	
EndProcedure

#EndRegion

#Region SeparateBusinessUnits

&AtClient
Procedure SeparateBusinessUnitsSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	CurrentData = Items.SeparateBusinessUnits.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	ShowValue(Undefined, CurrentData.Counterparty);
	
EndProcedure

#EndRegion

#EndRegion

#Region HandlersForOtherBankingDetails

#Region UniversalEventHandlers

&AtClient
Procedure Attachable_TextEditEnd(Item, Text, ChoiceData, Var_Parameters, StandardProcessing)
	
	PartnersAndCounterpartiesLocalizationClient.EndOfTextInput_Counterparty(Item,
		Text,
		ChoiceData,
		Var_Parameters,
		StandardProcessing,
		ThisObject);
		
EndProcedure

&AtClient
Procedure Attachable_OnChangeAttribute(Item)
	PartnersAndCounterpartiesLocalizationClient.WhenChangingBankingDetails_Counterparty(
		Item,
		ThisObject);
EndProcedure

&AtClient
Procedure Attachable_ProcessingTheFormSNavigationLink(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	PartnersAndCounterpartiesLocalizationClient.ProcessingNavigationLinkOfForm_Counterparty(Item,
		FormattedStringURL,
		StandardProcessing,
		ThisObject);
	
EndProcedure

&AtClient
Procedure AtEndOfChangingLocalizationDetails(TagName, AdditionalParameters) Export
	
	If AdditionalParameters.ServerCallRequired_ Then
		AtEndOfChangingLocalizationDetailsOnServer(TagName, AdditionalParameters.ProcessingParameters);
	EndIf;

EndProcedure

&AtServer
Procedure AtEndOfChangingLocalizationDetailsOnServer(TagName, ProcessingParameters)
	
	PartnersAndCounterpartiesLocalization.AtEndOfChangeOfProps_Counterparty(TagName, ThisObject);
	PageVisibilityPrimaryInformation();
EndProcedure

#EndRegion

&AtClient
Procedure TINOnChange(Item)
	PartnersAndCounterpartiesLocalizationClient.CheckTIN_(ThisObject);
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
Procedure ThisIsACompanyOnChange(Item)
	
	PageVisibilityPrimaryInformation();
	
	Items.TypeOfLegalEntityFace.Enabled = SpecifyLegalDetails;
	LegalEntityIndividual                       = PartnerSLegalEntityType(ThisIsACompany);
	
EndProcedure

&AtClient
Procedure AbbreviatedLegalEntityNameOfTheCounterpartyOnChange(Item)

	Attachable_OnChangeAttribute(Item);
	PartnersAndCounterpartiesClient.AbbreviatedLegalEntityNameWhenChanged(NameOfTheCounterparty, FullLegalName);
	
EndProcedure

&AtClient
Procedure AbbreviatedLegalNamePartnersOnlyOnChange(Item)
	
	Attachable_OnChangeAttribute(Item);
	PartnersAndCounterpartiesClient.AbbreviatedLegalEntityNameWhenChanged(FullDescr, FullLegalName);
	Name1 = FullDescr;
	ClearMarkIncomplete();

EndProcedure

&AtClient
Procedure PublicNameOnChange(Item)
	
	ClearMarkIncomplete();
	
EndProcedure

&AtClient
Procedure ActionBasedOnResultsFoundOnChange(Item)
	
	ManagingBasementPages();
	
EndProcedure

&AtClient
Procedure ActionWithTheCounterpartyOnChange(Item)
	
	ManagingBasementPages();
	
EndProcedure

&AtClient
Procedure CompanyTypeWhenChanging(Item)
	
	AvailabilityManagementPrimaryInformation();
	PartnersAndCounterpartiesLocalizationClient.CheckTIN_(ThisObject, True);
	
EndProcedure

&AtClient
Procedure SpecifyLegalDetailsOfAPrivatePersonOnChange(Item)
	
	PageVisibilityPrimaryInformation();
	
	Items.TypeOfLegalEntityFace.Enabled = SpecifyLegalDetails;
	
EndProcedure

&AtClient
Procedure SpecifyLegalDetailsOnChange(Item)
	
	PageVisibilityPrimaryInformation();
	
	Items.TypeOfLegalEntityFace.Enabled = SpecifyLegalDetails;
	
EndProcedure

&AtClient
Procedure SpecifyTheContactPersonSDetailsOnChange(Item)
	
	ClearMarkIncomplete();
	
	EstablishAvailabilityOfContactPersonData(ThisObject);
	
EndProcedure

&AtClient
Procedure ChannelOfInitialRequestOnChange(Item)
	
	ManagingElementsOfPrimaryInterest(ThisObject);
	If Not ValueIsFilled(ChannelOfInitialRequest) Then
		SourceOfInitialRequest = Undefined;
	EndIf;
	
EndProcedure

&AtClient
Procedure FlagIndicatesThePartnerWhenChanging(Item)
	
	FillPropertyValues(PartnerTheObjectOfAdditionalDetails, ThisObject, "Client, Competitor, Vendor, OtherRelations");
	AdditionalDetailsElementsNeedToBeUpdated = True;
	UpdateDependentDetailsOfPartnerAttribute(ThisObject);
	
EndProcedure

&AtClient
Procedure AccessGroupOnChange(Item)
	
	ClearMarkIncomplete();
	
EndProcedure

&AtClient
Procedure AccessGroupPrivatePersonOnChange(Item)
	
	ClearMarkIncomplete();
	
EndProcedure

&AtClient
Procedure BusinessRegionOnChange(Item)
	
	If ValueIsFilled(BusinessRegion) Then
			MainManagerOfBusinessRegion = PartnersAndCounterpartiesServerCall.MainManagerOfBusinessRegion(BusinessRegion);
			If ValueIsFilled(MainManagerOfBusinessRegion) And MainManagerOfBusinessRegion <> MainManager Then
				
				QueryText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Đối với khu vực kinh doanh đã chọn, người quản lý chính là %1. Đặt người đó là quản lý chính của bạn hàng?';
																							|ru = 'Для выбранного бизнес-региона основным менеджером является %1. Установить его основным менеджером партнера?';
																							|en = 'For selected business region %1 is the main manager. Set him or her as the main manager of the partner?'; fa = 'For selected business region %1 is the main manager. Set him or her as the main manager of the partner?';
																							|it = 'Per l''area commerciale selezionata il manager principale risulta essere %1. Impostarlo come manager principale del partner?';
																							|pl = 'Dla wybranego regionu biznesowego głównym menedżerem jest %1. Ustawić go jako głównego menedżera partnera?';
																							|tr = 'Seçilen iş bölgesi için ana yönetici %1 olmaktadır. Ana iş ortağı yöneticisi olarak yapılandırılsın mı?'"),MainManagerOfBusinessRegion);
				Result = Undefined;

				ShowQueryBox(New CallbackDescription("BusinessRegionOnChangeCompletion", ThisObject, New Structure("MainManagerOfBusinessRegion", MainManagerOfBusinessRegion)), QueryText, QuestionDialogMode.YesNo);
				
			EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure BusinessRegionOnChangeCompletion(QuestionResult, AdditionalParameters) Export
    
    MainManagerOfBusinessRegion = AdditionalParameters.MainManagerOfBusinessRegion;
    
    
    Result = QuestionResult;
    
    If Result = DialogReturnCode.Yes Then
        
        MainManager = MainManagerOfBusinessRegion;
        
    EndIf;

EndProcedure

&AtClient
Procedure LastNameKLOnChange(Item)
	
	ClearMarkIncomplete();
	
EndProcedure

&AtClient
Procedure KLNameOnChange(Item)
	
	ClearMarkIncomplete();
	
EndProcedure

&AtClient
Procedure SpecifyTheIdentityDocumentOnChange(Item)
	
	SetAvailabilityOfDataInIndividualDocument(ThisObject);
	ClearMarkIncomplete();
	
EndProcedure

&AtClient
Procedure DocumentKindOnChange(Item)
	
	ClearMarkIncomplete();
	
EndProcedure

&AtClient
Procedure SelectTheHeadCounterpartyOnChange(Item)
	
	PartnersAndCounterpartiesLocalizationClientServer.AvailabilityManagementHeadCounterparty(ThisObject);
	
EndProcedure

&AtClient
Procedure FullNameOfTheHeadCounterpartyOnChange(Item)
	Attachable_OnChangeAttribute(Item);
	PartnersAndCounterpartiesClient.AbbreviatedLegalEntityNameWhenChanged(
		NameHeadCounterparty, FullNameOfTheHeadCounterparty);
EndProcedure

#EndRegion

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteLocalizationCommand(Command)
	
	PartnersAndCounterpartiesLocalizationClient.ExecuteLocalizationCommand(Command, ThisObject);
	
EndProcedure

&AtClient
Procedure ContinueRunningLocalizationCommand(CommandName, AdditionalParameters) Export
	
	If AdditionalParameters.ServerCallRequired_ Then
		ContinueRunningLocalizationCommandOnServer(CommandName, AdditionalParameters.ProcessingParameters);
	EndIf;
	
EndProcedure

&AtServer
Procedure ContinueRunningLocalizationCommandOnServer(CommandName, ProcessingParameters)
	
	PartnersAndCounterpartiesLocalization.ExecuteLocalizationCommand(ThisObject, CommandName, ProcessingParameters);
	If ValueIsFilled(ProcessingParameters) And ProcessingParameters.Property("ProcedureName") Then
		If ProcessingParameters.ProcedureName = "PageVisibilityPrimaryInformation" Then
			PageVisibilityPrimaryInformation();
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure Next(Command)
	
	NavigateThroughPages(Undefined, Command);
	
EndProcedure

&AtClient
Procedure Back(Command)
	
	NavigateThroughPages(Undefined, Command);
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Close();
	
EndProcedure

&AtClient
Procedure SetTheLegalAddressEqualToTheActualOne(Command)
	
	If Items.WizardPages.CurrentPage = Items.AdditionalInformationPage Then
		
		LegalAddress              = ActualAddress;
		LegalAddressFieldValues = PhysicalAddressFieldValues;
		
	Else
		
		LegalAddressOfMainCounterparty              = ActualAddressOfTheHeadCounterparty;
		LegalAddressOfTheHeadCounterpartyFieldValues = ActualAddressOfTheHeadCounterpartyFieldValues;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SetBusinessAddressEqualToLegalOne(Command)
	
	If Items.WizardPages.CurrentPage = Items.AdditionalInformationPage Then
		
		ActualAddress              = LegalAddress;
		PhysicalAddressFieldValues = LegalAddressFieldValues;
		
	Else
		
		ActualAddressOfTheHeadCounterparty              = LegalAddressOfMainCounterparty;
		ActualAddressOfTheHeadCounterpartyFieldValues = LegalAddressOfTheHeadCounterpartyFieldValues;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SetAll(Command)
	
	For Each Page1 In SeparateBusinessUnits Do
		Page1.Selected = True;
	EndDo;
	
EndProcedure

&AtClient
Procedure ClearAllIetmsCommand(Command)
	
	For Each Page1 In SeparateBusinessUnits Do
		Page1.Selected = False;
	EndDo;
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

#EndRegion

#Region Private

#Region FormationOfFinalInformation

&AtServer
Procedure FillInSummaryInformation()
	
	Summary = Catalogs.Partners.GetTemplate("Template").GetText();
	
	If ClientApplication.CurrentInterfaceVariant() = ClientApplicationInterfaceVariant.Taxi Then
		Summary = StrReplace(Summary, "#fcfaeb", "#ffffff");
	EndIf;
	
	If ActionBasedOnResultsFound <> 0 Then
		
		Summary = StrReplace(Summary, "#PD#", "");
		Summary = StrReplace(Summary,"#TitlePartnerName#",
			?(OnlyPartnersAreUsed, NStr("vi = 'Tên viết tắt pháp nhân';
										|ru = 'Сокращенное юр. наименование';
										|en = 'Abbreviated legal name'; fa = 'نام حقوقی اختصاری';
										|it = 'Nome giuridico abbreviato';
										|pl = 'Skrócona nazwa prawna';
										|tr = 'Kısaltılmış yasal adı'"), NStr("vi = 'Tên gọi công khai';
																				|ru = 'Публичное наименование';
																				|en = 'Public name'; fa = 'نام عمومی';
																				|it = 'Nome pubblico';
																				|pl = 'Nazwa publiczna';
																				|tr = 'Kamu adı'")));
		Summary = StrReplace(Summary, "#PartnerName#", PartnerName());
		If ThisIsACompany = 1 Then
			Summary = StrReplace(Summary, "#DateOfBirth#", ?(BirthDate = Date(1,1,1), "", Format(BirthDate,"DLF=D")));
			Summary = StrReplace(Summary, "#Gender#", ?(ValueIsFilled(Gender),Gender,""));
			Summary = StrReplace(Summary, "#IND#", "");
		Else
			TMCommonUseClientServer.RemoveSubstringFromString(Summary, "#IND#");
		EndIf;
		Summary = StrReplace(Summary, "#WorkingNameOfThePartner#", ?(ThisIsACompany = 0, Name1,FIO_OneLine(PartnerSLastName, PartnerName_3, PartnerSMiddleName)));
		If OnlyPartnersAreUsed Then
			TMCommonUseClientServer.RemoveSubstringFromString(Summary, "#PC#");
		Else
			Summary = StrReplace(Summary, "#Parent#", Parent);
			Summary = StrReplace(Summary, "#PC#", "");
		EndIf;
		Summary = StrReplace(Summary, "#RelationshipType#", GetRelationshipTypeString());
		Summary = StrReplace(Summary, "#Email#", ?(ThisIsACompany = 0, EppartnerSAddress, EppartnerSAddressIndividual));
		Summary = StrReplace(Summary, "#Phone#", ?(ThisIsACompany = 0, PartnerSPhoneNumber, PartnerSPhoneNumberIndividual));
		If OnlyPartnersAreUsed And SpecifyLegalDetails Then
			TMCommonUseClientServer.RemoveSubstringFromString(Summary,"#AP#");
		Else
			If ThisIsACompany = 0 Then
				Summary = StrReplace(Summary, "#AddressName#", NStr("vi = 'Địa chỉ thực tế';
																	|ru = 'Фактический адрес';
																	|en = 'Business address'; fa = 'آدرس کسب‌وکار';
																	|it = 'Sede operativa';
																	|pl = 'Adres faktyczny';
																	|tr = 'İş adresi'"));
			Else
				Summary = StrReplace(Summary, "#AddressName#", NStr("vi = 'Địa chỉ cư trú';
																	|ru = 'Адрес проживания';
																	|en = 'Residence address'; fa = 'آدرس محل سکونت';
																	|it = 'Indirizzo di residenza';
																	|pl = 'Adres zamieszkania';
																	|tr = 'İkamet adresi'"));
			EndIf;
			Summary = StrReplace(Summary, "#Address#", ActualAddress);
			Summary = StrReplace(Summary, "#AP#", "");
		EndIf; 
		Summary = StrReplace(Summary, "#Address#", ActualAddress);
		
		If GetFunctionalOption("UsePartnerAccessGroups") Then
			Summary = StrReplace(Summary, "#AccessGroup#", AccessGroup);
			Summary = StrReplace(Summary, "#AG#", "");
		Else
			TMCommonUseClientServer.RemoveSubstringFromString(Summary,"#AG#");
		EndIf;
		Summary = StrReplace(Summary, "#ResponsibleManager#", MainManager);
		
		If GetFunctionalOption("UseBusinessRegions") Then
			Summary = StrReplace(Summary, "#BusinessRegion#", BusinessRegion);
			Summary = StrReplace(Summary, "#BR#", "");
		Else
			TMCommonUseClientServer.RemoveSubstringFromString(Summary, "#BR#");
		EndIf;
		
		If GetFunctionalOption("RecordInitialRequest") Then
			Summary = StrReplace(Summary, "#ChannelOfInitialRequest#", ChannelOfInitialRequest);
			Summary = StrReplace(Summary, "#SourceOfInitialRequest#", SourceOfInitialRequest);
			Summary = StrReplace(Summary, "#IR#", "");
		Else
			TMCommonUseClientServer.RemoveSubstringFromString(Summary, "#IR#");
		EndIf;
		
		If YouHaveTheRightToIncludeItInTheSegment And GetFunctionalOption("UsePartnersSegments") Then
			Summary = StrReplace(Summary, "#Segment#", Segment);
			Summary = StrReplace(Summary, "#SG#", "");
		Else
			TMCommonUseClientServer.RemoveSubstringFromString(Summary, "#SG#");
		EndIf;
		
	Else
		TMCommonUseClientServer.RemoveSubstringFromString(Summary, "#PD#");
	EndIf;
	
	If (OnlyPartnersAreUsed Or ActionWithTheCounterparty = 1) And SpecifyLegalDetails Then
		INNWithdrawal = ?(ThisIsACompany = 0, TIN, INNPartnerIndividual);
		
		If Not ThereIsADoubleForTheMainDetails Then
			Items.Next2.Enabled =True;
			TMCommonUseClientServer.RemoveSubstringFromString(Summary, "#ID#");
			Summary = StrReplace(Summary, "#RepresentationOfTheTypeOfLegalEntityIndividual#", PresentationOfLegalEntityType());
			If OnlyPartnersAreUsed Then
				TMCommonUseClientServer.RemoveSubstringFromString(Summary, "#AN#");
			Else
				Summary = StrReplace(Summary, "#FullNameOfTheCounterparty#",
				                     ?(ThisIsACompany = 0, FullLegalName, FIO_OneLine(PartnerSLastName, PartnerName_3, PartnerSMiddleName)));
				Summary = StrReplace(Summary, "#AN#", "");
			EndIf;
			If TypeOfCompany = 3 Then
				Summary = StrReplace(Summary, "#NameOfTheHeadCounterparty#",
				                     ?(OnlyPartnersAreUsed Or SelectTheHeadCounterparty = 0,
				                     MainCounterparty,
				                     ?(SelectTheHeadCounterparty = 1, NameHeadCounterparty, "")));
				Summary = StrReplace(Summary, "#SGK#", "");
			Else
				TMCommonUseClientServer.RemoveSubstringFromString(Summary, "#SGK#");
			EndIf;
			Summary = StrReplace(Summary, "#TIN#", INNWithdrawal);
			
			Summary = StrReplace(Summary, "#LegalAddress#", LegalAddress);
			Summary = StrReplace(Summary, "#PhysicalAddress#", ActualAddress);
			Summary = StrReplace(Summary, "#RD#", "");
			
			If ThisIsACompany = 1 And SpecifyTheIdentityDocument Then
				Summary = StrReplace(Summary, "#DocumentKind#" ,DocumentKind);
				Summary = StrReplace(Summary, "#DocumentSeries#", SeriesFromDocument);
				Summary = StrReplace(Summary, "#DocumentNumber#", DocumentNumber);
				Summary = StrReplace(Summary, "#DateOfIssue#", Format(DateOfIssue1,"DLF=D"));
				Summary = StrReplace(Summary, "#ValidityPeriod#", Format(ValidityPeriod,"DLF=D"));
				Summary = StrReplace(Summary, "#IssuedBy#", WhoIssuedDocument);
				Summary = StrReplace(Summary, "#IssuingAuthorityCode#",BusinessUnitCode);
				Summary = StrReplace(Summary, "#DD#", "");
			Else
				TMCommonUseClientServer.RemoveSubstringFromString(Summary, "#DD#");
			EndIf;
			
			If SpecifyTheCounterpartySBankAccount Then
				Summary = StrReplace(Summary, "#AccountNumber#", AccountNumber);
				Summary = StrReplace(Summary, "#CashCurrency#", CashCurrency);
				If Not ForeignBank Then
					Summary = StrReplace(Summary, "#Bank#", BankDescription);
					Summary = StrReplace(Summary, "#CorrBankAccount#", BankCorrAccount);
					If SettlementBankUsed Then
						Summary = StrReplace(
							Summary, "#BankForSettlements#", TransferBankDescription);
						Summary = StrReplace(
							Summary, "#OffsetBankAccountForSettlements#", TransferBankCorrAccount);
					Else
						Summary = StrReplace(Summary, "#BankForSettlements#", "");
						Summary = StrReplace(Summary, "#OffsetBankAccountForSettlements#", "");
					EndIf;
				Else
					Summary = StrReplace(Summary, "#Bank#",
						BankSWIFTCode + ", " + BankDescription + ", " + BankAddress);
					CurrencyAccount = (ValueIsFilled(CashCurrency)
									And CashCurrency <> CurrencyOfComplianceAccounting);
					If CurrencyAccount Then
						Summary = StrReplace(Summary, "#CorrBankAccount#", BankAccountForPayments);
					Else
						Summary = StrReplace(Summary, "#CorrBankAccount#", BankCorrAccount);
					EndIf;
					If SettlementBankUsed Then
						Summary = StrReplace(Summary, "#BankForSettlements#",
							BankSWIFTCodeForPayments + ", " + TransferBankDescription + ", " + TransferBankAddress);
						Summary = StrReplace(
							Summary, "#OffsetBankAccountForSettlements#", TransferBankCorrAccount);
					Else
						Summary = StrReplace(Summary, "#BankForSettlements#", "");
						Summary = StrReplace(Summary, "#OffsetBankAccountForSettlements#", "");
					EndIf;
				EndIf;
				Summary = StrReplace(Summary, "#BA#", "")
			Else
				TMCommonUseClientServer.RemoveSubstringFromString(Summary, "#BA#");
			EndIf;
			
		EndIf;
		
	Else
		TMCommonUseClientServer.RemoveSubstringFromString(Summary, "#RD#");
		TMCommonUseClientServer.RemoveSubstringFromString(Summary, "#ID#");
		TMCommonUseClientServer.RemoveSubstringFromString(Summary, "#DD#");
	EndIf;
	
	If TypeOfCompany = 3 And Not OnlyPartnersAreUsed And SelectTheHeadCounterparty = 1 Then
		
		Summary = StrReplace(Summary, "#DHC#", "");
		Summary = StrReplace(Summary, "#FullNameOfTheHeadCounterparty#",
			FullNameOfTheHeadCounterparty);
		If ValueIsFilled(PartnerOfTheHeadCounterparty) Then
			Summary = StrReplace(Summary, "#PartnerOfTheHeadCounterparty#", PartnerOfTheHeadCounterparty);
			Summary = StrReplace(Summary, "#PHC#", "");
		Else
			TMCommonUseClientServer.RemoveSubstringFromString(Summary, "#PHC#");
		EndIf;
		Summary = StrReplace(Summary, "#LegalAddressOfMainCounterparty#",
			LegalAddressOfMainCounterparty);
		Summary = StrReplace(Summary, "#ActualAddressOfTheHeadCounterparty#",
			ActualAddressOfTheHeadCounterparty);
		
		If SpecifyTheBankAccountOfTheMainCounterparty Then
			Summary = StrReplace(Summary, "#AccountNumberOfTheHeadCounterparty#",
				AccountNumberHeadCounterparty);
			Summary = StrReplace(Summary, "#CurrencyOfTheHeadCounterpartySFunds#",
				CurrencyOfCashHeadCounterparty);
				
			If Not ForeignBankHeadCounterparty Then
				Summary = StrReplace(
					Summary, "#BankOfTheMainCounterparty#", NameOfTheBankHeadCounterparty);
				Summary = StrReplace(Summary, "#CorrespondentBankAccountOfTheHeadCounterparty#",
					CorrespondentAccountOfTheBankHeadContractor);
				If UsedByTheBankForSettlementsHeadCounterparty Then
					Summary = StrReplace(Summary, "#BankForSettlementsOfTheMainCounterparty#",
						NameOfTheBankForSettlementsHeadCounterparty);
					Summary = StrReplace(Summary,
						"#CorrespondentAccountOfTheBankForTheCalculationsOfTheHeadContractor#", CorrespondentAccountOfTheBankForCalculationOfHeadContractor);
				Else
					Summary = StrReplace(Summary, "#BankForSettlementsOfTheMainCounterparty#", "");
					Summary = StrReplace(
						Summary, "#CorrespondentAccountOfTheBankForTheCalculationsOfTheHeadContractor#", "");
				EndIf;
			Else
				Summary = StrReplace(Summary, "#BankOfTheMainCounterparty#",
					SwiftBankHeadCounterparty + ", " + NameOfTheBankHeadCounterparty + ", "
					+ BankAddressHeadCounterparty);
				Summary = StrReplace(
					Summary, "#CorrespondentBankAccountOfTheHeadCounterparty#", CorrespondentAccountOfTheBankHeadContractor);
				
				If UsedByTheBankForSettlementsHeadCounterparty Then
					Summary = StrReplace(Summary, "#BankForSettlementsOfTheMainCounterparty#",
						SwiftBankForSettlementsHeadCounterparty + ", " + NameOfTheBankForSettlementsHeadCounterparty
						+ ", " + BankAddressForSettlementsHeadCounterparty);
					Summary = StrReplace(Summary,
						"#CorrespondentAccountOfTheBankForTheCalculationsOfTheHeadContractor#", CorrespondentAccountOfTheBankForCalculationOfHeadContractor);
				Else
					Summary = StrReplace(Summary, "#BankForSettlementsOfTheMainCounterparty#", "");
					Summary = StrReplace(
						Summary, "#CorrespondentAccountOfTheBankForTheCalculationsOfTheHeadContractor#", "");
				EndIf;
			EndIf;
			Summary = StrReplace(Summary, "#BAHC#", "")
		Else
			TMCommonUseClientServer.RemoveSubstringFromString(Summary, "#BAHC#");
		EndIf;
		
	Else
		TMCommonUseClientServer.RemoveSubstringFromString(Summary, "#DHC#");
	EndIf;
	
	If ActionBasedOnResultsFound <> 0 And ThisIsACompany = 0 And SpecifyTheContactPersonSDetails Then
		Summary = StrReplace(Summary, "#FULLNAME#",FIO_OneLine(LastNameKL, KLName, PatronymicKL));
		Summary = StrReplace(Summary, "#EmailCP#" ,EPCLAddress);
		Summary = StrReplace(Summary, "#PhoneCP#", PhoneNumberKL);
		Summary = StrReplace(Summary, "#MobilePhoneCP#", MobilePhoneKL);
		If GetFunctionalOption("UseRolesOfPartnerContactPersons") Then
			Summary = StrReplace(Summary, "#Role#", Role);
			Summary = StrReplace(Summary, "#RCP#", "");
		Else
			TMCommonUseClientServer.RemoveSubstringFromString(Summary, "#RCP#");
		EndIf;
		Summary = StrReplace(Summary, "#DCP#", "");
	Else
		TMCommonUseClientServer.RemoveSubstringFromString(Summary, "#DCP#");
	EndIf;
	
	VisibilityOfCountryOfRegistration = (OnlyPartnersAreUsed Or SpecifyLegalDetails) And TypeOfCompany = 1;
	If VisibilityOfCountryOfRegistration Then
		Summary = StrReplace(Summary, "#CountryOfResidence#",    RegistrationCountry);
		Summary = StrReplace(Summary, "#RegistrationNumber#", RegistrationNumber);
		Summary = StrReplace(Summary, "#TaxNumber#",       TaxNumber);
		Summary = StrReplace(Summary, "#NRI#", "");
	Else
		TMCommonUseClientServer.RemoveSubstringFromString(Summary, "#NRI#");
	EndIf;
	PartnersAndCounterpartiesLocalization.FillInSummaryInformation(Summary, ThisObject);
	
	StartHTMLTag = StrFind(Summary, "<html");
	If StartHTMLTag <> 0 Then
		Summary = Right(Summary, StrLen(Summary) - StartHTMLTag + 1);
	EndIf;
	
EndProcedure

&AtServer
Function GetRelationshipTypeString()
	
	StringRelationshipType = ?(Client,NStr("vi = 'Khách hàng';
											|ru = 'Клиент';
											|en = 'Customer'; fa = 'مشتری';
											|it = 'Cliente';
											|pl = 'Klient';
											|tr = 'Müşteri'"),"") + ?(Vendor, NStr("vi = ', Nhà cung cấp';
																					|ru = ', Поставщик';
																					|en = ', Vendor'; fa = ', Vendor';
																					|it = ', Fornitore';
																					|pl = ', Dostawca';
																					|tr = ', Tedarikçi'"),"") + ?(Carrier, NStr("vi = ', Người vận chuyển';
																															|ru = ', Перевозчик';
																															|en = ', Carrier'; fa = ', Carrier';
																															|it = ', Trasportatore';
																															|pl = ', Przewoźnik';
																															|tr = ', Taşıyıcı'"),"") + ?(Competitor, NStr("vi = ', Đối thủ cạnh tranh';
																																										|ru = ', Конкурент';
																																										|en = ', Competitor'; fa = ', Competitor';
																																										|it = ', Concorrente';
																																										|pl = ', Konkurent';
																																										|tr = ', Rakip'"),"") + ?(OtherRelations, NStr("vi = ', Quan hệ khác';
																																																							|ru = ', Прочие отношения';
																																																							|en = ', Other relations'; fa = ', Other relations';
																																																							|it = ', Altre relazioni';
																																																							|pl = ', Inne stosunki';
																																																							|tr = ', Diğer ilişkiler'"),"");
	If Left(StringRelationshipType, 2) = ", " Then
		StringRelationshipType = Right(StringRelationshipType, StrLen(StringRelationshipType)-2);
	EndIf;
	
	Return StringRelationshipType;
	
EndFunction

&AtServer
Function PartnerName()
	
	If ThisIsACompany = 0 Then
		Return ?(OnlyPartnersAreUsed, FullLegalName, FullDescr)
	Else
		Return FIO_OneLine(PartnerSLastName, PartnerName_3, PartnerSMiddleName);
	EndIf;
	
EndFunction

&AtServer
Function NameOfTheCounterparty()
	
	If ThisIsACompany = 0 Then
		Return NameOfTheCounterparty;
	Else
		Return FIO_OneLine(PartnerSLastName, PartnerName_3, PartnerSMiddleName);
	EndIf;
	
EndFunction


&AtServer
Function PresentationOfLegalEntityType()
	
	If ThisIsACompany = 0 Then
		If TypeOfCompany = 0 Then
			Return NStr("vi = 'Pháp nhân';
						|ru = 'Юридическое лицо';
						|en = 'Legal entity'; fa = 'شخص حقوقی';
						|it = 'Ente giuridico';
						|pl = 'Osoba prawna';
						|tr = 'Tüzel kişi'");
		ElsIf TypeOfCompany = 1 Then
			Return NStr("vi = 'Pháp nhân (ngoài lãnh thổ Việt Nam)';
						|ru = 'Юридическое лицо(за пределами РФ)';
						|en = 'Legal entity (outside RF)'; fa = 'Legal entity (outside RF)';
						|it = 'Entità giuridica (al di fuori della Federazione Russa)';
						|pl = 'Osoba prawna (poza granicami FR)';
						|tr = 'Tüzel kişi(Rusya Federasyonu dışında)'");
		ElsIf TypeOfCompany = 2 Then
			Return NStr("vi = 'Cá nhân kinh doanh (CNKD)';
						|ru = 'Индивидуальный предприниматель(ПБОЮЛ)';
						|en = 'Individual entrepreneur (Sole proprietor)'; fa = 'Individual entrepreneur (Sole proprietor)';
						|it = 'Imprenditore Individuale (Imprenditore senza una formazione di persona giuridica)';
						|pl = 'Przedsiębiorca indywidualny (przedsiębiorca bez utworzenia osoby prawnej)';
						|tr = 'Şahıs şirketi(Tüzel kişiliği olmayan işletme)'");
		Else
			Return NStr("vi = 'Bộ phận độc lập';
						|ru = 'Обособленное подразделение';
						|en = 'Branch office'; fa = 'شعبه';
						|it = 'Reparto esterno';
						|pl = 'Odrębny dział';
						|tr = 'Ayrı departman'");
		EndIf;
	Else
		Return NStr("vi = 'Cá nhân';
					|ru = 'Физическое лицо';
					|en = 'Person'; fa = 'شخص';
					|it = 'Persona fisica';
					|pl = 'Osoba fizyczna';
					|tr = 'Gerçek kişi'");
	EndIf;
	
EndFunction

&AtClientAtServerNoContext
Function PartnerSLegalEntityType(ThisIsACompany)
	
	If ThisIsACompany = 0 Then
		Return PredefinedValue("Enum.IndividualCompany.Company");
	Else
		Return PredefinedValue("Enum.IndividualCompany.Person_");
	EndIf;
	
EndFunction

#EndRegion

#Region ManagingVisibilityAndAvailabilityOfFormElements

&AtClient
Procedure ManagingBasementPages()
	
	PreviousPageBasement = Items.PagesFooter.CurrentPage;
	
	If Items.WizardPages.CurrentPage = Items.PrimaryInformationPage Then
		Items.PagesFooter.CurrentPage = Items.ClickNextPage;
	ElsIf Items.WizardPages.CurrentPage = Items.PageFound Then
		Items.PagesFooter.CurrentPage =
			?(ActionBasedOnResultsFound = 0 And (OnlyPartnersAreUsed Or ActionWithTheCounterparty = 0),
			Items.TheDoneButtonPage,
			Items.BackNextButtonPage);
	ElsIf Items.WizardPages.CurrentPage = Items.FinalPage Then
		Items.PagesFooter.CurrentPage = Items.CreateButtonPage;
	Else
		Items.PagesFooter.CurrentPage = Items.BackNextButtonPage;
	EndIf;
	
	If PreviousPageBasement <> Items.PagesFooter.CurrentPage Then
		If Items.PagesFooter.CurrentPage = Items.ClickNextPage Then
			Items.Next.DefaultButton = True;
		ElsIf Items.PagesFooter.CurrentPage = Items.TheDoneButtonPage Then
			Items.Next1.DefaultButton = True;
		ElsIf Items.PagesFooter.CurrentPage = Items.CreateButtonPage Then
			Items.Next2.DefaultButton = True;
		ElsIf Items.PagesFooter.CurrentPage = Items.BackNextButtonPage Then
			Items.Next3.DefaultButton = True;
		EndIf;
	EndIf;
		
EndProcedure

&AtServer
Procedure PageVisibilityPrimaryInformation()
	
	If ThisIsACompany = 0 Then
		
		Items.PagesCompanyPrivatePerson.CurrentPage = Items.CompanyPage;
		
	Else
		
		Items.PagesCompanyPrivatePerson.CurrentPage = Items.PageIndividual;
		
	EndIf;
	
	If Not BasedOnTheCounterparty Then
		If OnlyPartnersAreUsed Then
			Items.ThePageWillBeCreated.CurrentPage = Items.ThePageWillBeCreatedByTheCounterparty;
		Else
			Items.ThePageWillBeCreated.CurrentPage = 
			?(Not SpecifyLegalDetails , Items.PagePartnerWillBeCreated, Items.PagePartnerAndCounterpartyWillBeCreated);
		EndIf;
	EndIf;
	
	AvailabilityManagementPrimaryInformation();
	
EndProcedure

&AtServer
Procedure AvailabilityManagementPrimaryInformation()
	
	Items.TypeOfLegalEntityFace.Enabled = SpecifyLegalDetails;

	// Legal details
	If Not (BasedOnTheCounterparty Or BasedOnASeparateCounterparty) Then
		If ThisIsACompany = 0 Then
			TMCommonUseClientServer.SetFormItemProperty(Items, "GroupRegistrationData",
				"Enabled", SpecifyLegalDetails, True);
			If SpecifyLegalDetails Then
				PartnersAndCounterpartiesLocalizationClientServer.ManagingElementsOfLegalDetails(ThisObject);
			EndIf;
		Else
			TMCommonUseClientServer.SetFormItemProperty(Items, "GroupCounterpartyDataIndividual",
				"Enabled", SpecifyLegalDetails, True);
			If SpecifyLegalDetails Then
				SetAvailabilityOfDataInIndividualDocument(ThisObject);
			EndIf;
		EndIf;
	EndIf;
	
	// Contact person
	EstablishAvailabilityOfContactPersonData(ThisObject);
	
	// The country of registration is visible only if the counterparty is not a resident of the Russian Federation. 
	// Otherwise, both for individuals and for sole proprietors and for legal entities, the country of registration is always Russia.
	Items.CounterpartyRegistrationDataPageGroup.CurrentPage = 
		?((OnlyPartnersAreUsed Or SpecifyLegalDetails) And TypeOfCompany = 1, 
		Items.GroupForeignRegistrationPage, Items.LocalizationGroupPageOfTheRussianCounterparty);
		
	Items.EppartnerSAddress.AutoChoiceIncomplete   = TheEppartnerSAddressIsRequired;
	Items.PartnerSPhoneNumber.AutoMarkIncomplete = PartnerSPhoneNumberIsRequired;
	
	Items.EppartnerSAddressIndividual.AutoChoiceIncomplete   = TheEppartnerSAddressIsRequired;
	Items.PartnerSPhoneNumberIndividual.AutoMarkIncomplete = PartnerSPhoneNumberIsRequired;
	
	Items.PhoneNumberKL.AutoMarkIncomplete          = ContactPersonSPhoneNumberIsRequired;
	Items.EPCLAddress.AutoMarkIncomplete          = TheAddressOfTheContactPersonIsRequired;
	Items.MobilePhoneKL.AutoMarkIncomplete = TheContactPersonSMobilePhoneNumberIsRequired;
	PartnersAndCounterpartiesLocalizationClientServer.ManagingCounterpartyAvailability(ThisObject);
EndProcedure

&AtClient
Procedure AvailabilityManagementCheckingAccount(Available, ThisIsMainCounterparty=False)
	
	Postfix = ?(ThisIsMainCounterparty, "MainCounterparty", "");
	
	ItemArray = New Array;
	ItemArray.Add("BankAccountDetailsGroup" + Postfix);
	ItemArray.Add("AccountNumber" + Postfix);
	ItemArray.Add("CashCurrency" + Postfix);
	ItemArray.Add("DecorationOfBICBank" + Postfix);
	ItemArray.Add("BankBIC" + Postfix);
	ItemArray.Add("BankCorrAccount" + Postfix);
	ItemArray.Add("DecorationBank" + Postfix);
	ItemArray.Add("Bank" + Postfix);
	ItemArray.Add("SettlementBankUsed" + Postfix);
	ItemArray.Add("SettlementBankGroup" + Postfix);
	ItemArray.Add("DecorationOfBICBankForCalculations" + Postfix);
	ItemArray.Add("TransferBankBIC" + Postfix);
	ItemArray.Add("TransferBankCorrAccount" + Postfix);
	ItemArray.Add("DecorationBankForPayments" + Postfix);
	ItemArray.Add("TransferBank" + Postfix);
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled", Available);
	
EndProcedure

&AtClientAtServerNoContext
Procedure AvailabilityManagementAdditionalInformation(Form)
	
	Items = Form.Items;
	
	ThisIsCreatingCounterpartyWithoutRegisteringPartner = Form.ActionWithTheCounterparty = 1 
	                                               And Form.ActionBasedOnResultsFound = 0;
	
	Items.LegalAddress.ReadOnly              = (Not Form.SpecifyLegalDetails And Form.ThisIsACompany = 0);
	Items.TheLegalAddressIsEqualToTheActualAddress.Enabled = (Form.SpecifyLegalDetails);
	
	Items.LegalAddress.AutoMarkIncomplete = Form.SpecifyLegalDetails And Form.TheLegalAddressOfTheCounterpartyIsRequired;
	Items.ActualAddress.AutoMarkIncomplete = (Form.SpecifyLegalDetails And Form.FactTheCounterpartySAddressIsRequired)
                                                           Or (Form.ThePartnerSAddressIsRequired And Not ThisIsCreatingCounterpartyWithoutRegisteringPartner) ;
	
	Items.TheActualAddressOfAPrivatePerson.AutoMarkIncomplete = AddressOfPrivatePersonIsRequired(Form);
	
	ManagingElementsOfPrimaryInterest(Form);
	UpdateDependentDetailsOfPartnerAttribute(Form);
	
	If Form.ThisIsACompany = 0 Then
		
		Items.MainManager.Visible            = Not ThisIsCreatingCounterpartyWithoutRegisteringPartner;
		Items.Parent.Visible                    = Not ThisIsCreatingCounterpartyWithoutRegisteringPartner;
		Items.AccessGroup.Visible               = Not ThisIsCreatingCounterpartyWithoutRegisteringPartner;
		Items.BusinessRegion.Visible                = Not ThisIsCreatingCounterpartyWithoutRegisteringPartner;
		Items.Segment.Visible                     = Not ThisIsCreatingCounterpartyWithoutRegisteringPartner;
		
		If Form.OnlyPartnersAreUsed Or ThisIsCreatingCounterpartyWithoutRegisteringPartner Then
			Items.ActualAddress.Title = NStr("vi = 'Địa chỉ thực tế của đối tác';
											|ru = 'Фактический адрес контрагента';
											|en = 'Business address of the counterparty'; fa = 'Business address of the counterparty';
											|it = 'Indirizzo effettivo del contraente';
											|pl = 'Adres faktyczny kontrahenta';
											|tr = 'Cari hesabın iş adresi'");
			Items.LegalAddress.Title = NStr("vi = 'Địa chỉ đăng ký của đối tác';
											|ru = 'Юридический адрес контрагента';
											|en = 'Counterparty legal address'; fa = 'Counterparty legal address';
											|it = 'Indirizzo giuridico del contraente';
											|pl = 'Adres prawny kontrahenta';
											|tr = 'Cari hesabın yasal adresi'");
		Else
			Items.ActualAddress.Title = NStr("vi = 'Địa chỉ thực tế của bạn hàng';
											|ru = 'Фактический адрес партнера';
											|en = 'Business address of the partner'; fa = 'آدرس کسب‌وکار شریک';
											|it = 'Indirizzo effettivo del partner';
											|pl = 'Rzeczywisty adres partnera';
											|tr = 'İş ortağının iş adresi'");
			Items.LegalAddress.Title = NStr("vi = 'Địa chỉ đăng ký của bạn hàng';
											|ru = 'Юридический адрес партнера';
											|en = 'Legal address of the partner'; fa = 'آدرس قانونی شریک';
											|it = 'Indirizzo giuridico del partner';
											|pl = 'Adres prawny partnera';
											|tr = 'İş ortağının yasal adresi'");
		EndIf;
		
		Items.AdditionalInformationPages.CurrentPage = Items.PageAdditionalInformationCompany;
		Items.AddressPages.CurrentPage = Items.PageAddressCompany;
		
		VisibilityOfHeadCounterparty = Form.OnlyPartnersAreUsed 
		                               And Form.TypeOfCompany = 3;
		
		ItemArray = New Array;
		ItemArray.Add("HeadCounterpartyAdditionalInformation");
		ItemArray.Add("PictureWarningParentCounterpartyAdditionalInformation");
		ItemArray.Add("WarningMainCounterpartyAddInformation");
		
		TMCommonUseClientServer.SetPropertyOfFormElements(
			Items, ItemArray, "Visible", VisibilityOfHeadCounterparty);
		
		If VisibilityOfHeadCounterparty Then
			
			PartnersAndCounterpartiesLocalizationClientServer.AvailabilityManagementHeadCounterparty(Form);
			
		EndIf;
		
	Else
		Items.AdditionalInformationPages.CurrentPage = Items.PageAdditionalInformationIndividual;
		Items.AddressPages.CurrentPage = Items.AddressPagePrivatePerson;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure EstablishAvailabilityOfContactPersonData(Form)
	
	SelfServiceClientServer.AvailabilityManagementContactPersonSGroupNewAssistant(Form);
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetAvailabilityOfDataInIndividualDocument(Form)
	
	ItemArray = New Array;
	ItemArray.Add("DocumentKind");
	ItemArray.Add("SeriesFromDocument");
	ItemArray.Add("DocumentNumber");
	ItemArray.Add("DateOfIssue1");
	ItemArray.Add("ValidityPeriod");
	ItemArray.Add("WhoIssuedDocument");
	ItemArray.Add("BusinessUnitCode");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Form.Items, ItemArray, "Enabled",
		Form.SpecifyTheIdentityDocument);
	
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateDependentDetailsOfPartnerAttribute(Form)
	
	Items = Form.Items;
	
	ThisIsCreatingCounterpartyWithoutRegisteringPartner = Form.ActionWithTheCounterparty = 1 
	                                               And Form.ActionBasedOnResultsFound = 0;
	
	Items.TheGroupTypeOfRelationship.Visible              = Not ThisIsCreatingCounterpartyWithoutRegisteringPartner;
	Items.GroupRelationshipTypeAdvanced.Visible = Not ThisIsCreatingCounterpartyWithoutRegisteringPartner;
	
	Items.ServedBySalesRepresentatives.Enabled = Form.Client;
	If Not Form.Client Then
		Form.ServedBySalesRepresentatives = False;
	EndIf;
	
	Items.Carrier.Enabled = Form.Vendor;
	If Not Form.Vendor Then
		Form.Carrier = False;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure ManagingElementsOfPrimaryInterest(Form)
	
	ThisIsCreatingCounterpartyWithoutRegisteringPartner = Form.ActionWithTheCounterparty = 1 
	                                               And Form.ActionBasedOnResultsFound = 0;
	
	Items = Form.Items;
	OnlyViewItems = Not ValueIsFilled(Form.ChannelOfInitialRequest);
	
	Items.SourceOfInitialRequest.ReadOnly = OnlyViewItems;
	Items.SourceOfPrimaryInterestPrivatePerson.ReadOnly = OnlyViewItems;
	
	Items.ChannelOfInitialRequest.Visible               = Not ThisIsCreatingCounterpartyWithoutRegisteringPartner;
	Items.SourceOfInitialRequest.Visible            = Not ThisIsCreatingCounterpartyWithoutRegisteringPartner;
	Items.SourceOfPrimaryInterestPrivatePerson.Visible = Not ThisIsCreatingCounterpartyWithoutRegisteringPartner;

	
EndProcedure

&AtClientAtServerNoContext
Procedure ItemManagementBankAccount(Form, ThisIsMainCounterparty=False)
	
	Postfix = ?(ThisIsMainCounterparty, "MainCounterparty", "");
	
	CommonClientServer.SetFormItemProperty(Form.Items,
		"CorrespondentBankAccountInternational" + Postfix, "Visible",
		Not Form.Items["BankGroup1" + Postfix].Visible And Form.Items["BankCorrAccount" + Postfix].Visible);
	CommonClientServer.SetFormItemProperty(Form.Items,
		"BankAccountForSettlementsInternational" + Postfix, "Visible",
		Not Form.Items["BankGroup1" + Postfix].Visible
		And Form.Items["BankAccountForPayments" + Postfix].Visible);

	CommonClientServer.SetFormItemProperty(Form.Items,
		"OtherBankDetails" + Postfix, "Width", ?(Form["SettlementBankUsed" + Postfix], 12, 8));

	CommonClientServer.SetFormItemProperty(Form.Items,
		"BankGroup1" + Postfix, "ReadOnly", Form["BankIndicationMethod" + Postfix] = "SelectionFromCatalog");
	CommonClientServer.SetFormItemProperty(Form.Items,
		"BankInternationalGroup" + Postfix, "ReadOnly",
		Form["BankIndicationMethod" + Postfix] = "SelectionFromCatalog");
		
	CommonClientServer.SetFormItemProperty(Form.Items,
		"SettlementBankGroup" + Postfix, "ReadOnly",
		Form["MethodOfSpecifyingBankForSettlements" + Postfix] = "SelectionFromCatalog");
	CommonClientServer.SetFormItemProperty(Form.Items,
		"GroupBankForSettlementsInternational" + Postfix, "ReadOnly",
		Form["MethodOfSpecifyingBankForSettlements" + Postfix] = "SelectionFromCatalog");
		
	CommonClientServer.SetFormItemProperty(Form.Items,
		"BankInGroup" + Postfix, "Enabled", Form["BankIndicationMethod" + Postfix] = "SelectionFromCatalog");
	CommonClientServer.SetFormItemProperty(Form.Items,
		"BankForSettlementsInGroup" + Postfix, "Enabled",
		Form["MethodOfSpecifyingBankForSettlements" + Postfix] = "SelectionFromCatalog");
		
	CommonClientServer.SetFormItemProperty(Form.Items,
		"BankAccountForPayments" + Postfix, "Enabled", Form["SettlementBankUsed" + Postfix]);
	CommonClientServer.SetFormItemProperty(Form.Items,
		"TransferBankBIC" + Postfix, "Enabled", Form["SettlementBankUsed" + Postfix]);
	CommonClientServer.SetFormItemProperty(Form.Items,
		"BankNameForPaymentsInt" + Postfix, "Enabled",
		Form["SettlementBankUsed" + Postfix]);

	CommonClientServer.SetFormItemProperty(Form.Items,
		"SelectBankForSettlementsGroup" + Postfix, "Visible", Form["SettlementBankUsed" + Postfix]);
		
	If Form.InternationalBankAccountDetails Then
		CommonClientServer.SetFormItemProperty(Form.Items,
			"AccountNumber" + Postfix, "Mask", "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
	EndIf;
	
	CommonClientServer.SetFormItemProperty(Form.Items,
		"BankBIC" + Postfix, "Title",
		?(Form["ForeignBank" + Postfix], NStr("vi = 'Mã';
												|ru = 'Код';
												|en = 'Code'; fa = 'کد';
												|it = 'Codice';
												|pl = 'Code';
												|tr = 'Kod'"), NStr("vi = 'Mã ngân hàng';
																	|ru = 'БИК';
																	|en = 'Bank code'; fa = 'کد بانک';
																	|it = 'BIC';
																	|pl = 'Bank code';
																	|tr = 'BIC'")));
	
	CommonClientServer.SetFormItemProperty(Form.Items,
		"TransferBankBIC" + Postfix, "Title",
		?(Form["ForeignBank" + Postfix], NStr("vi = 'Mã';
												|ru = 'Код';
												|en = 'Code'; fa = 'کد';
												|it = 'Codice';
												|pl = 'Code';
												|tr = 'Kod'"), NStr("vi = 'Mã ngân hàng';
																	|ru = 'БИК';
																	|en = 'Bank code'; fa = 'کد بانک';
																	|it = 'BIC';
																	|pl = 'Bank code';
																	|tr = 'BIC'")));

	CurrencyAccount = (ValueIsFilled(Form["CashCurrency" + Postfix])
					And Form["CashCurrency" + Postfix] <> Form.CurrencyOfComplianceAccounting);
	
	CommonClientServer.SetFormItemProperty(Form.Items,
		"BankCorrAccount" + Postfix, "Visible", Not Form["ForeignBank" + Postfix] And Not CurrencyAccount);
	CommonClientServer.SetFormItemProperty(Form.Items,
		"TransferBankCorrAccount" + Postfix, "Visible", Not Form["ForeignBank" + Postfix] And Not CurrencyAccount);
	
	CommonClientServer.SetFormItemProperty(Form.Items,
		"BankAccountForPayments" + Postfix, "Visible", Not(Not Form["ForeignBank" + Postfix] And Not CurrencyAccount));
	
	CommonClientServer.SetFormItemProperty(Form.Items,
		"BankCountryInternational" + Postfix, "Visible", Not Form.NationalBankAccountDetails);
	
	CommonClientServer.SetFormItemProperty(Form.Items,
		"TransferBankDescription" + Postfix, "Visible", Not CurrencyAccount);
	CommonClientServer.SetFormItemProperty(Form.Items,
		"TransferBankCity" + Postfix, "Visible", Not CurrencyAccount);
		
	CommonClientServer.SetFormItemProperty(Form.Items,
		"ThisIsAnIBAN" + Postfix, "Visible", Form.InternationalBankAccountDetails);
	CommonClientServer.SetFormItemProperty(Form.Items,
		"BankInternationalGroup" + Postfix, "Visible", Form.InternationalBankAccountDetails);
	CommonClientServer.SetFormItemProperty(Form.Items,
		"GroupBankForSettlementsInternational" + Postfix, "Visible", Form.InternationalBankAccountDetails);
	
	CommonClientServer.SetFormItemProperty(Form.Items,
		"BankInternationalGroup" + Postfix, "ShowTitle", Form.NationalBankAccountDetails);
		
	CommonClientServer.SetFormItemProperty(Form.Items,
		"GroupBankForSettlementsInternational" + Postfix, "ShowTitle",
		Form.NationalBankAccountDetails);

	CommonClientServer.SetFormItemProperty(Form.Items,
		"BankGroup1" + Postfix, "ShowTitle", 
		Not(Not Form.InternationalBankAccountDetails And Form.NationalBankAccountDetails));
	CommonClientServer.SetFormItemProperty(Form.Items,
		"SettlementBankGroup" + Postfix, "ShowTitle", 
		Not(Not Form.InternationalBankAccountDetails And Form.NationalBankAccountDetails));
	
	CommonClientServer.SetFormItemProperty(Form.Items,
		"BankGroup1" + Postfix, "Visible", Form.NationalBankAccountDetails);
	CommonClientServer.SetFormItemProperty(Form.Items,
		"SettlementBankGroup" + Postfix, "Visible", Form.NationalBankAccountDetails);
		
	CommonClientServer.SetFormItemProperty(Form.Items,
		"BankGroup1" + Postfix, "ReadOnly", Form["BankIndicationMethod" + Postfix] = "SelectionFromCatalog");
	CommonClientServer.SetFormItemProperty(Form.Items,
		"BankInternationalGroup" + Postfix, "ReadOnly",
		Form["BankIndicationMethod" + Postfix] = "SelectionFromCatalog");
	
	CommonClientServer.SetFormItemProperty(Form.Items,
		"CorrespondentBankAccountForSettlementsInternational" + Postfix, "Visible",
		Not Form.NationalBankAccountDetails);
	
	CommonClientServer.SetFormItemProperty(Form.Items,
		"CountryOfBankForSettlementsInternational" + Postfix, "Visible", Not Form.NationalBankAccountDetails);
	
EndProcedure

#EndRegion

#Region SearchForPrimaryInformation_

&AtServer
Function SubqueryByName()
	
	TermsAndConditionsForUnknownPartnerCounterparty = " AND (NOT Counterparties.Partner.Predefined)";
	TermsAndConditionsForUnknownPartner           = " AND (NOT Partners.Ref.Predefined)";
	
	SubqueryText = "
	|SELECT ALLOWED
	|	Partners.Ref AS Partner,
	|	Partners.Ref AS FoundByReference,
	|	CASE
	|		WHEN Partners.Description LIKE &Name1
	|			THEN &StringName
	|			ELSE &StringFullName
	|	END AS FoundInProps
	|INTO FoundByName_
	|FROM
	|	Catalog.Partners AS Partners
	|WHERE
	|	Partners.Description LIKE &Name1 OR Partners.DescriptionFull LIKE &Name1 AND &ConditionForUnknownPartner";
	
	If Not OnlyPartnersAreUsed Then
		
		SubqueryText = SubqueryText + "
		|
		|UNION ALL
		|";
		
		SubqueryText = SubqueryText + "
		|SELECT 
		|	Counterparties.Partner,
		|	Counterparties.Ref,
		|	CASE
		|		WHEN Counterparties.Description LIKE &Name1
		|			THEN &StringName
		|			ELSE &StringFullName
		|	END
		|FROM
		|	Catalog.Counterparties AS Counterparties
		|WHERE
		|	(Counterparties.Description LIKE &Name1 OR Counterparties.DescriptionFull LIKE &Name1) AND 
		|	Counterparties.Partner <> VALUE(Catalog.Partners.EmptyRef) AND &ConditionForUnknownPartnerCounterparty";
		
	EndIf;
	
	SubqueryText = SubqueryText + "
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|
	|";
	
	
	SubqueryText = StrReplace(SubqueryText, "AND &ConditionForUnknownPartnerCounterparty", ?(BasedOnTheCounterparty, TermsAndConditionsForUnknownPartnerCounterparty,""));
	SubqueryText = StrReplace(SubqueryText, "AND &ConditionForUnknownPartner", ?(BasedOnTheCounterparty, TermsAndConditionsForUnknownPartner,""));
	
	Return SubqueryText;
	
EndFunction

&AtServer
Function SubqueryByEmailAddress()

	TermsAndConditionsForUnknownPartner = " AND (NOT PartnersContactInformation.Ref.Predefined)";
	TermsAndConditionsForUnknownCLPartner = " AND (NOT ContactPersonsOfPartnersContactInformation.Ref.Owner.Predefined)";
	
	QueryText =  "
	|SELECT ALLOWED
	|	PartnersContactInformation.Ref AS Partner,
	|	PartnersContactInformation.Ref AS FoundByReference,
	|	&EmailRow                        AS FoundInProps,
	|	PartnersContactInformation.Kind    AS ContactType_
	|INTO FoundAtItemInstance
	|FROM
	|	Catalog.Partners.ContactInformation AS PartnersContactInformation
	|WHERE
	|	PartnersContactInformation.EMAddress IN (&ItemInstanceAddresses) AND &ConditionForUnknownPartner
	|
	|UNION ALL
	|
	|SELECT 
	|	ContactPersonsOfPartnersContactInformation.Ref.Owner,
	|	ContactPersonsOfPartnersContactInformation.Ref,
	|	&EmailRow,
	|	ContactPersonsOfPartnersContactInformation.Kind
	|FROM
	|	Catalog.ContactPersonsForPartners.ContactInformation AS ContactPersonsOfPartnersContactInformation
	|WHERE
	|	ContactPersonsOfPartnersContactInformation.EMAddress IN (&ItemInstanceAddresses) AND &ConditionForUnknownCLPartner
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////";
	
	
	QueryText = StrReplace(QueryText, "AND &ConditionForUnknownCLPartner", ?(BasedOnTheCounterparty, TermsAndConditionsForUnknownCLPartner,""));
	QueryText = StrReplace(QueryText, "AND &ConditionForUnknownPartner", ?(BasedOnTheCounterparty, TermsAndConditionsForUnknownPartner,""));
	
	Return QueryText;
	
EndFunction

&AtServer
Function SubqueryByPhoneNumber(ArrayOfPhonePresentations)
	
	//Partners
	
	QueryText = "
	|SELECT ALLOWED
	|	PartnersContactInformation.Ref AS Partner,
	|	PartnersContactInformation.Ref AS FoundByReference,
	|	&PhoneLine                      AS FoundInProps,
	|	PartnersContactInformation.Kind    AS ContactType_
	|INTO FoundByPhone
	|FROM
	|	Catalog.Partners.ContactInformation AS PartnersContactInformation
	|WHERE
	|	(PartnersContactInformation.PhoneNumberWithoutCodes IN(&ArrayOfPhoneNumbers)"; //@Query-part
		
	For Indus = 0 To  ArrayOfPhonePresentations.Count()-1 Do
		
		QueryText = QueryText + " OR PartnersContactInformation.Presentation LIKE &PhonePresentation" + String(Indus) + " "  ; 
		
	EndDo;
	
	QueryText = QueryText + ")
	|	AND (PartnersContactInformation.Type = VALUE(Enum.ContactInformationTypes.Phone)
	|			OR PartnersContactInformation.Type = VALUE(Enum.ContactInformationTypes.Fax))";
	
	If BasedOnTheCounterparty Then
		
		QueryText = QueryText + " AND (NOT PartnersContactInformation.Ref.Predefined)";
		
	EndIf;
	
	// contact persons
	
	QueryText = QueryText + "
	|
	|UNION ALL
	|
	|SELECT 
	|	ContactPersonsOfPartnersContactInformation.Ref.Owner,
	|	ContactPersonsOfPartnersContactInformation.Ref,
	|	&PhoneLine,
	|	ContactPersonsOfPartnersContactInformation.Kind
	|FROM
	|	Catalog.ContactPersonsForPartners.ContactInformation AS ContactPersonsOfPartnersContactInformation
	|WHERE
	|	(ContactPersonsOfPartnersContactInformation.PhoneNumberWithoutCodes IN (&ArrayOfPhoneNumbers)"; //@Query-part
		
	For Indus = 0 To  ArrayOfPhonePresentations.Count()-1 Do
		
		QueryText = QueryText + " OR ContactPersonsOfPartnersContactInformation.Presentation LIKE &PhonePresentation" + String(Indus) + " "  ; 
		
	EndDo;
	
	QueryText = QueryText + ")
	|	AND (ContactPersonsOfPartnersContactInformation.Type = VALUE(Enum.ContactInformationTypes.Phone)
	|			OR ContactPersonsOfPartnersContactInformation.Type = VALUE(Enum.ContactInformationTypes.Fax))";
	
	If BasedOnTheCounterparty Then
		
		QueryText = QueryText + " AND (NOT ContactPersonsOfPartnersContactInformation.Ref.Owner.Predefined)";
		
	EndIf;
	
	// Natural person
	
	QueryText = QueryText + "
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|"; 
	
	Return QueryText;
	
EndFunction 

&AtServer
Function SubqueryByRegistrationNumberInCountryOfRegistration()
	
	TermsAndConditionsForUnknownPartner = " AND (NOT Counterparties.Partner.Predefined)";
	
	QueryText = "
	|SELECT ALLOWED
	|	Counterparties.Partner AS Partner,
	|	Counterparties.Ref  AS FoundByReference,
	|	&LineRegistrationNumber AS FoundInProps
	|INTO CounterpartiesByRegistrationNumber
	|FROM
	|	Catalog.Counterparties AS Counterparties
	|WHERE
	|	Counterparties.RegistrationNumber = &RegistrationNumber AND
	|	Counterparties.Partner <> VALUE(Catalog.Partners.EmptyRef) AND &ConditionForUnknownPartner
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////";
	
	QueryText = StrReplace(QueryText, "AND &ConditionForUnknownPartner", ?(BasedOnTheCounterparty, TermsAndConditionsForUnknownPartner,""));
	
	Return QueryText;
	
EndFunction

&AtServer
Procedure AddRequestForTIN(QueryText, BasedOnTheCounterparty)
	
	TermsAndConditionsForUnknownPartner = " AND (NOT Counterparties.Partner.Predefined)";
	
	QueryText = QueryText + "
	|SELECT ALLOWED
	|	Counterparties.Partner AS Partner,
	|	Counterparties.Ref  AS FoundByReference,
	|	&TINLine AS      FoundInProps
	|INTO ContractorsByTin
	|FROM
	|	Catalog.Counterparties AS Counterparties
	|WHERE
	|	Counterparties.TIN = &TIN AND
	|	Counterparties.Partner <> VALUE(Catalog.Partners.EmptyRef) " + ?(BasedOnTheCounterparty, TermsAndConditionsForUnknownPartner,"") + "
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////";
	
EndProcedure

&AtServer
Function SubqueryByTaxNumberInCountryOfRegistration()
	
	TermsAndConditionsForUnknownPartner = " AND (NOT Counterparties.Partner.Predefined)";
	
	QueryText = "
	|SELECT ALLOWED
	|	Counterparties.Partner   AS Partner,
	|	Counterparties.Ref    AS FoundByReference,
	|	&LineTaxNumber AS FoundInProps
	|INTO CounterpartiesByTaxNumber
	|FROM
	|	Catalog.Counterparties AS Counterparties
	|WHERE
	|	Counterparties.TaxNumber = &TaxNumber AND
	|	Counterparties.Partner <> VALUE(Catalog.Partners.EmptyRef) AND &ConditionForUnknownPartner
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////";
	
	QueryText = StrReplace(QueryText, "AND &ConditionForUnknownPartner", ?(BasedOnTheCounterparty, TermsAndConditionsForUnknownPartner,""));
	
	Return QueryText;
	
EndFunction

&AtServer
Function SubqueryForIdentityDocument()
	
	TermsAndConditionsForUnknownPartner = " AND (NOT Partners.Predefined)";
	
	QueryText = "
	|SELECT ALLOWED
	|	DocumentsPersonsSliceLast.Person AS Counterparty
	|INTO CounterpartiesAccordingToDocumentsOfIndividuals
	|FROM
	|	InformationRegister.DocumentsPersons.SliceLast(&CurrentDate, Person REFS Catalog.Counterparties) AS DocumentsPersonsSliceLast
	|WHERE
	|	DocumentsPersonsSliceLast.DocumentKind = &DocumentKind
	|	AND DocumentsPersonsSliceLast.Series = &Series
	|	AND DocumentsPersonsSliceLast.Number = &Number
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	Partners.Ref        AS Partner,
	|	Counterparties.Ref     AS FoundByReference,
	|	&StringDocumentData AS FoundInProps
	|INTO DocumentCounterparties_
	|FROM
	|	CounterpartiesAccordingToDocumentsOfIndividuals AS CounterpartiesAccordingToDocumentsOfIndividuals
	|		INNER JOIN Catalog.Counterparties AS Counterparties
	|		ON CounterpartiesAccordingToDocumentsOfIndividuals.Counterparty = Counterparties.Ref
	|		INNER JOIN Catalog.Partners AS Partners
	|		ON (Counterparties.Partner = Partners.Ref) AND &ConditionForUnknownPartner
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////";
	
	QueryText = StrReplace(QueryText, "AND &ConditionForUnknownPartner", ?(BasedOnTheCounterparty, TermsAndConditionsForUnknownPartner,""));
	
	Return QueryText;
	
EndFunction

&AtServer
Function FullNameSubquery(Query)
	
	ArrayOfFullNames = New Array;
	If Not IsBlankString(PartnerSLastName)
		And ThisIsACompany = 1 Then
		AddFullNameToArray(ArrayOfFullNames, PartnerSLastName, PartnerName_3, PartnerSMiddleName);
	EndIf;
	If Not IsBlankString(LastNameKL) Then
		AddFullNameToArray(ArrayOfFullNames, LastNameKL, KLName, PatronymicKL);
	EndIf;
	
	SubqueryForContactPersons = "";
	TermsAndConditionsForUnknownPartner = " AND (NOT ContactPersonsForPartners.Owner.Predefined)";
	
	For Indus = 1 To ArrayOfFullNames.Count() Do
	
		SubqueryIsEmpty = IsBlankString(SubqueryForContactPersons);
		
		If Not SubqueryIsEmpty Then
			SubqueryForContactPersons = SubqueryForContactPersons + "
			|UNION ALL"
		EndIf;
		
		SubqueryForContactPersons = SubqueryForContactPersons + "
		|
		|SELECT &TextAllowed,
		|	ContactPersonsForPartners.Owner AS Partner,
		|	ContactPersonsForPartners.Ref   AS FoundByReference,
		|	&StringName              AS FoundInProps
		|	,&TheTextToPut
		|FROM
		|	Catalog.ContactPersonsForPartners AS ContactPersonsForPartners
		|WHERE
		|	ContactPersonsForPartners.Description LIKE LastFirstName_X AND &ConditionForUnknownPartner
		|";
		
		SubqueryForContactPersons = StrReplace(SubqueryForContactPersons, "&TextAllowed,", ?(Indus = 1,"ALLOWED",""));
		SubqueryForContactPersons = StrReplace(SubqueryForContactPersons, ",&TheTextToPut", ?(SubqueryIsEmpty,"INTO FoundByContactPersonSFullName",""));
		SubqueryForContactPersons = StrReplace(SubqueryForContactPersons, "LastFirstName_X", "&LastFirstName_" + String(Indus));
		SubqueryForContactPersons = StrReplace(SubqueryForContactPersons, "AND &ConditionForUnknownPartner", ?(BasedOnTheCounterparty, TermsAndConditionsForUnknownPartner,""));
		
		Query.SetParameter("LastFirstName_" + String(Indus), ArrayOfFullNames[Indus-1]+"%")

	EndDo;
	
	SubqueryForContactPersons = SubqueryForContactPersons + "
	|;
	|////////////////////////////////////////////////////////////////////////////////";
	
	Return SubqueryForContactPersons ;
	
EndFunction

&AtServer
Function SubqueryByCounterpartyName()
	
	TermsAndConditionsForUnknownPartner = " AND (NOT Counterparties.Partner.Predefined)";
	
	QueryText = "
	|SELECT ALLOWED
	|	Counterparties.Partner AS Partner,
	|	Counterparties.Ref  AS FoundByReference,
	|	CASE
	|		WHEN  Counterparties.Description LIKE &Name1
	|			THEN &StringName
	|			ELSE &StringFullName
	|	END AS FoundInProps
	|INTO CounterpartiesByName
	|FROM
	|	Catalog.Counterparties AS Counterparties
	|WHERE
	|	Counterparties.Description LIKE &NameOfTheCounterparty OR Counterparties.DescriptionFull LIKE &NameOfTheCounterparty AND &ConditionForUnknownPartner
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////";
	
	QueryText = StrReplace(QueryText, "AND &ConditionForUnknownPartner", ?(BasedOnTheCounterparty, TermsAndConditionsForUnknownPartner,""));
	
	Return QueryText;
	
EndFunction

&AtServer
Function SummaryQuery(TheStructureOfTheSearch)
	
	SummaryQuery ="
		|
		|SELECT 
		|	FoundByName_.Partner           AS Partner,
		|	FoundByName_.FoundByReference   AS FoundByReference,
		|	FoundByName_.FoundInProps AS FoundInProps,
		|	UNDEFINED                        AS ContactType_
		|INTO MatchesFound
		|FROM
		|	FoundByName_ AS FoundByName_
		|";
	
	If TheStructureOfTheSearch.RegistrationNumber Then
		
		SummaryQuery = SummaryQuery + "
		|
		|UNION ALL
		|
		|SELECT 
		|	CounterpartiesByRegistrationNumber.Partner,
		|	CounterpartiesByRegistrationNumber.FoundByReference,
		|	CounterpartiesByRegistrationNumber.FoundInProps,
		|	UNDEFINED
		|FROM
		|	CounterpartiesByRegistrationNumber AS CounterpartiesByRegistrationNumber
		|"; 
		
	EndIf;
	
	If TheStructureOfTheSearch.TaxNumber Then
		
		SummaryQuery = SummaryQuery + "
		|
		|UNION ALL
		|
		|SELECT 
		|	CounterpartiesByTaxNumber.Partner,
		|	CounterpartiesByTaxNumber.FoundByReference,
		|	CounterpartiesByTaxNumber.FoundInProps,
		|	UNDEFINED
		|FROM
		|	CounterpartiesByTaxNumber AS CounterpartiesByTaxNumber
		|"; 
		
	EndIf;
	
	If TheStructureOfTheSearch.EMAddress Then
		
		SummaryQuery = SummaryQuery + "
		|
		|UNION ALL
		|
		|SELECT 
		|	FoundAtItemInstance.Partner,
		|	FoundAtItemInstance.FoundByReference,
		|	FoundAtItemInstance.FoundInProps,
		|	FoundAtItemInstance.ContactType_
		|FROM
		|	FoundAtItemInstance AS FoundAtItemInstance
		|";		
		
	EndIf;
	
	If TheStructureOfTheSearch.PhoneNumber Then
		
		SummaryQuery = SummaryQuery +  "
		|
		|UNION ALL
		|
		|SELECT 
		|	FoundByPhone.Partner,
		|	FoundByPhone.FoundByReference,
		|	FoundByPhone.FoundInProps,
		|	FoundByPhone.ContactType_
		|FROM
		|	FoundByPhone AS FoundByPhone
		|";
		
	EndIf;
	
	If TheStructureOfTheSearch.LASTFIRSTNAME Then
		
		SummaryQuery = SummaryQuery +  "
		|
		|UNION ALL
		|
		|SELECT 
		|	FoundByContactPersonSFullName.Partner,
		|	FoundByContactPersonSFullName.FoundByReference,
		|	FoundByContactPersonSFullName.FoundInProps,
		|	UNDEFINED
		|FROM
		|	FoundByContactPersonSFullName AS FoundByContactPersonSFullName
		|";
		
	EndIf;
	
	If TheStructureOfTheSearch.NameOfTheCounterparty Then
		
		SummaryQuery = SummaryQuery + "
		|
		|UNION ALL
		|
		|SELECT 
		|	CounterpartiesByName.Partner,
		|	CounterpartiesByName.FoundByReference,
		|	CounterpartiesByName.FoundInProps,
		|	UNDEFINED
		|FROM
		|	CounterpartiesByName AS CounterpartiesByName
		|"; 
		
	EndIf;
	
	If TheStructureOfTheSearch.DocumentCounterparty_ Then
	
		SummaryQuery = SummaryQuery + "
		|
		|UNION ALL
		|
		|SELECT 
		|	DocumentCounterparties_.Partner,
		|	DocumentCounterparties_.FoundByReference,
		|	DocumentCounterparties_.FoundInProps,
		|	UNDEFINED
		|FROM
		|	DocumentCounterparties_ AS DocumentCounterparties_
		|";
	
	EndIf;
	
	PartnersAndCounterpartiesLocalization.AddSummaryQueryBasedOnSearchStructure(SummaryQuery, TheStructureOfTheSearch);
	
	SummaryQuery = SummaryQuery + "
	|INDEX BY
	|	Partner,
	|	FoundByReference,
	|	FoundInProps
	|;
	|////////////////////////////////////////////////////////////////////////////////";
	
	SummaryQuery = SummaryQuery + "
	|SELECT
	|	MatchesFound.Partner             AS Partner,
	|	COUNT(MatchesFound.Partner) AS NumberOfSimilarPartnersFound
	|INTO MatchesPartners
	|FROM
	|	MatchesFound AS MatchesFound
	|
	|GROUP BY
	|	MatchesFound.Partner
	|INDEX BY
	|	Partner
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	MatchesPartners.Partner                   AS Partner,
	|	PartnerDetails_.Attribute                   AS Attribute,
	|	ISNULL(PartnerContacts.Kind, UNDEFINED) AS ContactType_,
	|	PartnerDetails_.Value                   AS ValueOfGenerated,
	|	PartnerDetails_.Order                    AS OrderOfProps,
	|	PartnerDetails_.Essential               AS Essential,
	|	CASE
	|		WHEN PartnerDetails_.Attribute = &PartnerTypeString
	|			THEN PRESENTATION(Partners.LegalEntityIndividual)
	|		WHEN PartnerDetails_.Attribute = &StringName
	|			THEN Partners.Description
	|		WHEN PartnerDetails_.Attribute = &StringFullName
	|			THEN Partners.DescriptionFull
	|		WHEN PartnerDetails_.Attribute = &EmailRow
	|			THEN PartnerContacts.EMAddress
	|		WHEN PartnerDetails_.Attribute = &PhoneLine
	|			THEN PartnerContacts.Presentation
	|		ELSE
	|			""""
	|	END AS Value
	|INTO PartnerData_
	|FROM
	|	MatchesPartners AS MatchesPartners
	|		INNER JOIN Catalog.Partners AS Partners
	|		ON MatchesPartners.Partner = Partners.Ref
	|		INNER JOIN PartnerDetails_ AS PartnerDetails_
	|		ON (TRUE)
	|		LEFT JOIN Catalog.Partners.ContactInformation AS PartnerContacts
	|		ON MatchesPartners.Partner = PartnerContacts.Ref
	|			AND (CASE
	|				WHEN PartnerDetails_.Attribute = &EmailRow
	|					THEN PartnerContacts.Type = VALUE(Enum.ContactInformationTypes.Email)
	|				WHEN PartnerDetails_.Attribute = &PhoneLine
	|					THEN PartnerContacts.Type = VALUE(Enum.ContactInformationTypes.Phone)
	|							OR PartnerContacts.Type = VALUE(Enum.ContactInformationTypes.Fax)
	|				ELSE FALSE
	|			END)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED DISTINCT
	|	MatchesFound.Partner         AS Partner,
	|	MatchesFound.FoundByReference AS Counterparty
	|INTO MatchingCounterparties
	|FROM
	|	MatchesFound AS MatchesFound
	|		INNER JOIN Catalog.Counterparties AS Counterparties
	|		ON MatchesFound.FoundByReference = Counterparties.Ref
	|WHERE
	|	NOT &OnlyPartnersAreUsed
	|
	|UNION ALL
	|
	|SELECT
	|	MatchesPartners.Partner,
	|	Counterparties.Ref
	|FROM
	|	MatchesPartners AS MatchesPartners
	|		INNER JOIN Catalog.Counterparties AS Counterparties
	|		ON MatchesPartners.Partner = Counterparties.Partner
	|WHERE
	|	&OnlyPartnersAreUsed
	|INDEX BY
	|	Partner,
	|	Counterparty
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	MatchingCounterparties.Partner     AS Partner,
	|	MatchingCounterparties.Counterparty  AS Counterparty,
	|	CounterpartyDetails_.Attribute     AS Attribute,
	|	UNDEFINED                      AS ContactType_,
	|	CounterpartyDetails_.Value     AS ValueOfGenerated,
	|	CounterpartyDetails_.Order      AS OrderOfProps,
	|	CounterpartyDetails_.Essential AS Essential,
	|	CASE
	|		WHEN CounterpartyDetails_.Attribute = &CounterpartyTypeLine
	|			THEN
	|				CASE WHEN Counterparties.BranchOffice
	|					THEN &LineSeparateDivision
	|					ELSE PRESENTATION(Counterparties.LegalEntityIndividual)
	|				END
	|		WHEN CounterpartyDetails_.Attribute = &StringName
	|			THEN Counterparties.Description
	|		WHEN CounterpartyDetails_.Attribute = &LineTaxNumber
	|			THEN Counterparties.TaxNumber
	|		WHEN CounterpartyDetails_.Attribute = &StringFullName
	|			THEN Counterparties.DescriptionFull
	|		WHEN CounterpartyDetails_.Attribute = &LineRegistrationNumber
	|			THEN Counterparties.RegistrationNumber
	|		WHEN CounterpartyDetails_.Attribute = &StringDocumentData
	|			THEN DocumentsOfIndividuals.Presentation
	|		ELSE &AddConditions
	|	END AS Value
	|INTO CounterpartyData_
	|FROM
	|	MatchingCounterparties AS MatchingCounterparties
	|		INNER JOIN Catalog.Counterparties AS Counterparties
	|		ON MatchingCounterparties.Counterparty = Counterparties.Ref
	|		INNER JOIN CounterpartyDetails_ AS CounterpartyDetails_
	|		ON (TRUE)
	|		LEFT JOIN InformationRegister.DocumentsPersons.SliceLast(&CurrentDate, Person REFS Catalog.Counterparties) AS DocumentsOfIndividuals
	|		ON MatchingCounterparties.Counterparty = DocumentsOfIndividuals.Person
	|			AND CounterpartyDetails_.Attribute = &StringDocumentData
	|			AND DocumentsOfIndividuals.DocumentKind = &DocumentKind
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	MatchesFound.Partner         AS Partner,
	|	MatchesFound.FoundByReference AS ContactPerson
	|INTO MatchContactPersons
	|FROM
	|	MatchesFound AS MatchesFound
	|		INNER JOIN Catalog.ContactPersonsForPartners AS ContactPersonsForPartners
	|		ON MatchesFound.FoundByReference = ContactPersonsForPartners.Ref
	|INDEX BY
	|	Partner,
	|	ContactPerson
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	MatchContactPersons.Partner                  AS Partner,
	|	MatchContactPersons.ContactPerson           AS ContactPerson,
	|	ContactPersonDetails_.Attribute                 AS Attribute,
	|	ISNULL(ContactsOfContactPersons.Kind, UNDEFINED) AS ContactType_,
	|	ContactPersonDetails_.Value                 AS ValueOfGenerated,
	|	ContactPersonDetails_.Order                  AS OrderOfProps,
	|	ContactPersonDetails_.Essential             AS Essential,
	|	CASE
	|		WHEN ContactPersonDetails_.Attribute = &StringName
	|			THEN ContactPersonsForPartners.Description
	|		WHEN ContactPersonDetails_.Attribute = &EmailRow
	|			THEN ContactsOfContactPersons.EMAddress
	|		WHEN ContactPersonDetails_.Attribute = &PhoneLine
	|			THEN ContactsOfContactPersons.Presentation
	|		ELSE
	|			""""
	|	END AS Value
	|INTO ContactPersonsData
	|FROM
	|	MatchContactPersons AS MatchContactPersons
	|		INNER JOIN Catalog.ContactPersonsForPartners AS ContactPersonsForPartners
	|		ON MatchContactPersons.ContactPerson = ContactPersonsForPartners.Ref
	|		INNER JOIN ContactPersonDetails_ AS ContactPersonDetails_
	|		ON (TRUE)
	|		LEFT JOIN Catalog.ContactPersonsForPartners.ContactInformation AS ContactsOfContactPersons
	|		ON MatchContactPersons.ContactPerson = ContactsOfContactPersons.Ref
	|			AND (CASE
	|				WHEN ContactPersonDetails_.Attribute = &EmailRow
	|					THEN ContactsOfContactPersons.Type = VALUE(Enum.ContactInformationTypes.Email)
	|				WHEN ContactPersonDetails_.Attribute = &PhoneLine
	|					THEN ContactsOfContactPersons.Type = VALUE(Enum.ContactInformationTypes.Phone)
	|							OR ContactsOfContactPersons.Type = VALUE(Enum.ContactInformationTypes.Fax)
	|				ELSE FALSE
	|			END)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	MatchesPartners.Partner                     AS Partner,
	|	MatchesPartners.NumberOfSimilarPartnersFound AS NumberOfSimilarPartnersFound,
	|	Partners.MainManager                      AS MainManager,
	|	Partners.Presentation                         AS Presentation
	|FROM
	|	MatchesPartners AS MatchesPartners
	|		INNER JOIN Catalog.Partners AS Partners
	|		ON MatchesPartners.Partner = Partners.Ref 
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PartnerData_.Partner              AS Partner,
	|	PartnerData_.Partner              AS FoundByReference,
	|	PartnerData_.Value             AS ValueOfFound,
	|	PartnerData_.ValueOfGenerated AS ValueOfGenerated,
	|	PartnerData_.Essential         AS Essential,
	|	1                                    AS NodeOrder,
	|	PartnerData_.OrderOfProps     AS OrderOfProps,
	|	CASE
	|		WHEN PartnerData_.ContactType_ = UNDEFINED
	|			THEN PartnerData_.Attribute
	|		ELSE PartnerData_.ContactType_
	|	END AS Attribute,
	|	CASE
	|		WHEN MatchesFound.FoundInProps IS NULL
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS Coincidence
	|	
	|FROM
	|	PartnerData_ AS PartnerData_
	|		LEFT JOIN MatchesFound AS MatchesFound
	|		ON PartnerData_.Partner = MatchesFound.Partner
	|		 AND PartnerData_.Partner = MatchesFound.FoundByReference
	|		 AND PartnerData_.Attribute = MatchesFound.FoundInProps
	|		 AND PartnerData_.ContactType_ = MatchesFound.ContactType_
	|
	|UNION ALL
	|
	|SELECT
	|	CounterpartyData_.Partner,
	|	CounterpartyData_.Counterparty,
	|	CounterpartyData_.Value,
	|	CounterpartyData_.ValueOfGenerated,
	|	CounterpartyData_.Essential,
	|	2,
	|	CounterpartyData_.OrderOfProps,
	|	CounterpartyData_.Attribute,
	|	CASE
	|		WHEN MatchesFound.FoundInProps IS NULL
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS Coincidence
	|FROM
	|	CounterpartyData_ AS CounterpartyData_
	|		LEFT JOIN MatchesFound AS MatchesFound
	|		ON CounterpartyData_.Partner = MatchesFound.Partner
	|		 AND CounterpartyData_.Counterparty = MatchesFound.FoundByReference
	|		 AND CounterpartyData_.Attribute = MatchesFound.FoundInProps
	|
	|UNION ALL
	|
	|SELECT
	|	ContactPersonsData.Partner,
	|	ContactPersonsData.ContactPerson,
	|	ContactPersonsData.Value,
	|	ContactPersonsData.ValueOfGenerated,
	|	ContactPersonsData.Essential,
	|	3,
	|	ContactPersonsData.OrderOfProps,
	|	CASE
	|		WHEN ContactPersonsData.ContactType_ = UNDEFINED
	|			THEN ContactPersonsData.Attribute
	|		ELSE ContactPersonsData.ContactType_
	|	END AS Attribute,
	|	CASE
	|		WHEN MatchesFound.FoundInProps IS NULL
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS Coincidence
	|FROM
	|	ContactPersonsData AS ContactPersonsData
	|		LEFT JOIN MatchesFound AS MatchesFound
	|		ON ContactPersonsData.Partner = MatchesFound.Partner
	|		 AND ContactPersonsData.ContactPerson = MatchesFound.FoundByReference
	|		 AND ContactPersonsData.Attribute = MatchesFound.FoundInProps
	|		 AND ContactPersonsData.ContactType_ = MatchesFound.ContactType_
	|
	|ORDER BY
	|	NodeOrder,
	|	OrderOfProps
	|TOTALS BY
	|	Partner,
	|	FoundByReference";
	
	PartnersAndCounterpartiesLocalization.SetAdditionalConditionsForSummaryQuery(SummaryQuery);
	
	SummaryQuery = StrReplace(SummaryQuery, "&AddConditions", """""");
	
	Return SummaryQuery;
	
EndFunction

&AtServer
Procedure SearchForPrimaryInformation()
	
	CurrentFoundPartner = Catalogs.Partners.EmptyRef();
	
	TheStructureOfTheSearch = New Structure;
	TheStructureOfTheSearch.Insert("NameOfTheCounterparty", SpecifyLegalDetails And ThisIsACompany = 0 And Not OnlyPartnersAreUsed);
	TheStructureOfTheSearch.Insert("EMAddress",                 ?(ThisIsACompany = 0, Not IsBlankString(EppartnerSAddress) Or (SpecifyTheContactPersonSDetails
	                                                    And Not IsBlankString(EPCLAddress)),Not IsBlankString(EppartnerSAddressIndividual)));
	TheStructureOfTheSearch.Insert("PhoneNumber",           ?(ThisIsACompany = 0,Not IsBlankString(PartnerSPhoneNumber) Or (SpecifyTheContactPersonSDetails 
	                                                    And (Not IsBlankString(PhoneNumberKL)Or Not IsBlankString(MobilePhoneKL))),Not IsBlankString(PartnerSPhoneNumberIndividual)));
	TheStructureOfTheSearch.Insert("LASTFIRSTNAME",                     (ThisIsACompany = 1) Or (ThisIsACompany = 0 And SpecifyTheContactPersonSDetails And Not IsBlankString(LastNameKL)));
	TheStructureOfTheSearch.Insert("DocumentCounterparty_",     (ThisIsACompany = 1) And SpecifyLegalDetails And SpecifyTheIdentityDocument);
	TheStructureOfTheSearch.Insert("RegistrationNumber",    (OnlyPartnersAreUsed Or SpecifyLegalDetails) And TypeOfCompany = 1 And Not IsBlankString(RegistrationNumber));
	TheStructureOfTheSearch.Insert("TaxNumber",          (OnlyPartnersAreUsed Or SpecifyLegalDetails) And TypeOfCompany = 1 And Not IsBlankString(TaxNumber));
	TheStructureOfTheSearch.Insert("TIN", (SpecifyLegalDetails And ThisIsACompany = 0 And Not IsBlankString(TIN)) 
		Or (ThisIsACompany = 1 And Not IsBlankString(INNPartnerIndividual)));
	PartnersAndCounterpartiesLocalization.AddSearchStructure(ThisObject, TheStructureOfTheSearch);
	
	ArrayOfPhonePresentations = ArrayOfPhonePresentations_();
	
	Query = New Query;
	
	QueryText = SubqueryByName();
	
	If TheStructureOfTheSearch.EMAddress Then
		QueryText = QueryText + SubqueryByEmailAddress();
	EndIf;
	
	If TheStructureOfTheSearch.PhoneNumber Then
		QueryText = QueryText + SubqueryByPhoneNumber(ArrayOfPhonePresentations);
	EndIf;
	
	If TheStructureOfTheSearch.LASTFIRSTNAME Then
		QueryText = QueryText + FullNameSubquery(Query);
	EndIf;
	
	If TheStructureOfTheSearch.NameOfTheCounterparty Then
		QueryText = QueryText + SubqueryByCounterpartyName();
	EndIf;

	If TheStructureOfTheSearch.DocumentCounterparty_ Then
		QueryText = QueryText + SubqueryForIdentityDocument()
	EndIf;
	
	If TheStructureOfTheSearch.RegistrationNumber Then
		QueryText = QueryText + SubqueryByRegistrationNumberInCountryOfRegistration();
	EndIf;
	
	If TheStructureOfTheSearch.TaxNumber Then
		QueryText = QueryText + SubqueryByTaxNumberInCountryOfRegistration();
	EndIf;
	
	If TheStructureOfTheSearch.TIN Then
		AddRequestForTIN(QueryText, BasedOnTheCounterparty);
	EndIf;
	
	PartnersAndCounterpartiesLocalization.AddSearchQueryText(QueryText, TheStructureOfTheSearch, BasedOnTheCounterparty);
	
	QueryText = QueryText + SummaryQuery(TheStructureOfTheSearch);
	
	NameSearch = PartnerName();
	If ThisIsACompany = 0 Then
		NameSearch = "%" + NameSearch + "%";
	EndIf;
	
	Query.SetParameter("Name1", NameSearch);
	Query.SetParameter("ItemInstanceAddresses", ArrayOfEmailAddressesToSearch());
	Query.SetParameter("ArrayOfPhoneNumbers", ArrayOfPhoneNumbersToSearch());
	Query.SetParameter("NameOfTheCounterparty","%"+FullLegalName+"%");
	Query.SetParameter("DocumentKind", DocumentKind);
	Query.SetParameter("Series", SeriesFromDocument);
	Query.SetParameter("Number", DocumentNumber);
	Query.SetParameter("CurrentDate", CurrentSessionDate());
	Query.SetParameter("OnlyPartnersAreUsed", OnlyPartnersAreUsed);
	Query.SetParameter("LineSeparateDivision", NStr("vi = 'Bộ phận độc lập';
													|ru = 'Обособленное подразделение';
													|en = 'Branch office'; fa = 'شعبه';
													|it = 'Reparto esterno';
													|pl = 'Odrębny dział';
													|tr = 'Ayrı departman'"));
	Query.SetParameter("RegistrationNumber", RegistrationNumber);
	Query.SetParameter("TaxNumber", TaxNumber);
	Query.SetParameter("TIN", ?(ThisIsACompany = 0, TIN, INNPartnerIndividual));
	PartnersAndCounterpartiesLocalization.SetSearchQueryParameters(ThisObject, Query);
	
	DetailsPresentations = New Structure;
	DetailsPresentations.Insert("StringName", NStr("vi = 'Tên gọi làm việc';
													|ru = 'Рабочее наименование';
													|en = 'Working title'; fa = 'عنوان کاری';
													|it = 'Nome operativo';
													|pl = 'Nazwa robocza';
													|tr = 'İş ünvanı'"));
	DetailsPresentations.Insert("StringFullName",
		?(OnlyPartnersAreUsed, NStr("vi = 'Tên viết tắt pháp nhân';
									|ru = 'Сокращенное юр. наименование';
									|en = 'Abbreviated legal name'; fa = 'نام حقوقی اختصاری';
									|it = 'Nome giuridico abbreviato';
									|pl = 'Skrócona nazwa prawna';
									|tr = 'Kısaltılmış yasal adı'"), NStr("vi = 'Tên gọi công khai';
																			|ru = 'Публичное наименование';
																			|en = 'Public name'; fa = 'نام عمومی';
																			|it = 'Nome pubblico';
																			|pl = 'Nazwa publiczna';
																			|tr = 'Kamu adı'")));
	DetailsPresentations.Insert("PhoneLine", NStr("vi = 'Điện thoại';
													|ru = 'Телефон';
													|en = 'Phone'; fa = 'تلفن';
													|it = 'Telefono';
													|pl = 'Phone';
													|tr = 'Telefon'"));
	DetailsPresentations.Insert("EmailRow", NStr("vi = 'Email';
												|ru = 'Email';
												|en = 'Email'; fa = 'ایمیل';
												|it = 'Email';
												|pl = 'Email';
												|tr = 'Email'"));
	DetailsPresentations.Insert("StringDocumentData", NStr("vi = 'Chứng từ của đối tác';
															|ru = 'Документ контрагента';
															|en = 'Counterparty document'; fa = 'Counterparty document';
															|it = 'Documento del contraente';
															|pl = 'Dokument kontrahenta';
															|tr = 'Cari hesap belgesi'"));
	DetailsPresentations.Insert("PartnerTypeString", NStr("vi = 'Dạng bạn hàng';
															|ru = 'Вид партнера';
															|en = 'Partner kind'; fa = 'Partner kind';
															|it = 'Tipo del partner';
															|pl = 'Rodzaj partnera';
															|tr = 'İş ortağı türü'"));
	DetailsPresentations.Insert("CounterpartyTypeLine", NStr("vi = 'Dạng đối tác';
															|ru = 'Вид контрагента';
															|en = 'Counterparty type'; fa = 'نوع طرف حساب';
															|it = 'Tipo del contraente';
															|pl = 'Rodzaj kontrahenta';
															|tr = 'Cari hesap türü'"));
	DetailsPresentations.Insert("LineRegistrationNumber", NStr("vi = 'Số đăng ký';
																|ru = 'Регистрационный номер';
																|en = 'Registration number'; fa = 'شماره ثبت';
																|it = 'Numero di registrazione';
																|pl = 'Numer rejestracyjny';
																|tr = 'Kayıt numarası'"));
	DetailsPresentations.Insert("LineTaxNumber", NStr("vi = 'Mã số thuế';
														|ru = 'Налоговый номер';
														|en = 'Tax number'; fa = 'شماره مالیاتی';
														|it = 'Codice fiscale';
														|pl = 'Numer podatkowy';
														|tr = 'Vergi numarası'"));
	DetailsPresentations.Insert("TINLine", NStr("vi = 'MST';
												|ru = 'ИНН';
												|en = 'TIN'; fa = 'شناسه مالیاتی';
												|it = 'ИНН';
												|pl = 'TIN';
												|tr = 'VKN'"));
	PartnersAndCounterpartiesLocalization.AddPresentationsOfSearchDetails(DetailsPresentations);
	For Each StructureItem In DetailsPresentations Do
		Query.SetParameter(StructureItem.Key, StructureItem.Value);
	EndDo;
	
	DetailsOfInformationWithoutSearch = New ValueList;
	
	TempTablesManager = New TempTablesManager;
	PlaceTemporaryTablesOfDataDetails(TempTablesManager, DetailsPresentations, TheStructureOfTheSearch, DetailsOfInformationWithoutSearch);
	
	Query.TempTablesManager = TempTablesManager;
	Query.Text = QueryText;
	
	For Indus = 0 To ArrayOfPhonePresentations.Count()-1 Do
		Query.SetParameter("PhonePresentation" + String(Indus), "%"+ArrayOfPhonePresentations[Indus]+"%");
	EndDo;
	
	QueryResult = Query.ExecuteBatch();
	TempTablesManager.Close();
	
	FillInResultsFound(QueryResult, DetailsPresentations, DetailsOfInformationWithoutSearch);
	
	PartnersAndCounterpartiesLocalization.SearchForPrimaryInformationCompletion(ThisObject, DetailsPresentations);
EndProcedure

&AtServer
Procedure PlaceTemporaryTablesOfDataDetails(TempTablesManager, DetailsPresentations, TheStructureOfTheSearch, DetailsOfInformationWithoutSearch)
	
	PartnerDetails_ = New ValueTable;
	PartnerDetails_.Columns.Add("Attribute",     New TypeDescription("String",, New StringQualifiers(100)));
	PartnerDetails_.Columns.Add("Value",     New TypeDescription("String",, New StringQualifiers(300)));
	PartnerDetails_.Columns.Add("Order",      New TypeDescription("Number"));
	PartnerDetails_.Columns.Add("Essential", New TypeDescription("Boolean"));
	
	CounterpartyDetails_ = PartnerDetails_.Copy();
	ContactPersonDetails_ = PartnerDetails_.Copy();
	
	// Partner's details
	
	If Not OnlyPartnersAreUsed Then
		DetailsOfInformationWithoutSearch.Add(DetailsPresentations.PartnerTypeString);
		AddRowToDataDetailsTable(PartnerDetails_, DetailsPresentations.PartnerTypeString,
			String(PartnerSLegalEntityType(ThisIsACompany)), 1, True);
	EndIf;
	
	NameSearch = PartnerName();
	
	AddRowToDataDetailsTable(PartnerDetails_, DetailsPresentations.StringFullName,
		NameSearch, 2);
	AddRowToDataDetailsTable(PartnerDetails_, DetailsPresentations.StringName,
		NameSearch, 3);
	
	If TheStructureOfTheSearch.EMAddress Then
		AddRowToDataDetailsTable(PartnerDetails_, DetailsPresentations.EmailRow,
			?(ThisIsACompany = 0, EppartnerSAddress, EppartnerSAddressIndividual), 4);
	EndIf;
	
	If TheStructureOfTheSearch.PhoneNumber Then
		AddRowToDataDetailsTable(PartnerDetails_, DetailsPresentations.PhoneLine,
			?(ThisIsACompany = 0, PartnerSPhoneNumber, PartnerSPhoneNumberIndividual), 5);
	EndIf;
	
	// Counterparty's Bank details
	
	DetailsOfInformationWithoutSearch.Add(DetailsPresentations.CounterpartyTypeLine);
	AddRowToDataDetailsTable(CounterpartyDetails_, DetailsPresentations.CounterpartyTypeLine,
		?(OnlyPartnersAreUsed Or SpecifyLegalDetails, PartnersAndCounterpartiesLocalizationClientServer.CounterpartySLegalEntityType(ThisIsACompany, TypeOfCompany), ""), 1, True);
	
	If Not OnlyPartnersAreUsed Then
		AddRowToDataDetailsTable(CounterpartyDetails_, DetailsPresentations.StringFullName,
			?(TheStructureOfTheSearch.NameOfTheCounterparty, FullLegalName, ""), 2);
		AddRowToDataDetailsTable(CounterpartyDetails_, DetailsPresentations.StringName,
			?(TheStructureOfTheSearch.NameOfTheCounterparty, FullLegalName, ""), 3);
	EndIf;
	
	If TheStructureOfTheSearch.DocumentCounterparty_ Then
		AddRowToDataDetailsTable(CounterpartyDetails_, DetailsPresentations.StringDocumentData,
			PresentationOfDocumentOfIndividual(), 7);
	EndIf;
	
	If TheStructureOfTheSearch.RegistrationNumber Then
		AddRowToDataDetailsTable(CounterpartyDetails_, DetailsPresentations.LineRegistrationNumber,
			RegistrationNumber, 8);
	EndIf;
		
	If TheStructureOfTheSearch.TaxNumber Then
		AddRowToDataDetailsTable(CounterpartyDetails_, DetailsPresentations.LineTaxNumber,
			TaxNumber, 8);
	EndIf;
		
	// Details of the contact person
	
	If TheStructureOfTheSearch.LASTFIRSTNAME Then
		If ThisIsACompany = 0 Then
			CurrentFN = FIO_OneLine(LastNameKL, KLName, PatronymicKL);
		Else
			CurrentFN = FIO_OneLine(PartnerSLastName, PartnerName_3, PartnerSMiddleName);
		EndIf;
		AddRowToDataDetailsTable(ContactPersonDetails_, DetailsPresentations.StringName, CurrentFN, 1);
	EndIf;
	
	If TheStructureOfTheSearch.EMAddress Then
		AddRowToDataDetailsTable(ContactPersonDetails_, DetailsPresentations.EmailRow,
			?(ThisIsACompany = 0 And SpecifyTheContactPersonSDetails, EPCLAddress, ""), 2);
	EndIf;
	
	If TheStructureOfTheSearch.PhoneNumber Then
		AddRowToDataDetailsTable(ContactPersonDetails_, DetailsPresentations.PhoneLine,
			?(ThisIsACompany = 0 And SpecifyTheContactPersonSDetails, ?(IsBlankString(PhoneNumberKL), MobilePhoneKL, PhoneNumberKL), ""), 2);
	EndIf;
	PartnersAndCounterpartiesLocalization.PlaceTemporaryTablesOfCounterpartyDetails(DetailsPresentations, TheStructureOfTheSearch, DetailsOfInformationWithoutSearch, CounterpartyDetails_, ThisObject); 

	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	
	Query.Text = "
	|SELECT
	|	PartnerDetails_.Attribute,
	|	PartnerDetails_.Value,
	|	PartnerDetails_.Order,
	|	PartnerDetails_.Essential
	|INTO PartnerDetails_
	|FROM
	|	&PartnerDetails_ AS PartnerDetails_
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CounterpartyDetails_.Attribute,
	|	CounterpartyDetails_.Value,
	|	CounterpartyDetails_.Order,
	|	CounterpartyDetails_.Essential
	|INTO CounterpartyDetails_
	|FROM
	|	&CounterpartyDetails_ AS CounterpartyDetails_
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ContactPersonDetails_.Attribute,
	|	ContactPersonDetails_.Value,
	|	ContactPersonDetails_.Order,
	|	ContactPersonDetails_.Essential
	|INTO ContactPersonDetails_
	|FROM
	|	&ContactPersonDetails_ AS ContactPersonDetails_";
	
	Query.SetParameter("PartnerDetails_",        PartnerDetails_);
	Query.SetParameter("CounterpartyDetails_",     CounterpartyDetails_);
	Query.SetParameter("ContactPersonDetails_", ContactPersonDetails_);
	
	Query.Execute();
	
EndProcedure

&AtServerNoContext
Procedure AddRowToDataDetailsTable(AttributesTable, Attribute, Value, Order, Essential = False)
	
	PropsString = AttributesTable.Add();
	PropsString.Attribute = Attribute;
	PropsString.Value = Value;
	PropsString.Order  = Order;
	PropsString.Essential = Essential;
	
EndProcedure

&AtServer
Function ArrayOfEmailAddressesToSearch()

	DSAddressesArray = New Array;
	If ThisIsACompany = 0 And Not IsBlankString(EppartnerSAddress) Then
		DSAddressesArray.Add(EppartnerSAddress);
	EndIf;
	If ThisIsACompany = 0 And SpecifyTheContactPersonSDetails And Not IsBlankString(EPCLAddress) Then
		DSAddressesArray.Add(EPCLAddress);
	EndIf;
	If ThisIsACompany = 1 And Not IsBlankString(EppartnerSAddressIndividual) Then
		DSAddressesArray.Add(EppartnerSAddressIndividual);
	EndIf;
	
	Return DSAddressesArray;

EndFunction

&AtServer
Function ArrayOfPhonePresentations_()
	
	ArrayOfPhonePresentations_ = New Array;
	
	If ThisIsACompany = 0 Then
		If Not IsBlankString(PartnerSPhoneNumber) Then
			ArrayOfPhonePresentations_.Add(PartnerSPhoneNumber);
		EndIf;
		If SpecifyTheContactPersonSDetails Then
			If Not IsBlankString(PhoneNumberKL) Then
				ArrayOfPhonePresentations_.Add(PhoneNumberKL);
			EndIf;
			If Not IsBlankString(MobilePhoneKL) Then
				ArrayOfPhonePresentations_.Add(MobilePhoneKL);
			EndIf;
		EndIf;
	Else
		If Not IsBlankString(PartnerSPhoneNumberIndividual) Then
			ArrayOfPhonePresentations_.Add(PartnerSPhoneNumberIndividual);
		EndIf;
	EndIf;
	
	Return ArrayOfPhonePresentations_;
	
EndFunction

&AtServer
Function ArrayOfPhoneNumbersToSearch()
	
	ArrayOfPhoneNumbers = New Array;
	
	If ThisIsACompany = 0 Then
		If Not IsBlankString(PartnerSPhoneNumber) Then
			AddPhoneNumberToArrayWithoutCodes(ArrayOfPhoneNumbers,
				FieldValuesInListOfValues(PartnerPhoneFieldValues));
		EndIf;
		If SpecifyTheContactPersonSDetails Then
			If Not IsBlankString(PhoneNumberKL) Then
				AddPhoneNumberToArrayWithoutCodes(ArrayOfPhoneNumbers,
					FieldValuesInListOfValues(PhoneNumberOfFieldValues));
			EndIf;
			If Not IsBlankString(MobilePhoneKL) Then
				AddPhoneNumberToArrayWithoutCodes(ArrayOfPhoneNumbers,
					FieldValuesInListOfValues(MobilePhoneNumberFieldValues));
			EndIf;
		EndIf;
	Else
		If Not IsBlankString(PartnerSPhoneNumberIndividual) Then
			AddPhoneNumberToArrayWithoutCodes(ArrayOfPhoneNumbers,
				FieldValuesInListOfValues(PartnerSPhoneNumberIndividualFieldValues));
		EndIf;
	EndIf;
	
	Return ArrayOfPhoneNumbers;
	
EndFunction

&AtServer
Procedure AddPhoneNumberToArrayWithoutCodes(NumbersArray, ListOfFieldValues)
	
	For Each ListItem In ListOfFieldValues Do
		If ListItem.Presentation = "PhoneNumber" And Not IsBlankString(ListItem.Value) Then
			NumbersArray.Add(RemoveSeparatorsFromPhoneNumber(ListItem.Value));
			Break;
		EndIf;
	EndDo;
	
EndProcedure

&AtServerNoContext
Function RemoveSeparatorsFromPhoneNumber(Val PhoneNumber)
	
	Pos = StrFind(PhoneNumber, ",");
	If Pos <> 0 Then
		PhoneNumber = Left(PhoneNumber, Pos-1);
	EndIf;
	
	PhoneNumber = StrReplace(PhoneNumber, "-", "");
	PhoneNumber = StrReplace(PhoneNumber, " ", "");
	PhoneNumber = StrReplace(PhoneNumber, "+", "");
	
	Return PhoneNumber;
	
EndFunction

&AtServer
Procedure AddFullNameToArray(ArrayOfFullNames, LastName, Name, MiddleName)
	
	StringToAdd =  FIO_OneLine(LastName, Name, MiddleName);
	If ArrayOfFullNames.Find(StringToAdd) = Undefined Then
		ArrayOfFullNames.Add(StringToAdd);
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInResultsFound(QueryResult, DetailsPresentations, DetailsOfInformationWithoutSearch)
	
	TableFound.Clear();
	DataTreeElements = DataTreeOfFoundPartners.GetItems();
	DataTreeElements.Clear();
	
	NumberOfPackages_ = QueryResult.Count();
	
	TablePartners        = QueryResult[NumberOfPackages_ -2].Unload();
	SamplePartnerData = QueryResult[NumberOfPackages_ -1].Select(QueryResultIteration.ByGroups);
	
	If TablePartners.Count() = 0 Then
		ActionBasedOnResultsFound = 2;
		ActionWithTheCounterparty = ?(SpecifyLegalDetails, 1, 0);
		Return;
	EndIf;
	
	While SamplePartnerData.Next() Do
		
		If Not ValueIsFilled(SamplePartnerData.Partner) Then
			Continue;
		EndIf;
		
		PartnerNode = DataTreeElements.Add();
		PartnerNode.Attribute = NStr("vi = 'Bạn hàng';
									|ru = 'Партнер';
									|en = 'Partner'; fa = 'شریک تجاری';
									|it = 'Partner';
									|pl = 'Partner';
									|tr = 'İş ortağı'");
		PartnerNode.FoundByReference = SamplePartnerData.Partner;
		
		PartnersTableRow = TablePartners.Find(SamplePartnerData.Partner, "Partner");
		
		TableRowFound = TableFound.Add();
		FillPropertyValues(TableRowFound, PartnersTableRow);
		If TableRowFound.NumberOfSimilarPartnersFound > 1 Then
			TableRowFound.PartnerView = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = '%1 (Trùng lặp - %2)';
					|ru = '%1 (Совпадений - %2)';
					|en = '%1 (Matches - %2)'; fa = '%1 (Matches - %2)';
					|it = '%1 (Coincidenze - %2)';
					|pl = '%1 (Pokrywa się - %2)';
					|tr = '%1 (Eşleşme - %2)'"),
				String(PartnersTableRow.Partner),
				PartnersTableRow.NumberOfSimilarPartnersFound);
		Else
			TableRowFound.PartnerView = PartnersTableRow.Presentation;
		EndIf;
		
		TableRowFound.IDOfTheDataTree = PartnerNode.GetID();
		
		ElementsOfPartnerNode = PartnerNode.GetItems();
		
		InformationNode = Undefined;
		SkipCounterpartyNode = False;
		
		FetchingSubordinateLink = SamplePartnerData.Select(QueryResultIteration.ByGroups);
		While FetchingSubordinateLink.Next() Do
			
			InformationType = TypeOf(FetchingSubordinateLink.FoundByReference);
			
			If OnlyPartnersAreUsed And InformationType = Type("CatalogRef.Counterparties") Then
				If SkipCounterpartyNode Then
					Continue;
				EndIf;
				SkipCounterpartyNode = True;
			Else
				
				InformationNode = ElementsOfPartnerNode.Add();
				InformationNode.FoundByReference = FetchingSubordinateLink.FoundByReference;
				
				If InformationType = Type("CatalogRef.ContactPersonsForPartners") Then
					InformationNode.Attribute = NStr("vi = 'Thông tin về người liên hệ';
													|ru = 'Информация о контактном лице';
													|en = 'Information about contact person'; fa = 'Information about contact person';
													|it = 'Informazioni sulla persona di contatto';
													|pl = 'Informacja o osobie do kontaktu';
													|tr = 'İlgili kişi bilgileri'");
				ElsIf InformationType = Type("CatalogRef.Counterparties") Or OnlyPartnersAreUsed Then
					InformationNode.Attribute = NStr("vi = 'Thông tin về đối tác';
													|ru = 'Информация о контрагенте';
													|en = 'Counterparty information'; fa = 'Counterparty information';
													|it = 'Informazioni sul contraente';
													|pl = 'Informacje dotyczące kontrahenta';
													|tr = 'Cari hesap bilgileri'");
				Else
					InformationNode.Attribute = NStr("vi = 'Thông tin về bạn hàng';
													|ru = 'Информация о партнере';
													|en = 'Information on partner'; fa = 'اطلاعات شریک';
													|it = 'Informazioni sul partner';
													|pl = 'informacja o partnerze';
													|tr = 'İş ortağı bilgileri'");
				EndIf
				
			EndIf;
			
			InformationNodeElements = InformationNode.GetItems();
			
			FetchingSubordinateData = FetchingSubordinateLink.Select();
			While FetchingSubordinateData.Next() Do
				
				DataNode = InformationNodeElements.Add();
				FillPropertyValues(DataNode, FetchingSubordinateData);
				
				If FetchingSubordinateData.Coincidence Then
					DataNode.Coincidence = True;
				ElsIf DetailsOfInformationWithoutSearch.FindByValue(FetchingSubordinateData.Attribute) <> Undefined Then
					
					If FetchingSubordinateData.ValueOfFound <> FetchingSubordinateData.ValueOfGenerated
						 And ValueIsFilled(FetchingSubordinateData.ValueOfGenerated) Then
						DataNode.Difference = FetchingSubordinateData.Essential;
						TableRowFound.Difference = Max(TableRowFound.Difference, DataNode.Difference);
					EndIf;
					Continue;
					
				EndIf;
				DataNode.Difference = Not DataNode.Coincidence And FetchingSubordinateData.Essential;
				TableRowFound.Difference = Max(TableRowFound.Difference, DataNode.Difference);
				
			EndDo;
			
		EndDo;
		
	EndDo;
	
	TableFound.Sort("NumberOfSimilarPartnersFound DESC, PartnerView");
	
EndProcedure

#EndRegion

#Region WorkingWithContactInformation

&AtClient
Procedure OpenContactInformationSelectionForm(ContactInformationKind, AttributeNamePresentation, FieldValuePropsName, Var_Title = "")
	
	OpeningParameters = ContactsManagerClient.ContactInformationFormParameters(
	             ContactInformationKind, 
	             JSONContactInformationValue(FieldValuePropsName), 
	             ThisObject[AttributeNamePresentation]);
	
	OpeningParameters.Insert("ContactInformationKind", ContactInformationKind);
	OpeningParameters.Insert("FieldValues",           ThisObject[FieldValuePropsName]);
	OpeningParameters.Insert("Presentation",           ThisObject[AttributeNamePresentation]);
	OpeningParameters.Insert("Country",                  RegistrationCountry);
	
	If Not IsBlankString(Var_Title) Then
		OpeningParameters.Insert("Title", Var_Title);
	EndIf;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("AttributeNamePresentation", AttributeNamePresentation);
	AdditionalParameters.Insert("FieldValuePropsName", FieldValuePropsName);
	NotificationOfEndOfKiEditing = New CallbackDescription("EditingContactInformationCompletion", ThisObject, AdditionalParameters);
	ContactsManagerClient.OpenContactInformationForm(OpeningParameters, ThisObject, NotificationOfEndOfKiEditing);
	
EndProcedure

&AtClient
Procedure EditingContactInformationCompletion(Result, AdditionalParameters) Export

	If TypeOf(Result) = Type("Structure") Then
		
		ThisObject[AdditionalParameters.FieldValuePropsName] = Result.ContactInformation;
		ThisObject[AdditionalParameters.AttributeNamePresentation] = Result.Presentation;
		SaveContactInformationValueInTable(Result.Value, AdditionalParameters.FieldValuePropsName);
		
		If StrCompare(AdditionalParameters.AttributeNamePresentation, "ActualAddress") = 0 Then
			
			SetVisibilityOfDeliveryZone();
			
		EndIf;
		
		ClearMarkIncomplete();
		
	EndIf;

EndProcedure

&AtClient
Function PhoneNumberSpecifiedCorrectly(ListOfFieldValues)
	
	PhoneNumber = "";
	CityCode = "";
	CountryCode = "";
	
	For Each ListItem In ListOfFieldValues Do
		If ListItem.Presentation = "PhoneNumber" Then
			PhoneNumber = ListItem.Value;
		EndIf;
		If ListItem.Presentation = "CityCode" Then
			CityCode = ListItem.Value;
		EndIf;
		If ListItem.Presentation = "CountryCode" Then
			CountryCode = ListItem.Value;
		EndIf;
	EndDo;
	
	If Not IsBlankString(CountryCode) Then
		CountryCode = TrimAll(CountryCode);
		If Left(CountryCode,1)= "+" Then
			CountryCode = Right(CountryCode, StrLen(CountryCode)-1);
		EndIf;
		If Not StringFunctionsClientServer.OnlyNumbersInString(CountryCode) Then
			Return False;
		EndIf;
	EndIf;
	
	If Not IsBlankString(CityCode) Then
		If Not StringFunctionsClientServer.OnlyNumbersInString(CityCode) Then
			Return False;
		EndIf;
	EndIf;
	
	If Not IsBlankString(PhoneNumber) Then
		If Not StringFunctionsClientServer.OnlyNumbersInString(PhoneNumber) Then
			Return False;
		EndIf;
	EndIf;
	
	Return True;
	
EndFunction

&AtServer
&AtServer
Procedure ProcessElementsForEditingContactInformation()

	ArrayOfKiTypes = New Array;
	ArrayOfKiTypes.Add(Catalogs.ContactInformationKinds.ContactPersonSMobilePhoneNumber);
	ArrayOfKiTypes.Add(Catalogs.ContactInformationKinds.ContactPersonSPhoneNumber);
	ArrayOfKiTypes.Add(Catalogs.ContactInformationKinds.PartnerSPhoneNumber);
	ArrayOfKiTypes.Add(Catalogs.ContactInformationKinds.ActualDataCounterpartyAddress);
	ArrayOfKiTypes.Add(Catalogs.ContactInformationKinds.LegalAddressOfCounterparty);
	
	For Each CIKind In ArrayOfKiTypes Do
		
		KindParameters = ContactsManager.ContactInformationKindParameters(CIKind);
		
		If CIKind = Catalogs.ContactInformationKinds.ContactPersonSMobilePhoneNumber Then
			
			If KindParameters.EditingOption = "Dialog" Then
				Items.MobilePhoneKL.TextEdit          = False;
				Items.MobilePhoneKL.BackColor                      = WebColors.Cream;
			EndIf;
			
			If KindParameters.ValidationSettings.EnterNumberByMask Then
				Items.MobilePhoneKL.Mask = KindParameters.ValidationSettings.PhoneNumberMask;
			EndIf;
			
		ElsIf CIKind = Catalogs.ContactInformationKinds.ContactPersonSPhoneNumber Then
			
			If KindParameters.EditingOption = "Dialog" Then
				Items.PhoneNumberKL.TextEdit                   = False;
				Items.PhoneNumberKL.BackColor                               = WebColors.Cream;
			EndIf;
			
			If KindParameters.ValidationSettings.EnterNumberByMask Then
				Items.PhoneNumberKL.Mask = KindParameters.ValidationSettings.PhoneNumberMask;
			EndIf;
			
		ElsIf CIKind = Catalogs.ContactInformationKinds.PartnerSPhoneNumber Then
			
			If KindParameters.EditingOption = "Dialog" Then
				Items.PartnerSPhoneNumber.TextEdit             = False;
				Items.PartnerSPhoneNumber.BackColor                         = WebColors.Cream;
				Items.PartnerSPhoneNumberIndividual.TextEdit      = False;
				Items.PartnerSPhoneNumberIndividual.BackColor                  = WebColors.Cream;
			EndIf;
			
			If KindParameters.ValidationSettings.EnterNumberByMask Then
				
				Items.PartnerSPhoneNumber.Mask        = KindParameters.ValidationSettings.PhoneNumberMask;
				Items.PartnerSPhoneNumberIndividual.Mask = KindParameters.ValidationSettings.PhoneNumberMask;
				
			EndIf;
			
		ElsIf CIKind = Catalogs.ContactInformationKinds.ActualDataCounterpartyAddress Then
			
			If KindParameters.EditingOption = "Dialog" Then
				Items.ActualAddress.TextEdit            = False;
				Items.ActualAddress.BackColor                        = WebColors.Cream;
				Items.TheActualAddressOfAPrivatePerson.TextEdit = False;
				Items.TheActualAddressOfAPrivatePerson.BackColor             = WebColors.Cream;
			EndIf;
			
		ElsIf CIKind = Catalogs.ContactInformationKinds.LegalAddressOfCounterparty Then
			
			If KindParameters.EditingOption = "Dialog" Then
				Items.LegalAddress.TextEdit            = False;
				Items.LegalAddress.BackColor                        = WebColors.Cream;
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure ProcessingEventOfKIPhoneElement(Item, ContactInformationKind, AttributeNamePresentation, FieldValuePropsName, Event)
	
	If Event = "StartChoice" Then
		If ThisObject[AttributeNamePresentation] <> Item.EditText Then
			ThisObject[AttributeNamePresentation] = Item.EditText;
			ValuesOfContactInformationFieldsServer(ThisObject[AttributeNamePresentation],
			                                        ThisObject[FieldValuePropsName],
			                                        PredefinedValue("Enum.ContactInformationTypes.Phone"));
		EndIf;
		
	ElsIf Event = "Clearing" Then
		
		ThisObject[AttributeNamePresentation] = "";
		ThisObject[FieldValuePropsName] = "";
		DeleteContactInformationValue(FieldValuePropsName);
		
	EndIf;
	
	If Event = "StartChoice" Then
		OpenContactInformationSelectionForm(ContactInformationKind,
		                                       AttributeNamePresentation,
		                                       FieldValuePropsName);
	ElsIf Event = "OnChange" Then
		
		ValuesOfContactInformationFieldsServer(ThisObject[AttributeNamePresentation],
		                                        ThisObject[FieldValuePropsName],
		                                        PredefinedValue("Enum.ContactInformationTypes.Phone"));
		
		DeleteContactInformationValue(FieldValuePropsName);
		
		If Not PhoneNumberSpecifiedCorrectly(FieldValuesInListOfValues(ThisObject[FieldValuePropsName])) Then
			OpenContactInformationSelectionForm(ContactInformationKind,
			                                       AttributeNamePresentation,
			                                       FieldValuePropsName,
			                                       NStr("vi = 'Hãy chỉ ra số điện thoại';
														|ru = 'Уточните номер телефона.';
														|en = 'Specify a telephone number.'; fa = 'Specify a telephone number.';
														|it = 'Specificate il numero di telefono.';
														|pl = 'Uściślij numer telefonu.';
														|tr = 'Telefon numarasını açık olarak belirtin.'"));
		Else
			ClearMarkIncomplete();
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessingEventOfKiAddressElement(Item, ContactInformationKind, AttributeNamePresentation, FieldValuePropsName, Event)
	
	If Event = "Clearing" Then
		ThisObject[AttributeNamePresentation] = "";
		ThisObject[FieldValuePropsName] = "";
		DeleteContactInformationValue(FieldValuePropsName);
	EndIf;
	
	If Event = "StartChoice" Then
		OpenContactInformationSelectionForm(ContactInformationKind,
		                                       AttributeNamePresentation,
		                                       FieldValuePropsName);
	ElsIf Event = "OnChange" Then
		
		ValuesOfContactInformationFieldsServer(ThisObject[AttributeNamePresentation],
		                                        ThisObject[FieldValuePropsName],
		                                        ContactInformationKind);
		
		DeleteContactInformationValue(FieldValuePropsName);
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure ValuesOfContactInformationFieldsServer(Val Presentation, FieldValues, Val ContactInformationKind)
	PartnersAndCounterparties.ValuesOfContactInformationFields(Presentation, FieldValues, ContactInformationKind);
EndProcedure

&AtClient
Function JSONContactInformationValue(FieldValuePropsName)
	
	SearchParameters = New Structure;
	
	SearchParameters.Insert("PropsNameFieldValues", FieldValuePropsName);
	
	FoundRows = JSONContactInformationFieldValues.FindRows(SearchParameters);
	If FoundRows.Count() = 1 Then
		Return FoundRows[0].JSONValue;
	Else
		Return ThisObject[FieldValuePropsName];
	EndIf;
	
EndFunction

&AtServer
Function JSONContactInformationValueServer(FieldValuePropsName)
	
	SearchParameters = New Structure;
	
	SearchParameters.Insert("PropsNameFieldValues", FieldValuePropsName);
	
	FoundRows = JSONContactInformationFieldValues.FindRows(SearchParameters);
	If FoundRows.Count() = 1 Then
		Return FoundRows[0].JSONValue;
	Else
		Return ContactsManager.ContactInformationInJSON(ThisObject[FieldValuePropsName]);
	EndIf;
	
EndFunction

&AtClient
Procedure SaveContactInformationValueInTable(JSONValue, FieldValuePropsName)

	SearchParameters = New Structure;
	
	SearchParameters.Insert("PropsNameFieldValues", FieldValuePropsName);
	
	FoundRows = JSONContactInformationFieldValues.FindRows(SearchParameters);
	If FoundRows.Count() = 0 Then
		FoundRow = JSONContactInformationFieldValues.Add();
		FoundRow.PropsNameFieldValues = FieldValuePropsName;
	Else
		FoundRow = FoundRows[0];
	EndIf;
	
	FoundRow.JSONValue = JSONValue;
	
EndProcedure

&AtClient
Procedure DeleteContactInformationValue(FieldValuePropsName) 
	
	SearchParameters = New Structure;
	
	SearchParameters.Insert("PropsNameFieldValues", FieldValuePropsName);
	
	FoundRows = JSONContactInformationFieldValues.FindRows(SearchParameters);
	If FoundRows.Count() = 1 Then
		JSONContactInformationFieldValues.Delete(JSONContactInformationFieldValues.IndexOf(FoundRows[0]));
	EndIf;
	
EndProcedure

#EndRegion

#Region WorkingWithBankAccounts

&AtServer
Procedure IssueBankAccountsWhenCreatingOnServer()
	
	InternationalBankAccountDetails = GetFunctionalOption("InternationalBankAccountDetails");
	NationalBankAccountDetails = GetFunctionalOption("NationalBankAccountDetails");
	Items.GroupErrorInAccountNumber.Visible = False;
	Items.GroupErrorInAccountNumberHeadCounterparty.Visible = False;
	BankIndicationMethod = "ManualFillingInOfBankingDetails";
	MethodOfSpecifyingBankForSettlements = "ManualFillingInOfBankingDetails";
	MethodOfSpecifyingBankHeadCounterparty = "ManualFillingInOfBankingDetails";
	MethodOfSpecifyingBankForSettlementsHeadCounterparty = "ManualFillingInOfBankingDetails";
	
EndProcedure

&AtClient
Procedure WhenChangingIBAN(ThisIsMainCounterparty=False)

	Postfix = ?(ThisIsMainCounterparty, "MainCounterparty", "");
	
	InvoiceData = CashClientServer.NewBankAccountData();
	CashClientServer.FillInDetailsOfBankAccount(InvoiceData, ThisObject, Postfix);

	Items["GroupErrorInAccountNumber" + Postfix].Visible = False;

	ThisObject["ForeignBank" + Postfix] = ItSForeignBank(InvoiceData);
	
	If ThisObject["ThisIsAnIBAN" + Postfix] Then
		CheckIBAN(ThisIsMainCounterparty)
	EndIf;
		
	If Not ThisObject["ForeignBank" + Postfix] And Not IsBlankString(ThisObject["AccountNumber" + Postfix]) Then
		
		AccountCurrency = GetCurrencyByAccountNumber(ThisObject["AccountNumber" + Postfix]);
		If ValueIsFilled(AccountCurrency) Then
			ThisObject["CashCurrency" + Postfix] = AccountCurrency;
		EndIf;
		
	EndIf;
	
	CashClientLocalization.CheckAccountNumber(ThisObject, Postfix, InvoiceData);
	
	ItemManagementBankAccount(ThisObject, ThisIsMainCounterparty);
	
	FillInMainBankDetails(ThisObject, ThisIsMainCounterparty);
	
	ClearMarkIncomplete();
	
EndProcedure

&AtClient
Procedure WhenChangingBankIsUsedForCalculations(ThisIsMainCounterparty=False)
	
	Postfix = ?(ThisIsMainCounterparty, "MainCounterparty", "");
	
	If ThisObject["SettlementBankUsed" + Postfix] Then
		Items["BankForPaymentsPage" + Postfix].Title = NStr("vi = 'Nhập thông tin ngân hàng thủ công...';
															|ru = 'Ввести реквизиты банка вручную...';
															|en = 'Enter bank details manually...'; fa = 'ورود دستی جزئیات بانکی...';
															|it = 'Inserire i requisiti bancari manualmente...';
															|pl = 'Wpisz dane banku ręcznie...';
															|tr = 'Banka bilgilerini manuel olarak gir…'");
	Else
		ThisObject["TransferBank" + Postfix] = Undefined;
		ClearBankDetails(ThisObject, True, ThisIsMainCounterparty);
		ThisObject["MethodOfSpecifyingBankForSettlements" + Postfix] = "ManualFillingInOfBankingDetails";
	EndIf;
	
	ItemManagementBankAccount(ThisObject, ThisIsMainCounterparty);
	FillInMainBankDetails(ThisObject, ThisIsMainCounterparty);
	
EndProcedure

&AtServerNoContext
Function GetCurrencyByAccountNumber(AccountNumber)
	
	Return CashServerLocalization.GetCurrencyByAccountNumber(AccountNumber);
	
EndFunction

&AtServerNoContext
Function AutoBankAccountName(AccountNumber, Bank, Currency)
	
	NameString_ = Right(TrimAll(AccountNumber), 4)
		+ ?(ValueIsFilled(Bank), " In " + String(Bank), "")
		+ " (" + String(Currency) + ")";
	
	Return Left(NameString_, 150);
	
EndFunction

&AtClient
Procedure CheckIBAN(ThisIsMainCounterparty)

	Postfix = ?(ThisIsMainCounterparty, "MainCounterparty", "");
	
	If IsBlankString(ThisObject["AccountNumber" + Postfix]) Then
		Return;
	EndIf;

	If CashClientServer.CorrectIBANLength(ThisObject["AccountNumber" + Postfix]) Then
		If CashClientServer.ValidIBANControlKey(ThisObject["AccountNumber" + Postfix]) Then
			If ThisObject["BankIndicationMethod" + Postfix] = "ManualFillingInOfBankingDetails" Then
				SWIFT = ThisObject["BankSWIFTCode" + Postfix];
			ElsIf ValueIsFilled(Bank) Then
				SWIFT = CashServerCall.SWIFT(ThisObject["Bank" + Postfix]);
			EndIf;
			
			If ValueIsFilled(SWIFT) Then
				If CashClientServer.AccountNumberCorrespondsToBank(ThisObject["AccountNumber" + Postfix], SWIFT) Then
					Items["GroupErrorInAccountNumber" + Postfix].Visible = False;
				Else
					Items["ErrorInAccountNumber" + Postfix].Title = NStr("vi = 'IBAN không khớp với ngân hàng';
																		|ru = 'IBAN не соответствует банку';
																		|en = 'IBAN does not match the bank'; fa = 'IBAN does not match the bank';
																		|it = 'L''IBAN non corrisponde alla banca';
																		|pl = 'IBAN nie jest zgodny z bankiem';
																		|tr = 'IBAN bankayla eşleşmiyor'");
					Items["GroupErrorInAccountNumber" + Postfix].Visible = True;
				EndIf;
			EndIf;
		Else
			Items["ErrorInAccountNumber" + Postfix].Title = NStr("vi = 'Số tài khoản không chính xác';
																|ru = 'Номер счета введен некорректно';
																|en = 'Account number is invalid'; fa = 'Account number is invalid';
																|it = 'Numero di conto inserito errato';
																|pl = 'Numer rachunku został wprowadzony niepoprawnie';
																|tr = 'Hesap numarası yanlış girildi'");
			Items["GroupErrorInAccountNumber" + Postfix].Visible = True;
		EndIf
	Else
		Items["ErrorInAccountNumber" + Postfix].Title = NStr("vi = 'Số tài khoản không khớp với định dạng IBAN';
															|ru = 'Номер счета не соответствует формату IBAN';
															|en = 'Account number does not match IBAN format'; fa = 'Account number does not match IBAN format';
															|it = 'Il numero di conto non corrisponde al formato IBAN';
															|pl = 'Numer rachunku nie jest zgodny z formatem IBAN';
															|tr = 'Hesap numarası, IBAN formatı ile uyumlu değildir'");
		Items["GroupErrorInAccountNumber" + Postfix].Visible = True;
	EndIf;
	
EndProcedure

&AtServer
Procedure IdentifyCountryAndBankByIBAN(ThisIsMainCounterparty)
	
	Postfix = ?(ThisIsMainCounterparty, "MainCounterparty", "");
	CountryCode = CashClientServer.CountryCodeIBAN(ThisObject["AccountNumber" + Postfix]);
	Country = CashServer.Country(CountryCode);
	If ValueIsFilled(Country) Then
		ThisObject["CountryOfBank" + Postfix] = Country;
		NationalBankCode = CashServer.NationalBankCode(ThisObject["AccountNumber" + Postfix]);
		FoundBank = CashServer.Bank(Country, NationalBankCode);
		If ValueIsFilled(FoundBank) Then
			ThisObject["Bank" + Postfix] = FoundBank;
			ThisObject["BankIndicationMethod" + Postfix] = "SelectionFromCatalog";
			FillInBankDetailsByBank("Bank", ThisObject["Bank" + Postfix], ThisIsMainCounterparty);
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInBankDetailsByBank(BankType, Bank = "", ThisIsMainCounterparty=False)
	
	Postfix = ?(ThisIsMainCounterparty, "MainCounterparty", "");
	
	If BankType = "Bank" Then
		
		AttributesStructure1 = BankingDetails(ThisIsMainCounterparty);
		
		BankingDetails = CashServer.BankAttributes(Bank, AttributesStructure1);
		
		FillPropertyValues(ThisObject, BankingDetails);
		
		If ThisIsMainCounterparty Then
			BankAccountForSettlementsHeadCounterparty = BankingDetails.CorrespondentAccountOfTheBankHeadContractor;
			BankCountryHeadCounterparty = CashServer.BankCountryByCode(BankingDetails.CountryCode);
		Else
			BankAccountForPayments = BankingDetails.BankCorrAccount;
			CountryOfBank = CashServer.BankCountryByCode(BankingDetails.CountryCode);
		EndIf;
		
	ElsIf BankType = "TransferBank" Then
		
		AttributesStructure1 = BankDetailsForSettlements(ThisIsMainCounterparty);
		BankingDetails = CashServer.BankAttributes(Bank, AttributesStructure1);
		
		FillPropertyValues(ThisObject, BankingDetails);
		
		If ThisIsMainCounterparty Then
			CountryOfBankForSettlementsHeadCounterparty = CashServer.BankCountryByCode(BankingDetails.CountryCode);
		Else
			CountryOfBankForPayments = CashServer.BankCountryByCode(BankingDetails.CountryCode);
		EndIf;
		
		FillInMainBankDetailsForSettlements(ThisObject, ThisIsMainCounterparty);
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function BankingDetails(ThisIsMainCounterparty)
	
	BankingDetails = New Structure;
	
	If ThisIsMainCounterparty Then
		BankingDetails.Insert("BikbankParentCounterparty",                       "BIC");
		BankingDetails.Insert("NameOfTheBankHeadCounterparty",              "Description");
		BankingDetails.Insert("CorrespondentAccountOfTheBankHeadContractor",                  "CorrAccount");
		BankingDetails.Insert("BankCityHeadCounterparty",                     "City");
		BankingDetails.Insert("BankCityInternationalHeadCounterparty",        "CityInternationalFormat");
		BankingDetails.Insert("BankAddressHeadCounterparty",                     "Address");
		BankingDetails.Insert("BankAddressInternationalHeadCounterparty",        "InternationalAddress");
		BankingDetails.Insert("BikbankParentCounterparty",                       "Code");
		BankingDetails.Insert("SwiftBankHeadCounterparty",                     "SWIFTBIC");
		BankingDetails.Insert("BankNameInternationalHeadCounterparty", "InternationalDescription");
	Else
		BankingDetails.Insert("BankBIC",                       "BIC");
		BankingDetails.Insert("BankDescription",              "Description");
		BankingDetails.Insert("BankCorrAccount",                  "CorrAccount");
		BankingDetails.Insert("BankCity",                     "City");
		BankingDetails.Insert("BankCityInt",        "CityInternationalFormat");
		BankingDetails.Insert("BankAddress",                     "Address");
		BankingDetails.Insert("BankAddressInt",        "InternationalAddress");
		BankingDetails.Insert("BankBIC",                       "Code");
		BankingDetails.Insert("BankSWIFTCode" ,                    "SWIFTBIC");
		BankingDetails.Insert("BankNameInt", "InternationalDescription");
	EndIf;
	
	Return BankingDetails;
	
EndFunction

&AtClientAtServerNoContext
Function BankDetailsForSettlements(ThisIsMainCounterparty)
	
	BankingDetails = New Structure;
	
	If ThisIsMainCounterparty Then
		BankingDetails.Insert("BikbankForSettlementsHeadCounterparty",                       "BIC");
		BankingDetails.Insert("NameOfTheBankForSettlementsHeadCounterparty",              "Description");
		BankingDetails.Insert("CorrespondentAccountOfTheBankForCalculationOfHeadContractor",                  "CorrAccount");
		BankingDetails.Insert("CityOfBankForSettlementsHeadCounterparty",                     "City");
		BankingDetails.Insert("BankCityForSettlementsInternationalHeadCounterparty",        "CityInternationalFormat");
		BankingDetails.Insert("BankAddressForSettlementsHeadCounterparty",                     "Address");
		BankingDetails.Insert("BankAddressForSettlementsInternationalHeadCounterparty",        "InternationalAddress");
		BankingDetails.Insert("BikbankForSettlementsHeadCounterparty",                       "Code");
		BankingDetails.Insert("SwiftBankForSettlementsHeadCounterparty",                     "SWIFTBIC");
		BankingDetails.Insert("NameOfBankForSettlementsInternationalHeadCounterparty", "InternationalDescription");
	Else
		BankingDetails.Insert("TransferBankBIC",                       "BIC");
		BankingDetails.Insert("TransferBankDescription",              "Description");
		BankingDetails.Insert("TransferBankCorrAccount",                  "CorrAccount");
		BankingDetails.Insert("TransferBankCity",                     "City");
		BankingDetails.Insert("BankCityForPaymentsInt",        "CityInternationalFormat");
		BankingDetails.Insert("TransferBankAddress",                     "Address");
		BankingDetails.Insert("BankAddressForPaymentInt",        "InternationalAddress");
		BankingDetails.Insert("TransferBankBIC",                       "Code");
		BankingDetails.Insert("BankSWIFTCodeForPayments" ,                    "SWIFTBIC");
		BankingDetails.Insert("BankNameForPaymentsInt", "InternationalDescription");
	EndIf;
	
	Return BankingDetails;
	
EndFunction

&AtClientAtServerNoContext
Procedure FillInMainBankDetails(Form, ThisIsMainCounterparty=False)

	Postfix = ?(ThisIsMainCounterparty, "MainCounterparty", "");
	UnbreakableGap = Char(160);
	Form.Items["BankPage" + Postfix].Title = "";
	
	If Not ValueIsFilled(Form["Bank" + Postfix])
		And Form["BankIndicationMethod" + Postfix] = "SelectionFromCatalog" Then
		Form.Items["BankPage" + Postfix].Title = NStr("vi = 'Nhập thông tin ngân hàng thủ công...';
														|ru = 'Ввести реквизиты банка вручную...';
														|en = 'Enter bank details manually...'; fa = 'ورود دستی جزئیات بانکی...';
														|it = 'Inserire i requisiti bancari manualmente...';
														|pl = 'Wpisz dane banku ręcznie...';
														|tr = 'Banka bilgilerini manuel olarak gir…'");
		Return
	EndIf;
	
	OutputAttributes = New Array;
	HasData = False;
	
	If Form["BankIndicationMethod" + Postfix] = "ManualFillingInOfBankingDetails" Then
		If Form.NationalBankAccountDetails Then
			If ValueIsFilled(Form["BankDescription" + Postfix]) Then
				BankDescription = Form["BankDescription" + Postfix];
				HasData = True;
			Else
				BankDescription = NStr("vi = '<chưa chỉ định>';
										|ru = '<не указано>';
										|en = '<none>'; fa = '<هیچ>';
										|it = '<non indicato>';
										|pl = '<nie określono>';
										|tr = '<belirtilmedi>'");
			EndIf;
		Else
			If ValueIsFilled(Form["BankNameInt" + Postfix]) Then
				BankDescription = Form["BankNameInt" + Postfix];
				HasData = True;
			Else
				BankDescription = NStr("vi = '<chưa chỉ định>';
										|ru = '<не указано>';
										|en = '<none>'; fa = '<هیچ>';
										|it = '<non indicato>';
										|pl = '<nie określono>';
										|tr = '<belirtilmedi>'");
			EndIf;
		EndIf;
		OutputAttributes.Add(StrReplace(BankDescription, "", UnbreakableGap));
	EndIf;
	
	If Form.NationalBankAccountDetails Then
		If ValueIsFilled(Form["BankBIC" + Postfix]) Then
			BankBIC = TrimAll(Form["BankBIC" + Postfix]);
			HasData = True;
		Else
			BankBIC = NStr("vi = '<chưa chỉ định>';
							|ru = '<не указан>';
							|en = '<not specified>'; fa = '<مشخص نشده>';
							|it = '<non specificato>';
							|pl = '<nie określono>';
							|tr = '<belirtilmedi>'");
		EndIf;
		OutputAttributes.Add(
			Form.Items["BankBIC" + Postfix].Title + ":" + UnbreakableGap + BankBIC);
	EndIf;
	
	If Form.InternationalBankAccountDetails Then
		If ValueIsFilled(Form["BankSWIFTCode" + Postfix]) Then
			BankSWIFTCode = Form["BankSWIFTCode" + Postfix];
			HasData = True;
		Else
			BankSWIFTCode = NStr("vi = '<chưa chỉ định>';
								|ru = '<не указан>';
								|en = '<not specified>'; fa = '<مشخص نشده>';
								|it = '<non specificato>';
								|pl = '<nie określono>';
								|tr = '<belirtilmedi>'");
		EndIf;
		OutputAttributes.Add(
			StrReplace(Form.Items["BankSWIFTCode" + Postfix].Title, " ", UnbreakableGap) + ":"
			+ UnbreakableGap + BankSWIFTCode);
	EndIf;
	
	If Form["SettlementBankUsed" + Postfix] Then
		Value = ?(Form.Items["BankCorrAccount" + Postfix].Visible, Form["BankCorrAccount" + Postfix],
			Form["BankAccountForPayments" + Postfix]);
		If ValueIsFilled(Value) Then
			HasData = True;
		Else
			Value = NStr("vi = '<chưa chỉ định>';
						|ru = '<не указан>';
						|en = '<not specified>'; fa = '<مشخص نشده>';
						|it = '<non specificato>';
						|pl = '<nie określono>';
						|tr = '<belirtilmedi>'");
		EndIf;
		OutputAttributes.Add(
			StrReplace(Form.Items["BankCorrAccount" + Postfix].Title, " ", UnbreakableGap) + ":"
			+ UnbreakableGap + Value);
	EndIf;
	
	If Form["BankIndicationMethod" + Postfix] = "ManualFillingInOfBankingDetails" And Not HasData Then
		Form.Items["BankPage" + Postfix].Title = NStr("vi = 'Nhập thông tin ngân hàng thủ công...';
														|ru = 'Ввести реквизиты банка вручную...';
														|en = 'Enter bank details manually...'; fa = 'ورود دستی جزئیات بانکی...';
														|it = 'Inserire i requisiti bancari manualmente...';
														|pl = 'Wpisz dane banku ręcznie...';
														|tr = 'Banka bilgilerini manuel olarak gir…'");
	Else
		Form.Items["BankPage" + Postfix].Title = StrConcat(OutputAttributes, "; ");
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillInMainBankDetailsForSettlements(Form, ThisIsMainCounterparty=False)

	Postfix = ?(ThisIsMainCounterparty, "MainCounterparty", "");

	UnbreakableGap = Char(160);
	Form.Items["BankForPaymentsPage" + Postfix].Title = "";
	
	If Not ValueIsFilled(Form["TransferBank" + Postfix])
		And Form["MethodOfSpecifyingBankForSettlements" + Postfix] = "SelectionFromCatalog" Then
		Form.Items["BankForPaymentsPage" + Postfix].Title = NStr("vi = 'Nhập thông tin ngân hàng thủ công...';
																|ru = 'Ввести реквизиты банка вручную...';
																|en = 'Enter bank details manually...'; fa = 'ورود دستی جزئیات بانکی...';
																|it = 'Inserire i requisiti bancari manualmente...';
																|pl = 'Wpisz dane banku ręcznie...';
																|tr = 'Banka bilgilerini manuel olarak gir…'");
		Return
	EndIf;
	
	OutputAttributes = New Array;
	HasData = False;
	
	If Form["MethodOfSpecifyingBankForSettlements" + Postfix] = "ManualFillingInOfBankingDetails" Then
		
		If Form.NationalBankAccountDetails Then
			If Not IsBlankString(Form["TransferBankDescription" + Postfix]) Then
				TransferBankDescription = TrimAll(Form["TransferBankDescription" + Postfix]);
				HasData = True;
			Else
				TransferBankDescription = NStr("vi = '<chưa chỉ định>';
												|ru = '<не указано>';
												|en = '<none>'; fa = '<هیچ>';
												|it = '<non indicato>';
												|pl = '<nie określono>';
												|tr = '<belirtilmedi>'");
			EndIf;
		Else
			If Not IsBlankString(Form["BankNameForPaymentsInt" + Postfix]) Then
				TransferBankDescription = TrimAll(Form["BankNameForPaymentsInt" + Postfix]);
				HasData = True;
			Else
				TransferBankDescription = NStr("vi = '<chưa chỉ định>';
												|ru = '<не указано>';
												|en = '<none>'; fa = '<هیچ>';
												|it = '<non indicato>';
												|pl = '<nie określono>';
												|tr = '<belirtilmedi>'");
			EndIf;
		EndIf;
		OutputAttributes.Add(StrReplace(TransferBankDescription, "", UnbreakableGap));
	EndIf;
	
	If Form.NationalBankAccountDetails Then
		If Not IsBlankString(Form["TransferBankBIC" + Postfix]) Then
			TransferBankBIC = TrimAll(Form["TransferBankBIC" + Postfix]);
			HasData = True;
		Else
			TransferBankBIC = NStr("vi = '<chưa chỉ định>';
									|ru = '<не указан>';
									|en = '<not specified>'; fa = '<مشخص نشده>';
									|it = '<non specificato>';
									|pl = '<nie określono>';
									|tr = '<belirtilmedi>'");
		EndIf;
		OutputAttributes.Add(Form.Items["TransferBankBIC" + Postfix].Title + ":" + UnbreakableGap
			+ TrimAll(TransferBankBIC));
	EndIf;
	
	If Form.InternationalBankAccountDetails Then
		If Not IsBlankString(Form["BankSWIFTCodeForPayments" + Postfix]) Then
			BankSWIFTCodeForPayments = TrimAll(Form["BankSWIFTCodeForPayments" + Postfix]);
			HasData = True;
		Else
			BankSWIFTCodeForPayments = NStr("vi = '<chưa chỉ định>';
											|ru = '<не указан>';
											|en = '<not specified>'; fa = '<مشخص نشده>';
											|it = '<non specificato>';
											|pl = '<nie określono>';
											|tr = '<belirtilmedi>'");
		EndIf;
		OutputAttributes.Add(
			StrReplace(Form.Items["BankSWIFTCodeForPayments" + Postfix].Title, " ", UnbreakableGap)
			+ ":" + UnbreakableGap + BankSWIFTCodeForPayments);
	EndIf;
	
	If Form["MethodOfSpecifyingBankForSettlements" + Postfix] = "ManualFillingInOfBankingDetails" And Not HasData Then
		Form.Items["BankForPaymentsPage" + Postfix].Title = NStr("vi = 'Nhập thông tin ngân hàng thủ công...';
																|ru = 'Ввести реквизиты банка вручную...';
																|en = 'Enter bank details manually...'; fa = 'ورود دستی جزئیات بانکی...';
																|it = 'Inserire i requisiti bancari manualmente...';
																|pl = 'Wpisz dane banku ręcznie...';
																|tr = 'Banka bilgilerini manuel olarak gir…'");
	Else
		Form.Items["BankForPaymentsPage" + Postfix].Title = StrConcat(OutputAttributes, "; ");
	EndIf;
	
EndProcedure

&AtClient
Procedure WhenChangingBank(ThisIsMainCounterparty=False)
	
	Postfix = ?(ThisIsMainCounterparty, "MainCounterparty", "");
	
	PartnersAndCounterpartiesLocalizationClient.WhenChangingBankLocalization(ThisObject, Postfix);
	
	If ThisObject["ThisIsAnIBAN" + Postfix] Then
		CheckIBAN(ThisIsMainCounterparty)
	EndIf;
	Items["Bank" + Postfix].InputHint = "";
	If ValueIsFilled(ThisObject["Bank" + Postfix]) Then
		ThisObject["BankIndicationMethod" + Postfix] = "SelectionFromCatalog";
		FillInBankDetailsByBank("Bank", ThisObject["Bank" + Postfix], ThisIsMainCounterparty);
		ItemManagementBankAccount(ThisObject, ThisIsMainCounterparty);
		FillInMainBankDetails(ThisObject, ThisIsMainCounterparty);
	Else
		ThisObject["BankIndicationMethod" + Postfix] = "ManualFillingInOfBankingDetails";
		Items["BankPage" + Postfix].Title = NStr("vi = 'Nhập thông tin ngân hàng thủ công...';
												|ru = 'Ввести реквизиты банка вручную...';
												|en = 'Enter bank details manually...'; fa = 'ورود دستی جزئیات بانکی...';
												|it = 'Inserire i requisiti bancari manualmente...';
												|pl = 'Wpisz dane banku ręcznie...';
												|tr = 'Banka bilgilerini manuel olarak gir…'");
		ItemManagementBankAccount(ThisObject, ThisIsMainCounterparty);
	EndIf;
	
EndProcedure

&AtClient
Procedure WhenChangingManuallyChangeBankDetails(ThisIsMainCounterparty=False)
	
	Postfix = ?(ThisIsMainCounterparty, "MainCounterparty", "");

	If ThisObject["BankIndicationMethod" + Postfix] = "ManualFillingInOfBankingDetails" Then
		Items["Bank" + Postfix].InputHint = NStr("vi = '<thông tin ngân hàng được nhập thủ công>';
												|ru = '<реквизиты банка введены вручную>';
												|en = '<the bank details are entered manually>'; fa = '<the bank details are entered manually>';
												|it = '<requisiti bancari inseriti manualmente>';
												|pl = '<dane banku zostały wprowadzone ręcznie>';
												|tr = '<banka bilgileri manuel olarak girildi>'");
		ThisObject["Bank" + Postfix] = Undefined;
	Else
		Items["Bank" + Postfix].InputHint = "";
	EndIf;

	ManualChangeOfBankDetailsWhenChangingOnServer(ThisIsMainCounterparty);
	
	ItemManagementBankAccount(ThisObject, ThisIsMainCounterparty);
	
EndProcedure

&AtServer
Procedure ManualChangeOfBankDetailsWhenChangingOnServer(ThisIsMainCounterparty)
	
	Postfix = ?(ThisIsMainCounterparty, "MainCounterparty", "");
	
	If ThisObject["BankIndicationMethod" + Postfix] = "SelectionFromCatalog" Then
		FillInBankDetailsForBIC("Bank", ThisObject["BankBIC" + Postfix], ThisIsMainCounterparty);
	EndIf;
	
	FillInMainBankDetails(ThisObject, ThisIsMainCounterparty);
	
EndProcedure

&AtServer
Function FillInBankDetailsForBIC(BankType, Val BIC = "", ThisIsMainCounterparty=False)
	
	FoundByBIC   = False;
	RecordAboutBank = Undefined;
	
	If BankType = "Bank" Then
		ClearBankDetails(ThisObject, False, ThisIsMainCounterparty);
	Else
		ClearBankDetails(ThisObject, True, ThisIsMainCounterparty);
	EndIf;
	
	If ValueIsFilled(BIC) Then
		
		BankManager.GetClassifierData(BIC,, RecordAboutBank);
		
		If ValueIsFilled(RecordAboutBank) Then
			FillInBankDetailsByBank(BankType, RecordAboutBank, ThisIsMainCounterparty);
			ThisObject[BankType] = RecordAboutBank;
			FoundByBIC = True;
		EndIf;
	EndIf;
	
	Return FoundByBIC;
	
EndFunction

&AtClient
Procedure WhenChangingBankForSettlements(ThisIsMainCounterparty=False)
	
	Postfix = ?(ThisIsMainCounterparty, "MainCounterparty", "");
	
	Items["TransferBank" + Postfix].InputHint = "";
	If ValueIsFilled(ThisObject["TransferBank" + Postfix]) Then
		ThisObject["MethodOfSpecifyingBankForSettlements" + Postfix] = "SelectionFromCatalog";
		FillInBankDetailsByBank("TransferBank", ThisObject["TransferBank" + Postfix], ThisIsMainCounterparty);
		FillInMainBankDetailsForSettlements(ThisObject, ThisIsMainCounterparty);
	Else
		Items["BankForPaymentsPage" + Postfix].Title = NStr("vi = 'Nhập thông tin ngân hàng thủ công...';
															|ru = 'Ввести реквизиты банка вручную...';
															|en = 'Enter bank details manually...'; fa = 'ورود دستی جزئیات بانکی...';
															|it = 'Inserire i requisiti bancari manualmente...';
															|pl = 'Wpisz dane banku ręcznie...';
															|tr = 'Banka bilgilerini manuel olarak gir…'")
	EndIf;
	
	ItemManagementBankAccount(ThisObject, ThisIsMainCounterparty);
	
EndProcedure

&AtClient
Procedure WhenChangingManuallyChangingBankDetailsForSettlements(ThisIsMainCounterparty=False)
	
	Postfix = ?(ThisIsMainCounterparty, "MainCounterparty", "");
	If ThisObject["MethodOfSpecifyingBankForSettlements" + Postfix] = "ManualFillingInOfBankingDetails" Then
		Items["TransferBank" + Postfix].InputHint = NStr("vi = '<thông tin ngân hàng được nhập thủ công>';
														|ru = '<реквизиты банка введены вручную>';
														|en = '<the bank details are entered manually>'; fa = '<the bank details are entered manually>';
														|it = '<requisiti bancari inseriti manualmente>';
														|pl = '<dane banku zostały wprowadzone ręcznie>';
														|tr = '<banka bilgileri manuel olarak girildi>'");
		ThisObject["TransferBank" + Postfix] = Undefined;
	Else
		Items["TransferBank" + Postfix].InputHint = "";
	EndIf;

	ManualChangeOfBankDetailsForSettlementsWhenChangingOnServer(ThisIsMainCounterparty);
	
	ItemManagementBankAccount(ThisObject, ThisIsMainCounterparty);
	
EndProcedure

&AtServer
Procedure ManualChangeOfBankDetailsForSettlementsWhenChangingOnServer(ThisIsMainCounterparty)
	
	Postfix = ?(ThisIsMainCounterparty, "MainCounterparty", "");
	If ThisObject["MethodOfSpecifyingBankForSettlements" + Postfix] = "SelectionFromCatalog" Then
		FillInBankDetailsForBIC("TransferBank", TransferBankBIC, ThisIsMainCounterparty)
	EndIf;
	
	If Not ThisObject["TransferBank" + Postfix].IsEmpty() Then
		FillInBankDetailsByBank("TransferBank", TransferBank, ThisIsMainCounterparty);
	EndIf;
	
	FillInMainBankDetailsForSettlements(ThisObject, ThisIsMainCounterparty);
	
EndProcedure

&AtClient
Procedure AccountNumberOnChangeClient(ThisIsMainCounterparty = False)
	
	Postfix = ?(ThisIsMainCounterparty, "MainCounterparty", "");
	
	Items["GroupErrorInAccountNumber" + Postfix].Visible = False;
	ThisObject["AccountNumber" + Postfix] = Upper(StrReplace(
		StrReplace(TrimAll(ThisObject["AccountNumber" + Postfix]), " ", ""), ".", ""));
	
	If InternationalBankAccountDetails Then
		ThisObject["ForeignBank" + Postfix] = True;
		If Mid(ThisObject["AccountNumber" + Postfix], 1, 4) = "IBAN" Then
			ThisObject["AccountNumber" + Postfix] = Mid(ThisObject["AccountNumber" + Postfix], 5);
		EndIf;
		If CashClientServer.CorrectIBANLength(ThisObject["AccountNumber" + Postfix]) Then
			ThisObject["ThisIsAnIBAN" + Postfix] = True;
			IdentifyCountryAndBankByIBAN(ThisIsMainCounterparty);
			Items["GroupErrorInAccountNumber" + Postfix].Visible = False;
		EndIf;
		If ThisObject["ThisIsAnIBAN" + Postfix] Then
			CheckIBAN(ThisIsMainCounterparty)
		EndIf;
	EndIf;
		
	FillInMainBankDetails(ThisObject, ThisIsMainCounterparty);
	
	If Not ThisObject["ForeignBank" + Postfix] And Not IsBlankString(ThisObject["AccountNumber" + Postfix]) Then
		
		AccountCurrency = GetCurrencyByAccountNumber(ThisObject["AccountNumber" + Postfix]);
		If ValueIsFilled(AccountCurrency) Then
			ThisObject["CashCurrency" + Postfix] = AccountCurrency;
		EndIf;
		
	EndIf;
	
	ItemManagementBankAccount(ThisObject, ThisIsMainCounterparty);
	
	ClearMarkIncomplete();
	
EndProcedure

&AtClient
Function ItSForeignBank(InvoiceData)

	Return CashClientLocalization.ItSForeignBank(InternationalBankAccountDetails, InvoiceData);

EndFunction

&AtClientAtServerNoContext
Procedure ClearBankDetails(Form, ThisIsBankForSettlements = False, ThisIsMainCounterparty = False)

	If Not ThisIsBankForSettlements Then
		
		AttributesStructure1 = BankingDetails(ThisIsMainCounterparty);
		
		If ThisIsMainCounterparty Then
			AttributesStructure1.Insert("BankCountryHeadCounterparty");
		Else
			AttributesStructure1.Insert("CountryOfBank");
		EndIf;
		
	Else
		
		AttributesStructure1 = BankDetailsForSettlements(ThisIsMainCounterparty);
		
		If ThisIsMainCounterparty Then
			AttributesStructure1.Insert("CountryOfBankForSettlementsHeadCounterparty");
		Else
			AttributesStructure1.Insert("CountryOfBankForPayments");
		EndIf;
		
	EndIf;
	
	CashClientServer.ClearBankDetailsOnForm(Form, AttributesStructure1);

EndProcedure

#EndRegion
	
#Region TransfersByPages

&AtClient
Procedure NavigateThroughPages(Val Notification, Command)
	
	Cancel = PageClickConditionsNotMet_(Command);
	
	If Not Cancel Then
		PerformNecessaryActionsWhenNavigatingThroughPages(New CallbackDescription("NavigateThroughPagesCompletion", ThisObject, New Structure("Notification", Notification)), Command);
		Return;
	EndIf;
	
	NavigateThroughPagesFragment(Notification);
	
EndProcedure

&AtClient
Procedure NavigateThroughPagesCompletion(Result, AdditionalParameters) Export
	
	Notification = AdditionalParameters.Notification;
	NavigateThroughPagesFragment(Notification);
	
EndProcedure

&AtClient
Procedure NavigateThroughPagesFragment(Val Notification)
	
	ManagingBasementPages();
	
	RunCallback(Notification);

EndProcedure

&AtClient
Function PageClickConditionsNotMet_(Command)
	
	Cancel = False;
	If Command.Name = "Next" Then
		If Items.WizardPages.CurrentPage = Items.PrimaryInformationPage Then
			Cancel = PrimaryInformationIsFilledInIncorrectly();
		ElsIf Items.WizardPages.CurrentPage = Items.AdditionalInformationPage Then
			Cancel = AdditionalInformationFilledInIncorrectly();
		ElsIf Items.WizardPages.CurrentPage = Items.AdditionalAttributesPage Then
			Cancel = AdditionalDetailsFilledInIncorrectly();
		ElsIf Items.WizardPages.CurrentPage = Items.HeadCounterpartyPage Then
			Cancel = InformationOfHeadCounterpartyIsFilledInIncorrectly();
		ElsIf Items.WizardPages.CurrentPage = Items.CurrentAccountPage Then
			Cancel = CurrentAccountFilledInIncorrectly();
		ElsIf Items.WizardPages.CurrentPage = Items.TheHeadCounterpartySSettlementAccountPage Then
			Cancel = SettlementAccountOfHeadCounterpartyIsFilledInIncorrectly();
		EndIf;
	EndIf;
	
	Return Cancel;
	
EndFunction

&AtClient
Procedure PerformNecessaryActionsWhenNavigatingThroughPages(Val Notification, Command)
	
	If Command.Name = "Next" Then
		
		If Items.WizardPages.CurrentPage = Items.PrimaryInformationPage Then
			
			SearchForPrimaryInformation();
			If TableFound.Count() > 0 Then
				GoToFoundMatchesPage();
			Else
				GoToAdditionalInformationPage();
			EndIf;
			
		ElsIf Items.WizardPages.CurrentPage = Items.PageFound Then
			
			UserSelectionBasedOnSearchResults(New CallbackDescription("PerformNecessaryActionsWhenNavigatingThroughPagesAfterSelecting", ThisObject, New Structure("Notification", Notification)));
			Return;
			
		ElsIf Items.WizardPages.CurrentPage = Items.AdditionalInformationPage Then
			
			If UseAdditionalBankingDetails_3 Then
				
				If AdditionalDetailsElementsNeedToBeUpdated Then
					UpdateAdditionalAttributesItems();
					AdditionalDetailsElementsNeedToBeUpdated = False;
				EndIf;
				
				If Items.GroupAdditionalAttributes.ChildItems.Count() > 0 Then
					GoToAdditionalDetailsPage();
				Else
					GoToCurrentAccountPageOrFinalPage();
				EndIf;
				
			Else
				
				GoToCurrentAccountPageOrFinalPage();
				
			EndIf;
			
		ElsIf Items.WizardPages.CurrentPage = Items.AdditionalAttributesPage Then
			
			GoToCurrentAccountPageOrFinalPage();
			
		ElsIf Items.WizardPages.CurrentPage = Items.CurrentAccountPage Then
			
			If OnlyPartnersAreUsed
					Or (ActionWithTheCounterparty = 1 And Not BasedOnTheCounterparty And SpecifyLegalDetails) Then
					
				If TypeOfCompany = 3 And Not OnlyPartnersAreUsed Then
					GoToPageForSelectingHeadCounterparty();
				ElsIf TypeOfCompany = 0 And PartnersAndCounterpartiesLocalizationClient.SearchForDetachedDetachedUnitsIsNeeded(ThisObject) Then
					SearchForUnboundDetachedUnits();
					If SeparateBusinessUnits.Count() > 0 Then
						GoToSeparateDivisionsPage();
					EndIf;
				EndIf;
				
			EndIf;
			
			If Items.WizardPages.CurrentPage = Items.CurrentAccountPage Then
				GoToFinalPage();
			EndIf;
			
		ElsIf Items.WizardPages.CurrentPage = Items.SeparateDivisionsPage Then
			
			GoToFinalPage();
			
		ElsIf Items.WizardPages.CurrentPage = Items.HeadCounterpartyPage Then
			
			If SelectTheHeadCounterparty = 1 Then
				GoToCurrentAccountPageOfHeadCounterparty();
			Else
				GoToFinalPage();
			EndIf;
			
		ElsIf Items.WizardPages.CurrentPage = Items.TheHeadCounterpartySSettlementAccountPage Then
			
			GoToFinalPage();
			
		ElsIf Items.WizardPages.CurrentPage = Items.FinalPage Then
			
			ListOfCreated = New ValueList;
			YouNeedToGoToMatchesPage = False;
			CreatePartner(ListOfCreated, YouNeedToGoToMatchesPage);
			
			If YouNeedToGoToMatchesPage Then
				GoToFoundMatchesPage();
				Return;
			EndIf;
			
			If CreationCompleted Then
				
				PartnerDetails_ = New Structure;
				
				For Each ListItem In ListOfCreated Do
					If TypeOf(ListItem.Value) = Type("CatalogRef.Partners") Then
						PartnerDetails_.Insert("Description", ListItem.Presentation);
						PartnerDetails_.Insert("MainManager", MainManager);
					EndIf;
					ShowUserNotification("Creating", ListItem.Value, ListItem.Presentation);
				EndDo;
				
				If PartnerDetails_.Count() = 0 Then
					PartnerDetails_ = GeneralPurposeTMServerCall.ObjectAttributesValues(PartnerChoice, "MainManager, Description");
				EndIf;
				
				PerformFormClosingActions(New CallbackDescription("PerformNecessaryActionsWhenNavigatingThroughPagesCompletion", ThisObject, New Structure("Notification", Notification)), PartnerDetails_, True);
				Return;
				
			EndIf;
			
		EndIf;
		
	Else
		
		ListSize = StackOfPreviousPages.Count();
		NameOfThePreviousPage = StackOfPreviousPages[ListSize - 1].Value;
		Items.WizardPages.CurrentPage = Items[NameOfThePreviousPage];
		StackOfPreviousPages.Delete(ListSize -1);
		
	EndIf;
	
	PerformNecessaryActionsWhenNavigatingThroughFragmentPages(Notification);
	
EndProcedure

&AtClient
Procedure PerformNecessaryActionsWhenNavigatingThroughPagesAfterSelecting(Result, AdditionalParameters) Export
	
Notification = AdditionalParameters.Notification;
	
	If Result Then
		RunCallback(Notification);
		Return;
	EndIf;
	If ActionBasedOnResultsFound = 0 Then
		If FactTheCounterpartySAddressIsRequired 
			Or TheLegalAddressOfTheCounterpartyIsRequired Then
			GoToAdditionalInformationPage();
		Else
			GoToCounterpartySCurrentAccountPage();
		EndIf;
	Else
		GoToAdditionalInformationPage();
	EndIf;
	
	PerformNecessaryActionsWhenNavigatingThroughFragmentPages(Notification);
	
EndProcedure

&AtClient
Procedure PerformNecessaryActionsWhenNavigatingThroughPagesCompletion(Result, AdditionalParameters) Export
    
    Notification = AdditionalParameters.Notification;
    
    
    PerformNecessaryActionsWhenNavigatingThroughFragmentPages(Notification);

EndProcedure

&AtClient
Procedure PerformNecessaryActionsWhenNavigatingThroughFragmentPages(Val Notification)
	
	RunCallback(Notification);
	
EndProcedure

&AtClient
Procedure GoToCurrentAccountPageOrFinalPage()

	If (ActionWithTheCounterparty = 1 Or OnlyPartnersAreUsed) And SpecifyLegalDetails Then
		GoToCounterpartySCurrentAccountPage();
	Else
		GoToFinalPage();
	EndIf;

EndProcedure

&AtClient
Procedure GoToFoundMatchesPage()
	
	StackOfPreviousPages.Add(Items.WizardPages.CurrentPage.Name);
	Items.WizardPages.CurrentPage = Items.PageFound;
	
	CurrentItem = Items.TableFound;
	
EndProcedure

&AtClient
Procedure GoToAdditionalInformationPage()
	
	If IsBlankString(FullLegalName) And ThisIsACompany = 1 And SpecifyLegalDetails Then
		FullLegalName = FIO_OneLine(PartnerSLastName, PartnerName_3, PartnerSMiddleName);
	EndIf;
	
	If BasedOnRetailCustomerData Then
		TitleDecorations = NStr("vi = 'Hãy chỉ ra thông tin hợp lệ khác về khách lẻ %1:';
								|ru = 'Укажите прочие доступные сведения о розничном покупателе %1:';
								|en = 'Specify other available details on retail customer %1:'; fa = 'Specify other available details on retail customer %1:';
								|it = 'Specificate le altre informazioni disponibili sul compratore al dettaglio %1:';
								|pl = 'Wskaż inne dostępne informacje o kliencie detalicznym %1:';
								|tr = '%1 perakende müşterisiyle ilgili mevcut diğer bilgileri belirtin:'");
	ElsIf OnlyPartnersAreUsed
		Or ActionBasedOnResultsFound = 0 Then
		TitleDecorations = NStr("vi = 'Hãy chỉ ra thông tin hợp lệ khác về đối tác %1:';
								|ru = 'Укажите прочие доступные сведения о контрагенте %1:';
								|en = 'Specify other available details about counterparty %1:'; fa = 'Specify other available details about counterparty %1:';
								|it = 'Specificate le altre informazioni disponibili sul contraente %1:';
								|pl = 'Wskaż inne dostępne informacje o kontrahencie %1:';
								|tr = '%1 cari hesabıyla ilgili mevcut diğer bilgileri belirtin:'");
	Else
		TitleDecorations = NStr("vi = 'Hãy chỉ ra thông tin hợp lệ khác về bạn hàng %1:';
								|ru = 'Укажите прочие доступные сведения о партнере %1:';
								|en = 'Specify other available details about partner %1:'; fa = 'Specify other available details about partner %1:';
								|it = 'Specificate le altre informazioni disponibili sul partner %1:';
								|pl = 'Wskaż inne dostępne informacje o partnerze %1:';
								|tr = '%1 iş ortağıyla ilgili mevcut diğer bilgileri belirtin:'");
	EndIf;
	
	If ThisIsACompany = 0 Then
		
		NameOfHeaderPartner = ?(OnlyPartnersAreUsed, FullDescr, FullLegalName);
		If IsBlankString(Name1) Then
			Name1 = FullDescr;
		EndIf;
		
		If TypeOfCompany = 3 And OnlyPartnersAreUsed Then
			FillInListOfSelectingHeadCounterparty();
		EndIf;
		
	Else
		NameOfHeaderPartner = FIO_OneLine(PartnerSLastName, PartnerName_3, PartnerSMiddleName);
	EndIf;
	
	Name1 = ?(IsBlankString(Name1) Or ThisIsACompany = 1, NameOfHeaderPartner, Name1);
	
	Items.DecorationAdditionalInformation.Title =
		StringFunctionsClientServer.SubstituteParametersToString(TitleDecorations, Name1);
	
	AvailabilityManagementAdditionalInformation(ThisObject);
	
	StackOfPreviousPages.Add(Items.WizardPages.CurrentPage.Name);
	Items.WizardPages.CurrentPage = Items.AdditionalInformationPage;
	
EndProcedure

&AtClient
Procedure GoToCounterpartySCurrentAccountPage()
	
	TitleDecorations = StrReplace(
		Items.DecorationBankInformation.Title,
		"#PartnerName#",
		NameOfHeaderPartner());

	TMCommonUseClientServer.SetFormItemProperty(
		Items,
		"DecorationBankInformation",
		"Title",
		TitleDecorations);
	
	AvailabilityManagementCheckingAccount(SpecifyTheCounterpartySBankAccount);
	ItemManagementBankAccount(ThisObject);
	
	StackOfPreviousPages.Add(Items.WizardPages.CurrentPage.Name);
	Items.WizardPages.CurrentPage = Items.CurrentAccountPage;
	
EndProcedure

&AtClient
Procedure GoToSeparateDivisionsPage()
	
	Items.WizardPages.CurrentPage = Items.SeparateDivisionsPage;
	
EndProcedure

&AtClient
Procedure GoToPageForSelectingHeadCounterparty()
	
	AvailabilityManagementCheckingAccount(SpecifyTheBankAccountOfTheMainCounterparty, True);
	FillInListOfSelectingHeadCounterparty();
	FillInPartnerSelectionListOfHeadCounterparty();
	
	PartnersAndCounterpartiesLocalizationClientServer.AvailabilityManagementHeadCounterparty(ThisObject);
	
	StackOfPreviousPages.Add(Items.WizardPages.CurrentPage.Name);
	Items.WizardPages.CurrentPage = Items.HeadCounterpartyPage;
	
EndProcedure

&AtClient
Procedure GoToCurrentAccountPageOfHeadCounterparty()
	
	TitleDecorations = StrReplace(
		Items.TheBackdropOfTheBankingInformationOfTheHeadContractor.Title,
		"#NameOfTheCounterparty#",
		NameHeadCounterparty);
	
	TMCommonUseClientServer.SetFormItemProperty(
		Items,
		"TheBackdropOfTheBankingInformationOfTheHeadContractor",
		"Title",
		TitleDecorations);
		
	AvailabilityManagementCheckingAccount(True);
	ItemManagementBankAccount(ThisObject, True);
	
	StackOfPreviousPages.Add(Items.WizardPages.CurrentPage.Name);
	Items.WizardPages.CurrentPage = Items.TheHeadCounterpartySSettlementAccountPage;
	
EndProcedure

&AtClient
Procedure GoToFinalPage()
	
	If BasedOnRetailCustomerData Then
		PageHeader = NStr("vi = 'Hãy kiểm tra thông tin đã nhập và nhấn nút ""Tạo mới"" để ghi nhận khách lẻ mới.';
							|ru = 'Проверьте введенные сведения, и нажмите кнопку ""Создать""  для регистрации нового розничного покупателя.';
							|en = 'Verify the information that you entered, and then click Create to register a new retail customer.'; fa = 'Verify the information that you entered, and then click Create to register a new retail customer.';
							|it = 'Controllate le informazioni inserite e cliccate il tasto ""Crea"" per registrare un nuovo compratore al dettaglio.';
							|pl = 'Sprawdź wprowadzone informacje i naciśnij przycisk ""Utwórz"", aby zarejestrować nowego klienta detalicznego.';
							|tr = 'Girilen bilgileri kontrol edin ve yeni bir perakende müşteri kaydetmek için ""Oluştur"" butonuna tıklayın.'");
		ActionHeader_ = NStr("vi = 'Mở lại biểu mẫu khách lẻ đã tạo để chỉ ra thông tin bổ sung.';
							|ru = 'Открыть форму вновь созданного розничного покупателя для указания дополнительной информации.';
							|en = 'Open the newly created retail customer form to specify additional information.'; fa = 'Open the newly created retail customer form to specify additional information.';
							|it = 'Aprire il modulo del compratore al dettaglio appena creato per indicare ulteriori informazioni.';
							|pl = 'Otwórz formularz nowo utworzonego klienta detalicznego w celu określenia informacji dodatkowej.';
							|tr = 'Ek bilgi belirtmek için yeni oluşturulan perakende müşteri formunu aç.'");
	ElsIf OnlyPartnersAreUsed Or ActionBasedOnResultsFound = 0 Then
		PageHeader = NStr("vi = 'Hãy kiểm tra thông tin đã nhập và nhấn nút ""Tạo mới"" để ghi nhận đối tác mới.';
							|ru = 'Проверьте введенные сведения, и нажмите кнопку ""Создать""  для регистрации нового контрагента.';
							|en = 'Verify the information that you entered, and then click ""Create"" to register a new counterparty.'; fa = 'Verify the information that you entered, and then click ""Create"" to register a new counterparty.';
							|it = 'Controllate le informazioni inserite e cliccate il tasto ""Crea"" per registrare un nuovo contraente.';
							|pl = 'Sprawdź wprowadzone informacje i naciśnij przycisk ""Utwórz"", aby zarejestrować nowego kontrahenta.';
							|tr = 'Girilen bilgileri kontrol edin ve yeni bir cari hesap kaydetmek için ""Oluştur"" butonuna tıklayın.'");
		ActionHeader_ = NStr("vi = 'Mở lại biểu mẫu bạn hàng để bổ sung thông tin.';
							|ru = 'Открыть форму вновь созданного контрагента для указания дополнительной информации.';
							|en = 'Open the newly created counterparty form to specify additional information.'; fa = 'Open the newly created counterparty form to specify additional information.';
							|it = 'Aprire il modulo del contraente appena creato per indicare ulteriori informazioni.';
							|pl = 'Otwórz formularz nowo utworzonego kontrahenta w celu określenia informacji dodatkowej.';
							|tr = 'Ek bilgi belirtmek için yeni oluşturulan cari hesap formunu aç.'");
	Else
		PageHeader = NStr("vi = 'Hãy kiểm tra thông tin đã nhập và nhấn nút ""Tạo mới"" để ghi nhận bạn hàng mới.';
							|ru = 'Проверьте введенные сведения, и нажмите кнопку ""Создать""  для регистрации нового партнера.';
							|en = 'Verify the information that you entered and click ""Create"" to register a new partner.'; fa = 'اطلاعات واردشده را بررسی کرده و برای ثبت شریک جدید روی «ایجاد» کلیک کنید.';
							|it = 'Controllate le informazioni inserite e cliccate il tasto ""Crea"" per registrare un nuovo partner.';
							|pl = 'Sprawdź wprowadzone informacje i naciśnij przycisk ""Utwórz"", aby zarejestrować nowego partnera.';
							|tr = 'Girilen bilgileri kontrol edin ve yeni bir iş ortağı kaydetmek için ""Oluştur"" butonuna tıklayın.'");
		ActionHeader_ = NStr("vi = 'Mở lại biểu mẫu bạn hàng đã tạo để bổ sung thông tin.';
							|ru = 'Открыть форму вновь созданного партнера для указания дополнительной информации.';
							|en = 'Open the new partner form to specify additional information.'; fa = 'فرم شریک جدید را برای تعیین اطلاعات تکمیلی باز کنید.';
							|it = 'Aprire il modulo del partner appena creato per indicare ulteriori informazioni.';
							|pl = 'Otwórz formularz nowo utworzonego partnera w celu określenia informacji dodatkowej.';
							|tr = 'Ek bilgi belirtmek için yeni oluşturulan iş ortağının formunu aç.'");
	EndIf;
	
	Items.FinalDecoration.Title = PageHeader;
	Items.OpenAfterCreation.Title = ActionHeader_;
	
	FillInSummaryInformation();
	
	StackOfPreviousPages.Add(Items.WizardPages.CurrentPage.Name);
	Items.WizardPages.CurrentPage = Items.FinalPage;
	
EndProcedure

&AtClient
Procedure GoToAdditionalDetailsPage()
	
	TitleDecorations = StrTemplate(NStr("vi = 'Chỉ định mục tin bổ sung %1:';
										|ru = 'Укажите дополнительные реквизиты %1:';
										|en = 'Specify additional attributes %1:'; fa = 'Specify additional attributes %1:';
										|it = 'Indicate requisiti aggiuntivi %1:';
										|pl = 'Wskaż dodatkowe atrybuty %1:';
										|tr = 'Ek %1 özniteliklerini belirtin:'"),
	                               NameOfHeaderPartner());
	
	TMCommonUseClientServer.SetFormItemProperty(
		Items,
		"DecorationAdditionalDetails",
		"Title",
		TitleDecorations);
	
	StackOfPreviousPages.Add(Items.WizardPages.CurrentPage.Name);
	Items.WizardPages.CurrentPage = Items.AdditionalAttributesPage;

EndProcedure

&AtClient
Procedure QuestionContinuationOfPartnerSelectionCompletion(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		
		PerformFormClosingActions(Undefined, AdditionalParameters.PartnerDetails_, AdditionalParameters.NewObjectsCreated);
        Return;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region CheckingEnteredInformation

&AtClient
Function PrimaryInformationIsFilledInIncorrectly()
	
	Cancel = False;
	ClearMessages();
	
	If ThisIsACompany = 0 Then
		If OnlyPartnersAreUsed Then
			If IsBlankString(FullLegalName) Then
				PartnersAndCounterpartiesClient.OutputUserMessage(NStr("vi = 'Chưa chỉ ra tên viết tắt pháp nhân của bạn hàng';
																		|ru = 'Не указано сокращенное юр. наименование партнера';
																		|en = 'Abbreviated partner name is not specified'; fa = 'Abbreviated partner name is not specified';
																		|it = 'Nome giuridico abbreviato del partner non indicato';
																		|pl = 'Nie wskazano skróconej nazwy prawnej partnera';
																		|tr = 'İş ortağının kısaltılmış yasal adı belirtilmedi'"), OnlyPartnersAreUsed, "FullLegalName");
				Cancel = True;
			EndIf;
		Else
			If IsBlankString(FullDescr) Then
				PartnersAndCounterpartiesClient.OutputUserMessage(NStr("vi = 'Chưa chỉ ra tên gọi công khai của bạn hàng';
																		|ru = 'Не указано публичное наименование партнера';
																		|en = 'Partner public name is not specified'; fa = 'Partner public name is not specified';
																		|it = 'Nome pubblico del partner non indicato';
																		|pl = 'Nie wskazano nazwy publicznej partnera';
																		|tr = 'İş ortağının kamu adı belirtilmedi'"), OnlyPartnersAreUsed, "FullDescr");
				Cancel = True;
			EndIf;
		EndIf;
	ElsIf ThisIsACompany = 1 Then
		If IsBlankString(PartnerSLastName) Then
			PartnersAndCounterpartiesClient.OutputUserMessage(NStr("vi = 'Chưa chỉ ra họ của bạn hàng';
																	|ru = 'Не указано фамилия партнера';
																	|en = 'Partner last name is not specified'; fa = 'Partner last name is not specified';
																	|it = 'Cognome del partner non indicato';
																	|pl = 'Nie wskazano nazwiska partnera';
																	|tr = 'İş ortağının soyadı belirtilmedi'"), OnlyPartnersAreUsed, "PartnerSLastName");
			Cancel = True;
		EndIf;
		If IsBlankString(PartnerName_3) Then
			PartnersAndCounterpartiesClient.OutputUserMessage(NStr("vi = 'Chưa chỉ ra tên của bạn hàng';
																	|ru = 'Не указано имя партнера';
																	|en = 'Partner name is not specified'; fa = 'Partner name is not specified';
																	|it = 'Nome del partner non indicato';
																	|pl = 'Nie wskazano imienia partnera';
																	|tr = 'İş ortağının adı belirtilmedi'"), OnlyPartnersAreUsed, "PartnerName_3");
			Cancel = True;
		EndIf;
	EndIf; 
	
	MandatoryContactInformationWorkedOut = False;
	
	If ThisIsACompany = 0 Then
		
		If TheEppartnerSAddressIsRequired
			And Not ValueIsFilled(EppartnerSAddress) Then
			
			PartnersAndCounterpartiesClient.OutputUserMessage(NStr("vi = 'Cần chỉ ra địa chỉ email của bạn hàng';
																	|ru = 'Необходимо указать адрес электронной почты партнера';
																	|en = 'Specify partner''s email address'; fa = 'Specify partner''s email address';
																	|it = 'È necessario indicare l''indirizzo di posta elettronica del partner';
																	|pl = 'Należy wskazać adres poczty elektronicznej partnera';
																	|tr = 'İş ortağının e-posta adresini belirtmeniz gerekmektedir'"),OnlyPartnersAreUsed, "EppartnerSAddress");
			Cancel = True;
			MandatoryContactInformationWorkedOut = True;
			
		EndIf;
		
		If PartnerSPhoneNumberIsRequired
			And Not ValueIsFilled(PartnerSPhoneNumber) Then
			
			PartnersAndCounterpartiesClient.OutputUserMessage(NStr("vi = 'Cần chỉ ra số điện thoại của bạn hàng';
																	|ru = 'Необходимо указать телефон партнера';
																	|en = 'Specify partner phone number'; fa = 'Specify partner phone number';
																	|it = 'È necessario indicare il numero di telefono del partner';
																	|pl = 'Należy wskazać numer telefonu partnera';
																	|tr = 'İş ortağının telefonunu belirtmeniz gerekmektedir'"),OnlyPartnersAreUsed, "PartnerSPhoneNumber");
			Cancel = True;
			MandatoryContactInformationWorkedOut = True;
			
		EndIf;
		
		If SpecifyTheContactPersonSDetails Then
			
			If TheAddressOfTheContactPersonIsRequired
				And Not ValueIsFilled(EPCLAddress) Then
				
				PartnersAndCounterpartiesClient.OutputUserMessage(NStr("vi = 'Cần chỉ ra địa chỉ email của người liên hệ';
																		|ru = 'Необходимо указать адрес электронной почты контактного лица';
																		|en = 'Specify email address of contact person'; fa = 'Specify email address of contact person';
																		|it = 'È necessario indicare l''indirizzo di posta elettronica della persona di contatto';
																		|pl = 'Należy wskazać adres poczty elektronicznej osoby do kontaktu';
																		|tr = 'İlgili kişinin e-posta adresini belirtmeniz gerekmektedir'"), OnlyPartnersAreUsed, "EPCLAddress");
				Cancel = True;
				MandatoryContactInformationWorkedOut = True;
				
			EndIf;
			
			If ContactPersonSPhoneNumberIsRequired 
				And Not ValueIsFilled(PhoneNumberKL) Then
				
				PartnersAndCounterpartiesClient.OutputUserMessage(NStr("vi = 'Cần chỉ ra số điện thoại của người liên hệ';
																		|ru = 'Необходимо указать телефон контактного лица';
																		|en = 'Specify contact person phone number'; fa = 'Specify contact person phone number';
																		|it = 'È necessario indicare il telefono della persona di contatto';
																		|pl = 'Należy wskazać numer telefonu osoby do kontaktu';
																		|tr = 'İlgili kişinin telefonunu belirtmeniz gerekmektedir'"), OnlyPartnersAreUsed, "PhoneNumberKL");
				Cancel = True;
				MandatoryContactInformationWorkedOut = True;
				
			EndIf;
			
			If TheContactPersonSMobilePhoneNumberIsRequired 
				And Not ValueIsFilled(MobilePhoneKL) Then
				
				PartnersAndCounterpartiesClient.OutputUserMessage(NStr("vi = 'Cần chỉ ra số điện thoại di động của người liên hệ';
																		|ru = 'Необходимо указать мобильный телефон контактного лица';
																		|en = 'Specify cell phone number of contact person'; fa = 'Specify cell phone number of contact person';
																		|it = 'È necessario indicare il telefono cellulare della persona di contatto';
																		|pl = 'Należy wskazać numer telefonu komórkowego osoby do kontaktu';
																		|tr = 'İlgili kişinin cep telefonunu belirtmeniz gerekmektedir'"), OnlyPartnersAreUsed, "MobilePhoneKL");
				Cancel = True;
				MandatoryContactInformationWorkedOut = True;
				
			EndIf;
			
		EndIf;
		
		If Not MandatoryContactInformationWorkedOut 
			And IsBlankString(EppartnerSAddress)
			And IsBlankString(PartnerSPhoneNumber) Then
			
			If (SpecifyTheContactPersonSDetails) Then
				
				If IsBlankString(PhoneNumberKL) And IsBlankString(MobilePhoneKL) And IsBlankString(EPCLAddress) Then
					
					PartnersAndCounterpartiesClient.OutputUserMessage(NStr("vi = 'Cần chỉ ra ít nhất một thông tin liên hệ';
																			|ru = 'Необходимо указать хотя бы одно значение контактной информации';
																			|en = 'You must specify at least one value for contact details'; fa = 'You must specify at least one value for contact details';
																			|it = 'È necessario indicare almeno un valore dell''informazione di contatto';
																			|pl = 'Należy wskazać chociażby jedną wartość danych kontaktowych';
																			|tr = 'En az bir iletişim bilgisi değeri belirtmeniz gerekmektedir'"),OnlyPartnersAreUsed, "EppartnerSAddress");
					Cancel = True;
					
				EndIf;
				
			Else
				
				PartnersAndCounterpartiesClient.OutputUserMessage(NStr("vi = 'Cần chỉ ra ít nhất một thông tin liên hệ';
																		|ru = 'Необходимо указать хотя бы одно значение контактной информации';
																		|en = 'You must specify at least one value for contact details'; fa = 'You must specify at least one value for contact details';
																		|it = 'È necessario indicare almeno un valore dell''informazione di contatto';
																		|pl = 'Należy wskazać chociażby jedną wartość danych kontaktowych';
																		|tr = 'En az bir iletişim bilgisi değeri belirtmeniz gerekmektedir'"),OnlyPartnersAreUsed, "EppartnerSAddress");
				Cancel = True;
				
			EndIf;
			
		EndIf;
		
	Else
		
		If (TheEppartnerSAddressIsRequired
			Or OptionOfSendingElectronicReceipt = PredefinedValue("Enum.OptionsOfSendingElectronicReceiptToCustomer.SendByEmail"))
			And Not ValueIsFilled(EppartnerSAddressIndividual) Then
			
			PartnersAndCounterpartiesClient.OutputUserMessage(NStr("vi = 'Cần chỉ ra địa chỉ email của bạn hàng';
																	|ru = 'Необходимо указать адрес электронной почты партнера';
																	|en = 'Specify partner''s email address'; fa = 'Specify partner''s email address';
																	|it = 'È necessario indicare l''indirizzo di posta elettronica del partner';
																	|pl = 'Należy wskazać adres poczty elektronicznej partnera';
																	|tr = 'İş ortağının e-posta adresini belirtmeniz gerekmektedir'"),OnlyPartnersAreUsed, "EppartnerSAddressIndividual");
			Cancel = True;
			MandatoryContactInformationWorkedOut = True;
			
		EndIf;
		
		If (PartnerSPhoneNumberIsRequired
			Or OptionOfSendingElectronicReceipt = PredefinedValue("Enum.OptionsOfSendingElectronicReceiptToCustomer.SendSMS"))
			And Not ValueIsFilled(PartnerSPhoneNumberIndividual) Then
			
			PartnersAndCounterpartiesClient.OutputUserMessage(NStr("vi = 'Cần chỉ ra số điện thoại của bạn hàng';
																	|ru = 'Необходимо указать телефон партнера';
																	|en = 'Specify partner phone number'; fa = 'Specify partner phone number';
																	|it = 'È necessario indicare il numero di telefono del partner';
																	|pl = 'Należy wskazać numer telefonu partnera';
																	|tr = 'İş ortağının telefonunu belirtmeniz gerekmektedir'"),OnlyPartnersAreUsed, "PartnerSPhoneNumberIndividual");
			Cancel = True;
			MandatoryContactInformationWorkedOut = True;
			
		EndIf;
		
		If Not MandatoryContactInformationWorkedOut
			And IsBlankString(EppartnerSAddressIndividual) And IsBlankString(PartnerSPhoneNumberIndividual) Then
			
			PartnersAndCounterpartiesClient.OutputUserMessage(NStr("vi = 'Cần chỉ ra ít nhất một thông tin liên hệ';
																	|ru = 'Необходимо указать хотя бы одно значение контактной информации';
																	|en = 'You must specify at least one value for contact details'; fa = 'You must specify at least one value for contact details';
																	|it = 'È necessario indicare almeno un valore dell''informazione di contatto';
																	|pl = 'Należy wskazać chociażby jedną wartość danych kontaktowych';
																	|tr = 'En az bir iletişim bilgisi değeri belirtmeniz gerekmektedir'"),OnlyPartnersAreUsed, "EppartnerSAddressIndividual");
			Cancel = True;
			
		EndIf;
		
	EndIf;
	
	If SpecifyLegalDetails Then
		
		If Not OnlyPartnersAreUsed And ThisIsACompany = 0 Then
			If IsBlankString(FullLegalName) Then
				PartnersAndCounterpartiesClient.OutputUserMessage(NStr("vi = 'Chưa chỉ ra tên viết tắt pháp nhân';
																		|ru = 'Не указано сокращенное юр. наименование';
																		|en = 'Abbreviated company name is not specified'; fa = 'Abbreviated company name is not specified';
																		|it = 'Nome giuridico abbreviato non indicato';
																		|pl = 'Nie wskazano skróconej nazwy prawnej';
																		|tr = 'Kısaltılmış yasal adı belirtilmedi'"),OnlyPartnersAreUsed, "NameOfTheCounterparty");
				Cancel = True; 
			EndIf;
		EndIf;
		
		If ThisIsACompany = 1 And SpecifyLegalDetails And SpecifyTheIdentityDocument Then
			If Not ValueIsFilled(DocumentKind) Then
				PartnersAndCounterpartiesClient.OutputUserMessage(NStr("vi = 'Chưa chỉ ra dạng giấy tờ tùy thân';
																		|ru = 'Не указано вид документа удостоверяющего личность';
																		|en = 'Identity document kind is not specified'; fa = 'Identity document kind is not specified';
																		|it = 'Tipo di documento di identità non specificato';
																		|pl = 'Nie wskazano rodzaju dokumentu potwierdzającego tożsamość';
																		|tr = 'Kimlik belgesi türü belirtilmedi'"),OnlyPartnersAreUsed, "DocumentKind");
				Cancel = True
			EndIf;
		EndIf;
		
	EndIf;
	
	If SpecifyTheContactPersonSDetails And ThisIsACompany = 0 Then
		
		If IsBlankString(LastNameKL) Then
			PartnersAndCounterpartiesClient.OutputUserMessage(NStr("vi = 'Chưa chỉ ra họ của người liên hệ';
																	|ru = 'Не указана фамилия контактного лица';
																	|en = 'Last name of contact person is not specified.'; fa = 'Last name of contact person is not specified.';
																	|it = 'Cognome della persona di contatto non indicato';
																	|pl = 'Nie wskazano nazwiska osoby do kontaktu';
																	|tr = 'İlgili kişinin soyadı belirtilmedi'"),OnlyPartnersAreUsed, "LastNameKL");
			Cancel = True;
		EndIf;
		
		If IsBlankString(KLName) Then
			PartnersAndCounterpartiesClient.OutputUserMessage(NStr("vi = 'Chưa chỉ ra tên người liên hệ';
																	|ru = 'Не указано имя контактного лица';
																	|en = 'Contact person name is not specified'; fa = 'Contact person name is not specified';
																	|it = 'Nome della persona di contatto non indicato';
																	|pl = 'Nie wskazano imienia osoby do kontaktu';
																	|tr = 'İlgili kişinin adı belirtilmedi'"),OnlyPartnersAreUsed, "KLName");
			Cancel = True;
		EndIf;
		
		If IsBlankString(PhoneNumberKL) And IsBlankString(EPCLAddress) And IsBlankString(MobilePhoneKL) Then
			PartnersAndCounterpartiesClient.OutputUserMessage(NStr("vi = 'Cần chỉ định ít nhất một thông tin liên lạc của người liên hệ';
																	|ru = 'Необходимо указать хотя бы одно значение контактной информации контактного лица';
																	|en = 'Specify at least one value for contact details of the contact person'; fa = 'Specify at least one value for contact details of the contact person';
																	|it = 'È necessario indicare almeno un valore dell''informazione di contatto della persona di contatto';
																	|pl = 'Należy wskazać chociażby jedną wartość danych kontaktowych osoby kontaktowej';
																	|tr = 'İlgili kişinin en az bir iletişim bilgisi değerini belirtmeniz gerekmektedir'"),OnlyPartnersAreUsed, "EPCLAddress");
			Cancel = True;
		EndIf;
		
	EndIf;
	
	If Not Cancel Then
		
		// checking the correctness of email addresses
		If  Not IsBlankString(EppartnerSAddress) And ThisIsACompany = 0 Then
			If TMCommonUseClientServer.CheckYourEmailAddress(EppartnerSAddress) Then
				PartnersAndCounterpartiesClient.OutputUserMessage(NStr("vi = 'Sai định dạng email của bạn hàng';
																		|ru = 'Неверный формат адреса электронной почты партнера';
																		|en = 'Incorrect format of partner''s email address'; fa = 'Incorrect format of partner''s email address';
																		|it = 'Formato della posta elettronica del partner non valido';
																		|pl = 'Nieprawidłowy format adresu poczty elektronicznej partnera';
																		|tr = 'Geçersiz iş ortağı e-posta adresi formatı'"), OnlyPartnersAreUsed, "EppartnerSAddress");
				Cancel = True;
			EndIf;
		EndIf;
		
		If  Not IsBlankString(EppartnerSAddressIndividual) And ThisIsACompany = 1 Then
			If TMCommonUseClientServer.CheckYourEmailAddress(EppartnerSAddressIndividual) Then
				PartnersAndCounterpartiesClient.OutputUserMessage(NStr("vi = 'Sai định dạng email của bạn hàng';
																		|ru = 'Неверный формат адреса электронной почты партнера';
																		|en = 'Incorrect format of partner''s email address'; fa = 'Incorrect format of partner''s email address';
																		|it = 'Formato della posta elettronica del partner non valido';
																		|pl = 'Nieprawidłowy format adresu poczty elektronicznej partnera';
																		|tr = 'Geçersiz iş ortağı e-posta adresi formatı'"), OnlyPartnersAreUsed, "EppartnerSAddressIndividual");
				Cancel = True;
			EndIf;
		EndIf;
		
		If  SpecifyTheContactPersonSDetails And Not IsBlankString(EPCLAddress) And ThisIsACompany = 0 Then
			If TMCommonUseClientServer.CheckYourEmailAddress(EPCLAddress) Then
				PartnersAndCounterpartiesClient.OutputUserMessage(NStr("vi = 'Sai định dạng email của người liên hệ';
																		|ru = 'Неверный формат адреса электронной почты контактного лица';
																		|en = 'Incorrect format of contact person''s email address'; fa = 'Incorrect format of contact person''s email address';
																		|it = 'Formato della posta elettronica della persona di contatto non valido';
																		|pl = 'Nieprawidłowy format adresu poczty elektronicznej osoby do kontaktu';
																		|tr = 'Geçersiz ilgili kişi e-posta adresi formatı'"), OnlyPartnersAreUsed, "EPCLAddress");
				Cancel = True;
			EndIf;
		EndIf;
		
		// Verification of the data of an individual
		If  ThisIsACompany = 1 And SpecifyLegalDetails And SpecifyTheIdentityDocument Then
			
			If Not IsBlankString(SeriesFromDocument) Then
				ErrorText = "";
				Cancel = Not PersonsClientServerTM.DocumentSeriesIsListedCorrectly(DocumentKind, SeriesFromDocument, ErrorText) Or Cancel;
				If Not IsBlankString(ErrorText) Then
					CommonClientServer.MessageToUser(ErrorText, , "SeriesFromDocument");
				EndIf;
			EndIf;
			
			If Not IsBlankString(DocumentNumber) Then
				ErrorText = "";
				Cancel = Not PersonsClientServerTM.DocumentNumberIsCorrect(DocumentKind, DocumentNumber, ErrorText) Or Cancel;
				If Not IsBlankString(ErrorText) Then
					CommonClientServer.MessageToUser(ErrorText, , "DocumentNumber");
				EndIf;
			EndIf;
			
		EndIf;
		
	EndIf;
	
	PartnersAndCounterpartiesLocalizationClient.PrimaryInformationIsFilledInIncorrectly(ThisObject, Cancel);
	Return Cancel;
	
EndFunction

&AtClient
Function AdditionalInformationFilledInIncorrectly()
	
	Cancel = False;
	ClearMessages();
	
	If ActionBasedOnResultsFound <> 0 Then
	
		If Not Client And Not Vendor And Not OtherRelations And Not Competitor Then
			PartnersAndCounterpartiesClient.OutputUserMessage(NStr("vi = 'Cần xác định ít nhất một kiểu mối quan hệ';
																	|ru = 'Необходимо определить хотя бы один тип отношений';
																	|en = 'You must define at least one type of relations'; fa = 'You must define at least one type of relations';
																	|it = 'Bisogna definire almeno un tipo di relazione';
																	|pl = 'Należy określić chociażby jeden typ stosunków';
																	|tr = 'En az bir ilişki tipi tanımlamanız gerekmektedir'"),OnlyPartnersAreUsed, "Client");
			Cancel = True;
		EndIf;
		
		If PartnerAccessGroupsAreUsed
		 And AccessGroup = PredefinedValue("Catalog.PartnerAccessGroups.EmptyRef") Then
			PartnersAndCounterpartiesClient.OutputUserMessage(NStr("vi = 'Cần chỉ định một nhóm truy cập';
																	|ru = 'Необходимо указать группу доступа';
																	|en = 'Specify access group'; fa = 'Specify access group';
																	|it = 'È necessario indicare un gruppo d''accesso';
																	|pl = 'Należy wskazać grupę dostępu';
																	|tr = 'Erişim grubunu belirtmeniz gerekmektedir'"),OnlyPartnersAreUsed, "AccessGroup");
			Cancel = True;
		EndIf;
		
		If IsBlankString(Name1) Then
			PartnersAndCounterpartiesClient.OutputUserMessage(NStr("vi = 'Cần chỉ định tên làm việc';
																	|ru = 'Необходимо указать рабочее наименование';
																	|en = 'Specify working title'; fa = 'Specify working title';
																	|it = 'È necessario indicare un nome lavorativo';
																	|pl = 'Należy wskazać nazwę roboczą';
																	|tr = 'İş ünvanını belirtmeniz gerekmektedir'"),OnlyPartnersAreUsed, "Name1");
			Cancel = True;
		EndIf;
	
	EndIf;
	
	If ThisIsACompany = 0 Then
	
		If SpecifyLegalDetails 
			And TheLegalAddressOfTheCounterpartyIsRequired
			And Not ValueIsFilled(LegalAddress) Then
			
			PartnersAndCounterpartiesClient.OutputUserMessage(NStr("vi = 'Cần chỉ định địa chỉ đăng ký';
																	|ru = 'Необходимо указать юридический адрес';
																	|en = 'Specify legal address'; fa = 'Specify legal address';
																	|it = 'È necessario indicare l''indirizzo giuridico';
																	|pl = 'Należy wskazać adres rejestrowy';
																	|tr = 'Yasal adres belirtmeniz gerekmektedir'"),OnlyPartnersAreUsed, "LegalAddress");
			Cancel = True;
			
		EndIf;
		
		If ((SpecifyLegalDetails And FactTheCounterpartySAddressIsRequired)
			Or (ActionBasedOnResultsFound <> 0 And ThePartnerSAddressIsRequired)) 
			And Not ValueIsFilled(ActualAddress) Then
			
			PartnersAndCounterpartiesClient.OutputUserMessage(NStr("vi = 'Cần chỉ định địa chỉ thực tế';
																	|ru = 'Необходимо указать фактический адрес';
																	|en = 'Specify business address'; fa = 'Specify business address';
																	|it = 'È necessario indicare l''indirizzo effettivo';
																	|pl = 'Należy wskazać adres fizyczny';
																	|tr = 'İş adresi belirtmeniz gerekmektedir'"),OnlyPartnersAreUsed, "ActualAddress");
			Cancel = True;
			
		EndIf;
		
	Else
		
		If AddressOfPrivatePersonIsRequired(ThisObject) Then
			
			PartnersAndCounterpartiesClient.OutputUserMessage(NStr("vi = 'Cần chỉ định địa chỉ cư trú';
																	|ru = 'Необходимо указать адрес проживания';
																	|en = 'Specify residential address'; fa = 'Specify residential address';
																	|it = 'È necessario indicare l''indirizzo di residenza';
																	|pl = 'Należy wskazać adres zamieszkania';
																	|tr = 'İkamet adresi belirtmeniz gerekmektedir'"), OnlyPartnersAreUsed, "LegalAddress");
			Cancel = True;
			
		EndIf;

		ContactDetailsForVerification = New Map;
		ContactDetailsForVerification.Insert(PredefinedValue("Enum.ContactInformationTypes.Email"), EppartnerSAddressIndividual);
		ContactDetailsForVerification.Insert(PredefinedValue("Enum.ContactInformationTypes.Phone"), PartnerSPhoneNumberIndividual);
		RetailSalesClientServer.CheckIndicationOfPartnerSContactDetails(OptionOfSendingElectronicReceipt, ContactDetailsForVerification, Cancel);
				
	EndIf;
	
	Return Cancel;
	
EndFunction

&AtServer
Function AdditionalDetailsFilledInIncorrectly()

	Cancel = False;
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, New Array, PartnerTheObjectOfAdditionalDetails);
	
	Return Cancel;

EndFunction

&AtClient
Function InformationOfHeadCounterpartyIsFilledInIncorrectly()
	
	Cancel = False;
	ClearMessages();
	
	If SelectTheHeadCounterparty = 1 Then
		
		If IsBlankString(FullNameOfTheHeadCounterparty) Then
			PartnersAndCounterpartiesClient.OutputUserMessage(NStr("vi = 'Chưa chỉ ra tên viết tắt pháp nhân';
																	|ru = 'Не указано сокращенное юр. наименование';
																	|en = 'Abbreviated company name is not specified'; fa = 'Abbreviated company name is not specified';
																	|it = 'Nome giuridico abbreviato non indicato';
																	|pl = 'Nie wskazano skróconej nazwy prawnej';
																	|tr = 'Kısaltılmış yasal adı belirtilmedi'"), OnlyPartnersAreUsed, "FullNameOfTheHeadCounterparty");
			Cancel = True;
		EndIf;
	EndIf;
	PartnersAndCounterpartiesLocalizationClient.InformationOfHeadCounterpartyIsFilledInIncorrectly(ThisObject, Cancel);
	Return Cancel;
	
EndFunction

&AtClient
Function CurrentAccountFilledInIncorrectly()
	
	Cancel = False;
	ClearMessages();
	
	If SpecifyTheCounterpartySBankAccount Then
		
		If IsBlankString(AccountNumber) Then
			PartnersAndCounterpartiesClient.OutputUserMessage(NStr("vi = 'Cần chỉ ra số tài khoản ngân hàng';
																	|ru = 'Необходимо указать номер банковского счета';
																	|en = 'You must specify bank account number'; fa = 'You must specify bank account number';
																	|it = 'È necessario indicare il numero del conto bancario';
																	|pl = 'Należy wskazać numer rachunku bankowego';
																	|tr = 'Banka hesap numarasını belirtmeniz gerekmektedir'"), OnlyPartnersAreUsed, "AccountNumber");
			Cancel = True;
		EndIf;
		
		If Not ValueIsFilled(CashCurrency) Then
			
			MessageText = NStr("vi = 'Trong hệ thống chưa chỉ ra ""Tiền tệ cơ sở mặc định"". Để tùy chỉnh, cần chuyển đến phân hệ ""Danh mục và quản trị""-""Công ty""-""Tiền tệ"".';
								|ru = 'В системе не указана ""Базовая валюта по умолчанию"". Для настройки необходимо перейти в раздел ""НСИ и администрирование""-""Предприятие""-""Валюты"".';
								|en = '""Default base currency"" is not specified in the system. To set it up, go to """"Master data and settings"" - ""Enterprise"" - ""Currencies"".'; fa = '""Default base currency"" is not specified in the system. To set it up, go to """"Master data and settings"" - ""Enterprise"" - ""Currencies"".';
								|it = 'Nel sistema non è indicata la ""Valuta di riferimento da impostazione predefinita"". Per impostarla andare alla sezione ""informazioni di riferimento e normative e amministrazione""-""Impresa""-""Valute"".';
								|pl = 'W systemie nie jest określona ""Podstawowa waluta domyślna"". W celu ustawienia należy przejść do sekcji  ""Ustawienia""-""Przedsiębiorstwo""-""Waluty"".';
								|tr = 'Sistemde ""Varsayılan Temel Para Birimi"" belirtilmedi. Ayarlar için ""Master veri ve yönetim""-""İşletme""-""Para Birimleri"" bölümüne gitmeniz gerekmektedir.'");
			
			
			PartnersAndCounterpartiesClient.OutputUserMessage(MessageText, OnlyPartnersAreUsed, "CashCurrency");
			Cancel = True;
			
		EndIf;
		
		If IsBlankString(BankBIC) And Not ForeignBank Then
			PartnersAndCounterpartiesClient.OutputUserMessage(NStr("vi = 'Cần chỉ ra mã ngân hàng';
																	|ru = 'Необходимо указать БИК банка';
																	|en = 'Specify bank code'; fa = 'Specify bank code';
																	|it = 'È necessario indicare il RCBIC della banca';
																	|pl = 'Należy wskazać BIC banku';
																	|tr = 'Banka BIC kodunu belirtmeniz gerekmektedir'"), OnlyPartnersAreUsed, "BankBIC");
			Cancel = True;
		EndIf;
		
		If SettlementBankUsed Then
			
			If IsBlankString(TransferBankBIC)
				And Not ForeignBank
				And Not (CashCurrency <> CurrencyOfComplianceAccounting) Then
				PartnersAndCounterpartiesClient.OutputUserMessage(NStr("vi = 'Cần chỉ ra mã ngân hàng để hạch toán';
																		|ru = 'Необходимо указать БИК банка для расчетов';
																		|en = 'Specify bank code of the bank for payments'; fa = 'Specify bank code of the bank for payments';
																		|it = 'È necessario indicare il RCBIC della banca per i conti';
																		|pl = 'Należy wskazać BIC banku do rozliczeń';
																		|tr = 'Ödemeler için banka BIC kodunu belirtmeniz gerekmektedir'"), OnlyPartnersAreUsed, "TransferBankBIC");
				Cancel = True;
			EndIf;
			
		EndIf;
		
	EndIf;
	
	Return Cancel;
	
EndFunction

&AtClient
Function SettlementAccountOfHeadCounterpartyIsFilledInIncorrectly()
	
	Cancel = False;
	ClearMessages();
	
	If SpecifyTheBankAccountOfTheMainCounterparty Then
		
		If IsBlankString(AccountNumberHeadCounterparty) Then
			PartnersAndCounterpartiesClient.OutputUserMessage(NStr("vi = 'Cần chỉ ra số tài khoản ngân hàng';
																	|ru = 'Необходимо указать номер банковского счета';
																	|en = 'You must specify bank account number'; fa = 'You must specify bank account number';
																	|it = 'È necessario indicare il numero del conto bancario';
																	|pl = 'Należy wskazać numer rachunku bankowego';
																	|tr = 'Banka hesap numarasını belirtmeniz gerekmektedir'"), OnlyPartnersAreUsed, "AccountNumberHeadCounterparty");
			Cancel = True;
		EndIf;
		
		If Not ValueIsFilled(CurrencyOfCashHeadCounterparty) Then
			PartnersAndCounterpartiesClient.OutputUserMessage(NStr("vi = 'Cần chỉ ra tiền tệ';
																	|ru = 'Необходимо указать валюту денежных средств';
																	|en = 'You must specify currency'; fa = 'You must specify currency';
																	|it = 'È necessario indicare la valuta dei fondi monetari';
																	|pl = 'Należy wskazać walutę środków pieniężnych';
																	|tr = 'Nakit para birimini belirtmeniz gerekmektedir'"), OnlyPartnersAreUsed, "CurrencyOfCashHeadCounterparty");
			Cancel = True;
		EndIf;
		
		If IsBlankString(BikbankParentCounterparty) And Not ForeignBankHeadCounterparty Then
			PartnersAndCounterpartiesClient.OutputUserMessage(NStr("vi = 'Cần chỉ ra mã ngân hàng';
																	|ru = 'Необходимо указать БИК банка';
																	|en = 'Specify bank code'; fa = 'Specify bank code';
																	|it = 'È necessario indicare il RCBIC della banca';
																	|pl = 'Należy wskazać BIC banku';
																	|tr = 'Banka BIC kodunu belirtmeniz gerekmektedir'"), OnlyPartnersAreUsed, "BikbankParentCounterparty");
			Cancel = True;
		EndIf;
		
		If UsedByTheBankForSettlementsHeadCounterparty Then
			
			If IsBlankString(BikbankForSettlementsHeadCounterparty)
				And Not ForeignBankHeadCounterparty
				And Not (CurrencyOfCashHeadCounterparty <> CurrencyOfComplianceAccounting) Then
				PartnersAndCounterpartiesClient.OutputUserMessage(NStr("vi = 'Cần chỉ ra mã ngân hàng để hạch toán';
																		|ru = 'Необходимо указать БИК банка для расчетов';
																		|en = 'Specify bank code of the settlements bank'; fa = 'Specify bank code of the settlements bank';
																		|it = 'È necessario indicare il RCBIC della banca per i conti';
																		|pl = 'Należy wskazać BIC banku do rozliczeń';
																		|tr = 'Ödemeler için banka BIC kodunu belirtmeniz gerekmektedir'"), OnlyPartnersAreUsed, "BikbankForSettlementsHeadCounterparty");
				Cancel = True;
			EndIf;
			
		EndIf;
		
	EndIf;
	
	Return Cancel;
	
EndFunction

#EndRegion

#Region Other

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.EPCLAddress.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PhoneNumberKL.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.MobilePhoneKL.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SpecifyTheContactPersonSDetails");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PhoneNumberKL");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("MobilePhoneKL");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("EPCLAddress");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	Item.Appearance.SetParameterValue("MarkIncomplete", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.KLName.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SpecifyTheContactPersonSDetails");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("KLName");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	Item.Appearance.SetParameterValue("MarkIncomplete", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.LastNameKL.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SpecifyTheContactPersonSDetails");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("LastNameKL");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	Item.Appearance.SetParameterValue("MarkIncomplete", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.EppartnerSAddressIndividual.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PartnerSPhoneNumberIndividual.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ThisIsACompany");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 1;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("EppartnerSAddressIndividual");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PartnerSPhoneNumberIndividual");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	Item.Appearance.SetParameterValue("MarkIncomplete", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.EppartnerSAddress.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PartnerSPhoneNumber.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ThisIsACompany");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("EppartnerSAddress");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PartnerSPhoneNumber");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SpecifyTheContactPersonSDetails");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	FilterGroup2 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SpecifyTheContactPersonSDetails");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PhoneNumberKL");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;

	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("MobilePhoneKL");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;

	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("EPCLAddress");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	Item.Appearance.SetParameterValue("MarkIncomplete", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AccessGroup.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PartnerAccessGroupsAreUsed");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AccessGroup");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Catalogs.PartnerAccessGroups.EmptyRef();

	Item.Appearance.SetParameterValue("MarkIncomplete", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AccountNumber.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SpecifyTheCounterpartySBankAccount");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AccountNumber");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CashCurrency.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("CashCurrency");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SpecifyTheCounterpartySBankAccount");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("MarkIncomplete", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AccountNumberHeadCounterparty.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SpecifyTheBankAccountOfTheMainCounterparty");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AccountNumberHeadCounterparty");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CurrencyOfCashHeadCounterparty.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("CurrencyOfCashHeadCounterparty");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SpecifyTheBankAccountOfTheMainCounterparty");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("MarkIncomplete", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.EppartnerAddressPartnersOnly.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PartnerSPhoneNumberPartnersOnly.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ThisIsACompany");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("EppartnerSAddress");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PartnerSPhoneNumber");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SpecifyTheContactPersonSDetails");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	FilterGroup2 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("MobilePhoneKL");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;

	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PhoneNumberKL");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;

	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("EPCLAddress");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;

	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SpecifyTheContactPersonSDetails");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("MarkIncomplete", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DocumentKind.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ThisIsACompany");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 1;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SpecifyLegalDetails");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SpecifyTheIdentityDocument");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DocumentKind");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("MarkIncomplete", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AbbreviatedLegalEntityNameOfTheCounterparty.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("BasedOnTheCounterparty");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("MarkIncomplete", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PartnerComparisonTreeValueOfFound.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PartnerComparisonTree.Difference");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("BackColor", StyleColors.FieldWithAnErrorBackground);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PartnerComparisonTreeValueOfFound.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PartnerComparisonTree.Coincidence");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("BackColor", StyleColors.BackgroundColorIsFullyProvided);

	PartnersAndCounterpartiesLocalization.SetConditionalAppearance_ForNew(ThisObject);

EndProcedure

&AtServer
Procedure WhenCreatingNewRetailBuyer()
	
	BasedOnRetailCustomerData = True;
	ThisIsACompany = 1;
	Client = True;
	
	Items.ThisIsACompany.Visible = False;
	Items.DecorationPrimaryInformationDownload.Visible = False;
	Items.ThePageWillBeCreated.CurrentPage = Items.PagePartnerWillBeCreated;
	Items.TheGroupTypeOfRelationship.Visible = False;
	Items.GroupIndividualCounterparty.Visible =False;
	Title = NStr("vi = 'Trợ giúp ghi nhận khách lẻ mới';
				|ru = 'Помощник регистрации нового розничного покупателя';
				|en = 'New retail customer registration wizard'; fa = 'New retail customer registration wizard';
				|it = 'Aiutante di registrazione di un nuovo compratore al dettaglio';
				|pl = 'Asystent rejestracji nowego klienta detalicznego';
				|tr = 'Yeni perakende müşteri kayıt sihirbazı'");
	Items.ActionBasedOnResultsFound.ChoiceList[0].Presentation = NStr("vi = 'Không ghi nhận khách lẻ mới, nên sử dụng khách lẻ đã tìm thấy';
																		|ru = 'Не регистрировать нового розничного покупателя, использовать найденного';
																		|en = 'Do not register a new retail customer, use a found one'; fa = 'Do not register a new retail customer, use a found one';
																		|it = 'Non registrare un nuovo compratore al dettaglio, usare quello trovato';
																		|pl = 'Nie rejestruj nowego klienta detalicznego, używaj znalezionego';
																		|tr = 'Yeni perakende müşteriyi kaydetme, bulunanı kullan'");
	Items.ActionBasedOnResultsFound.ChoiceList[1].Presentation = NStr("vi = 'Tiếp tục ghi nhận khách lẻ và đưa vào trực thuộc khách lẻ được tìm thấy';
																		|ru = 'Продолжить регистрацию розничного покупателя и подчинить найденному';
																		|en = 'Continue retail customer registration and make it subordinate to the found one'; fa = 'Continue retail customer registration and make it subordinate to the found one';
																		|it = 'Continuare con la registrazione del compratore al dettaglio e subordinarlo a quello trovato';
																		|pl = 'Kontynuuj rejestrację klienta detalicznego i podporządkuj go znalezionemu';
																		|tr = 'Perakende müşteri kaydına devam et ve bulunana bağımlı kıl'");
	Items.ActionBasedOnResultsFound.ChoiceList[2].Presentation = NStr("vi = 'Tiếp tục ghi nhận khách lẻ mới';
																		|ru = 'Продолжить регистрацию нового розничного покупателя';
																		|en = 'Continue registering the new retail customer'; fa = 'Continue registering the new retail customer';
																		|it = 'Continuare con la registrazione del nuovo compratore al dettaglio';
																		|pl = 'Kontynuuj rejestrację nowego klienta detalicznego';
																		|tr = 'Yeni perakende müşteri kaydına devam et'");
	
EndProcedure

&AtServer
Procedure WhenCreatingNewHeadCounterparty()
	
	BasedOnASeparateCounterparty = True;
	
	CounterpartyFoundation = Parameters.BasisSeparateCounterparty;
	
	ItemArray = New Array;
	ItemArray.Add("DecorationPrimaryInformationDownload");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Visible", False);
	
	ItemArray = New Array;
	ItemArray.Add("ThisIsACompany");
	ItemArray.Add("GroupTypeOfCompany");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "ReadOnly", True);
	
	PartnersAndCounterpartiesLocalization.WhenCreatingNewHeadCounterparty(ThisObject);
EndProcedure

&AtClientAtServerNoContext
Function FIO_OneLine(LastName,Name,MiddleName)
	
	Return TrimAll(TrimAll(LastName) + " " + TrimAll(Name) + " " + TrimAll(MiddleName));
	
EndFunction

&AtServer
Function PresentationOfDocumentOfIndividual()
	
	PresentationOfPersonDocument = "";
	
	If Not DocumentKind.IsEmpty() Then
		
		PresentationOfPersonDocument = ""
			+ DocumentKind
			+ ?(ValueIsFilled(SeriesFromDocument),
				StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = ', sê-ri: %1';
																				|ru = ', серия: %1';
																				|en = ', batch: %1'; fa = ', batch: %1';
																				|it = ', serie: %1';
																				|pl = ', seria: %1';
																				|tr = ', parti: %1'"), SeriesFromDocument), "")
			+ ?(ValueIsFilled(DocumentNumber),
				StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = ', Số %1';
																				|ru = ', № %1';
																				|en = ', No.%1'; fa = ', No.%1';
																				|it = ', № %1';
																				|pl = ', nr %1';
																				|tr = ', No %1'"), DocumentNumber), "")
			+ ?(ValueIsFilled(DateOfIssue1),
				StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = ', ngày cấp: %1';
																				|ru = ', выдан: %1 года';
																				|en = ', issued: %1'; fa = ', issued: %1';
																				|it = ', rilasciato nell''anno %1';
																				|pl = ', wydany: %1 roku';
																				|tr = ', veriliş: %1 yılı'"), Format(DateOfIssue1,"DLF=DD")), "")
			+ ?(ValueIsFilled(ValidityPeriod),
				StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = ', có giá trị đến: %1';
																				|ru = ', действует до: %1 года';
																				|en = ', valid till: %1'; fa = ', valid till: %1';
																				|it = ', valido fino all''anno %1';
																				|pl = ', ważny do: %1 roku';
																				|tr = ', geçerlilik sonu: %1 yılı'"), Format(ValidityPeriod,"DLF=DD")), "")
			+ ?(ValueIsFilled(WhoIssuedDocument), ", " + WhoIssuedDocument, "");
				
		
	EndIf;
	
	Return PresentationOfPersonDocument;
	
EndFunction

&AtServer
Procedure FillInListOfSelectingHeadCounterparty()
	
	PartnersAndCounterpartiesLocalization.FillInListOfSelectingHeadCounterparty(ThisObject);
	
EndProcedure

&AtClient
Procedure FillInPartnerSelectionListOfHeadCounterparty()
	
	ChoiceList = Items.PartnerOfTheHeadCounterparty.ChoiceList;
	ChoiceList.Clear();
	
	If ActionBasedOnResultsFound = 0 Then
		SearchForHierarchyByPartner = PartnerChoice;
	Else
		ChoiceList.Add(
			PredefinedValue("Catalog.Partners.EmptyRef"),
			NStr("vi = '<bạn hàng tạo mới>';
				|ru = '<создаваемый партнер>';
				|en = '<created partner>'; fa = '<created partner>';
				|it = '<partner in corso di creazione>';
				|pl = '<tworzony partner>';
				|tr = '<oluşturulan iş ortağı>'"));
		SearchForHierarchyByPartner = Parent;
	EndIf;
	
	If ValueIsFilled(SearchForHierarchyByPartner) Then
		
		PartnerList = ListOfPossiblePartnersHeadContractors(SearchForHierarchyByPartner);
		
		For Each Item In PartnerList Do
			ChoiceList.Add(Item.Value, Item.Presentation);
		EndDo;
		
	EndIf;
	
	ListSize = ChoiceList.Count();
	
	If ListSize = 1 Then
		PartnerOfTheHeadCounterparty = ChoiceList[0].Value;
	ElsIf ListSize = 0
			Or (ValueIsFilled(PartnerOfTheHeadCounterparty)
				And ChoiceList.FindByValue(PartnerOfTheHeadCounterparty) = Undefined) Then
		PartnerOfTheHeadCounterparty = Undefined;
	EndIf;
	
EndProcedure

&AtServerNoContext
Function ListOfPossiblePartnersHeadContractors(Partner)
	
	List = New ValueList;
	PartnersAndCounterparties.FillInListOfPartnersWithParents(Partner, List);
	
	Return List;
	
EndFunction

&AtServer
Procedure SearchForUnboundDetachedUnits()
	
	PartnersAndCounterpartiesLocalization.SearchForUnboundDetachedUnits(ThisObject);
	
EndProcedure

&AtClient
Procedure FillInPartnerComparisonTree()
	
	CurrentData = Items.TableFound.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If CurrentData.Partner <> CurrentFoundPartner Then
	
		PartnerNode_ = DataTreeOfFoundPartners.FindByID(CurrentData.IDOfTheDataTree);
		PartnerNodeElements = PartnerNode_.GetItems();
		
		ComparisonTreeElements = PartnerComparisonTree.GetItems();
		ComparisonTreeElements.Clear();
		
		CopyFormTreeDataNode(ComparisonTreeElements, PartnerNodeElements);
		
		// expand all
		For Each TreeItem In ComparisonTreeElements Do
			Items.PartnerComparisonTree.Expand(TreeItem.GetID());
		EndDo;
		
		CurrentFoundPartner = CurrentData.Partner;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CopyFormTreeDataNode(Receiver, Source)
	
	For Each SourceNode_ In Source Do
		
		ReceiverNode_ = Receiver.Add();
		FillPropertyValues(ReceiverNode_, SourceNode_);
		
		SourceItems = SourceNode_.GetItems();
		
		If SourceItems.Count() > 0 Then
			CopyFormTreeDataNode(ReceiverNode_.GetItems(), SourceItems);
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure RecordPartnerAndRelatedData(ListOfCreated)
	
	If ActionBasedOnResultsFound <> 0 Then
		
		//Partner
		PartnerObject = Catalogs.Partners.CreateItem();
		PartnerObject.Description                          = Name1;
		PartnerObject.DescriptionLanguage1                     = PartnerTheObjectOfAdditionalDetails.DescriptionLanguage1;
		PartnerObject.DescriptionLanguage2                     = PartnerTheObjectOfAdditionalDetails.DescriptionLanguage2;
		PartnerObject.Parent                              = Parent;
		PartnerObject.BusinessRegion                          = BusinessRegion;
		PartnerObject.AccessGroup                         = AccessGroup;
		PartnerObject.RegistrationDate                       = CurrentSessionDate();
		PartnerObject.Client                                = Client;
		PartnerObject.Competitor                             = Competitor;
		PartnerObject.Vendor                             = Vendor;
		PartnerObject.ServedBySalesRepresentatives = ServedBySalesRepresentatives;
		PartnerObject.OtherRelations                       = OtherRelations;
		PartnerObject.MainManager                      = MainManager;
		PartnerObject.DescriptionFull                    = PartnerName();
		PartnerObject.LegalEntityIndividual                             = PartnerSLegalEntityType(ThisIsACompany);
		PartnerObject.Gender                                   = Gender;
		PartnerObject.BirthDate                          = BirthDate;
		PartnerObject.Carrier                            = Carrier;
		PartnerObject.OptionOfSendingElectronicReceipt       = OptionOfSendingElectronicReceipt;
		
		// partner's contact information
		If Not IsBlankString(ActualAddress) Then
			NewCIRow = PartnerObject.ContactInformation.Add();
			NewCIRow.Type               = Enums.ContactInformationTypes.Address;
			NewCIRow.Kind               = Catalogs.ContactInformationKinds.PartnerAddress;
			NewCIRow.Presentation     = ActualAddress;
			NewCIRow.FieldValues     = PhysicalAddressFieldValues;
			NewCIRow.Value          = JSONContactInformationValueServer("PhysicalAddressFieldValues");
		EndIf;
		
		If ThisIsACompany = 0 Then
			BankingDetailsNamePhoneNumber = "PartnerSPhoneNumber";
			BankingDetailsNamePhoneNumberFieldValues = "PartnerPhoneFieldValues";
			PropsNameItemInstanceAddress = "EppartnerSAddress";
		Else
			BankingDetailsNamePhoneNumber = "PartnerSPhoneNumberIndividual";
			BankingDetailsNamePhoneNumberFieldValues = "PartnerSPhoneNumberIndividualFieldValues";
			PropsNameItemInstanceAddress = "EppartnerSAddressIndividual";
		EndIf;
		
		If FieldValuesInListOfValues(ThisObject[BankingDetailsNamePhoneNumberFieldValues]).Count()> 0 Then
			NewCIRow = PartnerObject.ContactInformation.Add();
			NewCIRow.Type               = Enums.ContactInformationTypes.Phone;
			NewCIRow.Kind               = Catalogs.ContactInformationKinds.PartnerSPhoneNumber;
			NewCIRow.Presentation     = ThisObject[BankingDetailsNamePhoneNumber];
			NewCIRow.FieldValues     = ThisObject[BankingDetailsNamePhoneNumberFieldValues];
			NewCIRow.Value          = JSONContactInformationValueServer(BankingDetailsNamePhoneNumberFieldValues);
		EndIf;
		
		If Not IsBlankString(ThisObject[PropsNameItemInstanceAddress]) Then
			NewCIRow = PartnerObject.ContactInformation.Add();
			NewCIRow.Type               = Enums.ContactInformationTypes.Email;
			NewCIRow.Kind               = Catalogs.ContactInformationKinds.EmailPartner_;
			NewCIRow.Presentation     = ThisObject[PropsNameItemInstanceAddress];
			NewCIRow.Value     		= ContactsManager.ContactsByPresentation(NewCIRow.Presentation, NewCIRow.Kind);
			NewCIRow.FieldValues     = ContactsManager.ContactInformationToXML(NewCIRow.Value, NewCIRow.Presentation, NewCIRow.Kind);
			NewCIRow.EMAddress           = ThisObject[PropsNameItemInstanceAddress];
			Pos = StrFind(ThisObject[PropsNameItemInstanceAddress], "@");
			If Pos <> 0 Then
				NewCIRow.ServerDomainName = Mid(ThisObject[PropsNameItemInstanceAddress], Pos+1);
			EndIf;
		EndIf;
		
		// StandardSubsystems.Properties
		PropertyManager.BeforeWriteAtServer(ThisObject, PartnerTheObjectOfAdditionalDetails);
		PartnerObject.AdditionalAttributes.Load(PartnerTheObjectOfAdditionalDetails.AdditionalAttributes.Unload());
		// End StandardSubsystems.Properties
		
		// Delivery Zone
		If ValueIsFilled(DeliveryZone)
		   And DeliveryZoneIsAvailable(ThisObject) Then
			
			If GoodsDeliveryClientServer.UsedDelivery20() Then
				
				PartnerObject.DeliveryZone = DeliveryZone;
				
			EndIf;
			
			PartnerObject.AdditionalProperties.Insert("DeliveryZone", DeliveryZone);
			
		EndIf;
		
		PartnerObject.Write();
		PartnerChoice = PartnerObject.Ref;
		ListOfCreated.Add(GetURL(PartnerChoice), PartnerObject.Description);
		
		// fix primary interest
		If GetFunctionalOption("RecordInitialRequest") And ValueIsFilled(ChannelOfInitialRequest) Then
		
			SetPrivilegedMode(True);
			Record = InformationRegisters.SourcesOfInitialRequests.CreateRecordManager();
			Record.Partner                    = PartnerChoice;
			Record.ChannelOfInitialRequest    = ChannelOfInitialRequest;
			Record.SourceOfInitialRequest = SourceOfInitialRequest;
			Record.Write();
			SetPrivilegedMode(False);
		
		EndIf;
		
		//Segment
		If ValueIsFilled(Segment)
			And YouHaveTheRightToIncludeItInTheSegment
			And Common.ObjectAttributeValue(Segment, "GenerationMethod") = Enums.SegmentGenerationMethods.GenerateManually Then
			SegmentsServer.AddPartnerToSegment(Segment, PartnerChoice);
		EndIf;
		
		// Contact person
		If ThisIsACompany = 0 And SpecifyTheContactPersonSDetails And Not IsBlankString(LastNameKL) Then
		
			ObjectContactPerson = Catalogs.ContactPersonsForPartners.CreateItem();
			ObjectContactPerson.Owner               = PartnerChoice;
			ObjectContactPerson.RelationRegistrationDate   = CurrentSessionDate();
			ObjectContactPerson.Description           = FIO_OneLine(LastNameKL, KLName, PatronymicKL);
			ObjectContactPerson.Author                  = Users.CurrentUser();
			If Not Role.IsEmpty() Then
				RoleRow = ObjectContactPerson.ContactPersonRoles.Add();
				RoleRow.ContactRole = Role;
			EndIf;
			
			If Not IsBlankString(EPCLAddress) Then
				NewCIRow = ObjectContactPerson.ContactInformation.Add();
				NewCIRow.Type               = Enums.ContactInformationTypes.Email;
				NewCIRow.Kind               = Catalogs.ContactInformationKinds.EmailContactPerson;
				NewCIRow.Presentation     = EPCLAddress;
				NewCIRow.Value		    = ContactsManager.ContactsByPresentation(NewCIRow.Presentation, NewCIRow.Kind);
				NewCIRow.FieldValues     = ContactsManager.ContactInformationToXML(NewCIRow.Value, NewCIRow.Presentation, NewCIRow.Kind);
				NewCIRow.EMAddress           = EPCLAddress;
				Pos = StrFind(EPCLAddress, "@");
				If Pos <> 0 Then
					NewCIRow.ServerDomainName = Mid(EPCLAddress, Pos+1);
				EndIf;
			EndIf;
			
			If FieldValuesInListOfValues(PhoneNumberOfFieldValues).Count()> 0 Then
				NewCIRow = ObjectContactPerson.ContactInformation.Add();
				NewCIRow.Type               = Enums.ContactInformationTypes.Phone;
				NewCIRow.Kind               = Catalogs.ContactInformationKinds.ContactPersonSPhoneNumber;
				NewCIRow.Presentation     = PhoneNumberKL;
				NewCIRow.FieldValues     = PhoneNumberOfFieldValues;
				NewCIRow.Value          = JSONContactInformationValueServer("PhoneNumberOfFieldValues");
			EndIf;
			
			If FieldValuesInListOfValues(MobilePhoneNumberFieldValues).Count()> 0 Then
				NewCIRow = ObjectContactPerson.ContactInformation.Add();
				NewCIRow.Type               = Enums.ContactInformationTypes.Phone;
				NewCIRow.Kind               = Catalogs.ContactInformationKinds.ContactPersonSMobilePhoneNumber;
				NewCIRow.Presentation     = MobilePhoneKL;
				NewCIRow.FieldValues     = MobilePhoneNumberFieldValues;
				NewCIRow.Value          = JSONContactInformationValueServer("MobilePhoneNumberFieldValues");
			EndIf;
			
			ObjectContactPerson.Write();
			ListOfCreated.Add(GetURL(ObjectContactPerson.Ref), ObjectContactPerson.Description);
			
		EndIf;
		
	EndIf;
	
	//Counterparty
	If OnlyPartnersAreUsed Or (ActionWithTheCounterparty = 1 And Not BasedOnTheCounterparty And SpecifyLegalDetails) Then
		
		CounterpartyObject_ = Catalogs.Counterparties.CreateItem();
		CounterpartyObject_.Description          = ?(OnlyPartnersAreUsed, Name1, NameOfTheCounterparty());
		CounterpartyObject_.DescriptionLanguage1     = CounterpartyForInternationalAttributes.DescriptionLanguage1;
		CounterpartyObject_.DescriptionLanguage2     = CounterpartyForInternationalAttributes.DescriptionLanguage2;
		CounterpartyObject_.LegalEntityIndividual             = PartnersAndCounterpartiesLocalizationClientServer.CounterpartySLegalEntityType(ThisIsACompany, TypeOfCompany);
		CounterpartyObject_.Partner               = PartnerChoice;
		CounterpartyObject_.RegistrationCountry     = RegistrationCountry;
		CounterpartyObject_.DescriptionFull    = ?(ThisIsACompany = 0,FullLegalName,FIO_OneLine(PartnerSLastName, PartnerName_3, PartnerSMiddleName));
		CounterpartyObject_.RegistrationNumber  = ?(CounterpartyObject_.LegalEntityIndividual = Enums.LegalEntityIndividual.LegalEntityNonResident, RegistrationNumber, "");
		CounterpartyObject_.TaxNumber        = ?(CounterpartyObject_.LegalEntityIndividual = Enums.LegalEntityIndividual.LegalEntityNonResident, TaxNumber, "");
		CounterpartyObject_.TIN                   = TIN;
		
		CounterpartyObject_.NameHistory.Load(NameHistory.Unload());
		PartnersAndCounterpartiesLocalization.AddCounterpartyDataWhenRecording(CounterpartyObject_, ThisObject);
		
		// contact information of the counterparty
		If Not IsBlankString(ActualAddress) Then
			NewCIRow = CounterpartyObject_.ContactInformation.Add();
			NewCIRow.Type           = Enums.ContactInformationTypes.Address;
			NewCIRow.Kind           = Catalogs.ContactInformationKinds.ActualDataCounterpartyAddress;
			NewCIRow.Presentation = ActualAddress;
			NewCIRow.FieldValues = PhysicalAddressFieldValues;
			NewCIRow.Value      = JSONContactInformationValueServer("PhysicalAddressFieldValues");
			
			If ThisIsACompany = 1
				And TheLegalAddressOfTheCounterpartyIsRequired Then
				
				NewCIRow = CounterpartyObject_.ContactInformation.Add();
				NewCIRow.Type           = Enums.ContactInformationTypes.Address;
				NewCIRow.Kind           = Catalogs.ContactInformationKinds.LegalAddressOfCounterparty;
				NewCIRow.Presentation = ActualAddress;
				NewCIRow.FieldValues = PhysicalAddressFieldValues;
				NewCIRow.Value      = JSONContactInformationValueServer("PhysicalAddressFieldValues");
				
			EndIf;
			
		EndIf;
		
		If ContactInformationHistory.Count() > 0 Then
			PartnersAndCounterparties.EnableChangeHistoryStorage("LegalAddressOfCounterparty");
			ContactInformationHistory[0].Date = Undefined;
			ContactsManager.SetObjectContactInformation(CounterpartyObject_, ContactInformationHistory);
		ElsIf Not IsBlankString(LegalAddress) Then
			NewCIRow = CounterpartyObject_.ContactInformation.Add();
			NewCIRow.Type           = Enums.ContactInformationTypes.Address;
			NewCIRow.Kind           = Catalogs.ContactInformationKinds.LegalAddressOfCounterparty;
			NewCIRow.Presentation = LegalAddress;
			NewCIRow.FieldValues = LegalAddressFieldValues;
			NewCIRow.Value      = JSONContactInformationValueServer("LegalAddressFieldValues");
		EndIf;
		
		If ThisIsACompany = 0 And Not IsBlankString(PartnerSPhoneNumber) Then
			
			If OnlyPartnersAreUsed Then
			
				NewCIRow = CounterpartyObject_.ContactInformation.Add();
				NewCIRow.Type           = Enums.ContactInformationTypes.Phone;
				NewCIRow.Kind           = Catalogs.ContactInformationKinds.CounterpartySPhoneNumber;
				NewCIRow.Presentation = PartnerSPhoneNumber;
				NewCIRow.FieldValues = PartnerPhoneFieldValues;
				NewCIRow.Value      = JSONContactInformationValueServer("PartnerPhoneFieldValues");
			EndIf;
			
		EndIf;
		
		
		If ThisIsACompany = 1 And Not IsBlankString(PartnerSPhoneNumberIndividual) Then
			NewCIRow = CounterpartyObject_.ContactInformation.Add();
			NewCIRow.Type           = Enums.ContactInformationTypes.Phone;
			NewCIRow.Kind           = Catalogs.ContactInformationKinds.CounterpartySPhoneNumber;
			NewCIRow.Presentation = PartnerSPhoneNumberIndividual;
			NewCIRow.FieldValues = PartnerSPhoneNumberIndividualFieldValues;
			NewCIRow.Value      = JSONContactInformationValueServer("PartnerSPhoneNumberIndividualFieldValues");
		EndIf;
		
		// head counterparty
		If ThisIsACompany = 0 And TypeOfCompany = 3 Then
			
			CounterpartyObject_.BranchOffice = True;
			
			If OnlyPartnersAreUsed Or SelectTheHeadCounterparty = 0 Then
				CounterpartyObject_.MainCounterparty = MainCounterparty;
			ElsIf SelectTheHeadCounterparty = 1 Then
				
				HeadCounterpartyObject = Catalogs.Counterparties.CreateItem();
				
				HeadCounterpartyObject.Description       = NameHeadCounterparty;
				HeadCounterpartyObject.DescriptionFull = FullNameOfTheHeadCounterparty;
				HeadCounterpartyObject.LegalEntityIndividual          = Enums.LegalEntityIndividual.Entity;
				HeadCounterpartyObject.TIN                = TIN;
				PartnersAndCounterpartiesLocalization.AddDataOfHeadCounterpartyWhenRecording(HeadCounterpartyObject, ThisObject);
				
				HeadCounterpartyObject.Partner = ?(ValueIsFilled(PartnerOfTheHeadCounterparty),
					PartnerOfTheHeadCounterparty, PartnerChoice);
				
				// contact information of the head counterparty
				If Not IsBlankString(ActualAddressOfTheHeadCounterparty) Then
					NewCIRow = HeadCounterpartyObject.ContactInformation.Add();
					NewCIRow.Type           = Enums.ContactInformationTypes.Address;
					NewCIRow.Kind           = Catalogs.ContactInformationKinds.ActualDataCounterpartyAddress;
					NewCIRow.Presentation = ActualAddressOfTheHeadCounterparty;
					NewCIRow.FieldValues = ActualAddressOfTheHeadCounterpartyFieldValues;
					NewCIRow.Value      = JSONContactInformationValueServer("ActualAddressOfTheHeadCounterpartyFieldValues");
				EndIf;
				
				If Not IsBlankString(LegalAddressOfMainCounterparty) Then
					NewCIRow = HeadCounterpartyObject.ContactInformation.Add();
					NewCIRow.Type           = Enums.ContactInformationTypes.Address;
					NewCIRow.Kind           = Catalogs.ContactInformationKinds.LegalAddressOfCounterparty;
					NewCIRow.Presentation = LegalAddressOfMainCounterparty;
					NewCIRow.FieldValues = LegalAddressOfTheHeadCounterpartyFieldValues;
					NewCIRow.Value      = JSONContactInformationValueServer("LegalAddressOfTheHeadCounterpartyFieldValues");
				EndIf;
				
				HeadCounterpartyObject.Write();
				ListOfCreated.Add(GetURL(HeadCounterpartyObject.Ref), HeadCounterpartyObject.Description);
				CounterpartyObject_.MainCounterparty = HeadCounterpartyObject.Ref;
				
				// bank account of the head counterparty
				If SpecifyTheBankAccountOfTheMainCounterparty Then
					
					Currency1 = (CurrencyOfCashHeadCounterparty <> CurrencyOfComplianceAccounting);
					
					BankAccount = Catalogs.CounterpartyBankAccounts.CreateItem();
					BankAccount.Owner = HeadCounterpartyObject.Ref;
					BankAccount.Description = AutoBankAccountName(
						AccountNumberHeadCounterparty, ParentCounterpartyBank, CurrencyOfCashHeadCounterparty);
					BankAccount.CashCurrency = CurrencyOfCashHeadCounterparty;
					BankAccount.AccountNumber = AccountNumberHeadCounterparty;
					BankAccount.Bank = ParentCounterpartyBank;
					BankAccount.TransferBank = BankForSettlementsHeadCounterparty;
					BankAccount.BankAccountForPayments = BankAccountForSettlementsHeadCounterparty;
					BankAccount.ForeignBank = ForeignBankHeadCounterparty;
					BankAccount.ManualBankDetailsChange = MethodOfSpecifyingBankHeadCounterparty = "ManualFillingInOfBankingDetails";
					BankAccount.TransferBankDetailsManualEdit = 
						(MethodOfSpecifyingBankForSettlementsHeadCounterparty = "ManualFillingInOfBankingDetails" And UsedByTheBankForSettlementsHeadCounterparty);
					BankAccount.BankBIC = BikbankParentCounterparty;
					BankAccount.BankCorrAccount = CorrespondentAccountOfTheBankHeadContractor;
					BankAccount.TransferBankBIC = BikbankForSettlementsHeadCounterparty;
					BankAccount.BankDescription = NameOfTheBankHeadCounterparty;
					BankAccount.TransferBankDescription = NameOfTheBankForSettlementsHeadCounterparty;
					BankAccount.BankAddress = BankAddressHeadCounterparty;
					BankAccount.TransferBankAddress = BankAddressForSettlementsHeadCounterparty;
					BankAccount.BankSWIFTCode = SwiftBankHeadCounterparty;
					BankAccount.BankSWIFTCodeForPayments = SwiftBankForSettlementsHeadCounterparty;
					BankAccount.TransferBankCorrAccount = CorrespondentAccountOfTheBankForCalculationOfHeadContractor;
					BankAccount.BankNameInt = BankNameInternationalHeadCounterparty;
					BankAccount.BankCityInt = BankCityInternationalHeadCounterparty;
					BankAccount.BankAddressInt = BankAddressInternationalHeadCounterparty;
					BankAccount.BankSWIFTCodeForPayments = SwiftBankForSettlementsHeadCounterparty;
					BankAccount.ThisIsAnIBAN = ThisIsIbanHeadCounterparty;
					BankAccount.BankNameForPaymentsInt = NameOfBankForSettlementsInternationalHeadCounterparty;
					BankAccount.CountryOfBankForPayments = CountryOfBankForSettlementsHeadCounterparty;
					BankAccount.TransferBankCity = CityOfBankForSettlementsHeadCounterparty;
					BankAccount.BankSWIFTCodeForPayments = SwiftBankForSettlementsHeadCounterparty;
					BankAccount.BankCityForPaymentsInt = BankCityForSettlementsInternationalHeadCounterparty;
					BankAccount.BankAddressForPaymentInt = BankAddressForSettlementsInternationalHeadCounterparty;
					
					BankAccount.Write();
					ListOfCreated.Add(GetURL(BankAccount.Ref), BankAccount.Description);
					
				EndIf;
				
			EndIf;
		EndIf;
		
		CounterpartyObject_.Write();
		TheCounterpartySelection = CounterpartyObject_.Ref;
		ListOfCreated.Add(GetURL(TheCounterpartySelection), CounterpartyObject_.Description);
		
		// Bank account
		If SpecifyTheCounterpartySBankAccount Then
			
			Currency1 = (CashCurrency <> CurrencyOfComplianceAccounting);
			
			BankAccount = Catalogs.CounterpartyBankAccounts.CreateItem();
			BankAccount.Owner = TheCounterpartySelection;
			BankAccount.Description = AutoBankAccountName(AccountNumber, Bank, CashCurrency);
			BankAccount.CashCurrency = CashCurrency;
			BankAccount.AccountNumber = AccountNumber;
			BankAccount.Bank = Bank;
			BankAccount.TransferBank = TransferBank;
			BankAccount.BankAccountForPayments = BankAccountForPayments;
			BankAccount.ForeignBank = ForeignBank;
			BankAccount.ManualBankDetailsChange = BankIndicationMethod = "ManualFillingInOfBankingDetails";
			BankAccount.TransferBankDetailsManualEdit = 
				(MethodOfSpecifyingBankForSettlements = "ManualFillingInOfBankingDetails" And SettlementBankUsed);
			BankAccount.BankBIC = BankBIC;
			BankAccount.BankCorrAccount = BankCorrAccount;
			BankAccount.TransferBankBIC = TransferBankBIC;
			BankAccount.BankDescription = BankDescription;
			BankAccount.CountryOfBank = CountryOfBank;
			BankAccount.BankCity = BankCity;
			BankAccount.TransferBankDescription = TransferBankDescription;
			BankAccount.BankAddress = BankAddress;
			BankAccount.TransferBankAddress = TransferBankAddress;
			BankAccount.BankSWIFTCode = BankSWIFTCode;
			BankAccount.BankNameInt = BankNameInt;
			BankAccount.BankCityInt = BankCityInt;
			BankAccount.BankAddressInt = BankAddressInt;
			BankAccount.BankSWIFTCodeForPayments = BankSWIFTCodeForPayments;
			BankAccount.TransferBankCorrAccount = TransferBankCorrAccount;
			BankAccount.ThisIsAnIBAN = ThisIsAnIBAN;
			BankAccount.BankNameForPaymentsInt = BankNameForPaymentsInt;
			BankAccount.CountryOfBankForPayments = CountryOfBankForPayments;
			BankAccount.TransferBankCity = TransferBankCity;
			BankAccount.BankSWIFTCodeForPayments = BankSWIFTCodeForPayments;
			BankAccount.BankCityForPaymentsInt = BankCityForPaymentsInt;
			BankAccount.BankAddressForPaymentInt = BankAddressForPaymentInt;
			
			BankAccount.Write();
			ListOfCreated.Add(GetURL(BankAccount.Ref), BankAccount.Description);
			
		EndIf;
		
		If ThisIsACompany = 1 And SpecifyLegalDetails And SpecifyTheIdentityDocument Then
			
			RecordManager = InformationRegisters.DocumentsPersons.CreateRecordManager();
			RecordManager.Active                               = True;
			RecordManager.Period                                   = CurrentSessionDate();
			RecordManager.Person                                  = TheCounterpartySelection;
			RecordManager.DocumentKind                             = DocumentKind;
			RecordManager.Series                                    = SeriesFromDocument;
			RecordManager.Number                                    = DocumentNumber;
			RecordManager.DateOfIssue1                               = DateOfIssue1;
			RecordManager.ValidityPeriod                             = ValidityPeriod;
			RecordManager.IssuedBy                                 = WhoIssuedDocument;
			RecordManager.BusinessUnitCode                         = BusinessUnitCode;
			RecordManager.ThisIsAnIdentityDocument = True;
			RecordManager.Write();
			
		EndIf;
		PartnersAndCounterpartiesLocalization.LinkSeparateDivisions(ThisObject);
	EndIf;
	
	If BasedOnTheCounterparty And ValueIsFilled(CounterpartyFoundation) Then
		
		ExecuteCounterpartyRecord(PartnerChoice, CounterpartyFoundation);
		
	EndIf;
	
	CreationCompleted = True;
	
	SegmentsServer.CheckWhetherPartnerIsIncludedInSegmentsWhenCreating(PartnerChoice);
	
EndProcedure

&AtClient
Procedure UserSelectionBasedOnSearchResults(Val Notification1)
	
	PartnerChoice = Undefined;
	
	CurrentData =  Items.TableFound.CurrentData;
	If CurrentData = Undefined Then
		RunCallback(Notification1, True);
		Return;
	EndIf;
	
	If ActionBasedOnResultsFound = 0 Then
		
		PartnerChoice = CurrentData.Partner;
		
		If OnlyPartnersAreUsed Or ActionWithTheCounterparty = 0 Then
			
			OpenAfterCreation = False;
			
			PartnerDetails_ = New Structure;
			PartnerDetails_.Insert("MainManager", CurrentData.MainManager);
			PartnerDetails_.Insert("Description",     CurrentData.Presentation);
			
			If CurrentData.Difference Then
				
				AdditionalParameters = New Structure;
				AdditionalParameters.Insert("PartnerDetails_", PartnerDetails_);
				AdditionalParameters.Insert("NewObjectsCreated", False);
				
				Notification = New CallbackDescription("QuestionContinuationOfPartnerSelectionCompletion", ThisObject, AdditionalParameters);
				If OnlyPartnersAreUsed Then
					QueryText = NStr("vi = 'Đối tác được chọn khác với dữ liệu đã nhập. Tiếp tục?';
									|ru = 'Выбранный контрагент имеет существенное различие с введенными данными. Продолжить?';
									|en = 'Selected counterparty has a significant difference with the data entered. Continue?'; fa = 'Selected counterparty has a significant difference with the data entered. Continue?';
									|it = 'Il contraente selezionato differisce significativamente dai dati inseriti. Continuare?';
									|pl = 'Dla wybranego kontrahenta istnieje znaczna różnica w stosunku do wprowadzonych danych. Kontynuować?';
									|tr = 'Seçilen cari hesabın, girilen verilerle önemli bir farkı vardır. Devam edilsin mi?'");
				Else
					QueryText = NStr("vi = 'Đối tác được chọn khác với dữ liệu đã nhập. Tiếp tục?';
									|ru = 'Выбранный партнер имеет существенное различие с введенными данными. Продолжить?';
									|en = 'Selected partner has a significant difference with data entered. Continue?'; fa = 'Selected partner has a significant difference with data entered. Continue?';
									|it = 'Il partner selezionato differisce significativamente dai dati inseriti. Continuare?';
									|pl = 'Dla wybranego partnera istnieje znaczna różnica w stosunku do wprowadzonych danych. Kontynuować?';
									|tr = 'Seçilen iş ortağının, girilen verilerle önemli bir farkı vardır. Devam edilsin mi?'");
				EndIf;
				
				ShowQueryBox(Notification, QueryText, QuestionDialogMode.YesNo, , DialogReturnCode.Yes);
				
			Else
				
				PerformFormClosingActions(New CallbackDescription("UserSelectionBasedOnSearchResultsCompletion", ThisObject, New Structure("Notification1, CurrentData", Notification1, CurrentData)), PartnerDetails_, False);
                Return;
				
			EndIf;
			
			
			UserSelectionBasedOnFoundFragmentResults(Notification1);

			Return;
			
		EndIf;
		
	ElsIf ActionBasedOnResultsFound = 1 Then
		
		Parent = CurrentData.Partner;
		
	EndIf;
	
	RunCallback(Notification1, False);
	Return;
	
EndProcedure

&AtClient
Procedure UserSelectionBasedOnSearchResultsCompletion(Result, AdditionalParameters) Export
    
    Notification1 = AdditionalParameters.Notification1;
    CurrentData = AdditionalParameters.CurrentData;
    
    
    UserSelectionBasedOnFoundFragmentResults(Notification1);

EndProcedure

&AtClient
Procedure UserSelectionBasedOnFoundFragmentResults(Val Notification1)
    
    RunCallback(Notification1, True);

EndProcedure

&AtClient
Procedure PerformFormClosingActions(Val Notification, PartnerDetails_, NewObjectsCreated)
	
	If BasedOnTheCounterparty And ValueIsFilled(CounterpartyFoundation) Then
		
		If Not NewObjectsCreated Then
			ExecuteCounterpartyRecord(PartnerChoice, CounterpartyFoundation);
		EndIf;
		
		NotifyChanged(CounterpartyFoundation);
		
	ElsIf BasisObject = Undefined Then
		
		Notify("ChoosingPartnerFound",
			New Structure("Partner,MainManager,Carrier", PartnerChoice, PartnerDetails_.MainManager, Carrier));
		
	Else
		
		InteractionsClient.ContactAfterWrite(
			ThisObject,
			New Structure("Ref, Description", PartnerChoice, PartnerDetails_.Description),
			New Structure,"Partners");
	EndIf;
	
	If ForSelection Then
		If ReturnTheLinkToTheCounterparty Then
			TheCounterpartySelection = GetPartnerSDefaultCounterparty(PartnerChoice);
			NotifyChoice(TheCounterpartySelection);
		Else
			NotifyChoice(PartnerChoice);
		EndIf;
	ElsIf BasedOnASeparateCounterparty Then
		If Not ValueIsFilled(TheCounterpartySelection) Then
			TheCounterpartySelection = GetPartnerSDefaultCounterparty(PartnerChoice);
		EndIf;
		Close(TheCounterpartySelection);
	Else
		Close(PartnerChoice);
	EndIf;
	
	If OpenAfterCreation Then
		If Not NewObjectsCreated Or ActionBasedOnResultsFound <> 0 Then
			ShowValue(Undefined, PartnerChoice);
            Return;
		Else
			ShowValue(Undefined, TheCounterpartySelection);
            Return;
		EndIf;
	EndIf;
	
	PerformActionsToCloseFragmentForm(Notification);
EndProcedure

&AtClient
Procedure PerformFormClosingActionsCompletion(AdditionalParameters) Export
    
    Notification = AdditionalParameters.Notification;
    
    
    PerformActionsToCloseFragmentForm(Notification);

EndProcedure

&AtClient
Procedure PerformActionsToCloseFragmentForm(Val Notification)
    
    RunCallback(Notification);

EndProcedure

&AtServerNoContext
Procedure ExecuteCounterpartyRecord(Partner, Counterparty)
	
	CounterpartyObject = Counterparty.GetObject();
	CounterpartyObject.Partner = Partner;
	CounterpartyObject.Write();
	
EndProcedure

&AtServer
Procedure FillInBasedOnCounterparty(CounterpartyData, Cancel)
	
	BasedOnTheCounterparty = True;
	Items.ThisIsACompany.Enabled = False;
	Items.DecorationPrimaryInformationDownload.Visible = False;
	Items.PagesSpecifyLegalDetailsCounterpartyBasis.CurrentPage = Items.PageBasedOnTheCounterparty;
	Items.PagesSpecifyCreateCounterpartyBaseObject.CurrentPage  = Items.PageBasedOnTheCounterpartyIndividual;
	Items.GroupLegalData.ReadOnly = True;
	Items.GroupLegalData.Enabled    = True;
	Items.GroupTaxNumberOfAnIndividual.ReadOnly = True;
	Items.GroupDocumentOfAnIndividual.ReadOnly = True;
	Items.GroupDocumentOfAnIndividual.Enabled = True;
	
	CounterpartyData = Parameters.CounterpartyFoundation;
	
	If CounterpartyData.Property("Ref") Then
		
		CounterpartyFoundation = CounterpartyData["Ref"];
		PartnersAndCounterpartiesLocalization.FillInCounterpartySDetailsUsingLink(CounterpartyData, Cancel);
		If Cancel Then
			Return;
		EndIf;
	EndIf;
	
	CounterpartyData.Insert("FullDescr",CounterpartyData.FullLegalName);
	
	If CounterpartyData.Property("ActualDataCounterpartyAddress") Then
		
		ActualAddress = CounterpartyData.ActualDataCounterpartyAddress.Presentation;
		PhysicalAddressFieldValues = CounterpartyData.ActualDataCounterpartyAddress.FieldValues;
		
	EndIf;
	
	If CounterpartyData.LegalEntityIndividual = Enums.LegalEntityIndividual.Person Then
		
		ThisIsACompany = 1;
		FillPropertyValues(ThisObject,CounterpartyData);
		LastFirstName = StringFunctionsClientServer.SplitStringIntoSubstringsArray(TrimAll(CounterpartyData.Name1)," ");
		SubstringCount = LastFirstName.Count();
		PartnerSLastName  = ?(SubstringCount > 0,LastFirstName[0],"");
		PartnerName_3      = ?(SubstringCount > 1,LastFirstName[1],"");
		PartnerSMiddleName = ?(SubstringCount > 2,LastFirstName[2],"");
		
		If CounterpartyData.Property("CounterpartySPhoneNumber") Then
			
			PartnerSPhoneNumberIndividual = CounterpartyData.CounterpartySPhoneNumber.Presentation;
			PartnerSPhoneNumberIndividualFieldValues = CounterpartyData.CounterpartySPhoneNumber.FieldValues;
			
		EndIf;
		
		If CounterpartyData.Property("EmailCounterparty_") Then
			
			EppartnerSAddressIndividual = CounterpartyData.EmailCounterparty_.Presentation;
			
		EndIf;
		
	ElsIf CounterpartyData.LegalEntityIndividual = Enums.LegalEntityIndividual.IndividualEntrepreneur Then
		
		ThisIsACompany = 0;
		TypeOfCompany = 2;
		FillPropertyValues(ThisObject,CounterpartyData);
		
		If CounterpartyData.Property("CounterpartySPhoneNumber") Then
			
			PartnerSPhoneNumber = CounterpartyData.CounterpartySPhoneNumber.Presentation;
			PartnerPhoneFieldValues = CounterpartyData.CounterpartySPhoneNumber.FieldValues;
			
		EndIf;
		
		If CounterpartyData.Property("EmailCounterparty_") Then
			
			EppartnerSAddress = CounterpartyData.EmailCounterparty_.Presentation;
			
		EndIf;
		
	ElsIf CounterpartyData.LegalEntityIndividual = Enums.LegalEntityIndividual.LegalEntityNonResident Then
		
		ThisIsACompany = 0;
		TypeOfCompany = 1;
		FillPropertyValues(ThisObject,CounterpartyData);
		NameOfTheCounterparty = Name1;
		
		If CounterpartyData.Property("LegalAddressOfCounterparty") Then
			
			LegalAddress = CounterpartyData.LegalAddressOfCounterparty.Presentation;
			LegalAddressFieldValues = CounterpartyData.LegalAddressOfCounterparty.FieldValues;
			
		EndIf;
		
		If CounterpartyData.Property("CounterpartySPhoneNumber") Then
			
			PartnerSPhoneNumber = CounterpartyData.CounterpartySPhoneNumber.Presentation;
			PartnerPhoneFieldValues = CounterpartyData.CounterpartySPhoneNumber.FieldValues;
			
		EndIf;
		
		If CounterpartyData.Property("EmailCounterparty_") Then
			
			EppartnerSAddress = CounterpartyData.EmailCounterparty_.Presentation;
			
		EndIf;
		
	Else
		
		ThisIsACompany = 0;
		TypeOfCompany = ?(CounterpartyData.BranchOffice, 3, 0);
		FillPropertyValues(ThisObject,CounterpartyData);
		NameOfTheCounterparty = Name1;
		
		If CounterpartyData.Property("LegalAddressOfCounterparty") Then
			
			LegalAddress = CounterpartyData.LegalAddressOfCounterparty.Presentation;
			LegalAddressFieldValues = CounterpartyData.LegalAddressOfCounterparty.FieldValues;
			
		EndIf;
		
		If CounterpartyData.Property("CounterpartySPhoneNumber") Then
			
			PartnerSPhoneNumber = CounterpartyData.CounterpartySPhoneNumber.Presentation;
			PartnerPhoneFieldValues = CounterpartyData.CounterpartySPhoneNumber.FieldValues;
			
		EndIf;
		
		If CounterpartyData.Property("EmailCounterparty_") Then
			
			EppartnerSAddress = CounterpartyData.EmailCounterparty_.Presentation;
			
		EndIf;
		
	EndIf;
	PartnersAndCounterpartiesLocalization.FillInBasedOnCounterparty(CounterpartyData, ThisObject);
	
EndProcedure

&AtServerNoContext
Function FieldValuesInListOfValues(FieldValueDetails)
	
	// Converts the "new", string value of the service address field to the "old", list of values.
	
	If IsBlankString(FieldValueDetails) Then
		Return New ValueList;
	EndIf;
	
	PhoneNumber = ContactsManager.ContactInformationPhoneNumber(FieldValueDetails);
	
	Result = New ValueList;
	
	Result.Add("",  "CountryCode");
	Result.Add("",  "CityCode");
	Result.Add(PhoneNumber, "PhoneNumber");
	Result.Add("", "PhoneExtension");
	
	Return Result;
	
EndFunction

&AtServer
Procedure SetHeaders()

	PartnersAndCounterparties.HeaderOfPropsDependingOnFOUsePartnersAsCounterparties(
	                     ThisObject, "", NStr("vi = 'Trợ giúp ghi nhận đối tác mới';
												|ru = 'Помощник регистрации нового контрагента';
												|en = 'New counterparty registration wizard'; fa = 'ویزارد ثبت طرف حساب جدید';
												|it = 'Assistente per la registrazione di un nuovo contraente';
												|pl = 'Asystent rejestracji nowego kontrahenta';
												|tr = 'Yeni cari hesap kaydı sihirbazı'"), OnlyPartnersAreUsed);
	PartnersAndCounterparties.HeaderOfPropsDependingOnFOUsePartnersAsCounterparties(
	                     ThisObject, "DecorationPrimaryInformation", 
	                     NStr("vi = 'Hãy chỉ ra thông tin hữu ích với bạn về đối tác tại thời điểm này ';
								|ru = 'Укажите доступную вам на данный момент информацию о контрагенте';
								|en = 'Specify available details about counterparty'; fa = 'Specify available details about counterparty';
								|it = 'Indicate le informazioni a vostra disposizione in questo momento sul contraente';
								|pl = 'Wskaż dostępne obecnie informacje na temat kontrahenta';
								|tr = 'Cari hesapla ilgili şu anda mevcut olan bilgileri belirtin'"), OnlyPartnersAreUsed);
	PartnersAndCounterparties.HeaderOfPropsDependingOnFOUsePartnersAsCounterparties(
	                     ThisObject, "SpecifyTheContactPersonSDetails", 
	                     NStr("vi = 'Chỉ ra dữ liệu người liên hệ (sẽ tạo người liên hệ của đối tác)';
								|ru = 'Указать данные контактного лица (будет создано контактное лицо контрагента)';
								|en = 'Specify contact person details (counterparty''s contact person will be created)'; fa = 'Specify contact person details (counterparty''s contact person will be created)';
								|it = 'Indicare i danni della persona di contatto (verrà creato una contatto del contraente)';
								|pl = 'Wskaż dane osoby do kontaktu (zostanie utworzona osoba do kontaktu kontrahenta)';
								|tr = 'İrtibat kişisi verilerini belirt (cari hesabın irtibat kişisi oluşturulacaktır)'"), OnlyPartnersAreUsed);
	PartnersAndCounterparties.HeaderOfPropsDependingOnFOUsePartnersAsCounterparties(
	                     ThisObject, "ActualAddress", 
	                     NStr("vi = 'Địa chỉ thực tế của đối tác';
								|ru = 'Фактический адрес контрагента';
								|en = 'Business address of the counterparty'; fa = 'Business address of the counterparty';
								|it = 'Indirizzo effettivo del contraente';
								|pl = 'Adres faktyczny kontrahenta';
								|tr = 'Cari hesabın iş adresi'"), OnlyPartnersAreUsed);
	PartnersAndCounterparties.HeaderOfPropsDependingOnFOUsePartnersAsCounterparties(
	                     ThisObject, "LegalAddress", 
	                     NStr("vi = 'Địa chỉ đăng ký của đối tác';
								|ru = 'Юридический адрес контрагента';
								|en = 'Counterparty legal address'; fa = 'Counterparty legal address';
								|it = 'Indirizzo giuridico del contraente';
								|pl = 'Adres prawny kontrahenta';
								|tr = 'Cari hesabın yasal adresi'"), OnlyPartnersAreUsed);
	PartnersAndCounterparties.HeaderOfPropsDependingOnFOUsePartnersAsCounterparties(
	                     ThisObject, "DecorationFound", 
	                     NStr("vi = 'Đã tìm thấy đối tác có dữ liệu bị trùng, hãy quyết định các thao tác tiếp theo.';
								|ru = 'Найдены контрагенты с совпадающими данными, примите решение о дальнейших действиях.';
								|en = 'Counterparties with matching data are found, decide on further actions.'; fa = 'Counterparties with matching data are found, decide on further actions.';
								|it = 'Contraenti con dati coincidenti trovati, decidete le azioni successive.';
								|pl = 'Znaleziono kontrahentów z pokrywającymi się danymi, podejmij decyzję o następnych działaniach.';
								|tr = 'Eşleşen verilere sahip cari hesaplar bulundu, sonraki adımlar ile ilgili karar verin.'"), OnlyPartnersAreUsed);
	PartnersAndCounterparties.HeaderOfPropsDependingOnFOUsePartnersAsCounterparties(
	                     ThisObject, "TableFound", 
	                     NStr("vi = 'Đối tác được tìm thấy';
								|ru = 'Найденные контрагенты';
								|en = 'Found counterparties'; fa = 'Found counterparties';
								|it = 'Contraenti trovati';
								|pl = 'Znalezieni kontrahenci';
								|tr = 'Bulunan cari hesaplar'"), OnlyPartnersAreUsed);
	PartnersAndCounterparties.HeaderOfPropsDependingOnFOUsePartnersAsCounterparties(
	                     ThisObject, "PartnerComparisonTree", 
	                     NStr("vi = 'So sánh đối tác';
								|ru = 'Сравнение контрагентов';
								|en = 'Compare counterparties'; fa = 'Compare counterparties';
								|it = 'Confronto dei contraenti';
								|pl = 'Porównanie kontrahentów';
								|tr = 'Cari hesapların karşılaştırılması'"), OnlyPartnersAreUsed);
	PartnersAndCounterparties.HeaderOfPropsDependingOnFOUsePartnersAsCounterparties(
	                     ThisObject, "PartnerComparisonTreeValueOfFound", 
	                     NStr("vi = 'Đối tác được tìm thấy';
								|ru = 'Найденный контрагент';
								|en = 'Found counterparty'; fa = 'Found counterparty';
								|it = 'Contraente trovato';
								|pl = 'Znaleziony kontrahent';
								|tr = 'Bulunan cari hesap'"), OnlyPartnersAreUsed);
	PartnersAndCounterparties.HeaderOfPropsDependingOnFOUsePartnersAsCounterparties(
	                     ThisObject, "PartnerComparisonTreeCurrentValue", 
	                     NStr("vi = 'Đối tác đã tạo';
								|ru = 'Создаваемый контрагент';
								|en = 'Counterparty to create'; fa = 'Counterparty to create';
								|it = 'Contraente in fase di creazione';
								|pl = 'Tworzony kontrahent';
								|tr = 'Oluşturulan cari hesap'"), OnlyPartnersAreUsed);
	
EndProcedure

&AtServer
Procedure DetermineWhetherContactInformationIsMandatory()

	Query = New Query;
	Query.Text = "
	|SELECT
	|	ContactInformationKinds.Ref AS Kind,
	|	ContactInformationKinds.Mandatory AS RequiredFilling
	|FROM
	|	Catalog.ContactInformationKinds AS ContactInformationKinds
	|WHERE
	|	ContactInformationKinds.Ref IN (VALUE(Catalog.ContactInformationKinds.PartnerSPhoneNumber), VALUE(Catalog.ContactInformationKinds.EmailPartner_), VALUE(Catalog.ContactInformationKinds.PartnerAddress))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ContactInformationKinds.Ref AS Kind,
	|	ContactInformationKinds.Mandatory AS RequiredFilling
	|FROM
	|	Catalog.ContactInformationKinds AS ContactInformationKinds
	|WHERE
	|	ContactInformationKinds.Ref IN (VALUE(Catalog.ContactInformationKinds.ContactPersonSMobilePhoneNumber), VALUE(Catalog.ContactInformationKinds.ContactPersonSPhoneNumber), VALUE(Catalog.ContactInformationKinds.EmailContactPerson))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ContactInformationKinds.Ref AS Kind,
	|	ContactInformationKinds.Mandatory AS RequiredFilling
	|FROM
	|	Catalog.ContactInformationKinds AS ContactInformationKinds
	|WHERE
	|	ContactInformationKinds.Ref IN (VALUE(Catalog.ContactInformationKinds.ActualDataCounterpartyAddress), VALUE(Catalog.ContactInformationKinds.LegalAddressOfCounterparty))";
	
	SetPrivilegedMode(True);
	Result = Query.ExecuteBatch();
	ResultPartners = Result[0]; // QueryResult
	
	SamplePartners = ResultPartners.Select();
	
	While SamplePartners.Next() Do
	
		If SamplePartners.Kind = Catalogs.ContactInformationKinds.PartnerSPhoneNumber Then
			PartnerSPhoneNumberIsRequired = SamplePartners.RequiredFilling;
		ElsIf SamplePartners.Kind = Catalogs.ContactInformationKinds.PartnerAddress Then 
			ThePartnerSAddressIsRequired   = SamplePartners.RequiredFilling;
		ElsIf SamplePartners.Kind = Catalogs.ContactInformationKinds.EmailPartner_ Then
			TheEppartnerSAddressIsRequired = SamplePartners.RequiredFilling;
		EndIf;
	
	EndDo;
	
	ResultContactPersons = Result[1]; // QueryResult
	SampleContactPersons   = ResultContactPersons.Select();
	
	While SampleContactPersons.Next() Do
	
		If SampleContactPersons.Kind = Catalogs.ContactInformationKinds.ContactPersonSMobilePhoneNumber Then
			TheContactPersonSMobilePhoneNumberIsRequired = SampleContactPersons.RequiredFilling;
		ElsIf SampleContactPersons.Kind = Catalogs.ContactInformationKinds.ContactPersonSPhoneNumber Then
			ContactPersonSPhoneNumberIsRequired = SampleContactPersons.RequiredFilling;
		ElsIf SampleContactPersons.Kind = Catalogs.ContactInformationKinds.EmailContactPerson Then
			TheAddressOfTheContactPersonIsRequired = SampleContactPersons.RequiredFilling;
		EndIf;
	
	EndDo;
	
	ResultCounterparties = Result[2]; // QueryResult
	SampleCounterparties   = ResultCounterparties.Select();
	
	While SampleCounterparties.Next() Do
	
		If SampleCounterparties.Kind = Catalogs.ContactInformationKinds.ActualDataCounterpartyAddress Then
			FactTheCounterpartySAddressIsRequired = SampleCounterparties.RequiredFilling;
		ElsIf SampleCounterparties.Kind = Catalogs.ContactInformationKinds.LegalAddressOfCounterparty Then
			TheLegalAddressOfTheCounterpartyIsRequired= SampleCounterparties.RequiredFilling;
		EndIf;
	
	EndDo;

EndProcedure

&AtServerNoContext
Function GetPartnerSDefaultCounterparty(Partner)
	
	Return PartnersAndCounterparties.GetPartnerSDefaultCounterparty(Partner);
	
EndFunction

&AtClient
Function NameOfHeaderPartner()
	
	If ThisIsACompany = 0 Then
		NameOfHeaderPartner = FullDescr;
	Else
		NameOfHeaderPartner = FIO_OneLine(PartnerSLastName, PartnerName_3, PartnerSMiddleName);
	EndIf;
	
	Return NameOfHeaderPartner;
	
EndFunction

&AtClientAtServerNoContext
Function AddressOfPrivatePersonIsRequired(Form)
	
	If Form.SpecifyLegalDetails
		And (Form.TheLegalAddressOfTheCounterpartyIsRequired
			And Not ValueIsFilled(Form.LegalAddress))
		And  ValueIsFilled(Form.ActualAddress) Then
		
		Form.LegalAddress = Form.ActualAddress;
		Form.LegalAddressFieldValues = Form.PhysicalAddressFieldValues;
		
	EndIf;
  
   Return Not ValueIsFilled(Form.ActualAddress)
	        And (Form.FactTheCounterpartySAddressIsRequired
	           Or Form.ThePartnerSAddressIsRequired
	           Or (Form.SpecifyLegalDetails 
	                And Form.TheLegalAddressOfTheCounterpartyIsRequired));
    
EndFunction

&AtServer
Procedure CreatePartner(ListOfCreated, YouNeedToGoToMatchesPage)

	Cancel = False;
	
	PartnersAndCounterpartiesLocalization.BeforeCreatingPartnerInFormOfNewAssistant(ThisObject, PartnersAndCounterparties.LegalEntityPhysicalPersonAccordingToNewAssistantForm(ThisObject), Cancel);
	
	If Cancel Then
		SearchForPrimaryInformation();
		YouNeedToGoToMatchesPage = True;
		Return;
	EndIf;

	BeginTransaction();
	
	Try
		
		RecordPartnerAndRelatedData(ListOfCreated);
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		WriteLogEvent(NStr("vi = 'Tạo đối tác mới.';
							|ru = 'Создание нового партнера.';
							|en = 'Create a new partner.'; fa = 'Create a new partner.';
							|it = 'Creazione di un nuovo partner.';
							|pl = 'Tworzenie nowego partnera.';
							|tr = 'Yeni iş ortağının oluşturulması.'", Common.DefaultLanguageCode()),
		EventLogLevel.Error,,, DetailErrorDescription(ErrorInfo()));
		
		Raise BriefErrorDescription(ErrorInfo());
		
	EndTry;

EndProcedure

&AtClient
Procedure SetVisibilityOfDeliveryZone()
	
	VisibilityOfDeliveryZone = DeliveryZoneIsAvailable(ThisObject);
	
	ItemsNames = New Array;
	ItemsNames.Add(Items.DeliveryZone.Name);
	ItemsNames.Add(Items.DeliveryZonePrivatePerson.Name);
	
	TMCommonUseClientServer.SetPropertyOfFormElements(
		Items,
		ItemsNames,
		"Visible",
		VisibilityOfDeliveryZone);
	
EndProcedure

&AtClientAtServerNoContext
Function DeliveryZoneIsAvailable(Form)
	
	AvailabilityOfDeliveryZone = Not IsBlankString(Form.ActualAddress);
	
	Return AvailabilityOfDeliveryZone;
	
EndFunction

#EndRegion

#Region AdditionalAttributes

// StandardSubsystems.Properties

&AtServer
Procedure UpdateAdditionalAttributesItems()
	PropertyManager.UpdateAdditionalAttributesItems(ThisObject, PartnerTheObjectOfAdditionalDetails);
EndProcedure

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject, PartnerTheObjectOfAdditionalDetails);
EndProcedure

// End StandardSubsystems.Properties

#EndRegion

#Region Localization


#EndRegion

#EndRegion

#Region Initialize

	ClosingInProgress = False;


#If AtServer Then

If Not ConnectedHandlersLocalization And GetFunctionalOption("RFPaymentsSupport") Then
	
	ConnectedHandlersLocalization = True;
	
	ConnectedElementEventHandlers = New Map; // Key - Element, Value - Event
	ConnectedElementEventHandlers.Insert("AccountNumber", "OnChange");
	ConnectedElementEventHandlers.Insert("AccountNumberHeadCounterparty", "OnChange");
	
	For Each Handler In ConnectedElementEventHandlers Do
		Items[Handler.Key].SetAction(
			Handler.Value, "Attachable_" + Handler.Key + Handler.Value + "Localization");
	EndDo;
	
EndIf;

#EndIf

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
