
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	CommonClientServer.SetDynamicListParameter(List, "Partner",		Parameters.Partner);
	CommonClientServer.SetDynamicListParameter(List, "Counterparty",	Parameters.Counterparty);
	CommonClientServer.SetDynamicListParameter(List, "Terms",	Parameters.Terms);
	CommonClientServer.SetDynamicListParameter(List, "Organization",	Parameters.Organization);
	CommonClientServer.SetDynamicListParameter(List, "Contract",		Parameters.Contract);
	
	BusinessOperationsAgreements = New Array;
	BusinessOperationsAgreements.Add(Enums.BusinessTransactions.ImportFromEAEU);
	BusinessOperationsAgreements.Add(Enums.BusinessTransactions.PurchaseByImport);
	BusinessOperationsAgreements.Add(Enums.BusinessTransactions.PurchaseFromSupplier);
	
	BusinessOperationsOfTheContract = New Array;
	BusinessOperationsOfTheContract.Add(Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt);
	BusinessOperationsOfTheContract.Add(Enums.BusinessTransactions.ImportFromEAEUInvoicedDelivery);
	BusinessOperationsOfTheContract.Add(Enums.BusinessTransactions.ImportFromEAEU);
	BusinessOperationsOfTheContract.Add(Enums.BusinessTransactions.PurchaseByImport);
	BusinessOperationsOfTheContract.Add(Enums.BusinessTransactions.PurchaseFromSupplier);
	BusinessOperationsOfTheContract.Add(Enums.BusinessTransactions.PurchaseFromVendorGoodsInTransit);
	BusinessOperationsOfTheContract.Add(Enums.BusinessTransactions.ImportGoodsInTransit);
	BusinessOperationsOfTheContract.Add(Enums.BusinessTransactions.ImportFromEAEUGoodsInTransit);
	
	SelectionOfContracts = True;
	ChoosingOrders = True;
	
	If Parameters.BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorUninvoicedDelivery
		Or Parameters.BusinessOperation = Enums.BusinessTransactions.ImportFromEAEUUninvoicedDelivery Then
		OptionOfAcceptanceOfContractServices = Common.ObjectAttributeValue(Parameters.Contract, "ServiceReceiptOption");
			
		If OptionOfAcceptanceOfContractServices = Enums.GoodsReceiptOptions.ByContractsAfterOrdersOrInvoices 
			Or OptionOfAcceptanceOfContractServices = Enums.GoodsReceiptOptions.UnderContractsWithoutOrdersAndInvoices Then
			ChoosingOrders = False;
			BusinessOperationsOfTheContract.Add(Enums.BusinessTransactions.PurchaseFromSupplier);
		ElsIf OptionOfAcceptanceOfContractServices = Enums.GoodsReceiptOptions.DividedByOrdersAndInvoices Then
			SelectionOfContracts = False;
		EndIf;
	EndIf;
	
	CommonClientServer.SetDynamicListParameter(List, "SelectionOfContracts", SelectionOfContracts);
	CommonClientServer.SetDynamicListParameter(List, "ChoosingOrders", ChoosingOrders);
	
	CommonClientServer.SetDynamicListParameter(List,
																		"BusinessOperation",
																		Parameters.BusinessOperation);
	CommonClientServer.SetDynamicListParameter(List,
																		"BusinessOperationsOfTheContract",
																		BusinessOperationsOfTheContract);
	CommonClientServer.SetDynamicListParameter(List,
																		"BusinessOperationsAgreements",
																		BusinessOperationsAgreements);
	
	OrderAcceptanceOptions = New Array;
	OrderAcceptanceOptions.Add(Enums.GoodsReceiptOptions.DividedByOrdersAndInvoices);
	
	CommonClientServer.SetDynamicListParameter(List,
																		"OrderAcceptanceOptions",
																		OrderAcceptanceOptions);
	
	OptionsForAcceptanceByInvoiceByOrder = New Array;
	OptionsForAcceptanceByInvoiceByOrder.Add(Enums.GoodsReceiptOptions.SplitByInvoicesOnly);
	
	CommonClientServer.SetDynamicListParameter(List,
																		"OptionsForAcceptanceByInvoiceByOrder",
																		OptionsForAcceptanceByInvoiceByOrder);
	
	AcceptanceOptionsForInvoiceWithoutOrder = New Array;
	AcceptanceOptionsForInvoiceWithoutOrder.Add(Enums.GoodsReceiptOptions.SplitByInvoicesOnly);
	AcceptanceOptionsForInvoiceWithoutOrder.Add(Enums.GoodsReceiptOptions.DividedByOrdersAndInvoices);
	
	CommonClientServer.SetDynamicListParameter(List,
																		"AcceptanceOptionsForInvoiceWithoutOrder",
																		AcceptanceOptionsForInvoiceWithoutOrder);

	AcceptanceOptionsUnderTheAgreement = New Array;
	AcceptanceOptionsUnderTheAgreement.Add(Enums.GoodsReceiptOptions.GoodsReceiptWithoutReferenceToOrdersAndInvoicesAllowed);
	AcceptanceOptionsUnderTheAgreement.Add(Enums.GoodsReceiptOptions.NotDividedByOrdersAndInvoices);
	AcceptanceOptionsUnderTheAgreement.Add(Enums.GoodsReceiptOptions.NotSeparatedByInvoices);
	
	ContractAcceptanceOptions = New Array;
	ContractAcceptanceOptions.Add(Enums.GoodsReceiptOptions.UnderContractsWithoutOrdersAndInvoices);
	ContractAcceptanceOptions.Add(Enums.GoodsReceiptOptions.ByContractsAfterOrdersOrInvoices);
	ContractAcceptanceOptions.Add(Enums.GoodsReceiptOptions.ByContractsAfterInvoices);
	
	CommonClientServer.SetDynamicListParameter(List,
																		"ContractAcceptanceOptions",
																		ContractAcceptanceOptions);
	
	CommonClientServer.SetDynamicListParameter(List,
																		"ConstantAcceptanceOption",
																		Constants.GoodsReceiptOption.Get());
	
	CommonClientServer.SetDynamicListParameter(List,
																		"UseGoodsInTransitFromVendors",
																		GetFunctionalOption("UseGoodsInTransitFromVendors"));
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	ProcessSelection(Item.CurrentData);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Select(Command)
	
	If TMCommonUseClient.CheckForSelectedLinesInList(Items.List) Then
		ProcessSelection(Items.List.CurrentData);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

