
#Region Public

// Returns True if it is a subordinate RIB node
//
// Returns:
// 	Boolean - 
Function IsSubordinateDIBNode() Export
	
	Result = DataExchangeServer.IsSubordinateDIBNode();
	
	Return Result
	
EndFunction

// Returns whether operations to close the month are available in the current is.
//
// Parameters:
//   Cancel - Boolean - indicates that the operation was refused.
//
// Returns:
//   Boolean - True if the execution of operations to close the month is available in this information system,
//            False - otherwise.
//
Function MonthClosingOperationsAreAvailableInThisNode(Cancel) Export
	
	If ExchangePlans.MasterNode() <> Undefined Then
		
		Cancel = True;
		
		UserMessage = 
			NStr("vi = 'Không cần thực hiện các giao dịch thường kỳ liên quan đến đóng tháng
			|trong nút trực thuộc của cơ sở thông tin phân tán,
			|chỉ cần thực hiện chúng trong nút cơ sở thông tin chính.';
			|ru = 'Выполнять регламентные операции связанные с закрытием месяца
			|в подчиненном узле распределенной информационной базы не требуется,
			|они выполняются только в центральном узле информационной базы.';
			|en = 'It is not required to execute period-end transactions connected with
			|month-end closing in the subnode of the distributed infobase;
			|they are executed only in the central infobase node.'; fa = 'It is not required to execute period-end transactions connected with
			|month-end closing in the subnode of the distributed infobase;
			|they are executed only in the central infobase node.';
			|it = 'Non è necessario eseguire operazioni di manutenzione ordinaria relative alla chiusura del mese
			| in un nodo slave di un database di informazioni distribuito,
			|vengono eseguite solo nel nodo centrale del database di informazioni.';
			|pl = 'Wykonywać operacje reglamentowane związane z zamknięciem miesiąca
			|w podporządkowanym węźle podzielonej bazy informacyjnej nie trzeba,
			|są one wykonywane tylko w centralnym węźle bazy informacyjnej.';
			|tr = 'Ay sonu kapanışı
			|ile ilgili dönem sonu işlemlerinin dağıtılan infobase''in alt ünitesinde gerçekleştirilmesine gerek yoktur,
			|sadece infobase''in merkezi ünitesinde gerçekleştirilir.'");
			
		Common.MessageToUser(UserMessage);
		
		Return False;
		
	EndIf;
	
	Return True;
	
EndFunction

// Specifies the list of available versions of the universal EnterpriseData format.
//
// Parameters:
//  FormatVersions - Map - Matches the format version number to the General module
//                  that contains the upload/download handlers for this version.
//
Procedure AvailableVersionsOfUniversalFormat(FormatVersions) Export
	
	FormatVersions.Insert("1.7", ExchangeManagerViaUniversalFormat);
	FormatVersions.Insert("1.8", ExchangeManagerViaUniversalFormat);
	FormatVersions.Insert("1.10", ExchangeManagerViaUniversalFormat);
	FormatVersions.Insert("1.11", ExchangeManagerViaUniversalFormat);
	FormatVersions.Insert("1.12", ExchangeManagerViaUniversalFormat);
	FormatVersions.Insert("1.15", ExchangeManagerViaUniversalFormat);
	FormatVersions.Insert("1.16", ExchangeManagerViaUniversalFormat);
	FormatVersions.Insert("1.17", ExchangeManagerViaUniversalFormat);
	FormatVersions.Insert("1.19", ExchangeManagerViaUniversalFormat);
	FormatVersions.Insert("1.20", ExchangeManagerViaUniversalFormat);
	FormatVersions.Insert("1.21", ExchangeManagerViaUniversalFormat);
	FormatVersions.Insert("1.22", ExchangeManagerViaUniversalFormat);
EndProcedure

// Handler after loading the data.
// Used in standard conversion rules for data exchanges and transfers.
// Called from the corresponding "After data loading" event handler for conversion rules.
//
// Parameters:
//  Parameters - Structure - structure with properties:
//            * CheckForUseOfImportedGoods - Boolean - If True , the use
//              of imported goods will be enabled if necessary (if the database contains elements of the reference book "GTD Numbers").
//            * CheckForUseOfImportPurchases - Boolean - If True, the use
//              of import purchases will be enabled (if the database contains the corresponding operations).
//            * CheckWhetherCommissionIsUsedInPurchases - Boolean - If True, the
//              Commission will be enabled for purchases (if the database contains the corresponding operations).
//            * CheckForCommissionOnSales - Boolean - If True, the use
//              of Commission for sales will be enabled (if there are corresponding operations in the database).
//            * CheckForUseOfContracts - Boolean - If True, the use
//              of counterparty agreements will be enabled (if there is at least one contract with the buyer in the database).
//            * CheckForRetailSalesUsage - Boolean - If True, the use
//              of retail sales will be enabled (if there are corresponding operations in the database).
//            * CheckForMovementUsage - Boolean - If True, the use
//              of product movements will be enabled (if there are corresponding operations in the database).
//            * CheckForUseOfSeveralTypesOfProducts - Boolean - If True, the use
//              of multiple item types will be enabled (if there are 3 or more item types).
//            * CheckForUseOfAlcoholicBeveragesInRetail - Boolean - If True, it will include
//              the use of retail sales of alcoholic beverages (if the database has types of nomenclature C).
//              a symptom of "Alcohol products").
//            * CheckForUseOfShipmentWithoutTransferOfOwnership - Boolean - If True
//              , the use of shipment operations without transfer of ownership will be enabled (if the database contains the corresponding
//              operations.
//
Procedure AfterImportData(Parameters) Export
	
	If Parameters.CheckForUseOfImportedGoods
		And Not GetFunctionalOption("UseImportedGoods") Then
		
		Query = New Query(
		"SELECT TOP 1
		|	1 AS Field1
		|FROM
		|	Catalog.CCDNumbers AS CCDNumbers");
		
		If Not Query.Execute().IsEmpty() Then
			Constants.UseImportedGoods.Set(True);
		EndIf;
		
	EndIf;
	
	If Parameters.CheckForUseOfImportPurchases
		And Not GetFunctionalOption("UseImports") Then
		
		Query = New Query(
		"SELECT TOP 1
		|	1 AS Field1
		|FROM
		|	Document.CCDImport AS Doc
		|
		|UNION ALL
		|
		|SELECT
		|	1
		|FROM
		|	Document.VendorInvoice AS Doc
		|WHERE
		|	Doc.BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseByImport)");
		
		If Not Query.Execute().IsEmpty() Then
			Constants.UseImports.Set(True);
			If Not GetFunctionalOption("UseImportedGoods") Then
				Constants.UseImportedGoods.Set(True);
			EndIf;
		EndIf;
		
	EndIf;
	
	If Parameters.CheckWhetherCommissionIsUsedInPurchases
		And Not GetFunctionalOption("UsePurchaseCommission") Then
		
		Query = New Query(
		"SELECT TOP 1
		|	1 AS Field1
		|FROM
		|	Document.ConsignmentReportToVendor AS Doc
		|
		|UNION ALL
		|
		|SELECT
		|	1
		|FROM
		|	Document.VendorInvoice AS Doc
		|WHERE
		|	Doc.BusinessOperation = VALUE(Enum.BusinessTransactions.ConsignmentProcurement)");
		
		If Not Query.Execute().IsEmpty() Then
			Constants.UsePurchaseCommission.Set(True);
		EndIf;
		
	EndIf;
	
	If Parameters.CheckForCommissionOnSales
		And Not GetFunctionalOption("UseSalesCommission") Then
		
		Query = New Query(
		"SELECT TOP 1
		|	1 AS Field1
		|FROM
		|	Document.ConsignmentReportFromCustomer AS Doc
		|
		|UNION ALL
		|
		|SELECT
		|	1
		|FROM
		|	Document.CustomerInvoice AS Doc
		|WHERE
		|	Doc.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToCommissionAgent)");
		
		If Not Query.Execute().IsEmpty() Then
			If Constants.UseTermsOfSales.Get() = Enums.UseTermsOfSales.DontUse Then
				EnableUseOfCustomerAgreementsIfNecessary();
				If Constants.UseTermsOfSales.Get() = Enums.UseTermsOfSales.DontUse Then
					Constants.UseTermsOfSales.Set(Enums.UseTermsOfSales.OnlyStandardTermsOfSales);
				EndIf;
			EndIf;
			Constants.UseSalesCommission.Set(True);
		EndIf;
		
	EndIf;
	
	If Parameters.CheckForUseOfContracts Then
		
		If Not GetFunctionalOption("UseCustomerContracts") Then
		
			Query = New Query(
			"SELECT TOP 1
			|	1 AS Field1
			|FROM
			|	Catalog.CounterpartyContracts AS Cat
			|WHERE
			|	Cat.ContractType = VALUE(Enum.ContractTypes.WithCustomer)");
			
			If Not Query.Execute().IsEmpty() Then
				Constants.UseCustomerContracts.Set(True);
			EndIf;
			
		EndIf;
		
		If Not GetFunctionalOption("UseContractsWithVendors") Then
		
			Query = New Query(
			"SELECT TOP 1
			|	1 AS Field1
			|FROM
			|	Catalog.CounterpartyContracts AS Cat
			|WHERE
			|	Cat.ContractType = VALUE(Enum.ContractTypes.WithVendor)");
			
			If Not Query.Execute().IsEmpty() Then
				Constants.UseContractsWithVendors.Set(True);
			EndIf;
			
		EndIf;
		
	EndIf;
	
	If Parameters.CheckForRetailSalesUsage
		And Not GetFunctionalOption("UseRetailSales") Then
		
		Query = New Query(
		"SELECT TOP 1
		|	1 AS Field1
		|FROM
		|	Document.RetailSalesReport AS Doc
		|
		|UNION ALL
		|
		|SELECT
		|	1
		|FROM
		|	Document.CashAccountReceiptNote AS Doc
		|WHERE
		|	Doc.BusinessOperation = VALUE(Enum.BusinessTransactions.CashReceiptFromCashRegister)");
		
		If Not Query.Execute().IsEmpty() Then
			Constants.UseRetailSales.Set(True);
		EndIf;
		
	EndIf;
	
	If Parameters.CheckForMovementUsage
		And Not GetFunctionalOption("UseGoodsTransfer") Then
		
		Query = New Query(
		"SELECT TOP 1
		|	1 AS Field1
		|FROM
		|	Document.InventoryTransfer AS Doc");
		
		If Not Query.Execute().IsEmpty() Then
			Constants.UseGoodsTransfer.Set(True);
		EndIf;
		
	EndIf;
	If Parameters.CheckForUseOfSeveralTypesOfProducts
		And Not GetFunctionalOption("UseMultipleKindsOfProducts") Then
		
		Query = New Query(
				"SELECT 
				|	COUNT(Cat.Ref) AS Count
				|FROM
				|	Catalog.ItemKinds AS Cat");
		Selection = Query.Execute().Select();
		Selection.Next();
		If Selection.Count > 2 Then
			Constants.UseMultipleKindsOfProducts.Set(True);
		EndIf;
		
	EndIf;
	
	
	If Parameters.CheckForUseOfShipmentWithoutTransferOfOwnership Then
		
		UseStatusesOfImplementations = False;
		
		If Not GetFunctionalOption("UseShipmentWithDeferredTransferOfTitle2_0") Then
			
			Query = New Query;
			Query.Text =
			"SELECT TOP 1
			|	TRUE
			|FROM
			|	Document.CustomerInvoice AS TableOfImplementations
			|WHERE
			|	TableOfImplementations.BusinessOperation =
			|	VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle)";
			
			QueryResult = Query.Execute();
			If Not QueryResult.IsEmpty() Then
				
				Constants.UseShipmentWithDeferredTransferOfTitle.Set(True);
				Constants.UseShipmentWithDeferredTransferOfTitle2_0.Set(True);
				
				UseStatusesOfImplementations = True;
				
			EndIf;
			
		EndIf;
		
		If Not GetFunctionalOption("UseShipmentWithDeferredTransferOfTitle2_5")
			And GetFunctionalOption("UseCustomerContracts") Then
			
			Query = New Query;
			Query.Text =
			"SELECT TOP 1
			|	TRUE
			|FROM
			|	Document.CustomerInvoice AS TableOfImplementations
			|WHERE
			|	TableOfImplementations.BusinessOperation =
			|	VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)";
			
			QueryResult = Query.Execute();
			If Not QueryResult.IsEmpty() Then
				
				Constants.UseShipmentWithDeferredTransferOfTitle.Set(True);
				Constants.UseShipmentWithDeferredTransferOfTitle2_5.Set(True);
				
				UseStatusesOfImplementations = True;
				
			EndIf;
			
		EndIf;
		
		If Not GetFunctionalOption("UseStatusesOfGoodsServicesSales")
			And UseStatusesOfImplementations Then
			Constants.UseStatusesOfGoodsServicesSales.Set(True);
		EndIf;
		
	EndIf;
		
EndProcedure

#Region UploadingLoadingDataInService

// Procedure-handler for the "pre-loading Object" event for the data upload/download mechanism in the service.
// 
// Parameters:
//   Container - DataProcessorObject.ExportImportDataContainerManager - Manager
//               the container used in the data loading process.
//   Object      - ConstantValueManager
//               - CatalogObject
//               - DocumentObject
//               - BusinessProcessObject
//               - TaskObject
//               - ChartOfAccountsObject
//               - ExchangePlanObject
//               - ChartOfCharacteristicTypesObject
//               - ChartOfCalculationTypesObject
//               - InformationRegisterRecordSet
//               - AccumulationRegisterRecordSet
//               - AccountingRegisterRecordSet
//               - CalculationRegisterRecordSet
//               - SequenceRecordSet
//               - RecalculationRecordSet - the data object of the information database, before loading which the handler was called.
//               The value passed to the preloading procedure of the object() as the parameter value
//               The object can be modified inside the handler procedure before loading the object().
//   Artifacts - Array - additional data that is logically inextricably linked
//               to the data object, but is not part of it. Generated in exported procedures
//               Before loading the object() of the data unloading handlers (see the procedure comment
//               When registering the processing of the uploaded data(). Each artifact must be an XDTO object,
//               for which an abstract XDTO type is used as the base type
//               {http://www.1c.ru/1cFresh/Data/Dump/1.0.2.1}Artefact. It is allowed to use XDTO packages,
//               in addition to those originally supplied as part of the data unloading subsystem.
//   Cancel     - Boolean - If the value of this
//               parameter is set to True in the procedure before loading the object (), the data object will not be loaded.
//
Procedure BeforeImportObject(Container, Object, Artifacts, Cancel) Export
	
	Object.AdditionalProperties.Insert("RegisterPrimaryDocumentData", False);
	
EndProcedure

#EndRegion

#EndRegion

#Region Internal

Procedure OnDataExport(StandardProcessing,
		Recipient,
		MessageFileName,
		MessageData,
		TransactionItemsCount,
		EventLogEventName,
		SentObjectsCount) Export
		
	InformationRegisters.RefinementsOfRetailOutletInventoryAffiliation.FillingOutSpecificationOfInventoryBelongingToRetailOutlets(Recipient);
		
EndProcedure
#EndRegion

#Region Private

// This function prepares the structure of parameters that are used when syncing data using a universal format.
// Returns:
//    Structure - structure with properties:
//            * CheckForUseOfImportedGoods - Boolean - If True , the use
//              of imported goods will be enabled if necessary (if the database contains elements of the reference book "GTD Numbers").
//            * CheckForUseOfImportPurchases - Boolean - If True, the use
//              of import purchases will be enabled (if the database contains the corresponding operations).
//            * CheckWhetherCommissionIsUsedInPurchases - Boolean - If True, the
//              Commission will be enabled for purchases (if the database contains the corresponding operations).
//            * CheckForCommissionOnSales - Boolean - If True, the use
//              of Commission for sales will be enabled (if there are corresponding operations in the database).
//            * CheckForUseOfContracts - Boolean - If True, the use
//              of counterparty agreements will be enabled (if there is at least one contract with the buyer in the database).
//            * CheckForRetailSalesUsage - Boolean - If True, the use
//              of retail sales will be enabled (if there are corresponding operations in the database).
//            * CheckForMovementUsage - Boolean - If True, the use
//              of product movements will be enabled (if there are corresponding operations in the database).
//            * CheckForUseOfSeveralTypesOfProducts - Boolean - If True, the use
//              of multiple item types will be enabled (if there are 3 or more item types).
//            * CheckForUseOfAlcoholicBeveragesInRetail - Boolean - If True, it will include
//              the use of retail sales of alcoholic beverages (if the database has types of nomenclature C).
//              a symptom of "Alcohol products").
//            * CheckForUseOfShipmentWithoutTransferOfOwnership - Boolean - If True
//              , the use of shipment operations without transfer of ownership will be enabled (if the database contains the corresponding
//              operations.
//
Function ParametersAfterDataLoading() Export
	
	Parameters = New Structure();
	Parameters.Insert("CheckForUseOfImportedGoods", True);
	Parameters.Insert("CheckForUseOfImportPurchases", True);
	Parameters.Insert("CheckWhetherCommissionIsUsedInPurchases", True);
	Parameters.Insert("CheckForCommissionOnSales", True);
	Parameters.Insert("CheckForUseOfContracts", True);
	Parameters.Insert("CheckForRetailSalesUsage", True);
	Parameters.Insert("CheckForMovementUsage", True);
	Parameters.Insert("CheckForUseOfSeveralTypesOfProducts", True);
	Parameters.Insert("CheckForUseOfAlcoholicBeveragesInRetail", True);
	Parameters.Insert("CheckForUseOfShipmentWithoutTransferOfOwnership", True);
	
	Return Parameters;
	
EndFunction

Procedure EnableUseOfCustomerAgreementsIfNecessary()
	
	CurConstantValue = Constants.UseTermsOfSales.Get();
	Query = New Query(
	"SELECT TOP 1
	|	1 AS Field1
	|FROM
	|	Catalog.TermsOfSale AS Cat
	|WHERE
	|	Cat.Standard_ = TRUE
	|	AND Cat.DeletionMark = FALSE
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	1 AS Field1
	|FROM
	|	Catalog.TermsOfSale AS Cat
	|WHERE
	|	Cat.Standard_ = FALSE
	|	AND Cat.DeletionMark = FALSE");
	
	QueryResults = Query.ExecuteBatch();
	ThereAreTypical = Not QueryResults[0].IsEmpty();
	ThereAreIndividual = Not QueryResults[1].IsEmpty();
	
	If ThereAreTypical And ThereAreIndividual Then
		
		If CurConstantValue <> Enums.UseTermsOfSales.StandardAndIndividualTermsOfSales Then
			Constants.UseTermsOfSales.Set(Enums.UseTermsOfSales.StandardAndIndividualTermsOfSales);
		EndIf;
		
	ElsIf ThereAreTypical Then
		
		If CurConstantValue <> Enums.UseTermsOfSales.OnlyStandardTermsOfSales
			And CurConstantValue <> Enums.UseTermsOfSales.StandardAndIndividualTermsOfSales Then
			Constants.UseTermsOfSales.Set(Enums.UseTermsOfSales.OnlyStandardTermsOfSales);
		EndIf;
		
	ElsIf ThereAreIndividual Then
		
		If CurConstantValue <> Enums.UseTermsOfSales.OnlySpecialTermsOfSales
			And CurConstantValue <> Enums.UseTermsOfSales.StandardAndIndividualTermsOfSales Then
			Constants.UseTermsOfSales.Set(Enums.UseTermsOfSales.OnlySpecialTermsOfSales);
		EndIf;
		
	ElsIf Not ValueIsFilled(CurConstantValue) Then
		Constants.UseTermsOfSales.Set(Enums.UseTermsOfSales.DontUse);
	EndIf;
	
EndProcedure

// Called before recording a data synchronization setting that performs an exchange with accounting.
// If necessary, the value of the constant is changed using the exchange of the enterprise's data.
//
// Parameters:
//    ExchangePlanObject- ExchangePlanObject - a writable exchange plan node intended for exchange with the accounting department.
//    ThisIsRemoval - Boolean - indicates that the node is being marked for deletion or directly deleted.
Procedure UpdateAttributeForUsingExchangeWithAccounting(ExchangePlanObject, ThisIsRemoval) Export
	
	If Constants.UsingExchangeWithAccounting.Get() Then
		
		If ThisIsRemoval Then
			
			// Installation in a Lie with the verification of other exchanges with the accounting department.
			Query = DataExchangeTMERP.RequestExchangeNodesWithAccounting();
			ExchangeWithAccountingFound = False;
			Selection = Query.Execute().Select();
			While Selection.Next() Do
				If Selection.Ref = ExchangePlanObject.Ref Then
					Continue;
				EndIf;
				ExchangeWithAccountingFound = True;
				Break;
			EndDo;
			If Not ExchangeWithAccountingFound Then
				Constants.UsingExchangeWithAccounting.Set(False);
			EndIf;
		EndIf;
		
	ElsIf Not ThisIsRemoval And Not ExchangePlanObject.ThisNode Then
		Constants.UsingExchangeWithAccounting.Set(True);
	EndIf;
	
EndProcedure

// Transferring a method from the general module of the manageromaineresuniversal Format.
// Parameters:
//	VersionString - String - string version Presentation 
// Returns:
//	Number - numerical interpretation of the version
Function NumberFormatVersion(VersionString)Export
	If Not ValueIsFilled(VersionString) Or VersionString = "1.0.beta" Then
		Return 0;
	EndIf;
	
	NumberFormatVersion = 0;
	
	VersionRanks = StrSplit(VersionString, ".");
	If VersionRanks.Count() <> 2 Then
		ExceptionText = NStr("vi = 'Sai định dạng tham số %1: %2';
							|ru = 'Неправильный формат параметра %1: %2';
							|en = 'Invalid %1 parameter format: %2'; fa = 'Invalid %1 parameter format: %2';
							|it = 'Неправильный формат параметра %1: %2';
							|pl = 'Nieprawidłowy format parametru %1: %2';
							|tr = 'Yanlış parametre biçimi%1:%2'");
		Raise StrTemplate(ExceptionText, "VersionString1", VersionString);
	EndIf;
	
	DischargeMultiplier = 10000;
	For DischargeIndexIsReversed = 0 To 1 Do
		NumberFormatVersion = NumberFormatVersion + Number(VersionRanks[DischargeIndexIsReversed])*DischargeMultiplier;
		DischargeMultiplier = DischargeMultiplier / 100;
	EndDo;
	Return NumberFormatVersion;
EndFunction

#Region CalculationOfCost

// When receiving data from a peripheral node that requires cost recalculation, it adds an entry to the cost accounting Task register.
//
// Parameters:
//	ReceivedData - Arbitrary - this is the data Element parameter for the exchange plan event of the same name.
//
// Returns:
//	Boolean - a sign that the received data is data related to the cost calculation mechanism.
//
Function CreateTaskForCalculatingCostOfDataExchange(ReceivedData) Export
	
	Return CostCalculationAppliedAlgorithms.CreateTaskForCalculatingCostOfDataExchange(ReceivedData);
	
EndFunction

#EndRegion

#EndRegion

#Region InfobaseUpdate

// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export 
	Return;
EndProcedure

#EndRegion