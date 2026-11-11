////////////////////////////////////////////////////////////////////////////////
// NSI of production: Procedures of the subsystem of product data management
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
	
	// Posting
	If Properties.WriteMode = DocumentWriteMode.Posting Then
		Parameters.SubordinateRegisters.Add(Metadata.InformationRegisters.AlternativeMaterials);
	EndIf;
	If Properties.WriteMode <> DocumentWriteMode.Write Then
		Parameters.IndependentRegisters.Add(Metadata.InformationRegisters.ScopesOfSubstitutes);
	EndIf;
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
	
	QueriesTexts = New Map();
	
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

// The procedure of formation of movements on the slave registers of the NSI production.
//
// Parameters:
//	TablesForRegisteredRecords - Structure - document data tables
//	RegisterRecords - RegisterRecordsCollection - collection of document movement record sets
//	Cancel - Boolean - indicates that the document was rejected.
//
Procedure ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, Cancel) Export
	
	If Cancel Then
		Return;
	EndIf;
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "AlternativeMaterials");
EndProcedure

// The procedure for forming Registered Records on the independent registers of the NSI of production.
//
// Parameters:
//	TablesForRegisteredRecords - Structure - document data tables
//	Document - DocumentRef - link to the document
//	TempTablesManager - TempTablesManager - Manager temporary tables in the document
//	Cancel - Boolean - indicates that the document was rejected.
//
Procedure WriteData(TablesForRegisteredRecords, Document, TempTablesManager, Cancel) Export
	
	If Cancel Then
		Return;
	EndIf;
	TableName = "Table" + "ScopesOfSubstitutes";
	
	If TablesForRegisteredRecords.Property(TableName) Then
		
		Set = InformationRegisters.ScopesOfSubstitutes.CreateRecordSet();
		Set.Filter.Resolution.Set(Document);
		Set.Load(TablesForRegisteredRecords[TableName]);
		Set.Write();
		
	EndIf;
EndProcedure 

#EndRegion

#Region Specifications

// Returns the specifications of the product
//
// Parameters:
//  ProductData             - See ProductDataManagementClientServer.ProductDataStructureForSpecificationSelection
//  BOMSelectionParameters - See ProductDataManagementClientServer.BOMSelectionParameters
// 
// Returns:
//  Array - contains the data of the product specifications.
//
Function BillsOfMaterial(ProductData, BOMSelectionParameters) Export
	
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement("BillsOfMaterials.BillsOfMaterial");
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	0                                                                   AS TheIndexOfTheData,
	|	CAST(&Products AS Catalog.Products).ProductKind AS ProductKind,
	|	&Products                                                       AS Products,
	|	&Characteristic                                                     AS Characteristic,
	|	BEGINOFPERIOD(&ProductionStart, DAY)                            AS ProductionStart,
	|	&ProductionDispatcherBusinessUnit                                             AS ProductionDispatcherBusinessUnit,
	|	&LineOfBusiness                                            AS LineOfBusiness,
	|	&UnderRepairProduct                                   AS UnderRepairProduct,
	|	&UnderRepairVariant                                 AS UnderRepairVariant
	|INTO TTListOfProducts
	|;
	|";
	
	Query.SetParameter("Products",                       ProductData.Products);
	Query.SetParameter("Characteristic",                     ProductData.Characteristic);
	Query.SetParameter("ProductionStart",                 ProductData.ProductionStart);
	Query.SetParameter("ProductionDispatcherBusinessUnit",             ProductData.ProductionDispatcherBusinessUnit);
	Query.SetParameter("LineOfBusiness",            ProductData.LineOfBusiness);
	Query.SetParameter("UnderRepairProduct",   ProductData.UnderRepairProduct);
	Query.SetParameter("UnderRepairVariant", ProductData.UnderRepairVariant);
	
	RequestTextParameters = ParametersOfRequestTextForManufacturedProductSpecifications();
	
	Query.Text = Query.Text +  RequestTextForProductItemsSpecifications(
		RequestTextParameters,
		BOMSelectionParameters);
	
	SetParametersForRequestManufacturedProductSpecifications(Query, BOMSelectionParameters);
	
	QueryResult = Query.Execute();
	
	BOMList = New Array;
	If Not QueryResult.IsEmpty() Then
		
		Selection = QueryResult.Select();
		While Selection.Next() Do
			SpecificationData = New Structure("BillOfMaterials,SelectedAutomatically,"+BOMSelectionParameters.SpecificationDetails);
			FillPropertyValues(SpecificationData, Selection);
			BOMList.Add(SpecificationData);
		EndDo;
		
	EndIf;
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, BOMList.Count());
	
	Return BOMList;
	
EndFunction

// Returns the specifications of the products
//
// Parameters:
//  ProductData_2            - See ProductDataManagementClientServer.ProductDataStructureForSpecificationSelection
//  BOMSelectionParameters - See ProductDataManagementClientServer.BOMSelectionParameters
// 
// Returns:
//  Array - contains the data of the product specifications.
//
Function ProductsBOM(ProductData_2, BOMSelectionParameters) Export
	
	If Not ValueIsFilled(ProductData_2) Then
		Return New Array;
	EndIf;
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	T.TheIndexOfTheData                            AS TheIndexOfTheData,
	|	T.Products                            AS Products,
	|	T.Characteristic                          AS Characteristic,
	|	BEGINOFPERIOD(T.ProductionStart, DAY) AS ProductionStart,
	|	T.ProductionDispatcherBusinessUnit                  AS ProductionDispatcherBusinessUnit,
	|	T.LineOfBusiness                 AS LineOfBusiness,
	|	T.UnderRepairProduct        AS UnderRepairProduct,
	|	T.UnderRepairVariant      AS UnderRepairVariant
	|INTO ItemList
	|FROM
	|	&ItemList AS T
	|
	|;
	|
	|SELECT
	|	T.*,
	|	T.Products.ProductKind AS ProductKind
	|INTO TTListOfProducts
	|FROM
	|	ItemList AS T
	|
	|INDEX BY
	|	Products, Characteristic
	|;
	|
	|";
	
	ItemList = ProductDataTableForSpecificationSelection();
	For TheIndexOfTheData = 0 To ProductData_2.UBound() Do
		NewRow = ItemList.Add();
		FillPropertyValues(NewRow, ProductData_2[TheIndexOfTheData]);
		NewRow.TheIndexOfTheData = TheIndexOfTheData;
	EndDo;
	Query.SetParameter("ItemList", ItemList);
	
	RequestTextParameters = ParametersOfRequestTextForManufacturedProductSpecifications();
	
	Query.Text = Query.Text + RequestTextForProductItemsSpecifications(
		RequestTextParameters,
		BOMSelectionParameters);
	
	SetParametersForRequestManufacturedProductSpecifications(Query, BOMSelectionParameters);
	
	BOMList = Query.Execute().Unload();
	
	Result = New Array(ProductData_2.Count());
	
	StopProcessing = New Map;
	
	For IndexOf = 0 To BOMList.Count() - 1 Do
		
		StringSpecification = BOMList[IndexOf];
		TheIndexOfTheData       = StringSpecification.TheIndexOfTheData;
		
		If StopProcessing.Get(TheIndexOfTheData) = True Then
			Continue;
		EndIf;
		
		ProductData        = ProductData_2[TheIndexOfTheData];
		PickUpAutomatically = (Result[TheIndexOfTheData] = Undefined And StringSpecification.SelectedAutomatically = True);
		
		If ProductData.Property("CurrentSpecification") And ValueIsFilled(ProductData.CurrentSpecification) Then
		
			ThisIsCurSpecification = (StringSpecification.BillOfMaterials = ProductData.CurrentSpecification);
			
			If ThisIsCurSpecification Or PickUpAutomatically Then
				Result[TheIndexOfTheData] = New Structure("BillOfMaterials,"+BOMSelectionParameters.SpecificationDetails);
				FillPropertyValues(Result[TheIndexOfTheData], StringSpecification);
			EndIf;
			
			If ThisIsCurSpecification Then
				StopProcessing.Insert(TheIndexOfTheData, True);
			EndIf;
		
		ElsIf PickUpAutomatically Then
			
			Result[TheIndexOfTheData] = New Structure("BillOfMaterials,"+BOMSelectionParameters.SpecificationDetails);
			FillPropertyValues(Result[TheIndexOfTheData], StringSpecification);
			StopProcessing.Insert(TheIndexOfTheData, True);
			
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

// Fills in the specification in the lines
//
// Parameters:
//  RowsArray					 - FormDataStructure, LineOfATabularSection - lines to fill in the specification
//  ProductData_2			 - See ProductDataManagementClientServer.ProductDataStructureForSpecificationSelection
//  BOMSelectionParameters	 - See ProductDataManagementClientServer.BOMSelectionParameters
//  FieldNameSpecification			 - String									 - Name of the specification field
//  OnlyEmpty			 - Boolean									 - True if you need to fill in the specification only if it is not specified.
//
Procedure FillInSpecificationInLines(RowsArray, ProductData_2, BOMSelectionParameters, FieldNameSpecification = "BillOfMaterials", OnlyEmpty = False) Export
	
	ProductsBOM = ProductsBOM(ProductData_2, BOMSelectionParameters);
	
	FieldName = FieldNameSpecification;
	TheIndexOfTheData = 0;
	For Each CurrentRow In RowsArray Do
		
		If Not ValueIsFilled(CurrentRow[FieldName]) Or Not OnlyEmpty Then
			
			SpecificationData = ProductsBOM[TheIndexOfTheData];
			
			If SpecificationData <> Undefined Then
				CurrentRow[FieldName] = SpecificationData.BillOfMaterials;
			Else
				CurrentRow[FieldName] = Undefined;
			EndIf;
			
			FillingValues = New Structure;
			For Each Attribute In StrSplit(BOMSelectionParameters.SpecificationDetails,",",False) Do
				FillingValues.Insert(Attribute, ?(SpecificationData = Undefined, Undefined, SpecificationData[Attribute]));
			EndDo;
			FillPropertyValues(CurrentRow, FillingValues);
			
		EndIf;
		
		ProductData_2[TheIndexOfTheData].Insert("BillOfMaterials", CurrentRow[FieldName]);
		TheIndexOfTheData = TheIndexOfTheData + 1;
		
	EndDo; 

EndProcedure

// Checks the correctness of filling in semi finished products produced in the process
//
// Parameters:
// 		DataCollection - TabularSection - The table in which you need to fill in THE Attributes contains:
// 			* LineNumber - Number - the line number table
// 		CheckParameters - Structure - The parameters of the checks to be performed contain:
// 			* ParametersForCheckingInternalSemiFinishedProducts - Structure - the structure of parameters for checking internal pf contains:
// 				** TableOfSemiFinishedProducts - ValueTable - table of semi-finished products to check
// 		Cancel - Boolean - indicates whether there are fill-in errors
// 		Object - CatalogObject.BillsOfMaterials - object associated with the check.
//
Procedure CheckSpecificationsOfSemiFinishedProducts(DataCollection, CheckParameters, Cancel, Object = Undefined) Export
	
	SubsystemSettingsProduction = ProductionServer.SubsystemSettingsProduction();
	
	DataPath = "";
	AttributeName = "SourceOfSemiFinishedProduct";
	
	StructureOfChecks = CheckParameters.StructureOfChecks;
	OutputMessages = True;
	
	If CheckParameters.Property("DataPath") Then
		DataPath = CheckParameters.DataPath;
	EndIf;
	
	If CheckParameters.Property("AttributeName") Then
		AttributeName = CheckParameters.AttributeName;
	EndIf;
	
	If CheckParameters.Property("OutputMessages") Then
		OutputMessages = CheckParameters.OutputMessages;
	EndIf;
	
	MessageTemplateNoProduct              = NStr("vi = 'Trong các sản phẩm đầu ra của bảng kê chi tiết các nguồn lực sản xuất bán thành phẩm, phải có sản phẩm bán thành phẩm được tiêu thụ trong bảng kê chi tiết các nguồn lực sản xuất hiện tại (danh sách ""Nguyên vật liệu và nhân công"", dòng %1)';
												|ru = 'В выходных изделиях спецификации полуфабриката должен быть полуфабрикат, который потребляется в текущей спецификации (список ""Материалы и работы"", строка %1)';
												|en = 'In the finished products of semi-finished product BOM, there should be a semi-finished product which is used in the current bill of materials (the ""Materials and works"" list, line %1)'; fa = 'In the finished products of semi-finished product BOM, there should be a semi-finished product which is used in the current bill of materials (the ""Materials and works"" list, line %1)';
												|it = 'Nei prodotti di output della specifica del semilavorato vi deve essere un semilavorato ulizzato nella specifica corrente (elenco ""Materiali e lavori"", riga %1)';
												|pl = 'W produktach wyjściowych, w specyfikacji półproduktu musi być wskazany półprodukt, który był zużyty w bieżącej specyfikacji (Lista ""Materiały i prace"", wiersz %1)';
												|tr = 'Yarı mamul ürün reçetesinin üretilen nihai ürünlerinde, mevcut ürün reçetesinde sarf edilen yarı mamul ürün bulunmalıdır (""Malzemeler ve İşler"" listesi, %1 satırı)'");
	MessageTemplateRecyclingOnSide    = NStr("vi = 'Theo bảng kê chi tiết các nguồn lực sản xuất của bán thành phẩm, quy trình sản xuất được thực hiện bởi bên nhận gia công. Các sản phẩm bán thành phẩm phải được sản xuất riêng (danh sách ""Nguyên vật liệu và nhân công"", dòng %1)';
											|ru = 'По спецификации полуфабриката производственный процесс выполняется силами переработчика. Полуфабрикаты должны производиться собственными силами (список ""Материалы и работы"", строка %1)';
											|en = 'Production process against the semi-finished product BOM is performed by subcontractor. The semi-finished products should be manufactured in-house (the ""Materials and works"" list, line %1)'; fa = 'Production process against the semi-finished product BOM is performed by subcontractor. The semi-finished products should be manufactured in-house (the ""Materials and works"" list, line %1)';
											|it = 'Secondo la specifica del semilavorato, il processo di produzione viene effettuato con le forze del subfornitore. I semilavorati devono essere prodotti in proprio (elenco ""Materiali e lavori"", riga %1)';
											|pl = 'Według specyfikacji półproduktu proces produkcyjny odbywa się siłami przetwórcy. Półprodukty powinny być wykonywane własnymi siłami (lista ""Materiały i prace"", wiersz %1)';
											|tr = 'Yarı mamulün ürün reçetesine göre, üretim süreci fason üretici tarafından gerçekleştirilmektedir. Yarı mamul ürünler kendi bünyesinde üretilmelidir (Malzemeler ve İşler"" listesi, %1 satırı)'");
	TemplateMessageSpecificationIsNotValid = NStr("vi = 'Bảng kê chi tiết các nguồn lực sản xuất bán thành phẩm phải hợp lệ (danh sách ""Nguyên vật liệu và nhân công"", dòng  %1)';
													|ru = 'Спецификация полуфабриката должна быть действующей (список ""Материалы и работы"", строка %1)';
													|en = 'Semi-finished product BOM should be valid (the ""Materials and works"" list, line %1)'; fa = 'Semi-finished product BOM should be valid (the ""Materials and works"" list, line %1)';
													|it = 'La specifica del semilavorato deve essere attiva (elenco ""Materiali e lavori"", riga %1)';
													|pl = 'Specyfikacja półproduktu musi być aktualna (lista ""Materiały i prace"", wiersz %1)';
													|tr = 'Yarı mamul ürün reçetesi aktif olmalıdır (Malzemeler ve İşler"" listesi, %1 satırı)'");
	MessageTemplateMultipleQuantity     = NStr("vi = 'Trong bảng kê chi tiết các nguồn lực sản xuất của bán thành phẩm, đầu ra của bán thành phẩm phải là bội số của số lượng bán thành phẩm đã tiêu thụ của bảng kê chi tiết các nguồn lực sản xuất hiện tại (danh sách ""Nguyên liệu và công việc"", dòng %1)';
												|ru = 'В спецификации полуфабриката выход полуфабриката должен быть кратен количеству потребляемого полуфабриката текущей спецификации (список ""Материалы и работы"", строка %1)';
												|en = 'Semi-finished product yield should be a multiple of quantity of the consumed semi-finished product of the current BOM (the ""Materials and works"" list, line %1)'; fa = 'Semi-finished product yield should be a multiple of quantity of the consumed semi-finished product of the current BOM (the ""Materials and works"" list, line %1)';
												|it = 'Nella specifica del semilavorato, l''emissione del semilavorato deve essere multipla alla quantità del semilavorato utilizzato nella specifica corrente (elenco ""Materiali e lavori"", riga %1)';
												|pl = 'W specyfikacji półproduktu wyjście półproduktu musi być wielokrotnością ilości zużywanego półproduktu bieżącej specyfikacji (lista ""Materiały i prace"", wiersz %1)';
												|tr = 'Yarı mamul ürün reçetesinde, yarı mamul ürünün çıkışı, mevcut ürün reçetesinde sarf edilen yarı mamul ürün miktarının katı olmalıdır (Malzemeler ve İşler"" listesi, %1 satırı)'");
	
	ItemList = New Array;
	BOMList = New Array;
	ListOfIntermediateSemiFinishedProductLines = New Array;
	
	For Each String In DataCollection Do
		
		If String.ProducedInProcess Then
		
			If ValueIsFilled(String.SourceOfSemiFinishedProduct) Then
				
				If TypeOf(String.SourceOfSemiFinishedProduct) = Type("CatalogRef.BillsOfMaterials") Then
					
					ItemList.Add(String.Products);
					BOMList.Add(String.SourceOfSemiFinishedProduct);
					
				ElsIf StructureOfChecks.Property("FillingInternalSemiFinishedProducts") Then
					
					ListOfIntermediateSemiFinishedProductLines.Add(String);
					
				EndIf;
			
			EndIf;
			
		EndIf;
		
	EndDo;
	
	QueryText = "
		|SELECT DISTINCT
		|	ProductionStages.Owner AS Ref
		|INTO TTSpecificationsOfSemiFinishedProducts
		|FROM
		|	Catalog.ProductionStages AS ProductionStages
		|WHERE
		|	ProductionStages.Owner IN (&SpecificationsOfSemiFinishedProducts)
		|	AND ProductionStages.ProductionByThirdParty
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	BillsOfMaterials.Ref AS Ref,
		|	BillsOfMaterials.Status AS Status,
		|	CASE
		|		WHEN SpecificationsWithStagesOnSide.Ref IS NULL 
		|			THEN FALSE
		|		ELSE TRUE
		|	END AS ThereIsRecyclingOnSide
		|FROM
		|	Catalog.BillsOfMaterials AS BillsOfMaterials
		|		LEFT JOIN TTSpecificationsOfSemiFinishedProducts AS SpecificationsWithStagesOnSide
		|		ON BillsOfMaterials.Ref = SpecificationsWithStagesOnSide.Ref
		|WHERE
		|	BillsOfMaterials.Ref IN(&SpecificationsOfSemiFinishedProducts)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	CatProducts.Ref          AS Products,
		|	CatProducts.ProductKind AS ProductKind
		|FROM
		|	Catalog.Products AS CatProducts
		|WHERE
		|	CatProducts.Ref IN (&ListOfSemiFinishedProducts)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ManufacturedProducts.Ref             AS Ref,
		|	ManufacturedProducts.ProductKind    AS ProductKind,
		|	ManufacturedProducts.Products       AS Products,
		|	ManufacturedProducts.Characteristic     AS Characteristic,
		|	ManufacturedProducts.Package           AS Package,
		|	ManufacturedProducts.NumberOfPackages AS NumberOfPackages
		|FROM
		|	Catalog.BillsOfMaterials.ManufacturedProducts AS ManufacturedProducts
		|WHERE
		|	ManufacturedProducts.Ref IN(&SpecificationsOfSemiFinishedProducts)";
	
	Query = New Query(QueryText);
	Query.SetParameter("ListOfSemiFinishedProducts",       ItemList);
	Query.SetParameter("SpecificationsOfSemiFinishedProducts", BOMList);
	
	Result = Query.ExecuteBatch(); 
	
	DetailsOfSpecifications = Result[1].Unload();
	ItemKinds      = Result[2].Unload();
	SpecificationsData    = Result[3].Unload();
	
	ItemKinds.Indexes.Add("Products");
	DetailsOfSpecifications.Indexes.Add("Ref");
	
	For Each StringMaterial In DataCollection Do
	
		If Not StringMaterial.ProducedInProcess 
			Or Not ValueIsFilled(StringMaterial.SourceOfSemiFinishedProduct)
			Or TypeOf(StringMaterial.SourceOfSemiFinishedProduct) <> Type("CatalogRef.BillsOfMaterials") Then
			Continue;
		EndIf;
		
		TheStructureOfTheSearch = New Structure("Ref", StringMaterial.SourceOfSemiFinishedProduct);
		SemiFinishedProductBOM = SpecificationsData.FindRows(TheStructureOfTheSearch);
		
		TableRow = ItemKinds.Find(StringMaterial.Products, "Products");
		If TableRow = Undefined Then
			TypeOfSemiFinishedProductProduct = Catalogs.ItemKinds.EmptyRef();
		Else
			TypeOfSemiFinishedProductProduct = TableRow.ProductKind;
		EndIf;
		
		Field = CommonClientServer.PathToTabularSection("MaterialsAndServices", StringMaterial.LineNumber, AttributeName);
		
		Attributes = DetailsOfSpecifications.Find(StringMaterial.SourceOfSemiFinishedProduct, "Ref");
		If Attributes <> Undefined And Attributes.Status <> Enums.BOMStatuses.Valid And StructureOfChecks.Property("SpecificationStatus_") Then
			
			// The specification is not valid
			If OutputMessages Then
				MessageText = StringFunctionsClientServer.SubstituteParametersToString(
					TemplateMessageSpecificationIsNotValid, 
					StringMaterial.LineNumber);
				
				Common.MessageToUser(MessageText, Object, Field, DataPath, Cancel);
			Else
				Cancel = True;
			EndIf;
			
		EndIf;
	
		
		ThereIsSemiFinishedProductOutput = False;
		For Each ProductLineSemiFinishedProductSpecifications In SemiFinishedProductBOM Do
			If (StringMaterial.Products = ProductLineSemiFinishedProductSpecifications.Products
					Or Not ValueIsFilled(ProductLineSemiFinishedProductSpecifications.Products)
						And ProductLineSemiFinishedProductSpecifications.ProductKind = TypeOfSemiFinishedProductProduct)
				And (Not ValueIsFilled(ProductLineSemiFinishedProductSpecifications.Characteristic)
					Or StringMaterial.Characteristic = ProductLineSemiFinishedProductSpecifications.Characteristic) Then
				
				ThereIsSemiFinishedProductOutput = True;
				
				
				Break;
			EndIf;
		EndDo;
		
		If StructureOfChecks.Property("ComplianceWithSpecification") Then
			If Not ThereIsSemiFinishedProductOutput Then
				// There is no semi-finished product output
				If OutputMessages Then
					MessageText = StringFunctionsClientServer.SubstituteParametersToString(
						MessageTemplateNoProduct,
						StringMaterial.LineNumber);
					
					Common.MessageToUser(MessageText, Object, Field, DataPath, Cancel);
				Else
					Cancel = True;
				EndIf;
				
			EndIf;
		EndIf;
		
	EndDo;
	
	If StructureOfChecks.Property("FillingInternalSemiFinishedProducts")
		And ListOfIntermediateSemiFinishedProductLines.Count() > 0 Then
		
		ParametersForCheckingInternalSemiFinishedProducts = CheckParameters.ParametersForCheckingInternalSemiFinishedProducts;
		QueryText = RequestTextForCheckingInternalSemiFinishedProducts(ParametersForCheckingInternalSemiFinishedProducts);
		TableOfDemandForSemiFinishedProducts = NeedForInternalSemiFinishedProducts(ParametersForCheckingInternalSemiFinishedProducts, ListOfIntermediateSemiFinishedProductLines);
		
		Query = New Query(QueryText);
		
		Query.SetParameter("ProductionIsUsed22", SubsystemSettingsProduction.ProductionIsUsed22);
		
		Query.SetParameter("TableOfDemandForSemiFinishedProducts", TableOfDemandForSemiFinishedProducts);
		
		
		Result = Query.ExecuteBatch();
		NumberOfPackages_ = Result.Count();
		
		If Not Result[NumberOfPackages_ - 4].IsEmpty() Then
		
			Selection = Result[NumberOfPackages_ - 4].Select();
			
			Template = NStr("vi = 'Công đoạn sản xuất bán thành phẩm được thực hiện muộn hơn công đoạn sản xuất bán thành phẩm này (danh sách ""Nguyên vật liệu và nhân công"", dòng %1)';
							|ru = 'Этап выпуска полуфабриката выполняется позже этапа, на котором этот полуфабрикат потребляется (список ""Материалы и работы"", строка %1)';
							|en = 'Release stage of the semi-finished product is performed later than the stage at which this semi-finished product is consumed (the ""Materials and works"" list, line %1)'; fa = 'Release stage of the semi-finished product is performed later than the stage at which this semi-finished product is consumed (the ""Materials and works"" list, line %1)';
							|it = 'La fase di emissione del semilavorato si effettua dopo la fase in cui questo semilavorato viene usato (elenco ""Materiali e lavori"", riga %1)';
							|pl = 'Etap produkcji półproduktu odbywa się później etapu, na którym ten półprodukt jest zużywany (lista ""Materiały i prace"", wiersz %1)';
							|tr = 'Yarı mamul imalatı aşaması, bu yarı mamul ürünün sarf edildiği aşamadan sonra gerçekleştirilmektedir (Malzemeler ve İşler"" listesi, %1 satırı)'");
			
			While Selection.Next() Do
				
				If OutputMessages Then
					
					MessageText = StringFunctionsClientServer.SubstituteParametersToString(
						Template,
						Selection.LineNumber);
						
					Field = CommonClientServer.PathToTabularSection("MaterialsAndServices", 
						Selection.LineNumber, 
						AttributeName);
						
					Common.MessageToUser(
						MessageText,
						Object,
						Field,
						DataPath,
						Cancel);
						
				Else
					
					Cancel = True;
					
				EndIf;
				
			EndDo;
			
		EndIf;
		
		If Not Result[NumberOfPackages_ - 3].IsEmpty() Then
		
			Selection = Result[NumberOfPackages_ - 3].Select();
			
			Template = NStr("vi = 'Không được phép chỉ định các tác phẩm là bán thành phẩm được sản xuất ở các kỳ (danh sách ""Vật liệu và công việc"", dòng  %1)';
							|ru = 'Не допускается указание работ в качестве полуфабрикатов, производимых на этапах (список ""Материалы и работы"", строка %1)';
							|en = 'Cannot specify works as semi-finished products manufactured at stages (list ""Materials and works"", line %1)'; fa = 'Cannot specify works as semi-finished products manufactured at stages (list ""Materials and works"", line %1)';
							|it = 'Non è consentito indicare lavori come semilavorati prodotti nelle fasi (elenco ""Materiali e lavori"", riga %1)';
							|pl = 'Nie dopuszcza się wskazanie prac jako półproduktów wytwarzanych na etapach (lista ""Materiały i prace"", wiersz %1)';
							|tr = 'İşlerin aşamalarda üretilen yarı mamul ürünler olarak belirtilmesine izin verilmemektedir (Malzemeler ve İşler"" listesi, %1 satırı)'");
			
			While Selection.Next() Do
				
				If OutputMessages Then
				
					MessageText = StringFunctionsClientServer.SubstituteParametersToString(
						Template,
						Selection.LineNumber);
						
					Field = CommonClientServer.PathToTabularSection("MaterialsAndServices", 
						Selection.LineNumber, 
						AttributeName);
						
					Common.MessageToUser(
						MessageText,
						Object,
						Field,
						DataPath,
						Cancel);
						
				Else
						
					Cancel = True;
					
				EndIf;
				
			EndDo;
			
		EndIf;
		
		If Not Result[NumberOfPackages_ - 2].IsEmpty() Then
		
			Selection = Result[NumberOfPackages_ - 2].Select();
			
			Template = NStr("vi = 'Công đoạn sản xuất bán thành phẩm được thực hiện bởi bên nhận gia công. Các sản phẩm bán thành phẩm phải được sản xuất riêng (danh sách ""Nguyên vật liệu và nhân công"", dòng %1)';
							|ru = 'Этап выпуска полуфабриката выполняется переработчиком. Полуфабрикаты должны производиться собственными силами (список ""Материалы и работы"", строка %1)';
							|en = 'Release stage of the semi-finished product is performed by a subcontractor. Semi-finished products should be manufactured in-house (the ""Materials and works"" list, line %1)'; fa = 'Release stage of the semi-finished product is performed by a subcontractor. Semi-finished products should be manufactured in-house (the ""Materials and works"" list, line %1)';
							|it = 'La fase di emissione del semilavorato viene effettuata dal subfornitore. I semilavorati devono essere prodotti in proprio  (elenco ""Materiali e lavori"", riga %1)';
							|pl = 'Etap produkcji półproduktu odbywa się przez przetwórcę. Półprodukty powinny być wykonywane własnymi siłami (lista ""Materiały i prace"", wiersz %1)';
							|tr = 'Yarı mamul imalatı aşaması, fason üretici tarafından gerçekleştirilmektedir. Yarı mamul ürünler kendi bünyesinde üretilmelidir (Malzemeler ve İşler"" listesi, %1 satırı)'");
			
			While Selection.Next() Do
				
				If OutputMessages Then
				
					MessageText = StringFunctionsClientServer.SubstituteParametersToString(
						Template,
						Selection.LineNumber);
						
					Field = CommonClientServer.PathToTabularSection("MaterialsAndServices", 
						Selection.LineNumber, 
						AttributeName);
						
					Common.MessageToUser(
						MessageText,
						Object,
						Field,
						DataPath,
						Cancel);
						
				Else
						
					Cancel = True;
					
				EndIf;
				
			EndDo;
			
		EndIf;
		
		If Not Result[NumberOfPackages_ - 1].IsEmpty() Then
			
			Template  = NStr("vi = 'Các sản phẩm đầu ra không mô tả việc sản xuất bán thành phẩm ""%ProductsCharacteristic%"" tại công đoạn ""%ReleaseStage%"" trong%sufficient% số lượng%NotEnough% %Count% %Package%, xem danh sách ""%TableOfSemiFinishedProducts%"" (danh sách""Vật liệu và công việc"", dòng %LineNumber%)';
							|ru = 'В выходных изделиях не описан выпуск полуфабриката ""%ProductsCharacteristic%"" на этапе ""%ReleaseStage%"" в%sufficient% количестве%NotEnough% %Count% %Package%, см. список ""%TableOfSemiFinishedProducts%"" (список ""Материалы и работы"", строка %LineNumber%)';
							|en = 'Release of semi-finished product ""%ProductsCharacteristic%"" at stage ""%ReleaseStage%"" in %sufficient% quantity %NotEnough% %Count% %Package% is not described in the finished products, see list ""%TableOfSemiFinishedProducts%"" (the ""Materials and works"" list, line %LineNumber%)'; fa = 'Release of semi-finished product ""%ProductsCharacteristic%"" at stage ""%ReleaseStage%"" in %sufficient% quantity %NotEnough% %Count% %Package% is not described in the finished products, see list ""%TableOfSemiFinishedProducts%"" (the ""Materials and works"" list, line %LineNumber%)';
							|it = 'Nei prodotti di output non è descritta l''emissione del semilavorato ""%ProductsCharacteristic%"" alla fase ""%ReleaseStage%"" in%sufficient% quantità%NotEnough% %Count% %Package%, vedasi elenco ""%TableOfSemiFinishedProducts%""  (elenco ""Materiali e lavori"", riga %LineNumber%)';
							|pl = 'W wyrobach wyjściowych nie jest opisane wydanie półproduktu ""%ProductsCharacteristic%"" na etapie ""%ReleaseStage%"" w%sufficient% ilości%NotEnough%%Count%%Package%, patrz lista ""%TableOfSemiFinishedProducts%"" (lista ""Materiały i prace"", wiersz %LineNumber%)';
							|tr = 'Üretilen nihai ürünlerde ""%ProductsCharacteristic%"" yarı mamul ürününün çıkışı ""%ReleaseStage%"" aşamasındaki %sufficient%miktarda %Package% %Count% %NotEnough%, bk. ""%TableOfSemiFinishedProducts%"" listesi (""Malzemeler ve İşler"" listesi, %LineNumber% satırı)'");
			TextSufficient = " " + NStr("vi = 'đủ';
										|ru = 'достаточном';
										|en = 'sufficient'; fa = 'sufficient';
										|it = 'abbastanza';
										|pl = 'dostatecznie';
										|tr = 'yeterli'");
			TextIsMissing   = ", " + NStr("vi = 'không đủ';
											|ru = 'не хватает';
											|en = 'not enough'; fa = 'not enough';
											|it = 'non abbastanza';
											|pl = 'nie wystarcza';
											|tr = 'yetersiz'");
			
			TheStructureOfTheSearch = CommonClientServer.CopyStructure(
				ParametersForCheckingInternalSemiFinishedProducts.TheStructureOfTheSearch);
			
			TableOfSemiFinishedProductsBalance = ParametersForCheckingInternalSemiFinishedProducts.TableOfSemiFinishedProducts;
			TableOfSemiFinishedProductsBalance.Columns.Add("QuantityIsAvailable");
			
			Selection = Result[NumberOfPackages_ - 1].Select();
			
			While Selection.Next() Do
			
				FillPropertyValues(TheStructureOfTheSearch, Selection);
				
				FoundRows = TableOfSemiFinishedProductsBalance.FindRows(TheStructureOfTheSearch);
				
				If FoundRows.UBound() <> -1 Then
					StringSemiFinishedProduct = FoundRows[0];
				Else
					StringSemiFinishedProduct = Undefined;
				EndIf;
				
				If StringSemiFinishedProduct = Undefined Then
					QuantityIsAvailable = 0;
				ElsIf StringSemiFinishedProduct.QuantityIsAvailable <> Undefined Then
					QuantityIsAvailable = StringSemiFinishedProduct.QuantityIsAvailable;
				Else
					QuantityIsAvailable = StringSemiFinishedProduct.Count;
				EndIf;
				
				If QuantityIsAvailable = -1 Then
					Continue;
				EndIf;
				
				If Selection.Count > QuantityIsAvailable Then
					
					If OutputMessages Then
						
						MessageText = StrReplace(Template, "%ProductsCharacteristic%", 
											ProductsClientServer.ProductPresentation(Selection.ProductsPresentation, Selection.CharacteristicPresentation));
						MessageText = StrReplace(MessageText, "%ReleaseStage%", Selection.ReleaseStagePresentation);
						MessageText = StrReplace(MessageText, "%Count%", (Selection.Count - QuantityIsAvailable)/Selection.PackagingFactor);
						MessageText = StrReplace(MessageText, "%Package%", Selection.PackagePresentation);
						MessageText = StrReplace(MessageText, "%TableOfSemiFinishedProducts%", ParametersForCheckingInternalSemiFinishedProducts.PresentationOfTableOfSemiFinishedProducts);
						MessageText = StrReplace(MessageText, "%LineNumber%", Selection.LineNumber);
						
						If StringSemiFinishedProduct <> Undefined Then
							MessageText = StrReplace(MessageText, "%sufficient%", TextSufficient);
							MessageText = StrReplace(MessageText, "%NotEnough%", TextIsMissing);
						Else
							MessageText = StrReplace(MessageText, "%sufficient%", "");
							MessageText = StrReplace(MessageText, "%NotEnough%", "");
						EndIf;
						
						Field = CommonClientServer.PathToTabularSection("MaterialsAndServices", 
							Selection.LineNumber, 
							AttributeName);
							
						Common.MessageToUser(
							MessageText, 
							Object, 
							Field, 
							DataPath, 
							Cancel);
							
					Else
						
						Cancel = True;
						
					EndIf;
					
				EndIf;
				
				If StringSemiFinishedProduct <> Undefined Then
					StringSemiFinishedProduct.QuantityIsAvailable = Max(QuantityIsAvailable - Selection.Count, 0);
				EndIf;
				
			EndDo;
			
		EndIf;
			
	EndIf;
	
EndProcedure

// Returns parameters for selecting specifications for the item.
//
// Parameters:
//  Object			 - CatalogObject, DocumentObject, FormDataStructure	 - the object to generate parameters for.
//  ObjectManager	 - CatalogManager, DocumentManager						 - Manager of the object to generate parameters for.
// 
// Returns:
//  Structure - specification selection parameters.
//
Function BOMSelectionParameters(Object, ObjectManager) Export
	
	AttributesNames = ObjectManager.NamesOfDetailsForFillingInParametersForSelectingSpecifications();
	
	AttributesValues = Undefined;
	If ValueIsFilled(AttributesNames) Then
		If Documents.AllRefsType().ContainsType(TypeOf(Object))
			Or Catalogs.AllRefsType().ContainsType(TypeOf(Object)) Then
			AttributesValues = Common.ObjectAttributesValues(Object, AttributesNames);
		Else
			AttributesValues = New Structure(AttributesNames);
			FillPropertyValues(AttributesValues, Object);
		EndIf;
	EndIf;
	
	Return New FixedStructure(ObjectManager.BOMSelectionParameters(AttributesValues));
	
EndFunction

// Returns a description of the source of available specifications
//
// Returns:
//  Structure - source description fields
//
Function SourceOfAvailableSpecificationsConstructor() Export
	
	Result = New Structure;
	
	Result.Insert("QueryText",                             "");
	Result.Insert("TextOfProductsField",                    "");
	Result.Insert("TextOfSpecificationField",                    "");
	Result.Insert("TextOfProductSpecificationField",        "");
	Result.Insert("TextOfPackagingSpecificationField",            "");
	Result.Insert("NameOfTemporarySpecificationSourceTable", "");
	
	Return Result;
	
EndFunction

// Returns parameters for forming the text of the request for product specifications
//
// Returns:
//  Structure - request text parameters
//
Function ParametersOfRequestTextForManufacturedProductSpecifications() Export
	
	Result = New Structure;
	
	// Used if the name of the input table differs from the list of nomenclature
	Result.Insert("NameOfInputTable",           "");
	// Used if the result needs to be placed in a temporary table 
	Result.Insert("OutputTableName",          "");
	// True - if it is necessary to select only priority specifications
	Result.Insert("PriorityOnly",          False);
	// True - if it is necessary to sort the result by priority
	Result.Insert("OrderByPriority_",     True);
	// True - if it is necessary to put all fields of the structure/table of product data in the selection result
	Result.Insert("AllFieldsInResult",          False);
	// True - if it is necessary to destroy the temporary tables used
	Result.Insert("DestroyTemporaryTables",  True);
	// True - if a separator of the final package is needed
	Result.Insert("FinalPackageSeparator",  True);
	// Additional conditions for selecting the input table
	Result.Insert("ConditionsForSelectingIncomingData", New Array);
	// Complete the output table (it already exists)
	Result.Insert("AddOutputTable", False);
	// Structure - See SourceOfAvailableSpecificationsConstructor
	Result.Insert("SourceOfAvailableSpecifications", Undefined);
	// Redefining fields 
	Result.Insert("DataPaths", New Structure());
	
	Return Result;
	
EndFunction

// Returns the text of the request for product specifications
//
// Parameters:
//  QueryOptions            - See ProductDataManagement.ParametersOfRequestTextForManufacturedProductSpecifications
//  BOMSelectionParameters - See ProductDataManagementClientServer.BOMSelectionParameters
// 
// Returns:
//  String - request text for selecting product specifications
//
Function RequestTextForProductItemsSpecifications(QueryOptions, BOMSelectionParameters) Export
	
	DestroyTables = New Array;
	DestroyTables.Add("TTAvailableSpecifications");
	DestroyTables.Add("TTCorrespondToDestinationParameters");
	DestroyTables.Add("TTFoundInList");
	
	ProductDataManagementOverridable.SourceOfAvailableSpecifications(QueryOptions, BOMSelectionParameters);
	
	If ValueIsFilled(QueryOptions.SourceOfAvailableSpecifications) Then
		
		SourceOfAvailableSpecifications = QueryOptions.SourceOfAvailableSpecifications;
		
		QueryText                             = SourceOfAvailableSpecifications.QueryText;
		TextOfProductsField                    = SourceOfAvailableSpecifications.TextOfProductsField;
		TextOfSpecificationField                    = SourceOfAvailableSpecifications.TextOfSpecificationField;
		TextOfProductSpecificationField        = SourceOfAvailableSpecifications.TextOfProductSpecificationField;
		TextOfPackagingSpecificationField            = SourceOfAvailableSpecifications.TextOfPackagingSpecificationField;
		NameOfTemporarySpecificationSourceTable = SourceOfAvailableSpecifications.NameOfTemporarySpecificationSourceTable;
		
	Else
		
		DestroyTables.Add("TTSourceOfAvailableSpecifications");
		
		QueryText = "
		|
		|SELECT
		|	TTListOfProducts.TheIndexOfTheData            AS TheIndexOfTheData,
		|	TTListOfProducts.Products            AS Products,
		|	TTListOfProducts.Characteristic          AS Characteristic,
		|	TTListOfProducts.ProductionDispatcherBusinessUnit  AS ProductionDispatcherBusinessUnit,
		|	TTListOfProducts.LineOfBusiness AS LineOfBusiness,
		|	TTListOfProducts.ProductionStart      AS ProductionStart,
		|
		|	ProductsBOM.BillOfMaterials           AS BillOfMaterials,
		|	ProductsBOM.ValidOnDate         AS ValidOnDate,
		|	ProductsBOM.BillOfMaterials.Code       AS Code,
		|
		|	ProductsBOM.Status = VALUE(Enum.BOMStatuses.Valid)
		|		AND NOT ProductsBOM.BillOfMaterials.ExcludeAutomaticSelection
		|		AND &TextAutoSelectionConditionFinishedProductUnderRepair
		|		AND NOT ProductsBOM.SideExit                                                        AS SelectedAutomatically,
		|	ProductsBOM.Products   = VALUE(Catalog.Products.EmptyRef)               AS AnyProducts,
		|	ProductsBOM.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS AnyCharacteristic
		|
		|INTO TTSourceOfAvailableSpecifications
		|FROM
		|	InformationRegister.ProductsBOM AS ProductsBOM
		|
		|		INNER JOIN TTListOfProducts AS TTListOfProducts
		|		 ON ProductsBOM.ProductKind = TTListOfProducts.ProductKind
		|			AND (ProductsBOM.Products = TTListOfProducts.Products
		|				OR ProductsBOM.Products = VALUE(Catalog.Products.EmptyRef))
		|			AND (ProductsBOM.Characteristic = TTListOfProducts.Characteristic
		|				OR ProductsBOM.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef))
		|			AND &TextSelectionConditionRepairedFinishedProduct
		|			AND &TextConditionForSelectingIncomingData
		|
		|WHERE
		|
		|	(TTListOfProducts.ProductionStart = DATETIME(1, 1, 1) 
		|		OR ProductsBOM.ValidOnDate <= TTListOfProducts.ProductionStart)
		|	AND (ProductsBOM.ValidToDate = DATETIME(1, 1, 1)
		|		OR ProductsBOM.ValidToDate >= TTListOfProducts.ProductionStart)
		|
		|	AND (ProductsBOM.ProductionProcessType IN (&AvailableTypes)
		|		OR &AvailableTypesWithoutSelection)
		|
		|	AND (ProductsBOM.Status IN (&AvailableStatuses)
		|		OR &AvailableStatusesWithoutSelection)
		|
		|	AND (ProductsBOM.BillOfMaterials <> &ExcludeSpecification
		|		OR &ExcludeSpecificationWithoutSelection)
		|
		|	AND (ProductsBOM.SideExit = FALSE
		|		OR (&SideOutputSpecificationsAreAvailable
		|				AND ProductsBOM.BillOfMaterials.AllowSelectionForSideOutletProducts)
		|		OR (&SideOutputSpecificationsAreAvailable
		|				AND &ProductionIsUsed21))
		|
		|	AND &TextSelectionConditionForPackaging
		|
		|	AND &TextSelectionCriteriaByName
		|
		|	AND &TextConditionSpecificationsAreAvailableWithProductionOnSide
		|
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|";
		
		TextOfProductsField                    = "TTListOfProducts.Products";
		TextOfSpecificationField                    = "ProductsBOM.BillOfMaterials";
		TextOfProductSpecificationField        = "ProductsBOM.Products";
		TextOfPackagingSpecificationField            = "ProductsBOM.Package";
		NameOfTemporarySpecificationSourceTable = "TTSourceOfAvailableSpecifications";
	
	EndIf;
	
	ConditionText = TextOfSelectionConditionForPackagingWhenSelectingSpecifications(
		TextOfProductsField, TextOfProductSpecificationField, TextOfPackagingSpecificationField);
	QueryText = StrReplace(QueryText, "AND &TextSelectionConditionForPackaging", ConditionText);
	
	If BOMSelectionParameters.Property("SearchString") Then
		ConditionText = "
		|	AND (&TextOfSpecificationField.Description LIKE &SearchString
		|		OR &SearchString = """")";
	Else
		ConditionText = "";
	EndIf;
	QueryText = StrReplace(QueryText, "AND &TextSelectionCriteriaByName", ConditionText);
	
	If BOMSelectionParameters.Property("SpecificationsWithProductionOnSideAreAvailable")
		And Not BOMSelectionParameters.SpecificationsWithProductionOnSideAreAvailable Then
		ConditionText = "
		|	AND NOT TRUE IN (
		|		SELECT TOP 1
		|			TRUE
		|		FROM
		|			Catalog.ProductionStages AS T
		|		WHERE
		|			T.Owner = &TextOfSpecificationField
		|			AND T.ProductionByThirdParty
		|			AND NOT T.DeletionMark
		|		)";
	Else
		ConditionText = "";
	EndIf;
	QueryText = StrReplace(QueryText, "AND &TextConditionSpecificationsAreAvailableWithProductionOnSide", ConditionText);
	
	ConditionText           = "TRUE";
	TextOfAutoSelectionCondition = "TRUE";
	If (BOMSelectionParameters.AvailableTypes.Count() = 0
			Or BOMSelectionParameters.AvailableTypes.Find(Enums.ProductionProcessTypes.PerformRM) <> Undefined) Then
		
		ConditionText = "
		|CASE
		|	WHEN TTListOfProducts.UnderRepairProduct = VALUE(Catalog.Products.EmptyRef)
		|		THEN TRUE
		|	ELSE
		|		(TTListOfProducts.UnderRepairProduct.ProductKind = ProductsBOM.BillOfMaterials.ItemKindOfProductUnderRM
		|			OR ProductsBOM.BillOfMaterials.ItemKindOfProductUnderRM = VALUE(Catalog.ItemKinds.EmptyRef))
		|		AND (TTListOfProducts.UnderRepairProduct = ProductsBOM.BillOfMaterials.UnderRepairProduct
		|			OR ProductsBOM.BillOfMaterials.UnderRepairProduct = VALUE(Catalog.Products.EmptyRef))
		|		AND (ProductsBOM.BillOfMaterials.UnderRepairVariant = TTListOfProducts.UnderRepairVariant
		|			OR ProductsBOM.BillOfMaterials.UnderRepairVariant = VALUE(Catalog.ItemsCharacteristics.EmptyRef))
		|END
		|";
		
		TextOfAutoSelectionCondition = "
		|CASE
		|	WHEN TTListOfProducts.UnderRepairProduct = VALUE(Catalog.Products.EmptyRef)
		|		THEN ProductsBOM.BillOfMaterials.ItemKindOfProductUnderRM = VALUE(Catalog.ItemKinds.EmptyRef)
		|	ELSE
		|		TRUE
		|END
		|";
		
	EndIf;
	QueryText = StrReplace(QueryText, "&TextSelectionConditionRepairedFinishedProduct",     ConditionText);
	QueryText = StrReplace(QueryText, "&TextAutoSelectionConditionFinishedProductUnderRepair", TextOfAutoSelectionCondition);
	
	ConditionText = "TRUE";
	If ValueIsFilled(QueryOptions.ConditionsForSelectingIncomingData) Then
		ConditionText = StrConcat(QueryOptions.ConditionsForSelectingIncomingData, " And ");
	EndIf;
	QueryText = StrReplace(QueryText, "&TextConditionForSelectingIncomingData", ConditionText);
	
	QueryText = QueryText + "
	|SELECT
	|	AvailableSpecifications.TheIndexOfTheData                               AS TheIndexOfTheData,
	|	AvailableSpecifications.BillOfMaterials                               AS BillOfMaterials,
	|	AvailableSpecifications.AnyProducts                          AS AnyProducts,
	|	AvailableSpecifications.AnyCharacteristic                        AS AnyCharacteristic,
	|
	|	AvailableSpecifications.ProductionStart                         AS ProductionStart,
	|	AvailableSpecifications.ValidOnDate                             AS ValidOnDate,
	|	AvailableSpecifications.Code                                        AS Code,
	|	AvailableSpecifications.SelectedAutomatically                   AS SelectedAutomatically,
	|
	|	BOMAssignmentParameters.ParameterKind                     AS TypeOfDestinationParameter,
	|	&LinkKeyIsEmpty                                                 AS TypeOfApplicationSpecification,
	|
	|	BOMAssignmentParameters.Attribute                         AS Attribute,
	|	ISNULL(CASE
	|				WHEN ValuesOfBOMAssignmentParameters.NumberInList IN (0, 1)
	|					THEN BOMAssignmentParameters.Priority
	|				ELSE 0
	|			END, 0)                                                AS Priority,
	|
	|	ISNULL(ValuesOfBOMAssignmentParameters.Condition, """") AS Condition,
	|	ValuesOfBOMAssignmentParameters.Value                AS SettingValue,
	|
	|	CASE BOMAssignmentParameters.ParameterKind
	|		WHEN VALUE(Enum.TypesOfBOMAssignmentParameters.ProductionDispatcherBusinessUnit)
	|			THEN AvailableSpecifications.ProductionDispatcherBusinessUnit
	|		WHEN VALUE(Enum.TypesOfBOMAssignmentParameters.LineOfBusiness)
	|			THEN AvailableSpecifications.LineOfBusiness
	|		WHEN VALUE(Enum.TypesOfBOMAssignmentParameters.AdditionalAttributesOfBusinessUnit)
	|			THEN ISNULL(AdditionalAttributesOfBusinessUnit.Value,
	|								CASE
	|									WHEN VALUETYPE(ValuesOfBOMAssignmentParameters.Value) = TYPE(BOOLEAN)
	|											AND AvailableSpecifications.ProductionDispatcherBusinessUnit <> VALUE(Catalog.BusinessStructure.EmptyRef)
	|										THEN FALSE
	|									WHEN VALUETYPE(ValuesOfBOMAssignmentParameters.Value) = TYPE(NUMBER)
	|											AND AvailableSpecifications.ProductionDispatcherBusinessUnit <> VALUE(Catalog.BusinessStructure.EmptyRef)
	|										THEN 0
	|									ELSE UNDEFINED
	|								END)
	|		WHEN VALUE(Enum.TypesOfBOMAssignmentParameters.AdditionalAttributesOfLineOfBusiness)
	|			THEN ISNULL(AdditionalAttributesOfLineOfBusiness.Value,
	|								CASE
	|									WHEN VALUETYPE(ValuesOfBOMAssignmentParameters.Value) = TYPE(BOOLEAN)
	|											AND AvailableSpecifications.LineOfBusiness <> VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|										THEN FALSE
	|									WHEN VALUETYPE(ValuesOfBOMAssignmentParameters.Value) = TYPE(NUMBER)
	|											AND AvailableSpecifications.LineOfBusiness <> VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|										THEN 0
	|									ELSE UNDEFINED 
	|								END)
	|	END                                                            AS ParameterValue,
	|	""DestinationParameter""                                           AS SettingKind
	|
	|INTO TTAvailableSpecifications
	|FROM
	|	TTSourceOfAvailableSpecifications AS AvailableSpecifications
	|
	|		LEFT JOIN InformationRegister.BOMAssignmentParameters AS BOMAssignmentParameters
	|		ON (&UseBOMAssignmentParameters)
	|
	|		LEFT JOIN InformationRegister.ValuesOfBOMAssignmentParameters AS ValuesOfBOMAssignmentParameters
	|		ON AvailableSpecifications.BillOfMaterials               = ValuesOfBOMAssignmentParameters.BillOfMaterials
	|			AND (BOMAssignmentParameters.ParameterKind = ValuesOfBOMAssignmentParameters.ParameterKind)
	|			AND (BOMAssignmentParameters.Attribute     = ValuesOfBOMAssignmentParameters.Attribute)
	|			AND NOT ValuesOfBOMAssignmentParameters.ParameterKind IN (&IgnoredDestinationParameters)
	|			AND ValuesOfBOMAssignmentParameters.NumberInList BETWEEN 0 AND 2
	|
	|		LEFT JOIN Catalog.BusinessStructure.AdditionalAttributes AS AdditionalAttributesOfBusinessUnit
	|		ON AvailableSpecifications.ProductionDispatcherBusinessUnit = AdditionalAttributesOfBusinessUnit.Ref
	|			AND (BOMAssignmentParameters.ParameterKind = VALUE(Enum.TypesOfBOMAssignmentParameters.AdditionalAttributesOfBusinessUnit)
	|			AND (BOMAssignmentParameters.Attribute = AdditionalAttributesOfBusinessUnit.Property))
	|
	|		LEFT JOIN Catalog.LinesOfBusiness.AdditionalAttributes AS AdditionalAttributesOfLineOfBusiness
	|		ON AvailableSpecifications.LineOfBusiness = AdditionalAttributesOfLineOfBusiness.Ref
	|			AND (BOMAssignmentParameters.ParameterKind = VALUE(Enum.TypesOfBOMAssignmentParameters.AdditionalAttributesOfLineOfBusiness)
	|			AND (BOMAssignmentParameters.Attribute = AdditionalAttributesOfLineOfBusiness.Property))
	|
	|WHERE
	|	CASE
	|		WHEN ISNULL(ValuesOfBOMAssignmentParameters.Condition, """") IN (""InList"",""NotInList"")
	|			THEN ValuesOfBOMAssignmentParameters.NumberInList = 1
	|		ELSE TRUE
	|	END
	|
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	AvailableSpecifications.TheIndexOfTheData,
	|	AvailableSpecifications.BillOfMaterials,
	|	AvailableSpecifications.AnyProducts,
	|	AvailableSpecifications.AnyCharacteristic,
	|
	|	AvailableSpecifications.ProductionStart,
	|	AvailableSpecifications.ValidOnDate,
	|	AvailableSpecifications.Code,
	|	AvailableSpecifications.SelectedAutomatically,
	|
	|	VALUE(Enum.TypesOfBOMAssignmentParameters.EmptyRef),
	|	SelectionByProperties.ConnectionKey AS ConnectionKey,
	|
	|	SelectionByProperties.Property  AS Property,
	|	0,
	|
	|	SelectionByProperties.Condition,
	|	CASE
	|		WHEN SelectionByProperties.Condition IN (""InList"",""NotInList"")
	|			THEN 0
	|		ELSE SelectionByProperties.Value
	|	END,
	|
	|	ISNULL(
	|		CASE SelectionByProperties.ConnectionKey
	|			WHEN &CommunicationKeyProducts
	|				THEN AdditionalProductItemDetails.Value
	|			WHEN &CommunicationKeyCharacteristic
	|				THEN AdditionalPropsCharacteristics.Value
	|		END,
	|		CASE
	|			WHEN VALUETYPE(SelectionByProperties.Value) = TYPE(BOOLEAN)
	|				THEN FALSE
	|			WHEN VALUETYPE(SelectionByProperties.Value) = TYPE(NUMBER)
	|				THEN 0
	|			ELSE UNDEFINED
	|		END),
	|	""ClarificationOfApplication""
	|
	|FROM
	|	TTSourceOfAvailableSpecifications AS AvailableSpecifications
	|
	|		INNER JOIN Catalog.BillsOfMaterials.SelectionByProperties AS SelectionByProperties
	|		ON AvailableSpecifications.BillOfMaterials = SelectionByProperties.Ref
	|			AND SelectionByProperties.ConnectionKey IN (&CommunicationKeyProducts, &CommunicationKeyCharacteristic)
	|			AND NOT SelectionByProperties.ConnectionKey IN (&IgnoredApplicationRefinements)
	|
	|		LEFT JOIN Catalog.Products.AdditionalAttributes AS AdditionalProductItemDetails
	|		ON AvailableSpecifications.Products = AdditionalProductItemDetails.Ref
	|			AND SelectionByProperties.ConnectionKey = &CommunicationKeyProducts
	|			AND SelectionByProperties.Property = AdditionalProductItemDetails.Property
	|
	|		LEFT JOIN Catalog.ItemsCharacteristics.AdditionalAttributes AS AdditionalPropsCharacteristics
	|		ON AvailableSpecifications.Characteristic = AdditionalPropsCharacteristics.Ref
	|			AND SelectionByProperties.ConnectionKey = &CommunicationKeyCharacteristic
	|			AND SelectionByProperties.Property = AdditionalPropsCharacteristics.Property
	|
	|
	|;
	|
	|SELECT
	|	T.TheIndexOfTheData           AS TheIndexOfTheData,
	|	T.BillOfMaterials           AS BillOfMaterials,
	|	T.TypeOfDestinationParameter AS TypeOfDestinationParameter,
	|	T.TypeOfApplicationSpecification AS TypeOfApplicationSpecification,
	|	T.Attribute               AS Attribute
	|
	|INTO
	|	TTFoundInList
	|FROM
	|	TTAvailableSpecifications AS T
	|
	|WHERE
	|	T.Condition IN (""InList"",""NotInList"")
	|	AND TRUE IN (
	|		SELECT TOP 1
	|			TRUE
	|		FROM
	|			InformationRegister.ValuesOfBOMAssignmentParameters AS T1
	|		WHERE
	|			T.SettingKind = ""DestinationParameter""
	|			AND T.ParameterValue = T1.Value
	|			AND T.BillOfMaterials = T1.BillOfMaterials
	|			AND T.TypeOfDestinationParameter = T1.ParameterKind
	|			AND T.Attribute = T1.Attribute
	|
	|		UNION ALL
	|
	|		SELECT TOP 1
	|			TRUE
	|		FROM
	|			Catalog.BillsOfMaterials.SelectionByProperties AS T2
	|		WHERE
	|			T.SettingKind = ""ClarificationOfApplication""
	|			AND T.ParameterValue = T2.Value
	|			AND T.BillOfMaterials = T2.Ref
	|			AND T.TypeOfApplicationSpecification = T2.ConnectionKey
	|			AND T.Attribute = T2.Property
	|		)
	|
	|INDEX BY
	|	TheIndexOfTheData,
	|	BillOfMaterials,
	|	TypeOfDestinationParameter,
	|	TypeOfApplicationSpecification,
	|	Attribute
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1000000000
	|	RECORDAUTONUMBER() AS Priority,
	|	AvailableSpecifications.TheIndexOfTheData                AS TheIndexOfTheData,
	|	AvailableSpecifications.BillOfMaterials                AS BillOfMaterials,
	|	AvailableSpecifications.ValidOnDate              AS ValidOnDate,
	|	AvailableSpecifications.Code                         AS Code,
	|	AvailableSpecifications.SelectedAutomatically    AS SelectedAutomatically,
	|	SUM(CASE
	|			WHEN NOT AvailableSpecifications.Condition IN (""NotEqual"", ""NotInList"")
	|				THEN AvailableSpecifications.Priority
	|			ELSE 0
	|		END)                                        AS Priority1,
	|	NOT AvailableSpecifications.AnyProducts        AS Priority2,
	|	NOT AvailableSpecifications.AnyCharacteristic      AS Priority3,
	|	SUM(CASE
	|			WHEN AvailableSpecifications.Condition IN (""NotEqual"", ""NotInList"")
	|				THEN AvailableSpecifications.Priority
	|			ELSE 0
	|		END)                                        AS Priority4
	|INTO TTCorrespondToDestinationParameters
	|FROM
	|	(SELECT
	|		T.TheIndexOfTheData             AS TheIndexOfTheData,
	|		T.BillOfMaterials             AS BillOfMaterials,
	|		T.ValidOnDate           AS ValidOnDate,
	|		T.Code                      AS Code,
	|		T.SelectedAutomatically AS SelectedAutomatically,
	|		T.AnyProducts        AS AnyProducts,
	|		T.AnyCharacteristic      AS AnyCharacteristic,
	|		T.Priority                AS Priority,
	|		T.Condition                  AS Condition,
	|		CASE T.Condition
	|			WHEN ""Equal""
	|				THEN T.ParameterValue = T.SettingValue
	|			WHEN ""NotEqual""
	|				THEN T.ParameterValue <> T.SettingValue
	|			WHEN ""Greater""
	|				THEN T.ParameterValue > T.SettingValue
	|			WHEN ""GreaterOrEqual""
	|				THEN T.ParameterValue >= T.SettingValue
	|			WHEN ""Less""
	|				THEN T.ParameterValue < T.SettingValue
	|			WHEN ""LessOrEqual""
	|				THEN T.ParameterValue <= T.SettingValue
	|			WHEN ""InList""
	|				THEN NOT FoundInList.TheIndexOfTheData IS NULL
	|			WHEN ""NotInList""
	|				THEN FoundInList.TheIndexOfTheData IS NULL
	|			WHEN ""Filled""
	|				THEN NOT T.ParameterValue IN (
	|										UNDEFINED, FALSE, 0,
	|										VALUE(Catalog.BusinessStructure.EmptyRef),
	|										VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|												)
	|			WHEN ""NotFilled""
	|				THEN T.ParameterValue IN (
	|										UNDEFINED, FALSE, 0,
	|										VALUE(Catalog.BusinessStructure.EmptyRef),
	|										VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|												)
	|			ELSE TRUE
	|		END AS MatchesDestinationParameters
	|	FROM
	|		TTAvailableSpecifications AS T
	|	
	|			LEFT JOIN TTFoundInList AS FoundInList
	|			ON T.TheIndexOfTheData = FoundInList.TheIndexOfTheData
	|				AND T.BillOfMaterials = FoundInList.BillOfMaterials
	|				AND T.TypeOfDestinationParameter = FoundInList.TypeOfDestinationParameter
	|				AND T.TypeOfApplicationSpecification = FoundInList.TypeOfApplicationSpecification
	|				AND T.Attribute = FoundInList.Attribute
	|	) AS AvailableSpecifications
	|
	|GROUP BY
	|	AvailableSpecifications.TheIndexOfTheData,
	|	AvailableSpecifications.BillOfMaterials,
	|	AvailableSpecifications.ValidOnDate,
	|	AvailableSpecifications.Code,
	|	AvailableSpecifications.SelectedAutomatically,
	|	NOT AvailableSpecifications.AnyProducts,
	|	NOT AvailableSpecifications.AnyCharacteristic
	|
	|HAVING
	|	MIN(AvailableSpecifications.MatchesDestinationParameters) = TRUE
	|";
	
	// Sorting by priority
	If QueryOptions.OrderByPriority_ Or QueryOptions.PriorityOnly Then
		
		TextSortedByPriority = "
		|ORDER BY
		|	TheIndexOfTheData,
		|	Priority1 DESC,
		|	Priority2 DESC,
		|	Priority3 DESC,
		|	Priority4 DESC,
		|	ValidOnDate DESC,
		|	Code DESC
		|;
		|";
		
	Else
		
		QueryText = StrReplace(QueryText, "TOP 1000000000",                "");
		QueryText = StrReplace(QueryText, "RECORDAUTONUMBER() AS Priority,", "");
		
		TextSortedByPriority = "
		|;";
		
	EndIf;
	QueryText = QueryText + TextSortedByPriority;
	
	TextOfSelectionConditions = "";
	TextSortedByPriority = "";
	If QueryOptions.PriorityOnly Then
		
		TextOfSelectionConditions = "
		|WHERE
		|	(Specifications.TheIndexOfTheData, Specifications.Priority) IN
		|			(SELECT
		|				T.TheIndexOfTheData,
		|				MIN(T.Priority)
		|			FROM
		|				TTCorrespondToDestinationParameters AS T
		|			WHERE
		|				T.SelectedAutomatically = TRUE
		|			GROUP BY
		|				T.TheIndexOfTheData)
		|";
		
	ElsIf QueryOptions.OrderByPriority_ And IsBlankString(QueryOptions.OutputTableName) Then
		
		TextSortedByPriority = "
		|ORDER BY
		|	Specifications.TheIndexOfTheData,
		|	Specifications.Priority
		|";
		
	EndIf;
		
	QueryText = QueryText + "
	|SELECT
	|	Specifications.TheIndexOfTheData               AS TheIndexOfTheData,
	|	Specifications.BillOfMaterials               AS BillOfMaterials,
	|	Specifications.SelectedAutomatically   AS SelectedAutomatically,
	|	&SpecificationDetails,
	|	&ALLPOLA_REQUESITS,
	|	Specifications.BillOfMaterials.Presentation AS Presentation
	|
	|INTO OutputTableName
	|
	|FROM
	|	TTCorrespondToDestinationParameters AS Specifications
	|
	|	,VSEPOLYA_Connection
	|
	|";
	
	// Specification details
	If ValueIsFilled(BOMSelectionParameters.SpecificationDetails) Then
		QueryFields = New Array;
		For Each Attribute In StrSplit(BOMSelectionParameters.SpecificationDetails, ",", False) Do
			QueryFields.Add(StrTemplate("Specifications.BillOfMaterials.%1 AS %1,", TrimAll(Attribute)));
		EndDo;
		QueryText = StrReplace(QueryText, "&SpecificationDetails,", StrConcat(QueryFields,Chars.LF));
	Else
		QueryText = StrReplace(QueryText, "&SpecificationDetails,", "");
	EndIf;
	
	QueryText = QueryText + TextOfSelectionConditions;
	QueryText = QueryText + TextSortedByPriority;
	
	If QueryOptions.AllFieldsInResult Then
		
		TextConnectionAllFields = "
		|	LEFT JOIN TTSourceOfAvailableSpecifications AS T
		|	ON Specifications.TheIndexOfTheData = T.TheIndexOfTheData
		|		AND Specifications.BillOfMaterials = T.BillOfMaterials
		|";
		TextDetailsAllFields  = "
		|	T.*,
		|";
		IndexText_     = "";
		
	Else
		
		TextConnectionAllFields = "";
		TextDetailsAllFields  = "";
		IndexText_     = "
		|
		|INDEX BY
		|	TheIndexOfTheData";
		
	EndIf;
	
	QueryText = StrReplace(QueryText, "&ALLPOLA_REQUESITS,", TextDetailsAllFields);
	QueryText = StrReplace(QueryText, ",VSEPOLYA_Connection", TextConnectionAllFields);
	
	If Not IsBlankString(QueryOptions.OutputTableName) Then
		
		If QueryOptions.AddOutputTable Then
			
			QueryText = StrReplace(QueryText, "INTO OutputTableName", "ADD "+QueryOptions.OutputTableName);
			
		Else
			
			QueryText = StrReplace(QueryText, "INTO OutputTableName", "INTO "+QueryOptions.OutputTableName);
			QueryText = QueryText + IndexText_;
			
		EndIf;
		
	Else
		
		QueryText = StrReplace(QueryText, "INTO OutputTableName", "");
		
	EndIf;
	
	If QueryOptions.DestroyTemporaryTables Then
		
		For IndexOf = 0 To DestroyTables.UBound() Do
			DestroyTables[IndexOf] = StrTemplate("%1 DROP %2", Common.QueryBatchSeparator(), DestroyTables[IndexOf]);
		EndDo;
		QueryText = QueryText + StrConcat(DestroyTables);
		
	EndIf;
	
	If QueryOptions.FinalPackageSeparator Then
		QueryText = QueryText + Common.QueryBatchSeparator();
	EndIf;
	
	QueryText = StrReplace(QueryText, "&TextOfSpecificationField", TextOfSpecificationField);
	
	If Not IsBlankString(QueryOptions.NameOfInputTable) Then
		QueryText = StrReplace(QueryText, "TTListOfProducts", QueryOptions.NameOfInputTable);
	EndIf;
	
	If NameOfTemporarySpecificationSourceTable <> "TTSourceOfAvailableSpecifications" Then
		QueryText = StrReplace(QueryText, "TTSourceOfAvailableSpecifications", NameOfTemporarySpecificationSourceTable);
	EndIf;
	
	Return QueryText;
	
EndFunction

// Sets the parameters of the request generated by the function of the Product Specification Text query()
//
// Parameters:
//  Query          - Query    - Request to select specifications
//  ChoiceParameters - See ProductDataManagementClientServer.BOMSelectionParameters
//
Procedure SetParametersForRequestManufacturedProductSpecifications(Query, ChoiceParameters) Export
	
	ParametersList = New Structure;
	ParametersList.Insert("AvailableTypes",         New Array);
	ParametersList.Insert("AvailableStatuses",      New Array);
	ParametersList.Insert("ExcludeSpecification", Catalogs.BillsOfMaterials.EmptyRef());
	
	ListOfParametersWithoutSelection = New Structure;
	ListOfParametersWithoutSelection.Insert("AvailableTypes",         "AvailableTypesWithoutSelection");
	ListOfParametersWithoutSelection.Insert("AvailableStatuses",      "AvailableStatusesWithoutSelection");
	ListOfParametersWithoutSelection.Insert("ExcludeSpecification", "ExcludeSpecificationWithoutSelection");
	
	For Each KeyAndValue In ParametersList Do
		ParameterValue = KeyAndValue.Value;
		If ChoiceParameters.Property(KeyAndValue.Key) Then
			ParameterValue = ChoiceParameters[KeyAndValue.Key];
		EndIf;
		Query.SetParameter(KeyAndValue.Key, ParameterValue);
		Query.SetParameter(ListOfParametersWithoutSelection[KeyAndValue.Key], Not ValueIsFilled(ParameterValue));
	EndDo;
	
	SideOutputSpecificationsAreAvailable = False;
	If ChoiceParameters.Property("SideOutputSpecificationsAreAvailable") Then
		SideOutputSpecificationsAreAvailable = ChoiceParameters.SideOutputSpecificationsAreAvailable;
	EndIf;
	Query.SetParameter("SideOutputSpecificationsAreAvailable", SideOutputSpecificationsAreAvailable);
	
	IgnoredDestinationParameters = New Array;
	If ChoiceParameters.Property("IgnoredDestinationParameters")
		And ValueIsFilled(ChoiceParameters.IgnoredDestinationParameters) Then
		For Each AssignmentParameters In ChoiceParameters.IgnoredDestinationParameters Do
			CommonClientServer.SupplementArray(
				IgnoredDestinationParameters, TypeOfDestinationParameterInArray(AssignmentParameters));
		EndDo;
	EndIf;
	Query.SetParameter("IgnoredDestinationParameters", IgnoredDestinationParameters);
	
	IgnoredApplicationRefinements = New Array;
	If ChoiceParameters.Property("IgnoredApplicationRefinements")
		And ValueIsFilled(ChoiceParameters.IgnoredApplicationRefinements) Then
		IgnoredApplicationRefinements = ChoiceParameters.IgnoredApplicationRefinements;
	EndIf;
	Query.SetParameter("IgnoredApplicationRefinements", IgnoredApplicationRefinements);
	
	Query.SetParameter("UseBOMAssignmentParameters", GetFunctionalOption("UseBOMAssignmentParameters"));
	Query.SetParameter("CommunicationKeyProducts",   ProductDataManagementClientServer.SelectionByPropertiesOfCommunicationKey("Products"));
	Query.SetParameter("CommunicationKeyCharacteristic", ProductDataManagementClientServer.SelectionByPropertiesOfCommunicationKey("Characteristic"));
	Query.SetParameter("LinkKeyIsEmpty",         New UUID("00000000-0000-0000-0000-000000000000"));
	
	If ChoiceParameters.Property("SearchString") Then
		
		Query.SetParameter("SearchString", "%" + TrimAll(ChoiceParameters.SearchString) + "%");
		
	EndIf;
	
	Query.SetParameter("ProductionIsUsed21", GetFunctionalOption("UseProductionManagement"));
	
EndProcedure

Function TextOfSelectionConditionForPackagingWhenSelectingSpecifications(TextOfProductsField, TextOfProductSpecificationField, TextOfPackagingSpecificationField) Export
	
	TextSelectionConditionForPackaging = StrTemplate("
	|	AND CASE WHEN %2 = VALUE(Catalog.Products.EmptyRef)
	|			AND NOT (%1.UnitOfMeasure = %3) THEN
	|		CASE (%3.MeasuredValueType)
	|			WHEN VALUE(Enum.TypesOfMeasuredValues.Package)
	|				THEN (%3.Owner IN (%1, %1.PackagingGroup))
	|			WHEN VALUE(Enum.TypesOfMeasuredValues.Weight)
	|				THEN (%1.WeightUse AND %1.YouCanSpecifyWeightInDocuments)
	|			WHEN VALUE(Enum.TypesOfMeasuredValues.VolumeM3)
	|				THEN (%1.VolumeUse AND %1.VolumeCanBeSpecifiedInDocuments)
	|			WHEN VALUE(Enum.TypesOfMeasuredValues.Length)
	|				THEN (%1.LengthUse AND %1.YouCanSpecifyLengthInDocuments)
	|			WHEN VALUE(Enum.TypesOfMeasuredValues.AreaTypeOfMeasurement)
	|				THEN (%1.AreaUse AND %1.AreaCanBeSpecifiedInDocuments)
	|			ELSE
	|				FALSE
	|		END
	|	ELSE
	|		TRUE
	|	END
	|", TextOfProductsField, TextOfProductSpecificationField, TextOfPackagingSpecificationField);
	
	Return TextSelectionConditionForPackaging;
	
EndFunction

// Set parameters for selecting specifications in the form
//
// Parameters:
//  Item						 - FormField, Array of FormField - specification entry field or list of fields
//  BOMSelectionParameters	 - See BOMSelectionParameters
//
Procedure SetSpecificationSelectionParameters(Item, BOMSelectionParameters) Export
	
	ChoiceParameters = ProductDataManagementClientServer.BillOfMaterialsItemSelectionParameters(BOMSelectionParameters);
	
	If TypeOf(Item) = Type("Array") Then
		ItemArray = Item;
	Else
		ItemArray = CommonClientServer.ValueInArray(Item);
	EndIf;
	
	WaysToLinkElementSelectionParameters = BOMSelectionParameters.ChoiceParameterLinks;
	For Each CurrentItem In ItemArray Do // FormField
		
		CurrentItem.ChoiceParameters = New FixedArray(ChoiceParameters);
		CurrentItem.ChoiceForm     = "Catalog.BillsOfMaterials.Form.ChoiceFormByItems";
		
		PathsForItemSelectionParameters = WaysToLinkElementSelectionParameters.Get(CurrentItem.DataPath);
		If PathsForItemSelectionParameters = Undefined Then
			Continue;
		EndIf;
		
		FormTable    = Undefined;
		CurrentParent = CurrentItem.Parent;
		While TypeOf(CurrentParent) <> Type("ClientApplicationForm") Do
			If TypeOf(CurrentParent) = Type("FormTable") Then
				FormTable = CurrentParent;
				Break;
			EndIf;
			CurrentParent = CurrentParent.Parent;
		EndDo;
		
		If FormTable = Undefined And StrFind(CurrentItem.DataPath, ".CurrentData.") > 0 Then
			PathParts = StrSplit(CurrentItem.DataPath,".");
			If PathParts.Count() = 4 Then
				FormTable = CurrentParent["Items"].Find(PathParts[1]);
			EndIf;
		EndIf;
		
		ChoiceParameterLinks = New Array();
		For Each KeyAndValue In PathsForItemSelectionParameters Do
			
			If Not ValueIsFilled(KeyAndValue.Value) Then
				Continue;
			EndIf;
			
			If TypeOf(KeyAndValue.Value) = Type("Structure") Then
				DataPath    = KeyAndValue.Value.DataPath;
				ChangeMode = KeyAndValue.Value.ChangeMode;
			Else
				DataPath    = KeyAndValue.Value;
				ChangeMode = LinkedValueChangeMode.DontChange;
			EndIf;
			
			If FormTable <> Undefined And StrFind(DataPath, FormTable.DataPath+".") > 0 Then
				DataPath = StrTemplate("Items.%1.CurrentData.%2",
					FormTable.Name,
					Mid(DataPath,StrFind(DataPath,".", SearchDirection.FromEnd)+1));
			EndIf;
				
			ChoiceParameterLinks.Add(New ChoiceParameterLink(KeyAndValue.Key, DataPath, ChangeMode));
			If KeyAndValue.Key = "Products"
					Or KeyAndValue.Key = "Characteristic" Then
				ChoiceParameterLinks.Add(New ChoiceParameterLink("Filter."+KeyAndValue.Key, DataPath, ChangeMode));
			EndIf;
			
		EndDo;
		
		CurrentItem.ChoiceParameterLinks = New FixedArray(ChoiceParameterLinks);
		
	EndDo;
	
EndProcedure

#EndRegion

#Region ProductionStages

// Checks whether the details correspond to the selected Department
//  If they don't match, the values are cleared.
//
// Parameters:
//  Object - FormDataStructure	- An object containing stage data.
//  AttributesList - String		 - The list of details to check.
//
Procedure CheckComplianceOfDetailsWithDivision(Object, AttributesList = "") Export

	If Object.Department.IsEmpty() Then
		Return;
	EndIf;
	AllAttributes = IsBlankString(AttributesList);
	AttributesList = New Structure(AttributesList);
	
	If AttributesList.Property("WorkCenterTypes") Or AllAttributes Then
		
		Query = New Query(
			"SELECT
			|	WorkCenterTypes.Ref
			|FROM
			|	Catalog.WorkCenterTypes AS WorkCenterTypes
			|WHERE
			|	(WorkCenterTypes.Ref IN (&WorkCenterType)
			|		OR WorkCenterTypes.Ref IN (&AlternateWorkCenterTypes))
			|	AND WorkCenterTypes.Department <> &Department");
		
		Query.SetParameter("Department",     Object.Department);
		Query.SetParameter("WorkCenterType", Object.WorkCenterTypes.Unload().UnloadColumn("WorkCenterType"));
		Query.SetParameter("AlternateWorkCenterTypes", Object.AlternateWorkCenterTypes.Unload().UnloadColumn("WorkCenterType"));
		
		Result = Query.Execute();
		Selection = Result.Select();
		
		TheStructureOfTheSearch = New Structure("WorkCenterType", Selection.Ref);
		While Selection.Next() Do
			TheStructureOfTheSearch.WorkCenterType = Selection.Ref;
			StringsList = Object.WorkCenterTypes.FindRows(TheStructureOfTheSearch);
			For Each RowViewRC In StringsList Do
				RowViewRC.WorkCenterType = Catalogs.WorkCenterTypes.EmptyRef();
				RowViewRC.Use = True;
			EndDo;
			
			TheStructureOfTheSearch.WorkCenterType = Selection.Ref;
			StringsList = Object.AlternateWorkCenterTypes.FindRows(TheStructureOfTheSearch);
			For Each RowViewRC In StringsList Do
				Object.AlternateWorkCenterTypes.Delete(RowViewRC);
			EndDo;
		EndDo;
		
	EndIf;
	
	If AttributesList.Property("RouteSheet") Or AllAttributes Then
		
		If Not Object.RouteSheet.IsEmpty() Then
			Department = Common.ObjectAttributeValue(Object.RouteSheet, "Department");
			If Object.Department <> Department Then
				Object.RouteSheet = Catalogs.RouteSheets.EmptyRef();
			EndIf; 
		EndIf;
	
	EndIf;
EndProcedure

// Fills in the planned duration and unit of measurement for the duration of the BBB stage.
//
// Parameters:
//  Object - DocumentObject.ProductionStage2_2, CatalogObject.ProductionStages, Structure - an object containing the stage details.
//  WorkCenterTypes - ValueTable, Array - a table with data for the types of stage work centers, or an array of rows.
//	FormulasAreCalculated - Boolean - True if the PM types of work centers are calculated using the formulas.
//
Procedure FillInUnitOfMeasurementAndDurationOfBBVStage(Object, WorkCenterTypes, FormulasAreCalculated) Export
	
	UnitOfMeasureOfStageDuration = Enums.TimeMeasureUnits.Day;
	
	DivisionParameters = ProductionServer.ProductionBusinessUnitDescription(Object.Department);
	PlanningInterval = DivisionParameters.PlanningInterval;
	
	If PlanningInterval = Enums.ProductionScheduleAccuracy.Hour
		Or ValueIsFilled(Object.PreliminaryBuffer) 
			And Object.UnitOfMeasureOfPreliminaryBuffer = Enums.TimeMeasureUnits.Hour
		Or ValueIsFilled(Object.FollowUpBuffer) 
			And Object.UnitOfMeasureOfFollowUpBuffer = Enums.TimeMeasureUnits.Hour Then
		
		UnitOfMeasureOfStageDuration =  Enums.TimeMeasureUnits.Hour;
		
	EndIf;
	
	StageDuration = 0;
	
	If WorkCenterTypes.Count() > 0 Then
		
		NormativeDuration = ProductionPlanningClientServer.GetNormativeIntervalDuration(
			PlanningInterval, 
			UnitOfMeasureOfStageDuration);
		
		StandardDurationInSeconds = ProductionPlanningClientServer.GetNormativeIntervalDuration(
			PlanningInterval) * 86400;
		
		References = New Array;
		For Each String In WorkCenterTypes Do
			References.Add(String.WorkCenterType);
		EndDo;
		MaximumAvailability = Catalogs.WorkCenterTypes.MaximumAvailabilityInSeconds(References);
		
		ThisIsFirstLine = True;
		
		For Each String In WorkCenterTypes Do
			
			If Not ValueIsFilled(String.WorkCenterType) Then
				Continue;
			EndIf;
			
			If FormulasAreCalculated Or IsBlankString(String.QuantityCalculationAlgorithm) Then
				RunningTimeInSeconds = ProductionPlanningClientServer.GetTimeInSeconds(
					String.OperationTime,
					String.UnitOfMeasure);
				MaxAvailabilityInSeconds = MaximumAvailability.Get(String.WorkCenterType);
				NumberOfIntervals_ = Round(RunningTimeInSeconds/MaxAvailabilityInSeconds+0.5,0,RoundMode.Round15as10);
			Else
				NumberOfIntervals_ = 1;
			EndIf;
			
			If Object.OperatingProcedureOfWorkCenterTypes = Enums.OperatingProcedureOfWorkCenterTypes.Sequentially Then
				
				If Not ThisIsFirstLine Then
					NumberOfIntervals_ = NumberOfIntervals_ - 1;
				EndIf;
				
				StageDuration = StageDuration + (NumberOfIntervals_ * NormativeDuration);
				
			Else
				
				StageDuration = Max(StageDuration, (NumberOfIntervals_ * NormativeDuration));
				
			EndIf;
			
			ThisIsFirstLine = False;
			
		EndDo;
		
	EndIf;
	
	If ValueIsFilled(Object.PreliminaryBuffer) Then
		
		If Object.UnitOfMeasureOfPreliminaryBuffer = UnitOfMeasureOfStageDuration Then
			
			StageDuration = StageDuration + Object.PreliminaryBuffer;
			
		Else
			
			StageDuration = StageDuration + ProductionPlanningClientServer.GetTimeInUnit(
																		ProductionPlanningClientServer.GetTimeInSeconds(
																					Object.PreliminaryBuffer, 
																					Object.UnitOfMeasureOfPreliminaryBuffer), 
																		UnitOfMeasureOfStageDuration);
		
		EndIf;
		
	EndIf;
	
	If ValueIsFilled(Object.FollowUpBuffer) Then
	
		If Object.UnitOfMeasureOfFollowUpBuffer = UnitOfMeasureOfStageDuration Then
			
			StageDuration = StageDuration + Object.FollowUpBuffer;
			
		Else
			
			StageDuration = StageDuration + ProductionPlanningClientServer.GetTimeInUnit(
																		ProductionPlanningClientServer.GetTimeInSeconds(
																					Object.FollowUpBuffer, 
																					Object.UnitOfMeasureOfFollowUpBuffer), 
																		UnitOfMeasureOfStageDuration);
		
		EndIf;
		
	EndIf;
	
	Object.UnitOfMeasureOfStageDuration = UnitOfMeasureOfStageDuration;
	Object.StageDuration                 = StageDuration;
	
EndProcedure

#EndRegion

#Region DescriptionManufacturingProcess

// Checks whether the release batch can be described according to the specification
// 
// Returns:
//  Boolean - True if the description of the release batch according to the specification is available
//
Function ReleaseBatchDescriptionIsAvailable() Export
	
	Return Not GetFunctionalOption("UseProductionManagement");
	
EndFunction

// Checks whether it is possible to describe the type of production process (Assembly, disassembly, repair).
// 
// Returns:
//  Boolean - True if the type of production process is available.
//
Function DescriptionOfManufacturingProcessTypeIsAvailable() Export
	
	Result = False;
	Result = GetFunctionalOption("UseProductionManagement2_2")
		And Not GetFunctionalOption("UseProductionManagement");
	Return Result;
	
EndFunction

// Checks whether it is possible to describe the probability of using materials.
// 
// Returns:
//  Boolean - True if the type of production process is available.
//
Function AvailableDescriptionOfProbabilityOfApplicationOfMaterials() Export
	
	Result = False;
	Result = GetFunctionalOption("UseProductionManagement2_2")
		And Not GetFunctionalOption("UseProductionManagement");
	Return Result;
	
EndFunction

// Production process parameters are available.
// 
// Parameters:
//  Object - CatalogObject.BillsOfMaterials
// 
// Returns:
//  Boolean
Function AvailableProductionProcessParameters(Object) Export
	
	Result = False;
	Result = Not (ThisIsTechnologicalSet(Object)
		Or Object.ProductionProcessType = Enums.ProductionProcessTypes.PerformRM
		Or Object.ProductionProcessType = Enums.ProductionProcessTypes.Disassembly);
	Return Result;
	
EndFunction

#EndRegion

#Region BOMsTree

// Builds a specification tree for the product.
//
// Parameters:
//  Form		 - ClientApplicationForm	 - managed form where the specification tree is located
//  Parameters	 - See ProductDataManagementClientServer.SpecificationTreeParameters
//
Procedure BuildSpecificationTree(Form, Parameters) Export
	
	Tree = Form.FormAttributeToValue("BOMsTree");
	
	FillInSpecificationTree(Parameters, Tree);
	
	AddressInStorage = "";
	
	If Parameters.DynamicReading Then
		
		Parameters.SaveData_ = True;
		
		AddressInStorage = CacheStructureOfSpecificationTree(
			Parameters, 
			Tree, 
			Form.UUID);
		
	EndIf;
	
	Form.BORTreeAddressInTheStorage = AddressInStorage;
	
	If Parameters.DynamicReading Then
		
		FilterParameters = New Structure("ThereIsBOM", True);
		
		FoundRows = Tree.Rows.FindRows(FilterParameters, True);
		For Each String In FoundRows Do
			If String.Rows.Count() > 0 Then
				Continue;
			EndIf;
			String.Rows.Add();
		EndDo;
		
	EndIf;
	
	Form.ValueToFormAttribute(Tree, "BOMsTree");
	
EndProcedure

// Returns the specification tree, and preloads all nodes of the tree during dynamic reading.
//
// Parameters:
//  Form		 - ClientApplicationForm	 - the managed form on which the specification tree is located.
// 
// Returns:
//  ValueTree - See StructureOfSpecificationTree
Function ReadSpecTree(Form) Export
	
	If Form.DynamicReading Then
		
		TreeStructure = GetFromTempStorage(Form.BORTreeAddressInTheStorage); // See StructureOfSpecificationTree
		
		If TreeStructure = Undefined Then
			Raise NStr("vi = 'Lỗi đọc giá trị lưu trữ!';
						|ru = 'Ошибка чтения кешированных значений!';
						|en = 'An error occurred when reading cache values.'; fa = 'An error occurred when reading cache values.';
						|it = 'Errore nella lettura dei valori salvati nella cache!';
						|pl = 'Błąd podczas odczytywania buforowanych wartości!';
						|tr = 'Önbelleğe alınan değerlerin okunma hatası!'");
		EndIf;
		
		Parameters = TreeStructure.Parameters;
		Tree    = TreeStructure.Tree;
		
		Parameters.DynamicReading = False;
		
		If Parameters.SaveData_ Then
			
			FilterParameters = New Structure("ThereIsBOM,BOMIsRead", True, False);
			FoundRows = Tree.Rows.FindRows(FilterParameters, True);
			
			FillInTreeRowSpecificationData(Parameters, FoundRows);
			For Each TreeRow In FoundRows Do
				
				FillTreeRows(Parameters, Tree, TreeRow);
				
			EndDo;
			
		Else
			
			FillInSpecificationTree(Parameters, Tree);
			
		EndIf;
		
		Parameters.DynamicReading = True;
		
		If Parameters.SaveData_ Then
			
			Form.BORTreeAddressInTheStorage = CacheStructureOfSpecificationTree(
				Parameters, 
				Tree, 
				Form.UUID);
				
		EndIf;
		
	Else
		
		Tree = Form.FormAttributeToValue("BOMsTree");
		
	EndIf;
	
	Return Tree;
	
EndFunction

// Gets the child line items of the tree spec
//
// Parameters:
//  CurrentRow		 - ValueTreeRow - data of the current row
//  AddressInStorage		 - String	 - address of the specification tree in temporary storage
//  UpdateRowData - Boolean	 - flag that forcibly updates data in the cache.
// 
// Returns:
//   - Array - subordinate elements of the specification tree line.
//
Function TreeSpecificationsReadElements(CurrentRow, AddressInStorage, UpdateRowData = False) Export

	ItemsCollection = New Array;
	
	BeginTime = CurrentUniversalDateInMilliseconds();
	
	TreeStructure = GetFromTempStorage(AddressInStorage); // See StructureOfSpecificationTree
	
	CacheIsInefficient = (CurrentUniversalDateInMilliseconds() - BeginTime) > 200;
	
	If TreeStructure <> Undefined Then
		
		Parameters = TreeStructure.Parameters;
		Tree    = TreeStructure.Tree;
		
		TreeChanged = False;
		
		If Parameters.SaveData_ Then
			
			TreeRow = Tree.Rows.Find(CurrentRow.Id, "Id", True); 
			
			If TreeRow <> Undefined
				And UpdateRowData Then
				
				FillPropertyValues(
					TreeRow,
					CurrentRow,
					"Products,Characteristic,Count,Package,NumberOfPackages,ThereIsBOM,BillOfMaterials");
				TreeRow.BOMIsRead = False;
				
			EndIf;
			
		Else
			
			TreeRow = Tree.Rows.Add();
			
			FillPropertyValues(
				TreeRow,
				CurrentRow,
				,
				"BOMIsRead");
			
		EndIf;
		
		If TreeRow <> Undefined Then
			
			If Not TreeRow.BOMIsRead Then
			
				FillTreeRows(Parameters, Tree, TreeRow);
				
				CurrentRow.ProductionProcessType = TreeRow.ProductionProcessType;
				TreeChanged = Parameters.SaveData_;
				
			EndIf;
		
			TreeStringIsConvertedToArrayOfStructures(TreeRow, ItemsCollection);
			
		EndIf;
		
		If Parameters.SaveData_ 
			And CacheIsInefficient Then 
			
			Tree.Rows.Clear();
			TreeChanged = True;
			
			Parameters.SaveData_ = False;
			
		EndIf;
		
		If TreeChanged Then
			
			CacheStructureOfSpecificationTree(Parameters, Tree, AddressInStorage);
			
		EndIf;
		
	EndIf;
	
	Return ItemsCollection;
	
EndFunction

// Changes a specification in a row in the specification tree
//
// Parameters:
//  Form - ClientApplicationForm  - managed form where the specification tree is located
//  Parameters - See ProductDataManagementClientServer.SpecificationTreeParameters
//  CurrentData - See ProductDataManagementClientServer.TreeStringWithStructure
//
Procedure ChangeSpecificationInTreeLine(Form, Parameters, CurrentData) Export

	If Parameters.DynamicReading Then
		
		AddressInStorage = Form.BORTreeAddressInTheStorage;
		UpdateRowData = True;
		
		ItemsCollection = TreeSpecificationsReadElements(CurrentData, AddressInStorage, UpdateRowData);
		
		ProductDataManagementClientServer.TreeSpecificationsOutputElements(CurrentData, ItemsCollection);
		
	Else
		
		Tree = Form.FormAttributeToValue("BOMsTree");
		
		TreeRow = Tree.Rows.Find(CurrentData.Id, "Id", True);
		
		FillTreeRows(Parameters, Tree, TreeRow);
		
		Form.ValueToFormAttribute(Tree, "BOMsTree");
		
	EndIf;
	
EndProcedure

// Updates the details of the tree row
//
// Parameters:
//  Form - ClientApplicationForm  - managed form where the specification tree is located
//  CurrentData - See ProductDataManagementClientServer.TreeStringWithStructure
//
Procedure UpdateTreeRowDetailsInRepository(Form, CurrentData) Export
	
	AddressInStorage = Form.BORTreeAddressInTheStorage;
	
	TreeStructure = GetFromTempStorage(AddressInStorage); // See StructureOfSpecificationTree
	
	If TreeStructure <> Undefined Then
		
		Parameters = TreeStructure.Parameters;
		Tree    = TreeStructure.Tree;
		
		TreeRow = Tree.Rows.Find(CurrentData.Id, "Id", True); 
		
		If TreeRow <> Undefined Then
			
			FillPropertyValues(
				TreeRow,
				CurrentData,
				"Products,Characteristic,Count,Package,NumberOfPackages,ThereIsBOM,BillOfMaterials");
			TreeRow.BOMIsRead = False;
			
			CacheStructureOfSpecificationTree(Parameters, Tree, AddressInStorage);
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Procedure for recursively adding rows to the specification tree.
//
// Parameters:
//  Parameters					 - Structure - parameter structure
//  Tree						 - ValueTree	 - value tree to fill in
//  TreeRow				 - ValueTreeRow	 - string to add rows to
//  UsedSpecifications	 - Array				 - array of used specifications
//  ConnectionKey					 - UUID	 - the link key.
//
Procedure FillTreeRows(Parameters, Tree, TreeRow, UsedSpecifications = Undefined, ConnectionKey = Undefined) Export
	
	If TreeRow <> Undefined Then
		
		TreeRow.Rows.Clear();
		
		If Not ValueIsFilled(TreeRow.BillOfMaterials) Then
			Return;
		EndIf;
		
		ParentProduct_ = TreeRow.Products;
		CharacteristicsOfParent = TreeRow.Characteristic;
		ParentSpecification_ = TreeRow.BillOfMaterials;
		
		If TreeRow.Count = 0 Then
			
			MainProductData = Catalogs.BillsOfMaterials.MainProductSpecificationData(
				ParentSpecification_,
				ParentProduct_,
				CharacteristicsOfParent);
			
			If MainProductData.Products.IsEmpty() Then
				Return;
			EndIf;
			
			FillPropertyValues(TreeRow, MainProductData, "Count,NumberOfPackages,Package");
			
		EndIf;
		
		ParentCount = TreeRow.Count;
		
		ThereIsBOM = TreeRow.ThereIsBOM;
		
	Else
		
		MainProductData = Catalogs.BillsOfMaterials.MainProductSpecificationData(Parameters.BillOfMaterials);
		
		ParentProduct_   = MainProductData.Products;
		CharacteristicsOfParent = MainProductData.Characteristic;
		ParentCount     = MainProductData.Count;
		
		ParentSpecification_ = Parameters.BillOfMaterials;
		ThereIsBOM = True;
		
	EndIf;
	
	ParentRow = TreeRow;
	
	ReceivingOutputProducts = Parameters.OutputOutputProducts
		Or (Common.ObjectAttributeValue(ParentSpecification_, "ProductionProcessType") = Enums.ProductionProcessTypes.Disassembly);
	
	ListOfData = ListOfTreeSpecificationData(
		Parameters.DisplayStages,
		Parameters.DeduceLaborCosts);
	
	SelectionParameters = Catalogs.BillsOfMaterials.DataSamplingParameters(ListOfData);
	SelectionParameters.OverridingReleasePartySetting = New Structure("Use,ProductionIssueByCustomPortions",True,True);
	SelectionParameters.GetPresentations                 = True;
	SelectionParameters.ConsiderProbabilityOfDefectiveGoods             = False;
	SelectionParameters.RoundUpNumberOfUnitItems_     = False;
	SelectionParameters.GetDataSets                 = False;
	SelectionParameters.SoftwareFillingOption          = ?(Parameters.DisplayBalanceOfGoods,
																	Enums.ProductionSupplyFillingVariants.BySupplySchemes,
																	Enums.ProductionSupplyFillingVariants.DontFill);
	SelectionParameters.MethodOfCalculationOfMaterials               = Enums.MaterialCalculationMethods.MaximumConsumption;
	SelectionParameters.CombineMaterialsAndWorksPerformed = True;
	
	// A list to check for looping.
	If Not Parameters.DynamicReading And UsedSpecifications = Undefined Then
		UsedSpecifications = New Array();
	EndIf;
	
	// Resource specification or production order specification
	If Not IsTempStorageURL(Parameters.AddressInStorage) Then
		
		If TreeRow = Undefined Or TreeRow.StructureOfData = Undefined Then
		
			ItemData_3 = Catalogs.BillsOfMaterials.ProductData_5();
			ItemData_3.Products            = ParentProduct_;
			ItemData_3.Characteristic          = CharacteristicsOfParent;
			ItemData_3.BillOfMaterials            = ParentSpecification_;
			ItemData_3.Count              = ParentCount;
			ItemData_3.ProductionStart      = Parameters.Date;
			ItemData_3.ProductionDispatcherBusinessUnit  = Parameters.ProductionDispatcherBusinessUnit;
			ItemData_3.LineOfBusiness = Parameters.LineOfBusiness;
			AddDataAboutWoodProduct(ItemData_3, TreeRow);
			
			StructureOfData = Catalogs.BillsOfMaterials.SpecificationDataByProducts(ItemData_3, SelectionParameters);
			
		Else
			
			StructureOfData = TreeRow.StructureOfData;
			
		EndIf;
		
		Catalogs.BillsOfMaterials.MarkInterimRelease(StructureOfData, True);
		
		Mode = ProductDataManagementClientServer.SpecificationTreeMode();
		
	Else
		
		StructureOfData = GetOrderSpecificationData(Parameters.AddressInStorage, ConnectionKey);
		Mode = ProductDataManagementClientServer.OrderSpecificationTreeMode();
		
	EndIf;
	
	DisplayStages                = Parameters.DisplayStages And StructureOfData.Stages.Count() > 0;
	OutputOfOperations             = DisplayStages And Parameters.OutputOfOperations And GetFunctionalOption("StoreOperationsInBillsOfMaterials");
	DisplayGroupingTitles = Parameters.DisplayGroupingTitles;
	
	// Preparing data for string output
	If Not DisplayStages Then
		
		// MaterialsAndServices
		MaterialsAndServices = TMCommonUse.CollapsedCopyOfTable(
			StructureOfData.MaterialsAndServices,
			"Products,
			|ItemsType,
			|Characteristic,
			|ItemVariantsAreUsed,
			|UnitOfMeasure,
			|Package,
			|ProducedInProcess,
			|MethodOfReceivingMaterial,SourceOfSemiFinishedProduct,BillOfMaterialsRM,
			|LineKind"
			+ ?(Parameters.DisplayBalanceOfGoods, ",Warehouse",""),
			"MethodOfProductsAutoselection,
			|MethodOfItemVariantAutoselection,
			|ApplyingTheMaterialEditing,
			|UnderRepairProduct,
			|UnderRepairVariant,
			|ConnectionKey",
			"Count,NumberOfPackages");
		MaterialsAndServices.Columns.Add("NestedSpecification");
		
		If ReceivingOutputProducts Then
		
			// ManufacturedProducts
			ManufacturedProducts = TMCommonUse.CollapsedCopyOfTable(
				StructureOfData.ManufacturedProducts,
				"Products,
				|ItemsType,
				|Characteristic, ItemVariantsAreUsed,
				|UnitOfMeasure,
				|Package,
				|ProcessByBOM, BillOfMaterials,
				|LineKind",,
				"Count,NumberOfPackages");
			ManufacturedProducts.Columns.Add("NestedSpecification");
			
			// RecyclableWaste
			RecyclableWaste = TMCommonUse.CollapsedCopyOfTable(
				StructureOfData.RecyclableWaste,
				"Products,
				|ItemsType,
				|Characteristic, ItemVariantsAreUsed,
				|UnitOfMeasure,
				|Package,
				|ProcessByBOM, BillOfMaterials,
				|LineKind",,
				"Count,NumberOfPackages");
			RecyclableWaste.Columns.Add("NestedSpecification");
		
		EndIf;
		
		// LaborCosts
		If Parameters.DeduceLaborCosts Then
			LaborCosts = TMCommonUse.CollapsedCopyOfTable(StructureOfData.LaborCosts, "WorkKind, UnitOfMeasure",, "Count");
		EndIf;
		
	Else
		
		// MaterialsAndServices
		MaterialsAndServices = StructureOfData.MaterialsAndServices;
		MaterialsAndServices.Columns.Add("NestedSpecification");
		
		If ReceivingOutputProducts Then
		
			// ManufacturedProducts
			ManufacturedProducts = StructureOfData.ManufacturedProducts;
			ManufacturedProducts.Columns.Add("NestedSpecification");
			
			// RecyclableWaste
			RecyclableWaste = StructureOfData.RecyclableWaste;
			RecyclableWaste.Columns.Add("NestedSpecification");
		
		EndIf;
		
		// LaborCosts
		If Parameters.DeduceLaborCosts Then
			LaborCosts = StructureOfData.LaborCosts;
		EndIf;
		
	EndIf;
	
	EmptyStageLink = Catalogs.ProductionStages.EmptyRef();
	RowsSet = New Structure;
	RowsSet.Insert("ManufacturedProducts", New Map);
	RowsSet.Insert("MaterialsAndServices", New Map);
	RowsSet.Insert("LaborCosts", New Map);
	RowsSet.Insert("Operations", New Map);
	If DisplayStages Then
		For Each String In StructureOfData.Stages Do
			RowsSet["ManufacturedProducts"].Insert(String.Stage, New Array);
			RowsSet["MaterialsAndServices"].Insert(String.Stage, New Array);
			RowsSet["LaborCosts"].Insert(String.Stage, New Array);
			RowsSet["Operations"].Insert(String.Stage, New Array);
		EndDo;
	EndIf;
	RowsSet["ManufacturedProducts"].Insert(EmptyStageLink, New Array);
	RowsSet["MaterialsAndServices"].Insert(EmptyStageLink, New Array);
	RowsSet["LaborCosts"].Insert(EmptyStageLink, New Array);
	RowsSet["Operations"].Insert(EmptyStageLink, New Array);
	
	If ReceivingOutputProducts Then
		For Each String In ManufacturedProducts Do
			CurrentStep = ?(DisplayStages, String.Stage, EmptyStageLink);
			If String.ProcessByBOM Then
				String.NestedSpecification = String.BillOfMaterials;
			EndIf;
			ThereIsNestedSpecificationInLine = ValueIsFilled(String.NestedSpecification);
			If Parameters.OutputOutputProducts Or ThereIsNestedSpecificationInLine Then
				If (String.Products = ParentProduct_ And String.Characteristic = CharacteristicsOfParent)
					Or StructureOfData.AssignmentOption = Enums.BillOfMaterialsAssignmentOptions.ProductKind Then
					Continue;
				EndIf;
				RowsArray = RowsSet["ManufacturedProducts"][CurrentStep]; // Array
				RowsArray.Add(String);
			EndIf;
		EndDo;
		For Each String In RecyclableWaste Do
			CurrentStep = ?(DisplayStages, String.Stage, EmptyStageLink);
			If String.ProcessByBOM Then
				String.NestedSpecification = String.BillOfMaterials;
			EndIf;
			ThereIsNestedSpecificationInLine = ValueIsFilled(String.NestedSpecification);
			If Parameters.OutputOutputProducts Or ThereIsNestedSpecificationInLine Then
				RowsArray = RowsSet["ManufacturedProducts"][CurrentStep]; // Array
				RowsArray.Add(String);
			EndIf;
		EndDo;
	EndIf;
	If MaterialsAndServices.Count() > 0 Then
		
		RowsArray = New Array;
		DataArray = New Array;
		For Each String In MaterialsAndServices Do
			
			If String.ProducedInProcess Then
				If String.MethodOfReceivingMaterial = Enums.MethodsOfReceivingBOMMaterials.ProduceByBillsOfMaterials Then
					String.NestedSpecification = String.SourceOfSemiFinishedProduct;
				ElsIf String.MethodOfReceivingMaterial = Enums.MethodsOfReceivingBOMMaterials.ProducedOnStage Then
					String.NestedSpecification = String.BillOfMaterialsRM;
					Continue;
				EndIf;
			EndIf;
			
			If String.ItemsType = Enums.ItemsTypes.Set Then
				If ProductDataManagementCached.ItIsAvailableToStoreCompositionOfSetInSpecifications() Then
					String.NestedSpecification = String.SourceOfSemiFinishedProduct;
				Else
					Continue;
				EndIf;
			EndIf;
			
			If StructureOfData.ProductionProcessType = Enums.ProductionProcessTypes.PerformRM
				And Not String.ItemsType = Enums.ItemsTypes.Work_5 Then
				Continue;
			EndIf;
			
			ProductData_2 = ProductDataManagementClientServer.ProductDataStructureForSpecificationSelection();
			FillPropertyValues(ProductData_2, String);
			ProductData_2.ProductionStart      = Parameters.Date;
			ProductData_2.ProductionDispatcherBusinessUnit  = Parameters.ProductionDispatcherBusinessUnit;
			ProductData_2.LineOfBusiness = Parameters.LineOfBusiness;
			
			RowsArray.Add(String);
			DataArray.Add(ProductData_2);
			
		EndDo;
		
		BOMSelectionParameters = ProductDataManagementClientServer.ParametersForSelectingSpecificationsForManufacturingAssembly();
		If StructureOfData.ProductionProcessType = Enums.ProductionProcessTypes.PerformRM Then
			BOMSelectionParameters.AvailableTypes.Clear();
			BOMSelectionParameters.AvailableTypes.Add(StructureOfData.ProductionProcessType);
		EndIf;
		FillInSpecificationInLines(RowsArray, DataArray, BOMSelectionParameters, "NestedSpecification", True);
		
		For Each String In MaterialsAndServices Do
			CurrentStep = ?(DisplayStages, String.Stage, EmptyStageLink);
			ThereIsNestedSpecificationInLine = ValueIsFilled(String.NestedSpecification);
			If Parameters.DisplayMaterials Or ThereIsNestedSpecificationInLine Then
				RowsArray = RowsSet["MaterialsAndServices"][CurrentStep]; // Array
				RowsArray.Add(String);
			EndIf;
		EndDo;
		
	EndIf;
	
	If Parameters.DeduceLaborCosts Then
		For Each String In LaborCosts Do
			CurrentStep = ?(DisplayStages, String.Stage, EmptyStageLink);
			RowsArray = RowsSet["LaborCosts"][CurrentStep]; // Array
			RowsArray.Add(String);
		EndDo;
	EndIf;
	
	If DisplayStages Then
		For Each String In StructureOfData.Operations Do
			CurrentStep = String.Stage;
			RowsArray = RowsSet["Operations"][CurrentStep]; // Array
			RowsArray.Add(String);
		EndDo;
	EndIf;
	
	// The output lines
	CycleCondition                = True;
	FirstStageRowIndex    = 0;
	LastStageRowIndex = 0;
	If DisplayStages Then
		DirectionOfDecrease = (StructureOfData.ProductionProcessType <> Enums.ProductionProcessTypes.Disassembly
							And StructureOfData.ProductionProcessType <> Enums.ProductionProcessTypes.PerformRM);
		If DirectionOfDecrease Then
			FirstStageRowIndex    = -StructureOfData.Stages.Count()+1;
		Else
			LastStageRowIndex = StructureOfData.Stages.Count()-1;
		EndIf;
	EndIf;
	StageRowIndex = FirstStageRowIndex;
	
	FilterProducedInProcess = New Structure("ProducedInProcess", True);
	
	If Parameters.DisplayBalanceOfGoods Then
	
		StockBalance = CurrentBalancesOnItemList(MaterialsAndServices);
		StockBalance.Indexes.Add("Products, Characteristic, Warehouse");
		StructureOfSearchForGoodsBalances = New Structure("Products, Characteristic, Warehouse");
	
	EndIf;
	
	// Cycle by stages, output if required, otherwise we output everything in one pass.
	While CycleCondition Do
		
		If DisplayStages Then
			
			// Output of the Stage string.
			If StageRowIndex > LastStageRowIndex Then
				CycleCondition = False;
				Continue;
			EndIf;
			
			Data_Stage = StructureOfData.Stages[Max(StageRowIndex,-StageRowIndex)];
			CurrentStep = Data_Stage.Stage;
			
			ParentRow = AddTreeRow(
				?(TreeRow = Undefined, Tree, TreeRow), Enums.TypesOfSpecificationLines.Stage, Data_Stage);
			ParentRow.Products = Data_Stage.Stage;
			ParentRow.BillOfMaterials = Data_Stage.RouteSheet;
			
		Else
			
			// Preparation of collections of components, products and labor costs at all stages.
			CycleCondition = False;
			CurrentStep = Catalogs.ProductionStages.EmptyRef();
			
		EndIf;
		
		If ParentRow = Undefined Then
			StageString = Tree;
			ParentRow = Tree;
		Else
			StageString = ParentRow;
		EndIf;
		
		// Output of output product lines.
		RowsArray = RowsSet["ManufacturedProducts"][CurrentStep];
		If DisplayStages And StageRowIndex = LastStageRowIndex Then
			CommonClientServer.SupplementArray(RowsArray, RowsSet["ManufacturedProducts"][EmptyStageLink]);
		EndIf;
		QuantityOfFinishedProducts = RowsArray.Count();
		If (Parameters.OutputOutputProducts Or QuantityOfFinishedProducts > 0)
			And ThereIsBOM Then
			
			// Output of the line "Output items".
			If QuantityOfFinishedProducts > 0 And DisplayGroupingTitles Then
				ParentRow = AddTreeRow(StageString, Enums.TypesOfSpecificationLines.ManufacturedProducts);
				ParentRow.Products = "" + Enums.TypesOfSpecificationLines.ManufacturedProducts +
					" (" + (QuantityOfFinishedProducts) + ")";
			EndIf;
			
			// Output of output product lines and undifferentiation according to the specification.
			For Each String In RowsArray Do
				
				NewRow = AddTreeRow(ParentRow, String.LineKind, String);
				NewRow.BillOfMaterials = String.NestedSpecification;
				NewRow.ProducedInProcess = ValueIsFilled(String.NestedSpecification);
				
				NewRow.PictureIndex = GetImageIndex(NewRow, String);
				
			EndDo;
			
			ArrayOfStringsToUnravel = ParentRow.Rows.FindRows(FilterProducedInProcess);
			If ArrayOfStringsToUnravel.UBound() <> -1
				And Mode = ProductDataManagementClientServer.SpecificationTreeMode() Then
				
				If Not Parameters.DynamicReading Then
					FillInTreeRowSpecificationData(Parameters, ArrayOfStringsToUnravel, SelectionParameters);
				EndIf;
				
				For IndexOf = 0 To ArrayOfStringsToUnravel.UBound() Do
					ContinueUnravelingAlongTreeLine(Parameters, Tree, ArrayOfStringsToUnravel[IndexOf], UsedSpecifications);
				EndDo;
				
			EndIf;
			
		EndIf;
		
		// Output of material strings.
		RowsArray = RowsSet["MaterialsAndServices"][CurrentStep];
		If DisplayStages And StageRowIndex = FirstStageRowIndex Then
			CommonClientServer.SupplementArray(RowsArray, RowsSet["MaterialsAndServices"][EmptyStageLink]);
		EndIf;
		QuantityOfMaterials = RowsArray.Count();
		If (Parameters.DisplayMaterials Or QuantityOfMaterials > 0)
			And ThereIsBOM Then
			
			// Output of the line "Materials and works".
			If QuantityOfMaterials > 0 And DisplayGroupingTitles Then
				ParentRow = AddTreeRow(StageString, Enums.TypesOfSpecificationLines.MaterialsAndServices);
				ParentRow.Products = "" + Enums.TypesOfSpecificationLines.MaterialsAndServices +
					" (" + QuantityOfMaterials + ")";
			EndIf;
		
			// Output of the material lines and unzipping according to the specification.
			ArrayOfStringsToUnravel = New Array;
			ArrayOfCommunicationKeys      = New Array;
			For Each String In RowsArray Do
				
				NewRow = AddTreeRow(ParentRow, String.LineKind, String);
				NewRow.BillOfMaterials = String.NestedSpecification;
				NewRow.ProducedInProcess = ValueIsFilled(String.NestedSpecification);
				
				NewRow.PictureIndex = GetImageIndex(NewRow, String);
				
				If NewRow.ProducedInProcess
					And Mode = ProductDataManagementClientServer.SpecificationTreeMode() Then
					ArrayOfStringsToUnravel.Add(NewRow);
					ArrayOfCommunicationKeys.Add(String.ConnectionKey);
				EndIf;
				
				If Parameters.DisplayBalanceOfGoods Then
					FillPropertyValues(StructureOfSearchForGoodsBalances, NewRow);
					ArrayOfWarehouseBalances = StockBalance.FindRows(StructureOfSearchForGoodsBalances);
					If ArrayOfWarehouseBalances.Count() > 0 Then
						FillPropertyValues(NewRow, ArrayOfWarehouseBalances[0]);
					EndIf;
				EndIf;
				
			EndDo;
			
			If ArrayOfStringsToUnravel.UBound() <> -1 Then
			
				If Not Parameters.DynamicReading Then
					FillInTreeRowSpecificationData(Parameters, ArrayOfStringsToUnravel, SelectionParameters);
				EndIf;
				
				For IndexOf = 0 To ArrayOfStringsToUnravel.UBound() Do
					ContinueUnravelingAlongTreeLine(
						Parameters, Tree, ArrayOfStringsToUnravel[IndexOf], UsedSpecifications, ArrayOfCommunicationKeys[IndexOf]);
				EndDo;
			
			EndIf;
			
		EndIf;
	
		// Output of labor cost lines.
		RowsArray = RowsSet["LaborCosts"][CurrentStep];
		If DisplayStages And StageRowIndex = FirstStageRowIndex Then
			CommonClientServer.SupplementArray(RowsArray, RowsSet["LaborCosts"][EmptyStageLink]);
		EndIf;
		NumberOfLaborCosts = RowsArray.Count();
		If Parameters.DeduceLaborCosts And ThereIsBOM And NumberOfLaborCosts > 0 Then
			
			If NumberOfLaborCosts > 0 And DisplayGroupingTitles Then
				ParentRow = AddTreeRow(StageString, Enums.TypesOfSpecificationLines.LaborCosts);
				ParentRow.Products = "" + Enums.TypesOfSpecificationLines.LaborCosts + " (" + NumberOfLaborCosts + ")";
			EndIf;
			
			For Each String In RowsArray Do
				NewRow = AddTreeRow(ParentRow, Enums.TypesOfSpecificationLines.LaborCost, String);
				NewRow.NumberOfPackages = String.Count;
				NewRow.Products = String.WorkKind;
			EndDo;
			
		EndIf;
		
		// Output lines of operations.
		RowsArray = RowsSet["Operations"][CurrentStep];
		OperationsCount = RowsArray.Count();
		If OutputOfOperations And OperationsCount > 0 Then
			
			If DisplayGroupingTitles Then
				ParentRow = AddTreeRow(StageString, Enums.TypesOfSpecificationLines.Operations);
				ParentRow.Products = "" + Enums.TypesOfSpecificationLines.Operations + " (" + OperationsCount + ")";
			EndIf;
			
			For Each String In RowsArray Do
				NewRow = AddTreeRow(ParentRow, Enums.TypesOfSpecificationLines.Operation, String);
				NewRow.Products = String.Operation;
				NewRow.NumberOfPackages = String.QuantityPerBatch;
				If Not ValueIsFilled(NewRow.UnitOfMeasure) Then
					NewRow.UnitOfMeasure = ProductionManagementClientServer.PresentationOfUnitOfOperation(Undefined, 0, True);
				EndIf;
			EndDo;
			
		EndIf;
		
		StageRowIndex = StageRowIndex + 1;
		
	EndDo;
	
	If TreeRow <> Undefined And TreeRow.ThereIsBOM Then
		TreeRow.BOMIsRead = True;
		TreeRow.StructureOfData = Undefined;
		TreeRow.ProductionProcessType = StructureOfData.ProductionProcessType;
	EndIf;
	
EndProcedure

// Procedure for creating a conditional design of the specification tree.
//
// Parameters:
//  ConditionalAppearance - DataCompositionConditionalAppearance - structure of parameters.
//
Procedure ConfigureConditionalAppearanceOfSpecificationTree(ConditionalAppearance) Export
	
	// Packaging.
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
	FormattedField.Field = New DataCompositionField("BOMsTreeUnitOfMeasure");
	
	FilterElement = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue = New DataCompositionField("BOMsTree.Package");
	FilterElement.ComparisonType  = DataCompositionComparisonType.Filled;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("Show", False);
	
	// Bold lines with the name of the stage.
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("Font", New Font(,,True));
	
	FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
	FormattedField.Field = New DataCompositionField("BOMsTreeProducts");
	
	FilterElement = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue = New DataCompositionField("BOMsTree.LineKind");
	FilterElement.ComparisonType = DataCompositionComparisonType.Equal;
	FilterElement.RightValue = Enums.TypesOfSpecificationLines.Stage;
	
	// Viewing only.
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("ReadOnly", True);
	
	FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
	FormattedField.Field = New DataCompositionField("BOMsTreeBillOfMaterials");
	FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
	FormattedField.Field = New DataCompositionField("BOMsTreeCharacteristic");
	
	TypesOfRows = New ValueList;
	TypesOfRows.Add(Enums.TypesOfSpecificationLines.Stage);
	TypesOfRows.Add(Enums.TypesOfSpecificationLines.LaborCosts);
	TypesOfRows.Add(Enums.TypesOfSpecificationLines.LaborCost);
	TypesOfRows.Add(Enums.TypesOfSpecificationLines.MaterialsAndServices);
	TypesOfRows.Add(Enums.TypesOfSpecificationLines.ManufacturedProducts);
	TypesOfRows.Add(Enums.TypesOfSpecificationLines.Operations);
	TypesOfRows.Add(Enums.TypesOfSpecificationLines.Operation);
	
	FilterElement = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue = New DataCompositionField("BOMsTree.LineKind");
	FilterElement.ComparisonType = DataCompositionComparisonType.InList;
	FilterElement.RightValue = TypesOfRows;
	
	//
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("ReadOnly", True);
	
	FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
	FormattedField.Field = New DataCompositionField("BOMsTreeNumberOfPackages");
	FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
	FormattedField.Field = New DataCompositionField("BOMsTreePackage");
	
	FilterElement = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue = New DataCompositionField("BOMsTree.LineKind");
	FilterElement.ComparisonType = DataCompositionComparisonType.NotEqual;
	FilterElement.RightValue = Enums.TypesOfSpecificationLines.Products;
	
	// Using characteristics.
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("ReadOnly", True);
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("vi = '<không sử dụng đặc tính>';
																		|ru = '<характеристики не используются>';
																		|en = '<variants are not used>'; fa = '<گونه‌ها استفاده نمی‌شوند>';
																		|it = '<le caratteristiche non vengono usate>';
																		|pl = '<charakterystyki nie dotyczą>';
																		|tr = '<varyantlar kullanılmamaktadır>'"));
	ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	
	FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
	FormattedField.Field = New DataCompositionField("BOMsTreeCharacteristic");
	
	FilterElement = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue = New DataCompositionField("BOMsTree.ItemVariantsAreUsed");
	FilterElement.ComparisonType = DataCompositionComparisonType.Equal;
	FilterElement.RightValue = False;
	
	TypesOfRows = New ValueList;
	TypesOfRows.Add(Enums.TypesOfSpecificationLines.Products);
	TypesOfRows.Add(Enums.TypesOfSpecificationLines.FinishedProduct);
	TypesOfRows.Add(Enums.TypesOfSpecificationLines.IncomingProduct);
	TypesOfRows.Add(Enums.TypesOfSpecificationLines.SideExit);
	TypesOfRows.Add(Enums.TypesOfSpecificationLines.Material);
	TypesOfRows.Add(Enums.TypesOfSpecificationLines.IntermediateSemiFinishedProduct);
	TypesOfRows.Add(Enums.TypesOfSpecificationLines.Work_In_Progress);
	
	FilterElement = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue = New DataCompositionField("BOMsTree.LineKind");
	FilterElement.ComparisonType = DataCompositionComparisonType.InList;
	FilterElement.RightValue = TypesOfRows;
	
	// Using characteristics for an item.
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("vi = '<đặc tính bất kỳ>';
																		|ru = '<любая характеристика>';
																		|en = '<any variant>'; fa = '<any variant>';
																		|it = '<qualsiasi caratteristica>';
																		|pl = '<dowolna charakterystyka>';
																		|tr = '<herhangi bir varyant>'"));
	ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	
	FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
	FormattedField.Field = New DataCompositionField("BOMsTreeCharacteristic");
	
	FilterElement = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue = New DataCompositionField("BOMsTree.ItemVariantsAreUsed");
	FilterElement.ComparisonType = DataCompositionComparisonType.Equal;
	FilterElement.RightValue = True;
	
	FilterElement = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue = New DataCompositionField("BOMsTree.Characteristic");
	FilterElement.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	// The nomenclature and characteristics are specified during production.
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("vi = '<được chỉ định trong sản xuất>';
																		|ru = '<уточняется при производстве>';
																		|en = '<specified during production>'; fa = '<specified during production>';
																		|it = '<specificato durante la produzione>';
																		|pl = '<uściślane podczas produkcji>';
																		|tr = '<üretim esnasında netleştirilmektedir>'"));
	ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.NoteText);
	
	FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
	FormattedField.Field = New DataCompositionField("BOMsTreeProducts");
	
	FilterElement = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue = New DataCompositionField("BOMsTree.MethodOfProductsAutoselection");
	FilterElement.ComparisonType = DataCompositionComparisonType.Equal;
	FilterElement.RightValue = Enums.MethodsOfProductAutoSelection.SpecifiedInProductionProcess;
	
	FilterElement = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue = New DataCompositionField("BOMsTree.Products");
	FilterElement.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	//
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("vi = '<được chỉ định trong sản xuất>';
																		|ru = '<уточняется при производстве>';
																		|en = '<specified during production>'; fa = '<specified during production>';
																		|it = '<specificato durante la produzione>';
																		|pl = '<uściślane podczas produkcji>';
																		|tr = '<üretim esnasında netleştirilmektedir>'"));
	ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.NoteText);
	
	FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
	FormattedField.Field = New DataCompositionField("BOMsTreeCharacteristic");
	
	FilterElement = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue = New DataCompositionField("BOMsTree.Characteristic");
	FilterElement.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	FilterElement = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue = New DataCompositionField("BOMsTree.MethodOfItemVariantAutoselection");
	FilterElement.ComparisonType = DataCompositionComparisonType.Equal;
	FilterElement.RightValue = Enums.MethodsOfItemVariantAutoselection.SpecifiedInProductionProcess;
	
	// The nomenclature and characteristics are specified taking into account the properties.
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("vi = '<được chỉ định trong thuộc tính của sản phẩm chính>';
																		|ru = '<указывается в свойстве основного изделия>';
																		|en = '<specified in the property of the main product>'; fa = '<specified in the property of the main product>';
																		|it = '<viene indicato nella proprietà del prodotto principale>';
																		|pl = '<wskazane we właściwości produktu głównego>';
																		|tr = '<nihai ana ürün özelliğinde belirtilmektedir>'"));
	ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.NoteText);
	
	FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
	FormattedField.Field = New DataCompositionField("BOMsTreeProducts");
	
	FilterElement = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue = New DataCompositionField("BOMsTree.Products");
	FilterElement.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	FilterElement = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue = New DataCompositionField("BOMsTree.MethodOfProductsAutoselection");
	FilterElement.ComparisonType = DataCompositionComparisonType.Equal;
	FilterElement.RightValue = Enums.MethodsOfProductAutoSelection.SpecifiedInProductsProperty;
	
	//
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("vi = '<được chọn bởi các thuộc tính>';
																		|ru = '<подбирается по свойствам>';
																		|en = '<selected by properties>'; fa = '<selected by properties>';
																		|it = '<viene selezionato in base alle proprietà>';
																		|pl = '<dobierane wg właściwości>';
																		|tr = '<özelliklere göre seçilmektedir>'"));
	ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.NoteText);
	
	FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
	FormattedField.Field = New DataCompositionField("BOMsTreeCharacteristic");
	
	FilterElement = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue = New DataCompositionField("BOMsTree.Characteristic");
	FilterElement.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	FilterElement = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue = New DataCompositionField("BOMsTree.MethodOfItemVariantAutoselection");
	FilterElement.ComparisonType = DataCompositionComparisonType.Equal;
	FilterElement.RightValue = Enums.MethodsOfItemVariantAutoselection.AutomaticallySelectedByProductsProperties;
	
	//
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("vi = '<được chọn theo thuật toán>';
																		|ru = '<подбирается по алгоритму>';
																		|en = '<picked by algorithm>'; fa = '<picked by algorithm>';
																		|it = '<viene selezionato in base ad un algoritmo>';
																		|pl = '<dobierane wg algorytmu>';
																		|tr = '<algoritmaya göre seçilmektedir>'"));
	ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.NoteText);
	
	FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
	FormattedField.Field = New DataCompositionField("BOMsTreeCharacteristic");
	
	FilterElement = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue = New DataCompositionField("BOMsTree.Characteristic");
	FilterElement.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	FilterElement = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue = New DataCompositionField("BOMsTree.MethodOfItemVariantAutoselection");
	FilterElement.ComparisonType = DataCompositionComparisonType.Equal;
	FilterElement.RightValue = Enums.MethodsOfItemVariantAutoselection.PickedByAlgorithm;
	
	// For specifications on the type of nomenclature
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("ReadOnly", True);
	
	FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
	FormattedField.Field = New DataCompositionField("BOMsTreeProducts");
	
	FilterElement = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue = New DataCompositionField("BOMsTree.ProductKind");
	FilterElement.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	//
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("ReadOnly", True);
	
	FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
	FormattedField.Field = New DataCompositionField("BOMsTreeBillOfMaterials");
	FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
	FormattedField.Field = New DataCompositionField("BOMsTreeCharacteristic");
	FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
	FormattedField.Field = New DataCompositionField("BOMsTreePackage");
	FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
	FormattedField.Field = New DataCompositionField("BOMsTreeNumberOfPackages");
	
	FilterElement = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue = New DataCompositionField("BOMsTree.Products");
	FilterElement.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	//
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", New DataCompositionField("BOMsTree.ProductKind"));
	ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	
	FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
	FormattedField.Field = New DataCompositionField("BOMsTreeProducts");
	
	FilterElement = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue = New DataCompositionField("BOMsTree.ProductKind");
	FilterElement.ComparisonType = DataCompositionComparisonType.Filled;
	
	FilterElement = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue = New DataCompositionField("BOMsTree.Products");
	FilterElement.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	// Color design of levels
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
	FormattedField.Field = New DataCompositionField("BOMsTree");

	FilterElement = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue = New DataCompositionField("BOMsTree.DesignLevel");
	FilterElement.ComparisonType = DataCompositionComparisonType.Equal;
	FilterElement.RightValue = 0;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("BackColor", StyleColors.ReportGroup1BackColor);
	
	//
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
	FormattedField.Field = New DataCompositionField("BOMsTree");

	FilterElement = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue = New DataCompositionField("BOMsTree.DesignLevel");
	FilterElement.ComparisonType = DataCompositionComparisonType.Equal;
	FilterElement.RightValue = 1;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("BackColor", StyleColors.ReportGroup2BackColor);
	
EndProcedure

#EndRegion

#Region RouteSheets

// Gets route maps that are valid for the specified division on the production start date
// The route map is valid if
//  - her status is Valid
//  - its validity period includes the start of production.
//
// Parameters:
//  Department		- CatalogRef.BusinessStructure - the division that is assigned to provide the product
//  ProductionStart	- Date - production start date, on which date the specification must be valid
//  SearchString		- String - the string contained in the name.
//
// Returns:
//   ValueList - properties that can be used for auto-selection.
//
Function CurrentRouteMapsOfDivision(Department, ProductionStart, SearchString = Undefined) Export
	
	Query = New Query;
	
	QueryText = 
	"SELECT ALLOWED
	|	RouteSheets.Ref AS RouteSheet,
	|	RouteSheets.Presentation AS RouteSheetPresentation
	|FROM
	|	Catalog.RouteSheets AS RouteSheets
	|WHERE
	|	RouteSheets.Status = VALUE(Enum.StatusesOfRouteSheets.Valid)
	|	AND (RouteSheets.Department = &Department)
	|	AND (&ProductionStart = DATETIME(1, 1, 1)
	|			OR RouteSheets.ValidOnDate <= &ProductionStart)
	|	AND (RouteSheets.ValidToDate = DATETIME(1, 1, 1)
	|			OR RouteSheets.ValidToDate >= BEGINOFPERIOD(&ProductionStart, DAY))
	|	AND &SearchString
	|ORDER BY
	|	RouteSheetPresentation";
	
	SearchStringSubstitution = "";
	If SearchString <> Undefined Then
		Query.SetParameter("Text", "%" + TrimAll(SearchString) + "%");
		SearchStringSubstitution = "AND RouteSheets.Description LIKE &Text";
	EndIf;
	QueryText = StrReplace(QueryText, "AND &SearchString", SearchStringSubstitution);
	
	Query.SetParameter("Department",      Department);
	Query.SetParameter("ProductionStart", ProductionStart);
	
	Query.Text = QueryText;
	
	Selection = Query.Execute().Select();
	
	ChoiceData = New ValueList;
	
	While Selection.Next() Do
		ChoiceData.Add(Selection.RouteSheet, Selection.RouteSheetPresentation);
	EndDo;

	Return ChoiceData;
	
EndFunction

#EndRegion

#Region AutoSelection_SelectionByProperties_CalculationOfQuantity

#Region AutoSelection

// Gets properties that can be used for auto-selection
//
// Parameters:
//  TypeOfProducts					- CatalogRef.ItemKinds - a set of properties that can be used for items.
//  OnlyPropertiesOfCharacteristics	- Boolean - True if you only need to get the properties of characteristics.
//
// Returns:
//   Array - properties that can be used for auto-selection.
//
Function GetPropertiesForAutoSelection(TypeOfProducts, OnlyPropertiesOfCharacteristics = False) Export

	QueryText = RequestTextAvailableProductProperties(False, Not OnlyPropertiesOfCharacteristics);
	Query = New Query(QueryText);

	Query.SetParameter("ItemKinds", TypeOfProducts);
	Query.SetParameter("Set_Catalog_Products_Overall", PropertyManager.PropertiesSetByName("Catalog_Products_Overall"));
	Query.SetParameter("Set_Catalog_ItemsCharacteristics_Overall", PropertyManager.PropertiesSetByName("Catalog_ItemsCharacteristics_Overall"));
	
	Result = Query.Execute().Unload();
	Return Result;
	
EndFunction

// Generates an array of descriptions of auto-selection functions.
// 
// Returns:
//  Array of See CreateDescriptionOfAutoselectFunction
//
// Example:
//  See DescriptionOfAutoSelectionFunctionsForProductItemPropertyValue
//
Function DescriptionOfAutoSelectFeatureFunctions() Export
	
	Result = New Array;
	
	Return Result;
	
EndFunction

// Generates an array of descriptions of auto-selection functions.
// 
// Returns:
//  Array - array of descriptions of auto-selection functions, See CreateDescriptionOfAutoselectFunction
//
// Example:
//  In order to supplement the list of auto-selection functions of the property, it is necessary
//  to create a configuration extension, add a Custom product management module to the created extension and implement the following code:
//  
//  &Instead of("Function descriptionauthorization of the properties of the nomenclature")
//  Function descriptionfunctionauthorization of the properties of the nomenclature Expanded() Export
//
//    Result = Continue Call();
//  
//    Description = Create a description of the Auto-selection function("My Auto-selection function",,NStr("ru = 'My auto-selection function'"));
//
//    The result.Add(Description);
//
//    Return Result;
//
//  The end of the function
//
Function DescriptionOfAutoSelectionFunctionsForProductItemPropertyValue() Export
	
	Result = New Array;
	
	Return Result;
	
EndFunction

#EndRegion

#Region CalculationByFormulas

// Returns a tree of operators for the formula constructor
// 
// Returns:
//  ValueTree - See ProcessingOfFormulas.GetEmptyOperatorsTree
Function BuildTreeOfOperators() Export
	
	Tree = ProcessingOfFormulas.GetEmptyOperatorsTree();
	
	GroupPresentation = NStr("vi = 'Ký tự tách';
							|ru = 'Разделители';
							|en = 'Separators'; fa = 'Separators';
							|it = 'Divisori';
							|pl = 'Separatory';
							|tr = 'Ayırıcılar'");
	OperatorsGroup = ProcessingOfFormulas.AddOperatorsGroup(Tree, "Separators", GroupPresentation);
	ProcessingOfFormulas.AddOperator(OperatorsGroup, "(", " + "" ("" + ", "(");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, ")", " + "") "" + ", ")");
	
	GroupPresentation = NStr("vi = 'Toán tử';
							|ru = 'Операторы';
							|en = 'Operators'; fa = 'عملگرها';
							|it = 'Operatori';
							|pl = 'Operatory';
							|tr = 'Operatörler'");
	OperatorsGroup = ProcessingOfFormulas.AddOperatorsGroup(Tree, "Operators", GroupPresentation);
	ProcessingOfFormulas.AddOperator(OperatorsGroup, "+", " + ", "+");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, "-", " - ", "-");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, "*", " * ", "*");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, "/", " / ", "/");
	
	GroupPresentation = NStr("vi = 'Toán tử lo-gic và hằng';
							|ru = 'Логические операторы и константы';
							|en = 'Logical operators and constants'; fa = 'Logical operators and constants';
							|it = 'Operatori logici e costanti';
							|pl = 'Operatory logiczne i konstanty';
							|tr = 'Mantıksal operatörler ve sabitler'");
	OperatorsGroup = ProcessingOfFormulas.AddOperatorsGroup(Tree, "LogicalOperatorsAndConstants", GroupPresentation);
	ProcessingOfFormulas.AddOperator(OperatorsGroup, "<",  " < ",  "<");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, ">",  " > ",  ">");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, "<=", " <= ", "<=");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, ">=", " >= ", ">=");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, "=",  " = ",  "=");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, "<>", " <> ", "<>");
	
	Id = "And";
	StructureToInsert = " " + "And" + " ";
	Presentation = NStr("vi = 'VÀ';
						|ru = 'И';
						|en = 'AND'; fa = 'و';
						|it = 'E';
						|pl = 'ORAZ';
						|tr = 'VE'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, Id, StructureToInsert, Presentation);
	
	Id = "OR";
	StructureToInsert = " " + "OR" + " ";
	Presentation = NStr("vi = 'HOẶC';
						|ru = 'ИЛИ';
						|en = 'OR'; fa = 'یا';
						|it = 'OPPURE';
						|pl = 'LUB';
						|tr = 'VEYA'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, Id, StructureToInsert, Presentation);
	
	Id = "NOT";
	StructureToInsert = " " + "NOT" + " ";
	Presentation = NStr("vi = 'KHÔNG';
						|ru = 'НЕ';
						|en = 'NOT'; fa = 'NOT';
						|it = 'NON';
						|pl = 'NIE';
						|tr = 'DEĞİL'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, Id, StructureToInsert, Presentation);
	
	Id = "TRUE";
	StructureToInsert = " " + "TRUE" + " ";
	Presentation = NStr("vi = 'ĐÚNG';
						|ru = 'ИСТИНА';
						|en = 'TRUE'; fa = 'TRUE';
						|it = 'VERO';
						|pl = 'PRAWDA';
						|tr = 'TRUE'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, Id, StructureToInsert, Presentation);
	
	Id = "FALSE";
	StructureToInsert = " " + "FALSE" + " ";
	Presentation = NStr("vi = 'SAI';
						|ru = 'ЛОЖЬ';
						|en = 'FALSE'; fa = 'FALSE';
						|it = 'FALSO';
						|pl = 'FAŁSZ';
						|tr = 'FALSE'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, Id, StructureToInsert, Presentation);
	
	GroupPresentation = NStr("vi = 'Hàm';
							|ru = 'Числовые функции';
							|en = 'Numeric functions'; fa = 'Numeric functions';
							|it = 'Funzioni numeriche';
							|pl = 'Funkcje liczbowe';
							|tr = 'Sayısal fonksiyonlar'");
	OperatorsGroup = ProcessingOfFormulas.AddOperatorsGroup(Tree, "NumericFunction", GroupPresentation);
	
	Id = "Max";
	ParameterPresentation1 = NStr("vi = '<Giá trị 1>';
									|ru = '<Значение 1>';
									|en = '<Value 1>'; fa = '<Value 1>';
									|it = '<Valore 1>';
									|pl = '<Wartość 1>';
									|tr = '<Değer 1>'");
	ParameterPresentation2 = NStr("vi = '<Giá trị 2>';
									|ru = '<Значение 2>';
									|en = '<Value 2>'; fa = '<Value 2>';
									|it = '<Valore 2>';
									|pl = '<Wartość 2>';
									|tr = '<Değer 2>'");
	StructureToInsert = StringFunctionsClientServer.SubstituteParametersToString(
		"Max(%1, %2)",
		ParameterPresentation1,
		ParameterPresentation2);
	Presentation = NStr("vi = 'Tối đa';
						|ru = 'Максимум';
						|en = 'Maximum'; fa = 'حداکثر';
						|it = 'Massimo';
						|pl = 'Maksimum';
						|tr = 'Maksimum'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, Id, StructureToInsert, Presentation,, 2);
	
	Id = "Min";
	ParameterPresentation1 = NStr("vi = '<Giá trị 1>';
									|ru = '<Значение 1>';
									|en = '<Value 1>'; fa = '<Value 1>';
									|it = '<Valore 1>';
									|pl = '<Wartość 1>';
									|tr = '<Değer 1>'");
	ParameterPresentation2 = NStr("vi = '<Giá trị 2>';
									|ru = '<Значение 2>';
									|en = '<Value 2>'; fa = '<Value 2>';
									|it = '<Valore 2>';
									|pl = '<Wartość 2>';
									|tr = '<Değer 2>'");
	StructureToInsert = StringFunctionsClientServer.SubstituteParametersToString(
		"Min(%1, %2)",
		ParameterPresentation1,
		ParameterPresentation2);
	Presentation = NStr("vi = 'Tối thiểu';
						|ru = 'Минимум';
						|en = 'Minimum'; fa = 'حداقل';
						|it = 'Minimo';
						|pl = 'Minimum';
						|tr = 'Minimum'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, Id, StructureToInsert, Presentation,, 2);
	
	Id = "Round";
	ParameterPresentation1 = NStr("vi = '<Giá trị làm tròn>';
									|ru = '<Округляемое значение>';
									|en = '<Round value>'; fa = '<Round value>';
									|it = '<Valore da arrotondare>';
									|pl = '<Wartość zaokrąglana>';
									|tr = '<Yuvarlanmış değer>'");
	ParameterPresentation2 = NStr("vi = '<Độ sâu bit>';
									|ru = '<Разрядность>';
									|en = '<Bitness>'; fa = '<Bitness>';
									|it = '<bitness>';
									|pl = '<Ilość pozycji>';
									|tr = '<Bit genişliği>'");
	StructureToInsert = StringFunctionsClientServer.SubstituteParametersToString(
		"Round(%1, %2)",
		ParameterPresentation1,
		ParameterPresentation2);
	Presentation = NStr("vi = 'Làm tròn';
						|ru = 'Округление';
						|en = 'Rounding'; fa = 'Rounding';
						|it = 'Arrotondamento';
						|pl = 'Zaokrąglenie';
						|tr = 'Yuvarlama'");
	Explanation = NStr("vi = 'Làm tròn đến số gần nhất';
						|ru = 'Округление к ближайшему числу';
						|en = 'Rounding to the nearest number'; fa = 'Rounding to the nearest number';
						|it = 'Arrotondamento al numero più vicino';
						|pl = 'Zaokrąglenie do najbliższej liczby';
						|tr = 'En yakın sayıya yuvarlama'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, Id, StructureToInsert, Presentation, Explanation, 2);
	
	LongDesc = ProductDataManagementClientServer.DescriptionOfFunctionOfOcdFormulaConstructorUp();
	ProcessingOfFormulas.AddOperator(
		OperatorsGroup, LongDesc.Id, LongDesc.StructureToInsert, LongDesc.Presentation, LongDesc.Explanation, 1);
	
	LongDesc = ProductDataManagementClientServer.DescriptionOfFunctionOfOcdFormulaConstructorDown();
	ProcessingOfFormulas.AddOperator(
		OperatorsGroup, LongDesc.Id, LongDesc.StructureToInsert, LongDesc.Presentation, LongDesc.Explanation, 1);
	
	Id = "Int";
	StructureToInsert = "Int()";
	Presentation = NStr("vi = 'Phần nguyên';
						|ru = 'Целая часть';
						|en = 'Integral part'; fa = 'بخش صحیح';
						|it = 'Parte intera';
						|pl = 'Cała część';
						|tr = 'Tam sayı kısmı'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, Id, StructureToInsert, Presentation,, 1);
	
	Id = "Pow";
	ParameterPresentation1 = NStr("vi = '<Cơ sở>';
									|ru = '<Основание>';
									|en = '<Base document>'; fa = '<Base document>';
									|it = '<Causale>';
									|pl = '<Podstawa>';
									|tr = '<Temel>'");
	ParameterPresentation2 = NStr("vi = '<Chỉ tiêu>';
									|ru = '<Показатель>';
									|en = '<Indicator>'; fa = '<Indicator>';
									|it = '<Indicatore>';
									|pl = '<Wskaźnik>';
									|tr = '<Gösterge>'");
	StructureToInsert = StringFunctionsClientServer.SubstituteParametersToString(
		"Pow(%1, %2)",
		ParameterPresentation1,
		ParameterPresentation2);;
	Presentation = NStr("vi = 'Mức';
						|ru = 'Степень';
						|en = 'Degree'; fa = 'Degree';
						|it = 'Potenza';
						|pl = 'Stopień';
						|tr = 'Derece'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, Id, StructureToInsert, Presentation,, 2);
	
	Id = "Sqrt";
	StructureToInsert = "Sqrt()";
	Presentation = NStr("vi = 'Căn bậc hai';
						|ru = 'Квадратный корень';
						|en = 'Square root'; fa = 'Square root';
						|it = 'Radice quadrata';
						|pl = 'Pierwiastek kwadratowy';
						|tr = 'Karekök'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, Id, StructureToInsert, Presentation,, 1);
	
	GroupPresentation = NStr("vi = 'Hàm lượng giác';
							|ru = 'Тригонометрические функции';
							|en = 'Trigonometric functions'; fa = 'Trigonometric functions';
							|it = 'Funzioni trigonometriche';
							|pl = 'Funkcje trygonometryczne';
							|tr = 'Trigonometrik fonksiyonlar'");
	OperatorsGroup = ProcessingOfFormulas.AddOperatorsGroup(Tree, "TrigonometricFunctions", GroupPresentation);
	
	Id = "Sin";
	StructureToInsert = "Sin()";
	Presentation = NStr("vi = 'Sin';
						|ru = 'Синус';
						|en = 'Sine'; fa = 'Sine';
						|it = 'Seno';
						|pl = 'Sinus';
						|tr = 'Sinüs'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, Id, StructureToInsert, Presentation,, 1);
	
	Id = "Cos";
	StructureToInsert = "Cos()";
	Presentation = NStr("vi = 'Cô-sin';
						|ru = 'Косинус';
						|en = 'Cosine'; fa = 'Cosine';
						|it = 'Coseno';
						|pl = 'Kosinus';
						|tr = 'Kosinüs'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, Id, StructureToInsert, Presentation,, 1);
	
	Id = "Tan";
	StructureToInsert = "Tan()";
	Presentation = NStr("vi = 'Tiếp tuyến';
						|ru = 'Тангенс';
						|en = 'Tangent'; fa = 'Tangent';
						|it = 'Tangente';
						|pl = 'Tangens';
						|tr = 'Tanjant'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, Id, StructureToInsert, Presentation,, 1);
	
	GroupPresentation = NStr("vi = 'Chức năng theo xâu ký tự';
							|ru = 'Строковые функции';
							|en = 'String functions'; fa = 'توابع رشته‌ای';
							|it = 'Funzioni di stringa';
							|pl = 'Funkcje wierszy';
							|tr = 'Satır fonksiyonları'");
	OperatorsGroup = ProcessingOfFormulas.AddOperatorsGroup(Tree, "StringFunctions", GroupPresentation);

	Id = "Left";
	ParameterPresentation1 = NStr("vi = '<Xâu ký tự>';
									|ru = '<Строка>';
									|en = '<String>'; fa = '<String>';
									|it = '<Riga>';
									|pl = '<Wiersz>';
									|tr = '<Satır>'");
	ParameterPresentation2 = NStr("vi = '<Số ký tự>';
									|ru = '<Число символов>';
									|en = '<Number of characters>'; fa = '<Number of characters>';
									|it = '<Numero simboli>';
									|pl = '<Liczba znaków>';
									|tr = '<Karakter sayısı>'");
	StructureToInsert = StringFunctionsClientServer.SubstituteParametersToString(
		"Left(%1, %2)",
		ParameterPresentation1,
		ParameterPresentation2);
	Presentation = NStr("vi = 'Phần trái của xâu ký tự';
						|ru = 'Левая часть строки';
						|en = 'Left part of the string'; fa = 'Left part of the string';
						|it = 'Parte sinistra della riga';
						|pl = 'Lewa strona wiersza';
						|tr = 'Satırın sol kısmı'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, Id, StructureToInsert, Presentation,, 1);
	
	Id = "Right";
	ParameterPresentation1 = NStr("vi = '<Xâu ký tự>';
									|ru = '<Строка>';
									|en = '<String>'; fa = '<String>';
									|it = '<Riga>';
									|pl = '<Wiersz>';
									|tr = '<Satır>'");
	ParameterPresentation2 = NStr("vi = '<Số ký tự>';
									|ru = '<Число символов>';
									|en = '<Number of characters>'; fa = '<Number of characters>';
									|it = '<Numero simboli>';
									|pl = '<Liczba znaków>';
									|tr = '<Karakter sayısı>'");
	StructureToInsert = StringFunctionsClientServer.SubstituteParametersToString(
		"Right(%1, %2)",
		ParameterPresentation1,
		ParameterPresentation2);
	Presentation = NStr("vi = 'Phần phải của xâu ký tự';
						|ru = 'Правая часть строки';
						|en = 'Right part of the string'; fa = 'Right part of the string';
						|it = 'Parte destra della riga';
						|pl = 'Prawa strona wiersza';
						|tr = 'Satırın sağ kısmı'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, Id, StructureToInsert, Presentation,, 1);
	
	Id = "Mid";
	ParameterPresentation1 = NStr("vi = '<Xâu ký tự>';
									|ru = '<Строка>';
									|en = '<String>'; fa = '<String>';
									|it = '<Riga>';
									|pl = '<Wiersz>';
									|tr = '<Satır>'");
	ParameterPresentation2 = NStr("vi = '<Số đầu>';
									|ru = '<Начальный номер>';
									|en = '<Starting number>'; fa = '<Starting number>';
									|it = '<Numero iniziale>';
									|pl = '<Numer początkowy>';
									|tr = '<Başlangıç numarası>'");
	ParameterPresentation3 = NStr("vi = '<Số ký tự>';
									|ru = '<Число символов>';
									|en = '<Number of characters>'; fa = '<Number of characters>';
									|it = '<Numero simboli>';
									|pl = '<Liczba znaków>';
									|tr = '<Karakter sayısı>'");
	StructureToInsert = StringFunctionsClientServer.SubstituteParametersToString(
		"Mid(%1, %2, %3)",
		ParameterPresentation1,
		ParameterPresentation2,
		ParameterPresentation3);
	Presentation = NStr("vi = 'Phần giữa của xâu ký tự';
						|ru = 'Средняя часть строки';
						|en = 'Middle part of the string'; fa = 'Middle part of the string';
						|it = 'Parte centrale della riga';
						|pl = 'Średnia część wiersza';
						|tr = 'Satırın orta kısmı'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, Id, StructureToInsert, Presentation,, 1);
	
	Id = "StrLen";
	StructureToInsert = "StrLen()";
	Presentation = NStr("vi = 'Độ dài xâu ký tự';
						|ru = 'Длина строки';
						|en = 'String length'; fa = 'طول رشته';
						|it = 'Lunghezza della riga';
						|pl = 'Długość wiersza';
						|tr = 'Satır uzunluğu'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, Id, StructureToInsert, Presentation,, 1);
	
	Id = "StrFind";
	ParameterPresentation1 = NStr("vi = '<Xâu ký tự>';
									|ru = '<Строка>';
									|en = '<String>'; fa = '<String>';
									|it = '<Riga>';
									|pl = '<Wiersz>';
									|tr = '<Satır>'");
	ParameterPresentation2 = NStr("vi = '<Cụm từ để tìm kiếm>';
									|ru = '<Подстрока для поиска>';
									|en = '<Substring for search>'; fa = '<Substring for search>';
									|it = '<Sottoriga per la ricerca>';
									|pl = '<Podwiersz do wyszukiwania>';
									|tr = '<Arama alt satırı>'");
	StructureToInsert = StringFunctionsClientServer.SubstituteParametersToString(
		"StrFind(%1, %2)",
		ParameterPresentation1,
		ParameterPresentation2);
	Presentation = NStr("vi = 'Tìm kiếm cụm từ';
						|ru = 'Найти подстроку';
						|en = 'Find substring'; fa = 'Find substring';
						|it = 'Trovare sottoriga';
						|pl = 'Znajdź podwiersz';
						|tr = 'Alt satırı bul'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, Id, StructureToInsert, Presentation,, 1);
	
	Id = "StrCompare";
	ParameterPresentation1 = NStr("vi = '<Xâu ký tự 1>';
									|ru = '<Строка 1>';
									|en = '<String 1>'; fa = '<String 1>';
									|it = '<Riga 1>';
									|pl = '<Wiersz 1>';
									|tr = '<Satır 1>'");
	ParameterPresentation2 = NStr("vi = '<Xâu ký tự 2>';
									|ru = '<Строка 2>';
									|en = '<String 2>'; fa = '<String 2>';
									|it = '<Riga 2>';
									|pl = '<Wiersz 2>';
									|tr = '<Satır 2>'");
	StructureToInsert = StringFunctionsClientServer.SubstituteParametersToString(
		"StrCompare(%1, %2)",
		ParameterPresentation1,
		ParameterPresentation2);
	Presentation = NStr("vi = 'So sánh các dòng';
						|ru = 'Сравнить строки';
						|en = 'Compare strings'; fa = 'Compare strings';
						|it = 'Confrontare righe';
						|pl = 'Porównaj wiersze';
						|tr = 'Satırları karşılaştır'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, Id, StructureToInsert, Presentation,, 1);
	
	Id = "Upper";
	StructureToInsert = "Upper()";
	Presentation = NStr("vi = 'Biểu ghi phía trên';
						|ru = 'Верхний регистр';
						|en = 'Uppercase'; fa = 'Uppercase';
						|it = 'Maiuscolo';
						|pl = 'Rejestr górny';
						|tr = 'Üst kayıt'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, Id, StructureToInsert, Presentation,, 1);
	
	Id = "Lower";
	StructureToInsert = "Lower()";
	Presentation = NStr("vi = 'Biểu ghi phía dưới';
						|ru = 'Нижний регистр';
						|en = 'Lowercase'; fa = 'Lowercase';
						|it = 'Minuscolo';
						|pl = 'Rejestr dolny';
						|tr = 'Küçük harf'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, Id, StructureToInsert, Presentation,, 1);
	
	GroupPresentation = NStr("vi = 'Các hàm làm việc với ngày tháng';
							|ru = 'Функции по работе с датами';
							|en = 'Functions for operations with dates'; fa = 'Functions for operations with dates';
							|it = 'Funzioni del lavoro con le date';
							|pl = 'Funkcje do pracy z datami';
							|tr = 'Tarihlerle çalışma fonksiyonları'");
	OperatorsGroup = ProcessingOfFormulas.AddOperatorsGroup(Tree, "FunctionDates", GroupPresentation);
	
	Id = "Date";
	ParameterPresentation1 = NStr("vi = '<Năm>';
									|ru = '<Год>';
									|en = '<Year>'; fa = '<Year>';
									|it = '<Anno>';
									|pl = '<Rok>';
									|tr = '<Yıl>'");
	ParameterPresentation2 = NStr("vi = '<Tháng>';
									|ru = '<Месяц>';
									|en = '<Month>'; fa = '<Month>';
									|it = '<Mese>';
									|pl = '<Miesiąc>';
									|tr = '<Ay>'");
	ParameterPresentation3 = NStr("vi = '<Ngày>';
									|ru = '<День>';
									|en = '<Day>'; fa = '<Day>';
									|it = '<Giorno>';
									|pl = '<Dzień>';
									|tr = '<Gün>'");
	StructureToInsert = StringFunctionsClientServer.SubstituteParametersToString(
		"Date(%1, %2, %3)",
		ParameterPresentation1,
		ParameterPresentation2,
		ParameterPresentation3);
	Presentation =  NStr("vi = 'Ngày';
						|ru = 'Дата';
						|en = 'Date'; fa = 'تاریخ';
						|it = 'Data';
						|pl = 'Data';
						|tr = 'Tarih'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, Id, StructureToInsert, Presentation,, 1);
	
	Id = "CurrentDate";
	StructureToInsert = "CurrentDate()";
	Presentation = NStr("vi = 'Ngày hiện tại';
						|ru = 'Текущая дата';
						|en = 'Current date'; fa = 'تاریخ فعلی';
						|it = 'Data corrente';
						|pl = 'Bieżąca data';
						|tr = 'Geçerli tarih'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, Id, StructureToInsert, Presentation,, 1);
	
	Id = "Day";
	StructureToInsert = "Day()";
	Presentation = NStr("vi = 'Ngày';
						|ru = 'День';
						|en = 'Day'; fa = 'روز';
						|it = 'Giorno';
						|pl = 'Dzień';
						|tr = 'Gün'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, Id, StructureToInsert, Presentation,, 1);
	
	Id = "Month";
	StructureToInsert = "Month()";
	Presentation = NStr("vi = 'Tháng';
						|ru = 'Месяц';
						|en = 'Month'; fa = 'ماه';
						|it = 'Mese';
						|pl = 'Miesiąc';
						|tr = 'Ay'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, Id, StructureToInsert, Presentation,, 1);
	
	Id = "Year";
	StructureToInsert = "Year()";
	Presentation = NStr("vi = 'Năm';
						|ru = 'Год';
						|en = 'Year'; fa = 'سال';
						|it = 'Anno';
						|pl = 'Rok';
						|tr = 'yıl'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, Id, StructureToInsert, Presentation,, 1);
	
	Id = "BegOfDay";
	StructureToInsert = "BegOfDay()";
	Presentation = NStr("vi = 'Đầu ngày';
						|ru = 'Начало дня';
						|en = 'Day start'; fa = 'شروع روز';
						|it = 'Inizio giorno';
						|pl = 'Początek dnia';
						|tr = 'Gün başlangıcı'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, Id, StructureToInsert, Presentation,, 1);
	
	Id = "BegOfMonth";
	StructureToInsert = "BegOfMonth()";
	Presentation = NStr("vi = 'Đầu tháng';
						|ru = 'Начало месяца';
						|en = 'Month beginning'; fa = 'ابتدای ماه';
						|it = 'Inizio del mese';
						|pl = 'Początek miesiąca';
						|tr = 'Ay başlangıcı'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, Id, StructureToInsert, Presentation,, 1);
	
	Id = "BegOfYear";
	StructureToInsert = "BegOfYear()";
	Presentation = NStr("vi = 'Đầu năm';
						|ru = 'Начало года';
						|en = 'Beginning of the year'; fa = 'ابتدای سال';
						|it = 'Inizio dell''anno';
						|pl = 'Początek roku';
						|tr = 'Yıl başlangıcı'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, Id, StructureToInsert, Presentation,, 1);
	
	Id = "EndOfDay";
	StructureToInsert = "EndOfDay()";
	Presentation = NStr("vi = 'Cuối ngày';
						|ru = 'Конец дня';
						|en = 'Day end'; fa = 'Day end';
						|it = 'Fine del giorno';
						|pl = 'Koniec dnia';
						|tr = 'Gün sonu'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, Id, StructureToInsert, Presentation,, 1);
	
	Id = "EndOfMonth";
	StructureToInsert = "EndOfMonth()";
	Presentation = NStr("vi = 'Cuối tháng';
						|ru = 'Конец месяца';
						|en = 'End of the month'; fa = 'End of the month';
						|it = 'Fine mese';
						|pl = 'Koniec miesiąca';
						|tr = 'Ay sonu'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, Id, StructureToInsert, Presentation,, 1);
	
	Id = "EndOfYear";
	StructureToInsert = "EndOfYear()";
	Presentation = NStr("vi = 'Cuối năm';
						|ru = 'Конец года';
						|en = 'End of the year'; fa = 'پایان سال';
						|it = 'Fine dell''anno';
						|pl = 'Koniec roku';
						|tr = 'Yıl sonu'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, Id, StructureToInsert, Presentation,, 1);
	
	GroupName = "OtherFunctions";
	GroupPresentation = NStr("vi = 'Chức năng khác';
							|ru = 'Прочие функции';
							|en = 'Other functions'; fa = 'Other functions';
							|it = 'Altre funzioni';
							|pl = 'Inne funkcje';
							|tr = 'Diğer fonksiyonlar'");
	OperatorsGroup = ProcessingOfFormulas.AddOperatorsGroup(Tree, GroupName, GroupPresentation);
	
	Id = "?";
	ParameterPresentation1 = NStr("vi = '<Biểu thức lô-gic>';
									|ru = '<Логическое выражение>';
									|en = '<Logical expression>'; fa = '<Logical expression>';
									|it = '<Espressione logica>';
									|pl = '<Wyrażenie logiczne>';
									|tr = '<Mantıksal ifade>'");
	ParameterPresentation2 = NStr("vi = '<Giá trị nếu kết quả điều kiện là đúng>';
									|ru = '<Значение если результат условия истина>';
									|en = '<Value if the condition result is true>'; fa = '<Value if the condition result is true>';
									|it = '<Valore se il risultato della condizione è vero>';
									|pl = '<Wartość, jeśli wynik warunku prawda>';
									|tr = '<Koşul sonucu doğru ise değer>'");
	ParameterPresentation3 = NStr("vi = '<Giá trị nếu kết quả điều kiện là sai>';
									|ru = '<Значение если результат условия ложь>';
									|en = '<Value if the condition result is false>'; fa = '<Value if the condition result is false>';
									|it = '<Valore se il risultato della condizione è falso>';
									|pl = '<Wartość, jeśli wynik warunku fałsz>';
									|tr = '<Koşul sonucu yanlış ise değer>'");
	StructureToInsert = StringFunctionsClientServer.SubstituteParametersToString(
		"?(%1, %2, %3)",
		ParameterPresentation1,
		ParameterPresentation2,
		ParameterPresentation3);
	Presentation = NStr("vi = 'Điều kiện';
						|ru = 'Условие';
						|en = 'Condition'; fa = 'شرط';
						|it = 'Condizione';
						|pl = 'Warunek';
						|tr = 'Koşul'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, Id, StructureToInsert, Presentation,, 3);
	
	FunctionDescription = ProductDataManagementClientServer.DescriptionOfFormulaConstructorFunctions(GroupName);
	
	For Each LongDesc In FunctionDescription Do
		
		ProcessingOfFormulas.AddOperator(OperatorsGroup,
			LongDesc.Id,
			LongDesc.StructureToInsert,
			LongDesc.Presentation,
			LongDesc.Explanation);
		
	EndDo;
	
	Return Tree;
	
EndFunction

// Returns a table of parameters for calculating using formulas
//
// Parameters:
//  LongDesc - see the description of the sourcesreferences
//  DataSet	 - Array	 - a set of algorithms for calculating formulas.
// 
// Returns:
//  ValueTable - parameters for calculation by formulas containing:
//  	* ParameterName - String - parameter name
//  	* Key - String - the key parameter
//  	* LineNumber - Number - Line number
//  	* PropertyName - String - property name
//  	* RowData - Structure - line data, from:
//  		** LineNumber - Number - Line number
//  	* Found - Boolean - indicates that the value was found
//  	* Value - Number - parameter value
//
Function ParametersForCalculationByFormulas(LongDesc, DataSet) Export
	
	If Not ValueIsFilled(DataSet) Then
		Return Undefined;
	EndIf;
	
	Parameters = New ValueTable;
	Parameters.Columns.Add("ParameterName");
	Parameters.Columns.Add("Key");
	Parameters.Columns.Add("LineNumber");
	Parameters.Columns.Add("PropertyName");
	Parameters.Columns.Add("RowData");
	Parameters.Columns.Add("Found");
	Parameters.Columns.Add("Value");
	
	For Each RowsArray In DataSet Do
		For Each RowData In RowsArray Do
			If IsBlankString(RowData.QuantityCalculationAlgorithm) Then
				RowData.Formula = "";
			Else
				RowData.Formula = FormulaTranslator(RowData, Parameters, LongDesc);
			EndIf;
		EndDo;
	EndDo;
	
	Parameters.Indexes.Add("Key");
	Parameters.Indexes.Add("ParameterName");
	
	Return Parameters;
	
EndFunction

// Returns parameter values for calculation using formulas
//
// Parameters:
//  Manager			 - CatalogsManager	 - the directory Manager
//  ParametersForCalculation	 - See ParametersForCalculationByFormulas
//  DescriptionOfSources	 - See Catalogs.BillsOfMaterials.DescriptionOfOperandDataSources
//  DataSources		 - Structure  - used when retrieving source data in the Manager.
// 
// Returns:
//  Structure - From:
//  	* Parameters - Structure - Parameters
//  	* AutoCalculation - Map - lines for automatic calculation
//
Function DataForCalculationByFormulas(Manager, ParametersForCalculation, DescriptionOfSources, DataSources) Export

	DataForCalculation = New Structure("Parameters,AutoCalculation", New Structure, New Map);
	
	For Each DataPath In ParametersForCalculation Do
		
		If DataPath.Found = True Then
			AddParameterToDataForCalculation(DataForCalculation, DataPath.ParameterName, DataPath.Value);
			Continue;
		EndIf;
		
		LongDesc = Undefined;
		If IsBlankString(DataPath.Key)
			Or Not DescriptionOfSources.Property(DataPath.Key, LongDesc) Then
			Continue;
		EndIf;
		
		Source = Manager.DataSourceForFormulaCalculations(DataPath, DataSources);
		If Not ValueIsFilled(Source) Then
			Continue;
		EndIf;
		
		If DataPathContainsSourceDetails(DataPath, LongDesc) Then
			
			AddParameterToDataForCalculation(
				DataForCalculation,
				DataPath.ParameterName,
				Source[DataPath.PropertyName],
				ParametersForCalculation);
			AddMatchForAutoCalculation(DataForCalculation, DataPath, Source);
			
		EndIf;
		
	EndDo;
	
	For Each String In ParametersForCalculation.FindRows(New Structure("Found")) Do
		AddParameterToDataForCalculation(DataForCalculation,String.ParameterName);
	EndDo;
	
	Return DataForCalculation;
	
EndFunction

// Calculates the number in a row using the formulas
//
// Parameters:
//  String			 - ValueTableRow - Current line
//  DataForCalculation - See DataForCalculationByFormulas
//  FieldName			 - String				 - name of the field in the string.
// 
// Returns:
//  Boolean - the quantity is calculated.
//
Function CalculateQuantityUsingFormula(String, DataForCalculation, FieldName = "Count") Export
	
	Parameters = CommonClientServer.StructureProperty(DataForCalculation, "Parameters");
	
	Try
		
		String[FieldName] = Common.CalculateInSafeMode(String.Formula, Parameters);
		
	Except
		
		String[FieldName] = 0;
		
		EventLogEvent = ProductionServer.EventCalculationOfQuantityByFormula();
		ErrorInfo = ErrorInfo();
		
		MessageText = StrTemplate(
			NStr("vi = 'Không thể tính công thức: ""%1""
			|do nguyên nhân: %2';
			|ru = 'Не удалось рассчитать формулу: ""%1""
			|по причине: %2';
			|en = 'Cannot calculate formula: ""%1"".
			|Reason: %2'; fa = 'Cannot calculate formula: ""%1"".
			|Reason: %2';
			|it = 'Non è stato possibile calcolare la formula: ""%1""
			| a causa di: %2';
			|pl = 'Nie udało się obliczyć formuły: ""%1""
			|z powodu: %2';
			|tr = 'Formül hesaplanamadı: ""%1""
			| çünkü: %2'"),
			String.QuantityCalculationAlgorithm,
			ErrorProcessing.DetailErrorDescription(ErrorInfo));
		
		WriteLogEvent(
			EventLogEvent,
			EventLogLevel.Error,,,
			MessageText);
			
		String.FormulaCalculationError = ErrorProcessing.BriefErrorDescription(ErrorInfo);
			
		Return False;
		
	EndTry;
	
	If DataForCalculation <> Undefined Then
		UpdateAutoCalculationData(String, DataForCalculation, FieldName);
	EndIf;
	
	Return True;
	
EndFunction

// Checks the algorithm for calculating the number by comparing it with the set of available operands.
//
// Parameters:
//  Object - CatalogObject.BillsOfMaterials, CatalogObject.RouteSheets - object being checked
//  DescriptionOfSources	 - See Catalogs.BillsOfMaterials.DescriptionOfOperandDataSources
//  CheckParameters	 - Structure - object verification structure:
//   * Content             - Array    - list of table parts to check (list of structures containing the keys <Name>, <View>)
//   * OutputMessages  - Boolean    - True if you want to display error messages
//   * ClearNotFound - Boolean    - The truth is, if you want to clear the formula contains the missing operands
//  Cancel				 - Boolean - the output parameter that is set to True when an error occurs.
// 
// Returns:
//  Map - list of errors (row numbers of table parts containing errors).
//
Function CheckClearQuantityCalculationAlgorithm(Object, DescriptionOfSources, CheckParameters, Cancel = False) Export
	
	Result = New Map;
	Template = NStr("vi = 'Thuật toán tính toán số lượng chứa các toán hạng không thể truy cập (danh sách ""%1"", dòng %2).';
					|ru = 'Алгоритм расчета количества содержит недоступные операнды (список ""%1"", строка %2).';
					|en = 'Quantity calculation algorithm contains unavailable operands (see line %2 of the ""%1"" list).'; fa = 'Quantity calculation algorithm contains unavailable operands (see line %2 of the ""%1"" list).';
					|it = 'L''algoritmo di calcolo della quantità contiene degli operandi non disponibili (elenco ""%1"", riga %2).';
					|pl = 'Algorytm obliczania ilości zawiera niedostępne operandy (lista ""%1"", wiersz %2).';
					|tr = 'Miktar hesaplama algoritması mevcut olmayan işlenenleri içermektedir (""%1"" listesi, %2 satırı).'");
	
	For Each CheckStructure In CheckParameters.Content Do
		
		Table = TMCommonUse.ExportValuesTable(Object[CheckStructure.TSName],, "LineNumber,QuantityCalculationAlgorithm", New Structure("Formula", ""));
		DataSet = New Array;
		DataSet.Add(Table);
		Result.Insert(CheckStructure.TSName, New Array());
		
		ParametersForCalculation = ParametersForCalculationByFormulas(DescriptionOfSources, DataSet);
		
		For Each Parameter In ParametersForCalculation Do
			
			Parameter.Found = False;
			LineNumber = Parameter.RowData.LineNumber;
			
			If Result[CheckStructure.TSName].Find(LineNumber) <> Undefined Then
				Continue; // the error has already been found in this line
			EndIf;
			
			SourceDetails = Undefined; // See ProductDataManagement.CreateDescriptionsOfOperandDataSource
			If ValueIsFilled(Parameter.Key) And DescriptionOfSources.Property(Parameter.Key, SourceDetails) Then
				
				OperandsTable = Undefined;
				ParameterLineNumber = Parameter.LineNumber;
				ParameterKey = Parameter.Key;
				
				If Not IsBlankString(SourceDetails.TSName) 
					And DescriptionOfSources.Property(SourceDetails.TSName, SourceDetails) 
					And SourceDetails.Property("Operands") Then
						OperandsTable = SourceDetails.Operands.Copy(New Structure("LineNumber", LineNumber));
						ParameterLineNumber = LineNumber;
						ParameterKey = SourceDetails.Id;
				Else
					SourceDetails.Property("Operands", OperandsTable);
				EndIf;
				
				If ParameterLineNumber = Undefined Then
					Id = ParameterKey+"."+Parameter.PropertyName;
				Else
					Id = ParameterKey+"["+ParameterLineNumber+"]."+Parameter.PropertyName;
				EndIf;
				
				If ValueIsFilled(OperandsTable) Then
					Found = OperandsTable.Find(Id, "Id");
					If Found <> Undefined Then
						If CheckStructure.TSName = Parameter.Key Then
							If LineNumber > Parameter.LineNumber Then
								Parameter.Found = True;
							EndIf;
						Else
							Parameter.Found = True;
						EndIf;
					EndIf;
				EndIf;
				
			EndIf;
			
			If Not Parameter.Found Then
				
				If CheckParameters.OutputMessages Then
					
					MessageText = StrTemplate(Template, CheckStructure.Presentation, Format(LineNumber, "NG="));
					Field = CommonClientServer.PathToTabularSection(CheckStructure.TSName, LineNumber, CheckStructure.Attribute);
					
					Common.MessageToUser(
						MessageText,
						Object,
						Field,
						,
						Cancel);
					
				EndIf;
				
				If CheckParameters.ClearNotFound Then
					Object[CheckStructure.TSName][LineNumber-1].QuantityCalculationAlgorithm = "";
				EndIf;
				
				Result[CheckStructure.TSName].Add(LineNumber);
				
			EndIf;
				
		EndDo;
		
	EndDo;
	
	Return Result;
	
EndFunction

// Gets item properties that can be used in the formula constructor
//
// Parameters:
//  ItemKinds	 - Array - types of nomenclature.
// 
// Returns:
//  ValueTable - a set of properties that can be used in the formula constructor.
//
Function GetProductPropertiesToCalculateUsingFormulas(ItemKinds) Export
	
	QueryText = RequestTextAvailableProductProperties();
	Query = New Query(QueryText);
	
	Query.SetParameter("ItemKinds", ItemKinds);
	Query.SetParameter("Set_Catalog_Products_Overall", PropertyManager.PropertiesSetByName("Catalog_Products_Overall"));
	Query.SetParameter("Set_Catalog_ItemsCharacteristics_Overall", PropertyManager.PropertiesSetByName("Catalog_ItemsCharacteristics_Overall"));

	Result = Query.Execute().Unload();
	
	Result.Indexes.Add("Kind");
	
	Return Result;
	
EndFunction

// Gets properties that can be used in the formula constructor
//
// Parameters:
//  SetsList - Array - sets of additional details and information. 
// 
// Returns:
//  ValueTable - a set of properties that can be used in the formula constructor.
//
Function GetSourcePropertiesForCalculationUsingFormulas(SetsList) Export
	
	QueryText = RequestTextAvailableSourceProperties();
	Query = New Query(QueryText);
	
	Query.SetParameter("SetsList", SetsList);
	
	Result = Query.Execute().Unload();
	
	Result.Indexes.Add("Ref");
	
	Return Result;
	
EndFunction

#EndRegion

#Region SelectionByProperties

// Gets the properties to use in the audition
//
// Parameters:
//  ProductKind - CatalogRef.ItemKinds - Product kind
//  PropertySources - String - list of sources for which properties are obtained
//  OnlyValidOnes - Boolean - determines whether only active properties should be included in the selection
// 
// Returns:
//  ValueTable - properties for use in selections
//
Function GetPropertiesToSelectByProperties(ProductKind, PropertySources = "", OnlyValidOnes = True) Export
	
	If ValueIsFilled(PropertySources) Then
		ListOfSources = StrSplit(PropertySources, ",");
	Else
		ListOfSources = PropertySourcesForPropertySelection();
	EndIf;
	
	Query = New Query;
	Query.SetParameter("ItemKinds", ProductKind);
	Query.SetParameter("Set_Catalog_Products_Overall", PropertyManager.PropertiesSetByName("Catalog_Products_Overall"));
	Query.SetParameter("Set_Catalog_ItemsCharacteristics_Overall", PropertyManager.PropertiesSetByName("Catalog_ItemsCharacteristics_Overall"));
	
	QueriesTexts = New Array;
	
	QueriesTexts.Add(
		RequestTextAvailableProductProperties(
			OnlyValidOnes,
			ListOfSources.Find("Products") <> Undefined,
			ListOfSources.Find("Characteristic") <> Undefined));
	
	If ListOfSources.Find("LineOfBusiness") <> Undefined
		And GetFunctionalOption("GenerateFinancialResult") Then
			
		QueriesTexts.Add(RequestTextAvailableSourceProperties(OnlyValidOnes));
		
		Query.SetParameter("SetsList", PropertyManager.PropertiesSetByName("Catalog_LinesOfBusiness"));
		
	EndIf;
	
	Query.Text = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
	
	QueryResults = Query.ExecuteBatch();
	
	Result = QueryResults[0].Unload();
	
	For IndexOf = 1 To QueryResults.UBound() Do
		Selection = QueryResults[IndexOf].Select();
		While Selection.Next() Do
			FillPropertyValues(Result.Add(), Selection);
		EndDo;
	EndDo;
	
	Result.GroupBy("Property,ValueType,Presentation");
	
	Return Result;
	
EndFunction

#EndRegion

#Region Other

// Sets the conditional design of the specification form and route map
//  associated with the automatic selection of the item.
//
// Parameters:
//  Form      - ClientApplicationForm - form of a specification or route map.
//  ObjectName - String           - name of the form object
//  TableName - String           - Name of the form element
//
Procedure SetConditionalAppearanceForAutoSelectingProducts(Form, ObjectName, TableName) Export
	
	ConditionalAppearance = Form.ConditionalAppearance;
	Items = Form.Items;
	
	MatchingElements = MatchingElementsOfTablePartsWithParameterization(TableName);
	
	// Nomenclature - Mark of the filled
	Item = ConditionalAppearance.Items.Add(); 
	Item.Use = True;
	
	TSName           = StrReplace(Items[TableName].DataPath,ObjectName+".","");
	ObjectNameTSName = ObjectName+"."+TSName;
	
	FilterDesignFeatures = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterDesignFeatures.Use  = True;
	FilterDesignFeatures.LeftValue  = New DataCompositionField(ObjectNameTSName+".MethodOfProductsAutoselection");
	FilterDesignFeatures.ComparisonType   = DataCompositionComparisonType.NotEqual;
	FilterDesignFeatures.RightValue = Enums.MethodsOfProductAutoSelection.SpecifiedInMasterData;
	
	FilterDesignFeatures = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterDesignFeatures.Use  = True;
	FilterDesignFeatures.LeftValue  = New DataCompositionField("UseBillOfMaterialsParameterization");
	FilterDesignFeatures.ComparisonType   = DataCompositionComparisonType.Equal;
	FilterDesignFeatures.RightValue = True;
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items[MatchingElements.Products].Name);
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	// Nomenclature by line - Display
	Item = ConditionalAppearance.Items.Add(); 
	Item.Use = True;
	
	GroupDesignSelection = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	GroupDesignSelection.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	FilterDesignFeatures = GroupDesignSelection.Items.Add(Type("DataCompositionFilterItem"));
	FilterDesignFeatures.Use  = True;
	FilterDesignFeatures.LeftValue  = New DataCompositionField("UseBillOfMaterialsParameterization");
	FilterDesignFeatures.ComparisonType   = DataCompositionComparisonType.Equal;
	FilterDesignFeatures.RightValue = False;
	
	GroupDesignSelection = GroupDesignSelection.Items.Add(Type("DataCompositionFilterItemGroup"));
	GroupDesignSelection.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	FilterDesignFeatures = GroupDesignSelection.Items.Add(Type("DataCompositionFilterItem"));
	FilterDesignFeatures.Use  = True;
	FilterDesignFeatures.LeftValue  = New DataCompositionField(ObjectNameTSName+".MethodOfProductsAutoselection");
	FilterDesignFeatures.ComparisonType   = DataCompositionComparisonType.NotEqual;
	FilterDesignFeatures.RightValue = Enums.MethodsOfProductAutoSelection.SpecifiedInProductsProperty;
	
	FilterDesignFeatures = GroupDesignSelection.Items.Add(Type("DataCompositionFilterItem"));
	FilterDesignFeatures.Use  = True;
	FilterDesignFeatures.LeftValue  = New DataCompositionField(ObjectNameTSName+".MethodOfProductsAutoselection");
	FilterDesignFeatures.ComparisonType   = DataCompositionComparisonType.NotEqual;
	FilterDesignFeatures.RightValue = Enums.MethodsOfProductAutoSelection.SpecifiedInProductionProcess;
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items[MatchingElements.ProductsAsAString].Name);
	
	Item.Appearance.SetParameterValue("Show", False);
	
	// Nomenclatureline - Text Color
	Item = ConditionalAppearance.Items.Add(); 
	Item.Use = True;
	
	GroupDesignSelection = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	GroupDesignSelection.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	FilterDesignFeatures = GroupDesignSelection.Items.Add(Type("DataCompositionFilterItem"));
	FilterDesignFeatures.Use  = True;
	FilterDesignFeatures.LeftValue  = New DataCompositionField(ObjectNameTSName+".MethodOfProductsAutoselection");
	FilterDesignFeatures.ComparisonType   = DataCompositionComparisonType.Equal;
	FilterDesignFeatures.RightValue = Enums.MethodsOfProductAutoSelection.SpecifiedInProductsProperty;
	
	FilterDesignFeatures = GroupDesignSelection.Items.Add(Type("DataCompositionFilterItem"));
	FilterDesignFeatures.Use  = True;
	FilterDesignFeatures.LeftValue  = New DataCompositionField(ObjectNameTSName+".MethodOfProductsAutoselection");
	FilterDesignFeatures.ComparisonType   = DataCompositionComparisonType.Equal;
	FilterDesignFeatures.RightValue = Enums.MethodsOfProductAutoSelection.SpecifiedInProductionProcess;
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items[MatchingElements.ProductsAsAString].Name);
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.NoteText);
	
	// Characteristic - Text
	Item = ConditionalAppearance.Items.Add();
	Item.Use = True;
	
	FilterDesignFeatures = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterDesignFeatures.Use  = True;
	FilterDesignFeatures.LeftValue  = New DataCompositionField(ObjectNameTSName+".ItemVariantsAreUsed");
	FilterDesignFeatures.ComparisonType   = DataCompositionComparisonType.Equal;
	FilterDesignFeatures.RightValue = False;
	
	GroupDesignSelection = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	GroupDesignSelection.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	FilterDesignFeatures = GroupDesignSelection.Items.Add(Type("DataCompositionFilterItem"));
	FilterDesignFeatures.Use  = True;
	FilterDesignFeatures.LeftValue  = New DataCompositionField("UseBillOfMaterialsParameterization");
	FilterDesignFeatures.ComparisonType   = DataCompositionComparisonType.Equal;
	FilterDesignFeatures.RightValue = False;
	
	FilterDesignFeatures = GroupDesignSelection.Items.Add(Type("DataCompositionFilterItem"));
	FilterDesignFeatures.Use  = True;
	FilterDesignFeatures.LeftValue  = New DataCompositionField(ObjectNameTSName+".MethodOfItemVariantAutoselection");
	FilterDesignFeatures.ComparisonType   = DataCompositionComparisonType.Equal;
	FilterDesignFeatures.RightValue = Enums.MethodsOfItemVariantAutoselection.SpecifiedInMasterData;
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items[MatchingElements.Characteristic].Name);
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không sử dụng đặc tính>';
													|ru = '<характеристики не используются>';
													|en = '<variants are not used>'; fa = '<گونه‌ها استفاده نمی‌شوند>';
													|it = '<le caratteristiche non vengono usate>';
													|pl = '<charakterystyki nie dotyczą>';
													|tr = '<varyantlar kullanılmamaktadır>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	
	// Characteristic - Only inspection
	Item = ConditionalAppearance.Items.Add(); 
	Item.Use = True;
	
	FilterDesignFeatures = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterDesignFeatures.Use  = True;
	FilterDesignFeatures.LeftValue  = New DataCompositionField(ObjectNameTSName+".ItemVariantsAreUsed");
	FilterDesignFeatures.ComparisonType   = DataCompositionComparisonType.Equal;
	FilterDesignFeatures.RightValue = False;
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items[MatchingElements.Characteristic].Name);
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	// Characteristic - Mark of the filled
	Item = ConditionalAppearance.Items.Add(); 
	Item.Use = True;
	
	GroupDesignSelection = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	GroupDesignSelection.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	FilterDesignFeatures = GroupDesignSelection.Items.Add(Type("DataCompositionFilterItem"));
	FilterDesignFeatures.Use  = True;
	FilterDesignFeatures.LeftValue  = New DataCompositionField(ObjectNameTSName+".ItemVariantsAreUsed");
	FilterDesignFeatures.ComparisonType   = DataCompositionComparisonType.Equal;
	FilterDesignFeatures.RightValue = False;
	
	GroupDesignSelection = GroupDesignSelection.Items.Add(Type("DataCompositionFilterItemGroup"));
	GroupDesignSelection.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	FilterDesignFeatures = GroupDesignSelection.Items.Add(Type("DataCompositionFilterItem"));
	FilterDesignFeatures.Use  = True;
	FilterDesignFeatures.LeftValue  = New DataCompositionField("UseBillOfMaterialsParameterization");
	FilterDesignFeatures.ComparisonType   = DataCompositionComparisonType.Equal;
	FilterDesignFeatures.RightValue = True;
	
	FilterDesignFeatures = GroupDesignSelection.Items.Add(Type("DataCompositionFilterItem"));
	FilterDesignFeatures.Use  = True;
	FilterDesignFeatures.LeftValue  = New DataCompositionField(ObjectNameTSName+".MethodOfItemVariantAutoselection");
	FilterDesignFeatures.ComparisonType   = DataCompositionComparisonType.NotEqual;
	FilterDesignFeatures.RightValue = Enums.MethodsOfItemVariantAutoselection.SpecifiedInMasterData;
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items[MatchingElements.Characteristic].Name);
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	// The characteristic of the line is to display
	Item = ConditionalAppearance.Items.Add(); 
	Item.Use = True;
	
	GroupDesignSelection = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	GroupDesignSelection.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	FilterDesignFeatures = GroupDesignSelection.Items.Add(Type("DataCompositionFilterItem"));
	FilterDesignFeatures.Use  = True;
	FilterDesignFeatures.LeftValue  = New DataCompositionField("UseBillOfMaterialsParameterization");
	FilterDesignFeatures.ComparisonType   = DataCompositionComparisonType.Equal;
	FilterDesignFeatures.RightValue = False;
	
	GroupDesignSelection = GroupDesignSelection.Items.Add(Type("DataCompositionFilterItemGroup"));
	GroupDesignSelection.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	FilterDesignFeatures = GroupDesignSelection.Items.Add(Type("DataCompositionFilterItem"));
	FilterDesignFeatures.Use  = True;
	FilterDesignFeatures.LeftValue  = New DataCompositionField(ObjectNameTSName+".MethodOfItemVariantAutoselection");
	FilterDesignFeatures.ComparisonType   = DataCompositionComparisonType.NotEqual;
	FilterDesignFeatures.RightValue = Enums.MethodsOfItemVariantAutoselection.AutomaticallySelectedByProductsProperties;
	
	FilterDesignFeatures = GroupDesignSelection.Items.Add(Type("DataCompositionFilterItem"));
	FilterDesignFeatures.Use  = True;
	FilterDesignFeatures.LeftValue  = New DataCompositionField(ObjectNameTSName+".MethodOfItemVariantAutoselection");
	FilterDesignFeatures.ComparisonType   = DataCompositionComparisonType.NotEqual;
	FilterDesignFeatures.RightValue = Enums.MethodsOfItemVariantAutoselection.PickedByAlgorithm;
	
	FilterDesignFeatures = GroupDesignSelection.Items.Add(Type("DataCompositionFilterItem"));
	FilterDesignFeatures.Use  = True;
	FilterDesignFeatures.LeftValue  = New DataCompositionField(ObjectNameTSName+".MethodOfItemVariantAutoselection");
	FilterDesignFeatures.ComparisonType   = DataCompositionComparisonType.NotEqual;
	FilterDesignFeatures.RightValue = Enums.MethodsOfItemVariantAutoselection.SpecifiedInProductionProcess;
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items[MatchingElements.CharacteristicAsAString].Name);
	
	Item.Appearance.SetParameterValue("Show", False);

	// Characterization of the text - color line
	Item = ConditionalAppearance.Items.Add(); 
	Item.Use = True;
	
	GroupDesignSelection = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	GroupDesignSelection.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	FilterDesignFeatures = GroupDesignSelection.Items.Add(Type("DataCompositionFilterItem"));
	FilterDesignFeatures.Use  = True;
	FilterDesignFeatures.LeftValue  = New DataCompositionField(ObjectNameTSName+".MethodOfItemVariantAutoselection");
	FilterDesignFeatures.ComparisonType   = DataCompositionComparisonType.Equal;
	FilterDesignFeatures.RightValue = Enums.MethodsOfItemVariantAutoselection.AutomaticallySelectedByProductsProperties;
	
	FilterDesignFeatures = GroupDesignSelection.Items.Add(Type("DataCompositionFilterItem"));
	FilterDesignFeatures.Use  = True;
	FilterDesignFeatures.LeftValue  = New DataCompositionField(ObjectNameTSName+".MethodOfItemVariantAutoselection");
	FilterDesignFeatures.ComparisonType   = DataCompositionComparisonType.Equal;
	FilterDesignFeatures.RightValue = Enums.MethodsOfItemVariantAutoselection.PickedByAlgorithm;
	
	FilterDesignFeatures = GroupDesignSelection.Items.Add(Type("DataCompositionFilterItem"));
	FilterDesignFeatures.Use  = True;
	FilterDesignFeatures.LeftValue  = New DataCompositionField(ObjectNameTSName+".MethodOfItemVariantAutoselection");
	FilterDesignFeatures.ComparisonType   = DataCompositionComparisonType.Equal;
	FilterDesignFeatures.RightValue = Enums.MethodsOfItemVariantAutoselection.SpecifiedInProductionProcess;
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items[MatchingElements.CharacteristicAsAString].Name);
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.NoteText);
	
EndProcedure

// Sets the conditional design of the specification form and route map
//  related to usage settings and quantity calculation.
//
// Parameters:
//  Form      - ClientApplicationForm - form of a specification or route map
//  ObjectName - String                     - name of the form object
//  TableName - String                     - name of the form table
//  ColumnName - String	                    - the name of the column <Number>.
//
Procedure EstablishConditionalAppearanceOfSelectionByPropertiesAndCalculationByFormulas(Form, ObjectName, TableName, ColumnName) Export

	TSName = StrReplace(Form.Items[TableName].DataPath,ObjectName+".","");

	ConditionalAppearance = Form.ConditionalAppearance;
	Items = Form.Items;
	
	Item = ConditionalAppearance.Items.Add();
	Item.Use = True;
	
	FilterDesignFeatures = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterDesignFeatures.Use  = True;
	
	If IsBlankString(ObjectName) Then
		FilterDesignFeatures.LeftValue = New DataCompositionField(TSName + ".CalculationByFormula");
	Else
		FilterDesignFeatures.LeftValue = New DataCompositionField(ObjectName + "." + TSName + ".CalculationByFormula");
	EndIf;
	
	FilterDesignFeatures.ComparisonType   = DataCompositionComparisonType.Equal;
	FilterDesignFeatures.RightValue = True;
	
	FilterDesignFeatures = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterDesignFeatures.Use  = True;
	FilterDesignFeatures.LeftValue  = New DataCompositionField("UseBillOfMaterialsParameterization");
	FilterDesignFeatures.ComparisonType   = DataCompositionComparisonType.Equal;
	FilterDesignFeatures.RightValue = True;
	
	MatchingElements = MatchingElementsOfTablePartsWithParameterization(TableName);
	
	FormField = Items[MatchingElements[ColumnName]]; // FormField
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FormField.Name);
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<theo công thức>';
													|ru = '<по формуле>';
													|en = '<using formula>'; fa = '<using formula>';
													|it = '<secondo la formula>';
													|pl = '<wg formuły>';
													|tr = '<formüle göre>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.NoteText);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
EndProcedure

// Fills in the details of the table part related to the auto-selection and quantity calculation settings.
//
// Parameters:
//  TabularSection		 - TabularSection	 - table part for which you need to fill in the service details
//  ThereIsAutoselection		 - Boolean			 - flag that uses auto-selection
//  ThereIsCalculationAccordingToFormula	 - Boolean			 - indicates whether the quantity is calculated using the formula.
//  SelectionByProperties     - ValueTable - a table containing the settings selection on properties
//
Procedure FillInServiceDetailsOfAutoSelectionAndCalculationOfNumber(TabularSection, ThereIsAutoselection, ThereIsCalculationAccordingToFormula, SelectionByProperties) Export
	
	Appearance = ProductDataManagementClientServer.DesignTextsForAutoSelectionMethods();
	
	For Each CurrentRow In TabularSection Do
		
		If ThereIsAutoselection Then
			
			If CurrentRow.MethodOfProductsAutoselection = Enums.MethodsOfProductAutoSelection.SpecifiedInProductsProperty Then
				PropertyHeader = Common.ObjectAttributeValue(CurrentRow.PropertyThatContainsProducts, "Title");
			Else
				PropertyHeader = "";
			EndIf;
			
			CurrentRow.ProductsAsAString   = StringFunctionsClientServer.SubstituteParametersToString(
														Appearance.Get(CurrentRow.MethodOfProductsAutoselection),
														PropertyHeader);
			CurrentRow.CharacteristicAsAString = Appearance.Get(CurrentRow.MethodOfItemVariantAutoselection);
			
		EndIf;
		
		If ThereIsCalculationAccordingToFormula Then
			
			If IsBlankString(CurrentRow.QuantityCalculationAlgorithm) Then
				CurrentRow.CalculationByFormula = False;
			Else
				CurrentRow.CalculationByFormula = True;
			EndIf;
			CurrentRow.FilterByPropertiesIsSet = SelectionByProperties.FindRows(New Structure("ConnectionKey", CurrentRow.ConnectionKey)).Count() > 0;
			
		EndIf;
		
	EndDo; 
	
EndProcedure

Function MatchingElementsOfTablePartsWithParameterization(TableName) Export
	
	Result = New Structure;
	
	If TableName = "ManufacturedProduct" Then
		
		Result.Insert("Products",          "ManufacturedProductProducts");
		Result.Insert("Characteristic",        "ManufacturedProductCharacteristic");
		Result.Insert("ProductsAsAString",   "ProductsItemByLine");
		Result.Insert("CharacteristicAsAString", "ProductsFeatureByLine");
		Result.Insert("NumberOfPackages",    "ManufacturedProductNumberOfPackages");
		
	ElsIf TableName = "ManufacturedProducts" Then
		
		Result.Insert("Products",          "ManufacturedProductsProducts");
		Result.Insert("Characteristic",        "ManufacturedProductsCharacteristic");
		Result.Insert("ProductsAsAString",   "ManufacturedProductsProductsAsAString");
		Result.Insert("CharacteristicAsAString", "ManufacturedProductsCharacteristicAsAString");
		Result.Insert("NumberOfPackages",    "ManufacturedProductsNumberOfPackages");
		
	ElsIf TableName = "RecyclableWaste" Then
		
		Result.Insert("Products",          "RecyclableWasteProducts");
		Result.Insert("Characteristic",        "RecyclableWasteCharacteristic");
		Result.Insert("ProductsAsAString",   "RecyclableWasteProductsAsAString");
		Result.Insert("CharacteristicAsAString", "RecyclableWasteCharacteristicAsAString");
		Result.Insert("NumberOfPackages",    "RecyclableWasteNumberOfPackages");
		
	ElsIf TableName = "MaterialsAndServices" Then
		
		Result.Insert("Products",          "MaterialsAndServicesProducts");
		Result.Insert("Characteristic",        "MaterialsAndServicesCharacteristic");
		Result.Insert("ProductsAsAString",   "MaterialsAndServicesProductsAsAString");
		Result.Insert("CharacteristicAsAString", "MaterialsAndServicesCharacteristicAsAString");
		Result.Insert("NumberOfPackages",    "MaterialsAndServicesNumberOfPackages");
		
	ElsIf TableName = "LaborCosts" Then
		
		Result.Insert("Count",            "LaborCostsCount");
		
	ElsIf TableName = "WorkCenterTypes" Then
		
		Result.Insert("OperationTime",           "WorkCenterTypesOperationTime");
		
	ElsIf TableName = "StageTypesOfWorkCenters" Then
		
		Result.Insert("OperationTime",           "StageTypesOfWorkCentersOperationTime");
		
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion

#EndRegion

#Region Private

#Region Specifications

#Region SpecificationsOfProducts

Function ListOfSpecificationsByProduct(ProductData, BOMSelectionParameters) Export
	
	SpecificationsData = BillsOfMaterial(ProductData, BOMSelectionParameters);
	
	Result = New Array;
	
	For Each SpecificationData In SpecificationsData Do
		Result.Add(SpecificationData.BillOfMaterials);
	EndDo;
	
	Return Result;
	
EndFunction

Function ListOfSpecificationsByProductList(ItemList, BOMSelectionParameters) Export
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	T.TheIndexOfTheData                            AS TheIndexOfTheData,
	|	T.Products                            AS Products,
	|	T.Characteristic                          AS Characteristic,
	|	BEGINOFPERIOD(T.ProductionStart, DAY) AS ProductionStart,
	|	T.ProductionDispatcherBusinessUnit                  AS ProductionDispatcherBusinessUnit,
	|	T.LineOfBusiness                 AS LineOfBusiness
	|INTO ItemList
	|FROM
	|	&ItemList AS T
	|;
	|
	|SELECT
	|	T.*,
	|	T.Products.ProductKind AS ProductKind
	|INTO TTListOfProducts
	|FROM
	|	ItemList AS T
	|
	|INDEX BY
	|	Products, Characteristic
	|;
	|
	|";
	Query.SetParameter("ItemList", ItemList);
	
	RequestTextParameters = ParametersOfRequestTextForManufacturedProductSpecifications();
	RequestTextParameters.OutputTableName = "TTSpecifications";
	
	Query.Text = Query.Text + RequestTextForProductItemsSpecifications(RequestTextParameters, BOMSelectionParameters) + "
	|
	|SELECT
	|	Specifications.BillOfMaterials AS BillOfMaterials
	|FROM
	|	TTSpecifications AS Specifications
	|
	|GROUP BY
	|	Specifications.BillOfMaterials
	|
	|HAVING
	|	COUNT(DISTINCT Specifications.TheIndexOfTheData) IN
	|		(SELECT
	|			COUNT(DISTINCT T.TheIndexOfTheData)
	|		FROM
	|			TTListOfProducts AS T)";
	
	SetParametersForRequestManufacturedProductSpecifications(Query, BOMSelectionParameters);
	
	Result = Query.Execute().Unload().UnloadColumn("BillOfMaterials");
	Return Result;
	
EndFunction

Function ProductDataTableForSpecificationSelection() Export
	
	Result = New ValueTable;
	
	Result.Columns.Add("TheIndexOfTheData",            New TypeDescription("Number", New NumberQualifiers(10)));
	Result.Columns.Add("Products",            New TypeDescription("CatalogRef.Products"));
	Result.Columns.Add("Characteristic",          New TypeDescription("CatalogRef.ItemsCharacteristics"));
	Result.Columns.Add("ProductionStart",      New TypeDescription("Date",,,New DateQualifiers(DateFractions.Date)));
	Result.Columns.Add("ProductionDispatcherBusinessUnit",  New TypeDescription("CatalogRef.BusinessStructure"));
	Result.Columns.Add("LineOfBusiness", New TypeDescription("CatalogRef.LinesOfBusiness"));
	
	Result.Columns.Add("UnderRepairProduct",   New TypeDescription("CatalogRef.Products"));
	Result.Columns.Add("UnderRepairVariant", New TypeDescription("CatalogRef.ItemsCharacteristics"));
	
	Return Result;
	
EndFunction

#EndRegion

#Region Sets

// This is a technological set.
// 
// Parameters:
//  Object - CatalogObject.BillsOfMaterials
// 
// Returns:
//  Boolean
Function ThisIsTechnologicalSet(Object) Export
	
	Result = False;
	If Not Object.AdditionalProperties.Property("ThisIsTechnologicalSet") Then
		
		ItemsType = Common.ObjectAttributeValue(Object.MainProductProductKind, "ItemsType");
		
		Object.AdditionalProperties.Insert("ThisIsTechnologicalSet", ItemsType = Enums.ItemsTypes.Set);
		
	EndIf;
	Result = Object.AdditionalProperties.ThisIsTechnologicalSet; // Boolean
	
	Return Result;
	
EndFunction

Function SetsOfMaterialsAndWorksDesigner() Export
	
	Result = New ValueTable;
	
	DataTypes = New Array;
	DataTypes.Add(Type("CatalogRef.BillsOfMaterials"));
	DataTypes.Add(Type("CatalogRef.ProductKitConfigurations"));
	
	Result.Columns.Add("ConnectionKey",             New TypeDescription("UUID"));
	Result.Columns.Add("BillOfMaterials",          New TypeDescription(DataTypes));
	Result.Columns.Add("ParentCommunicationKey",     New TypeDescription("UUID"));
	Result.Columns.Add("ParentSpecification",  New TypeDescription("CatalogRef.BillsOfMaterials"));
	Result.Columns.Add("RowsCount",       New TypeDescription("Number"));
	Result.Columns.Add("LinkKeyBOM", New TypeDescription("UUID"));
	
	Result.Columns.Add("Stage",                  New TypeDescription("CatalogRef.ProductionStages"));
	
	Return Result;
	
EndFunction

Procedure AdjustTableSetsOfMaterialsAndWorks(Table, LinkKeyString, Delta) Export
	
	If LinkKeyString = Undefined
		Or LinkKeyString = CommonClientServer.BlankUUID()
		Or Delta = 0 Then
		Return;
	EndIf;
	
	If TypeOf(LinkKeyString) = Type("UUID") Then
		FoundRows = Table.FindRows(New Structure("ConnectionKey", LinkKeyString));
		If FoundRows.Count() = 0 Then
			Return;
		EndIf;
		CurrentRow = FoundRows[0];
	Else
		CurrentRow = LinkKeyString;
	EndIf;
	
	CurrentRow.RowsCount = CurrentRow.RowsCount + Delta;
	AdjustTableSetsOfMaterialsAndWorks(
		Table, CurrentRow.ParentCommunicationKey, Delta);
	
	If Delta < 0 And CurrentRow.RowsCount = 0 Then
		Table.Delete(CurrentRow);
	EndIf;
	
EndProcedure

Procedure UpdateSetsOfMaterialsAndWorksTable(Object, SourceOfMaterials = "SupplyWithMaterialsAndWorks") Export
	
	Table = Object.MaterialsAndWorksSets;
	
	For Each String In Table Do
		String.RowsCount = 0;
	EndDo;
	
	UsedMaterials = Object[SourceOfMaterials];
	If TypeOf(UsedMaterials) = Type("ValueTable") Then
		KeyTable_ = UsedMaterials.Copy(,"CommunicationKeySet,Count");
	Else
		KeyTable_ = UsedMaterials.Unload(,"CommunicationKeySet,Count");
	EndIf;
	KeyTable_.FillValues(1, "Count");
	KeyTable_.GroupBy("CommunicationKeySet", "Count");
	
	For Each String In KeyTable_ Do
		AdjustTableSetsOfMaterialsAndWorks(
			Table,
			String.CommunicationKeySet,
			String.Count);
	EndDo;
	
	DeleteRows_ = Table.FindRows(New Structure("RowsCount", 0));
	For Each String In DeleteRows_ Do
		Table.Delete(String);
	EndDo;
	
EndProcedure

Function CompositionOfSetInProductionConstructor()
	
	Table = New ValueTable;
	
	Table.Columns.Add("LineNumber",    New TypeDescription("Number"));
	Table.Columns.Add("ConnectionKey",      New TypeDescription("UUID"));
	Table.Columns.Add("CommunicationKeySet", New TypeDescription("UUID"));
	
	Table.Columns.Add("ItemsType",            New TypeDescription("EnumRef.ItemsTypes"));
	Table.Columns.Add("Products",               New TypeDescription("CatalogRef.Products"));
	Table.Columns.Add("Characteristic",             New TypeDescription("CatalogRef.ItemsCharacteristics"));
	Table.Columns.Add("ItemVariantsAreUsed", New TypeDescription("Boolean"));
	
	Table.Columns.Add("Count",                 New TypeDescription("Number"));
	Table.Columns.Add("UnitOfMeasure",           New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
	Table.Columns.Add("PieceUnitOfMeasure",    New TypeDescription("Boolean"));
	Table.Columns.Add("NumberOfPackages",         New TypeDescription("Number"));
	Table.Columns.Add("Package",                   New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
	Table.Columns.Add("PackagingFactor",        New TypeDescription("Number"));
	Table.Columns.Add("PackageData");
	
	Table.Columns.Add("BillOfMaterials",          New TypeDescription("CatalogRef.BillsOfMaterials"));
	Table.Columns.Add("ProductCostElement",     New TypeDescription("CatalogRef.ProductCostElements"));
	
	Table.Columns.Add("UseAutoselection", New TypeDescription("Boolean"));
	Table.Columns.Add("AutoselectionDetails",    New TypeDescription("String"));
	
	Table.Columns.Add("MaterialApplication",   New TypeDescription("String"));
	Table.Columns.Add("Produced",          New TypeDescription("Boolean"));
	
	Table.Columns.Add("Department",         New TypeDescription("CatalogRef.BusinessStructure"));
	Table.Columns.Add("Warehouse",                 New TypeDescription("CatalogRef.Warehouses"));
	Table.Columns.Add("SupplyOption",    New TypeDescription("EnumRef.SupplyOptions"));
	Table.Columns.Add("WithAssignment",           New TypeDescription("Boolean"));
	
	Return Table;
	
EndFunction

Function ParametersForObtainingCompositionOfSetInProduction() Export
	
	Parameters = New Structure;
	
	Parameters.Insert("Products",             Catalogs.Products.EmptyRef());
	Parameters.Insert("Characteristic",           Catalogs.ItemsCharacteristics.EmptyRef());
	Parameters.Insert("BillOfMaterials",             Catalogs.BillsOfMaterials.EmptyRef());
	Parameters.Insert("ParentSpecification",     Catalogs.BillsOfMaterials.EmptyRef());
	Parameters.Insert("Count",               0);
	Parameters.Insert("ProductionDispatcherBusinessUnit",   Catalogs.BusinessStructure.EmptyRef());
	Parameters.Insert("AssigneeBusinessUnit", Catalogs.BusinessStructure.EmptyRef());
	Parameters.Insert("LineOfBusiness",  Catalogs.LinesOfBusiness.EmptyRef());
	Parameters.Insert("ProductionStart",       Date(1,1,1));
	Parameters.Insert("ReferenceOrder",             Documents.ProductionOrder2_2.EmptyRef());

	Parameters.Insert("ProductCostElement",        Catalogs.ProductCostElements.EmptyRef());
	
	Parameters.Insert("ConnectionKey",                New UUID());
	Parameters.Insert("CommunicationKeySet",           New UUID());
	
	Parameters.Insert("SourcesOfComposition",         New Array);
	
	Parameters.Insert("Product",                  Catalogs.Products.EmptyRef());
	Parameters.Insert("ItemVariantOfProduct",    Catalogs.ItemsCharacteristics.EmptyRef());
	Parameters.Insert("ProductSpecification",      Catalogs.BillsOfMaterials.EmptyRef());
	Parameters.Insert("ProductSpecificationStage",  Catalogs.ProductionStages.EmptyRef());
	
	Return Parameters;
	
EndFunction

Function CompositionOfSetInProduction(Parameters) Export
	
	Content                 = Undefined;
	MaterialsAndWorksSets = Undefined;
	CompositionSpecification    = Undefined;
	
	If ProductDataManagementCached.ItIsAvailableToStoreCompositionOfSetInSpecifications()
		And (Not ValueIsFilled(Parameters.SourcesOfComposition)
			Or Parameters.SourcesOfComposition.Find(Enums.SourcesOfCompositionOfSetsInProduction.Specifications) <> Undefined) Then
		
		CompositionSpecification = Parameters.BillOfMaterials;
		If Not ValueIsFilled(CompositionSpecification) Then
			
			ProductData = ProductDataManagementClientServer.ProductDataStructureForSpecificationSelection();
			FillPropertyValues(ProductData, Parameters);
			
			ResultOfSpecificationSelection = ProductDataManagementServerCall.ProductSpecification(
				ProductData,
				ProductDataManagementClientServer.ParametersForSelectingSpecificationsForManufacturingAssembly());
				
			If ValueIsFilled(ResultOfSpecificationSelection) Then
				CompositionSpecification = ResultOfSpecificationSelection.BillOfMaterials;
			EndIf;
			
		EndIf;
		
		If ValueIsFilled(CompositionSpecification) Then
			
			ItemData_3 = Catalogs.BillsOfMaterials.ProductData_5();
			FillPropertyValues(ItemData_3, Parameters);
			ItemData_3.Insert("BillOfMaterials",             CompositionSpecification);
			ItemData_3.Insert("AssigneeBusinessUnit", Parameters.AssigneeBusinessUnit);
			ItemData_3.Insert("Product",                  Parameters.Product);
			ItemData_3.Insert("ItemVariantOfProduct",    Parameters.ItemVariantOfProduct);
			ItemData_3.Insert("ProductSpecification",      Parameters.ProductSpecification);
			ItemData_3.Insert("ProductSpecificationStage",  Parameters.ProductSpecificationStage);
			
			SelectionParameters = Catalogs.BillsOfMaterials.DataSamplingParameters("MaterialsAndServices");

			SetSpecificationData = Catalogs.BillsOfMaterials.SpecificationDataByProducts(ItemData_3, SelectionParameters);
			
			Content = CompositionOfSetInProductionConstructor();
			For Each String In SetSpecificationData.MaterialsAndServices Do
				
				NewRow = Content.Add();
				FillPropertyValues(NewRow, String);
				
			EndDo;
			
			SetSpecificationData.Property("MaterialsAndWorksSets", MaterialsAndWorksSets);
			
		EndIf;
		
	EndIf;
	
	If ProductDataManagementCached.StorageOfCompositionOfSetIsAvailableInConfigurationOptions()
		And Content = Undefined
		And (Not ValueIsFilled(Parameters.SourcesOfComposition)
			Or Parameters.SourcesOfComposition.Find(Enums.SourcesOfCompositionOfSetsInProduction.KitConfigurations) <> Undefined) Then 
		
		ConfigurationOptionData = SetsServerCall.ProductConfigurationOptions(
			Parameters.Products, Parameters.Characteristic);
		If ValueIsFilled(ConfigurationOptionData) Then
			
			CompositionSpecification = ConfigurationOptionData.ItemKitConfiguration;
			
			Content = CompositionOfSetInProductionConstructor();
			For Each String In ConfigurationOptionData.Components Do
				
				NewRow = Content.Add();
				FillPropertyValues(NewRow, String);
				NewRow.Count = NewRow.Count * Parameters.Count;
				NewRow.NumberOfPackages = NewRow.NumberOfPackages * Parameters.Count;
				
			EndDo;
			
			PerformDirectiveSubstitutionsInDataSet(Content, Parameters);
			
		EndIf;
		
	EndIf;
	
	If Content <> Undefined Then
		
		For Each String In Content Do
			If Not ValueIsFilled(String.CommunicationKeySet) Then
				String.CommunicationKeySet = Parameters.CommunicationKeySet;
			EndIf;
			If Not ValueIsFilled(String.ProductCostElement) Then
				String.ProductCostElement = Parameters.ProductCostElement;
			EndIf;
			If Not ValueIsFilled(String.Department) Then
				String.Department = Parameters.AssigneeBusinessUnit;
			EndIf;
		EndDo;
		
		If TypeOf(CompositionSpecification) = Type("CatalogRef.ProductKitConfigurations") Then
			
			DataTypes = New Array;
			DataTypes.Add(Type("CatalogRef.BillsOfMaterials"));
			DataTypes.Add(Type("CatalogRef.ProductionStages"));
			Content.Columns.Add("SourceOfSemiFinishedProduct", New TypeDescription(DataTypes));
			
			SecurityDataTable = ProductionSupply.StageMaterialAssuranceParameters_(Content, Parameters.ReferenceOrder);
			
			SearchAttributes = "Products,Characteristic";
			TheStructureOfTheSearch = New Structure(SearchAttributes);
			SecurityDataTable.Indexes.Add(SearchAttributes);
			
			For Each String In Content Do
				FillPropertyValues(TheStructureOfTheSearch, String);
				FoundRows = SecurityDataTable.FindRows(TheStructureOfTheSearch);
				If ValueIsFilled(FoundRows) Then
					FillPropertyValues(String, FoundRows[0], "Warehouse,SupplyOption,WithAssignment");
				EndIf;
			EndDo;
			
		EndIf;
		
		If MaterialsAndWorksSets = Undefined Then
			MaterialsAndWorksSets = SetsOfMaterialsAndWorksDesigner();
		EndIf;
		
		NewRow = MaterialsAndWorksSets.Insert(0);
		NewRow.ConnectionKey             = Parameters.CommunicationKeySet;
		NewRow.BillOfMaterials          = CompositionSpecification;
		NewRow.ParentSpecification  = Parameters.ParentSpecification;
		NewRow.RowsCount       = Content.Count();
		NewRow.LinkKeyBOM = Parameters.ConnectionKey;
		For IndexOf = 1 To MaterialsAndWorksSets.Count() - 1 Do
			String = MaterialsAndWorksSets[IndexOf];
			If Not ValueIsFilled(String.ParentCommunicationKey) Then
				String.ParentCommunicationKey = NewRow.ConnectionKey;
			EndIf;
		EndDo;
		
		Return New Structure("MaterialsAndServices, MaterialsAndWorksSets", Content, MaterialsAndWorksSets);
		
	EndIf;
	
	Return Undefined;
	
EndFunction

Procedure ExcludeMaterialsOfTechnologicalSets(SpecificationData) Export
	
	If Not SpecificationData.Property("MaterialsAndServices")
			Or Not SpecificationData.Property("MaterialsAndWorksSets")
			Or Not ProductDataManagementCached.ItIsAvailableToStoreCompositionOfSetInSpecifications() Then
		Return;
	EndIf;
	
	DeleteRows_ = New Array;
	
	For Each CurrentRow In SpecificationData.MaterialsAndServices Do
		If ValueIsFilled(CurrentRow.CommunicationKeySet) Then
			FoundRow = SpecificationData.MaterialsAndWorksSets.Find(CurrentRow.CommunicationKeySet, "ConnectionKey");
			If FoundRow <> Undefined
				And (TypeOf(FoundRow.BillOfMaterials) = Type("CatalogRef.BillsOfMaterials")
					Or ValueIsFilled(FoundRow.ParentCommunicationKey)) Then
				DeleteRows_.Add(CurrentRow);
			EndIf;
		EndIf;
	EndDo;
	
	If DeleteRows_.Count() > 0 Then
		For Each String In DeleteRows_ Do
			SpecificationData.MaterialsAndServices.Delete(String);
		EndDo;
		UpdateSetsOfMaterialsAndWorksTable(SpecificationData, "MaterialsAndServices");
	EndIf;
	
EndProcedure

Procedure FillInDetailsIncludedInSet(Object, SourceOfMaterials = "SupplyWithMaterialsAndWorks") Export
	
	For Each String In Object[SourceOfMaterials] Do
		
		String.IncludedInSet = ValueIsFilled(String.CommunicationKeySet);
		
	EndDo;
	
EndProcedure

Procedure ProcessDeletionOfRowsIncludedInSets(Object, RowsIDs, SourceOfMaterials = "SupplyWithMaterialsAndWorks") Export
	
	For Each Id In RowsIDs Do
		
		RowData = Object[SourceOfMaterials].FindByID(Id);
		If ValueIsFilled(RowData.CommunicationKeySet) Then
			
			AdjustTableSetsOfMaterialsAndWorks(
				Object.MaterialsAndWorksSets, RowData.CommunicationKeySet, -1);
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure GetSetCommunicationKeysRecursively(Table, KeysLinksSet, VerifiableKeys = Undefined) Export
	
	NewKeys = New Array;
	
	For Each ConnectionKey In ?(VerifiableKeys = Undefined, KeysLinksSet, VerifiableKeys) Do
		For IndexOf = 1 To 2 Do
			FieldForSearch   = ?(IndexOf = 1, "ConnectionKey", "ParentCommunicationKey");
			ValueField = ?(IndexOf = 1, "ParentCommunicationKey", "ConnectionKey");
			FoundRows = Table.FindRows(New Structure(FieldForSearch, ConnectionKey));
			For Each String In FoundRows Do
				If KeysLinksSet.Find(String[ValueField]) = Undefined And ValueIsFilled(String[ValueField]) Then
					NewKeys.Add(String[ValueField]);
				EndIf;
			EndDo;
		EndDo;
	EndDo;
	
	CommonClientServer.SupplementArray(KeysLinksSet, NewKeys);
	TMCommonUse.DeleteDuplicateElementsFromArray(KeysLinksSet);
	
	If NewKeys.Count() > 0 Then
		GetSetCommunicationKeysRecursively(Table, KeysLinksSet, NewKeys);
	EndIf;
	
EndProcedure

Procedure AddCompositionOfSetsToSelectionResultInBackground(Parameters, StorageAddress) Export
	
	AddCompositionOfSetsToTable(Parameters.TableOfGoods, Parameters.ParametersForObtainingComposition);
	
	Result = New Structure;
	Result.Insert("SelectionOption", Parameters.SelectionOption);
	Result.Insert("TableOfGoods", Parameters.TableOfGoods);
	Result.Insert("TSName",          Parameters.TSName);
	
	PutToTempStorage(Result, StorageAddress);
	
EndProcedure

Procedure AddCompositionOfSetsToTable(Table, ParametersForObtainingComposition) Export
	
	If Table.Columns.Find("ContentData") = Undefined Then
		Table.Columns.Add("ContentData");
	EndIf;
	
	LineDetails = "Products,Characteristic,Count";
	For Each AttributeName In StrSplit("BillOfMaterials,ProductCostElement,AssigneeBusinessUnit,ConnectionKey", ",") Do
		If Table.Columns.Find(AttributeName) <> Undefined Then
			LineDetails = LineDetails + ","+AttributeName;
		EndIf;
	EndDo;
	
	For Each String In Table Do
		
		If Not String.ItemsType = Enums.ItemsTypes.Set Then
			Continue;
		EndIf;
		
		Parameters = ParametersForObtainingCompositionOfSetInProduction();
		FillPropertyValues(Parameters, ParametersForObtainingComposition,,"CommunicationKeySet,ConnectionKey");
		FillPropertyValues(Parameters, String, LineDetails);
		
		String.ContentData = CompositionOfSetInProduction(Parameters);
		
	EndDo;
	
EndProcedure

Procedure UnpackCompositionOfProcessKits(DataSet, ParametersForObtainingComposition) Export
	
	ItemsTypeSet = Enums.ItemsTypes.Set;
	If DataSet.Find(ItemsTypeSet, "ItemsType") = Undefined Then
		Return;
	EndIf;
	
	ThereArePresentations = False;
	If DataSet.Columns.Find("ProductsPresentation") <> Undefined Then
		ThereArePresentations = True;
	EndIf;
	
	AddCompositionOfSetsToTable(DataSet, ParametersForObtainingComposition);
	
	RowIndex           = 0;
	TableRowsCount = DataSet.Count();
	While RowIndex < TableRowsCount Do
		DataSetRow = DataSet[RowIndex];
		If DataSetRow.ItemsType = ItemsTypeSet Then
			
			ContentData = DataSetRow.ContentData;
			If ValueIsFilled(ContentData) Then
				
				For Each StringComponents In ContentData.MaterialsAndServices Do
					
					If StringComponents.ItemsType <> Enums.ItemsTypes.OwnGoods
						And StringComponents.ItemsType <> Enums.ItemsTypes.ReusablePackage Then
						Continue;
					EndIf;
					
					NewRow = DataSet.Insert(RowIndex);
					FillPropertyValues(NewRow, DataSetRow);
					FillPropertyValues(NewRow, StringComponents);
					
					If ThereArePresentations Then
						NewRow.ProductsPresentation = String(NewRow.Products);
						NewRow.CharacteristicPresentation = String(NewRow.Characteristic);
					EndIf;
					
					RowIndex = RowIndex + 1;
					
				EndDo;
				
				DataSet.Delete(DataSetRow);
				TableRowsCount = DataSet.Count();
				
			Else
				
				MessageText = StrTemplate(NStr("vi = 'Không thể nhận thành phần bộ sản phẩm: %1';
												|ru = 'Не удалось получить состав набора: %1';
												|en = 'Cannot receive the set content: %1'; fa = 'Cannot receive the set content: %1';
												|it = 'Non è stato possibile ricevere la composizione del kit: %1';
												|pl = 'Nie udało się otrzymać składu zestawu: %1';
												|tr = 'Set kapsamı alınamadı: %1'"),
					ProductsClientServer.ProductPresentation(DataSetRow.Products, DataSetRow.Characteristic));
					
				Common.MessageToUser(
					MessageText);
					
				CleaningStructure = New Structure;
				CleaningStructure.Insert("Products", Catalogs.Products.EmptyRef());
				CleaningStructure.Insert("Characteristic", Catalogs.ItemsCharacteristics.EmptyRef());
				CleaningStructure.Insert("MethodOfProductsAutoselection", Enums.MethodsOfProductAutoSelection.SpecifiedInProductionProcess);
				CleaningStructure.Insert("MethodOfItemVariantAutoselection", Enums.MethodsOfItemVariantAutoselection.SpecifiedInMasterData);
				
				FillPropertyValues(DataSetRow, CleaningStructure);
				
				RowIndex = RowIndex + 1;
				
			EndIf;
			
		Else
			
			RowIndex = RowIndex + 1;
			
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#Region AssignmentParameters

Procedure SetAssignmentParametersByDivisionDispatcher() Export
	
	BeginTransaction();
	Try
		
		Constants.UseBOMAssignmentParameters.Set(True);
		
		RecordSet = InformationRegisters.BOMAssignmentParameters.CreateRecordSet();
		Record = RecordSet.Add();
		Record.ParameterKind = Enums.TypesOfBOMAssignmentParameters.ProductionDispatcherBusinessUnit;
		Record.Priority    = 2;
		RecordSet.Write();
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		MessageText = NStr("vi = 'Không thể ghi các tham số gán đặc tả cho lý do: %Cause%';
							|ru = 'Не удалось записать параметры назначения спецификаций по причине: %Cause%';
							|en = 'Cannot save BOM assignment parameters. Reason: %Cause%'; fa = 'Cannot save BOM assignment parameters. Reason: %Cause%';
							|it = 'Non è stato possibile attivare l''utilizzo dei parametri di assegnazione delle specifiche a causa di: %Cause%';
							|pl = 'Nie udało się zapisać parametrów przeznaczenia specyfikacji z powodu: %Cause%';
							|tr = 'Ürün reçetesi atama parametrelerinin kaydedilememe nedeni: %Cause%'",
			Common.DefaultLanguageCode());
		MessageText = StrReplace(MessageText, "%Cause%", DetailErrorDescription(ErrorInfo()));
		
		WriteLogEvent(
			InfobaseUpdate.EventLogEvent(),
			EventLogLevel.Warning,,,
			MessageText);
			
	EndTry;
	
EndProcedure

Procedure CopyValuesOfSpecificationAssignmentParameters(Source, Receiver) Export
	
	QueryText = "
	|SELECT
	|	T.ParameterKind AS ParameterKind,
	|	T.Attribute     AS Attribute,
	|	T.NumberInList AS NumberInList,
	|	T.Condition      AS Condition,
	|	T.Value     AS Value
	|FROM
	|	InformationRegister.ValuesOfBOMAssignmentParameters AS T
	|WHERE
	|	T.BillOfMaterials = &BillOfMaterials";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("BillOfMaterials", Source);
	
	QueryResult = Query.Execute();
	
	If Not QueryResult.IsEmpty() Then
		RecordSet = InformationRegisters.ValuesOfBOMAssignmentParameters.CreateRecordSet();
		RecordSet.Filter.BillOfMaterials.Set(Receiver);
		Selection = QueryResult.Select();
		While Selection.Next() Do
			Record = RecordSet.Add();
			FillPropertyValues(Record, Selection);
			Record.BillOfMaterials = Receiver;
		EndDo;
		RecordSet.Write();
	EndIf;
	
EndProcedure

// Gets a view of the specification assignment parameter
//
// Parameters:
//  ParameterKind  - EnumRef.TypesOfBOMAssignmentParameters - type of parameter
//  Attribute      - ChartOfCharacteristicTypesRef.AdditionalAttributesAndInfo - Additional banking details
//  FullPresentation - Boolean - need to get a complete view (including the parameter view)
//
// Returns:
//   String - representation of the destination parameter
//
Function PresentationOfDestinationParameter(ParameterKind, Attribute = Undefined, FullPresentation = True) Export
	
	PresentationUnitManager  = NStr("vi = 'Bộ phận-điều phối';
									|ru = 'Подразделение-диспетчер';
									|en = 'Dispatching unit'; fa = 'واحد دیسپچینگ';
									|it = 'Reparto-distributore';
									|pl = 'Dział dyspozytorski';
									|tr = 'Üretim planlama departmanı'");
	PresentationDirectionOfActivity = NStr("vi = 'Lĩnh vực hoạt động';
											|ru = 'Направление деятельности';
											|en = 'Line of business'; fa = 'خط کسب‌وکار';
											|it = 'Settore di attività';
											|pl = 'Rodzaj działalności';
											|tr = 'İş kolu'");
	
	TypesOfParameters = New Map;
	TypesOfParameters.Insert(Enums.TypesOfBOMAssignmentParameters.ProductionDispatcherBusinessUnit,             PresentationUnitManager);
	TypesOfParameters.Insert(Enums.TypesOfBOMAssignmentParameters.AdditionalAttributesOfBusinessUnit,           PresentationUnitManager);
	TypesOfParameters.Insert(Enums.TypesOfBOMAssignmentParameters.LineOfBusiness,            PresentationDirectionOfActivity);
	TypesOfParameters.Insert(Enums.TypesOfBOMAssignmentParameters.AdditionalAttributesOfLineOfBusiness, PresentationDirectionOfActivity);
	
	Result = "";
	
	If ValueIsFilled(Attribute) Then
		
		Title = Common.ObjectAttributeValue(Attribute, "Title");
		
		If FullPresentation Then
		
			Result = StrTemplate("%1 (%2)", Title, TypesOfParameters[ParameterKind]);
			
		Else
			
			Result = Title;
			
		EndIf;
		
	Else
		
		Result = TypesOfParameters[ParameterKind];
		
	EndIf;
	
	Return Result;
	
EndFunction

// Checks the correctness of filling in the destination parameter
// 
// Parameters:
//  BillOfMaterials - CatalogRef.BillsOfMaterials
//  ParameterKind  - EnumRef.TypesOfBOMAssignmentParameters - type of parameter
//  Attribute      - ChartOfCharacteristicTypesRef.AdditionalAttributesAndInfo - Additional banking details
//  ValueStructure - See ProductDataManagementClientServer.SpecificationAssignmentParameterValueStructure
//  ValueType - TypeDescription - type of parameter
//  Cancel - Boolean - Cancel
Procedure CheckFillingOfDestinationParameter(BillOfMaterials, ParameterKind, Attribute, ValueStructure, ValueType, Cancel) Export
	
	TemplateNotFilledIn      = NStr("vi = 'Chưa điền %1 giá trị tham số ""%2"".';
									|ru = 'Не заполнено %1значение параметра ""%2"".';
									|en = 'The %1 value of the ""%2"" parameter is not filled in.'; fa = 'The %1 value of the ""%2"" parameter is not filled in.';
									|it = 'Non è stato compilato %1 il valore del parametro ""%2"".';
									|pl = 'Nie wypełniono %1wartości parametru""%2"".';
									|tr = '""%2"" parametresinin %1 değeri doldurulmadı.'");
	TemplateInvalidInterval = NStr("vi = 'Giá trị bên trái của tham số ""%1"" không thể lớn hơn giá trị bên phải.';
									|ru = 'Левое значение параметра ""%1"" не может быть больше правого.';
									|en = 'The left value of the parameter ""%1"" cannot be greater than the right value.'; fa = 'The left value of the parameter ""%1"" cannot be greater than the right value.';
									|it = 'Valore sinistro del parametro ""%1"" non deve essere superiore del destro.';
									|pl = 'Lewa wartość parametru ""%1"" nie może być większa od prawej.';
									|tr = '""%1"" parametresinin sol değeri, sağdakinden büyük olamaz.'");
	
	FillingIsMandatory = ProductDataManagementClientServer.FillingInValueOfDestinationParameterIsMandatory(
		ValueStructure.Condition, ValueType);
	
	If ValueStructure.Condition.Interval Then
		
		For IndexOf = 1 To 2 Do
			If FillingIsMandatory And Not ValueIsFilled(ValueStructure["Value"+IndexOf]) Then
				MessageText = StrTemplate(
					TemplateNotFilledIn,
					?(IndexOf=1,NStr("vi = 'bên trái';
									|ru = 'левое';
									|en = 'left'; fa = 'left';
									|it = 'a sinistra';
									|pl = 'lewe';
									|tr = 'sol'"),NStr("vi = 'bên phải';
														|ru = 'правое';
														|en = 'right'; fa = 'right';
														|it = 'a destra';
														|pl = 'prawe';
														|tr = 'sağ'"))+" ",
					PresentationOfDestinationParameter(ParameterKind,Attribute,False));
				Common.MessageToUser(MessageText,BillOfMaterials,,,Cancel);
			EndIf;
		EndDo;
		
		If ValueStructure.Value1 <> Undefined
			And ValueStructure.Value2 <> Undefined
			And ValueStructure.Value1 > ValueStructure.Value2 Then
				MessageText = StrTemplate(
					TemplateInvalidInterval,
					PresentationOfDestinationParameter(ParameterKind,Attribute,False));
				Common.MessageToUser(MessageText,BillOfMaterials,,,Cancel);
		EndIf;
		
	Else
		
		If FillingIsMandatory And Not ValueIsFilled(ValueStructure.Value) Then
			MessageText = StrTemplate(
				TemplateNotFilledIn,
				"",
				PresentationOfDestinationParameter(ParameterKind,Attribute,False));
			Common.MessageToUser(MessageText,BillOfMaterials,,,Cancel);
		EndIf;
		
	EndIf;
	
EndProcedure

Function TypeOfDestinationParameterInArray(ParameterKind, IncludingDependent = True) Export
	
	Result = New Array;
	Result.Add(ParameterKind);
	
	If IncludingDependent Then
		If ParameterKind = Enums.TypesOfBOMAssignmentParameters.ProductionDispatcherBusinessUnit Then
			Result.Add(Enums.TypesOfBOMAssignmentParameters.AdditionalAttributesOfBusinessUnit);
		ElsIf ParameterKind = Enums.TypesOfBOMAssignmentParameters.LineOfBusiness Then
			Result.Add(Enums.TypesOfBOMAssignmentParameters.AdditionalAttributesOfLineOfBusiness);
		EndIf;
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#Region Other


// Sets the selection by item in the list of specifications
// 
// Parameters:
// 	List - DynamicList - List
// 	Products - CatalogRef.Products - Products
// 	Purpose - EnumRef.UseOfItemsInProductionMasterData - use case
//
Procedure SetSelectionByProductInListOfSpecifications(List, Products, Purpose = Undefined) Export
	
	QueryTexts = New Array;
	
	// Product
	If ValueIsFilled(Products)
		And (Not ValueIsFilled(Purpose) Or Purpose = PredefinedValue("Enum.UseOfItemsInProductionMasterData.Product")) Then
		
		QueryTexts.Add("
		|SELECT
		|	T.Ref AS Ref
		|FROM
		|	Catalog.BillsOfMaterials.ManufacturedProducts AS T
		|WHERE
		|	T.Products = &Products
		|
		|UNION ALL
		|
		|SELECT
		|	T.Ref
		|FROM
		|	Catalog.BillsOfMaterials.ManufacturedProducts AS T
		|WHERE
		|	T.Products = VALUE(Catalog.Products.EmptyRef)
		|	AND T.ProductKind = &ProductKind
		|
		|UNION ALL
		|
		|SELECT
		|	T.Ref
		|FROM
		|	Catalog.BillsOfMaterials AS T
		|WHERE
		|	T.MainProductProducts = &Products
		|
		|UNION ALL
		|
		|SELECT
		|	T.Ref
		|FROM
		|	Catalog.BillsOfMaterials AS T
		|WHERE
		|	T.MainProductProducts = VALUE(Catalog.Products.EmptyRef)
		|	AND T.MainProductProductKind = &ProductKind
		|
		|UNION
		|
		|SELECT
		|	T.Ref
		|FROM
		|	Catalog.BillsOfMaterials.RecyclableWaste AS T
		|WHERE
		|	T.Products = &Products
		|");
		
	EndIf;
		
	// Material
	If ValueIsFilled(Products)
		And (Not ValueIsFilled(Purpose) Or Purpose = PredefinedValue("Enum.UseOfItemsInProductionMasterData.Material")) Then
		
		QueryTexts.Add("
		|SELECT
		|	T.Ref AS Ref
		|FROM
		|	Catalog.BillsOfMaterials.MaterialsAndServices AS T
		|WHERE
		|	T.Products = &Products");
		
	EndIf;
	
	FilterList = New ValueList;
	Use = (QueryTexts.Count() > 0);
	
	If Use Then
		
		Query = New Query;
		Query.Text = StrConcat(QueryTexts, " UNION ");
		Query.SetParameter("Products",    Products);
		ProductKind = Common.ObjectAttributeValue(Products, "ProductKind");
		Query.SetParameter("ProductKind", ProductKind);
		FilterList.LoadValues(Query.Execute().Unload().UnloadColumn("Ref"));
		
	EndIf;
		
	FilterRemainingGoodsByShelfLives = CommonClientServer.CreateFilterItemGroup(
		List.SettingsComposer.FixedSettings.Filter.Items,
		NStr("vi = 'Lọc theo mặt hàng';
			|ru = 'Отбор по номенклатуре';
			|en = 'Filter by items'; fa = 'فیلتر بر اساس اقلام';
			|it = 'La selezione in base all''elenco articoli';
			|pl = 'Filtr wg wierszy pozycji';
			|tr = 'Öğeye göre filtre'"),
		DataCompositionFilterItemsGroupType.AndGroup);
	
	CommonClientServer.AddCompositionItem(
			FilterRemainingGoodsByShelfLives,
			"Ref",
			DataCompositionComparisonType.InList,
			FilterList,
			,
			Use);
	
EndProcedure

#EndRegion

#EndRegion

#Region CalculationOfNormativeDuration

Procedure StandardProductionDurationCalculationIsRequiredBeforeSaving(Source, Cancel) Export
	
	If Source.DataExchange.Load Or Cancel Or Not GetFunctionalOption("UseProduction") Then
		Return;
	EndIf;
	
	WorkScheduleCalendar = ScheduleFromEventSource(Source);
	If WorkScheduleCalendar = Undefined Then
		Return;
	EndIf;
	
	AverageRateOfHours = 0;
	If ValueIsFilled(WorkScheduleCalendar) Then
		ArrayOfGraphs = ProductionServer.ArrayOfValues(WorkScheduleCalendar);
		AverageRateOfHours = AverageHoursAccordingToWorkSchedules(ArrayOfGraphs)[WorkScheduleCalendar];
	EndIf;
	Source.AdditionalProperties.Insert("AverageHoursBeforeChange", AverageRateOfHours);
	
EndProcedure

Procedure StandardProductionDurationCalculationIsRequiredOnSaving(Source, Cancel) Export
	
	If Source.DataExchange.Load Then
		Return;
	EndIf;
	
	AverageHoursBeforeChange = 0;
	If Not Source.AdditionalProperties.Property("AverageHoursBeforeChange", AverageHoursBeforeChange)
		Or Cancel Then
		Return;
	EndIf;
	
	WorkScheduleCalendar = ScheduleFromEventSource(Source);
	If Not ValueIsFilled(WorkScheduleCalendar) Then
		Return;
	EndIf;
	
	ArrayOfGraphs = ProductionServer.ArrayOfValues(WorkScheduleCalendar);
	AverageRateOfHours = AverageHoursAccordingToWorkSchedules(ArrayOfGraphs)[WorkScheduleCalendar];

	If AverageHoursBeforeChange <> AverageRateOfHours Then
		
		InformationRegisters.JobsOfStandardProductionDurationCalculation.AddJob(WorkScheduleCalendar, True, True);
		
	EndIf;
	
EndProcedure

// Gets a link to the work schedule from the event source
// 
// Parameters:
// 	Source - CatalogObject.Calendars, ConstantValueManager.MainEnterpriseCalendar - Calendar
// Returns:
// 	CatalogRef.Calendars - work schedule
//
Function ScheduleFromEventSource(Source)
	
	Var WorkScheduleCalendar;
	
	SourceType = TypeOf(Source);
	If SourceType = Type("ConstantValueManager.MainEnterpriseCalendar") Then
		
		WorkScheduleCalendar = Constants.MainEnterpriseCalendar.Get(); 
		
	ElsIf SourceType = Type("CatalogObject.Calendars") Then
		
		WorkScheduleCalendar = Source.Ref;
		
	EndIf;
	
	Return WorkScheduleCalendar;
	
EndFunction

Function AverageHoursAccordingToWorkSchedules(ReferencesArrray) Export
	
	Query = New Query("
	|SELECT
	|	Calendars.Ref                                          AS Ref,
	|	CAST(AVG(Calendars.Duration) AS NUMBER(10,3)) AS NormOfHours
	|FROM
	|	(SELECT
	|		FillingTemplate.Ref                                                          AS Ref,
	|		SUM(DATEDIFF(Schedule.BeginTime, Schedule.EndTime, MINUTE)/60) AS Duration
	|	FROM
	|		Catalog.Calendars.FillingTemplate AS FillingTemplate
	|			LEFT JOIN Catalog.Calendars.WorkSchedule AS Schedule
	|			ON FillingTemplate.Ref = Schedule.Ref
	|				AND FillingTemplate.LineNumber = Schedule.DayNumber
	|	WHERE
	|		FillingTemplate.Ref IN (&WorkSchedules)
	|		AND FillingTemplate.DayAddedToSchedule
	|	
	|	GROUP BY
	|		FillingTemplate.Ref,
	|		FillingTemplate.LineNumber) AS Calendars
	|
	|GROUP BY
	|	Calendars.Ref");
	
	Query.SetParameter("WorkSchedules", ReferencesArrray);
	
	AverageRateOfHours = New Map;
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		AverageRateOfHours.Insert(Selection.Ref, Selection.NormOfHours);
	EndDo;
	For Each Ref In ReferencesArrray Do
		If Not ValueIsFilled(AverageRateOfHours[Ref]) Then
			AverageRateOfHours[Ref] = 24.000;
		EndIf;
	EndDo;
	
	Return AverageRateOfHours;
	
EndFunction

Function CollapsedAverageHoursByWorkSchedule(ReferencesArrray) Export
	
	Query = New Query("
	|SELECT
	|	CAST(AVG(Calendars.Duration) AS NUMBER(10,3)) AS NormOfHours
	|FROM
	|	(SELECT
	|		SUM(DATEDIFF(Schedule.BeginTime, Schedule.EndTime, MINUTE)/60) AS Duration
	|	FROM
	|		Catalog.Calendars.FillingTemplate AS FillingTemplate
	|			LEFT JOIN Catalog.Calendars.WorkSchedule AS Schedule
	|			ON FillingTemplate.Ref = Schedule.Ref
	|				AND FillingTemplate.LineNumber = Schedule.DayNumber
	|	WHERE
	|		FillingTemplate.Ref IN (&WorkSchedules)
	|		AND FillingTemplate.DayAddedToSchedule
	|	
	|	GROUP BY
	|		FillingTemplate.LineNumber) AS Calendars");
	
	Query.SetParameter("WorkSchedules", ReferencesArrray);
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() And ValueIsFilled(Selection.NormOfHours) Then
		Result = Selection.NormOfHours;
	Else
		Result = 24.000;
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#Region AutoSelection_SelectionByProperties_CalculationOfQuantity

Function TablePartsWithParameterizationConstructor() Export
	
	Result = New ValueTable();
	
	Result.Columns.Add("TSName",                New TypeDescription("String"));
	Result.Columns.Add("ThereIsAutoselection",        New TypeDescription("Boolean"));
	Result.Columns.Add("ThereIsSelectionByProperties", New TypeDescription("Boolean"));
	Result.Columns.Add("ThereIsCalculationAccordingToFormula",  New TypeDescription("Boolean"));
	Result.Columns.Add("ThereArePackages",         New TypeDescription("Boolean"));
	
	Return Result;
	
EndFunction

#Region AutoSelection

// The constructor parameters of the auto-detect item
// 
// Returns:
// 	Structure - From:
// * GetAutoSelectionInformation - Boolean - flag for getting auto-selection information
// * GetPresentations - Boolean - the symptom of receipt of submissions
// * PropertyMapping - ValueTable - table of compliance of the properties
// * ValuesOfProductProperties - ValueTable - the table of values of the properties of products
// * TableOfProductData - ValueTable - item data table
// * TempTablesManager - TempTablesManager -
//
Function AutoSelectionParametersConstructor() Export
	
	AutoSelectionParameters = New Structure;
	
	AutoSelectionParameters.Insert("TempTablesManager"    , Undefined);
	AutoSelectionParameters.Insert("TableOfProductData", Undefined);
	
	AutoSelectionParameters.Insert("ValuesOfProductProperties", Undefined);
	AutoSelectionParameters.Insert("PropertyMapping"   , Undefined);
	
	AutoSelectionParameters.Insert("GetPresentations"     , False);
	AutoSelectionParameters.Insert("GetAutoSelectionInformation", True);
	
	AutoSelectionParameters.Insert("TSName", "");
	
	Return AutoSelectionParameters;
	
EndFunction

// Creates auto-selection parameters for the object and the transmitted item data
// 
// Parameters:
//  BillOfMaterials - CatalogRef.BillsOfMaterials
//  ItemData_3 - Structure
// 
// Returns:
//  See AutoSelectionParametersConstructor
Function GetAutoSelectionParameters(BillOfMaterials, ItemData_3) Export
	
	AutoSelectionParameters = AutoSelectionParametersConstructor();
	AutoSelectionParameters.TempTablesManager = New TempTablesManager();
	
	CreateTTDataOnItem(ItemData_3, AutoSelectionParameters.TempTablesManager);
	
	AutoSelectionParameters.TableOfProductData = AutoSelectionParameters.TempTablesManager.Tables[0].GetData().Unload();
	AutoSelectionParameters.ValuesOfProductProperties      = ProductPropertyValues(ItemData_3);
	AutoSelectionParameters.PropertyMapping         = PropertyMatchingSettings(BillOfMaterials);
	
	Return AutoSelectionParameters;
	
EndFunction

Procedure CreateTTDataOnItem(ItemData_3, TempTablesManager) Export
	
	Query = New Query;
	
	QueryText = "
	|SELECT
	|	0 AS Id,
	|	&AdditionalFields
	|
	|INTO TTProductData_
	|;
	|";
	
	AdditionalFields = New Array;
	For Each KeyAndValue In ItemData_3 Do
		AdditionalFields.Add(StrTemplate("&%1 AS %1", KeyAndValue.Key));
		Query.SetParameter(KeyAndValue.Key, KeyAndValue.Value);
	EndDo;
	QueryText = StrReplace(QueryText, "&AdditionalFields", StrConcat(AdditionalFields,","+Chars.LF));
	
	Query.Text = QueryText;
	Query.TempTablesManager = TempTablesManager;
	Query.Execute();
	
EndProcedure

Procedure ProcessSettingsForAutomaticSelectionOfProducts(DataSet, AutoSelectionParameters) Export
	
	If DataSet.Count() = 0 Then
		Return;
	EndIf;
	
	ProcessProductSelectionFromProperty(DataSet, AutoSelectionParameters);
	
	ProcessFeatureSelectionByProperties(DataSet, AutoSelectionParameters);
	
	ProcessSelectionOfCharacteristicsByAlgorithm(DataSet, AutoSelectionParameters);
	
	ProcessSpecificationOfProductSpecificationInProduction(DataSet, AutoSelectionParameters);
	
EndProcedure

// Auto-selecting an item from a property
// 
// Parameters:
// 	DataSet - ValueTable - a data table containing:
// 		* Id - Number - row ID
// 	AutoSelectionParameters - See AutoSelectionParametersConstructor
//
Procedure ProcessProductSelectionFromProperty(DataSet, AutoSelectionParameters)
	
	DatasetRows = DataSet.FindRows(New Structure("MethodOfProductsAutoselection",
															Enums.MethodsOfProductAutoSelection.SpecifiedInProductsProperty));
	
	Table = New ValueTable;
	Table.Columns.Add("RowIndex" ,                  New TypeDescription("Number"));
	Table.Columns.Add("Id",                  New TypeDescription("Number"));
	Table.Columns.Add("Property",                       New TypeDescription("ChartOfCharacteristicTypesRef.AdditionalAttributesAndInfo"));
	Table.Columns.Add("MethodOfItemVariantAutoselection", New TypeDescription("EnumRef.MethodsOfItemVariantAutoselection"));
	Table.Columns.Add("DataSetRow");
	
	RowIndex = 0;
	For Each DataSetRow In DatasetRows Do
		
		If DataSetRow.PropertyThatContainsProducts.IsEmpty() Then
			Continue;
		EndIf;
		
		NewRow = Table.Add();
		NewRow.RowIndex                   = RowIndex;
		NewRow.Id                  = DataSetRow.Id;
		NewRow.Property                       = DataSetRow.PropertyThatContainsProducts;
		NewRow.MethodOfItemVariantAutoselection = DataSetRow.MethodOfItemVariantAutoselection;
		NewRow.DataSetRow = DataSetRow;
		
		RowIndex = RowIndex + 1;
		
	EndDo;
	
	If Table.Count() = 0 Then
		Return;
	EndIf;
	
	QueryText = "
	|SELECT
	|	T.RowIndex,
	|	T.Id,
	|	CAST(T.Property AS ChartOfCharacteristicTypes.AdditionalAttributesAndInfo) AS Property,
	|	T.MethodOfItemVariantAutoselection
	|
	|INTO TTProperties
	|FROM
	|	&Properties AS T
	|
	|INDEX BY
	|	Property
	|;
	|
	|SELECT
	|	TTProductData_.Id                           AS Id,
	|	0                                                              AS Priority,
	|	&ProductsPresentation                                     AS ProductsPresentation,
	|	PropertiesValues.Property                                       AS Property,
	|	CAST(PropertiesValues.Value AS Catalog.Products) AS Products,
	|
	|	ISNULL(CAST(PropertiesValues.Value AS Catalog.Products).ItemsType, VALUE(Enum.ItemsTypes.EmptyRef)) AS ItemsType,
	|	ISNULL(CAST(PropertiesValues.Value AS Catalog.Products).UnitOfMeasure, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) AS UnitOfMeasure,
	|	ISNULL(CAST(PropertiesValues.Value AS Catalog.Products).UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.NumberOfPieces), FALSE) AS PieceUnitOfMeasure,
	|	CASE
	|		WHEN ISNULL(CAST(PropertiesValues.Value AS Catalog.Products).UseVariants, UNDEFINED) IN (
	|											VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind),
	|											VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind),
	|											VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems))
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ItemVariantsAreUsed
	|
	|INTO TTPropertyValues
	|FROM
	|	TTProductData_ AS TTProductData_
	|		INNER JOIN Catalog.Products.AdditionalAttributes AS PropertiesValues
	|		ON TTProductData_.Products = PropertiesValues.Ref
	|WHERE
	|	PropertiesValues.Property IN (SELECT DISTINCT T.Property FROM TTProperties AS T)
	|
	|UNION ALL
	|
	|SELECT
	|	TTProductData_.Id                             AS Id,
	|	1                                                                AS Priority,
	|	&ProductsPresentation                                       AS ProductsPresentation,
	|	PropertiesValues.Property                                         AS Property,
	|	CAST(PropertiesValues.Value AS Catalog.Products)   AS Products,
	|
	|	ISNULL(CAST(PropertiesValues.Value AS Catalog.Products).ItemsType, VALUE(Enum.ItemsTypes.EmptyRef)) AS ItemsType,
	|	ISNULL(CAST(PropertiesValues.Value AS Catalog.Products).UnitOfMeasure, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) AS UnitOfMeasure,
	|	ISNULL(CAST(PropertiesValues.Value AS Catalog.Products).UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.NumberOfPieces), FALSE) AS PieceUnitOfMeasure,
	|	CASE
	|		WHEN ISNULL(CAST(PropertiesValues.Value AS Catalog.Products).UseVariants, UNDEFINED) IN (
	|											VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind),
	|											VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind),
	|											VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems))
	|			THEN TRUE
	|		ELSE FALSE
	|	END
	|FROM
	|	TTProductData_ AS TTProductData_
	|		INNER JOIN Catalog.ItemsCharacteristics.AdditionalAttributes AS PropertiesValues
	|		ON TTProductData_.Characteristic = PropertiesValues.Ref
	|WHERE
	|	PropertiesValues.Property IN (SELECT DISTINCT T.Property FROM TTProperties AS T)
	|
	|INDEX BY
	|	Id,
	|	Property,
	|	ItemsType
	|;
	|
	|SELECT
	|	Properties.RowIndex                      AS RowIndex,
	|	Properties.Property                          AS Property,
	|	&PropertyIDExpression           AS IDProperty,
	|	PRESENTATION(Properties.Property)           AS PropertyPresentation,
	|
	|	PropertiesValues.Products               AS Products,
	|	PropertiesValues.ProductsPresentation  AS ProductsPresentation,
	|	PropertiesValues.ItemsType            AS ItemsType,
	|	PropertiesValues.UnitOfMeasure           AS UnitOfMeasure,
	|	PropertiesValues.PieceUnitOfMeasure    AS PieceUnitOfMeasure,
	|
	|	PropertiesValues.ItemVariantsAreUsed AS ItemVariantsAreUsed,
	|	CASE PropertiesValues.ItemVariantsAreUsed
	|		WHEN TRUE
	|			THEN Properties.MethodOfItemVariantAutoselection
	|		ELSE
	|			VALUE(Enum.MethodsOfItemVariantAutoselection.SpecifiedInMasterData)
	|	END                                      AS MethodOfItemVariantAutoselection
	|
	|FROM TTProperties AS Properties
	|
	|	LEFT JOIN TTPropertyValues AS PropertiesValues
	|		ON Properties.Id = PropertiesValues.Id
	|			AND Properties.Property = PropertiesValues.Property
	|			AND PropertiesValues.ItemsType IN (&AcceptableProductTypes)
	|
	|ORDER BY
	|	Properties.RowIndex,
	|	PropertiesValues.Priority
	|";
	
	IdField_ = ProcessingOfFormulas.IdFieldForAdditionalBankingDetails();
	PropertyIDExpression = StringFunctionsClientServer.SubstituteParametersToString(
		"Properties.Property.%1",
		IdField_);
	QueryText = StrReplace(QueryText, "&PropertyIDExpression", PropertyIDExpression);
	
	If AutoSelectionParameters.GetPresentations Then
		QueryText = StrReplace(QueryText, "&ProductsPresentation", "ISNULL(CAST(PropertiesValues.Value AS Catalog.Products).Presentation, """")");
	Else
		QueryText = StrReplace(QueryText, "&ProductsPresentation", """""");
	EndIf;
	
	Query = New Query;
	Query.TempTablesManager = AutoSelectionParameters.TempTablesManager;
	Query.SetParameter("Properties", Table);
	
	AcceptableProductTypes = New Array;
	AcceptableProductTypes.Add(Enums.ItemsTypes.OwnGoods);
	AcceptableProductTypes.Add(Enums.ItemsTypes.Work_5);
	AcceptableProductTypes.Add(Enums.ItemsTypes.ReusablePackage);
	If AutoSelectionParameters.TSName = "MaterialsAndServices" Then
		AcceptableProductTypes.Add(Enums.ItemsTypes.Set);
	EndIf;
	
	Query.SetParameter("AcceptableProductTypes", AcceptableProductTypes);
	
	Query.Text = QueryText;
	
	Selection = Query.Execute().Select();
	
	CurRowIndex = Undefined;
	While Selection.Next() Do
		
		If CurRowIndex = Selection.RowIndex Then
			Continue;
		EndIf;
		
		DataSetRow = Table[Selection.RowIndex].DataSetRow;
		
		If ValueIsFilled(Selection.Products) Then
			
			FillPropertyValues(DataSetRow, Selection);
			
		Else
			
			If AutoSelectionParameters.GetAutoSelectionInformation Then
				DataSetRow.AutoselectionDetails =
					StrTemplate(NStr("vi = 'Mặt hàng không thể lấy tính chất < %1>.';
									|ru = 'Номенклатуру не удалось получить из свойства <%1>.';
									|en = 'Cannot receive products from property <%1>.'; fa = 'Cannot receive products from property <%1>.';
									|it = 'Non è stato possibile ottenere l''articolo dalla proprietà <%1>.';
									|pl = 'Nomenklaturę nie można pobrać z właściwości <%1>.';
									|tr = '<%1> özelliğinden öğe alınamadı.'"),
						Selection.PropertyPresentation);
			EndIf; 
			
		EndIf;
		
		CurRowIndex = Selection.RowIndex;
		
	EndDo;
	
	TMCommonUse.DestroyTemporaryTables(Query.TempTablesManager, "TTProperties,TTPropertyValues");
	
EndProcedure

// Automatic selection of characteristics by properties
// 
// Parameters:
// 	DataSet - ValueTable - a data table containing:
// 		* Id - Number - row ID
// 	AutoSelectionParameters - See AutoSelectionParametersConstructor
//
Procedure ProcessFeatureSelectionByProperties(DataSet, AutoSelectionParameters)
	
	DatasetRows = DataSet.FindRows(New Structure("MethodOfItemVariantAutoselection,ItemVariantsAreUsed",
															Enums.MethodsOfItemVariantAutoselection.AutomaticallySelectedByProductsProperties,
															True));
	
	If DatasetRows.Count() = 0 Then
		Return;
	EndIf;
	
	DescriptionsOfAutoSelectionFunctions = New Map;
	For Each LongDesc In ProductDataManagementCached.DescriptionOfAutoSelectionFunctionsForProductItemPropertyValue() Do
		If Not TypeOf(LongDesc) = Type("Structure") Or Not LongDesc.Property("FunctionName") Then
			Continue;
		EndIf;
		DescriptionsOfAutoSelectionFunctions.Insert(LongDesc.FunctionName, LongDesc);
	EndDo;
	
	Table = New ValueTable;
	Table.Columns.Add("RowIndex");
	Table.Columns.Add("DataSetRow");
	Table.Columns.Add("PropertyMapping");
	Table.Columns.Add("ProductRange_2");
	Table.Columns.Add("ItemVariantOfProduct");
	Table.Columns.Add("Processed1");
	
	ItemData_3              = Undefined;
	ProductPropertyValues            = Undefined;
	ProductCharacteristics = New Structure("Products, Characteristic");
	ProductsArray                = New Array;
	
	ListOfResultDetails        = "AutoselectionDetails, Characteristic";
	If AutoSelectionParameters.GetPresentations Then
		ListOfResultDetails = ListOfResultDetails + ", CharacteristicPresentation";
	EndIf;
	
	RowIndex  = 0;
	CurID_ = Undefined;
	For Each DataSetRow In DatasetRows Do
		
		If CurID_ <> DataSetRow.Id Then
			
			ItemData_3 = AutoSelectionParameters.TableOfProductData.Find(DataSetRow.Id, "Id");
			If ItemData_3 = Undefined Then
				Continue;
			EndIf;
			
			FillPropertyValues(ProductCharacteristics, ItemData_3, "Products, Characteristic");
			ProductPropertyValues = AutoSelectionParameters.ValuesOfProductProperties.Copy(ProductCharacteristics);
			
			CurID_ = DataSetRow.Id;
			
			ProductsArray.Add(ItemData_3.Products);
			
		EndIf;
		
		ProductsArray.Add(DataSetRow.Products);
		
		PropertyMapping = AutoSelectionParameters.PropertyMapping.Copy(
			New Structure("BillOfMaterials, ConnectionKey", ItemData_3.BillOfMaterials, DataSetRow.ConnectionKey));
		
		For Each ConfiguringCompliance In PropertyMapping Do
		
			If ConfiguringCompliance.ValueSelectionMethod = Enums.MethodsOfSelectingProductPropertyValue.ByProperty
				And ValueIsFilled(ConfiguringCompliance.ProductsProperty) Then
				
				ValueFound = ProductPropertyValues.Find(ConfiguringCompliance.ProductsProperty, "Property");
				If ValueFound <> Undefined Then
					ConfiguringCompliance.Value = ValueFound.Value;
				EndIf;
				
			ElsIf ConfiguringCompliance.ValueSelectionMethod = Enums.MethodsOfSelectingProductPropertyValue.ByFormula 
				And Not IsBlankString(ConfiguringCompliance.ValueCalculationAlgorithm) Then
				
				DataToCalculate = PrepareFormulaForCalculation(ConfiguringCompliance.ValueCalculationAlgorithm, ProductPropertyValues);
				
				ConfiguringCompliance.Value = CalculatePropertyValueForAutoSelection(
					DataToCalculate.Formula, 
					DataToCalculate.Parameters, 
					ItemData_3.BillOfMaterials);
					
			ElsIf ConfiguringCompliance.ValueSelectionMethod = Enums.MethodsOfSelectingProductPropertyValue.ByAlgorithm 
				And Not IsBlankString(ConfiguringCompliance.ValueCalculationAlgorithm) Then
				
				ParametersOfAutoselectAlgorithm = AutoselectionAlgorithmExecutionParameters(ItemData_3, ProductPropertyValues, DataSetRow);
				
				LongDesc = DescriptionsOfAutoSelectionFunctions[ConfiguringCompliance.ValueCalculationAlgorithm];
				
				If LongDesc <> Undefined Then
					
					Algorithm = LongDesc.ModuleName+"."+LongDesc.FunctionName+"(Parameters)";
					
					ConfiguringCompliance.Value = CalculatePropertyValueForAutoSelection(
						Algorithm, 
						ParametersOfAutoselectAlgorithm, 
						ItemData_3.BillOfMaterials);
						
				EndIf;
				
			EndIf;
			
		EndDo;
		
		NewRow = Table.Add();
		NewRow.RowIndex          = RowIndex;
		NewRow.DataSetRow    = DataSetRow;
		NewRow.PropertyMapping   = PropertyMapping;
		NewRow.ProductRange_2   = ProductCharacteristics.Products;
		NewRow.ItemVariantOfProduct = ProductCharacteristics.Characteristic;
		NewRow.Processed1            = False;
		
		RowIndex = RowIndex + 1;
		
	EndDo;
	
	OwnersOfCharacteristics = New Map;
	
	Query = New Query;
	Query.SetParameter("ProductsArray", ProductsArray);
	Query.Text = "
	|SELECT
	|	Products.Ref AS Products,
	|	CASE Products.UseVariants
	|		WHEN VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind)
	|			THEN Products.ProductKind
	|		WHEN VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind)
	|			THEN Products.ItemVariantsOwner
	|		WHEN VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems)
	|			THEN Products.Ref
	|		ELSE UNDEFINED
	|	END AS TechnicalCharacteristics
	|FROM
	|	Catalog.Products AS Products
	|WHERE
	|	Products.Ref IN(&ProductsArray)";
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		OwnersOfCharacteristics.Insert(Selection.Products, Selection.TechnicalCharacteristics);
	EndDo;
	
	PackageTemplate = "
	|SELECT
	|	&Characteristic_Presentation,
	|	Characteristics.Ref AS Characteristic
	|FROM
	|	Catalog.ItemsCharacteristics AS Characteristics
	|	
	|	LEFT JOIN ChartOfCharacteristicTypes.AdditionalAttributesAndInfo AS Properties
	|	ON Properties.Ref IN (&ParameterNameListOfPackageProperties)
	|	
	|	LEFT JOIN Catalog.ItemsCharacteristics.AdditionalAttributes AS PropertiesValues
	|	ON Characteristics.Ref = PropertiesValues.Ref
	|		AND Properties.Ref = PropertiesValues.Property
	|	
	|WHERE
	|	Characteristics.Owner = &NameOfPropertyOwnerParameter
	|	AND NOT Characteristics.DeletionMark
	|	
	|GROUP BY
	|	Characteristics.Ref
	|	
	|HAVING
	|	SUM(CASE WHEN
	|				&TextOfSelectionsByProperties
	|			THEN 1
	|		ELSE 0
	|	END) = &ParameterNameNumberOfPackageProperties
	|";
	
	SelectionTemplateByProperty = "Properties.Ref = &%1 AND ISNULL(PropertiesValues.Value, UNDEFINED) = &%2";
	
	MappingPattern = "
	|SELECT
	|	&Characteristic_Presentation,
	|	Characteristics.Ref AS Characteristic
	|FROM
	|	Catalog.ItemsCharacteristics AS Characteristics
	|WHERE
	|	Characteristics.Ref = &NameOfMaterialCharacteristicsParameter
	|";
	
	PackageParameters   = New Structure;
	RequestPacketCache_ = New Map;
	
	RowIndex      = 0;
	While RowIndex < Table.Count() Do
		
		Query = New Query;
		
		QueryTexts     = New Array;
		RequestTextsHashes = New Array;
		
		While RowIndex < Table.Count() And QueryTexts.Count() < 100 Do
			
			TableRow      = Table[RowIndex];
			DataSetRow = TableRow.DataSetRow;
			
			NameOfPropertyOwnerParameter  = "TechnicalCharacteristics_"+Format(RowIndex, "NZ=0; NG=");
			ParameterNameNumberOfPackageProperties = "PropertiesCount_"+Format(RowIndex, "NZ=0; NG=");
			ParameterNameListOfPackageProperties     = "ListOfProperties_"+Format(RowIndex, "NZ=0; NG=");
			
			PackageParameters.Clear();
			
			PropertiesCount = TableRow.PropertyMapping.Count();
			If PropertiesCount = 0 Then
				
				NameOfMaterialCharacteristicsParameter = "ItemVariantOfMaterial_"+Format(RowIndex, "NZ=0; NG=");
				
				If OwnersOfCharacteristics[DataSetRow.Products] = OwnersOfCharacteristics[TableRow.ProductRange_2] Then
					PackageParameters.Insert(NameOfMaterialCharacteristicsParameter, TableRow.ItemVariantOfProduct);
				Else
					PackageParameters.Insert(NameOfMaterialCharacteristicsParameter, Undefined);
				EndIf;
				
				PackageRequestText = StrReplace(MappingPattern, "NameOfMaterialCharacteristicsParameter", NameOfMaterialCharacteristicsParameter);
				
			Else
				
				PackageParameters.Insert(ParameterNameListOfPackageProperties, New Array);
				
				SelectionTextsByProperties = New Array;
				For X = 0 To PropertiesCount - 1 Do
					
					ConfiguringCompliance = TableRow.PropertyMapping[X];
					
					NameOfMaterialPropertyParameter = StrTemplate("MaterialProperty_%1_%2", Format(RowIndex, "NZ=0; NG="), Format(X, "NZ=0; NG="));
					ParameterNamePropertyValue  = StrTemplate("PropertyValue_%1_%2" , Format(RowIndex, "NZ=0; NG="), Format(X, "NZ=0; NG="));
					
					SelectionTextsByProperties.Add(StrTemplate(
						SelectionTemplateByProperty,
						NameOfMaterialPropertyParameter,
						ParameterNamePropertyValue));
						
					PackageParameters.Insert(NameOfMaterialPropertyParameter, ConfiguringCompliance.MaterialProperty);
					If ValueIsFilled(ConfiguringCompliance.Value) And ConfiguringCompliance.Value <> False Then
						PackageParameters.Insert(ParameterNamePropertyValue, ConfiguringCompliance.Value);
					Else
						PackageParameters.Insert(ParameterNamePropertyValue, Undefined);
					EndIf;
					
					ParametersArray = PackageParameters[ParameterNameListOfPackageProperties]; // Array
					ParametersArray.Add(ConfiguringCompliance.MaterialProperty);
					
				EndDo;
				
				PackageParameters.Insert(NameOfPropertyOwnerParameter,  OwnersOfCharacteristics[DataSetRow.Products]);
				PackageParameters.Insert(ParameterNameNumberOfPackageProperties, PropertiesCount);
				
				PackageRequestText = StrReplace(PackageTemplate,       "ParameterNameListOfPackageProperties",     ParameterNameListOfPackageProperties);
				PackageRequestText = StrReplace(PackageRequestText, "NameOfPropertyOwnerParameter",  NameOfPropertyOwnerParameter);
				PackageRequestText = StrReplace(PackageRequestText, "ParameterNameNumberOfPackageProperties", ParameterNameNumberOfPackageProperties);
				PackageRequestText = StrReplace(PackageRequestText, "&TextOfSelectionsByProperties",            StrConcat(SelectionTextsByProperties, Chars.LF + "OR "));
				
			EndIf;
			
			PackageHash = HashOfPackageForSelectingCharacteristicByProperties(PackageParameters);
			
			RequestPacketCache = RequestPacketCache_.Get(PackageHash.HashSum);
			If RequestPacketCache = Undefined Then
				
				RequestPacketCache_.Insert(PackageHash.HashSum,
					New Structure("TableRow, DependentTableRows", TableRow, New Array));
				
				QueryTexts.Add(PackageRequestText);
				RequestTextsHashes.Add(PackageHash.HashSum);
				
				For Each KeyAndValue In PackageParameters Do
					Query.SetParameter(KeyAndValue.Key, KeyAndValue.Value);
				EndDo;
				
			Else
				
				If RequestPacketCache.TableRow.Processed1 = True Then
					FillPropertyValues(
						DataSetRow,
						RequestPacketCache.TableRow.DataSetRow,
						ListOfResultDetails);
					TableRow.Processed1 = True;
				Else
					RequestPacketCache.DependentTableRows.Add(TableRow);
				EndIf;
				
			EndIf;
			
			RowIndex = RowIndex + 1;
			
		EndDo;
		
		QueryText = StrConcat(QueryTexts, Common.QueryBatchSeparator());
		If AutoSelectionParameters.GetPresentations Then
			FieldTextPresentation = "PRESENTATION(Characteristics.Ref) AS CharacteristicPresentation,";
		Else
			FieldTextPresentation = "";
		EndIf;
		QueryText = StrReplace(QueryText, "&Characteristic_Presentation,", FieldTextPresentation);
		
		Query.Text = QueryText;
		QueryResults = Query.ExecuteBatch(); 
		For X = 0 To QueryResults.Count() - 1 Do
			
			QueryResult = QueryResults[X];
			
			Selection = QueryResult.Select();
			
			RequestPacketCache   = RequestPacketCache_.Get(RequestTextsHashes[X]);
			
			TableRow      = RequestPacketCache.TableRow;
			DataSetRow = TableRow.DataSetRow;
			
			If Selection.Count() = 0 Then
				If AutoSelectionParameters.GetAutoSelectionInformation Then
					DataSetRow.AutoselectionDetails =
						StrTemplate(NStr("vi = 'Đặc tính không thể được chọn bởi các thuộc tính:  %1';
										|ru = 'Характеристику не удалось подобрать по свойствам: %1';
										|en = 'Failed to pick a variant by properties: %1'; fa = 'Failed to pick a variant by properties: %1';
										|it = 'Non è stato possibile selezionare la caratteristica in base alle proprietà: %1';
										|pl = 'Charakterystykę nie można pobrać z właściwości: %1';
										|tr = 'Özelliklere göre öğe seçilemedi: %1'"),
							FillInAutoselectionInformation(TableRow.PropertyMapping));
				EndIf;
			ElsIf Selection.Count() > 1 Then
				If AutoSelectionParameters.GetAutoSelectionInformation Then
					DataSetRow.AutoselectionDetails =
						StrTemplate(NStr("vi = 'Theo thuộc tính: %1, đã tìm thấy hơn một đặc tính';
										|ru = 'По свойствам: %1, найдено более одной характеристики';
										|en = 'By properties: %1, more than one variant is found'; fa = 'By properties: %1, more than one variant is found';
										|it = 'Per proprietà: %1, trovata più di una caratteristica';
										|pl = 'Wg właściwości: %1, znaleziono więcej niż jedna charakterystyka';
										|tr = 'Özelliklere göre: %1, birden fazla varyant bulundu'"),
							FillInAutoselectionInformation(TableRow.PropertyMapping));
				EndIf;
			Else
				Selection.Next();
				DataSetRow.Characteristic = Selection.Characteristic;
				If AutoSelectionParameters.GetPresentations Then
					DataSetRow.CharacteristicPresentation = Selection.CharacteristicPresentation;
				EndIf;
			EndIf;
			
			TableRow.Processed1 = True;
			
			If RequestPacketCache.DependentTableRows.Count() > 0 Then
				For Each DependentTableRow In RequestPacketCache.DependentTableRows Do
					FillPropertyValues(DependentTableRow.DataSetRow,
						DataSetRow,
						ListOfResultDetails);
					DependentTableRow.Processed1 = True;
				EndDo;
			EndIf;
			
		EndDo;
		
	EndDo;
	
EndProcedure

// Auto-select features according to the algorithm
// 
// Parameters:
// 	DataSet - ValueTable - a data table containing:
// 		* Id - Number - row ID
// 	AutoSelectionParameters - See AutoSelectionParametersConstructor
//
Procedure ProcessSelectionOfCharacteristicsByAlgorithm(DataSet, AutoSelectionParameters)
	
	DatasetRows = DataSet.FindRows(New Structure("MethodOfItemVariantAutoselection,ItemVariantsAreUsed",
															Enums.MethodsOfItemVariantAutoselection.PickedByAlgorithm,
															True));
	
	If DatasetRows.Count() = 0 Then
		Return;
	EndIf;
	
	DescriptionsOfAutoSelectionFunctions = New Map;
	For Each LongDesc In ProductDataManagementCached.DescriptionOfAutoSelectFeatureFunctions() Do
		If Not TypeOf(LongDesc) = Type("Structure") Or Not LongDesc.Property("FunctionName") Then
			Continue;
		EndIf;
		DescriptionsOfAutoSelectionFunctions.Insert(LongDesc.FunctionName, LongDesc);
	EndDo;
	
	ItemData_3            = Undefined;
	ProductPropertyValues          = Undefined;
	FilterProductsCharacteristic = New Structure("Products, Characteristic");
	
	DescriptionErrorPattern   = NStr("vi = 'Không tìm thấy thuật toán chọn tự động đặc tính: %1';
									|ru = 'Не найден алгоритм автовыбора характеристики: %1';
									|en = 'The algorithm for auto selection of the item variant is not found: %1'; fa = 'The algorithm for auto selection of the item variant is not found: %1';
									|it = 'Nessun algoritmo di individuazione automatica delle funzionalità trovato: %1';
									|pl = 'Nie znaleziono algorytmu automatycznego wyboru cechy: %1';
									|tr = 'Varyantların otomatik seçim algoritması bulunamadı: %1'");
	ExecutionErrorPattern = NStr("vi = 'Không thể tìm thấy đặc tính theo thuật toán:  %1';
								|ru = 'Не удалось подобрать характеристику по алгоритму: %1';
								|en = 'Failed to pick the variant by the algorithm: %1'; fa = 'Failed to pick the variant by the algorithm: %1';
								|it = 'Non è stato possibile selezionare la caratteristica in base all''algoritmo: %1';
								|pl = 'Nie udało się dobrać cechę według algorytmu: %1';
								|tr = 'Algoritmaya göre varyant seçilemedi: %1'");
	
	CurID_ = Undefined;
	For Each DataSetRow In DatasetRows Do
		
		If IsBlankString(DataSetRow.ItemVariantAutoSelectionAlgorithm) Then
			Continue;
		EndIf;
		
		LongDesc = DescriptionsOfAutoSelectionFunctions[DataSetRow.ItemVariantAutoSelectionAlgorithm];
		
		If LongDesc = Undefined Then
			DataSetRow.AutoselectionDetails = StrTemplate(DescriptionErrorPattern, DataSetRow.ItemVariantAutoSelectionAlgorithm);
			Continue;
		EndIf;
		
		If CurID_ <> DataSetRow.Id Then
			
			ItemData_3 = AutoSelectionParameters.TableOfProductData.Find(DataSetRow.Id, "Id");
			If ItemData_3 = Undefined Then
				Continue;
			EndIf;
			
			FillPropertyValues(FilterProductsCharacteristic, ItemData_3, "Products, Characteristic");
			ProductPropertyValues = AutoSelectionParameters.ValuesOfProductProperties.Copy(FilterProductsCharacteristic);
			
			CurID_ = DataSetRow.Id;
			
		EndIf;
		
		ParametersOfAutoselectAlgorithm = AutoselectionAlgorithmExecutionParameters(ItemData_3, ProductPropertyValues, DataSetRow);
		
		AutoselectionDetails = StrTemplate(ExecutionErrorPattern, LongDesc.FunctionName);
		
		Try
			Algorithm = LongDesc.ModuleName+"."+LongDesc.FunctionName+"(Parameters)";
			DataSetRow.Characteristic = Common.CalculateInSafeMode(Algorithm, ParametersOfAutoselectAlgorithm);
		Except
			
			WriteLogEvent(
				ProductionServer.AutoselectFeatureEventByAlgorithm(),
				EventLogLevel.Error,,,
				AutoselectionDetails + Chars.LF + DetailErrorDescription(ErrorInfo()));
				
		EndTry;
		
		If ValueIsFilled(DataSetRow.Characteristic) Then
			AutoselectionDetails = "";
			If AutoSelectionParameters.GetPresentations Then
				DataSetRow.CharacteristicPresentation = String(DataSetRow.Characteristic);
			EndIf;
		EndIf;
		
		If AutoSelectionParameters.GetAutoSelectionInformation Then
			DataSetRow.AutoselectionDetails = AutoselectionDetails;
		EndIf;
		
	EndDo;
	
EndProcedure

// Specification of the nomenclature during production
// 
// Parameters:
// 	DataSet - ValueTable - a data table containing:
// 		* Id - Number - row ID
// 	AutoSelectionParameters - See AutoSelectionParametersConstructor
//
Procedure ProcessSpecificationOfProductSpecificationInProduction(DataSet, AutoSelectionParameters)
	
	If Not AutoSelectionParameters.GetAutoSelectionInformation Then
		Return;
	EndIf;
	
	ThereIsDescriptionOfProduct     = DataSet.Columns.Find("ProductDescription") <> Undefined;
	ThereIsApplicationOfMaterial = DataSet.Columns.Find("MaterialApplication") <> Undefined;
	FilterProductsCharacteristic = New Structure("Products, Characteristic");
	
	For Each DataSetRow In DataSet Do
		
		ThereIsClarificationInProduction = (DataSetRow.MethodOfProductsAutoselection = Enums.MethodsOfProductAutoSelection.SpecifiedInProductionProcess)
			Or (DataSetRow.MethodOfItemVariantAutoselection = Enums.MethodsOfItemVariantAutoselection.SpecifiedInProductionProcess
				And DataSetRow.ItemVariantsAreUsed = True);
			
		If Not ThereIsClarificationInProduction Then
			Continue;
		EndIf;
		
		ItemData_3 = AutoSelectionParameters.TableOfProductData.Find(DataSetRow.Id, "Id");
		If ItemData_3 = Undefined Then
			Continue;
		EndIf;
		
		FillPropertyValues(FilterProductsCharacteristic, ItemData_3, "Products, Characteristic");
		ProductPropertyValues = AutoSelectionParameters.ValuesOfProductProperties.FindRows(FilterProductsCharacteristic);
		
		If ThereIsDescriptionOfProduct And Not IsBlankString(DataSetRow.ProductDescription) Then
			DataSetRow.AutoselectionDetails = StrTemplate(NStr("vi = 'Mô tả sản phẩm: %1';
																|ru = 'Описание изделия: %1';
																|en = 'Product description: %1'; fa = 'Product description: %1';
																|it = 'Descrizione produzione: %1';
																|pl = 'Opis wyrobu: %1';
																|tr = 'Nihai ürün ayrıntıları: %1'"), DataSetRow.ProductDescription) + "; ";
		ElsIf ThereIsApplicationOfMaterial And Not IsBlankString(DataSetRow.MaterialApplication) Then
			DataSetRow.AutoselectionDetails = StrTemplate(NStr("vi = 'Sử dụng nguyên vật liệu: %1';
																|ru = 'Применение материала: %1';
																|en = 'Material application: %1'; fa = 'Material application: %1';
																|it = 'Applicazione materiale: %1';
																|pl = 'Zastosowanie materiału: %1';
																|tr = 'Malzemeni uygulanması: %1'"), DataSetRow.MaterialApplication) + "; ";
		EndIf;
		DataSetRow.AutoselectionDetails = DataSetRow.AutoselectionDetails + RefinementOfMaterialDuringProduction(ProductPropertyValues);
		
	EndDo;
	
EndProcedure

Function FillInAutoselectionInformation(ProductPropertyValues)
	
	AutoselectionDetails = "";
	
	For Each String In ProductPropertyValues Do
		AutoselectionDetails = StrTemplate("%1%2<%3>%4%5",
												AutoselectionDetails,
												?(IsBlankString(AutoselectionDetails), "", "; "),
												String.PropertyPresentation,
												?(String.Value = Undefined, "", ": "),
												String.Value);
	EndDo;
	
	Return AutoselectionDetails;
	
EndFunction

Procedure CheckPropertiesOfAutoSelectionAndSelectionByProperties(Object, PropertyMapping, SelectionByProperties, TypeOfProducts) Export
	
	ListOfProperties = GetPropertiesForAutoSelection(TypeOfProducts);
	
	// Let's check the selection settings by properties
	DeleteRows_ = New Array;
	For Each StringSelection_ In SelectionByProperties Do
		If ListOfProperties.Find(StringSelection_.Property) = Undefined Then
			DeleteRows_.Add(StringSelection_);
		EndIf;
	EndDo;
	For Each DeleteLine In DeleteRows_ Do
		SelectionByProperties.Delete(DeleteLine);
	EndDo;
	
	// Let's check the auto-selection setting
	For Each ConfigurationData In PropertyMapping Do
		If ListOfProperties.Find(ConfigurationData.ProductsProperty) = Undefined Then
			ConfigurationData.ProductsProperty = ChartsOfCharacteristicTypes.AdditionalAttributesAndInfo.EmptyRef();
		EndIf;
	EndDo;
	
EndProcedure

Function RefinementOfMaterialDuringProduction(ProductPropertyValues)

	AutoselectionDetails = StrTemplate(NStr("vi = 'Bắt buộc phải được chỉ định có tính đến các thuộc tính:  %1';
											|ru = 'Требуется уточнить с учетом свойств: %1';
											|en = 'It is required to specify considering properties: %1'; fa = 'It is required to specify considering properties: %1';
											|it = 'È necessario precisare tenendo conto delle proprietà: %1';
											|pl = 'Należy wyjaśnić w odniesieniu do właściwości:  %1';
											|tr = 'Özellik doğrultusunda netleştirmeniz gerekmektedir: %1'"),
		FillInAutoselectionInformation(ProductPropertyValues));
	
	Return AutoselectionDetails;
	
EndFunction

Procedure ClearContentAutoSelectionSettings(RowData, PropertyMapping) Export
	
	RowData.MethodOfProductsAutoselection   = PredefinedValue("Enum.MethodsOfProductAutoSelection.SpecifiedInMasterData");
	RowData.MethodOfItemVariantAutoselection = PredefinedValue("Enum.MethodsOfItemVariantAutoselection.SpecifiedInMasterData");
	RowData.PropertyThatContainsProducts = Undefined;

	TheStructureOfTheSearch = New Structure("ConnectionKey", RowData.ConnectionKey);
	StringsList = PropertyMapping.FindRows(TheStructureOfTheSearch);
	For Each String_Matching In StringsList Do
		PropertyMapping.Delete(String_Matching);
	EndDo;
	
EndProcedure

Function HashOfPackageForSelectingCharacteristicByProperties(PackageParameters)
	
	Result = New DataHashing(HashFunction.MD5);
	
	For Each KeyAndValue In PackageParameters Do
		Value = KeyAndValue.Value;
		If TypeOf(Value) <> Type("Array") Then
			If Common.RefTypeValue(Value) Then
				Result.Append(String(Value.UUID()));
			Else
				Result.Append(String(Value));
			EndIf;
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

// It is intended to describe the auto-selection function of the item characteristic or the value of the item characteristic property 
// in the connected algorithms. See the auto-selection configuration form and the property matching setting.
//
// Parameters:
//  FunctionName            - String - name of the function that must be exported
//  ModuleName             - String - name of the module, if the function is not located in the control modulereferencesexternal Links
//  Presentation         - String - the view with which the function will be displayed in the auto-selection settings list
//  ReturnValue  - String,Array,TypeDescription - a string containing the names of the return value types separated by commas,
//                                                        an array of values of the Type type consisting of possible types of the function return value,
//                                                        and a description of the return value,
//                                                        Information about the return value is used to filter the list of available functions when selected.
//  Parameters             - Structure - the structure of additional description parameters may contain the following keys:
//                              * PropertyName - String - The name of the property specified in the setting element properties, under "For developers",
//                                                       if specified, the algorithm will only apply to that property.
//
// Returns:
//  Structure - From:
//		* FunctionName - String
//		* ModuleName - String
//		* Presentation - String
//		* ReturnValue - String,Array,TypeDescription,Undefined
//		* Parameters - Structure
Function CreateDescriptionOfAutoselectFunction(FunctionName, ModuleName = "", Presentation = "", ReturnValue = Undefined, Parameters = Undefined) Export
	
	Result = New Structure;
	
	Result.Insert("FunctionName",           FunctionName);
	Result.Insert("ModuleName",            ModuleName);
	Result.Insert("Presentation",        Presentation);
	Result.Insert("ReturnValue", Undefined);
	Result.Insert("Parameters",            New Structure);
	
	If IsBlankString(Result.ModuleName) Then
		Result.ModuleName = "ProductDataManagement";
	EndIf;
	
	If IsBlankString(Result.Presentation) Then
		Result.Presentation = FunctionName;
	EndIf;
	
	If ReturnValue <> Undefined Then
		If TypeOf(ReturnValue) = Type("Array") Or TypeOf(ReturnValue) = Type("String") Then
			Result.ReturnValue = New TypeDescription(ReturnValue);
		ElsIf TypeOf(ReturnValue) = Type("TypeDescription") Then
			Result.ReturnValue = ReturnValue;
		ElsIf TypeOf(ReturnValue) = Type("Type") Then
			Result.ReturnValue = New TypeDescription(CommonClientServer.ValueInArray(ReturnValue));
		EndIf;
	EndIf;
	
	If Parameters <> Undefined Then
		Result.Parameters = Parameters;
	EndIf;
	
	Return Result;
	
EndFunction

Function ProductPropertyValues(ItemData_3) Export
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	&Products                               AS Products,
	|	&Characteristic                             AS Characteristic,
	|	ValuesOfProductProperties_.Property           AS Property,
	|	&ExpressionOfProductIDAndDetails AS IDProperty,
	|	PRESENTATION(ValuesOfProductProperties_.Property) AS PropertyPresentation,
	|	ValuesOfProductProperties_.Value           AS Value
	|FROM
	|	Catalog.Products.AdditionalAttributes AS ValuesOfProductProperties_
	|WHERE
	|	ValuesOfProductProperties_.Ref = &Products
	|
	|UNION ALL
	|
	|SELECT
	|	&Products,
	|	&Characteristic,
	|	PropertyValuesOfCharacteristic.Property,
	|	&ExpressionOfIdentifierOfAdditionalCharacteristicDetails,
	|	PRESENTATION(PropertyValuesOfCharacteristic.Property),
	|	PropertyValuesOfCharacteristic.Value
	|FROM
	|	Catalog.ItemsCharacteristics.AdditionalAttributes AS PropertyValuesOfCharacteristic
	|		LEFT JOIN Catalog.Products.AdditionalAttributes AS ValuesOfProductProperties_
	|		ON (ValuesOfProductProperties_.Ref = &Products)
	|			AND PropertyValuesOfCharacteristic.Property = ValuesOfProductProperties_.Property
	|WHERE
	|	PropertyValuesOfCharacteristic.Ref = &Characteristic
	|	AND ValuesOfProductProperties_.Property IS NULL";
	
	IdField_ = ProcessingOfFormulas.IdFieldForAdditionalBankingDetails();
	ExpressionOfProductIDAndDetails = StringFunctionsClientServer.SubstituteParametersToString(
		"ValuesOfProductProperties_.Property.%1",
		IdField_);
	ExpressionOfIdentifierOfAdditionalCharacteristicDetails = StringFunctionsClientServer.SubstituteParametersToString(
		"PropertyValuesOfCharacteristic.Property.%1",
		IdField_);
	Query.Text = StrReplace(Query.Text, "&ExpressionOfProductIDAndDetails", ExpressionOfProductIDAndDetails);
	Query.Text = StrReplace(Query.Text, "&ExpressionOfIdentifierOfAdditionalCharacteristicDetails", ExpressionOfIdentifierOfAdditionalCharacteristicDetails);
	
	Query.SetParameter("Products"  , ItemData_3.Products);
	Query.SetParameter("Characteristic", ItemData_3.Characteristic);
	
	Result = Query.Execute().Unload();
	
	Result.Indexes.Add("Property");
	Result.Indexes.Add("IDProperty");
	
	Return Result;
	
EndFunction

Function PropertyMatchingSettings(BillOfMaterials) Export
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	&Ref                                         AS BillOfMaterials,
	|	PropertyMapping.ConnectionKey                   AS ConnectionKey,
	|	PropertyMapping.ValueSelectionMethod       AS ValueSelectionMethod,
	|	PropertyMapping.MaterialProperty           AS MaterialProperty,
	|	&ExpressionOfMaterialPropertyID       AS IDProperty,
	|	PRESENTATION(PropertyMapping.MaterialProperty) AS PropertyPresentation,
	|	PropertyMapping.ProductsProperty           AS ProductsProperty,
	|	PropertyMapping.PropertyValue            AS Value,
	|	PropertyMapping.ValueCalculationAlgorithm     AS ValueCalculationAlgorithm
	|FROM
	|	Catalog.BillsOfMaterials.PropertyMapping AS PropertyMapping
	|WHERE
	|	PropertyMapping.Ref = &Ref
	|	AND PropertyMapping.ValueSelectionMethod <> VALUE(Enum.MethodsOfSelectingProductPropertyValue.AnyValue)";
	
	IdField_ = ProcessingOfFormulas.IdFieldForAdditionalBankingDetails();
	ExpressionOfMaterialPropertyID = StringFunctionsClientServer.SubstituteParametersToString(
		"PropertyMapping.MaterialProperty.%1",
		IdField_);
	Query.Text = StrReplace(Query.Text, "&ExpressionOfMaterialPropertyID", ExpressionOfMaterialPropertyID);
	
	If TypeOf(BillOfMaterials) = Type("CatalogRef.RouteSheets") Then
		Query.Text = StrReplace(Query.Text, "BillsOfMaterials", "RouteSheets");
	ElsIf TypeOf(BillOfMaterials) = Type("CatalogRef.TechnologicalProcesses") Then
		Query.Text = StrReplace(Query.Text, "BillsOfMaterials", "TechnologicalProcesses");
	EndIf;

	Query.SetParameter("Ref", BillOfMaterials);
	
	Result = Query.Execute().Unload();
	Result.Indexes.Add("ConnectionKey");
	
	Return Result;
	
EndFunction

// There is an automatic selection of items in the table.
// 
// Parameters:
//  Table - TabularSection
// 
// Returns:
//  Boolean
Function ThereIsAutomaticSelectionOfItemsInTable(Table) Export
	
	Result = False;
	
	For Each String In Table Do
		
		If (
				ValueIsFilled(String.MethodOfProductsAutoselection)
				And String.MethodOfProductsAutoselection <> Enums.MethodsOfProductAutoSelection.SpecifiedInMasterData
			)
			Or
			(
				ValueIsFilled(String.MethodOfItemVariantAutoselection)
				And String.MethodOfItemVariantAutoselection <> Enums.MethodsOfItemVariantAutoselection.SpecifiedInMasterData
			) Then
			
			Result = True;
			Break;
			
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

#EndRegion

#Region CalculationByFormulas

#Region Translator

Function FormulaTranslator(String, Parameters, LongDesc) Export
	
	Operand = "";
	IndexOf = Parameters.Count();
	
	Formula = String.QuantityCalculationAlgorithm;
	FormulaForParsing = String.QuantityCalculationAlgorithm;
	
	ParametersMap = New Map;
	
	While NextOperand(Operand, FormulaForParsing) Do
		
		If ParametersMap[Operand] <> Undefined Then
			
			Continue;
		EndIf;
		
		ParameterName = StrTemplate("Parameter%1", Format(IndexOf, "NZ=; NG="));
		
		Formula = StrReplace(Formula, "[" + Operand + "]", StrTemplate("Parameters.%1", ParameterName));
		
		DataPath = Parameters.Add();
		DataPath.Value = 0;
		DataPath.ParameterName = ParameterName;
		If Not FillDataPathByOperand(
					Operand,
					DataPath,
					LongDesc)
				And StrFind(Operand, "ManufacturedProduct") > 0
				Then
			// for compatibility with 2.2.3 [#...#]
			DataPath.Key        = "MainProduct";
			DataPath.PropertyName = "Count";
		EndIf;
		DataPath.RowData = String;
		
		ParametersMap.Insert(Operand, ParameterName);
		IndexOf = IndexOf + 1;
		
	EndDo;
	
	For Each KeyAndValue In FunctionsFromCommonModule() Do
		
		Formula = StrReplace(Formula, KeyAndValue.Key + "(", KeyAndValue.Value + "(");
		
	EndDo;
	
	Return Formula;
	
EndFunction

Function FillDataPathByOperand(Operand, DataPath, LongDesc)
	
	For Each KeyAndValue In LongDesc Do
		
		SourceDetails = KeyAndValue.Value; // See CreateDescriptionsOfOperandDataSource
		ID = SourceDetails.Id;
		
		Length = StrLen(ID);
		If Left(Operand, Length)= ID
			And (Mid(Operand, Length + 1, 1) = "." Or Mid(Operand, Length + 1, 1) = "[") Then
			
			DataPath.Key = KeyAndValue.Key;
			
			Separator = ".";
			If KeyAndValue.Value.Collection Then
				
				TextToParse = Operand;
				
				NextOperand(
					Separator,
					TextToParse);
				
				DataPath.LineNumber = Common.TypeDescriptionNumber(10).AdjustValue(Separator);
				Separator = "["+Separator+"].";
				
			EndIf;
			DataPath.PropertyName = StrReplace(Operand, ID + Separator, "");
			
			Return True;
			
		EndIf;
		
	EndDo;
	
	Return False;
	
EndFunction

Function NextOperand(Operand, Text)
	
	Position = StrFind(Text, "[");
	If Position > 0 Then
		PositionEnd1 = StrFind(Text, "]", SearchDirection.FromBegin, Position + 1);
		While PositionEnd1 > 0 Do
			Operand = Mid(Text, Position + 1, PositionEnd1 - Position - 1);
			If StrOccurrenceCount(Operand, "[") = StrOccurrenceCount(Operand, "]") Then
				Text = Mid(Text, PositionEnd1 + 1);
				Return True;
			EndIf;
			PositionEnd1 = StrFind(Text, "]", SearchDirection.FromBegin, PositionEnd1 + 1);
		EndDo;
	EndIf;
	Return False;
	
EndFunction

Function IDOfAdditionalDetailsInFormula(Operand)
	Id = Operand;
	
	If Left(Id, 1) = "{"
		And Right(Id, 1) = "}"
		And StrOccurrenceCount(Id, "{") = 1 Then
		
		Id = ProcessingOfFormulas.PropertiesCharacteristics(Operand).Id;
		
	EndIf;
	
	Return Id;
EndFunction

Function PrepareFormulaForCalculation(CalculationAlgorithm, PropertiesValues)
	
	Parameters = New Structure;
	
	Formula = CalculationAlgorithm;
	FormulaForParsing = CalculationAlgorithm;
	
	IndexOf = 0;
	Operand = "";
	
	TheProcessedParameters = New Map;
	While NextOperand(Operand, FormulaForParsing) Do
		
		If TheProcessedParameters[Operand] <> Undefined Then
			Continue;
		EndIf;
		
		PropertyID = IDOfAdditionalDetailsInFormula(Operand);
		RowProperty = PropertiesValues.Find(PropertyID, "IDProperty");
		If RowProperty <> Undefined Then
			ParameterName = StrTemplate("Parameter%1", Format(IndexOf, "NZ=; NG="));
			
			Formula = StrReplace(Formula, "[" + Operand + "]", StrTemplate("Parameters.%1", ParameterName));
			
			Parameters.Insert(ParameterName, RowProperty.Value);
			
			TheProcessedParameters.Insert(Operand, ParameterName);
			
			IndexOf = IndexOf + 1;
		EndIf;
		
	EndDo;
	
	For Each KeyAndValue In FunctionsFromCommonModule() Do
		Formula = StrReplace(Formula, KeyAndValue.Key + "(", KeyAndValue.Value + "(");
	EndDo;
	
	Return New Structure("Formula, Parameters", Formula, Parameters);
	
EndFunction

Function CalculatePropertyValueForAutoSelection(CalculationAlgorithm, Parameters, BillOfMaterials)
	
	Result = Undefined;
	
	Try
		Result = Common.CalculateInSafeMode(CalculationAlgorithm, Parameters);
	Except
			
		WriteLogEvent(
			ProductionServer.EventCalculatingPropertyValueDuringAutoSelection(),
			EventLogLevel.Error,,
			BillOfMaterials,
			DetailErrorDescription(ErrorInfo()));
		
	EndTry;
	
	Return Result;
	
EndFunction

#EndRegion

#Region DataForCalculation

Procedure AddParameterToDataForCalculation(DataForCalculation, ParameterName, Value = 0, Parameters = Undefined)
	
	DataForCalculation.Parameters.Insert(ParameterName, Value);

	If Parameters <> Undefined Then
		Parameters.Find(ParameterName, "ParameterName").Found = True;
	EndIf;
	
EndProcedure

// Adds a string to the match for auto-calculation
// 
// Parameters:
// 	DataForCalculation - See DataForCalculationByFormulas
// 	DataPath - ValueTableRow of See ProductDataManagement.ParametersForCalculationByFormulas
// 	Source - See Catalogs.BillsOfMaterials.DataSourceForFormulaCalculations
//
Procedure AddMatchForAutoCalculation(DataForCalculation, DataPath, Source)
	
	If (DataPath.Key = "ManufacturedProducts" 
		Or DataPath.Key = "RecyclableWaste"
		Or DataPath.Key = "MaterialsAndServices")
		And DataPath.PropertyName = NStr("vi = 'Số lượng';
										|ru = 'Количество';
										|en = 'Quantity'; fa = 'مقدار';
										|it = 'Quantità';
										|pl = 'Quantity';
										|tr = 'Miktar'") Then
		
		If Not IsBlankString(Source.QuantityCalculationAlgorithm) Then
			
			If DataForCalculation.AutoCalculation[Source.ConnectionKey] = Undefined Then
				DataForCalculation.AutoCalculation.Insert(Source.ConnectionKey, New Array);
			EndIf;
			
			RowsArray = DataForCalculation.AutoCalculation[Source.ConnectionKey]; // Array
			RowsArray.Add(DataPath.ParameterName);
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region DataSources

// Constructor for describing the operand data source
// 
// Parameters:
// 	Id - String - source ID
// 	Presentation - String - Source presentation
// Returns:
// 	Structure - From:
// * Id - String - source ID
// * Presentation - String - Source presentation
// * Attributes - Array of See ProductDataManagement.CreateDescriptionsOfOperandDataSourceProps - list of Bank details
// * ContainsProperties - Boolean - indicates whether properties are present
// * PropertiesSet - CatalogRef.AdditionalAttributesAndInfoSets - set of properties
// * ContainsProductProperties - Boolean - indicates whether the item has properties
// * Collection - Boolean - collection attribute
// * TSName - String - name of the table part
// * SourceOfProductProperties - CatalogRef.Products,CatalogRef.ItemKinds - the source of the properties
Function CreateDescriptionsOfOperandDataSource(Id, Presentation = "") Export
	
	Result = New Structure("
	|Id,
	|Presentation,
	|
	|Attributes,
	|
	|ContainsProperties, 
	|PropertiesSet,
	|
	|ContainsProductProperties, 
	|Collection,
	|
	|TSName,
	|SourceOfProductProperties,
	|");

	Result.Id = Id;
	If IsBlankString(Presentation) Then
		Result.Presentation = Id;
	Else
		Result.Presentation = Presentation;
	EndIf;
	
	Result.Attributes = New Array;
	
	Result.ContainsProperties = False;
	Result.PropertiesSet = Catalogs.AdditionalAttributesAndInfoSets.EmptyRef();
	
	Result.ContainsProductProperties = False;
	Result.Collection = False;
	
	Result.TSName = "";
	
	Return Result;
	
EndFunction

// Returns the structure of the description of the props or table part of the operand source
// 
// Parameters:
// 	Id - String - ID of the item or table part.
// 	ValueType - TypeDescription - description of the types of props.
// 	Presentation - String - Representation of a prop or table part.
// Returns:
// 	Structure - LongDesc:
// * Id - String - ID of the item or table part.
// * ValueType - TypeDescription - description of the types of props.
// * Presentation - String - Representation of a prop or table part.
Function CreateDescriptionsOfOperandDataSourceProps(Id, ValueType, Presentation = "") Export
	
	Result = New Structure("Id, ValueType, Presentation");

	Result.Id = Id;
	Result.ValueType = ValueType;
	If IsBlankString(Presentation) Then
		Result.Presentation = Id;
	Else
		Result.Presentation = Presentation;
	EndIf;
	
	Return Result;
	
EndFunction

// Constructor of the data source table for calculation using formulas
// 
// Returns:
// 	ValueTable - From:
// * LineNumber - Number - row number of the source table
// * Products - CatalogRef.Products - Products
// * Characteristic - CatalogRef.ItemsCharacteristics - characteristics of the nomenclature
// * Count - Number - Count
// * ConnectionKey - UUID - ID of the table row
// * QuantityCalculationAlgorithm - String - the text of the algorithm
//
Function CreateTableOfDataSourcesForCalculationByFormulas() Export
	
	Table = New ValueTable;
	
	Table.Columns.Add("LineNumber", New TypeDescription("Number"));
	
	Table.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
	Table.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
	
	Table.Columns.Add("Count", New TypeDescription("Number"));
	
	Table.Columns.Add("ConnectionKey");
	Table.Columns.Add("QuantityCalculationAlgorithm");
	
	Return Table;
	
EndFunction

// Constructor of the data source structure for calculation using formulas
// 
// Returns:
// 	Structure - From:
// * Products - Undefined - uninitialized item value
// * Characteristic - Undefined - uninitialized characteristic value
// * Count - Undefined - the uninitialized value for the number
// * ConnectionKey - Undefined - uninitialized value of the link key
// * QuantityCalculationAlgorithm - Undefined - uninitialized value of the quantity calculation algorithm
//
Function CreateSourceDataStructureForCalculationUsingFormulas() Export
	
	Return New Structure("Products,Characteristic,Count,ConnectionKey,QuantityCalculationAlgorithm");
	
EndFunction

// Constructor of the data source operand table
// 
// Returns:
//  ValueTable -  Table of operands:
// * LineNumber - Number
// * Id - String 
// * LineNumber - Number
// * Id - String
// * Presentation - String
// * ValueType - TypeDescription
// * OperandType_ - String
Function DataSourceOperandTableConstructor() Export
	
	Result = New ValueTable;
	
	Result.Columns.Add("LineNumber",   New TypeDescription("Number"));
	Result.Columns.Add("Id", New TypeDescription("String"));
	Result.Columns.Add("Presentation", New TypeDescription("String"));
	Result.Columns.Add("ValueType");
	Result.Columns.Add("OperandType_", New TypeDescription("String"));
	
	Return Result;
	
EndFunction

// Constructor of the operand description
// 
// Returns:
//  Structure -  The structure of:
// * LineNumber - Number
// * Id - String 
// * Presentation - String 
// * ValueType - TypeDescription
// * OperandType_ - String
Function StructureOfDataSourceOperandConstructor() Export
	
	Result = New Structure;
	
	Result.Insert("LineNumber",   0);
	Result.Insert("Id", "");
	Result.Insert("Presentation", "");
	Result.Insert("ValueType",   New TypeDescription());
	Result.Insert("OperandType_",   "");
	
	Return Result;
	
EndFunction

// Determines whether the passed data path contains the source details
// 
// Parameters:
// 	DataPath - See ParametersForCalculationByFormulas
// 	LongDesc - See ProductDataManagement.CreateDescriptionsOfOperandDataSource
// Returns:
// 	Boolean - True if the data path contains the source details
//
Function DataPathContainsSourceDetails(DataPath, LongDesc) Export
	
	For Each Attribute In LongDesc.Attributes Do
		
		If Attribute.Id = DataPath.PropertyName Then
			
			Return True;
			
		EndIf;
		
	EndDo;
	
	Return False;
	
EndFunction

// Adds the operands in the source description
// 
// Parameters:
// 	DescriptionOfSources - See Catalogs.BillsOfMaterials.DescriptionOfOperandDataSources
// 	Object - FormDataStructure - object data
// 	TSName - String - name of the table part
// 	RowData - FormDataCollectionItem - table row:
// 		* LineNumber - Number - Line number
//
Procedure SupplementDescriptionOfSourcesWithCompositionOfOperands(DescriptionOfSources, Object, TSName, RowData = Undefined) Export
	
	UseAdditionalAttributesAndInfo = GetFunctionalOption("UseAdditionalAttributesAndInfo");
	
	SetsList =           New Array;
	ItemList =      New Array;
	ListOfProductKinds = New Array;
	
	If UseAdditionalAttributesAndInfo Then
	
		For Each KeyAndValue In DescriptionOfSources Do
			
			Var_Key = KeyAndValue.Key;
			SourceDetails = KeyAndValue.Value;
			
			If SourceDetails.ContainsProperties Then
				SetsList.Add(SourceDetails.PropertiesSet);
			EndIf;
			
			If SourceDetails.ContainsProductProperties Then
				If SourceDetails.Collection Then
					For Each String In Object[Var_Key] Do
						If ValueIsFilled(String.Products) Then
							ItemList.Add(String.Products);
						EndIf;
					EndDo;
				ElsIf ValueIsFilled(SourceDetails.SourceOfProductProperties) Then
					If TypeOf(SourceDetails.SourceOfProductProperties) = Type("CatalogRef.Products") Then
						ItemList.Add(SourceDetails.SourceOfProductProperties);
					Else
						ListOfProductKinds.Add(SourceDetails.SourceOfProductProperties);
					EndIf;
				EndIf;
			EndIf;
			
		EndDo;

		ProductAttributes = Common.ObjectsAttributesValues(ItemList, "ProductKind");
		For Each Item In ItemList Do
			ListOfProductKinds.Add(ProductAttributes[Item].ProductKind);
		EndDo;

		ListOfProperties = GetSourcePropertiesForCalculationUsingFormulas(SetsList);
		ListOfProductProperties_ = GetProductPropertiesToCalculateUsingFormulas(ListOfProductKinds);
	
	EndIf;
	
	TypesOfOperands = ProcessingOfFormulas.TypesOfOperandTreeElements();
	
	For Each KeyAndValue In DescriptionOfSources Do
		
		Var_Key = KeyAndValue.Key;
		SourceDetails = KeyAndValue.Value; // See CreateDescriptionsOfOperandDataSource
		
		SourceOperands_ = New Array;
		
		If SourceDetails.Collection Then
			
			Table = Object[Var_Key]; // CatalogTabularSection.BillsOfMaterials.MaterialsAndServices
			
			For Each String In Table Do
				
				If TSName = Var_Key And RowData <> Undefined And RowData.LineNumber <= String.LineNumber Then
					Continue;
				EndIf;
				
				RowID = StrTemplate("%1[%2].", SourceDetails.Id, Format(String.LineNumber, "NZ=; NG="));
				LinePresentation = StrTemplate(NStr("vi = 'Dòng[%1].';
													|ru = 'Строка[%1].';
													|en = 'Line[%1].'; fa = 'Line[%1].';
													|it = 'Riga [%1].';
													|pl = 'Wiersz[%1].';
													|tr = 'Satır[%1].'"), Format(String.LineNumber, "NZ=; NG="));
				
				For Each Attribute In SourceDetails.Attributes Do
					OperandProperties = StructureOfDataSourceOperandConstructor();
					OperandProperties.LineNumber   = String.LineNumber;
					OperandProperties.Id = RowID + Attribute.Id;
					OperandProperties.Presentation = LinePresentation + Attribute.Presentation;
					OperandProperties.ValueType   = Attribute.ValueType;
					OperandProperties.OperandType_   = TypesOfOperands.Attribute;
					SourceOperands_.Add(OperandProperties);
				EndDo;
				
				If UseAdditionalAttributesAndInfo Then
				
					If SourceDetails.ContainsProperties Then
						
						FoundProperties = ListOfProperties.FindRows(New Structure("Ref",
							SourceDetails.PropertiesSet));
							
						For Each Property In FoundProperties Do
							If PropertyHasValidTypeForOperand(Property) Then
								OperandProperties = StructureOfDataSourceOperandConstructor();
								OperandProperties.LineNumber   = String.LineNumber;
								OperandProperties.Id = RowID + Property.Id;
								OperandProperties.Presentation = LinePresentation + Property.Presentation;
								OperandProperties.ValueType   = Property.ValueType;
								OperandProperties.OperandType_   = TypesOfOperands.AdditionalAttribute;
								SourceOperands_.Add(OperandProperties);
							EndIf;
						EndDo;
						
					EndIf;
					
					If SourceDetails.ContainsProductProperties And ValueIsFilled(String.Products) Then
						
						FoundProperties = ListOfProductProperties_.FindRows(New Structure("Kind",
							ProductAttributes[String.Products].ProductKind));
							
						For Each Property In FoundProperties Do
							If PropertyHasValidTypeForOperand(Property) Then
								OperandProperties = StructureOfDataSourceOperandConstructor();
								OperandProperties.LineNumber   = String.LineNumber;
								OperandProperties.Id = RowID + Property.Id;
								OperandProperties.Presentation = LinePresentation + Property.Presentation;
								OperandProperties.ValueType   = Property.ValueType;
								OperandProperties.OperandType_   = TypesOfOperands.AdditionalAttribute;
								SourceOperands_.Add(OperandProperties);
							EndIf;
						EndDo;
						
					EndIf;
					
				EndIf;
				
			EndDo;
			
		Else
			
			If Not IsBlankString(SourceDetails.TSName) And SourceDetails.TSName <> TSName Then 
				Continue;
			EndIf;
			
			For Each Attribute In SourceDetails.Attributes Do
				OperandProperties = StructureOfDataSourceOperandConstructor();
				OperandProperties.Id = SourceDetails.Id+"."+Attribute.Id;
				OperandProperties.Presentation = Attribute.Presentation;
				OperandProperties.ValueType   = Attribute.ValueType;
				OperandProperties.OperandType_   = TypesOfOperands.Attribute;
				SourceOperands_.Add(OperandProperties);
			EndDo;
				
			If UseAdditionalAttributesAndInfo Then
				
				If SourceDetails.ContainsProperties Then
					FoundProperties = ListOfProperties.FindRows(New Structure("Ref", SourceDetails.PropertiesSet));
					For Each Property In FoundProperties Do
						If PropertyHasValidTypeForOperand(Property) Then
							OperandProperties = StructureOfDataSourceOperandConstructor();
							OperandProperties.Id = SourceDetails.Id+"."+Property.Id;
							OperandProperties.Presentation = Property.Presentation;
							OperandProperties.ValueType   = Property.ValueType;
							OperandProperties.OperandType_   = TypesOfOperands.AdditionalAttribute;
							SourceOperands_.Add(OperandProperties);
						EndIf;
					EndDo;
				EndIf;
				
				If SourceDetails.ContainsProductProperties Then
					
					ProductKind = Undefined;
					If SourceDetails.TSName <> "" And RowData <> Undefined Then
						TSRow = Object[SourceDetails.TSName][RowData.LineNumber-1];
						If ValueIsFilled(TSRow.Products) Then
							ProductKind = ProductAttributes[TSRow.Products].ProductKind;
						EndIf;
					ElsIf SourceDetails.SourceOfProductProperties <> Undefined Then
						If TypeOf(SourceDetails.SourceOfProductProperties) = Type("CatalogRef.Products") Then
							ProductKind = ProductAttributes[SourceDetails.SourceOfProductProperties].ProductKind;
						Else
							ProductKind = SourceDetails.SourceOfProductProperties;
						EndIf;
					EndIf;
					
					FoundProperties = ListOfProductProperties_.FindRows(New Structure("Kind", ProductKind));
					For Each Property In FoundProperties Do
						If PropertyHasValidTypeForOperand(Property) Then
							OperandProperties = StructureOfDataSourceOperandConstructor();
							OperandProperties.Id = SourceDetails.Id+"."+Property.Id;
							OperandProperties.Presentation = Property.Presentation;
							OperandProperties.ValueType   = Property.ValueType;
							OperandProperties.OperandType_   = TypesOfOperands.AdditionalAttribute;
							SourceOperands_.Add(OperandProperties);
						EndIf;
					EndDo;
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
		If SourceOperands_.Count() Then
			
			OperandsTable = DataSourceOperandTableConstructor();
			
			For Each Operand In SourceOperands_ Do
				FillPropertyValues(OperandsTable.Add(), Operand);
			EndDo;
			
			OperandsTable.Indexes.Add("LineNumber");
			OperandsTable.Indexes.Add("Id");
			
			SourceDetails.Insert("Operands", OperandsTable);
			
		EndIf;
		
	EndDo;
	
EndProcedure

Function PropertyHasValidTypeForOperand(Property)
	
	Return ValueIsFilled(Property.ValueType)
		And (Property.ValueType.ContainsType(Type("Number"))
			Or Property.ValueType.ContainsType(Type("String"))
			Or Property.ValueType.ContainsType(Type("Date")));
	
EndFunction

#EndRegion

#Region Other

Procedure UpdateAutoCalculationData(String, DataForCalculation, FieldName)

	If (DataForCalculation.AutoCalculation.Count() = 0
			Or String.Owner().Columns.Find("ConnectionKey") = Undefined
		) Then
		
		Return;
	EndIf;
	
	Parameters = DataForCalculation.AutoCalculation[String.ConnectionKey];
	If Parameters <> Undefined Then
		For Each ParameterName In Parameters Do
			DataForCalculation.Parameters[ParameterName] = String[FieldName];
		EndDo;
	EndIf;
	
EndProcedure

Function AutoselectionAlgorithmExecutionParameters(ItemData_3, ProductPropertyValues, DataSetRow)
	
	Parameters = New Structure("Products, BillOfMaterials, ReferenceOrder");
	
	Parameters.Products = DataSetRow.Products;
	
	FillPropertyValues(Parameters, ItemData_3,, "Products");
	
	MainProduct = New Structure("Products, Characteristic, PropertiesValues");
	
	FillPropertyValues(MainProduct, ItemData_3, "Products, Characteristic");
	
	MainProduct.PropertiesValues = New Map;
	For Each String In ProductPropertyValues Do
		MainProduct.PropertiesValues.Insert(String.IDProperty, String.Value);
	EndDo;
	
	Parameters.Insert("MainProduct", MainProduct);
	
	Return Parameters;
	
EndFunction

// Constructor of the table of sources of parameter values for calculation using formulas
// 
// Returns:
// 	ValueTable - From:
// * Processed - Boolean - whether the object is being processed
// * Object - CatalogRef.Products,CatalogRef.ItemsCharacteristics,CatalogRef.LinesOfBusiness,CatalogRef.BusinessStructure,DocumentRef.ProductionOrder2_2 - 
// * HeaderProperty - String - the caption property
// * DataPath - Structure - 
Function CreateTableOfSourcesOfParameterValuesForCalculationByFormulas() Export

	ObjectTypes_ = "
	|CatalogRef.Products,
	|CatalogRef.ItemsCharacteristics,
	|CatalogRef.LinesOfBusiness,
	|CatalogRef.BusinessStructure,
	|CatalogRef.BillsOfMaterials,
	|DocumentRef.ProductionOrder2_2";
	
	SourcesOfParameterValues = New ValueTable;
	SourcesOfParameterValues.Columns.Add("Processed",        New TypeDescription("Boolean"));
	SourcesOfParameterValues.Columns.Add("Object",            New TypeDescription(ObjectTypes_));
	SourcesOfParameterValues.Columns.Add("IDProperty", New TypeDescription("String",,,,New StringQualifiers(100)));
	SourcesOfParameterValues.Columns.Add("DataPath");
	
	Return SourcesOfParameterValues;
	
EndFunction

Procedure SupplementTableOfSourcesOfParameterValuesForCalculationByFormulas(
	Manager,
	SourcesOfParameterValues,
	DataSources,
	DescriptionOfSources,
	ParametersForCalculation) Export
	
	For Each DataPath In ParametersForCalculation Do
		
		LongDesc = Undefined;
		If IsBlankString(DataPath.Key)
			Or Not DescriptionOfSources.Property(DataPath.Key, LongDesc) Then
			Continue;
		EndIf;
		
		If DataPathContainsSourceDetails(DataPath, LongDesc) Then
			Continue;
		EndIf;
		
		CurSource = Manager.DataSourceForFormulaCalculations(DataPath, DataSources);
		If Not ValueIsFilled(CurSource) Then
			Continue;
		EndIf;
		
		If LongDesc.ContainsProductProperties Then
			
			AddEntryToParameterValueSourceTable(
				SourcesOfParameterValues,
				CurSource.Products,
				DataPath);
			
			If ValueIsFilled(CurSource.Characteristic) Then
				
				AddEntryToParameterValueSourceTable(
					SourcesOfParameterValues,
					CurSource.Characteristic,
					DataPath);
				
			EndIf;
				
		ElsIf LongDesc.ContainsProperties Then
			
			AddEntryToParameterValueSourceTable(
				SourcesOfParameterValues,
				CurSource,
				DataPath);
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Adds an entry to the parameter value source table
// 
// Parameters:
// 	SourcesOfParameterValues - See CreateTableOfSourcesOfParameterValuesForCalculationByFormulas
// 	Object - CatalogRef.Products,CatalogRef.ItemsCharacteristics,CatalogRef.LinesOfBusiness,CatalogRef.BusinessStructure,DocumentRef.ProductionOrder2_2 -
// 	DataPath - Structure - 
Procedure AddEntryToParameterValueSourceTable(SourcesOfParameterValues, Object, DataPath) Export
	
	DataPath.Found = True;
	
	NewRow = SourcesOfParameterValues.Add();
	NewRow.Object                = Object;
	NewRow.IDProperty = DataPath.PropertyName;
	NewRow.DataPath           = DataPath;
	
EndProcedure

// Add a table for formula calculation to an array of tables
// 
// Parameters:
//  ArrayOfTables - Array of ValueTable
//  StructureOfData - Structure
//  TSName - String
Procedure AddTableForCalculationByFormulas(ArrayOfTables, StructureOfData, TSName) Export
	
	Filter = New Structure("QuantityCalculationAlgorithm", "");
	
	If StructureOfData.Property(TSName)
		And StructureOfData[TSName].FindRows(Filter).Count() <> StructureOfData[TSName].Count() Then
		
		If StructureOfData[TSName].Columns.Find("Formula") = Undefined Then
			StructureOfData[TSName].Columns.Add("Formula", New TypeDescription("String"));
			StructureOfData[TSName].Columns.Add("FormulaCalculationError", New TypeDescription("String"));
		EndIf;
		
		ArrayOfTables.Add(StructureOfData[TSName]);
		
	EndIf;
	
EndProcedure

Procedure CalculateNumberInRows(StructureOfData, TSName, ThereArePackages, DataForCalculation) Export
	
	If StructureOfData.Property(TSName) Then
		
		For Each String In StructureOfData[TSName] Do
			
			If Not IsBlankString(String.QuantityCalculationAlgorithm) Then
				
				CalculateQuantityUsingFormula(String, DataForCalculation);
				
				If ThereArePackages Then
					
					BatchProcessingOfTablePartServer.ProcessTSString(String, New Structure("RecalculateNumberOfPackages"), Undefined);
					
				EndIf;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure

// Fills in parameter values for calculation using formulas
// 
// Parameters:
// 	SourcesOfParameterValues - See CreateTableOfSourcesOfParameterValuesForCalculationByFormulas
Procedure FillInParameterValuesForCalculationByFormulas(SourcesOfParameterValues) Export
	
	If SourcesOfParameterValues = Undefined Then
		Return;
	EndIf;
	
	KeyFields = "Object,IDProperty";
	
	SourcesOfParameterValues.Indexes.Add(KeyFields);
	
	SourcesOfConvolutionParameterValues = SourcesOfParameterValues.Copy(,KeyFields);
	SourcesOfConvolutionParameterValues.GroupBy(KeyFields);
	DescriptionOfTypesID = SourcesOfConvolutionParameterValues.Columns["IDProperty"].ValueType;
	SourcesOfConvolutionParameterValues.Columns.Add("IDInTable", DescriptionOfTypesID);
	For Each TableRow In SourcesOfConvolutionParameterValues Do
		TableRow.IDInTable = ProcessingOfFormulas.PropertiesCharacteristics(
			TableRow.IDProperty).Id;
	EndDo;
	
	QueryText = 
	"SELECT
	|	T.Object            AS Object,
	|	T.IDProperty AS IDProperty,
	|	T.IDInTable AS IDInTable
	|INTO SourcesOfParameterValues
	|FROM
	|	&SourcesOfParameterValues AS T
	|INDEX BY
	|	IDInTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SourcesOfParameterValues.Object            AS Object,
	|	AdditionalAttributesAndInfo.Ref       AS Property,
	|	SourcesOfParameterValues.IDProperty AS IDProperty
	|INTO ValueSources
	|FROM
	|	SourcesOfParameterValues AS SourcesOfParameterValues
	|		LEFT JOIN ChartOfCharacteristicTypes.AdditionalAttributesAndInfo AS AdditionalAttributesAndInfo
	|		ON SourcesOfParameterValues.IDInTable = &ExpressionOfIDOfBankingDetailsInFormulas
	|
	|INDEX BY
	|	Object,
	|	Property
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|
	|SELECT
	|	1                                   AS Priority,
	|	ValueSources.Object            AS Object,
	|	ValueSources.IDProperty AS IDProperty,
	|	AdditionalAttributes.Value    AS Value
	|FROM
	|	Catalog.LinesOfBusiness.AdditionalAttributes AS AdditionalAttributes
	|		INNER JOIN ValueSources AS ValueSources
	|		ON AdditionalAttributes.Ref = ValueSources.Object
	|			AND AdditionalAttributes.Property = ValueSources.Property
	|
	|UNION ALL
	|	
	|SELECT
	|	2,
	|	ValueSources.Object,
	|	ValueSources.IDProperty,
	|	AdditionalAttributes.Value
	|FROM
	|	Catalog.BusinessStructure.AdditionalAttributes AS AdditionalAttributes
	|		INNER JOIN ValueSources AS ValueSources
	|		ON AdditionalAttributes.Ref = ValueSources.Object
	|			AND AdditionalAttributes.Property = ValueSources.Property
	|
	|UNION ALL
	|
	|SELECT
	|	3,
	|	ValueSources.Object,
	|	ValueSources.IDProperty,
	|	AdditionalAttributes.Value
	|FROM
	|	Document.ProductionOrder2_2.AdditionalAttributes AS AdditionalAttributes
	|		INNER JOIN ValueSources AS ValueSources
	|		ON AdditionalAttributes.Ref = ValueSources.Object
	|			AND AdditionalAttributes.Property = ValueSources.Property
	|
	|UNION ALL
	|
	|SELECT
	|	4,
	|	ValueSources.Object,
	|	ValueSources.IDProperty,
	|	AdditionalAttributes.Value
	|FROM
	|	Catalog.Products.AdditionalAttributes AS AdditionalAttributes
	|		INNER JOIN ValueSources AS ValueSources
	|		ON AdditionalAttributes.Ref = ValueSources.Object
	|			AND AdditionalAttributes.Property = ValueSources.Property
	|
	|UNION ALL
	|
	|SELECT
	|	5,
	|	ValueSources.Object,
	|	ValueSources.IDProperty,
	|	AdditionalAttributes.Value
	|FROM
	|	Catalog.ItemsCharacteristics.AdditionalAttributes AS AdditionalAttributes
	|		INNER JOIN ValueSources AS ValueSources
	|		ON AdditionalAttributes.Ref = ValueSources.Object
	|			AND AdditionalAttributes.Property = ValueSources.Property
	|
	|UNION ALL
	|	
	|SELECT
	|	6,
	|	ValueSources.Object,
	|	ValueSources.IDProperty,
	|	AdditionalAttributes.Value
	|FROM
	|	Catalog.BillsOfMaterials.AdditionalAttributes AS AdditionalAttributes
	|		INNER JOIN ValueSources AS ValueSources
	|		ON AdditionalAttributes.Ref = ValueSources.Object
	|			AND AdditionalAttributes.Property = ValueSources.Property
	|
	|ORDER BY
	|	Priority";
	
	IdentifierExpression = StringFunctionsClientServer.SubstituteParametersToString(
		"AdditionalAttributesAndInfo.%1",
		ProcessingOfFormulas.IdFieldForAdditionalBankingDetails());
	QueryText = StrReplace(QueryText, "&ExpressionOfIDOfBankingDetailsInFormulas", IdentifierExpression);
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("SourcesOfParameterValues", SourcesOfConvolutionParameterValues);
	
	FilterStructure1 = New Structure(KeyFields);
	
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	SetPrivilegedMode(False);
	
	While Selection.Next() Do
		
		FillPropertyValues(FilterStructure1, Selection);
		
		FoundRows = SourcesOfParameterValues.FindRows(FilterStructure1);
		For Each FoundRow In FoundRows Do
			
			If FoundRow.Processed Then
				Continue;
			EndIf;
			
			FoundRow.DataPath.Value = Selection.Value;
			FoundRow.Processed           = True;
			
		EndDo;
		
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#Region SelectionByProperties

Function PropertySourcesForPropertySelection()
	
	Result = New Array;
	
	Result.Add("Products");
	Result.Add("Characteristic");
	Result.Add("LineOfBusiness");
	
	Return Result;
	
EndFunction

Function TableOfSelectionValuesByProperties() Export
	
	Result = New ValueTable;
	
	Result.Columns.Add("Property");
	Result.Columns.Add("Condition");
	Result.Columns.Add("Value");
	Result.Columns.Add("Value1");
	Result.Columns.Add("Value2");
	
	Return Result;
	
EndFunction

Function ValuesOfSpecificationsApplicationConstraints(Specifications) Export
	
	Result = New Map;
	
	QueryText = "
	|SELECT
	|	T.Property    AS Property,
	|	T.Condition     AS Condition,
	|	T.Value    AS Value,
	|	T.Ref      AS BillOfMaterials,
	|	T.LineNumber AS LineNumber
	|FROM
	|	Catalog.BillsOfMaterials.SelectionByProperties AS T
	|WHERE
	|	T.Ref IN (&Specifications)
	|	AND T.ConnectionKey IN (&CommunicationKeyProducts, &CommunicationKeyCharacteristic)
	|
	|ORDER BY
	|	BillOfMaterials,
	|	LineNumber
	|";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Specifications", Specifications);
	Query.SetParameter("CommunicationKeyProducts",   ProductDataManagementClientServer.SelectionByPropertiesOfCommunicationKey("Products"));
	Query.SetParameter("CommunicationKeyCharacteristic", ProductDataManagementClientServer.SelectionByPropertiesOfCommunicationKey("Characteristic"));
	
	SettingValues = Query.Execute().Unload();
	SettingValues.Indexes.Add("BillOfMaterials");
	For Each BillOfMaterials In Specifications Do
		
		SpecificationSettingsValues = SettingValues.Copy(New Structure("BillOfMaterials", BillOfMaterials));
		SpecificationSettingsValues.Sort("LineNumber");
		
		ValuesOfSpecificationApplicationConstraints = TableOfSelectionValuesByProperties();
		FillInListOfSelectionsByProperties(ValuesOfSpecificationApplicationConstraints, SpecificationSettingsValues, True);
		
		Result.Insert(BillOfMaterials, ValuesOfSpecificationApplicationConstraints);
		
	EndDo;
	
	Return Result;
	
EndFunction

// Sets the conditional design of the selection table by properties
// 
// Parameters:
// 	ConditionalAppearance - DataCompositionConditionalAppearance - conditional form design
Procedure SetConditionalAppearanceOfSelectionTableByProperties(ConditionalAppearance) Export
	
	TableName = "SelectionByProperties";
	
	// terms of use
	
	ConditionsFullness = New ValueList;
	ConditionsInterval      = New ValueList;
	
	ConditionsStructure = ProductDataManagementClientServer.StructureOfSelectionConditionsByProductProperties();
	For Each KeyAndValue In ConditionsStructure Do
		
		Condition = KeyAndValue.Value; // See ProductDataManagementClientServer.StructureOfSelectionConditionByProductProperties
		
		Item = ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField("Condition");
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue  = New DataCompositionField(StrTemplate("%1.Condition", TableName));
		ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = Condition.Id;
		
		Item.Appearance.SetParameterValue("Text", Condition.Presentation);
		
		If Condition.Fullness Then
			ConditionsFullness.Add(Condition.Id);
		EndIf;
		
		If Condition.Interval Then
			ConditionsInterval.Add(Condition.Id);
		EndIf;
		
	EndDo;
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("Condition");
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("Value");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(StrTemplate("%1.Property", TableName));
	ItemFilter.ComparisonType  = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	// selection by properties in the interval
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("GroupRange");
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("Value1");
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("Value2");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField(StrTemplate("%1.Condition", TableName));
	ItemFilter.ComparisonType   = DataCompositionComparisonType.NotInList;
	ItemFilter.RightValue = ConditionsInterval;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("Value");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField(StrTemplate("%1.Condition", TableName));
	ItemFilter.ComparisonType   = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = ConditionsInterval;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	// selection by properties on filled, not filled
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("Value");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField(StrTemplate("%1.Condition", TableName));
	ItemFilter.ComparisonType   = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = ConditionsFullness;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("Text", "");
	
EndProcedure

Procedure FillInListOfSelectionsByProperties(DataTable, SettingsTable, ConditionByStructure = False) Export
	
	GroupingSettings_ = New Structure;
	
	GroupingSettings_.Insert("InList",
							New Structure("Supplement, Result", "InList", "InList"));
	GroupingSettings_.Insert("NotInList",
							New Structure("Supplement, Result", "NotInList", "NotInList"));
	GroupingSettings_.Insert("Less",
							New Structure("Supplement, Result", "Greater", "InInterval"));
	GroupingSettings_.Insert("LessOrEqual",
							New Structure("Supplement, Result", "GreaterOrEqual", "InIntervalIncluding"));
	
	CurrentRow = Undefined;
	
	For Each Item In SettingsTable Do
		
		Setting = New Structure; // see Production Server.Service structuresstructures - 
		If GroupingSettings_.Property(Item.Condition, Setting)
			And CurrentRow <> Undefined
			And CurrentRow.Property = Item.Property 
			And CurrentRow.Condition = Setting.Supplement Then
			
			If Setting.Supplement = Setting.Result Then
				CurrentRow.Value.Add(Item.Value);
			Else
				CurrentRow.Value1 = CurrentRow.Value;
				CurrentRow.Value2 = Item.Value;
				CurrentRow.Condition   = Setting.Result;
				CurrentRow = Undefined;
			EndIf;
			
		Else
			CurrentRow = DataTable.Add();
			CurrentRow.Property = Item.Property;
			CurrentRow.Condition  = Item.Condition;
			If Setting <> Undefined And Setting.Supplement = Setting.Result Then
				CurrentRow.Value = New ValueList;
				CurrentRow.Value.ValueType = Item.Property.ValueType;
				CurrentRow.Value.Add(Item.Value);
			Else
				CurrentRow.Value = Item.Value;
			EndIf;
		EndIf;
		
	EndDo;
	
	If ConditionByStructure Then
		ConditionsStructure = ProductDataManagementClientServer.StructureOfSelectionConditionsByProductProperties();
		For Each CurrentRow In DataTable Do
			CurrentRow.Condition = ConditionsStructure[CurrentRow.Condition];
		EndDo;
	EndIf;
	
EndProcedure

Procedure CreateTTSelectionBasedOnProperties(ObjectReference, TempTablesManager, ItemData_3 = Undefined) Export
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	
	If ItemData_3 = Undefined Then
		Query.Text = "
		|SELECT
		|	0                 AS Id,
		|	&EmptyLinkKey  AS ConnectionKey,
		|	FALSE              AS Used
		|INTO TT_SelectionByProperties
		|";
		Query.SetParameter("EmptyLinkKey", CommonClientServer.BlankUUID());
	Else
		Query.Text = QueryTextTTSelectionBasedOnPropertiesOfSetting(ObjectReference)
			+ Common.QueryBatchSeparator()
			+ QueryTextTTSelectionByProperties("TTSelectionBySettingProperties");
		Query.SetParameter("Ref",                     ObjectReference);
		Query.SetParameter("Products",               ItemData_3.Products);
		Query.SetParameter("Characteristic",             ItemData_3.Characteristic);
		Query.SetParameter("LineOfBusiness",    ItemData_3.LineOfBusiness);
		Query.SetParameter("UseParameterization", GetFunctionalOption("UseBillOfMaterialsParameterization"));
	EndIf;
	
	SetPrivilegedMode(True);
	Query.Execute();
	SetPrivilegedMode(False);
	
EndProcedure

// Query Text of the temporary table of selection settings by properties
// 
// Parameters:
//  ObjectReference - CatalogRef.BillsOfMaterials - reference to the object for which the request is being generated
// 
// Returns:
//  String - Query text
Function QueryTextTTSelectionBasedOnPropertiesOfSetting(ObjectReference) Export
	
	QueryText =
	"SELECT
	|	0                          AS Id,
	|	SelectionByProperties.ConnectionKey AS ConnectionKey,
	|	SelectionByProperties.Property  AS Property,
	|	SelectionByProperties.Condition   AS Condition,
	|	SelectionByProperties.Value  AS ValueSelection,
	|
	|	CASE
	|		WHEN NOT ValuesForAdditionalCharacteristicDetails.Value IS NULL
	|			THEN ValuesForAdditionalCharacteristicDetails.Value
	|		WHEN NOT ValuesForAdditionalProductItemDetails.Value IS NULL
	|			THEN ValuesForAdditionalProductItemDetails.Value
	|		WHEN NOT ValuesOfAdditionalDetailsOfAreasOfActivity.Value IS NULL
	|			THEN ValuesOfAdditionalDetailsOfAreasOfActivity.Value
	|		ELSE
	|			CASE
	|				WHEN VALUETYPE(SelectionByProperties.Value) = TYPE(BOOLEAN)
	|					THEN FALSE
	|				WHEN VALUETYPE(SelectionByProperties.Value) = TYPE(NUMBER)
	|					THEN 0
	|				ELSE UNDEFINED
	|			END
	|	END                                     AS PropertyValue
	|
	|INTO TTSelectionBySettingProperties
	|FROM
	|	Catalog.BillsOfMaterials.SelectionByProperties AS SelectionByProperties
	|
	|		LEFT JOIN Catalog.Products.AdditionalAttributes AS ValuesForAdditionalProductItemDetails
	|		ON SelectionByProperties.Property = ValuesForAdditionalProductItemDetails.Property
	|			AND (ValuesForAdditionalProductItemDetails.Ref = &Products)
	|
	|		LEFT JOIN Catalog.ItemsCharacteristics.AdditionalAttributes AS ValuesForAdditionalCharacteristicDetails
	|		ON SelectionByProperties.Property = ValuesForAdditionalCharacteristicDetails.Property
	|			AND (ValuesForAdditionalCharacteristicDetails.Ref = &Characteristic)
	|
	|		LEFT JOIN Catalog.LinesOfBusiness.AdditionalAttributes AS ValuesOfAdditionalDetailsOfAreasOfActivity
	|		ON SelectionByProperties.Property = ValuesOfAdditionalDetailsOfAreasOfActivity.Property
	|			AND (ValuesOfAdditionalDetailsOfAreasOfActivity.Ref = &LineOfBusiness)
	|
	|WHERE
	|	SelectionByProperties.Ref = &Ref
	|	AND &UseParameterization
	|";
	
	If TypeOf(ObjectReference) = Type("CatalogRef.RouteSheets") Then
		QueryText = StrReplace(QueryText, "BillsOfMaterials", "RouteSheets");
	ElsIf TypeOf(ObjectReference) = Type("CatalogRef.TechnologicalProcesses") Then
		QueryText = StrReplace(QueryText, "BillsOfMaterials", "TechnologicalProcesses");
	EndIf;
	
	Return QueryText;
	
EndFunction

// Query Text of the temporary selection table by properties
// 
// Parameters:
//  NameOfSettingsTable - String - Name Of The Settings Table
// 
// Returns:
//  String - Query text
Function QueryTextTTSelectionByProperties(NameOfSettingsTable) Export
	
	QueryText = "
	|SELECT
	|	NestedQuery.Id         AS Id,
	|	NestedQuery.ConnectionKey             AS ConnectionKey,
	|	MIN(NestedQuery.Used) AS Used
	|INTO TT_SelectionByProperties
	|FROM
	|	(SELECT
	|		TTSelectionBySettingProperties.Id  AS Id,
	|		TTSelectionBySettingProperties.ConnectionKey      AS ConnectionKey,
	|		CASE TTSelectionBySettingProperties.Condition
	|			WHEN ""Equal""
	|				THEN TTSelectionBySettingProperties.PropertyValue = TTSelectionBySettingProperties.ValueSelection
	|			WHEN ""NotEqual""
	|				THEN TTSelectionBySettingProperties.PropertyValue <> TTSelectionBySettingProperties.ValueSelection
	|			WHEN ""Greater""
	|				THEN TTSelectionBySettingProperties.PropertyValue > TTSelectionBySettingProperties.ValueSelection
	|			WHEN ""GreaterOrEqual""
	|				THEN TTSelectionBySettingProperties.PropertyValue >= TTSelectionBySettingProperties.ValueSelection
	|			WHEN ""Less""
	|				THEN TTSelectionBySettingProperties.PropertyValue < TTSelectionBySettingProperties.ValueSelection
	|			WHEN ""LessOrEqual""
	|				THEN TTSelectionBySettingProperties.PropertyValue <= TTSelectionBySettingProperties.ValueSelection
	|			WHEN ""InList""
	|				THEN TTSelectionBySettingProperties.PropertyValue IN
	|						(&SelectionTextInList)
	|			WHEN ""NotInList""
	|				THEN TTSelectionBySettingProperties.PropertyValue <> TTSelectionBySettingProperties.ValueSelection
	|			WHEN ""Filled""
	|				THEN NOT TTSelectionBySettingProperties.PropertyValue IN (UNDEFINED, FALSE, 0)
	|			WHEN ""NotFilled""
	|				THEN TTSelectionBySettingProperties.PropertyValue IN (UNDEFINED, FALSE, 0)
	|			ELSE FALSE
	|		END AS Used
	|	FROM
	|		&TTSelectionBySettingProperties AS TTSelectionBySettingProperties) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.Id,
	|	NestedQuery.ConnectionKey
	|
	|INDEX BY
	|	Id,
	|	ConnectionKey";
	
	SelectionTextInList = "
	|						SELECT
	|							T.ValueSelection AS ValueSelection
	|						FROM
	|							&TTSelectionBySettingProperties AS T
	|						WHERE
	|							T.Condition           = ""InList""
	|							AND T.Property        = TTSelectionBySettingProperties.Property
	|							AND T.Id   = TTSelectionBySettingProperties.ID
	|							AND T.ConnectionKey       = TTSelectionBySettingProperties.ConnectionKey";
	
	QueryText = StrReplace(QueryText, "&SelectionTextInList",          SelectionTextInList);
	QueryText = StrReplace(QueryText, "&TTSelectionBySettingProperties", NameOfSettingsTable);
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region Other

Function RequestTextAvailableProductProperties(OnlyValidOnes = True, ProductPropertiesAvailable = True, AvailablePropertiesCharacteristics = True)
	
	QueryTexts = New Array();
	
	QueryTexts.Add(
	"SELECT
	|	VALUE(Catalog.ItemKinds.EmptyRef)                             AS Kind,
	|	VALUE(ChartOfCharacteristicTypes.AdditionalAttributesAndInfo.EmptyRef) AS Property
	|WHERE
	|	FALSE
	|");
	
	If ProductPropertiesAvailable Then
		
		// Additional details common to the nomenclature
		QueryTexts.Add(
		"SELECT
		|	ItemKinds.Ref AS Kind,
		|	PropertiesTable.Property AS Property
		|FROM
		|	Catalog.ItemKinds AS ItemKinds
		|		INNER JOIN Catalog.AdditionalAttributesAndInfoSets.AdditionalAttributes AS PropertiesTable
		|		ON TRUE
		|WHERE
		|	ItemKinds.Ref IN (&ItemKinds)
		|	AND PropertiesTable.Ref = &Set_Catalog_Products_Overall
		|	AND &OnlyValidOnes");
		
		// Additional details of the type of nomenclature
		QueryTexts.Add(
		"SELECT
		|	ItemKinds.Ref AS Kind,
		|	PropertiesTable.Property AS Property
		|FROM
		|	Catalog.ItemKinds AS ItemKinds
		|		INNER JOIN Catalog.AdditionalAttributesAndInfoSets.AdditionalAttributes AS PropertiesTable
		|		ON ItemKinds.PropertiesSet = PropertiesTable.Ref
		|WHERE
		|	ItemKinds.Ref IN (&ItemKinds)
		|	AND &OnlyValidOnes");
		
	EndIf;
	
	If AvailablePropertiesCharacteristics Then
	
		// Additional details are common to all characteristics
		QueryTexts.Add(
		"SELECT
		|	ItemKinds.Ref AS Kind,
		|	PropertiesTable.Property AS Property
		|FROM
		|	Catalog.ItemKinds AS ItemKinds
		|		INNER JOIN Catalog.AdditionalAttributesAndInfoSets.AdditionalAttributes AS PropertiesTable
		|		ON TRUE
		|WHERE
		|	ItemKinds.Ref IN (&ItemKinds) 
		|	AND ItemKinds.UseCharacteristics
		|	AND PropertiesTable.Ref = &Set_Catalog_ItemsCharacteristics_Overall
		|	AND &OnlyValidOnes");
		
		// Additional details of the characteristics of the type of nomenclature
		QueryTexts.Add(
		"SELECT
		|	ItemKinds.Ref AS Kind,
		|	PropertiesTable.Property AS Property
		|FROM
		|	Catalog.ItemKinds AS ItemKinds
		|		INNER JOIN Catalog.AdditionalAttributesAndInfoSets.AdditionalAttributes AS PropertiesTable
		|		ON (CASE
		|				WHEN ItemKinds.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind)
		|					THEN ItemKinds.ItemVariantsOwner.CharacteristicsPropertySet
		|				ELSE ItemKinds.CharacteristicsPropertySet
		|			END = PropertiesTable.Ref)
		|WHERE
		|	ItemKinds.Ref IN(&ItemKinds)
		|	AND &OnlyValidOnes");
	
	EndIf;
	
	QueryText = StrConcat(QueryTexts, Chars.LF + " UNION " + Chars.LF);
	
	If OnlyValidOnes Then
		QueryText = StrReplace(QueryText, "AND &OnlyValidOnes", "AND NOT PropertiesTable.DeletionMark");
	Else
		QueryText = StrReplace(QueryText, "AND &OnlyValidOnes", "");
	EndIf;
	
	QueryText = StrReplace("
	|SELECT
	|	T.Kind                                     AS Kind,
	|	T.Property                                AS Property,
	|	PRESENTATION(T.Property)                 AS Presentation,
	|	T.Property.ValueType                    AS ValueType,
	|	T.Property.AdditionalValuesOwner AS AdditionalValuesOwner,
	|	T.Property.DeletionMark                AS DeletionMark,
	|	&IdentifierExpression                  AS Id
	|FROM
	|	&QueryText AS T", "&QueryText", "(" + QueryText + ")");
	
	MDAdditionalBankingDetails = Metadata.ChartsOfCharacteristicTypes.AdditionalAttributesAndInfo;
	IdentifierExpression = ProcessingOfFormulas.ExpressionOfFullFeatureID(MDAdditionalBankingDetails, False);
	IdentifierExpression = StrReplace(IdentifierExpression, "%TableName%", "T.Property");
	QueryText = StrReplace(QueryText, "&IdentifierExpression", IdentifierExpression);
	
	Return QueryText;
	
EndFunction

Function RequestTextAvailableSourceProperties(OnlyValidOnes = True)
	
	QueryText = "
	|SELECT
	|	T.Ref               AS Ref,
	|	T.Property             AS Property,
	|	PRESENTATION(T.Property)   AS Presentation,
	|	&IdentifierExpression    AS Id,
	|	T.Property.ValueType AS ValueType
	|FROM
	|	Catalog.AdditionalAttributesAndInfoSets.AdditionalAttributes AS T
	|INNER JOIN
	|	ChartOfCharacteristicTypes.AdditionalAttributesAndInfo AS AddlAttributesTable
	|ON
	|	T.Property = AddlAttributesTable.Ref
	|WHERE
	|	T.Ref IN (&SetsList)
	|	AND &OnlyValidOnes
	|";
	
	MDAdditionalBankingDetails = Metadata.ChartsOfCharacteristicTypes.AdditionalAttributesAndInfo;
	IdentifierExpression = ProcessingOfFormulas.ExpressionOfFullFeatureID(MDAdditionalBankingDetails, False);
	IdentifierExpression = StrReplace(IdentifierExpression, "%TableName%", "AddlAttributesTable");
	QueryText = StrReplace(QueryText, "&IdentifierExpression", IdentifierExpression);
	
	If OnlyValidOnes Then
		QueryText = StrReplace(QueryText, "AND &OnlyValidOnes", "AND NOT AddlAttributesTable.DeletionMark");
	Else
		QueryText = StrReplace(QueryText, "AND &OnlyValidOnes", "");
	EndIf;
	
	Return QueryText;
	
EndFunction

#EndRegion

#EndRegion

#Region BOMsTree

Procedure FillInSpecificationTree(Parameters, Tree)
	
	Tree.Rows.Clear();
	
	ConnectionKey = Undefined;
	NewTreeRow = Undefined;
	
	UsedSpecifications = Undefined;
	
	Products               = Parameters.Products;
	ProductCharacteristic = Parameters.ProductCharacteristic;
	
	SelectionParametersManufactureAssembly = ProductDataManagementClientServer.ParametersForSelectingSpecificationsForManufacturingAssembly();
	
	If ValueIsFilled(Products) Then
		
		NewTreeRow = Tree.Rows.Add(); // See ProductDataManagementClientServer.TreeStringWithStructure
		NewTreeRow.Id  = New UUID;
		NewTreeRow.LineKind      = Enums.TypesOfSpecificationLines.Products;
		NewTreeRow.PictureIndex = GetImageIndex(NewTreeRow);
		
		NewTreeRow.Products   = Products;
		NewTreeRow.Characteristic = ProductCharacteristic;
		
		// We check whether the characteristics are used or not.
		CheckResult = Catalogs.Products.CharacteristicAndPackagingBelongToOwner(
			NewTreeRow.Products,
			NewTreeRow.Characteristic,
			Catalogs.PackagesAndUnitsOfMeasure.EmptyRef());
		NewTreeRow.ItemVariantsAreUsed = CheckResult.ItemVariantsAreUsed;
		
		AttributesValues = Common.ObjectAttributesValues(Products, "ItemsType,UnitOfMeasure");
		FillPropertyValues(NewTreeRow, AttributesValues);
		
		If Not ValueIsFilled(Parameters.BillOfMaterials) Then
			
			ProductData = ProductDataManagementClientServer.ProductDataStructureForSpecificationSelection();
			ProductData.Products            = Products;
			ProductData.Characteristic          = ProductCharacteristic;
			ProductData.ProductionStart      = Parameters.Date;
			ProductData.ProductionDispatcherBusinessUnit  = Parameters.ProductionDispatcherBusinessUnit;
			ProductData.LineOfBusiness = Parameters.LineOfBusiness;
			
			SpecificationData = ProductDataManagementServerCall.ProductSpecification(
				ProductData, SelectionParametersManufactureAssembly);
			
			If Not ValueIsFilled(SpecificationData) Then
				Common.MessageToUser(
					NStr("vi = 'Không tìm thấy bảng kê chi tiết các nguồn lực sản xuất.';
						|ru = 'Не найдена спецификация для изделия.';
						|en = 'BOM for the item is not found.'; fa = 'BOM for the item is not found.';
						|it = 'Non è stata trovata la specifica principale del prodotto.';
						|pl = 'Nie znaleziono specyfikacji dla wyrobu.';
						|tr = 'Nihai ürüne yönelik ürün reçetesi bulunamadı.'"),
					,
					"BOMsTree");
				Return;
			EndIf;
			
			NewTreeRow.BillOfMaterials = SpecificationData.BillOfMaterials;
		Else
			NewTreeRow.BillOfMaterials = Parameters.BillOfMaterials;
		EndIf;
		
		// Mode according to the order specification
		If ValueIsFilled(Parameters.AddressInStorage) Then
			
			NewTreeRow.Count         = Parameters.OutputProductQuantity;
			NewTreeRow.NumberOfPackages = Parameters.NumberOfPackagesOfOutputProduct;
			NewTreeRow.Package           = Parameters.OutputProductPackaging;
			
			ConnectionKey                            = Parameters.ConnectionKey;
			
		ElsIf ValueIsFilled(Parameters.NumberOfPackagesOfOutputProduct) Then
			
			NewTreeRow.Count         = Parameters.OutputProductQuantity;
			NewTreeRow.NumberOfPackages = Parameters.NumberOfPackagesOfOutputProduct;
			NewTreeRow.Package           = Parameters.OutputProductPackaging;
			
		Else
			
			MainProductData = Catalogs.BillsOfMaterials.MainProductSpecificationData(
				NewTreeRow.BillOfMaterials,
				Products,
				ProductCharacteristic);
			
			If MainProductData.Products.IsEmpty() Then
				Return;
			EndIf;
			
			FillPropertyValues(NewTreeRow, MainProductData, "Count,NumberOfPackages,Package");
			
		EndIf;
		
		If Not ValueIsFilled(NewTreeRow.Package) Then
			NewTreeRow.Package = NewTreeRow.UnitOfMeasure;
		EndIf;
		
		NewTreeRow.ThereIsBOM = True;
		
	ElsIf ValueIsFilled(Parameters.BillOfMaterials) Then
		
		NewTreeRow = Tree.Rows.Add(); // See ProductDataManagementClientServer.TreeStringWithStructure
		NewTreeRow.Id  = New UUID;
		NewTreeRow.PictureIndex = GetImageIndex(NewTreeRow);
		NewTreeRow.LineKind      = Enums.TypesOfSpecificationLines.Products;
		
		MainProduct = Catalogs.BillsOfMaterials.MainProductSpecificationData(Parameters.BillOfMaterials);
		
		If ValueIsFilled(MainProduct.Products) Then
			NewTreeRow.Products    = MainProduct.Products;
			NewTreeRow.Characteristic  = MainProduct.Characteristic;
		Else
			NewTreeRow.ProductKind = MainProduct.ProductKind;
		EndIf;
		
		FillPropertyValues(
			NewTreeRow,
			MainProduct,
			"Count,NumberOfPackages,Package,UnitOfMeasure,ItemVariantsAreUsed,ItemsType");
		
		If Not ValueIsFilled(NewTreeRow.Package) Then
			NewTreeRow.Package = NewTreeRow.UnitOfMeasure;
		EndIf;
		
		NewTreeRow.ThereIsBOM = True;
		NewTreeRow.BillOfMaterials = Parameters.BillOfMaterials;
		
	EndIf;
	
	ThereIsBOM = (NewTreeRow <> Undefined And NewTreeRow.ThereIsBOM Or NewTreeRow = Undefined);
	
	If Not Parameters.DynamicReading And ThereIsBOM Then
		
		UsedSpecifications = New Array;
		
		If NewTreeRow <> Undefined Then
			UsedSpecifications.Add(NewTreeRow.BillOfMaterials);
		Else
			UsedSpecifications.Add(Parameters.BillOfMaterials);
		EndIf;
		
	EndIf;
	
	FillTreeRows(Parameters, Tree, NewTreeRow, UsedSpecifications, ConnectionKey);
	
EndProcedure

Procedure ContinueUnravelingAlongTreeLine(Parameters, Tree, TreeRow, UsedSpecifications = Undefined, ConnectionKey = Undefined)
	
	TreeRow.ThereIsBOM = True;
	
	If Parameters.DynamicReading Then
		Return;
	EndIf;
	
	If UsedSpecifications.Find(TreeRow.BillOfMaterials) <> Undefined Then
		Return;
	EndIf;
	
	UsedSpecifications.Add(TreeRow.BillOfMaterials);
	FillTreeRows(Parameters, Tree, TreeRow, UsedSpecifications, ConnectionKey);
	UsedSpecifications.Delete(UsedSpecifications.Find(TreeRow.BillOfMaterials));
	
EndProcedure

Procedure FillInTreeRowSpecificationData(Parameters, RowsArray, SelectionParameters = Undefined)
	
	If RowsArray.UBound() = -1 Then
		Return;
	EndIf;
	
	If SelectionParameters = Undefined Then
		
		ListOfData = ListOfTreeSpecificationData();
		
		SelectionParameters = Catalogs.BillsOfMaterials.DataSamplingParameters(ListOfData);
		SelectionParameters.OverridingReleasePartySetting = New Structure("Use,ProductionIssueByCustomPortions",True,True);
		SelectionParameters.GetPresentations                 = True;
		SelectionParameters.ConsiderProbabilityOfDefectiveGoods             = False;
		SelectionParameters.SoftwareFillingOption          = ?(Parameters.DisplayBalanceOfGoods,
																		Enums.ProductionSupplyFillingVariants.BySupplySchemes,
																		Enums.ProductionSupplyFillingVariants.DontFill);
		SelectionParameters.MethodOfCalculationOfMaterials               = Enums.MaterialCalculationMethods.MaximumConsumption;
		
	EndIf;
	
	ItemList = Catalogs.BillsOfMaterials.ItemList();
	
	For IndexOf = 0 To RowsArray.UBound() Do
		NewRow = ItemList.Add();
		FillPropertyValues(NewRow, RowsArray[IndexOf]);
		NewRow.ProductionStart      = Parameters.Date;
		NewRow.ProductionDispatcherBusinessUnit  = Parameters.ProductionDispatcherBusinessUnit;
		NewRow.LineOfBusiness = Parameters.LineOfBusiness;
	EndDo;
	
	SpecificationsData = Catalogs.BillsOfMaterials.SpecificationDataByProductsList(
		ItemList, SelectionParameters);
	
	For IndexOf = 0 To RowsArray.UBound() Do
		RowsArray[IndexOf].StructureOfData = SpecificationsData[IndexOf];
	EndDo;
	
EndProcedure

Function GetImageIndex(RowData, StringBase = Undefined)
	
	LineKind = RowData.LineKind;
	
	DetailsOfBaseLine = New Structure;
	DetailsOfBaseLine.Insert("LineKind");
	DetailsOfBaseLine.Insert("ItemsType");
	DetailsOfBaseLine.Insert("ItIsSubjectToRAndM");
	DetailsOfBaseLine.Insert("WorkPlanning");
	
	If StringBase <> Undefined Then
		FillPropertyValues(DetailsOfBaseLine, StringBase);
	EndIf;
	
	If LineKind = Enums.TypesOfSpecificationLines.Stage
			And DetailsOfBaseLine.WorkPlanning = True Then
		Result = 2;
	ElsIf LineKind = Enums.TypesOfSpecificationLines.Stage Then
		Result = 0;
	ElsIf LineKind = Enums.TypesOfSpecificationLines.Operation Then
		Result = 4;
	ElsIf DetailsOfBaseLine.ItemsType = Enums.ItemsTypes.Work_5 Then
		Result = 10;
	ElsIf LineKind = Enums.TypesOfSpecificationLines.IntermediateSemiFinishedProduct
			And DetailsOfBaseLine.ItIsSubjectToRAndM <> True Then
		Result = 13;
	ElsIf LineKind = Enums.TypesOfSpecificationLines.Material
			And RowData.ProducedInProcess Then
		Result = 6;
	ElsIf LineKind = Enums.TypesOfSpecificationLines.Material Then
		Result = 7;
	ElsIf LineKind = Enums.TypesOfSpecificationLines.LaborCost Then
		Result = 15;
	ElsIf LineKind = Enums.TypesOfSpecificationLines.FinishedProduct Then
		Result = 12;
	ElsIf LineKind = Enums.TypesOfSpecificationLines.SideExit Then
		Result = 12;
	ElsIf DetailsOfBaseLine.ItIsSubjectToRAndM = True Then
		Result = 12;
	Else
		Result = 100;
	EndIf;
	
	Return Result;
	
EndFunction

Function GetOrderSpecificationData(AddressInStorage, ConnectionKey)
	
	OrderData = GetFromTempStorage(AddressInStorage);
	
	FilterStructure1 = New Structure("LinkKeySemiFinishedProduct", ConnectionKey);
	Stages = OrderData.Stages.Copy(FilterStructure1);
	
	ManufacturedProducts = OrderData.ManufacturedProducts.CopyColumns(); // ValueTable
	ManufacturedProducts.Columns.Add("UnitOfMeasure", New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
	ManufacturedProducts.Columns.Add("ProcessByBOM", New TypeDescription("Boolean"));
	ManufacturedProducts.Columns.Add("BillOfMaterials", New TypeDescription("CatalogRef.BillsOfMaterials"));

	RecyclableWaste = OrderData.ManufacturedProducts.CopyColumns(); // ValueTable
	RecyclableWaste.Columns.Add("UnitOfMeasure", New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
	RecyclableWaste.Columns.Add("ProcessByBOM", New TypeDescription("Boolean"));
	RecyclableWaste.Columns.Add("BillOfMaterials", New TypeDescription("CatalogRef.BillsOfMaterials"));
	
	MaterialsAndServices = OrderData.MaterialsAndServices.CopyColumns(); // ValueTable
	MaterialsAndServices.Columns.Add("UnitOfMeasure", New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
	MaterialsAndServices.Columns.Add("MethodOfReceivingMaterial", New TypeDescription("EnumRef.MethodsOfReceivingBOMMaterials"));
	MaterialsAndServices.Columns.Add("BillOfMaterialsRM", New TypeDescription("CatalogRef.BillsOfMaterials"));
	
	LaborCosts = OrderData.LaborCosts.CopyColumns(); // ValueTable
	LaborCosts.Columns.Add("UnitOfMeasure", New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
	
	For Each StringStages In Stages Do
		
		FilterStructure1.Clear();
		FilterStructure1.Insert("LinkKeySteps", StringStages.ConnectionKey); 
		
		FoundRows = OrderData.ManufacturedProducts.FindRows(FilterStructure1);
		For Each String In FoundRows Do
			NewRow = ManufacturedProducts.Add();
			FillPropertyValues(NewRow, String);
			FillPropertyValues(NewRow, NewRow.Products, "UnitOfMeasure");
		EndDo;
		
		FoundRows = OrderData.RecyclableWaste.FindRows(FilterStructure1);
		For Each String In FoundRows Do
			NewRow = RecyclableWaste.Add();
			FillPropertyValues(NewRow, String);
			FillPropertyValues(NewRow, NewRow.Products, "UnitOfMeasure");
		EndDo;
		
		FoundRows = OrderData.MaterialsAndServices.FindRows(FilterStructure1);
		For Each String In FoundRows Do
			NewRow = MaterialsAndServices.Add();
			If String.ProducedInProcess
				And TypeOf(String.SourceOfSemiFinishedProduct) = Type("CatalogRef.BillsOfMaterials") Then
				NewRow.MethodOfReceivingMaterial = Enums.MethodsOfReceivingBOMMaterials.ProduceByBillsOfMaterials;
			Else
				NewRow.MethodOfReceivingMaterial = Enums.MethodsOfReceivingBOMMaterials.Provide;
			EndIf;
			FillPropertyValues(NewRow, String);
			FillPropertyValues(NewRow, NewRow.Products, "UnitOfMeasure");
		EndDo;
		
		FoundRows = OrderData.LaborCosts.FindRows(FilterStructure1);
		For Each String In FoundRows Do
			NewRow = LaborCosts.Add();
			FillPropertyValues(NewRow, String);
			FillPropertyValues(NewRow, NewRow.WorkKind, "UnitOfMeasure");
		EndDo;
		
	EndDo;
	
	StructureOfData = New Structure();
	
	StructureOfData.Insert("ProductionProcessType", Enums.ProductionProcessTypes.Assembly);
	StructureOfData.Insert("AssignmentOption", Enums.BillOfMaterialsAssignmentOptions.Products);
	
	StructureOfData.Insert("ManufacturedProducts",  ManufacturedProducts);
	StructureOfData.Insert("RecyclableWaste", RecyclableWaste);
	StructureOfData.Insert("MaterialsAndServices", MaterialsAndServices);
	StructureOfData.Insert("LaborCosts",     LaborCosts);
	
	StructureOfData.Insert("Stages",    Stages);
	StructureOfData.Insert("Operations", New Array);
	
	Return StructureOfData;
	
EndFunction

// Specification tree structure constructor
// 
// Parameters:
// 	Parameters - See ProductDataManagementClientServer.SpecificationTreeParameters
// 	Tree - ValueTree - specification tree data
// Returns:
// 	Structure - From:
// * Parameters - See ProductDataManagementClientServer.SpecificationTreeParameters
// * Tree - Arbitrary - specification tree data
//
Function StructureOfSpecificationTree(Parameters, Tree)
	
	Return New Structure("Parameters, Tree", Parameters, Tree);
	
EndFunction

Function CacheStructureOfSpecificationTree(Parameters, Tree, Address)
	
	TreeStructure = StructureOfSpecificationTree(Parameters, Tree);
	
	Return PutToTempStorage(TreeStructure, Address);

EndFunction

Procedure TreeStringIsConvertedToArrayOfStructures(TreeRow, StructuresArray)
	
	For Each String In TreeRow.Rows Do

		String_Structure = ProductDataManagementClientServer.TreeStringWithStructure(String);
		
		If Not String.ThereIsBOM Then
			TreeStringIsConvertedToArrayOfStructures(String, String_Structure.Rows);
		EndIf;
		
		StructuresArray.Add(String_Structure);
		
	EndDo;
	
EndProcedure

Function ListOfTreeSpecificationData(DisplayStages = True, DeduceLaborCosts = True)
	
	ListOfData = New Array;
	
	ListOfData.Add("MaterialsAndServices");
	ListOfData.Add("ManufacturedProducts");
	ListOfData.Add("RecyclableWaste");
		
	If DeduceLaborCosts Then
		ListOfData.Add("LaborCosts");
	EndIf;
	
	If DisplayStages Then
		ListOfData.Add("Stages");
		ListOfData.Add("Operations");
	EndIf;
	
	Return ListOfData;
	
EndFunction

Function SelectionSettingsForSpecificationTreeConstructor()
	
	Filter_Settings = New Structure;
	
	Filter_Settings.Insert("TreeOutputStages",                True);
	Filter_Settings.Insert("TreeOutputOfOperations",             True);
	Filter_Settings.Insert("TreeOutputOutputItems",      True);
	Filter_Settings.Insert("TreeOutputMaterials",            True);
	Filter_Settings.Insert("TreeOutputLaborCosts",         True);
	Filter_Settings.Insert("TreeDisplayGroupingHeaders", True);
	
	Return Filter_Settings;
	
EndFunction

Procedure LoadSelectionSettingsOfSpecificationTree(Form) Export
	
	Filter_Settings = SelectionSettingsForSpecificationTreeConstructor();
	
	SelectionSettingsSaved = FormDataSettingsStorage.Load("BillsOfMaterialsTree", "FilterParameters");
	If ValueIsFilled(SelectionSettingsSaved) Then
		FillPropertyValues(Filter_Settings, SelectionSettingsSaved);
	EndIf;
	
	FillPropertyValues(Form, Filter_Settings);
	
EndProcedure

Procedure SaveSelectionSettingsOfSpecificationTree(Form) Export
	
	Filter_Settings = SelectionSettingsForSpecificationTreeConstructor();
	
	FillPropertyValues(Filter_Settings, Form);
	
	FormDataSettingsStorage.Save("BillsOfMaterialsTree", "FilterParameters", Filter_Settings);
	
EndProcedure

Procedure FillInSelectionSettingsOfSpecificationTree(TreeParameters, Form) Export
	
	TreeParameters.DisplayStages                = Form.TreeOutputStages;
	TreeParameters.OutputOfOperations             = Form.TreeOutputOfOperations;
	TreeParameters.OutputOutputProducts      = Form.TreeOutputOutputItems;
	TreeParameters.DisplayMaterials            = Form.TreeOutputMaterials;
	TreeParameters.DeduceLaborCosts         = Form.TreeOutputLaborCosts;
	TreeParameters.DisplayGroupingTitles = Form.TreeDisplayGroupingHeaders;
	
EndProcedure

// Add a tree line.
// 
// Parameters:
//  ParentRow - ValueTreeRow,ValueTree
//  LineKind - EnumRef.TypesOfSpecificationLines
//  StringBase - ValueTableRow
// 
// Returns:
//  See ProductDataManagementClientServer.TreeStringWithStructure
Function AddTreeRow(ParentRow, LineKind, StringBase = Undefined)
	
	TreeRows = ParentRow.Rows; // ValueTreeRowCollection
	NewRow = TreeRows.Add();
	
	If StringBase <> Undefined Then
		FillPropertyValues(NewRow, StringBase);
	EndIf;
	
	NewRow.LineKind      = LineKind;
	NewRow.Id  = New UUID;
	NewRow.PictureIndex = GetImageIndex(NewRow, StringBase);
	NewRow.Level        = NewRow.Level();
	
	NewRow.DesignLevel = ParentRow.DesignLevel;
	If NewRow.LineKind = Enums.TypesOfSpecificationLines.FinishedProduct
		Or NewRow.LineKind = Enums.TypesOfSpecificationLines.IncomingProduct
		Or NewRow.LineKind = Enums.TypesOfSpecificationLines.SideExit
		Or NewRow.LineKind = Enums.TypesOfSpecificationLines.Material
		Or NewRow.LineKind = Enums.TypesOfSpecificationLines.IntermediateSemiFinishedProduct
		Or NewRow.LineKind = Enums.TypesOfSpecificationLines.Work_In_Progress
		Or NewRow.LineKind = Enums.TypesOfSpecificationLines.LaborCost
		Or NewRow.LineKind = Enums.TypesOfSpecificationLines.Operation Then
		NewRow.DesignLevel = NewRow.DesignLevel + 1;
	EndIf;
	
	Return NewRow;
	
EndFunction

Procedure AddDataAboutWoodProduct(ItemData_3, TreeRow)
	
	ProductData = New Structure;
	
	RowData = TreeRow;
	While RowData <> Undefined Do
		If RowData.LineKind = Enums.TypesOfSpecificationLines.Products Then
			ProductData.Insert("Product",                 RowData.Products);
			ProductData.Insert("ItemVariantOfProduct",   RowData.Characteristic);
			ProductData.Insert("ProductSpecification",     RowData.BillOfMaterials);
		ElsIf RowData.LineKind = Enums.TypesOfSpecificationLines.Stage Then
			ProductData.Insert("Product",                 Catalogs.Products.EmptyRef());
			ProductData.Insert("ItemVariantOfProduct",   Catalogs.ItemsCharacteristics.EmptyRef());
			ProductData.Insert("ProductSpecification",     Catalogs.BillsOfMaterials.EmptyRef());
			ProductData.Insert("ProductSpecificationStage", RowData.Products);
		EndIf;
		RowData = RowData.Parent;
	EndDo;
	
	If ProductData.Property("Product")
		And ValueIsFilled(ProductData.Product) Then
		CommonClientServer.SupplementStructure(ItemData_3, ProductData);
	EndIf;
	
EndProcedure

Function CurrentBalancesOnItemList(TableOfMaterials)

	Query = New Query;
	QueryText = 
	"SELECT DISTINCT
	|	TableOfMaterials.Products AS Products,
	|	TableOfMaterials.Characteristic AS Characteristic,
	|	TableOfMaterials.Warehouse AS Warehouse,
	|	VALUE(Catalog.Assignments.EmptyRef) AS Purpose
	|INTO TT_UsedMaterials
	|FROM
	|	&TableOfMaterials AS TableOfMaterials
	|
	|INDEX BY
	|	Products, Characteristic, Warehouse, Purpose
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	Inventories.Products AS Products,
	|	Inventories.Characteristic AS Characteristic,
	|	Inventories.Warehouse AS Warehouse,
	|	Inventories.Purpose AS Purpose,
	|	Inventories.InStockBalance AS InStockBalance,
	|	Inventories.LockedInStockBalance AS LockedInStockBalance,
	|	Inventories.OrderedBalance AS OrderedBalance,
	|	Inventories.Received_1Balance AS Received_1Balance,
	|	Inventories.LockedReceiptBalance AS LockedReceiptBalance,
	|	Inventories.ReserveAtWarehouseBalance AS ReserveAtWarehouseBalance,
	|	Inventories.ReserveAsReceivedBalance AS ReserveAsReceivedBalance,
	|	Inventories.SnoozeReservationBalance AS SnoozeReservationBalance,
	|	Inventories.ToSupplyBalance AS ToSupplyBalance,
	|	Inventories.NotProvideBalance AS NotProvideBalance
	|INTO InventoryAndDemandsBalance
	|FROM
	|	AccumulationRegister.InventoryAndDemands.Balance(,
	|		(Products, Characteristic, Warehouse, Purpose) IN(
	|			SELECT
	|				Filter.Products AS Products,
	|				Filter.Characteristic AS Characteristic,
	|				Filter.Warehouse AS Warehouse,
	|				Filter.Purpose AS Purpose
	|			FROM
	|				TT_UsedMaterials AS Filter)) AS Inventories
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Calculation.Products AS Products,
	|	Calculation.Characteristic AS Characteristic,
	|	Calculation.Warehouse AS Warehouse,
	|	Calculation.QuantityInStock AS InStock,
	|	Calculation.QuantityForShipAction AS Available
	|FROM
	|	TT_UsedMaterials AS TT_UsedMaterials
	|		
	|		LEFT JOIN CalculationOfBalancesForSettingActions AS Calculation
	|		ON Calculation.Products = TT_UsedMaterials.Products
	|			AND Calculation.Characteristic = TT_UsedMaterials.Characteristic
	|			AND Calculation.Warehouse = TT_UsedMaterials.Warehouse";
	
	TablesNames = ProvisionInDocumentsServer.NewTableNamesForCalculatingBalancesForSettingActions();
	TablesNames.Balance = "InventoryAndDemandsBalance"; // @query-part-1
	TablesNames.Result = "CalculationOfBalancesForSettingActions"; // @query-part-1
	ProvisionInDocumentsServer.CalculationOfBalancesForSettingActions(QueryText, TablesNames);
	
	Query.Text = QueryText;
	Query.SetParameter("TableOfMaterials", TableOfMaterials);
	
	Return Query.Execute().Unload();

EndFunction

#EndRegion

#Region PackageData

Procedure FillInPackingDataInDataset(DataSet, PackingOfDataTable) Export
	
	If DataSet.Count() = 0 Then
		Return;
	EndIf;
	
	TheStructureOfTheSearch              = New Structure("Products,Package");
	DefaultPackagingStructure = ProductDataManagementCached.PackingDataStructure();
	
	For Each String In DataSet Do
		If ValueIsFilled(String.Package) Then
			FillInPackingDataInDataSetRow(String, PackingOfDataTable, TheStructureOfTheSearch);
		Else
			String.PackageData = DefaultPackagingStructure;
		EndIf;
	EndDo;
	
EndProcedure

Procedure FillInPackingDataInDataSetRow(String, PackingOfDataTable, TheStructureOfTheSearch = Undefined) Export
	
	SearchAttributes = "Products,Package";
	
	If PackingOfDataTable.Indexes.Count() = 0 Then
		PackingOfDataTable.Indexes.Add(SearchAttributes);
	EndIf;
	
	If TheStructureOfTheSearch = Undefined Then
		TheStructureOfTheSearch = New Structure(SearchAttributes, String.Products, String.Package);
	Else
		FillPropertyValues(TheStructureOfTheSearch, String);
	EndIf;
	
	TableRow = Undefined;
	
	FoundRows = PackingOfDataTable.FindRows(TheStructureOfTheSearch);
	If FoundRows.Count() > 0 Then
		
		TableRow = FoundRows[0];
		
		If ValueIsFilled(TableRow.PackageData) Then
		
			String.PackageData = TableRow.PackageData;
			Return;
			
		EndIf;
		
		TableRow.PackageData = PackingDataStructure(FoundRows[0]);
		
	EndIf;
	
	If ValueIsFilled(TableRow) And ValueIsFilled(TableRow.PackageData) Then
		String.PackageData = TableRow.PackageData;
	Else
		String.PackageData = ProductDataManagementCached.PackingDataStructure();
	EndIf;
	
EndProcedure

Function DescriptionOfQueryTextTablePackageData() Export
	
	Result = New Structure;
	
	Result.Insert("TableName",           "");
	Result.Insert("JoinText",      "");
	Result.Insert("ConditionText",         "TRUE");
	Result.Insert("SourceOfProducts", "");
	Result.Insert("SourceOfPackaging",     "");
	
	Return Result;
	
EndFunction

Function QueryTextPackageData_(TableDescriptions) Export
	
	QueryTemplate = "
	|SELECT
	|	T.Products AS Products,
	|	T.Package     AS Package,
	|
	|	&RequestTextPackingDetailsUnitsOfMeasurement,
	|
	|	UNDEFINED   AS PackageData
	|
	|FROM
	|	&TableName AS T
	|
	|		,JoinText
	|
	|WHERE
	|	T.Package <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|	AND &ConditionText
	|
	|";
	
	QueryText = "";
	For IndexOf = 0 To TableDescriptions.UBound() Do
		
		TableDetails = TableDescriptions[IndexOf];
		If TypeOf(TableDetails) = Type("String") Then
			TableDetails = DescriptionOfQueryTextTablePackageData();
			TableDetails.TableName = TableDescriptions[IndexOf];
		EndIf;
		
		If ValueIsFilled(QueryText) Then
			
			QueryText = QueryText + StrTemplate("
				| %1
				|", "UNION"+?(IndexOf = TableDescriptions.UBound(),"", " ALL"));
			
		EndIf;
		
		QueryTextFromTemplate = StrReplace(QueryTemplate,         "&TableName",      TableDetails.TableName);
		QueryTextFromTemplate = StrReplace(QueryTextFromTemplate, ",JoinText", TableDetails.JoinText);
		QueryTextFromTemplate = StrReplace(QueryTextFromTemplate, "&ConditionText",    TableDetails.ConditionText);
		QueryTextFromTemplate = StrReplace(QueryTextFromTemplate,
			"&RequestTextPackingDetailsUnitsOfMeasurement",
			RequestTextPackingDetailsUnitsOfMeasurement("T.Package", "T.Products"));
		
		If ValueIsFilled(TableDetails.SourceOfProducts) Then
			QueryTextFromTemplate = StrReplace(QueryTextFromTemplate, "T.Products", TableDetails.SourceOfProducts);
		EndIf;
		
		If ValueIsFilled(TableDetails.SourceOfPackaging) Then
			QueryTextFromTemplate = StrReplace(QueryTextFromTemplate, "T.Package", TableDetails.SourceOfPackaging);
		EndIf;
		
		QueryText = QueryText + QueryTextFromTemplate;
		
	EndDo;
	
	Return QueryText;
	
EndFunction

Function RequestTextPackingDetailsUnitsOfMeasurement(SourceOfPackaging, SourceOfProducts) Export
	
	QueryText = "
	|	GoodsTable.Products.UnitOfMeasure.MeasuredValueType          AS UnitOfMeasurementTypeOfMeasuredValue,
	|	ISNULL(GoodsTable.Products.UnitOfMeasure.Numerator, 0)         AS UnitOfMeasurementNumerator,
	|	ISNULL(GoodsTable.Products.UnitOfMeasure.Denominator, 0)       AS UnitDenominator,
	|
	|	GoodsTable.Package.MeasuredValueType                               AS PackagingTypeOfMeasuredValue,
	|	ISNULL(GoodsTable.Package.Numerator,0)                               AS PackingNumerator,
	|	ISNULL(GoodsTable.Package.Denominator,0)                             AS PackingDenominator,
	|
	|	GoodsTable.Products.WeightUse                                 AS WeightUse,
	|	GoodsTable.Products.WeightUnitOfMeasure                             AS WeightUnitOfMeasure,
	|	ISNULL(GoodsTable.Products.WeightNumerator,0)                        AS WeightNumerator,
	|	ISNULL(GoodsTable.Products.WeightDenominator,0)                      AS WeightDenominator,
	|	ISNULL(GoodsTable.Products.WeightUnitOfMeasure.Numerator,0)       AS WeightUnitNumerator,
	|	ISNULL(GoodsTable.Products.WeightUnitOfMeasure.Denominator,0)     AS WeightUnitDenominator,
	|
	|	GoodsTable.Products.VolumeUse                               AS VolumeUse,
	|	GoodsTable.Products.VolumeUnitOfMeasure                           AS VolumeUnitOfMeasure,
	|	ISNULL(GoodsTable.Products.VolumeNumerator,0)                      AS VolumeNumerator,
	|	ISNULL(GoodsTable.Products.VolumeDenominator,0)                    AS VolumeDenominator,
	|	ISNULL(GoodsTable.Products.VolumeUnitOfMeasure.Numerator,0)     AS VolumeUnitOfMeasurementNumerator,
	|	ISNULL(GoodsTable.Products.VolumeUnitOfMeasure.Denominator,0)   AS VolumeUnitDenominator,
	|
	|	GoodsTable.Products.AreaUse                             AS AreaUse,
	|	GoodsTable.Products.AreaUnitOfMeasure                         AS AreaUnitOfMeasure,
	|	ISNULL(GoodsTable.Products.AreaNumerator,0)                    AS AreaNumerator,
	|	ISNULL(GoodsTable.Products.AreaDenominator,0)                  AS AreaDenominator,
	|	ISNULL(GoodsTable.Products.AreaUnitOfMeasure.Numerator,0)   AS AreaUnitNumerator,
	|	ISNULL(GoodsTable.Products.AreaUnitOfMeasure.Denominator,0) AS AreaUnitDenominator,
	|
	|	GoodsTable.Products.LengthUse                               AS LengthUse,
	|	GoodsTable.Products.LengthUnitOfMeasure                           AS LengthUnitOfMeasure,
	|	ISNULL(GoodsTable.Products.LengthNumerator,0)                      AS LengthNumerator,
	|	ISNULL(GoodsTable.Products.LengthDenominator,0)                    AS LengthDenominator,
	|	ISNULL(GoodsTable.Products.LengthUnitOfMeasure.Numerator,0)     AS LengthUnitNumerator,
	|	ISNULL(GoodsTable.Products.LengthUnitOfMeasure.Denominator,0)   AS LengthUnitDenominator
	|";
	
	QueryText = StrReplace(QueryText, "GoodsTable.Products", SourceOfProducts);
	QueryText = StrReplace(QueryText, "GoodsTable.Package",     SourceOfPackaging);
	
	Return QueryText;
	
EndFunction

Function PackingDataStructure(PackingDetails)
	
	Numerator = 0;
	Denominator = 0;
	
	If PackingDetails.PackagingTypeOfMeasuredValue = Enums.TypesOfMeasuredValues.Weight Then
		
		Numerator = PackingDetails.PackingNumerator
								* PackingDetails.WeightUnitDenominator
								* PackingDetails.WeightDenominator;
				
		Denominator = PackingDetails.PackingDenominator
								* PackingDetails.WeightUnitNumerator
								* PackingDetails.WeightNumerator;
		
	ElsIf PackingDetails.PackagingTypeOfMeasuredValue = Enums.TypesOfMeasuredValues.VolumeM3 Then
		
		Numerator = PackingDetails.PackingNumerator
								* PackingDetails.VolumeUnitDenominator
								* PackingDetails.VolumeDenominator;
				
		Denominator = PackingDetails.PackingDenominator
								* PackingDetails.VolumeUnitOfMeasurementNumerator
								* PackingDetails.VolumeNumerator;
		
	ElsIf PackingDetails.PackagingTypeOfMeasuredValue = Enums.TypesOfMeasuredValues.AreaTypeOfMeasurement Then
		
		Numerator = PackingDetails.PackingNumerator
								* PackingDetails.AreaUnitDenominator
								* PackingDetails.AreaDenominator;
				
		Denominator = PackingDetails.PackingDenominator
								* PackingDetails.AreaUnitNumerator
								* PackingDetails.AreaNumerator;
		
	ElsIf PackingDetails.PackagingTypeOfMeasuredValue = Enums.TypesOfMeasuredValues.Length Then
		
		Numerator = PackingDetails.PackingNumerator
								* PackingDetails.LengthUnitDenominator
								* PackingDetails.LengthDenominator;
				
		Denominator = PackingDetails.PackingDenominator
								* PackingDetails.LengthUnitNumerator
								* PackingDetails.LengthNumerator;
		
	ElsIf (PackingDetails.PackagingTypeOfMeasuredValue = Enums.TypesOfMeasuredValues.Capacity
		Or PackingDetails.PackagingTypeOfMeasuredValue = Enums.TypesOfMeasuredValues.Energy
		Or PackingDetails.PackagingTypeOfMeasuredValue = Enums.TypesOfMeasuredValues.ElectricCharge
		Or PackingDetails.PackagingTypeOfMeasuredValue = Enums.TypesOfMeasuredValues.Time)
		And PackingDetails.UnitOfMeasurementTypeOfMeasuredValue = PackingDetails.PackagingTypeOfMeasuredValue Then
			
		Numerator = PackingDetails.PackingNumerator * PackingDetails.UnitDenominator;
		Denominator = PackingDetails.PackingDenominator * PackingDetails.UnitOfMeasurementNumerator;
			
	ElsIf PackingDetails.PackagingTypeOfMeasuredValue = Enums.TypesOfMeasuredValues.Package Then
	
		Numerator = PackingDetails.PackingNumerator;
		Denominator = PackingDetails.PackingDenominator;
		
	EndIf;
	
	Return ProductDataManagementCached.PackingDataStructure(Numerator, Denominator);
	
EndFunction

#EndRegion

#Region ImportProductionMasterData

// Description of the loaded data element constructor.
// 
// Parameters:
//  MetadataObjectName - String - directory name
//  TSName - String - PM name
// 
// Returns:
//  Structure - Description Of The Loaded Data Element Constructor:
// * Key - String
// * MetadataObjectName - String
// * TSName - String
// * FullName - String
// * RequiredAttributes - Array of String
// * AttributesIds - Structure
// * AttributesStandard - Structure
// * AttributesApplication - Structure
// * AdditionalDetails_ - Structure
// * ServiceDetails - Structure
// * AttributesExcluded - Structure
// * SearchIsAvailable - Boolean
// * ObjectAlgorithmsAreAvailable - Boolean
// * SectionKey - String
// * LevelInFile - Number
// * Id - String
// * TechnologyID - String
// * IdOfProduct - String
// * MaterialId - String
// * MetadataObject - CatalogRef.MetadataObjectIDs
// * MetadataObjectEmptyLink - AnyRef
// * IsCatalog - Boolean
// * IsDocument - Boolean
Function DescriptionOfLoadedDataElementConstructor(MetadataObjectName, TSName = "") Export
	
	Result = New Structure;
	
	Result.Insert("Key", ProductDataManagementClientServer.KeyForDescriptionOfUploadedDataElement(MetadataObjectName, TSName));
	Result.Insert("MetadataObjectName", MetadataObjectName);
	Result.Insert("TSName",                TSName);
	Result.Insert("FullName");
	Result.Insert("Presentation");
	Result.Insert("MetadataObject");
	Result.Insert("FilterStructure1");
	
	Result.Insert("HasCode",          False);
	Result.Insert("HasDescription", False);
	
	Result.Insert("RequiredAttributes",   New Array);
	
	Result.Insert("AttributesIds", New Structure);
	Result.Insert("AttributesStandard",    New Structure);
	Result.Insert("AttributesApplication",     New Structure);
	Result.Insert("AdditionalDetails_", New Structure);
	Result.Insert("ServiceDetails",      New Structure);
	Result.Insert("AttributesExcluded",    New Structure);
	
	Result.Insert("SearchIsAvailable", False);
	Result.Insert("ObjectAlgorithmsAreAvailable", IsBlankString(TSName));
	
	Result.Insert("SectionKey");
	Result.Insert("LevelInFile", 0);
	
	Result.Insert("IsCatalog", False);
	Result.Insert("IsDocument"  , False);
	
	If Metadata.Catalogs.Find(MetadataObjectName) <> Undefined Then
		Result.Insert("MetadataObjectEmptyLink", Catalogs[MetadataObjectName].EmptyRef());
		Result.IsCatalog = IsBlankString(TSName);
	ElsIf Metadata.Documents.Find(MetadataObjectName) <> Undefined Then
		Result.Insert("MetadataObjectEmptyLink", Documents[MetadataObjectName].EmptyRef());
		Result.IsDocument   = IsBlankString(TSName);
	EndIf;
	
	Return Result;
	
EndFunction

// Constructor for the description of the Attributes Of the uploaded data
// 
// Returns:
//  Structure:
// * Name - String
// * Presentation - String 
// * Type - TypeDescription
// * CompositeType - Boolean
// * ReferentialType - Boolean
// * HasCode - Boolean
// * HasDescription - Boolean
// * ChoiceFoldersAndItems - FoldersAndItems
// * ChoiceParameters - FixedArray of ChoiceParameter
// * IsRequired - Boolean
// * OrderInGroup - Number
// * Property - ChartOfCharacteristicTypesRef.AdditionalAttributesAndInfo
// * IDType - TypeDescription
// * RefTypesDetails - Array of Structure
Function DescriptionOfAttributesOfUploadedDataConstructor() Export
	
	Result = New Structure;
	
	Result.Insert("Name",           "");
	Result.Insert("Presentation", "");
	
	Result.Insert("Type");
	Result.Insert("CompositeType",  False);
	Result.Insert("ReferentialType",  False);
	Result.Insert("IDType");
	
	Result.Insert("HasCode",          False);
	Result.Insert("HasDescription", False);
	Result.Insert("HasNumber",        False);
	
	Result.Insert("ChoiceFoldersAndItems");
	Result.Insert("ChoiceParameters");
	
	Result.Insert("IsRequired", False);
	Result.Insert("OrderInGroup", 0);
	Result.Insert("MandatorySearch", False);
	
	Result.Insert("PropertyDetails");
	
	Result.Insert("ThisIsID", False);
	Result.Insert("ThisIsMainIdentifier", False);
	
	Result.Insert("RefTypesDetails", New Array);
	
	Return Result;
	
EndFunction

Function DescriptionOfConstructorReferenceType()
	
	Result = New Structure;
	
	Result.Insert("MetadataObject");
	
	Result.Insert("Type",                  "");
	Result.Insert("Name",                  "");
	Result.Insert("Synonym",              "");
	Result.Insert("FullName",            "");
	Result.Insert("ListPresentation",  "");
	Result.Insert("ObjectPresentation", "");
	
	Result.Insert("HasCode",              False);
	Result.Insert("HasDescription",     False);
	Result.Insert("HasNumber",            False);
	
	Return Result;
	
EndFunction

// Description OF THE Attributes of the OBJECT being UPLOADED.
// 
// Parameters:
//  AttributeMetadata - MetadataObject
// 
// Returns:
//  Structure - See the descriptionerequestionable data constructorconstructor
//
Function DescriptionOfAttributesOfUploadedData(AttributeMetadata)
	
	AttributeDetails = DescriptionOfAttributesOfUploadedDataConstructor();
	
	AttributeName = AttributeMetadata.Name;
	
	AttributeDetails.Name = AttributeName;
	AttributeDetails.Presentation = ?(IsBlankString(AttributeMetadata.Synonym), AttributeName, AttributeMetadata.Synonym);
	
	AllowedTypes = AttributeMetadata.Type.Types();
	For Each Type In AllowedTypes Do
		If Common.IsReference(Type) Then
			AttributeDetails.ReferentialType = True;
			Break;
		EndIf;
	EndDo;
	
	AttributeDetails.Type = AttributeMetadata.Type;
	AttributeDetails.CompositeType = AllowedTypes.Count() > 1;
	
	If AttributeDetails.ReferentialType Then
		If AttributeName = "Parent" Then
			AttributeDetails.ChoiceFoldersAndItems = FoldersAndItems.Folders;
		ElsIf Not CommonClientServer.HasAttributeOrObjectProperty(AttributeMetadata, "ChoiceFoldersAndItems") Then
			AttributeDetails.ChoiceFoldersAndItems = FoldersAndItems.FoldersAndItems;
		ElsIf AttributeMetadata.ChoiceFoldersAndItems = FoldersAndItemsUse.Items Then
			AttributeDetails.ChoiceFoldersAndItems = FoldersAndItems.Items;
		ElsIf AttributeMetadata.ChoiceFoldersAndItems = FoldersAndItemsUse.Folders Then
			AttributeDetails.ChoiceFoldersAndItems = FoldersAndItems.Folders;
		Else
			AttributeDetails.ChoiceFoldersAndItems = FoldersAndItems.FoldersAndItems;
		EndIf;
		AttributeDetails.ChoiceParameters = AttributeMetadata.ChoiceParameters;
		AddDescriptionOfReferenceTypes(AttributeDetails);
	EndIf;
	
	Return AttributeDetails;
	
EndFunction

// Description of the upload object.
// 
// Parameters:
//  MetadataObjectName - String - directory name
//  TSName - String - PM name
// 
// Returns:
//  Structure - See DescriptionOfLoadedDataElementConstructor
//
Function DescriptionOfUploadedDataElement(MetadataObjectName, TSName = "")
	
	Result = DescriptionOfLoadedDataElementConstructor(MetadataObjectName, TSName);
	
	MetadataObjectDetails = Metadata.FindByType(TypeOf(Result.MetadataObjectEmptyLink));
	
	AttributesExcluded  = ExcludedAttributesOfUploadedDataElement(MetadataObjectName, TSName);
	RequiredAttributes = RequiredAttributesOfUploadedDataElement(MetadataObjectName, TSName);
	
	Result.FullName         = MetadataObjectDetails.FullName();
	Result.MetadataObject  = Common.MetadataObjectID(MetadataObjectDetails);
	
	If IsBlankString(TSName) Then
		For Each DescriptionOfMetadataAttribute In MetadataObjectDetails.StandardAttributes Do // MetadataObject
			If DescriptionOfMetadataAttribute.Name = "Code" Then
				Result.HasCode = True;
			ElsIf DescriptionOfMetadataAttribute.Name = "Description" Then
				Result.HasDescription = True;
			EndIf;
			AttributeDetails = DescriptionOfAttributesOfUploadedData(DescriptionOfMetadataAttribute);
			AttributeDetails.IsRequired = (RequiredAttributes.Find(AttributeDetails.Name) <> Undefined);
			If AttributesExcluded.Find(DescriptionOfMetadataAttribute.Name) <> Undefined Then
				StorageStructure = Result.AttributesExcluded;
			Else
				StorageStructure = Result.AttributesStandard;
			EndIf;
			StorageStructure.Insert(AttributeDetails.Name, AttributeDetails);
		EndDo;
	Else
		MetadataObjectDetails = MetadataObjectDetails.TabularSections.Find(TSName);
	EndIf;
	
	For Each DescriptionOfMetadataAttribute In MetadataObjectDetails.Attributes Do // MetadataObject
		If DescriptionOfMetadataAttribute.Type.ContainsType(Type("ValueStorage"))
				Or DescriptionOfMetadataAttribute.Type.ContainsType(Type("UUID"))
				Or StrFind(Upper(DescriptionOfMetadataAttribute.Name), "DELETE") = 1 Then
			Continue;
		EndIf;
		AttributeDetails = DescriptionOfAttributesOfUploadedData(DescriptionOfMetadataAttribute);
		AttributeDetails.IsRequired = (RequiredAttributes.Find(AttributeDetails.Name) <> Undefined);
		If AttributesExcluded.Find(DescriptionOfMetadataAttribute.Name) <> Undefined Then
			StorageStructure = Result.AttributesExcluded;
		Else
			StorageStructure = Result.AttributesApplication;
		EndIf;
		StorageStructure.Insert(AttributeDetails.Name, AttributeDetails);
	EndDo;
	
	If GetFunctionalOption("UseAdditionalAttributesAndInfo") And IsBlankString(TSName) Then
			
		AddAdditionalAttributesAndInformation(Result);
		
	EndIf;
	
	Result.RequiredAttributes = RequiredAttributes;
	Result.FilterStructure1 = New Structure("MetadataObject,TSName", Result.MetadataObject, TSName);
	Result.Presentation = MetadataObjectDetails.Synonym;
	
	Return Result;
	
EndFunction

// Description of the upload objects.
// 
// Parameters:
// SourceSettings - See Catalogs.SourcesToImportProductionMasterData.DataSourceSettingsConstructor
// 
// Returns:
//  Structure - Description of upload objects:
// * Products - See DescriptionOfLoadedDataElementConstructor
// * WorkCenterTypes - See DescriptionOfLoadedDataElementConstructor
// * WorkCenters - See DescriptionOfLoadedDataElementConstructor
// * BillsOfMaterials - See DescriptionOfLoadedDataElementConstructor
// * ProductionStages - See DescriptionOfLoadedDataElementConstructor
// * ManufacturingOperations - See DescriptionOfLoadedDataElementConstructor
// * EmployeeWorkKinds - See DescriptionOfLoadedDataElementConstructor
Function DescriptionOfUploadedData(SourceSettings) Export
	
	Result = New Structure;
	
	LongDesc = DescriptionOfUploadedDataElement("Products");
	LongDesc.SearchIsAvailable = True;
	LongDesc.SectionKey = ProductDataManagementClientServer.KeyOfProductsAndMaterialsSection();
	AddAttributeId(LongDesc, "Id", NStr("vi = 'Tên định danh';
										|ru = 'Идентификатор';
										|en = 'ID'; fa = 'شناسه';
										|it = 'Идентификатор';
										|pl = 'ID';
										|tr = 'Tanımlayıcı'"));
	If GetFunctionalOption("UseItemVariants") Then
		AddAttributeInternal(LongDesc, "ItemVariantName", NStr("vi = 'Tên gọi đặc tính';
																|ru = 'Наименование характеристики';
																|en = 'Item variant name'; fa = 'نام گونه قلم';
																|it = 'Nome della caratteristica';
																|pl = 'Nazwa charakterystyki';
																|tr = 'Varyant tanımı'"));
	EndIf;
	Result.Insert(LongDesc.Key, LongDesc);
	
	If SourceSettings.SectionsToBeProcessed.Property(ProductDataManagementClientServer.KeyOfProductionEquipmentSection()) Then
		For Each HardwareLoadingOption In Enums.ImportMasterDataEquipment Do
			If SourceSettings.HardwareLoadingOption = HardwareLoadingOption Then
				LongDesc = DescriptionOfUploadedDataElement(XMLString(HardwareLoadingOption));
				LongDesc.SearchIsAvailable = True;
				LongDesc.SectionKey = ProductDataManagementClientServer.KeyOfProductionEquipmentSection();
				AddAttributeId(LongDesc, "Id", NStr("vi = 'Tên định danh';
													|ru = 'Идентификатор';
													|en = 'ID'; fa = 'شناسه';
													|it = 'Идентификатор';
													|pl = 'ID';
													|tr = 'Tanımlayıcı'"));
				Result.Insert(LongDesc.Key, LongDesc);
			EndIf;
		EndDo;
	EndIf;
	
	LongDesc = DescriptionOfUploadedDataElement("BillsOfMaterials");
	LongDesc.SectionKey = ProductDataManagementClientServer.KeyOfProductCompositionsSection();
	AddAttributeId(LongDesc, "IdOfProduct", NStr("vi = 'Tên định danh sản phẩm';
												|ru = 'Идентификатор изделия';
												|en = 'Finished product ID'; fa = 'Finished product ID';
												|it = 'Идентификатор изделия';
												|pl = 'Finished product ID';
												|tr = 'Nihai ürün tanımlayıcısı'"),, New TypeDescription("CatalogRef.Products"));
	AddAttributeId(LongDesc, "TechnologyID", NStr("vi = 'Tên định danh kỹ thuật';
													|ru = 'Идентификатор технологии';
													|en = 'Technology ID'; fa = 'Technology ID';
													|it = 'Идентификатор технологии';
													|pl = 'Technology ID';
													|tr = 'Teknoloji tanımlayıcısı'"));
	Result.Insert(LongDesc.Key, LongDesc);
	
	LongDesc = DescriptionOfUploadedDataElement("BillsOfMaterials", "MaterialsAndServices");
	LongDesc.SectionKey = ProductDataManagementClientServer.KeyOfProductCompositionsSection();
	LongDesc.LevelInFile = 1;
	AddAttributeId(LongDesc, "MaterialId", NStr("vi = 'Tên định danh nguyên vật liệu';
												|ru = 'Идентификатор материала';
												|en = 'Material ID'; fa = 'Material ID';
												|it = 'Идентификатор материала';
												|pl = 'Material ID';
												|tr = 'Malzeme tanımlayıcısı'"),, New TypeDescription("CatalogRef.Products"));
	AddAttributeId(LongDesc, "IdOfEmbeddedTechnology", NStr("vi = 'Tên định danh công nghệ lồng trong';
															|ru = 'Идентификатор вложенной технологии';
															|en = 'Nested technology ID'; fa = 'Nested technology ID';
															|it = 'Идентификатор вложенной технологии';
															|pl = 'Nested technology ID';
															|tr = 'İç içe teknoloji tanımlayıcısı'"), False);
	AddAttributeInternal(LongDesc, "CommunicationKeyMaterialOperation", NStr("vi = 'Khóa liên kết với giao dịch';
																			|ru = 'Ключ связи с операцией';
																			|en = 'Operation link key'; fa = 'Operation link key';
																			|it = 'Ключ связи с операцией';
																			|pl = 'Operation link key';
																			|tr = 'İşlem bağlantı anahtarı'"));
	Result.Insert(LongDesc.Key, LongDesc);
	
	LongDesc = DescriptionOfUploadedDataElement("BillsOfMaterials", "LaborCosts");
	LongDesc.SectionKey = ProductDataManagementClientServer.KeyOfProductionTechnologySection();
	LongDesc.LevelInFile = 1;
	Result.Insert(LongDesc.Key, LongDesc);
	
	LongDesc = DescriptionOfUploadedDataElement("ProductionStages");
	LongDesc.SectionKey = ProductDataManagementClientServer.KeyOfProductionTechnologySection();
	LongDesc.LevelInFile = 1;
	Result.Insert(LongDesc.Key, LongDesc);
	
	LongDesc = DescriptionOfUploadedDataElement("ManufacturingOperations");
	LongDesc.SectionKey = ProductDataManagementClientServer.KeyOfProductionTechnologySection();
	LongDesc.LevelInFile = 1;
	AddAttributeInternal(LongDesc, "CommunicationKeyMaterialOperation", NStr("vi = 'Khóa liên kết với nguyên vật liệu';
																			|ru = 'Ключ связи с материалом';
																			|en = 'Material link key'; fa = 'Material link key';
																			|it = 'Ключ связи с материалом';
																			|pl = 'Material link key';
																			|tr = 'Malzeme bağlantı anahtarı'"));
	Result.Insert(LongDesc.Key, LongDesc);
	
	LongDesc = DescriptionOfUploadedDataElement("EmployeeWorkKinds");
	LongDesc.SearchIsAvailable = True;
	LongDesc.LevelInFile = 1;
	LongDesc.SectionKey = ProductDataManagementClientServer.KeyOfProductionTechnologySection();
	AddAttributeId(LongDesc, "Id", NStr("vi = 'Tên định danh';
										|ru = 'Идентификатор';
										|en = 'ID'; fa = 'شناسه';
										|it = 'Идентификатор';
										|pl = 'ID';
										|tr = 'Tanımlayıcı'"));
	Result.Insert(LongDesc.Key, LongDesc);
	
	If SourceSettings.SectionsToBeProcessed.Property(ProductDataManagementClientServer.KeyOfMaterialsReplacementSection()) Then
		
		LongDesc = DescriptionOfUploadedDataElement("EngineeringChangeOrder");
		LongDesc.SectionKey = ProductDataManagementClientServer.KeyOfMaterialsReplacementSection();
		AddAttributeId(LongDesc, "Id", NStr("vi = 'Tên định danh';
											|ru = 'Идентификатор';
											|en = 'ID'; fa = 'شناسه';
											|it = 'Идентификатор';
											|pl = 'ID';
											|tr = 'Tanımlayıcı'"));
		AddAttributeId(LongDesc, "IdOfProduct", NStr("vi = 'Tên định danh sản phẩm';
													|ru = 'Идентификатор изделия';
													|en = 'Finished product ID'; fa = 'Finished product ID';
													|it = 'Идентификатор изделия';
													|pl = 'Finished product ID';
													|tr = 'Nihai ürün tanımlayıcısı'"), False, New TypeDescription("CatalogRef.Products"));
		AddAttributeId(LongDesc, "TechnologyID", NStr("vi = 'Tên định danh kỹ thuật';
														|ru = 'Идентификатор технологии';
														|en = 'Technology ID'; fa = 'Technology ID';
														|it = 'Идентификатор технологии';
														|pl = 'Technology ID';
														|tr = 'Teknoloji tanımlayıcısı'"), False, New TypeDescription("CatalogRef.BillsOfMaterials"));
		CommonClientServer.SupplementStructure(
			LongDesc.ServiceDetails,
			DescriptionOfUploadedDataElement("EngineeringChangeOrder", "AreasOfAction").AttributesApplication,
			True);
		Result.Insert(LongDesc.Key, LongDesc);
		
		LongDesc = DescriptionOfUploadedDataElement("EngineeringChangeOrder", "UsedMaterials");
		LongDesc.Presentation = NStr("vi = 'Nguyên vật liệu và tương tự';
									|ru = 'Материалы и аналоги';
									|en = 'Materials and substitutes'; fa = 'مواد و جایگزین‌ها';
									|it = 'Материалы и аналоги';
									|pl = 'Materials and substitutes';
									|tr = 'Malzemeler ve İkameler'");
		LongDesc.SectionKey = ProductDataManagementClientServer.KeyOfMaterialsReplacementSection();
		LongDesc.LevelInFile = 1;
		AddAttributeId(LongDesc, "MaterialId", NStr("vi = 'Tên định danh nguyên vật liệu';
													|ru = 'Идентификатор материала';
													|en = 'Material ID'; fa = 'Material ID';
													|it = 'Идентификатор материала';
													|pl = 'Material ID';
													|tr = 'Malzeme tanımlayıcısı'"),, New TypeDescription("CatalogRef.Products"));
		AddAttributeInternal(LongDesc, "ReplacementGroup", NStr("vi = 'Nguyên vật liệu / tương tự';
																|ru = 'Материал / аналог';
																|en = 'Material / substitute'; fa = 'Material / substitute';
																|it = 'Материал / аналог';
																|pl = 'Material / substitute';
																|tr = 'Malzeme / İkame'"), True);
		Result.Insert(LongDesc.Key, LongDesc);
		
	EndIf;
	
	Return Result;
	
EndFunction

Function AddAttributeId(LongDesc, Name, Presentation, IsRequired = True, Type = Undefined)
	
	AttributeDetails = DescriptionOfAttributesOfUploadedDataConstructor();
	AttributeDetails.Name               = Name;
	AttributeDetails.Presentation     = Presentation;
	AttributeDetails.Type               = New TypeDescription("String");
	AttributeDetails.OrderInGroup    = LongDesc.AttributesIds.Count();
	
	AttributeDetails.ThisIsID  = True;
	If Type = Undefined Then
		TypesArray = CommonClientServer.ValueInArray(TypeOf(LongDesc.MetadataObjectEmptyLink));
		AttributeDetails.IDType = New TypeDescription(TypesArray);
		AttributeDetails.ThisIsMainIdentifier = True;
	Else
		AttributeDetails.IDType = Type;
	EndIf;
	
	If IsRequired Then
		AttributeDetails.IsRequired = True;
		LongDesc.RequiredAttributes.Add(Name);
	EndIf;
	
	AddDescriptionOfReferenceTypes(AttributeDetails);
	
	LongDesc.AttributesIds.Insert(Name, AttributeDetails);
	
	Return AttributeDetails;
	
EndFunction

Function AddAttributeInternal(LongDesc, Name, Presentation, IsRequired = False, Type = Undefined)
	
	AttributeDetails = DescriptionOfAttributesOfUploadedDataConstructor();
	AttributeDetails.Name               = Name;
	AttributeDetails.Presentation     = Presentation;
	AttributeDetails.Type               = ?(Type = Undefined, New TypeDescription("String"), Type);
	
	If IsRequired Then
		AttributeDetails.IsRequired = True;
		LongDesc.RequiredAttributes.Add(Name);
	EndIf;
	
	AddDescriptionOfReferenceTypes(AttributeDetails);
	
	LongDesc.ServiceDetails.Insert(Name, AttributeDetails);
	
	Return AttributeDetails;
	
EndFunction

Procedure AddAdditionalAttributesAndInformation(DescriptionOfUploadedDataElement)
	
	Query = New Query;
	PropertiesSets = New Array;
	
	If DescriptionOfUploadedDataElement.MetadataObjectName = "Products" Then
		UseCharacteristics = GetFunctionalOption("UseItemVariants");
		UseCharacteristics = GetFunctionalOption("UseItemVariants");
		QueryText = "
		|SELECT
		|	PropertiesSets.Ref
		|FROM
		|	Catalog.ItemKinds AS ItemKinds
		|		INNER JOIN Catalog.AdditionalAttributesAndInfoSets AS PropertiesSets
		|		ON ItemKinds.PropertiesSet = PropertiesSets.Ref
		|		OR (ItemKinds.CharacteristicsPropertySet = PropertiesSets.Ref
		|				AND &UseCharacteristics)
		|WHERE
		|	PropertiesSets.Used
		|	AND (PropertiesSets.AttributesCount <> """"
		|		OR PropertiesSets.InfoCount <> """")
		|";
		Query.Text = QueryText;
		Query.SetParameter("UseCharacteristics", UseCharacteristics);
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			PropertiesSets.Add(Selection.Ref);
		EndDo;
		PropertiesSets.Add(PropertyManager.PropertiesSetByName("Catalog_Products_Overall"));
		If UseCharacteristics Then
			PropertiesSets.Add(PropertyManager.PropertiesSetByName("Catalog_ItemsCharacteristics_Overall"));
		EndIf;
	Else
		PropertiesSets.Add(PropertyManager.PropertiesSetByName(StrReplace(DescriptionOfUploadedDataElement.FullName,".","_")));
	EndIf;
	
	QueryText = "
	|SELECT
	|	T.Ref   AS PropertiesSet,
	|	T.Property AS Property
	|INTO
	|	PropertiesTable
	|FROM
	|	Catalog.AdditionalAttributesAndInfoSets.AdditionalAttributes AS T
	|		INNER JOIN ChartOfCharacteristicTypes.AdditionalAttributesAndInfo AS AdditionalAttributesAndInfo
	|		ON T.Property = AdditionalAttributesAndInfo.Ref
	|WHERE
	|	T.Ref IN (&PropertiesSets)
	|
	|UNION
	|
	|SELECT
	|	T.Ref   AS PropertiesSet,
	|	T.Property AS Property
	|FROM
	|	Catalog.AdditionalAttributesAndInfoSets.AdditionalInfo AS T
	|		INNER JOIN ChartOfCharacteristicTypes.AdditionalAttributesAndInfo AS AdditionalAttributesAndInfo
	|		ON T.Property = AdditionalAttributesAndInfo.Ref
	|WHERE
	|	T.Ref IN (&PropertiesSets)
	|;
	|
	|SELECT
	|	T.PropertiesSet                            AS PropertiesSet,
	|	T.Property                                AS Property,
	|	T.Property.Name                            AS NameProperty,
	|	T.Property.Description                   AS Property_Name,
	|	T.Property.Presentation                  AS PropertyPresentation,
	|	T.Property.Title                      AS HeaderProperty,
	|	T.Property.IsAdditionalInfo      AS PropertyIsAdditionalInformation,
	|	T.Property.AdditionalValuesOwner AS PropertyOwnerOfAdditionalValues,
	|	T.Property.ValueType                    AS PropertyValueType,
	|	T.Property.DeletionMark                AS PropertyDeletionMark
	|FROM
	|	PropertiesTable AS T
	|TOTALS
	|	MAX(NameProperty)
	|BY
	|	Property
	|";
	
	Query.Text = QueryText;
	Query.SetParameter("PropertiesSets", PropertiesSets);
	
	SelectionProperty = Query.Execute().Select(QueryResultIteration.ByGroups, "Property");
	While SelectionProperty.Next() Do
		
		If IsExpression(SelectionProperty.NameProperty) Then
			Continue;
		EndIf;
		
		FillingData = Undefined;
		PropertyDetails = Undefined;
		
		Selection = SelectionProperty.Select();
		While Selection.Next() Do
			If PropertyDetails = Undefined Then
				PropertyDetails = DescriptionOfConstructorProperty();
				FillPropertyValues(PropertyDetails, Selection);
			EndIf;
			PropertyDetails.PropertiesSets.Add(Selection.PropertiesSet);
			If FillingData = Undefined Then
				Keys = "Name,Type,Synonym,ChoiceFoldersAndItems,ChoiceParameters";
				FillingData = New Structure(Keys);
				FillingData.Name      = PropertyDetails.NameProperty;
				FillingData.Type      = PropertyDetails.PropertyValueType;
				FillingData.Synonym  = PropertyDetails.Property_Name;
				ChoiceParameters = New Array;
				If PropertyDetails.PropertyValueType.ContainsType(Type("CatalogRef.ObjectsPropertiesValues")) Then
					If Not ValueIsFilled(PropertyDetails.PropertyOwnerOfAdditionalValues) Then
						PropertyDetails.PropertyOwnerOfAdditionalValues = PropertyDetails.Property;
					EndIf;
					ChoiceParameters.Add(New ChoiceParameter("Filter.Owner", PropertyDetails.PropertyOwnerOfAdditionalValues));
				EndIf;
				FillingData.ChoiceParameters = New FixedArray(ChoiceParameters);
			EndIf;
		EndDo;
		
		AttributeDetails = DescriptionOfAttributesOfUploadedData(FillingData);
		AttributeDetails.PropertyDetails = PropertyDetails;
		DescriptionOfUploadedDataElement.AdditionalDetails_.Insert(FillingData.Name, AttributeDetails);
		
	EndDo;
	
EndProcedure

Function DescriptionOfConstructorProperty()
	
	PropertyDetails = New Structure();
	
	PropertyDetails.Insert("Property");
	PropertyDetails.Insert("NameProperty");
	PropertyDetails.Insert("Property_Name");
	PropertyDetails.Insert("PropertyPresentation");
	PropertyDetails.Insert("HeaderProperty");
	PropertyDetails.Insert("PropertyIsAdditionalInformation");
	PropertyDetails.Insert("PropertyOwnerOfAdditionalValues");
	PropertyDetails.Insert("PropertyValueType");
	PropertyDetails.Insert("PropertyDeletionMark");
	
	PropertyDetails.Insert("PropertiesSets", New Array);
	
	Return PropertyDetails;
	
EndFunction

Function RequiredAttributesOfUploadedDataElement(MetadataObjectName, TSName = "")
	
	Result = New Array;
	
	If MetadataObjectName = "Products" Then
		
		Result.Add("Description");
		Result.Add("ProductKind");
		Result.Add("UnitOfMeasure");
	
	ElsIf MetadataObjectName = "WorkCenterTypes" Then
		
		Result.Add("Description");
		Result.Add("Department");
		
	ElsIf MetadataObjectName = "WorkCenters" Then
	
		Result.Add("Description");
		Result.Add("WorkCenterType");
	
	ElsIf MetadataObjectName = "BillsOfMaterials" Then
	
		If IsBlankString(TSName) Then
		
			Result.Add("Description");
		
		ElsIf TSName = "MaterialsAndServices" Then
		
			Result.Add("NumberOfPackages");
			Result.Add("ProductCostElement");
		
		ElsIf TSName = "LaborCosts" Then
		
			Result.Add("WorkKind");
			Result.Add("Count");
			Result.Add("ProductCostElement");
		
		EndIf;
		
	ElsIf MetadataObjectName = "ProductionStages" Then
		
		Result.Add("Department");
		
	ElsIf MetadataObjectName = "ManufacturingOperations" Then
		
		Result.Add("Description");
		Result.Add("Count");
		
	ElsIf MetadataObjectName = "EmployeeWorkKinds" Then
		
		Result.Add("Description");
		
	ElsIf MetadataObjectName = "EngineeringChangeOrder" Then
		
		If Not IsBlankString(TSName) Then
		
			Result.Add("NumberOfPackages");
			
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

Function ExcludedAttributesOfUploadedDataElement(MetadataObjectName, TSName = "")
	
	Result = StrSplit("Ref,Code,Number,Date,Posted,Owner,IsFolder,DeletionMark,Predefined,PredefinedDataName",",");
	
	If MetadataObjectName = "Products" Then
		
		CommonClientServer.SupplementArray(Result, Catalogs.Products.DetailsOfSignsOfAccountingFeatures(Metadata.Catalogs.Products));
		Result.Add("ItemsType");
		Result.Add("SaleRegistrationOption");
		Result.Add("AccessGroup");
		Result.Add("UseVariants");
		Result.Add("BatchOwner");
		Result.Add("ItemVariantsOwner");
		Result.Add("ProductCategoryOwner");
		Result.Add("AccountingFeature");
		Result.Add("ShelfLifeUnitOfMeasure");
	
	ElsIf MetadataObjectName = "BillsOfMaterials" Then
		
		Result.Add("AssignmentOption");
		Result.Add("MultiStageProductionProcess");
		Result.Add("ProductionProcessType");
		
		Result.Add("ThereIsSpecifiedMainProduct");
		Result.Add("ContainsResourcesParametrization");
		Result.Add("ContainsNestedBOMs");
		Result.Add("ContainsProbabilityCalculation");
		Result.Add("ContainsAliquotStandardsOfWorkCenterTypes");
		
		Result.Add("MainProductProductKind");
		Result.Add("MainProductProducts");
		Result.Add("MainProductCharacteristic");
		Result.Add("MainProductPackage");
		Result.Add("MainProductNumberOfPackages");
		Result.Add("MainProductStage");
		
		Result.Add("ItemKindOfProductUnderRM");
		Result.Add("UnderRepairProduct");
		Result.Add("UnderRepairVariant");
		
		Result.Add("Products");
		Result.Add("Characteristic");
		Result.Add("Stage");
		Result.Add("StageEditing");
		Result.Add("Operation");
		Result.Add("OperationEdit");
		Result.Add("MethodOfProductsAutoselection");
		Result.Add("MethodOfItemVariantAutoselection");
		Result.Add("PropertyThatContainsProducts");
		Result.Add("MethodOfReceivingMaterial");
		Result.Add("SourceOfSemiFinishedProduct");
		Result.Add("BillOfMaterialsRM");
		Result.Add("BatchIndicationRequired");
		Result.Add("PrintRouteSheet");
		
		Result.Add("DataVersionID");
		
	ElsIf MetadataObjectName = "ProductionStages" Then
		
		Result.Add("RouteSheet");
		Result.Add("RouteSheetFactor");
		
		Result.Add("WorkPlanning");
		
		Result.Add("ContainsResourcesParametrization");
		
	ElsIf MetadataObjectName = "ManufacturingOperations" Then
		
		Result.Add("Id");
		Result.Add("ContainsNestedRoute");
		Result.Add("NestedRoute");
		Result.Add("ContainsTechnologicalProcess");
		Result.Add("TechnologicalProcess");
		Result.Add("TechnologicalProcessFactor");
		Result.Add("BillOfMaterials");
		Result.Add("Basis");
		
	ElsIf MetadataObjectName = "EngineeringChangeOrder" Then
		
		Result.Add("ReplacementOption");
		Result.Add("Product");
		Result.Add("ItemVariantOfProduct");
		Result.Add("Products");
		Result.Add("Characteristic");
		Result.Add("BillOfMaterials");
		Result.Add("Stage");
		
	EndIf;
	
	Return Result;
	
EndFunction

Procedure AddDescriptionOfReferenceTypes(AttributeDetails)
	
	If AttributeDetails.IDType <> Undefined Then
		Type = AttributeDetails.IDType;
	Else
		Type = AttributeDetails.Type;
	EndIf;
	
	For Each Type In Type.Types() Do
		If Common.IsReference(Type) Then
			
			Ref = New(Type); // CatalogRef
			Ref_Metadata = Ref.Metadata();
			
			LongDesc = DescriptionOfConstructorReferenceType();
			LongDesc.Type              = Type;
			LongDesc.MetadataObject = Ref;
			LongDesc.FullName        = Ref_Metadata.FullName();
			
			FillPropertyValues(LongDesc, Ref_Metadata);
			
			For Each StandardAttribute In Ref_Metadata.StandardAttributes Do // MetadataObject
				PropertyName = "";
				If StandardAttribute.Name = "Code" Then
					PropertyName = "HasCode";
				ElsIf StandardAttribute.Name = "Description" Then
					PropertyName = "HasDescription";
				ElsIf StandardAttribute.Name = "Number" Then
					PropertyName = "HasNumber";
				EndIf;
				If Not IsBlankString(PropertyName) Then
					LongDesc[PropertyName] = True;
					If Not AttributeDetails.ThisIsID Then
						AttributeDetails[PropertyName] = True;
					EndIf;
				EndIf;
			EndDo;
			
			AttributeDetails.RefTypesDetails.Add(LongDesc);
			
		EndIf;
	EndDo;
	
EndProcedure

// Returns a description OF THE Attributes of the uploaded data ELEMENT
// 
// Parameters:
//  AttributeName - String
//  DescriptionOfUploadedDataElement - See DescriptionOfUploadedData
// 
// Returns:
//  Undefined - Description Of The Attributes Of The Uploaded Data
Function DescriptionOfAttributesOfUploadedDataByName(AttributeName, DescriptionOfUploadedDataElement) Export
	
	For Each AttributeGroup In ProductDataManagementClientServer.AttributesGroups() Do
		If DescriptionOfUploadedDataElement[AttributeGroup].Property(AttributeName) Then
			Return DescriptionOfUploadedDataElement[AttributeGroup][AttributeName];
		EndIf;
	EndDo;
	
	Return Undefined;
	
EndFunction

// Determines whether the passed setting is an expression
// 
// Parameters:
//  SettingText - String
// 
// Returns:
//  Boolean
Function IsExpression(SettingText) Export
	
	IsExpression = False;
	SpecialChars  = " [].,+-/*?=<>():;""!@#$%&№{}?\|/`~'^";
	
	For CharNum = 1 To StrLen(SettingText) Do
		Char = Mid(SettingText, CharNum, 1);
		If StrFind(SpecialChars, Char) > 0 Then
			IsExpression = True;
			Break;
		EndIf;
	EndDo;
	
	Return IsExpression;
	
EndFunction

#Region RoutineTask_LoadingOfProductionNSI

Procedure ImportProductionMasterData(DataSource) Export
	
	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.ImportProductionMasterData);
	
	If IsBlankString(UserName()) Then
		
		SetPrivilegedMode(True);
		
	EndIf;
	
	Parameters = New Structure;
	Parameters.Insert("DataSource", DataSource);
	
	DataProcessor = DataProcessors.ImportProductionMasterData.Create();
	DataProcessor.ExecuteAction(DataProcessors.ImportProductionMasterData.UploadDataAction(), Parameters);
	
EndProcedure

#EndRegion

#EndRegion

#Region DirectiveSubstitutions

// The text of the substitution fields for the selection of substitutions.
// 
// Parameters:
//  SelectionParameters - See Catalogs.BillsOfMaterials.DataSamplingParameters
//  NameOfMaterialsTable - String - 
//  Filter - String - Additional selection
// 
// Returns:
//  String
Function QueryTextOfDirectiveReplacementField(SelectionParameters = Undefined, NameOfMaterialsTable = "", Filter = "") Export
	
	QueryText = "
	|	VALUE(Document.EngineeringChangeOrder.EmptyRef) AS PermissionToReplace,
	|	FALSE                                                         AS SelectReplacement
	|"; //@Query-part
	
	Return QueryText;
	
EndFunction

Procedure PerformDirectiveSubstitutionsInDataSet(DataSet, Parameters) Export
	
	If Not AlternativeMaterials.UseDirectiveSubstitutions() Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager();
	
	QueriesTexts = New Array;
	
	QueryText = "
	|SELECT
	|	0                                AS Ref,
	|	DataSet.Products         AS Products,
	|	DataSet.Characteristic       AS Characteristic,
	|	DataSet.Package             AS Package
	|INTO TTListOfProducts
	|FROM
	|	&DataSet AS DataSet
	|
	|";
	
	ParametersTable = AlternativeMaterials.TableOfAnalogParameters(New TypeDescription("Number"));
	ParametersString1 = ParametersTable.Add();
	
	If Not Parameters.Property("ProductionStart", ParametersString1.PermissionValidityDate)
		Or Not ValueIsFilled(ParametersString1.PermissionValidityDate) Then
		ParametersString1.PermissionValidityDate = CurrentSessionDate();
	EndIf;
	If Parameters.Property("Product", ParametersString1.Product)
		And ValueIsFilled(ParametersString1.Product) Then
		Parameters.Property("ItemVariantOfProduct", ParametersString1.ItemVariantOfProduct);
		Parameters.Property("ProductSpecification", ParametersString1.BillOfMaterials);
		Parameters.Property("ProductSpecificationStage", ParametersString1.Stage);
	Else
		Parameters.Property("Products", ParametersString1.Product);
		Parameters.Property("Characteristic", ParametersString1.ItemVariantOfProduct);
		Parameters.Property("BillOfMaterials", ParametersString1.BillOfMaterials);
		Parameters.Property("BOMStage", ParametersString1.Stage);
	EndIf;
	Parameters.Property("ReferenceOrder", ParametersString1.ProductionOrder);
	Parameters.Property("ProductionDispatcherBusinessUnit", ParametersString1.Department);
	Parameters.Property("LineOfBusiness", ParametersString1.LineOfBusiness);
	
	QueriesTexts.Add(QueryText);
	
	MatchingMatchingFields = New Map;
	MatchingMatchingFields.Insert("ReplacementPriority", "InstructionsForReplacement");
	
	ParametersForSelectingAnalogs = New Structure;
	ParametersForSelectingAnalogs.Insert("GoodsTogetherWithParameters",         False);
	ParametersForSelectingAnalogs.Insert("ConsiderManyToMany",             False);
	ParametersForSelectingAnalogs.Insert("ToSelectInterchangeableAnalogues", False);
	ParametersForSelectingAnalogs.Insert("SelectionOfPermissions",                  MatchingMatchingFields);
	ParametersForSelectingAnalogs.Insert("NameOfTemporaryGoodsTable",        "TTListOfProducts");
	ParametersForSelectingAnalogs.Insert("TempTableName",              "TTDirectiveSubstitutions");
	
	QueriesTexts.Add(AlternativeMaterials.QueryTextDirectiveSubstitutions(ParametersForSelectingAnalogs));
	
	// Package data
	QueriesTexts.Add(QueryTextPackageData_(StrSplit("TTListOfProducts,TTDirectiveSubstitutions", ",")));
	
	QueryText = "
	|SELECT
	|	Substitutions_3.Products.ItemsType              AS ItemsType,
	|	Substitutions_3.Products.UnitOfMeasure             AS UnitOfMeasure,
	|	UNDEFINED                                     AS PackageData,
	|	Substitutions_3.Products.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.NumberOfPieces)   AS PieceUnitOfMeasure,
	|	ISNULL(&QueryTextMeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.NumberOfPieces), FALSE)           AS PackagingPiece,
 	|	CASE 
	|		WHEN Substitutions_3.Products.UseVariants IN (
	|				VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind),
	|				VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind),
	|				VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems))
	|			THEN TRUE
	|		ELSE FALSE
	|	END                                                                       AS ItemVariantsAreUsed,
	|	ISNULL(&RoundUpNumberOfUnitItems_
	|		AND Substitutions_3.Products.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.NumberOfPieces)
	|		AND Substitutions_3.Package <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|		AND &QueryTextMeasuredValueType IN (
	|			VALUE(Enum.TypesOfMeasuredValues.Weight),
	|			VALUE(Enum.TypesOfMeasuredValues.Length),
	|			VALUE(Enum.TypesOfMeasuredValues.VolumeM3),
	|			VALUE(Enum.TypesOfMeasuredValues.AreaTypeOfMeasurement)), FALSE)        AS RoundOff,
	|	Substitutions_3.*
	|FROM
	|	TTDirectiveSubstitutions AS Substitutions_3
	|
	|ORDER BY
	|	Substitutions_3.ScopeMaxPriority DESC,
	|	Substitutions_3.Period DESC,
	|	Substitutions_3.Resolution DESC";
	
	TextOfMeasuredValueTypeField = Catalogs.PackagesAndUnitsOfMeasure.RequestTextValueOfUnitDetails(
		"MeasuredValueType",
		"Substitutions_3.Package",
		"Substitutions_3.Products");
	
	QueryText = StrReplace(
		QueryText, 
		"&QueryTextMeasuredValueType",
		TextOfMeasuredValueTypeField);
		
	Round = ?(Parameters.Property("RoundUpNumberOfUnitItems_"), Parameters.RoundUpNumberOfUnitItems_, True);
	Query.SetParameter("RoundUpNumberOfUnitItems_", Round);
	
	QueriesTexts.Add(QueryText);
	
	Query.Text = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
	Query.SetParameter("DataSet", DataSet);
	Query.SetParameter("ParametersTable", ParametersTable);
	
	QueryResults = Query.ExecuteBatch();
	
	PackageData_ = QueryResults[QueryResults.Count()-2].Unload();
	DataForReplacement = QueryResults[QueryResults.Count()-1].Unload();
	
	FillInPackingDataInDataset(DataForReplacement, PackageData_);
	FillInPackingDataInDataset(DataSet, PackageData_);
	
	For Each RowData In DataSet Do
		
		ReplacementData = ReplacementDataForDatasetRow(RowData, DataForReplacement);
		If ReplacementData <> Undefined Then
			FillPropertyValues(RowData, ReplacementData);
		EndIf;
		
	EndDo;
	
EndProcedure

// Perform a directive replacement in a row of the dataset.
// 
// Parameters:
//  RowData - ValueTableRow
//  DataForReplacement - ValueTable
//  AdditionalSearchFields - String
// Returns:
//  Structure,Undefined - replacement result data
Function ReplacementDataForDatasetRow(RowData, DataForReplacement, AdditionalSearchFields = "") Export
	
	If DataForReplacement.Count() = 0 Then
		Return Undefined;
	EndIf;
	
	SearchFields1 = "ProductsRole,Products,Characteristic";
	SearchFields2 = "ProductsRole,Resolution";
	
	If Not IsBlankString(AdditionalSearchFields) Then
		SearchFields1 = SearchFields1 + "," + AdditionalSearchFields;
		SearchFields2 = SearchFields2 + "," + AdditionalSearchFields;
	EndIf;
	
	If DataForReplacement.Indexes.Count() = 0 Then
		DataForReplacement.Indexes.Add(SearchFields1);
		DataForReplacement.Indexes.Add(SearchFields2);
	EndIf;
	
	TheStructureOfTheSearch1 = New Structure(SearchFields1);
	FillPropertyValues(TheStructureOfTheSearch1, RowData);
	TheStructureOfTheSearch1.ProductsRole = Enums.SubstituteRoles.Material;
	
	FoundRows = DataForReplacement.FindRows(TheStructureOfTheSearch1);
	If FoundRows.UBound() = -1 Then
		Return Undefined;
	EndIf;
	
	StringMaterial = FoundRows[0];
	
	TheStructureOfTheSearch2 = New Structure(SearchFields2);
	FillPropertyValues(TheStructureOfTheSearch2, StringMaterial);
	TheStructureOfTheSearch2.ProductsRole = Enums.SubstituteRoles.Substitute;
	
	FoundRows = DataForReplacement.FindRows(TheStructureOfTheSearch2);
	If FoundRows.UBound() = -1 Then
		Return Undefined;
	EndIf;
	
	StringAnalog = FoundRows[0];
	
	MaterialRatio = StringMaterial.NumberOfPackages
		* StringMaterial.PackageData.Numerator / StringMaterial.PackageData.Denominator;
		
	AnalogCoefficient = StringAnalog.NumberOfPackages
		* StringAnalog.PackageData.Numerator / StringAnalog.PackageData.Denominator;
		
	If RowData.PieceUnitOfMeasure
		And (MaterialRatio <> 1 Or AnalogCoefficient <> 1) Then
		Return Undefined; // incorrect directive permission to replace
	EndIf;
	
	ReplacementResult = New Structure(ProcessedAttributesForDirectiveReplacement());
	
	If RowData.NumberOfPackages <> 0 Then
		
		SubstituteQuantity = AnalogCoefficient * ProductionClientServer.CoefficientByStandard(False,
			RowData.NumberOfPackages * RowData.PackageData.Numerator / RowData.PackageData.Denominator,
			StringMaterial.NumberOfPackages,
			StringMaterial.PackageData);
			
		ReplacementResult.Insert("NumberOfPackages", SubstituteQuantity);
		ReplacementResult.Insert("NumberOfPackagesPerUnitOfProductionBatch", SubstituteQuantity);
		
	EndIf;
	
	ReplacementResult.PermissionToReplace               = StringAnalog.Resolution;
	
	ReplacementResult.Products                     = StringAnalog.Products;
	ReplacementResult.Characteristic                   = StringAnalog.Characteristic;
	ReplacementResult.ItemVariantsAreUsed       = StringAnalog.ItemVariantsAreUsed;

	ReplacementResult.UnitOfMeasure                 = StringAnalog.UnitOfMeasure;
	ReplacementResult.Package                         = Undefined;
	ReplacementResult.PackagingFactor              = 1;
	ReplacementResult.PackageData                   = ProductDataManagementCached.PackingDataStructure();
	ReplacementResult.RoundOff                        = StringAnalog.RoundOff;
	
	ReplacementResult.MethodOfReceivingMaterial         = Enums.MethodsOfReceivingBOMMaterials.Provide;
	ReplacementResult.BillOfMaterials                     = Catalogs.BillsOfMaterials.EmptyRef();
	ReplacementResult.SourceOfSemiFinishedProduct   = Catalogs.BillsOfMaterials.EmptyRef();
	ReplacementResult.Produced                     = False;
	ReplacementResult.ProducedInProcess            = False;
	
	ReplacementResult.UseAutoselection            = False;
	ReplacementResult.MethodOfProductsAutoselection     = Enums.MethodsOfProductAutoSelection.SpecifiedInMasterData;
	ReplacementResult.MethodOfItemVariantAutoselection   = Enums.MethodsOfItemVariantAutoselection.SpecifiedInMasterData;
	ReplacementResult.AutoselectionDetails               = "";
	ReplacementResult.ItemVariantAutoSelectionAlgorithm = "";
	
	Return ReplacementResult;
	
EndFunction

Function ProcessedAttributesForDirectiveReplacement(ToArray = False)
	
	Result = New Array;
	
	Result.Add("PermissionToReplace");
	
	Result.Add("Products");
	Result.Add("Characteristic");
	Result.Add("ItemVariantsAreUsed");
	Result.Add("UnitOfMeasure");
	Result.Add("Package");
	Result.Add("PackagingFactor");
	Result.Add("PackageData");
	Result.Add("RoundOff");
	
	Result.Add("MethodOfReceivingMaterial");
	Result.Add("BillOfMaterials");
	Result.Add("SourceOfSemiFinishedProduct");
	Result.Add("Produced");
	Result.Add("ProducedInProcess");
	
	Result.Add("UseAutoselection");
	Result.Add("MethodOfProductsAutoselection");
	Result.Add("MethodOfItemVariantAutoselection");
	Result.Add("AutoselectionDetails");
	Result.Add("ItemVariantAutoSelectionAlgorithm");
	
	If Not ToArray Then
		Result = StrConcat(Result,",");
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#Region Other

// Returns a description of the functions used in the formula constructor
// 
// Returns:
//  Structure - Description of functions:
//   *Key - String - ID of the function in the formula.
//   *Value - String - The full path to the function, including the name of the shared module.
//
Function FunctionsFromCommonModule()
	
	FunctionDescription = ProductDataManagementCached.DescriptionOfFormulaConstructorFunctions();
	
	Structure = New Structure;
	
	For Each LongDesc In FunctionDescription Do
		
		Structure.Insert(LongDesc.Id, LongDesc.FullPath);
		
	EndDo;
	
	Return Structure;
	
EndFunction

Function UseSemiFinishedProductsProducedAtStage(Object = Undefined) Export
	
	Result = False;
	ThereIsWayToGetAtStage = False;
	If Object <> Undefined Then
		ThereIsWayToGetAtStage = Object.MaterialsAndServices.FindRows(
			New Structure("MethodOfReceivingMaterial", PredefinedValue("Enum.MethodsOfReceivingBOMMaterials.ProducedOnStage"))).Count() > 0;
	EndIf;
	If ThereIsWayToGetAtStage
			Or Not GetFunctionalOption("DynamicStructureOfProductionOrders") Then
		Result = True;
	EndIf;
	Return Result;
	
EndFunction

Procedure UpdateObjectLinkKeys(Object, OnlyFilledValues = False) Export
	
	MainTabularParts  = New Array;
	MainTabularParts.Add("ManufacturedProducts");
	MainTabularParts.Add("RecyclableWaste");
	MainTabularParts.Add("MaterialsAndServices");
	MainTabularParts.Add("LaborCosts");
	MainTabularParts.Add("WorkCenterTypes");
	MainTabularParts.Add("AlternateWorkCenterTypes");
	MainTabularParts.Add("IntermediateRelease");
	DependentTableParts = New Structure;
	DependentTableParts.Insert("AlternateWorkCenterTypes", "LinkKeyWorkCenterTypes");
	DependentTableParts.Insert("PropertyMapping", "ConnectionKey");
	DependentTableParts.Insert("SelectionByProperties", "ConnectionKey");
	MatchingKeys = New Map();
	
	For Each TSName In MainTabularParts Do
		If Not CommonClientServer.HasAttributeOrObjectProperty(Object, TSName) Then
			Continue;
		EndIf;
		For Each String In Object[TSName] Do
			If OnlyFilledValues And Not ValueIsFilled(String.ConnectionKey) Then
				Continue;
			EndIf;
			NewCommunicationKey_ = New UUID();
			MatchingKeys.Insert(String.ConnectionKey, NewCommunicationKey_);
			String.ConnectionKey = NewCommunicationKey_;
		EndDo;
	EndDo;
	
	For Each KeyAndValue In DependentTableParts Do
		TSName = KeyAndValue.Key;
		If Not CommonClientServer.HasAttributeOrObjectProperty(Object, TSName) Then
			Continue;
		EndIf;
		For Each String In Object[TSName] Do
			NewCommunicationKey_ = MatchingKeys.Get(String[KeyAndValue.Value]);
			If NewCommunicationKey_ <> Undefined Then
				String[KeyAndValue.Value] = NewCommunicationKey_;
			EndIf;
		EndDo;
	EndDo;
	
EndProcedure

Function PieceProduct(Products) Export
	
	Return ( Common.ObjectAttributeValue(Products, "UnitOfMeasure.MeasuredValueType") = Enums.TypesOfMeasuredValues.NumberOfPieces );
	
EndFunction

Procedure FillInConversionFactorToMainProduct(OrderedProduct, MainProduct) Export
	
	If Not OrderedProduct.ThisIsMainProduct
		And Not OrderedProduct.PackageData.Denominator = 0
		And Not MainProduct.NumberOfPackagesPerUnitOfProductionBatch = 0
		And Not MainProduct.PackageData.Numerator = 0 Then
		
		OrderedProduct.ConversionFactorToMainProduct = 
			(OrderedProduct.NumberOfPackagesPerUnitOfProductionBatch
				* OrderedProduct.PackageData.Numerator * MainProduct.PackageData.Denominator)
				/
			(MainProduct.NumberOfPackagesPerUnitOfProductionBatch
				* OrderedProduct.PackageData.Denominator * MainProduct.PackageData.Numerator);
			
	EndIf;
	
EndProcedure

// Checks the compliance of the semi-finished product and the specification that is assigned for its production.
//
// Parameters:
//  Object                  - CatalogObject.BillsOfMaterials,
//                              Processing an object.Editspecificationistroquizacase,
//                              Document link.Custom production - an object associated with verification
//  CollectionOfSemiFinishedProducts - Array - a collection of rows containing data about semi-finished products
//  CollectionOfStages         - Array - a collection of strings containing data about the sequence of stages
// Returns:
//   - Structure - Structure of parameters for checking the filling of internal semi
//                  -finished products in the resource specification and the production order specification.
//
Function GetParametersForCheckingInternalSemiFinishedProducts(Object, Val CollectionOfSemiFinishedProducts = Undefined, Val CollectionOfStages = Undefined) Export
	
	ParametersForCheckingInternalSemiFinishedProducts = New Structure("
		|TheStructureOfTheSearch,
		|TableOfSemiFinishedProducts,
		|PresentationOfTableOfSemiFinishedProducts");
	
		
		// the structure of the search in the table of semi-finished products
		
		ParametersForCheckingInternalSemiFinishedProducts.TheStructureOfTheSearch = New Structure("
			|SourceOfSemiFinishedProduct,
			|Products,
			|Characteristic");
			
		If CollectionOfSemiFinishedProducts = Undefined Then
			CollectionOfSemiFinishedProducts = Object.RecyclableWaste;
		EndIf;
		
		QueryText = "
		|SELECT
		|	CAST(T.StageEditing AS Catalog.ProductionStages)      AS SourceOfSemiFinishedProduct,
		|	CAST(T.Products AS Catalog.Products)                 AS Products,
		|	CAST(T.Characteristic AS Catalog.ItemsCharacteristics) AS Characteristic,
		|	CAST(T.Package AS Catalog.PackagesAndUnitsOfMeasure)         AS Package,
		|	T.NumberOfPackages                                                 AS NumberOfPackages,
		|	CAST(T.QuantityCalculationAlgorithm AS STRING(100)) <> """"        AS CalculationByFormula
		|INTO
		|	TTTableOfSemiFinishedProducts
		|FROM
		|	&TableOfSemiFinishedProducts AS T
		|WHERE
		|	T.ProcessByBOM = FALSE
		|;
		|
		|SELECT
		|	T.SourceOfSemiFinishedProduct AS SourceOfSemiFinishedProduct,
		|	T.Products                   AS Products,
		|	T.Characteristic                 AS Characteristic,
		|	SUM(CASE WHEN T.CalculationByFormula
		|			THEN -1
		|		ELSE
		|			CAST(T.NumberOfPackages * ISNULL(&QueryTextPackagingFactor, 1) AS NUMBER(15,3))
		|	END)                           AS Count
		|FROM
		|	TTTableOfSemiFinishedProducts AS T
		|
		|GROUP BY
		|	T.SourceOfSemiFinishedProduct,
		|	T.Products,
		|	T.Characteristic,
		|	T.CalculationByFormula
		|";
		
		QueryText = StrReplace(QueryText,
			"&QueryTextPackagingFactor",
			Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient("T.Package", "T.Products"));
		
		Query = New Query(QueryText);
		Query.SetParameter("TableOfSemiFinishedProducts", CollectionOfSemiFinishedProducts);
		
		TableOfSemiFinishedProducts = Query.Execute().Unload();
		
		TableOfSemiFinishedProducts.Indexes.Add("
			|SourceOfSemiFinishedProduct, 
			|Products, 
			|Characteristic");
		
		ParametersForCheckingInternalSemiFinishedProducts.TableOfSemiFinishedProducts = TableOfSemiFinishedProducts;
		
		// presentation of the table of semi-finished products
		
		ParametersForCheckingInternalSemiFinishedProducts.PresentationOfTableOfSemiFinishedProducts = NStr("vi = 'Sản phẩm phụ và xuất xưởng trung gian';
																											|ru = 'Побочный и промежуточный выпуск';
																											|en = 'Side and intermediate release'; fa = 'عرضه جانبی و میانی';
																											|it = 'Produzione collaterale e intermedia';
																											|pl = 'Poboczne i pośrednie wypuszczenie';
																											|tr = 'Yan ve ara ürün çıkışı'");
		
	
	Return ParametersForCheckingInternalSemiFinishedProducts;
	
EndFunction

Function NeedForInternalSemiFinishedProducts(ParametersForCheckingInternalSemiFinishedProducts, RowsArray)
	
	TableOfDemandForSemiFinishedProducts = New ValueTable;
	
	TableOfDemandForSemiFinishedProducts.Columns.Add("LineNumber", New TypeDescription("Number", New NumberQualifiers(10, 0, AllowedSign.Nonnegative)));
	TableOfDemandForSemiFinishedProducts.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
	TableOfDemandForSemiFinishedProducts.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
	
	TableOfDemandForSemiFinishedProducts.Columns.Add("Package", New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
	TableOfDemandForSemiFinishedProducts.Columns.Add("NumberOfPackages", New TypeDescription("Number", New NumberQualifiers(15, 3, AllowedSign.Nonnegative)));
	TableOfDemandForSemiFinishedProducts.Columns.Add("Count", New TypeDescription("Number", New NumberQualifiers(15, 3, AllowedSign.Nonnegative)));
	
	TableOfDemandForSemiFinishedProducts.Columns.Add("SourceOfSemiFinishedProduct", New TypeDescription("CatalogRef.ProductionStages"));
	
		
		TableOfDemandForSemiFinishedProducts.Columns.Add("Stage", New TypeDescription("CatalogRef.ProductionStages"));
		
	
	For Each CollectionItem In RowsArray Do
		
		NewRow = TableOfDemandForSemiFinishedProducts.Add();
		
		FillPropertyValues(NewRow, CollectionItem);
		
			
			NewRow.Stage = CollectionItem.StageEditing;
			
		
	EndDo;
	
	Return TableOfDemandForSemiFinishedProducts;
	
EndFunction

Function RequestTextForCheckingInternalSemiFinishedProducts(ParametersForCheckingInternalSemiFinishedProducts)
	
		
		QueryText = 
		"SELECT
		|	T.LineNumber AS LineNumber,
		|	CAST(T.Products AS Catalog.Products) AS Products,
		|	CAST(T.Characteristic AS Catalog.ItemsCharacteristics) AS Characteristic,
		|	CAST(T.Stage AS Catalog.ProductionStages) AS Stage,
		|	CAST(T.SourceOfSemiFinishedProduct AS Catalog.ProductionStages) AS SourceOfSemiFinishedProduct,
		|	CAST(T.Package AS Catalog.PackagesAndUnitsOfMeasure) AS Package,
		|	T.NumberOfPackages                                         AS NumberOfPackages
		|INTO TTDemandForSemiFinishedProducts
		|FROM
		|	&TableOfDemandForSemiFinishedProducts AS T
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	T.LineNumber AS LineNumber
		|INTO TTSequenceErrors
		|FROM
		|	TTDemandForSemiFinishedProducts AS T
		|WHERE
		|	T.SourceOfSemiFinishedProduct.StageNumber >= CASE
		|			WHEN T.Stage = VALUE(Catalog.ProductionStages.EmptyRef)
		|				THEN 1
		|			ELSE T.Stage.StageNumber
		|		END
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	T.LineNumber AS LineNumber
		|INTO TTErrorOperation
		|FROM
		|	TTDemandForSemiFinishedProducts AS T
		|WHERE
		|	T.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	T.LineNumber AS LineNumber
		|INTO TTErrorProductionOnSide
		|FROM
		|	TTDemandForSemiFinishedProducts AS T
		|WHERE
		|	T.SourceOfSemiFinishedProduct.ProductionByThirdParty
		|	AND NOT &ProductionIsUsed22
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	T.LineNumber AS LineNumber
		|FROM
		|	TTSequenceErrors AS T
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	T.LineNumber AS LineNumber
		|FROM
		|	TTErrorOperation AS T
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	T.LineNumber AS LineNumber
		|FROM
		|	TTErrorProductionOnSide AS T
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	T.LineNumber AS LineNumber,
		|	T.Products AS Products,
		|	T.Characteristic AS Characteristic,
		|	T.SourceOfSemiFinishedProduct AS SourceOfSemiFinishedProduct,
		|	T.Package AS Package,
		|	ISNULL(&QueryTextPackagingFactor, 1) AS PackagingFactor,
		|	CAST(T.NumberOfPackages * ISNULL(&QueryTextPackagingFactor, 1) AS NUMBER(15,3)) AS Count,
		|	T.Products.Presentation AS ProductsPresentation,
		|	T.Characteristic.Presentation AS CharacteristicPresentation,
		|	T.SourceOfSemiFinishedProduct.Presentation AS ReleaseStagePresentation,
		|	CASE
		|		WHEN T.Package <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|			THEN T.Package.Presentation
		|		ELSE T.Products.UnitOfMeasure.Presentation
		|	END AS PackagePresentation
		|FROM
		|	TTDemandForSemiFinishedProducts AS T
		|WHERE
		|	NOT T.LineNumber IN
		|				(SELECT
		|					SequenceErrors.LineNumber
		|				FROM
		|					TTSequenceErrors AS SequenceErrors
		|		
		|				UNION ALL
		|		
		|				SELECT
		|					ErrorsWork.LineNumber
		|				FROM
		|					TTErrorOperation AS ErrorsWork
		|		
		|				UNION ALL
		|		
		|				SELECT
		|					ProductionSideErrors.LineNumber
		|				FROM
		|					TTErrorProductionOnSide AS ProductionSideErrors)";
			
		QueryText = StrReplace(QueryText,
			"&QueryTextPackagingFactor",
			Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"T.Package",
			"T.Products"));
		
	
	Return QueryText;
	
EndFunction

Procedure ConfigureSelectionElementByParameters(ParametersStructure, FilterName, FormAttributeName) Export
	
	FilterValue = Undefined;
	
	If Not ParametersStructure.Property(FilterName, FilterValue) Then
		If ParametersStructure.Property("Filter") Then
			//
		EndIf;
	EndIf;
	
	If Not ValueIsFilled(FilterValue) Then
		Return;
	EndIf;
	
	//
	
EndProcedure

Procedure CheckFillInDefaultAttributes(Object) Export
	
	ObjectMetadata = Metadata.FindByType(TypeOf(Object));
	
	For Each Attribute In ObjectMetadata.Attributes Do
		FillValue = Attribute.Type.AdjustValue(Attribute.FillValue); // UnknownObject
		If ValueIsFilled(FillValue) And Not ValueIsFilled(Object[Attribute.Name]) Then
			Object[Attribute.Name] = FillValue;
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion