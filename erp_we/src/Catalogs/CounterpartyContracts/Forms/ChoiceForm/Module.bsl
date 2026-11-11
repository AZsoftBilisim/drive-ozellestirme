
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Refund upon receipt of the form for analysis.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	ShowContractsReceiptOfServicesIsCanceled = True;
	If Parameters.Property("ShowContractsReceiptOfServicesIsCanceled") Then
		ShowContractsReceiptOfServicesIsCanceled = Parameters.ShowContractsReceiptOfServicesIsCanceled;
	EndIf;
	
	ShowSalesThroughCommissionAgent = Parameters.Property("ShowSalesThroughCommissionAgent") 
		And GetFunctionalOption("UseSalesCommission");
	
	List.Parameters.SetParameterValue("OBEntry", Parameters.Property("ThisIsInputOfResiduals"));
	
	Terms = Undefined;
	If Parameters.Property("Terms", Terms)
		And ValueIsFilled(Terms)
		And TypeOf(Terms) = Type("CatalogRef.TermsOfPurchaseFromVendors")
		And Not Parameters.Filter.Property("BusinessOperation") Then
		Parameters.Filter.Insert(
			"BusinessOperation",
			Catalogs.TermsOfPurchaseFromVendors.BusinessTransactionFromAgreement(Parameters.Terms));
	EndIf;
	
	SetUnavailableSelectionsFromParameters(Parameters.Filter, Parameters.Property("ShowSeparatePurchaseContracts"),
		ShowSalesThroughCommissionAgent, ShowContractsReceiptOfServicesIsCanceled);
	
	If Parameters.Property("Partner") And Not ShowSalesThroughCommissionAgent Then
		
		Partner = Parameters.Partner;
		
		PartnerList = New ValueList;
		PartnersAndCounterparties.FillInListOfPartnersWithParents(Partner, PartnerList);
		
		CommonClientServer.SetDynamicListFilterItem(
			List,
			"Partner",
			PartnerList,
			DataCompositionComparisonType.InList,
			Undefined,
			ValueIsFilled(Partner));
		
		List.Parameters.SetParameterValue("PartnerList", PartnerList);
		CommonClientServer.SetDynamicListFilterItem(
			List,
			"FilterByPartner",
			True,
			DataCompositionComparisonType.Equal);
		
		List.Parameters.SetParameterValue("DefaultPartner", Partner);
		CommonClientServer.SetDynamicListFilterItem(
			List,
			"DefaultPartner",
			Partner,
			DataCompositionComparisonType.Equal,
			Undefined,
			True);
		
	Else
		
		List.Parameters.SetParameterValue("DefaultPartner", Catalogs.Partners.EmptyRef());
		
	EndIf;
	
	If Parameters.Property("Counterparty") And Not ShowSalesThroughCommissionAgent Then
		Counterparty = Parameters.Counterparty;
		
		SetDynamicListFilterItem(List, Counterparty, "Counterparty");
	EndIf;
	
	If Parameters.Property("AllowSelectionOfBranchContracts") Then
		List.Parameters.SetParameterValue("AllowSelectionOfBranchContracts", Parameters.AllowSelectionOfBranchContracts);
	Else
		List.Parameters.SetParameterValue("AllowSelectionOfBranchContracts", False);
	EndIf;
	
	If Parameters.Property("AllowPartnerSelection") Then
		Items.FilterPartner.Visible			= True;
		Items.FilterCounterparty.Visible		= True;
		Items.ListOrganization.Visible	= True;
		Items.ListCounterparty.Visible		= True;
		Items.ListPartner.Visible		= True;
	EndIf;
	
	If Parameters.Property("VATTaxation") Then
		CompanyActsAsAVATTaxAgent = (Parameters.VATTaxation = Enums.VATTaxationTypes.VATTaxAgent);
		
		CommonClientServer.SetDynamicListFilterItem(List,
																				"CompanyActsAsAVATTaxAgent",
																				CompanyActsAsAVATTaxAgent,
																				DataCompositionComparisonType.Equal,
																				Undefined,
																				True);
	EndIf;
		
	ArrayOfBusinessOperations = New Array;
	
	If Parameters.Property("ShowPurchaseByImport")
		And Parameters.Filter.Property("BusinessOperation")
		And Parameters.Filter.BusinessOperation = Enums.BusinessTransactions.PurchaseFromSupplier Then
		
		ArrayOfBusinessOperations.Add(Enums.BusinessTransactions.PurchaseFromSupplier);
		ArrayOfBusinessOperations.Add(Enums.BusinessTransactions.PurchaseByImport);
		ArrayOfBusinessOperations.Add(Enums.BusinessTransactions.ImportFromEAEU);
		
		If GetFunctionalOption("UseImportedPurchasesOfGoodsInTransit") Then
			OperationsInTransit = PurchasesServer.BusinessOperationsOnMain(Enums.BusinessTransactions.PurchaseByImport);
			
			CommonClientServer.SupplementArray(ArrayOfBusinessOperations, OperationsInTransit);
			OperationsInTransit = PurchasesServer.BusinessOperationsOnMain(Enums.BusinessTransactions.ImportFromEAEU);
			CommonClientServer.SupplementArray(ArrayOfBusinessOperations, OperationsInTransit);
		EndIf;
		
		If GetFunctionalOption("UseGoodsInTransitFromVendors")
			Or GetFunctionalOption("UseUninvoicedDeliveries") Then
			
			OperationsInTransit = PurchasesServer.BusinessOperationsOnMain(Enums.BusinessTransactions.PurchaseFromSupplier);
			
			CommonClientServer.SupplementArray(ArrayOfBusinessOperations, OperationsInTransit);
			
		EndIf;
		
		
		If GetFunctionalOption("UseProductionByThirdParty2_5") Then
			ProductionByToller = PurchasesServer.BusinessOperationsOnMain(Enums.BusinessTransactions.ProductionByToller2_5);
			CommonClientServer.SupplementArray(ArrayOfBusinessOperations, ProductionByToller);
		EndIf;
	EndIf;
	
	If Parameters.Property("AvailablePaymentTerms") Then
		CommonClientServer.SetDynamicListFilterItem(List,
																				"ARAPObjectSettings",
																				Parameters.AvailablePaymentTerms,
																				DataCompositionComparisonType.InList);
	EndIf;
	
	If Parameters.Property("ContractTypes") Then
		
		CommonClientServer.SetDynamicListFilterItem(
			List, 
			"ContractType", 
			Parameters.ContractTypes, 
			DataCompositionComparisonType.InList);
		
	EndIf;
	
	If Parameters.Property("ShowTransfersForCommission")
		And GetFunctionalOption("UseSalesCommission") Then
		
		If ArrayOfBusinessOperations.Count() Then
			ArrayOfBusinessOperations.Add(Enums.BusinessTransactions.TransferToCommissionAgent);
		EndIf;
	
		FilterGroup = CommonClientServer.CreateFilterItemGroup(List.Filter.Items, "ShowTransfersForCommission", DataCompositionFilterItemsGroupType.OrGroup);
		CommissionSelectionGroup = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
		CommissionSelectionGroup.LeftValue = New DataCompositionField("BusinessOperation");
		CommissionSelectionGroup.ComparisonType = DataCompositionComparisonType.NotEqual;
		CommissionSelectionGroup.RightValue = Enums.BusinessTransactions.TransferToCommissionAgent;
		
		CommissionSelectionGroup = FilterGroup.Items.Add(Type("DataCompositionFilterItemGroup"));
		CommissionSelectionGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
		ItemFilter = CommissionSelectionGroup.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("BusinessOperation");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = Enums.BusinessTransactions.TransferToCommissionAgent;
		
		ItemFilter = CommissionSelectionGroup.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("ConsignmentSales25");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = True;
		
	EndIf;
	
	If ShowSalesThroughCommissionAgent Then
		
		If ArrayOfBusinessOperations.Count() Then
			ArrayOfBusinessOperations.Add(Enums.BusinessTransactions.SalesViaCommissionAgent);
		EndIf;
	
		FilterGroup = CommonClientServer.CreateFilterItemGroup(List.Filter.Items, "ShowSalesThroughCommissionAgent", DataCompositionFilterItemsGroupType.OrGroup);
		SelectionGroupIsNormal = FilterGroup.Items.Add(Type("DataCompositionFilterItemGroup"));
		SelectionGroupIsNormal.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
		ItemFilter = SelectionGroupIsNormal.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("BusinessOperation");
		ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
		ItemFilter.RightValue = Enums.BusinessTransactions.SalesViaCommissionAgent;
		
		AddSelectionCounterpartyPartner(SelectionGroupIsNormal, Parameters.Filter, "Counterparty", "Partner");
		
		ItemFilter = SelectionGroupIsNormal.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("ContractType");
		ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
		ItemFilter.RightValue = Parameters.Filter.ContractType;
		
		CommissionSelectionGroup = FilterGroup.Items.Add(Type("DataCompositionFilterItemGroup"));
		CommissionSelectionGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
		ItemFilter = CommissionSelectionGroup.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("BusinessOperation");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = Enums.BusinessTransactions.SalesViaCommissionAgent;

		ItemFilter = CommissionSelectionGroup.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("ConductARAPAccountingThroughEndCustomers");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = False;
		
		AddSelectionCounterpartyPartner(CommissionSelectionGroup, Parameters.Filter, "CounterpartyCommissionAgent", "CommissionAgentPartner");
		
		CommissionSelectionGroup = FilterGroup.Items.Add(Type("DataCompositionFilterItemGroup"));
		CommissionSelectionGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
		ItemFilter = CommissionSelectionGroup.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("BusinessOperation");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = Enums.BusinessTransactions.SalesViaCommissionAgent;

		ItemFilter = CommissionSelectionGroup.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("ConductARAPAccountingThroughEndCustomers");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = True;
		
		AddSelectionCounterpartyPartner(CommissionSelectionGroup, Parameters.Filter, "Counterparty", "Partner");
		
		CommissionSelectionGroup = FilterGroup.Items.Add(Type("DataCompositionFilterItemGroup"));
		CommissionSelectionGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
		ItemFilter = CommissionSelectionGroup.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("BusinessOperation");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = Enums.BusinessTransactions.TransferToCommissionAgent;

		ItemFilter = CommissionSelectionGroup.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("ConductARAPAccountingThroughEndCustomers");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = True;
		
		ItemFilter = CommissionSelectionGroup.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("ARAPObjectSettings");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice;
		
		AddSelectionCounterpartyPartner(CommissionSelectionGroup, Parameters.Filter, "Counterparty", "Partner");
		
		FilterParameters = New Structure;
		If Parameters.Property("Counterparty") Then
			FilterParameters.Insert("Counterparty", Parameters.Counterparty);
		EndIf;
		If Parameters.Property("Partner") Then
			FilterParameters.Insert("Partner", Parameters.Partner);
		EndIf;
		
	EndIf;
	
	If Parameters.Property("ProcessingInEAEUCountries") Then
		If GetFunctionalOption("UseProductionByThirdParty2_5") Then
			
			ProductionByToller = PurchasesServer.BusinessOperationsOnMain(Enums.BusinessTransactions.ProductionByToller2_5);
			CommonClientServer.SupplementArray(ArrayOfBusinessOperations, ProductionByToller);
					
		EndIf;
	EndIf;
	
	If ArrayOfBusinessOperations.Count() Then
	
		CommonClientServer.SetDynamicListFilterItem(List,
																				"BusinessOperation", 
																				ArrayOfBusinessOperations,
																				DataCompositionComparisonType.InList);
	EndIf;
	
	If Parameters.Property("LineOfBusiness")
		And ValueIsFilled(Parameters.LineOfBusiness) Then
		
		LinesOfBusiness = New ValueList;
		LinesOfBusiness.Add(Parameters.LineOfBusiness);
		LinesOfBusiness.Add(Catalogs.LinesOfBusiness.EmptyRef());
		
		List.Parameters.SetParameterValue("LineOfBusiness", LinesOfBusiness);
		
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	Parameters.Filter.Clear();
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	Manager = Settings.Get("Manager");
	
	CommonClientServer.SetDynamicListFilterItem(
		List, 
		"Manager", 
		Manager, 
		DataCompositionComparisonType.Equal,
		, 
		ValueIsFilled(Manager));
	
	Settings.Clear();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FilterManagerOnChange(Item)
	
	SetDynamicListFilterItem(List, Manager, "Manager");
	
