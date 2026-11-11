////////////////////////////////////////////////////////////////////////////////
// Procedures and functions of the TMC subsystem in operation.
// 
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region Posting

// Generates parameters for conducting a document on the registers of the accounting mechanism through the General mechanism of conducting.
//
// Parameters:
//  Document - DocumentObject - recordable document
//  Properties - See DocumentsPosting.DocumentProperties
//
// Returns:
//  Structure - See DocumentsPosting.ParametersOfAccountingMechanism
//
Function ParametersForHoldingDocument(Document, Properties) Export
	
	Parameters = DocumentsPosting.ParametersOfAccountingMechanism();
	
	DocumentType = TypeOf(Document);
	
	// Posting
	If Properties.WriteMode = DocumentWriteMode.Posting Then
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.InventoryInOperation);
		Parameters.SubordinateRegisters.Add(Metadata.InformationRegisters.CostOfInventoryInOperation);
	EndIf;
	
	// Control
	If Properties.WriteMode <> DocumentWriteMode.Write Then
		Parameters.ControlRegistersOfChanges.Add(Metadata.AccumulationRegisters.InventoryInOperation);
	EndIf;
	
	InventoryInOperationLocalization.AddParametersForDocument(Parameters, Document, Properties);
	
	Return Parameters;
	
EndFunction

// Returns the text of the queries to reverse the movements when correcting documents
// 
// Parameters:
// 	MetadataOfDocument - MetadataObjectDocument - Metadata of the document that is being held.
// 
// Returns:
// 	Map - Correspondence of the full register name to the text of the reversal request
//
Function TextsOfCancellationRequests(MetadataOfDocument) Export
	
	DocumentRegisterRecords = MetadataOfDocument.RegisterRecords;
	QueriesTexts = New Map();
	RegisterMetadata = Metadata.AccumulationRegisters.InventoryInOperation;
	If DocumentRegisterRecords.Contains(RegisterMetadata) Then
		QueriesTexts.Insert(RegisterMetadata.FullName(),
			DocumentsPosting.TextOfReversingRequest(
				RegisterMetadata, MetadataOfDocument));
	EndIf;
	Return QueriesTexts;
	
EndFunction

// Complements the request text of the mechanism for checking the ban date by the table of changes.
// 
// Parameters:
// 	Query - Query - used for setting request parameters.
// 
// Returns:
//	Map - matching the names of the register change tables and query texts.
//	
Function QueryTextsMonitoringBanDateBasedOnChangesTable(Query) Export

	MatchingQueryTexts = New Map();
	Return MatchingQueryTexts;
	
EndFunction

// The procedure of formation of movements on the slave registers of settlements.
//
// Parameters:
//   TablesForRegisteredRecords - Structure - document data tables
//   RegisterRecords - RegisterRecordsCollection - collection of document movement record sets
//   Cancel - Boolean - indicates that the document was rejected.
//
Procedure ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, Cancel) Export
	
	If Cancel Then
		Return;
	EndIf;
	
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "InventoryInOperation");
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "CostOfInventoryInOperation");

	InventoryInOperationLocalization.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, Cancel);
	
EndProcedure

// Forms the text of the requests for control changes, the recorded movements of the registers.
//
// Parameters:
//  Query - Query - a query that stores the parameters used in the query list
//  QueryTexts - ValueList - list of query texts and their names.
//  Document - DocumentObject - a recordable document.
//
Procedure InitializeChangeControlData(Query, QueryTexts, Document) Export
	
	If DocumentsPosting.ThereAreRecordsInTable(Document, "MovementOfTMTSVOperationChange") Then
		
		QueryText =
			"SELECT
			|	TableOfRevolutions.Organization  AS Organization,
			|	TableOfRevolutions.Department AS Department,
			|	TableOfRevolutions.Individual AS Individual,
			|	TableOfRevolutions.Products AS Products,
			|	TableOfRevolutions.Products.UnitOfMeasure AS UnitOfMeasure,
			|	TableOfRevolutions.Characteristic AS Characteristic,
			|	TableOfRevolutions.Series AS Series,
			|	TableOfRevolutions.Lot AS Lot,
			|	TableOfRevolutions.LineOfBusiness AS LineOfBusiness,
			|	TableOfRevolutions.AssetID AS AssetID,
			|	TableOfRevolutions.CCDNumber AS CCDNumber,
			|	TableOfRevolutions.CountBalance AS Count
			|FROM
			|	AccumulationRegister.InventoryInOperation.Balance(,
			|			(Organization, Department, Individual, Products, Characteristic, Series, Lot, LineOfBusiness, AssetID, CCDNumber) IN
			|				(SELECT
			|					Table.Organization,
			|					Table.Department,
			|					Table.Individual,
			|					Table.Products,
			|					Table.Characteristic,
			|					Table.Series,
			|					Table.Lot,
			|					Table.LineOfBusiness,
			|					Table.AssetID,
			|					Table.CCDNumber
			|				FROM
			|					MovementOfTMTSVOperationChange AS Table)
			|	) AS TableOfRevolutions
			|WHERE
			|	TableOfRevolutions.CountBalance < 0";
		
		QueryTexts.Add(QueryText, "ErrorsOfTMTSVOperation");
		
	EndIf;
EndProcedure

