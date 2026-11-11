
#Region Public

#Region LabelsAndPriceTags

// Returns data for printing labels or price tags,
//	and gets this data from the modules of print object managers.
//
// Parameters:
//	Id	- String - it can take the values "price Tags" or " Labels";
//	PrintObjects	- Array - array of links to objects to print, links must be of the same type;
//	AdditionalParameters	- Structure - print settings.
//
// Returns:
//	String	-	the address of the structure in the temporary storage that contains the data to be printed.
//
Function DataForPrintingPriceTagsAndLabels(Id, PrintObjects, AdditionalParameters) Export
	
	ObjectManager = Common.ObjectManagerByRef(PrintObjects[0]);
	
	MatchingObjects = TMCommonUse.DecomposeArrayOfReferencesByType(PrintObjects);
	If MatchingObjects.Count() > 1 Then
		MessageText = NStr("vi = 'Không hỗ trợ in nhãn tem và nhãn giá cho một số dạng chứng từ';
							|ru = 'Печать этикеток и ценников для нескольких видов документов не поддерживается';
							|en = 'Cannot print labels and price tags for several document kinds'; fa = 'Cannot print labels and price tags for several document kinds';
							|it = 'La stampa di etichette e cartellini dei prezzi per diversi tipi di documenti non è supportata.';
							|pl = 'Drukowanie etykiet i cenników dla kilku rodzajów dokumentów nie jest obsługiwane';
							|tr = 'Birden fazla belge türü için etiket ve fiyat etiketi yazdırma desteklenmiyor'");
		Raise MessageText;
	EndIf;
	
	If Id = "PriceTags" Then
		Return ObjectManager.DataForPrintingPriceTags(PrintObjects);	
	ElsIf Id = "Labels" Then
		Return ObjectManager.LabelPrintingData(PrintObjects);
	EndIf;
	
EndFunction

// Returns the data for label printing of storage cells
//
// Parameters:
//  Id	 - String - ID of the print command,
//  PrintObjects	- Array - an array of references Spravochnike.Storage cells.
// 
// Returns:
//   - String	-	the address of the structure in the temporary storage that contains the data to be printed.
//
Function LabelPrintingDataStorageCells(Id, PrintObjects) Export
	
	Query = New Query;
	Query.Text =
	"SELECT DISTINCT
	|	StorageBins.Owner AS Warehouse,
	|	StorageBins.Premise
	|FROM
	|	Catalog.StorageBins AS StorageBins
	|WHERE
	|	StorageBins.Ref IN(&Cells)";
	Query.SetParameter("Cells", PrintObjects);
	
	Selection = Query.Execute().Select();
	
	If Selection.Count() <> 1 Then
		ExceptionText = NStr("vi = 'Đã chọn ô trong các khu vực kho (nhà kho) khác nhau.
			|Chỉ có thể in đồng thời nhãn tem theo các ô hàng thuộc một khu vực kho (nhà kho).';
			|ru = 'Выделены ячейки разных складских территорий (помещений).
			|Одновременно можно печатать этикетки только по ячейкам, принадлежащим одной складской территории (помещению).';
			|en = 'You have selected bins of different warehouse areas (warerooms).
			|You can print labels simultaneously only for the bins that belong to the same warehouse area (wareroom).'; fa = 'You have selected bins of different warehouse areas (warerooms).
			|You can print labels simultaneously only for the bins that belong to the same warehouse area (wareroom).';
			|it = 'Selezionate celle di diversi territori di stoccaggio (spostamento).
			| Si possono stampare solamente le etichette delle celle di un singolo territorio di stoccaggio alla volta.';
			|pl = 'Zostały wyróżnione komórki różnych magazynowych obszarów (pomieszczeń).
			|Jednocześnie można drukować etykiety tylko dla komórek należących do jednego magazynowego obszaru(pomieszczenia).';
			|tr = 'Farklı ambar alanlarının (depoların) depo yerleri seçildi.
			|Sadece aynı ambar alanına (deposunda) ait depo yerleri aynı anda etiketlenebilir.'");
		Raise ExceptionText;
	EndIf;
	
	Selection.Next();
	
	Query = New Query;
	Query.Text =
	"SELECT DISTINCT
	|	StorageBins.Ref AS Cell
	|FROM
	|	Catalog.StorageBins AS StorageBins
	|WHERE
	|	StorageBins.Ref IN HIERARCHY(&Cells)
	|	AND NOT StorageBins.DeletionMark
	|	AND NOT StorageBins.IsFolder
	|
	|ORDER BY
	|	StorageBins.Code";
	
	Query.SetParameter("Cells", PrintObjects);
	
	CellTable = Query.Execute().Unload();
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("Warehouse", 	  Selection.Warehouse);
	ParametersStructure.Insert("Premise", Selection.Premise);
	ParametersStructure.Insert("Cells",    CellTable);
	
	Return PutToTempStorage(ParametersStructure);
	
EndFunction

#EndRegion

// Returns the data for label printing of storage cells
//
// Parameters:
//  ObjectsArray - Array - array of document links.
//  PrintParameters	- Structure - additional print options.
// 
Procedure DataForRecordingStatesOfOriginalsAfterPrintingPackage(ObjectsArray, PrintParameters) Export
	
	Var AddressOfSetOfPrintedForms;
	
	If TypeOf(PrintParameters) = Type("Structure") And PrintParameters.Property("AddressOfSetOfPrintedForms", AddressOfSetOfPrintedForms) Then
		
		PrintFormsSet = GetFromTempStorage(AddressOfSetOfPrintedForms);
		
	Else
		
		For Each DocumentRef In ObjectsArray Do
			TypeByRef = Common.TableNameByRef(DocumentRef);
			TypeByRef =  Metadata.FindByFullName(TypeByRef);
			
			PrintFormsSet = InformationRegisters.ObjectPrintSettings.PrintFormsSet(
				TypeByRef.FullName(),
				ObjectsArray, Undefined);
				
			PrintList = New ValueList;
			For Each Template In PrintFormsSet Do
				If Template.Print Then
					PrintList.Add(Template.Name, Template.Presentation);
				EndIf;
			EndDo;
			
			PrintObject = New ValueList;
			PrintObject.Add(DocumentRef);
			
			SourceDocumentsOriginalsRecordingServerCall.WriteOriginalsStatesAfterPrint(PrintObject,PrintList);
		EndDo;
				
	EndIf;

	
EndProcedure

#Region Inv3_Inv19

// Returns the structure of the parameters for generating PF INV3 and INV19. 
//
// Parameters:
//  ArrayOfRecalculations - 	Array - an array of references to the document "Conversion of goods".
// 
// Returns:
//  Structure - Structure of parameters with keys:
//		*Sheets - Array - an array of inventory inventories, the inventory period of which includes recalculations from the array of recalculations
//		*Warehouses - Array - an array of warehouses from recalculations An array of recalculations
//		*StartDate - Date - the minimum start date of the inventory period from all received inventories, 
//							if no inventories are found, then the minimum date from all recalculations
//		*EndDate - Date - the maximum date of the end of the inventory period from all received inventories, 
//							if no inventories are found, then the maximum date from all recalculations
//		*Companies - Array - array of organizations from the inventory list.
//
Function GetFormationParameters(ArrayOfRecalculations) Export
	
	Query = New Query;
	Query.SetParameter("ArrayOfRecalculations", ArrayOfRecalculations);
	Query.Text =
	"SELECT
	|	InventoryRecount.Ref AS Ref,
	|	BEGINOFPERIOD(InventoryRecount.Date, DAY) AS Date,
	|	InventoryRecount.Warehouse
	|INTO RecountsList
	|FROM
	|	Document.InventoryRecount AS InventoryRecount
	|WHERE
	|	InventoryRecount.Ref IN(&ArrayOfRecalculations)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED DISTINCT
	|	PhysicalCountReport.Ref,
	|	PhysicalCountReport.Organization,
	|	PhysicalCountReport.StartDate,
	|	PhysicalCountReport.EndDate,
	|	PhysicalCountReport.Warehouse
	|INTO SheetList
	|FROM
	|	Document.PhysicalCountReport AS PhysicalCountReport
	|		INNER JOIN RecountsList AS InventoryRecount
	|		ON (InventoryRecount.Warehouse = PhysicalCountReport.Warehouse)
	|			AND (InventoryRecount.Date BETWEEN PhysicalCountReport.StartDate AND PhysicalCountReport.EndDate)
	|WHERE
	|	PhysicalCountReport.Posted
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SheetList.Ref AS Ref
	|FROM
	|	SheetList AS SheetList
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	RecountsList.Warehouse
	|FROM
	|	RecountsList AS RecountsList
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MIN(SheetList.StartDate) AS StartDate,
	|	MAX(SheetList.EndDate) AS EndDate
	|FROM
	|	SheetList AS SheetList
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MIN(RecountsList.Date) AS StartDate,
	|	MAX(RecountsList.Date) AS EndDate
	|FROM
	|	RecountsList AS RecountsList
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	SheetList.Organization
	|FROM
	|	SheetList AS SheetList";
	Result = Query.ExecuteBatch(); 
	
	GenerationParameters = New Structure;
	GenerationParameters.Insert("Sheets", Result[2].Unload().UnloadColumn("Ref"));
	GenerationParameters.Insert("Warehouses", Result[3].Unload().UnloadColumn("Warehouse"));
	Selection = Result[4].Select();
	Selection.Next();
	GenerationParameters.Insert("StartDate", Selection.StartDate);
	GenerationParameters.Insert("EndDate", Selection.EndDate);
	If Not ValueIsFilled(GenerationParameters.StartDate) Then
		Selection = Result[5].Select();
		Selection.Next();
		GenerationParameters.Insert("StartDate", Selection.StartDate);
		GenerationParameters.Insert("EndDate", Selection.EndDate);
	EndIf;
	GenerationParameters.Insert("Companies", Result[6].Unload().UnloadColumn("Organization"));
	
	Return GenerationParameters;
	
EndFunction

#EndRegion

// Sorts the submitted array of reconciliation documents by Organization, Counterparty
//
// Parameters:
//	ObjectsArray - Array of DocumentRef.ARAPReconciliation2_4,DocumentRef.ARAPReconciliation2_5_11 - array of document links.
//
// Returns:
//	Array of DocumentRef.ARAPReconciliation2_4,DocumentRef.ARAPReconciliation2_5_11 - an array of documents sorted by Organization, Counterparty.
//
Function SortReconciliationDocuments(ObjectsArray) Export
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	ARAPReconciliation.Ref AS Ref,
	|	PRESENTATION(ARAPReconciliation.Organization) AS OrganizationPresentation,
	|	PRESENTATION(ARAPReconciliation.Counterparty) AS CounterpartyPresentation
	|FROM
	|	Document.ARAPReconciliation2_4 AS ARAPReconciliation
	|WHERE
	|	ARAPReconciliation.Ref IN(&Objects_To_Print)
	|
	|UNION ALL
	|
	|SELECT
	|	ARAPReconciliation2_5_11.Ref,
	|	PRESENTATION(ARAPReconciliation2_5_11.Organization),
	|	PRESENTATION(ARAPReconciliation2_5_11.Counterparty)
	|FROM
	|	Document.ARAPReconciliation2_5_11 AS ARAPReconciliation2_5_11
	|WHERE
	|	ARAPReconciliation2_5_11.Ref IN(&Objects_To_Print)";
	
	Query.SetParameter("Objects_To_Print", ObjectsArray);
	
	Result = ObjectsArray;
	Selection = Query.Execute().Unload();
	If Selection.Count() > 0 Then
		Selection.Sort("OrganizationPresentation,CounterpartyPresentation");
		Result = Selection.UnloadColumn("Ref");
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#Region Private

#Region LabelsAndPriceTags

// Data for printing shipping labels.
// 
// Parameters:
//  Id - String - 
//  PrintObjects - Array
// 
// Returns:
//  Structure - Shipping Label Printing Data:
// * DeliveryToOurWarehouse - Boolean -
// * ThereAreLabelsToPrint - Boolean -
// * AddressInStorage - String -
// * ArrayOfTasksWithoutOrders - Array -
Function ShippingLabelPrintingData(Id, PrintObjects) Export
	
	Return DataProcessors.PrintPriceTagsAndLabels.ShippingLabelPrintingData(PrintObjects);
	
EndFunction

// Label printing data packing lists.
// 
// Parameters:
//  PrintObjects - Array
// 
// Returns:
//  Structure - Label Printing Data Packing Sheets:
// * ThereIsLabelTemplate - Boolean -
Function LabelPrintingDataPackingSheets(PrintObjects) Export
	
	Return DataProcessors.PrintPriceTagsAndLabels.LabelPrintingDataPackingSheets(PrintObjects);
	
EndFunction


#EndRegion

Procedure OnExecutePrintCommand(Objects, CommandDetails) Export
	
	PrintManagement.OnExecutePrintCommand(Objects, CommandDetails);
	
EndProcedure

Function PreparePrintCommands(PrintObjects) Export
	
	MetadataOfPrintObject = PrintObjects[0].Metadata();
	
	PrintFormsSet = InformationRegisters.ObjectPrintSettings.PrintFormsSet(
		MetadataOfPrintObject.FullName(),
		PrintObjects, Undefined);
	
	RowFromCommandsTable = PrintManagement.CreatePrintCommandsCollection().Add();
	PrintCommandTemplate = Common.ValueTableRowToStructure(RowFromCommandsTable);
	
	Result = New Array();
	
	ObjectPrintCommands = PrintManagement.ObjectPrintCommands(MetadataOfPrintObject);
	
	For Each ObjectPrintingCommands In ObjectPrintCommands Do
		If ObjectPrintingCommands.PrintManager = "StandardSubsystems.AdditionalReportsAndDataProcessors" Then
			ExternalPrintFormsPrefix = "ExternalPrintForm.";
		Else
			ExternalPrintFormsPrefix = "";
		EndIf;
		
		Filter = New Structure("Name", ExternalPrintFormsPrefix + ObjectPrintingCommands.Id);
		FoundCommands = PrintFormsSet.FindRows(Filter);
		
		If FoundCommands.Count() And FoundCommands[0].Print Then
			KitIncludedCommand = CommonClientServer.CopyRecursive(PrintCommandTemplate);
			FillPropertyValues(KitIncludedCommand, ObjectPrintingCommands);
			
			If CommonClientServer.StructureProperty(ObjectPrintingCommands.AdditionalParameters, "PrintManager", "") <> "" Then
				KitIncludedCommand.PrintManager = ObjectPrintingCommands.AdditionalParameters.PrintManager;
			EndIf;
			
			IdentificatorAsKit = New Array;
			For Cnt = 1 To FoundCommands[0].Copies2 Do
				IdentificatorAsKit.Add(KitIncludedCommand.Id);
			EndDo;
			KitIncludedCommand.Id = StrConcat(IdentificatorAsKit, ",");
			
			Result.Add(KitIncludedCommand);
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

#EndRegion