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
	
	If GoodsIndicator = Enums.TargetSalesIndicatorsOfRebatesByGoods.NotUsed Then
		
		NotCheckedAttributeArray.Add("ConditionFrequency");
		NotCheckedAttributeArray.Add("AllocationProcedure");
	
	ElsIf GoodsIndicator = Enums.TargetSalesIndicatorsOfRebatesByGoods.QuantityTotal Then
		
		NotCheckedAttributeArray.Add("AllocationProcedure");
		
	EndIf;
	
	If WithoutCalculation Then
		
		NotCheckedAttributeArray.Add("ConditionFrequency");
		NotCheckedAttributeArray.Add("AllocationProcedure");
		NotCheckedAttributeArray.Add("SalesCalculationBase");
		NotCheckedAttributeArray.Add("ContentOfGoods");
		NotCheckedAttributeArray.Add("FilterOfProducts_");
		
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	ControlOfChangesInBankingDetails(Cancel);
	RebatesServer.ControlPropertiesOfNomenclatureOfRebateKind(ProductItemProperty, ContentOfGoods, Cancel);
	
EndProcedure

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If IsFolder Then
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
	
	SalesFigures = Enums.TargetSalesIndicatorsOfRebatesByGoods;
	
	If (GoodsIndicator <> SalesFigures.NotUsed
		  And GoodsIndicator <> SalesFigures.Sum) Then
		
		FilterOfProducts_ = Enums.RebatesLists.Selected_;
		
	EndIf;
	
	If GoodsIndicator = SalesFigures.NotUsed Then
		
		ConditionFrequency = Enums.RebatesFrequencies.EmptyRef();
		AllocationProcedure = Enums.RebatesAllocationProcedures.EmptyRef();
		
	ElsIf GoodsIndicator = SalesFigures.QuantityTotal Then
		
		AllocationProcedure = Enums.RebatesAllocationProcedures.EmptyRef();
		
	EndIf;
	
	If WithoutCalculation Then
		
		AllocationProcedure = Enums.RebatesAllocationProcedures.EmptyRef();
		SalesCalculationBase = Enums.RebateCalculationBases.EmptyRef();
		ContentOfGoods = Enums.RebatesItems.EmptyRef();
		FilterOfProducts_ = Enums.RebatesLists.EmptyRef();
		
	EndIf;
	
	If SalesCalculationBase = Enums.RebateCalculationBases.RevenueBasePrices Then
		
		ConsiderVAT = False;
		FilterOfProducts_ = Enums.RebatesLists.Selected_;
		
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
	
	If Not Catalogs.CustomerRebatesKinds.RebateKindIsUsed(ThisObject, CheckWithBlocking) Then
		Return;
	EndIf;
	
	AttributesThatCannotBeChanged = New Array; // Array of String
	AttributesThatCannotBeChanged.Add("WithoutCalculation");
	AttributesThatCannotBeChanged.Add("GoodsIndicator");
	AttributesThatCannotBeChanged.Add("SalesCalculationBase");
	AttributesThatCannotBeChanged.Add("ConsiderVAT");
	AttributesThatCannotBeChanged.Add("PartyList");
	AttributesThatCannotBeChanged.Add("ContentOfGoods");
	AttributesThatCannotBeChanged.Add("AllocationProcedure");
	AttributesThatCannotBeChanged.Add("ProductItemProperty");
	
	Map = New Map;
	For Each CurProps In AttributesThatCannotBeChanged Do
		
		Attribute_Synonym = Metadata.Catalogs.CustomerRebatesKinds.Attributes[CurProps].Synonym;
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