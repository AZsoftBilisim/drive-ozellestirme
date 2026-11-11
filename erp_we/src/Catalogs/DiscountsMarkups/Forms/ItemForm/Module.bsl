
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);

	FillPropertyValues(ThisObject, DiscountsMarkupsServer.StructureOfDiscountSourcesAccordingToFederalLaw());
	
	DestinationMethod = Object.Managed;
	
	// Handler of the subsystem prohibiting editing of object details
	ObjectAttributesLock.LockAttributes(ThisObject);
	
	// Handler of the "Versioning of objects" mechanism
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	If Not ValueIsFilled(Object.Ref) Then
		Object.Description = AutoDescription(ThisObject);
	Else
		AutoDescription(ThisObject);
	EndIf;
	DiscountsMarkupsClientServer.UpdateAutoNamingDetails(ThisObject);
	
	FillInListForSelectingDeliveryMethod(ThisObject);
	
	Items.RoundingPrecision.ChoiceList.Clear();
	RoundingValue             = 0.01;
	EvenIncrement               = False;
	MaximumRoundingValue = 100000;
	PriceRangeBoundary            = 100000000;
	
	While RoundingValue <= MaximumRoundingValue 
		And (RoundingValue <= PriceRangeBoundary Or PriceRangeBoundary < 0) Do
		
		Items.RoundingPrecision.ChoiceList.Add(RoundingValue);
		RoundingValue = RoundingValue * ?(EvenIncrement, 2, 5);
		EvenIncrement   = Not EvenIncrement;
		
	EndDo;
	
	If Object.Ref.IsEmpty() Then
		
		DiscountsMarkupsServer.OnCreatReadAtServer(ThisObject);
		
		OnCreatReadAtServer();
		
		SetDiscountTrackingSettings();
		
	EndIf;
	
	DiscountsMarkupsServer.AddCommandsToCreateNewConditionsForDiscountsMarkups(ThisObject, Items.TheConditionsForGrantingAGroupToCreate);
	
	SetSettingsForElementsOfProductConditionOptions(ThisObject);
	
	ChangeVisibilityOfElements();
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	DiscountsMarkupsServer.OnCreatReadAtServer(ThisObject, CurrentObject);
	
	OnCreatReadAtServer();

	ConfigurationModificationOverridable.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	// Handler of the subsystem prohibiting editing of object details
	ObjectAttributesLock.LockAttributes(ThisObject);
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);

EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	If Object.ItemFilterOption = PredefinedValue("Enum.ItemFilterOptionsForDiscountMarkupCalculation.DataCompositionFilter")
		And Not ValueIsFilled(String(SettingsComposerFilterByProducts.Settings.Filter)) Then
		
		CommonClient.MessageToUser(
			NStr("vi = 'Chưa đặt bộ lọc mặt hàng';
				|ru = 'Не установлен отбор номенклатуры';
				|en = 'Item filter is not set'; fa = 'Item filter is not set';
				|it = 'Non è selezionata la scelta di articolo';
				|pl = 'Nie ustawiono wyboru towarów';
				|tr = 'Öğe filtresi yapılandırılmadı'"),,"SettingsComposerFilterByProductsPresentation",, Cancel);
		
	EndIf;
	
	UpdateAutoNaming(Modified);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)

	ConfigurationModificationClientOverridable.AfterWrite(ThisObject, WriteParameters);
	
	AttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)

	DiscountsMarkupsServer.BeforeWriteAtServer(ThisObject, CurrentObject, "MethodsOfProviding");
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisObject, Cancel, CurrentObject, WriteParameters);

EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Selection_TermsOfDiscountsMarkups" 
		And ValueIsFilled(Source)
		And TypeOf(Source) = Type("CatalogRef.DiscountMarkupTerms") Then
		
		NewRow = Object.DiscountMarkupConditions.Add();
		NewRow.DiscountMarkupCondition = Source;
		Modified = True;
		
		ChangeVisibilityOfElements();
		
	ElsIf EventName = "Write_ValidityOfDiscountsMarkups" 
		And Parameter.Property("DiscountMarkup") 
		And Parameter.DiscountMarkup.Find(Object.Ref) <> Undefined Then
		
		UpdateUsageOfDiscountsMarkups();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ParentOnChange(Item)
	
	SetDiscountTrackingSettings();
	
EndProcedure

