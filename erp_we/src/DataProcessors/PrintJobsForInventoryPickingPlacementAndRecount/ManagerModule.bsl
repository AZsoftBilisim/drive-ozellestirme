#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region Print

// Adds the print command for the print form of the product selection (placement) Task to the collection of document print commands.
//
// Parameters:
//	PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//	JobType    - String - the type of job that is being printed for.
//											Possible values:
//												of "Task selection"		- printing a task for selecting Goods.
//												"Assignment"	- print the assignment for the placement of goods.
//												"Task recalculation"		- printing the task for recalculation of Goods.
//												"Assignment"		- print job for the collection of Goods.
//	Order      - Number - (optional) the order in which the command is placed in relation to other print commands.
//	VisibilityCondition - Structure - The condition for the visibility of the printed form
//	
// Returns:
//	ValueTableRow - an element of the Print command collection containing a description of the print command.
//
Function AddPrintCommand(PrintCommands, JobType, Order = Undefined, VisibilityCondition = Undefined) Export
	
	PrintCommand = PrintCommands.Add();
	PrintCommand.PrintManager = "DataProcessor.PrintJobsForInventoryPickingPlacementAndRecount";
	PrintCommand.Id = "GoodsPickingPlacementJob";
	PrintCommand.Presentation = PresentationOfPrintCommand(JobType);
	PrintCommand.CheckPostingBeforePrint = True;
	PrintCommand.AdditionalParameters.Insert("JobType", JobType);
	
	If JobType = "RecalculationTask" Then
		PrintCommand.FunctionalOptions = "UseBinLocationWarehousingForInformation";
	EndIf;
	
	If ValueIsFilled(Order) Then
		PrintCommand.Order = Order;
	EndIf;
	
	If ValueIsFilled(VisibilityCondition) Then
		PrintCommand.VisibilityConditions.Add(VisibilityCondition);
	EndIf;
	
	Return PrintCommand;
	
EndFunction

// Returns the rules for printing the printed form of the Task for selecting (placing) products.
//
// Returns:
//	Structure - a structure with the following keys:
//		* ReceiptOperation	- Boolean - True - indicates that the document reflects the arrival of goods to the warehouse.
//														The default value is False.
//		* SurplusesRecord		- Boolean - True - a sign that the document is selling surplus goods.
//														The default value is False.
//		* ThisIsAnInvoice			- Boolean - True - indicates that the document for which
//														the printed form is output is an invoice. The default value is True.
//		* AdjustmentOfGoods	- Boolean - True - indicates that the document is intended for correcting information
//														about goods in warehouses. The default value is False.
//		* VHFWarehouses				- Boolean - True - indicates that information about warehouses is specified in the table part of the document.
//														The default value is False.
//		* WarehouseFieldName			- String			- name of the document details that stores information about the warehouse.
//														The default value is "warehouse".
//		* FieldNameRoom		- String			- name of the document details that stores information about the warehouse.
//														Specified if the document contains the necessary information.
//		* NameTSGoods			- String			- name of the table part of the document that stores information about warehouses.
//														The default value is "Products". Redefined if information about warehouses is stored in a table part
//														that has a name other than the default value.
//		* ThereArePackingLists	- Boolean - True - indicates that the document contains information about packing lists.
//														Used in warehouse orders.
//														The default value is False.
//		* DocumentCorrectionsAreUsed	- Boolean - indicates that corrections can be made to the document.
//
Function RulesForPrintingTasksForSelectionPlacement() Export
	
	PrintRules = New Structure;
	PrintRules.Insert("ReceiptOperation",	False);
	PrintRules.Insert("SurplusesRecord",		False);
	PrintRules.Insert("ThisIsAnInvoice",			True);
	PrintRules.Insert("AdjustmentOfGoods",	False);
	PrintRules.Insert("VHFWarehouses",				False);
	PrintRules.Insert("WarehouseFieldName",			"Warehouse");
	PrintRules.Insert("FieldNameRoom",		"");
	PrintRules.Insert("NameTSGoods",			"Goods");
	PrintRules.Insert("ThereArePackingLists",	False);
	PrintRules.Insert("DocumentCorrectionsAreUsed",	False);
	
	Return PrintRules;
	
EndFunction

// Forms printed forms of the object.
//
// Parameters:
//	ObjectsArray			- Array of DocumentRef	- links to objects that need to be printed.
//	PrintParameters			- Structure					- additional print options.
//	PrintFormsCollection	- ValueTable			- generated tabular documents.
//	PrintObjects			- ValueList			- print objects.
//	OutputParameters			- Structure					- parameters of generated table documents.
//
Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
		
	StructureOfTypes = TMCommonUse.MatchingArraysByObjectType(ObjectsArray);
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "GoodsPickingPlacementJob") Then
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"GoodsPickingPlacementJob",
			NStr("vi = 'Nhiệm vụ lấy ra (xếp vào) hàng hóa';
				|ru = 'Задание на отбор (размещение) товара';
				|en = 'Intra-warehouse transfer task'; fa = 'وظیفه انتقال درون‌انباری';
				|it = 'Task di selezione (allocazione) della merce';
				|pl = 'Zadanie na dobór (umieszczenie) towaru';
				|tr = 'Ürün filtre (yerleştirme) görevi'"),
			CreateTaskForProductSelectionAndPlacement(ObjectsArray, PrintObjects, PrintParameters));
	EndIf;
	
	PrintFormGeneration.FillInSendingParameters(OutputParameters.SendOptions, StructureOfTypes, PrintFormsCollection);
	
EndProcedure

