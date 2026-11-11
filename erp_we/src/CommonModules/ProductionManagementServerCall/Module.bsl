////////////////////////////////////////////////////////////////////////////////
// Production Management: Contains procedures for production management.
// The module is part of the "Enterprise Management" subsystem.
// 
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Generates a view of the production order.
//
// Parameters:
//  Ref	 - DocumentRef.ProductionOrder2_2 - production order
//  Prefix	 - String								 - prefix.
// 
// Returns:
//  String - submission of a production order.
//
Function OrderPresentation(Ref, Prefix = Undefined) Export
	
	Return Documents.ProductionOrder2_2.OrderPresentation(Ref, Prefix);
	
EndFunction

// Creates a representation of the production stage based on the document data.
//
// Parameters:
//  Data_Stage - See Documents.ProductionStage2_2.PresentationStage.
// 
// Returns:
//  String - presentation of the production stage.
//
Function PresentationStage(Data_Stage) Export
	
	Return Documents.ProductionStage2_2.PresentationStage(Data_Stage);
	
EndFunction

// Sets the date based on the passed mark
//
// Parameters:
//  Mark		 - Boolean	 - Mark
//  DateField_	 - Date		 - details to set the date in
//  EventDate	 - Date		 - set date
//  Erase	 - Boolean	 - indicates that the date must be set forcibly.
//
Procedure SetDateByMark(Mark, DateField_, EventDate = Undefined, Erase = False) Export
	
	ProductionManagement.SetDateByMark(
				Mark,
				DateField_, EventDate, Erase);
	
EndProcedure

// Returns values for filling in a new production stage
//
// Parameters:
//  ReferenceOrder				 - DocumentRef.ProductionOrder2_2 			 - production order
//  AssignmentProducts			 - CatalogRef.Assignments						 - product designation ( when separated by purpose )
//  ProductionLot			 - CatalogRef.ProductionLots				 - Production batch
//  ProductionProcessType - EnumRef.ProductionProcessTypes	 - type of production process.
//  BillOfMaterials				 - CatalogRef.BillsOfMaterials			 - resource specification.
// 
// Returns:
//  Structure - filling values of the new production stage:
//   * ReferenceOrder                     - DocumentRef.ProductionOrder2_2 -
//   * DynamicStructure            - Boolean -
//   * Organization                      - CatalogRef.Companies -
//   * BusinessOperation            - EnumRef.BusinessTransactions -
//   * LineOfBusiness          - CatalogRef.LinesOfBusiness -
//   * Partner                          - CatalogRef.Partners -
//   * Contract                          - CatalogRef.CounterpartyContracts -
//   * ProductionIssueForActivity            - EnumRef.VATTaxationTypes -
//   * OperationAsOutputReference - See ProductionManagement.UseProductionOperationsAsReferencesForOutput
//   * PriceKind                          - See Catalogs.TypesOfPrices.TypeOfPricePlannedCostOfInventory
//   * Currency                           - See IncomeAndExpensesServer.GetCurrencyOfManagementAccounting
//   * GoodsReceiptOption            - EnumRef.GoodsReceiptOptions -
//   * AssignmentProducts              - CatalogRef.Assignments -
//   * ProductionLot               - CatalogRef.ProductionLots -
//   * ProductionProcessType     - EnumRef.ProductionProcessTypes -
//   * BillOfMaterials                     - CatalogRef.BillsOfMaterials -
//   * ResponsibleBusinessUnit       - See Catalogs.BillsOfMaterials.ResponsibleBusinessUnit
//
Function ValuesForFillingNewProductionStage(ReferenceOrder,
													AssignmentProducts,
													ProductionLot,
													ProductionProcessType,
													BillOfMaterials) Export
	
	Result = AttributesOfNewStageOfProduction();
	
	AttributesNames = New Structure;
	AttributesNames.Insert("ReferenceOrder", "Ref");
	AttributesNames.Insert("DynamicStructure");
	AttributesNames.Insert("Organization");
	AttributesNames.Insert("BusinessOperation");
	AttributesNames.Insert("LineOfBusiness");
	AttributesNames.Insert("Partner");
	AttributesNames.Insert("Contract");
	AttributesNames.Insert("ProductionIssueForActivity", "OrderForActivity");
	
	AttributesValues = Common.ObjectAttributesValues(ReferenceOrder, AttributesNames);
	FillPropertyValues(Result, AttributesValues);
	
	If ValueIsFilled(AssignmentProducts) Then
		LineOfBusiness = ProductionManagementCached.DirectionOfActivityPurposeOfProduction(AssignmentProducts);
		Result.LineOfBusiness = LineOfBusiness;
	EndIf;
	
	ResponsibleBusinessUnit = Catalogs.BillsOfMaterials.ResponsibleBusinessUnit(BillOfMaterials);
	Result.ResponsibleBusinessUnit = ResponsibleBusinessUnit;
	
	Result.AssignmentProducts = AssignmentProducts;
	Result.ProductionLot = ProductionLot;
	Result.ProductionProcessType = ProductionProcessType;
	Result.BillOfMaterials = BillOfMaterials;
	
	Return Result;
	
EndFunction

// A list of Attributes for filling in a new stage of production.
// The values of Attributes that do not depend on the data are filled in.
// 
// Returns:
//  Structure - Attributes Of The New Stage Of Production:
// * ReferenceOrder - Undefined
// * DynamicStructure - Undefined
// * Organization - Undefined
// * BusinessOperation - Undefined
// * LineOfBusiness - Undefined
// * Partner - Undefined
// * Contract - Undefined
// * ProductionIssueForActivity - Undefined
// * AssignmentProducts - Undefined
// * ProductionLot - Undefined
// * ProductionProcessType - Undefined
// * BillOfMaterials - Undefined
// * ResponsibleBusinessUnit - Undefined
// * OperationAsOutputReference - Boolean - 
// * PriceKind - CatalogRef.TypesOfPrices, Undefined - 
// * Currency - CatalogRef.Currencies, Undefined - 
// * GoodsReceiptOption - EnumRef.GoodsReceiptOptions
//
Function AttributesOfNewStageOfProduction() Export
	
	Result = New Structure;
	
	Result.Insert("ReferenceOrder", Undefined);
	Result.Insert("DynamicStructure", Undefined);
	Result.Insert("Organization", Undefined);
	Result.Insert("BusinessOperation", Undefined);
	Result.Insert("LineOfBusiness", Undefined);
	Result.Insert("Partner", Undefined);
	Result.Insert("Contract", Undefined);
	Result.Insert("ProductionIssueForActivity", Undefined);
	Result.Insert("AssignmentProducts", Undefined);
	Result.Insert("ProductionLot", Undefined);
	Result.Insert("ProductionProcessType", Undefined);
	Result.Insert("BillOfMaterials", Undefined);
	Result.Insert("ResponsibleBusinessUnit", Undefined);
	
	OperationAsOutputReference = ProductionManagement.UseProductionOperationsAsReferencesForOutput(
		CurrentSessionDate());
	Result.Insert("OperationAsOutputReference", OperationAsOutputReference);
	
	PriceKind = Catalogs.TypesOfPrices.TypeOfPricePlannedCostOfInventory();
	Result.Insert("PriceKind", PriceKind);
	
	Currency = IncomeAndExpensesServer.GetCurrencyOfManagementAccounting(
		Catalogs.TypesOfPrices.GetPriceTypeDetails(PriceKind).PriceCurrency);
	Result.Insert("Currency", Currency);
	
	GoodsReceiptOption = Constants.GoodsReceiptOption.Get();
	Result.Insert("GoodsReceiptOption", GoodsReceiptOption);
	
	Return Result;
	
EndFunction

#EndRegion

#Region Private

// Parameters:
//  ReferencesArrray - Array of DocumentRef.ProductionStage2_2 - List of production stages.
// 
// Returns:
//  Map of CatalogRef.BusinessStructure - divisions-executors of production stages.
//
Function DivisionsPerformers(ReferencesArrray) Export
	
	Return Common.ObjectsAttributeValue(ReferencesArrray, "Department");
	
EndFunction

// Parameters:
//  ArrayOfStages - Array of DocumentRef.ProductionStage2_2
// 
// Returns:
//  Array of DocumentRef.ProductionStage2_2 - List Of Production Steps Available For Deletion
//
Function ListOfProductionStepsAvailableForDeletion(ArrayOfStages) Export
	
	Query = New Query;
	Query.Text = Documents.ProductionStage2_2.QueryTextListOfProductionStepsAvailableForDeletion();
	Query.SetParameter("ReferencesArrray", ArrayOfStages);
	
	Result = Query.Execute();
	
	Return Result.Unload().UnloadColumn("Ref");
	
EndFunction

// Parameters:
//  ProductionLot - See Documents.ProductionStage2_2.StepOnBarcodeOfProductionBatch.ProductionLot
// 
// Returns:
//  DocumentRef.ProductionStage2_2, Undefined -
//
Function StepOnBarcodeOfProductionBatch(ProductionLot) Export
	
	Return Documents.ProductionStage2_2.StepOnBarcodeOfProductionBatch(ProductionLot);
	
EndFunction

// Returns:
//  Boolean -
//
Function DynamicStructureOfProductionOrders() Export
	
	Return GetFunctionalOption("DynamicStructureOfProductionOrders");
	
EndFunction

#EndRegion
