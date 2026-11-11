
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);

	// Handler of the "Versioning of objects" mechanism
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	If Not ValueIsFilled(Object.Ref)
		And Not ValueIsFilled(Object.Parent)
		And ValueIsFilled(Parameters.DataToFillInForTheParent) Then
		
		Query = New Query(
		"SELECT
		|	DiscountMarkupTerms.IsFolder AS IsFolder,
		|	DiscountMarkupTerms.Parent AS Parent
		|FROM
		|	Catalog.DiscountMarkupTerms AS DiscountMarkupTerms
		|WHERE
		|	DiscountMarkupTerms.Ref = &Ref");
		
		Query.SetParameter("Ref", Parameters.DataToFillInForTheParent);
		
		Result = Query.Execute();
		Selection = Result.Select();
		
		If Selection.Next() Then
		
			If Selection.IsFolder Then
				Object.Parent = Parameters.DataToFillInForTheParent;
			Else
				Object.Parent = Selection.Parent;
			EndIf;
		
		EndIf;
		
	EndIf;
	
	If Object.Ref.IsEmpty() Then
		DiscountsMarkupsServer.OnCreatReadAtServer(ThisObject);
	EndIf;
	
	RestrictionCurrencyDoNotUseSeveralCurrencies = Object.RestrictionCurrency;
	
	// Handler of the subsystem prohibiting editing of object details
	ObjectAttributesLock.LockAttributes(ThisObject);
	
	SetSettingsForElementsOfProductConditionOptions(ThisObject, "ForOneTimeSalesVolume");
	SetSettingsForElementsOfProductConditionOptions(ThisObject, "ForAccumulatedSalesVolume");
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	// Handler of the subsystem prohibiting editing of object details
	ObjectAttributesLock.LockAttributes(ThisForm);

	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);

EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	DiscountsMarkupsClient.UpdateAutoNamingDiscountTermsAndConditions(ThisObject, Modified);
	
	If Object.ItemFilterOption = PredefinedValue("Enum.ItemFilterOptionsForDiscountMarkupCalculation.DataCompositionFilter")
		And Not ValueIsFilled(String(SettingsComposerFilterByProducts.Settings.Filter))
		And (Object.DiscountMarkupCondition = PredefinedValue("Enum.DiscountMarkupTerms.ForAccumulatedSalesVolume")
			Or Object.DiscountMarkupCondition = PredefinedValue("Enum.DiscountMarkupTerms.ForOneTimeSalesVolume")) Then
			CommonClientServer.MessageToUser(
				NStr("vi = 'Chưa đặt bộ lọc mặt hàng';
					|ru = 'Не установлен отбор номенклатуры';
					|en = 'Item filter is not set'; fa = 'Item filter is not set';
					|it = 'Non è selezionata la scelta di articolo';
					|pl = 'Nie ustawiono wyboru towarów';
					|tr = 'Öğe filtresi yapılandırılmadı'"),,"SettingsComposerFilterByProductsPresentation",, Cancel);
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)

	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	DiscountsMarkupsServer.BeforeWriteAtServer(ThisObject, CurrentObject, "DiscountMarkupCondition");
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	DiscountsMarkupsServer.OnCreatReadAtServer(ThisForm, CurrentObject);
	
	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DescriptionOnChange(Item)
	
	DiscountsMarkupsClientServer.UpdateAutoNamingDetails(ThisObject);
	
EndProcedure

&AtClient
Procedure ComparisonTypeSSLOnChange(Item)
	DiscountsMarkupsClient.UpdateAutoNamingDiscountTermsAndConditions(ThisObject, True);
EndProcedure

&AtClient
Procedure MeaningOfTheTermsOfServiceOnChange(Item)
	DiscountsMarkupsClient.UpdateAutoNamingDiscountTermsAndConditions(ThisObject, True);
EndProcedure

&AtClient
Procedure RestrictionCurrencyOnChange(Item)
	DiscountsMarkupsClient.UpdateAutoNamingDiscountTermsAndConditions(ThisObject, True);
EndProcedure

&AtClient
Procedure ProductSegmentOnChange(Item)
	DiscountsMarkupsClient.UpdateAutoNamingDiscountTermsAndConditions(ThisObject, True);
EndProcedure

&AtClient
Procedure AccumulationOptionOnChange(Item)
	DiscountsMarkupsClient.UpdateAutoNamingDiscountTermsAndConditions(ThisObject, True);
EndProcedure

&AtClient
Procedure AccumulationPeriodOnChange(Item)
	DiscountsMarkupsClient.UpdateAutoNamingDiscountTermsAndConditions(ThisObject, True);
EndProcedure

&AtClient
Procedure TheTypeOfComparisonForTheAccumulatedVolumeOfSalesOnChange(Item)
	DiscountsMarkupsClient.UpdateAutoNamingDiscountTermsAndConditions(ThisObject, True);
EndProcedure

&AtClient
Procedure TheValueOfTheProvisionConditionForTheAccumulatedSalesVolumeOnChange(Item)
	DiscountsMarkupsClient.UpdateAutoNamingDiscountTermsAndConditions(ThisObject, True);
EndProcedure

&AtClient
Procedure CurrencyOfTheLimitForTheAccumulatedSalesVolumeOnChange(Item)
	DiscountsMarkupsClient.UpdateAutoNamingDiscountTermsAndConditions(ThisObject, True);
EndProcedure

&AtClient
Procedure ItemSegmentForAccumulatedSalesVolumeOnChange(Item)
	DiscountsMarkupsClient.UpdateAutoNamingDiscountTermsAndConditions(ThisObject, True);
EndProcedure

&AtClient
Procedure PaymentScheduleOnChange(Item)
	DiscountsMarkupsClient.UpdateAutoNamingDiscountTermsAndConditions(ThisObject, True);
EndProcedure

&AtClient
Procedure ProductSegmentRestrictionsOnChange(Item)
	DiscountsMarkupsClient.UpdateAutoNamingDiscountTermsAndConditions(ThisObject, True);
EndProcedure

&AtClient
Procedure TimeOfValidityOnChange(Item)
	DiscountsMarkupsClient.UpdateAutoNamingDiscountTermsAndConditions(ThisObject, True);
EndProcedure

&AtClient
Procedure PaymentMethodOnChange(Item)
	DiscountsMarkupsClient.UpdateAutoNamingDiscountTermsAndConditions(ThisObject, True);
EndProcedure

&AtClient
Procedure UsersGroupOnChange(Item)
	DiscountsMarkupsClient.UpdateAutoNamingDiscountTermsAndConditions(ThisObject, True);
EndProcedure

&AtClient
Procedure LoyaltyCardKindOnChange(Item)
	DiscountsMarkupsClient.UpdateAutoNamingDiscountTermsAndConditions(ThisObject, True);
EndProcedure

&AtClient
Procedure NumberOfAccumulationPeriodsOnChange(Item)
	DiscountsMarkupsClient.UpdateAutoNamingDiscountTermsAndConditions(ThisObject, True);
EndProcedure

&AtClient
Procedure DiscountMarkupConditionOnChange(Item)
	
	DiscountsMarkupsClientServer.ProvisionConditionWhenChangedOnServer(ThisObject);
	Object.Description = "";
	
	DiscountsMarkupsClient.UpdateAutoNamingDiscountTermsAndConditions(ThisObject, True);
	
EndProcedure

&AtClient
Procedure OptionOfCumulativeQuantityDiscountPeriodDeterminationOnChange(Item)
	
	DiscountsMarkupsClientServer.OptionForDeterminingCumulativeDiscountPeriodWhenChangingOnServer(ThisObject);
	
	DiscountsMarkupsClient.UpdateAutoNamingDiscountTermsAndConditions(ThisObject, True);
	
EndProcedure

&AtClient
Procedure ApplicationCriteriaForTheVolumeOfSalesWhenChanging(Item)
	
	DiscountsMarkupsClientServer.CriteriaForApplyingForSalesVolumeWhenChangingOnServer(ThisObject);
	
	DiscountsMarkupsClientServer.RoundUpValueOfRestrictionCondition(
		Object.CriteriaOfApplicationLimitationForSalesVolume,
		Object.RestrictionConditionValue);
	
	DiscountsMarkupsClient.UpdateAutoNamingDiscountTermsAndConditions(ThisObject, True);
	
EndProcedure

&AtClient
Procedure ItemFilterOptionOnChange(Item)
	
	SetSettingsForElementsOfProductConditionOptions(ThisObject, "ForOneTimeSalesVolume");
	SetSettingsForElementsOfProductConditionOptions(ThisObject, "ForAccumulatedSalesVolume");
	
	DiscountsMarkupsClient.UpdateAutoNamingDiscountTermsAndConditions(ThisObject, True);
	
EndProcedure

&AtClient
Procedure TheDecorationDescriptionIsSuppliedByExternalDiscountProcessingURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	ShowValue(Undefined, Object.DiscountMarkupCondition);
	
EndProcedure

&AtClient
Procedure FilterForOneTimeSalesVolumeURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	DiscountsMarkupsClient.ConfigureFilter(
		ThisObject,
		FormattedStringURL,
		GetAddressesOfDataLayoutSchemeInTemporaryStorage(FormattedStringURL));
	
EndProcedure

&AtClient
Procedure FilterForAccumulatedSalesVolumeURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	DiscountsMarkupsClient.ConfigureFilter(
		ThisObject,
		FormattedStringURL,
		GetAddressesOfDataLayoutSchemeInTemporaryStorage(FormattedStringURL));
	
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
			New CallbackDescription("ProcessingIssueAlertBeforeOpeningProductList", ThisForm),
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
Procedure DiscountMarkupConditionClearing(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)
	
	ProcedureParameters = TMCommonUseClient.PermissionParametersForEditingItemDetails();
	ProcedureParameters.NotificationAboutUnblocking = New CallbackDescription("AllowObjectAttributeEditCompletion", ThisObject);
	TMCommonUseClient.AllowObjectAttributeEdit(ThisForm, ProcedureParameters);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

&AtClient
Procedure ShowTheExternalProcessingSettingsForm(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("AddressOfExternalDataProcessorSettings", AddressOfExternalDataProcessorSettings);
	OpenForm(
		NameOfExternalDataProcessorSettingForm,
		FormParameters,
		ThisForm,,,,
		New CallbackDescription("ChangedExternalProcessingSettings", ThisObject));
	
EndProcedure

#EndRegion

#Region Private

#Region OnChangeAttributes

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
	
	DiscountsMarkupsClient.UpdateAutoNamingDiscountTermsAndConditions(ThisObject, True);
	
EndProcedure

// Parameters:
// 	Result - Undefined, String - result of schema editing (temporary storage address)
// 	AdditionalParameters - Structure - with properties:
// 		* Name - String - 
&AtClient
Procedure EditDataCompositionSchemaCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	ApplyTheChanges(Result, AdditionalParameters.Name);
	
	DiscountsMarkupsClient.UpdateAutoNamingDiscountTermsAndConditions(ThisObject, True);
	
EndProcedure

&AtClient
Procedure ChangedExternalProcessingSettings(Result, AdditionalParameters) Export
	
	If ValueIsFilled(Result) Then
		
		DescriptionOfTheExternalProcessingAction = Result.DescriptionOfTheExternalProcessingAction;
		AutomaticNamingOfExternalDataProcessor = Result.AutomaticNamingOfExternalDataProcessor;
		
		DiscountsMarkupsClient.UpdateAutoNamingDiscountTermsAndConditions(ThisObject, True);
		Modified = True;
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetSettingsForElementsOfProductConditionOptions(Form, GroupName)
	
	If GroupName = "ForOneTimeSalesVolume" Then
		Form.Items.ItemSegmentPerOneTimeSalesVolume.Enabled = (Form.Object.ItemFilterOption = PredefinedValue("Enum.ItemFilterOptionsForDiscountMarkupCalculation.ProductSegment"))
			And Not Form.Items.ItemSelectionOptionForAOneTimeSalesVolumeItemSegment.ReadOnly;
		Form.Items.ListOfItemsForOneTimeSalesVolume.Enabled = (Form.Object.ItemFilterOption = PredefinedValue("Enum.ItemFilterOptionsForDiscountMarkupCalculation.ItemList"))
			And Not Form.Items.ItemSelectionOptionForAOneTimeSalesVolumeItemList.ReadOnly;
		Form.Items.FilterForOneTimeSalesVolume.Enabled = (Form.Object.ItemFilterOption = PredefinedValue("Enum.ItemFilterOptionsForDiscountMarkupCalculation.DataCompositionFilter"))
			And Not Form.Items.OptionForSelectingAnItemForAOneTimeSalesVolumeSelectionOfTheDataLayout.ReadOnly;
	ElsIf GroupName = "ForAccumulatedSalesVolume" Then
		Form.Items.ItemSegmentForAccumulatedSalesVolume.Enabled = (Form.Object.ItemFilterOption = PredefinedValue("Enum.ItemFilterOptionsForDiscountMarkupCalculation.ProductSegment"))
			And Not Form.Items.ItemSelectionOptionForAccumulatedSalesVolumeItemSegment.ReadOnly;
		Form.Items.ListOfItemsForAccumulatedSalesVolume.Enabled = (Form.Object.ItemFilterOption = PredefinedValue("Enum.ItemFilterOptionsForDiscountMarkupCalculation.ItemList"))
			And Not Form.Items.ItemSelectionOptionForAccumulatedSalesItemList.ReadOnly;
		Form.Items.FilterForAccumulatedSalesVolume.Enabled = (Form.Object.ItemFilterOption = PredefinedValue("Enum.ItemFilterOptionsForDiscountMarkupCalculation.DataCompositionFilter"))
			And Not Form.Items.OptionForSelectingTheItemForTheAccumulatedSalesVolumeSelectionOfTheDataLayout.ReadOnly;
	Else
		Raise NStr("vi = 'Tên nhóm không xác định';
					|ru = 'Неизвестное имя группы';
					|en = 'Unknown group name'; fa = 'Unknown group name';
					|it = 'Nome del gruppo sconosciuto';
					|pl = 'Nieznana nazwa grupy';
					|tr = 'Bilinmeyen grup adı'") + " " + GroupName;
	EndIf;
	
	DiscountsMarkupsClientServer.ConfigureSelectionHyperlinks(Form);
	
EndProcedure

&AtClient
Procedure AllowObjectAttributeEditCompletion(Result, AdditionalParameters) Export
	
	SetSettingsForElementsOfProductConditionOptions(ThisObject, "ForOneTimeSalesVolume");
	SetSettingsForElementsOfProductConditionOptions(ThisObject, "ForAccumulatedSalesVolume");
	
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

#EndRegion

#EndRegion
