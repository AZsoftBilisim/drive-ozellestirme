////////////////////////////////////////////////////////////////////////////////
//
// Server procedures for working with expense items
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Private

#Region Other

// Managing form elements
//
// Parameters:
// 	Form - ClientApplicationForm - Form of the plan of types of characteristics
//
Procedure FormItemsManagement(Form) Export
	
	Items = Form.Items;
	Object = Form.Object;

	// The "Main" tab.
	
	// General settings or full features
	Items.AGroupOfSimpleFeatures.Visible = Not Form.FullFunctionality;
	Items.FullFeaturesGroup.Visible = Form.FullFunctionality;
	
	// Settings for selections and parameters for creating new rules
	PurposeOfTheUprRule = Form.PurposeOfTheUprRule;
	PurposeOfTheReglRule = Form.PurposeOfTheReglRule;
	TaRuleAssignment = Form.TaRuleAssignment;

	Form.PurposeOfTheUprRule = Catalogs.CostAllocationRules.GetRuleAssignmentForDistributionOption(Object.CostAllocationOptionManag);
	Form.PurposeOfTheReglRule = Catalogs.CostAllocationRules.GetRuleAssignmentForDistributionOption(Object.CostAllocationOptionLocal);
	Form.TaRuleAssignment = Catalogs.CostAllocationRules.GetRuleAssignmentForDistributionOption(Object.CostAllocationOptionTax);
	
	If ValueIsFilled(PurposeOfTheUprRule) And PurposeOfTheUprRule <> Form.PurposeOfTheUprRule Then
		Object.CostAllocationRuleManag = Catalogs.CostAllocationRules.EmptyRef();
	EndIf;
	
	If ValueIsFilled(PurposeOfTheReglRule) And PurposeOfTheReglRule <> Form.PurposeOfTheReglRule Then
		Object.CostAllocationRuleLocal = Catalogs.CostAllocationRules.EmptyRef();
	EndIf;
	
	If ValueIsFilled(TaRuleAssignment) And TaRuleAssignment <> Form.TaRuleAssignment Then
		Object.CostAllocationRuleTax = Catalogs.CostAllocationRules.EmptyRef();
	EndIf;
	
	If Not Form.FullFunctionality Then
		// Rules for the cost of goods
		Items.TheCostAllocationRuleIsCommon.Visible =	False;
		// Rules on the cost of sales
		Items.TheDistributionRuleForTheCostOfSalesIsCommon.Visible = (Object.CostAllocationOptionManag = Enums.CostAllocationOptions.ToCostOfGoodsSold);

		// Rules on the cost of production
		Items.TheBaseOfDistributionByParty.Visible = False 
			Or (Object.CostAllocationOptionManag = Enums.CostAllocationOptions.ToProductionCostDirect) 
			And Form.ValueType <> "CatalogRef.ProductionLots"
		;

		// Other rules
		Items.TheRuleOfAllocationOfCommonCosts.Visible = 
			Enums.CostAllocationOptions.VariantUsesAllocationRule(Object.CostAllocationOptionManag);

		// Inscriptions
		Items.InscriptionDoesNotRequireDistribution.Visible = 
			Not Object.CostAllocationOptionManag.IsEmpty() 
			And Enums.CostAllocationOptions.OptionWithoutDistribution(Object.CostAllocationOptionManag);
	Else
		// Rules for the cost of goods
		Items.TheDistributionRuleForTheCostOfUprIsComplete.Visible = False;
		Items.TheDistributionRuleForTheCostOfRegl.Visible = False;
		// Rules on the cost of sales
		Items.TheDistributionRuleForTheCostOfSalesUprFull.Visible = 
			(Object.CostAllocationOptionManag  = Enums.CostAllocationOptions.ToCostOfGoodsSold);
		Items.TheDistributionRuleForTheCostOfSalesRegl.Visible = 
			(Object.CostAllocationOptionLocal = Enums.CostAllocationOptions.ToCostOfGoodsSold);

		// Rules on the cost of production
		Items.DistributionBaseByBatchUprComplete.Visible = False
			Or (Object.CostAllocationOptionManag = Enums.CostAllocationOptions.ToProductionCostDirect) 
			And Form.ValueType <> "CatalogRef.ProductionLots"
		;
		Items.DatabaseOfDistributionByBatchReglComplete.Visible = False
			Or (Object.CostAllocationOptionLocal = Enums.CostAllocationOptions.ToProductionCostDirect)
			And Form.ValueType <> "CatalogRef.ProductionLots" 
			And (Object.CostAllocationOptionManag<>Object.CostAllocationOptionLocal)
		;

		// Other rules
		Items.TheRuleOfDistributionOfExpensesOfTheUprIsComplete.Visible = 
			Enums.CostAllocationOptions.VariantUsesAllocationRule(Object.CostAllocationOptionManag);
		Items.TheRuleOfApportionmentOfTheExpensesOfReglFull.Visible = 
			Enums.CostAllocationOptions.VariantUsesAllocationRule(Object.CostAllocationOptionLocal);
		// Inscriptions
		Items.TheLabelDoesNotRequireTheDistributionOfUpr.Visible = 
			Not Object.CostAllocationOptionManag.IsEmpty() 
			And Enums.CostAllocationOptions.OptionWithoutDistribution(Object.CostAllocationOptionManag);
		Items.TheLabelDoesNotRequireTheDistributionOfRegl.Visible = 
			Not Object.CostAllocationOptionLocal.IsEmpty() 
			And Enums.CostAllocationOptions.OptionWithoutDistribution(Object.CostAllocationOptionLocal);
		Items.LabelDistributionRuleReglAsUpr.Visible = 
			Not Object.CostAllocationOptionLocal.IsEmpty() 
			And Not Enums.CostAllocationOptions.VariantUsesAllocationRule(Object.CostAllocationOptionLocal) 
			And Not Enums.CostAllocationOptions.OptionWithoutDistribution(Object.CostAllocationOptionLocal) 
			And (Object.CostAllocationOptionManag = Object.CostAllocationOptionLocal)
			And Not (Object.CostAllocationOptionLocal = Enums.CostAllocationOptions.ToCostOfGoodsSold);
		Items.LabelSetUpDistributionRules.Visible = 
			Enums.CostAllocationOptions.VariantUsesAllocationRule(Object.CostAllocationOptionManag) 
			Or Enums.CostAllocationOptions.VariantUsesAllocationRule(Object.CostAllocationOptionLocal)
			Or Enums.CostAllocationOptions.VariantUsesTaAllocationRule(Object.CostAllocationOptionTax);
	EndIf;
	
	// Analytics.
	Items.AnalyticsViewGroup.Visible = True 
		And (Object.ExpensesOccur <> Enums.ExpenseTypes.ExpenseToCostCenters)
	;
	
	Items.TheGroupAllocationRuleForTheProductionOf.Visible = False 
		Or Object.CostAllocationOptionManag = Enums.CostAllocationOptions.ToProductionCostDirect
		Or Object.CostAllocationOptionManag = Enums.CostAllocationOptions.ToProductionCosts
		Or Object.CostAllocationOptionLocal = Enums.CostAllocationOptions.ToProductionCostDirect
		Or Object.CostAllocationOptionLocal = Enums.CostAllocationOptions.ToProductionCosts


		Or CalculationOfCostLocalization.GetFunctionalOptionAITAccounting() And Object.RecognizedInAITExpenses;
		
	Items.ControlDimensionFilling.Enabled = Not 
		(Object.ExpensesOccur = Enums.ExpenseTypes.CalculationOfNonCurrentAssetsVAlue
			Or Object.ExpensesOccur = Enums.ExpenseTypes.ExpenseToCostCenters
			Or Object.ExpensesOccur = Enums.ExpenseTypes.ManufactureOfProducts);
	
	// Separate VAT accounting
	VNAValueType = (Object.VATAssetTaxClass = Enums.AssetKinds.IA) Or (Object.VATAssetTaxClass = Enums.AssetKinds.FA);
	
	UseSeparateFAAccountingByTaxation = False;
	UseSeparateFAAccountingByTaxation = GetFunctionalOption("UseSeparateFAAccountingByTaxation");
	OptionOfSeparateVATAccountingForAreasOfActivityVisibility =
		Not (VNAValueType And UseSeparateFAAccountingByTaxation)
			And (Object.CostAllocationOptionLocal <> Enums.CostAllocationOptions.ToInventoryCost);
	
	OptionOfSeparateVATAccountingWarningVisibility = False;
	
	If Object.CostAllocationOptionLocal = Enums.CostAllocationOptions.ToProductionCostDirect
			Or Object.CostAllocationOptionLocal = Enums.CostAllocationOptions.ToProductionCosts
 	Then
		OptionOfSeparateVATAccountingWarningVisibility = 
			Object.SeparateVATAccountingOption <> Enums.SeparateVATAccountingOptions.FromDocument;
 		OptionOfSeparateVATAccountingForAreasOfActivityVisibility = OptionOfSeparateVATAccountingWarningVisibility;
	EndIf;
	
	Items.OptionOfSeparateVATAccountingWarning.Visible = OptionOfSeparateVATAccountingWarningVisibility;
	Items.OptionForSeparateAccountingOfNDSNaActivities.Visible = OptionOfSeparateVATAccountingForAreasOfActivityVisibility;
		
	Items.GroupFullReglSettings.Visible = GetFunctionalOption("UseAccountingOfOtherIncomeExpensesInLocalAccounting");
	
	Items.OptionOfSeparateAccountingOfVATOS.Visible =
		UseSeparateFAAccountingByTaxation 
			And (Object.VATAssetTaxClass = Enums.AssetKinds.FA
				Or Object.VATAssetTaxClass = Enums.AssetKinds.IA);
	
	
	// The "Usage restriction" tab.	
		
	Items.AvailableBusinessTransactions.Enabled = (Object.RestrictUsageInBusinessTransactions And Not Form.ReadOnly);
	
	Items.InformationOnOtherAssetsText.Title = 
		NStr("vi = 'Phương án phân bổ này đã cũ, thay cho các dạng với phương án phân bổ này, cần sử dụng dạng tài sản/nguồn vốn trong các chứng từ.';
			|ru = 'Данный вариант распределения устарел, вместо статей с таким вариантом распределения в документах следует использовать статьи активов/пассивов.';
			|en = 'This allocation option is outdated, use asset/liability items instead of the items with such allocation option in documents.'; fa = 'This allocation option is outdated, use asset/liability items instead of the items with such allocation option in documents.';
			|it = 'L''opzione corrente di ammortizzazione è obsoleta, al posto degli articoli con questa variante di ammortizzazione, nei documenti bisogna utilizzare gli articoli degli attivi/passivi.';
			|pl = 'Dany wariant przydziału jest nieaktualny, zamiast pozycji z takim wariantem przydziału w dokumentach należy używać pozycji aktywów/pasywów.';
			|tr = 'Bu dağıtım seçeneği artık kullanılmamaktadır; belgelerde bu dağıtım seçeneğine sahip kalemler yerine varlık/yükümlülük kalemleri kullanılmalıdır.'");
		
	If Not GetFunctionalOption("UseAccountingOfOtherAssetsAndLiabilities") Then
		Items.InformationOnOtherAssetsText.Title = Items.InformationOnOtherAssetsText.Title 
			+ " " 
			+ NStr("vi = 'Để sử dụng các dạng tài sản/nguồn vốn, hãy bật tùy chọn ""Hạch toán tài sản và nguồn vốn khác"" (phân hệ Quản trị - Kết quả kinh doanh).';
					|ru = 'Для использования статей активов/пассивов включите опцию ""Учитывать прочие активы и пассивы"" (раздел Администрирование - Финансовый результат).';
					|en = 'To use asset/liability items, enable the ""Record other assets and liabilities"" option (section Settings - Financial result).'; fa = 'To use asset/liability items, enable the ""Record other assets and liabilities"" option (section Settings - Financial result).';
					|it = 'Per utilizzare gli articoli degli attivi/passivi attivate l''opzione ""Conteggiare gli altri attivi e passivi"" (sezione Amministrazione - Risultato finanziario).';
					|pl = 'Aby użyć pozycji aktywów/pasywów, włącz opcję ""Uwzględniaj inne aktywa i pasywa"" (rozdział Administrowanie - Wynik finansowy).';
					|tr = 'Varlık/yükümlülük kalemlerini kullanmak için ""Diğer varlık ve yükümlülükleri dikkate al"" seçeneğini aç (bölüm Yönetim - Finansal sonuç).'")
		
	EndIf;

EndProcedure

#EndRegion

#EndRegion