// Returns the printed form of the object.
//
// Parameters:
//	ObjectsArray	- Array of DocumentRef	- links to objects that need to be printed.
//	PrintObjects	- ValueList			- print objects.
//	PrintParameters	- Structure					- additional print options.
//
// Returns:
//	SpreadsheetDocument - the printed form of the object.
//
Function CreateTaskForProductSelectionAndPlacement(ObjectsArray, PrintObjects, PrintParameters) Export
	
	If TypeOf(ObjectsArray) = Type("Map") Then
		StructureOfTypes = ObjectsArray;
	Else
		StructureOfTypes = TMCommonUse.MatchingArraysByObjectType(ObjectsArray);
	EndIf;
	
	If PrintParameters.Property("JobType") And
		ValueIsFilled(PrintParameters.JobType) Then
		JobType = PrintParameters.JobType;
	Else
		JobType = "PlacementJob";
	EndIf;
	
	PrintingFromDocumentData	= PrintParameters.Property("PrintingFromDocumentData");
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.PrintParametersName = "PRINT_OPTIONS_" + JobType;
	
	TemplatePath			= "DataProcessor.PrintJobsForInventoryPickingPlacementAndRecount.PF_MXL_GoodsPickingPlacementJob";
	ColumnOfCodes = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms();
	NameOfCodeColumn = ColumnOfCodes.ColumnName;
	PresentationOfCodesColumn = ColumnOfCodes.ColumnPresentation;
	
	OutputCodes		= ValueIsFilled(NameOfCodeColumn);
	DisplayingPackages	= GetFunctionalOption("UseItemPackages")
							And Not (PrintParameters.Property("NoExtraCharge"));
	
	For Each ObjectsStructure In StructureOfTypes Do
		
		FirstDocument = True;
		
		FormName_1 = PrintFormName(JobType);
		
		If JobType = "CollectionJob" Then
			PrintData = DataProcessors.GoodsQuantityCheckInDocument.GetDataForPrintedFormTaskOnDoborGoods(
								PrintParameters,
								PrintParameters.WarehouseDocument);
		ElsIf PrintingFromDocumentData Then
			ObjectManager	= Common.ObjectManagerByFullName(ObjectsStructure.Key);
			PrintData	= ObjectManager.GetDataForPrintedFormForProductPlacement(PrintParameters,
																									ObjectsStructure.Value);
		Else
			ObjectManager			= Common.ObjectManagerByFullName(ObjectsStructure.Key);
			DocumentRules		= ObjectManager.RulesForPrintingTasksForSelectionPlacement();
			JobPrintingRules	= ?(TypeOf(DocumentRules) <> Type("Array"),
										CommonClientServer.ValueInArray(DocumentRules),
										DocumentRules);
			PrintData			= GetTaskDataForSelectingAndPlacingProducts(JobPrintingRules,
																					ObjectsStructure.Key,
																					JobType,
																					ObjectsStructure.Value);
		EndIf;
		
		ErrorData_1			= PrintData.ErrorResults;
		PackagingData		= PrintData.ResultForPackages;//QueryResult
		If PrintData.Property("ResultByBrand") Then
			DataOnBrands		= PrintData.ResultByBrand; // QueryResult
			SelectionByBrand 	= ?(ValueIsFilled(DataOnBrands),
									DataOnBrands.Select(),
									Undefined);
		Else
			SelectionByBrand 	= Undefined;
		EndIf;
		SelectionByHeader			= PrintData.HeaderResults.Select();
		SamplingByOrders	= ?(ValueIsFilled(PrintData.ResultOnOrders),
									PrintData.ResultOnOrders.Select(),
									Undefined);
		SelectionByTablePart	= PrintData.ResultForTabularPart.Select(QueryResultIteration.ByGroups);
		SampleByPackage		= ?(ValueIsFilled(PackagingData),
									PackagingData.Select(),
									Undefined);
		SelectionBySeries			= ?(ValueIsFilled(PrintData.ResultBySeries),
									PrintData.ResultBySeries.Select(),
									Undefined);
		
		If ValueIsFilled(ErrorData_1)
			And Not ErrorData_1.IsEmpty() Then
			
			FetchingDocumentsWithoutData = ErrorData_1.Select();
			
			While FetchingDocumentsWithoutData.Next() Do
				WarehouseOperation_ = ?(JobType <> "PlacementJob", NStr("vi = 'vận chuyển';
																		|ru = 'отгружаемая';
																		|en = 'shipping'; fa = 'shipping';
																		|it = 'in spedizione';
																		|pl = 'wysyłana';
																		|tr = 'sevk ediliyor'"), NStr("vi = 'được lưu trữ';
																								|ru = 'размещаемая';
																								|en = 'Allocating'; fa = 'Allocating';
																								|it = 'in collocazione';
																								|pl = 'rozmieszczana';
																								|tr = 'yerleştirilen'"));
				
				ErrorText = NStr("vi = 'Không thể in ""%FormName_1%"" đối với ""%Document%"",
				|bởi vì trong chứng từ không có %WarehouseOperation_% mặt hàng.';
				|ru = 'Невозможно напечатать ""%FormName_1%"" для ""%Document%"",
				|потому что в документе отсутствует %WarehouseOperation_% номенклатура.';
				|en = 'Can not print ""%FormName_1%"" for ""%Document%"",
				|because there is no %WarehouseOperation_% items in the document.'; fa = 'Can not print ""%FormName_1%"" for ""%Document%"",
				|because there is no %WarehouseOperation_% items in the document.';
				|it = 'impossibile stampare ""%FormName_1%"" per ""%Document%"",
				|perche nel documento manca %WarehouseOperation_% l''articolo.';
				|pl = 'Niemożliwe jest drukowanie ""%FormName_1%"" dla ""%Document%"",
				|ponieważ w dokumencie nie istnieje nomenklatura %WarehouseOperation_%.';
				|tr = 'Belge %WarehouseOperation_% öğesine sahip olmadığından ""%Document%"" için
				| ""%FormName_1%"" yazdırılamıyor.'");
				ErrorText = StrReplace(ErrorText, "%FormName_1%",		FormName_1);
				ErrorText = StrReplace(ErrorText, "%Document%",			FetchingDocumentsWithoutData.Ref);
				ErrorText = StrReplace(ErrorText, "%WarehouseOperation_%",	WarehouseOperation_);
				
				Common.MessageToUser(ErrorText);
			EndDo;
			
		EndIf;
		
		CurrentDocument = Undefined;
		
		While SelectionByHeader.Next() Do
			
			ErrorText = ErrorTextBasedOnDocumentData(SelectionByHeader,
														SelectionByTablePart,
														CurrentDocument,
														JobType,
														FormName_1);
			
			If ValueIsFilled(ErrorText) Then
				Common.MessageToUser(ErrorText);
				
				Continue;
			EndIf;
			
			ReferenceStorageIsUsed	= SelectionByHeader.ReferenceStorageIsUsed;
			WarehouseZoneUsage	= SelectionByHeader.WarehouseZoneUsage;
			DisplaySections					= WarehouseZoneUsage = Enums.UseIsDeterminedInWarerooms.Use;
			WithdrawByAccounting					= ?(JobType = "RecalculationTask", SelectionByHeader.WithdrawByAccounting, DisplayingPackages);
			UsePackages			= DisplayingPackages
												Or WithdrawByAccounting;
			NamesOfRegions                = NamesOfRegions(ReferenceStorageIsUsed, UsePackages, OutputCodes);
			
			FilterByWarehouse		= New Structure("Warehouse", SelectionByHeader.Warehouse);
			SampleByWarehouse	= SelectionByTablePart.Select(QueryResultIteration.ByGroups);
			
			While SampleByWarehouse.FindNext(FilterByWarehouse) Do
				
				Template = PrintManagement.PrintFormTemplate(TemplatePath);
				
				If Not FirstDocument Then
					SpreadsheetDocument.PutHorizontalPageBreak();
				EndIf;
				
				LineNumber			= 1;
				FirstDocument		= False;
				RowNumberStart	= SpreadsheetDocument.TableHeight + 1;
				
				HeaderArea_ = Template.GetArea("Title");
				HeaderArea_.Parameters.Fill(New Structure("TitleText", FormName_1));
				BarcodingOfPrintForms.OutputBarcodeToTabularDocument(SpreadsheetDocument,
																				Template,
																				HeaderArea_,
																				SelectionByHeader.Ref);
																				
				If Not SelectionByBrand = Undefined Then
					
					SelectionByBrand.Reset();
					If SelectionByBrand.FindNext(New Structure("Ref",SampleByWarehouse.Ref)) Then
						
						DisplayStamps = SelectionByBrand.ThereAreLabeledProducts;
						HeaderArea_.Parameters.MarkingAttribute = ?(DisplayStamps, "[M]", "");
					EndIf;
					
				Else
					DisplayStamps = False;
				EndIf;
				
				SpreadsheetDocument.Put(HeaderArea_);
				
				HeaderParameters_ = ParametersForFillingHeaderArea(SelectionByHeader);
				
				SectionHeader = Template.GetArea("Header");
				SectionHeader.Parameters.Fill(HeaderParameters_);
				SpreadsheetDocument.Put(SectionHeader);
				
				If TypeOf(SelectionByHeader.Ref) = Type("DocumentRef.GoodsIssueNote") Then
					
					BasisParameters = ParametersForFillingBaseArea(SelectionByHeader.Ref, SamplingByOrders);
					
					ScopeOfApplication_2 = Template.GetArea("Basis");
					ScopeOfApplication_2.Parameters.Fill(BasisParameters);
					SpreadsheetDocument.Put(ScopeOfApplication_2);
					
					If SelectionByHeader.ShipmentUnderTransportationJob Then
						TransportTaskParameters = ParametersForFillingInTransportTaskArea(SelectionByHeader);
						
						TransportTaskArea = Template.GetArea("TransportationJob");
						TransportTaskArea.Parameters.Fill(TransportTaskParameters);
						SpreadsheetDocument.Put(TransportTaskArea);
					EndIf;
					
				EndIf;
				
				If JobType = "RecalculationTask" Then
					ParametersOfPerformerArea = New Structure("PerformerPresentation",
																	PersonsTM.IndividualShortName(SelectionByHeader.PerformerPresentation,
																											SelectionByHeader.Date));
					
					ScopeOfApplication_ = Template.GetArea("Performer");
					ScopeOfApplication_.Parameters.Fill(ParametersOfPerformerArea);
					SpreadsheetDocument.Put(ScopeOfApplication_);
				EndIf;
				
				Area_TableHeader		= Template.GetArea(NamesOfRegions.TableHeader);
				AreaWorkSite	= Template.GetArea(NamesOfRegions.WarehouseZone);
				AreaTableRow	= Template.GetArea(NamesOfRegions.TableRow);
				TableBasementArea	= Template.GetArea(NamesOfRegions.TableFooter);
				
				ParametersOfTableHeaderArea = ParametersForFillingInTableHeaderArea(OutputCodes,
																						PresentationOfCodesColumn,
																						UsePackages,
																						JobType);
				
				Area_TableHeader.Parameters.Fill(ParametersOfTableHeaderArea);
				SpreadsheetDocument.Put(Area_TableHeader);
				
				SamplingWorkspaces = SampleByWarehouse.Select(QueryResultIteration.ByGroups);
				
				While SamplingWorkspaces.Next() Do
					
					If DisplaySections
						And ValueIsFilled(SamplingWorkspaces.WarehouseZone) Then
						
						AreaWorkSite.Parameters.Fill(SamplingWorkspaces);
						SpreadsheetDocument.Put(AreaWorkSite);
						
					EndIf;
					
					ProductSelection_2 = SamplingWorkspaces.Select(QueryResultIteration.ByGroups);
					
					While ProductSelection_2.Next() Do
						
						ProductPresentation	= ?(ValueIsFilled(ProductSelection_2.Products),
														ProductSelection_2.ProductPresentation,
														NStr("vi = '<ô trống>';
															|ru = '<пустая ячейка>';
															|en = '<empty bin>'; fa = '<empty bin>';
															|it = '<cella vuota>';
															|pl = '<pusta komórka>';
															|tr = '<boş hücre>'", Common.DefaultLanguageCode()));
						BatchPresentation			= BatchPresentation(ProductSelection_2, SelectionBySeries);
						
						AdditionalParametersProductPresentation = ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
						AdditionalParametersProductPresentation.DefaultLanguageCode = Common.DefaultLanguageCode();
						
						If DisplayStamps And ProductSelection_2.MarkedProducts Then
							AreaTableRow.Parameters.MarkingAttribute = "[M]";
						Else	
							AreaTableRow.Parameters.MarkingAttribute = "";
						EndIf; 
						
						OwnGoods = ProductsClientServer.PresentationOfProductsForPrinting(ProductPresentation,
																							ProductSelection_2.CharacteristicPresentation,
																							Undefined,
																							BatchPresentation,
																							AdditionalParametersProductPresentation);
						
						ParametersOfTSStringArea = New Structure;
						ParametersOfTSStringArea.Insert("LineNumber",	LineNumber);
						ParametersOfTSStringArea.Insert("OwnGoods",			OwnGoods);
						
						If OutputCodes Then
							ParametersOfTSStringArea.Insert("SKU", ProductSelection_2[NameOfCodeColumn]);
						EndIf;
						
						If ReferenceStorageIsUsed Then
							AdditionalStorageBins = AdditionalProductCells(ProductSelection_2,
																				Not ValueIsFilled(SampleByPackage));
							
							ParametersOfTSStringArea.Insert("AdditionalStorageBins", AdditionalStorageBins);
						EndIf;
						
						PackageFillingParameters = PackageFillingParameters(ProductSelection_2,
																					SampleByPackage,
																					UsePackages);
						
						AreaTableRow.Parameters.Fill(ProductSelection_2);
						AreaTableRow.Parameters.Fill(ParametersOfTSStringArea);
						AreaTableRow.Parameters.Fill(PackageFillingParameters);
						SpreadsheetDocument.Put(AreaTableRow);
						
						LineNumber = LineNumber + 1;
						
					EndDo;
					
				EndDo;
				
				SpreadsheetDocument.Put(TableBasementArea);
				
				PrintManagement.SetDocumentPrintArea(SpreadsheetDocument, RowNumberStart, PrintObjects,
					SelectionByHeader.Ref);
				
			EndDo;
			
		EndDo;
		
	EndDo;
	
	SpreadsheetDocument.FitToPage = True;
	
	Return SpreadsheetDocument;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

#Region Print

Function PresentationOfPrintCommand(JobType)
	
	CommandPresentation = "";
	
	If JobType = "PlacementJob" Then
		CommandPresentation = NStr("vi = 'Phân công vị trí đặt hàng';
									|ru = 'Задание на размещение товаров';
									|en = 'Put-away task'; fa = 'وظیفه جای‌گذاری';
									|it = 'Task per allocazione prodotti';
									|pl = 'Zadanie na rozmieszczenie towarów';
									|tr = 'Ürün yerleştirme görevi'");
	ElsIf JobType = "SelectionTask" Then
		CommandPresentation = NStr("vi = 'Nhiệm vụ lấy ra hàng hóa';
									|ru = 'Задание на отбор товаров';
									|en = 'Picking job'; fa = 'کار برداشت';
									|it = 'Task per selezione prodotti';
									|pl = 'Zadanie na selekcję towarów';
									|tr = 'Mal seçimi görevi'");;
	ElsIf JobType = "RecalculationTask" Then
		CommandPresentation = NStr("vi = 'Mẫu nhiệm vụ kiểm đếm hàng hóa (với ô hàng tra cứu)';
									|ru = 'Бланк задания на пересчет товаров (с ячейками справочно)';
									|en = 'Inventory count task template (with storage bins)'; fa = 'Inventory count task template (with storage bins)';
									|it = 'Modulo del task di ricalcolo delle merci (con celle di riferimento)';
									|pl = 'Formularz zadania na inwentaryzacje (z komórkami dla odniesienia)';
									|tr = 'Stok sayımı iş formu (referans için hücrelerle ile)'");
	Else
		CommandPresentation = NStr("vi = 'Nhiệm vụ tuyển chọn hàng hóa';
									|ru = 'Задание на добор товаров';
									|en = 'Goods collection job'; fa = 'Goods collection job';
									|it = 'Task per la selezione aggiuntiva di prodotti';
									|pl = 'Zadanie na dobór towarów';
									|tr = 'Ürün siparişi ekle görevi'");
	EndIf;
	
	Return CommandPresentation;
	
EndFunction

Function PrintFormName(JobType)
	
	If JobType = "PlacementJob" Then
		TitleText = NStr("vi = 'Phân công vị trí đặt hàng';
						|ru = 'Задание на размещение товаров';
						|en = 'Put-away task'; fa = 'وظیفه جای‌گذاری';
						|it = 'Task per allocazione prodotti';
						|pl = 'Zadanie na rozmieszczenie towarów';
						|tr = 'Ürün yerleştirme görevi'", Common.DefaultLanguageCode());
	ElsIf JobType = "SelectionTask" Then
		TitleText = NStr("vi = 'Nhiệm vụ lấy ra hàng hóa';
						|ru = 'Задание на отбор товаров';
						|en = 'Picking job'; fa = 'کار برداشت';
						|it = 'Task per selezione prodotti';
						|pl = 'Zadanie na selekcję towarów';
						|tr = 'Mal seçimi görevi'", Common.DefaultLanguageCode());
	ElsIf JobType = "CollectionJob" Then
		TitleText = NStr("vi = 'Nhiệm vụ tuyển chọn hàng hóa';
						|ru = 'Задание на добор товаров';
						|en = 'Goods collection job'; fa = 'Goods collection job';
						|it = 'Task per la selezione aggiuntiva di prodotti';
						|pl = 'Zadanie na dobór towarów';
						|tr = 'Ürün siparişi ekle görevi'", Common.DefaultLanguageCode());
	Else
		TitleText = NStr("vi = 'Nhiệm vụ kiểm đếm hàng hóa';
						|ru = 'Задание на пересчет товаров';
						|en = 'Inventory count task'; fa = 'وظیفه شمارش موجودی';
						|it = 'Task di ricalcolo delle merci';
						|pl = 'Zadanie na inwentaryzacje';
						|tr = 'Stok sayımı görevi'", Common.DefaultLanguageCode());
	EndIf;
	
	Return TitleText;
	
EndFunction

// Parameters:
//	PrintRules - See RulesForPrintingTasksForSelectionPlacement.
//	DocumentName - String - the full name of the document.
//	JobType - String - string identifier of the warehouse task type.
//	ObjectsArray - Array of DocumentRef - collection of links to the documents of the information base.
//	
// Returns:
//	Structure - a structure with the following keys:
//		*ErrorResults			- QueryResult	- errors in document data that make it impossible
//															to print the document.
//		*ResultOnOrders	- Undefined		- information about orders for document shipment.
//		*HeaderResults			- QueryResult	- data of the document header used for printing the Task
//															for selecting (placing) products.
//		*ResultForTabularPart	- QueryResult	- data of the product part of the document used for printing
//															Tasks for selecting (placing) products.
//		*ResultForPackages		- QueryResult	- data about product packages in the table part of the document
//															used for printing the Task for selecting (placing) products.
//		*ResultBySeries			- Undefined		- data about product series in the table part of the document
//															used for printing the Task for selecting (placing) products.
//
Function GetTaskDataForSelectingAndPlacingProducts(PrintRules, DocumentName, JobType, ObjectsArray)
	
	ReceiptOperation			= JobType = "PlacementJob";
	RecordType					= ?(ReceiptOperation, AccumulationRecordType.Receipt, AccumulationRecordType.Expense);
	RequestPacketSeparator	= Common.QueryBatchSeparator();
	UsedPremises		= ?(PrintRules.Count() > 0,
									ValueIsFilled(PrintRules[0].FieldNameRoom),
									False);
	
	QueryTexts = New Array;
	QueryTexts.Add(RequestTextForTaskDataTT(PrintRules, DocumentName));
	QueryTexts.Add(QueryTextTTDocumentGoods(PrintRules, DocumentName));
	QueryTexts.Add(QueryTextTTTaskItems_(DocumentName));
	QueryTexts.Add(RequestTextTTProductsSummarized());
	QueryTexts.Add(RequestTextForDocumentsWithoutProducts(DocumentName));
	QueryTexts.Add(TaskDataRequestTextTemplate(False));
	QueryTexts.Add(QueryTextTaskItems_(UsedPremises, ReceiptOperation));
	QueryTexts.Add(RequestAndTaskText_(UsedPremises, ReceiptOperation));
	
	QueryText = StrConcat(QueryTexts, RequestPacketSeparator);
	QueryText = StrReplace(QueryText, "&TaskData_", "TaskData_");
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("ObjectsArray",			ObjectsArray);
	Query.SetParameter("ReceiptOperation",	ReceiptOperation);
	Query.SetParameter("RecordType",			RecordType);
	
	SetPrivilegedMode(True);
	Result = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	
	MaxIndex = Result.UBound();
	
	TaskData_ = New Structure;
	TaskData_.Insert("ErrorResults",		Result[MaxIndex - 3]);
	TaskData_.Insert("ResultOnOrders",	Undefined);
	TaskData_.Insert("HeaderResults",			Result[MaxIndex - 2]);
	TaskData_.Insert("ResultForTabularPart",	Result[MaxIndex - 1]);
	TaskData_.Insert("ResultForPackages",		Result[MaxIndex]);
	TaskData_.Insert("ResultBySeries",			Undefined);
	
	Return TaskData_;
	
EndFunction

#Region RequestTextsForTaskData

Function RequestTextForTaskDataTT(PrintRules, DocumentName)
	
	TextsOfNestedTables	= New Array;
	MergeText		= TMCommonUse.QuerySeparatorInJoin();
	QueryText			= TaskDataRequestTextTemplate(True);
	
	For Each PrintRule In PrintRules Do
		TextOfDocumentDataRequest = TextOfDocumentDataRequest(DocumentName, PrintRule);
		
		TextsOfNestedTables.Add(TextOfDocumentDataRequest);
	EndDo;
	
	QueryTextTT	= StrConcat(TextsOfNestedTables, MergeText);
	QueryText	= StrReplace(QueryText, "&TaskData_", "(" + QueryTextTT + ")");
	
	Return QueryText;
	
EndFunction

Function TaskDataRequestTextTemplate(ThisIsTemporaryTable)
	
	QueryTextTemplate2 = 
	"SELECT DISTINCT
	|	TaskData_.Ref							AS Ref,
	|	PRESENTATION(TaskData_.Ref)				AS RefPresentation,
	|	TaskData_.Number								AS Number,
	|	TaskData_.Date								AS Date,
	|	TaskData_.NumberOfDocumentBeingCorrected		AS NumberOfDocumentBeingCorrected,
	|	TaskData_.DateOfDocumentBeingCorrected		AS DateOfDocumentBeingCorrected,
	|	TaskData_.Warehouse								AS Warehouse,
	|	PRESENTATION(TaskData_.Warehouse)				AS WarehousePresentation,
	|	TaskData_.Premise							AS Premise,
	|	PRESENTATION(TaskData_.Premise)			AS PremisePresentation,
	|	TaskData_.ThisIsAnInvoice						AS ThisIsAnInvoice,
	|	TaskData_.BinLocationWarehousingIsUsed		AS BinLocationWarehousingIsUsed,
	|	TaskData_.ReferenceStorageIsUsed	AS ReferenceStorageIsUsed,
	|	TaskData_.WarehouseZoneUsage		AS WarehouseZoneUsage,
	|	TaskData_.AdvancedWarehousingIsUsed			AS AdvancedWarehousingIsUsed
	|INTO TaskData_
	|FROM
	|	&TaskData_ AS TaskData_";
	
	If ThisIsTemporaryTable Then
		QueryTextTemplate2 = QueryTextTemplate2 + "
		|WHERE
		|	TaskData_.ReceiptOperation = &ReceiptOperation";
	Else
		QueryTextTemplate2 = StrReplace(QueryTextTemplate2, "INTO TaskData_", "");
		QueryTextTemplate2 = StrReplace(QueryTextTemplate2, "TaskData_.AdvancedWarehousingIsUsed", "MIN(TaskData_.AdvancedWarehousingIsUsed)");
		
		QueryTextTemplate2 = QueryTextTemplate2 + "
		|
		|GROUP BY
		|	TaskData_.Ref,
		|	TaskData_.Number,
		|	TaskData_.Date,
		|	TaskData_.NumberOfDocumentBeingCorrected,
		|	TaskData_.DateOfDocumentBeingCorrected,
		|	TaskData_.Warehouse,
		|	TaskData_.Premise,
		|	TaskData_.ThisIsAnInvoice,
		|	TaskData_.BinLocationWarehousingIsUsed,
		|	TaskData_.ReferenceStorageIsUsed,
		|	TaskData_.WarehouseZoneUsage
		|
		|ORDER BY
		|	TaskData_.Ref,
		|	TaskData_.Warehouse";
	EndIf;
	
	Return QueryTextTemplate2;
	
EndFunction

Function TextOfDocumentDataRequest(DocumentName, PrintRule)
	
	QueryText = 
	"SELECT DISTINCT
	|	DocumentData.Ref					AS Ref,
	|	DocumentData.Number					AS Number,
	|	DocumentData.Date					AS Date,
	|	&NumberOfDocumentBeingCorrected			AS NumberOfDocumentBeingCorrected,
	|	&DateOfDocumentBeingCorrected				AS DateOfDocumentBeingCorrected,
	|	&ReceiptOperation					AS ReceiptOperation,
	|	&Warehouse									AS Warehouse,
	|	&Premise								AS Premise,
	|	&ThisIsAnInvoice							AS ThisIsAnInvoice,
	|	&BinLocationWarehousingIsUsed			AS BinLocationWarehousingIsUsed,
	|	&ReferenceStorageIsUsed			AS ReferenceStorageIsUsed,
	|	&WarehouseZoneUsage			AS WarehouseZoneUsage,
	|	&AdvancedWarehousingIsUsed				AS AdvancedWarehousingIsUsed
	|FROM
	|	&TheTableNameOfTheDocument AS DocumentData
	|,&TableJoinText
	|WHERE
	|	DocumentData.Ref IN(&ObjectsArray)
	|AND &TextOfDocumentDataCondition";
	
	If PrintRule.VHFWarehouses Then
		TableJoinText	= TextOfDataConnectionOfSTCHDocument(DocumentName, PrintRule.NameTSGoods);
		ConditionText			= TextOfDocumentDataCondition();
	Else
		TableJoinText	= "";
		ConditionText			= "";
	EndIf;
	
	QueryText = StrReplace(QueryText, "&TheTableNameOfTheDocument",			DocumentName);
	QueryText = StrReplace(QueryText, ",&TableJoinText",		TableJoinText);
	QueryText = StrReplace(QueryText, "AND &TextOfDocumentDataCondition",	ConditionText);
	
	DocumentFieldValues = DocumentFieldValues();
	FillInValuesOfDocumentFields(DocumentFieldValues, PrintRule);
	
	For Each Simple In DocumentFieldValues Do
		SearchString = "&" + Simple.Key;
		QueryText = StrReplace(QueryText, SearchString, Simple.Value);
	EndDo;
	
	Return QueryText;
	
EndFunction

Function TextOfDataConnectionOfSTCHDocument(DocumentName, TSName)
	
	DocumentTSName = DocumentName + "." + TSName;
	
	TableJoinText = 
	"		INNER JOIN &NameTSGoods AS DocumentGoods
	|		ON DocumentData.Ref = DocumentGoods.Ref";
	
	TableJoinText = StrReplace(TableJoinText, "&NameTSGoods", DocumentTSName);
	
	Return TableJoinText;
	
EndFunction

Function TextOfDocumentDataCondition()
	
	TextOfDocumentDataCondition = 
	"	AND &Warehouse REFS Catalog.Warehouses
	|	AND &Warehouse <> VALUE(Catalog.Warehouses.EmptyRef)";
	
	Return TextOfDocumentDataCondition;
	
EndFunction

Function DocumentFieldValues()
	
	DocumentFieldValues = New Structure;
	DocumentFieldValues.Insert("WarehouseZoneUsage");
	DocumentFieldValues.Insert("Warehouse");
	DocumentFieldValues.Insert("Premise");
	DocumentFieldValues.Insert("ThisIsAnInvoice");
	DocumentFieldValues.Insert("ReceiptOperation");
	DocumentFieldValues.Insert("BinLocationWarehousingIsUsed");
	DocumentFieldValues.Insert("ReferenceStorageIsUsed");
	DocumentFieldValues.Insert("AdvancedWarehousingIsUsed");
	DocumentFieldValues.Insert("NumberOfDocumentBeingCorrected");
	DocumentFieldValues.Insert("DateOfDocumentBeingCorrected");
	
	Return DocumentFieldValues;
	
EndFunction

Procedure FillInValuesOfDocumentFields(FieldValues, PrintRule)
	
	ThisIsAnInvoice				= PrintRule.ThisIsAnInvoice;
	ReceiptOperation			= PrintRule.ReceiptOperation;
	SurplusesRecord			= PrintRule.SurplusesRecord;
	SourceOfBankingDetails			= ?(PrintRule.VHFWarehouses, "DocumentGoods.", "DocumentData.");
	UsedPremises		= ValueIsFilled(PrintRule.FieldNameRoom);
	DefaultRoom		= "VALUE(Catalog.Warerooms.EmptyRef)";
	CheckWarehouseOrder	= ThisIsAnInvoice
									And Not UsedPremises
									And Not PrintRule.AdjustmentOfGoods;
	DocumentCorrectionsAreUsed = PrintRule.DocumentCorrectionsAreUsed;
	
	Warehouse		= SourceOfBankingDetails + PrintRule.WarehouseFieldName;
	Premise	= ?(UsedPremises, "DocumentData." + PrintRule.FieldNameRoom, DefaultRoom);
	
	FieldValues.Warehouse								= Warehouse;
	FieldValues.Premise							= Premise;
	FieldValues.ThisIsAnInvoice						= ?(ThisIsAnInvoice, "TRUE", "FALSE");
	FieldValues.ReceiptOperation				= ?(ReceiptOperation, "TRUE", "FALSE");
	FieldValues.BinLocationWarehousingIsUsed		= TextAddressStorageIsUsed(ThisIsAnInvoice, Warehouse, Premise);
	FieldValues.ReferenceStorageIsUsed	= TextUsedReferenceStorage(UsedPremises,
																							Warehouse,
																							Premise);
	FieldValues.WarehouseZoneUsage		= TextUsingWorkspaces(UsedPremises,
																						Warehouse,
																						Premise);
	FieldValues.AdvancedWarehousingIsUsed			= TextOrderSchemeIsUsed(CheckWarehouseOrder,
																					ReceiptOperation,
																					SurplusesRecord,
																					Warehouse);
	FieldValues.DateOfDocumentBeingCorrected		= ?(DocumentCorrectionsAreUsed, "DocumentData.CorrectedDocument.Date", "UNDEFINED");
	FieldValues.NumberOfDocumentBeingCorrected		= ?(DocumentCorrectionsAreUsed, "DocumentData.CorrectedDocument.Number", "UNDEFINED");
	
EndProcedure

Function TextUsedReferenceStorage(UsedPremises, Source_Warehouse, RoomSource)
	
	If UsedPremises Then
		QueryText = 
		"ISNULL(CASE
		|		WHEN DocumentData.Warehouse.UseWarerooms
		|				AND DocumentData.Date >= DocumentData.Warehouse.StartDateOfWareroomUse
		|			THEN CASE
		|					WHEN DocumentData.Premise.UseBinLocationWarehousingForInformation
		|							AND (NOT DocumentData.Premise.UseBinLocationWarehousing
		|								OR DocumentData.Date < DocumentData.Premise.StartDateOfUsingWarehouseBinSystem)
		|						THEN TRUE
		|					ELSE FALSE
		|				END
		|		ELSE CASE
		|				WHEN DocumentData.Warehouse.UseBinLocationWarehousingForInformation
		|						AND (NOT DocumentData.Warehouse.UseBinLocationWarehousing
		|							OR DocumentData.Date < DocumentData.Warehouse.StartDateOfUsingWarehouseBinSystem)
		|					THEN TRUE
		|				ELSE FALSE
		|			END
		|	END, FALSE)";//@query-part-1
		
		QueryText = StrReplace(QueryText, "DocumentData.Premise", RoomSource);
	Else
		QueryText = 
		"ISNULL(CASE
		|		WHEN DocumentData.Warehouse.UseBinLocationWarehousingForInformation
		|				AND (NOT DocumentData.Warehouse.UseBinLocationWarehousing
		|					OR DocumentData.Date < DocumentData.Warehouse.StartDateOfUsingWarehouseBinSystem)
		|			THEN TRUE
		|		ELSE FALSE
		|	END, FALSE)";//@query-part-1
	EndIf;
	
	QueryText = StrReplace(QueryText, "DocumentData.Warehouse", Source_Warehouse);
	
	Return QueryText;
	
EndFunction

Function TextAddressStorageIsUsed(ThisIsAnInvoice, Source_Warehouse, RoomSource)
	
	If ThisIsAnInvoice Then
		QueryText = "FALSE";
	Else
		QueryText = 
		"ISNULL(CASE
		|		WHEN DocumentData.Warehouse.UseWarerooms
		|				AND DocumentData.Date >= DocumentData.Warehouse.StartDateOfWareroomUse
		|			THEN CASE
		|					WHEN DocumentData.Premise.UseBinLocationWarehousing
		|							AND DocumentData.Date >= DocumentData.Premise.StartDateOfUsingWarehouseBinSystem
		|						THEN TRUE
		|					ELSE FALSE
		|				END
		|		ELSE CASE
		|				WHEN DocumentData.Warehouse.UseBinLocationWarehousing
		|						AND DocumentData.Date >= DocumentData.Warehouse.StartDateOfUsingWarehouseBinSystem
		|					THEN TRUE
		|				ELSE FALSE
		|			END
		|	END, FALSE)"; // @query-part-1
		
		QueryText = StrReplace(QueryText, "DocumentData.Warehouse",		Source_Warehouse);
		QueryText = StrReplace(QueryText, "DocumentData.Premise",	RoomSource);
	EndIf;
	
	Return QueryText;
	
EndFunction

Function TextUsingWorkspaces(UsedPremises, Source_Warehouse, RoomSource)
	
	If UsedPremises Then
		QueryText = 
		"ISNULL(CASE
		|		WHEN DocumentData.Warehouse.UseWarerooms
		|				AND DocumentData.Date >= DocumentData.Warehouse.StartDateOfWareroomUse
		|			THEN DocumentData.Premise.WarehouseZoneUsage
		|		ELSE DocumentData.Warehouse.WarehouseZoneUsage
		|	END, FALSE)";// @query-part-1
		
		QueryText = StrReplace(QueryText, "DocumentData.Premise", RoomSource);
	Else
		QueryText = "ISNULL(DocumentData.Warehouse.WarehouseZoneUsage, FALSE)";
	EndIf;
	
	QueryText = StrReplace(QueryText, "DocumentData.Warehouse", Source_Warehouse);
	
	Return QueryText;
	
EndFunction

Function TextOrderSchemeIsUsed(CheckWarehouseOrder, ReceiptOperation, SurplusesRecord, Source_Warehouse)
	
	If CheckWarehouseOrder Then
		QueryText = 
		"ISNULL(CASE
		|		WHEN DocumentData.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
		|				AND DocumentData.Date >= DocumentData.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt
		|			THEN TRUE
		|		ELSE FALSE
		|	END, FALSE)";// @query-part-1
		
		WarehouseOperation = ?(SurplusesRecord, "WhenReflectingSurplusShortages",
								?(Not ReceiptOperation, "OnShipment", "OnReceipt"));
		
		QueryText = StrReplace(QueryText, "OnReceipt",			WarehouseOperation);
		QueryText = StrReplace(QueryText, "DocumentData.Warehouse",	Source_Warehouse);
	Else
		QueryText = "FALSE";
	EndIf;
	
	Return QueryText;
	
EndFunction

Function RequestTextForDocumentsWithoutProducts(DocumentName)
	
	QueryText = 
	"SELECT DISTINCT
	|	DocumentData.Ref AS Ref
	|FROM
	|	&TheTableNameOfTheDocument AS DocumentData
	|		LEFT JOIN TaskData_ AS TaskData_
	|		ON DocumentData.Ref = TaskData_.Ref
	|WHERE
	|	DocumentData.Ref IN(&ObjectsArray)
	|	AND TaskData_.Ref IS NULL";
	
	QueryText = StrReplace(QueryText, "&TheTableNameOfTheDocument", DocumentName);
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region RequestTextsAndTasks

Function QueryTextTTDocumentGoods(PrintRules, DocumentName)
	
	If Not UseDocumentData(DocumentName) Then
		ObjectManager	= Common.ObjectManagerByFullName(DocumentName);
		QueryText	= ObjectManager.TextOfGoodsRequestDocumentForPrintingTaskForSelectingPlacingGoods();
	Else
		TextsOfNestedTables	= New Array;
		MergeText		= TMCommonUse.QuerySeparatorInJoin();
		QueryText			= RequestTextTemplateForDocumentProducts();
		
		TSName = "";
		
		For Each PrintRule In PrintRules Do
			If PrintRule.NameTSGoods = TSName Then
				Continue;
			EndIf;
			
			QueryTextDocumentGoods = QueryTextDocumentGoods(DocumentName, PrintRule);
			
			TextsOfNestedTables.Add(QueryTextDocumentGoods);
		EndDo;
		
		QueryTextTT	= StrConcat(TextsOfNestedTables, MergeText);
		QueryText	= StrReplace(QueryText, "#DocumentGoods", "(" + QueryTextTT + ")");
	EndIf;
	
	Return QueryText;
	
EndFunction

Function RequestTextTemplateForDocumentProducts()
	
	QueryTextTemplate2 =
	"SELECT
	|	TableOfGoods.Ref				AS Ref,
	|	TableOfGoods.Warehouse				AS Warehouse,
	|	TableOfGoods.Premise			AS Premise,
	|	MIN(TableOfGoods.LineNumber)	AS LineNumber,
	|	TableOfGoods.Products			AS Products,
	|	TableOfGoods.Characteristic		AS Characteristic,
	|	TableOfGoods.Series				AS Series
	|INTO DocumentGoods
	|FROM
	|	#DocumentGoods AS TableOfGoods
	|
	|WHERE
	|	TableOfGoods.ReceiptOperation = &ReceiptOperation
	|
	|GROUP BY
	|	TableOfGoods.Ref,
	|	TableOfGoods.Warehouse,
	|	TableOfGoods.Premise,
	|	TableOfGoods.Products,
	|	TableOfGoods.Characteristic,
	|	TableOfGoods.Series
	|
	|INDEX BY
	|	Ref,
	|	Warehouse,
	|	Premise,
	|	Products,
	|	Characteristic,
	|	Series";
	
	Return QueryTextTemplate2;
	
EndFunction

Function QueryTextDocumentGoods(DocumentName, PrintRule)
	
	QueryText =
	"SELECT
	|	DocumentGoods.Ref			AS Ref,
	|	&Warehouse							AS Warehouse,
	|	&Premise						AS Premise,
	|	DocumentGoods.LineNumber		AS LineNumber,
	|	DocumentGoods.Products	AS Products,
	|	DocumentGoods.Characteristic	AS Characteristic,
	|	DocumentGoods.Series			AS Series,
	|	&ReceiptOperation			AS ReceiptOperation
	|FROM
	|	#NameTSGoods AS DocumentGoods
	|	,#TableJoinText AS ExternalTable
	|
	|WHERE
	|	DocumentGoods.Ref IN(&ObjectsArray)";
	
	DocumentTSName = DocumentName + "." + PrintRule.NameTSGoods;
	
	TableJoinText = "";
	
	If Not PrintRule.VHFWarehouses Then
		TableJoinText = 
		"		INNER JOIN &TheTableNameOfTheDocument AS DocumentData
		|		ON DocumentGoods.Ref = DocumentData.Ref";
		
		TableJoinText = StrReplace(TableJoinText, "&TheTableNameOfTheDocument", DocumentName);
	EndIf;
	
	QueryText = StrReplace(QueryText, "#NameTSGoods", DocumentTSName);
	QueryText = StrReplace(QueryText, ",#TableJoinText AS ExternalTable", TableJoinText);
	
	DocumentFieldValues = DocumentFieldValues();
	FillInValuesOfDocumentFields(DocumentFieldValues, PrintRule);
	
	For Each Simple In DocumentFieldValues Do
		SearchString = "&" + Simple.Key;
		QueryText = StrReplace(QueryText, SearchString, Simple.Value);
	EndDo;
	
	Return QueryText;
	
EndFunction

Function QueryTextTTTaskItems_(DocumentName)
	
	QueryText = 
	"SELECT
	|	ProductStock.Recorder				AS Ref,
	|	ProductStock.Warehouse					AS Warehouse,
	|	ProductStock.Premise				AS Premise,
	|	ISNULL(MIN(DocumentGoods.LineNumber), MIN(ProductStock.LineNumber)) AS LineNumber,
	|	ProductStock.Products			AS Products,
	|	ProductStock.Characteristic			AS Characteristic,
	|	ProductStock.Series					AS Series,
	|	Goods.PackagingGroup					AS PackagingGroup,
	|	SUM(CASE
	|			WHEN ProductStock.InStock > 0
	|				THEN ProductStock.InStock
	|			ELSE -ProductStock.InStock
	|		END)								AS Count
	|INTO TaskItems_
	|FROM
	|	AccumulationRegister.ProductStock AS ProductStock
	|		LEFT JOIN Catalog.Products AS Goods
	|		ON ProductStock.Products = Goods.Ref
	|		
	|		LEFT JOIN DocumentGoods AS DocumentGoods
	|		ON ProductStock.Recorder = DocumentGoods.Ref
	|			AND ProductStock.Warehouse = DocumentGoods.Warehouse
	|			AND ProductStock.Premise = DocumentGoods.Premise
	|			AND ProductStock.Products = DocumentGoods.Products
	|			AND ProductStock.Characteristic = DocumentGoods.Characteristic
	|			AND (ProductStock.Series = DocumentGoods.Series
	|				OR DocumentGoods.Series = VALUE(Catalog.ItemsBatches.EmptyRef))
	|
	|WHERE
	|	ProductStock.Recorder IN(&ObjectsArray)
	|	AND ProductStock.RecordType = &RecordType
	|	AND NOT ProductStock.ReversingEntry
	|
	|GROUP BY
	|	ProductStock.Recorder,
	|	ProductStock.Warehouse,
	|	ProductStock.Premise,
	|	ProductStock.Products,
	|	ProductStock.Characteristic,
	|	ProductStock.Series,
	|	Goods.PackagingGroup";
	
	Return QueryText;
	
EndFunction

Function UseDocumentData(DocumentName)
	
	ExclusionDocuments = New Array;
	ExclusionDocuments.Add(Metadata.Documents.ReturnOfGoodsFromCustomer.FullName());
	ExclusionDocuments.Add(Metadata.Documents.AssemblyFromComponents.FullName());
	ExclusionDocuments.Add(Metadata.Documents.RecyclableWasteAllocation.FullName());
	ExclusionDocuments.Add(Metadata.Documents.ProductionCostAllocation.FullName());
	UseDocumentData = ExclusionDocuments.Find(DocumentName) = Undefined;
	
	Return UseDocumentData;
	
EndFunction

Function RequestTextTTProductsSummarized()
	
	QueryText = 
	"SELECT
	|	GoodsTable.Ref				AS Ref,
	|	GoodsTable.Warehouse					AS Warehouse,
	|	GoodsTable.Premise				AS Premise,
	|	MIN(GoodsTable.LineNumber)	AS LineNumber,
	|	GoodsTable.Products			AS Products,
	|	GoodsTable.Characteristic		AS Characteristic,
	|	GoodsTable.Series					AS Series,
	|	GoodsTable.PackagingGroup			AS PackagingGroup,
	|	CASE
	|		WHEN GoodsTable.Products.ProductKind.BatchUsageSettings = &BatchUsageSettings
	|			THEN GoodsTable.Products.UnitOfMeasure
	|		ELSE VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|	END								AS Package,
	|	SUM(GoodsTable.Count)		AS Count
	|INTO TableOfGoodsSummarized
	|FROM
	|	TaskItems_ AS GoodsTable
	|
	|GROUP BY
	|	GoodsTable.Ref,
	|	GoodsTable.Warehouse,
	|	GoodsTable.Premise,
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic,
	|	GoodsTable.Series,
	|	GoodsTable.PackagingGroup,
	|	CASE
	|		WHEN GoodsTable.Products.ProductKind.BatchUsageSettings = &BatchUsageSettings
	|			THEN GoodsTable.Products.UnitOfMeasure
	|		ELSE VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|	END";
	
	QueryText = StrReplace(QueryText,
								"&BatchUsageSettings",
								"VALUE(Enum.ItemsBatchUsageSettings.InventoryItem)");
	
	Return QueryText;
	
EndFunction

Function QueryTextTaskItems_(UsedPremises, ReceiptOperation)
	
	QueryText = 
	"SELECT
	|	TableOfGoods.Ref								AS Ref,
	|	TableOfGoods.Warehouse								AS Warehouse,
	|	ISNULL(MainStorageBins.Cell.WarehouseZone, &DefaultWorkArea)	AS WarehouseZone,
	|	PRESENTATION(MainStorageBins.Cell.WarehouseZone)	AS PresentationOfWorkArea,
	|	ISNULL(MainStorageBins.Cell.TabIndex, 0)	AS TabIndex,
	|	ISNULL(MainStorageBins.Cell, &DefaultCell)	AS MainStorageBin,
	|	ISNULL(MainStorageBins.Cell.Code, """")			AS MainStorageBinPresentation,
	|	ISNULL(OtherCells.Cell.TabIndex, 0)	AS TraversalOrderAdditionalCell,
	|	ISNULL(OtherCells.Cell.Code, """")			AS CellPresentation,
	|	TableOfGoods.LineNumber							AS LineNumber,
	|	TableOfGoods.Products.Code						AS Code,
	|	TableOfGoods.Products.SKU					AS SKU,
	|	TableOfGoods.Products							AS Products,
	|	TableOfGoods.Products.DescriptionFull		AS ProductPresentation,
	|	TableOfGoods.Characteristic						AS Characteristic,
	|	TableOfGoods.Characteristic.DescriptionFull	AS CharacteristicPresentation,
	|	Goods.ProductKind.BatchUsageSettings	AS BatchUsageSettings,
	|	TableOfGoods.Series								AS Series,
	|	TableOfGoods.Series.Description					AS BatchPresentation,
	|	TableOfGoods.Package								AS Package,
	|	PRESENTATION(TableOfGoods.Package)				AS PresentationOfPackingUnit,
	|	PRESENTATION(Goods.UnitOfMeasure)				AS PresentationOfBasicUnitOfMeasure,
	|	TableOfGoods.Count							AS Count,
	|	TableOfGoods.Count							AS NumberOfPackages
	|FROM
	|	TableOfGoodsSummarized AS TableOfGoods
	|		LEFT JOIN Catalog.Products AS Goods
	|		ON TableOfGoods.Products = Goods.Ref
	|		
	|		LEFT JOIN InformationRegister.PlaceProductsInStorageBins AS MainStorageBins
	|		ON TableOfGoods.Products = MainStorageBins.Products
	|			AND MainStorageBins.MainStorageBin
	|			AND TableOfGoods.Warehouse = MainStorageBins.Warehouse
	|			AND &ConditionForConnectingMainCells
	|		
	|		LEFT JOIN InformationRegister.PlaceProductsInStorageBins AS OtherCells
	|		ON TableOfGoods.Products = OtherCells.Products
	|			AND NOT OtherCells.MainStorageBin
	|			AND TableOfGoods.Warehouse = OtherCells.Warehouse
	|			AND &ConditionForConnectingOtherCells
	|
	|ORDER BY
	|	Ref,
	|	Warehouse,
	|	WarehouseZone,
	|	LineNumber,
	|	Products,
	|	Characteristic,
	|	Series
	|
	|TOTALS BY
	|	Ref,
	|	Warehouse,
	|	WarehouseZone";
	
	If UsedPremises Then
		ConditionForConnectingMainCells	= TextOfProductLinkCondition("MainStorageBins",
																						ReceiptOperation);
		ConditionForConnectingOtherCells	= TextOfProductLinkCondition("OtherCells",
																						ReceiptOperation);
	Else
		ConditionForConnectingMainCells	= "";
		ConditionForConnectingOtherCells	= "";
	EndIf;
	
	QueryText = StrReplace(QueryText,
								"&DefaultWorkArea",
								"VALUE(Catalog.WarehouseZones.EmptyRef)");
	QueryText = StrReplace(QueryText,
								"&DefaultCell",
								"VALUE(Catalog.StorageBins.EmptyRef)");
	QueryText = StrReplace(QueryText,
								"AND &ConditionForConnectingMainCells",
								ConditionForConnectingMainCells);
	QueryText = StrReplace(QueryText,
								"AND &ConditionForConnectingOtherCells",
								ConditionForConnectingOtherCells);
	
	Return QueryText;
	
EndFunction

#EndRegion

Function RequestAndTaskText_(UsedPremises, ReceiptOperation)
	
	QueryText = 
	"SELECT DISTINCT
	|	TableOfGoods.Ref					AS Ref,
	|	TableOfGoods.Warehouse					AS Warehouse,
	|	ISNULL(MainStorageBins.Cell.WarehouseZone, &DefaultWorkArea)	AS WarehouseZone,
	|	TableOfGoods.LineNumber				AS LineNumber,
	|	TableOfGoods.Products				AS Products,
	|	TableOfGoods.Characteristic			AS Characteristic,
	|	TableOfGoods.Series					AS Series,
	|	ISNULL(ProductPackages.Ref, &DefaultPackaging)	AS Package,
	|	ISNULL(PRESENTATION(ProductPackages.Ref), PRESENTATION(TableOfGoods.Products.UnitOfMeasure))	AS PresentationOfPackingUnit,
	|	ISNULL(&PackingCoefficientText, 1)	AS QuantityPerPackage
	|FROM
	|	TableOfGoodsSummarized AS TableOfGoods
	|		LEFT JOIN Catalog.PackagesAndUnitsOfMeasure AS ProductPackages
	|		ON (TableOfGoods.Products = ProductPackages.Owner
	|				OR TableOfGoods.PackagingGroup = ProductPackages.Owner)
	|			AND NOT ProductPackages.DeletionMark
	|			AND TableOfGoods.Count >= &PackingCoefficientText
	|		
	|		LEFT JOIN InformationRegister.PlaceProductsInStorageBins AS MainStorageBins
	|		ON TableOfGoods.Products = MainStorageBins.Products
	|			AND MainStorageBins.MainStorageBin
	|			AND TableOfGoods.Warehouse = MainStorageBins.Warehouse
	|			AND &ConditionForConnectingMainCells
	|
	|ORDER BY
	|	Ref,
	|	Warehouse,
	|	WarehouseZone,
	|	LineNumber,
	|	Products,
	|	Characteristic,
	|	Series,
	|	QuantityPerPackage DESC";
	
	PackingCoefficientText = Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
									"ProductPackages",
									"TableOfGoods.Products");
	
	If UsedPremises Then
		ConditionForConnectingMainCells = TextOfProductLinkCondition("MainStorageBins", ReceiptOperation);
	Else
		ConditionForConnectingMainCells = "";
	EndIf;
	
	QueryText = StrReplace(QueryText,
								"&DefaultWorkArea",
								"VALUE(Catalog.WarehouseZones.EmptyRef)");
	QueryText = StrReplace(QueryText,
								"&DefaultPackaging",
								"VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)");
	QueryText = StrReplace(QueryText, "&PackingCoefficientText", PackingCoefficientText);
	QueryText = StrReplace(QueryText,
								"AND &ConditionForConnectingMainCells",
								ConditionForConnectingMainCells);
	
	Return QueryText;
	
EndFunction

Function TextOfProductLinkCondition(CellSource, ReceiptOperation)
	
	FieldNameDate = ?(ReceiptOperation, "Date", "DateOfShipment");
	
	ConnectionConditionText = 
	"			AND CASE
	|				WHEN TableOfGoods.Warehouse.UseWarerooms
	|						AND TableOfGoods.Ref.FieldNameDate >= TableOfGoods.Warehouse.StartDateOfWareroomUse
	|					THEN TableOfGoods.Premise = MainStorageBins.Premise
	|				ELSE MainStorageBins.Premise = VALUE(Catalog.Warerooms.EmptyRef)
	|			END";
	
	ConnectionConditionText = StrReplace(ConnectionConditionText, "MainStorageBins",	CellSource);
	ConnectionConditionText = StrReplace(ConnectionConditionText, "FieldNameDate",		FieldNameDate);
	
	Return ConnectionConditionText;
	
EndFunction

Function ErrorTextBasedOnDocumentData(DocumentData, TSData, CurDokumet, JobType, FormName_1)
	
	ErrorText = "";
	
	If DocumentData.AdvancedWarehousingIsUsed Then
		
		WarehousePresentation_ = WarehousesServer.GetWarehousePresentation(DocumentData.WarehousePresentation,
																		DocumentData.PremisePresentation);
		
		ErrorText = NStr("vi = 'Không thể in %FormName_1% đối với ""%Document%"",
							|bởi vì trong kho ""%Warehouse%"" có sử dụng sơ đồ hai pha, do đó cần in nhiệm vụ từ phiếu.';
							|ru = 'Невозможно напечатать %FormName_1% для ""%Document%"",
							|потому что на складе ""%Warehouse%"" используется ордерная схема, поэтому печать задания должна вестись из ордера.';
							|en = 'Cannot print %FormName_1% for ""%Document%""
							|as Warehouse Management is enabled at warehouse ""%Warehouse%"". Print the task from the goods receipt/issue.'; fa = 'Cannot print %FormName_1% for ""%Document%""
							|as Warehouse Management is enabled at warehouse ""%Warehouse%"". Print the task from the goods receipt/issue.';
							|it = 'Impossibile stampare %FormName_1% per ""%Document%"",
							| perche nel magazzino ""%Warehouse%"" viene usato lo schema dei mandati, perciò la stampa del task deve essere effettuata dal mandato.';
							|pl = 'Nie można wydrukować %FormName_1% dla ""%Document%"", 
							|ponieważ na magazynie ""%Warehouse%"" jest używany schemat zleceń, dlatego drukowanie zadania powinno odbywać się ze zlecenia.';
							|tr = '""%Document%"" için %FormName_1% yazdırmak mümkün değildir
							|çünkü ""%Warehouse%"" ambarı bir sipariş şeması kullanır, bu nedenle işin bir siparişten yazdırılması gerekir.'");
		ErrorText = StrReplace(ErrorText, "%Warehouse%", WarehousePresentation_);
		
	ElsIf Not DocumentData.ThisIsAnInvoice
		And DocumentData.BinLocationWarehousingIsUsed Then
		
		ErrorText = NStr("vi = 'Không thể in %FormName_1% đối với ""%Document%"",
							|do đó đối với kho bãi (nhà kho) có ô hàng được dùng để cất giữ số dư hàng hóa thì mẫu in này không khả dụng.
							|Có thể in nhiệm vụ lấy ra (xếp vào) từ chứng từ ""Lấy ra (xếp vào) hàng hóa"".';
							|ru = 'Невозможно напечатать %FormName_1% для ""%Document%"",
							|потому что для склада (помещения) с ячейками, используемыми для хранения остатков номенклатуры, эта печатная форма не предусмотрена.
							|Печать задания на отбор (размещение) возможна из документа ""Отбор (размещение) товаров"".';
							|en = '%Document% cannot generate %FormName_1%.
							|The document doesn''t support this print form.
							|To print the form, open Intra-warehouse transfer and select Print.'; fa = '%Document% cannot generate %FormName_1%.
							|The document doesn''t support this print form.
							|To print the form, open Intra-warehouse transfer and select Print.';
							|it = 'Impossibile stampare %FormName_1% per ""%Document%"",
							| perché per un magazzino (locale) con celle utilizzate per conservare le rimanenze degli articoli, non è previsto questo modulo di stampa
							|La stampa del task per la selezione (allocazione) è possibile dal documento ""Selezione (allocazione) delle merci"".';
							|pl = 'Nie można wydrukować %FormName_1% dla ""%Document%"",
							|ponieważ dla magazynu (pomieszczenia) z komórkami, używanymi do przechowywania pozostałości nomenklatury, ten formularz wydruku nie jest przewidziany.
							|Wydruk zadania na dobór (umieszczenie) jest możliwy z dokumentu ""Dobór (umieszczenie) towarów"".';
							|tr = '""%Document%"" için %FormName_1% yazdırmak mümkün değildir,
							|çünkü bu yazdırma formu öğe bakiyelerini saklamak için kullanılan hücrelere sahip ambar (alan) için mevcut değildir.
							|""Ürünlerin filtresi (yerleştirilmesi)"" belgesinden bir filtre (yerleştirme) görevi yazdırmak mümkündür.'");
		
	ElsIf CurDokumet <> DocumentData.Ref Then
		
		FilterByDocument = New Structure("Ref", DocumentData.Ref);
		
		If Not TSData.FindNext(FilterByDocument) Then
			WarehousePresentation_ = WarehousesServer.GetWarehousePresentation(DocumentData.WarehousePresentation,
																		DocumentData.PremisePresentation);
			
			If JobType <> "PlacementJob" Then
				If ValueIsFilled(WarehousePresentation_) Then
					ErrorText = NStr("vi = 'Không thể in ""%FormName_1%"" đối với ""%Document%"",
										|bởi vì trong chứng từ không có mặt hàng được giao từ kho ""%Warehouse%"".';
										|ru = 'Невозможно напечатать ""%FormName_1%"" для ""%Document%"",
										|потому что в документе отсутствует отгружаемая номенклатура со склада ""%Warehouse%"".';
										|en = 'Cannot print ""%FormName_1%"" for ""%Document%""
										|as the document does not contain an item to ship from the ""%Warehouse%"" warehouse.'; fa = 'Cannot print ""%FormName_1%"" for ""%Document%""
										|as the document does not contain an item to ship from the ""%Warehouse%"" warehouse.';
										|it = 'Impossibile stampare ""%FormName_1%"" per ""%Document%"", 
										| poiché nel documento manca la nomenclatura spedibile dal magazzino ""%Warehouse%"".';
										|pl = 'Nie można wydrukować ""%FormName_1%"" dla ""%Document%"",
										|ponieważ dokument nie zawiera wysyłanego produktu z magazynu ""%Warehouse%"".';
										|tr = 'Belge ""%Document%"" için ""%FormName_1%"" yazdırmak mümkün değildir,
										|çünkü belge ""%Warehouse%"" ambarından sevk edilecek öğeyi içermemektedir.'");
				Else
					ErrorText = NStr("vi = 'Không thể in ""%FormName_1%"" đối với ""%Document%"",
										|bởi vì trong chứng từ không có mặt hàng được giao.';
										|ru = 'Невозможно напечатать ""%FormName_1%"" для ""%Document%"",
										|потому что в документе отсутствует отгружаемая номенклатура.';
										|en = 'Cannot print ""%FormName_1%"" for ""%Document%"", 
										| due to the absence of the shipped items in the document.'; fa = 'Cannot print ""%FormName_1%"" for ""%Document%"", 
										| due to the absence of the shipped items in the document.';
										|it = 'Невозможно напечатать ""%FormName_1%"" для ""%Document%"",
										|потому что в документе отсутствует отгружаемая номенклатура.';
										|pl = 'Cannot print ""%FormName_1%"" for ""%Document%"", 
										| due to the absence of the shipped items in the document.';
										|tr = 'Belgede sevk edilecek öğe bulunmadığından dolayı
										|""%Belge%"" için ""%FormName_1%"" yazdırılamıyor.'");
				EndIf;
			Else
				ErrorText = NStr("vi = 'Không thể in ""%FormName_1%"" đối với ""%Document%"",
									|bởi vì trong chứng từ không có mặt hàng được sắp xếp vào kho ""%Warehouse%"".';
									|ru = 'Невозможно напечатать ""%FormName_1%"" для ""%Document%"",
									|потому что в документе отсутствует размещаемая номенклатура на складе ""%Warehouse%"".';
									|en = 'Cannot print ""%FormName_1%"" for ""%Document%""
									|as the document does not contain an item to put away in the ""%Warehouse%"" warehouse.'; fa = 'Cannot print ""%FormName_1%"" for ""%Document%""
									|as the document does not contain an item to put away in the ""%Warehouse%"" warehouse.';
									|it = 'Impossibile stampare ""%FormName_1%"" per ""%Document%"",
									|poiché nel documento manca la nomenclatura posizionabile nel magazzino ""%Warehouse%"".';
									|pl = 'Nie można wydrukować ""%FormName_1%"" dla ""%Document%"",
									|ponieważ dokument nie zawiera rozmieszczonego produktu w magazynie ""%Warehouse%"".';
									|tr = 'Belge ""%Document%"" için ""%FormName_1%"" yazdırmak mümkün değildir,
									|çünkü belge ""%Warehouse%"" ambarına yerleştirilecek öğeye sahip değildir.'");
			EndIf;
			
			ErrorText = StrReplace(ErrorText, "%Warehouse%", WarehousePresentation_);
		Else
			CurDokumet = DocumentData.Ref;
		EndIf;
		
	EndIf;
	
	If ValueIsFilled(ErrorText) Then
		ErrorText = StrReplace(ErrorText, "%FormName_1%",	FormName_1);
		ErrorText = StrReplace(ErrorText, "%Document%",		DocumentData.RefPresentation);
	EndIf;
	
	Return ErrorText;
	
EndFunction

Function NamesOfRegions(ReferenceStorageIsUsed, UsePackages, OutputCodes)
	
	ReturnStructure = New Structure("TableFooter, TableRow, WarehouseZone, TableHeader");
	
	If ReferenceStorageIsUsed And UsePackages And OutputCodes Then
		ReturnStructure.TableFooter = "BasementTableBase";
		ReturnStructure.TableRow = "TableRowBasis";
		ReturnStructure.WarehouseZone = "WorkingAreaBasis";
		ReturnStructure.TableHeader = "HeaderOfBaseTable";
	ElsIf Not ReferenceStorageIsUsed And UsePackages And OutputCodes Then
		ReturnStructure.TableFooter = "BasementTableWithoutCells";
		ReturnStructure.TableRow = "TableRowWithoutCells";
		ReturnStructure.WarehouseZone = "WorkingAreaWithoutCells";
		ReturnStructure.TableHeader = "TableHeaderWithoutCells";
	ElsIf Not ReferenceStorageIsUsed And UsePackages And Not OutputCodes Then
		ReturnStructure.TableFooter = "BasementTableWithoutCellsWithoutCodes";
		ReturnStructure.TableRow = "TableRowWithoutCellsWithoutCodes";
		ReturnStructure.WarehouseZone = "WorkingAreaWithoutCellsWithoutCodes";
		ReturnStructure.TableHeader = "TableHeaderWithoutCellsWithoutCodes";
	ElsIf Not ReferenceStorageIsUsed And Not UsePackages And OutputCodes Then
		ReturnStructure.TableFooter = "BasementTableWithoutCellsWithoutPackages";
		ReturnStructure.TableRow = "TableRowWithoutCellsWithoutPackages";
		ReturnStructure.WarehouseZone = "WorkingAreaWithoutCellsWithoutPackages";
		ReturnStructure.TableHeader = "TableHeaderWithoutCellsWithoutPackages";
	ElsIf Not ReferenceStorageIsUsed And Not UsePackages And Not OutputCodes Then
		ReturnStructure.TableFooter = "BasementTablesNOCellsNoPackagesNoCodes";
		ReturnStructure.TableRow = "TableRowNoCellsNoPackagesNoCodes";
		ReturnStructure.WarehouseZone = "WorkingAreaWithoutCellsWithoutPackagesWithoutCodes";
		ReturnStructure.TableHeader = "TableHeaderWithoutCellsWithoutPackagesWithoutCodes";
	ElsIf ReferenceStorageIsUsed And Not UsePackages And OutputCodes Then
		ReturnStructure.TableFooter = "TableBasementWithoutPackages";
		ReturnStructure.TableRow = "TableRowWithoutPackages";
		ReturnStructure.WarehouseZone = "WorkingAreaWithoutPackages";
		ReturnStructure.TableHeader = "TableHeaderWithoutPackages";
	ElsIf ReferenceStorageIsUsed And Not UsePackages And Not OutputCodes Then
		ReturnStructure.TableFooter = "BasementTablesWithoutPackagesWithoutCodes";
		ReturnStructure.TableRow = "TableRowWithoutPackagesWithoutCodes";
		ReturnStructure.WarehouseZone = "WorkingAreaWithoutPackagesWithoutCodes";
		ReturnStructure.TableHeader = "TableHeaderWithoutPackagesWithoutCodes";
	ElsIf ReferenceStorageIsUsed And UsePackages And Not OutputCodes Then
		ReturnStructure.TableFooter = "BasementTablesWithoutCodes";
		ReturnStructure.TableRow = "TableRowWithoutCodes";
		ReturnStructure.WarehouseZone = "WorkAreaWithoutCodes";
		ReturnStructure.TableHeader = "TableHeaderWithoutCodes";
	EndIf;
	
	Return ReturnStructure;
	
EndFunction

Function ParametersForFillingBaseArea(DocumentRef, SamplingByOrders)
	
	TextSeparator	= ", ";
	TextsOfPresentations	= New Array;
	DocumentAttributes	= DocumentAttributes();
	FilterReferences	= New Structure("Ref", DocumentRef);
	
	While SamplingByOrders.FindNext(FilterReferences) Do
		DocumentAttributes.Date				= SamplingByOrders.ReferenceDocumentDateForPrintForms;
		DocumentAttributes.Number			= SamplingByOrders.BaseDocumentNumber;
		DocumentAttributes.Prefix			= "";
		DocumentAttributes.Presentation	= SamplingByOrders.BasisPresentation;
		
		TextsOfPresentations.Add(TMCommonUseClientServer.GenerateDocumentTitle(DocumentAttributes));
	EndDo;
	
	BaseHeader		= ?(TextsOfPresentations.Count() > 1, NStr("vi = 'Cơ sở:';
																|ru = 'Основания:';
																|en = 'Base documents:'; fa = 'Base documents:';
																|it = 'Causali:';
																|pl = 'Podstawy:';
																|tr = 'Temel:'", Common.DefaultLanguageCode()), NStr("vi = 'Lý do:';
																																|ru = 'Основание:';
																																|en = 'Base document:'; fa = 'سند مبنا:';
																																|it = 'Causale:';
																																|pl = 'Podstawa:';
																																|tr = 'Temel:'", Common.DefaultLanguageCode()));
	PresentationOfGrounds	= StrConcat(TextsOfPresentations, TextSeparator);
	
	FillParameters = New Structure;
	FillParameters.Insert("Basis1",				BaseHeader);
	FillParameters.Insert("PresentationOfGrounds",	PresentationOfGrounds);
	
	Return FillParameters;
	
EndFunction

Function DocumentAttributes()
	
	DocumentAttributes = New Structure("Date, Number, Prefix, Presentation, DateOfDocumentBeingCorrected, NumberOfDocumentBeingCorrected");
	
	Return DocumentAttributes;
	
EndFunction

Function ParametersForFillingInTransportTaskArea(DocumentData)
	
	DocumentAttributes = DocumentAttributes();
	DocumentAttributes.Date				= DocumentData.TransportationTaskDate;
	DocumentAttributes.Number			= DocumentData.TransportationTaskNumber;
	DocumentAttributes.Prefix			= "";
	DocumentAttributes.Presentation	= DocumentData.TransportationJobPresentation;
	
	TransportationJobPresentation = TMCommonUseClientServer.GenerateDocumentTitle(DocumentAttributes);
	
	FillParameters = New Structure;
	FillParameters.Insert("DeliveryProcedure",					DocumentData.DeliveryProcedure);
	FillParameters.Insert("TransportationJobPresentation",	TransportationJobPresentation);
	
	Return FillParameters;
	
EndFunction

Function ParametersForFillingHeaderArea(DocumentData)
	
	WarehousePresentation_ = WarehousesServer.GetWarehousePresentation(DocumentData.WarehousePresentation,
																	DocumentData.PremisePresentation);
																	
																	DocumentAttributes = DocumentAttributes();
	FillPropertyValues(DocumentAttributes, DocumentData);
	DocumentAttributes.Presentation = DocumentData.RefPresentation;
	
	PresentationOfOrder = TMCommonUseClientServer.GenerateDocumentTitle(DocumentAttributes,
																								"",
																								True);
	
	FillParameters = New Structure;
	FillParameters.Insert("WarehousePresentation_",			WarehousePresentation_);
	FillParameters.Insert("PresentationOfOrder",	PresentationOfOrder);
	
	Return FillParameters;
	
EndFunction

Function ParametersForFillingInTableHeaderArea(OutputCodes, ColumnOfCodes, UsePackages, JobType)
	
	FillParameters = New Structure;
	
	If OutputCodes Then
		FillParameters.Insert("NameOfCodeColumn", ColumnOfCodes);
	EndIf;
	
	If UsePackages Then
		If JobType <> "RecalculationTask" Then
			FillParameters.Insert("LabelPackingQuantity", NStr("vi = '(đóng gói)';
																|ru = '(упаковок)';
																|en = '(packaging units)'; fa = '(واحدهای بسته‌بندی)';
																|it = '(imballaggi)';
																|pl = '(packaging units)';
																|tr = '(paketleme ünitesi)'", Common.DefaultLanguageCode()));
		Else
			FillParameters.Insert("LabelQuantity",			NStr("vi = '(thực tế)';
																	|ru = '(факт)';
																	|en = '(actual)'; fa = '(actual)';
																	|it = '(факт)';
																	|pl = '(actual)';
																	|tr = '(bilgiler)'", Common.DefaultLanguageCode()));
			FillParameters.Insert("LabelPackingQuantity",	NStr("vi = '(theo kế toán)';
																	|ru = '(по учету)';
																	|en = '(by accounting)'; fa = '(by accounting)';
																	|it = '(по учету)';
																	|pl = '(by accounting)';
																	|tr = '(muhasebeye göre)'", Common.DefaultLanguageCode()));
		EndIf;
	EndIf;
	
	Return FillParameters;
	
EndFunction

Function BatchPresentation(ProductData_8, SelectionBySeries)
	
	BatchPresentation = ProductData_8.BatchPresentation;
	
	If ValueIsFilled(SelectionBySeries) Then
		
		BatchUsageSettings = ProductData_8.BatchUsageSettings;
		
		If BatchUsageSettings = Enums.ItemsBatchUsageSettings.InventoryItem Then
			ProductitemSeries = New Array;
			
			FilterByProduct = New Structure("Ref, Warehouse, WarehouseZone, Products, Characteristic");
			FillPropertyValues(FilterByProduct, ProductData_8);
			
			While SelectionBySeries.FindNext(FilterByProduct) Do
				ProductitemSeries.Add(SelectionBySeries.BatchPresentation);
			EndDo;
			
			BatchPresentation = StrConcat(ProductitemSeries, ", ");
		EndIf;
		
	EndIf;
	
	Return BatchPresentation;
	
EndFunction

Function AdditionalProductCells(ProductSelection_2, SelectByPackages)
	
	AdditionalStorageBins		= New Array;
	BatchUsageSettings	= ProductSelection_2.BatchUsageSettings;
	
	SelectionKeys = ?(BatchUsageSettings = Enums.ItemsBatchUsageSettings.InventoryItem,
					"Products, Characteristic",
					"Products, Characteristic, Series");
	SelectionKeys = ?(SelectByPackages, SelectionKeys + ", Package", SelectionKeys);

	
	FilterByProduct = New Structure(SelectionKeys);
	FillPropertyValues(FilterByProduct, ProductSelection_2);
	
	AdditionalStorageBins.Add(ProductSelection_2.CellPresentation);
	
	While ProductSelection_2.FindNext(FilterByProduct) Do
		AdditionalStorageBins.Add(ProductSelection_2.CellPresentation);
	EndDo;
	
	AdditionalCellsByRow = StrConcat(AdditionalStorageBins, Chars.LF);
	
	Return AdditionalCellsByRow;
	
EndFunction

Function PackageFillingParameters(ProductData_8, SampleByPackage, UsePackages)
	
	BatchUsageSettings	= ProductData_8.BatchUsageSettings;
	FillParameters			= New Structure("NumberOfPackages, PresentationOfPackingUnit");
	
	If Not UsePackages
		Or Not ValueIsFilled(SampleByPackage)
		Or BatchUsageSettings = Enums.ItemsBatchUsageSettings.InventoryItem Then
		
		FillPropertyValues(FillParameters, ProductData_8);
		
	Else
		
		NumberOfPackages = New Array;
		PackageNaming = New Array;
		
		Count = ?(ValueIsFilled(ProductData_8.Products), ProductData_8.Count, 0);
		
		If Count > 0 Then
			SampleByPackage.Reset();
			
			FilterByProduct = New Structure("Ref, Warehouse, WarehouseZone, Products, Characteristic, Series");
			FillPropertyValues(FilterByProduct, ProductData_8);
			
			While SampleByPackage.FindNext(FilterByProduct) Do
				
				If Count <= 0 Then
					Break;
				EndIf;
				
				QuantityPerDocument = Int(Count / SampleByPackage.QuantityPerPackage);
				
				If QuantityPerDocument > 0 Then
					NumberOfPackages.Add(QuantityPerDocument);
					PackageNaming.Add(SampleByPackage.PresentationOfPackingUnit);
					
					Count = Count - QuantityPerDocument * SampleByPackage.QuantityPerPackage;
				EndIf;
				
			EndDo;
			
			If Count > 0 Then
				NumberOfPackages.Add(Count);
				PackageNaming.Add(ProductData_8.PresentationOfBasicUnitOfMeasure);
			EndIf;
			
			FillParameters.NumberOfPackages						= StrConcat(NumberOfPackages, Chars.LF);
			FillParameters.PresentationOfPackingUnit	= StrConcat(PackageNaming, Chars.LF);
		Else
			FillPropertyValues(FillParameters, ProductData_8);
		EndIf;
		
	EndIf;
	
	Return FillParameters;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
