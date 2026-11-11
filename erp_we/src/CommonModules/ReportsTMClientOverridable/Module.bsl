////////////////////////////////////////////////////////////////////////////////
// Report Options - UT Report Form (Client, redefined)
// 
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Handler for decoding a table document in a report form.
//
// Parameters:
//   ThisForm - ClientApplicationForm - report form.
//   Item     - FormField        - table document.
//   Details - Arbitrary     - the value of the decoding point, series, or chart value.
//   StandardProcessing - Boolean  - indicates whether standard (system) event processing is performed.
//
Procedure DetailProcessing(ThisForm, Item, Details, StandardProcessing) Export
	
	FullReportName = ThisForm.ReportSettings.FullName;
	CurrentVariantKey = ThisForm.CurrentVariantKey;
	
	ReportMenu  = New Array;
	ActionMenu = New Array;
		
	If FullReportName = "Report.TransferredReturnablePackagingList"
		Or FullReportName = "Report.ReceivedReturnablePackagingList" Then
		StandardProcessing = False;
		
		DetailProcessing = New DataCompositionDetailsProcess(
		ThisForm.ReportDetailsData, 
		New DataCompositionAvailableSettingsSource(ThisForm.Report));
		
		ChosenAction = Undefined;
		ChosenActionParameter = Undefined;
		
		AvailableAction = New Array;
		AvailableAction.Add(DataCompositionDetailsProcessingAction.OpenValue);
		
		ActionParameters = New Structure("ThisForm", ThisForm);
		CallbackDescription = New CallbackDescription("DetailProcessingCompletion", 
			ReportsTMClientOverridable, 
			ActionParameters);
		DetailProcessing.ShowActionChoice(CallbackDescription, Details, AvailableAction);
	ElsIf FullReportName = "Report.GoodsWithExpiringCertificates" Then
		
		StandardProcessing = False;
			
		DetailsStructure2 = ReportsTMServerCallOverridable.GenerateDecryptionData(Details, ThisForm.ReportDetailsData);
		
		If ValueIsFilled(DetailsStructure2.Products) Then
			OpenProductCertificatesReport(ThisForm.Report, DetailsStructure2);	
		EndIf;
		
	ElsIf FullReportName = "Report.FulfillmentAnalysisOfProductRange" Then
		
		ProductRangeClient.ProcessingOfDecryptionOfAssortmentExecution(ThisForm, Details, StandardProcessing);
		
	ElsIf FullReportName = "Report.ProductRangeAndSalesTrends" Then
		
		ProductRangeClient.ProcessingDecryptionOfComparativeAnalysisOfAssortment(ThisForm, Details, StandardProcessing);
		
	ElsIf FullReportName = "Report.AnalysisOfStockBalanceOfCompanies" Then	
		
		StandardProcessing = False;
		ProcessDecryptionAnalysisOfBalanceOfGoodsOfOrganizations(ThisForm, Details);
		
	ElsIf FullReportName = "Report.CompanyStockBalance" Then
		
		StandardProcessing = False;
		ProcessDecryptionAnalysisOfBalanceOfGoodsOfOrganizations(ThisForm, Details);
		
	ElsIf FullReportName = "Report.ItemsBatchStructure" Then
		
		ProcessDecodingStructureOfSeriesOfProducts(ThisForm, Details, StandardProcessing);
		
	ElsIf FullReportName = "Report.ApplicationOfItemBatch" Then
		
		ProcessTranscriptApplicationSeriesProducts(ThisForm, Details, StandardProcessing);
		
	ElsIf FullReportName = "Report.ItemsBatchList"
		And (CurrentVariantKey = "ItemsBatchList" 
			Or CurrentVariantKey = "StatementOfProductSeries") Then
			
		ProcessTranscriptOfStatementBySeriesOfProducts(ThisForm, Details, StandardProcessing);
		
	ElsIf FullReportName = "Report.BalanceSheetStatement" Then
		
		ProcessDecodingOfManagementBalanceSheet(ThisForm, Details, StandardProcessing);
		
	ElsIf FullReportName = "Report.SupplySchemeGoods" Then
		
		DecryptionFields = New Array;
		DecryptionFields.Add("Products");
		DecryptionFields.Add("Characteristic");
		DecryptionFields.Add("Warehouse");
		
		DetailsStructure2 = DataCompositionServerCall.ExplanationFormParameters(Details,
			ThisForm.ReportDetailsData, New Array, DecryptionFields);
		
		If DetailsStructure2.Property("Products") And DetailsStructure2.Property("Warehouse") Then
			StandardProcessing = False;
			
			FormParameters = New Structure;
			FormParameters.Insert("Source",		"SupplySchemeGoods");
			FormParameters.Insert("Products",	DetailsStructure2.Products);
			FormParameters.Insert("Warehouse",		DetailsStructure2.Warehouse);
			If DetailsStructure2.Property("Characteristic") Then
				FormParameters.Insert("Characteristic",	DetailsStructure2.Characteristic);
			EndIf;
			OpenForm("DataProcessor.SettingOfProcurementStrategies.Form.Form", FormParameters);
		EndIf;
		
	ElsIf FullReportName = "Report.CustomersARAPStatement" Then
		
		ReportParameters = New Structure;
		ReportParameters.Insert("Name", "Card");
		ReportParameters.Insert("Title", NStr("vi = 'Thẻ hạch toán với khách hàng';
												|ru = 'Карточка расчетов с клиентами';
												|en = 'Customer AR/AP breakdown'; fa = 'تفکیک دریافتنی/پرداختنی مشتری';
												|it = 'Scheda di regolamento dei conti con i clienti';
												|pl = 'Karta rozliczeń z klientami';
												|tr = 'Müşteri mutabakat kartı'"));
		ReportParameters.Insert("ReportName", "Report.CustomerARAPOpenItems24");
		
		DecryptionFields  = New Array;
		DecryptionFields.Add("Organization");
		DecryptionFields.Add("Currency");
		DecryptionFields.Add("Partner");
		DecryptionFields.Add("Contract");
		DecryptionFields.Add("ARAPObject");
		ReportParameters.Insert("DecryptionFields", DecryptionFields);
		
		ParametersList = New Array;
		ParametersList.Add("Period");
		ParametersList.Add("BeginOfPeriod");
		ParametersList.Add("EndOfPeriod");
		ParametersList.Add("ReportData");
		ReportParameters.Insert("ParametersList", ParametersList);
		
		ReportMenu.Add(ReportParameters);
		
	ElsIf FullReportName = "Report.VendorsARAPStatement" Then
		
		ReportParameters = New Structure;
		ReportParameters.Insert("Name", "Card");
		ReportParameters.Insert("Title", NStr("vi = 'Thẻ hạch toán với nhà cung cấp';
												|ru = 'Карточка расчетов с поставщиками';
												|en = 'Vendor AR/AP open items'; fa = 'اقلام باز دریافتنی/پرداختنی فروشنده';
												|it = 'Scheda di regolamento dei conti con i fornitori';
												|pl = 'Karta rozliczeń z dostawcami';
												|tr = 'Tedarikçi alacak/borç hesabı açık kalemler'"));
		ReportParameters.Insert("ReportName", "Report.VendorARAPOpenItems24");
		
		DecryptionFields  = New Array;
		DecryptionFields.Add("Organization");
		DecryptionFields.Add("Currency");
		DecryptionFields.Add("Partner");
		DecryptionFields.Add("Contract");
		DecryptionFields.Add("ARAPObject");
		ReportParameters.Insert("DecryptionFields", DecryptionFields);
		
		ParametersList = New Array;
		ParametersList.Add("Period");
		ParametersList.Add("BeginOfPeriod");
		ParametersList.Add("EndOfPeriod");
		ParametersList.Add("ReportData");
		ReportParameters.Insert("ParametersList", ParametersList);
		
		ReportMenu.Add(ReportParameters);
		
	ElsIf FullReportName = "Report.ControlOfInventoryTransferDocumentRegistration" 
		And TypeOf(Details) = Type("String") Then
		
		StandardProcessing = False;
		ProcessDecryptionControlOfRegistrationOfDocumentsOfCommodityMovement(ThisForm, Details);
		
	ElsIf FullReportName = "Report.DetailedCalculationOfDiscountingInterestExpenseWriteOff" Then
		
		StandardProcessing = False;		
		
		DetailsStructure2 = ReportsTMServerCallOverridable.GenerateDecryptionData(Details, ThisForm.ReportDetailsData);
		
		If DetailsStructure2.Property("ARAPDocument") And ValueIsFilled(DetailsStructure2.ARAPDocument) Then
			
			SettingsComposer = ThisForm.Report.SettingsComposer; // DataCompositionSettingsComposer - 
			FormParameters = New Structure("Filter, PurposeUseKey, VariantKey, GenerateOnOpen");
			FormParameters.GenerateOnOpen = True;
			FormParameters.VariantKey = "DecryptionByDocument";
			
			PeriodParameter = ThisForm.Report.SettingsComposer.Settings.DataParameters.FindParameterValue(New DataCompositionParameter("ReportPeriod"));
			IDOfPeriodParameter = ThisForm.Report.SettingsComposer.UserSettings.GetIDByObject(PeriodParameter);
			SettingUpPeriod = SettingsComposer.UserSettings.Items.Find(IDOfPeriodParameter);
			ReportDataParameter = ThisForm.Report.SettingsComposer.Settings.DataParameters.FindParameterValue(New DataCompositionParameter("ReportData"));
			IDOfReportDataParameter = ThisForm.Report.SettingsComposer.UserSettings.GetIDByObject(ReportDataParameter);
			ConfiguringReportData = SettingsComposer.UserSettings.Items.Find(IDOfReportDataParameter);
			
			Filter = New Structure();
			
			If ThisForm.Report.SettingsComposer.Settings.AdditionalProperties.VariantKey = "ContextOption_" Then
				If PeriodParameter.Use Then
					Filter.Insert("ReportPeriod", PeriodParameter.Value);
				EndIf;
				If ReportDataParameter.Use Then
					Filter.Insert("ReportData", ReportDataParameter.Value);
				EndIf;
			Else
				If SettingUpPeriod.Use Then
					Filter.Insert("ReportPeriod", SettingUpPeriod.Value);
				EndIf;
				If ConfiguringReportData.Use Then
					Filter.Insert("ReportData", ConfiguringReportData.Value);
				EndIf;
			EndIf;
			If DetailsStructure2.Property("ARAPObject") And ValueIsFilled(DetailsStructure2.ARAPObject) Then
				Filter.Insert("ARAPObject", DetailsStructure2.ARAPObject);
			EndIf;
			FormParameters.Filter = Filter;
			DocumentsArray = New Array;
			DocumentsArray.Add(DetailsStructure2.ARAPDocument);
			FormParameters.Insert("CommandParameter", DocumentsArray);
			
			OpenForm("Report.DetailedCalculationOfDiscountingInterestExpenseWriteOff.Form.DrillDownForm", FormParameters);
			
		EndIf;
	ElsIf FullReportName = "Report.DetailedCalculationOfDiscountingOfProvisionsAndContingentLiabilities" Then
		
		StandardProcessing = False;		
		
		DetailsStructure2 = ReportsTMServerCallOverridable.GenerateDecryptionData(Details, ThisForm.ReportDetailsData);
		
		If DetailsStructure2.Property("ProvisionObject") And ValueIsFilled(DetailsStructure2.ProvisionObject) Then
			
			FormParameters = New Structure;
			FormParameters.Insert("ProvisionObject", DetailsStructure2.ProvisionObject);
			
			PeriodParameter = ThisForm.Report.SettingsComposer.Settings.DataParameters.FindParameterValue(New DataCompositionParameter("Period"));
			FormParameters.Insert("Period", PeriodParameter.Value);
						
			LoggerParameter = DataCompositionClientServer.GetParameter(ThisForm.Report.SettingsComposer.Settings, "Recorder");
			
			If LoggerParameter.Value = Undefined Then
				LoggerParameter = DataCompositionClientServer.GetParameter(ThisForm.Report.SettingsComposer.UserSettings, "Recorder");				
			EndIf;
			
			If LoggerParameter <> Undefined Then
				FormParameters.Insert("Recorder", LoggerParameter.Value);				
			EndIf;
			
			FormParameters.Insert("GenerateOnOpen", True);
			
			OpenForm("Report.DetailedCalculationProvisionDiscountingInterestOfFutureExpenseCommitments.ObjectForm", FormParameters);
			
		EndIf;
		
	EndIf;
	
	RebatesClient.DetailProcessing(
		ThisForm,
		Item,
		Details,
		StandardProcessing,
		ReportMenu,
		ActionMenu);
	
	If ReportMenu.Count() > 0 Or ActionMenu.Count() > 0 Then
		
		DetailsParameters = New Structure;
		DetailsParameters.Insert("ReportMenu",  ReportMenu);
		DetailsParameters.Insert("ActionMenu", ActionMenu);
		DetailsParameters.Insert("Details",  Details);
		
		DataCompositionClient.DecryptionProcessingWithAdditionalMenu(ThisForm, DetailsParameters, StandardProcessing);
		
	EndIf;
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
	
	ReportMenu  = New Array;
	ActionMenu = New Array;
	
	If FullReportName = "Report.BalanceSheetStatement" Then
		If CurrentVariantKey = "BalanceSheetStatement"
			Or CurrentVariantKey = "FinancialStateOfCompany" Then
			
			// Decipher the report -> Cost of sales
			#Region InventoryCost
			ReportParameters = New Structure;
			ReportParameters.Insert("Name", "InventoryCost");
			ReportParameters.Insert("Title", NStr("vi = 'Giá vốn hàng hóa';
													|ru = 'Себестоимость товаров';
													|en = 'Inventory cost'; fa = 'بهای موجودی';
													|it = 'Costo di produzione dei prodotti';
													|pl = 'Koszty własne towarów';
													|tr = 'Stok maliyeti'"));
			ReportParameters.Insert("ReportName", "Report.InventoryCost");
			
			DecryptionFields  = New Array;
			DecryptionFields.Add("Factor");
			ReportParameters.Insert("DecryptionFields", DecryptionFields);
			
			ReplacingParameters = New Structure;
			ReplacementParameters_ = New Map;
			
			ReplacingParameters.Insert("Factor", Undefined);
			ReplacingParameters.Insert("Factor_Parent", Undefined);
			ReplacingParameters.Insert("DynamicGroupingByAnalysisType", "CompanyStructure_Organization");
			ReportParameters.Insert("ReplacingParameters", ReplacingParameters);

			RequiredParameterValues = New Array;
			RequiredParameterValues.Add(PredefinedValue("ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceGoods"));
			RequiredParameters = New Structure;
			RequiredParameters.Insert("Factor", RequiredParameterValues);
			ReportParameters.Insert("RequiredParameters", RequiredParameters);
			
			ParametersList = New Array;
			ParametersList.Add("Period");
			ReportParameters.Insert("ParametersList", ParametersList);
			
			ReportMenu.Add(ReportParameters);		
			#EndRegion
		EndIf;
	ElsIf FullReportName = "Report.RevenueAndCOGS" Then
		// Decipher the report -> Cost of sales
		#Region InventoryCost
		ReportParameters = New Structure;
		If StrFind(CurrentVariantKey, "ByEnterprise") <> 0
		 Or CurrentVariantKey = "SalesSummary" Then
			ReportParameters.Insert("Name", "CostOfGoodsForEnterprise");
		Else
			ReportParameters.Insert("Name", "CostOfGoodsByOrganization");
		EndIf;
		ReportParameters.Insert("Title", NStr("vi = 'Giá vốn hàng hóa';
												|ru = 'Себестоимость товаров';
												|en = 'Inventory cost'; fa = 'بهای موجودی';
												|it = 'Costo di produzione dei prodotti';
												|pl = 'Koszty własne towarów';
												|tr = 'Stok maliyeti'"));
		ReportParameters.Insert("ReportName", "Report.InventoryCost");
		
		DecryptionFields  = New Array;
		DecryptionFields.Add("Organization");
		DecryptionFields.Add("Department");
		DecryptionFields.Add("Manager");
		DecryptionFields.Add("Warehouse");
		DecryptionFields.Add("Partner");
		DecryptionFields.Add("Products");
		DecryptionFields.Add("Characteristic");
		DecryptionFields.Add("Series");
		DecryptionFields.Add("BusinessOperation");
		DecryptionFields.Add("CostOfProductionTotal");
		DecryptionFields.Add("Cost_");
		DecryptionFields.Add("AddExpensesForGoods");
		ReportParameters.Insert("DecryptionFields", DecryptionFields);
		
		SufficientParameters = New Structure;
		SufficientParameters.Insert("CostOfProductionTotal");
		SufficientParameters.Insert("Cost_");
		SufficientParameters.Insert("AddExpensesForGoods");
		ReportParameters.Insert("SufficientParameters", SufficientParameters);
		
		ReplacingParameters = New Structure;
		ReplacementParameters_ = New Map;
		
		ReplacingParameters.Insert("Organization",		"CompanyStructure_Organization");
		ReplacingParameters.Insert("Department",		"TurnoverAnalytics_Division");
		ReplacingParameters.Insert("Manager",			"TurnoverAnalytics_Manager");
		ReplacingParameters.Insert("Warehouse",				"EnterpriseStructure_Warehouse");
		ReplacingParameters.Insert("Partner",			"TurnoverAnalytics_Partner");
		ReplacingParameters.Insert("Products",		"ProductAnalysis_Products");
		ReplacingParameters.Insert("Characteristic",		"ProductAnalysis_Characteristics");
		ReplacingParameters.Insert("Series",				"ProductAnalysis_Series");
		ReplacingParameters.Insert("CostOfProductionTotal", Undefined);
		ReplacingParameters.Insert("Cost_",		Undefined);
		ReplacingParameters.Insert("AddExpensesForGoods",			Undefined);
		
		ParameterValues = New Map;
		ParameterValues.Insert("TurnoverAnalytics_BusinessOperation", BusinessSalesOperations());
		ReplacementParameters_.Insert(0, ParameterValues); // All sales
		
		ParameterValues = New Map;
		ParameterValues.Insert("TurnoverAnalytics_BusinessOperation", BusinessSalesOperations(True));
		ReplacementParameters_.Insert(1, ParameterValues); // Except for sales between own legal entities
		
		ParameterValues = New Map;
		ParameterValues.Insert("TurnoverAnalytics_BusinessOperation", PredefinedValue("Catalog.BusinessTransactionsSettings.GoodsSaleToAnotherCompany"));
		ReplacementParameters_.Insert(2, ParameterValues); // Only sales between own legal entities
		
		ReplacingParameters.Insert("ShowSales_", ReplacementParameters_);
		
		ReportParameters.Insert("ReplacingParameters", ReplacingParameters);
		
		FixedParameters = New Structure;
		FixedParameters.Insert("TurnoverAnalytics_BusinessOperation_DataSource", "RevenueAndCOGS");
		ReportParameters.Insert("FixedParameters", FixedParameters);
		
		ParametersList = New Array;
		ParametersList.Add("Period");
		ParametersList.Add("ReportData");
		ParametersList.Add("QuantityUnits");
		ParametersList.Add("ShowSales_");
		ReportParameters.Insert("ParametersList", ParametersList);
		
		ReportMenu.Add(ReportParameters);
		#EndRegion
	ElsIf FullReportName = "Report.InventoryCost" Then
		// Decipher the report -> Statement of batches of goods
		#Region LotList
		ReportParameters = New Structure;
		If StrFind(CurrentVariantKey, "ByEnterprise") <> 0 Then
			ReportParameters.Insert("Name", "EnterpriseBatchList");
		Else
			ReportParameters.Insert("Name", "CompanyBatchList");
		EndIf;
		ReportParameters.Insert("Title", NStr("vi = 'Bảng kê theo lô hàng - chỉ đối với phương pháp FIFO (bình quân gia quyền)';
												|ru = 'Ведомость по партиям товаров - только при ФИФО(скользящая оценка)';
												|en = 'Lot list - only with FIFO (rolling valuation)'; fa = 'Lot list - only with FIFO (rolling valuation)';
												|it = 'Dichiarazione per lotti di merci - solo con FIFO (stima scorrevole)';
												|pl = 'Zestawienie wg partii towarów - tylko przy FIFO (ocena ruchoma)';
												|tr = 'Ürün lot tablosu- yalnızca FIFO (hareketli değerleme)'"));
		ReportParameters.Insert("ReportName", "Report.LotList");
		
		DecryptionFields  = New Array;
		DecryptionFields.Add("CompanyStructure_Organization");
		DecryptionFields.Add("TurnoverAnalytics_Division");
		DecryptionFields.Add("ProductAnalysis_Products");
		DecryptionFields.Add("ProductAnalysis_Characteristics");
		DecryptionFields.Add("ProductAnalysis_Series");
		DecryptionFields.Add("EnterpriseStructure_Warehouse");
		ReportParameters.Insert("DecryptionFields", DecryptionFields);
		
		ReplacingParameters = New Structure;
		ReplacementParameters_ = New Map;
		
		ReplacingParameters.Insert("CompanyStructure_Organization", "Organization");
		ReplacingParameters.Insert("TurnoverAnalytics_Division", "Department");
		ReplacingParameters.Insert("ProductAnalysis_Products", "Products");
		ReplacingParameters.Insert("ProductAnalysis_Characteristics", "Characteristic");
		ReplacingParameters.Insert("ProductAnalysis_Series", "Series");
		ReplacingParameters.Insert("EnterpriseStructure_Warehouse", "Warehouse");
		ReportParameters.Insert("ReplacingParameters", ReplacingParameters);
		
		ParametersList = New Array;
		ParametersList.Add("Period");
		ParametersList.Add("ReportData");
		ParametersList.Add("QuantityUnits");
		ReportParameters.Insert("ParametersList", ParametersList);
		
		ReportMenu.Add(ReportParameters);		
		#EndRegion
	ElsIf FullReportName = "Report.SupplySchemeGoods" Then
		#Region ChangingWayNeedsAreMet
		ActionParameters = New Structure;
		ActionParameters.Insert("Name", "ChangingWayNeedsAreMet");
		ActionParameters.Insert("Title", NStr("vi = 'Thay đổi cách đảm bảo nhu cầu';
												|ru = 'Изменить способ обеспечения потребностей';
												|en = 'Change the procurement strategy'; fa = 'Change the procurement strategy';
												|it = 'Modificare modalità di approvvigionamento fabbisogni';
												|pl = 'Zmień sposób zapewnienia zapotrzebowań';
												|tr = 'Tedarik stratejisini değiştir'"));
		ActionParameters.Insert("Action", "OpenForm");
		ActionParameters.Insert("FormName", "DataProcessor.SettingOfProcurementStrategies.Form.Form");
		
		DecryptionFields = New Array;
		DecryptionFields.Add("Products");
		DecryptionFields.Add("Characteristic");
		DecryptionFields.Add("Warehouse");
		ActionParameters.Insert("DecryptionFields", DecryptionFields);
		
		RequiredParameters = New Structure;
		RequiredParameters.Insert("Products");
		RequiredParameters.Insert("Warehouse");
		ActionParameters.Insert("RequiredParameters", RequiredParameters);
		
		FormParameters = New Structure;
		FormParameters.Insert("Source", "SupplySchemeGoods");
		FormParameters.Insert("Products");
		FormParameters.Insert("Characteristic");
		FormParameters.Insert("Warehouse");
		ActionParameters.Insert("FormParameters", FormParameters);
		
		ActionMenu.Add(ActionParameters);
		#EndRegion
	ElsIf FullReportName = "Report.ARAPReconciliationWithPartners" Then
		StandardProcessing  = False;
	EndIf;
	
	RebatesClient.AdditionalDetailProcessing(
		ThisForm,
		Item,
		Details,
		StandardProcessing,
		ReportMenu,
		ActionMenu);
	
	If ReportMenu.Count() > 0 
		Or ActionMenu.Count() > 0 Then
			DetailsParameters = New Structure;
			DetailsParameters.Insert("ReportMenu",  ReportMenu);
			DetailsParameters.Insert("ActionMenu", ActionMenu);
			DetailsParameters.Insert("Details",  Details);
			
			DataCompositionClient.DecryptionProcessingWithAdditionalMenu(ThisForm, DetailsParameters, StandardProcessing);
	EndIf;
EndProcedure

// Handler for dynamically added commands.
//
// Parameters:
//   ThisForm - ClientApplicationForm - report form.
//   Command     - FormCommand     - the command that was called.
//   Result   - Boolean           - True if the command call was processed.
//
Procedure HandlerCommands(ThisForm, Command, Result) Export
	
EndProcedure

// Handler for the result of selecting a subordinate form.
//
// Parameters:
//   ThisForm       - ClientApplicationForm - report form.
//   ValueSelected - Arbitrary     - the result of the selection in the subordinate form.
//   ChoiceSource    - ClientApplicationForm - the form where the selection was made.
//   Result         - Boolean           - True if the selection result is processed.
//
Procedure ChoiceProcessing(ThisForm,ValueSelected, ChoiceSource, Result) Export
	
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
	FullReportName = ThisForm.ReportSettings.FullName;
	
EndProcedure

// The method is called from the report form after it is generated.
//
//	Parameters:
//		ReportForm - ClientApplicationForm - report form.
//
Procedure AfterGenerationOnClient(ReportForm) Export
	RestoreOfflineCalculations(ReportForm)
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
		For Each KeyAndValue In RawForms Do
			AfterGenerationOnClient(KeyAndValue.Key);
		EndDo;
	EndIf;
EndProcedure

// The method returns the handler for waiting for "parametersproverkyphon Tasks".
// 
// Returns:
//   CallbackDescription - ParametersForCheckingBackgroundTasks 
//
Function ParametersForCheckingBackgroundTasks() Export
	Return ApplicationParameters["TradeManagement.ParametersForCheckingBackgroundTasks"];
EndFunction

#Region OpeningReports
	
// Opens the specified version of the report Cardaccountsclients contextually from documents.
//
// Parameters:
//   VariantKey - String - Name of the report setting to open
//   Document - DocumentRef - Link to the document to set the context.
//
Procedure OpenCustomerSettlementCardReport(VariantKey, Document) Export
	
	If Not ValueIsFilled(Document) Then
		ClearMessages();
		If TypeOf(Document) = Type("CatalogRef.CounterpartyContracts")
			Or TypeOf(Document) = Type("CatalogRef.IntercompanyContracts") Then
			CommonClientServer.MessageToUser(NStr("vi = 'Chưa ghi lại hợp đồng. Việc chuyển sang báo cáo có thể chỉ sau khi ghi lại hợp đồng.';
													|ru = 'Договор не записан. Переход к отчету возможен только после записи договора.';
													|en = 'The contract is not saved. You can go to the report only after you save the contract.'; fa = 'The contract is not saved. You can go to the report only after you save the contract.';
													|it = 'Договор не записан. Переход к отчету возможен только после записи договора.';
													|pl = 'The contract is not saved. You can go to the report only after you save the contract.';
													|tr = 'Sözleşme kaydedilmedi. Rapora geçiş ancak sözleşme kaydedildikten sonra mümkündür.'"));
		Else
			CommonClientServer.MessageToUser(NStr("vi = 'Chưa kết chuyển chứng từ. Chỉ có thể chuyển đến báo cáo sau khi kết chuyển chứng từ.';
													|ru = 'Документ не проведен. Переход к отчету возможен только после проведения документа.';
													|en = 'The document is not posted. You can access the report only after you post the document.'; fa = 'The document is not posted. You can access the report only after you post the document.';
													|it = 'Documento non registrato. Sarà possibile passare al report solo dopo la registrazione del documento.';
													|pl = 'Dokument nie jest zatwierdzony. Przejście do raportu jest możliwe tylko po zatwierdzeniu dokumentu.';
													|tr = 'Belge kaydedilmedi. Rapora geçiş ancak belge kaydedildikten sonra mümkündür.'"));
		EndIf;
		Return;
	EndIf;
	
	If GeneralPurposeTMServerCall.ValueOfFunctionOption("NewOnlineARAPAccounting") Then
		
		FormParameters = New Structure("PurposeUseKey, Filter, GenerateOnOpen, ReportOptionsCommandsVisibility");
		FormParameters.Insert("PurposeUseKey",		Undefined);
		FormParameters.Insert("CommandParameter",					Document);
		FormParameters.Insert("GenerateOnOpen",			True);
		FormParameters.Insert("ReportOptionsCommandsVisibility",	False);
		
		OpenForm("Report.CustomerARAPOpenItems24.Form", FormParameters);
		
	Else
	
		BasicLine = ?(GeneralPurposeTMServerCall.ValueOfFunctionOption("BaseVersion"), "Basic", "");
		
		FormParameters = New Structure("VariantKey, PurposeUseKey, Filter, GenerateOnOpen, ReportOptionsCommandsVisibility");
		FormParameters.Insert("VariantKey",						VariantKey + BasicLine);
		FormParameters.Insert("PurposeUseKey",		Undefined); 
		If TypeOf(Document) = Type("CatalogRef.CounterpartyContracts") Then
			FormParameters.Insert("Filter",						New Structure("Contract", Document));
		Else
			FormParameters.Insert("Filter",						New Structure("CustomerOrderSelection, CurrentDocument", Document, Document));
		EndIf;
		FormParameters.Insert("GenerateOnOpen",			True);
		FormParameters.Insert("ReportOptionsCommandsVisibility",	False);
		
		OpenForm("Report.CustomerARAPOpenItems.Form", FormParameters);
		
	EndIf;
EndProcedure

// Opens the specified version of the report cardaccounts by Suppliers contextually from documents.
//
// Parameters:
//   VariantKey - String - Name of the report setting to open
//   Document - DocumentRef - Link to the document to set the context.
//
Procedure OpenPaymentCardWithSuppliersReport(VariantKey, Document) Export
	
	If Not ValueIsFilled(Document) Then
		ClearMessages();
		If TypeOf(Document) = Type("CatalogRef.CounterpartyContracts")
			Or TypeOf(Document) = Type("CatalogRef.IntercompanyContracts") Then
			CommonClientServer.MessageToUser(NStr("vi = 'Chưa ghi lại hợp đồng. Việc chuyển sang báo cáo có thể chỉ sau khi ghi lại hợp đồng.';
													|ru = 'Договор не записан. Переход к отчету возможен только после записи договора.';
													|en = 'The contract is not saved. You can go to the report only after you save the contract.'; fa = 'The contract is not saved. You can go to the report only after you save the contract.';
													|it = 'Договор не записан. Переход к отчету возможен только после записи договора.';
													|pl = 'The contract is not saved. You can go to the report only after you save the contract.';
													|tr = 'Sözleşme kaydedilmedi. Rapora geçiş ancak sözleşme kaydedildikten sonra mümkündür.'"));
		Else
			CommonClientServer.MessageToUser(NStr("vi = 'Chưa kết chuyển chứng từ. Chỉ có thể chuyển đến báo cáo sau khi kết chuyển chứng từ.';
													|ru = 'Документ не проведен. Переход к отчету возможен только после проведения документа.';
													|en = 'The document is not posted. You can access the report only after you post the document.'; fa = 'The document is not posted. You can access the report only after you post the document.';
													|it = 'Documento non registrato. Sarà possibile passare al report solo dopo la registrazione del documento.';
													|pl = 'Dokument nie jest zatwierdzony. Przejście do raportu jest możliwe tylko po zatwierdzeniu dokumentu.';
													|tr = 'Belge kaydedilmedi. Rapora geçiş ancak belge kaydedildikten sonra mümkündür.'"));
		EndIf;
		Return;
	EndIf;
	
	If GeneralPurposeTMServerCall.ValueOfFunctionOption("NewOnlineARAPAccounting") Then
		
		FormParameters = New Structure("PurposeUseKey, Filter, GenerateOnOpen, ReportOptionsCommandsVisibility");
		FormParameters.Insert("PurposeUseKey",		Undefined);
		FormParameters.Insert("CommandParameter",					Document);
		FormParameters.Insert("GenerateOnOpen",			True);
		FormParameters.Insert("ReportOptionsCommandsVisibility",	False);
		
		OpenForm("Report.VendorARAPOpenItems24.Form", FormParameters);
		
	Else
	
		BasicLine = ?(GeneralPurposeTMServerCall.ValueOfFunctionOption("BaseVersion"), "Basic", "");
		
		FormParameters = New Structure("VariantKey, PurposeUseKey, Filter, GenerateOnOpen, ReportOptionsCommandsVisibility");
		FormParameters.Insert("VariantKey",						VariantKey + BasicLine);
		FormParameters.Insert("PurposeUseKey",		Undefined);
		If TypeOf(Document) = Type("CatalogRef.CounterpartyContracts") Then
			FormParameters.Insert("Filter",						New Structure("Contract", Document));
		Else
			FormParameters.Insert("Filter",						New Structure("OrderToSupplierSelection, CurrentDocument", Document, Document));
		EndIf;
		FormParameters.Insert("GenerateOnOpen",			True);
		FormParameters.Insert("ReportOptionsCommandsVisibility",	False);
		
		OpenForm("Report.VendorARAPOpenItems.Form", FormParameters);
	
	EndIf;
	
EndProcedure

#EndRegion

// Occurs after the report is generated.
//
// Parameters:
//   ReportForm - ClientApplicationForm - report form.
//   ReportCreated - Boolean - True if the report was generated successfully.
//
Procedure AfterGenerate(ReportForm, ReportCreated) Export
	RestoreOfflineCalculations(ReportForm);
	RebatesClient.AfterReportIsGenerated(ReportForm);
EndProcedure

// Called for the report "control of formationdocumentsofmovement".
//
// Parameters:
//  ThisForm							 - ClientApplicationForm	 - the form on which the decryption is processed.
//  Details							 - See Reports.ControlOfInventoryTransferDocumentRegistration.OrderSelectionStructureXMLString.
//  NameOfAlertDescriptionProcedure		 - String			 - name of the handler procedure for the form closing notification description that will be opened during decryption processing.
//  RegistrationDate						 - Date				 - the end date of the warehouse acts, if you need to issue warehouse acts.
//  FiltersToGenerateControlReport	 - TabularSection	 - see the tabular part of the Processing.Assistant to the management of the products of the organizations.Selection for the formation of the Control report.
//
Procedure ProcessDecryptionControlOfRegistrationOfDocumentsOfCommodityMovement(
	ThisForm, Details, NameOfAlertDescriptionProcedure = Undefined, 
	RegistrationDate = Undefined, FiltersToGenerateControlReport = Undefined) Export
	
	DecryptionProcessingParameters = 
		ReportsTMServerCallOverridable.ParametersOfProcessingOfDecryptionControlOfRegistrationOfDocumentsOfCommodityMovement(Details);
	StructureOfRecommendations = DecryptionProcessingParameters.StructureOfRecommendations;
	If ValueIsFilled(NameOfAlertDescriptionProcedure) Then
		CallbackDescription = New CallbackDescription(NameOfAlertDescriptionProcedure, ThisForm);
	Else
		CallbackDescription = Undefined;
	EndIf;
	If StructureOfRecommendations.RegisterPurchaseOfGoodsAndServices 
		Or StructureOfRecommendations.RegisterGoodsReceivingForStorage 
		Or StructureOfRecommendations.ProcessReceiptOfGoods Then
		ReportsTMServerCallOverridable.FillInSelectionsControlOfRegistrationOfDocumentsOfCommodityMovement(
			DecryptionProcessingParameters, "References", FiltersToGenerateControlReport);
		FormOpenParameters = New Structure;
		FormOpenParameters.Insert("QuickFilterStructure", New Structure);
		FormOpenParameters.QuickFilterStructure.Insert("Ref", DecryptionProcessingParameters.References);
		FormOpenParameters.QuickFilterStructure.Insert("Warehouse", DecryptionProcessingParameters.Warehouse);
		FormOpenParameters.Insert("CurrentPageName", "PageReceivingReferences");
		OpenForm("DataProcessor.LogOfPurchaseDocuments.Form.InvoicesForRegistrationList",
			FormOpenParameters, ThisForm,,,, CallbackDescription);
	ElsIf StructureOfRecommendations.RegisterSalesOfGoodsAndServices Then
		ReportsTMServerCallOverridable.FillInSelectionsControlOfRegistrationOfDocumentsOfCommodityMovement(
			DecryptionProcessingParameters, "References", FiltersToGenerateControlReport);
		FormOpenParameters = New Structure;
		FormOpenParameters.Insert("QuickFilterStructure", New Structure);
		FormOpenParameters.QuickFilterStructure.Insert("Ref", DecryptionProcessingParameters.References);
		FormOpenParameters.QuickFilterStructure.Insert("Warehouse", DecryptionProcessingParameters.Warehouse);
		OpenForm("DataProcessor.LogOfSalesDocuments.Form.ToRegisterInvoices",
			FormOpenParameters, ThisForm,,,, CallbackDescription);
	ElsIf StructureOfRecommendations.MakeMovementOfGoodsWithStatusAccepted 
		Or StructureOfRecommendations.IssueDisassemblyDocumentWithAssembledDisassembledStatus
		Or StructureOfRecommendations.IssueBuildDocumentWithAssembledDisassembledStatus Then
		ReportsTMServerCallOverridable.FillInSelectionsControlOfRegistrationOfDocumentsOfCommodityMovement(
			DecryptionProcessingParameters, "References", FiltersToGenerateControlReport);
		FormOpenParameters = New Structure;
		FormOpenParameters.Insert("References", DecryptionProcessingParameters.References.UnloadValues());
		FormOpenParameters.Insert("Warehouse", DecryptionProcessingParameters.Warehouse);
		OpenForm("DataProcessor.LogOfInternalDocuments.Form.InternalDocumentsForRegistration",
			FormOpenParameters, ThisForm,,,, CallbackDescription);
	ElsIf StructureOfRecommendations.RegisterOtherGoodsRecordingAsReceived Then
		ReportsTMServerCallOverridable.FillInSelectionsControlOfRegistrationOfDocumentsOfCommodityMovement(
			DecryptionProcessingParameters, "References", FiltersToGenerateControlReport);
		FormOpenParameters = New Structure;
		FormOpenParameters.Insert("Filter", New Structure);
		FormOpenParameters.Filter.Insert("Ref", DecryptionProcessingParameters.References);
		FormOpenParameters.Insert("QuickFilterStructure", New Structure);
		FormOpenParameters.QuickFilterStructure.Insert("FilterDocumentTypes");
		FormOpenParameters.QuickFilterStructure.Insert("FilterBusinessTransactions");
		OpenForm("DataProcessor.LogOfInternalDocuments.Form.DocumentsList",
			FormOpenParameters, ThisForm,,,, CallbackDescription);
	ElsIf StructureOfRecommendations.RegisterReturnOfGoodsFromCustomer Then
		ReportsTMServerCallOverridable.FillInSelectionsControlOfRegistrationOfDocumentsOfCommodityMovement(
			DecryptionProcessingParameters, "References", FiltersToGenerateControlReport);
		FormOpenParameters = New Structure;
		FormOpenParameters.Insert("QuickFilterStructure", New Structure);
		FormOpenParameters.QuickFilterStructure.Insert("Ref", DecryptionProcessingParameters.References);
		OpenForm("DataProcessor.LogOfSalesDocuments.Form.ToRegisterReturnInvoices",
			FormOpenParameters, ThisForm,,,, CallbackDescription);
	ElsIf StructureOfRecommendations.RegisterWarehouseActsToRecordSurpluses 
		Or StructureOfRecommendations.RegisterWarehouseActsToRecordShortages Then
		ReportsTMServerCallOverridable.FillInSelectionsControlOfRegistrationOfDocumentsOfCommodityMovement(
			DecryptionProcessingParameters, "ProductAndCharacteristics", FiltersToGenerateControlReport);
		FormOpenParameters = New Structure;
		FormOpenParameters.Insert("Warehouse", DecryptionProcessingParameters.Warehouse);
		FormOpenParameters.Insert("StocktakingPeriod", New StandardPeriod);
		If ValueIsFilled(RegistrationDate) Then
			FormOpenParameters.StocktakingPeriod.StartDate = Date("20010101");
			FormOpenParameters.StocktakingPeriod.EndDate = EndOfMonth(RegistrationDate);
		EndIf;
		FormOpenParameters.Insert("FilterOfProductItem", New Structure);
		FormOpenParameters.FilterOfProductItem.Insert("Products", DecryptionProcessingParameters.ItemList);
		FormOpenParameters.FilterOfProductItem.Insert("Characteristic", DecryptionProcessingParameters.ListOfCharacteristics);
		OpenForm("DataProcessor.WarehouseGoodsIssueReceiptWizard.Form.MainForm", 
			FormOpenParameters, ThisForm,,,, CallbackDescription, FormWindowOpeningMode.LockOwnerWindow);
	ElsIf StructureOfRecommendations.RegisterMaterialReturnFromProduction Then
		ReportsTMServerCallOverridable.FillInSelectionsControlOfRegistrationOfDocumentsOfCommodityMovement(
			DecryptionProcessingParameters, "References", FiltersToGenerateControlReport);
		FormOpenParameters = New Structure;
		FormOpenParameters.Insert("References", DecryptionProcessingParameters.References.UnloadValues());
		FormOpenParameters.Insert("QuickFilterStructure", New Structure);
		FormOpenParameters.QuickFilterStructure.Insert("FilterBusinessTransactions", New ValueList);
		ListOfSelectedBusinessOperations = FormOpenParameters.QuickFilterStructure.FilterBusinessTransactions; // ValueList - 
		ListOfSelectedBusinessOperations.Add(
			PredefinedValue("Enum.BusinessTransactions.ReturnOfMaterialsFromProduction"));
		FormOpenParameters.QuickFilterStructure.Insert("FilterDocumentTypes", New ValueList);
		ListAndTypesOfDocuments = FormOpenParameters.QuickFilterStructure.FilterDocumentTypes; // ValueList - 
		ListAndTypesOfDocuments.Add(
			ReportsTMServerCallOverridable.IDMovementOfProductsAndMaterials());
		OpenForm("Document.MovementOfProductsAndMaterials.Form.Workplace",
			FormOpenParameters, ThisForm,,,, CallbackDescription);
	ElsIf StructureOfRecommendations.RegisterProductRelease Then
	ElsIf StructureOfRecommendations.RegisterRawMaterialReturnFromToller Then
	ElsIf StructureOfRecommendations.RegisterReceiptFromToller Then
	ElsIf StructureOfRecommendations.RegisterReceiptOfRawMaterialsFromMaterialProvider Then
	ElsIf StructureOfRecommendations.CreateGoodsIssueNotes 
		Or StructureOfRecommendations.IssueSpendingOrdersForGoods Then
		ReportsTMServerCallOverridable.FillInSelectionsControlOfRegistrationOfDocumentsOfCommodityMovement(
			DecryptionProcessingParameters, "References", FiltersToGenerateControlReport);
		FormOpenParameters = New Structure;
		FormOpenParameters.Insert("QuickFilterStructure", New Structure);
		FormOpenParameters.QuickFilterStructure.Insert("Warehouse", DecryptionProcessingParameters.Warehouse);
		FormOpenParameters.QuickFilterStructure.Insert("FilterReferences", DecryptionProcessingParameters.References);
		OpenForm("DataProcessor.ShipGoodsFromWarehouse.Form.Form",
			FormOpenParameters, ThisForm,,,, CallbackDescription);
	ElsIf StructureOfRecommendations.RegisterGoodsReceiptNotes Then
		ReportsTMServerCallOverridable.FillInSelectionsControlOfRegistrationOfDocumentsOfCommodityMovement(
			DecryptionProcessingParameters, "References", FiltersToGenerateControlReport);
		FormOpenParameters = New Structure;
		FormOpenParameters.Insert("QuickFilterStructure", New Structure);
		FormOpenParameters.QuickFilterStructure.Insert("Warehouse", DecryptionProcessingParameters.Warehouse);
		FormOpenParameters.QuickFilterStructure.Insert("FilterReferences", DecryptionProcessingParameters.References);
		OpenForm("DataProcessor.InboundWarehouseMangement.Form.Form",
			FormOpenParameters, ThisForm,,,, CallbackDescription);
	ElsIf StructureOfRecommendations.SubmitMaterialsForProductionWithAcceptedStatus Then
	ElsIf StructureOfRecommendations.RegisterGoodsShipmentFromStorage Then
		ReportsTMServerCallOverridable.FillInSelectionsControlOfRegistrationOfDocumentsOfCommodityMovement(
			DecryptionProcessingParameters, "References", FiltersToGenerateControlReport);
		FormOpenParameters = New Structure;
		FormOpenParameters.Insert("Filter", New Structure);
		FormOpenParameters.Filter.Insert("Ref", DecryptionProcessingParameters.References);
		OpenForm("Document.GoodsShipmentFromStorage.Form.ListForm",
			FormOpenParameters, ThisForm,,,, CallbackDescription);
	ElsIf StructureOfRecommendations.RegisterInventoryConsumption Then
		ReportsTMServerCallOverridable.FillInSelectionsControlOfRegistrationOfDocumentsOfCommodityMovement(
			DecryptionProcessingParameters, "References", FiltersToGenerateControlReport);
		FormOpenParameters = New Structure;
		FormOpenParameters.Insert("QuickFilterStructure", New Structure);
		FormOpenParameters.QuickFilterStructure.Insert("Ref", DecryptionProcessingParameters.References);
		FormOpenParameters.QuickFilterStructure.Insert("Warehouse", DecryptionProcessingParameters.Warehouse);
		OpenForm("DataProcessor.LogOfInternalDocuments.Form.InternalDocumentsForRegistration",
			FormOpenParameters, ThisForm,,,, CallbackDescription);
	EndIf;

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
	
EndProcedure

#EndRegion 

#Region Internal

Procedure DetailProcessingCompletion(ChosenAction, ChosenActionParameter, AdditionalParameters) Export 
	If ChosenAction = DataCompositionDetailsProcessingAction.OpenValue Then
		If TypeOf(ChosenActionParameter) = Type("DocumentRef.CustomerInvoice") Then
			OpenReportPaymentCardForTransferredReturnContainer(AdditionalParameters.ThisForm.Report, ChosenActionParameter);
		ElsIf TypeOf(ChosenActionParameter) = Type("DocumentRef.VendorInvoice") Then
			OpenReportCalculationCardForAcceptedReturnContainers(AdditionalParameters.ThisForm.Report, ChosenActionParameter);
		Else
			ShowValue(Undefined, ChosenActionParameter);
		EndIf;
	EndIf;
EndProcedure

#EndRegion 


#Region Private

// Called for the report " Vedomosttransferedrecoverabletare"
//
Procedure OpenReportPaymentCardForTransferredReturnContainer(Report, Document)
	
	SettingsComposer = Report.SettingsComposer; // DataCompositionSettingsComposer - 
	FormParameters = New Structure("Filter, PurposeUseKey, VariantKey, GenerateOnOpen");
	FormParameters.GenerateOnOpen = True;
	FormParameters.VariantKey = "ARAPAccountingStatementByReturnablePackagingReceived";
	
	IDOfPeriodParameter = Report.SettingsComposer.UserSettings.GetIDByObject(
		Report.SettingsComposer.Settings.DataParameters.FindParameterValue(New DataCompositionParameter("Period")));
	SettingUpPeriod = SettingsComposer.UserSettings.Items.Find(IDOfPeriodParameter);
	
	Filter = New Structure();
	
	If SettingUpPeriod.Use Then
		Filter.Insert("Period", SettingUpPeriod.Value);
	EndIf;
	FormParameters.Filter = Filter;
	FormParameters.Insert("CommandParameter", Document);
	
	OpenForm("Report.ARAPAccountingStatementByReturnablePackagingProvided.Form", FormParameters);
	
EndProcedure

// Called for the report " Vedomostpopriyatoyvokratoytare"
//
Procedure OpenReportCalculationCardForAcceptedReturnContainers(Report, Document)
	
	SettingsComposer = Report.SettingsComposer; // DataCompositionSettingsComposer - 
	
	FormParameters = New Structure("Filter, PurposeUseKey, VariantKey, GenerateOnOpen");
	FormParameters.GenerateOnOpen = True;
	FormParameters.VariantKey = "ARAPAccountingStatementByReturnablePackagingReceived";
	
	IDOfPeriodParameter = Report.SettingsComposer.UserSettings.GetIDByObject(
		Report.SettingsComposer.Settings.DataParameters.FindParameterValue(New DataCompositionParameter("Period")));
	SettingUpPeriod = SettingsComposer.UserSettings.Items.Find(IDOfPeriodParameter);
	
	Filter = New Structure();
	
	If SettingUpPeriod.Use Then
		Filter.Insert("Period", SettingUpPeriod.Value);
	EndIf;
	FormParameters.Filter = Filter;
	FormParameters.Insert("CommandParameter", Document);
	
	OpenForm("Report.ARAPAccountingStatementByReturnablePackagingReceived.Form", FormParameters);
	
EndProcedure

// Called for the report "the Analysis of residues of products of organizations" and "the Remains of the products of organizations".
//
Procedure ProcessDecryptionAnalysisOfBalanceOfGoodsOfOrganizations(ThisForm, Details)
	
	DetailProcessing = New DataCompositionDetailsProcess(
		ThisForm.ReportDetailsData, 
		New DataCompositionAvailableSettingsSource(ThisForm.Report));
	
	ChosenAction = Undefined;
	ChosenActionParameter = Undefined;
	
	AvailableAction = New Array;
	AvailableAction.Add(DataCompositionDetailsProcessingAction.OpenValue);
	
	AddlParameters = New Structure;
	AddlParameters.Insert("ChosenAction", ChosenAction);
	AddlParameters.Insert("ChosenActionParameter", ChosenActionParameter);
	CallbackDescription = New CallbackDescription("ProcessDecryptionAnalysisOfBalanceOfGoodsOfOrganizationsCompletion",
			ThisObject, AddlParameters);
	DetailProcessing.ShowActionChoice(CallbackDescription,
		Details, 
		AvailableAction);
		
EndProcedure

Procedure ProcessDecryptionAnalysisOfBalanceOfGoodsOfOrganizationsCompletion(ChosenAction,
					ChosenActionParameter, AdditionalParameters) Export
	
	If ChosenAction = DataCompositionDetailsProcessingAction.OpenValue Then
		ShowValue(Undefined, ChosenActionParameter);
	EndIf;

EndProcedure

// For a report called "the Structure series item"
//
Procedure ProcessDecodingStructureOfSeriesOfProducts(ThisForm, Details, StandardProcessing)
	
	StandardProcessing = False;
	
	FieldsStructure = Undefined;
	
	If TypeOf(Details) = Type("DataCompositionDetailsID") Then
		
		FieldsStructure = ReportsTMServerCallOverridable.ParametersForDecodingReportBySeries(
			Details, ThisForm.ReportDetailsData);
			
	ElsIf TypeOf(Details) = Type("Structure") Then
			
		FieldsStructure = Details;
			
	EndIf;
	
	If FieldsStructure <> Undefined Then 
	
		ReportsList = New ValueList;
		
		SettingPresentation = NStr("vi = 'Biến động sê-ri mặt hàng';
									|ru = 'Движение серии номенклатуры';
									|en = 'Item batch movement'; fa = 'جابه‌جایی بچ قلم';
									|it = 'Movimento di lotti di articoli';
									|pl = 'Ruch serii nomenklatury';
									|tr = 'Ürün parti hareketi'");
		ReportsList.Add("ItemBatchMovement", SettingPresentation,, PictureLib.Report);
		
		SettingPresentation = NStr("vi = 'Bảng kê theo sê-ri mặt hàng';
									|ru = 'Ведомость по сериям номенклатуры';
									|en = 'Item batch list'; fa = 'فهرست بچ‌های قلم';
									|it = 'Inventario in base ai lotti di articoli';
									|pl = 'Zestawienie według serii nomenklatury';
									|tr = 'Ürün partileri listesi'");
		ReportsList.Add("ItemsBatchList", SettingPresentation,, PictureLib.Report);
		
		If ValueIsFilled(FieldsStructure.Series) Then
		
			SettingPresentation = NStr("vi = 'Áp dụng sê-ri mặt hàng';
										|ru = 'Применение серии номенклатуры';
										|en = 'Application of item batch'; fa = 'کاربرد بچ قلم';
										|it = 'Applicazione della serie degli articoli';
										|pl = 'Zastosowanie serii nomenklatury';
										|tr = 'Ürün partisinin uygulanması'");
			ReportsList.Add("ApplicationOfItemBatch", SettingPresentation,, PictureLib.Report);
			
			SettingPresentation = NStr("vi = 'Cấu trúc sê-ri mặt hàng';
										|ru = 'Структура серии номенклатуры';
										|en = 'Item batch structure'; fa = 'ساختار بچ قلم';
										|it = 'Struttura della serie di articoli';
										|pl = 'Struktura serii nomenklatury';
										|tr = 'Ürün partisinin yapısı'");
			ReportsList.Add("ItemsBatchStructure", SettingPresentation,, PictureLib.Report);
		
		EndIf;
		
		CallbackDescription = New CallbackDescription("SelectingReportBySeriesCompletion", ThisObject, FieldsStructure);
		ThisForm.ShowChooseFromMenu(CallbackDescription, ReportsList);
		
	EndIf;
	
EndProcedure

// Called for the "applying an item series" report"
//
Procedure ProcessTranscriptApplicationSeriesProducts(ThisForm, Details, StandardProcessing)
	
	StandardProcessing = False;
	
	FieldsStructure = Undefined;
	
	If TypeOf(Details) = Type("DataCompositionDetailsID") Then
		
		FieldsStructure = ReportsTMServerCallOverridable.ParametersForDecodingReportBySeries(
			Details, ThisForm.ReportDetailsData);
			
	ElsIf TypeOf(Details) = Type("Structure") Then
			
		FieldsStructure = Details;
			
	EndIf;
	
	If FieldsStructure <> Undefined Then
	
		ReportsList = New ValueList;
	
		SettingPresentation = NStr("vi = 'Biến động sê-ri mặt hàng';
									|ru = 'Движение серии номенклатуры';
									|en = 'Item batch movement'; fa = 'جابه‌جایی بچ قلم';
									|it = 'Movimento di lotti di articoli';
									|pl = 'Ruch serii nomenklatury';
									|tr = 'Ürün parti hareketi'");
		ReportsList.Add("ItemBatchMovement", SettingPresentation,, PictureLib.Report);
		
		SettingPresentation = NStr("vi = 'Bảng kê theo sê-ri mặt hàng';
									|ru = 'Ведомость по сериям номенклатуры';
									|en = 'Item batch list'; fa = 'فهرست بچ‌های قلم';
									|it = 'Inventario in base ai lotti di articoli';
									|pl = 'Zestawienie według serii nomenklatury';
									|tr = 'Ürün partileri listesi'");
		ReportsList.Add("ItemsBatchList", SettingPresentation,, PictureLib.Report);
		
		If ValueIsFilled(FieldsStructure.Series) Then
		
			SettingPresentation = NStr("vi = 'Cấu trúc sê-ri mặt hàng';
										|ru = 'Структура серии номенклатуры';
										|en = 'Item batch structure'; fa = 'ساختار بچ قلم';
										|it = 'Struttura della serie di articoli';
										|pl = 'Struktura serii nomenklatury';
										|tr = 'Ürün partisinin yapısı'");
			ReportsList.Add("ItemsBatchStructure", SettingPresentation,, PictureLib.Report);
		
		EndIf;
		
		CallbackDescription = New CallbackDescription("SelectingReportBySeriesCompletion", ThisObject, FieldsStructure);
		ThisForm.ShowChooseFromMenu(CallbackDescription, ReportsList);
	
	EndIf;
		
EndProcedure

// Called for the "list by item series" report"
//
Procedure ProcessTranscriptOfStatementBySeriesOfProducts(ThisForm, Details, StandardProcessing)
	
	DetailsParameters = ProductsClient.DecryptionParametersReportStatementBySeriesOfProducts();
	DetailsParameters.Insert("Details", Details);
	
	DataCompositionClient.DecryptionProcessingWithAdditionalMenu(ThisForm, DetailsParameters, StandardProcessing);
	
EndProcedure

Procedure SelectingReportBySeriesCompletion(SelectedElement, AdditionalParameters) Export

	If SelectedElement = Undefined Then
		Return;
	EndIf;
	
	If SelectedElement.Value = "ItemBatchMovement" Then
		
		FilterParameters = New Structure;
		FilterParameters.Insert("Series",  AdditionalParameters.Series);
		FilterParameters.Insert("Products", AdditionalParameters.Products);
		FilterParameters.Insert("Characteristic", AdditionalParameters.Characteristic);
		
		FormParameters = New Structure;
		FormParameters.Insert("DetailsMode", True);
		FormParameters.Insert("UserSettingsKey", "ProductSeriesMovementContext");
		FormParameters.Insert("GenerateOnOpen", True);
		FormParameters.Insert("PurposeUseKey", "ProductSeriesMovementContext" + String(New UUID));
		FormParameters.Insert("VariantKey", "ProductSeriesMovementContext");
		FormParameters.Insert("Filter", FilterParameters);
		
		OpenForm("Report.ItemBatchMovement.ObjectForm", FormParameters);
		
	ElsIf SelectedElement.Value = "ItemsBatchList" Then
		
		FilterParameters = New Structure;
		FilterParameters.Insert("Series",  AdditionalParameters.Series);
		FilterParameters.Insert("Products", AdditionalParameters.Products);
		FilterParameters.Insert("Characteristic", AdditionalParameters.Characteristic);
		
		FormParameters = New Structure;
		FormParameters.Insert("DetailsMode", True);
		FormParameters.Insert("UserSettingsKey", "StatementOfProductSeries");
		FormParameters.Insert("GenerateOnOpen", True);
		FormParameters.Insert("PurposeUseKey", "StatementOfProductSeries" + String(New UUID));
		FormParameters.Insert("VariantKey", "StatementOfProductSeries");
		FormParameters.Insert("Filter", FilterParameters);
		
		OpenForm("Report.ItemsBatchList.ObjectForm", FormParameters);
		
	ElsIf SelectedElement.Value = "ItemsBatchStructure" Then
		
		FilterParameters = New Structure;
		FilterParameters.Insert("Series",  AdditionalParameters.Series);
		FilterParameters.Insert("Products", AdditionalParameters.Products);
		FilterParameters.Insert("Characteristic", AdditionalParameters.Characteristic);
		
		FormParameters = New Structure;
		FormParameters.Insert("DetailsMode", True);
		FormParameters.Insert("UserSettingsKey", "SeriesStructureProductContext");
		FormParameters.Insert("GenerateOnOpen", True);
		FormParameters.Insert("PurposeUseKey", "SeriesStructureProductContext" + String(New UUID));
		FormParameters.Insert("VariantKey", "SeriesStructureProductContext");
		FormParameters.Insert("Filter", FilterParameters);
		
		OpenForm("Report.ItemsBatchStructure.ObjectForm", FormParameters);
		
	ElsIf SelectedElement.Value = "ApplicationOfItemBatch" Then
		
		FilterParameters = New Structure;
		FilterParameters.Insert("Series",  AdditionalParameters.Series);
		FilterParameters.Insert("Products", AdditionalParameters.Products);
		FilterParameters.Insert("Characteristic", AdditionalParameters.Characteristic);
		
		FormParameters = New Structure;
		FormParameters.Insert("DetailsMode", True);
		FormParameters.Insert("UserSettingsKey", "ApplicationSeriesProductContext");
		FormParameters.Insert("GenerateOnOpen", True);
		FormParameters.Insert("PurposeUseKey", "ApplicationSeriesProductContext" + String(New UUID));
		FormParameters.Insert("VariantKey", "ApplicationSeriesProductContext");
		FormParameters.Insert("Filter", FilterParameters);
		
		OpenForm("Report.ApplicationOfItemBatch.ObjectForm", FormParameters);
		
	EndIf; 
	
	
EndProcedure

Procedure OpenProductCertificatesReport(ThisForm, DetailsStructure2)
	
	Filter = New Structure;
	Filter.Insert("ProductKind", DetailsStructure2.ProductKind);
	Filter.Insert("Products", DetailsStructure2.Products);
	
	If ValueIsFilled(DetailsStructure2.Characteristic) Then
		Filter.Insert("Characteristic", DetailsStructure2.Characteristic);
	EndIf;
	
	If ValueIsFilled(DetailsStructure2.Series) Then
		Filter.Insert("Series", DetailsStructure2.Series);
	EndIf;

	Form = GetForm("Report.QualityCertificatesWhichAreAboutToExpire.Form");
	
	DataCompositionSettingsComposer = Form.Report.SettingsComposer;
	UserSettings = DataCompositionSettingsComposer.UserSettings;
	
	Parameter = GetCustomSettingParameter(ThisForm.SettingsComposer.UserSettings,
														"InvalidAsOfTheDate");
	SetCustomSettingParameter(UserSettings,
												"InvalidAsOfTheDate",
												Parameter);

	Parameter = GetCustomSettingParameter(ThisForm.SettingsComposer.UserSettings,
														"DateHideCertificates");
	SetCustomSettingParameter(UserSettings,
												"DateHideCertificates",
												Parameter);
	
	ConfiguringCertificateType = New Structure;
	ConfiguringCertificateType.Insert("ComparisonType",	DataCompositionComparisonType.Equal);
	ConfiguringCertificateType.Insert("RightValue",	DetailsStructure2.CertificateType);
	ConfiguringCertificateType.Insert("Use",	Not IsBlankString(DetailsStructure2.CertificateType));
	
	SetCustomSetting(DataCompositionSettingsComposer,
										UserSettings,
										"UserFields.Field1",
										ConfiguringCertificateType);
	
	FormParameters = New Structure;
	FormParameters.Insert("GenerateOnOpen",		True);
	FormParameters.Insert("UserSettings",	UserSettings);
	FormParameters.Insert("Filter",						Filter);
	
	OpenForm("Report.QualityCertificatesWhichAreAboutToExpire.Form", FormParameters);
	
EndProcedure

// Sets the user setting based on the passed values.
// 
// Parameters:
// 	DataCompositionSettingsComposer - DataCompositionSettingsComposer - 
// 	UserSettings - DataCompositionUserSettings - 
// 	SettingName - String - Name of the selection layout field.
// 	Setting - Structure - values to set in the user setting:
// * RightValue - Arbitrary - 
// * ComparisonType - DataCompositionComparisonType - 
// * Use - Boolean -
Procedure SetCustomSetting(DataCompositionSettingsComposer, UserSettings, SettingName, Setting)
	
	LayoutField = New DataCompositionField(SettingName);
	FilterElement = Undefined;
	
	For Each Item In DataCompositionSettingsComposer.Settings.Filter.Items Do
		If Item.LeftValue = LayoutField
			And Item.ComparisonType = Setting.ComparisonType Then
			FilterElement = Item;
			Break;
		EndIf;
	EndDo;
	
	If Item = Undefined Then
		Return;
	EndIf;
	
	Item = UserSettings.Items.Find(FilterElement.UserSettingID);
	
	Item.ComparisonType = Setting.ComparisonType;
	Item.RightValue = Setting.RightValue;
	Item.Use = Setting.Use;
	
EndProcedure	


// LongDesc
// 
// Parameters:
// 	UserSettings - DataCompositionUserSettings - 
// 	SettingName - String - Name of the user configuration parameter.
// Returns:
// 	Structure - LongDesc:
// * Use - Boolean - Flag for using the parameter.
// * Value - Undefined - Value of the user setting parameter.
Function GetCustomSettingParameter(UserSettings, SettingName)
	
	Result = New Structure;
	Result.Insert("Value", Undefined);
	Result.Insert("Use", False);
	
	LayoutFieldParameter = New DataCompositionParameter(SettingName);
	
	For Each Item In UserSettings.Items Do
		If Item.Parameter = LayoutFieldParameter Then
			Result.Value = Item.Value;
			Result.Use = Item.Use;
			Break;
		EndIf;
	EndDo;
	
	Return Result;
EndFunction


// LongDesc
// 
// Parameters:
// 	UserSettings - DataCompositionUserSettings - 
// 	SettingName - String - 
// 	Parameter - Structure - LongDesc:
// * Value - Arbitrary - Value of the user parameter.
// * Use - Boolean - Flag for using the parameter.
Procedure SetCustomSettingParameter(UserSettings, SettingName, Parameter)
	
	LayoutFieldParameter = New DataCompositionParameter(SettingName);
	
	For Each Item In UserSettings.Items Do
		If Item.Parameter = LayoutFieldParameter Then
			Item.Value = Parameter.Value;
			Item.Use = Parameter.Use; 
			Break;
		EndIf;
	EndDo;
	
EndProcedure

Procedure RestoreOfflineCalculations(ReportForm)
	
	AuxProperties = ReportForm.Report.SettingsComposer.UserSettings.AdditionalProperties;
	WaitHandlerIsRequired = False;
	
	ParameterName = "TradeManagement.ParametersForCheckingBackgroundTasks";
	If ApplicationParameters[ParameterName] = Undefined Then
		ApplicationParameters.Insert(ParameterName, New Structure);
		ApplicationParameters[ParameterName].Insert("Jobs", New Structure());
		ApplicationParameters[ParameterName].Insert("Interval", 7);
	EndIf;
	
	If AuxProperties.Property("LotsAndCostCalculation") And AuxProperties.LotsAndCostCalculation Then
		
		WaitHandlerIsRequired = True;
		
		If Not ApplicationParameters[ParameterName].Jobs.Property("BatchAccounting") Then
			ApplicationParameters[ParameterName].Jobs.Insert("BatchAccounting", New Map);
		EndIf;
		
		JobParameters = ApplicationParameters[ParameterName].Jobs.BatchAccounting;
		
		FormParameters = New Structure("StartOfSettlementPeriod, EndOfSettlementPeriod, CompanyArray, JobNumber");
		FillPropertyValues(FormParameters, AuxProperties);
		
		JobParameters.Insert(ReportForm, FormParameters);
		
	ElsIf AuxProperties.Property("BorderOfMutualSettlements") Then
		
		If Not AuxProperties.Property("CalculationName") Then
			Return;
		EndIf;
		
		WaitHandlerIsRequired = True;
		
		If Not ApplicationParameters[ParameterName].Jobs.Property(AuxProperties.CalculationName) Then
			ApplicationParameters[ParameterName].Jobs.Insert(AuxProperties.CalculationName, New Map());
		EndIf;
		
		JobParameters = ApplicationParameters[ParameterName].Jobs[AuxProperties.CalculationName];
		
		FormParameters = New Structure("BorderOfMutualSettlements, JobNumber, ReadyForCalculation, CalculationName");
		FillPropertyValues(FormParameters, AuxProperties);
		
		JobParameters.Insert(ReportForm, FormParameters);
		
	EndIf;
	
	If WaitHandlerIsRequired Then
		ReportForm.AttachIdleHandler("CheckBackgroundJobs", ApplicationParameters[ParameterName].Interval, True);
	EndIf;
	
EndProcedure

Function BusinessSalesOperations(ExcludeSalesToOwnOrganizations = False)
	BusinessSalesOperations = ReportsTMServerCallOverridable.BusinessOperationsOfAnalyticalRegisters("RevenueAndCOGS");
	If ExcludeSalesToOwnOrganizations Then
		IndexOfElementToDelete = BusinessSalesOperations.Find(PredefinedValue("Catalog.BusinessTransactionsSettings.GoodsSaleToAnotherCompany"));
		BusinessSalesOperations.Delete(IndexOfElementToDelete);
	EndIf;
	
	BusinessTransactionList = New ValueList;
	BusinessTransactionList.LoadValues(BusinessSalesOperations);
	
	Return BusinessTransactionList;
EndFunction

Procedure ProcessDecodingOfManagementBalanceSheet(ThisForm, Details, StandardProcessing)
	
	StandardProcessing = False;
	If Details = Undefined Then
		Return;
	EndIf; 
	
	SettingsComposer = ThisForm.Report.SettingsComposer;
	DecryptionReports = ReportsTMServerCallOverridable.SettingsForDecodingAssetLiabilityArticle(SettingsComposer, Details, ThisForm.ReportDetailsData);
	
	ReportMenu = DecryptionReports.ReportMenu;
	If ReportMenu.Count() > 1 Then
		CallbackDescription = New CallbackDescription("SelectingAssetLiabilityDecryptionReport", ThisObject, DecryptionReports);
		ThisForm.ShowChooseFromMenu(CallbackDescription, ReportMenu);
	ElsIf ReportMenu.Count() = 1 Then
		SelectingAssetLiabilityDecryptionReport(ReportMenu[0], DecryptionReports)
	EndIf;
	
EndProcedure

Procedure SelectingAssetLiabilityDecryptionReport(SelectedElement, DecryptionSettings) Export
	
	If SelectedElement = Undefined Then
		Return;
	
	ElsIf SelectedElement.Value = "OpenValue" Then
		ShowValue(Undefined, DecryptionSettings.Factor);
		
	Else
		Report = DecryptionSettings[SelectedElement.Value];
		OpenForm("Report."+Report.ReportName+".Form", Report.FormParameters);
	EndIf;
	
EndProcedure

#EndRegion
