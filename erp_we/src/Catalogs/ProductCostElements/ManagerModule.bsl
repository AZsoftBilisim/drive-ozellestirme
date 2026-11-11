#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns the names of blocked details for the BSP details blocking mechanism.
//
// Returns:
//	Array - names of the blocked details.
//
Function GetObjectAttributesToLock() Export
	Result = New Array;
	Result.Add("ExpenseType");
	Result.Add("IDForFormulas");
	Return Result;
EndFunction

// Defines the configuration for the initial fill of elements
//
// Parameters:
//  Settings - Structure - filling settings:
//   * OnInitialItemFilling - Boolean - if True,
//      the individual filling procedure will be called for each element at the beginning of the element Filling.
Procedure OnSetUpInitialItemsFilling(Settings) Export
	
	Settings.OnInitialItemFilling = True;
	
EndProcedure

// Called when the directory is initially filled in.
//
// Parameters:
//  LanguagesCodes - Array - list of configuration languages. Relevant for multilingual configurations.
//  Items   - ValueTable - fill-in data. The composition of columns corresponds to the set
//                                 of reference book details.
//  TabularSections - Structure - Key - Name of the table part of the object.
//                               Value-Uploads an empty table part to the table of values.
//
Procedure OnInitialItemsFilling(LanguagesCodes, Items, TabularSections) Export
	
	#Region SemiFinishedProductsProducedInProcess
	Item = Items.Add(); // CatalogObject.ProductCostElements - 
	Item.PredefinedDataName = "SemiFinishedProductsProducedInProcess";
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Bán thành phẩm được sản xuất trong quy trình';
																					|ru = 'Полуфабрикаты производимые в процессе';
																					|en = 'Semi-finished products manufactured in process';
																					|it = 'Semiprodotti fabbricati nel processo';
																					|pl = 'Półprodukty produkowane w procesie';
																					|tr = 'Süreçte üretilen yarı mamul ürünler'", LanguagesCodes); // @NStr-2
	Item.ExpenseType = Enums.CostTypes.Material_;
	Item.AddlOrderingAttribute = 0;
	Item.IDForFormulas = "SemiFinishedProductsProducedInProcess";
	#EndRegion

	#Region TransportationAndProcurementExpenses
	Item = Items.Add(); // CatalogObject.ProductCostElements - 
	Item.PredefinedDataName = "TransportationAndProcurementExpenses";
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Chi phí vận chuyển và thu mua';
																					|ru = 'Транспортно-заготовительные затраты';
																					|en = 'Transportation and procurement costs';
																					|it = 'Transportation and procurement costs';
																					|pl = 'Transportation and procurement costs';
																					|tr = 'Nakliye-tedarik giderleri'", LanguagesCodes); // @NStr-2
	Item.ExpenseType = Enums.CostTypes.Other;
	Item.AddlOrderingAttribute = 0;
	Item.IDForFormulas = "TransportationAndProcurementExpenses";
	#EndRegion
	
	#Region CostCalculationError
	Item = Items.Add(); // CatalogObject.ProductCostElements - 
	Item.PredefinedDataName = "CostCalculationError";
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Lỗi tính giá vốn';
																					|ru = 'Погрешность расчета себестоимости';
																					|en = 'Cost calculation error';
																					|it = 'Errore di calcolo dei costi ';
																					|pl = 'Błąd rozliczenia kosztów własnych';
																					|tr = 'Hesaplama yönteminde hata'", LanguagesCodes); // @NStr-2
	Item.ExpenseType = Enums.CostTypes.Other;
	Item.AddlOrderingAttribute = 0;
	Item.IDForFormulas = "CostCalculationError";
	#EndRegion
	
	#Region ProductsBeingDisassembled
	Item = Items.Add(); // CatalogObject.ProductCostElements -
	Item.PredefinedDataName = "ProductsBeingDisassembled";
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Sản phẩm tháo rời';
																					|ru = 'Разбираемые изделия';
																					|en = 'Products for recycling';
																					|it = 'Prodotti in fase di smontaggio';
																					|pl = 'Rozbierane produkty';
																					|tr = 'Sökülen nihai ürünler'", LanguagesCodes); // @NStr-2
	Item.ExpenseType = Enums.CostTypes.Material_;
	Item.AddlOrderingAttribute = 0;
	Item.IDForFormulas = "ProductsBeingDisassembled";
	#EndRegion

	#Region ProductsUnderRepair
	Item = Items.Add(); // CatalogObject.ProductCostElements -
	Item.PredefinedDataName = "ProductsUnderRepair";
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Sản phẩm sửa chữa';
																					|ru = 'Ремонтируемые изделия';
																					|en = 'Products under R&M';
																					|it = 'Prodotti in manutenzione';
																					|pl = 'Naprawiane produkty';
																					|tr = 'Onarılan nihai ürünler'", LanguagesCodes); // @NStr-2
	Item.ExpenseType = Enums.CostTypes.Material_;
	Item.AddlOrderingAttribute = 0;
	Item.IDForFormulas = "ProductsUnderRepair";
	#EndRegion

EndProcedure


// Called when the element being created is initially filled in.
//
// Parameters:
//  Object                  - CatalogObject.ProductCostElements - the object to fill in.
//  Data                  - ValueTableRow - fill-in data.
//  AdditionalParameters - Structure - advanced setting.
//
Procedure OnInitialItemFilling(Object, Data, AdditionalParameters) Export
	
	
	
EndProcedure

// Gets a list of batches for a list of Attribute values
// Parameters:
//  Period - Date
//  AttributeName - String
//  Values - ValueList of CatalogRef
//  ByHierarchy - Boolean
// Returns:
//  ValueList of CatalogRef.ProductCostElements
// 
Function ListOfItemsByProps(Period, AttributeName, Val Values, ByHierarchy = False) Export
	Result = New ValueList;
	
	If Not TypeOf(Values) = Type("ValueList") Then
		Return Result;
	EndIf;
	
	QueryText = "SELECT
	|	ProductCostElements.Ref AS Ref
	|FROM
	|	Catalog.ProductCostElements AS ProductCostElements
	|WHERE
	|	ProductCostElements.Ref IN (&Values)";
	
	QueryText = StrReplace(QueryText, "ProductCostElements.Ref IN (&Values)",
												"ProductCostElements." + AttributeName + " IN (&Values)");
	If ByHierarchy Then
		QueryText = StrReplace(QueryText, " IN (&Values)", " IN HIERARCHY (&Values)");
	EndIf;
	
	Query = New Query(QueryText);
	Query.SetParameter("Period", Period);
	Query.SetParameter("Values", Values);

	FoundItems1 = Query.Execute().Unload().UnloadColumn("Ref");
	Result.LoadValues(FoundItems1);
	
	Return Result;
EndFunction

#EndRegion

#EndIf

#Region EventHandlers

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	// StandardSubsystems.Core
	NationalLanguageSupportServer.ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing, Metadata.Catalogs.ProductCostElements);
	// End StandardSubsystems.Core		
EndProcedure

#EndIf

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	// StandardSubsystems.Core
	NationalLanguageSupportClientServer.PresentationFieldsGetProcessing(Fields, StandardProcessing);
	// End StandardSubsystems.Core
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	// StandardSubsystems.Core
	NationalLanguageSupportClientServer.PresentationGetProcessing(Data, Presentation, StandardProcessing);
	// End StandardSubsystems.Core
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

Procedure SetDetailsForOrderingGroupsOfIncomeItems() Export
	Query = New Query;
	Query.Text = "SELECT
	|	ProductCostElements.Ref AS Ref
	|FROM
	|	Catalog.ProductCostElements AS ProductCostElements
	|WHERE
	|	ProductCostElements.IsFolder
	|
	|ORDER BY
	|	ProductCostElements.Description";
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do 
		Object = Selection.Ref.GetObject(); // CatalogObject.ProductCostElements
		LockDataForEdit(Object.Ref);
		ItemOrderSetup.FillOrderingAttributeValue(Object, False);
		InfobaseUpdate.WriteData(Object);
	EndDo;
EndProcedure

#Region InfobaseUpdate

