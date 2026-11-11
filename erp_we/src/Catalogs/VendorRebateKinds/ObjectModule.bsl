//@strict-types

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnCopy(CopiedObject)
	
	If IsFolder Then
		Return;
	EndIf;
	
	Status = Enums.RebatesKindsStatuses.Prepared;
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If IsFolder Then
		Return;
	EndIf;
	
	If ValueIsFilled(ValidOnDate)
	   And ValueIsFilled(ValidTo)
	   And ValidTo < ValidOnDate Then
		
		MessageText = NStr("vi = 'Ngày hết hiệu lực của dạng thưởng lũy kế không được nhỏ hơnn ngày đầu hiệu lực';
							|ru = 'Дата окончания действия вида ретро-бонуса должна быть не меньше даты начала действия';
							|en = 'Expiration date of the rebate kind cannot be less than the effective date'; fa = 'Expiration date of the rebate kind cannot be less than the effective date';
							|it = 'Дата окончания действия вида ретро-бонуса должна быть не меньше даты начала действия';
							|pl = 'Expiration date of the rebate kind cannot be less than the effective date';
							|tr = 'Retro bonusu türünün sona erme tarihi, işlemin başlangıç tarihinden önce olmamalıdır'");
		Common.MessageToUser(MessageText, ThisObject, "ValidTo",, Cancel);
		
	EndIf;
	
	NotCheckedAttributeArray = New Array; // Array of String
	
	If ContentOfGoods <> Enums.RebatesItems.ProductItemProperty Then
		
		NotCheckedAttributeArray.Add("ProductItemProperty");
		
	EndIf;
	
	If BonusType = Enums.VendorRebateTypes.Balance Then
		
		NotCheckedAttributeArray.Add("AccrualFrequency");
		
	EndIf;
	
	If BonusType <> Enums.VendorRebateTypes.Sales Then
		
		NotCheckedAttributeArray.Add("PartyList");
		NotCheckedAttributeArray.Add("FilterParties");
		
	EndIf;
	
	DistributionRequired =
		BonusType = Enums.VendorRebateTypes.Purchases
		And BaseOfCalculation <> Enums.RebateCalculationBases.PurchaseAmountBasePrices
		And (GoodsIndicator = Enums.TargetSalesIndicatorsOfRebatesByGoods.Count
		   Or GoodsIndicator = Enums.TargetSalesIndicatorsOfRebatesByGoods.BatchOffer);
	
	If WithoutCalculation
	 Or Not DistributionRequired Then
		
		NotCheckedAttributeArray.Add("AllocationProcedure");
		
	EndIf;
	
	If WithoutCalculation
	 Or BonusType = Enums.VendorRebateTypes.Balance
	 Or GoodsIndicator = Enums.TargetSalesIndicatorsOfRebatesByGoods.NotUsed Then
		
		NotCheckedAttributeArray.Add("ConditionFrequency");
		
	EndIf;
	
	If WithoutCalculation Then
		
		NotCheckedAttributeArray.Add("BonusType");
		NotCheckedAttributeArray.Add("GoodsIndicator");
		NotCheckedAttributeArray.Add("ContentOfGoods");
		NotCheckedAttributeArray.Add("FilterOfProducts_");
		
	EndIf;
	
	If WithoutCalculation
	 Or BonusType = Enums.VendorRebateTypes.Balance Then
		
		NotCheckedAttributeArray.Add("BaseOfCalculation");
		
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	ControlOfChangesInBankingDetails(Cancel);
	RebatesServer.ControlPropertiesOfNomenclatureOfRebateKind(ProductItemProperty, ContentOfGoods, Cancel);
	
EndProcedure

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If ExchangePlans.MasterNode() <> Undefined Then
		
		MessageText = NStr("vi = 'Cấm thay đổi danh mục trong nút phụ trao đổi';
							|ru = 'Запрещено изменение справочника в подчиненном узле обмена';
							|en = 'Cannot change the catalog in a subordinate exchange node'; fa = 'Cannot change the catalog in a subordinate exchange node';
							|it = 'Запрещено изменение справочника в подчиненном узле обмена';
							|pl = 'Cannot change the catalog in a subordinate exchange node';
							|tr = 'Bağımlı değişim düğümündeki kataloğun değiştirilmesi yasaktır'");
		Common.MessageToUser(MessageText, ThisObject,,, Cancel);
		
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	If IsFolder Then
		Return;
	EndIf;
	
	If BonusType <> Enums.VendorRebateTypes.Sales Then
		
		PartyList = Enums.RebatesParticipants.EmptyRef();
		FilterParties = Enums.RebatesLists.EmptyRef();
		
	EndIf;
	
	If BonusType <> Enums.VendorRebateTypes.Purchases
	   And Not (BonusType = Enums.VendorRebateTypes.Sales
			 And GoodsIndicator <> Enums.TargetSalesIndicatorsOfRebatesByGoods.NotUsed) Then
		
		ConditionFrequency = Enums.RebatesFrequencies.EmptyRef();
		
	EndIf;
	
	If WithoutCalculation
	 Or BonusType = Enums.VendorRebateTypes.Balance
	 Or GoodsIndicator = Enums.TargetSalesIndicatorsOfRebatesByGoods.NotUsed Then
		
		ConditionFrequency = Enums.RebatesFrequencies.EmptyRef();
		
	EndIf;
	
	AllocationProcedure = RebatesClientServer.CheckResetAllocationOrder(
		AllocationProcedure,
		WithoutCalculation,
		BonusType,
		GoodsIndicator,
		BaseOfCalculation);
	
	CustomerVerificationIsAvailable =
		(BonusType = Enums.VendorRebateTypes.Sales
		 And GoodsIndicator <> Enums.TargetSalesIndicatorsOfRebatesByGoods.NotUsed);
	If Not CustomerVerificationIsAvailable
	 Or WithoutCalculation Then
		
		FulfilConditionsByCustomers = False;
		
	EndIf;
	
	If WithoutCalculation Then
		
		ConsiderVAT = False;
		GoodsIndicator = Enums.TargetSalesIndicatorsOfRebatesByGoods.NotUsed;
		BonusType = Enums.VendorRebateTypes.EmptyRef();
		ContentOfGoods = Enums.RebatesItems.EmptyRef();
		FilterOfProducts_ = Enums.RebatesLists.EmptyRef();
		
	EndIf;
	
	If WithoutCalculation
	 Or BonusType = Enums.VendorRebateTypes.Balance Then
		
		BaseOfCalculation = Enums.RebateCalculationBases.EmptyRef();
		
	EndIf;
	
	If BonusType = Enums.VendorRebateTypes.Balance Then
		
		AccrualFrequency = Enums.RebatesFrequencies.EmptyRef();
		
	ElsIf WithoutCalculation Then 
		
		AccrualFrequency = Enums.RebatesFrequencies.Single;
		
	EndIf;
	
	If ContentOfGoods <> Enums.RebatesItems.ProductItemProperty Then
		
		ProductItemProperty = "";
		
	EndIf;
	
	ControlOfChangesInBankingDetails(Cancel, True);
	
EndProcedure

#EndRegion

#Region Private

Procedure ControlOfChangesInBankingDetails(Cancel, CheckWithBlocking = False)
	
	If Ref.IsEmpty() Then
		Return;
	EndIf;
	
	If Not Catalogs.VendorRebateKinds.RebateKindIsUsed(ThisObject, CheckWithBlocking) Then
		Return;
	EndIf;
	
	AttributesThatCannotBeChanged = New Array; // Array of String
	AttributesThatCannotBeChanged.Add("BonusType");
	AttributesThatCannotBeChanged.Add("WithoutCalculation");
	AttributesThatCannotBeChanged.Add("GoodsIndicator");
	AttributesThatCannotBeChanged.Add("BaseOfCalculation");
	AttributesThatCannotBeChanged.Add("ConsiderVAT");
	AttributesThatCannotBeChanged.Add("PartyList");
	AttributesThatCannotBeChanged.Add("ContentOfGoods");
	AttributesThatCannotBeChanged.Add("AllocationProcedure");
	AttributesThatCannotBeChanged.Add("FulfilConditionsByCustomers");
	AttributesThatCannotBeChanged.Add("ProductItemProperty");
	
	Map = New Map;
	For Each CurProps In AttributesThatCannotBeChanged Do
		
		Attribute_Synonym = Metadata.Catalogs.VendorRebateKinds.Attributes[CurProps].Synonym;
		Map.Insert(CurProps, Attribute_Synonym);
		
	EndDo;
	
	OldAttributesValues = Common.ObjectAttributesValues(
		Ref, 
		AttributesThatCannotBeChanged);
	
	MessageTemplate = NStr("vi = 'Không nên thay đổi mục tin ""%1, bởi vì dạng thưởng lũy kế ""%2"" đã được sử dụng trong các chứng từ.';
							|ru = 'Реквизит ""%1"" изменять нельзя, так как вид ретро-бонуса ""%2"" уже используется в документах.';
							|en = 'Cannot change the ""%1"" attribute as the ""%2"" rebate kind is already used in documents.'; fa = 'Cannot change the ""%1"" attribute as the ""%2"" rebate kind is already used in documents.';
							|it = 'Реквизит ""%1"" изменять нельзя, так как вид ретро-бонуса ""%2"" уже используется в документах.';
							|pl = 'Cannot change the ""%1"" attribute as the ""%2"" rebate kind is already used in documents.';
							|tr = '""%1"" özniteliği değiştirilemez, çünkü ""%2"" retro bonusu halihazırda belgede kullanılmakta.'");
	
	For Each CurProps In AttributesThatCannotBeChanged Do
		
		If OldAttributesValues[CurProps] <> ThisObject[CurProps] Then
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				MessageTemplate, 
				Map[CurProps],
				String(Ref));
			
			Common.MessageToUser(MessageText,, CurProps, "Object", Cancel);
			
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#EndIf