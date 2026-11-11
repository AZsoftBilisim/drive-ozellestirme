#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	If IsFolder Then
		
		NotCheckedAttributeArray.Add("Description");
		
		If Ref = Catalogs.DiscountsMarkups.RootGroup Then
			NotCheckedAttributeArray.Add("Parent");
		EndIf;
		
	Else
		
		If MethodsOfProviding <> Enums.MethodsToProvideDiscountsMarkups.PriceKind Then
			NotCheckedAttributeArray.Add("PriceKind");
		EndIf;
		
		If (MethodsOfProviding <> Enums.MethodsToProvideDiscountsMarkups.Sum
			And MethodsOfProviding <> Enums.MethodsToProvideDiscountsMarkups.RoundDocumentAmount
			And MethodsOfProviding <> Enums.MethodsToProvideDiscountsMarkups.DiscountMarkupAsAmountForEachRow)
			And DiscountApplicationMethod = Enums.DiscountMarkupApplicationMethods.ApplyDuringCalculationOfDiscountsMarkups Then
			NotCheckedAttributeArray.Add("DiscountMarkupCurrency");
		EndIf;
		
		If DiscountApplicationMethod = Enums.DiscountMarkupApplicationMethods.GrantBonusPoints Then
			NotCheckedAttributeArray.Add("DiscountMarkupCurrency");
		EndIf;
		
		If MethodsOfProviding = Enums.MethodsToProvideDiscountsMarkups.PriceKind
			Or MethodsOfProviding = Enums.MethodsToProvideDiscountsMarkups.Percent
			Or MethodsOfProviding = Enums.MethodsToProvideDiscountsMarkups.Sum
			Or MethodsOfProviding = Enums.MethodsToProvideDiscountsMarkups.DiscountMarkupAsAmountForEachRow Then
			
			NotCheckedAttributeArray.Add("LoyaltyCardKind");
			NotCheckedAttributeArray.Add("MessageText");
			
		ElsIf MethodsOfProviding = Enums.MethodsToProvideDiscountsMarkups.LoyaltyCard
			Or MethodsOfProviding = Enums.MethodsToProvideDiscountsMarkups.Message Then
			
			NotCheckedAttributeArray.Add("DiscountMarkupValue");
			
			If MethodsOfProviding = Enums.MethodsToProvideDiscountsMarkups.LoyaltyCard Then
				NotCheckedAttributeArray.Add("MessageText");
			EndIf;
			If MethodsOfProviding = Enums.MethodsToProvideDiscountsMarkups.Message Then
				NotCheckedAttributeArray.Add("LoyaltyCardKind");
			EndIf;
			
		EndIf;
		
		If MethodsOfProviding = Enums.MethodsToProvideDiscountsMarkups.RoundDocumentAmount Then
			
			NotCheckedAttributeArray.Add("MessageText");
			NotCheckedAttributeArray.Add("LoyaltyCardKind");
			
			If ValueIsFilled(RoundingPrecision) And
				SmartRounding >= RoundingPrecision Then
				
				ErrorText = NStr("vi = 'Làm tròn tâm lý cần phải nhỏ hơn phần thập phân làm tròn';
								|ru = 'Психологическое округление должно быть меньше точности округления';
								|en = 'Smart rounding should be smaller than the rounding precision'; fa = 'Smart rounding should be smaller than the rounding precision';
								|it = 'L''arrotondamento psicologico deve essere inferiore alla precisione dell''arrotondamento stesso';
								|pl = 'Zaokrąglenie psychologiczne musi być mniejsze niż dokładność zaokrąglenia';
								|tr = 'Psikolojik yuvarlama, yuvarlama duyarlılığından daha az olmalıdır'");
				
				Common.MessageToUser(
					ErrorText,
					ThisObject,
					"SmartRounding",
					,
					Cancel);
				
			EndIf;
			
		EndIf;
		
		If MethodsOfProviding <> Enums.MethodsToProvideDiscountsMarkups.RoundDocumentAmount Then
			NotCheckedAttributeArray.Add("RoundingPrecision");
		EndIf;
		
		If MethodsOfProviding = Enums.MethodsToProvideDiscountsMarkups.Gift
			Or MethodsOfProviding = Enums.MethodsToProvideDiscountsMarkups.Count Then
			NotCheckedAttributeArray.Add("MessageText");
			NotCheckedAttributeArray.Add("LoyaltyCardKind");
		EndIf;
		
		If DiscountApplicationMethod <> Enums.DiscountMarkupApplicationMethods.GrantBonusPoints Then
			NotCheckedAttributeArray.Add("ActionPeriod");
			NotCheckedAttributeArray.Add("NumberOfValidityPeriods");
			NotCheckedAttributeArray.Add("PeriodOfActionStartDelay");
			NotCheckedAttributeArray.Add("NumberOfActionStartDelayPeriods");
			NotCheckedAttributeArray.Add("LoyaltyProgram");
		EndIf;
		
		If TypeOf(MethodsOfProviding) = Type("CatalogRef.AdditionalReportsAndDataProcessors") Then
			NotCheckedAttributeArray.Add("MessageText");
			NotCheckedAttributeArray.Add("LoyaltyCardKind");
		EndIf;
			
		If MethodsOfProviding = Enums.MethodsToProvideDiscountsMarkups.Count Then
			If DiscountMarkupValue >= DiscountConditionByQuantity Then
			
				ErrorText = NStr("vi = 'Số lượng hàng hóa miễn phí phải nhỏ hơn tổng số lượng của mặt hàng này""';
								|ru = 'Количество бесплатного товара должно быть меньше общего количества данного товара""';
								|en = 'Amount of free goods should be less than the total amount of these goods""'; fa = 'Amount of free goods should be less than the total amount of these goods""';
								|it = 'La quantità della merce gratuita deve essere inferiore alla quantità totale della merce stessa""';
								|pl = 'Ilość bezpłatnego towaru musi być mniejsze niż łączna ilość danego towaru""';
								|tr = 'Ücretsiz ürün miktarı, bu ürünün toplam miktarından daha az olmalıdır""'");
				
				CommonClientServer.MessageToUser(
					ErrorText,
					ThisObject,
					"DiscountMarkupValue",
					,
					Cancel);
				
			EndIf;
		Else
			NotCheckedAttributeArray.Add("DiscountConditionByQuantity");
		EndIf;
		
		If ItemFilterOption <> Enums.ItemFilterOptionsForDiscountMarkupCalculation.ProductSegment
			And ItemFilterOption <> Enums.ItemFilterOptionsForDiscountMarkupCalculation.NotProductSegment Then
			NotCheckedAttributeArray.Add("ProductSegmentRestrictions");
		EndIf;
		
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DiscountsMarkupsServer.BeforeWrite(ThisObject, Cancel);
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	If Ref <> Catalogs.DiscountsMarkups.RootGroup 
		And Not ValueIsFilled(Parent) Then
		Common.MessageToUser(
		NStr("vi = 'Trường ""Nhóm áp dụng chung"" là bắt buộc điền';
			|ru = 'Поле ""Группа совместного применения"" обязательно к заполнению';
			|en = 'The ""Joint application group"" field is required.'; fa = 'The ""Joint application group"" field is required.';
			|it = 'E'' necessario compilare il campo ""Gruppo di applicazione condivisa""';
			|pl = 'Pole ""Grupa wspólnego stosowania"" jest obowiązkowa do wypełnienia';
			|tr = '""Ortak Uygulama Grubu"" alanının doldurulması zorunludur'"),,,, Cancel);
	EndIf;
		
	ClearUnusedProps();
	SetDiscountTrackingSettings();
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	If Not IsFolder Then
		
		DiscountMarkupCurrency = IncomeAndExpensesServer.GetCurrencyOfManagementAccounting(DiscountMarkupCurrency);
		PriceKind = Catalogs.TypesOfPrices.DefaultPriceType(PriceKind);
		
		If FillingData <> Undefined
			And FillingData.Property("MethodsOfProviding")
			And TypeOf(FillingData.MethodsOfProviding) = Type("CatalogRef.AdditionalReportsAndDataProcessors") Then
			
			ExternalDataProcessor = DiscountsMarkupsCached.ExternalDataProcessorObject(FillingData.MethodsOfProviding);
			SetSafeMode(True);
			DiscountApplicationMethod = ExternalDataProcessor.ApplicationMethod();
			SetSafeMode(False);
			
		EndIf;
		
		If FillingData <> Undefined
			And FillingData.Property("DataToFillInForTheParent")
			And ValueIsFilled(FillingData.DataToFillInForTheParent) Then
			
			Parent = Common.ObjectAttributeValue(FillingData.DataToFillInForTheParent, "Parent");
			If Not ValueIsFilled(Parent) Then
				Parent = Catalogs.DiscountsMarkups.RootGroup;
			EndIf;
			
		Else
			
			Parent = Catalogs.DiscountsMarkups.RootGroup;
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

#Region Other

Procedure ClearUnusedProps()

	If MethodsOfProviding = Enums.MethodsToProvideDiscountsMarkups.PriceKind Then
		
		DiscountMarkupCurrency = Undefined;
		DiscountMarkupValue = Undefined;
		
		MessageText = Undefined;
		LoyaltyCardKind = Undefined;
		
	ElsIf MethodsOfProviding = Enums.MethodsToProvideDiscountsMarkups.Percent Then
		
		If DiscountApplicationMethod = Enums.DiscountMarkupApplicationMethods.ApplyDuringCalculationOfDiscountsMarkups Then
			DiscountMarkupCurrency = Undefined;
		EndIf;
		
		DiscountMarkupCurrency = Undefined;
		PriceKind              = Undefined;
		
		MessageText = Undefined;
		LoyaltyCardKind = Undefined;
		
	ElsIf MethodsOfProviding = Enums.MethodsToProvideDiscountsMarkups.Sum Then
		
		PriceKind = Undefined;
		
		MessageText = Undefined;
		LoyaltyCardKind = Undefined;
		
	ElsIf MethodsOfProviding = Enums.MethodsToProvideDiscountsMarkups.Message Then
		
		DiscountMarkupValue = Undefined;
		DiscountMarkupCurrency = Undefined;
		PriceKind              = Undefined;
		
		PriceGroups.Clear();
		LoyaltyCardKind = Undefined;
		
	ElsIf MethodsOfProviding = Enums.MethodsToProvideDiscountsMarkups.LoyaltyCard Then
		
		DiscountMarkupValue = Undefined;
		DiscountMarkupCurrency = Undefined;
		PriceKind              = Undefined;
		
		PriceGroups.Clear();
		MessageText = Undefined;
		
	EndIf;
	
	If PriceGroups.Count() > 0 Then
		If MethodsOfProviding <> Enums.MethodsToProvideDiscountsMarkups.Percent And
			 MethodsOfProviding <> Enums.MethodsToProvideDiscountsMarkups.DiscountMarkupAsAmountForEachRow Then
			 PriceGroups.Clear();
		EndIf; 
	EndIf;	
	
	If Not IsFolder And DiscountApplicationMethod <> Enums.DiscountMarkupApplicationMethods.GrantBonusPoints Then
		LoyaltyProgram = Undefined;
	EndIf;
	
EndProcedure

Procedure SetDiscountTrackingSettings()
	
	If IsFolder Or ApplyMultiplicationWithinParentGroup Then
		Return;
	EndIf;
	
	If Not Ref.IsEmpty() And Parent <> Common.ObjectAttributeValue(Parent, "Parent") Then
		
		VariantOfJointApplicationOfGroup = Common.ObjectAttributeValue(Parent, "JointApplicationOption");
		
		ApplyMultiplicationWithinParentGroup = 
				MethodsOfProviding = Enums.MethodsToProvideDiscountsMarkups.Percent 
				And VariantOfJointApplicationOfGroup = Enums.OptionsOfJointUsageOfDiscountsAndMarkups.Multiplication;

	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
