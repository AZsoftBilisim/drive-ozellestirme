
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If Object.Ref.IsEmpty() Then
		DiscountsMarkupsServer.OnCreatReadAtServer(ThisObject);
	EndIf;
	
	SetSettingsForElementsOfProductConditionOptions(ThisObject, "ForOneTimeSalesVolume");
	SetSettingsForElementsOfProductConditionOptions(ThisObject, "ForAccumulatedSalesVolume");
	
	RestrictionCurrencyDoNotUseSeveralCurrencies = Object.RestrictionCurrency;
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	// Handler of the subsystem prohibiting editing of object details
	ObjectAttributesLock.LockAttributes(ThisObject);
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning

EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	DiscountsMarkupsServer.OnCreatReadAtServer(ThisForm, CurrentObject);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
	// Handler of the subsystem prohibiting editing of object details
	ObjectAttributesLock.LockAttributes(ThisObject);
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	DiscountsMarkupsClient.UpdateAutoNamingDiscountTermsAndConditions(ThisObject, Modified);
	
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
Procedure TheDecorationDescriptionIsSuppliedByExternalDiscountProcessingURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	ShowValue(Undefined, Object.DiscountMarkupCondition);
	
EndProcedure

&AtClient
Procedure ItemFilterOptionOnChange(Item)
	
	SetSettingsForElementsOfProductConditionOptions(ThisObject, "ForOneTimeSalesVolume");
	SetSettingsForElementsOfProductConditionOptions(ThisObject, "ForAccumulatedSalesVolume");
	
	DiscountsMarkupsClient.UpdateAutoNamingDiscountTermsAndConditions(ThisObject, True);
	
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
Procedure WriteAndClose(Command)
	
	ClearMessages();
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	Cancel = False;
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
	
	If Cancel Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(Object.Ref) Then
	
		DiscountsMarkupsClientServer.ClearDetailsDependingOnApplicationCondition(Object);
		ExistingCondition = ExistingConditionProvisionOfDiscount();
		If ExistingCondition <> Undefined Then
			
			Notify("Selection_TermsOfDiscountsMarkups", New Structure, ExistingCondition);
			Modified = False;
			Close();
			
		Else
			
			If Write() Then
				Notify("Selection_TermsOfDiscountsMarkups", New Structure, Object.Ref);
				Close();
			EndIf;
			
		EndIf;
		
	Else
		
		If Modified Then
			If Not Write() Then
				Return;
			EndIf;
			
		EndIf;
		
		Notify("Selection_TermsOfDiscountsMarkups", New Structure, Object.Ref);
		Close();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)
	
	TMCommonUseClient.AllowObjectAttributeEdit(ThisForm);
	
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
	Modified = True;
	
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

