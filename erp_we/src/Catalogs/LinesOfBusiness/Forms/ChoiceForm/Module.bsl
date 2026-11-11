
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ChoiceMode = "Active_1";
	
	ConfigureSelectionsOnForm();

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	NationalLanguageSupportServer.OnCreateAtServer(ThisObject);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ChoiceModeOnChange(Item)
	SelectModeWhenChangingOnServer();
EndProcedure

&AtServer
Procedure SelectModeWhenChangingOnServer()
	
	NewStatus = Enums.LineOfBusinessStatuses.Used;
	If ChoiceMode = "All" Then
		NewStatus = Enums.LineOfBusinessStatuses.EmptyRef();
	EndIf;
	
	CommonClientServer.SetDynamicListFilterItem(
			List,
			"Status",
			NewStatus,
			DataCompositionComparisonType.Equal,
			,
			ValueIsFilled(NewStatus));
	
EndProcedure

#EndRegion

#Region Utilities

&AtServer
Procedure ConfigureSelectionsOnForm()
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"Status",
		Enums.LineOfBusinessStatuses.Used,
		DataCompositionComparisonType.Equal,
		,
		True);
	If Parameters.Property("Filter") Then
		If Parameters.Filter.Property("CostsOrVendorsARAPAccounting") And Parameters.Filter.CostsOrVendorsARAPAccounting Then
			FilterOrGroup = List.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
			FilterOrGroup.Use = True;
			FilterOrGroup.Presentation = NStr("vi = 'Hạch toán với nhà cung cấp hoặc chi phí đặt riêng';
												|ru = 'Расчеты с поставщиками или затраты с обособлением';
												|en = 'Vendor AR/AP or costs with assignment'; fa = 'Vendor AR/AP or costs with assignment';
												|it = 'Calcoli con i fornitori o costi segregati';
												|pl = 'Rozliczenia z dostawcami lub koszty z oddzieleniem';
												|tr = 'Tedarikçi mutabakatı veya ayrıştırılmış giderler'");
			FilterOrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
			FilterOrGroup.ViewMode = DataCompositionSettingsItemViewMode.Normal;
			
			FilterCostAccounting = FilterOrGroup.Items.Add(Type("DataCompositionFilterItem"));
			FilterCostAccounting.LeftValue    = New DataCompositionField("CostAccounting");
			FilterCostAccounting.ComparisonType     = DataCompositionComparisonType.Equal;
			FilterCostAccounting.Use    = True;
			FilterCostAccounting.RightValue   = True;
			
			FilterVendorARAP = FilterOrGroup.Items.Add(Type("DataCompositionFilterItem"));
			FilterVendorARAP.LeftValue    = New DataCompositionField("VendorARAP");
			FilterVendorARAP.ComparisonType     = DataCompositionComparisonType.Equal;
			FilterVendorARAP.Use    = True;
			FilterVendorARAP.RightValue   = True;
		EndIf;
		
		If Parameters.Filter.Property("CostOrCustomersARAPAccounting")
		   And Parameters.Filter.CostOrCustomersARAPAccounting Then
			
			FilterOrGroup = List.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
			FilterOrGroup.Use = True;
			FilterOrGroup.Presentation = NStr("vi = 'Hạch toán với khách hàng hoặc chi phí đặt riêng';
												|ru = 'Расчеты с клиентами или затраты с обособлением';
												|en = 'Customer AR/AP or costs with assignment'; fa = 'Customer AR/AP or costs with assignment';
												|it = 'Расчеты с клиентами или затраты с обособлением';
												|pl = 'Customer AR/AP or costs with assignment';
												|tr = 'Müşteriler ile ödemeler veya atanmış giderler'");
			FilterOrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
			FilterOrGroup.ViewMode = DataCompositionSettingsItemViewMode.Normal;
			
			FilterCostAccounting = FilterOrGroup.Items.Add(Type("DataCompositionFilterItem"));
			FilterCostAccounting.LeftValue = New DataCompositionField("CostAccounting");
			FilterCostAccounting.ComparisonType = DataCompositionComparisonType.Equal;
			FilterCostAccounting.Use = True;
			FilterCostAccounting.RightValue = True;
			
			SelectionAccountingOfSettlementsWithClients = FilterOrGroup.Items.Add(Type("DataCompositionFilterItem"));
			SelectionAccountingOfSettlementsWithClients.LeftValue = New DataCompositionField("IncomeAccounting");
			SelectionAccountingOfSettlementsWithClients.ComparisonType = DataCompositionComparisonType.Equal;
			SelectionAccountingOfSettlementsWithClients.Use = True;
			SelectionAccountingOfSettlementsWithClients.RightValue = True;
			
		EndIf;
		
		If Parameters.Filter.Property("StateContractAndSDOContractFulfillment") Then
			CommonClientServer.SetDynamicListFilterItem(
						List,
						"StateContractAndSDOContractFulfillment",
						Parameters.Filter.StateContractAndSDOContractFulfillment,
						DataCompositionComparisonType.Equal,
						,
						True);
		EndIf;
		
	EndIf;
	If Parameters.Property("Ref") Then
		
		If TypeOf(Parameters.Ref) = Type("CatalogRef.CounterpartyContracts") 
			And Parameters.Property("ContractType") Then
			
			If Parameters.ContractType = Enums.ContractTypes.WithCustomer
				Or Parameters.ContractType = Enums.ContractTypes.WithConsignee Then
				
				Parameters.Filter.Insert("IncomeAccounting", True);
			ElsIf Parameters.ContractType = Enums.ContractTypes.ReceiptForTolling2_5
				Or False Then
				
				FilterOrGroup = List.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
				FilterOrGroup.Use = True;
				FilterOrGroup.Presentation = NStr("vi = 'Thu nhập hoặc chi phí riêng';
													|ru = 'Доходы или затраты с обособлением';
													|en = 'Income or costs with assignment'; fa = 'Income or costs with assignment';
													|it = 'Ricavi o spese separate';
													|pl = 'Dochody lub koszty z oddzieleniem';
													|tr = 'Gelirler ve ayrıştırılmış giderler'");
				FilterOrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
				FilterOrGroup.ViewMode = DataCompositionSettingsItemViewMode.Normal;

				SelectionGroupIncomeWithoutExpenses = FilterOrGroup.Items.Add(Type("DataCompositionFilterItemGroup"));
				SelectionGroupIncomeWithoutExpenses.Use = True;
				SelectionGroupIncomeWithoutExpenses.Presentation = NStr("vi = 'Thu nhập không có chi phí';
																		|ru = 'Доходы без затрат';
																		|en = 'Income with no costs'; fa = 'Income with no costs';
																		|it = 'Ricavi senza spese';
																		|pl = 'Dochody bez kosztów';
																		|tr = 'Gidersiz gelirler'");
				SelectionGroupIncomeWithoutExpenses.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
				SelectionGroupIncomeWithoutExpenses.ViewMode = DataCompositionSettingsItemViewMode.Normal;
				
				CostSelection_ = SelectionGroupIncomeWithoutExpenses.Items.Add(Type("DataCompositionFilterItem"));
				CostSelection_.LeftValue  = New DataCompositionField("CostAccounting");
				CostSelection_.ComparisonType   = DataCompositionComparisonType.Equal;
				CostSelection_.Use  = True;
				CostSelection_.RightValue = False;
				
				SelectionByIncome = SelectionGroupIncomeWithoutExpenses.Items.Add(Type("DataCompositionFilterItem"));
				SelectionByIncome.LeftValue    = New DataCompositionField("IncomeAccounting");
				SelectionByIncome.ComparisonType     = DataCompositionComparisonType.Equal;
				SelectionByIncome.Use    = True;
				SelectionByIncome.RightValue   = True;
				
				SelectionGroupAndCosts = FilterOrGroup.Items.Add(Type("DataCompositionFilterItemGroup"));
				SelectionGroupAndCosts.Use = True;
				SelectionGroupAndCosts.Presentation = NStr("vi = 'chi phí đặt riêng';
															|ru = 'затраты с обособлением';
															|en = 'costs with assignment'; fa = 'costs with assignment';
															|it = 'spese separate';
															|pl = 'koszty z oddzieleniem';
															|tr = 'ayrıştırılmış giderler'");
				SelectionGroupAndCosts.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
				SelectionGroupAndCosts.ViewMode = DataCompositionSettingsItemViewMode.Normal;
				
				CostSelection_ = SelectionGroupAndCosts.Items.Add(Type("DataCompositionFilterItem"));
				CostSelection_.LeftValue  = New DataCompositionField("CostAccounting");
				CostSelection_.ComparisonType   = DataCompositionComparisonType.Equal;
				CostSelection_.Use  = True;
				CostSelection_.RightValue = True;
				
				SelectionByIncome = SelectionGroupAndCosts.Items.Add(Type("DataCompositionFilterItem"));
				SelectionByIncome.LeftValue    = New DataCompositionField("IncomeAccounting");
				SelectionByIncome.ComparisonType     = DataCompositionComparisonType.Equal;
				SelectionByIncome.Use    = True;
				SelectionByIncome.RightValue   = True;
			ElsIf Parameters.ContractType = Enums.ContractTypes.WithVendor
				Or Parameters.ContractType = Enums.ContractTypes.WithConsignor
				Or Parameters.ContractType = Enums.ContractTypes.Import
				Or Parameters.ContractType = Enums.ContractTypes.PurchaseEAEU
				Or Parameters.ContractType = Enums.ContractTypes.ReceivingForCustody Then
				
				FilterOrGroup = List.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
				FilterOrGroup.Use = True;
				FilterOrGroup.Presentation = NStr("vi = 'Hạch toán với nhà cung cấp hoặc chi phí đặt riêng';
													|ru = 'Расчеты с поставщиками или затраты с обособлением';
													|en = 'Vendor AR/AP or costs with assignment'; fa = 'Vendor AR/AP or costs with assignment';
													|it = 'Calcoli con i fornitori o costi segregati';
													|pl = 'Rozliczenia z dostawcami lub koszty z oddzieleniem';
													|tr = 'Tedarikçi mutabakatı veya ayrıştırılmış giderler'");
				FilterOrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
				FilterOrGroup.ViewMode = DataCompositionSettingsItemViewMode.Normal;
				
				FilterCostAccounting = FilterOrGroup.Items.Add(Type("DataCompositionFilterItem"));
				FilterCostAccounting.LeftValue    = New DataCompositionField("CostAccounting");
				FilterCostAccounting.ComparisonType     = DataCompositionComparisonType.Equal;
				FilterCostAccounting.Use    = True;
				FilterCostAccounting.RightValue   = True;
				
				FilterVendorARAP = FilterOrGroup.Items.Add(Type("DataCompositionFilterItem"));
				FilterVendorARAP.LeftValue    = New DataCompositionField("VendorARAP");
				FilterVendorARAP.ComparisonType     = DataCompositionComparisonType.Equal;
				FilterVendorARAP.Use    = True;
				FilterVendorARAP.RightValue   = True;
							
			Else
				
				Parameters.Filter.Insert("CostAccounting", True);
				
			EndIf;
			
		ElsIf TypeOf(Parameters.Ref) = Type("DocumentRef.IntercompanyGoodsReturn")
			Or TypeOf(Parameters.Ref) = Type("DocumentRef.MovementOfOtherAssetsAndLiabilities")
			Or TypeOf(Parameters.Ref) = Type("DocumentRef.CommissionReportIntercompany")
			Or TypeOf(Parameters.Ref) = Type("DocumentRef.CommissionWriteOffReportIntercompany")
			Or TypeOf(Parameters.Ref) = Type("DocumentRef.CustomerInvoiceIntercompany")
			Or TypeOf(Parameters.Ref) = Type("DocumentRef.ConsumptionReportSubcontractingServicesDeliveredIntercompany")
			Or TypeOf(Parameters.Ref) = Type("DocumentRef.GoodsMisgrading")
			Or TypeOf(Parameters.Ref) = Type("DocumentRef.OtherIncomeExpenses")
			Or TypeOf(Parameters.Ref) = Type("CatalogRef.IntercompanyContracts") Then
			
			FilterOrGroup = List.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
			FilterOrGroup.Use = True;
			FilterOrGroup.Presentation = NStr("vi = 'danh sách kết hợp dự án/trạng thái';
												|ru = 'список комбинаций проект/статус';
												|en = 'combination list project/status'; fa = 'combination list project/status';
												|it = 'elenco combinazioni progetto/stato';
												|pl = 'lista kombinacji projekt/status';
												|tr = 'proje/durum kombinasyonlarının listesi'");
			FilterOrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
			FilterOrGroup.ViewMode = DataCompositionSettingsItemViewMode.Normal;

			SelectionByIncome = FilterOrGroup.Items.Add(Type("DataCompositionFilterItem"));
			SelectionByIncome.LeftValue    = New DataCompositionField("IncomeAccounting");
			SelectionByIncome.ComparisonType     = DataCompositionComparisonType.Equal;
			SelectionByIncome.Use    = True;
			SelectionByIncome.RightValue   = True;

			CostSelection_ = FilterOrGroup.Items.Add(Type("DataCompositionFilterItem"));
			CostSelection_.LeftValue  = New DataCompositionField("CostAccounting");
			CostSelection_.ComparisonType   = DataCompositionComparisonType.Equal;
			CostSelection_.Use  = True;
			CostSelection_.RightValue = True;
			
			FilterVendorARAP = FilterOrGroup.Items.Add(Type("DataCompositionFilterItem"));
			FilterVendorARAP.LeftValue    = New DataCompositionField("VendorARAP");
			FilterVendorARAP.ComparisonType     = DataCompositionComparisonType.Equal;
			FilterVendorARAP.Use    = True;
			FilterVendorARAP.RightValue   = True;
		EndIf;
		
	EndIf;

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.List);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

#EndRegion
