
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	TheseArePurchases = Parameters.TheseArePurchases;
	If Not TheseArePurchases Then
		UseRestrictionsOfManualDiscounts = (GetFunctionalOption("UseLimitsForDiscountAdjustmentsInSalesByUsers")
											  Or GetFunctionalOption("UseLimitsForDiscountAdjustmentsInSalesByTermsOfSales"));
	Else
		If GetFunctionalOption("BaseVersion") Then
			UseRestrictionsOfManualDiscounts = False;
		Else
			UseRestrictionsOfManualDiscounts = True;
		EndIf;
	EndIf;
	UseDiscountsMarkupsInSales = GetFunctionalOption("UseDiscountsMarkupsInSales");
	
	If Not UseRestrictionsOfManualDiscounts Then
		DiscountMarkupIsNotLimited = NStr("vi = 'Không hạn chế';
											|ru = 'Не ограничена';
											|en = 'Not limited'; fa = 'نامحدود';
											|it = 'Non limitata';
											|pl = 'Nie ograniczona';
											|tr = 'Sınırsız'");
	EndIf;
	
	Items.MaximumMargin.Visible = UseRestrictionsOfManualDiscounts;
	Items.MaximumDiscount.Visible = UseRestrictionsOfManualDiscounts;
	Items.MaxDiscountPercentage.Visible = UseRestrictionsOfManualDiscounts;
	Items.MaxMarkupPercentage.Visible = UseRestrictionsOfManualDiscounts;
	Items.TheMaximumDiscountIsNotLimited.Visible = Not UseRestrictionsOfManualDiscounts;
	Items.TheMaximumMarginIsNotLimited.Visible = Not UseRestrictionsOfManualDiscounts;
	
	TableStructure = GetFromTempStorage(Parameters.AddressInTempStorage);
	
	AmountWithoutDiscounts                   = TableStructure.Restrictions.Total("AmountWithoutADiscount");
	AmountOfAutomaticDiscountMarkup = TableStructure.Restrictions.Total("DiscountMarkupAmount");
	AmountOfManualDiscountMarkUp         = TableStructure.Restrictions.Total("ManualDiscount");
	Currency                           = Parameters.Currency;
	
	DocumentAmount = AmountWithoutDiscounts;
	DocumentAmountIncludingDiscountAutomaticDiscount = AmountWithoutDiscounts - AmountOfAutomaticDiscountMarkup;
	If DocumentAmountIncludingDiscountAutomaticDiscount >= AmountOfManualDiscountMarkUp Then
		DocumentAmountIncludingDiscount = DocumentAmountIncludingDiscountAutomaticDiscount - AmountOfManualDiscountMarkUp;
	Else
		AmountOfManualDiscountMarkUp = DocumentAmountIncludingDiscountAutomaticDiscount;
		DocumentAmountIncludingDiscount = 0;
	EndIf;
	
	If AmountOfManualDiscountMarkUp < 0 Then
		AmountOfManualDiscountMarkUp = -AmountOfManualDiscountMarkUp;
		ProvisionOption = 2;
		Items.ProvisionOptions.CurrentPage = Items.ProvisionOptions.ChildItems.Markup;
	Else
		AmountOfManualDiscountMarkUp = AmountOfManualDiscountMarkUp;
		ProvisionOption = 1;
		Items.ProvisionOptions.CurrentPage = Items.ProvisionOptions.ChildItems.Discount;
	EndIf;
	
	If DocumentAmount > 0 Then
		PercentRateOfManualDiscountMarkup = AmountOfManualDiscountMarkUp * 100 / DocumentAmount;
	EndIf;
	
	If UseRestrictionsOfManualDiscounts Then
		
		MaxDiscountAmount  = TableStructure.Restrictions.Total("MaximumAmountOfManualDiscount");
		MaxMarkupAmount = TableStructure.Restrictions.Total("MaximumAmountOfManualMarkUp");
		
		If DocumentAmount > 0 Then
			MaxDiscountPercentage  = MaxDiscountAmount * 100 / DocumentAmount;
			MaxMarkupPercentage = MaxMarkupAmount * 100 / DocumentAmount;
		EndIf;
		
		TheMaximumAmountOfDiscountsForControl = MaxDiscountAmount;
		TheMaximumTotalMarkupForTheControl = MaxMarkupAmount;
		
		If MaxDiscountAmount > 0 Then
			Items.DiscountAmount.ChoiceListButton = True;
			Items.DiscountAmount.ChoiceList.Add(MaxDiscountAmount, Format(MaxDiscountAmount, "NFD=2"));
		EndIf;
		
		If MaxDiscountPercentage > 0 Then
			Items.DiscountPercentage.ChoiceListButton = True;
			Items.DiscountPercentage.ChoiceList.Add(MaxDiscountPercentage, Format(MaxDiscountPercentage, "NFD=2"));
		EndIf;
		
		If MaxMarkupAmount > 0 Then
			Items.MarkUpAmount.ChoiceListButton = True;
			Items.MarkUpAmount.ChoiceList.Add(MaxMarkupAmount, Format(MaxMarkupAmount, "NFD=2"));
		EndIf;
		
		If MaxMarkupPercentage > 0 Then
			Items.MarginPercentage.ChoiceListButton = True;
			Items.MarginPercentage.ChoiceList.Add(MaxMarkupPercentage, Format(MaxMarkupPercentage, "NFD=2"));
		EndIf;
		
	EndIf;
	
	Items.ProvisionOption.ChoiceList.Add(1, NStr("vi = 'Chiết khấu';
												|ru = 'Скидка';
												|en = 'Discount'; fa = 'تخفیف';
												|it = 'Sconto';
												|pl = 'Rabat';
												|tr = 'İndirim'"));
	Items.ProvisionOption.ChoiceList.Add(2, NStr("vi = 'Phụ thu';
												|ru = 'Наценка';
												|en = 'Markup'; fa = 'افزایش قیمت';
												|it = 'Sovrapprezzo';
												|pl = 'Marża';
												|tr = 'Marj'"));
	
	TMCommonUseClientServer.SetFormItemProperty(Items, 
		"AutomaticDiscountAmountGroup",
		"Visible",
		UseDiscountsMarkupsInSales And Not TheseArePurchases,
		True);
		
	TMCommonUseClientServer.SetFormItemProperty(Items, 
		"GroupAmountOfAutomaticDiscountMarkUp",
		"Visible",
		UseDiscountsMarkupsInSales And Not TheseArePurchases,
		True);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	PrepareSelectionLists();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	ClearMessages();
	If UseRestrictionsOfManualDiscounts Then
		
		MessageText = "";
		If ProvisionOption = 1 Then
			If AmountOfManualDiscountMarkUp > TheMaximumAmountOfDiscountsForControl Then
				MessageText = NStr("vi = 'Số tiền chiết khấu vượt quá giá trị lớn nhất có thể:';
									|ru = 'Сумма скидки превышает максимальное возможное значение:';
									|en = 'Discount amount exceeds the maximum possible value:'; fa = 'Discount amount exceeds the maximum possible value:';
									|it = 'L''importo dello sconto supera il valore massimo consentito:';
									|pl = 'Wartość rabatu przekracza maksymalną możliwą wartość:';
									|tr = 'İndirim tutarı mümkün olan maksimum değeri aşıyor:'") + " " + TheMaximumAmountOfDiscountsForControl + " " + Currency;
			EndIf;
		EndIf;
		
		If ProvisionOption = 2 Then
			If AmountOfManualDiscountMarkUp > TheMaximumTotalMarkupForTheControl Then
				MessageText = NStr("vi = 'Số tiền phụ thu vượt quá giá trị lớn nhất có thể:';
									|ru = 'Сумма наценки превышает максимальное возможное значение:';
									|en = 'Markup amount exceeds the maximum allowed value:'; fa = 'Markup amount exceeds the maximum allowed value:';
									|it = 'L''importo del margine (markup) supera il valore massimo consentito:';
									|pl = 'Wartość marży przekracza maksymalną możliwą wartość:';
									|tr = 'Zam tutarı mümkün olan maksimum değeri aşıyor:'") + " " + TheMaximumTotalMarkupForTheControl + " " + Currency;
			EndIf;
		EndIf;
		
		If ValueIsFilled(MessageText) Then
			Response = Undefined;

			ShowQueryBox(New CallbackDescription("OKCompletion", ThisObject), MessageText + ". " + NStr("vi = 'Tiếp tục?';
																										|ru = 'Продолжить?';
																										|en = 'Continue?'; fa = 'Continue?';
																										|it = 'Continuare?';
																										|pl = 'Continue?';
																										|tr = 'Devam edilsin mi?'"), QuestionDialogMode.OKCancel);
            Return;
		EndIf;
		
	EndIf;
	
	OKFragment();
EndProcedure

&AtClient
Procedure OKCompletion(QuestionResult, AdditionalParameters) Export
    
    Response = QuestionResult;
    If Not Response = DialogReturnCode.OK Then
        Return;
    EndIf;
    
    OKFragment();

EndProcedure

&AtClient
Procedure OKFragment()
    
    If ProvisionOption = 1 Then
        Close(AmountOfManualDiscountMarkUp);
    Else
        Close(-AmountOfManualDiscountMarkUp);
    EndIf;

EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Close(Undefined);
	
EndProcedure

#EndRegion

#Region EventHandlers

&AtClient
Procedure ProvisionOptionOnChange(Item)
	
	If ProvisionOption = 1 Then
		Items.ProvisionOptions.CurrentPage = Items.ProvisionOptions.ChildItems.Discount;
		DocumentAmountIncludingDiscount = DocumentAmount - AmountOfAutomaticDiscountMarkup - AmountOfManualDiscountMarkUp;
		CurrentItem = Items.DiscountAmount;
	Else
		Items.ProvisionOptions.CurrentPage = Items.ProvisionOptions.ChildItems.Markup;
		DocumentAmountIncludingDiscount = DocumentAmount - AmountOfAutomaticDiscountMarkup + AmountOfManualDiscountMarkUp;
		CurrentItem = Items.MarkUpAmount;
	EndIf;
	
EndProcedure

&AtClient
Procedure DiscountAmountOnChange(Item)
	
	If DocumentAmount > 0 Then
		PercentRateOfManualDiscountMarkup = AmountOfManualDiscountMarkUp * 100 / DocumentAmount;
	EndIf;
	DocumentAmountIncludingDiscount = DocumentAmount - AmountOfAutomaticDiscountMarkup - AmountOfManualDiscountMarkUp;
	
	PrepareSelectionLists();
	
EndProcedure

&AtClient
Procedure DiscountPercentageOnChange(Item)
	
	If PercentRateOfManualDiscountMarkup = MaxDiscountPercentage Then
		AmountOfManualDiscountMarkUp = MaxDiscountAmount;
	Else
		AmountOfManualDiscountMarkUp    = PercentRateOfManualDiscountMarkup * DocumentAmount / 100;
	EndIf;
	
	DocumentAmountIncludingDiscount = DocumentAmount - AmountOfAutomaticDiscountMarkup - AmountOfManualDiscountMarkUp;
	
	PrepareSelectionLists();
	
EndProcedure

&AtClient
Procedure DocumentAmountIncludingDiscountOnChange(Item)
	
	If DocumentAmountIncludingDiscount > DocumentAmount Then
		DocumentAmountIncludingDiscount = DocumentAmount - AmountOfAutomaticDiscountMarkup;
		AmountOfManualDiscountMarkUp = 0;
		PercentRateOfManualDiscountMarkup = 0;
	Else
		AmountOfManualDiscountMarkUp   = DocumentAmount - AmountOfAutomaticDiscountMarkup - DocumentAmountIncludingDiscount;
		If DocumentAmount > 0 Then
			PercentRateOfManualDiscountMarkup = AmountOfManualDiscountMarkUp * 100 / DocumentAmount;
		EndIf;
	EndIf;
	
	PrepareSelectionLists();
	
EndProcedure

&AtClient
Procedure MarkUpAmountOnChange(Item)

	If DocumentAmount > 0 Then
		PercentRateOfManualDiscountMarkup = AmountOfManualDiscountMarkUp * 100 / DocumentAmount;
	EndIf;
	DocumentAmountIncludingDiscount = DocumentAmount - AmountOfAutomaticDiscountMarkup + AmountOfManualDiscountMarkUp;
	
	PrepareSelectionLists();
	
EndProcedure

&AtClient
Procedure MarginPercentageOnChange(Item)
	
	If PercentRateOfManualDiscountMarkup = MaxMarkupPercentage Then
		AmountOfManualDiscountMarkUp = MaxMarkupAmount;
	Else
		AmountOfManualDiscountMarkUp    = PercentRateOfManualDiscountMarkup * DocumentAmount / 100;
	EndIf;
	
	DocumentAmountIncludingDiscount = DocumentAmount + AmountOfManualDiscountMarkUp - AmountOfAutomaticDiscountMarkup;
	
EndProcedure

&AtClient
Procedure DocumentAmountIncludingMarkupOnChange(Item)
	
	If DocumentAmountIncludingDiscount < DocumentAmount - AmountOfAutomaticDiscountMarkup Then
		DocumentAmountIncludingDiscount = DocumentAmount - AmountOfAutomaticDiscountMarkup;
		AmountOfManualDiscountMarkUp = 0;
		PercentRateOfManualDiscountMarkup = 0;
	Else
		AmountOfManualDiscountMarkUp   = DocumentAmountIncludingDiscount - (DocumentAmount - AmountOfAutomaticDiscountMarkup);
		If DocumentAmount > 0 Then
			PercentRateOfManualDiscountMarkup = AmountOfManualDiscountMarkUp * 100 / DocumentAmount;
		EndIf;
	EndIf;
	
	PrepareSelectionLists();
	
EndProcedure

&AtClient
Procedure DocumentAmountWithDiscountPrepareSelectionList()
	
	Items.DocumentAmountIncludingDiscount.ChoiceList.Clear();

	MaximumRoundingAccuracy = 100000;
	
	Variants = New Array;

	RoundingAccuracy = New Array();
	RoundingPrecision             = 0.01;
	EvenIncrement               = False;
	
	MatchingAccuracy = New Map;
	
	While RoundingPrecision <= MaximumRoundingAccuracy Do
		
		Value = PriceManagementSystemClientServer.RoundUpPrice(DocumentAmountIncludingDiscount, RoundingPrecision, PredefinedValue("Enum.RoundingOptions.AlwaysForBenefitOfEnterprise"));
		If Variants.Find(Value) = Undefined Then
			Variants.Add(Value);
			MatchingAccuracy.Insert(Value, StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '(làm tròn đến %1)';
																										|ru = '(+окр.до %1)';
																										|en = '(+round. to %1)'; fa = '(+round. to %1)';
																										|it = '(+arr. a %1)';
																										|pl = '(+zaokr. do %1)';
																										|tr = '(+ %1 kadar yuvarlak)'"), RoundingPrecision));
		EndIf;
		
		Value = PriceManagementSystemClientServer.RoundUpPrice(DocumentAmountIncludingDiscount, RoundingPrecision, PredefinedValue("Enum.RoundingOptions.RoundingOptionForBenefitOfCustomer"));
		If Variants.Find(Value) = Undefined Then
			Variants.Add(Value);
			MatchingAccuracy.Insert(Value, StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '(làm tròn đến %1)';
																										|ru = '(-окр.до %1)';
																										|en = '(- round.to %1)'; fa = '(- round.to %1)';
																										|it = '(-arr. a %1)';
																										|pl = '(-zaokr. do %1)';
																										|tr = '(- %1 kadar yuvarlak)'"), RoundingPrecision));
		EndIf;
	
		RoundingPrecision = RoundingPrecision * ?(EvenIncrement, 2, 5);
		EvenIncrement   = Not EvenIncrement;
		
	EndDo;
	
	For Each Sum In Variants Do
		
		If Sum = 0 Then
			Continue;
		EndIf;
		
		If DocumentAmount - AmountOfAutomaticDiscountMarkup - Sum > MaxDiscountAmount Then
			Continue;
		EndIf;
		
		If DocumentAmount - AmountOfAutomaticDiscountMarkup - Sum < 0 Then
			Continue;
		EndIf;
		
		If DocumentAmountIncludingDiscount = Sum Then
			Continue;
		EndIf;
		
		Items.DocumentAmountIncludingDiscount.ChoiceList.Add(Sum, Format(Sum, "NFD=2")+ " " + MatchingAccuracy.Get(Sum));
		
	EndDo;
	
	Items.DocumentAmountIncludingDiscount.ChoiceList.SortByValue();
	
EndProcedure

&AtClient
Procedure DocumentAmountIncludingMarkUpPrepareSelectionList()
	
	Items.DocumentAmountIncludingMarkup.ChoiceList.Clear();

	MaximumRoundingAccuracy = 100000;
	
	Variants = New Array;

	RoundingAccuracy = New Array();
	RoundingPrecision             = 0.01;
	EvenIncrement               = False;
	
	MatchingAccuracy = New Map;
	
	While RoundingPrecision <= MaximumRoundingAccuracy Do
		
		Value = PriceManagementSystemClientServer.RoundUpPrice(DocumentAmountIncludingDiscount, RoundingPrecision, PredefinedValue("Enum.RoundingOptions.AlwaysForBenefitOfEnterprise"));
		If Variants.Find(Value) = Undefined Then
			Variants.Add(Value);
			MatchingAccuracy.Insert(Value, StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '(làm tròn đến %1)';
																										|ru = '(+окр.до %1)';
																										|en = '(+round. to %1)'; fa = '(+round. to %1)';
																										|it = '(+arr. a %1)';
																										|pl = '(+zaokr. do %1)';
																										|tr = '(+ %1 kadar yuvarlak)'"), RoundingPrecision));
		EndIf;
		
		Value = PriceManagementSystemClientServer.RoundUpPrice(DocumentAmountIncludingDiscount, RoundingPrecision, PredefinedValue("Enum.RoundingOptions.RoundingOptionForBenefitOfCustomer"));
		If Variants.Find(Value) = Undefined Then
			Variants.Add(Value);
			MatchingAccuracy.Insert(Value, StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '(làm tròn đến %1)';
																										|ru = '(-окр.до %1)';
																										|en = '(- round.to %1)'; fa = '(- round.to %1)';
																										|it = '(-arr. a %1)';
																										|pl = '(-zaokr. do %1)';
																										|tr = '(- %1 kadar yuvarlak)'"), RoundingPrecision));
		EndIf;
		
		RoundingPrecision = RoundingPrecision * ?(EvenIncrement, 2, 5);
		EvenIncrement   = Not EvenIncrement;
		
	EndDo;
	
	For Each Sum In Variants Do
		
		If Sum = 0 Then
			Continue;
		EndIf;
		
		If Sum - (DocumentAmount - AmountOfAutomaticDiscountMarkup) > MaxMarkupAmount Then
			Continue;
		EndIf;
		
		If Sum - (DocumentAmount - AmountOfAutomaticDiscountMarkup) < 0 Then
			Continue;
		EndIf;
		
		If DocumentAmountIncludingDiscount = Sum Then
			Continue;
		EndIf;
		
		Items.DocumentAmountIncludingMarkup.ChoiceList.Add(Sum, Format(Sum, "NFD=2")+ " " + MatchingAccuracy.Get(Sum));
		
	EndDo;
	
	Items.DocumentAmountIncludingMarkup.ChoiceList.SortByValue();

EndProcedure

&AtClient
Procedure DiscountAmountPrepareSelectionList()
	
	Items.DiscountAmount.ChoiceList.Clear();
	
	If MaxDiscountAmount > 0 Then
		Items.DiscountAmount.ChoiceList.Add(MaxDiscountAmount, Format(MaxDiscountAmount, "NFD=2"));
	EndIf;

	MaximumRoundingAccuracy = 100000;
	
	Variants = New Array;

	RoundingAccuracy = New Array();
	RoundingPrecision             = 0.01;
	EvenIncrement               = False;
	
	MatchingAccuracy = New Map;
	
	While RoundingPrecision <= MaximumRoundingAccuracy Do
		
		Value = PriceManagementSystemClientServer.RoundUpPrice(DocumentAmountIncludingDiscount, RoundingPrecision, PredefinedValue("Enum.RoundingOptions.AlwaysForBenefitOfEnterprise"));
		If Variants.Find(Value) = Undefined Then
			Variants.Add(Value);
			MatchingAccuracy.Insert(Value, StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '(làm tròn đến %1)';
																										|ru = '(окр.до %1)';
																										|en = '(round.to %1)'; fa = '(round.to %1)';
																										|it = '(arr. a %1)';
																										|pl = '(zaokr. do %1)';
																										|tr = '(%1 kadar yuvarlak)'"), Value));
		EndIf;
		
		Value = PriceManagementSystemClientServer.RoundUpPrice(DocumentAmountIncludingDiscount, RoundingPrecision, PredefinedValue("Enum.RoundingOptions.ByArithmeticRules"));
		If Variants.Find(Value) = Undefined Then
			Variants.Add(Value);
			MatchingAccuracy.Insert(Value, StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '(làm tròn đến %1)';
																										|ru = '(окр.до %1)';
																										|en = '(round.to %1)'; fa = '(round.to %1)';
																										|it = '(arr. a %1)';
																										|pl = '(zaokr. do %1)';
																										|tr = '(%1 kadar yuvarlak)'"), Value));
		EndIf;
		
		RoundingPrecision = RoundingPrecision * ?(EvenIncrement, 2, 5);
		EvenIncrement   = Not EvenIncrement;
		
	EndDo;
	
	For Each Sum In Variants Do
		
		If Sum = 0 Then
			Continue;
		EndIf;
		
		DiscountAmount =  DocumentAmount - AmountOfAutomaticDiscountMarkup - Sum;
		
		If DiscountAmount > MaxDiscountAmount Then
			Continue;
		EndIf;
		
		If DiscountAmount < 0 Then
			Continue;
		EndIf;
		
		If DocumentAmountIncludingDiscount = Sum Then
			Continue;
		EndIf;
		
		Items.DiscountAmount.ChoiceList.Add(DiscountAmount, Format(DiscountAmount, "NFD=2; NZ=0.00")+ " " + MatchingAccuracy.Get(Sum));
		
	EndDo;
	
	Items.DiscountAmount.ChoiceList.SortByValue();
	
EndProcedure

&AtClient
Procedure MarkUpAmountPrepareSelectionList()
	
	Items.MarkUpAmount.ChoiceList.Clear();
	
	If MaxDiscountAmount > 0 Then
		Items.MarkUpAmount.ChoiceList.Add(MaxDiscountAmount, Format(MaxDiscountAmount, "NFD=2"));
	EndIf;

	MaximumRoundingAccuracy = 100000;
	
	Variants = New Array;

	RoundingAccuracy = New Array();
	RoundingPrecision             = 0.01;
	EvenIncrement               = False;
	
	MatchingAccuracy = New Map;
	
	While RoundingPrecision <= MaximumRoundingAccuracy Do
		
		Value = PriceManagementSystemClientServer.RoundUpPrice(DocumentAmountIncludingDiscount, RoundingPrecision, True);
		If Variants.Find(Value) = Undefined Then
			Variants.Add(Value);
			MatchingAccuracy.Insert(Value, StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '(làm tròn đến %1)';
																										|ru = '(окр.до %1)';
																										|en = '(round.to %1)'; fa = '(round.to %1)';
																										|it = '(arr. a %1)';
																										|pl = '(zaokr. do %1)';
																										|tr = '(%1 kadar yuvarlak)'"), Value));
		EndIf;
		
		Value = PriceManagementSystemClientServer.RoundUpPrice(DocumentAmountIncludingDiscount, RoundingPrecision, False);
		If Variants.Find(Value) = Undefined Then
			Variants.Add(Value);
			MatchingAccuracy.Insert(Value, StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '(làm tròn đến %1)';
																										|ru = '(окр.до %1)';
																										|en = '(round.to %1)'; fa = '(round.to %1)';
																										|it = '(arr. a %1)';
																										|pl = '(zaokr. do %1)';
																										|tr = '(%1 kadar yuvarlak)'"), Value));
		EndIf;
		
		RoundingPrecision = RoundingPrecision * ?(EvenIncrement, 2, 5);
		EvenIncrement   = Not EvenIncrement;
		
	EndDo;
	
	For Each Sum In Variants Do
		
		If Sum = 0 Then
			Continue;
		EndIf;
		
		MarkUpAmount = Sum - (DocumentAmount - AmountOfAutomaticDiscountMarkup);
		
		If MarkUpAmount > MaxMarkupAmount Then
			Continue;
		EndIf;
		
		If MarkUpAmount < 0 Then
			Continue;
		EndIf;
		
		If DocumentAmountIncludingDiscount = Sum Then
			Continue;
		EndIf;
		
		Items.MarkUpAmount.ChoiceList.Add(MarkUpAmount, Format(MarkUpAmount, "NFD=2; NZ=0.00")+ " " + MatchingAccuracy.Get(Sum));
		
	EndDo;
	
	Items.MarkUpAmount.ChoiceList.SortByValue();
	
EndProcedure

&AtClient
Procedure PrepareSelectionLists()
	
	DocumentAmountWithDiscountPrepareSelectionList();
	DocumentAmountIncludingMarkUpPrepareSelectionList();
	DiscountAmountPrepareSelectionList();
	MarkUpAmountPrepareSelectionList();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DiscountAmount.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AmountOfManualDiscountMarkUp");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
	ItemFilter.RightValue = New DataCompositionField("MaxDiscountAmount");

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseRestrictionsOfManualDiscounts");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", WebColors.FireBrick);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DiscountPercentage.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PercentRateOfManualDiscountMarkup");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
	ItemFilter.RightValue = New DataCompositionField("MaxDiscountPercentage");

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseRestrictionsOfManualDiscounts");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", WebColors.FireBrick);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.MarkUpAmount.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AmountOfManualDiscountMarkUp");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
	ItemFilter.RightValue = New DataCompositionField("MaxMarkupAmount");

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseRestrictionsOfManualDiscounts");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", WebColors.FireBrick);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.MarginPercentage.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PercentRateOfManualDiscountMarkup");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
	ItemFilter.RightValue = New DataCompositionField("MaxMarkupPercentage");

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseRestrictionsOfManualDiscounts");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", WebColors.FireBrick);

EndProcedure

#EndRegion