&AtClient
Procedure MethodsOfProvidingOnChange(Item)
	
	SuggestAddingConditionLoyaltyCardNotRegistered = MethodOfRenderingWhenChangedOnServer();
	If SuggestAddingConditionLoyaltyCardNotRegistered Then
		
		ShowQueryBox(New CallbackDescription("MethodsOfProvidingOnChangeCompletion", ThisObject), 
			StrTemplate(
				NStr("vi = 'Thêm điều kiện ""Thẻ khách hàng thân thiết ""%1"" chưa được ghi nhận?""';
					|ru = 'Добавить условие ""Карта лояльности ""%1"" не зарегистрирована?""';
					|en = 'Add condition ""Is loyalty card ""%1"" not registered?""'; fa = 'Add condition ""Is loyalty card ""%1"" not registered?""';
					|it = 'Aggiungere la condizione ""Carta di fedeltà ""%1"" non registrata?""';
					|pl = 'Dodaj warunek ""Karta lojalnościowa ""%1"" nie jest zarejestrowana?""';
					|tr = '""""%1"" sadakat kartı kaydedilmedi mi?"" şartını ekle'"),
				Object.LoyaltyCardKind
			), QuestionDialogMode.YesNo);
		Return;
		
	EndIf;
	
	SetDiscountTrackingSettings();
	
	UpdateAutoNaming(True);
	
EndProcedure

&AtClient
Procedure MethodsOfProvidingOnChangeCompletion(QuestionResult, AdditionalParameters) Export
	
	Result = QuestionResult;
	If Result = DialogReturnCode.Yes Then
		AddConditionLoyaltyCardNotRegistered(Object.LoyaltyCardKind);
	EndIf;
	
	UpdateAutoNaming(True);

EndProcedure

&AtClient
Procedure DescriptionOnChange(Item)
	
	DiscountsMarkupsClientServer.UpdateAutoNamingDetails(ThisObject);
	
EndProcedure

&AtClient
Procedure DiscountMarkupValueOnChange(Item)
	UpdateAutoNaming(True);
EndProcedure

&AtClient
Procedure CurrencyOfTheGrantWhenChanged(Item)
	UpdateAutoNaming(True);
EndProcedure

&AtClient
Procedure PriceKindOnChange(Item)
	UpdateAutoNaming(True);
EndProcedure

&AtClient
Procedure DiscountMarkupConditionsOnChange(Item)
	
	UpdateAutoNaming(True);
	ChangeVisibilityOfElements();
	
EndProcedure

&AtClient
Procedure LoyaltyCardKindOnChange(Item)
	
	UpdateAutoNaming(True);
	
	SuggestAddingConditionLoyaltyCardNotRegistered = TypeOfLoyaltyCardWhenChangedOnServer();
	If SuggestAddingConditionLoyaltyCardNotRegistered Then

		ShowQueryBox(New CallbackDescription("LoyaltyCardKindOnChangeCompletion", ThisObject), 
			StrTemplate(
				NStr("vi = 'Thêm điều kiện ""Thẻ khách hàng thân thiết ""%1"" chưa được ghi nhận?""';
					|ru = 'Добавить условие ""Карта лояльности ""%1"" не зарегистрирована?""';
					|en = 'Add condition ""Is loyalty card ""%1"" not registered?""'; fa = 'Add condition ""Is loyalty card ""%1"" not registered?""';
					|it = 'Aggiungere la condizione ""Carta di fedeltà ""%1"" non registrata?""';
					|pl = 'Dodaj warunek ""Karta lojalnościowa ""%1"" nie jest zarejestrowana?""';
					|tr = '""""%1"" sadakat kartı kaydedilmedi mi?"" şartını ekle'"),
				Object.LoyaltyCardKind
			), QuestionDialogMode.YesNo);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure LoyaltyCardKindOnChangeCompletion(QuestionResult, AdditionalParameters) Export
    
    Result = QuestionResult;
    If Result = DialogReturnCode.Yes Then
        AddConditionLoyaltyCardNotRegistered(Object.LoyaltyCardKind);
    EndIf;

EndProcedure

&AtClient
Procedure MessageTextOnChange(Item)
	UpdateAutoNaming(True);
EndProcedure

&AtClient
Procedure GiftSegmentOnChange(Item)
	UpdateAutoNaming(True);
EndProcedure

&AtClient
Procedure DiscountConditionByQuantityOnChange(Item)
	UpdateAutoNaming(True);
EndProcedure

&AtClient
Procedure HowToApplyTheDiscountWhenChanging(Item)
	
	If Object.DiscountApplicationMethod = PredefinedValue("Enum.DiscountMarkupApplicationMethods.GrantBonusPoints") Then
		Items.Pages.CurrentPage = Items.BonusesPage;
		If Not ValueIsFilled(Object.ActionPeriod) Then
			Object.ActionPeriod = PredefinedValue("Enum.Periodicity.Month");
		EndIf;
		If Not ValueIsFilled(Object.PeriodOfActionStartDelay) Then
			Object.PeriodOfActionStartDelay = PredefinedValue("Enum.Periodicity.Week");
		EndIf;
	Else
		Items.Pages.CurrentPage = Items.DiscountPage;
	EndIf;
	
	Items.BonusesPage.Visible = (Object.DiscountApplicationMethod = PredefinedValue("Enum.DiscountMarkupApplicationMethods.GrantBonusPoints"));
	Items.DiscountPage.Visible = Not (Object.DiscountApplicationMethod = PredefinedValue("Enum.DiscountMarkupApplicationMethods.GrantBonusPoints"));
	
	UpdateAutoNaming(True);
	HowToApplyDiscountWhenChangingOnServer();
	
EndProcedure

&AtClient
Procedure ProvisionMethodBonusPointsOnChange(Item)
	
	SuggestAddingConditionLoyaltyCardNotRegistered = MethodOfRenderingWhenChangedOnServer();
	If SuggestAddingConditionLoyaltyCardNotRegistered Then
		
		ShowQueryBox(New CallbackDescription("ProvisionMethodBonusPointsOnChangeCompletion", ThisObject), 
			StrTemplate(
				NStr("vi = 'Thêm điều kiện ""Thẻ khách hàng thân thiết ""%1"" chưa được ghi nhận?""';
					|ru = 'Добавить условие ""Карта лояльности ""%1"" не зарегистрирована?""';
					|en = 'Add condition ""Is loyalty card ""%1"" not registered?""'; fa = 'Add condition ""Is loyalty card ""%1"" not registered?""';
					|it = 'Aggiungere la condizione ""Carta di fedeltà ""%1"" non registrata?""';
					|pl = 'Dodaj warunek ""Karta lojalnościowa ""%1"" nie jest zarejestrowana?""';
					|tr = '""""%1"" sadakat kartı kaydedilmedi mi?"" şartını ekle'"),
				Object.LoyaltyCardKind
			), QuestionDialogMode.YesNo);
		Return;
		
	EndIf;
	
	MethodOfGrantingBonusesWhenChangingFragment();
EndProcedure

&AtClient
Procedure ProvisionMethodBonusPointsOnChangeCompletion(QuestionResult, AdditionalParameters) Export
    
    Result = QuestionResult;
    If Result = DialogReturnCode.Yes Then
        AddConditionLoyaltyCardNotRegistered(Object.LoyaltyCardKind);
    EndIf;
    
    
    MethodOfGrantingBonusesWhenChangingFragment();

EndProcedure

&AtClient
Procedure MethodOfGrantingBonusesWhenChangingFragment()
    
    UpdateAutoNaming(True);

EndProcedure

&AtClient
Procedure AssignmentMethodWhenChanging(Item)
	
	Object.Managed = DestinationMethod > 0;
	
	UpdateAutoNaming(True);
	
EndProcedure

&AtClient
Procedure LoyaltyProgramInCaseOfChange(Item)
	UpdateAutoNaming(True);
EndProcedure

&AtClient
Procedure UseValidityPeriodOnChange(Item)
	
	ChangeAvailability(ThisObject);
	
	Object.NumberOfValidityPeriods = UseValidityPeriod;
	
EndProcedure

&AtClient
Procedure UseActionStartDelayOnChange(Item)
	
	ChangeAvailability(ThisObject);
	
	Object.NumberOfActionStartDelayPeriods = UseActionStartDelay;
	
EndProcedure

&AtClient
Procedure DiscountMarkupConditionsSelection(Item, RowSelected, Field, StandardProcessing)
	
	OpenTermsOfService();

EndProcedure

&AtClient
Procedure InformationOnDiscountValidityURLProcessing(Item, Var_URL, StandardProcessing)
	
	StandardProcessing = False;
	If Var_URL = "Change" Then
		
		If Not ValueIsFilled(Object.Ref) Then
			
			Buttons = New ValueList;
			Buttons.Add("Write", NStr("vi = 'Ghi lại';
										|ru = 'Записать';
										|en = 'Save'; fa = 'ذخیره';
										|it = 'Salvare';
										|pl = 'Save';
										|tr = 'Kaydet'"));
			Buttons.Add("Cancel", NStr("vi = 'Hủy bỏ';
										|ru = 'Отмена';
										|en = 'Cancel'; fa = 'انصراف';
										|it = 'Annulla';
										|pl = 'Cancel';
										|tr = 'İptal'"));
			
			CallbackDescription = New CallbackDescription("HandlingAlertIssueBeforeStatusChange", ThisObject);
			
			ShowQueryBox(CallbackDescription, NStr("vi = 'Để thay đổi trạng thái hiệu lực, cần ghi lại chiết khấu (phụ thu).';
													|ru = 'Для изменения статуса действия скидка (наценка) должна быть записана.';
													|en = 'Discount (markup) must be saved to change the action status.'; fa = 'Discount (markup) must be saved to change the action status.';
													|it = 'Per modificare lo stato di validità lo sconto (sovrapprezzo) deve essere registrato.';
													|pl = 'Aby zmienić status działania, rabat (marża) musi być zapisany.';
													|tr = 'Eylemin durumunu değiştirmek için indirim (zam) uygulanmalıdır.'"), Buttons,,,NStr("vi = 'Chưa ghi lại chiết khấu (phụ thu)';
																																			|ru = 'Скидка (наценка) не записана';
																																			|en = 'Discount (markup) is not saved'; fa = 'Discount (markup) is not saved';
																																			|it = 'Lo sconto (sovrapprezzo) non è registrato';
																																			|pl = 'Rabat (marża) nie jest zapisany';
																																			|tr = 'İndirim (zam) uygulanmadı'"));
			
		Else
			OpenActionStatusChangeForm();
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DeliveredByExternalProcessingOfTheDiscountNavigationLinkProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	ShowValue(Undefined, Object.MethodsOfProviding);
	
EndProcedure

&AtClient
Procedure FilterURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	DiscountsMarkupsClient.ConfigureFilter(
		ThisObject,
		FormattedStringURL,
		GetAddressesOfDataLayoutSchemeInTemporaryStorage(FormattedStringURL));
	
EndProcedure

&AtClient
Procedure AdditionalSelectionPresentationURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	DiscountsMarkupsClient.ConfigureFilter(
		ThisObject,
		FormattedStringURL,
		GetAddressesOfDataLayoutSchemeInTemporaryStorage(FormattedStringURL));
	
EndProcedure

&AtClient
Procedure ClarificationByPriceGroupPresentationURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	FormParameters = New Structure;
	FormParameters.Insert("AddressInTempStorage", AddressForSpecifyingDiscountMarkUpValueInTemporaryStorage());
	FormParameters.Insert("ReadOnly", Items.MethodsOfProviding.ReadOnly);
	AdditionalParameters = New Structure;
	OpenForm(
		"Catalog.DiscountsMarkups.Form.SpecifyAmountOfDiscountMarkup",
		FormParameters,
		ThisObject,
		UUID,,,
		New CallbackDescription("EditingClarificationOfValueOfDiscountMarginCompletion", ThisObject, AdditionalParameters));
	
EndProcedure

&AtClient
Procedure ItemListURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
		
	If Not ValueIsFilled(Object.Ref) Then
		
		Buttons = New ValueList;
		Buttons.Add("Write", NStr("vi = 'Ghi lại';
									|ru = 'Записать';
									|en = 'Save'; fa = 'ذخیره';
									|it = 'Salvare';
									|pl = 'Save';
									|tr = 'Kaydet'"));
		Buttons.Add("Cancel", NStr("vi = 'Hủy bỏ';
									|ru = 'Отмена';
									|en = 'Cancel'; fa = 'انصراف';
									|it = 'Annulla';
									|pl = 'Cancel';
									|tr = 'İptal'"));
		
		ShowQueryBox(
			New CallbackDescription("ProcessingIssueAlertBeforeOpeningProductList", ThisObject),
			NStr("vi = 'Để thay đổi trạng thái hiệu lực, cần ghi lại chiết khấu (phụ thu).';
				|ru = 'Для изменения статуса действия скидка (наценка) должна быть записана.';
				|en = 'Discount (markup) must be saved to change the action status.'; fa = 'Discount (markup) must be saved to change the action status.';
				|it = 'Per modificare lo stato di validità lo sconto (sovrapprezzo) deve essere registrato.';
				|pl = 'Aby zmienić status działania, rabat (marża) musi być zapisany.';
				|tr = 'Eylemin durumunu değiştirmek için indirim (zam) uygulanmalıdır.'"),
			Buttons,,,NStr("vi = 'Chưa ghi lại chiết khấu (phụ thu)';
							|ru = 'Скидка (наценка) не записана';
							|en = 'Discount (markup) is not saved'; fa = 'Discount (markup) is not saved';
							|it = 'Lo sconto (sovrapprezzo) non è registrato';
							|pl = 'Rabat (marża) nie jest zapisany';
							|tr = 'İndirim (zam) uygulanmadı'"));
		
	Else
		
		DataParameters = New Structure;
		DataParameters.Insert("Source", Object.Ref);
		OpenForm(
			"InformationRegister.ValidityOfDiscountsMarkupsByItems.Form.ItemList",
			DataParameters,,,,,
			New CallbackDescription("ValidityOfDiscountsMarkupsByItemsCompletion", ThisObject));
		
	EndIf;
	
EndProcedure

&AtClient
Procedure MethodsOfProvidingClearing(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure ItemFilterOptionClearing(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SelectTerms(Command)
	
	ListOfTermsOfService = New ValueList();
	For Each CurRow In Object.DiscountMarkupConditions Do
		ListOfTermsOfService.Add(CurRow.DiscountMarkupCondition);
	EndDo;
	
	FormParameters = New Structure;
	FormParameters.Insert("Document",      Object.Ref);
	FormParameters.Insert("DiscountMarkupConditions", ListOfTermsOfService);
	OpenForm(
		"Catalog.DiscountMarkupTerms.Form.PickForm",
		FormParameters,
		ThisObject,,,, New CallbackDescription("SelectTermsCompletion", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure SelectTermsCompletion(Result, AdditionalParameters) Export
	
	ListOfTermsOfService = Result;
	
	If ListOfTermsOfService <> Undefined Then
		
		Object.DiscountMarkupConditions.Clear();
		
		For Each CurRow In ListOfTermsOfService Do
			
			NewRow = Object.DiscountMarkupConditions.Add();
			NewRow.DiscountMarkupCondition = CurRow.Value;
			
		EndDo;
		
		UpdateAutoNaming(True);
		ChangeVisibilityOfElements();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)
	
	ProcedureParameters = TMCommonUseClient.PermissionParametersForEditingItemDetails();
	ProcedureParameters.NotificationAboutUnblocking = New CallbackDescription("AllowObjectAttributeEditCompletion", ThisObject);
	
	TMCommonUseClient.AllowObjectAttributeEdit(ThisObject, ProcedureParameters );
	
EndProcedure

&AtClient
Procedure SmartRoundingConstructor(Command)
	
	EditResult = Undefined;
	
	FormParameters = New Structure;
	FormParameters.Insert("RoundingPrecision", Object.RoundingPrecision);
	FormParameters.Insert("RoundOffOption", Object.RoundOffOption);
	FormParameters.Insert("SmartRounding", Object.SmartRounding);
	FormParameters.Insert("PriceRangeBoundary", Object.DiscountMarkupValue);
	FormParameters.Insert("ExampleNumber", Object.DiscountMarkupValue);
	
	OpenForm("Catalog.TypesOfPrices.Form.SmartRoundingConstructorForm",
		FormParameters,,,,,
		New CallbackDescription("SmartRoundingConstructorCompletion",
			ThisObject),
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure SmartRoundingConstructorCompletion(Result, AdditionalParameters) Export
	
	EditResult = Result;
	
	If EditResult <> Undefined Then
		Object.SmartRounding = EditResult.SmartRounding;
		Object.RoundingPrecision = EditResult.RoundingPrecision;
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

&AtClient
Procedure OpenSelectedTerm(Command)

	OpenTermsOfService();

EndProcedure

&AtClient
Procedure Attachable_ExecuteCommandToCreateConditionsForProvisionOfDiscountsMargins(Command)
	
	DiscountsMarkupsClient.ProcessCommandToAddConditionsForGrantingDiscountsMarkups(
		ThisObject,
		Command,
		Undefined);
	
EndProcedure

&AtClient
Procedure ShowTheExternalProcessingSettingsForm(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("AddressOfExternalDataProcessorSettings", AddressOfExternalDataProcessorSettings);
	OpenForm(
		NameOfExternalDataProcessorSettingForm,
		FormParameters,
		ThisObject,,,,
		New CallbackDescription("ChangedExternalProcessingSettings", ThisObject));
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
	
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	
	ExecuteCommandAtServer(ExecutionParameters);
	
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
	
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion

#Region Private

#Region OnChangeAttributes

&AtServer
Function TypeOfLoyaltyCardWhenChangedOnServer()
	
	If ValueIsFilled(Object.LoyaltyCardKind) Then
		
		Return Not ThereIsConditionLoyaltyCardIsNotRegistered(
			Object.DiscountMarkupConditions.Unload().UnloadColumn("DiscountMarkupCondition"),
			Object.LoyaltyCardKind);
		
	Else
		
		Return False;
		
	EndIf;
	
EndFunction

&AtServer
Function MethodOfRenderingWhenChangedOnServer()
	
	ChangeVisibilityOfElements();
	
	If Object.MethodsOfProviding = Enums.MethodsToProvideDiscountsMarkups.LoyaltyCard
		And ValueIsFilled(Object.LoyaltyCardKind) Then
		
		Return Not ThereIsConditionLoyaltyCardIsNotRegistered(
			Object.DiscountMarkupConditions.Unload().UnloadColumn("DiscountMarkupCondition"),
			Object.LoyaltyCardKind);
		
	Else
		
		Return False;
		
	EndIf;
	
EndFunction

#EndRegion

#Region Other

&AtClientAtServerNoContext
Function AutoDescription(Form)
	
	Form.Items.Description.ChoiceList.Clear();
	Object = Form.Object;
	
	NameString_ = "";
	If Object.MethodsOfProviding = PredefinedValue("Enum.MethodsToProvideDiscountsMarkups.Percent") Then
		
		If Object.DiscountApplicationMethod <> PredefinedValue("Enum.DiscountMarkupApplicationMethods.GrantBonusPoints") Then
			NameString_ = String(Object.DiscountMarkupValue) + "%";
		Else
			NameString_ = StrTemplate(NStr("vi = '%1%3, chương trình điểm thưởng %2';
											|ru = '%1%3, бонусная программа %2';
											|en = '%1%3, bonus program %2'; fa = '%1%3, bonus program %2';
											|it = '%1%3, raccolta punti %2';
											|pl = '%1%3, program bonusowy %2';
											|tr = '%1%3, %2 bonus programı'"), Object.DiscountMarkupValue, Object.LoyaltyProgram, "%");
		EndIf;
		
	ElsIf Object.MethodsOfProviding = PredefinedValue("Enum.MethodsToProvideDiscountsMarkups.Sum") Then
		
		If Object.DiscountApplicationMethod <> PredefinedValue("Enum.DiscountMarkupApplicationMethods.GrantBonusPoints") Then
			NameString_ = StrTemplate("%1 %2", Object.DiscountMarkupValue, Object.DiscountMarkupCurrency);
		Else
			NameString_ = StrTemplate(NStr("vi = '%1 chương trình điểm thưởng %2';
											|ru = '%1 бонусной программы %2';
											|en = '%1 of bonus program %2'; fa = '%1 of bonus program %2';
											|it = '%1 della raccolta punti %2';
											|pl = '%1 programu bonusowego %2';
											|tr = '%2 bonus programındaki %1'"),
				StringFunctionsClientServer.NumberInDigitsUnitOfMeasurementInWords(Object.DiscountMarkupValue, NStr("vi = 'điểm, điểm, điểm';
																													|ru = 'балл, баллов, баллов';
																													|en = 'point, points, points'; fa = 'point, points, points';
																													|it = 'punto, dei punti, dei punti';
																													|pl = 'punkt, punktów, punktów';
																													|tr = 'puan, puan, puan'")),
				Object.LoyaltyProgram);
		EndIf;
		
	ElsIf Object.MethodsOfProviding = PredefinedValue("Enum.MethodsToProvideDiscountsMarkups.DiscountMarkupAsAmountForEachRow") Then
		
		NameString_ = StrTemplate("%1 %2", Object.DiscountMarkupValue, Object.DiscountMarkupCurrency);
		
	ElsIf Object.MethodsOfProviding = PredefinedValue("Enum.MethodsToProvideDiscountsMarkups.PriceKind") Then
		
		NameString_ = StrTemplate(NStr("vi = 'Dạng giá: %1';
										|ru = 'Вид цены: %1';
										|en = 'Price type: %1'; fa = 'Price type: %1';
										|it = 'Il tipo del prezzo: %1';
										|pl = 'Rodzaj ceny: %1';
										|tr = 'Fiyat türü: %1'"), Object.PriceKind);
		
	ElsIf Object.MethodsOfProviding = PredefinedValue("Enum.MethodsToProvideDiscountsMarkups.Message") Then
		
		NameString_ = StrTemplate(NStr("vi = 'Thông báo: %1';
										|ru = 'Сообщение: %1';
										|en = 'Message: %1'; fa = 'Message: %1';
										|it = 'Il messaggio: %1';
										|pl = 'Wiadomość: %1';
										|tr = 'Mesaj: %1'"), Object.MessageText);
		
	ElsIf Object.MethodsOfProviding = PredefinedValue("Enum.MethodsToProvideDiscountsMarkups.LoyaltyCard") Then
		
		NameString_ = StrTemplate(NStr("vi = 'Thẻ khách hàng thân thiết: %1';
										|ru = 'Карта лояльности: %1';
										|en = 'Loyalty card: %1'; fa = 'Loyalty card: %1';
										|it = 'La carta di fedeltà: %1';
										|pl = 'Karta lojalnościowa: %1';
										|tr = 'Sadakat kartı: %1'"), Object.LoyaltyCardKind);
		
	ElsIf Object.MethodsOfProviding = PredefinedValue("Enum.MethodsToProvideDiscountsMarkups.Count") Then
		
		NameString_ = StrTemplate(
			NStr("vi = 'Miễn phí %1 đơn vị trong số %2 đơn vị';
				|ru = 'Бесплатно %1 ед. из %2 ед.';
				|en = 'Free %1 units from %2 units'; fa = 'Free %1 units from %2 units';
				|it = 'Gratuiti %1 pezzi da %2 pezzi.';
				|pl = 'Bezpłatnie %1 jedn. z %2 jedn.';
				|tr = '%2 birimi üzerinden ücretsiz %1 birim'"),
			Object.DiscountMarkupValue,
			Object.DiscountConditionByQuantity);
		
	ElsIf Object.MethodsOfProviding = PredefinedValue("Enum.MethodsToProvideDiscountsMarkups.Gift") Then
		
		If ValueIsFilled(Object.GiftSegment) Then
			NameString_ = StrTemplate(
				NStr("vi = '%1 đơn vị trong phân khúc %2 để làm quà tặng';
					|ru = '%1 ед. из сегмента %2 в подарок';
					|en = '%1 units as a gift from segment %2'; fa = '%1 units as a gift from segment %2';
					|it = '%1 pz. dal segmento %2 in omaggio';
					|pl = '%1 jedn. z segmentu %2 w prezencie';
					|tr = 'Hediye olarak %2 segmentinden %1 birim'"),
				Object.DiscountMarkupValue,
				Object.GiftSegment);
		Else
			NameString_ = StrTemplate(
				NStr("vi = '%1 đơn vị trong chứng từ để làm quà tặng';
					|ru = '%1 ед. из документа в подарок';
					|en = '%1 units as a gift from the document'; fa = '%1 units as a gift from the document';
					|it = '%1 pz. dal documento in omaggio';
					|pl = '%1 jedn. z dokumentu w prezencie';
					|tr = 'Hediye olarak belgeden %1 birim'"),
				Object.DiscountMarkupValue);
		EndIf;
		
	ElsIf Object.MethodsOfProviding = PredefinedValue("Enum.MethodsToProvideDiscountsMarkups.RoundDocumentAmount") Then
		
		NameString_ = StrTemplate(
			NStr("vi = 'Làm tròn số tiền chứng từ, phần thập phân %1';
				|ru = 'Округление суммы документа, точность %1';
				|en = 'Document amount rounding, precision %1'; fa = 'Document amount rounding, precision %1';
				|it = 'Arrotondamento dell''importo di documento, precisione %1';
				|pl = 'Zaokrąglenie kwoty dokumentu, dokładność %1';
				|tr = 'Belge tutarının yuvarlanması, duyarlılık %1'"),
			Object.RoundingPrecision);
			
	ElsIf TypeOf(Object.MethodsOfProviding) = Type("CatalogRef.AdditionalReportsAndDataProcessors") Then
		
		NameString_ = Form.AutomaticNamingOfExternalDataProcessor;
		
	EndIf;
	
	If Object.Managed Then
		NameString_ = NStr("vi = 'Ấn định thủ công:';
							|ru = 'Назначается вручную:';
							|en = 'Assigned manually:'; fa = 'Assigned manually:';
							|it = 'Viene assegnato a mano:';
							|pl = 'Przydzielane ręcznie:';
							|tr = 'Manuel olarak atanmaktadır:'") + " "+ NameString_;
	EndIf;
	
	If Object.DiscountApplicationMethod = PredefinedValue("Enum.DiscountMarkupApplicationMethods.GrantBonusPoints") Then
		NameString_ = NStr("vi = 'Điểm thưởng:';
							|ru = 'Бонус:';
							|en = 'Bonus:'; fa = 'Bonus:';
							|it = 'Omaggio:';
							|pl = 'Bonus:';
							|tr = 'Bonus:'") + " "+ NameString_;
	EndIf;
	
	Form.Items.Description.ChoiceList.Add(NameString_);
	
	If Object.DiscountMarkupConditions.Count() = 1 Then
		NameString_ = NameString_ + " ("+Object.DiscountMarkupConditions[0].DiscountMarkupCondition+")";
		Form.Items.Description.ChoiceList.Add(NameString_);
	ElsIf Object.DiscountMarkupConditions.Count() > 1 Then
		
		NumberOfConditions = Object.DiscountMarkupConditions.Count();
		
		If NumberOfConditions >= 2 Then
			NameString_ = NameString_ + " " +NStr("vi = '(nhiều điều kiện)';
													|ru = '(несколько условий)';
													|en = '(several conditions)'; fa = '(several conditions)';
													|it = '(alcune condizioni)';
													|pl = '(kilka warunków)';
													|tr = '(birden fazla koşul)'");
			Form.Items.Description.ChoiceList.Add(NameString_);
		EndIf;
		
	ElsIf Object.DiscountMarkupConditions.Count() = 0 Then
		NameString_ = NameString_ + " " + NStr("vi = 'không điều kiện';
												|ru = 'без условий';
												|en = 'without conditions'; fa = 'without conditions';
												|it = 'senza condizioni';
												|pl = 'bez warunków';
												|tr = 'koşulsuz'");
		Form.Items.Description.ChoiceList.Add(NameString_);
	EndIf;
	
	If Object.PriceGroups.Count() > 0 Then
		NameString_ = NameString_ + " " +NStr("vi = '(có làm rõ theo nhóm giá)';
												|ru = '(с уточнением по ценовым группам)';
												|en = '(specification by price groups)'; fa = '(specification by price groups)';
												|it = '(con la puntualizzazione per i gruppi di prezzi)';
												|pl = '(z uściśleniem wg grup cen)';
												|tr = '(fiyat gruplarına göre iyileştirme ile)'");
		Form.Items.Description.ChoiceList.Add(NameString_);
	EndIf;
	
	If Form.AutomaticNamingIndex <= Form.Items.Description.ChoiceList.Count() - 1 Then
		Return Form.Items.Description.ChoiceList.Get(Form.AutomaticNamingIndex).Value;
	Else
		Return NameString_;
	EndIf;
	
EndFunction

&AtClient
Procedure UpdateAutoNaming(Refresh = True)
	
	Description = AutoDescription(ThisObject);
	If Not ValueIsFilled(Object.Description)
		Or (Refresh And AutoNameIsUsed And Not NameIsChangedByUser) Then
		Object.Description = Description;
		AutoNameIsUsed = True;
	EndIf;
	
EndProcedure

&AtServer
Procedure ChangeVisibilityOfElements()
	
	//Elements.Decorationapplication.Visibility = utilizationbonuseprogramme of loyalty;
	Items.HowToApplyTheDiscountDiscountMarkup.Visible = UseLoyaltyPrograms;
	Items.TheApplicationOfTheDiscountRewardPoints.Visible = UseLoyaltyPrograms;
	
	Items.Pages.CurrentPage.Visible = False;
	
	If Object.DiscountApplicationMethod = PredefinedValue("Enum.DiscountMarkupApplicationMethods.GrantBonusPoints") Then
		Items.Pages.CurrentPage = Items.BonusesPage;
	Else
		Items.Pages.CurrentPage = Items.DiscountPage;
	EndIf;
	Items.Pages.CurrentPage.Visible = True;
	
	Items.PageDescriptionBonusPoints.CurrentPage.Visible = False;
	If Object.DiscountApplicationMethod = PredefinedValue("Enum.DiscountMarkupApplicationMethods.GrantBonusPoints") Then
		If Object.MethodsOfProviding = PredefinedValue("Enum.MethodsToProvideDiscountsMarkups.Percent") Then
			Items.PageDescriptionBonusPoints.CurrentPage = Items.PageDescriptionBonusPoints.ChildItems.GroupDescriptionBonusesPercentage;
		ElsIf Object.MethodsOfProviding = PredefinedValue("Enum.MethodsToProvideDiscountsMarkups.Sum") Then
			Items.PageDescriptionBonusPoints.CurrentPage = Items.PageDescriptionBonusPoints.ChildItems.GroupDescriptionBonusesAmount;
		ElsIf TypeOf(Object.MethodsOfProviding) = Type("CatalogRef.AdditionalReportsAndDataProcessors") Then
			Items.PageDescriptionBonusPoints.CurrentPage = Items.PageDescriptionBonusPoints.ChildItems.GroupDescriptionBonusesExternalProcessing;
		EndIf;
		Items.PageDescriptionBonusPoints.CurrentPage.Visible = True;
	EndIf;
	
	Items.GroupExpirationDates.Visible = Object.DiscountApplicationMethod = PredefinedValue("Enum.DiscountMarkupApplicationMethods.GrantBonusPoints");
	
	VisibilityOfPriceGroups = False;
	
	Items.PageDescriptionDiscountsMarkups.CurrentPage.Visible = False;
	If Object.MethodsOfProviding = PredefinedValue("Enum.MethodsToProvideDiscountsMarkups.PriceKind") Then
		Items.PageDescriptionDiscountsMarkups.CurrentPage = Items.PageDescriptionDiscountsMarkups.ChildItems.GroupDiscountDescriptionPriceType;
	ElsIf Object.MethodsOfProviding = PredefinedValue("Enum.MethodsToProvideDiscountsMarkups.LoyaltyCard") Then
		Items.PageDescriptionDiscountsMarkups.CurrentPage = Items.PageDescriptionDiscountsMarkups.ChildItems.GroupDescriptionDiscountsLoyaltyCard;
	ElsIf Object.MethodsOfProviding = PredefinedValue("Enum.MethodsToProvideDiscountsMarkups.Count") Then
		Items.PageDescriptionDiscountsMarkups.CurrentPage = Items.PageDescriptionDiscountsMarkups.ChildItems.GroupDiscountDescriptionQuantity;
	ElsIf Object.MethodsOfProviding = PredefinedValue("Enum.MethodsToProvideDiscountsMarkups.RoundDocumentAmount") Then
		Items.PageDescriptionDiscountsMarkups.CurrentPage = Items.PageDescriptionDiscountsMarkups.ChildItems.GroupDiscountDescriptionRoundingUpTheAmount;
	ElsIf Object.MethodsOfProviding = PredefinedValue("Enum.MethodsToProvideDiscountsMarkups.Gift") Then
		Items.PageDescriptionDiscountsMarkups.CurrentPage = Items.PageDescriptionDiscountsMarkups.ChildItems.GroupDescriptionDiscountGift;
	ElsIf Object.MethodsOfProviding = PredefinedValue("Enum.MethodsToProvideDiscountsMarkups.Percent") Then
		VisibilityOfPriceGroups = True;
		Items.PageDescriptionDiscountsMarkups.CurrentPage = Items.PageDescriptionDiscountsMarkups.ChildItems.GroupDescriptionDiscountPercentage;
	ElsIf Object.MethodsOfProviding = PredefinedValue("Enum.MethodsToProvideDiscountsMarkups.Message") Then
		Items.PageDescriptionDiscountsMarkups.CurrentPage = Items.PageDescriptionDiscountsMarkups.ChildItems.GroupDiscountDescriptionMessage;
	ElsIf Object.MethodsOfProviding = PredefinedValue("Enum.MethodsToProvideDiscountsMarkups.Sum") Then
		Items.PageDescriptionDiscountsMarkups.CurrentPage = Items.PageDescriptionDiscountsMarkups.ChildItems.GroupDiscountDescriptionAmount;
	ElsIf Object.MethodsOfProviding = PredefinedValue("Enum.MethodsToProvideDiscountsMarkups.DiscountMarkupAsAmountForEachRow") Then
		VisibilityOfPriceGroups = True;
		Items.PageDescriptionDiscountsMarkups.CurrentPage = Items.PageDescriptionDiscountsMarkups.ChildItems.GroupDiscountDescriptionAmountForEachLine;
	ElsIf TypeOf(Object.MethodsOfProviding) = Type("CatalogRef.AdditionalReportsAndDataProcessors") Then
		Items.PageDescriptionDiscountsMarkups.CurrentPage = Items.PageDescriptionDiscountsMarkups.ChildItems.GroupDiscountDescriptionExternalProcessing;
		
		DescriptionOfTheExternalProcessingAction = DiscountsMarkupsServerCall.DescriptionOfTheExternalProcessingAction(
			Object.MethodsOfProviding,
			AddressOfExternalDataProcessorSettings);
		AutomaticNamingOfExternalDataProcessor = DiscountsMarkupsServerCall.AutomaticNamingOfExternalDataProcessor(
			Object.MethodsOfProviding,
			AddressOfExternalDataProcessorSettings);
		NameOfExternalDataProcessorSettingForm = DiscountsMarkupsServerCall.NameOfExternalDataProcessorSettingForm(
			Object.MethodsOfProviding,
			AddressOfExternalDataProcessorSettings);
		Items.ShowTheFormForExternalDiscountProcessingSettings.Visible = ValueIsFilled(NameOfExternalDataProcessorSettingForm);
		
	EndIf;
	Items.PageDescriptionDiscountsMarkups.CurrentPage.Visible = True;
	
	If Object.MethodsOfProviding = PredefinedValue("Enum.MethodsToProvideDiscountsMarkups.Percent") Then
		
		Items.ApplyMultiplicationWithinParentGroup.Visible       = True;
		Items.ApplyMultiplicationInTheFrameworkOfTheSuperordinateGroupBonuses.Visible = True;
		
		AdjustVisibilityAndAvailabilityOfAccountingItemsForAppliedDiscounts();
		
	Else
		
		Items.ApplyMultiplicationWithinParentGroup.Visible       = False;
		Items.ApplyMultiplicationInTheFrameworkOfTheSuperordinateGroupBonuses.Visible = False;
		
	EndIf;
	
	If Object.MethodsOfProviding = PredefinedValue("Enum.MethodsToProvideDiscountsMarkups.Sum")
		Or Object.MethodsOfProviding = PredefinedValue("Enum.MethodsToProvideDiscountsMarkups.DiscountMarkupAsAmountForEachRow")
		Or Object.MethodsOfProviding = PredefinedValue("Enum.MethodsToProvideDiscountsMarkups.Gift") Then
		
		Items.UseMultiplicityBonusesAmount.Visible          = True;
		Items.UseTheMultiplicityOfTheGift.Visible              = True;
		Items.UseMultipleSum.Visible                = True;
		Items.UseMultipleSumForEachRow.Visible = True;
		
	Else
		
		Items.UseMultiplicityBonusesAmount.Visible          = False;
		Items.UseTheMultiplicityOfTheGift.Visible              = False;
		Items.UseMultipleSum.Visible                = False;
		Items.UseMultipleSumForEachRow.Visible = False;
		
	EndIf;
	
	ConditionForFormOfPayment = ThereIsConditionForFormOfPayment(Object.DiscountMarkupConditions.Unload().UnloadColumn("DiscountMarkupCondition"));
	Items.InformationAboutUnsupportedDiscounts.Visible = ConditionForFormOfPayment;
	
EndProcedure

&AtServerNoContext
Function ThereIsConditionLoyaltyCardIsNotRegistered(ArrayOfConditions, LoyaltyCardKind)
	
	Query = New Query(
	"SELECT TOP 1
	|	Conditions.Ref
	|FROM
	|	Catalog.DiscountMarkupTerms AS Conditions
	|WHERE
	|	Conditions.DiscountMarkupCondition = VALUE(
	|		Enum.DiscountMarkupTerms.LoyaltyCardIsNotRegistered
	|	)
	|	AND Conditions.Ref IN(&ArrayOfConditions)
	|	AND Conditions.LoyaltyCardKind = &LoyaltyCardKind");
	
	Query.SetParameter("ArrayOfConditions",      ArrayOfConditions);
	Query.SetParameter("LoyaltyCardKind", LoyaltyCardKind);
	
	Result = Query.Execute();
	
	Return Not Result.IsEmpty();
	
EndFunction

&AtServerNoContext
Function ThereIsConditionForFormOfPayment(ArrayOfConditions)
	
	Query = New Query(
	"SELECT TOP 1
	|	Conditions.Ref AS Ref
	|FROM
	|	Catalog.DiscountMarkupTerms AS Conditions
	|WHERE
	|	Conditions.DiscountMarkupCondition = VALUE(Enum.DiscountMarkupTerms.ForPaymentForm)
	|	AND Conditions.Ref IN(&ArrayOfConditions)");
	
	Query.SetParameter("ArrayOfConditions", ArrayOfConditions);
	
	Result = Query.Execute();
	
	Return Not Result.IsEmpty();
	
EndFunction

&AtServer
Procedure AddConditionLoyaltyCardNotRegistered(LoyaltyCardKind)
	
	SetPrivilegedMode(True);
	Condition = Undefined;
	
	Query = New Query(
	"SELECT TOP 1
	|	Conditions.Ref
	|FROM
	|	Catalog.DiscountMarkupTerms AS Conditions
	|WHERE
	|	Conditions.DiscountMarkupCondition = VALUE(
	|		Enum.DiscountMarkupTerms.LoyaltyCardIsNotRegistered
	|	)
	|	AND Conditions.LoyaltyCardKind = &LoyaltyCardKind");
	
	Query.SetParameter("ReferencesArrray", Object.DiscountMarkupConditions.Unload().UnloadColumn("DiscountMarkupCondition"));
	Query.SetParameter("LoyaltyCardKind", LoyaltyCardKind);
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Condition = Selection.Ref;
	Else
		NewConditionObject = Catalogs.DiscountMarkupTerms.CreateItem();
		NewConditionObject.DiscountMarkupCondition = Enums.DiscountMarkupTerms.LoyaltyCardIsNotRegistered;
		NewConditionObject.LoyaltyCardKind =  LoyaltyCardKind;
		NewConditionObject.Description = StrTemplate(
			NStr("vi = 'Chưa ghi nhận thẻ khách hàng thân thiết ""%1""';
				|ru = 'Карта лояльности ""%1"" не зарегистрирована';
				|en = 'Loyalty card ""%1"" is not registered'; fa = 'Loyalty card ""%1"" is not registered';
				|it = 'La carta fedeltà ""%1"" non è registrata';
				|pl = 'Karta lojalnościowa ""%1"" nie jest zarejestrowana';
				|tr = '""%1"" sadakat kartı kaydedilmedi'"),
			LoyaltyCardKind);
		NewConditionObject.Write();
		Condition = NewConditionObject.Ref;
	EndIf;
	
	NewLine = Object.DiscountMarkupConditions.Add();
	NewLine.DiscountMarkupCondition = Condition;
	
EndProcedure

&AtServer
Procedure FillInListForSelectingDeliveryMethod(Form)
	
	Form.Items.MethodsOfProviding.ChoiceList.Clear();
	Form.Items.ProvisionMethodBonusPoints.ChoiceList.Clear();
	
	Variants = DiscountsMarkupsServer.AvailableDeliveryMethods();
	
	For Each KeyAndValue In Variants Do
		
		If KeyAndValue.Key = "BonusPoints" Then
			
			For Each ListItem In Variants.BonusPoints Do
				Form.Items.ProvisionMethodBonusPoints.ChoiceList.Add(ListItem.Value, ListItem.Presentation);
			EndDo;
			
		EndIf;
		
		If KeyAndValue.Key = "DiscountsMarkups" Then
			
			For Each ListItem In Variants.DiscountsMarkups Do
				Form.Items.MethodsOfProviding.ChoiceList.Add(ListItem.Value, ListItem.Presentation);
			EndDo;
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure HowToApplyDiscountWhenChangingOnServer()
	
	ChangeVisibilityOfElements();
	
EndProcedure

&AtServer
Procedure OnCreatReadAtServer()
	
	UseValidityPeriod         = ?(Object.NumberOfValidityPeriods > 0, 1, 0);
	UseActionStartDelay = ?(Object.NumberOfActionStartDelayPeriods > 0, 1, 0);
	
	GrantCurrencyDoNotUseMultipleCurrenciesView = String(IncomeAndExpensesServer.GetCurrencyOfManagementAccounting());
	
	UpdateUsageOfDiscountsMarkups();
	
	UpdatePresentationToClarifyValueOfMarkUpDiscount();
	
	ChangeAvailability(ThisObject);
	
EndProcedure

&AtServer
Procedure UpdateUsageOfDiscountsMarkups()
	
	UsingMarkUpDiscount = DiscountsMarkupsServer.UsingMarkUpDiscount(Object.Ref, CurrentSessionDate());
	DiscountsMarkupsServer.CreateInformationLabelUsingDiscountsMargins(InformationOnDiscountValidity,
	                                                                                UsingMarkUpDiscount,
	                                                                                "Change",
	                                                                                False);
	
	Items.InformationOnDiscountValidity.Height = ?(StrLen(InformationOnDiscountValidity) < 120 , 1, 2);
	
EndProcedure

&AtClientAtServerNoContext
Procedure ChangeAvailability(Form)
	
	Form.Items.GroupValidityPeriodRight.Enabled = (Form.UseValidityPeriod = 1);
	Form.Items.GroupDeferralRight.Enabled     = (Form.UseActionStartDelay = 1);
	
EndProcedure

&AtClient
Procedure OpenTermsOfService()
	
	CurrentData = Items.DiscountMarkupConditions.CurrentData;
	If CurrentData = Undefined Then
		ShowMessageBox(Undefined, NStr("vi = 'Chưa chọn điều kiện cho phép';
										|ru = 'Не выбрано условие предоставления';
										|en = 'Provision condition is not selected'; fa = 'Provision condition is not selected';
										|it = 'Non è selezionata la condizione della concessione';
										|pl = 'Nie wybrano warunku udzielenia';
										|tr = 'Sağlama koşulu seçilmedi'"));
		Return;
	EndIf;
	
	ShowValue(Undefined, CurrentData.DiscountMarkupCondition);
	
EndProcedure

&AtClient
Procedure OpenActionStatusChangeForm()
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("DiscountMarkup", Object.Ref);
	
	If (Not UseLoyaltyCards) And (Not UseSeveralWarehouses) And (Not ToUseTermsOfSales) Then
		
		OpeningParameters.Insert("Source", PredefinedValue("Catalog.Warehouses.EmptyRef"));
		OpenForm("Catalog.DiscountsMarkups.Form.SettingOfValidityStatus", OpeningParameters);
		
	Else
		
		OpenForm("Catalog.DiscountsMarkups.Form.DiscountMarkupValidity", OpeningParameters);
		
	EndIf;

EndProcedure

&AtClient
Procedure HandlingAlertIssueBeforeStatusChange(Result, AdditionalParameters) Export
	
	If Result = "Write" Then
		If Write() Then
			OpenActionStatusChangeForm();
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure ChangedExternalProcessingSettings(Result, AdditionalParameters) Export
	
	If ValueIsFilled(Result) Then
		
		DescriptionOfTheExternalProcessingAction = Result.DescriptionOfTheExternalProcessingAction;
		AutomaticNamingOfExternalDataProcessor = Result.AutomaticNamingOfExternalDataProcessor;
		
		UpdateAutoNaming(True);
		Modified = True;
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetSettingsForElementsOfProductConditionOptions(Form)
	
	Form.Items.ProductSegment.Visible = (Form.Object.ItemFilterOption = PredefinedValue("Enum.ItemFilterOptionsForDiscountMarkupCalculation.ProductSegment")
													Or Form.Object.ItemFilterOption = PredefinedValue("Enum.ItemFilterOptionsForDiscountMarkupCalculation.NotProductSegment"));
	Form.Items.ItemList.Visible = (Form.Object.ItemFilterOption = PredefinedValue("Enum.ItemFilterOptionsForDiscountMarkupCalculation.ItemList"));
	Form.Items.FilterPresentation.Visible = (Form.Object.ItemFilterOption = PredefinedValue("Enum.ItemFilterOptionsForDiscountMarkupCalculation.DataCompositionFilter"));
	
	DiscountsMarkupsClientServer.ConfigureSelectionHyperlinks(Form);
	
EndProcedure

&AtClient
Procedure ItemFilterOptionOnChange(Item)
	
	SetSettingsForElementsOfProductConditionOptions(ThisObject);
	
EndProcedure

&AtClient
Procedure ProcessingIssueAlertBeforeOpeningProductList(Result, AdditionalParameters) Export
	
	If Result = "Write" Then
		If Write() Then
			
			DataParameters = New Structure;
			DataParameters.Insert("Source", Object.Ref);
			OpenForm(
				"InformationRegister.ValidityOfDiscountsMarkupsByItems.Form.ItemList",
				DataParameters,,,,,
				New CallbackDescription("ValidityOfDiscountsMarkupsByItemsCompletion", ThisObject));
			
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure ValidityOfDiscountsMarkupsByItemsCompletion(Result, AdditionalParameters) Export
	
	DiscountsMarkupsClientServer.ConfigureHyperlinkToListOfItems(ThisObject);
	
EndProcedure

&AtServer
Function GetAddressesOfDataLayoutSchemeInTemporaryStorage(Name)
	
	Return DiscountsMarkupsServerCall.GetAddressesOfDataLayoutSchemeInTemporaryStorage(ThisObject, Name);
	
EndFunction

&AtServer
Procedure ApplyTheChanges(Result, Name)
	
	Settings = GetFromTempStorage(Result);
	ThisObject[Name].LoadSettings(Settings);
	
	DiscountsMarkupsClientServer.ConfigureSelectionHyperlinks(ThisObject);

EndProcedure

// Parameters:
// 	Result - Undefined, String - the result of editing (the address of the temporary storage).
// 	AdditionalParameters - Structure - with properties:
// 		* Name - String - 
&AtClient
Procedure EditDataCompositionSchemaCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	ApplyTheChanges(Result, AdditionalParameters.Name);
	
EndProcedure

&AtServer
Function AddressForSpecifyingDiscountMarkUpValueInTemporaryStorage()

	Return PutToTempStorage(Object.PriceGroups.Unload(), UUID);

EndFunction

&AtServer
Procedure LoadConstraintsForDiscountMarkUpValueFromTemporaryStorage(Address)
	
	ValueTable = GetFromTempStorage(Address);
	
	Object.PriceGroups.Load(ValueTable);
	
	Modified = True;
	
	UpdatePresentationToClarifyValueOfMarkUpDiscount();
	
EndProcedure

&AtClient
Procedure EditingClarificationOfValueOfDiscountMarginCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		LoadConstraintsForDiscountMarkUpValueFromTemporaryStorage(Result);
		UpdateAutoNaming(True);
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdatePresentationToClarifyValueOfMarkUpDiscount()
	
	If Object.PriceGroups.Count() = 0 Then
		ClarificationByPriceGroupPresentation = New FormattedString(NStr("vi = 'Làm rõ';
																		|ru = 'Уточнить';
																		|en = 'Specify'; fa = 'تعیین';
																		|it = 'Specificare';
																		|pl = 'Uściślij';
																		|tr = 'İyileştir'"),,,,"Change");
	Else
		ClarificationByPriceGroupPresentation = New FormattedString(NStr("vi = 'Có xác định';
																		|ru = 'Есть уточнения';
																		|en = 'There are clarifications'; fa = 'There are clarifications';
																		|it = 'Ci sono le precisazioni';
																		|pl = 'Istnieją uściślenia';
																		|tr = 'İyileştirmeler mevcut'"),,,,"Change");
	EndIf;
	
EndProcedure

&AtClient
Procedure ValueOfDiscountMarkUpQuantityTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	If StrFind(Text, "-") > 0 Then
		ClearMessages();
		CommonClientServer.MessageToUser(NStr("vi = 'Đối với kiểu chiết khấu ""Chiết khấu số lượng"", trường ""Miễn phí"" không thể nhỏ hơn 0';
												|ru = 'Для типа скидки ""Скидка количеством"", поле ""Бесплатно"" не может быть меньше 0';
												|en = 'For the discount type ""Discount by amount"" ""Free"" field cannot be less than 0'; fa = 'For the discount type ""Discount by amount"" ""Free"" field cannot be less than 0';
												|it = 'Per il tipo di sconto ""Sconto quantità"", campo ""Gratuito"" non può essere inferiore a 0';
												|pl = 'Dla rodzaju rabatu ""Rabat ilością"", pole ""Za darmo"" nie może być mniejsze niż 0';
												|tr = '""Miktar İndirimi"" indirim tipi için ""Ücretsiz"" alanı 0''dan az olamaz'"),,,,);	
	EndIf;  
EndProcedure

&AtClient
Procedure TheValueOfTheDiscountMarkUpGiftTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	If StrFind(Text, "-") > 0 Then
		ClearMessages();
		CommonClientServer.MessageToUser(NStr("vi = 'Đối với kiểu chiết khấu ""Quà tặng"", trường ""Giá trị"" không thể nhỏ hơn 0';
												|ru = 'Для типа скидки ""Подарок"", поле ""Стоимость"" не может быть меньше 0';
												|en = 'For the discount type ""Gift"" ""Price"" field cannot be less than 0'; fa = 'For the discount type ""Gift"" ""Price"" field cannot be less than 0';
												|it = 'Per il tipo di sconto ""Omaggio"", il campo ""Costo"" non può essere inferiore a 0';
												|pl = 'Dla rodzaju rabatu ""Prezent"", pole ""Cena"" nie może być mniejsze niż 0';
												|tr = '""Hediye"" indirim türü için ""Maliyet"" alanı 0''dan az olamaz'"),,,,);	
	EndIf;

EndProcedure

&AtServer
Procedure AdjustVisibilityAndAvailabilityOfAccountingItemsForAppliedDiscounts()
	
	If Not Items.MethodsOfProviding.Enabled Then
		Return;
	EndIf;
	
	VariantOfJointApplicationOfGroup = Common.ObjectAttributeValue(Object.Parent, "JointApplicationOption");
	
	If Object.MethodsOfProviding = PredefinedValue("Enum.MethodsToProvideDiscountsMarkups.Percent")
		And VariantOfJointApplicationOfGroup = Enums.OptionsOfJointUsageOfDiscountsAndMarkups.Multiplication Then

		Items.ApplyMultiplicationWithinParentGroup.Enabled = 
														Not Object.ApplyMultiplicationWithinParentGroup;
														
	Else
		Items.ApplyMultiplicationWithinParentGroup.Enabled = True;
	EndIf;

EndProcedure

&AtClient
Procedure AllowObjectAttributeEditCompletion(Result, AdditionalParameters) Export
	
	AdjustVisibilityAndAvailabilityOfAccountingItemsForAppliedDiscounts();

EndProcedure

&AtServer
Procedure SetDiscountTrackingSettings()
	
	If Not Object.ApplyMultiplicationWithinParentGroup Then
		VariantOfJointApplicationOfGroup = Common.ObjectAttributeValue(Object.Parent, "JointApplicationOption");
		
		Object.ApplyMultiplicationWithinParentGroup = 
				Object.MethodsOfProviding = Enums.MethodsToProvideDiscountsMarkups.Percent 
				And VariantOfJointApplicationOfGroup = Enums.OptionsOfJointUsageOfDiscountsAndMarkups.Multiplication;
	EndIf;
	
	AdjustVisibilityAndAvailabilityOfAccountingItemsForAppliedDiscounts();
	
EndProcedure

#EndRegion

#EndRegion
