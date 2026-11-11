////////////////////////////////////////////////////////////////////////////////
// Report Options - UP Report Form (client, redefined)
// 
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Handler for decoding a table document in a report form.
//
// Parameters:
//  ThisForm - ClientApplicationForm - report form.
//  Item     - FormField        - table document.
//  Details - Arbitrary     - the value of the decoding point, series, or chart value.
//  StandardProcessing - Boolean  - indicates whether standard (system) event processing is performed.
//
Procedure DetailProcessing(ThisForm, Item, Details, StandardProcessing) Export
	
	FullReportName = ThisForm.ReportSettings.FullName;
	CurrentVariantKey = ThisForm.CurrentVariantKey;
	
	NonCurrentAssetsClient.ProcessingReportDecryption(ThisForm, Item, Details, StandardProcessing);
	
	If FullReportName = "Report.BudgetReportFormulaDrillDown" Then
	
		StandardProcessing = False;
		
		OpeningParameters = BudgetReportingServerCall.DecryptionFormParametersForDecryptionReport(
																		Details, ThisForm.ReportDetailsData);
		
		If OpeningParameters = Undefined Then
			ShowMessageBox(, NStr("vi = 'Không có dữ liệu để giải mã';
									|ru = 'Нет данных для расшифровки';
									|en = 'No data to drill down'; fa = 'No data to drill down';
									|it = 'Non ci sono dati per la decodifica';
									|pl = 'Brak danych do odszyfrowania';
									|tr = 'Çözümleme için veri yok'"));
		Else
			BudgetReportingClient.OpenReportForm(OpeningParameters, ThisForm);
		EndIf;
		
	
	ElsIf FullReportName = "Report.LoadOfWorkCenterTypes" Then
		
		ReportMenu  = New Array;
		ActionMenu = New Array;
		
		If CurrentVariantKey = "LoadingTypesOfWorkCentersTable" 
			Or CurrentVariantKey = "LoadingTypesOfWorkCentersTableContext" Then
			
			
			// Go -> Change the availability of the work centers view
			#Region ChangeAvailabilityOfRCView
			ActionParameters = New Structure;
			ActionParameters.Insert("Name", "ChangeAvailabilityOfRCView");
			ActionParameters.Insert("Title", NStr("vi = 'Thay đổi sự sẵn có của quan điểm trung tâm làm việc';
													|ru = 'Изменить доступность вида рабочих центров';
													|en = 'Change capacity of work center type'; fa = 'Change capacity of work center type';
													|it = 'Modificare la disponibilità del tipo di centri di lavoro';
													|pl = 'Zmień dostępność rodzaju centrum pracy';
													|tr = 'İş merkezi türünün kullanılabilirliğini değiştir'"));
			ActionParameters.Insert("CommonModuleName", "ReportsERPClientOverridable");
			
			DecryptionFields = New Array;
			DecryptionFields.Add("WorkCenterType");
			DecryptionFields.Add("SchedulePeriod");
			ActionParameters.Insert("DecryptionFields", DecryptionFields);
			
			RequiredParameters = New Structure;
			RequiredParameters.Insert("WorkCenterType");
			RequiredParameters.Insert("SchedulePeriod");
			ActionParameters.Insert("RequiredParameters", RequiredParameters);
			
			ActionMenu.Add(ActionParameters);
			#EndRegion
			
		EndIf;
		
		DetailsParameters = New Structure;
		DetailsParameters.Insert("ReportMenu",  ReportMenu);
		DetailsParameters.Insert("ActionMenu", ActionMenu);
		DetailsParameters.Insert("Details",  Details);
		
		DataCompositionClient.DecryptionProcessingWithAdditionalMenu(ThisForm, DetailsParameters, StandardProcessing);
		

	ElsIf FullReportName = "Report.CheckBudgetItemLinks" Then
		
		ReportDetailsData = BudgetingServerCall.ReportDetailsData(Details, ThisForm.ReportDetailsData);
		
		If ReportDetailsData.MainAction = DataCompositionDetailsProcessingAction.DrillDown Then
			StandardProcessing = False;
			
			AvailableDecryptionFields  = New Structure;
			AvailableDecryptionFields.Insert("BudgetBalanceItem");
			AvailableDecryptionFields.Insert("Dimension1");
			AvailableDecryptionFields.Insert("Dimension2");
			AvailableDecryptionFields.Insert("Dimension3");
			AvailableDecryptionFields.Insert("Dimension4");
			AvailableDecryptionFields.Insert("Dimension5");
			AvailableDecryptionFields.Insert("Dimension6");
			AvailableDecryptionFields.Insert("Currency");
			
			DecryptionFields = New Structure;
			For Each Field In ReportDetailsData.DecryptionFields Do
				If AvailableDecryptionFields.Property(Field.Key) Then
					DecryptionFields.Insert(Field.Key, Field.Value);
				EndIf;
			EndDo;
			For Each Field In ReportDetailsData.DecryptionFieldsParents Do
				If AvailableDecryptionFields.Property(Field.Key) Then
					DecryptionFields.Insert(Field.Key, Field.Value);
				EndIf;
			EndDo;
			
			Parameters = New Structure;
			Parameters.Insert("ReportName"			, "DetailedCalculationOfBudgetTargets");
			Parameters.Insert("VariantKey"		, "DetailedCalculationOfBudgetTargets");
			Parameters.Insert("SettingsComposer", ThisForm.Report.SettingsComposer);
			Parameters.Insert("DecryptionFields"	, DecryptionFields);
			SettingUpCalculatedBudgets = ReportsTMServerCallOverridable.ConfigureDecryptionReport(Parameters);
			
			MainReportDataParameters = ThisForm.Report.SettingsComposer.Settings.DataParameters;
			
			FixedParameters = New Structure("Period, Factor", ReportDetailsData.DataParameters.Period);
			For Each KeyAndValue In FixedParameters Do
				
				ParameterValue = ?(KeyAndValue.Key = "Period", KeyAndValue.Value,
					MainReportDataParameters.FindParameterValue(New DataCompositionParameter(KeyAndValue.Key)).Value);
				
				Parameter = DataCompositionClientServer.GetParameter(SettingUpCalculatedBudgets.FixedSettings, KeyAndValue.Key);
				If Parameter = Undefined Then
					Parameter = SettingUpCalculatedBudgets.FixedSettings.DataParameters.Items.Add();
					Parameter.Parameter = New DataCompositionParameter(KeyAndValue.Key);
				EndIf;
				DataCompositionClientServer.SetParameter(SettingUpCalculatedBudgets.FixedSettings,
																					KeyAndValue.Key, ParameterValue, True);
				
			EndDo;
			
			SettingsKey = "DecodingBudgetIndicator";
			FormParameters = New Structure;
			FormParameters.Insert("VariantKey",                  "DetailedCalculationOfBudgetTargets");
			FormParameters.Insert("PurposeUseKey",    SettingsKey);
			FormParameters.Insert("UserSettingsKey",   SettingsKey);
			FormParameters.Insert("UserSettings",      SettingUpCalculatedBudgets.UserSettings);
			FormParameters.Insert("FixedSettings",         SettingUpCalculatedBudgets.FixedSettings);
			FormParameters.Insert("GenerateOnOpen",        True);
			FormParameters.Insert("ReportOptionsCommandsVisibility",False);
			FormParameters.Insert("DetailsMode",               True);
			OpenForm("Report.DetailedCalculationOfBudgetTargets.Form", FormParameters, ThisForm, True);
		EndIf;
		
	ElsIf FullReportName = "Report.TargetAndActualProductsCost" Then
		
		ReportMenu  = New Array;
		ActionMenu  = New Array;
		
		ParametersList = New Array;
		ParametersList.Add("Cost_Data");
		ParametersList.Add("Period");
		
		ReportParameters = New Structure;
		ReportParameters.Insert("Name",              "ActualProductCost");
		ReportParameters.Insert("Title",        NStr("vi = 'Giá vốn sản phẩm thực tế';
													|ru = 'Фактическая себестоимость продукции';
													|en = 'Actual product cost'; fa = 'بهای واقعی محصول';
													|it = 'Costo di produzione effettivo';
													|pl = 'Faktyczne koszty własne produkcji';
													|tr = 'Ürün gerçek maliyeti'"));
		ReportParameters.Insert("ReportName",        "Report.ActualProductCost");
		ReportParameters.Insert("ParametersList", ParametersList);
		
		DecryptionFields  = New Array;
		DecryptionFields.Add("ManufacturedProduct");
		DecryptionFields.Add("ItemVariant");
		DecryptionFields.Add("AssignmentOfProducts");
		DecryptionFields.Add("ProductsBatch");
		ReportParameters.Insert("DecryptionFields", DecryptionFields);
		
		ReportMenu.Add(ReportParameters);
		
		ReportParameters = New Structure;
		ReportParameters.Insert("Name",              "ProductCostEstimate");
		ReportParameters.Insert("Title",        NStr("vi = 'Chi phí sản xuất theo kế hoạch';
													|ru = 'Плановая себестоимость продукции';
													|en = 'Standard product cost'; fa = 'بهای استاندارد محصول';
													|it = 'Costo di produzione stimata';
													|pl = 'Planowane koszty własne produkcji';
													|tr = 'İmal edilen ürünlerin standart maliyeti'"));
		ReportParameters.Insert("ReportName",        "Report.ProductCostEstimate");
		ReportParameters.Insert("ParametersList", ParametersList);
		
		DecryptionFields  = New Array;
		DecryptionFields.Add("ManufacturedProduct");
		DecryptionFields.Add("ItemVariant");
		DecryptionFields.Add("StandardCostEstimate");
		ReportParameters.Insert("DecryptionFields", DecryptionFields);
		
		ReportMenu.Add(ReportParameters);
		
		DetailsParameters = New Structure;
		DetailsParameters.Insert("ReportMenu",  ReportMenu);
		DetailsParameters.Insert("ActionMenu", ActionMenu);
		DetailsParameters.Insert("Details",  Details);
		
		DataCompositionClient.DecryptionProcessingWithAdditionalMenu(ThisForm, DetailsParameters, StandardProcessing);
		
	ElsIf FullReportName = "Report.ProductCostEstimate" Then
		
		StandardProcessing = False;
				
	ElsIf FullReportName = "Report.ProductionCosts"
		Or FullReportName = "Report.ProductionCostsByProductionLots"
		Or FullReportName = "Report.ItemizedProductionCosts"
		Or FullReportName = "Report.ProductionMaterialCost" Then
		
		StandardProcessing = False;
		
		DecryptionFields = New Array;
		
		ParametersList = New Array;
		ParametersList.Add("Cost_Data");
		ParametersList.Add("Period");
		
		ServiceGroupingFields = New Array;
		ServiceGroupingFields.Add("MovementOfMaterialsAndProducts");
		ServiceGroupingFields.Add("MovementOfItemizedExpenses");
		ServiceGroupingFields.Add("AllocationOfCostsByProductionBatches");
		ServiceGroupingFields.Add("CostGroupingByProductionBatches");
		CommonClientServer.SupplementArray(DecryptionFields, ServiceGroupingFields);
		
		GroupFields = New Array;
		// to decrypt the shopping center
		GroupFields.Add("Organization");
		GroupFields.Add("WarehouseDivision");
		GroupFields.Add("ItemsLocationAttributes");
		GroupFields.Add("Products");
		GroupFields.Add("Characteristic");
		GroupFields.Add("Series");
		GroupFields.Add("Purpose");
		// to decipher the article - by - article
		GroupFields.Add("Department");
		GroupFields.Add("ExpenseItem");
		GroupFields.Add("DimensionOfExpenses");
		GroupFields.Add("LineOfBusiness");
		// to decipher the production
		GroupFields.Add("ProductionLot");
		GroupFields.Add("LineOfBusiness");
		GroupFields.Add("ProductCostElement");
		GroupFields.Add("Cost_");
		GroupFields.Add("DimensionCosts");
		GroupFields.Add("AnalyticsCostsAdditional");
		GroupFields.Add("WorkKind");
		CommonClientServer.SupplementArray(DecryptionFields, GroupFields);
		
		ArrayOfOptionFields = New Array;
		
		AddGroupOfColumns(ArrayOfOptionFields, DecryptionFields, "InitialBalanceQuantity,InitialBalanceCost,InitialBalanceOfPD,InitialBalanceOfTD,InitialBalanceOffBalanceSheet", "OpeningBalance");
		AddGroupOfColumns(ArrayOfOptionFields, DecryptionFields, "ReceivedQuantity,ReceivedCost,ReceivedPD,TDHasBeenReceived,ReceivedOffBalanceSheet", "Inflow");
		AddGroupOfColumns(ArrayOfOptionFields, DecryptionFields, "PurchasedQuantity_,PurchasedValue,PurchasedPD,AcquiredByTD,PurchasedOffBalanceSheet", "Purchased");
		AddGroupOfColumns(ArrayOfOptionFields, DecryptionFields, "MovementsQuantity,MovingCost,PDMovements,PDMovements,OffBalanceSheetTransfers", "Transfers");
		AddGroupOfColumns(ArrayOfOptionFields, DecryptionFields, "InclusionExclusionOfVAT", "InclusionExclusionOfVAT");
		AddGroupOfColumns(ArrayOfOptionFields, DecryptionFields, "QuantityTransmitted,TransferredCost,SubmittedByPD,SubmittedByTD,PassedOffBalanceSheet", "TransfersToWarehouse");
		AddGroupOfColumns(ArrayOfOptionFields, DecryptionFields, "ProductionCostsQuantity,ProductionCostsCost,CostOfProductionPD,CostOfProductionOfTD, ProductionCostsOffBalanceSheet", "Costs_Production");
		AddGroupOfColumns(ArrayOfOptionFields, DecryptionFields, "AmountSpentOnProduction,SpentOnProductionCost,SpentOnProductionOfPD,SpentOnProductionOfTD, SpentOnProductionOffBalanceSheet", "ConsumedForProductionBatches");
		AddGroupOfColumns(ArrayOfOptionFields, DecryptionFields, "DebitedQuantity,DebitedCost,WrittenOffPD,TDWasWrittenOff,WrittenOffOffBalanceSheet", "WriteOffsForExpenses");
		AddGroupOfColumns(ArrayOfOptionFields, DecryptionFields, "FinalRemainderQuantity,FinalRemainderCost,FinalBalanceOfPD,FinalBalanceOfTD,FinalBalanceIsOffBalance", "ClosingBalance");
		AddGroupOfColumns(ArrayOfOptionFields, DecryptionFields, "ProducedQuantity,ProducedCost,ProducedByPD,ProducedByTD,ProducedOffBalanceSheet", "Manufactured");
		
		ReportDetailsData = DataCompositionServerCall.ExplanationFormParameters(
												Details,
												ThisForm.ReportDetailsData,
												ParametersList,
												DecryptionFields);
		
		If ReportDetailsData = Undefined Then
			Return;
		EndIf;
		
		ReportVariant = Undefined;
		
		For Each Variant In ArrayOfOptionFields Do
			For Each DecryptionField In Variant.Fields Do
				If ReportDetailsData.Property(DecryptionField) Then
					ReportVariant = Variant.ReportVariant;
					Break;
				EndIf;
			EndDo;
			If ValueIsFilled(ReportVariant) Then
				Break;
			EndIf;
		EndDo;
		
		DivisionOverrideIsRequired = False;
		DoNotOverrideUserParameters = False;
		Filter = New Structure;
		UserParameters = New Array;
		If ReportDetailsData.Property("MovementOfMaterialsAndProducts")
			Or FullReportName = "Report.ProductionMaterialCost" Then
			
			ReportName = "Report.ProductionMaterialCost.Form";
			
			If Not ValueIsFilled(ReportVariant) Then
				
				If StrFind(CurrentVariantKey, "ByEnterprise") = 0 Then
					
					ReportVariant = "MovementOfMaterialsProductsWorks";
					If ReportDetailsData.Property("Organization") Then
						Filter.Insert("Organization", ReportDetailsData.Organization);
					EndIf;
					
				Else
					ReportVariant = "MovementOfMaterialsProductsWorksOnEnterprise";
				EndIf;
				
				DoNotOverrideUserParameters = True;
				
			EndIf;
			
		ElsIf ReportDetailsData.Property("MovementOfItemizedExpenses")
			Or FullReportName = "Report.ItemizedProductionCosts" Then
			
			ReportName = "Report.ItemizedProductionCosts.Form";
			
			If Not ValueIsFilled(ReportVariant) Then
				
				If StrFind(CurrentVariantKey, "ByEnterprise") = 0 Then
					
					ReportVariant = "MovementOfItemizedExpenses";
					If ReportDetailsData.Property("Organization") Then
						Filter.Insert("Organization", ReportDetailsData.Organization);
					EndIf;
					
				Else
					ReportVariant = "MovementOfItemizedExpensesByEnterprise";
				EndIf;
				
				DoNotOverrideUserParameters = True;
				
			EndIf;
			
		ElsIf ReportDetailsData.Property("AllocationOfCostsByProductionBatches")
			Or FullReportName = "Report.ProductionCostsByProductionLots" Then
			
			ReportName = "Report.ProductionCostsByProductionLots.Form";
			
			If Not ValueIsFilled(ReportVariant) Then
				
				If StrFind(CurrentVariantKey, "ByEnterprise") = 0 Then
					
					ReportVariant = "AllocationOfCostsByProductionBatches";
					If ReportDetailsData.Property("Organization") Then
						Filter.Insert("Organization", ReportDetailsData.Organization);
					EndIf;
					
				Else
					ReportVariant = "DistributionOfCostsForProductionBatchesByEnterprise";
				EndIf;
				
				DoNotOverrideUserParameters = True;
				
			EndIf;
			
		ElsIf ReportDetailsData.Property("CostGroupingByProductionBatches")
			Or FullReportName = "Report.ProductionCostsByProductionLots" Then
			
			ReportName = "Report.ProductionCostsByProductionLots.Form";
			
			If Not ValueIsFilled(ReportVariant) Then
				
				DoNotOverrideUserParameters = True;
				If StrFind(CurrentVariantKey, "ByEnterprise") = 0 Then
					
					ReportVariant = "CostGroupingByProductionBatches";
					If ReportDetailsData.Property("Organization") Then
						Filter.Insert("Organization", ReportDetailsData.Organization);
					EndIf;
					
				Else
					ReportVariant = "GroupingOfCostsByProductionBatchesByEnterprise";
				EndIf;
				
			EndIf;
			
			DivisionOverrideIsRequired = True;
			
		Else
			Return;
		EndIf;
		
		If Not ValueIsFilled(ReportVariant) Then
			Return;
		EndIf;
		
		FormParameters = New Structure;
		FormParameters.Insert("VariantKey",                   ReportVariant);
		FormParameters.Insert("GenerateOnOpen",        True);
		
		If DoNotOverrideUserParameters Then
			CustomSetting = New Structure("Name, Value", "Cost_Data", ReportDetailsData.Cost_Data);
			UserParameters.Add(CustomSetting);
			If ReportDetailsData.Property("Period") And ValueIsFilled(ReportDetailsData.Period) Then
				CustomSetting = New Structure("Name, Value", "Period", ReportDetailsData.Period);
				UserParameters.Add(CustomSetting);
			EndIf;
		Else
			Filter.Insert("Cost_Data", ReportDetailsData.Cost_Data);
			If ReportDetailsData.Property("Period") And ValueIsFilled(ReportDetailsData.Period) Then
				Filter.Insert("Period", ReportDetailsData.Period);
			EndIf;
		EndIf;
		
		For Each GroupingField In GroupFields Do
			If ReportDetailsData.Property(GroupingField) And ValueIsFilled(ReportDetailsData[GroupingField]) Then
				Filter.Insert(GroupingField,ReportDetailsData[GroupingField]);
			EndIf;
		EndDo;
		
		FormParameters.Insert("Filter", Filter);
		FormParameters.Insert("UserParameters", UserParameters);
		FormParameters.Insert("SettingsSource_", ReportDetailsData);
		OpenForm(ReportName, FormParameters, ThisForm, True);
	
	ElsIf FullReportName = "Report.LotsInProduction" Then
		
		ReportMenu 			= New Array;
		ActionMenu 			= New Array;
		DecryptionFields 		= New Array;
		ReportParameters			= New Structure;
		ActionParameters 		= New Structure;
		DetailsParameters 	= New Structure;
		
		StandardProcessing = False;
		DecryptionFields.Add("ProductionLot");
		
		ReportParameters.Insert("Name", "ControlOfMovementOfProductsAndMaterialsAtProductionStage");
		ReportParameters.Insert("Title", NStr("vi = 'Kiểm soát sự lưu chuyển của sản phẩm và nguyên liệu trên một lô sản xuất';
												|ru = 'Контроль движения продукции и материалов по партии производства';
												|en = 'Control movement of manufactured products and materials by production lot'; fa = 'Control movement of manufactured products and materials by production lot';
												|it = 'Controllo del movimento della produzione e dei materiali sul lotto di produzione';
												|pl = 'Kontrola ruchów produkcji i materiałów wg partii produkcji';
												|tr = 'Üretim lotuna göre imal edilen ürün ve malzeme hareketinin kontrolü'"));
		ReportParameters.Insert("ReportName", "Report.ControlOfProductsAndMaterialFlowOnProductionStage");
		ReportParameters.Insert("DecryptionFields", DecryptionFields);
		
		ReportMenu.Add(ReportParameters);
		
		ActionParameters.Insert("Name", "SupplyState");
		ActionParameters.Insert("Title", NStr("vi = 'Trạng thái đảm bảo';
												|ru = 'Состояние обеспечения';
												|en = 'Supply forecast'; fa = 'پیش‌بینی تأمین';
												|it = 'Stato di approvvigionamento';
												|pl = 'Status zaopatrzenia';
												|tr = 'tedarik durumu'"));
		ActionParameters.Insert("Action", "OpenForm");
		ActionParameters.Insert("FormName", "DataProcessor.OrderSupplyForecast.Form");
		
		DecryptionFields = New Array;
		DecryptionFields.Add("ProductionStage");
		
		ParametersList = New Array;
		ParametersList.Add("ProductionStage");
		
		ReportDetailsData = DataCompositionServerCall.ExplanationFormParameters(
			Details,
			ThisForm.ReportDetailsData,
			ParametersList,
			DecryptionFields);
		
		FormParameters = ProvisionInDocumentsClient.OrderSecurityStateFormParameters("ORDERLIST");
		FormParameters.Orders = CommonClientServer.ValueInArray(ReportDetailsData.ProductionStage);
		ActionParameters.Insert("FormParameters", FormParameters);
		
		ActionMenu.Add(ActionParameters);
		
		DetailsParameters.Insert("ReportMenu", ReportMenu);
		DetailsParameters.Insert("ActionMenu", ActionMenu);
		DetailsParameters.Insert("Details", Details);
		
		DataCompositionClient.DecryptionProcessingWithAdditionalMenu(ThisForm, DetailsParameters, StandardProcessing);
	
	ElsIf FullReportName = "Report.OrderCompleteness" Then 
		
		If CurrentVariantKey = "ForAllOrders" Then
			
			FormParameters = New Structure;
			FormParameters.Insert("VariantKey",                     "ByOrder");
			FormParameters.Insert("GenerateOnOpen",          True);
			FormParameters.Insert("ReportOptionsCommandsVisibility",  False);
			FormParameters.Insert("DetailsMode",                 False);
			
			ParametersList = New Array;
			ParametersList.Add("EndDate");

			DecryptionFields = New Array;
			DecryptionFields.Add("ProductionOrder");
			
			ReportDetailsData = DataCompositionServerCall.ExplanationFormParameters(
				Details, ThisForm.ReportDetailsData, ParametersList, DecryptionFields);
			
			Filter = New Structure();
			
			If ReportDetailsData <> Undefined
				And ReportDetailsData.Property("ProductionOrder") Then
				
				StandardProcessing = False;
				
				Filter.Insert("ProductionOrder", ReportDetailsData.ProductionOrder);
				FormParameters.Insert("Filter", Filter);
				
				FormParameters.Insert("EndDate", 
					?(ReportDetailsData.Property("EndDate"),
						ReportDetailsData.EndDate,
						'00010101'));
				
				OpenForm("Report.OrderCompleteness.Form", FormParameters, ThisForm, True);
				
			EndIf;
		
		ElsIf CurrentVariantKey = "ByOrder" Or CurrentVariantKey = "RemainingGoodsByShelfLives" Then
			
			ActionMenu         = New Array;
			ReportMenu          = New Array;
			DetailsParameters = New Structure;
			
			// By security sources
			ReportParameters = New Structure;
			ReportParameters.Insert("Name", "BySourcesAndDatesContext");
			ReportParameters.Insert("Title", NStr("vi = 'Theo nguồn và ngày đảm bảo';
													|ru = 'По источникам и датам обеспечения';
													|en = 'By sources and supply dates'; fa = 'By sources and supply dates';
													|it = 'Per fonti e dati di fornitura';
													|pl = 'Według źródeł i dat zaopatrzenia';
													|tr = 'Kaynak ve temin tarihine göre'"));
			ReportParameters.Insert("ReportName", "Report.OrderCompleteness");
			
			DecryptionFields = New Array;
			DecryptionFields.Add("Products");
			DecryptionFields.Add("Characteristic");
			DecryptionFields.Add("ProductionOrder");
			DecryptionFields.Add("Warehouse");
			DecryptionFields.Add("Purpose");
			ReportParameters.Insert("DecryptionFields", DecryptionFields);
			
			ReportMenu.Add(ReportParameters);
			
			// By nomenclature / by order
			If CurrentVariantKey = "ByOrder" Then
				ReportParameters = New Structure;
				ReportParameters.Insert("Name", "RemainingGoodsByShelfLives");
				ReportParameters.Insert("Title", NStr("vi = 'Theo tất cả đơn hàng';
														|ru = 'По всем заказам';
														|en = 'By all orders'; fa = 'By all orders';
														|it = 'Per tutti gli ordini';
														|pl = 'Według wszystkich zamówień';
														|tr = 'Tüm siparişlere göre'"));
				ReportParameters.Insert("ReportName", "Report.OrderCompleteness");
				
				DecryptionFields = New Array;
				DecryptionFields.Add("Products");
				DecryptionFields.Add("Characteristic");
				ReportParameters.Insert("DecryptionFields", DecryptionFields);
				
				ParametersList = New Array;
				ParametersList.Add("EndDate");
				ReportParameters.Insert("ParametersList", ParametersList);
			Else
				ReportParameters = New Structure;
				ReportParameters.Insert("Name", "ByOrder");
				ReportParameters.Insert("Title", NStr("vi = 'Hoàn thiện đơn hàng hiện tại';
														|ru = 'Укомплектованность текущего заказа';
														|en = 'Current order completeness'; fa = 'Current order completeness';
														|it = 'Assegnazione personale all''ordine corrente';
														|pl = 'Kompletność bieżącego zamówienia';
														|tr = 'Mevcut siparişin tamamlanması'"));
				ReportParameters.Insert("ReportName", "Report.OrderCompleteness");
				
				DecryptionFields = New Array;
				DecryptionFields.Add("ProductionOrder");
				ReportParameters.Insert("DecryptionFields", DecryptionFields);
				
				ParametersList = New Array;
				ParametersList.Add("EndDate");
				ReportParameters.Insert("ParametersList", ParametersList);
			EndIf;
			ReportMenu.Add(ReportParameters);
			
			DetailsParameters.Insert("ReportMenu", ReportMenu);
			DetailsParameters.Insert("ActionMenu", ActionMenu);
			DetailsParameters.Insert("Details", Details);
				
			DataCompositionClient.DecryptionProcessingWithAdditionalMenu(ThisForm, DetailsParameters, StandardProcessing);
			
		EndIf;
		
	ElsIf FullReportName = "Report.ItemPlanItemDrillDown" Then
		
		ParametersList = New Array;
		ParametersList.Add("LineOfBusiness");
		ParametersList.Add("ProductionOrder");
		ParametersList.Add("BillOfMaterials");
		ParametersList.Add("Products");
		ParametersList.Add("Characteristic");
		
		DecryptionFields = New Array;
		DecryptionFields.Add("Required2");
		DecryptionFields.Add("AvailableStock");
		DecryptionFields.Add("ProductsInStockToOrder");
		DecryptionFields.Add("Substitutes");
		
		ReportDetailsData = DataCompositionServerCall.ExplanationFormParameters(
				Details, ThisForm.ReportDetailsData, ParametersList, DecryptionFields);
		
		DecryptionWithAdditionalMenu = False;
			
		If ReportDetailsData.Property("Required2")
		 Or ReportDetailsData.Property("AvailableStock")
		 Or ReportDetailsData.Property("ProductsInStockToOrder") Then
			
			DecryptionWithAdditionalMenu = True;
			
			DetailsParameters = New Structure;
			
			ReportMenu  = New Array;
			ActionMenu = New Array;
			
			// Decipher the report -> "Balances and availability of goods"
			ReportParameters = New Structure;
			ReportParameters.Insert("Name",       "ByProductContext");
			ReportParameters.Insert("Title", NStr("vi = 'Số dư và tính khả dụng của hàng hóa';
													|ru = 'Остатки и доступность товаров';
													|en = 'Stock availability'; fa = 'دسترس‌پذیری موجودی';
													|it = 'Giacenze e disponibilità delle merci';
													|pl = 'Ostatki i dostępność towarów';
													|tr = 'Ürün bakiyeleri ve kullanılabilirlikleri'"));
			ReportParameters.Insert("ReportName", "Report.StockAvailability");
			
			DecryptionFields = New Array;
			DecryptionFields.Add("Products");
			DecryptionFields.Add("Characteristic");
			ReportParameters.Insert("DecryptionFields", DecryptionFields);
			
			FixedParameters = New Structure;
			FixedParameters.Insert("ShowSeparateProducts", True);
			ReportParameters.Insert("FixedParameters", FixedParameters);
			
			ReportMenu.Add(ReportParameters);
			
		ElsIf ReportDetailsData.Property("Substitutes") Then
			
			DecryptionWithAdditionalMenu = True;
			
			DetailsParameters = New Structure;
			
			ReportMenu  = New Array;
			ActionMenu = New Array;
			
			// Decipher the form of the document "Permission to replace materials" -> "Replacement of materials with analogues"
			ActionParameters = New Structure;
			ActionParameters.Insert("Name",             "SubstitutionOfMaterialsWithAlternativeMaterials");
			ActionParameters.Insert("Title",       NStr("vi = 'Mặt hàng tương tự';
														|ru = 'Аналоги';
														|en = 'Substitutes'; fa = 'جایگزین‌ها';
														|it = 'Аналоги';
														|pl = 'Substitutes';
														|tr = 'İkameler'"));
			ActionParameters.Insert("CommonModuleName", "ReportsERPClientOverridable");
			
			ParameterData = New Structure;
			ParameterData.Insert("LineOfBusiness", ReportDetailsData.LineOfBusiness);
			ParameterData.Insert("ProductionOrder",     ReportDetailsData.ProductionOrder);
			ParameterData.Insert("BillOfMaterials",            ReportDetailsData.BillOfMaterials);
			ParameterData.Insert("Product",                 ReportDetailsData.Products);
			ParameterData.Insert("ItemVariantOfProduct",   ReportDetailsData.Characteristic);
			ActionParameters.Insert("ParameterData", ParameterData);
			
			DecryptionFields = New Array;
			DecryptionFields.Add("LineNumber");
			DecryptionFields.Add("Stage");
			DecryptionFields.Add("StageSubdivision");
			DecryptionFields.Add("Products");
			DecryptionFields.Add("Characteristic");
			DecryptionFields.Add("Purpose");
			DecryptionFields.Add("WithAssignment");
			DecryptionFields.Add("Warehouse");
			DecryptionFields.Add("Substitutes");
			ActionParameters.Insert("DecryptionFields", DecryptionFields);
			
			ActionMenu.Add(ActionParameters);
			
		EndIf;
		
		If DecryptionWithAdditionalMenu Then
			
			DetailsParameters.Insert("ReportMenu",  ReportMenu);
			DetailsParameters.Insert("ActionMenu", ActionMenu);
			DetailsParameters.Insert("Details",  Details);
			
			DataCompositionClient.DecryptionProcessingWithAdditionalMenu(
				ThisForm, DetailsParameters, StandardProcessing);
			
		EndIf;
		
	ElsIf FullReportName = "Report.ControlOfProductionByOrder" Then
		
		ReportMenu  = New Array;
		ActionMenu = New Array;
		
		//Balances and availability of goods
		ReportParameters = New Structure;
		ReportParameters.Insert("Name",       "ByProductContext");
		ReportParameters.Insert("Title", NStr("vi = 'Số dư và tính khả dụng của hàng hóa';
												|ru = 'Остатки и доступность товаров';
												|en = 'Stock availability'; fa = 'دسترس‌پذیری موجودی';
												|it = 'Giacenze e disponibilità delle merci';
												|pl = 'Ostatki i dostępność towarów';
												|tr = 'Ürün bakiyeleri ve kullanılabilirlikleri'"));
		ReportParameters.Insert("ReportName", "Report.StockAvailability");
		
		ParametersList = New Array;
		ReportParameters.Insert("ParametersList", ParametersList);
		
		DecryptionFields  = New Array;
		DecryptionFields.Add("Products");
		DecryptionFields.Add("Characteristic");
		ReportParameters.Insert("DecryptionFields", DecryptionFields);
		
		FixedParameters = New Structure;
		FixedParameters.Insert("ShowSeparateProducts", True);
		ReportParameters.Insert("FixedParameters", FixedParameters);
		
		ReplacingParameters = New Structure;
		ReplacingParameters.Insert("ProductionOrder", Undefined);
		ReportParameters.Insert("ReplacingParameters", ReplacingParameters);
		
		ReportMenu.Add(ReportParameters);
		
		If CurrentVariantKey = "ProductionControl" Then
			
			//Launch Parties
			ParametersList = New Array;
			DecryptionFields  = New Array;
			DecryptionFields.Add("Products");
			DecryptionFields.Add("Characteristic");
			DecryptionFields.Add("Purpose");
			
			ReportData = DataCompositionServerCall.ExplanationFormParameters(
				Details,
				ThisForm.ReportDetailsData,
				ParametersList,
				DecryptionFields);
			
			If Not ReportData.Property("Purpose") Then
				
				ReportParameters = New Structure;
				ReportParameters.Insert("Name", "LaunchParties");
				ReportParameters.Insert("Title", NStr("vi = 'Lô xuất xưởng';
														|ru = 'Партии запуска';
														|en = 'Release lots'; fa = 'Release lots';
														|it = 'Release lots';
														|pl = 'Release lots';
														|tr = 'Başlatma lotları'"));
				ReportParameters.Insert("ReportName", "Report.DrillDownProductionOrderControlByReleaseLots");
				
				ParametersList = New Array;
				ParametersList.Add("ProductionOrder");
				ReportParameters.Insert("ParametersList", ParametersList);
				
				ReportSettings = ThisForm.ReportSettings.ResultProperties.FinalSettings;
				ShowSideIssue = DataCompositionClientServer.GetParameter(ReportSettings, "ShowSideIssue");
				FixedParameters = New Structure;
				FixedParameters.Insert("ShowSideIssue", ShowSideIssue.Value);
				ReportParameters.Insert("FixedParameters", FixedParameters);
				
				ReportParameters.Insert("DecryptionFields", DecryptionFields);
				
				ReportMenu.Add(ReportParameters);
				
			EndIf;
		
		EndIf;
		
		DetailsParameters = New Structure;
		DetailsParameters.Insert("ReportMenu",  ReportMenu);
		DetailsParameters.Insert("ActionMenu", ActionMenu);
		DetailsParameters.Insert("Details",  Details);
		
		DataCompositionClient.DecryptionProcessingWithAdditionalMenu(ThisForm, DetailsParameters, StandardProcessing);
		
	ElsIf FullReportName = "Report.DrillDownProductionOrderControlByReleaseLots" Then
		
		StandardProcessing = False;
		SettingsSource = New DataCompositionAvailableSettingsSource(ThisForm.Report);
		DetailProcessing = New DataCompositionDetailsProcess(ThisForm.ReportDetailsData, SettingsSource);
		
		ChosenAction = Undefined;
		ChosenActionParameter = Undefined;
		
		AvailableAction = New Array;
		AvailableAction.Add(DataCompositionDetailsProcessingAction.OpenValue);
		
		ActionParameters = New Structure("ThisForm", ThisForm);
		CallbackDescription = New CallbackDescription("DetailProcessingCompletion", ReportsTMClientOverridable, ActionParameters);
		DetailProcessing.ShowActionChoice(CallbackDescription, Details, AvailableAction);
	EndIf;
	FinancialAccountingClient.DetailProcessing(ThisForm, Item, Details, StandardProcessing);
EndProcedure

// Handler for additional decryption (menu of the table document of the report form).
//
// Parameters:
//   ThisForm - ClientApplicationForm - report form.
//   Item     - FormField        - table document.
//   Details - Arbitrary     - the value of the decoding point, series, or chart value.
//   StandardProcessing - Boolean  - indicates whether standard (system) event processing is performed.
//
Procedure AdditionalDetailProcessing(ThisForm, Item, Details, StandardProcessing) Export
	
	FullReportName = ThisForm.ReportSettings.FullName;
	CurrentVariantKey = ThisForm.CurrentVariantKey;
	
	If FullReportName = "Report.КлассификацияВыручкиПоОКВЭД" Then
		
		StandardProcessing = False;
		
	
	EndIf;
	FinancialAccountingClient.DetailProcessing(ThisForm, Item, Details, StandardProcessing);
EndProcedure

// Handler for dynamically added commands.
//
// Parameters:
//   ThisForm - ClientApplicationForm - report form.
//   Command - FormCommand - the command that was called.
//   Result - Boolean - True if the command call was processed.
//
Procedure HandlerCommands(ThisForm, Command, Result) Export
	
	FullReportName = ThisForm.ReportSettings.FullName;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Report", FullReportName);
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command, AdditionalParameters); 
	FinancialAccountingClient.HandlerCommands(ThisForm, Command, Result);
EndProcedure

// Handler for the result of selecting a subordinate form.
//
// Parameters:
//   ThisForm       - ClientApplicationForm - report form.
//   ValueSelected - Arbitrary     - the result of the selection in the subordinate form.
//   ChoiceSource    - ClientApplicationForm - the form where the selection was made.
//   Result         - Boolean           - True if the selection result is processed.
//
Procedure ChoiceProcessing(ThisForm, ValueSelected, ChoiceSource, Result) Export
	
EndProcedure

// Notification handler for the report form.
//
// Parameters:
//   ThisForm - ClientApplicationForm - report form.
//   EventName  - String           - event ID for receiving forms.
//   Parameter    - Arbitrary     - extended information about the event.
//   Source    - ClientApplicationForm
//               - Arbitrary - the source of the event.
//   The notification is processed - Boolean - a sign that the event has been processed.
//
Procedure NotificationProcessing(ThisForm, EventName, Parameter, Source) Export
	
	
EndProcedure
 
// Handler for special actions when decrypting reports.
// For example, opening specialized forms with parameterization.
//
//	Parameters:
//		ActionParameters - Structure
//			Name-String - Name of the action to be performed
//			Header-String - Custom representation of the action being performed
//		DetailsParameters - Structure - Parameters passed to the form.
//
Procedure PerformDecryptionAction(ActionParameters, DetailsParameters) Export
	If ActionParameters.Name = "ChangeAvailabilityOfRCView" Then
		
		ProductionPlanningClient.ChangeAvailabilityOfRCView(
					DetailsParameters.WorkCenterType, 
					DetailsParameters.SchedulePeriod);
		
	ElsIf ActionParameters.Name = "SubstitutionOfMaterialsWithAlternativeMaterials" Then
		
		AnalogSelectionParameters = 
			ReportsERPServerCallOverridable.DecryptionParametersDecryptionOfItemOfNomenclaturePlanForAnalogues(
				ActionParameters, DetailsParameters);
		
		AlternativeMaterialsClient.OpenSelectionOfAnalogues(AnalogSelectionParameters, Undefined);
		
	Else
		Raise StringFunctionsClientServer.SubstituteParametersToString(
										NStr("vi = 'Trình xử lý không xác định %1.';
											|ru = 'Не определен обработчик действия %1.';
											|en = '%1 action handler is not determined.'; fa = '%1 action handler is not determined.';
											|it = 'Non è definito un elaboratore dell''azione %1.';
											|pl = 'Nie jest określony program przetwarzania czynności %1.';
											|tr = '%1 eyleminin işleyicisi tanımlanmadı.'"),
										ActionParameters.Title);
	EndIf;
EndProcedure

// The method is called from the report form after it is generated.
//
//	Parameters:
//		ReportForm - ClientApplicationForm - report form.
//
Procedure AfterGenerationOnClient(ReportForm) Export
	
	AuxProperties = ReportForm.Report.SettingsComposer.UserSettings.AdditionalProperties;
	WaitHandlerIsRequired = False;
	ParameterName = "TradeManagement.ParametersForCheckingBackgroundTasks";
	If ApplicationParameters[ParameterName] = Undefined Then
		ApplicationParameters.Insert(ParameterName, New Structure);
		ApplicationParameters[ParameterName].Insert("Jobs", New Structure());
		ApplicationParameters[ParameterName].Insert("Interval", 7);
	EndIf;
	If AuxProperties.Property("NumberOfDocumentsToBeReflectedInBudgeting") Then
		WaitHandlerIsRequired = True;
		If Not ApplicationParameters[ParameterName].Jobs.Property("DocumentPostingInBudgeting") Then
			CurCallParameters = New Structure("BeginOfPeriod, EndOfPeriod", AuxProperties.BeginOfPeriod, AuxProperties.EndOfPeriod);
			JobParameters = New Structure("Parameters, Forms", CurCallParameters, New Map());
			ApplicationParameters[ParameterName].Jobs.Insert("DocumentPostingInBudgeting", JobParameters);
		EndIf;
		JobParameters = ApplicationParameters[ParameterName].Jobs.DocumentPostingInBudgeting.Forms;
		FormParameters = New Structure("BeginOfPeriod, EndOfPeriod", AuxProperties.BeginOfPeriod, AuxProperties.EndOfPeriod);
		JobParameters.Insert(ReportForm, FormParameters);
	ElsIf AuxProperties.Property("NumberOfDocumentsToReflectLimitsBasedOnBudgetingData") Then
		WaitHandlerIsRequired = True;
		If Not ApplicationParameters[ParameterName].Jobs.Property("ControlFlow_TasksForReflectingLimitsBasedOnBudgetingData") Then
			JobParameters = New Structure("Parameters, Forms", New Structure(), New Map());
			ApplicationParameters[ParameterName].Jobs.Insert("ControlFlow_TasksForReflectingLimitsBasedOnBudgetingData", JobParameters);
		EndIf;
		JobParameters = ApplicationParameters[ParameterName].Jobs.ControlFlow_TasksForReflectingLimitsBasedOnBudgetingData.Forms;
		JobParameters.Insert(ReportForm, New Structure());
	EndIf;
	If WaitHandlerIsRequired Then
		ReportForm.AttachIdleHandler("CheckBackgroundJobs", ApplicationParameters[ParameterName].Interval, True);
	EndIf;
	
EndProcedure

// The method is called from the report form after it is generated.
//
//	Parameters:
//		Response - DialogReturnCode - If the "Yes" option is selected, the forms will be re-formed
//		ExecutionParameters - Structure - Contains a list of forms that need to be re-formed.
//
Procedure ReportFormAfterConfirmationOfReformulation(Response, ExecutionParameters) Export
	Var RawForms;
	If Response <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	For Each ReportForm In ExecutionParameters.Forms Do
		ReportForm.AttachIdleHandler("Generate", 1, True);
	EndDo;
	If ExecutionParameters.Property("RawForms", RawForms) Then
		TimeIntervals = New Array;
		For Each KeyAndValue In RawForms Do
			TimeIntervals.Add(KeyAndValue.Value.BeginOfPeriod);
			TimeIntervals.Add(KeyAndValue.Value.EndOfPeriod);
		EndDo;
		BudgetReportingServerCall.ReflectDocumentsAsBackgroundTaskOnFormWithMaximumPeriod(TimeIntervals);
		For Each KeyAndValue In RawForms Do
			AfterGenerationOnClient(KeyAndValue.Key);
		EndDo;
	EndIf;
EndProcedure

// Occurs after the report is generated.
//
// Parameters:
//   ReportForm - ClientApplicationForm - report form.
//   ReportCreated - Boolean - True if the report was generated successfully.
//
Procedure AfterGenerate(ReportForm, ReportCreated) Export
	AfterGenerationOnClient(ReportForm);
EndProcedure

// Handler for double-clicking, pressing the Enter key, or hyperlinks in a tabular document of a report form.
// See "Form field extension for a tabular document field.Choice" in the syntax assistant.
//
// Parameters:
//   ReportForm - ClientApplicationForm - report form.
//   Item     - FormField        - table document.
//   Area     - SpreadsheetDocumentRange - selected value.
//   StandardProcessing - Boolean - indicates whether standard event processing is being performed.
//
Procedure SpreadsheetDocumentSelectionHandler(ReportForm, Item, Area, StandardProcessing) Export
	
	FullReportName = ReportForm.ReportSettings.FullName;
	
	If FullReportName = "Report.BudgetingTurnoverBalanceReport"
		Or FullReportName = "Report.TrialBalanceForBudgetBalanceItems"
		Or FullReportName = "Report.CheckBudgetItemLinks"
		Or FullReportName = "Report.ResultOfActualDataQuery"
		Or FullReportName = "Report.DetailedCalculationOfBudgetTargets" Then
		
		If Area.Text = NStr("vi = 'Hiển thị';
							|ru = 'Отразить';
							|en = 'Record'; fa = 'ثبت';
							|it = 'Отразить';
							|pl = 'Record';
							|tr = 'Отразить'") Then
			
			Period = BudgetingClientServer.ValueOfDCSSettings(ReportForm.Report.SettingsComposer, "Period"); // StandardPeriod -
			BeginOfPeriod = Period.StartDate;
			EndOfPeriod = Period.EndDate;
			BudgetReportingServerCall.StartBackgroundTaskOfReflectionInBudgeting(BeginOfPeriod, EndOfPeriod);
			Area.Text = "";
			Area.Hyperlink = False;
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private


Procedure AddGroupOfColumns(ArrayOfOptionFields, SharedArrayOfFields, FieldsString, ReportVariant)
	
	Fields = StringFunctionsClientServer.SplitStringIntoSubstringsArray(FieldsString,",", True);
	CommonClientServer.SupplementArray(SharedArrayOfFields, Fields);
	
	FieldsStructure = New Structure;
	FieldsStructure.Insert("Fields", Fields);
	FieldsStructure.Insert("ReportVariant", ReportVariant);
	
	ArrayOfOptionFields.Add(FieldsStructure);
	
EndProcedure
#EndRegion 