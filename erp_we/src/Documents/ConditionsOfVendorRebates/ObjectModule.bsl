//@strict-types

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	FillInDataType = TypeOf(FillingData);
	
	If FillInDataType = Type("DocumentRef.ConditionsOfVendorRebates") Then
		
		DocumentReference = FillingData; // DocumentRef.ConditionsOfVendorRebates
		FillInAccordingToRebateConditionOfSuppliers(DocumentReference);
		
	EndIf;
	
	InitializeDocument();
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If ValueIsFilled(ValidOnDate)
	   And ValueIsFilled(ValidTo)
	   And ValidTo < ValidOnDate Then
		
		MessageText = NStr("vi = 'Ngày hết hiệu lực không được nhỏ hơn ngày đầu hiệu lực';
							|ru = 'Дата окончания действия должна быть не меньше даты начала действия';
							|en = 'End date must be later than the start date'; fa = 'End date must be later than the start date';
							|it = 'Дата окончания действия должна быть не меньше даты начала действия';
							|pl = 'End date must be later than the start date';
							|tr = 'Geçerlilik bitiş tarihi, geçerlilik başlangıç tarihinden daha az olmamalıdır'");
		Common.MessageToUser(MessageText, ThisObject, "ValidTo",, Cancel);
		
	EndIf;
	
	NotCheckedAttributeArray = New Array; // Array of String
	
	If RebateKind.IsEmpty() Then
		
		NotCheckedAttributeArray.Add("FilterParties");
		NotCheckedAttributeArray.Add("FilterOfProducts_");
		NotCheckedAttributeArray.Add("ConditionFrequency");
		NotCheckedAttributeArray.Add("AccrualFrequency");
		NotCheckedAttributeArray.Add("SumPlan");
		NotCheckedAttributeArray.Add("BonusPercent");
		NotCheckedAttributeArray.Add("CalculationScales");
		NotCheckedAttributeArray.Add("Currency");
		
		NotCheckedAttributeArray.Add("CustomerCounterparties");
		NotCheckedAttributeArray.Add("ClientsCounterpartiesTIN");
		NotCheckedAttributeArray.Add("Goods");
		NotCheckedAttributeArray.Add("ProductProperties_");
		NotCheckedAttributeArray.Add("GoodsSegments");
		NotCheckedAttributeArray.Add("Warehouses");
		NotCheckedAttributeArray.Add("Vendors");
		
	Else
		
		If FilterParties = Enums.RebatesLists.All
		 Or FilterParties = Enums.RebatesLists.EmptyRef() Then
			
			NotCheckedAttributeArray.Add("CustomerCounterparties");
			NotCheckedAttributeArray.Add("ClientsCounterpartiesTIN");
			
		EndIf;
		
		If FilterOfProducts_ = Enums.RebatesLists.All Then
			
			NotCheckedAttributeArray.Add("Goods");
			NotCheckedAttributeArray.Add("ProductProperties_");
			NotCheckedAttributeArray.Add("GoodsSegments");
			
		EndIf;
		
		KindAttributes = DocumentTypeData();
		
		CalculationByScale =
			(KindAttributes.GoodsIndicator = Enums.TargetSalesIndicatorsOfRebatesByGoods.Sum
		     And CalculationScaleType <> 0); // Not the only value
		
		If Not CalculationByScale Then
			NotCheckedAttributeArray.Add("CalculationScales");
		EndIf;
		
		If BonusType = Enums.VendorRebateTypes.Balance Then
			
			#Region FillInArrayOfUnverifiableBankingDetailsBalance
			NotCheckedAttributeArray.Add("FilterParties");
			NotCheckedAttributeArray.Add("BonusPercent");
			NotCheckedAttributeArray.Add("CalculationScales");
			NotCheckedAttributeArray.Add("SumPlan");
			NotCheckedAttributeArray.Add("AmountBonus");
			NotCheckedAttributeArray.Add("Goods.Percent");
			NotCheckedAttributeArray.Add("ValidOnDate");
			NotCheckedAttributeArray.Add("ValidTo");
			NotCheckedAttributeArray.Add("AccrualFrequency");
			
			NotCheckedAttributeArray.Add("Vendors");
			NotCheckedAttributeArray.Add("CustomerCounterparties");
			NotCheckedAttributeArray.Add("ClientsCounterpartiesTIN");
			
			If SelectionOfWarehouses_ = Enums.RebatesLists.All Then
				NotCheckedAttributeArray.Add("Warehouses");
			EndIf;
			#EndRegion
			
		ElsIf BonusType = Enums.VendorRebateTypes.Purchases Then
			
			#Region FillInArrayOfUnverifiablePurchaseDetails
			NotCheckedAttributeArray.Add("DateOfRemainingGoods");
			NotCheckedAttributeArray.Add("SelectionOfWarehouses_");
			NotCheckedAttributeArray.Add("Goods.Characteristic");
			NotCheckedAttributeArray.Add("Goods.AmountBonus");
			NotCheckedAttributeArray.Add("Goods.BonusPerUnit");
			NotCheckedAttributeArray.Add("FilterParties");
			NotCheckedAttributeArray.Add("Warehouses");
			NotCheckedAttributeArray.Add("Counterparty");
			NotCheckedAttributeArray.Add("Partner");
			
			If Not ModeMultipleVendors Then
				
				NotCheckedAttributeArray.Add("Vendors");
				
			EndIf;
			
			If KindAttributes.ContentOfGoods = Enums.RebatesItems.Products Then
				
				NotCheckedAttributeArray.Add("GoodsSegments");
				
			ElsIf KindAttributes.ContentOfGoods = Enums.RebatesItems.ProductSegments Then	
				
				NotCheckedAttributeArray.Add("Goods");
				
			EndIf;
			
			If KindAttributes.PartyList = Enums.RebatesParticipants.TIN Then
				
				NotCheckedAttributeArray.Add("CustomerCounterparties");
				
			ElsIf KindAttributes.PartyList = Enums.RebatesParticipants.Counterparties Then
				
				NotCheckedAttributeArray.Add("ClientsCounterpartiesTIN");
				
			EndIf;
			#EndRegion
			
		ElsIf BonusType = Enums.VendorRebateTypes.Sales Then
			
			#Region FillInArrayOfUnverifiableSalesDetails
			NotCheckedAttributeArray.Add("DateOfRemainingGoods");
			NotCheckedAttributeArray.Add("SelectionOfWarehouses_");
			NotCheckedAttributeArray.Add("Goods.Characteristic");
			NotCheckedAttributeArray.Add("Goods.AmountBonus");
			NotCheckedAttributeArray.Add("Goods.BonusPerUnit");
			
			NotCheckedAttributeArray.Add("Warehouses");
			NotCheckedAttributeArray.Add("Vendors");
			
			If KindAttributes.ContentOfGoods = Enums.RebatesItems.Products Then
				
				NotCheckedAttributeArray.Add("GoodsSegments");
				
			ElsIf KindAttributes.ContentOfGoods = Enums.RebatesItems.ProductSegments Then	
				
				NotCheckedAttributeArray.Add("Goods");
				
			EndIf;
			
			If KindAttributes.PartyList = Enums.RebatesParticipants.TIN Then
				
				NotCheckedAttributeArray.Add("CustomerCounterparties");
				
			ElsIf KindAttributes.PartyList = Enums.RebatesParticipants.Counterparties Then
				
				NotCheckedAttributeArray.Add("ClientsCounterpartiesTIN");
				
			EndIf;
			#EndRegion
			
		EndIf;
		
		#Region BonusPercent
		ProhibitionOfExceedingAmount =
			(KindAttributes.GoodsIndicator = Enums.TargetSalesIndicatorsOfRebatesByGoods.Sum
			 And RestrictAccrualOverPlan);
		If (KindAttributes.ContentOfGoods = Enums.RebatesItems.Products
		      Or KindAttributes.ContentOfGoods = Enums.RebatesItems.ProductItemProperty)
		   And FilterOfProducts_ = Enums.RebatesLists.Selected_
		   And Not ProhibitionOfExceedingAmount Then
			
			NotCheckedAttributeArray.Add("BonusPercent");
			
		EndIf;
		
		If WithoutCalculation
		 Or CalculationByScale
		 Or (KindAttributes.GoodsIndicator <> Enums.TargetSalesIndicatorsOfRebatesByGoods.NotUsed
			  And KindAttributes.GoodsIndicator <> Enums.TargetSalesIndicatorsOfRebatesByGoods.Sum) Then
			
			NotCheckedAttributeArray.Add("BonusPercent");
			
		EndIf;
		#EndRegion
		
		CheckCompletionOfHeaderPeriods(KindAttributes, Cancel);
		
		NeedToCheckConditionPeriod =
			(BonusType = Enums.VendorRebateTypes.Purchases
			Or BonusType = Enums.VendorRebateTypes.Sales)
				 And KindAttributes.GoodsIndicator <> Enums.TargetSalesIndicatorsOfRebatesByGoods.NotUsed;
		If WithoutCalculation
		 Or Not NeedToCheckConditionPeriod Then
			
			NotCheckedAttributeArray.Add("ConditionFrequency");
			
		EndIf;
		
		If WithoutCalculation Then
			
			NotCheckedAttributeArray.Add("DateOfRemainingGoods");
			NotCheckedAttributeArray.Add("SelectionOfWarehouses_");
			
			NotCheckedAttributeArray.Add("Goods");
			NotCheckedAttributeArray.Add("ProductProperties_");
			NotCheckedAttributeArray.Add("GoodsSegments");
			NotCheckedAttributeArray.Add("CustomerCounterparties");
			NotCheckedAttributeArray.Add("ClientsCounterpartiesTIN");
			NotCheckedAttributeArray.Add("FilterParties");
			NotCheckedAttributeArray.Add("FilterOfProducts_");
			NotCheckedAttributeArray.Add("Warehouses");
			NotCheckedAttributeArray.Add("Vendors");
			
		Else
			
			NotCheckedAttributeArray.Add("AmountBonus");
			
		EndIf;
		
		// If the indicator is not a sum, or a sum, but not by a single value
		If KindAttributes.GoodsIndicator <> Enums.TargetSalesIndicatorsOfRebatesByGoods.Sum
		 Or (KindAttributes.GoodsIndicator = Enums.TargetSalesIndicatorsOfRebatesByGoods.Sum
		      And RebateKind <> 0) Then
			
			NotCheckedAttributeArray.Add("SumPlan");
			
		EndIf;
		
		NeedCurrencyCheck =
			(WithoutCalculation
			 Or KindAttributes.BaseOfCalculation = Enums.RebateCalculationBases.PurchaseAmountBasePrices
			 Or KindAttributes.BaseOfCalculation = Enums.RebateCalculationBases.RevenueBasePrices)
			 Or BonusType = Enums.VendorRebateTypes.Balance
			 Or KindAttributes.GoodsIndicator = Enums.TargetSalesIndicatorsOfRebatesByGoods.Sum;
		
		If Not NeedCurrencyCheck Then
			
			NotCheckedAttributeArray.Add("Currency");
			
		EndIf;
		
		CheckCompositionOfVendors(Cancel);
		
		CheckNumberOfParticipantsCounterparties(KindAttributes, NotCheckedAttributeArray, Cancel);
		CheckTINByCompositionOfParticipants(KindAttributes, NotCheckedAttributeArray, Cancel);
		
		CheckCompositionOfGoodsItem(KindAttributes, NotCheckedAttributeArray, Cancel);
		CheckPropertiesOfItemByCompositionOfItems(KindAttributes, NotCheckedAttributeArray, Cancel);
		CheckItemSegmentsByCompositionOfGoods(KindAttributes, NotCheckedAttributeArray, Cancel);
		CheckByWarehouseComposition(KindAttributes, Cancel);
		CheckSupplierData(KindAttributes, Cancel);
		
		RebatesServer.CheckCalculationScales(CalculationScales, CalculationScaleType, KindAttributes, Cancel);
		CheckAccrualLimits(KindAttributes, Cancel);
		
	EndIf;
	
	DocumentCorrection.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	If BonusType = Enums.VendorRebateTypes.Balance Then
		ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject, NotCheckedAttributeArray, Cancel);
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If ExchangePlans.MasterNode() <> Undefined Then
		
		MessageText = NStr("vi = 'Cấm thay đổi chứng từ trong nút phụ trao đổi';
							|ru = 'Запрещено изменение документа в подчиненном узле обмена';
							|en = 'Cannot change the document in a subordinate exchange node'; fa = 'Cannot change the document in a subordinate exchange node';
							|it = 'Запрещено изменение документа в подчиненном узле обмена';
							|pl = 'Cannot change the document in a subordinate exchange node';
							|tr = 'Bağımlı değişim düğümündeki belgenin değiştirilmesi yasaktır'");
		Common.MessageToUser(MessageText, ThisObject,,, Cancel);
		
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	RebatesServer.CheckChainOfDocuments(
		CorrectedDocument, ReversedDocument, ChainID, WriteMode);
	
	SkipCheckingChangesByStatus = CommonClientServer.StructureProperty(
		AdditionalProperties,
		"SkipCheckingChangesByStatus",
		False);
	
	Allowed1Update = True;
	
	If Not Status.IsEmpty()
	   And Not SkipCheckingChangesByStatus Then
		
		Allowed1Update = Documents.ConditionsOfVendorRebates.ChangeByStatusIsAllowed(Status);
		If Not Allowed1Update Then
			
			ErrorTemplate = NStr("vi = 'Cấm thay đổi chứng từ với trạng thái ""%1""';
								|ru = 'Изменение документа в статусе ""%1"" запрещено';
								|en = 'Cannot change the document in the ""%1"" status'; fa = 'Cannot change the document in the ""%1"" status';
								|it = 'Изменение документа в статусе ""%1"" запрещено';
								|pl = 'Cannot change the document in the ""%1"" status';
								|tr = 'Belgenin ""%1"" durumuna değiştirilmesi yasaktır'");
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorTemplate, String(Status));
			
			Common.MessageToUser(ErrorText, ThisObject, "Status",, Cancel);
			
		EndIf;
		
	EndIf;
	
	If Not RebateKind.IsEmpty() Then
		
		KindAttributes = DocumentTypeData();
		
		If KindAttributes.GoodsIndicator <> Enums.TargetSalesIndicatorsOfRebatesByGoods.Sum
		   And KindAttributes.GoodsIndicator <> Enums.TargetSalesIndicatorsOfRebatesByGoods.Count Then
			
			CalculationScaleType = 0; // default value
			
		EndIf;
		
		RebatesServer.ClearCalculationScales(CalculationScales, CalculationScaleType, KindAttributes);
		
		If BonusType = Enums.VendorRebateTypes.Balance Then
			
			FilterParties = Enums.RebatesLists.EmptyRef();
			ConditionFrequency = Enums.RebatesFrequencies.EmptyRef();
			SumPlan = 0;
			BonusPercent = 0;
			ValidOnDate = Date(1, 1, 1);
			ValidTo = Date(1, 1, 1);
			
			If AccrueImmediately Then
				
				AmountBonus = Goods.Total("AmountBonus");
				Warehouses.Clear();
				SelectionOfWarehouses_ = Enums.RebatesLists.All;
				
			Else
				
				AmountBonus = 0;
				
			EndIf;
			
		Else
			
			SelectionOfWarehouses_ = Enums.RebatesLists.EmptyRef();
			DateOfRemainingGoods = Date(1, 1, 1);
			If Not WithoutCalculation Then
				AccrueImmediately = False;
			EndIf;
			
		EndIf;
		
		If BonusType = Enums.VendorRebateTypes.Balance Then
			
			AccrualFrequency = Enums.RebatesFrequencies.EmptyRef();
			
		EndIf;
		
		If BonusType = Enums.VendorRebateTypes.Purchases Then
			
			FilterParties = Enums.RebatesLists.EmptyRef();
			
		EndIf;
		
		If WithoutCalculation Then
			
			ConditionFrequency = Enums.RebatesFrequencies.EmptyRef();
			FilterParties = Enums.RebatesLists.EmptyRef();
			
		EndIf;
		
		AdjustmentOfVendorDataAndInputModeByDataComposition();
		
		If WithoutCalculation
		 Or (KindAttributes.GoodsIndicator <> Enums.TargetSalesIndicatorsOfRebatesByGoods.Count
			  And KindAttributes.GoodsIndicator <> Enums.TargetSalesIndicatorsOfRebatesByGoods.Sum) Then
			
			RestrictAccrualOverPlan = False;
			
		EndIf;
		
		ProhibitionOfExceedingAmount =
			(KindAttributes.GoodsIndicator = Enums.TargetSalesIndicatorsOfRebatesByGoods.Sum
			 And RestrictAccrualOverPlan);
		If WithoutCalculation
		 Or Not (FilterOfProducts_ <> Enums.RebatesLists.Selected_
				 Or KindAttributes.ContentOfGoods = Enums.RebatesItems.ProductSegments
				 Or ProhibitionOfExceedingAmount) Then
			
			BonusPercent = 0;
			
		EndIf;
		
		ParametersOfParticipants = Documents.ConditionsOfVendorRebates.ParametersForClearingParticipantsAttributes();
		ParametersOfParticipants.PartyList = KindAttributes.PartyList;
		ParametersOfParticipants.FilterParties = FilterParties;
		Documents.ConditionsOfVendorRebates.ClearUnusedDetailsOfParticipants(
			ThisObject, ParametersOfParticipants);
		
		GoodsParameters = Documents.ConditionsOfVendorRebates.ParametersForClearingGoodsAttributes();
		GoodsParameters.ContentOfGoods = KindAttributes.ContentOfGoods;
		GoodsParameters.FilterOfProducts_ = FilterOfProducts_;
		GoodsParameters.GoodsIndicator = KindAttributes.GoodsIndicator;
		GoodsParameters.BaseOfCalculation = KindAttributes.BaseOfCalculation;
		GoodsParameters.BonusType = BonusType;
		GoodsParameters.AccrueImmediately = AccrueImmediately;
		Documents.ConditionsOfVendorRebates.ClearUnusedGoodsDetails(ThisObject, GoodsParameters);
		
		If Not ModeMultipleVendors
		 Or Not Patch Then
			
			DateEmpty = Date(1, 1, 1);
			
			For Each TSRow In Vendors Do
				
				TSRow.Canceled = False;
				TSRow.StartDateBeforeChange = DateEmpty;
				TSRow.EndDateBeforeChange = DateEmpty;
				
			EndDo
			
		EndIf;
		
	EndIf;
	
	If Patch Then
		
		TermsAndConditionsAttributes = Documents.ConditionsOfVendorRebates.UpToDateData(CorrectedDocument);
		If TermsAndConditionsAttributes.RecordingIsCompleted
		   And Allowed1Update Then
			
			NotificationText2 = NStr("vi = 'Đã ấn định thành phần chứng từ, không thể nhập chỉnh sửa.';
									|ru = 'Состав документа зафиксирован, ввод исправлений невозможен.';
									|en = 'The document content is recorded. Cannot register the corrections.'; fa = 'The document content is recorded. Cannot register the corrections.';
									|it = 'The document content is recorded. Cannot register the corrections.';
									|pl = 'The document content is recorded. Cannot register the corrections.';
									|tr = 'Belge içeriği sabitlendi, düzeltme yapmak mümkün değildir.'");
			Common.MessageToUser(NotificationText2, ThisObject,,, Cancel);
			
		EndIf;
		
	EndIf;
	
	If Allowed1Update Then
		
		CheckAccrualLimits(KindAttributes, Cancel, True);
		
	EndIf;
	
	DocumentCorrection.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	DocumentCorrection.OnCopy(ThisObject, CopiedObject);
	
	Status = Enums.RebatesDocumentStatuses.Draft;
	
	NamesOfFieldsToBeCleared = New Array; // Array of String
	NamesOfFieldsToBeCleared.Add("StartDateBeforeChange");
	NamesOfFieldsToBeCleared.Add("EndDateBeforeChange");
	
	RebatesServer.InitializeListToBeCopied(ThisObject, "CustomerCounterparties");
	RebatesServer.InitializeListToBeCopied(ThisObject, "ClientsCounterpartiesTIN", NamesOfFieldsToBeCleared);
	
	RebatesServer.InitializeListToBeCopied(ThisObject, "Goods", NamesOfFieldsToBeCleared);
	RebatesServer.InitializeListToBeCopied(ThisObject, "ProductProperties_", NamesOfFieldsToBeCleared);
	RebatesServer.InitializeListToBeCopied(ThisObject, "GoodsSegments");
	
	RebatesServer.InitializeListToBeCopied(ThisObject, "Vendors", NamesOfFieldsToBeCleared);
	
	InitializeDocument();
	
EndProcedure

Procedure OnSetNewNumber(StandardProcessing, Prefix)
	
	Prefix = ?(Patch, "K", "0");
	
EndProcedure

#EndRegion

#Region Private

// Document type data.
// 
// Returns:
//  Structure:
//	* WithoutCalculation - Boolean
//	* ValidOnDate - Date
//	* ValidTo - Date 
//	* ConditionFrequency - EnumRef.RebatesFrequencies
//	* AccrualFrequency - EnumRef.RebatesFrequencies
//	* FilterOfProducts_ - EnumRef.RebatesLists
//	* FilterParties - EnumRef.RebatesLists
//	* GoodsIndicator - EnumRef.TargetSalesIndicatorsOfRebatesByGoods
//	* BaseOfCalculation - EnumRef.RebateCalculationBases
//	* ContentOfGoods - EnumRef.RebatesItems
//	* PartyList - EnumRef.RebatesParticipants
//	* ProductItemProperty - String
//
Function DocumentTypeData()
	
	AttributesArray = New Array; // Array of String
	AttributesArray.Add("ValidOnDate");
	AttributesArray.Add("ValidTo");
	AttributesArray.Add("ConditionFrequency");
	AttributesArray.Add("AccrualFrequency");
	AttributesArray.Add("ContentOfGoods");
	AttributesArray.Add("FilterOfProducts_");
	AttributesArray.Add("PartyList");
	AttributesArray.Add("FilterParties");
	AttributesArray.Add("WithoutCalculation");
	AttributesArray.Add("GoodsIndicator");
	AttributesArray.Add("BaseOfCalculation");
	AttributesArray.Add("ProductItemProperty");
	
	KindAttributes = Common.ObjectAttributesValues(RebateKind, AttributesArray);
	
	Return KindAttributes;
	
EndFunction

// Fill in according to the condition of retro customer bonuses.
// 
// Parameters:
//  FillingData - DocumentRef.ConditionsOfVendorRebates - fill-in data
//
Procedure FillInAccordingToRebateConditionOfSuppliers(FillingData)
	
	FillingDocument = FillingData; // DocumentRef.ConditionsOfVendorRebates
	LastFix = DocumentCorrection.LastCorrectiveDocument(FillingDocument);
	
	AttributesNames = New Structure;
	AttributesNames.Insert("ValidOnDate");
	AttributesNames.Insert("ValidTo");
	AttributesNames.Insert("SumPlan");
	AttributesNames.Insert("GoodsIndicator", "RebateKind.GoodsIndicator");
	AttributesNames.Insert("PartyList", "RebateKind.PartyList");
	
	If LastFix = Undefined Then
		
		DocumentCorrection.FillInCorrection(ThisObject, FillingDocument);
		DetailsOfFoundation = Common.ObjectAttributesValues(FillingDocument, AttributesNames);
		
	Else
		
		LastFixLink = LastFix.Ref; // DocumentRef.ConditionsOfVendorRebates
		
		LastFixStatus = Common.ObjectAttributeValue(
			LastFixLink, "Status");
		If LastFixStatus <> Enums.RebatesDocumentStatuses.Approved Then
			
			NotificationText2 = NStr("vi = 'Không thể chỉnh sửa khi chưa thống nhất chứng từ cuối cùng trong chuỗi chỉnh sửa';
									|ru = 'Последний в цепочке исправлений документ не согласован, ввод исправлений невозможен';
									|en = 'The last document in the correction chain is not approved. Cannot register the correction'; fa = 'The last document in the correction chain is not approved. Cannot register the correction';
									|it = 'Последний в цепочке исправлений документ не согласован, ввод исправлений невозможен';
									|pl = 'The last document in the correction chain is not approved. Cannot register the correction';
									|tr = 'Düzeltmeler zincirinde son belge eşleşmiyor, düzeltmeler girilemiyor'");
			Raise NotificationText2;
			
		EndIf;
		
		DocumentCorrection.FillInCorrection(ThisObject, LastFix.Ref);
		DetailsOfFoundation = Common.ObjectAttributesValues(LastFix.Ref, AttributesNames);
		
	EndIf;
	
	If AccrualFrequency = Enums.RebatesFrequencies.Single
	 Or BonusType = Enums.VendorRebateTypes.Balance Then
		
		MaxDate = RebatesServer.LimitOfSupplierCharges(CorrectedDocument);
		If MaxDate <> Date(1, 1, 1) Then
			
			NotificationText2 = NStr("vi = 'Không thể chỉnh sửa khi đã ghi nhận tính thưởng lũy kế';
									|ru = 'Зарегистрировано начисление ретро-бонусов, ввод исправлений невозможен';
									|en = 'Rebate accrual is registered. Cannot register the corrections'; fa = 'Rebate accrual is registered. Cannot register the corrections';
									|it = 'Зарегистрировано начисление ретро-бонусов, ввод исправлений невозможен';
									|pl = 'Rebate accrual is registered. Cannot register the corrections';
									|tr = 'Retro bonusu tahakkuku kaydedildi, düzeltmeler girilemiyor'");
			Raise NotificationText2;
			
		EndIf;
		
	EndIf;
	
	TermsAndConditionsAttributes = Documents.ConditionsOfVendorRebates.UpToDateData(CorrectedDocument);
	If TermsAndConditionsAttributes.RecordingIsCompleted Then
		
		NotificationText2 = NStr("vi = 'Đã ấn định thành phần chứng từ, không thể nhập chỉnh sửa.';
								|ru = 'Состав документа зафиксирован, ввод исправлений невозможен.';
								|en = 'The document content is recorded. Cannot register the corrections.'; fa = 'The document content is recorded. Cannot register the corrections.';
								|it = 'The document content is recorded. Cannot register the corrections.';
								|pl = 'The document content is recorded. Cannot register the corrections.';
								|tr = 'Belge içeriği sabitlendi, düzeltme yapmak mümkün değildir.'");
		Raise NotificationText2;
		
	EndIf;
	
	Status = Enums.RebatesDocumentStatuses.Draft;
	IncomingDocumentNumber = "";
	IncomingDocumentDate = Date(1, 1, 1);
	
	#Region PM_CounterpartiesOfClients
	LinesToDelete = New Array; // Array of DocumentTabularSectionRow.ConditionsOfVendorRebates.CustomerCounterparties
	
	For Each TSRow In CustomerCounterparties Do
		
		If TSRow.Canceled Then
			
			LinesToDelete.Add(TSRow);
			Continue;
			
		EndIf;
		
		TSRow.InitialString = True;
		
		If FilterParties = Enums.RebatesLists.Selected_ Then
			
			FillInPeriodDataBasedOn(TSRow, DetailsOfFoundation);
			
		EndIf;
		
	EndDo;
	
	For Each RowToDelete In LinesToDelete Do
		
		CustomerCounterparties.Delete(RowToDelete);
		
	EndDo;
	#EndRegion
	
	#Region PM_INNOfCounterpartiesOfClients
	LinesToDelete = New Array; // Array of DocumentTabularSectionRow.ConditionsOfVendorRebates.ClientsCounterpartiesTIN
	
	For Each TSRow In ClientsCounterpartiesTIN Do
		
		If TSRow.Canceled Then
			
			LinesToDelete.Add(TSRow);
			Continue;
			
		EndIf;
		
		TSRow.InitialString = True;
		
		If FilterParties = Enums.RebatesLists.Selected_ Then
			
			FillInPeriodDataBasedOn(TSRow, DetailsOfFoundation);
			
		EndIf;
		
	EndDo;
	
	For Each RowToDelete In LinesToDelete Do
		
		ClientsCounterpartiesTIN.Delete(RowToDelete);
		
	EndDo;
	#EndRegion
	
	#Region TS_Goods
	LinesToDelete = New Array; // Array of DocumentTabularSectionRow.ConditionsOfVendorRebates.Goods
	
	For Each TSRow In Goods Do
		
		If TSRow.Canceled Then
			
			LinesToDelete.Add(TSRow);
			Continue;
			
		EndIf;
		
		TSRow.InitialString = True;
		
		If RebatesClientServer.PeriodOfGoodsConditionsIsUsed(DetailsOfFoundation.GoodsIndicator) Then
			
			FillInPeriodDataBasedOn(TSRow, DetailsOfFoundation);
			
		EndIf;
		
	EndDo;
	
	For Each RowToDelete In LinesToDelete Do
		
		Goods.Delete(RowToDelete);
		
	EndDo;
	#EndRegion
	
	#Region PM_ItemProperties
	LinesToDelete = New Array; // Array of DocumentTabularSectionRow.ConditionsOfVendorRebates.ProductProperties_
	
	For Each TSRow In ProductProperties_ Do
		
		If TSRow.Canceled Then
			
			LinesToDelete.Add(TSRow);
			Continue;
			
		EndIf;
		
		TSRow.InitialString = True;
		
		If RebatesClientServer.PeriodOfGoodsConditionsIsUsed(DetailsOfFoundation.GoodsIndicator) Then
			
			FillInPeriodDataBasedOn(TSRow, DetailsOfFoundation);
			
		EndIf;
		
	EndDo;
	
	For Each RowToDelete In LinesToDelete Do
		
		ProductProperties_.Delete(RowToDelete);
		
	EndDo;
	#EndRegion
	
	#Region PM_GoodsSegments
	LinesToDelete = New Array; // Array of DocumentTabularSectionRow.ConditionsOfVendorRebates.GoodsSegments
	
	For Each TSRow In GoodsSegments Do
		
		If TSRow.Canceled Then
			
			LinesToDelete.Add(TSRow);
			Continue;
			
		EndIf;
		
		TSRow.InitialString = True;
		
	EndDo;
	
	For Each RowToDelete In LinesToDelete Do
		
		GoodsSegments.Delete(RowToDelete);
		
	EndDo;
	#EndRegion
	
	#Region PM_Vendors
	LinesToDelete = New Array; // Array of DocumentTabularSectionRow.ConditionsOfVendorRebates.Vendors
	
	For Each TSRow In Vendors Do
		
		If TSRow.Canceled Then
			
			LinesToDelete.Add(TSRow);
			Continue;
			
		EndIf;
		
		TSRow.InitialString = True;
		
		FillInPeriodDataBasedOn(TSRow, DetailsOfFoundation);
		
	EndDo;
	
	For Each RowToDelete In LinesToDelete Do
		
		Vendors.Delete(RowToDelete);
		
	EndDo;
	#EndRegion
	
EndProcedure

// Parameters:
//  DataString1 - LineOfATabularSection:
//  * ValidOnDate - Date
//  * StartDateBeforeChange - Date
//  * ValidTo - Date
//  * EndDateBeforeChange - Date
//	TheseGrounds - Structure:
//  * ValidOnDate - Date
//  * ValidTo - Date
//
Procedure FillInPeriodDataBasedOn(DataString1, Val TheseGrounds)
	
	DateEmpty = Date(1, 1, 1);
	
	If DataString1.ValidOnDate = DateEmpty Then
				
		DataString1.StartDateBeforeChange = TheseGrounds.ValidOnDate;
		
	Else
		
		DataString1.StartDateBeforeChange = DataString1.ValidOnDate;
		
	EndIf;
	
	If DataString1.ValidTo = DateEmpty Then
		
		DataString1.EndDateBeforeChange = TheseGrounds.ValidTo;
		
	Else
		
		DataString1.EndDateBeforeChange = DataString1.ValidTo;
		
	EndIf;
	
EndProcedure

// Parameters:
//  KindAttributes - See DocumentTypeData
//  Cancel - Boolean - Cancel
//
Procedure CheckCompletionOfHeaderPeriods(KindAttributes, Cancel)
	
	If BonusType = Enums.VendorRebateTypes.Balance Then
		Return;
	EndIf;
	
	DateEmpty = Date(1, 1, 1);
	MaxDate = Date(2999, 12, 31);
	
	BeginningOfTypeAction = KindAttributes.ValidOnDate;
	TerminationOfView = KindAttributes.ValidTo;
	If TerminationOfView = DateEmpty Then
		TerminationOfView = MaxDate;
	EndIf;
	
	If ValidOnDate <> DateEmpty
	   And ValidOnDate < BeginningOfTypeAction Then
		
		MessageText = NStr("vi = 'Đầu kỳ hiệu lực của chứng từ sớm hơn đầu kỳ hiệu lực của dạng thưởng lũy kế';
							|ru = 'Начало периода действия документа раньше, чем начало действия вида ретро-бонуса';
							|en = 'The document validity period start is earlier than the rebate kind start'; fa = 'The document validity period start is earlier than the rebate kind start';
							|it = 'Начало периода действия документа раньше, чем начало действия вида ретро-бонуса';
							|pl = 'The document validity period start is earlier than the rebate kind start';
							|tr = 'Belgenin geçerlilik döneminin bitiş tarihinin retro bonusu türünün son süresinden büyük olması'");
		Common.MessageToUser(MessageText, ThisObject, "ValidOnDate",, Cancel);
		
	EndIf;
	
	If ValidTo <> DateEmpty
	   And ValidTo > TerminationOfView Then
		
		MessageText = NStr("vi = 'Cuối kỳ hiệu lực của chứng từ muộn hơn cuối kỳ hiệu lực của dạng thưởng lũy kế';
							|ru = 'Окончание периода действия документа больше, чем окончание действия вида ретро-бонуса';
							|en = 'The document validity period end is later than the rebate kind end'; fa = 'The document validity period end is later than the rebate kind end';
							|it = 'Окончание периода действия документа больше, чем окончание действия вида ретро-бонуса';
							|pl = 'The document validity period end is later than the rebate kind end';
							|tr = 'Belgenin geçerlilik süresinin bitiş tarihinin retro bonusu türünün son süresinden büyük olması'");
		Common.MessageToUser(MessageText, ThisObject, "ValidTo",, Cancel);
		
	EndIf;
	
	If ValidOnDate <> DateEmpty
	   And ValidTo <> DateEmpty Then
		
		CheckResult = RebatesServer.CheckPeriodsByTimeFence(
			ConditionFrequency, 
			ValidOnDate,
			ValidTo);
		If CheckResult.ThereIsViolationOfBeginning Then
			
			Common.MessageToUser(
				CheckResult.TextOfStartError, ThisObject, "ValidOnDate",, Cancel);
			
		EndIf;
		
		If CheckResult.ThereIsViolationOfEnding Then
			
			Common.MessageToUser(
				CheckResult.TextOfEndingError, ThisObject, "ValidTo",, Cancel);
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Parameters:
//  KindAttributes - See DocumentTypeData
//  NotCheckedAttributeArray - Array of String- Array of unverifiable Attributes
//  Cancel - Boolean - Cancel
//
Procedure CheckNumberOfParticipantsCounterparties(KindAttributes, NotCheckedAttributeArray, Cancel)
	
	If KindAttributes.PartyList <> Enums.RebatesParticipants.Counterparties
	 Or FilterParties = Enums.RebatesLists.All
	 Or FilterParties = Enums.RebatesLists.EmptyRef() Then
		Return;
	EndIf;
	
	TableName = "CustomerCounterparties";
	TablePresentation = RebatesClientServer.PageTitleBySettings(
		KindAttributes.PartyList, FilterParties, True);
	If FilterParties = Enums.RebatesLists.Selected_ Then
		
		RebatesServer.CheckTablePeriods(
			ThisObject, TableName, TablePresentation, Cancel);
		
	EndIf;
	
	RowFilter = New Structure;
	RowFilter.Insert("Canceled", False);
	RebatesServer.CheckForDuplicatesOfTSStrings(
		ThisObject, TableName, "Counterparty", Cancel, TablePresentation,, RowFilter);
	
	RebatesServer.CheckForValidLines(
		ThisObject, TableName, TablePresentation, Cancel);
	
	NotCheckedAttributeArray.Add("ClientsCounterpartiesTIN");
	
EndProcedure

// Parameters:
//  KindAttributes - See DocumentTypeData
//  NotCheckedAttributeArray - Array of String- Array of unverifiable Attributes
//  Cancel - Boolean - Cancel
//
Procedure CheckTINByCompositionOfParticipants(KindAttributes, NotCheckedAttributeArray, Cancel)
	
	If KindAttributes.PartyList <> Enums.RebatesParticipants.TIN
	 Or FilterParties = Enums.RebatesLists.All
	 Or FilterParties = Enums.RebatesLists.EmptyRef() Then
		Return;
	EndIf;
	
	TableName = "ClientsCounterpartiesTIN";
	TablePresentation = RebatesClientServer.PageTitleBySettings(
		KindAttributes.PartyList, FilterParties, True);
	If FilterParties = Enums.RebatesLists.Selected_ Then
		
		RebatesServer.CheckTablePeriods(
			ThisObject, TableName, TablePresentation, Cancel);
		
	EndIf;
	
	RowFilter = New Structure;
	RowFilter.Insert("Canceled", False);
	RebatesServer.CheckForDuplicatesOfTSStrings(
		ThisObject, TableName, "TIN", Cancel, TablePresentation,, RowFilter);
	
	RebatesServer.CheckForValidLines(
		ThisObject, TableName, TablePresentation, Cancel);
	
	RebatesServer.CheckFillingInINN(ThisObject, TableName, TablePresentation, Cancel);
	NotCheckedAttributeArray.Add("CustomerCounterparties");
	
EndProcedure

// Parameters:
//  KindAttributes - See DocumentTypeData
//  Cancel - Boolean - Cancel
//
Procedure CheckByWarehouseComposition(KindAttributes, Cancel)
	
	If BonusType <> Enums.VendorRebateTypes.Balance
	 Or SelectionOfWarehouses_ = Enums.RebatesLists.All Then
		Return;
	EndIf;
	
	TableName = "Warehouses";
	TablePresentation = RebatesClientServer.PageTitleWarehouses(SelectionOfWarehouses_);
	
	RebatesServer.CheckForDuplicatesOfTSStrings(
		ThisObject, TableName, "Warehouse", Cancel, TablePresentation,);
	
EndProcedure

// Parameters:
//  KindAttributes - See DocumentTypeData
//  Cancel - Boolean - Cancel
//
Procedure CheckSupplierData(KindAttributes, Cancel)
	
	If BonusType <> Enums.VendorRebateTypes.Purchases Then
		Return;
	EndIf;
		
	MessageTemplate = NStr("vi = 'Trong dòng %1 của danh sách Nhà cung cấp, cần điền một trong số các trường ""Đối tác"", ""Nhà cung cấp""';
							|ru = 'В строке %1 списка Поставщики необходимо заполнить одно из полей ""Контрагент"", ""Поставщик""';
							|en = 'In line %1 of the ""Vendors"" list, fill in one of the fields: ""Counterparty"" or ""Vendor""'; fa = 'In line %1 of the ""Vendors"" list, fill in one of the fields: ""Counterparty"" or ""Vendor""';
							|it = 'В строке %1 списка Поставщики необходимо заполнить одно из полей ""Контрагент"", ""Поставщик""';
							|pl = 'In line %1 of the ""Vendors"" list, fill in one of the fields: ""Counterparty"" or ""Vendor""';
							|tr = 'Tedarikçiler listesinin %1 satırında ""Cari Hesap"", ""Tedarikçi"" alanlarından biri doldurulmalıdır'");
	ErrorText = NStr("vi = 'Cần điền một trong các trường ""Đối tác"", ""Nhà cung cấp""';
					|ru = 'Необходимо заполнить одно из полей ""Контрагент"", ""Поставщик""';
					|en = 'Fill in one of the fields: ""Counterparty"" or ""Vendor""'; fa = 'Fill in one of the fields: ""Counterparty"" or ""Vendor""';
					|it = 'Необходимо заполнить одно из полей ""Контрагент"", ""Поставщик""';
					|pl = 'Fill in one of the fields: ""Counterparty"" or ""Vendor""';
					|tr = '""Cari Hesap"" veya ""Tedarikçi"" alanlarından birinin doldurulması gerekmektedir'");
	
	If ModeMultipleVendors Then
		
		TableName = "Vendors";
		TablePresentation = NStr("vi = 'Nhà cung cấp';
								|ru = 'Поставщики';
								|en = 'Vendors'; fa = 'تأمین‌کنندگان';
								|it = 'Поставщики';
								|pl = 'Vendors';
								|tr = 'Tedarikçiler'");
		RebatesServer.CheckTablePeriods(ThisObject, TableName, TablePresentation, Cancel);
		
		RowFilter = New Structure;
		RowFilter.Insert("Canceled", False);
		
		KeyFields = "Counterparty,Partner,Contract,Terms";
		
		RebatesServer.CheckForDuplicatesOfTSStrings(
			ThisObject, TableName, KeyFields, Cancel, TablePresentation,, RowFilter);
		
		For Each CurrentRow In Vendors Do
			
			LineNumber = CurrentRow.LineNumber;
			
			CounterpartyIsNotFilledIn = Not ValueIsFilled(CurrentRow.Counterparty);
			PartnerIsNotFilledIn = Not ValueIsFilled(CurrentRow.Partner);
			FieldsNotFilled = (CounterpartyIsNotFilledIn And PartnerIsNotFilledIn);
			
			If FieldsNotFilled Then
				
				Field = CommonClientServer.PathToTabularSection(
					TableName, LineNumber, "LineNumber");
					
				MessageText = StringFunctionsClientServer.SubstituteParametersToString(
					MessageTemplate, String(LineNumber));
				
				Common.MessageToUser(MessageText,, Field, "Object", Cancel);
				
			EndIf;
			
		EndDo;
		
	Else
		
		CounterpartyIsNotFilledIn = Not ValueIsFilled(Counterparty);
		PartnerIsNotFilledIn = Not ValueIsFilled(Partner);
		
		FieldsNotFilled = (CounterpartyIsNotFilledIn And PartnerIsNotFilledIn);
		
		If FieldsNotFilled Then
			
			Common.MessageToUser(ErrorText,, "Counterparty", "Object", Cancel);
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Parameters:
//  KindAttributes - See DocumentTypeData
//  NotCheckedAttributeArray - Array of String- Array of unverifiable Attributes
//  Cancel - Boolean - Cancel
//
Procedure CheckCompositionOfGoodsItem(KindAttributes, NotCheckedAttributeArray, Cancel)
	
	If KindAttributes.ContentOfGoods <> Enums.RebatesItems.Products
	 Or FilterOfProducts_ = Enums.RebatesLists.All Then
		Return;
	EndIf;
	
	ThisIsNumberByRanges = RebatesClientServer.ThisIsNumberByRanges(
		CalculationScaleType, KindAttributes.GoodsIndicator);
	GoodsIndicators = Enums.TargetSalesIndicatorsOfRebatesByGoods;
	
	NotCheckedAttributeArray.Add("ProductProperties_");
	NotCheckedAttributeArray.Add("GoodsSegments");
	
	If GetFunctionalOption("UseItemVariants") Then
		
		KeyFields = "Products,Characteristic";
		
	Else
		
		KeyFields = "Products";
		
	EndIf;
	
	TablePresentation = RebatesClientServer.PageTitleBySettings(
		KindAttributes.ContentOfGoods, FilterOfProducts_);
	
	If FilterOfProducts_ = Enums.RebatesLists.Selected_
	   And BonusType <> Enums.VendorRebateTypes.Balance Then
		
		ConditionPeriodsAreFilledIn = (ValueIsFilled(ValidOnDate)
								   And ValueIsFilled(ValidTo));
		
		RebatesServer.CheckTablePeriods(ThisObject, "Goods", TablePresentation, Cancel);
		
		If KindAttributes.GoodsIndicator = GoodsIndicators.QuantityTotal
		 Or KindAttributes.GoodsIndicator = GoodsIndicators.BatchOffer Then
			
			RowFilter = New Structure;
			RowFilter.Insert("Canceled", False);
			RebatesServer.CheckForDuplicatesOfTSStrings(
				ThisObject, "Goods", KeyFields, Cancel, TablePresentation,, RowFilter);
			
		EndIf;
		
		If ConditionPeriodsAreFilledIn Then
			
			If KindAttributes.GoodsIndicator = GoodsIndicators.Sum
			 Or KindAttributes.GoodsIndicator = GoodsIndicators.NotUsed
			 Or KindAttributes.GoodsIndicator = GoodsIndicators.Count Then
				
				CheckParameters = RebatesServer.ParametersForCheckingPeriodsByKeys();
				CheckParameters.ValidOnDate = ValidOnDate;
				CheckParameters.ValidTo = ValidTo;
				CheckParameters.ConditionFrequency = ConditionFrequency;
				CheckParameters.GoodsIndicator = KindAttributes.GoodsIndicator;
				CheckParameters.TablePresentation = TablePresentation;
				CheckParameters.CalculationScaleType = CalculationScaleType;
				
				RebatesServer.CheckGoodsPeriodsByKey(Goods, CheckParameters, Cancel);
				
			EndIf;
			
		EndIf;
		
		If KindAttributes.GoodsIndicator = GoodsIndicators.Sum
		   And (CalculationScaleType <> 0 // Percentage scale
		      Or RestrictAccrualOverPlan) Then
			
			NotCheckedAttributeArray.Add("Goods.Percent");
			
		EndIf;
		
	Else
		
		RowFilter = New Structure;
		RowFilter.Insert("Canceled", False);
		RebatesServer.CheckForDuplicatesOfTSStrings(
			ThisObject, "Goods", KeyFields, Cancel, TablePresentation,, RowFilter);
		
		NotCheckedAttributeArray.Add("Goods.ValidOnDate");
		NotCheckedAttributeArray.Add("Goods.ValidTo");
		
	EndIf;
	
	If KindAttributes.BaseOfCalculation <> Enums.RebateCalculationBases.RevenueBasePrices
	   And KindAttributes.BaseOfCalculation <> Enums.RebateCalculationBases.PurchaseAmountBasePrices Then
		
		NotCheckedAttributeArray.Add("Goods.BasePrice");
		
	EndIf;
	
	If FilterOfProducts_ <> Enums.RebatesLists.Selected_
	 Or BonusType = Enums.VendorRebateTypes.Balance
	 Or ThisIsNumberByRanges Then
		
		NotCheckedAttributeArray.Add("Goods.Percent");
		
	EndIf;
	
	ArrayIndicators = New Array; // Array of EnumRef.TargetSalesIndicatorsOfRebatesByGoods
	ArrayIndicators.Add(GoodsIndicators.Count);
	ArrayIndicators.Add(GoodsIndicators.QuantityTotal);
	ArrayIndicators.Add(GoodsIndicators.BatchOffer);
	
	CheckPlanQuantity = (BonusType = Enums.VendorRebateTypes.Balance
							   Or ArrayIndicators.Find(KindAttributes.GoodsIndicator) <> Undefined)
							   And FilterOfProducts_ = Enums.RebatesLists.Selected_;
	
	If Not CheckPlanQuantity
	 Or ThisIsNumberByRanges Then
		
		NotCheckedAttributeArray.Add("Goods.CountPlan");
		
	EndIf;
	
	If ThisIsNumberByRanges Then
		
		TempTableManager = New TempTablesManager();
		
		RebatesServer.CheckGoodsAvailabilityOfInitialRange(
			ThisObject, TablePresentation, TempTableManager, Cancel);
		
		RebatesServer.CheckGoodsIdentityOfTheseRanges(
			ThisObject, TablePresentation, TempTableManager, Cancel);
		
		RebatesServer.CheckGoodsForBonusInterest(
			ThisObject, TablePresentation, TempTableManager, Cancel);
		
	EndIf;
	
	If BonusType = PredefinedValue("Enum.VendorRebateTypes.Balance")
	   And Not AccrueImmediately Then
		
		NotCheckedAttributeArray.Add("Goods.AmountBonus");
		
	EndIf;
	
	RebatesServer.CheckForValidLines(ThisObject, "Goods", TablePresentation, Cancel);
	If BonusType <> Enums.VendorRebateTypes.Balance Then
		RebatesServer.CheckIndicationOfEmptyCharacteristicValues(ThisObject, TablePresentation, KindAttributes, Cancel);
	EndIf;
	
EndProcedure

// Parameters:
//  KindAttributes - See DocumentTypeData
//  NotCheckedAttributeArray - Array of String- Array of unverifiable Attributes
//  Cancel - Boolean - Cancel
//
Procedure CheckPropertiesOfItemByCompositionOfItems(KindAttributes, NotCheckedAttributeArray, Cancel)
	
	If KindAttributes.ContentOfGoods <> Enums.RebatesItems.ProductItemProperty Then
		Return;
	EndIf;
	
	ThisIsNumberByRanges = RebatesClientServer.ThisIsNumberByRanges(
		CalculationScaleType, KindAttributes.GoodsIndicator);
	GoodsIndicators = Enums.TargetSalesIndicatorsOfRebatesByGoods;
	NotCheckedAttributeArray.Add("Goods");
	NotCheckedAttributeArray.Add("GoodsSegments");
	
	KeyFields = "PropertyValue";
	
	ResultOfCheckingProperty  = RebatesServer.ItemPropertyVerificationData(KindAttributes.ProductItemProperty);
	If Not ResultOfCheckingProperty.AllowedToUse Then
		
		RebatesServer.ReportItemPropertiesError(ResultOfCheckingProperty, "RebateKind", Cancel);
		
	EndIf;
	
	If FilterOfProducts_ = Enums.RebatesLists.Selected_ Then
		
		ConditionPeriodsAreFilledIn = (ValueIsFilled(ValidOnDate)
								   And ValueIsFilled(ValidTo));
		
		TablePresentation = NStr("vi = 'Giá trị thuộc tính được chọn';
								|ru = 'Выбранные значения свойства';
								|en = 'Selected property values'; fa = 'Selected property values';
								|it = 'Selected property values';
								|pl = 'Selected property values';
								|tr = 'Seçilen özellik değerleri'");
		RebatesServer.CheckTablePeriods(ThisObject, "ProductProperties_", TablePresentation, Cancel);
		
		If KindAttributes.GoodsIndicator = GoodsIndicators.QuantityTotal
		 Or KindAttributes.GoodsIndicator = GoodsIndicators.BatchOffer Then
			
			RowFilter = New Structure;
			RowFilter.Insert("Canceled", False);
			RebatesServer.CheckForDuplicatesOfTSStrings(
				ThisObject, "ProductProperties_", KeyFields, Cancel, TablePresentation,, RowFilter);
			
		EndIf;
		
		If ConditionPeriodsAreFilledIn Then
			
			If KindAttributes.GoodsIndicator = GoodsIndicators.Sum
			 Or KindAttributes.GoodsIndicator = GoodsIndicators.NotUsed
			 Or KindAttributes.GoodsIndicator = GoodsIndicators.Count Then
				
				CheckParameters = RebatesServer.ParametersForCheckingPeriodsByKeys();
				CheckParameters.ValidOnDate = ValidOnDate;
				CheckParameters.ValidTo = ValidTo;
				CheckParameters.ConditionFrequency = ConditionFrequency;
				CheckParameters.GoodsIndicator = KindAttributes.GoodsIndicator;
				CheckParameters.TablePresentation = TablePresentation;
				CheckParameters.CalculationScaleType = CalculationScaleType;
				
				RebatesServer.CheckPeriodsOfItemPropertiesByKey(ProductProperties_, CheckParameters, Cancel);
				
			EndIf;
			
		EndIf;
		
		If KindAttributes.GoodsIndicator = GoodsIndicators.Sum
		   And (CalculationScaleType <> 0 // Percentage scale
		      Or RestrictAccrualOverPlan) Then
			
			NotCheckedAttributeArray.Add("ProductProperties_.Percent");
			
		EndIf;
		
	Else
		
		TablePresentation = NStr("vi = 'Ngoài giá trị thuộc tính';
								|ru = 'Кроме значений свойств';
								|en = 'Except for property values'; fa = 'Except for property values';
								|it = 'Except for property values';
								|pl = 'Except for property values';
								|tr = 'Özellik değerleri dışında'");
		
		RowFilter = New Structure;
		RowFilter.Insert("Canceled", False);
		RebatesServer.CheckForDuplicatesOfTSStrings(
			ThisObject, "ProductProperties_", KeyFields, Cancel, TablePresentation,, RowFilter);
		
		NotCheckedAttributeArray.Add("ProductProperties_.ValidOnDate");
		NotCheckedAttributeArray.Add("ProductProperties_.ValidTo");
		
	EndIf;
	
	If KindAttributes.BaseOfCalculation <> Enums.RebateCalculationBases.RevenueBasePrices
	   And KindAttributes.BaseOfCalculation <> Enums.RebateCalculationBases.PurchaseAmountBasePrices Then
		
		NotCheckedAttributeArray.Add("ProductProperties_.BasePrice");
		
	EndIf;
	
	If FilterOfProducts_ <> Enums.RebatesLists.Selected_
	 Or ThisIsNumberByRanges Then
		
		NotCheckedAttributeArray.Add("ProductProperties_.Percent");
		
	EndIf;
	
	If (KindAttributes.GoodsIndicator <> GoodsIndicators.Count
		  And KindAttributes.GoodsIndicator <> GoodsIndicators.QuantityTotal
		  And KindAttributes.GoodsIndicator <> GoodsIndicators.Count)
	 Or ThisIsNumberByRanges Then
		
		NotCheckedAttributeArray.Add("ProductProperties_.CountPlan");
		
	EndIf;
	
	If ThisIsNumberByRanges Then
		
		TempTableManager = New TempTablesManager();
		
		RebatesServer.CheckItemPropertiesForInitialRange(
			ThisObject, TablePresentation, TempTableManager, Cancel);
		
		RebatesServer.CheckPropertiesOfItemIdentityOfTheseRanges(
			ThisObject, TablePresentation, TempTableManager, Cancel);
		
		RebatesServer.CheckItemPropertiesForBonusPercentages(
			ThisObject, TablePresentation, TempTableManager, Cancel);
		
	EndIf;
	
	RebatesServer.CheckForValidLines(ThisObject, "ProductProperties_", TablePresentation, Cancel);
	
EndProcedure

// Parameters:
//  KindAttributes - See DocumentTypeData
//  NotCheckedAttributeArray - Array of String- Array of unverifiable Attributes
//  Cancel - Boolean - Cancel
//
Procedure CheckItemSegmentsByCompositionOfGoods(KindAttributes, NotCheckedAttributeArray, Cancel)
	
	If KindAttributes.ContentOfGoods <> Enums.RebatesItems.ProductSegments Then
		Return;
	EndIf;
	
	NotCheckedAttributeArray.Add("Goods");
	NotCheckedAttributeArray.Add("ProductProperties_");
	
	TableName = "GoodsSegments";
	TablePresentation = RebatesClientServer.PageTitleBySettings(
		KindAttributes.ContentOfGoods, FilterOfProducts_);
	
	RowFilter = New Structure;
	RowFilter.Insert("Canceled", False);
	RebatesServer.CheckForDuplicatesOfTSStrings(
		ThisObject, TableName, "Segment", Cancel, TablePresentation,, RowFilter);
	
	RebatesServer.CheckForValidLines(ThisObject, TableName, TablePresentation, Cancel);
	
EndProcedure

// Parameters:
//  Cancel - Boolean - Cancel
//
Procedure CheckCompositionOfVendors(Cancel)

	If Not ModeMultipleVendors Then
		Return;
	EndIf;
	
	TablePresentation = NStr("vi = 'Nhà cung cấp';
							|ru = 'Поставщики';
							|en = 'Vendors'; fa = 'تأمین‌کنندگان';
							|it = 'Поставщики';
							|pl = 'Vendors';
							|tr = 'Tedarikçiler'");
	
	RebatesServer.CheckForValidLines(ThisObject, "Vendors", TablePresentation, Cancel);

EndProcedure

Procedure InitializeDocument()
	
	EmployeeResponsible = Users.CurrentUser();
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	
EndProcedure

// Parameters:
//  KindAttributes - See DocumentTypeData
//  Cancel - Boolean -
//  ToExecuteWithLock - Boolean -
//
Procedure CheckAccrualLimits(KindAttributes, Cancel, ToExecuteWithLock = False)
	
	SkipCheckingForAccrualRestrictionsIfThereAreNoChanges = CommonClientServer.StructureProperty(
		AdditionalProperties,
		"SkipCheckingForAccrualRestrictionsIfThereAreNoChanges",
		True);
	
	If SkipCheckingForAccrualRestrictionsIfThereAreNoChanges
	   And Posted Then
		
		DocumentChanges = TMCommonUse.DocumentChanges(ThisObject);
		If DocumentChanges.Count() = 0 Then
			Return;
		EndIf;
		
	EndIf;
	
	Result = DataToCheck();
	
	If Not ValueIsFilled(Result.DocumentChecks) Then
		Return;
	EndIf;
	
	DocumentChecks = Result.DocumentChecks;
	ModificationOfAgreedDocument = Result.ModificationOfAgreedDocument;
	OldValueSumPlan = Result.OldValueSumPlan;
	
	If ToExecuteWithLock Then
		
		Try
		
			Block = New DataLock;
			
			LockItem = Block.Add("AccumulationRegister.VendorRebates");
			LockItem.SetValue("TermDocument", DocumentChecks);
			
			LockItem.Mode = DataLockMode.Shared;
			Block.Lock();
			
		Except
			
			ErrorTemplate = NStr("vi = 'Không thể kiểm tra đã tính toán theo chứng từ điều kiện hay chưa theo nguyên nhân:
								|%1';
								|ru = 'Не удалось выполнить проверку на наличие уже введенных начислений по документу условий по причине:
								|%1';
								|en = 'Cannot check whether there are already entered accruals for the condition document due to:
								|%1'; fa = 'Cannot check whether there are already entered accruals for the condition document due to:
								|%1';
								|it = 'Не удалось выполнить проверку на наличие уже введенных начислений по документу условий по причине:
								|%1';
								|pl = 'Cannot check whether there are already entered accruals for the condition document due to:
								|%1';
								|tr = 'Şartlar belgesinde önceden girilmiş olan tahakkuklar, şu sebeple kontrol edilemedi:
								|%1'");
			ErrorDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo());
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				ErrorTemplate, 
				ErrorDescription);
			
			Raise ErrorText;
			
		EndTry;
	
	EndIf;
	
	MaxDate = RebatesServer.LimitOfSupplierCharges(DocumentChecks);
	
	If MaxDate <> Date(1, 1, 1) Then
		
		If ModificationOfAgreedDocument Then
			
			MessageText = NStr("vi = 'Không thể chỉnh sửa khi đã ghi nhận tính thưởng lũy kế.';
								|ru = 'Зарегистрировано начисление ретро-бонусов, ввод исправлений невозможен.';
								|en = 'Rebate accrual is registered. Cannot register the corrections.'; fa = 'Rebate accrual is registered. Cannot register the corrections.';
								|it = 'Зарегистрировано начисление ретро-бонусов, ввод исправлений невозможен.';
								|pl = 'Rebate accrual is registered. Cannot register the corrections.';
								|tr = 'Retro bonusu tahakkuku kaydedildi, düzeltmeler girilemiyor.'");
			Common.MessageToUser(MessageText,,, "Object", Cancel);
			
		ElsIf AccrualFrequency = Enums.RebatesFrequencies.Single
		  Or BonusType = Enums.VendorRebateTypes.Balance Then
			
			MessageText = NStr("vi = 'Không thể chỉnh sửa khi đã ghi nhận tính thưởng lũy kế';
								|ru = 'Зарегистрировано начисление ретро-бонусов, ввод исправлений невозможен';
								|en = 'Rebate accrual is registered. Cannot register the corrections'; fa = 'Rebate accrual is registered. Cannot register the corrections';
								|it = 'Зарегистрировано начисление ретро-бонусов, ввод исправлений невозможен';
								|pl = 'Rebate accrual is registered. Cannot register the corrections';
								|tr = 'Retro bonusu tahakkuku kaydedildi, düzeltmeler girilemiyor'");
			Common.MessageToUser(MessageText,,,, Cancel);
			
		Else
			
			If OldValueSumPlan <> SumPlan Then
				
				MessageText = NStr("vi = 'Đã cấm thay đổi số tiền dự tính khi đã ghi nhận tính thưởng lũy kế';
									|ru = 'Зарегистрировано начисление ретро-бонусов, изменение суммы плана запрещено';
									|en = 'Rebate accrual is registered. Changing the plan amount is prohibited'; fa = 'Rebate accrual is registered. Changing the plan amount is prohibited';
									|it = 'Зарегистрировано начисление ретро-бонусов, изменение суммы плана запрещено';
									|pl = 'Rebate accrual is registered. Changing the plan amount is prohibited';
									|tr = 'Retro bonusu tahakkuku kaydedildi, plan tutarının değiştirilmesi yasaktır'");
				Common.MessageToUser(MessageText,, "SumPlan", "Object", Cancel);
				
			EndIf;
			
			TargetValuesWithoutPeriod = New Array; // Array of EnumRef.TargetSalesIndicatorsOfRebatesByGoods
			TargetValuesWithoutPeriod.Add(Enums.TargetSalesIndicatorsOfRebatesByGoods.BatchOffer);
			TargetValuesWithoutPeriod.Add(Enums.TargetSalesIndicatorsOfRebatesByGoods.QuantityTotal);
			
			MaximumDateByLine = Format(MaxDate, "DLF=D;");
			CheckPeriodsInTables = True;
			
			If ValidTo < MaxDate Then
				
				Template = NStr("vi = 'Ngày hết hiệu lực không thể nhỏ hơn %1 - ngày cuối kỳ tính toán đã ghi nhận';
								|ru = 'Дата окончания действия не может быть меньше %1 - даты окончания периода зарегистрированного начисления';
								|en = 'The end date must be later than %1, the registered accrual period end date'; fa = 'The end date must be later than %1, the registered accrual period end date';
								|it = 'Дата окончания действия не может быть меньше %1 - даты окончания периода зарегистрированного начисления';
								|pl = 'The end date must be later than %1, the registered accrual period end date';
								|tr = 'Son kullanma tarihi ""%1"" değerinden az olamaz: Kayıtlı tahakkuk döneminin bitiş tarihi'");
				MessageText = StringFunctionsClientServer.SubstituteParametersToString(
					Template, MaximumDateByLine);
				Common.MessageToUser(MessageText,, "ValidTo", "Object", Cancel);
				CheckPeriodsInTables = False;
				
			EndIf;
			
			#Region VerificationOfParticipants
			NamePresentationOfTable = RebatesServer.NamePresentationOfTableByAttributesOfVendorConditions(
				KindAttributes.PartyList, FilterParties);
			
			If NamePresentationOfTable.TableName <> "" Then
				
				CheckParameters = RebatesServer.NewParametersForCheckingConditionsInTable();
				CheckParameters.Object = ThisObject;
				CheckParameters.TableName = NamePresentationOfTable.TableName;
				CheckParameters.TablePresentation = NamePresentationOfTable.TablePresentation;
				CheckParameters.ValidOnDate = ValidOnDate;
				CheckParameters.ValidTo = ValidTo;
				CheckParameters.MaxDate = MaxDate;
				CheckParameters.ListComposition = FilterParties;
				CheckParameters.CheckPeriodsInTables = CheckPeriodsInTables;
				
				RebatesServer.CheckChangesToConditionsInTable(CheckParameters, Cancel);
				
			EndIf;
			#EndRegion
			
			#Region CheckingItems
			NamePresentationOfTable = RebatesServer.NamePresentationOfTableByAttributesOfVendorConditions(
				KindAttributes.ContentOfGoods, FilterOfProducts_);
			
			If NamePresentationOfTable.TableName <> "" Then
				
				If TargetValuesWithoutPeriod.Find(KindAttributes.GoodsIndicator) = Undefined Then
					
					CheckParameters = RebatesServer.NewParametersForCheckingConditionsInTable();
					CheckParameters.Object = ThisObject;
					CheckParameters.TableName = NamePresentationOfTable.TableName;
					CheckParameters.TablePresentation = NamePresentationOfTable.TablePresentation;
					CheckParameters.ValidOnDate = ValidOnDate;
					CheckParameters.ValidTo = ValidTo;
					CheckParameters.MaxDate = MaxDate;
					CheckParameters.ListComposition = FilterOfProducts_;
					CheckParameters.CheckPeriodsInTables = CheckPeriodsInTables;
					
					RebatesServer.CheckChangesToConditionsInTable(CheckParameters, Cancel);
					
				Else
					
					RebatesServer.CheckChangesToConditionsInTableWithoutValidityPeriods(
						ThisObject,
						FilterOfProducts_,
						NamePresentationOfTable.TableName,
						NamePresentationOfTable.TablePresentation,
						Cancel);
					
				EndIf;
				
			EndIf;
			#EndRegion
			
			If BonusType = Enums.VendorRebateTypes.Purchases
			   And Vendors.Count() > 0 Then
				
				CheckParameters = RebatesServer.NewParametersForCheckingConditionsInTable();
				CheckParameters.Object = ThisObject;
				CheckParameters.TableName = "Vendors";
				CheckParameters.TablePresentation = NStr("vi = 'Nhà cung cấp';
														|ru = 'Поставщики';
														|en = 'Vendors'; fa = 'تأمین‌کنندگان';
														|it = 'Поставщики';
														|pl = 'Vendors';
														|tr = 'Tedarikçiler'");
				CheckParameters.ValidOnDate = ValidOnDate;
				CheckParameters.ValidTo = ValidTo;
				CheckParameters.MaxDate = MaxDate;
				CheckParameters.ListComposition = Enums.RebatesLists.Selected_;
				CheckParameters.CheckPeriodsInTables = CheckPeriodsInTables;
				
				RebatesServer.CheckChangesToConditionsInTable(CheckParameters, Cancel);
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Returns a document that needs to be checked and indicates that the agreed document has been modified.
// 
// Returns:
//  Structure - Verification data:
// * DocumentChecks - DocumentRef.ConditionsOfVendorRebates - 
// * ModificationOfAgreedDocument - Boolean
// * OldValueSumPlan- Number
// 
Function DataToCheck()
	
	Result = New Structure;
	Result.Insert("DocumentChecks", Documents.ConditionsOfVendorRebates.EmptyRef());
	Result.Insert("ModificationOfAgreedDocument", False);
	Result.Insert("OldValueSumPlan", 0);
	
	If Not CorrectedDocument.IsEmpty() Then
		
		Result.DocumentChecks = CorrectedDocument;
		Result.OldValueSumPlan = Common.ObjectAttributeValue(ReversedDocument, "SumPlan");;
		
	Else
		
		If Not Ref.IsEmpty() Then
			
			StatusOfLink = Common.ObjectAttributeValue(Ref, "Status");
			
			If StatusOfLink = Enums.RebatesDocumentStatuses.Approved Then
				
				Result.DocumentChecks = Ref;
				Result.ModificationOfAgreedDocument = True;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

Procedure AdjustmentOfVendorDataAndInputModeByDataComposition()
	
	If ModeMultipleVendors Then
		
		SwitchingIsAllowed = ModeSwitchingIsAllowed();
		
		If SwitchingIsAllowed Then
			
			ModeMultipleVendors = False;
			
			If Vendors.Count() = 1 Then
				
				VendorString = Vendors[0];
				Counterparty = VendorString.Counterparty;
				Partner = VendorString.Partner;
				Contract = VendorString.Contract;
				Terms = VendorString.Terms;
				
				Vendors.Clear();
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	If ModeMultipleVendors Then
		
		Counterparty = Catalogs.Counterparties.EmptyRef();
		Partner = Catalogs.Partners.EmptyRef();
		Contract = Catalogs.CounterpartyContracts.EmptyRef();
		Terms = Catalogs.TermsOfPurchaseFromVendors.EmptyRef();
		
	EndIf;
	
EndProcedure

Function ModeSwitchingIsAllowed()
	
	If Vendors.Count() = 0 Then
		
		SwitchingIsAllowed = True;
		
	ElsIf Vendors.Count() > 1 Then
		
		SwitchingIsAllowed = False;
		
	Else
		
		DateEmpty = Date(1, 1, 1);
		VendorString = Vendors[0];
		
		If VendorString.ValidOnDate = DateEmpty Then
			CurrentStartDate = ValidOnDate
		Else
			CurrentStartDate = VendorString.ValidOnDate;
		EndIf;
			
		If VendorString.ValidTo = DateEmpty Then
			CurrentEndDate = ValidTo;
		Else
			CurrentEndDate = VendorString.ValidTo;
		EndIf;
		
		SwitchingIsAllowed = (CurrentStartDate = ValidOnDate
			And CurrentEndDate = ValidTo);
		
	EndIf;
	
	Return SwitchingIsAllowed;
	
EndFunction

#EndRegion

#EndIf