// Displays messages to the user if there are errors in monitoring changes to recorded register movements.
//
// Parameters:
//  ControlResults - Structure - table with the results of the control changes
//  Document - DocumentObject - recordable document
//  Cancel - Boolean - indicates that the document was rejected.
//
Procedure ReportChangeControlResults(ControlResults, Document, Cancel) Export
	
	If DocumentsPosting.ThereAreRecordsInTable(Document, "MovementOfTMTSVOperationChange") Then
		
		MessageTemplate = NStr("vi = 'Vượt quá số dư hoạt động trong bộ phận %1, là %2 %3';
								|ru = 'Превышен оперативный остаток в подразделении %1, на %2 %3';
								|en = 'Operational stock balance in business unit %1 is exceeded by %2 %3'; fa = 'Operational stock balance in business unit %1 is exceeded by %2 %3';
								|it = 'Saldo operativo superato nei reparti %1, di %2 %3';
								|pl = 'Przekroczono stan operacyjny w dziale %1, o %2 %3';
								|tr = 'Departman %1''daki operasyonel denge %2 %3 tarafından aşıldı'");
		MessageTemplateIndividual = NStr("vi = 'Vượt quá số dư hoạt động trong bộ phận %1 (cá nhân %2), là %3 %4';
										|ru = 'Превышен оперативный остаток в подразделении %1 (физ. лицо %2), на %3 %4';
										|en = 'Operational stock balance in business unit %1 (person %2) is exceeded by %3 %4'; fa = 'Operational stock balance in business unit %1 (person %2) is exceeded by %3 %4';
										|it = 'Saldo operativo superato nei reparti %1 (persona fisica %2), di %3 %4';
										|pl = 'Przekroczono stan operacyjny w dziale %1 (osoba fizyczna %2), o %3 %4';
										|tr = 'Departman%1''daki (fiziksel kişi %2) operasyonel denge %3 %4 tarafından aşıldı'");
		
		For Each ErrorString In ControlResults.ErrorsOfTMTSVOperation Do
			
			Rows = New Array;
			
			ProductPresentation = ProductsClientServer.ProductPresentation(
				ErrorString.Products,
				ErrorString.Characteristic,,
				ErrorString.Series);
			Rows.Add(StrTemplate(NStr("vi = 'Mặt hàng: %1';
										|ru = 'Номенклатура: %1';
										|en = 'Items: %1'; fa = 'Items: %1';
										|it = 'Nomenclatura: %1';
										|pl = 'Produkt: %1';
										|tr = 'Ürün: %1'"), ProductPresentation));

			If ValueIsFilled(ErrorString.AssetID) Then
				Rows.Add(" " + StrTemplate(NStr("vi = 'Số kiểm kê: %1';
												|ru = 'Инв.№: %1';
												|en = 'Inv. No. %1'; fa = 'Inv. No. %1';
												|it = '№ inventario: %1';
												|pl = 'Nr inw.: %1';
												|tr = 'Env. No: %1'"), TrimAll(ErrorString.AssetID)));
			EndIf;
			
			If ValueIsFilled(ErrorString.LineOfBusiness) Then
				Rows.Add(" " + StrTemplate(NStr("vi = 'Lĩnh vực hoạt động: %1';
												|ru = 'Направление деятельности: %1';
												|en = 'Line of business: %1'; fa = 'Line of business: %1';
												|it = 'Settore di attività: %1';
												|pl = 'Rodzaj działalności: %1';
												|tr = 'İş kolu: %1'"), ErrorString.LineOfBusiness));
			EndIf;

			Rows.Add(" " + StrTemplate(NStr("vi = 'Lô hàng: %1';
											|ru = 'Партия: %1';
											|en = 'Lot: %1'; fa = 'Lot: %1';
											|it = 'Lotto: %1';
											|pl = 'Partia: %1';
											|tr = 'Lot: %1'"), ErrorString.Lot));
				
			MessageText = StrConcat(Rows, NStr("vi = ';';
												|ru = ';';
												|en = ';'; fa = ';';
												|it = ';';
												|pl = ';';
												|tr = ';'"));
			
			If ValueIsFilled(ErrorString.Individual) Then
				
				MessageText = 
					MessageText
					+ Chars.LF
					+ StrTemplate(MessageTemplateIndividual, ErrorString.Department, ErrorString.Individual, -ErrorString.Count, ErrorString.UnitOfMeasure);
					
			Else	
				
				MessageText = 
					MessageText
					+ Chars.LF
					+ StrTemplate(MessageTemplate, ErrorString.Department, -ErrorString.Count, ErrorString.UnitOfMeasure);
					
			EndIf;
			
			Common.MessageToUser(MessageText, Document,,, Cancel);
			
		EndDo;
		
	EndIf;
	
EndProcedure

// Called from the corresponding document handler
// 
// Parameters:
//  Object - DocumentObject.InventoryConsumption - processed object
//  Cancel - Boolean - indicates that the recording was rejected.
//  WriteMode - DocumentWriteMode - The current document recording mode.
//  PostingMode - DocumentPostingMode - The current mode of the event.
Procedure InventoryConsumption_BeforeWrite(Object, Cancel, WriteMode, PostingMode) Export
	
	If Object.BusinessOperation <> Enums.BusinessTransactions.TransferToOperation Then
		Return;
	EndIf;
	
	DetailsOfCategories = AttributesOfOperatingCategories(Object.Goods);
	
	FillInAttributesByCategoryOfOperation(Object.Goods);
	
	Catalogs.LotsOfInventoryInOperation.FillInBatches(Object, WriteMode);
	
	ListOfParties = New Array;
	For Each TSRow In Object.Goods Do
		If ValueIsFilled(TSRow.Lot)
			And ListOfParties.Find(TSRow.Lot) = Undefined Then
			ListOfParties.Add(TSRow.Lot);
		EndIf;
	EndDo;
	
	DetailsOfParties = Undefined;
	
	For Each TSRow In Object.Goods Do
		
		If Not ValueIsFilled(TSRow.OperationCategory)
			Or Not ValueIsFilled(TSRow.Lot) Then
			Continue;
		EndIf;
				
		CategoryProperties = DetailsOfCategories.Get(TSRow.OperationCategory);
		
		If CategoryProperties.AccountAsGroupFA Then
			
			If DetailsOfParties = Undefined Then
				DetailsOfParties = Common.ObjectsAttributesValues(ListOfParties, "FixedAsset");
			EndIf;
			
			BatchProperties = DetailsOfParties.Get(TSRow.Lot);
			TSRow.DimensionOfExpenses = BatchProperties.FixedAsset;
			
		EndIf;
			
	EndDo;
	
EndProcedure

// Checks the filling of the inventory number and quantity.
// 
// Parameters:
//  Object - DocumentObject - Document.
//  AttributesNotToCheck - Array - Unverifiable banking details.
//  Cancel - Boolean - True if the check is not passed.
//  CheckParameters - See InventoryControlParameters
//
Procedure CheckInventoryRecords(Object, AttributesNotToCheck, Cancel, CheckParameters = Undefined) Export

	If CheckParameters = Undefined Then
		CheckParameters = InventoryControlParameters();
	EndIf;
	
	TabularSection = Object[CheckParameters.TSName]; // TabularSection
	
	AttributesNotToCheck.Add(CheckParameters.TSName + ".AssetID");
	
	ListOfParties = New Array;
	
	For Each RowData In TabularSection Do
		If ValueIsFilled(RowData.Lot)
			And (Not ValueIsFilled(RowData.AssetID)
				Or RowData.Count > 1) Then
			
			ListOfParties.Add(RowData.Lot);
		EndIf;
	EndDo;
	
	If ListOfParties.Count() = 0 Then
		Return;
	EndIf;
	
	QueryText = 
	"SELECT
	|	LotsOfInventoryInOperation.Ref
	|FROM
	|	Catalog.LotsOfInventoryInOperation AS LotsOfInventoryInOperation
	|WHERE
	|	LotsOfInventoryInOperation.Ref IN (&ListOfParties)
	|	AND LotsOfInventoryInOperation.OperationCategory.StocktakingRecord";
	
	Query = New Query(QueryText);
	Query.SetParameter("ListOfParties", ListOfParties);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	LotsWithInventoryAccounting = New Map();
	While Selection.Next() Do
		LotsWithInventoryAccounting.Insert(Selection.Ref, True);
	EndDo;
	
	MessageTemplateInventoryNumber = NStr("vi = 'Chưa điền cột ""Số kiểm kê"" trong dòng %1 của danh sách ""%2""';
											|ru = 'Не заполнена колонка ""Инв. №"" в строке %1 списка ""%2""';
											|en = 'Column ""Inv. #"" in line %1 of list ""%2"" is not filled in'; fa = 'Column ""Inv. #"" in line %1 of list ""%2"" is not filled in';
											|it = 'Colonna ""№ inventario"" non compilata nella riga %1 dell''elenco ""%2""';
											|pl = 'Kolumna ""Nr inw"" w wierszu %1 listy ""%2"" nie jest wypełniona.';
											|tr = '""%2"" listesinin %1 satırında ""Env. No."" sütunu doldurulmadı.'");
	
	MessageTemplateQuantity = NStr("vi = 'Lô hàng đang tiến hành kế toán vật tư, cần đặt số lượng theo đơn vị lưu kho bằng 1 tại dòng %1 trong danh sách ""%2""';
									|ru = 'По партии ведется инвентарный учет, количество в единицах хранения должно быть установлено равным 1 в строке %1 списка ""%2""';
									|en = 'Inventory accounting is kept for the lot, the quantity in storage units must be set equal to 1 in the line %1 of the ""%2"" list'; fa = 'Inventory accounting is kept for the lot, the quantity in storage units must be set equal to 1 in the line %1 of the ""%2"" list';
									|it = 'Per i lotti vi è la contabilità di inventario, la quantità in unità di stoccaggio deve essere impostato pari a 1 nella riga %1 dell''elenco ""%2""';
									|pl = 'Według partii jest prowadzona ewidencja inwentarzowa, ilość w jednostkach przechowywania powinna być ustawiona na 1 w wierszu %1 listy ""%2""';
									|tr = 'Toplu iş için bir stok tutulur, depolama birimlerindeki miktar ""%2"" liste %1satırında  1 olarak ayarlanmalıdır.'");
	
	For Each RowData In TabularSection Do
		
		If Not ValueIsFilled(RowData.Lot)
			Or LotsWithInventoryAccounting.Get(RowData.Lot) = Undefined Then
			Continue;
		EndIf;
		
		If Not ValueIsFilled(RowData.AssetID) Then
			
			MessageText = 
				StrTemplate(MessageTemplateInventoryNumber, 
					Format(RowData.LineNumber, "NG=0;"),
					CheckParameters.PresentationOfTS);
			
			Field = CommonClientServer.PathToTabularSection(CheckParameters.TSName, RowData.LineNumber, "AssetID");
			Common.MessageToUser(MessageText, Object.Ref, Field, "Object", Cancel);
			
		EndIf;

		If RowData.Count > 1 Then
			
			MessageText = 
				StrTemplate(MessageTemplateQuantity, 
					Format(RowData.LineNumber, "NG=0;"),
					CheckParameters.PresentationOfTS);
				
			Field = CommonClientServer.PathToTabularSection(CheckParameters.TSName, RowData.LineNumber, CheckParameters.PropsNameQuantity);
			Common.MessageToUser(MessageText, Object.Ref, Field, "Object", Cancel);
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Returns the parameters of the inventory check.
//
//	Returns:
//		Structure  - a structure with the following keys:
//			* TSName - String - the default value is "Products".
//			* PresentationOfTS - String - the default value is "TMC in operation".
//			* PropsNameQuantity - String - the default value is "Quantity".
//
Function InventoryControlParameters() Export
	
	CheckParameters = New Structure;
	CheckParameters.Insert("TSName", "Goods");
	CheckParameters.Insert("PresentationOfTS", NStr("vi = 'Vật tư đang sử dụng';
													|ru = 'ТМЦ в эксплуатации';
													|en = 'Inventory in operation'; fa = 'موجودی در حال بهره‌برداری';
													|it = 'Beni materiali in uso';
													|pl = 'Dobra towarowo-materiałowe w eksploatacji';
													|tr = 'Stok kullanımda'"));
	CheckParameters.Insert("PropsNameQuantity", "Count");
	
	Return CheckParameters;
	
EndFunction

// Checks the filling of the physical. faces.
// 
// Parameters:
//  Object - DocumentObject - Document.
//  AttributesNotToCheck - Array - Unverifiable banking details.
//  Cancel - Boolean - True if the check is not passed.
//  CheckParameters - See ParametersForCheckingAccountingForIndividuals
//
Procedure CheckAccountingForIndividuals(Object, AttributesNotToCheck, Cancel, CheckParameters = Undefined) Export
	
	If CheckParameters = Undefined Then
		CheckParameters = ParametersForCheckingAccountingForIndividuals();
	EndIf;
	
	TabularSection = Object[CheckParameters.TSName]; // TabularSection

	For Each AttributeParameters In CheckParameters.BankingDetailsOfIndividual Do
		AttributesNotToCheck.Add(CheckParameters.TSName + "." + AttributeParameters.Value);
	EndDo;

	ListOfParties = New Array;
	
	For Each RowData In TabularSection Do
		
		If Not ValueIsFilled(RowData.Lot) Then
			Continue;
		EndIf;
		
		For Each AttributeParameters In CheckParameters.BankingDetailsOfIndividual Do
			If Not ValueIsFilled(RowData[AttributeParameters.Value]) Then
				ListOfParties.Add(RowData.Lot);
				Break;
			EndIf;
		EndDo;

	EndDo;
	
	If ListOfParties.Count() = 0 Then
		Return;
	EndIf;
	
	QueryText = 
	"SELECT
	|	LotsOfInventoryInOperation.Ref
	|FROM
	|	Catalog.LotsOfInventoryInOperation AS LotsOfInventoryInOperation
	|WHERE
	|	LotsOfInventoryInOperation.Ref IN (&ListOfParties)
	|	AND LotsOfInventoryInOperation.OperationCategory.AccountingForIndividuals";
	
	Query = New Query(QueryText);
	Query.SetParameter("ListOfParties", ListOfParties);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	PartiesWithConsiderationForIndividuals = New Map();
	While Selection.Next() Do
		PartiesWithConsiderationForIndividuals.Insert(Selection.Ref, True);
	EndDo;
	
	MessageTemplate = NStr("vi = 'Chưa điền cột ""%1"" tại dòng %2 trong danh sách ""%3""';
							|ru = 'Не заполнена колонка ""%1"" в строке %2 списка ""%3""';
							|en = 'Column ""%1"" in line %2 of list ""%3"" is required'; fa = 'Column ""%1"" in line %2 of list ""%3"" is required';
							|it = 'La colonna ""%1"" nella riga %2 dell''elenco ""%3"" non è compilata';
							|pl = 'Nie wypełniono kolumny ""%1"" w wierszu %2 listy ""%3""';
							|tr = 'Sütun ""%1"" ""%2"" listesinin %3 satırında doldurulmadı'");
	
	For Each RowData In TabularSection Do
		
		If Not ValueIsFilled(RowData.Lot)
			Or PartiesWithConsiderationForIndividuals.Get(RowData.Lot) = Undefined Then
			Continue;
		EndIf;
		
		For Each AttributeParameters In CheckParameters.BankingDetailsOfIndividual Do
			
			If Not ValueIsFilled(RowData[AttributeParameters.Value]) Then
				
				MessageText = 
					StrTemplate(MessageTemplate, 
						AttributeParameters.Presentation,
						Format(RowData.LineNumber, "NG=0;"),
						CheckParameters.PresentationOfTS);
				
				Field = CommonClientServer.PathToTabularSection(CheckParameters.TSName, RowData.LineNumber, AttributeParameters.Value);
				Common.MessageToUser(MessageText, Object.Ref, Field, "Object", Cancel);
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
EndProcedure

// Returns parameters for checking accounting by physical. persons.
//
//	Returns:
//		Structure  - a structure with the following keys:
//			* TSName - String - the default value is "Products".
//			* PresentationOfTS - String - the default value is "TMC in operation".
//			* BankingDetailsOfIndividual - ValueList - the default value is "Physical".
//
Function ParametersForCheckingAccountingForIndividuals() Export
	
	CheckParameters = New Structure;
	CheckParameters.Insert("TSName", "Goods");
	CheckParameters.Insert("PresentationOfTS", "INVENTORY In ofoperation");
	
	AttributesList = New ValueList();
	AttributesList.Add("Individual", NStr("vi = 'Cá nhân';
											|ru = 'Физическое лицо';
											|en = 'Person'; fa = 'شخص';
											|it = 'Persona fisica';
											|pl = 'Osoba fizyczna';
											|tr = 'Gerçek kişi'"));
	CheckParameters.Insert("BankingDetailsOfIndividual", AttributesList);
	
	Return CheckParameters;
	
EndFunction

// Fills in the Attributes of the document by category of operation.
// 
// Parameters:
//  TabularSection - TabularSection - The tabular part.
//  DetailsOfCategories - Map - Category Attributes.
Procedure FillInAttributesByCategoryOfOperation(TabularSection, DetailsOfCategories = Undefined) Export
	
	If DetailsOfCategories = Undefined Then
		DetailsOfCategories = AttributesOfOperatingCategories(TabularSection);
	EndIf;
	
	For Each TSRow In TabularSection Do
		
		If Not ValueIsFilled(TSRow.OperationCategory) Then
			Continue
		EndIf;
				
		CategoryProperties = DetailsOfCategories.Get(TSRow.OperationCategory);
		
		NewValues = New Structure;
		
		If Not CategoryProperties.StocktakingRecord Then
			NewValues.Insert("AssetID", "");
		EndIf;
		
		If Not CategoryProperties.AccountingForIndividuals Then
			NewValues.Insert("Individual", Catalogs.Persons.EmptyRef());
		EndIf;
		
		If Not CategoryProperties.AccountAsGroupFA Then
			NewValues.Insert("FixedAsset", Catalogs.Assets.EmptyRef());
		EndIf;
		
		If NewValues.Count() <> 0 Then
			FillPropertyValues(TSRow, NewValues);
		EndIf;
		
	EndDo;
	
EndProcedure

// Gets the Attributes of the categories of operation of the document.
// 
// Parameters:
//  Goods - TabularSection - Goods
// 
// Returns:
//  Map of KeyAndValue - Attributes of Operating Categories:
//		* Key - CatalogRef.OperationCategories - Category
//		* Value - Structure of KeyAndValue - Attributes
Function AttributesOfOperatingCategories(Goods) Export
	
	ListOfCategories = New Array;
	For Each TSRow In Goods Do
		If ValueIsFilled(TSRow.OperationCategory)
			And ListOfCategories.Find(TSRow.OperationCategory) = Undefined Then
			ListOfCategories.Add(TSRow.OperationCategory);
		EndIf;
	EndDo;
	
	DetailsOfCategories = Common.ObjectsAttributesValues(
			ListOfCategories, "AccountingForIndividuals,AccountAsGroupFA,StocktakingRecord");

	Return DetailsOfCategories;
		
EndFunction

#EndRegion

#Region BarcodesAndTradeEquipment

// Finds Inventory by barcodes.
// 
// Parameters:
//  BarcodeData_5 - Structure - Barcode data.
//  PickingParameters - See BarcodeMatchingParameters
// 	
// Returns:
// 	Structure - Contains:
//    * ObjectsTable - ValueTable - found objects.
//    * NotFound_1 - Array of String - barcodes for which objects could not be found.
//    * DoNotFit - Array of CatalogRef.Assets - Objects that do not match the selection parameters.
Function FindObjectsByBarcodes(BarcodeData_5, PickingParameters = Undefined) Export

	Result = New Structure;
	Result.Insert("ObjectsTable", New ValueTable);
	Result.Insert("DoNotFit", New Array);
	Result.Insert("NotFound_1", New Array);

	ArrayOfBarcodes = ArrayOfBarcodes(BarcodeData_5);
	
	If ArrayOfBarcodes.Count() = 0 Then
		Return Result;
	EndIf; 
	
	QueryText = 
	"SELECT
	|	InventoryInOperation.Organization AS Organization,
	|	InventoryInOperation.Department AS Department,
	|	InventoryInOperation.Individual AS Individual,
	|	InventoryInOperation.Products AS Products,
	|	InventoryInOperation.Characteristic AS Characteristic,
	|	InventoryInOperation.Series AS Series,
	|	InventoryInOperation.Lot AS Lot,
	|	InventoryInOperation.Lot.Description AS LotPresentation,
	|	InventoryInOperation.Lot.OperationCategory.StocktakingRecord AS StocktakingRecord,
	|	InventoryInOperation.Lot.OperationCategory.AccountingForIndividuals AS AccountingForIndividuals,
	|	InventoryInOperation.Lot.OperationCategory.MethodOfRepaymentOfCostOfAC AS MethodOfRepaymentOfCostOfAC,
	|	InventoryInOperation.Lot.OperationCategory.EstimatedRunningTime AS EstimatedRunningTime,
	|	InventoryInOperation.LineOfBusiness AS LineOfBusiness,
	|	InventoryInOperation.AssetID AS AssetID,
	|
	|	SUM(InventoryInOperation.CountBalance) AS Count
	|
	|FROM
	|		AccumulationRegister.InventoryInOperation.Balance(
	|			&Date,
	|			(Organization = &Organization
	|					OR &Organization = VALUE(Catalog.Companies.EmptyRef))
	|
	|				AND (Department = &Department
	|					OR &Department = VALUE(Catalog.BusinessStructure.EmptyRef))
	|
	|				AND (Individual = &Individual
	|					OR &Individual = VALUE(Catalog.Persons.EmptyRef))
	|
	|				AND (AssetID IN (&ArrayOfBarcodes))
	|
	|			) AS InventoryInOperation
	|WHERE
	|	InventoryInOperation.Products.ItemsType IN (
	|		VALUE(Enum.ItemsTypes.OwnGoods),
	|		VALUE(Enum.ItemsTypes.ReusablePackage))
	|
	|GROUP BY
	|	InventoryInOperation.Organization,
	|	InventoryInOperation.Department,
	|	InventoryInOperation.Individual,
	|	InventoryInOperation.Products,
	|	InventoryInOperation.Characteristic,
	|	InventoryInOperation.Series,
	|	InventoryInOperation.Lot,
	|	InventoryInOperation.LineOfBusiness,
	|	InventoryInOperation.AssetID
	|
	|ORDER BY
	|	InventoryInOperation.Individual.Presentation,
	|	InventoryInOperation.Products.Presentation,
	|	InventoryInOperation.Characteristic.Presentation,
	|	InventoryInOperation.Series.Presentation,
	|	InventoryInOperation.AssetID";
	
	Query = New Query(QueryText);
	Query.SetParameter("ArrayOfBarcodes", ArrayOfBarcodes);

	If PickingParameters = Undefined Then
		PickingParameters = BarcodeMatchingParameters();
	EndIf;
	
	Query.SetParameter("Date", PickingParameters.Date);
	Query.SetParameter("Organization", PickingParameters.Organization);
	Query.SetParameter("Department", PickingParameters.Department);
	Query.SetParameter("Individual", PickingParameters.Individual);
	
	ObjectsTable = Query.Execute().Unload();
	
	NotFound_1 = New Array;
	For Each Barcode In ArrayOfBarcodes Do
		If ObjectsTable.Find(Barcode, "AssetID") = Undefined Then
			NotFound_1.Add(Barcode);
		EndIf; 
	EndDo; 
	
	DoNotFit = New Array;
	
	Result.ObjectsTable = ObjectsTable;
	Result.DoNotFit = DoNotFit;
	Result.NotFound_1 = NotFound_1;
	
	Return Result;

EndFunction

// Reports the barcode search results.
// 
// Parameters:
// 	SearchResult - See FindObjectsByBarcodes
Procedure ReportBarcodeSearchResults(SearchResult) Export
	
	MessageTemplate = NStr("vi = 'Không tìm thấy vật tư đang sử dụng với số kiểm kê %1';
							|ru = 'ТМЦ в эксплуатации с инвентарным номером %1 не найдено';
							|en = 'Inventory in operation with inventory number %1 is not found'; fa = 'Inventory in operation with inventory number %1 is not found';
							|it = 'Beni materiali in lavorazione con numero di inventario %1 non trovati';
							|pl = 'Zapasy w eksploatacji z numerem inwentarzowym %1 nie zostały znalezione';
							|tr = 'Stok numarası %1 ile kullanımda olan mal ve malzemeler bulunamadı'");
	For Each Barcode In SearchResult.NotFound_1 Do
		MessageText = StrTemplate(MessageTemplate, Barcode);
		Common.MessageToUser(MessageText); 
	EndDo; 
	
	MessageTemplate = NStr("vi = 'Không thể thêm vật tư đang sử dụng ""%1"" vào chứng từ, vì không đáp ứng điều kiện chọn';
							|ru = 'ТМЦ в эксплуатации ""%1"" не может быть добавлено в документ, т.к. оно не удовлетворяет условиям выбора';
							|en = 'The ""%1"" inventory in operation cannot be added to the document. It does not meet selection conditions'; fa = 'The ""%1"" inventory in operation cannot be added to the document. It does not meet selection conditions';
							|it = 'Il bene materiali in lavorazione ""%1"" non può essere aggiunto al documento, poiché non soddisfa le condizioni di selezione';
							|pl = 'Nie można dodać zapasów w eksploatacji „%1” do dokumentu, ponieważ nie spełnia warunków wyboru';
							|tr = 'Kullanımda olan stok ""%1"" belgesine eklenemez, çünkü seçim koşullarını karşılamaz'");
	For Each ObjectReference In SearchResult.DoNotFit Do
		MessageText = StrTemplate(MessageTemplate, ObjectReference);
		Common.MessageToUser(MessageText, ObjectReference); 
	EndDo; 
	
EndProcedure

// Retrieves the list of barcodes from the input result.
// 
// Parameters:
//  BarcodeData_5 - Structure, Array of String - Barcode data.
//  
// Returns:
// 	Array - 
Function ArrayOfBarcodes(BarcodeData_5) Export
	
	ArrayOfBarcodes = New Array;
	If TypeOf(BarcodeData_5) = Type("Array") Then
		For Each BarcodeString In BarcodeData_5 Do
			If ValueIsFilled(BarcodeString.Barcode) Then
				ArrayOfBarcodes.Add(BarcodeString.Barcode);
			EndIf;
		EndDo;
	ElsIf ValueIsFilled(BarcodeData_5.Barcode) Then
		ArrayOfBarcodes.Add(BarcodeData_5.Barcode);
	EndIf;
	
	TMCommonUse.DeleteDuplicateElementsFromArray(ArrayOfBarcodes);
	
	Return ArrayOfBarcodes;
	
EndFunction

// Barcode matching parameters.
// 
// Returns:
//  Structure - Barcode Matching Parameters:
// 		* Date - Date -
// 		* Organization - CatalogRef.Companies -
// 		* Department - CatalogRef.BusinessStructure -
// 		* Individual - CatalogRef.Persons -
Function BarcodeMatchingParameters() Export
	
	PickingParameters = New Structure;
	PickingParameters.Insert("Date", '000101010000');
	PickingParameters.Insert("Organization", Catalogs.Companies.EmptyRef());
	PickingParameters.Insert("Department", Catalogs.BusinessStructure.EmptyRef());
	PickingParameters.Insert("Individual", Catalogs.Persons.EmptyRef());
	
	Return PickingParameters;
	
EndFunction

#EndRegion

#Region ProcessingOfRowsInTablePart

// Complements methods for execution.
// 
// Parameters:
//  MethodsForImplementation - ValueList of String -
Procedure AddMethodsToExecution(MethodsForImplementation) Export
	
	MethodsForImplementation.Add("FillInCategoryAttributes", "InventoryInOperationServer.FillInCategoryAttributes");
	MethodsForImplementation.Add("FillInBatchOfTMTSV", "InventoryInOperationServer.FillInBatchOfTMTSV");
EndProcedure

// Complements methods for execution.
// 
// Parameters:
//  MethodsForImplementation - ValueList of String -
Procedure AddMethodsToBatchExecution(MethodsForImplementation) Export
	
	MethodsForImplementation.Add("FillInCategoryAttributes", "InventoryInOperationServer.FillInAttributesOfOperationCategoryInBatches");
	MethodsForImplementation.Add("FillInBatchOfTMTSV", "InventoryInOperationServer.FillInBatchOfTMTSVOperationInBatches");
EndProcedure

// Adds queries to the query package to get the data needed to process the rows in the table part.
//
// Parameters:
//  StructureOfActions - See BatchProcessingOfTablePartServer.ProcessTSStrings.StructureOfActions
//  QueryDetails - See BatchProcessingOfTablePartServer.QueryDetails
//  CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
//
Procedure AddDescriptionOfBatchProcessingRequestTS(StructureOfActions, QueryDetails, CachedValues) Export
	
	CompleteDescriptionOfRequestForProcessingPM_SignsOfCategoryOfOperation(StructureOfActions, QueryDetails, CachedValues);
	CompleteDescriptionOfRequestForProcessingPM_FillInBatchOfInventoryItemsForOperation(StructureOfActions, QueryDetails, CachedValues);
EndProcedure

#EndRegion

#Region Other

// See ReportsOptionsOverridable.CustomizeReportsOptions.
//
Procedure CustomizeReportsOptions(Settings) Export

	InventoryInOperationLocalization.CustomizeReportsOptions(Settings);

	#Region ListOfInventoryInOperation
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.ListOfInventoryInOperation);
	DescriptionOfReport.DefineFormSettings = True;
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích biến động vật tư đang sử dụng theo số lượng và đánh giá giá trị số dư.';
									|ru = 'Анализ количественного движения ТМЦ в эксплуатации и стоимостная оценка остатков.';
									|en = 'Analyze the quantitative movement of inventory in operation and evaluate available inventory.'; fa = 'Analyze the quantitative movement of inventory in operation and evaluate available inventory.';
									|it = 'Analisi del movimento quantitativo dei beni materiali in lavorazione e valutazione del prezzo dei saldi.';
									|pl = 'Analiza przepływu ilościowego zapasów w eksploatacji i wycenę zapasów w walucie.';
									|tr = 'İşletmede mal ve malzemelerin kantitatif hareketinin analizi ve kalıntıların değerlemesi.'");
	
	#EndRegion
	
	#Region StockOfInventoryInOperation
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.StockOfInventoryInOperation);
	DescriptionOfReport.DefineFormSettings = True;
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích số dư vật tư đang sử dụng.';
									|ru = 'Анализ остатков ТМЦ в эксплуатации.';
									|en = 'Analysis of balance of inventory in operation.'; fa = 'Analysis of balance of inventory in operation.';
									|it = 'Analisi saldi beni materiali in lavorazione.';
									|pl = 'Analiza stanu zapasów w eksploatacji.';
									|tr = 'Kullanımdaki stok bakiyesi analizi'");
	
	#EndRegion

EndProcedure

//  See AccessManagementOverridable.OnFillListsWithAccessRestriction 
//
Procedure OnFillListsWithAccessRestriction(Lists) Export
	
	InventoryInOperationLocalization.OnFillListsWithAccessRestriction(Lists);
	Lists.Insert(Metadata.Documents.PhysicalCountOfInventoryInOperation, True);
	Lists.Insert(Metadata.Documents.RecordInventoryInOperation, True);
	Lists.Insert(Metadata.Documents.TransferInOperation, True);
	Lists.Insert(Metadata.Documents.Decomissioning, True);
	Lists.Insert(Metadata.AccumulationRegisters.InventoryInOperation, True);
	Lists.Insert(Metadata.InformationRegisters.CostOfInventoryInOperation, True);
EndProcedure

// See PrintManagementOverridable.OnDefinePrintSettings
//
Procedure OnDefinePrintSettings(Settings) Export

	ListOfObjects = Settings.PrintObjects;
	ListOfObjects.Add(Documents.OBEntryInventoryInOperation);
	ListOfObjects.Add(Documents.PhysicalCountOfInventoryInOperation);
	ListOfObjects.Add(Documents.RecordInventoryInOperation);
	ListOfObjects.Add(Documents.TransferInOperation);
	ListOfObjects.Add(Documents.Decomissioning);
EndProcedure

// Defines a list of configuration objects, in the modules of managers of which the procedure is provided 
// Add a creation command on the basis that forms creation commands based on objects.
// For the syntax of the Add Command Creation procedure, see the documentation.
//
// Parameters:
//   Objects - Array of MetadataObject - metadata objects (metadata Objects) with commands to create based on.
//
// Example:
//	Objects.Add (Metadata.Guides.Companies);
//   
Procedure OnDefineObjectsWithCreationBasedOnCommands(Objects) Export
	Objects.Add(Metadata.Documents.PhysicalCountOfInventoryInOperation);
EndProcedure

// See also updating the information base undefined.At firstfillingelements
//
// Parameters:
//  LanguagesCodes - See InfobaseUpdateOverridable.OnInitialItemsFilling.LanguagesCodes
//  Items   - See InfobaseUpdateOverridable.OnInitialItemsFilling.Items
//  TabularSections - See InfobaseUpdateOverridable.OnInitialItemsFilling.TabularSections
//
Procedure OnInitialItemsFilling(LanguagesCodes, Items, TabularSections) Export

	Set = Items.Add();
	Set.PredefinedSetName = "Document_PhysicalCountOfInventoryInOperation";
	Set.Ref = New UUID("4c03551b-5501-4b3a-8c04-129358da86fc");
	Set.Used = True;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Set, "Description",
		"vi = 'Chứng từ kiểm kê vật tư đang sử dụng';
		|ru = 'Документы инвентаризации ТМЦ в эксплуатации';
		|en = 'Documents of physical count of inventory in operation';
		|it = 'Документы инвентаризации ТМЦ в эксплуатации';
		|pl = 'Dokumenty inwentaryzacji zapasów w eksploatacji';
		|tr = 'Kullanılan stoklar için envanter belgeleri'", LanguagesCodes); // @NStr-2
	
	Set = Items.Add();
	Set.PredefinedSetName = "Document_RecordInventoryInOperation";
	Set.Ref = New UUID("9c244308-aad4-4466-9894-7c53492e4683");
	Set.Used = True;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Set, "Description",
		"vi = 'Chứng từ ghi tăng vật tư đang sử dụng';
		|ru = 'Документы оприходования ТМЦ в эксплуатации';
		|en = 'Documents of receipt of inventory in operation';
		|it = 'Документы оприходования ТМЦ в эксплуатации';
		|pl = 'Dokumenty rejestracji zapasów w eksploatacji';
		|tr = 'Kullanılan stoklar için makbuz belgeleri'", LanguagesCodes); // @NStr-2
	
	Set = Items.Add();
	Set.PredefinedSetName = "Document_OBEntryInventoryInOperation";
	Set.Ref = New UUID("7a5b4a72-72d0-4dd0-bb39-59f13c226572");
	Set.Used = True;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Set, "Description",
		"vi = 'Nhập số dư vật tư đang sử dụng';
		|ru = 'Ввод остатков ТМЦ в эксплуатации';
		|en = 'OB entry: inventory in operation';
		|it = 'Ввод остатков ТМЦ в эксплуатации';
		|pl = 'Wprowadzenie ostatków dóbr towarowo-materiałowych w eksploatacji';
		|tr = 'Kullanımdaki stok bakiyelerinin girişi'", LanguagesCodes); // @NStr-2
	
EndProcedure

// See FilesOperationsOverridable.OnDefineFileStorageCatalogs
//
Procedure OnDefineFileStorageCatalogs(TypeFileOwner, CatalogNames) Export
	If TypeFileOwner = Type("DocumentRef.PhysicalCountOfInventoryInOperation")
		Or TypeFileOwner = Type("DocumentRef.RecordInventoryInOperation") Then
		CatalogNames.Insert("DocumentsFAAttachedFiles", True);
	EndIf;
EndProcedure

// Determines whether it is possible to account for the series in operation.
// 
// Returns:
//  Boolean - True if there is an accounting policy with series accounting enabled in operation
Function ItIsPossibleToTakeIntoAccountSeriesInOperation() Export
	
	Result = False;
	
	KeepAccountingByBatch = GetFunctionalOption("UseItemsBatchWarehouse", New Structure());
	
	If Not KeepAccountingByBatch Then
		Return False;
	EndIf;
	
	QueryText = 
	"SELECT ALLOWED TOP 1
	|	TRUE
	|FROM
	|	Catalog.ItemKinds AS ItemKinds
	|WHERE
	|	ItemKinds.BatchAccountingPolicy.SeriesAccountingInventoryInOperation
	|	AND NOT ItemKinds.DeletionMark";
	
	Query = New Query(QueryText);
	
	Result = Query.Execute();
	Result = Not Result.IsEmpty();
	
	Return Result;
	
EndFunction

// Defines configuration objects whose manager modules have a procedure for adding Report commands
// describing commands for opening contextual reports.
// For the syntax of the Add Report Commands procedure, see the documentation.
//
// Parameters:
//   Objects - Array of MetadataObject - metadata objects with report commands.
//
Procedure DefineObjectsWithReportCommands(Objects) Export
	
	InventoryInOperationLocalization.DefineObjectsWithReportCommands(Objects);
	
	Objects.Add(Metadata.Documents.OBEntryInventoryInOperation);
	Objects.Add(Metadata.Documents.PhysicalCountOfInventoryInOperation);
	Objects.Add(Metadata.Documents.RecordInventoryInOperation);
	Objects.Add(Metadata.Documents.TransferInOperation);
	Objects.Add(Metadata.Documents.Decomissioning);
	Objects.Add(Metadata.DataProcessors.DocumentJournalInventoryInOperation);
EndProcedure

// See PeriodClosingDatesOverridable.FillDataSourcesForPeriodClosingCheck
//
Procedure FillDataSourcesForPeriodClosingCheck(DataSources) Export
	
	PeriodClosingDates.AddRow(
		DataSources,
		Metadata.Documents.OBEntryInventoryInOperation.FullName(),
		"Date",
		"OBEntry",
		"Organization");
										
	PeriodClosingDates.AddRow(
		DataSources,
		Metadata.AccumulationRegisters.InventoryInOperation.FullName(),
		"Period",
		"InternalInventoryTransfers",
		"Organization");
										
	PeriodClosingDates.AddRow(
		DataSources,
		Metadata.Documents.TransferInOperation.FullName(),
		"Date",
		"InternalInventoryTransfers",
		"Organization");
										
	PeriodClosingDates.AddRow(
		DataSources,
		Metadata.Documents.Decomissioning.FullName(),
		"Date",
		"InternalInventoryTransfers",
		"Organization");
	
	PeriodClosingDates.AddRow(
		DataSources,
		Metadata.Documents.RecordInventoryInOperation.FullName(),
		"Date",
		"InternalInventoryTransfers",
		"Organization");
	
	PeriodClosingDates.AddRow(
		DataSources,
		Metadata.Documents.PhysicalCountOfInventoryInOperation.FullName(),
		"Date",
		"InternalInventoryTransfers",
		"Organization");
	
EndProcedure

// Adds roles to the profile that allow you to work in the VNA subsystem with change rights.
// 
// Parameters:
// 	ProfileDetails - See AccessManagement.NewAccessGroupProfileDescription
Procedure AddRolesToAccessSubsystemForModification(ProfileDetails) Export
	
	InventoryInOperationLocalization.AddRolesToAccessSubsystemForModification(ProfileDetails);
	
	ProfileDetails.Roles.Add("AddEditOperationCategories");
	ProfileDetails.Roles.Add("AddEditsForWriteOffs");
	ProfileDetails.Roles.Add("AddEditsOfTransfersInOperation");
	ProfileDetails.Roles.Add("AddEditReceiptsOfInventoryInOperation");
	ProfileDetails.Roles.Add("AddEditPhysicalCountsOfInventoryInOperation");

	ProfileDetails.Roles.Add("ReadInventoryInOperation");
	ProfileDetails.Roles.Add("UseDataProcessorDocumentJournalInventoryInOperation");
EndProcedure

// Sets the conditional registration of the inventory number.
// 
// Parameters:
//  Form - ClientApplicationForm - The form in which the conditional design is established.
//  NameOfInventoryNumberField - String - The name of the "Inventory Number" field on the form.
//  PathToInventoryField - String - The path to the "Inventory Number" field.
//  PathToPartyField - String - The path to the "Party" field.
Procedure SetConditionalRegistrationOfInventoryNumber(Form, NameOfInventoryNumberField = "", PathToInventoryField = "", PathToPartyField = "") Export
	
	If NameOfInventoryNumberField = "" Then
		NameOfInventoryNumberField = "GoodsAssetID";
	EndIf;
	
	If PathToInventoryField = "" Then
		PathToInventoryField = "Object.Goods.StocktakingRecord";
	EndIf;
	
	If PathToPartyField = "" Then
		PathToPartyField = "Object.Goods.Lot";
	EndIf;

	ConditionalAppearance = Form.ConditionalAppearance;
	FormItems = Form.Items;
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	FormField = FormItems[NameOfInventoryNumberField]; // FormField
	ItemField.Field = New DataCompositionField(FormField.Name);
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(PathToInventoryField);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	If PathToPartyField <> Undefined Then
		ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField(PathToPartyField);
		ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	EndIf;

	ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	ConditionalAppearanceItem.Appearance.SetParameterValue("MarkIncomplete", False);
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("vi = '<không sử dụng>';
																		|ru = '<не используется>';
																		|en = '<not used>'; fa = '<استفاده نمی‌شود>';
																		|it = '<non viene utilizzato>';
																		|pl = '<nie używa się>';
																		|tr = '<kullanılmayan>'"));
	ConditionalAppearanceItem.Appearance.SetParameterValue("ReadOnly", True);
	
EndProcedure

// Sets the conditional registration of the physical . faces.
// 
// Parameters:
//  Form - ClientApplicationForm - The form in which the conditional design is established.
//  FieldNameIndividual - String - The name of the "Physical Person" field on the form.
//  PathToAccountingForIndividualsField - String - The path to the field "Accounting for Individuals".
//  PathToPartyField - String - The path to the "Party" field.
Procedure EstablishConditionalRegistrationOfIndividual(Form, FieldNameIndividual = "", PathToAccountingForIndividualsField = "", PathToPartyField = "") Export
	
	If FieldNameIndividual = "" Then
		FieldNameIndividual = "GoodsIndividual";
	EndIf;
	
	If PathToAccountingForIndividualsField = "" Then
		PathToAccountingForIndividualsField = "Object.Goods.AccountingForIndividuals";
	EndIf;
	
	If PathToPartyField = "" Then
		PathToPartyField = "Object.Goods.Lot";
	EndIf;

	ConditionalAppearance = Form.ConditionalAppearance;
	FormItems = Form.Items;
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	FormField = FormItems[FieldNameIndividual]; // FormField
	ItemField.Field = New DataCompositionField(FormField.Name);
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(PathToAccountingForIndividualsField);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	If PathToPartyField <> Undefined Then
		ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField(PathToPartyField);
		ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	EndIf;

	ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	ConditionalAppearanceItem.Appearance.SetParameterValue("MarkIncomplete", False);
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("vi = '<không sử dụng>';
																		|ru = '<не используется>';
																		|en = '<not used>'; fa = '<استفاده نمی‌شود>';
																		|it = '<non viene utilizzato>';
																		|pl = '<nie używa się>';
																		|tr = '<kullanılmayan>'"));
	ConditionalAppearanceItem.Appearance.SetParameterValue("ReadOnly", True);
	
EndProcedure

// Fill in the service details for the batch of goods and materials.
// 
// Parameters:
//  TabularSection - FormDataCollection - The tabular part.
Procedure FillInServiceDetailsForBatchOfGoodsAndMaterials(TabularSection) Export

	ListOfParties = New Array;
	For Each RowData In TabularSection Do
		ListOfParties.Add(RowData.Lot); 
	EndDo;
	
	QueryText = 
	"SELECT
	|	LotsOfInventoryInOperation.Ref AS Ref,
	|	LotsOfInventoryInOperation.OperationCategory.StocktakingRecord AS StocktakingRecord,
	|	LotsOfInventoryInOperation.OperationCategory.AccountingForIndividuals AS AccountingForIndividuals,
	|	LotsOfInventoryInOperation.OperationCategory.AccountAsGroupFA AS AccountAsGroupFA
	|FROM 
	|	Catalog.LotsOfInventoryInOperation AS LotsOfInventoryInOperation
	|WHERE
	|	LotsOfInventoryInOperation.Ref IN (&ListOfParties)";
	
	Query = New Query(QueryText);
	Query.SetParameter("ListOfParties", ListOfParties);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	BatchesParameters = New Map();
	While Selection.Next() Do
		BatchParameters = New Structure;
		BatchParameters.Insert("StocktakingRecord", Selection.StocktakingRecord);
		BatchParameters.Insert("AccountingForIndividuals", Selection.AccountingForIndividuals);
		BatchParameters.Insert("AccountAsGroupFA", Selection.AccountAsGroupFA);
		BatchesParameters.Insert(Selection.Ref, BatchParameters);
	EndDo;
	
	FillingValues = New Structure("StocktakingRecord,AccountingForIndividuals,AccountAsGroupFA");
	
	For Each RowData In TabularSection Do
		
		BatchParameters = BatchesParameters.Get(RowData.Lot);
		
		If BatchParameters <> Undefined Then
			FillingValues.StocktakingRecord = BatchParameters.StocktakingRecord;
			FillingValues.AccountingForIndividuals = BatchParameters.AccountingForIndividuals;
			FillingValues.AccountAsGroupFA = BatchParameters.AccountAsGroupFA;
		Else
			FillingValues.StocktakingRecord = False;
			FillingValues.AccountingForIndividuals = False;
			FillingValues.AccountAsGroupFA = False;
		EndIf;
		
		FillPropertyValues(RowData, FillingValues);
	
	EndDo;
	
EndProcedure

// Generates a new inventory number.
// 
// Parameters:
//  TakeIntoAccountInventoryNumbers - Array - Take into account inventory numbers.
//  ExcludeDocument - DocumentRef - Exclude document movements.
// 
// Returns:
//	String - New inventory number.
Function NewInventoryNumber(TakeIntoAccountInventoryNumbers = Undefined, ExcludeDocument = Undefined) Export

	NumberLength = Metadata.DefinedTypes.InventoryNumberOfInventoryInOperation.Type.StringQualifiers.Length;
	
	SearchTemplate = "";
	For IndexOf = 1 To NumberLength Do
		SearchTemplate = SearchTemplate + "[0123456789]";
	EndDo;
	
	QueryText = 
	"SELECT TOP 1
	|	SUBSTRING(InventoryInOperation.AssetID, 1, &NumberLength) AS AssetID
	|FROM
	|	AccumulationRegister.InventoryInOperation AS InventoryInOperation
	|WHERE
	|	InventoryInOperation.AssetID LIKE ""&SearchTemplate""
	|	AND InventoryInOperation.AssetID <> """"
	|	AND InventoryInOperation.Recorder <> &ExcludeDocument
	|	AND InventoryInOperation.Active
	|	
	|ORDER BY
	|	InventoryInOperation.AssetID DESC";
	
	QueryText = StrReplace(QueryText, "&SearchTemplate", SearchTemplate);
	QueryText = StrReplace(QueryText, "&NumberLength", NumberLength);
	
	Query = New Query(QueryText);
	Query.SetParameter("ExcludeDocument", ExcludeDocument);
	
	SetPrivilegedMode(True);
	Result = Query.Execute();
	SetPrivilegedMode(False);

	Selection = Result.Select();
	
	If Selection.Next() Then
		DescriptionOfNumberType = Common.TypeDescriptionNumber(NumberLength, 0);
		InventoryNumberByNumber = DescriptionOfNumberType.AdjustValue(Selection.AssetID) + 1;
	Else	
		InventoryNumberByNumber = 1;
	EndIf;
	
	If TakeIntoAccountInventoryNumbers <> Undefined Then
		
		AllInventoryNumbers = New ValueList();
		AllInventoryNumbers.Add(InventoryNumberByNumber);
		
		DescriptionOfNumberType = Common.TypeDescriptionNumber(NumberLength, 0);
		For Each AssetID In TakeIntoAccountInventoryNumbers Do
			InventoryNumberByNumber = DescriptionOfNumberType.AdjustValue(AssetID);
			If InventoryNumberByNumber <> 0 Then
				AllInventoryNumbers.Add(InventoryNumberByNumber + 1);
			EndIf;
		EndDo;
		
		AllInventoryNumbers.SortByValue(SortDirection.Desc);
		
		InventoryNumberByNumber = AllInventoryNumbers.Get(0).Value;
		
	EndIf;
	
	Return Format(InventoryNumberByNumber, StrTemplate("ND=%1; NLZ=; NG=;", String(NumberLength)));
	
EndFunction

// Generates new inventory numbers.
// 
// Parameters:
//	Count - Number - Number of rooms.
//  TakeIntoAccountInventoryNumbers - Array - Take into account inventory numbers.
//  ExcludeDocument - DocumentRef - Exclude document movements.
// 
// Returns:
//	Array of String - New inventory numbers.
Function NewInventoryNumbers(Count, TakeIntoAccountInventoryNumbers = Undefined, ExcludeDocument = Undefined) Export
	
	NewInventoryNumber = NewInventoryNumber(TakeIntoAccountInventoryNumbers, ExcludeDocument);
	
	NewInventoryNumbers = New Array;
	NewInventoryNumbers.Add(NewInventoryNumber);

	If Count > 1 Then
		
		NumberLength = Metadata.DefinedTypes.InventoryNumberOfInventoryInOperation.Type.StringQualifiers.Length;
		DescriptionOfNumberType = Common.TypeDescriptionNumber(NumberLength, 0);
		
		InventoryNumberByNumber = DescriptionOfNumberType.AdjustValue(NewInventoryNumber) + 1;
		For IndexOf = 2 To Count Do
			NewInventoryNumbers.Add(Format(InventoryNumberByNumber, StrTemplate("ND=%1; NLZ=; NG=;", String(NumberLength))));
			InventoryNumberByNumber = InventoryNumberByNumber + 1;
		EndDo;
		
	EndIf;
	
	Return NewInventoryNumbers;
	
EndFunction

// Checks the document of the transfer of goods and materials into operation.
//
// Parameters:
//  Object - DocumentObject.OBEntryInventoryInOperation, DocumentObject.InventoryConsumption, DocumentObject.RecordInventoryInOperation - processed object
//  AttributesNotToCheck - Array of String - Array of paths to the details for which the fill check will be disabled.
//  Cancel - Boolean - True if there are errors.
//
Procedure CheckTransferIntoOperation(Object, AttributesNotToCheck, Cancel) Export
	
	DocumentType = TypeOf(Object);
	
	If DocumentType = Type("DocumentObject.OBEntryInventoryInOperation") Then
		TSName = "InventoryInOperation";
	Else
		TSName = "Goods";
	EndIf;
	
	AttributesNotToCheck.Add(TSName + "." + "AssetID");
	AttributesNotToCheck.Add(TSName + "." + "Individual");
	
	If DocumentType = Type("DocumentObject.InventoryConsumption")
		And Object.BusinessOperation <> Enums.BusinessTransactions.TransferToOperation Then
		Return;
	EndIf;
	
	ThisIsRegistrationOfTMTSVOperation = (DocumentType = Type("DocumentObject.RecordInventoryInOperation"));
	
	If DocumentType = Type("DocumentObject.InventoryConsumption") Then
		PresentationOfTS = NStr("vi = 'Hàng hóa';
								|ru = 'Товары';
								|en = 'Goods'; fa = 'کالاها';
								|it = 'Merci';
								|pl = 'Towary';
								|tr = 'Ürünler'");
	Else
		PresentationOfTS = NStr("vi = 'Vật tư đang sử dụng';
								|ru = 'ТМЦ в эксплуатации';
								|en = 'Inventory in operation'; fa = 'موجودی در حال بهره‌برداری';
								|it = 'Beni materiali in uso';
								|pl = 'Grupa zapasy w eksploatacji';
								|tr = 'Stok kullanımda'");
	EndIf;
	
	AttributesNotToCheck.Add("Goods.ExpenseItem");
	AttributesNotToCheck.Add("Goods.DimensionOfExpenses");
	AttributesNotToCheck.Add("Goods.AssetsLiabilitiesDimension");
	
	QueryText =
	"SELECT
	|	CAST(DocumentTable.LineNumber AS NUMBER) AS LineNumber,
	|	CAST(DocumentTable.OperationCategory AS Catalog.OperationCategories) AS OperationCategory,
	|	DocumentTable.Individual AS Individual,
	|	CAST(DocumentTable.ExpenseItem AS ChartOfCharacteristicTypes.ExpenseItems) AS ExpenseItem,
	|	DocumentTable.DimensionOfExpenses AS DimensionOfExpenses,
	|	CAST(DocumentTable.FixedAsset AS Catalog.Assets) AS FixedAsset,
	|	DocumentTable.AssetID AS AssetID,
	|	DocumentTable.Count AS Count
	|
	|INTO DocumentTable
	|
	|FROM
	|	&DocumentTable AS DocumentTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentTable.LineNumber AS LineNumber
	|
	|INTO InventoryNumbersDuplicates
	|
	|FROM
	|	DocumentTable AS DocumentTable
	|
	|		LEFT JOIN DocumentTable AS DuplicatesTable
	|		ON DuplicatesTable.AssetID = DocumentTable.AssetID
	|			AND DuplicatesTable.LineNumber <> DocumentTable.LineNumber
	|WHERE
	|	DocumentTable.AssetID <> """"
	|
	|GROUP BY
	|	DocumentTable.LineNumber
	|
	|HAVING
	|	COUNT(DuplicatesTable.LineNumber) > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CheckResult.LineNumber AS LineNumber,
	|	CheckResult.AssetID AS AssetID,
	|	CheckResult.ExpenseItem AS ExpenseItem,
	|	CheckResult.DimensionOfExpenses AS DimensionOfExpenses,
	|	CheckResult.FixedAsset AS FixedAsset,
	|	CheckResult.OperationCategory.Presentation AS OperationCategoryPresentation,
	|	CheckResult.InventoryNumberNotFilledIn AS InventoryNumberNotFilledIn,
	|	CheckResult.IndividualIsNotFilledIn AS IndividualIsNotFilledIn,
	|	CheckResult.ErrorFillingInQuantity AS ErrorFillingInQuantity,
	|	CheckResult.DoubleError AS DoubleError,
	|	CheckResult.ArticleIsNotFormationOfValue AS ArticleIsNotFormationOfValue,
	|	CheckResult.SelectedNonGroupOS AS SelectedNonGroupOS,
	|	CheckResult.ExpenseItemIsNotFilledIn AS ExpenseItemIsNotFilledIn,
	|	CheckResult.CheckAnalytics AS CheckAnalytics,
	|	CheckResult.NotAccountingIsSupportedInFormOfGroupFA AS NotAccountingIsSupportedInFormOfGroupFA,
	|	CheckResult.MethodOfRepaymentOfCostIsNotSpecified AS MethodOfRepaymentOfCostIsNotSpecified
	|FROM
	|	(SELECT
	|		DocumentTable.LineNumber AS LineNumber,
	|		DocumentTable.AssetID AS AssetID,
	|		DocumentTable.ExpenseItem AS ExpenseItem,
	|		DocumentTable.DimensionOfExpenses AS DimensionOfExpenses,
	|		DocumentTable.FixedAsset AS FixedAsset,
	|		DocumentTable.OperationCategory AS OperationCategory,
	|	
	|		DocumentTable.AssetID = """" 
	|			AND ISNULL(DocumentTable.OperationCategory.StocktakingRecord, FALSE) AS InventoryNumberNotFilledIn,
	|
	|		DocumentTable.Individual = VALUE(Catalog.Persons.EmptyRef) 
	|			AND ISNULL(DocumentTable.OperationCategory.AccountingForIndividuals, FALSE) AS IndividualIsNotFilledIn,
	|
	|		DocumentTable.Count > 1 
	|			AND ISNULL(DocumentTable.OperationCategory.StocktakingRecord, FALSE) AS ErrorFillingInQuantity,
	|
	|		NOT InventoryNumbersDuplicates.LineNumber IS NULL AS DoubleError,
	|
	|		ISNULL(DocumentTable.OperationCategory.AccountAsGroupFA, FALSE)
	|			AND &AccountingIsSupportedInFormOfGroupFA
	|			AND &ThereIsExpenseItem
	|			AND NOT (ISNULL(DocumentTable.ExpenseItem.ExpensesOccur, UNDEFINED) = VALUE(Enum.ExpenseTypes.CalculationOfNonCurrentAssetsVAlue)
	|					AND ISNULL(DocumentTable.ExpenseItem.ExpensesOnAssets, FALSE)
	|					AND (ISNULL(DocumentTable.ExpenseItem.CostAllocationOptionManag, UNDEFINED) = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|						OR ISNULL(DocumentTable.ExpenseItem.CostAllocationOptionLocal, UNDEFINED) = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost))) AS ArticleIsNotFormationOfValue,
	|
	|		ISNULL(DocumentTable.OperationCategory.AccountAsGroupFA, FALSE)
	|			AND &AccountingIsSupportedInFormOfGroupFA
	|			AND DocumentTable.FixedAsset <> VALUE(Catalog.Assets.EmptyRef)
	|			AND ISNULL(DocumentTable.FixedAsset.OSType, UNDEFINED) <> VALUE(Enum.FATypes.GroupFA) AS SelectedNonGroupOS,
	|
	|		&ThereIsExpenseItem
	|		AND DocumentTable.ExpenseItem IN (
	|				VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef),
	|				VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef),
	|				UNDEFINED) AS ExpenseItemIsNotFilledIn,
	|
	|		&ThereIsExpenseItem
	|		AND NOT ISNULL(DocumentTable.OperationCategory.AccountAsGroupFA, FALSE)
	|			AND DocumentTable.ExpenseItem IN (&ArticlesWithMandatoryAnalytics) AS CheckAnalytics,
	|
	|		ISNULL(DocumentTable.OperationCategory.AccountAsGroupFA, FALSE)
	|			AND &AccountingIsSupportedInFormOfGroupFA
	|			AND &AccountingIsMaintainedPriorToApplicationOfFSB5
	|			AND &Date < &BeginningOfApplicationOfFSBU5 AS NotAccountingIsSupportedInFormOfGroupFA,
	|
	|		&Date < &BeginningOfApplicationOfFSBU5
	|			AND &AccountingIsMaintainedPriorToApplicationOfFSB5
	|			AND DocumentTable.OperationCategory <> VALUE(Catalog.OperationCategories.EmptyRef)
	|			AND DocumentTable.OperationCategory.MethodOfRepaymentOfCostOfAC = VALUE(Enum.WaysToRepayCostOfInventory.EmptyRef) AS MethodOfRepaymentOfCostIsNotSpecified
	|	FROM
	|		DocumentTable AS DocumentTable
	|
	|			LEFT JOIN InventoryNumbersDuplicates AS InventoryNumbersDuplicates
	|			ON InventoryNumbersDuplicates.LineNumber = DocumentTable.LineNumber
	|
	|	) AS CheckResult
	|
	|WHERE
	|	(CheckResult.InventoryNumberNotFilledIn
	|		OR CheckResult.IndividualIsNotFilledIn
	|		OR CheckResult.ErrorFillingInQuantity
	|		OR CheckResult.DoubleError
	|		OR CheckResult.ArticleIsNotFormationOfValue
	|		OR CheckResult.SelectedNonGroupOS
	|		OR CheckResult.ExpenseItemIsNotFilledIn
	|		OR CheckResult.CheckAnalytics
	|		OR CheckResult.NotAccountingIsSupportedInFormOfGroupFA
	|		OR CheckResult.MethodOfRepaymentOfCostIsNotSpecified)
	|
	|ORDER BY
	|	LineNumber";
	
	ListOfArticles = New Array;
	
	ColumnsList = "LineNumber,OperationCategory,Individual,AssetID,Count";
	If DocumentType = Type("DocumentObject.InventoryConsumption") Then
		ColumnsList = ColumnsList + ",ExpenseItem,DimensionOfExpenses,FixedAsset";
	ElsIf DocumentType = Type("DocumentObject.OBEntryInventoryInOperation") Then
		ColumnsList = ColumnsList + ",FixedAsset";
	EndIf;
	
	DocumentTable = Object[TSName].Unload(, ColumnsList); // ValueTable
	
	If ThisIsRegistrationOfTMTSVOperation Then
		
		DocumentTable.Columns.Add("ExpenseItem", New TypeDescription("ChartOfCharacteristicTypesRef.ExpenseItems"));
		DocumentTable.Columns.Add("DimensionOfExpenses", Metadata.ChartsOfCharacteristicTypes.ExpenseItems.Type);
		DocumentTable.Columns.Add("FixedAsset", New TypeDescription("CatalogRef.Assets"));
		
	ElsIf DocumentType = Type("DocumentObject.OBEntryInventoryInOperation") Then
		
		DocumentTable.Columns.Add("ExpenseItem", New TypeDescription("ChartOfCharacteristicTypesRef.ExpenseItems"));
		DocumentTable.Columns.Add("DimensionOfExpenses", Metadata.ChartsOfCharacteristicTypes.ExpenseItems.Type);
		
	EndIf;
	
	For Each TSRow In DocumentTable Do
		TSRow.AssetID = TrimAll(TSRow.AssetID);
		If ValueIsFilled(TSRow.ExpenseItem) Then
			ListOfArticles.Add(TSRow.ExpenseItem);
		EndIf;
	EndDo;
	
	BeginningOfApplicationOfFSBU5 = LocalAccntingClientServer.BeginningOfApplicationFSBU5_2019();
	
	Query = New Query(QueryText);
	Query.SetParameter("Date", Object.Date);
	Query.SetParameter("BeginningOfApplicationOfFSBU5", BeginningOfApplicationOfFSBU5);
	Query.SetParameter("DocumentTable", DocumentTable);
	Query.SetParameter("ArticlesWithMandatoryAnalytics", ChartsOfCharacteristicTypes.ExpenseItems.ArticlesWithMandatoryAnalytics(ListOfArticles));
	Query.SetParameter("AccountingIsSupportedInFormOfGroupFA", Not ThisIsRegistrationOfTMTSVOperation);
	Query.SetParameter("AccountingIsMaintainedPriorToApplicationOfFSB5", Not ThisIsRegistrationOfTMTSVOperation);
	
	Query.SetParameter(
		"ThereIsExpenseItem", 
		Not ThisIsRegistrationOfTMTSVOperation 
			And DocumentType <> Type("DocumentObject.OBEntryInventoryInOperation"));
	
	Result = Query.Execute();
		
	TemplateFieldIsNotFilledIn = NStr("vi = 'Chưa điền cột ""%1"" tại dòng %2 trong danh sách ""%3""';
										|ru = 'Не заполнена колонка ""%1"" в строке %2 списка ""%3""';
										|en = 'Column ""%1"" in line #%2, list ""%3"" cannot be empty.'; fa = 'Column ""%1"" in line #%2, list ""%3"" cannot be empty.';
										|it = 'La colonna ""%1"" nella riga %2 dell''elenco ""%3"" non è compilata';
										|pl = 'Nie wypełniono kolumny ""%1"" w wierszu %2 listy ""%3""';
										|tr = 'Sütun ""%1"" ""%2"" listesinin %3 satırında doldurulmadı'");
	
	TemplateErrorFillingInQuantity = 
		NStr("vi = 'Theo thể loại sử dụng có tiến hành kế toán kiểm kê, số lượng theo đơn vị lưu kho phải bằng 1 trong dòng %1 danh sách ""%2""';
			|ru = 'По категории эксплуатации ведется инвентарный учет, количество в единицах хранения должно быть установлено равным 1 в строке %1 списка ""%2""';
			|en = 'Inventory accounting is kept for the operation category, the quantity in stock UOM must be equal to 1 in line %1 of the ""%2"" list'; fa = 'Inventory accounting is kept for the operation category, the quantity in stock UOM must be equal to 1 in line %1 of the ""%2"" list';
			|it = 'Per categoria di lavorazione viene eseguita la contabilità di inventario, la quantità in unità di stoccaggio deve essere impostata pari a 1 nella riga %1 dell''elenco ""%2""';
			|pl = 'Według kategorii eksploatacji jest prowadzona ewidencja inwentarzowa, ilość w jednostkach przechowywania powinna być ustawiona na 1 w wierszu %1 listy ""%2""';
			|tr = 'İşlem kategorisi için envanter tutulur, depolama birimlerindeki sayı ""%2"" liste %1satırında  1 olarak ayarlanmalıdır.İşlem kategorisi için envanter tutulur, depolama birimlerindeki sayı """" liste satırında  1 olarak ayarlanmalıdır.'");
			
	TemplateErrorDuplicate = NStr("vi = 'Số kiểm kê ""%1"" trong dòng %2 danh sách ""%3"" bị lặp lại tại các dòng khác của chứng từ';
									|ru = 'Инвентарный номер ""%1"" в строке %2 списка ""%3"" повторяется в других строках документа';
									|en = 'The ""%1"" inventory number in line %2 of the ""%3"" list is repeated in other lines of the document'; fa = 'The ""%1"" inventory number in line %2 of the ""%3"" list is repeated in other lines of the document';
									|it = 'Numero di inventario ""%1"" nella stringa %2 dell''elenco ""%3"" viene ripetuto in altre stringhe del documento';
									|pl = 'Numer inwentarzowy ""%1"" w wierszu %2 listy ""%3"" powtarza się w innych wierszach dokumentu';
									|tr = '""%3"" liste %2satırındaki  ""%1"" stok numarası, belgenin diğer satırlarında yinelenir'");
		
	ArticleTemplateIsNotCostGeneration = NStr("vi = 'Trong dòng %1 danh sách ""%2"" cần chọn dạng mà chi phí của nó được đưa vào giá trị tài sản cố định';
												|ru = 'В строке %1 списка ""%2"" необходимо выбрать статью, расходы по которой относятся на стоимость основного средства';
												|en = 'In line %1 of the ""%2"" list, select an item whose expenses are allocated to the fixed asset cost'; fa = 'In line %1 of the ""%2"" list, select an item whose expenses are allocated to the fixed asset cost';
												|it = 'Nella stringa %1 dell''elenco ""%2"" è necessario selezionare la voce in base a cui le spese si riferiscono al costo del cespite';
												|pl = 'W wierszu %1 listy ""%2"" należy wybrać pozycję, której rozchody należą do wartości środka trwałego';
												|tr = '""%2"" liste satırında %1 , giderleri sabit kıymetin değeriyle ilgili olan kalemi seçmelisiniz'");

	TemplateSelectedIsNotGroupOS = NStr("vi = 'Trong dòng %1 danh sách ""%2"" cần chọn nhóm tài sản cố định hoặc để trống';
										|ru = 'В строке %1 списка ""%2"" необходимо выбрать групповое основное средство или оставить его пустым';
										|en = 'In line %1 of the ""%2"" list, select a group fixed asset or leave it blank'; fa = 'In line %1 of the ""%2"" list, select a group fixed asset or leave it blank';
										|it = 'Nella stringa %1 dell''elenco ""%2"" è necessario selezionare l cespite di gruppo o lasciarlo vuoto';
										|pl = 'W wierszu %1 listy ""%2"" należy wybrać grupowy środek trwały lub pozostawić go pustym';
										|tr = '""%2"" liste %1 satırında, bir sabit kıymet grubu seçilmeli veya boş bırakılmalıdır'");

	TemplateDoesNotSupportAccountingInFormOfGroupOS = NStr("vi = 'Trong dòng %1 danh sách ""%2"" đã chọn thể loại sử dụng có tính đến dạng nhóm TSCĐ. Hỗ trợ ghi nhận theo dạng nhóm TSCĐ từ %3.';
															|ru = 'В строке %1 списка ""%2"" выбрана категория эксплуатации с учетом в виде группового ОС. Учет в виде группового ОС поддерживается с %3.';
															|en = 'Operation category with accounting as group fixed assets is selected in line %1 of the ""%2"" list. Accounting as group fixed assets is supported with %3.'; fa = 'Operation category with accounting as group fixed assets is selected in line %1 of the ""%2"" list. Accounting as group fixed assets is supported with %3.';
															|it = 'Nella riga %1 dell''elenco ""%2"" è selezionata la categoria di lavorazione con contabilità in forma di cespite di gruppo. La contabilità in forma di cespite di gruppo viene supportata con %3.';
															|pl = 'W wierszu %1 listy ""%2"" jest wybrana kategoria eksploatacji z ewidencją w postaci grupowego środka trwałego. Ewidencja w postaci grupowego środka trwałego jest obsługiwana z %3.';
															|tr = '""%2"" listesinin %1 satırında SK grubu muhasebesi ile operasyon kategorisi seçildi. SK grubu muhasebesi %3''ten itibaren desteklenir.'");
	
	TemplateMethodOfCostRepayment = NStr("vi = 'Cần điền trình tự ghi giảm giá trị trong thể loại sử dụng ""%1"" tại dòng %2 danh sách ""%3""';
										|ru = 'Необходимо заполнить порядок погашения стоимости в категории эксплуатации ""%1"" в строке %2 списка ""%3""';
										|en = 'Fill the repayment procedure in the ""%1"" operation category in line %2 of the ""%3"" list'; fa = 'Fill the repayment procedure in the ""%1"" operation category in line %2 of the ""%3"" list';
										|it = 'È necessario compilare l''ordine di rimborso del prezzo nella categoria di lavorazione ""%1"" nella stringa %2 dell''elenco ""%3""';
										|pl = 'Należy wypełnij tryb spłaty wartości w kategorii eksploatacji ""%1"" w wierszu %2 listy ""%3""';
										|tr = 'Maliyetin geri ödeme sırasını ""%3"" listesinin %2satırında  ""%1"" kullanım kategorisinde doldurmak gerekir.'");
	
	Selection = Result.Select();
	While Selection.Next() Do
		
		If Selection.InventoryNumberNotFilledIn Then
			MessageText = StrTemplate(TemplateFieldIsNotFilledIn, NStr("vi = 'Số kiểm kê';
																		|ru = 'Инвентарный номер';
																		|en = 'Inventory number'; fa = 'شماره اموال';
																		|it = 'Numero d''inventario';
																		|pl = 'Numer inwentarzowy';
																		|tr = 'Stok numarası'"), Selection.LineNumber, PresentationOfTS);
			Field = CommonClientServer.PathToTabularSection(TSName, Selection.LineNumber, "AssetID");
			Common.MessageToUser(MessageText, Object, Field, "Object", Cancel);
		EndIf;
		
		If Selection.IndividualIsNotFilledIn Then
			MessageText = StrTemplate(TemplateFieldIsNotFilledIn, NStr("vi = 'Cá nhân';
																		|ru = 'Физическое лицо';
																		|en = 'Person'; fa = 'شخص';
																		|it = 'Persona fisica';
																		|pl = 'Osoba fizyczna';
																		|tr = 'Gerçek kişi'"), Selection.LineNumber, PresentationOfTS);
			Field = CommonClientServer.PathToTabularSection(TSName, Selection.LineNumber, "Individual");
			Common.MessageToUser(MessageText, Object, Field, "Object", Cancel);
		EndIf;
		
		If Selection.ErrorFillingInQuantity Then
			MessageText = StrTemplate(TemplateErrorFillingInQuantity, Selection.LineNumber, PresentationOfTS);
			Field = CommonClientServer.PathToTabularSection(TSName, Selection.LineNumber, "NumberOfPackages");
			Common.MessageToUser(MessageText, Object, Field, "Object", Cancel);
		EndIf;
		
		If Selection.DoubleError Then
			MessageText = StrTemplate(TemplateErrorDuplicate, Selection.AssetID, Selection.LineNumber, PresentationOfTS);
			Field = CommonClientServer.PathToTabularSection(TSName, Selection.LineNumber, "AssetID");
			Common.MessageToUser(MessageText, Object, Field, "Object", Cancel);
		EndIf;

		If Selection.ArticleIsNotFormationOfValue Then
			MessageText = StrTemplate(ArticleTemplateIsNotCostGeneration, Selection.LineNumber, PresentationOfTS);
			Field = CommonClientServer.PathToTabularSection(TSName, Selection.LineNumber, "ExpenseItem");
			Common.MessageToUser(MessageText, Object, Field, "Object", Cancel);
		EndIf;
		
		If Selection.SelectedNonGroupOS
			And ValueIsFilled(Selection.FixedAsset) Then
			MessageText = StrTemplate(TemplateSelectedIsNotGroupOS, Selection.LineNumber, PresentationOfTS);
			Field = CommonClientServer.PathToTabularSection(TSName, Selection.LineNumber, "FixedAsset");
			Common.MessageToUser(MessageText, Object, Field, "Object", Cancel);
		EndIf;
		
		If Selection.ExpenseItemIsNotFilledIn Then
			MessageText = StrTemplate(TemplateFieldIsNotFilledIn, NStr("vi = 'Dạng chi phí';
																		|ru = 'Статья расходов';
																		|en = 'Expense item'; fa = 'قلم هزینه';
																		|it = 'Voce di spese';
																		|pl = 'Rodzaj kosztu';
																		|tr = 'Gider kalemi'"), Selection.LineNumber, PresentationOfTS);
			Field = CommonClientServer.PathToTabularSection(TSName, Selection.LineNumber, "ExpenseItem");
			Common.MessageToUser(MessageText, Object, Field, "Object", Cancel);
		EndIf;
		
		If Selection.CheckAnalytics
			And Not ValueIsFilled(Selection.DimensionOfExpenses)
			And ValueIsFilled(Selection.ExpenseItem) Then
			
			MessageText = StrTemplate(TemplateFieldIsNotFilledIn, NStr("vi = 'Đối tượng phân tích chi phí';
																		|ru = 'Аналитика расходов';
																		|en = 'Expense dimension'; fa = 'بُعد هزینه';
																		|it = 'Analitica delle uscite';
																		|pl = 'Analityka kosztów';
																		|tr = 'Gider boyutu'"), Selection.LineNumber, PresentationOfTS);
			Field = CommonClientServer.PathToTabularSection(TSName, Selection.LineNumber, "DimensionOfExpenses");
			Common.MessageToUser(MessageText, Object, Field, "Object", Cancel);
		EndIf;
		
		If Selection.NotAccountingIsSupportedInFormOfGroupFA Then
			MessageText = StrTemplate(TemplateDoesNotSupportAccountingInFormOfGroupOS, Selection.LineNumber, PresentationOfTS, Format(BeginningOfApplicationOfFSBU5, "DLF=D;"));
			Field = CommonClientServer.PathToTabularSection(TSName, Selection.LineNumber, "OperationCategory");
			Common.MessageToUser(MessageText, Object, Field, "Object", Cancel);
		EndIf;
		
		If Selection.MethodOfRepaymentOfCostIsNotSpecified Then
			MessageText = StrTemplate(TemplateMethodOfCostRepayment, Selection.OperationCategoryPresentation, Selection.LineNumber, PresentationOfTS);
			Field = CommonClientServer.PathToTabularSection(TSName, Selection.LineNumber, "OperationCategory");
			Common.MessageToUser(MessageText, Object, Field, "Object", Cancel);
		EndIf;
		
	EndDo;
	
EndProcedure

// Checks the order for the transfer of goods and materials into operation.
//
// Parameters:
//  Object - DocumentObject.InventoryConsumptionOrder - processed object
//  AttributesNotToCheck - Array - Array of paths to the details for which the fill check will be disabled.
//  Cancel - Boolean - True if there are errors.
//
Procedure CheckOrderForCommissioning(Object, AttributesNotToCheck, Cancel) Export
	
	If Object.BusinessOperation <> Enums.BusinessTransactions.TransferToOperation Then
		Return;
	EndIf;
	
	AttributesNotToCheck.Add("Goods.ExpenseItem");
	AttributesNotToCheck.Add("Goods.DimensionOfExpenses");
	AttributesNotToCheck.Add("Goods.AssetsLiabilitiesDimension");
	
	QueryText =
	"SELECT
	|	CAST(DocumentTable.LineNumber AS NUMBER) AS LineNumber,
	|	CAST(DocumentTable.OperationCategory AS Catalog.OperationCategories) AS OperationCategory,
	|	CAST(DocumentTable.ExpenseItem AS ChartOfCharacteristicTypes.ExpenseItems) AS ExpenseItem,
	|	DocumentTable.DimensionOfExpenses AS DimensionOfExpenses
	|INTO DocumentTable
	|FROM
	|	&DocumentTable AS DocumentTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CheckResult.LineNumber AS LineNumber,
	|	CheckResult.ExpenseItem AS ExpenseItem,
	|	CheckResult.DimensionOfExpenses AS DimensionOfExpenses,
	|	CheckResult.ArticleIsNotFormationOfValue AS ArticleIsNotFormationOfValue,
	|	CheckResult.ExpenseItemIsNotFilledIn AS ExpenseItemIsNotFilledIn,
	|	CheckResult.CheckAnalytics AS CheckAnalytics,
	|	CheckResult.NotAccountingIsSupportedInFormOfGroupFA AS NotAccountingIsSupportedInFormOfGroupFA
	|FROM
	|	(SELECT
	|		DocumentTable.LineNumber AS LineNumber,
	|		DocumentTable.ExpenseItem AS ExpenseItem,
	|		DocumentTable.DimensionOfExpenses AS DimensionOfExpenses,
	|	
	|		ISNULL(DocumentTable.OperationCategory.AccountAsGroupFA, FALSE)
	|			AND NOT (DocumentTable.ExpenseItem.ExpensesOccur = VALUE(Enum.ExpenseTypes.CalculationOfNonCurrentAssetsVAlue)
	|				AND DocumentTable.ExpenseItem.ExpensesOnAssets
	|				AND (DocumentTable.ExpenseItem.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|					OR DocumentTable.ExpenseItem.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost))) AS ArticleIsNotFormationOfValue,
	|
	|		DocumentTable.ExpenseItem IN (
	|				VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef),
	|				VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef),
	|				UNDEFINED) AS ExpenseItemIsNotFilledIn,
	|
	|		NOT ISNULL(DocumentTable.OperationCategory.AccountAsGroupFA, FALSE)
	|			AND DocumentTable.ExpenseItem IN (&ArticlesWithMandatoryAnalytics) AS CheckAnalytics,
	|
	|		ISNULL(DocumentTable.OperationCategory.AccountAsGroupFA, FALSE)
	|			AND &Date < &BeginningOfApplicationOfFSBU5 AS NotAccountingIsSupportedInFormOfGroupFA
	|	FROM
	|		DocumentTable AS DocumentTable
	|
	|	) AS CheckResult
	|
	|WHERE
	|	(CheckResult.ArticleIsNotFormationOfValue
	|		OR CheckResult.ExpenseItemIsNotFilledIn
	|		OR CheckResult.CheckAnalytics
	|		OR CheckResult.NotAccountingIsSupportedInFormOfGroupFA)
	|
	|ORDER BY
	|	LineNumber";
	
	ListOfArticles = New Array;
	DocumentTable = Object.Goods.Unload(, "LineNumber,OperationCategory,ExpenseItem,DimensionOfExpenses,");
	For Each TSRow In DocumentTable Do
		If ValueIsFilled(TSRow.ExpenseItem) Then
			ListOfArticles.Add(TSRow.ExpenseItem);
		EndIf;
	EndDo;
	
	BeginningOfApplicationOfFSBU5 = LocalAccntingClientServer.BeginningOfApplicationFSBU5_2019();
	
	Query = New Query(QueryText);
	Query.SetParameter("Date", Object.Date);
	Query.SetParameter("BeginningOfApplicationOfFSBU5", BeginningOfApplicationOfFSBU5);
	Query.SetParameter("DocumentTable", DocumentTable);
	Query.SetParameter("ArticlesWithMandatoryAnalytics", ChartsOfCharacteristicTypes.ExpenseItems.ArticlesWithMandatoryAnalytics(ListOfArticles));
	
	Result = Query.Execute();
		
	TemplateFieldIsNotFilledIn = NStr("vi = 'Chưa điền cột ""%1"" tại dòng %2 trong danh sách ""Hàng hóa""';
										|ru = 'Не заполнена колонка ""%1"" в строке %2 списка ""Товары""';
										|en = 'Column ""%1"" in line %2 of the ""Goods"" list is not filled in'; fa = 'Column ""%1"" in line %2 of the ""Goods"" list is not filled in';
										|it = 'Colonna ""%1"" nella riga %2 dell''elenco ""Merci"" non è compilata';
										|pl = 'Nie wypełniono kolumny ""%1"" w wierszu %2 listy ""Wiersze pozycji""';
										|tr = '""Ürünler"" listesinin %2 satırındaki ""%1"" sütunu eksik'");
	
	ArticleTemplateIsNotCostGeneration = NStr("vi = 'Tại dòng %1 trong danh sách ""Hàng hóa"" cần chọn dạng có chi phí liên quan đến giá trị tài sản cố định';
												|ru = 'В строке %1 списка ""Товары"" необходимо выбрать статью, расходы по которой относятся на стоимость основного средства';
												|en = 'In the %1line of the ""Goods"" list, select an item whose expenses are allocated to the fixed asset cost'; fa = 'In the %1line of the ""Goods"" list, select an item whose expenses are allocated to the fixed asset cost';
												|it = 'Nella riga %1dell''elenco ""Articoli"" è necessario selezionare la voce le cui spese si riferiscono al costo dell''immobilizzazione';
												|pl = 'W wierszu %1 listy ""Towary"" należy wybrać pozycję, której rozchody należą do wartości środka trwałego';
												|tr = '""Ürünler"" listesinin %1 satırında, maliyetleri sabit kıymetin değerine atfedilen kalemi seçmelisiniz'");

	TemplateDoesNotSupportAccountingInFormOfGroupOS = NStr("vi = 'Tại dòng %1 trong danh sách ""Hàng hóa"" đã chọn thể loại sử dụng có tính đến dạng TSCĐ theo nhóm. Việc hạch toán dưới dạng TSCĐ theo nhóm được hỗ trợ từ %2.';
															|ru = 'В строке %1 списка ""Товары"" выбрана категория эксплуатации с учетом в виде группового ОС. Учет в виде группового ОС поддерживается с %2.';
															|en = 'Operation category with accounting as group fixed assets is selected in the %1 line of the ""Goods"" list. Accounting as group fixed assets is supported with %2.'; fa = 'Operation category with accounting as group fixed assets is selected in the %1 line of the ""Goods"" list. Accounting as group fixed assets is supported with %2.';
															|it = 'Nella riga %1dell''elenco ""Articoli"" è stata selezionata una categoria di lavorazione con contabilità di tipo immobilizzazione di gruppo. Questa viene supportata con %2.';
															|pl = 'W wierszu %1 listy ""Towary"" jest wybrana kategoria eksploatacji z ewidencją w postaci grupowego środka trwałego. Ewidencja w postaci grupowego środka trwałego jest obsługiwana z %2.';
															|tr = '""Ürünler"" listesinin %1 satırında SK grubu muhasebesi ile operasyon kategorisi seçildi. SK grubu muhasebesi %2''ten itibaren desteklenir.'");
	
	Selection = Result.Select();
	While Selection.Next() Do
		
		If Selection.ArticleIsNotFormationOfValue Then
			MessageText = StrTemplate(ArticleTemplateIsNotCostGeneration, Selection.LineNumber);
			Field = CommonClientServer.PathToTabularSection("Goods", Selection.LineNumber, "ExpenseItem");
			Common.MessageToUser(MessageText, Object, Field, "Object", Cancel);
		EndIf;
		
		If Selection.ExpenseItemIsNotFilledIn Then
			MessageText = StrTemplate(TemplateFieldIsNotFilledIn, NStr("vi = 'Dạng chi phí';
																		|ru = 'Статья расходов';
																		|en = 'Expense item'; fa = 'قلم هزینه';
																		|it = 'Voce di spese';
																		|pl = 'Rodzaj kosztu';
																		|tr = 'Gider kalemi'"), Selection.LineNumber);
			Field = CommonClientServer.PathToTabularSection("Goods", Selection.LineNumber, "ExpenseItem");
			Common.MessageToUser(MessageText, Object, Field, "Object", Cancel);
		EndIf;
		
		If Selection.CheckAnalytics
			And Not ValueIsFilled(Selection.DimensionOfExpenses)
			And ValueIsFilled(Selection.ExpenseItem) Then
			
			MessageText = StrTemplate(TemplateFieldIsNotFilledIn, NStr("vi = 'Đối tượng phân tích chi phí';
																		|ru = 'Аналитика расходов';
																		|en = 'Expense dimension'; fa = 'بُعد هزینه';
																		|it = 'Analitica delle uscite';
																		|pl = 'Analityka kosztów';
																		|tr = 'Gider boyutu'"), Selection.LineNumber);
			Field = CommonClientServer.PathToTabularSection("Goods", Selection.LineNumber, "DimensionOfExpenses");
			Common.MessageToUser(MessageText, Object, Field, "Object", Cancel);
		EndIf;
		
		If Selection.NotAccountingIsSupportedInFormOfGroupFA Then
			MessageText = StrTemplate(TemplateDoesNotSupportAccountingInFormOfGroupOS, Selection.LineNumber, Format(BeginningOfApplicationOfFSBU5, "DLF=D;"));
			Field = CommonClientServer.PathToTabularSection("Goods", Selection.LineNumber, "OperationCategory");
			Common.MessageToUser(MessageText, Object, Field, "Object", Cancel);
		EndIf;
		
	EndDo;
	
EndProcedure

// Called before recording the order for commissioning.
// 
// Parameters:
//  Object - DocumentObject.InventoryConsumptionOrder - The object being processed.
//  Cancel - Boolean - True if there are errors.
Procedure BeforeRecordingOrderForCommissioning(Object, Cancel) Export
	
	If Object.BusinessOperation <> Enums.BusinessTransactions.TransferToOperation Then
		Return;
	EndIf;
	
	QueryText = 
	"SELECT
	|	CAST(DocumentTable.LineNumber AS NUMBER) AS LineNumber,
	|	CAST(DocumentTable.OperationCategory AS Catalog.OperationCategories) AS OperationCategory,
	|	DocumentTable.DimensionOfExpenses AS DimensionOfExpenses
	|INTO DocumentTable
	|FROM
	|	&DocumentTable AS DocumentTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentTable.LineNumber AS LineNumber
	|FROM
	|	DocumentTable AS DocumentTable
	|WHERE
	|	ISNULL(DocumentTable.OperationCategory.AccountAsGroupFA, FALSE)
	|	AND VALUETYPE(DocumentTable.DimensionOfExpenses) = TYPE(Catalog.Assets)
	|	AND DocumentTable.DimensionOfExpenses <> VALUE(Catalog.Assets.EmptyRef)";
	
	DocumentTable = Object.Goods.Unload(, "LineNumber,OperationCategory,DimensionOfExpenses,");

	Query = New Query(QueryText);
	Query.SetParameter("DocumentTable", DocumentTable);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	While Selection.Next() Do
		RowData = Object.Goods[Selection.LineNumber - 1];
		RowData.DimensionOfExpenses= Undefined;
	EndDo;
	
EndProcedure

// See ChartsOfCharacteristicTypes.ExpenseItems.ProcessingSelectionParameters
Procedure ProcessingParametersForSelectingExpenseItem(Parameters) Export
	
	If Parameters.Property("AccountAsGroupFA")
		And Parameters.AccountAsGroupFA Then
		Parameters.Filter.Insert("ExpensesOnAssets", True);
		Parameters.Filter.Insert("ExpensesOccur", Enums.ExpenseTypes.CalculationOfNonCurrentAssetsVAlue);
	EndIf; 
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region ProcessingOfRowsInTablePart

// Fills in the attributes of the category of operation in the line.
// 
// Parameters:
//  CurrentRow - FormDataStructure - Current line.
//  StructureOfActions - Structure - Structure of actions.
//	CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
Procedure FillInCategoryAttributes(CurrentRow, StructureOfActions, CachedValues) Export
	
	If Not StructureOfActions.Property("FillInCategoryAttributes") Then
		Return;
	EndIf;
	
	FeatureStructure = CachedValues.SignsOfCategoryOfOperation.Get(
		CurrentRow.OperationCategory);
		
	If FeatureStructure = Undefined Then
		
		FillParameters = StructureOfActions.FillInCategoryAttributes;
		If FillParameters = Undefined Then
			FillParameters = InventoryInOperationClientServer.ParametersForFillingInOperationCategoryAttributes();
		EndIf;
		
		Signs = "StocktakingRecord,AccountingForIndividuals,
			|AccountAsGroupFA,FACostCapitalizationArticle,
			|MethodOfRepaymentOfCostOfAC";
			
		If FillParameters.FillInExpenseItem Then
			Signs = Signs + ",ExpenseItem";
		EndIf;
			
		If FillParameters.FillInServiceLife Then
			Signs = Signs + ",ServiceLife";
		EndIf;
			
		FeatureStructure = Common.ObjectAttributesValues(CurrentRow.OperationCategory, Signs);
		
		If FillParameters.FillInExpenseItemForGroupFA
			And FeatureStructure.AccountAsGroupFA Then
			FeatureStructure.Insert("ExpenseItem", FeatureStructure.FACostCapitalizationArticle);
		EndIf;
		
		CachedValues.SignsOfCategoryOfOperation.Insert(
			CurrentRow.OperationCategory,
			FeatureStructure);
			
	EndIf;
	
	FillPropertyValues(CurrentRow, FeatureStructure);
	
EndProcedure

// Adds a query to the query package to get the data needed to fill in the data by category of operation
// when processing rows in the table part.
//
// Parameters:
//  StructureOfActions - See BatchProcessingOfTablePartServer.ProcessTSStrings.StructureOfActions
//  QueryDetails - See BatchProcessingOfTablePartServer.QueryDetails
//  CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
//
Procedure CompleteDescriptionOfRequestForProcessingPM_SignsOfCategoryOfOperation(StructureOfActions, QueryDetails, CachedValues) Export
	
	If Not BatchProcessingOfTablePartServer.YouNeedToPerformAction("FillInCategoryAttributes", StructureOfActions, CachedValues) Then
		Return;
	EndIf;
	
	FillParameters = StructureOfActions.FillInCategoryAttributes;
	If FillParameters = Undefined Then
		FillParameters = InventoryInOperationClientServer.ParametersForFillingInOperationCategoryAttributes();
	EndIf;

	Signs = 
	"CatOperationCategories.StocktakingRecord AS StocktakingRecord,
	|CatOperationCategories.AccountingForIndividuals AS AccountingForIndividuals,
	|CatOperationCategories.AccountAsGroupFA AS AccountAsGroupFA,
	|CatOperationCategories.FACostCapitalizationArticle AS FACostCapitalizationArticle,
	|CatOperationCategories.MethodOfRepaymentOfCostOfAC AS MethodOfRepaymentOfCostOfAC";
		
	If FillParameters.FillInExpenseItemForGroupFA Then
		Signs = Signs + "
		|,CASE 
		|	WHEN CatOperationCategories.AccountAsGroupFA
		|			THEN CatOperationCategories.FACostCapitalizationArticle
		|		ELSE CatOperationCategories.ExpenseItem
		|END AS ExpenseItem";
	ElsIf FillParameters.FillInExpenseItem Then
		Signs = Signs + "
		|,CatOperationCategories.ExpenseItem AS ExpenseItem";
	EndIf;
		
	If FillParameters.FillInServiceLife Then
		Signs = Signs + "
		|,CatOperationCategories.ServiceLife AS ServiceLife";
	EndIf;
	
	QueryText = 
	"SELECT
	|	DataSource.IdOfTTRow AS IdOfTTRow,
	|	&Signs
	|FROM
	|	TTDataSource AS DataSource
	|
	|		LEFT JOIN Catalog.OperationCategories AS CatOperationCategories
	|		ON CatOperationCategories.Ref = DataSource.OperationCategory
	|";
	
	QueryText = StrReplace(QueryText, "&Signs", Signs); 
			
	QueryDetails.QueriesTexts.Add(QueryText, "SignsOfCategoryOfOperation");
	
EndProcedure

// Fills in the service Attributes in the tabular part based on the category of operation, which are used to manage availability and verify filling.
// For example, if you select the category for which inventory is kept, you will need to fill in the Inv No. field.
// 
// Parameters:
//  CurrentRow - See BatchProcessingOfTablePartServer.ProcessTSString.CurrentRow
//  StructureOfActions - See BatchProcessingOfTablePartServer.ProcessTSStrings.StructureOfActions
//  CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
//
Procedure FillInAttributesOfOperationCategoryInBatches(CurrentRow, StructureOfActions, CachedValues) Export
	
	FillingData = BatchProcessingOfTablePartServer.DataForStringProcessing("SignsOfCategoryOfOperation", CachedValues);
	
	If FillingData <> Undefined Then
		
		FeatureStructure = FillingData[0];
	
	Else
		
		FeatureStructure = New Structure;
		FeatureStructure.Insert("StocktakingRecord", False);
		FeatureStructure.Insert("AccountingForIndividuals", False);
		FeatureStructure.Insert("AccountAsGroupFA", False);
		FeatureStructure.Insert("FACostCapitalizationArticle", Undefined);
		FeatureStructure.Insert("MethodOfRepaymentOfCostOfAC", Undefined);
		
	EndIf;
	
	FillPropertyValues(CurrentRow, FeatureStructure);
	
EndProcedure

// Fills in the batch of Inventory in operation in the line.
// 
// Parameters:
//  CurrentRow - FormDataStructure - Current line.
//  StructureOfActions - Structure - Structure of actions.
//	CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
Procedure FillInBatchOfTMTSV(CurrentRow, StructureOfActions, CachedValues) Export
	
	If Not StructureOfActions.Property("FillInBatchOfTMTSV") Then
		Return;
	EndIf;
	
	If StructureOfActions.FillInBatchOfTMTSV = Undefined Then
		ChoiceParameters = InventoryInOperationClientServer.ParametersOfSelectionOfGoodsInOperation();
	Else
		ChoiceParameters = StructureOfActions.FillInBatchOfTMTSV; // InventoryInOperationClientServer.ParametersOfSelectionOfGoodsInOperation
	EndIf;
	
	FillPropertyValues(ChoiceParameters, CurrentRow);

	QueryDetails = InventoryInOperationClientServer.DescriptionOfRequestToSelectBatchOfGoodsAndMaterials(ChoiceParameters);
	
	Query = New Query(QueryDetails.QueryText);
	For Each ParameterDetails In QueryDetails.QueryOptions Do
		Query.SetParameter(ParameterDetails.Key, ParameterDetails.Value);
	EndDo;
	
	NewValues = New Structure("Lot,StocktakingRecord,AccountingForIndividuals", Catalogs.LotsOfInventoryInOperation.EmptyRef(), False, False);

	Result = Query.Execute();	
	Selection = Result.Select();
	While Selection.Next() Do
	
		If Not ValueIsFilled(CurrentRow.Lot)
			Or Selection.Lot = CurrentRow.Lot Then
			
			NewValues.Lot = Selection.Lot;
			NewValues.StocktakingRecord = Selection.StocktakingRecord;
			NewValues.AccountingForIndividuals = Selection.AccountingForIndividuals;
			
			Break;
			
		EndIf;
	
	EndDo;
	
	FillPropertyValues(CurrentRow, NewValues);
	
EndProcedure

// Fills in the batch in the row of the tabular part according to the data of this row: Nomenclature, Characteristics, Physical. person, Inv no.
// For example, if you fill in these fields during the move, the corresponding batch should be automatically filled in.
// 
// Parameters:
//  CurrentRow - FormDataStructure - Current line.
//  StructureOfActions - Structure - Structure of actions.
//	CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
Procedure FillInBatchOfTMTSVOperationInBatches(CurrentRow, StructureOfActions, CachedValues) Export
	
	NewValues = New Structure;
	NewValues.Insert("Lot", Catalogs.LotsOfInventoryInOperation.EmptyRef());
	NewValues.Insert("StocktakingRecord", False);
	NewValues.Insert("AccountingForIndividuals", False);

	FillingData = BatchProcessingOfTablePartServer.DataForStringProcessing("LotsOfInventoryInOperation", CachedValues);
	
	If FillingData <> Undefined Then
		
		For Each Selection In FillingData Do
			
			If Not ValueIsFilled(CurrentRow.Lot)
				Or Selection.Lot = CurrentRow.Lot Then
				
				NewValues.Lot = Selection.Lot;
				NewValues.StocktakingRecord = Selection.StocktakingRecord;
				NewValues.AccountingForIndividuals = Selection.AccountingForIndividuals;
				
				Break;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	FillPropertyValues(CurrentRow, NewValues);
	
EndProcedure

Procedure CompleteDescriptionOfRequestForProcessingPM_FillInBatchOfInventoryItemsForOperation(StructureOfActions, QueryDetails, CachedValues)
	
	If Not BatchProcessingOfTablePartServer.YouNeedToPerformAction("FillInBatchOfTMTSV", StructureOfActions, CachedValues) Then
		Return;
	EndIf;
	
	If StructureOfActions.FillInBatchOfTMTSV = Undefined Then
		ChoiceParameters = InventoryInOperationClientServer.ParametersOfSelectionOfGoodsInOperation();
	Else
		ChoiceParameters = StructureOfActions.FillInBatchOfTMTSV; // InventoryInOperationClientServer.ParametersOfSelectionOfGoodsInOperation
	EndIf;
	
	QueryText =
	"SELECT DISTINCT
	|	TTDataSource.Products AS Products
	|
	|INTO TTDataSource_InventoryList
	|
	|FROM
	|	TTDataSource AS TTDataSource
	|
	|INDEX BY
	|	Products
	|";
	QueryDetails.QueriesTexts.Add(QueryText, "TTDataSource_InventoryList");

	QueryText =
	"SELECT ALLOWED
	|	InventoryInOperation.Lot AS Lot,
	|	ISNULL(InventoryInOperation.Lot.OperationCategory.StocktakingRecord, FALSE) AS StocktakingRecord,
	|	ISNULL(InventoryInOperation.Lot.OperationCategory.AccountingForIndividuals, FALSE) AS AccountingForIndividuals,
	|	InventoryInOperation.Department AS Department,
	|	InventoryInOperation.Individual AS Individual,
	|	InventoryInOperation.Products AS Products,
	|	InventoryInOperation.Characteristic AS Characteristic,
	|	InventoryInOperation.Series AS Series,
	|	InventoryInOperation.LineOfBusiness AS LineOfBusiness,
	|	InventoryInOperation.AssetID AS AssetID,
	|	InventoryInOperation.CCDNumber AS CCDNumber
	|
	|INTO InventoryInOperation
	|
	|FROM
	|	(SELECT
	|		InventoryInOperation.Organization AS Organization,
	|		InventoryInOperation.Department AS Department,
	|		InventoryInOperation.Individual AS Individual,
	|		InventoryInOperation.Products AS Products,
	|		InventoryInOperation.Characteristic AS Characteristic,
	|		InventoryInOperation.Series AS Series,
	|		InventoryInOperation.Lot AS Lot,
	|		InventoryInOperation.LineOfBusiness AS LineOfBusiness,
	|		InventoryInOperation.AssetID AS AssetID,
	|		InventoryInOperation.CCDNumber AS CCDNumber,
	|		InventoryInOperation.CountBalance AS Count
	|	FROM
	|		AccumulationRegister.InventoryInOperation.Balance(
	|			&PlaceOfOperation_SelectionDate,
	|			(Organization = &TMCVOperation_SelectionCompany
	|					OR &TMCVOperation_SelectionCompany = VALUE(Catalog.Companies.EmptyRef))
	|
	|				AND (Department = &TMCVOperation_SelectionDivision
	|					OR &TMCVOperation_SelectionDivision = VALUE(Catalog.BusinessStructure.EmptyRef))
	|
	|				AND Products IN (
	|						SELECT
	|							TTDataSource_InventoryList.Products
	|						FROM
	|							TTDataSource_InventoryList AS TTDataSource_InventoryList)
	|
	|				AND (Products,Characteristic,Individual,AssetID) IN (
	|						SELECT
	|							TTDataSource.Products,
	|							TTDataSource.Characteristic,
	|							TTDataSource.Individual,
	|							TTDataSource.AssetID
	|						FROM
	|							TTDataSource AS TTDataSource)) AS InventoryInOperation
	|
	|	UNION ALL
	|
	|	SELECT
	|		InventoryInOperation.Organization AS Organization,
	|		InventoryInOperation.Department AS Department,
	|		InventoryInOperation.Individual AS Individual,
	|		InventoryInOperation.Products AS Products,
	|		InventoryInOperation.Characteristic AS Characteristic,
	|		InventoryInOperation.Series AS Series,
	|		InventoryInOperation.Lot AS Lot,
	|		InventoryInOperation.LineOfBusiness AS LineOfBusiness,
	|		InventoryInOperation.AssetID AS AssetID,
	|		InventoryInOperation.CCDNumber AS CCDNumber,
	|		CASE
	|			WHEN InventoryInOperation.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -InventoryInOperation.Count
	|			ELSE InventoryInOperation.Count
	|		END AS Count
	|	FROM
	|		AccumulationRegister.InventoryInOperation AS InventoryInOperation
	|
	|	WHERE
	|		InventoryInOperation.Recorder = &TMCVOfOperation_CurrentRegistrar
	|		AND InventoryInOperation.Active
	|
	|		AND (InventoryInOperation.Period < &PlaceOfOperation_SelectionDate
	|			OR &PlaceOfOperation_SelectionDate = DATETIME(1,1,1))
	|
	|		AND (InventoryInOperation.Organization = &TMCVOperation_SelectionCompany
	|				OR &TMCVOperation_SelectionCompany = VALUE(Catalog.Companies.EmptyRef))
	|
	|		AND (InventoryInOperation.Department = &TMCVOperation_SelectionDivision
	|				OR &TMCVOperation_SelectionDivision = VALUE(Catalog.BusinessStructure.EmptyRef))
	|
	|		AND InventoryInOperation.Products IN (
	|				SELECT
	|					TTDataSource_InventoryList.Products
	|				FROM
	|					TTDataSource_InventoryList AS TTDataSource_InventoryList)
	|
	|		AND (Products,Characteristic,Individual,AssetID) IN (
	|				SELECT
	|					TTDataSource.Products,
	|					TTDataSource.Characteristic,
	|					TTDataSource.Individual,
	|					TTDataSource.AssetID
	|				FROM
	|					TTDataSource AS TTDataSource)
	|
	|	) AS InventoryInOperation
	|
	|GROUP BY
	|	InventoryInOperation.Organization,
	|	InventoryInOperation.Department,
	|	InventoryInOperation.Individual,
	|	InventoryInOperation.Products,
	|	InventoryInOperation.Characteristic,
	|	InventoryInOperation.Series,
	|	InventoryInOperation.Lot,
	|	InventoryInOperation.LineOfBusiness,
	|	InventoryInOperation.AssetID,
	|	InventoryInOperation.CCDNumber
	|
	|HAVING
	|	SUM(InventoryInOperation.Count) > 0
	|";
	QueryDetails.QueriesTexts.Add(QueryText, "InventoryInOperation");
	
	QueryText = 
	"SELECT DISTINCT
	|	DataSource.IdOfTTRow AS IdOfTTRow,
	|	InventoryInOperation.Lot AS Lot,
	|	InventoryInOperation.StocktakingRecord AS StocktakingRecord,
	|	InventoryInOperation.AccountingForIndividuals AS AccountingForIndividuals
	|
	|FROM
	|	TTDataSource AS DataSource
	|
	|		LEFT JOIN InventoryInOperation AS InventoryInOperation
	|		ON InventoryInOperation.Products = DataSource.Products
	|			AND InventoryInOperation.Characteristic = DataSource.Characteristic
	|			AND InventoryInOperation.Individual = DataSource.Individual
	|			AND InventoryInOperation.AssetID = DataSource.AssetID
	|			AND &SelectionTextBatch
	|";
	
	If BatchProcessingOfTablePartServer.ThereIsColumnInDataSource("BatchesIndicationStatusSender", CachedValues) Then
		
		SelectionTextBatch =
		"(InventoryInOperation.Series = DataSource.Series
		|	OR DataSource.BatchesIndicationStatusSender <> 19
		|		AND DataSource.BatchesIndicationStatusSender <> 20)";
		
	Else
		
		SelectionTextBatch =
		"(InventoryInOperation.Series = DataSource.Series
		|	OR DataSource.BatchesIndicationStatus <> 19
		|		AND DataSource.BatchesIndicationStatus <> 20)";
		
	EndIf;
	QueryText = StrReplace(QueryText, "&SelectionTextBatch", SelectionTextBatch);

	QueryDetails.QueriesTexts.Add(QueryText, "LotsOfInventoryInOperation");
	
	FilterDate = ?(
		ChoiceParameters.Date <> Undefined And ChoiceParameters.Date <> '000101010000', 
		EndOfDay(ChoiceParameters.Date) + 1, 
		'000101010000');
	
	FilterOrganization = ?(
		ChoiceParameters.Organization <> Undefined, 
		ChoiceParameters.Organization, 
		PredefinedValue("Catalog.Companies.EmptyRef"));

	FilterDepartment = ?(
		ChoiceParameters.Department <> Undefined, 
		ChoiceParameters.Department, 
		PredefinedValue("Catalog.BusinessStructure.EmptyRef"));

	QueryDetails.QueryOptions.Insert("PlaceOfOperation_SelectionDate", FilterDate);
	QueryDetails.QueryOptions.Insert("TMCVOperation_SelectionCompany", FilterOrganization);
	QueryDetails.QueryOptions.Insert("TMCVOperation_SelectionDivision", FilterDepartment);
	QueryDetails.QueryOptions.Insert("TMCVOfOperation_CurrentRegistrar", ChoiceParameters.CurrentRegistrar);
	
EndProcedure

#EndRegion

#EndRegion