// Fills in the ID and cost type of the predefined calculation item.
// 
// Returns:
// 	Boolean
Function SetUpArticleCalculationOfPredefinedItems() Export
	
	ObjectMetadata = Metadata.Catalogs.ProductCostElements;
	FullObjectName  = ObjectMetadata.FullName();
	
	ListOfArticlesMaterial = New Array;
	ListOfArticlesMaterial.Add("SemiFinishedProductsProducedInProcess");
	ListOfArticlesMaterial.Add("ProductsBeingDisassembled");
	ListOfArticlesMaterial.Add("ProductsUnderRepair");
	
	ListOfArticlesOther = New Array;
	ListOfArticlesOther.Add("TransportationAndProcurementExpenses");
	ListOfArticlesOther.Add("CostCalculationError");
	
	Query = New Query(
	"SELECT
	|	ProductCostElements.Ref AS Ref,
	|	CASE WHEN ProductCostElements.PredefinedDataName IN (&ListOfArticlesMaterial)
	|		THEN VALUE(Enum.CostTypes.Material_)
	|		ELSE VALUE(Enum.CostTypes.Other)
	|	END AS ExpenseType,
	|	ProductCostElements.DataVersion AS DataVersion
	|FROM
	|	Catalog.ProductCostElements AS ProductCostElements
	|WHERE
	|	ProductCostElements.IDForFormulas = """"
	|	AND ProductCostElements.ExpenseType = VALUE(Enum.CostTypes.EmptyRef)
	|	AND (ProductCostElements.PredefinedDataName IN (&ListOfArticlesMaterial)
	|		OR ProductCostElements.PredefinedDataName IN (&ListOfArticlesOther))
	|");
	Query.SetParameter("ListOfArticlesMaterial", ListOfArticlesMaterial);
	Query.SetParameter("ListOfArticlesOther", ListOfArticlesOther);
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		BeginTransaction();
		
		Try
			
			Block = New DataLock;
			Block.Add(FullObjectName).SetValue("Ref", Selection.Ref);
			Block.Lock();
			
			Object = Selection.Ref.GetObject(); // CatalogObject.ProductCostElements - 
			
			If Object <> Undefined And Object.DataVersion = Selection.DataVersion Then
				
				If Not ValueIsFilled(Object.IDForFormulas) Then
					Object.IDForFormulas = Object.PredefinedDataName;
				EndIf;
				
				If Not ValueIsFilled(Object.ExpenseType) Then
					Object.ExpenseType = Selection.ExpenseType;
				EndIf;
				
				InfobaseUpdate.WriteData(Object);
				
			EndIf;
			
			CommitTransaction();
			
		Except
			RollbackTransaction();
			MessageText = NStr("vi = 'Không thể xử lý mục: %Ref% vì lý do: %Cause%';
								|ru = 'Не удалось обработать элемент: %Ref% по причине: %Cause%';
								|en = 'Cannot process the item: %Ref%. Reason: %Cause%'; fa = 'Cannot process the item: %Ref%. Reason: %Cause%';
								|it = 'Non è stato possibile elaborare l''elemento: %Ref% a causa di: %Cause%';
								|pl = 'Przetwarzanie elementu: %Ref% nie powiodło się z powodu: %Cause%';
								|tr = 'Öğe işlenemedi: %Ref% çünkü: %Cause%'");
			MessageText = StrReplace(MessageText, "%Ref%", Selection.Ref);
			MessageText = StrReplace(MessageText, "%Cause%", DetailErrorDescription(ErrorInfo()));
			WriteLogEvent(InfobaseUpdate.EventLogEvent(),
				EventLogLevel.Warning,
				ObjectMetadata,
				Selection.Ref,
				MessageText);
			Continue;
		EndTry;
		
	EndDo;
	Return True;
	
EndFunction

// See InfobaseUpdateSSL.OnAddUpdateHandlers
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "Catalogs.ProductCostElements.ProcessDataForMigrationToNewVersion";
	Handler.Version = "2.5.27.22";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("58f9cde9-1177-47a5-b757-a84386c615c2");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "Catalogs.ProductCostElements.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Comment = NStr("vi = 'Điền các thuộc tính của các phần tử được xác định trước trong danh mục.';
							|ru = 'Заполняет свойства предопределенных элементов справочника.';
							|en = 'Fills in the properties of predefined catalog item.'; fa = 'Fills in the properties of predefined catalog item.';
							|it = 'Fills in the properties of predefined catalog item.';
							|pl = 'Fills in the properties of predefined catalog item.';
							|tr = 'Kataloğun önceden tanımlı öğelerinin özelliklerini doldurur.'");
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Catalogs.ProductCostElements.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Catalogs.ProductCostElements.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.Catalogs.ProductCostElements.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");

EndProcedure

Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullNamesOfObjects = EmptyRef().Metadata().FullName();
	SelectionParameters.SelectionMethod = InfobaseUpdate.RefsSelectionMethod();

	Query = New Query;
	Query.Text =
	"SELECT
	|	T.Ref
	|FROM
	|	Catalog.ProductCostElements AS T
	|WHERE
	|	T.Ref IN (
	|		VALUE(Catalog.ProductCostElements.TransportationAndProcurementExpenses),
	|		VALUE(Catalog.ProductCostElements.CostCalculationError))
	|	AND T.ExpenseType = VALUE(Enum.CostTypes.EmptyRef)
	|";
	
	InfobaseUpdate.MarkForProcessing(Parameters, Query.Execute().Unload().UnloadColumn("Ref"));
	
EndProcedure

Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	Parameters.ProcessingCompleted = False;
	FullObjectName = EmptyRef().Metadata().FullName();
	
	UpdatedData = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	
	If UpdatedData.Count() = 0 Then
		Parameters.ProcessingCompleted =
			InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
		Return;
	EndIf;
	
	For Each Item In UpdatedData Do
		
		ArticleLink = Item.Ref;
		
		BeginTransaction();
		
		Try
			
			Block = New DataLock;
			LockItem = Block.Add(FullObjectName);
			LockItem.SetValue("Ref", ArticleLink);
			LockItem.Mode = DataLockMode.Exclusive;
			Block.Lock();
			
			Object = ArticleLink.GetObject(); // CatalogObject.ProductCostElements - 
			
			If Object = Undefined Then
				InfobaseUpdate.MarkProcessingCompletion(ArticleLink);
				CommitTransaction();
				Continue;
			EndIf;
			
			If Not ValueIsFilled(Object.ExpenseType) Then
				Object.ExpenseType = Enums.CostTypes.Other;
				Object.IDForFormulas = Object.PredefinedDataName;
				InfobaseUpdate.WriteObject(Object);
			Else
				InfobaseUpdate.MarkProcessingCompletion(ArticleLink);
			EndIf;
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			InfobaseUpdateTM.ReportFailedProcessing(ErrorInfo(), ArticleLink);
			
		EndTry;
		
	EndDo;
	
	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