EndProcedure

&AtClient
Procedure FilterPartnerOnChange(Item)
	
	SetDynamicListFilterItem(List, Partner, "Partner");
	
EndProcedure

&AtClient
Procedure FilterCounterpartyOnChange(Item)
	
	SetDynamicListFilterItem(List, Counterparty, "Counterparty");
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, IsFolder, Parameter)
	ClearMessages();
	
	If Not Copy And TypeOf(FilterParameters) = Type("Structure") Then
		
		Cancel = True;
		
		FillingValues = New Structure;
		CommonClientServer.SupplementStructure(FillingValues, FilterParameters);
		
		For Each FilterElement In List.Filter.Items Do
			If TypeOf(FilterElement) = Type("DataCompositionFilterItem")
				And (FilterElement.Use = True
				And FilterElement.ComparisonType = DataCompositionComparisonType.Equal
				Or FilterElement.LeftValue = New DataCompositionField("ARAPObjectSettings")) Then
				
				FillingValues.Insert(String(FilterElement.LeftValue), FilterElement.RightValue);
				
			EndIf;
		EndDo;
		
		FormParameters = New Structure;
		FormParameters.Insert("FillingValues", FillingValues);
		
		OpenForm("Catalog.CounterpartyContracts.ObjectForm", FormParameters, Items.List, ThisObject);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.List);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.List, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