// The external processing settings have been changed.
// 
// Parameters:
// 	Result - Undefined, Structure - result of the change
// 	AdditionalParameters - Structure - with properties:
// 		* Name - String - 
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
		ProductSegmentField_ = Form.Items.ItemSegmentPerOneTimeSalesVolume;
		ProductListFormField = Form.Items.ListOfItemsForOneTimeSalesVolume;
		SelectionFormField = Form.Items.FilterForOneTimeSalesVolume;
	ElsIf GroupName = "ForAccumulatedSalesVolume" Then
		ProductSegmentField_ = Form.Items.ItemSegmentForAccumulatedSalesVolume;
		ProductListFormField = Form.Items.ListOfItemsForAccumulatedSalesVolume;
		SelectionFormField = Form.Items.FilterForAccumulatedSalesVolume;
	Else
		Raise NStr("vi = 'Tên nhóm không xác định';
					|ru = 'Неизвестное имя группы';
					|en = 'Unknown group name'; fa = 'Unknown group name';
					|it = 'Nome del gruppo sconosciuto';
					|pl = 'Nieznana nazwa grupy';
					|tr = 'Bilinmeyen grup adı'") + " " + GroupName;
	EndIf;
	
	ProductSegmentField_.Enabled = (Form.Object.ItemFilterOption = PredefinedValue("Enum.ItemFilterOptionsForDiscountMarkupCalculation.ProductSegment"));
	ProductListFormField.Enabled = (Form.Object.ItemFilterOption = PredefinedValue("Enum.ItemFilterOptionsForDiscountMarkupCalculation.ItemList"));
	SelectionFormField.Enabled = (Form.Object.ItemFilterOption = PredefinedValue("Enum.ItemFilterOptionsForDiscountMarkupCalculation.DataCompositionFilter"));
	
	DiscountsMarkupsClientServer.ConfigureSelectionHyperlinks(Form);
	
EndProcedure

&AtServer
Function ExistingConditionProvisionOfDiscount()

	Query = New Query;
	
	If Object.DiscountMarkupCondition = Enums.DiscountMarkupTerms.DuringSale Then
		
		Query.Text = "
		|SELECT
		|	ObjectDiscounts.WeekDay,
		|	ObjectDiscounts.BeginTime,
		|	ObjectDiscounts.EndTime
		|INTO ObjectDiscounts
		|FROM
		|	&ObjectDiscounts AS ObjectDiscounts
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED TOP 1
		|	DiscountMarkupTermsTimeOfValidity.Ref,
		|	COUNT(DiscountMarkupTermsTimeOfValidity.Ref) AS Count
		|FROM
		|	ObjectDiscounts AS ObjectDiscounts
		|		INNER JOIN Catalog.DiscountMarkupTerms.TimeOfValidity AS DiscountMarkupTermsTimeOfValidity
		|			INNER JOIN Catalog.DiscountMarkupTerms AS DiscountMarkupTerms
		|			ON DiscountMarkupTermsTimeOfValidity.Ref = DiscountMarkupTerms.Ref
		|		ON ObjectDiscounts.WeekDay = DiscountMarkupTermsTimeOfValidity.WeekDay
		|			AND ObjectDiscounts.BeginTime = DiscountMarkupTermsTimeOfValidity.BeginTime
		|			AND ObjectDiscounts.EndTime = DiscountMarkupTermsTimeOfValidity.EndTime
		|WHERE
		|	NOT DiscountMarkupTerms.DeletionMark
		|	AND NOT DiscountMarkupTerms.IsFolder
		|
		|GROUP BY
		|	DiscountMarkupTermsTimeOfValidity.Ref
		|
		|HAVING
		|	COUNT(DiscountMarkupTermsTimeOfValidity.Ref) = &RowsCount";
		
		Query.SetParameter("ObjectDiscounts", Object.TimeOfValidity.Unload());
		Query.SetParameter("RowsCount", Object.TimeOfValidity.Count());
		
	ElsIf TypeOf(Object.DiscountMarkupCondition) = Type("CatalogRef.AdditionalReportsAndDataProcessors") Then
		
		Return Undefined;
		
	ElsIf (Object.DiscountMarkupCondition = Enums.DiscountMarkupTerms.ForOneTimeSalesVolume
			Or Object.DiscountMarkupCondition = Enums.DiscountMarkupTerms.ForAccumulatedSalesVolume)
			And Object.ItemFilterOption = Enums.ItemFilterOptionsForDiscountMarkupCalculation.ItemList Then
			
		Return Undefined;
		
	Else
		
		Query.Text = "
		|SELECT ALLOWED TOP 1
		|	DiscountMarkupTerms.Ref,
		|	DiscountMarkupTerms.StorageOfDataCompositionSettings AS StorageOfDataCompositionSettings
		|FROM
		|	Catalog.DiscountMarkupTerms AS DiscountMarkupTerms
		|WHERE
		|	NOT DiscountMarkupTerms.DeletionMark
		|	AND NOT DiscountMarkupTerms.IsFolder
		|	AND DiscountMarkupTerms.DiscountMarkupCondition = &DiscountMarkupCondition
		|	AND DiscountMarkupTerms.OptionOfCumulativeQuantityDiscountPeriodDetermination = &OptionOfCumulativeQuantityDiscountPeriodDetermination
		|	AND DiscountMarkupTerms.AccumulationOption = &AccumulationOption
		|	AND DiscountMarkupTerms.CriteriaOfApplicationLimitationForSalesVolume = &CriteriaOfApplicationLimitationForSalesVolume
		|	AND DiscountMarkupTerms.RestrictionCurrency = &RestrictionCurrency
		|	AND DiscountMarkupTerms.PaymentSchedule = &PaymentSchedule
		|	AND DiscountMarkupTerms.PaymentMethod = &PaymentMethod
		|	AND DiscountMarkupTerms.RestrictionConditionValue = &RestrictionConditionValue
		|	AND DiscountMarkupTerms.ProductSegmentRestrictions = &ProductSegmentRestrictions
		|	AND DiscountMarkupTerms.AccumulationPeriod = &AccumulationPeriod
		|	AND DiscountMarkupTerms.ComparisonTypeSSL = &ComparisonTypeSSL
		|	AND DiscountMarkupTerms.UsersGroup = &UsersGroup
		|	AND DiscountMarkupTerms.LoyaltyCardKind = &LoyaltyCardKind
		|	AND DiscountMarkupTerms.PartnersSegment = &PartnersSegment
		|	AND DiscountMarkupTerms.NumberOfAccumulationPeriods = &NumberOfAccumulationPeriods
		|	AND DiscountMarkupTerms.ItemFilterOption = &ItemFilterOption
		|	AND DiscountMarkupTerms.NumberOfDaysBeforeBirthday = &NumberOfDaysBeforeBirthday
		|	AND DiscountMarkupTerms.NumberOfDaysAfterBirthday = &NumberOfDaysAfterBirthday
		|	AND DiscountMarkupTerms.IncludeCurrentSaleInAccumulatedSalesVolume = &IncludeCurrentSaleInAccumulatedSalesVolume
		|	AND DiscountMarkupTerms.ApplyVariants = &ApplyVariants";
		
		Query.SetParameter("DiscountMarkupCondition", Object.DiscountMarkupCondition);
		Query.SetParameter("OptionOfCumulativeQuantityDiscountPeriodDetermination", Object.OptionOfCumulativeQuantityDiscountPeriodDetermination);
		Query.SetParameter("AccumulationOption", Object.AccumulationOption);
		Query.SetParameter("CriteriaOfApplicationLimitationForSalesVolume", Object.CriteriaOfApplicationLimitationForSalesVolume);
		Query.SetParameter("RestrictionCurrency", Object.RestrictionCurrency);
		Query.SetParameter("PaymentSchedule", Object.PaymentSchedule);
		Query.SetParameter("PaymentMethod", Object.PaymentMethod);
		Query.SetParameter("RestrictionConditionValue", Object.RestrictionConditionValue);
		Query.SetParameter("ProductSegmentRestrictions", Object.ProductSegmentRestrictions);
		Query.SetParameter("AccumulationPeriod", Object.AccumulationPeriod);
		Query.SetParameter("ComparisonTypeSSL", Object.ComparisonTypeSSL);
		Query.SetParameter("UsersGroup", Object.UsersGroup);
		Query.SetParameter("LoyaltyCardKind", Object.LoyaltyCardKind);
		Query.SetParameter("PartnersSegment", Object.PartnersSegment);
		Query.SetParameter("NumberOfAccumulationPeriods", Object.NumberOfAccumulationPeriods);
		Query.SetParameter("ItemFilterOption", Object.ItemFilterOption);
		Query.SetParameter("NumberOfDaysBeforeBirthday", Object.NumberOfDaysBeforeBirthday);
		Query.SetParameter("NumberOfDaysAfterBirthday", Object.NumberOfDaysAfterBirthday);
		Query.SetParameter("IncludeCurrentSaleInAccumulatedSalesVolume", Object.IncludeCurrentSaleInAccumulatedSalesVolume);
		Query.SetParameter("ApplyVariants", Object.ApplyVariants);
		
		If (Object.DiscountMarkupCondition = Enums.DiscountMarkupTerms.ForOneTimeSalesVolume
			Or Object.DiscountMarkupCondition = Enums.DiscountMarkupTerms.ForAccumulatedSalesVolume)
			And Object.ItemFilterOption = Enums.ItemFilterOptionsForDiscountMarkupCalculation.DataCompositionFilter Then
			Query.Text = StrReplace(Query.Text, "ALLOWED TOP 1", "ALLOWED");
		EndIf;
		
	EndIf;
	
	Selection = Query.Execute().Select();
	
	If (Object.DiscountMarkupCondition = Enums.DiscountMarkupTerms.ForOneTimeSalesVolume
		Or Object.DiscountMarkupCondition = Enums.DiscountMarkupTerms.ForAccumulatedSalesVolume)
		And Object.ItemFilterOption = Enums.ItemFilterOptionsForDiscountMarkupCalculation.DataCompositionFilter Then
		
		SearchResult = Undefined;
		While Selection.Next() Do
			StorageOfDataCompositionSettings = Selection.StorageOfDataCompositionSettings; // ValueStorage
			Settings = StorageOfDataCompositionSettings.Get();
			If Settings <> Undefined Then
				
				If String(SettingsComposerFilterByProducts.Settings.Filter) = String(Settings.FilterRemainingGoodsByShelfLives.Filter) Then
					SearchResult = Selection.Ref;
					Break;
				EndIf;
				
			EndIf;
			
		EndDo;
		
		Return SearchResult;
		
	Else
		If Selection.Next() Then
			Return Selection.Ref;
		Else
			Return Undefined;
		EndIf;
	EndIf;
	
EndFunction

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
