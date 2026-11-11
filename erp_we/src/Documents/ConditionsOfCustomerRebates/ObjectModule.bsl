//@strict-types

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	FillInDataType = TypeOf(FillingData);
	
	If FillInDataType = Type("DocumentRef.ConditionsOfCustomerRebates") Then
		
		DocumentReference = FillingData; // DocumentRef.ConditionsOfCustomerRebates
		FillInAccordingToConditionOfCustomerRebates(DocumentReference);
		
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
		
		NotCheckedAttributeArray.Add("Counterparties");
		NotCheckedAttributeArray.Add("CounterpartiesTIN");
		NotCheckedAttributeArray.Add("PartnersSegments");
		NotCheckedAttributeArray.Add("Goods");
		NotCheckedAttributeArray.Add("ProductProperties_");
		NotCheckedAttributeArray.Add("GoodsSegments");
		NotCheckedAttributeArray.Add("ContractsTermsOfSales");
		
	Else
		
		If FilterParties = Enums.RebatesLists.All Then
			
			NotCheckedAttributeArray.Add("Counterparties");
			NotCheckedAttributeArray.Add("CounterpartiesTIN");
			NotCheckedAttributeArray.Add("PartnersSegments");
			NotCheckedAttributeArray.Add("ContractsTermsOfSales");
			
		EndIf;
		
		If FilterOfProducts_ = Enums.RebatesLists.All Then
			
			NotCheckedAttributeArray.Add("Goods");
			NotCheckedAttributeArray.Add("ProductProperties_");
			NotCheckedAttributeArray.Add("GoodsSegments");
			
		EndIf;
		
		KindAttributes = DocumentTypeData();
		
		ProhibitionOfExceedingAmount =
			(KindAttributes.GoodsIndicator = Enums.TargetSalesIndicatorsOfRebatesByGoods.Sum
			 And RestrictAccrualOverPlan);
		CalculationByScale =
			(KindAttributes.GoodsIndicator = Enums.TargetSalesIndicatorsOfRebatesByGoods.Sum
		     And CalculationScaleType <> 0); // Not the only value
		
		If Not CalculationByScale Then
			NotCheckedAttributeArray.Add("CalculationScales");
		EndIf;
		
		#Region BonusPercent
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
		
		If WithoutCalculation Then
			
			NotCheckedAttributeArray.Add("FilterOfProducts_");
			NotCheckedAttributeArray.Add("Goods");
			NotCheckedAttributeArray.Add("ProductProperties_");
			NotCheckedAttributeArray.Add("PartnersSegments");
			NotCheckedAttributeArray.Add("GoodsSegments");
			NotCheckedAttributeArray.Add("ConditionFrequency");
			
		Else
			
			NotCheckedAttributeArray.Add("Counterparties.AmountBonus");
			
		EndIf;
		
		If KindAttributes.GoodsIndicator = Enums.TargetSalesIndicatorsOfRebatesByGoods.NotUsed Then
			
			NotCheckedAttributeArray.Add("ConditionFrequency");
			
		EndIf;
		
		// If the indicator is not a sum, or a sum, but not by a single value
		If KindAttributes.GoodsIndicator <> Enums.TargetSalesIndicatorsOfRebatesByGoods.Sum
		 Or (KindAttributes.GoodsIndicator = Enums.TargetSalesIndicatorsOfRebatesByGoods.Sum
		      And RebateKind <> 0) Then
			
			NotCheckedAttributeArray.Add("SumPlan");
			
		EndIf;
		
		If Not WithoutCalculation
		   And KindAttributes.SalesCalculationBase = Enums.RebateCalculationBases.RevenueARAPAccounting Then
			
			NotCheckedAttributeArray.Add("Currency");
			
		EndIf;
		
		CheckNumberOfParticipantsCounterparties(KindAttributes, NotCheckedAttributeArray, Cancel);
		CheckListOfParticipantsPartners(KindAttributes, NotCheckedAttributeArray, Cancel);
		CheckTINByCompositionOfParticipants(KindAttributes, NotCheckedAttributeArray, Cancel);
		CheckPartnerSegmentsByMembership(KindAttributes, NotCheckedAttributeArray, Cancel);
		CheckByCompositionOfContractParticipants(KindAttributes, NotCheckedAttributeArray, Cancel);
		CheckCompositionOfPartiesToAgreement(KindAttributes, NotCheckedAttributeArray, Cancel);
		
		CheckCompositionOfGoodsItem(KindAttributes, NotCheckedAttributeArray, Cancel);
		CheckPropertiesOfItemByCompositionOfItems(KindAttributes, NotCheckedAttributeArray, Cancel);
		CheckItemSegmentsByCompositionOfGoods(KindAttributes, NotCheckedAttributeArray, Cancel);
		
		RebatesServer.CheckCalculationScales(CalculationScales, CalculationScaleType, KindAttributes, Cancel);
		CheckAccrualLimits(KindAttributes, Cancel);
		
	EndIf;
	
	DocumentCorrection.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
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
		
		Allowed1Update = Documents.ConditionsOfCustomerRebates.ChangeByStatusIsAllowed(Status);
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
		
		CalculationOnProgressiveScale =
			(KindAttributes.GoodsIndicator = Enums.TargetSalesIndicatorsOfRebatesByGoods.Sum
			 And CalculationScaleType = 1);
		CalculationByRanges =
			(KindAttributes.GoodsIndicator = Enums.TargetSalesIndicatorsOfRebatesByGoods.Sum
			 And CalculationScaleType = 2);
		
		If WithoutCalculation
		 Or CalculationByRanges
		 Or (KindAttributes.GoodsIndicator <> Enums.TargetSalesIndicatorsOfRebatesByGoods.Count
			  And KindAttributes.GoodsIndicator <> Enums.TargetSalesIndicatorsOfRebatesByGoods.Sum) Then
			
			RestrictAccrualOverPlan = False;
			
		EndIf;
		
		If KindAttributes.GoodsIndicator <> Enums.TargetSalesIndicatorsOfRebatesByGoods.Sum
		 Or (KindAttributes.GoodsIndicator = Enums.TargetSalesIndicatorsOfRebatesByGoods.Sum
		      And CalculationScaleType <> 0) // Not by a single value
		 Or WithoutCalculation Then
			
			SumPlan = 0;
			
		EndIf;
		
		ProhibitionOfExceedingAmount =
			(KindAttributes.GoodsIndicator = Enums.TargetSalesIndicatorsOfRebatesByGoods.Sum
			 And RestrictAccrualOverPlan);
		
		If WithoutCalculation
		 Or CalculationOnProgressiveScale
		 Or CalculationByRanges
		 Or (FilterOfProducts_ = Enums.RebatesLists.Selected_
			  And KindAttributes.ContentOfGoods <> Enums.RebatesItems.ProductSegments
			  And Not ProhibitionOfExceedingAmount) Then
			
			BonusPercent = 0;
			
		EndIf;
		
		If KindAttributes.GoodsIndicator <> Enums.TargetSalesIndicatorsOfRebatesByGoods.Sum Then
			
			CalculationScales.Clear();
			
		EndIf;
		
		ParametersOfParticipants = Documents.ConditionsOfCustomerRebates.ParametersForClearingParticipantsAttributes();
		ParametersOfParticipants.PartyList = KindAttributes.PartyList;
		ParametersOfParticipants.FilterParties = FilterParties;
		ParametersOfParticipants.GoodsIndicator = KindAttributes.GoodsIndicator;
		Documents.ConditionsOfCustomerRebates.ClearUnusedDetailsOfParticipants(
			ThisObject, ParametersOfParticipants);
		Documents.ConditionsOfCustomerRebates.EstablishSignsOfCalculationOfParticipantsPlan(
			ThisObject, ParametersOfParticipants);
		
		GoodsParameters = Documents.ConditionsOfCustomerRebates.ParametersForClearingGoodsAttributes();
		GoodsParameters.ContentOfGoods = KindAttributes.ContentOfGoods;
		GoodsParameters.FilterOfProducts_ = FilterOfProducts_;
		GoodsParameters.GoodsIndicator = KindAttributes.GoodsIndicator;
		GoodsParameters.BaseOfCalculation = KindAttributes.SalesCalculationBase;
		Documents.ConditionsOfCustomerRebates.ClearUnusedGoodsDetails(ThisObject, GoodsParameters);
		
	EndIf;
	
	If Patch Then
		
		TermsAndConditionsAttributes = Documents.ConditionsOfCustomerRebates.UpToDateData(CorrectedDocument);
		If TermsAndConditionsAttributes.RecordingIsCompleted
		   And Allowed1Update Then
			
			NotificationText2 = NStr("vi = 'Đã ấn định thành phần chứng từ, không thể nhập chỉnh sửa';
									|ru = 'Состав документа зафиксирован, ввод исправлений невозможен';
									|en = 'The document content is recorded. Cannot register the corrections'; fa = 'The document content is recorded. Cannot register the corrections';
									|it = 'The document content is recorded. Cannot register the corrections';
									|pl = 'The document content is recorded. Cannot register the corrections';
									|tr = 'Belge içeriği sabitlendi, düzeltme yapmak mümkün değildir'");
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
	NamesOfFieldsToBeCleared.Add("AmountPlanBeforeChange");
	NamesOfFieldsToBeCleared.Add("PlanIsNotSpecifiedBeforeChange");
	NamesOfFieldsToBeCleared.Add("StartDateBeforeChange");
	NamesOfFieldsToBeCleared.Add("EndDateBeforeChange");
	RebatesServer.InitializeListToBeCopied(ThisObject, "Counterparties", NamesOfFieldsToBeCleared);
	
	NamesOfFieldsToBeCleared = New Array; // Array of String
	NamesOfFieldsToBeCleared.Add("AmountPlanBeforeChange");
	NamesOfFieldsToBeCleared.Add("StartDateBeforeChange");
	NamesOfFieldsToBeCleared.Add("EndDateBeforeChange");
	RebatesServer.InitializeListToBeCopied(ThisObject, "CounterpartiesTIN", NamesOfFieldsToBeCleared);
	
	RebatesServer.InitializeListToBeCopied(ThisObject, "PartnersSegments");
	
	NamesOfFieldsToBeCleared = New Array; // Array of String
	NamesOfFieldsToBeCleared.Add("AmountPlanBeforeChange");
	NamesOfFieldsToBeCleared.Add("StartDateBeforeChange");
	NamesOfFieldsToBeCleared.Add("EndDateBeforeChange");
	RebatesServer.InitializeListToBeCopied(ThisObject, "ContractsTermsOfSales");
	
	NamesOfFieldsToBeCleared = New Array; // Array of String
	NamesOfFieldsToBeCleared.Add("StartDateBeforeChange");
	NamesOfFieldsToBeCleared.Add("EndDateBeforeChange");
	RebatesServer.InitializeListToBeCopied(ThisObject, "Goods", NamesOfFieldsToBeCleared);
	
	NamesOfFieldsToBeCleared = New Array; // Array of String
	NamesOfFieldsToBeCleared.Add("StartDateBeforeChange");
	NamesOfFieldsToBeCleared.Add("EndDateBeforeChange");
	RebatesServer.InitializeListToBeCopied(ThisObject, "ProductProperties_", NamesOfFieldsToBeCleared);
	
	RebatesServer.InitializeListToBeCopied(ThisObject, "GoodsSegments");
	
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
//	* PartyCountDetails - EnumRef.ARAPAccountingDrilldownsOfRebatesParticipants
//	* FilterOfProducts_ - EnumRef.RebatesLists
//	* FilterParties - EnumRef.RebatesLists
//	* GoodsIndicator - EnumRef.TargetSalesIndicatorsOfRebatesByGoods
//	* SalesCalculationBase - EnumRef.RebateCalculationBases
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
	AttributesArray.Add("PartyCountDetails");
	AttributesArray.Add("FilterOfProducts_");
	AttributesArray.Add("FilterParties");
	AttributesArray.Add("WithoutCalculation");
	AttributesArray.Add("GoodsIndicator");
	AttributesArray.Add("SalesCalculationBase");
	AttributesArray.Add("ContentOfGoods");
	AttributesArray.Add("PartyList");
	AttributesArray.Add("ProductItemProperty");
	KindAttributes = Common.ObjectAttributesValues(RebateKind, AttributesArray);
	
	Return KindAttributes;
	
EndFunction

// Fill in according to the condition of retro customer bonuses.
// 
// Parameters:
//  FillingData - DocumentRef.ConditionsOfCustomerRebates - fill-in data
//
Procedure FillInAccordingToConditionOfCustomerRebates(FillingData)
	
	FillingDocument = FillingData; // DocumentRef.ConditionsOfCustomerRebates
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
		
		LastFixLink = LastFix.Ref; // DocumentRef.ConditionsOfCustomerRebates
		
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
	
	If AccrualFrequency = Enums.RebatesFrequencies.Single Then
		
		MaxDate = RebatesServer.LimitOfAccrualsOfClients(CorrectedDocument);
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
	
	TermsAndConditionsAttributes = Documents.ConditionsOfCustomerRebates.UpToDateData(CorrectedDocument);
	If TermsAndConditionsAttributes.RecordingIsCompleted Then
		
		NotificationText2 = NStr("vi = 'Đã ấn định thành phần chứng từ, không thể nhập chỉnh sửa';
								|ru = 'Состав документа зафиксирован, ввод исправлений невозможен';
								|en = 'The document content is recorded. Cannot register the corrections'; fa = 'The document content is recorded. Cannot register the corrections';
								|it = 'The document content is recorded. Cannot register the corrections';
								|pl = 'The document content is recorded. Cannot register the corrections';
								|tr = 'Belge içeriği sabitlendi, düzeltme yapmak mümkün değildir'");
		Raise NotificationText2;
		
	EndIf;
	
	Status = Enums.RebatesDocumentStatuses.Draft;
	
	ShouldDetailCalculation = Enums.ARAPAccountingDrilldownsOfRebatesParticipants;
	
	DetailsCounterpartyCompositionClient =
		(PartyCountDetails = ShouldDetailCalculation.ByCounterparty
		 And DetailsOfFoundation.PartyList = Enums.RebatesParticipants.Customers);
	
	DetailsClientCompositionCounterparty =
		(PartyCountDetails = ShouldDetailCalculation.ByCustomer
		 And DetailsOfFoundation.PartyList = Enums.RebatesParticipants.Counterparties);
	
	PlanIsSpecified = Not (FilterParties = Enums.RebatesLists.Selected_
						  And (DetailsCounterpartyCompositionClient
							 Or DetailsClientCompositionCounterparty));
	
	FillingOutPlan = (FilterParties <> Enums.RebatesLists.ExceptForSelectedOnes
					 And PlanIsSpecified);
	
	#Region TS_Counterparties
	LinesToDelete = New Array; // Array of DocumentTabularSectionRow.ConditionsOfCustomerRebates.Counterparties
	
	For Each TSRow In Counterparties Do
		
		If TSRow.Canceled Then
			
			LinesToDelete.Add(TSRow);
			Continue;
			
		EndIf;
		
		TSRow.InitialString = True;
		TSRow.PlanIsNotSpecifiedBeforeChange = TSRow.PlanIsNotSpecified;
		If FillingOutPlan Then
			
			If TSRow.SumPlan = 0 Then
				
				TSRow.AmountPlanBeforeChange = DetailsOfFoundation.SumPlan;
				
			Else
				
				TSRow.AmountPlanBeforeChange = TSRow.SumPlan;
				
			EndIf;
			
		EndIf;
		
		If FilterParties = Enums.RebatesLists.Selected_ Then
			
			FillInPeriodDataBasedOn(TSRow, DetailsOfFoundation);
			
		EndIf;
		
	EndDo;
	
	For Each RowToDelete In LinesToDelete Do
		
		Counterparties.Delete(RowToDelete);
		
	EndDo;
	#EndRegion
	
	#Region TS_CounterpartiesTIN
	LinesToDelete = New Array; // Array of DocumentTabularSectionRow.ConditionsOfCustomerRebates.CounterpartiesTIN
	
	For Each TSRow In CounterpartiesTIN Do
		
		If TSRow.Canceled Then
			
			LinesToDelete.Add(TSRow);
			Continue;
			
		EndIf;
		
		TSRow.InitialString = True;
		If FillingOutPlan Then
			
			If TSRow.SumPlan = 0 Then
				
				TSRow.AmountPlanBeforeChange = DetailsOfFoundation.SumPlan;
				
			Else
				
				TSRow.AmountPlanBeforeChange = TSRow.SumPlan;
				
			EndIf;
			
		EndIf;
		
		If FilterParties = Enums.RebatesLists.Selected_ Then
			
			FillInPeriodDataBasedOn(TSRow, DetailsOfFoundation);
			
		EndIf;
		
	EndDo;
	
	For Each RowToDelete In LinesToDelete Do
		
		CounterpartiesTIN.Delete(RowToDelete);
		
	EndDo;
	#EndRegion

	#Region PM_ContractAgreements
	LinesToDelete = New Array; // Array of DocumentTabularSectionRow.ConditionsOfCustomerRebates.ContractsTermsOfSales
	
	For Each TSRow In ContractsTermsOfSales Do
		
		If TSRow.Canceled Then
			
			LinesToDelete.Add(TSRow);
			Continue;
			
		EndIf;
		
		TSRow.InitialString = True;
		If FillingOutPlan Then
			
			If TSRow.SumPlan = 0 Then
				
				TSRow.AmountPlanBeforeChange = DetailsOfFoundation.SumPlan;
				
			Else
				
				TSRow.AmountPlanBeforeChange = TSRow.SumPlan;
				
			EndIf;
			
		EndIf;
		
		FillInPeriodDataBasedOn(TSRow, DetailsOfFoundation);
		
	EndDo;
	
	For Each RowToDelete In LinesToDelete Do
		
		ContractsTermsOfSales.Delete(RowToDelete);
		
	EndDo;
	#EndRegion
	
	#Region TS_Goods
	LinesToDelete = New Array; // Array of DocumentTabularSectionRow.ConditionsOfCustomerRebates.Goods
	
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
	LinesToDelete = New Array; // Array of DocumentTabularSectionRow.ConditionsOfCustomerRebates.ProductProperties_
	
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
	
	#Region TS_PartnersSegments
	LinesToDelete = New Array; // Array of DocumentTabularSectionRow.ConditionsOfCustomerRebates.PartnersSegments
	
	For Each TSRow In PartnersSegments Do
		
		If TSRow.Canceled Then
			
			LinesToDelete.Add(TSRow);
			Continue;
			
		EndIf;
		
		TSRow.InitialString = True;
		
	EndDo;
	
	For Each RowToDelete In LinesToDelete Do
		
		PartnersSegments.Delete(RowToDelete);
		
	EndDo;
	#EndRegion
	
	#Region PM_GoodsSegments
	LinesToDelete = New Array; // Array of DocumentTabularSectionRow.ConditionsOfCustomerRebates.GoodsSegments
	
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
	 Or FilterParties = Enums.RebatesLists.All Then
		Return;
	EndIf;
	
	If FilterParties = Enums.RebatesLists.Selected_ Then
		
		TablePresentation = NStr("vi = 'Đối tác được chọn';
								|ru = 'Выбранные контрагенты';
								|en = 'Selected counterparties'; fa = 'Selected counterparties';
								|it = 'Выбранные контрагенты';
								|pl = 'Selected counterparties';
								|tr = 'Seçili cari hesaplar'");
		RebatesServer.CheckTablePeriods(ThisObject, "Counterparties", TablePresentation, Cancel);
		
	Else
		
		If FilterParties = Enums.RebatesLists.ExceptForSelectedOnes Then
			
			TablePresentation = NStr("vi = 'Ngoại trừ đối tác';
									|ru = 'Кроме контрагентов';
									|en = 'Except for counterparties'; fa = 'Except for counterparties';
									|it = 'Кроме контрагентов';
									|pl = 'Except for counterparties';
									|tr = 'Cari hesaplar hariç'");
			
			CheckIndicationOfEmptyParticipantValues(True, Cancel, TablePresentation);
			
		EndIf;
		
	EndIf;
	
	RowFilter = New Structure;
	RowFilter.Insert("Canceled", False);
	RebatesServer.CheckForDuplicatesOfTSStrings(
		ThisObject, "Counterparties", "Counterparty,Partner", Cancel, TablePresentation,, RowFilter);
	
	RebatesServer.CheckForValidLines(ThisObject, "Counterparties", TablePresentation, Cancel);
	
	If Not AccrueImmediately Then
		NotCheckedAttributeArray.Add("Counterparties.Partner");
	EndIf;
	NotCheckedAttributeArray.Add("CounterpartiesTIN");
	NotCheckedAttributeArray.Add("PartnersSegments");
	NotCheckedAttributeArray.Add("ContractsTermsOfSales");
	
EndProcedure

// Parameters:
//  KindAttributes - See DocumentTypeData
//  NotCheckedAttributeArray - Array of String- Array of unverifiable Attributes
//  Cancel - Boolean - Cancel
//
Procedure CheckListOfParticipantsPartners(KindAttributes, NotCheckedAttributeArray, Cancel)
	
	If KindAttributes.PartyList <> Enums.RebatesParticipants.Customers
	 Or FilterParties = Enums.RebatesLists.All Then
		Return;
	EndIf;
	
	PlanAccordingToScale = (KindAttributes.GoodsIndicator = Enums.TargetSalesIndicatorsOfRebatesByGoods.Sum
				   And CalculationScaleType <> 0); // Not the only value
	
	If FilterParties = Enums.RebatesLists.Selected_ Then
		
		TablePresentation = NStr("vi = 'Khách hàng được chọn';
								|ru = 'Выбранные клиенты';
								|en = 'Selected customers'; fa = 'Selected customers';
								|it = 'Выбранные клиенты';
								|pl = 'Selected customers';
								|tr = 'Seçili müşteriler'");
		RebatesServer.CheckTablePeriods(ThisObject, "Counterparties", TablePresentation, Cancel);
		
	Else
		
		If FilterParties = Enums.RebatesLists.ExceptForSelectedOnes Then
			
			TablePresentation = NStr("vi = 'Ngoại trừ khách hàng';
									|ru = 'Кроме клиентов';
									|en = 'Except for customers'; fa = 'Except for customers';
									|it = 'Кроме клиентов';
									|pl = 'Except for customers';
									|tr = 'Müşteriler hariç'");
			
			CheckIndicationOfEmptyParticipantValues(False, Cancel, TablePresentation);
			
		EndIf;
		
	EndIf;
	
	RowFilter = New Structure;
	RowFilter.Insert("Canceled", False);
	RebatesServer.CheckForDuplicatesOfTSStrings(
		ThisObject, "Counterparties", "Partner,Counterparty", Cancel, TablePresentation,, RowFilter);
	
	RebatesServer.CheckForValidLines(ThisObject, "Counterparties", TablePresentation, Cancel);
	
	If Not AccrueImmediately Then
		NotCheckedAttributeArray.Add("Counterparties.Counterparty");
	EndIf;
	
	If PlanAccordingToScale Then
		NotCheckedAttributeArray.Add("Counterparties.SumPlan");
	EndIf;
	
	NotCheckedAttributeArray.Add("CounterpartiesTIN");
	NotCheckedAttributeArray.Add("PartnersSegments");
	NotCheckedAttributeArray.Add("ContractsTermsOfSales");
	
EndProcedure

Procedure CheckIndicationOfEmptyParticipantValues(PartnerVerification, Cancel, TablePresentation)
	
	If PartnerVerification Then
		
		KeyField = "Counterparty";
		PresentationOfKeyField = NStr("vi = 'Đối tác';
										|ru = 'Контрагент';
										|en = 'Counterparty'; fa = 'طرف حساب';
										|it = 'Контрагент';
										|pl = 'Kontrahent';
										|tr = 'Cari hesap'");
		AuxiliaryField = "Partner";
		PresentationOfAuxiliaryField = NStr("vi = 'Khách hàng';
											|ru = 'Клиент';
											|en = 'Customer'; fa = 'مشتری';
											|it = 'Клиент';
											|pl = 'Klient';
											|tr = 'Müşteri'");
		EmptyAuxiliaryField = Catalogs.Partners.EmptyRef(); // CatalogRef.Partners, CatalogRef.Counterparties
		
	Else
		
		KeyField = "Partner";
		PresentationOfKeyField = NStr("vi = 'Khách hàng';
										|ru = 'Клиент';
										|en = 'Customer'; fa = 'مشتری';
										|it = 'Клиент';
										|pl = 'Klient';
										|tr = 'Müşteri'");
		AuxiliaryField = "Counterparty";
		PresentationOfAuxiliaryField = NStr("vi = 'Đối tác';
											|ru = 'Контрагент';
											|en = 'Counterparty'; fa = 'طرف حساب';
											|it = 'Контрагент';
											|pl = 'Kontrahent';
											|tr = 'Cari hesap'");
		EmptyAuxiliaryField = Catalogs.Counterparties.EmptyRef();
		
	EndIf;
	
	Selection = SamplingOfEmptyAndFilledParticipants(KeyField, AuxiliaryField, EmptyAuxiliaryField);
	
	If FilterParties = Enums.RebatesLists.ExceptForSelectedOnes Then
		
		MessageTemplate = NStr("vi = 'Trong danh sách ""%1"" theo trường chính ""%2"" (%3) tại các dòng khác nhau đã chỉ định và không chỉ định đồng thời giá trị tạ trường ""%4""';
								|ru = 'В списке ""%1"" по ключевому полю ""%2"" (%3) в разных строках одновременно указано и не указано значение в поле ""%4""';
								|en = 'In the ""%1"" list, for the key ""%2"" (%3) field, the value in the ""%4"" field is specified and not specified in different lines at the same time'; fa = 'In the ""%1"" list, for the key ""%2"" (%3) field, the value in the ""%4"" field is specified and not specified in different lines at the same time';
								|it = 'В списке ""%1"" по ключевому полю ""%2"" (%3) в разных строках одновременно указано и не указано значение в поле ""%4""';
								|pl = 'In the ""%1"" list, for the key ""%2"" (%3) field, the value in the ""%4"" field is specified and not specified in different lines at the same time';
								|tr = 'Farklı satırlardaki ""%2"" (%3) anahtar alanı için, ""%1"" listesinde ve ""%4"" alanındaki değerler, farklı satırlarda eş zamanlı belirtilmiş ve belirtilmemiş'");
		
	Else
		
		MessageTemplate = NStr("vi = 'Trong danh sách ""%1"" theo trường chính ""%2"" (%3) tại các dòng khác nhau đối với trường ""%4"" giá trị đồng thời không được chỉ định và được chỉ định';
								|ru = 'В списке ""%1"" по ключевому полю ""%2"" (%3) в разных строках для поля ""%4"" одновременно не указано значение и указано';
								|en = 'In the ""%1"" list by the ""%2"" key field (%3), a value is simultaneously specified and not specified in different lines for the ""%4"" field'; fa = 'In the ""%1"" list by the ""%2"" key field (%3), a value is simultaneously specified and not specified in different lines for the ""%4"" field';
								|it = 'В списке ""%1"" по ключевому полю ""%2"" (%3) в разных строках для поля ""%4"" одновременно не указано значение и указано';
								|pl = 'In the ""%1"" list by the ""%2"" key field (%3), a value is simultaneously specified and not specified in different lines for the ""%4"" field';
								|tr = 'Farklı satırlardaki ""%2"" (%3) anahtar alanı için, ""%1"" listesinde ve ""%4"" alanındaki için eş zamanlı belirtilmiş veya belirtilmemiş'");
		
	EndIf;
	
	While Selection.Next() Do
		
		Field = CommonClientServer.PathToTabularSection(
			"Counterparties", Selection.LineNumber, "LineNumber");
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			MessageTemplate,
			TablePresentation,
			PresentationOfKeyField,
			String(Selection.KeyField),
			PresentationOfAuxiliaryField);
		Common.MessageToUser(ErrorText, ThisObject, Field,, Cancel);
		
	EndDo;
	
EndProcedure

// Parameters:
//  KeyField - String - Key Field
//  AuxiliaryField - String - Auxiliary Field
//  EmptyAuxiliaryField - CatalogRef.Counterparties, CatalogRef.Partners - An empty link of the type
// 
// Returns:
//  QueryResultSelection:
//	* LineNumber - Number -
//	* KeyField - CatalogRef.Partners, CatalogRef.Counterparties -
//
Function SamplingOfEmptyAndFilledParticipants(KeyField, AuxiliaryField, EmptyAuxiliaryField)
	
	Query = New Query;
	QueryText =
	"SELECT
	|	CheckTable.LineNumber AS LineNumber,
	|	CheckTable.Partner AS Partner,
	|	CheckTable.Counterparty AS Counterparty
	|INTO CheckTable
	|FROM
	|	&CheckTable AS CheckTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MIN(CheckTable.LineNumber) AS LineNumber,
	|	&KeyField AS KeyField
	|FROM
	|	CheckTable AS CheckTable
	|
	|GROUP BY
	|	&KeyField
	|
	|HAVING
	|	COUNT(DISTINCT CASE
	|		WHEN &AuxiliaryField = &EmptyAuxiliaryField
	|			THEN 0
	|		ELSE 1
	|	END) > 1";
	
	QueryText = StrReplace(QueryText, "&KeyField", KeyField);
	QueryText = StrReplace(QueryText, "&AuxiliaryField", AuxiliaryField);
	Query.Text = QueryText;
	
	Query.SetParameter("EmptyAuxiliaryField", EmptyAuxiliaryField);
	
	RowFilter = New Structure;
	RowFilter.Insert("Canceled", False);
	CheckTable = Counterparties.Unload(RowFilter, "LineNumber, Counterparty, Partner");
	Query.SetParameter("CheckTable", CheckTable);
	
	Selection = Query.Execute().Select();
	Return Selection;
	
EndFunction

// Parameters:
//  KindAttributes - See DocumentTypeData
//  NotCheckedAttributeArray - Array of String- Array of unverifiable Attributes
//  Cancel - Boolean - Cancel
//
Procedure CheckTINByCompositionOfParticipants(KindAttributes, NotCheckedAttributeArray, Cancel)
	
	If KindAttributes.PartyList <> Enums.RebatesParticipants.TIN
	 Or FilterParties = Enums.RebatesLists.All Then
		Return;
	EndIf;
	
	PlanAccordingToScale = (KindAttributes.GoodsIndicator = Enums.TargetSalesIndicatorsOfRebatesByGoods.Sum
				   And CalculationScaleType <> 0); // Not the only value
	TableName = "CounterpartiesTIN";
	TablePresentation = RebatesClientServer.PageTitleBySettings(
		KindAttributes.PartyList, FilterParties);
	If FilterParties = Enums.RebatesLists.Selected_ Then
		
		RebatesServer.CheckTablePeriods(ThisObject, TableName, TablePresentation, Cancel);
		
	EndIf;
	
	RowFilter = New Structure;
	RowFilter.Insert("Canceled", False);
	RebatesServer.CheckForDuplicatesOfTSStrings(
		ThisObject, TableName, "TIN", Cancel, TablePresentation,, RowFilter);
	
	RebatesServer.CheckForValidLines(ThisObject, TableName, TablePresentation, Cancel);
	
	RebatesServer.CheckFillingInINN(ThisObject, TableName, TablePresentation, Cancel);
	
	If PlanAccordingToScale Then
		NotCheckedAttributeArray.Add("Counterparties.SumPlan");
	EndIf;
	NotCheckedAttributeArray.Add("Counterparties");
	NotCheckedAttributeArray.Add("PartnersSegments");
	NotCheckedAttributeArray.Add("ContractsTermsOfSales");
			
EndProcedure

// Parameters:
//  KindAttributes - See DocumentTypeData
//  NotCheckedAttributeArray - Array of String- Array of unverifiable Attributes
//  Cancel - Boolean - Cancel
//
Procedure CheckPartnerSegmentsByMembership(KindAttributes, NotCheckedAttributeArray, Cancel)
	
	If KindAttributes.PartyList <> Enums.RebatesParticipants.PartnersSegments Then
		Return;
	EndIf;
	
	NotCheckedAttributeArray.Add("Counterparties");
	NotCheckedAttributeArray.Add("CounterpartiesTIN");
	NotCheckedAttributeArray.Add("ContractsTermsOfSales");
	
	If FilterParties = Enums.RebatesLists.ExceptForSelectedOnes Then
		
		TablePresentation = NStr("vi = 'Ngoại trừ phân khúc khách hàng';
								|ru = 'Кроме сегментов клиентов';
								|en = 'Except for customer segments'; fa = 'Except for customer segments';
								|it = 'Кроме сегментов клиентов';
								|pl = 'Except for customer segments';
								|tr = 'Müşteri segmentleri hariç'");
		
	Else
		
		TablePresentation = NStr("vi = 'Phân khúc khách hàng được chọn';
								|ru = 'Выбранные сегменты клиентов';
								|en = 'Selected customer segments'; fa = 'Selected customer segments';
								|it = 'Выбранные сегменты клиентов';
								|pl = 'Selected customer segments';
								|tr = 'Seçili müşteri segmentleri'");
		
	EndIf;
	
	RebatesServer.CheckForValidLines(ThisObject, "PartnersSegments", TablePresentation, Cancel);
	
	RowFilter = New Structure;
	RowFilter.Insert("Canceled", False);
	RebatesServer.CheckForDuplicatesOfTSStrings(
		ThisObject, "PartnersSegments", "Segment", Cancel, TablePresentation,, RowFilter);
	
EndProcedure

// Parameters:
//  KindAttributes - See DocumentTypeData
//  NotCheckedAttributeArray - Array of String- Array of unverifiable Attributes
//  Cancel - Boolean - Cancel
//
Procedure CheckByCompositionOfContractParticipants(KindAttributes, NotCheckedAttributeArray, Cancel)
	
	If KindAttributes.PartyList <> Enums.RebatesParticipants.Contracts Then
		Return;
	EndIf;
	
	NotCheckedAttributeArray.Add("Counterparties");
	NotCheckedAttributeArray.Add("CounterpartiesTIN");
	NotCheckedAttributeArray.Add("PartnersSegments");
	
	NotCheckedAttributeArray.Add("ContractsTermsOfSales.Terms");
	
	TablePresentation = NStr("vi = 'Hợp đồng đã chọn';
							|ru = 'Выбранные договоры';
							|en = 'Selected contracts'; fa = 'Selected contracts';
							|it = 'Выбранные договоры';
							|pl = 'Selected contracts';
							|tr = 'Seçili sözleşmeler'");
	RebatesServer.CheckForValidLines(ThisObject, "ContractsTermsOfSales", TablePresentation, Cancel);
	RebatesServer.CheckTablePeriods(ThisObject, "ContractsTermsOfSales", TablePresentation, Cancel);
	
	RowFilter = New Structure;
	RowFilter.Insert("Canceled", False);
	RebatesServer.CheckForDuplicatesOfTSStrings(
		ThisObject, "ContractsTermsOfSales", "Contract", Cancel, TablePresentation,, RowFilter);
	
EndProcedure

// Parameters:
//  KindAttributes - See DocumentTypeData
//  NotCheckedAttributeArray - Array of String- Array of unverifiable Attributes
//  Cancel - Boolean - Cancel
//
Procedure CheckCompositionOfPartiesToAgreement(KindAttributes, NotCheckedAttributeArray, Cancel)
	
	If KindAttributes.PartyList <> Enums.RebatesParticipants.Terms1 Then
		Return;
	EndIf;
	
	NotCheckedAttributeArray.Add("Counterparties");
	NotCheckedAttributeArray.Add("CounterpartiesTIN");
	NotCheckedAttributeArray.Add("PartnersSegments");
	
	NotCheckedAttributeArray.Add("ContractsTermsOfSales.Counterparty");
	NotCheckedAttributeArray.Add("ContractsTermsOfSales.Contract");
	
	TablePresentation = NStr("vi = 'Thỏa thuận đã chọn';
							|ru = 'Выбранные соглашения';
							|en = 'Selected terms of sales'; fa = 'Selected terms of sales';
							|it = 'Выбранные соглашения';
							|pl = 'Selected terms of sales';
							|tr = 'Seçili anlaşmalar'");
	RebatesServer.CheckForValidLines(ThisObject, "ContractsTermsOfSales", TablePresentation, Cancel);
	RebatesServer.CheckTablePeriods(ThisObject, "ContractsTermsOfSales", TablePresentation, Cancel);
	
	RowFilter = New Structure;
	RowFilter.Insert("Canceled", False);
	RebatesServer.CheckForDuplicatesOfTSStrings(
		ThisObject, "ContractsTermsOfSales", "Terms", Cancel, TablePresentation,, RowFilter);
	
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
	
	If FilterOfProducts_ = Enums.RebatesLists.Selected_ Then
		
		ConditionPeriodsAreFilledIn = (ValueIsFilled(ValidOnDate)
								   And ValueIsFilled(ValidTo));
		
		TablePresentation = NStr("vi = 'Hàng hóa được chọn';
								|ru = 'Выбранные товары';
								|en = 'Selected goods'; fa = 'کالای انتخاب‌شده';
								|it = 'Выбранные товары';
								|pl = 'Wybrane towary';
								|tr = 'Seçili ürünler'");
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
		
		TablePresentation = NStr("vi = 'Ngoại trừ mặt hàng';
								|ru = 'Кроме товаров';
								|en = 'Except for goods'; fa = 'Except for goods';
								|it = 'Кроме товаров';
								|pl = 'Except for goods';
								|tr = 'Ürünler hariç'");
		
		RowFilter = New Structure;
		RowFilter.Insert("Canceled", False);
		RebatesServer.CheckForDuplicatesOfTSStrings(
			ThisObject, "Goods", KeyFields, Cancel, TablePresentation,, RowFilter);
		
		NotCheckedAttributeArray.Add("Goods.ValidOnDate");
		NotCheckedAttributeArray.Add("Goods.ValidTo");
		
	EndIf;
	
	If KindAttributes.SalesCalculationBase <> Enums.RebateCalculationBases.RevenueBasePrices Then
		
		NotCheckedAttributeArray.Add("Goods.BasePrice");
		
	EndIf;
	
	If FilterOfProducts_ <> Enums.RebatesLists.Selected_
	 Or ThisIsNumberByRanges Then
		
		NotCheckedAttributeArray.Add("Goods.Percent");
		
	EndIf;
	
	If (KindAttributes.GoodsIndicator <> GoodsIndicators.Count
		  And KindAttributes.GoodsIndicator <> GoodsIndicators.QuantityTotal
		  And KindAttributes.GoodsIndicator <> GoodsIndicators.Count)
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
	
	RebatesServer.CheckForValidLines(ThisObject, "Goods", TablePresentation, Cancel);
	RebatesServer.CheckIndicationOfEmptyCharacteristicValues(ThisObject, TablePresentation, KindAttributes, Cancel);
	
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
	
	ResultOfCheckingProperty = RebatesServer.ItemPropertyVerificationData(KindAttributes.ProductItemProperty);
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
	
	If KindAttributes.SalesCalculationBase <> Enums.RebateCalculationBases.RevenueBasePrices Then
		
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
	
	If FilterOfProducts_ = Enums.RebatesLists.ExceptForSelectedOnes Then
		
		TablePresentation = NStr("vi = 'Ngoại trừ phân khúc mặt hàng';
								|ru = 'Кроме сегментов товаров';
								|en = 'Except for goods segments'; fa = 'Except for goods segments';
								|it = 'Кроме сегментов товаров';
								|pl = 'Except for goods segments';
								|tr = 'Ürün segmentleri hariç'");
		
	Else
		
		TablePresentation = NStr("vi = 'Phân khúc mặt hàng được chọn';
								|ru = 'Выбранные сегменты товаров';
								|en = 'Selected goods segments'; fa = 'Selected goods segments';
								|it = 'Выбранные сегменты товаров';
								|pl = 'Selected goods segments';
								|tr = 'Seçili ürün segmentleri'");
		
	EndIf;
	
	RowFilter = New Structure;
	RowFilter.Insert("Canceled", False);
	RebatesServer.CheckForDuplicatesOfTSStrings(
		ThisObject, "GoodsSegments", "Segment", Cancel, TablePresentation,, RowFilter);
	
	RebatesServer.CheckForValidLines(ThisObject, "GoodsSegments", TablePresentation, Cancel);
	
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
	
	If ToExecuteWithLock Then
		
		Try
			
			Block = New DataLock;
			
			LockItem = Block.Add("AccumulationRegister.CustomerRebates");
			LockItem.SetValue("TermDocument", DocumentChecks);
			
			LockItem.Mode = DataLockMode.Shared;
			Block.Lock();
			
		Except
			
			ErrorTemplate = NStr("vi = 'Không thể kiểm tra đã tính toán theo chứng từ điều kiện hay chưa theo nguyên nhân:
								|%1';
								|ru = 'Не удалось выполнить проверку на наличие уже введенных начислений по документу условий по причине:
								|%1';
								|en = 'Cannot check whether there are already entered accruals in the condition document due to:
								|%1'; fa = 'Cannot check whether there are already entered accruals in the condition document due to:
								|%1';
								|it = 'Не удалось выполнить проверку на наличие уже введенных начислений по документу условий по причине:
								|%1';
								|pl = 'Cannot check whether there are already entered accruals in the condition document due to:
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
	
	MaxDate = RebatesServer.LimitOfAccrualsOfClients(DocumentChecks);
	
	If MaxDate <> Date(1, 1, 1) Then
		
		If ModificationOfAgreedDocument Then
			
			MessageText = NStr("vi = 'Đã ghi nhận tính thưởng lũy kế. Cấm thay đổi chứng từ.';
								|ru = 'Зарегистрировано начисление ретро-бонусов. Изменение документа запрещено.';
								|en = 'Rebate accrual is registered. Cannot edit the document.'; fa = 'Rebate accrual is registered. Cannot edit the document.';
								|it = 'Зарегистрировано начисление ретро-бонусов. Изменение документа запрещено.';
								|pl = 'Rebate accrual is registered. Cannot edit the document.';
								|tr = 'Retro bonusu tahakkuku kaydedildi. Dosyada değişiklik yapmak yasaktır.'");
			Common.MessageToUser(MessageText,,, "Object", Cancel);
			
		ElsIf AccrualFrequency = Enums.RebatesFrequencies.Single Then
			
			MessageText = NStr("vi = 'Không thể chỉnh sửa khi đã ghi nhận tính thưởng lũy kế';
								|ru = 'Зарегистрировано начисление ретро-бонусов, ввод исправлений невозможен';
								|en = 'Rebate accrual is registered. Cannot save the corrections'; fa = 'Rebate accrual is registered. Cannot save the corrections';
								|it = 'Зарегистрировано начисление ретро-бонусов, ввод исправлений невозможен';
								|pl = 'Rebate accrual is registered. Cannot save the corrections';
								|tr = 'Retro bonusu tahakkuku kaydedildi, düzeltmeler girilemiyor'");
			Common.MessageToUser(MessageText,,,, Cancel);
			
		Else
			
			GoodsTargets = Enums.TargetSalesIndicatorsOfRebatesByGoods;
			TargetValuesWithoutPeriod = New Array; // Array of EnumRef.TargetSalesIndicatorsOfRebatesByGoods
			TargetValuesWithoutPeriod.Add(GoodsTargets.BatchOffer);
			TargetValuesWithoutPeriod.Add(GoodsTargets.QuantityTotal);
			
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
			NamePresentationOfTable = RebatesServer.NamePresentationOfTableByDetailsOfCustomerConditions(
				KindAttributes.PartyList, FilterParties);
			
			If NamePresentationOfTable.TableName <> "" Then
				
				CheckParameters = RebatesServer.NewParametersForCheckingConditionsInTable();
				CheckParameters.Object = ThisObject;
				CheckParameters.TableName = NamePresentationOfTable.TableName;
				CheckParameters.TablePresentation = NamePresentationOfTable.TablePresentation;
				CheckParameters.ValidOnDate = ValidOnDate;
				CheckParameters.ValidTo = ValidTo;
				CheckParameters.MaxDate = MaxDate;
				CheckParameters.CheckPlanAmount = True;
				CheckParameters.AmountPlan = SumPlan;
				CheckParameters.ListComposition = FilterParties;
				CheckParameters.CheckPeriodsInTables = CheckPeriodsInTables;
				
				RebatesServer.CheckChangesToConditionsInTable(CheckParameters, Cancel);
				
			EndIf;
			#EndRegion
			
			#Region CheckingItems
			NamePresentationOfTable = RebatesServer.NamePresentationOfTableByDetailsOfCustomerConditions(
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
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Returns a document that needs to be checked and indicates that the Status has changed.
// 
// Returns:
//  Structure - Verification data:
// * DocumentChecks - DocumentRef.ConditionsOfCustomerRebates - 
// * ModificationOfAgreedDocument - Boolean
// 
Function DataToCheck()
	
	Result = New Structure;
	Result.Insert("DocumentChecks", Documents.ConditionsOfCustomerRebates.EmptyRef());
	Result.Insert("ModificationOfAgreedDocument", False);
	
	If Not CorrectedDocument.IsEmpty() Then
		
		Result.DocumentChecks = CorrectedDocument;
		
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

#EndRegion

#EndIf