EndProcedure
// End StandardSubsystems.AttachableCommands

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.List);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

#EndRegion

#Region Private

#Region Other

&AtClientAtServerNoContext
Procedure SetDynamicListFilterItem(List, FormAttribute, DynamicListFieldName)
	
	CommonClientServer.SetDynamicListFilterItem(
		List, 
		DynamicListFieldName, 
		FormAttribute, 
		DataCompositionComparisonType.Equal,
		, 
		ValueIsFilled(FormAttribute));
	
EndProcedure

// The procedure sets the selections passed in the structure. Selections cannot be changed.
//
// Parameters:
//	FilterStructure1 - Structure - Key: name of the data layout field, Value: selection value.
//
&AtServer
Procedure SetUnavailableSelectionsFromParameters(FilterStructure1, ShowSeparatePurchaseContracts, 
		ShowSalesThroughCommissionAgent, ShowContractsReceiptOfServicesIsCanceled = True)
	
	If FilterStructure1.Property("Owner") Then
		FilterStructure1.Delete("Owner");
	EndIf;
	
	If FilterStructure1.Property("ArticleOwner") Then
		FilterStructure1.Delete("ArticleOwner");
	EndIf;
	
	For Each FilterElement In FilterStructure1 Do
		
		FilterValue = FilterElement.Value;
		
		If ShowSalesThroughCommissionAgent = True
			And (FilterElement.Key = "Counterparty" 
				Or FilterElement.Key = "Partner"
				Or FilterElement.Key = "ContractType") Then
			Continue;
		EndIf;
		
		If FilterElement.Key = "Organization" Then
			
			CommonClientServer.SetDynamicListFilterItem(
				List,
				"FilterByCompany",
				True,
				DataCompositionComparisonType.Equal);
				
			CommonClientServer.SetDynamicListFilterItem(
				List,
				"OrganizationOfSelection",
				FilterValue,
				DataCompositionComparisonType.Equal,
				,
				True);
				
			CommonClientServer.SetDynamicListParameter(
				List,
				"Organization",
				FilterValue);
			
			Continue;
			
		EndIf;
		
		If FilterElement.Key = "Counterparty"
			And GetFunctionalOption("UsePartnersAsCounterparties") Then
			
			AttributeOfFilter = ?(ValueIsFilled(FilterValue),
								Common.ObjectAttributeValue(FilterValue, "Partner"),
								Catalogs.Partners.EmptyRef());
			
			CommonClientServer.SetDynamicListFilterItem(
				List,
				"Partner",
				AttributeOfFilter,
				DataCompositionComparisonType.Equal);
			
			Continue;
			
		EndIf;
		
		If FilterElement.Key = "SupplyAssignment" Then
			
			// We use the line of business from the destination to select Contracts with the procedure for calculating "Sub-agreements of contractors":
			If FilterStructure1.Property("LineOfBusiness") Then
				Continue;
			EndIf;
			
			If Not ValueIsFilled(FilterValue) Then
				Continue;
			EndIf;
			
			LinesOfBusiness = Catalogs.Assignments.AreasOfActivityOfAppointments(
				CommonClientServer.ValueInArray(FilterValue));

			LineOfBusiness = LinesOfBusiness.Get(FilterValue);
			
			If LineOfBusiness = Undefined Then
				Continue;
			EndIf;
			
			AvailableAreasOfActivity = New Array;
			AvailableAreasOfActivity.Add(LineOfBusiness);
			AvailableAreasOfActivity.Add(Catalogs.LinesOfBusiness.EmptyRef());
				
			OrGroup = DataCompositionClientServer.AddSelectionGroup(
				List.Filter.Items,
				DataCompositionFilterItemsGroupType.OrGroup);
				
				DataCompositionClientServer.AddFilter(OrGroup,
					"LineOfBusiness",
					AvailableAreasOfActivity,
					DataCompositionComparisonType.InList);
				
				DataCompositionClientServer.AddFilter(OrGroup,
					"ARAPObjectSettings",
					Enums.ARAPObjectSettings.ByCounterpartyContracts,
					DataCompositionComparisonType.NotEqual);
			
			Continue;

		EndIf;
		
		If FilterElement.Key = "BusinessOperation" Then
			
			If FilterValue = Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt Or 
				FilterValue = Enums.BusinessTransactions.ImportFromEAEUInvoicedDelivery Then

				If ShowSeparatePurchaseContracts Then
	                FilterGroup = CommonClientServer.CreateFilterItemGroup(List.Filter, 
	                    "SeparationOfPurchases", DataCompositionFilterItemsGroupType.OrGroup);
					
                    CommonClientServer.AddCompositionItem(FilterGroup, "PurchaseRegistrationOption", 
						DataCompositionComparisonType.Equal, Enums.PurchaseRegistrationOptions.UninvoicedDeliveriesOfGoodsAndServices);
	
					ListOfOptionsForServices = New ValueList;
					ListOfOptionsForServices.Add(Enums.OptionsForRegisteringServiceDocuments.ReceiptOfServicesIsInvoiced);
					
					If ShowContractsReceiptOfServicesIsCanceled Then
						ListOfOptionsForServices.Add(Enums.OptionsForRegisteringServiceDocuments.ReceiptOfServicesIsReversed);
					EndIf;
					
					CommonClientServer.AddCompositionItem(FilterGroup,
					    "OptionForRegisteringServiceReceiptDocuments", DataCompositionComparisonType.InList, ListOfOptionsForServices);
					
					If FilterValue = Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt Then
						FilterValue = PurchasesServer.BusinessOperationsOnMain(Enums.BusinessTransactions.PurchaseFromSupplier);
					Else
						FilterValue = PurchasesServer.BusinessOperationsOnMain(Enums.BusinessTransactions.ImportFromEAEU);
					EndIf;
                EndIf;

			ElsIf FilterValue = Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle
				Or FilterValue = Enums.BusinessTransactions.TransferOfTitleToGoods
				Or FilterValue = Enums.BusinessTransactions.GoodsShipmentToCustomer Then
				
				FilterValue = Enums.BusinessTransactions.SaleToCustomer
				
			ElsIf ShowSeparatePurchaseContracts
				And (FilterValue = Enums.BusinessTransactions.PurchaseFromSupplier
					Or FilterValue = Enums.BusinessTransactions.PurchaseByImport
					Or FilterValue = Enums.BusinessTransactions.ImportFromEAEU) Then
				
				FilterValue = PurchasesServer.BusinessOperationsOnMain(FilterElement.Value);
				
				If Parameters.Property("ShowProductionAtProcessor")
					And (FilterElement.Value = Enums.BusinessTransactions.ImportFromEAEU
						Or FilterElement.Value = Enums.BusinessTransactions.PurchaseFromSupplier) Then
				
					If GetFunctionalOption("UseProductionByThirdParty2_5") Then
						If FilterElement.Value = Enums.BusinessTransactions.PurchaseFromSupplier Then 
							CommonClientServer.SupplementArray(FilterValue, 
										CommonClientServer.ValueInArray(Enums.BusinessTransactions.ProductionByToller2_5));
						ElsIf FilterElement.Value = Enums.BusinessTransactions.ImportFromEAEU Then 
							CommonClientServer.SupplementArray(FilterValue, 
										CommonClientServer.ValueInArray(Enums.BusinessTransactions.ProductionAtProcessorInEAEUCountries2_5));
						EndIf;
					EndIf;
					
				EndIf;
				
			ElsIf Not ShowSeparatePurchaseContracts
				And Parameters.Property("ShowProductionAtProcessor")
				And (FilterValue = Enums.BusinessTransactions.PurchaseFromSupplier
					Or FilterValue = Enums.BusinessTransactions.ImportFromEAEU) Then
					
				FilterValue = CommonClientServer.ValueInArray(FilterValue);
			
				If GetFunctionalOption("UseProductionByThirdParty2_5") Then
					If FilterElement.Value = Enums.BusinessTransactions.PurchaseFromSupplier Then 
						CommonClientServer.SupplementArray(FilterValue, 
									CommonClientServer.ValueInArray(Enums.BusinessTransactions.ProductionByToller2_5));
					ElsIf FilterElement.Value = Enums.BusinessTransactions.ImportFromEAEU Then 
						CommonClientServer.SupplementArray(FilterValue, 
									CommonClientServer.ValueInArray(Enums.BusinessTransactions.ProductionAtProcessorInEAEUCountries2_5));
					EndIf;
				EndIf;
			
			EndIf;
			
		EndIf;
		
		If ShowSalesThroughCommissionAgent = True
			And FilterElement.Key = "ARAPObjectSettings" Then
			If TypeOf(FilterValue) = Type("FixedArray") Then
				SelectionValueARAPObjectSettings = New Array(FilterValue);
			Else
				SelectionValueARAPObjectSettings = New Array();
				SelectionValueARAPObjectSettings.Add(FilterValue);
			EndIf;
			SelectionValueARAPObjectSettings.Add(Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice);
			FilterValue = SelectionValueARAPObjectSettings;
		EndIf;
		
		If TypeOf(FilterValue) = Type("Array")
			Or TypeOf(FilterValue) = Type("ValueList")
			Or TypeOf(FilterValue) = Type("FixedArray") Then
			
			LayoutComparisonView = DataCompositionComparisonType.InList;
			
		Else
			LayoutComparisonView = DataCompositionComparisonType.Equal;
		EndIf;
		
		CommonClientServer.SetDynamicListFilterItem(
			List,
			FilterElement.Key,
			FilterValue,
			LayoutComparisonView);
		
	EndDo;
	
EndProcedure

&AtServer
Procedure AddSelectionCounterpartyPartner(FilterGroup, FilterStructure1, CounterpartyPropertyName, PartnerPropertyName)
	
	FilterValue = Undefined;
	If FilterStructure1.Property("Counterparty", FilterValue) Then
		
		ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField(CounterpartyPropertyName);
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = FilterValue;
		
		If GetFunctionalOption("UsePartnersAsCounterparties") Then
			AttributeOfFilter = ?(ValueIsFilled(FilterValue),
								Common.ObjectAttributeValue(FilterValue, "Partner"),
								Catalogs.Partners.EmptyRef());
		Else
			AttributeOfFilter = FilterStructure1.Partner;
		EndIf;
		
		PartnerList = New ValueList;
		PartnersAndCounterparties.FillInListOfPartnersWithParents(AttributeOfFilter, PartnerList);
		
		If PartnerList.Count() = 0 Then
			ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = New DataCompositionField(PartnerPropertyName);
			ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
			ItemFilter.RightValue = AttributeOfFilter;
		Else
			ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = New DataCompositionField(PartnerPropertyName);
			ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
			ItemFilter.RightValue = PartnerList;
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion
