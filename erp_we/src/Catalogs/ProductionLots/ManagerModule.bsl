#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Matching with the list of details that determine the uniqueness of the key
// 
// Returns:
//   Map - the key is the name of the props 
//
Function KeyAttributes() Export
	
	Result = New Map;
	Result.Insert("Code");
	Result.Insert("Document");
	
	Return Result;
	
EndFunction

// Returns the production batch with the fields corresponding to the specified ones.
//
// Parameters:
//	BatchFields - Structure, ValueTableRow - the field production lot.
//		The required fields are "Document", "Organization", and "item"
//		. the other fields are optional and will be filled in with empty values if they are not available.
//	CheckBeforeCreation	- Boolean - flag for searching for a production batch before creating a new one.
//	UpdateExistingItems	- Boolean - flag for updating the fields of existing production batches.
//
// Returns:
//	CatalogRef.ProductionLots - a production batch found or formed.
//
Function GetProductionBatch(BatchFields = Undefined,
								CheckBeforeCreation = True,
								UpdateExistingItems = False) Export
	
	DefaultLanguageCode = Common.DefaultLanguageCode();
	
	// We will fill in all the details of the production batch.
	StructureOfPartyDetails = New Structure("Code, Document, Ref", 0, Undefined, Undefined);
	FillPropertyValues(StructureOfPartyDetails, BatchFields);
	
	For Each MetaAttribute In Metadata.Catalogs.ProductionLots.Attributes Do
		
		AttributeStructure = New Structure(MetaAttribute.Name);
		FillPropertyValues(AttributeStructure, BatchFields); // there may not be such a property in the Political Party
		
		StructureOfPartyDetails.Insert(
			MetaAttribute.Name,
			MetaAttribute.Type.AdjustValue(AttributeStructure[MetaAttribute.Name])); // and there is definitely such a property in the structure of the Visa
		
	EndDo;
	For Each MetaAttribute In Metadata.Catalogs.ProductionLots.TabularSections Do
		
		If MetaAttribute.Name = "AdditionalAttributes" Then
			Continue;
		EndIf;
		
		AttributeStructure = New Structure(MetaAttribute.Name);
		FillPropertyValues(AttributeStructure, BatchFields); // there may not be such a property in the Political Party
		
		StructureOfPartyDetails.Insert(
			MetaAttribute.Name,
			AttributeStructure[MetaAttribute.Name]); // and there is definitely such a property in the structure of the Visa
		
	EndDo;
	BeginTransaction();
	
	Try
		
		If CheckBeforeCreation Or UpdateExistingItems Then
			
			Block = New DataLock;
			LockItem = Block.Add("Catalog.ProductionLots");
			LockItem.SetValue("Code", StructureOfPartyDetails.Code);
			LockItem.SetValue("Document", StructureOfPartyDetails.Document);
			LockItem.Mode = DataLockMode.Exclusive;
			
			Block.Lock();
		
		EndIf;
		
		// If necessary, we will try to find a suitable match.
		BatchData = New Structure;
		BatchData.Insert("ProductionLot", Catalogs.ProductionLots.EmptyRef());
		
		If CheckBeforeCreation Then
			FilterStructure1 = New Structure(ProductionBatchIdentificationFields());
			FillPropertyValues(FilterStructure1, StructureOfPartyDetails);
			
			Query = New Query;
			Query.Text =
			"SELECT TOP 1
			|	Table.Ref AS ProductionLot
			|FROM
			|	Catalog.ProductionLots AS Table
			|WHERE
			|	NOT Table.DeletionMark
			|	AND &QueryCondition
			|";
			
			QueryCondition = "TRUE";
			
			For Each KeyAndValue In FilterStructure1 Do
				
				Query.SetParameter(KeyAndValue.Key, KeyAndValue.Value);
				QueryCondition = QueryCondition + "
					|	AND Table." + KeyAndValue.Key + " = &" + KeyAndValue.Key;
				
			EndDo;
			
			Query.Text = StrReplace(Query.Text, "&QueryCondition", QueryCondition);
			
			SetPrivilegedMode(True);
			Selection = Query.Execute().Select();
			SetPrivilegedMode(False);
			
			If Selection.Next() Then
				FillPropertyValues(BatchData, Selection);
			EndIf;
			
		EndIf;
		
		If Not ValueIsFilled(BatchData.ProductionLot)
			Or UpdateExistingItems Then
			
			SetPrivilegedMode(True);
			If Not ValueIsFilled(BatchData.ProductionLot) Then
				
				// The production batch is not in the directory - let's create a directory element.
				CatalogObject = Catalogs.ProductionLots.CreateItem();
				
				If ValueIsFilled(StructureOfPartyDetails.Ref) Then
					CatalogObject.SetNewObjectRef(StructureOfPartyDetails.Ref);
				EndIf;
				
			Else
				CatalogObject = BatchData.ProductionLot.GetObject();
			EndIf;
			
			FillPropertyValues(CatalogObject, StructureOfPartyDetails);
			CatalogObject.Companies.Clear();
			If CatalogObject.InternalSubcontracting Then
				For Each CurrentData In StructureOfPartyDetails.Companies Do
					NewRow = CatalogObject.Companies.Add();
					NewRow.Organization = CurrentData.Organization;
				EndDo;
			EndIf;
			CatalogObject.Write();
			
			SetPrivilegedMode(False);
			
			BatchData.ProductionLot = CatalogObject.Ref;
			
		EndIf;
		
		CommitTransaction();
		
		Return BatchData.ProductionLot;
		
	Except
		
		RollbackTransaction();
		
		CostGroupPresentation = CostGroupsServer.CostGroupPresentation(StructureOfPartyDetails);
		PartyName = NameOfProductionBatch(StructureOfPartyDetails, CostGroupPresentation);
		
		MessageText = NStr("vi = 'Không thể tạo lô sản xuất với các tham số: %ProductionLot% do: %Cause%';
							|ru = 'Не удалось создать партию производства с параметрами: %ProductionLot% по причине: %Cause%';
							|en = 'Cannot create a production lot with parameters: %ProductionLot%. Reason:%Cause%'; fa = 'Cannot create a production lot with parameters: %ProductionLot%. Reason:%Cause%';
							|it = 'Impossibile creare un lotto di produzione con i parametri: %ProductionLot% a causa di: %Cause%';
							|pl = 'Nie udało się utworzyć partię produkcji z parametrami: %ProductionLot% z powodu: %Cause%';
							|tr = '%Cause% nedeniyle %ProductionLot% parametreleri ile üretim lotu oluşturulamadı'");
		MessageText = StrReplace(MessageText, "%ProductionLot%", PartyName);
		MessageText = StrReplace(MessageText, "%Cause%", DetailErrorDescription(ErrorInfo()));
		
		WriteLogEvent(
			NStr("vi = 'Danh mục';
				|ru = 'Справочник';
				|en = 'Catalog'; fa = 'فهرست';
				|it = 'Directory';
				|pl = 'Catalog';
				|tr = 'Katalog'", DefaultLanguageCode)
				+"." + NStr("vi = 'Lô sản xuất';
							|ru = 'Партии производства';
							|en = 'Production lots'; fa = 'بچ‌های تولید';
							|it = 'Lotti di produzione';
							|pl = 'Partie produkcji';
							|tr = 'Üretim lotları'", DefaultLanguageCode)
				+ "." + NStr("vi = 'Nhận lô hàng sản xuất';
							|ru = 'Получить партию производства';
							|en = 'Get production lot'; fa = 'Get production lot';
							|it = 'Ricevere lotto di produzione';
							|pl = 'Otrzymaj partię produkcji';
							|tr = 'Üretim lotu al'", DefaultLanguageCode),
			EventLogLevel.Error,
			Metadata.Catalogs.ProductionLots,,
			MessageText);
		
		CommonClientServer.MessageToUser(ErrorDescription());
		
		Return Undefined;
		
	EndTry;
	
EndFunction

// Creates or updates the data of the production batch during the recording of the document.
//
// Parameters:
//  ProductionLot		 - CatalogRef.ProductionLots	 - link to the production batch.
//  BatchFields				 - Structure							 - description of the production batch.
//  UpdateExistingItems	 - Boolean								 - flag for updating existing batches.
// 
// Returns:
//  Structure -  Create Update Production Batch:
// 	* NewProductionBatch - Boolean - A new production Lot reference has been created
// 	* ProductionBatchNumber - Number - Production Batch Number
//
Function CreateUpdateProductionBatch(ProductionLot, BatchFields = Undefined, UpdateExistingItems = True) Export
	
	Result = New Structure("NewProductionBatch, ProductionBatchNumber", False, -1);
	
	If Not ValueIsFilled(ProductionLot) Then
		Return Result;
	EndIf;
	
	AttributesNames = New Structure("Code, Document, Ref, DeletionMark");
	
	StructureOfPartyDetails = New Structure;
	StructureOfPartyDetails.Insert("Code", 0);
	StructureOfPartyDetails.Insert("Document", Undefined);
	StructureOfPartyDetails.Insert("Ref", Undefined);
	StructureOfPartyDetails.Insert("DeletionMark", BatchFields.DeletionMark);
	
	For Each MetaAttribute In Metadata.Catalogs.ProductionLots.Attributes Do
		
		AttributesNames.Insert(MetaAttribute.Name);
		
		AttributeStructure = New Structure(MetaAttribute.Name);
		FillPropertyValues(AttributeStructure, BatchFields);
		
		StructureOfPartyDetails.Insert(
			MetaAttribute.Name,
			MetaAttribute.Type.AdjustValue(AttributeStructure[MetaAttribute.Name]));
		
	EndDo;
	For Each MetaAttribute In Metadata.Catalogs.ProductionLots.TabularSections Do
		
		If MetaAttribute.Name = "AdditionalAttributes" Then
			Continue;
		EndIf;
		
		AttributesNames.Insert(MetaAttribute.Name);
		
		AttributeStructure = New Structure(MetaAttribute.Name);
		FillPropertyValues(AttributeStructure, BatchFields);
		
		StructureOfPartyDetails.Insert(MetaAttribute.Name, AttributeStructure[MetaAttribute.Name]);
		
	EndDo;
	SetPrivilegedMode(True);
	PartyDetails = Common.ObjectAttributesValues(ProductionLot, AttributesNames);
	For Each CurrentData In PartyDetails Do
		If TypeOf(CurrentData.Value) = Type("QueryResult") Then
			PartyDetails[CurrentData.Key] = CurrentData.Value.Unload();
		EndIf;
	EndDo;
	SetPrivilegedMode(False);
	
	Result.ProductionBatchNumber = PartyDetails.Code;
	Result.NewProductionBatch = (PartyDetails.Code = Undefined);
	
	If Not Result.NewProductionBatch
		And (Not UpdateExistingItems Or PartyPropsStructuresAreEqual(PartyDetails, StructureOfPartyDetails)) Then
		Return Result;
	EndIf;
	
	SetPrivilegedMode(True);
	
	If Result.NewProductionBatch Then
		
		Block = New DataLock;
		LockItem = Block.Add("Catalog.ProductionLots");
		LockItem.SetValue("Document", StructureOfPartyDetails.Document);
		LockItem.Mode = DataLockMode.Exclusive;
		
		Block.Lock();
		
		Query = New Query(
		"SELECT
		|	ISNULL(MAX(Table.Code), 0) + 1 AS ProductionBatchNumber
		|FROM
		|	Catalog.ProductionLots AS Table
		|WHERE
		|	Table.Document = &Document
		|");
		Query.SetParameter("Document", StructureOfPartyDetails.Document);
		
		Selection = Query.Execute().Select();
		Selection.Next();
		
		Result.ProductionBatchNumber = Selection.ProductionBatchNumber;
		
		CatalogObject = Catalogs.ProductionLots.CreateItem();
		CatalogObject.SetNewObjectRef(ProductionLot);
		
	Else
		CatalogObject = ProductionLot.GetObject();
	EndIf;
	
	StructureOfPartyDetails.Code = Result.ProductionBatchNumber;
	FillPropertyValues(CatalogObject, StructureOfPartyDetails);
	CatalogObject.Companies.Clear();
	If CatalogObject.InternalSubcontracting Then
		For Each CurrentData In StructureOfPartyDetails.Companies Do
			NewRow = CatalogObject.Companies.Add();
			NewRow.Organization = CurrentData.Organization;
		EndDo;
	EndIf;
	CatalogObject.Write();
	
	SetPrivilegedMode(False);
	
	Return Result;
	
EndFunction

// The procedure receives data for forming production batches and generates them.
// 
// Parameters:
//	Query							- Query - request with parameters set for batch generation.
//	TextSelectionOfBatchFields					- String -
//		the text of the request for the formation of a temporary table in the Production party field with the fields
//			Document
//			Cost Grouping
//			Cost GroupNumber
//			Organization
//			Internal processing
//			Process Type
//			Directions of activity
//			Type of activitiesinds
//			Basic Product Nomenclature
//			Basic Design characteristics
//			Nomenclature
//			Characteristics
//			Product groupproducts
//			Specification
//			Appointment.
//	CheckBeforeCreation			- Boolean - flag for searching for a production batch before creating a new one.
//	UpdateExistingItems			- Boolean - flag for updating the fields of existing production batches.
//
Procedure FormProductionBatches(Query,
										TextSelectionOfBatchFields,
										CheckBeforeCreation = True,
										UpdateExistingItems = False) Export
	
	QueryTextArray = New Array;
	QueryTextArray.Add(QueryTextLineNumbersOfMainProducts());
	QueryTextArray.Add(TextSelectionOfBatchFields);
	
	QueryTextArray.Add(RequestTextValidBatchFields());
	QueryTextArray.Add(QueryTextProductionBatchTablePreliminary());
	QueryTextArray.Add(QueryTextTableOfBatchCompanies());
	QueryTextArray.Add(RequestTextTableOfProductionBatchesForProcessing(UpdateExistingItems));
	
	Query.Text = StrConcat(QueryTextArray, Common.QueryBatchSeparator());
	
	Query.SetParameter("AnalyticalAccountingByProductsGroups",
		GetFunctionalOption("AnalyticalAccountingByProductsGroups"));
	
	SetPrivilegedMode(True);
	Result = Query.ExecuteBatch();
	CompanyTable      = Result[Result.UBound() - 1].Unload();
	CompanyTable.Indexes.Add("Ref, CostGroupNumber");
	BatchTableForProcessing = Result[Result.UBound()].Unload();
	SetPrivilegedMode(False);
	
	// If the column value is Undefined, then the description of the value types of this column will be empty.
	// In this case, the platform will not be able to select values from an untyped column in queries.
	// To work around this situation, we will create a column in the table with the "correct" type of values and replace the original column with it.
	BatchTableForProcessing.Columns.Add("DocumentTyped",
		Metadata.Catalogs.ProductionLots.Attributes.Document.Type);
	
	For Each CurrRow In BatchTableForProcessing Do
		If CurrRow.InternalSubcontracting Then
			
			PartyCompanies = CompanyTable.CopyColumns("Organization");
			
			FilterStructure1 = New Structure("Ref, CostGroupNumber", CurrRow.Document, CurrRow.Code);
			For Each FoundRow In CompanyTable.FindRows(FilterStructure1) Do
				FillPropertyValues(PartyCompanies.Add(), FoundRow);
			EndDo;
			
			CurrRow.Companies = PartyCompanies;
			
		EndIf;
		CurrRow.ProductionLot = GetProductionBatch(CurrRow, CheckBeforeCreation, UpdateExistingItems);
		CurrRow.DocumentTyped = CurrRow.Document;
		
	EndDo;
	
	BatchTableForProcessing.Columns.Delete("Document");
	BatchTableForProcessing.Columns.DocumentTyped.Name = "Document";
	
EndProcedure

// Creates new batches for a given list of these Production Stages.
//
// Parameters:
//	Lots - ValueTable - Batch data of production stages.
//
Procedure GenerateProductionBatchesForListOfStages(Lots) Export
	
	PartyGroups = New Map; // The key is a Document, the value is an array of rows in the Batch table
	For Each String In Lots Do
		If PartyGroups[String.Document] = Undefined Then
			PartyGroups.Insert(String.Document, New Array);
		EndIf;
		PartyGroups[String.Document].Add(String);
	EndDo;
	
	TabularSections = New Array;
	For Each TabularSection In Metadata.Catalogs.ProductionLots.TabularSections Do
		If TabularSection.Name = "AdditionalAttributes" Then
			Continue;
		ElsIf Lots.Columns.Find(TabularSection.Name) <> Undefined Then
			TabularSections.Add(TabularSection.Name);
		EndIf;
	EndDo;
	
	Query = New Query(
		"SELECT
		|	ISNULL(MAX(Table.Code), 0) + 1 AS Code
		|FROM
		|	Catalog.ProductionLots AS Table
		|WHERE
		|	Table.Document = &Document");
	
	For Each KeyAndValue In PartyGroups Do
		
		DocumentBatches = KeyAndValue.Value;
		BatchData = DocumentBatches[DocumentBatches.UBound()];
		
		BeginTransaction();
		Try
			
			Block = New DataLock;
			LockItem = Block.Add("Catalog.ProductionLots");
			LockItem.SetValue("Document", BatchData.Document);
			LockItem.Mode = DataLockMode.Exclusive;
			Block.Lock();
			
			Query.SetParameter("Document", BatchData.Document);
			Selection = Query.Execute().Select();
			Selection.Next();
			Code = Selection.Code;
			
			BatchData.Code = Code + DocumentBatches.UBound();
		
			SetPrivilegedMode(True);
			CatalogObject = Catalogs.ProductionLots.CreateItem();
			FillPropertyValues(CatalogObject, BatchData);
			For Each TabularSection In TabularSections Do
				If ValueIsFilled(BatchData[TabularSection]) Then
					CatalogObject[TabularSection].Load(BatchData[TabularSection]);
				EndIf;
			EndDo;
			CatalogObject.Write();
			SetPrivilegedMode(False);
				
			BatchData.ProductionLot = CatalogObject.Ref;
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			DefaultLanguageCode = Common.DefaultLanguageCode();
			MessageText = NStr("vi = 'Không thể tạo lô hàng sản xuất với các tham số: %ProductionLot% do nguyên nhân: %Cause%';
								|ru = 'Не удалось создать партию производства с параметрами: %ProductionLot% по причине: %Cause%';
								|en = 'Cannot create a production lot with parameters: %ProductionLot%. Reason:%Cause%'; fa = 'Cannot create a production lot with parameters: %ProductionLot%. Reason:%Cause%';
								|it = 'Impossibile creare un lotto di produzione con i parametri: %ProductionLot% a causa di: %Cause%';
								|pl = 'Nie udało się utworzyć partię produkcji z parametrami: %ProductionLot% z powodu: %Cause%';
								|tr = '%Cause% nedeniyle %ProductionLot% parametreleri ile üretim lotu oluşturulamadı'");
			MessageText = StrReplace(MessageText, "%ProductionLot%",  NameOfProductionBatch(
				BatchData, CostGroupsServer.CostGroupPresentation(BatchData)));
			MessageText = StrReplace(MessageText, "%Cause%", DetailErrorDescription(ErrorInfo()));
			
			WriteLogEvent(
				NStr("vi = 'Danh mục';
					|ru = 'Справочник';
					|en = 'Catalog'; fa = 'فهرست';
					|it = 'Directory';
					|pl = 'Catalog';
					|tr = 'Katalog'", DefaultLanguageCode)
					+"." + NStr("vi = 'Lô hàng sản xuất';
								|ru = 'Партии производства';
								|en = 'Production lots'; fa = 'بچ‌های تولید';
								|it = 'Lotti di produzione';
								|pl = 'Partie produkcji';
								|tr = 'Üretim lotları'", DefaultLanguageCode)
					+ "." + NStr("vi = 'Nhận lô hàng sản xuất đối với danh sách công đoạn';
								|ru = 'Получить партию производства для списка этапов';
								|en = 'Receive production lot for stage list'; fa = 'Receive production lot for stage list';
								|it = 'Ricevere fornitura di produzione per l''elenco delle fasi';
								|pl = 'Otrzymaj partię produkcji dla listy etapów';
								|tr = 'Aşama listesi için üretim lotunu al'", DefaultLanguageCode),
				EventLogLevel.Error,
				Metadata.Catalogs.ProductionLots,,
				MessageText);
			
			CommonClientServer.MessageToUser(ErrorDescription());
			
			Continue;
			
		EndTry;
		
		For IndexOf = 0 To DocumentBatches.UBound()-1 Do
			
			BatchData = DocumentBatches[IndexOf];
			
			Try
				BatchData.Code = Code + IndexOf;
			
				SetPrivilegedMode(True);
				CatalogObject = Catalogs.ProductionLots.CreateItem();
				FillPropertyValues(CatalogObject, BatchData);
				For Each TabularSection In TabularSections Do
					If ValueIsFilled(BatchData[TabularSection]) Then
						CatalogObject[TabularSection].Load(BatchData[TabularSection]);
					EndIf;
				EndDo;
				CatalogObject.Write();
				SetPrivilegedMode(False);
					
				BatchData.ProductionLot = CatalogObject.Ref;
			Except
				
				DefaultLanguageCode = Common.DefaultLanguageCode();
				MessageText = NStr("vi = 'Không thể tạo lô hàng sản xuất với các tham số: %ProductionLot% do nguyên nhân: %Cause%';
									|ru = 'Не удалось создать партию производства с параметрами: %ProductionLot% по причине: %Cause%';
									|en = 'Cannot create a production lot with parameters: %ProductionLot%. Reason:%Cause%'; fa = 'Cannot create a production lot with parameters: %ProductionLot%. Reason:%Cause%';
									|it = 'Impossibile creare un lotto di produzione con i parametri: %ProductionLot% a causa di: %Cause%';
									|pl = 'Nie udało się utworzyć partię produkcji z parametrami: %ProductionLot% z powodu: %Cause%';
									|tr = '%Cause% nedeniyle %ProductionLot% parametreleri ile üretim lotu oluşturulamadı'");
				MessageText = StrReplace(MessageText, "%ProductionLot%",  NameOfProductionBatch(
					BatchData, CostGroupsServer.CostGroupPresentation(BatchData)));
				MessageText = StrReplace(MessageText, "%Cause%", DetailErrorDescription(ErrorInfo()));
				
				WriteLogEvent(
					NStr("vi = 'Danh mục';
						|ru = 'Справочник';
						|en = 'Catalog'; fa = 'فهرست';
						|it = 'Directory';
						|pl = 'Catalog';
						|tr = 'Katalog'", DefaultLanguageCode)
						+"." + NStr("vi = 'Lô hàng sản xuất';
									|ru = 'Партии производства';
									|en = 'Production lots'; fa = 'بچ‌های تولید';
									|it = 'Lotti di produzione';
									|pl = 'Partie produkcji';
									|tr = 'Üretim lotları'", DefaultLanguageCode)
						+ "." + NStr("vi = 'Nhận lô hàng sản xuất đối với danh sách công đoạn';
									|ru = 'Получить партию производства для списка этапов';
									|en = 'Receive production lot for stage list'; fa = 'Receive production lot for stage list';
									|it = 'Ricevere fornitura di produzione per l''elenco delle fasi';
									|pl = 'Otrzymaj partię produkcji dla listy etapów';
									|tr = 'Aşama listesi için üretim lotunu al'", DefaultLanguageCode),
					EventLogLevel.Error,
					Metadata.Catalogs.ProductionLots,,
					MessageText);
				
				CommonClientServer.MessageToUser(ErrorDescription());
				
			EndTry;
			
		EndDo;
		
	EndDo;
	
EndProcedure

// Returns the production batch number.
// 
// Parameters:
// 	ProductionLot - CatalogRef.ProductionLots	 - production batch.
// Returns:
// 	Number - production batch number.
Function ProductionBatchNumber(ProductionLot) Export
	
	LotNumber = -1;
	
	Query = New Query(
	"SELECT
	|	Table.Code AS LotNumber
	|FROM
	|	Catalog.ProductionLots AS Table
	|WHERE
	|	Table.Ref = &Ref
	|");
	Query.SetParameter("Ref", ProductionLot);

	QueryResult = Query.Execute();
	
	If Not QueryResult.IsEmpty() Then
		
		Selection = QueryResult.Select();
		Selection.Next();
		
		LotNumber = Selection.LotNumber;
		
	EndIf;
	
	Return LotNumber;
	
EndFunction

// Returns the name of the production batch.
//
// Parameters:
//  PartyStructure				- CatalogObject.ProductionLots, Structure - production batch.
//  CostGroupPresentation	- String - representation of the cost group of a production batch.
// 
// Returns:
//  String - the name of the production batch.
//
Function NameOfProductionBatch(PartyStructure, CostGroupPresentation = "") Export
	
	If Not ValueIsFilled(CostGroupPresentation) Then
		CostGroupPresentation = CostGroupsServer.CostGroupPresentation(PartyStructure);
	EndIf;
	
	AttributesList = "Number, Date";
	DocumentAttributes = Common.ObjectAttributesValues(PartyStructure.Document, AttributesList);
	
	ObjectManager = Common.ObjectManagerByRef(PartyStructure.Document);
	
	PresentationOfDocument = ObjectManager.PresentationOfObjectInMainLanguage();
	DocumentNumber = ObjectsPrefixesClientServer.DeleteLeadingZerosFromObjectNumber(DocumentAttributes.Number);
	
	PartyPresentation = NStr("vi = '%PresentationOfDocument% (%Number%.%NumberOfGroup%, %Date%, %Organization%);';
							|ru = '%PresentationOfDocument% (%Number%.%NumberOfGroup%, %Date%, %Organization%);';
							|en = '%PresentationOfDocument% (%Number%.%NumberOfGroup%, %Date%, %Organization%);'; fa = '%PresentationOfDocument% (%Number%.%NumberOfGroup%, %Date%, %Organization%);';
							|it = '%PresentationOfDocument% (%Number%.%NumberOfGroup%, %Date%, %Organization%);';
							|pl = '%PresentationOfDocument% (%Number%.%NumberOfGroup%, %Date%, %Organization%);';
							|tr = '%PresentationOfDocument% (%Number%.%NumberOfGroup%, %Date%, %Organization%);'");
	If ValueIsFilled(PartyStructure.GroupCosts) Then
		PartyPresentation = PartyPresentation + " "
			+ NStr("vi = 'Nhóm chi phí: %ExpenseGroup%';
					|ru = 'Группа затрат: %ExpenseGroup%';
					|en = 'Cost group: %ExpenseGroup%'; fa = 'Cost group: %ExpenseGroup%';
					|it = 'Gruppo di costi: %ExpenseGroup%';
					|pl = 'Grupa kosztów: %ExpenseGroup%';
					|tr = 'Gider grubu: %ExpenseGroup%'", Common.DefaultLanguageCode());
	EndIf;
	
	PartyPresentation = StrReplace(PartyPresentation, "%PresentationOfDocument%",	PresentationOfDocument);
	PartyPresentation = StrReplace(PartyPresentation, "%Number%",					DocumentNumber);
	PartyPresentation = StrReplace(PartyPresentation, "%NumberOfGroup%",				String(PartyStructure.Code));
	PartyPresentation = StrReplace(PartyPresentation, "%Date%",					Format(DocumentAttributes.Date, "DLF=D"));
	PartyPresentation = StrReplace(PartyPresentation, "%Organization%",				PartyStructure.Organization);
	PartyPresentation = StrReplace(PartyPresentation, "%ExpenseGroup%",			CostGroupPresentation);
	
	Return PartyPresentation;
	
EndFunction


// The Query Text of the list of production batches for which work has not yet been completed.
// 
// Parameters:
//  NameOfTTBatchOfProduction - String - the name of the TT in which the list of production Lot references for analysis is placed.
// 
// Returns:
//  String - The Query Text of the list of production batches for which work has not yet been completed.
//
Function QueryTextOfProductionBatchIsInProgress(NameOfTTBatchOfProduction) Export
	
	QueryText =
	"
	// Production stages (not completed, in-house) - the planned production date may change at any time
	|SELECT
	|		ProductionLots.ProductionLot AS ProductionLot
	|INTO PartiesInWork
	|FROM
	|	(SELECT
	|		ProductionLots.ProductionLot AS ProductionLot
	|	FROM
	|		&ProductionLots AS ProductionLots
	|		
	|		INNER JOIN Document.ProductionStage2_2 AS DocumentAttributes
	|		ON DocumentAttributes.ProductionLot = ProductionLots.ProductionLot
	|		AND DocumentAttributes.Posted
	|		AND NOT DocumentAttributes.Status = VALUE(Enum.StatusesOfProductionStages2_2.Completed)
	|		AND NOT DocumentAttributes.ProductionByThirdParty
	|
	|		INNER JOIN Document.ProductionStage2_2.ManufacturedProducts AS Products_1
	|		ON Products_1.Ref = DocumentAttributes.Ref
	|		AND NOT Products_1.Manufactured
	|		AND NOT Products_1.Canceled
	|	
	|	UNION ALL
	|	
	// Production order without specifications - completion date is uncertain
	|	SELECT
	|		ProductionLots.ProductionLot AS ProductionLot
	|	FROM
	|		&ProductionLots AS ProductionLots
	|		
	|		INNER JOIN Document.ProductionOrder2_2 AS DocumentAttributes
	|		ON DocumentAttributes.Ref = ProductionLots.ProductionLot.Document
	|
	|	WHERE
	|		DocumentAttributes.Posted
	|		AND DocumentAttributes.Status = VALUE(Enum.ProductionOrderStatuses2_2.ToProduce)
	|		AND DocumentAttributes.ProductionProcessType = VALUE(Enum.ProductionProcessTypes.WithoutBillsOfMaterials)
	|	) AS ProductionLots
	|
	|GROUP BY
	|	ProductionLots.ProductionLot
	|
	|INDEX BY
	|	ProductionLot
	|";
	
	QueryText = StrReplace(QueryText, "&ProductionLots", NameOfTTBatchOfProduction);
	
	Return QueryText;
	
EndFunction
// The text of the "In progress" Status.
// 
// Returns:
//  String
Function TextOfStatusInProgress() Export
	
	Return NStr("vi = 'Đang làm việc';
				|ru = 'В работе';
				|en = 'In progress'; fa = 'در حال انجام';
				|it = 'In esecuzione';
				|pl = 'Wykonuje się';
				|tr = 'İşleniyor'");
	
EndFunction

// The Status text is "Completed".
// 
// Returns:
//  String
Function StatusTextCompleted() Export
	
	Return NStr("vi = 'Đã hoàn thành';
				|ru = 'Завершена';
				|en = 'Completed'; fa = 'تکمیل‌شده';
				|it = 'Завершена';
				|pl = 'Completed';
				|tr = 'Tamamlandı'");
	
EndFunction

#Region StandardCommandSubsystems

// Populates the list of creation commands based on.
// 
// Parameters:
// 	GenerationCommands - ValueTable - list of commands
// 	Parameters - Structure - Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
EndProcedure

// Adds a command to create an object based on.
// 
// Parameters:
// 	GenerationCommands - ValueTable - list of commands
// Returns:
// 	Undefined, ValueTableRow - added command.
//
Function AddGenerateCommand(GenerationCommands) Export
	
EndFunction

// Fills in the list of report commands.
// 
// Parameters:
// 	ReportsCommands - ValueTable - list of commands
// 	Parameters - Structure - Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
EndProcedure

Procedure OnDefineCommandsAttachedToObject(Commands) Export
	
	ReportCommand_ = Commands.Find("RelatedDocuments", "Kind");
	If Not ReportCommand_ = Undefined Then
		AttachableCommands.AddCommandVisibilityCondition(
			ReportCommand_,
			"ProcessType",
			Enums.ProductionProcessTypes.EmptyRef(),
			DataCompositionComparisonType.NotEqual);
		
	EndIf;
	
EndProcedure

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
EndProcedure

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Organization)";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

// StandardSubsystems.Print

// Overrides the printing settings for the object.
//
// Parameters:
//  Settings - See PrintManagement.ObjectPrintingSettings.
//
Procedure OnDefinePrintSettings(Settings) Export
	
	Settings.OnAddPrintCommands = True;
	
EndProcedure

// End StandardSubsystems.Print

#EndRegion

#Region Private

// Returns a list of fields that identify the production batch
//
// Returns:
//	String - a list of fields identifying the production batch.
//
Function ProductionBatchIdentificationFields() Export
	
	Return "Document, Code";
	
EndFunction

// Creates a structure for describing the production batch fields
// 
// Returns:
//  Structure - structure of production batch fields
//
Function ProductionBatchDescription() Export
	
	StructureOfPartyDetails = New Structure;
	StructureOfPartyDetails.Insert("DeletionMark", False);
	
	For Each MetaAttribute In Metadata.Catalogs.ProductionLots.Attributes Do
		
		StructureOfPartyDetails.Insert(
			MetaAttribute.Name,
			MetaAttribute.Type.AdjustValue(Undefined));
		
	EndDo;
	For Each MetaAttribute In Metadata.Catalogs.ProductionLots.TabularSections Do
		
		If MetaAttribute.Name = "AdditionalAttributes" Then
			Continue;
		EndIf;
		
		StructureOfPartyDetails.Insert(MetaAttribute.Name, New ValueTable);
		
	EndDo;
	Return StructureOfPartyDetails;
	
EndFunction

Function PartyPropsStructuresAreEqual(Structure1, Structure2)
	
	For Each CurProps In Structure1 Do
		
		AttributeName = CurProps.Key;
		
		If AttributeName = "Code"
			Or AttributeName = "Ref"
			Or AttributeName = "UUID"
			Or AttributeName = "Description"
			Or AttributeName = "ExpenseGroup" Then
			Continue;
		EndIf;
		If AttributeName = "Companies" Then
			
			Table1 = Structure1[AttributeName]; // ValueTable
			Table2 = Structure2[AttributeName]; // ValueTable
			
			If Not Table1.Count() = Table2.Count() Then
				Return False;
			EndIf;
			
			For IndexOf = 0 To Table1.Count() - 1 Do
				If Table1[IndexOf].Organization <> Table2[IndexOf].Organization Then
					Return False;
				EndIf;
			EndDo;
			
		Else
			If Structure1[AttributeName] <> Structure2[AttributeName] Then
				Return False;
			EndIf;
		EndIf;
	EndDo;
	
	Return True;
	
EndFunction

Function QueryTextLineNumbersOfMainProducts()
	
	Return
	"SELECT
	|	MIN(GoodsTable.LineNumber)	AS LineNumber,
	|	GoodsTable.Ref				AS Ref,
	|	GoodsTable.CostGroupNumber		AS CostGroupNumber
	|INTO LineNumbersOfMainProducts
	|FROM
	|	TableProduction AS GoodsTable
	|
	|WHERE
	|	NOT GoodsTable.GroupCosts = VALUE(Enum.CostGroupingsInTollingOrder.ByProductionStages)
	|
	|GROUP BY
	|	GoodsTable.Ref,
	|	GoodsTable.CostGroupNumber
	|
	|INDEX BY
	|	Ref,
	|	CostGroupNumber
	|";
	
EndFunction

Function RequestTextValidBatchFields()
	
	Return
	"SELECT
	|	CASE
	|		WHEN NOT VALUETYPE(T.Document) IN (
	|					TYPE(Document.SubcontractorReport2_5),
	|					TYPE(Document.ProductionOrder2_2),
	|					TYPE(Document.BackflushProduction))
	|			THEN UNDEFINED
	|		ELSE T.Document
	|	END						AS Document,
	|	CASE
	|		WHEN NOT VALUETYPE(T.GroupCosts) IN (TYPE(Enum.CostGroupingsInTollingOrder),
	|													TYPE(Enum.GroupingsOfCostsInBackflushProduction))
	|			THEN UNDEFINED
	|		ELSE T.GroupCosts
	|	END						AS GroupCosts,
	|	CASE
	|		WHEN NOT VALUETYPE(T.CostGroupNumber) = TYPE(NUMBER)
	|			THEN 0
	|		ELSE T.CostGroupNumber
	|	END						AS CostGroupNumber,
	|	CASE
	|		WHEN NOT VALUETYPE(T.Organization) = TYPE(Catalog.Companies)
	|			THEN VALUE(Catalog.Companies.EmptyRef)
	|		ELSE T.Organization
	|	END						AS Organization,
	|	CASE
	|		WHEN NOT VALUETYPE(T.InternalSubcontracting) = TYPE(BOOLEAN)
	|			THEN FALSE
	|		ELSE T.InternalSubcontracting
	|	END						AS InternalSubcontracting,
	|	CASE
	|		WHEN NOT VALUETYPE(T.ProcessType) = TYPE(Enum.ProductionProcessTypes)
	|			THEN VALUE(Enum.ProductionProcessTypes.EmptyRef)
	|		ELSE T.ProcessType
	|	END						AS ProcessType,
	|	CASE
	|		WHEN NOT VALUETYPE(T.LineOfBusiness) = TYPE(Catalog.LinesOfBusiness)
	|			THEN VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|		ELSE T.LineOfBusiness
	|	END						AS LineOfBusiness,
	|	CASE
	|		WHEN NOT VALUETYPE(T.VATActivityType) = TYPE(Enum.VATTaxationTypes)
	|			THEN VALUE(Enum.VATTaxationTypes.EmptyRef)
	|		ELSE T.VATActivityType
	|	END						AS VATActivityType,
	|	CASE
	|		WHEN NOT VALUETYPE(T.MainProductProducts) = TYPE(Catalog.Products)
	|			THEN VALUE(Catalog.Products.EmptyRef)
	|		ELSE T.MainProductProducts
	|	END						AS MainProductProducts,
	|	CASE
	|		WHEN NOT VALUETYPE(T.MainProductCharacteristic) = TYPE(Catalog.ItemsCharacteristics)
	|			THEN VALUE(Catalog.ItemsCharacteristics.EmptyRef)
	|		ELSE T.MainProductCharacteristic
	|	END						AS MainProductCharacteristic,
	|	CASE
	|		WHEN NOT VALUETYPE(T.Products) = TYPE(Catalog.Products)
	|			THEN VALUE(Catalog.Products.EmptyRef)
	|		ELSE T.Products
	|	END						AS Products,
	|	CASE
	|		WHEN NOT VALUETYPE(T.Characteristic) = TYPE(Catalog.ItemsCharacteristics)
	|			THEN VALUE(Catalog.ItemsCharacteristics.EmptyRef)
	|		ELSE T.Characteristic
	|	END						AS Characteristic,
	|	CASE
	|		WHEN NOT &AnalyticalAccountingByProductsGroups
	|			THEN VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|		WHEN NOT VALUETYPE(T.ProductsGroup) = TYPE(Catalog.AnalyticalInventoryGroups)
	|			THEN VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|		ELSE T.ProductsGroup
	|	END						AS ProductsGroup,
	|	CASE
	|		WHEN NOT VALUETYPE(T.BillOfMaterials) = TYPE(Catalog.BillsOfMaterials)
	|			THEN VALUE(Catalog.BillsOfMaterials.EmptyRef)
	|		ELSE T.BillOfMaterials
	|	END						AS BillOfMaterials,
	|	CASE
	|		WHEN NOT VALUETYPE(T.Purpose) = TYPE(Catalog.Assignments)
	|			THEN VALUE(Catalog.Assignments.EmptyRef)
	|		ELSE T.Purpose
	|	END						AS Purpose,
	|	CASE
	|		WHEN NOT VALUETYPE(T.Series) = TYPE(Catalog.ItemsBatches)
	|			THEN VALUE(Catalog.ItemsBatches.EmptyRef)
	|		ELSE T.Series
	|	END						AS Series
	|INTO TTCorrectFieldsOfProductionBatches
	|FROM
	|	TTProductionBatchFields AS T
	|
	|GROUP BY
	|	CASE
	|		WHEN NOT VALUETYPE(T.Document) IN (
	|					TYPE(Document.SubcontractorReport2_5),
	|					TYPE(Document.ProductionOrder2_2),
	|					TYPE(Document.BackflushProduction))
	|			THEN UNDEFINED
	|		ELSE T.Document
	|	END,
	|	CASE
	|		WHEN NOT VALUETYPE(T.GroupCosts) IN (TYPE(Enum.CostGroupingsInTollingOrder),
	|													TYPE(Enum.GroupingsOfCostsInBackflushProduction))
	|			THEN UNDEFINED
	|		ELSE T.GroupCosts
	|	END,
	|	CASE
	|		WHEN NOT VALUETYPE(T.CostGroupNumber) = TYPE(NUMBER)
	|			THEN 0
	|		ELSE T.CostGroupNumber
	|	END,
	|	CASE
	|		WHEN NOT VALUETYPE(T.Organization) = TYPE(Catalog.Companies)
	|			THEN VALUE(Catalog.Companies.EmptyRef)
	|		ELSE T.Organization
	|	END,
	|	CASE
	|		WHEN NOT VALUETYPE(T.InternalSubcontracting) = TYPE(BOOLEAN)
	|			THEN FALSE
	|		ELSE T.InternalSubcontracting
	|	END,
	|	CASE
	|		WHEN NOT VALUETYPE(T.ProcessType) = TYPE(Enum.ProductionProcessTypes)
	|			THEN VALUE(Enum.ProductionProcessTypes.EmptyRef)
	|		ELSE T.ProcessType
	|	END,
	|	CASE
	|		WHEN NOT VALUETYPE(T.LineOfBusiness) = TYPE(Catalog.LinesOfBusiness)
	|			THEN VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|		ELSE T.LineOfBusiness
	|	END,
	|	CASE
	|		WHEN NOT VALUETYPE(T.VATActivityType) = TYPE(Enum.VATTaxationTypes)
	|			THEN VALUE(Enum.VATTaxationTypes.EmptyRef)
	|		ELSE T.VATActivityType
	|	END,
	|	CASE
	|		WHEN NOT VALUETYPE(T.MainProductProducts) = TYPE(Catalog.Products)
	|			THEN VALUE(Catalog.Products.EmptyRef)
	|		ELSE T.MainProductProducts
	|	END,
	|	CASE
	|		WHEN NOT VALUETYPE(T.MainProductCharacteristic) = TYPE(Catalog.ItemsCharacteristics)
	|			THEN VALUE(Catalog.ItemsCharacteristics.EmptyRef)
	|		ELSE T.MainProductCharacteristic
	|	END,
	|	CASE
	|		WHEN NOT VALUETYPE(T.Products) = TYPE(Catalog.Products)
	|			THEN VALUE(Catalog.Products.EmptyRef)
	|		ELSE T.Products
	|	END,
	|	CASE
	|		WHEN NOT VALUETYPE(T.Characteristic) = TYPE(Catalog.ItemsCharacteristics)
	|			THEN VALUE(Catalog.ItemsCharacteristics.EmptyRef)
	|		ELSE T.Characteristic
	|	END,
	|	CASE
	|		WHEN NOT &AnalyticalAccountingByProductsGroups
	|			THEN VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|		WHEN NOT VALUETYPE(T.ProductsGroup) = TYPE(Catalog.AnalyticalInventoryGroups)
	|			THEN VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|		ELSE T.ProductsGroup
	|	END,
	|	CASE
	|		WHEN NOT VALUETYPE(T.BillOfMaterials) = TYPE(Catalog.BillsOfMaterials)
	|			THEN VALUE(Catalog.BillsOfMaterials.EmptyRef)
	|		ELSE T.BillOfMaterials
	|	END,
	|	CASE
	|		WHEN NOT VALUETYPE(T.Purpose) = TYPE(Catalog.Assignments)
	|			THEN VALUE(Catalog.Assignments.EmptyRef)
	|		ELSE T.Purpose
	|	END,
	|	CASE
	|		WHEN NOT VALUETYPE(T.Series) = TYPE(Catalog.ItemsBatches)
	|			THEN VALUE(Catalog.ItemsBatches.EmptyRef)
	|		ELSE T.Series
	|	END
	|
	|INDEX BY
	|	Document,
	|	CostGroupNumber
	|";
EndFunction

Function QueryTextProductionBatchTablePreliminary()
	
	Return
	"SELECT
	|	T.Document						AS Document,
	|	T.GroupCosts				AS GroupCosts,
	|	T.CostGroupNumber				AS CostGroupNumber,
	|	T.Organization					AS Organization,
	|	T.InternalSubcontracting			AS InternalSubcontracting,
	|	T.ProcessType					AS ProcessType,
	|	T.LineOfBusiness		AS LineOfBusiness,
	|	T.VATActivityType			AS VATActivityType,
	|	T.MainProductProducts	AS MainProductProducts,
	|	T.MainProductCharacteristic	AS MainProductCharacteristic,
	|	T.Products					AS Products,
	|	T.Characteristic				AS Characteristic,
	|	T.ProductsGroup				AS ProductsGroup,
	|	T.BillOfMaterials					AS BillOfMaterials,
	|	T.Series							AS Series,
	|	T.Purpose					AS Purpose,
	|	ISNULL(CatProductionLots.Ref,
	|		VALUE(Catalog.ProductionLots.EmptyRef)) AS ProductionLot
	|INTO TTProductionBatchPreliminaryTable
	|FROM
	|	TTCorrectFieldsOfProductionBatches AS T
	|
	|	LEFT JOIN Catalog.ProductionLots AS CatProductionLots
	|		ON CatProductionLots.Document = T.Document
	|		AND CatProductionLots.Code = T.CostGroupNumber
	|		AND NOT CatProductionLots.DeletionMark
	|";
	
EndFunction

Function RequestTextTableOfProductionBatchesForProcessing(UpdateExistingItems = False)
	
	QueryText = 
	"SELECT
	|	T.Document						AS Document,
	|	T.GroupCosts				AS GroupCosts,
	|	T.CostGroupNumber				AS Code,
	|	T.Organization					AS Organization,
	|	T.InternalSubcontracting			AS InternalSubcontracting,
	|	T.ProcessType					AS ProcessType,
	|	T.LineOfBusiness		AS LineOfBusiness,
	|	T.VATActivityType			AS VATActivityType,
	|	T.MainProductProducts	AS MainProductProducts,
	|	T.MainProductCharacteristic	AS MainProductCharacteristic,
	|	T.Products					AS Products,
	|	T.Characteristic				AS Characteristic,
	|	T.ProductsGroup				AS ProductsGroup,
	|	T.BillOfMaterials					AS BillOfMaterials,
	|	T.Series							AS Series,
	|	T.Purpose					AS Purpose,
	|	UNDEFINED					AS Companies,
	|	T.ProductionLot			AS ProductionLot
	|FROM
	|	TTProductionBatchPreliminaryTable AS T
	|WHERE
	|	&ConditionUpdateExistingOnes
	|";
	
	If UpdateExistingItems Then
		QueryText = StrReplace(QueryText, "&ConditionUpdateExistingOnes", "TRUE");
	Else
		QueryText = StrReplace(QueryText, "&ConditionUpdateExistingOnes", "T.ProductionLot = VALUE(Catalog.ProductionLots.EmptyRef)");
	EndIf;
	
	Return QueryText;
	
EndFunction

Function QueryTextTableOfBatchCompanies()
	
	QueryText = 
	"SELECT
	|	GoodsTable.Ref            AS Ref,
	|	GoodsTable.CostGroupNumber AS CostGroupNumber,
	|	GoodsTable.Organization       AS Organization
	|FROM
	|	(SELECT
	|		GoodsTable.Ref             AS Ref,
	|		GoodsTable.CostGroupNumber  AS CostGroupNumber,
	|		GoodsTable.MaterialProviderCompany AS Organization
	|	FROM
	|		TableProduction AS GoodsTable
	|	WHERE
	|		GoodsTable.InternalSubcontracting
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		GoodsTable.Ref            AS Ref,
	|		GoodsTable.CostGroupNumber AS CostGroupNumber,
	|		GoodsTable.Organization       AS Organization
	|	FROM
	|		TableProduction AS GoodsTable
	|	WHERE
	|		GoodsTable.InternalSubcontracting
	|	) AS GoodsTable
	|
	|GROUP BY
	|	GoodsTable.Ref,
	|	GoodsTable.CostGroupNumber,
	|	GoodsTable.Organization
	|";
	
	Return QueryText;
	
EndFunction
#EndRegion

#EndIf
