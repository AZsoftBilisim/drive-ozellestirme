#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	If TypeOf(FillingData) = Type("Structure")
	 And Not IsFolder
	 And FillingData.Property("CostAllocationOptionLocal") Then
	 
		If FillingData.CostAllocationOptionLocal = Enums.CostAllocationOptions.ToInventoryCost Then
			ValueType = New TypeDescription("CatalogRef.Warehouses");
			ExpensesOccur = Enums.ExpenseTypes.WarehouseStorage;
		ElsIf FillingData.CostAllocationOptionLocal = Enums.CostAllocationOptions.ToProductionCosts Then
			ValueType = New TypeDescription("CatalogRef.BusinessStructure");
			ExpensesOccur = Enums.ExpenseTypes.TypeOfExpensesProduction;
		ElsIf FillingData.CostAllocationOptionLocal = Enums.CostAllocationOptions.ToNonCurrentAssetCost Then
			ValueType = New TypeDescription("CatalogRef.Assets");
			ExpensesOccur = Enums.ExpenseTypes.CalculationOfNonCurrentAssetsVAlue;
			ControlDimensionFilling = True;
		EndIf;
	 
	EndIf;
	
	If TypeOf(FillingData) = Type("Structure")
	 And Not IsFolder
	 And	(
		 	FillingData.Property("CostAllocationOptionManag") 
		 	And Not TypeOf(FillingData.CostAllocationOptionManag) = 
		 		Type("EnumRef.CostAllocationOptions")
		 	Or 
		 	FillingData.Property("CostAllocationOptionLocal") 
		 	And Not TypeOf(FillingData.CostAllocationOptionLocal) = 
		 		Type("EnumRef.CostAllocationOptions")
	 	)
	Then

		// Fill in the default values for the case of creation from a list with multiple filters
		CostAllocationOptionManag = Enums.CostAllocationOptions.ToInventoryCost;
		CostAllocationOptionLocal = Enums.CostAllocationOptions.ToInventoryCost;
		ValueType = New TypeDescription("CatalogRef.Warehouses");
		ExpensesOccur = Enums.ExpenseTypes.WarehouseStorage;
		
	EndIf;
	
	If ValueType.Types().Count() > 1 Then
		ValueType = New TypeDescription("DocumentRef.VendorInvoice");
	EndIf;
	
	ExpenseItemsLocalization.Filling(ThisObject, FillingData, StandardProcessing);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If Predefined Then
		
		ComplianceOfArticlesWithDistributionOptions = ChartsOfCharacteristicTypes.ExpenseItems.ComplianceOfArticlesWithDistributionOptions();
		
		VerifiableDistributionOptions = New ValueList;
		VerifiableDistributionOptions.Add("CostAllocationOptionLocal", NStr("vi = 'phương án phân bổ vào kế toán tài chính';
																			|ru = 'вариант распределения в регл. учете';
																			|en = 'local accounting allocation option'; fa = 'local accounting allocation option';
																			|it = 'opzione di ripartizione in contabilità regolamentata';
																			|pl = 'wariant przydzielenia w ewidencji regl.';
																			|tr = 'yerel muhasebede dağıtım seçeneği'"));
		VerifiableDistributionOptions.Add("CostAllocationOptionManag", NStr("vi = 'phương án phân bổ vào kế toán quản trị';
																			|ru = 'вариант распределения в упр. учете';
																			|en = 'management accounting allocation option'; fa = 'management accounting allocation option';
																			|it = 'opzione di ripartizione in contabilità gestionale';
																			|pl = 'wariant przydzielenia w ewidencji zarz.';
																			|tr = 'yönetim muhasebede dağıtım seçeneği'"));
		VerifiableDistributionOptions.Add("CostAllocationOptionTax", NStr("vi = 'Phương án phân bổ trong kế toán thuế';
																			|ru = 'вариант распределения в налоговом учете';
																			|en = 'allocation option in tax accounting'; fa = 'allocation option in tax accounting';
																			|it = 'variante di distribuzione in contabilità fiscale';
																			|pl = 'wariant przydzielenia w ewidencji podatkowej';
																			|tr = 'vergi muhasebesinde dağıtım seçeneği'"));
		
		Filter = New Structure();
		Filter.Insert("AssetRef", Ref);
				
		RequiredDistributionOptions = ComplianceOfArticlesWithDistributionOptions.Get(Ref);
		If RequiredDistributionOptions <> Undefined Then
			MessageTemplate = NStr("vi = 'Cần chọn %1 ""%2""';
									|ru = 'Необходимо выбрать %1 ""%2""';
									|en = 'Select %1 ""%2""'; fa = 'Select %1 ""%2""';
									|it = 'È necessario selezionare %1 ""%2""';
									|pl = 'Należy wybrać %1 ""%2""';
									|tr = '%1 ""%2"" seçmek gerekiyor'");
			For Each VerifiableDistributionOption In VerifiableDistributionOptions Do
				If RequiredDistributionOptions.FindByValue(ThisObject[VerifiableDistributionOption.Value]) = Undefined Then
					OptionsCount = RequiredDistributionOptions.Count();
					If OptionsCount = 1 Then
						MessageText = StrTemplate(MessageTemplate, VerifiableDistributionOption.Presentation, RequiredDistributionOptions[0]);
					Else
						Counter = 0;
						TextOption = "";
						While Counter < OptionsCount Do
							If Counter <> 0 Then
								TextOption = TextOption + """ or """;
							EndIf;
							TextOption = TextOption + RequiredDistributionOptions[Counter];
							Counter = Counter + 1;
						EndDo;
						MessageText = StrTemplate(MessageTemplate, VerifiableDistributionOption.Presentation, TextOption);
					EndIf;
					Common.MessageToUser(MessageText, ThisObject, VerifiableDistributionOption.Value,, Cancel);
				EndIf;
			EndDo;
		EndIf;
		
		ComplianceOfItemsWithTypesOfExpenses = ChartsOfCharacteristicTypes.ExpenseItems.ComplianceOfItemsWithTypesOfExpenses();
		RequiredTypeOfExpenses = ComplianceOfItemsWithTypesOfExpenses.Get(Ref);
		
		If RequiredTypeOfExpenses <> Undefined And ThisObject["ExpensesOccur"] <> RequiredTypeOfExpenses Then
			MessageTemplate = NStr("vi = 'Cần chọn kiểu chi phí ""%1""';
									|ru = 'Необходимо выбрать тип расходов ""%1""';
									|en = 'Select expense type ""%1""'; fa = 'Select expense type ""%1""';
									|it = 'È necessario selezionare il tipo di spesa ""%1""';
									|pl = 'Należy wybrać typ rozchodów ""%1""';
									|tr = '""%1"" gider türünü seçmek gerekiyor'");
			MessageText = StrTemplate(MessageTemplate, RequiredTypeOfExpenses);
			Common.MessageToUser(MessageText, ThisObject, "ExpensesOccur",, Cancel);
		EndIf;
		
	EndIf;
	
	NotCheckedAttributeArray = New Array;
	UT = GetFunctionalOption("TradeManagement");
	LocalizationRFService = GetFunctionalOption("LocalizationRFService");
	LocalAccnting = GetFunctionalOption("UseLocal");
	
	If CostAllocationOptionLocal <> Enums.CostAllocationOptions.ToInventoryCost
	 And CostAllocationOptionManag <> Enums.CostAllocationOptions.ToInventoryCost Then
		NotCheckedAttributeArray.Add("CostAllocationRuleToProcuctCost");
	EndIf;
	
	If CostAllocationOptionManag <> Enums.CostAllocationOptions.ToCostOfGoodsSold Then
		NotCheckedAttributeArray.Add("CostAllocationRuleToCostOfGoodsSoldMan");
	EndIf;
	
	If CostAllocationOptionLocal <> Enums.CostAllocationOptions.ToCostOfGoodsSold Then
		NotCheckedAttributeArray.Add("CostAllocationRuleToCostOfGoodsSoldLocal");
	EndIf;
	
	If UT
		Or CostAllocationOptionLocal <> Enums.CostAllocationOptions.ToProductionCosts
	 	And CostAllocationOptionManag <> Enums.CostAllocationOptions.ToProductionCosts
	 Then
		NotCheckedAttributeArray.Add("CostSharingRule");
		NotCheckedAttributeArray.Add("ProductionCostType");
	EndIf;
	
	If UT
		Or CostAllocationOptionLocal <> Enums.CostAllocationOptions.ToProductionCostDirect
		And CostAllocationOptionManag <> Enums.CostAllocationOptions.ToProductionCostDirect
	Then
		NotCheckedAttributeArray.Add("BaseOfAllocationByLots");
	EndIf;
	
	If UT Or Not LocalizationRFService Or Not LocalAccnting Then
		NotCheckedAttributeArray.Add("CostAllocationOptionTax");
	EndIf;

	If Not IsFolder Then
		// The Separate accountand option will be forcibly set before recording the item if it is not filled in
		NotCheckedAttributeArray.Add("SeparateVATAccountingOption");
	EndIf;

	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	ExpenseItemsLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
EndProcedure

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Not IsFolder Then
		
		If CostAllocationOptionLocal = Enums.CostAllocationOptions.ToInventoryCost Then
			VATAssetTaxClass = Enums.AssetKinds.Goods;
		ElsIf CostAllocationOptionLocal = Enums.CostAllocationOptions.ToNonCurrentAssetCost Then
			If VATAssetTaxClass.IsEmpty() Then
				VATAssetTaxClass = Enums.AssetKinds.FA
			EndIf;
		Else
			VATAssetTaxClass = Enums.AssetKinds.OtherWorksAndServices;
		EndIf;
		
		OtherExpenses = ValueType.ContainsType(Type("CatalogRef.OtherExpenses"));
		LoanAndDepositContracts = ValueType.ContainsType(Type("CatalogRef.LoanAndDepositContracts"));
		ExpensesOnAssets = (ValueType.ContainsType(Type("CatalogRef.Assets")));
		IntangibleAssetsAndRDExpenses = (ValueType.ContainsType(Type("CatalogRef.IntangibleAssets")));
		ResearchAndDevelopmentExpenses = (ValueType.ContainsType(Type("CatalogRef.RDTopicsStages")));
		ExpensesOnConstructionObjects = (ValueType.ContainsType(Type("CatalogRef.ConstructionObjects")));
		RMOrderExpenses = (ValueType.ContainsType(Type("DocumentRef.RMOrder")));
		If Not IsBlankString(OffsettingAccount) Then
			If IsBlankString(StrReplace(OffsettingAccount, ".", "")) Then
				OffsettingAccount = "";
			Else
				While Right(TrimAll(OffsettingAccount), 1) = "." Do
					OffsettingAccount = Left(TrimAll(OffsettingAccount), StrLen(TrimAll(OffsettingAccount)) - 1);
				EndDo;
			EndIf;
		EndIf;
		
		If Not RestrictUsageInBusinessTransactions
			And AvailableBusinessTransactions.Count() > 0 Then
			
			AvailableBusinessTransactions.Clear();
			AvailableTransactions = "";
		Else
			TransactionList = New ValueList;
			ChartsOfCharacteristicTypes.ExpenseItems.FillInListOfBusinessOperations(
				TransactionList,
				CostAllocationOptionManag,
				CostAllocationOptionLocal);
			LineAvailableOperations = "";
			For Each TableRow In AvailableBusinessTransactions Do
				ListItem = TransactionList.FindByValue(TableRow.BusinessOperation);
				If ListItem <> Undefined Then
					LineAvailableOperations = LineAvailableOperations
						+ ?(Not IsBlankString(LineAvailableOperations), ", ", "")
						+ ListItem.Presentation;
				EndIf;
			EndDo;
			If AvailableTransactions <> LineAvailableOperations Then
				AvailableTransactions = LineAvailableOperations;
			EndIf;
		EndIf;
		
		If Not ValueIsFilled(SeparateVATAccountingOption) Then
			SeparateVATAccountingOption = Enums.SeparateVATAccountingOptions.FromDocument;
		EndIf;
		
	EndIf;
	
	ExpenseItemsLocalization.BeforeWrite(ThisObject, Cancel);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If Cancel Or DataExchange.Load Then
		Return;
	EndIf;
	
	ExpenseItemsLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure OnReadPresentationsAtServer() Export
	// StandardSubsystems.Core
	NationalLanguageSupportServer.OnReadPresentationsAtServer(ThisObject);
	// End StandardSubsystems.Core
EndProcedure

#EndRegion

#EndIf
