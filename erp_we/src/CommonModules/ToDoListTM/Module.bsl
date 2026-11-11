
#Region Public

// Fills in the list of to-do handlers.
//
// Parameters:
//  Handlers - Array - an array of links to Manager modules or shared modules that
//                         define the procedure for filling in current Data.
//
Procedure OnDetermineToDoListHandlers(Handlers) Export
	
	Handlers.Add(Catalogs.SalesOpportunitiesToCustomer);
	
	Handlers.Add(Catalogs.TermsOfSale);
	
	// Supplier Agreements (2h)
	Handlers.Add(Catalogs.TermsOfPurchaseFromVendors);
	
	// Contract with customers (2h)
	// Contract with suppliers (2h)
	Handlers.Add(Catalogs.CounterpartyContracts);

	// Customer Order (4h)
	Handlers.Add(Documents.SalesOrder);
	
	// The application for the return of the client's goods (4h)
	Handlers.Add(Documents.RequestForReturnOfGoodsFromCustomer);
	
	// Orders of Access (1T)
	Handlers.Add(DataProcessors.InboundWarehouseMangement);
	
	// Unloading Orders (1T)
	Handlers.Add(DataProcessors.ShipGoodsFromWarehouse);
	
	// Order to suppliers (4h)
	Handlers.Add(Documents.PurchaseOrder);
	
	// Application for payment (2h)
	Handlers.Add(Documents.PaymentRequest);
	
	// Tasks for Trade representatives (3h)
	Handlers.Add(Documents.JobForSalesRepresentative);
	
	// Power of attorney for the receipt of goods (4h)
	Handlers.Add(Documents.IssuedLetterOfAuthority);
	
	// Moving of goods (2h)
	Handlers.Add(Documents.InventoryTransfer);
	
	// formalizationskladskihaktov (1h)
	Handlers.Add(DataProcessors.WarehouseGoodsIssueReceipt);
	
	// Commissioners' report (1h)
	Handlers.Add(DataProcessors.ConsignmentReportsFromCustomers);
	
	// Report to clients (1h)
	Handlers.Add(DataProcessors.AccountSalesToConsignors);
	
	// Internal consumption (3h)
	Handlers.Add(Documents.InventoryConsumption);
	
	// Document Disassembly (3h)
	Handlers.Add(Documents.AssemblyFromComponents);
	
	// Document of access to Goods and services (1h)
	Handlers.Add(Documents.VendorInvoice);
	
	// Documentsrealization of goods and services (4h)
	Handlers.Add(Documents.CustomerInvoice);
	
	// Purchase plan (1h)
	Handlers.Add(Documents.PurchasePlan);
	
	// Planesstates (1h)
	Handlers.Add(Documents.PlanOfGoodsStock);
	
	// Sales plans (1h)
	Handlers.Add(Documents.SalesPlan);
	
	// Internal consumption plan (1h)
	Handlers.Add(Documents.InventoryConsumptionPlan);
	
	Handlers.Add(Documents.SalesPlanByCategories);
	
	// Disassembly plan (1h)
	Handlers.Add(Documents.AssemblyDisassemblyPlan);
	
	
	// Production plans (1h)
	Handlers.Add(Documents.ProductionPlan);
	// (2T)
	Handlers.Add(DataProcessors.AvailabilityOfWorkCenterTypes);
	
	
	// Documentationproduction of materials (1h)
	Handlers.Add(Documents.MovementOfProductsAndMaterials);
	
	
	// Production of workers (1h)
	Handlers.Add(Documents.WorkOutput);
	
	
	// (1h)
	Handlers.Add(Documents.SubcontractOrder2_5);
	// Document transmission to the Storekeeper (4h)
	Handlers.Add(Documents.TransferOfGoodsToBailee);
	
	// (1h)
	Handlers.Add(Documents.SubcontractorReport2_5);
	
	// The document of the access of the storage goods (4h)
	Handlers.Add(Documents.ReceiptOfGoodsFromCustodian);
	
	// (1h)
	Handlers.Add(Documents.ReportToMaterialProvider2_5);
	
	// (1h)
	Handlers.Add(Documents.GoodsReceiptForStorage);
	
	// (1h)
	Handlers.Add(Documents.GoodsShipmentFromStorage);
	
	// The budgeting tasks
	Handlers.Add(Tasks.BudgetTask);
	Handlers.Add(Documents.ApplicationForCollateral);
	
	Handlers.Add(Documents.PurchaseRequest);
	
	// Document of Goods availability (1h)
	Handlers.Add(Documents.ReceiptOfGoodsToWarehouse);

	// Commercial Proposals and Documents (2h)
	Handlers.Add(Documents.CommercialProposalForCustomer);
	
EndProcedure

#EndRegion