// Parameters:
// 	CurrentRow - FormDataCollectionItem, FormDataTreeItem, FormDataStructure - Contains:
//	* Ref                - DocumentRef.PurchaseOrder - 
//	* Partner               - CatalogRef.Partners - 
//	* Counterparty            - CatalogRef.Counterparties - 
//	* Terms            - CatalogRef.TermsOfPurchaseFromVendors - 
//	* BusinessOperation - EnumRef.BusinessTransactions - 
//	* Organization           - CatalogRef.Companies - 
//	* Contract               - CatalogRef.CounterpartyContracts - 
//	* Currency                - CatalogRef.Currencies - 
//	* VendorPriceKind     - CatalogRef.VendorPriceTypes - 
&AtClient
Procedure ProcessSelection(CurrentRow)
	
	ValueSelected = New Structure;
	ValueSelected.Insert("ReferenceOrder",			CurrentRow.Ref);
	ValueSelected.Insert("Partner",				CurrentRow.Partner);
	ValueSelected.Insert("Counterparty",			CurrentRow.Counterparty);
	ValueSelected.Insert("Terms",			CurrentRow.Terms);
	ValueSelected.Insert("BusinessOperation",	CurrentRow.BusinessOperation);
	ValueSelected.Insert("Organization",			CurrentRow.Organization);
	ValueSelected.Insert("Contract",				CurrentRow.Contract);
	ValueSelected.Insert("Currency",				CurrentRow.Currency);
	ValueSelected.Insert("VendorPriceKind",		CurrentRow.VendorPriceKind);
	
	Close(ValueSelected);
	
EndProcedure

#EndRegion
