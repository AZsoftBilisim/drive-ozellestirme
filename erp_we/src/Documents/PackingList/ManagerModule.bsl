#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Names of the details that the parameters for specifying the series depend on
//
//	Returns:
//		String - the names of the details, separated by commas.
//
Function NamesOfDetailsForFillingInParametersForSpecifyingSeries() Export
	AttributesNames = "";
	
	Return AttributesNames;
EndFunction

// Returns parameters for specifying series for the products specified in the document.
//
// Parameters:
//  Object	 - Structure - the structure of the values of the details object required to populate the parameters specify the series.
// 
// Returns:
//  See ProductsClientServer.SeriesSpecificationParameters.
//
Function SeriesSpecificationParameters(Object) Export
	
	SeriesSpecificationParameters = ProductsClientServer.SeriesSpecificationParameters();
	SeriesSpecificationParameters.FullObjectName = "Document.PackingList";
	UseItemsBatch = GetFunctionalOption("UseItemsBatch");
	SeriesSpecificationParameters.UseItemsBatch  = UseItemsBatch;
	SeriesSpecificationParameters.UseCostAccountingByBatches = UseItemsBatch;
	SeriesSpecificationParameters.TSSeriesName = "Goods";
	SeriesSpecificationParameters.WarehouseFieldName = Undefined;
	
	SeriesSpecificationParameters.LinkFields.Add("Package");
	
	Return SeriesSpecificationParameters;
	
EndFunction

// Returns the request text for calculating the statuses for specifying series
//	Parameters:
//		SeriesSpecificationParameters - Structure - the structure of fields is specified in the function Nomenclaturales.Parametrizatsii
//	Returns:
//		String - query text.
//
Function TextOfRequestToFillInStatusesForSpecifyingSeries(SeriesSpecificationParameters) Export
	
	QueryText =
	"SELECT
	|	Goods.Products,
	|	Goods.Series,
	|	Goods.BatchesIndicationStatus,
	|	Goods.LineNumber
	|INTO Goods
	|FROM
	|	&Goods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber AS LineNumber,
	|	Goods.BatchesIndicationStatus AS OldStatusOfSpecifyingSeries,
	|	CASE
	|		WHEN ItemKinds.BatchUsageSettings = VALUE(Enum.ItemsBatchUsageSettings.EmptyRef)
	|			OR ItemKinds.BatchUsageSettings IS NULL
	|			THEN 0
	|		ELSE CASE
	|				WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|					THEN 2
	|				ELSE 11
	|			END
	|	END AS BatchesIndicationStatus
	|INTO StatusTable
	|FROM
	|	Goods AS Goods
	|		LEFT JOIN Catalog.ItemKinds AS ItemKinds
	|		ON (CAST(Goods.Products AS Catalog.Products).ProductKind = ItemKinds.Ref)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	StatusTable.LineNumber AS LineNumber,
	|	StatusTable.BatchesIndicationStatus AS BatchesIndicationStatus
	|FROM
	|	StatusTable AS StatusTable
	|WHERE
	|	StatusTable.OldStatusOfSpecifyingSeries <> StatusTable.BatchesIndicationStatus
	|
	|ORDER BY
	|	LineNumber";
	
	Return QueryText;

EndFunction

// The function returns an array with the data of the barcode
//
// Parameters:
//  Barcodes - Array, String - an array of lines with packing list codes, or a single code as a string.
//
// Returns:
//  	Array - an array of links of the Document Link type.Packing list.
//
Function ArrayOfLinksByArrayOfCodes(Barcodes) Export
	
	If Not GetFunctionalOption("UsePackingLists") Then
		Return New Array;
	EndIf;
	
	// You need to add filtering by the sender (source) of the packing list
	
	Query = New Query;
	
	Query.Text = 
	"SELECT
	|	PackingList.Ref AS Ref
	|FROM
	|	Document.PackingList AS PackingList
	|WHERE
	|	PackingList.Code IN(&ArrayOfBarcodes)";
	
	ArrayOfBarcodes = New Array;
	
	If TypeOf(Barcodes) = Type("Array") Then
		
		For Each CurBarcode In Barcodes Do
			Barcode = Upper(TrimAll(CurBarcode));
			ArrayOfBarcodes.Add(Barcode);
		EndDo;
		
	Else
		
		ArrayOfBarcodes.Add(Barcodes);
		
	EndIf;
	
	

	Query.SetParameter("ArrayOfBarcodes", ArrayOfBarcodes);

	Return Query.Execute().Unload().UnloadColumn("Ref");

EndFunction

// Complements the correspondence with the data of the item barcodes with the data of the packing lists.
//
// Parameters:
//	CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues.
//	Barcodes - Array of String - the processed barcode.
//
Procedure AddDataOnBarcodes(CachedValues, Barcodes) Export

	Query = New Query;
	
	Query.Text = 
	"SELECT
	|	MAX(PackingList.Ref) AS Ref,
	|	COUNT(*) AS Count,
	|	PackingList.Code AS Barcode
	|FROM
	|	Document.PackingList AS PackingList
	|WHERE
	|	PackingList.Code IN(&ArrayOfBarcodes)
	|	AND PackingList.Posted
	|
	|GROUP BY
	|	PackingList.Code";
	
	ArrayOfBarcodes = New Array;
	
	For Each CurBarcode In Barcodes Do
		Barcode = Upper(TrimAll(CurBarcode));
		ArrayOfBarcodes.Add(Barcode);
	EndDo;

	Query.SetParameter("ArrayOfBarcodes", ArrayOfBarcodes);

	Selection = Query.Execute().Select();
	While Selection.Next() Do
		curData = CachedValues.Barcodes[Upper(TrimAll(Selection.Barcode))];
		If curData.UnknownBarcode
			And Selection.Count = 1 Then
			curData.PackingList     = Selection.Ref;
			curData.UnknownBarcode = False;
		EndIf;
	EndDo;

EndProcedure

// The function creates a new completed document "Packing list" and returns a link to it.
//
// Parameters:
//	FillingData - Structure - structure for filling in the properties of the new document.
//
// Returns:
//	DocumentRef.PackingList - the link of the document "Packing list".
//
Function CreateHoldNew(FillingData = Undefined) Export
	
	DocObject = Documents.PackingList.CreateDocument();
	DocObject.Date = CurrentSessionDate();
	DocObject.Fill(FillingData);
	DocObject.Write(DocumentWriteMode.Posting);
	Return DocObject.Ref;
	
EndFunction

// Calculates the following packing list code
//
// Returns:
//	String - code of the packing list.
//
Function GetNewCode() Export
	
	CodeLengthWithoutPrefix = 9;
	
	Block = New DataLock;
	LockItem = Block.Add("Constant.CodeOfLastPackingList");
	LockItem.Mode = DataLockMode.Exclusive;
	Block.Lock();
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	PackingList.Code AS Code
	|FROM
	|	Document.PackingList AS PackingList
	|WHERE
	|	PackingList.Code LIKE &CodeTemplate
	|
	|ORDER BY
	|	PackingList.Code DESC";
		
	Prefix = TrimAll(Constants.DistributedInfobaseNodePrefix.Get());
	PrefixCode = "";
	If ValueIsFilled(Prefix) Then
		PrefixCode = StrReplace(String(CharCode(Upper(Right(Prefix,1)))), Chars.NBSp, "");
		PrefixCode = StringFunctionsClientServer.SupplementString(PrefixCode, 5);
		If StrLen(Prefix) > 1 Then
			PrefixCode =  StringFunctionsClientServer.SupplementString(
				StrReplace(String(CharCode(Upper(Left(Prefix,1)))), Chars.NBSp, ""), 5)
				+ PrefixCode;
		EndIf;
	EndIf;
	
	CodeTemplate = PrefixCode;
	For Account = 1 To CodeLengthWithoutPrefix Do
		CodeTemplate = CodeTemplate + "[0-9]";
	EndDo;
	
	Query.SetParameter("CodeTemplate", CodeTemplate);
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		Code = StringFunctionsClientServer.SupplementString(
			StrReplace(String(Number(Selection.Code)+1), Chars.NBSp,""),
			StrLen(PrefixCode) + CodeLengthWithoutPrefix);
	Else
		Code = PrefixCode + StringFunctionsClientServer.SupplementString("1", CodeLengthWithoutPrefix);
	EndIf;
	
	SetPrivilegedMode(True);
	Constants.CodeOfLastPackingList.Set(StrReplace(Code, Chars.NBSp, ""));
	SetPrivilegedMode(False);
	
	Return Code;
	
EndFunction

#Region InterfaceImplementation

// Standard subsystems.Versioning objects
// Defines object settings for the object Versioning subsystem.
//
// Parameters:
// Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export
EndProcedure
// End StandardSubsystems.ObjectsVersioning

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

#EndRegion

#EndIf

#Region EventHandlers

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	StandardProcessing = False;
	Fields.Add("Code");
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	StandardProcessing = False;
	Presentation = Metadata.Documents.PackingList.ObjectPresentation + " " + Data.Code;
	
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	
	
EndProcedure

// Adds the "Packing list" document creation command.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//  Undefined, ValueTableRow - Add a create command based on
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.PackingList) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.PackingList.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.PackingList);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UsePackingLists";

		Return CreateBasedOnCommand;
	EndIf;

	Return Undefined;
EndFunction

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
EndProcedure

#Region Print

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export

	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "PackingList";
	PrintCommand.Presentation = NStr("vi = 'Danh sách đóng gói';
									|ru = 'Упаковочный лист';
									|en = 'Packing list'; fa = 'فهرست بسته‌بندی';
									|it = 'Distinta di imballaggio';
									|pl = 'Specyfikacja ładunkowa';
									|tr = 'Ürün listesi'");
	PrintCommand.CheckPostingBeforePrint = True;
	
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "PackingListWithDecryption";
	PrintCommand.Presentation = NStr("vi = 'Phiếu đóng gói (có diễn giải thành phần)';
									|ru = 'Упаковочный лист (с расшифровкой состава)';
									|en = 'Packing list (detailed)'; fa = 'Packing list (detailed)';
									|it = 'Distinta di imballaggio (con decodifica della composizione)';
									|pl = 'Specyfikacja ładunkowa (z wyszczególnieniem zawartości)';
									|tr = 'Ürün listesi (içerik dökümüyle birlikte)'");
	PrintCommand.CheckPostingBeforePrint = True;

	PrintCommand = PrintCommands.Add();
	PrintCommand.Handler = "PrintManagementTMClient.PrintingLabelsPackingSheets";
	PrintCommand.PrintManager = "";
	PrintCommand.Id = "LabelPackingSheets";
	PrintCommand.Presentation = NStr("vi = 'Nhãn tem phiếu đóng gói';
									|ru = 'Этикетка упаковочного листа';
									|en = 'Packing list label'; fa = 'برچسب فهرست بسته‌بندی';
									|it = 'Etichetta della distinta di imballaggio';
									|pl = 'Etykieta specyfikacji ładunkowej';
									|tr = 'Ürün listesinin marka etiketleri'");
	PrintCommand.CheckPostingBeforePrint = True;
	
EndProcedure

Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export

	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "PackingList") Then

		PrintManagement.OutputSpreadsheetDocumentToCollection(PrintFormsCollection, "PackingList",
				NStr("vi = 'Danh sách đóng gói';
					|ru = 'Упаковочный лист';
					|en = 'Packing list'; fa = 'فهرست بسته‌بندی';
					|it = 'Distinta di imballaggio';
					|pl = 'Specyfikacja ładunkowa';
					|tr = 'Ürün listesi'"),
				PrintPackingList_(ObjectsArray, PrintObjects));
	ElsIf PrintManagement.TemplatePrintRequired(PrintFormsCollection, "PackingListWithDecryption") Then

		PrintManagement.OutputSpreadsheetDocumentToCollection(PrintFormsCollection, "PackingListWithDecryption",
				NStr("vi = 'Phiếu đóng gói (có diễn giải thành phần)';
					|ru = 'Упаковочный лист (с расшифровкой состава)';
					|en = 'Packing list (detailed)'; fa = 'Packing list (detailed)';
					|it = 'Distinta di imballaggio (con decodifica della composizione)';
					|pl = 'Specyfikacja ładunkowa (z wyszczególnieniem zawartości)';
					|tr = 'Ürün listesi (içerik dökümüyle birlikte)'"),
				PrintPackingListWithTranscript(ObjectsArray, PrintObjects));
	EndIf;
			
EndProcedure

Function PrintPackingList_(ObjectsArray, PrintObjects)
	
	ColumnOfCodes = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms();
	NameOfCodeColumn = ColumnOfCodes.ColumnName;
	PresentationOfCodesColumn = ColumnOfCodes.ColumnPresentation;
	OutputCodes = ValueIsFilled(ColumnOfCodes);
	
	DisplayingPackages = GetFunctionalOption("UseItemPackages");
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.PrintParametersName = "PackingList";
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	PackingList.Ref AS Ref,
	|	PRESENTATION(PackingList.Ref) AS Presentation,
	|	PackingList.Date AS Date,
	|	PackingList.Code AS Code,
	|	PackingList.Kind AS Kind,
	|	PRESENTATION(PackingList.PackageWarehouse) AS WarehousePresentation,
	|	PackingList.PackedBy.Individual AS Packer,
	|	PackingList.Basis AS Basis
	|FROM
	|	Document.PackingList AS PackingList
	|WHERE
	|	PackingList.Ref IN(&ObjectsArray)
	|
	|ORDER BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PackingListGoods.LineNumber AS LineNumber,
	|	PackingListGoods.ThisIsAPackingList AS ThisIsAPackingList,
	|	PackingListGoods.NumberOfPackages AS NumberOfPackages,
	|	PRESENTATION(PackingListGoods.PackingListParent) AS PackingListParent,
	|	PRESENTATION(PackingListGoods.PackingList) AS PackingList,
	|	PackingListGoods.Products.DescriptionFull AS ProductsPresentation,
	|	PackingListGoods.Characteristic.DescriptionFull AS CharacteristicPresentation,
	|	PackingListGoods.Series.Description AS SeriesPresentation,
	|	PRESENTATION(PackingListGoods.Package) AS PackagePresentation,
	|	PackingListGoods.Products.Code AS Code,
	|	PackingListGoods.Products.SKU AS SKU,
	|	PackingListGoods.Ref AS Ref,
	|	PRESENTATION(PackingListGoods.Products.UnitOfMeasure) AS PresentationOfBasicUnitOfMeasure,
	|	CASE
	|		WHEN PackingListGoods.Package <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN PRESENTATION(PackingListGoods.Package)
	|		ELSE PRESENTATION(PackingListGoods.Products.UnitOfMeasure)
	|	END AS PresentationOfPackingUnit,
	|	PackingListGoods.Count
	|FROM
	|	Document.PackingList.Goods AS PackingListGoods
	|WHERE
	|	PackingListGoods.Ref IN(&ObjectsArray)
	|	AND PackingListGoods.PackingListParent = VALUE(Document.PackingList.EmptyRef)
	|
	|ORDER BY
	|	Ref,
	|	LineNumber
	|TOTALS BY
	|	Ref";
	
	Query.SetParameter("ObjectsArray", ObjectsArray);
	
	ResultsArray = Query.ExecuteBatch();
	
	QueryResult = ResultsArray[0]; // QueryResult
	SelectionByDocuments = QueryResult.Select();
	
	QueryResult = ResultsArray[1]; // QueryResult
	SelectionByTableParts = QueryResult.Select(QueryResultIteration.ByGroups);
	
	DocumentAttributes = New Structure("Code, Date, Presentation");
	
	Template = PrintManagement.PrintFormTemplate("Document.PackingList.PF_MXL_PackingList");
	
	HeaderArea_ 		  = Template.GetArea("Title");
	AreaWarehousePacker     = Template.GetArea("WarehousePacker");
	ScopeOfApplication_2	 	  = Template.GetArea("Basis");
	
	TableHeaderAreaStart 					= Template.GetArea("TableHeader|BeginningOfTheLine");
	AreaTableRowProductStart 			= Template.GetArea("ProductTableRow|BeginningOfTheLine");
	AreaTableRowPackingListStart	= Template.GetArea("RowTablePackingList|BeginningOfTheLine");
	AreaBasementTableTop 					= Template.GetArea("TableFooter|BeginningOfTheLine");
	
	AreaTableHeaderCodeColumn 		= Template.GetArea("TableHeader|ColumnOfCodes");
	AreaTableRowItemCodeColumn 	= Template.GetArea("ProductTableRow|ColumnOfCodes");
	AreaTableRowPackingListCodeColumn = Template.GetArea("RowTablePackingList|ColumnOfCodes");
	AreaBasementTableColumnCodes 		= Template.GetArea("TableFooter|ColumnOfCodes");
	
	AreaTableHeaderCodeColumn.Parameters.NameOfCodeColumn = PresentationOfCodesColumn;
	
	ProductColumnArea_ = Template.Area("ProductColumn_");
	
	If Not OutputCodes Then
		ProductColumnArea_.ColumnWidth = ProductColumnArea_.ColumnWidth  + Template.Area("ColumnOfCodes").ColumnWidth;
	EndIf;
	
	If Not DisplayingPackages Then
		ProductColumnArea_.ColumnWidth = ProductColumnArea_.ColumnWidth + Template.Area("ColumnOfPackagesQuantity").ColumnWidth
				+ Template.Area("ColumnOfPackagesPresentation").ColumnWidth;
	EndIf;
	
	AreaTableHeaderProductColumn 	= Template.GetArea("TableHeader|ProductColumn_");
	AreaTableRowProductColumnProducts 	= Template.GetArea("ProductTableRow|ProductColumn_");
	AreaTableRowPackingListGoodsColumn 	= Template.GetArea("RowTablePackingList|ProductColumn_");
	AreaBasementTableGoodsColumn 	= Template.GetArea("TableFooter|ProductColumn_");
	
	TableHeaderAreaEnd 	= Template.GetArea("TableHeader|EndOfRow");
	AreaTableRowProductEnd 	= Template.GetArea("ProductTableRow|EndOfRow");
	AreaRowTablePackingListEnd 	= Template.GetArea("RowTablePackingList|EndOfRow");
	AreaBasementTableEnd 	= Template.GetArea("TableFooter|EndOfRow");
	
	If DisplayingPackages Then
		AreaTableHeaderPackingColumn = Template.GetArea("TableHeader|ColumnOfPackages");
		AreaTableRowProductPackagingColumn = Template.GetArea("ProductTableRow|ColumnOfPackages");
		AreaTableRowPackingListPackingColumn = Template.GetArea("RowTablePackingList|ColumnOfPackages");
		AreaBasementTablePackingColumn = Template.GetArea("TableFooter|ColumnOfPackages");
	EndIf;
	
	FirstDocument = True;
	
	While SelectionByDocuments.Next() Do
		
		If Not SelectionByTableParts.FindNext(New Structure("Ref",SelectionByDocuments.Ref)) Then
			MessageText = NStr("vi = 'Không thể in ""%Document%"", vì chưa điền phần bảng.';
								|ru = 'Невозможно напечатать ""%Document%"", т.к. не заполнена табличная часть.';
								|en = 'Cannot print ""%Document%"" because table is not filled in.'; fa = 'Cannot print ""%Document%"" because table is not filled in.';
								|it = 'Non è possibile stampare ""%Document%"", poiché la parte tabulare non è compilata.';
								|pl = 'Nie można wydrukować ""%Document%"", ponieważ nie jest wypełniona część tabelaryczna.';
								|tr = 'Tablo kısmı doldurulmadığı için ""%Document%"" yazdırılamıyor.'");
			MessageText = StrReplace(MessageText,"%Document%", SelectionByDocuments.Presentation);
			CommonClientServer.MessageToUser(MessageText);
			Continue;
		EndIf;
			
		SamplingByTSLines = SelectionByTableParts.Select(QueryResultIteration.ByGroups);
		
		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
		FirstDocument = False;
		RowNumberStart = SpreadsheetDocument.TableHeight + 1;
		
		TitleText = SelectionByDocuments.Presentation;
		OutputWarehouseAndPacker = True;
		If SelectionByDocuments.Kind = Enums.PackingListKinds.Incoming Then
			TitleText = TitleText  + " " + NStr("vi = '(đầu vào)';
												|ru = '(входящий)';
												|en = '(incoming)'; fa = '(incoming)';
												|it = '(in entrata)';
												|pl = '(przychodząca)';
												|tr = '(gelen)'", Common.DefaultLanguageCode());
			OutputWarehouseAndPacker = False;
		ElsIf SelectionByDocuments.Kind = Enums.PackingListKinds.Outgoing Then
			TitleText = TitleText + " " + NStr("vi = '(đầu ra)';
												|ru = '(исходящий)';
												|en = '(outbound)'; fa = '(outbound)';
												|it = '(in uscita)';
												|pl = '(wychodząca)';
												|tr = '(giden)'", Common.DefaultLanguageCode());
		EndIf;
		HeaderArea_.Parameters.TitleText = TitleText;
		
		FillPropertyValues(DocumentAttributes, SelectionByDocuments);
		
		BarcodingOfPrintForms.OutputBarcodeToTabularDocument(SpreadsheetDocument, Template, HeaderArea_, SelectionByDocuments.Ref);
		SpreadsheetDocument.Put(HeaderArea_);
		
		ScopeOfApplication_2.Parameters.BasisPresentation = SelectionByDocuments.Basis;
		SpreadsheetDocument.Put(ScopeOfApplication_2);
		
		SpreadsheetDocument.Put(TableHeaderAreaStart);
		If OutputCodes Then
			SpreadsheetDocument.Join(AreaTableHeaderCodeColumn);
		EndIf;
		SpreadsheetDocument.Join(AreaTableHeaderProductColumn);
		If DisplayingPackages Then
			SpreadsheetDocument.Join(AreaTableHeaderPackingColumn);
		EndIf;
		SpreadsheetDocument.Join(TableHeaderAreaEnd);
		
		LineNumber = 0;
		While SamplingByTSLines.Next() Do
			LineNumber = LineNumber + 1;
			
			If SamplingByTSLines.ThisIsAPackingList Then
				AreaTableRowStart = AreaTableRowPackingListStart;
				AreaRowColumnCodes = AreaTableRowPackingListCodeColumn;
				AreaTableRowProductColumn = AreaTableRowPackingListGoodsColumn;
				AreaTableRowProductColumn.Parameters.PackingList = SamplingByTSLines.PackingList;
				If OutputCodes Then
					AreaTableRowCodeColumn = AreaTableRowPackingListCodeColumn;
				EndIf;
				If DisplayingPackages Then
					AreaTableRowPackingColumn = AreaTableRowPackingListPackingColumn;
				EndIf;
				AreaTableRowEnd = AreaRowTablePackingListEnd;
			Else
				AdditionalParametersProductPresentation = ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
				AdditionalParametersProductPresentation.DefaultLanguageCode = Common.DefaultLanguageCode();
	
				AreaTableRowStart = AreaTableRowProductStart;
				AreaTableRowCodeColumn = AreaTableRowItemCodeColumn;
				AreaTableRowProductColumn = AreaTableRowProductColumnProducts;
				AreaTableRowProductColumn.Parameters.OwnGoods = ProductsClientServer.PresentationOfProductsForPrinting(
					SamplingByTSLines.ProductsPresentation,
					SamplingByTSLines.CharacteristicPresentation,
					, // Package
					SamplingByTSLines.SeriesPresentation,
					AdditionalParametersProductPresentation);
				If OutputCodes Then
					AreaTableRowCodeColumn = AreaTableRowItemCodeColumn;
				EndIf;
				If DisplayingPackages Then
					AreaTableRowPackingColumn = AreaTableRowProductPackagingColumn;
				EndIf;
				AreaTableRowEnd = AreaTableRowProductEnd;
			EndIf;
			
			AreaTableRowStart.Parameters.Fill(SamplingByTSLines);
			AreaTableRowStart.Parameters.LineNumber = LineNumber;
			SpreadsheetDocument.Put(AreaTableRowStart);
			
			If OutputCodes Then
				AreaTableRowCodeColumn.Parameters.SKU = SamplingByTSLines[NameOfCodeColumn];
				SpreadsheetDocument.Join(AreaTableRowCodeColumn);
			EndIf;
				
			SpreadsheetDocument.Join(AreaTableRowProductColumn);
			
			If DisplayingPackages Then
				AreaTableRowPackingColumn.Parameters.Fill(SamplingByTSLines);
				SpreadsheetDocument.Join(AreaTableRowPackingColumn);
			EndIf;
			
			AreaTableRowEnd.Parameters.Fill(SamplingByTSLines);
			SpreadsheetDocument.Join(AreaTableRowEnd);
			
		EndDo;
		
		SpreadsheetDocument.Put(AreaBasementTableTop);
		If OutputCodes Then
			SpreadsheetDocument.Join(AreaBasementTableColumnCodes);
		EndIf;
		SpreadsheetDocument.Join(AreaBasementTableGoodsColumn);
		If DisplayingPackages Then
			SpreadsheetDocument.Join(AreaBasementTablePackingColumn);
		EndIf;
		SpreadsheetDocument.Join(AreaBasementTableEnd);
		
		If OutputWarehouseAndPacker Then
			AreaWarehousePacker.Parameters.PackerPresentation = PersonsTM.IndividualShortName(SelectionByDocuments.Packer, SelectionByDocuments.Date);
			AreaWarehousePacker.Parameters.WarehousePresentation = WarehousesServer.GetWarehousePresentation(SelectionByDocuments.WarehousePresentation);
			SpreadsheetDocument.Put(AreaWarehousePacker);
		EndIf;
		
		PrintManagement.SetDocumentPrintArea(SpreadsheetDocument, RowNumberStart, PrintObjects, SelectionByDocuments.Ref);
	EndDo;
	
	SpreadsheetDocument.FitToPage = True;
	
	Return SpreadsheetDocument;
	
EndFunction

Function PrintPackingListWithTranscript(ObjectsArray, PrintObjects)
	
	ColumnOfCodes = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms();
	NameOfCodeColumn = ColumnOfCodes.ColumnName;
	PresentationOfCodesColumn = ColumnOfCodes.ColumnPresentation;
	OutputCodes = ValueIsFilled(NameOfCodeColumn);
	
	DisplayingPackages = GetFunctionalOption("UseItemPackages");
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.PrintParametersName = "PackingList";
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	PackingListGoods.Ref,
	|	TRUE AS ThereIsNestingOfPackingSheets
	|INTO ComplexPackingLists
	|FROM
	|	Document.PackingList.Goods AS PackingListGoods
	|WHERE
	|	PackingListGoods.ThisIsAPackingList
	|	AND PackingListGoods.PackingListParent <> VALUE(Document.PackingList.EmptyRef)
	|	AND PackingListGoods.Ref IN(&ObjectsArray)
	|
	|GROUP BY
	|	PackingListGoods.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PackingList.Ref AS Ref,
	|	PRESENTATION(PackingList.Ref) AS Presentation,
	|	PackingList.Date AS Date,
	|	PackingList.Code AS Code,
	|	PackingList.Kind AS Kind,
	|	PRESENTATION(PackingList.PackageWarehouse) AS WarehousePresentation,
	|	PackingList.PackedBy.Individual AS Packer,
	|	PackingList.Basis AS Basis,
	|	ISNULL(ComplexPackingLists.ThereIsNestingOfPackingSheets, FALSE) AS ThereIsNestingOfPackingSheets
	|FROM
	|	Document.PackingList AS PackingList
	|		LEFT JOIN ComplexPackingLists AS ComplexPackingLists
	|		ON PackingList.Ref = ComplexPackingLists.Ref
	|WHERE
	|	PackingList.Ref IN(&ObjectsArray)
	|
	|ORDER BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PackingListGoods.LineNumber AS LineNumber,
	|	PackingListGoods.ThisIsAPackingList AS ThisIsAPackingList,
	|	PackingListGoods.NumberOfPackages AS NumberOfPackages,
	|	PackingListGoods.PackingListParent.Code AS PackingListParentCode,
	|	PackingListGoods.PackingListParent.Date AS PackingListParentDate,
	|	ISNULL(PackingListGoods.Products.DescriptionFull, """") AS ProductsPresentation,
	|	ISNULL(PackingListGoods.Characteristic.DescriptionFull, """") AS CharacteristicPresentation,
	|	ISNULL(PackingListGoods.Series.Description, """") AS SeriesPresentation,
	|	PRESENTATION(PackingListGoods.Package) AS PackagePresentation,
	|	PackingListGoods.Products.Code AS Code,
	|	PackingListGoods.Products.SKU AS SKU,
	|	PackingListGoods.Ref AS Ref,
	|	PRESENTATION(PackingListGoods.Products.UnitOfMeasure) AS PresentationOfBasicUnitOfMeasure,
	|	CASE
	|		WHEN PackingListGoods.Package <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN PRESENTATION(PackingListGoods.Package)
	|		ELSE PRESENTATION(PackingListGoods.Products.UnitOfMeasure)
	|	END AS PresentationOfPackingUnit,
	|	PackingListGoods.Count
	|FROM
	|	Document.PackingList.Goods AS PackingListGoods
	|WHERE
	|	PackingListGoods.Ref IN(&ObjectsArray)
	|	AND NOT PackingListGoods.ThisIsAPackingList
	|
	|ORDER BY
	|	Ref,
	|	PackingListParentCode,
	|	LineNumber
	|TOTALS BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CASE
	|		WHEN PackingListGoods.PackingListParent = VALUE(Document.PackingList.EmptyRef)
	|			THEN PackingListGoods.Ref
	|		ELSE PackingListGoods.PackingListParent
	|	END AS PackingListParent,
	|	PackingListGoods.PackingList AS PackingList,
	|	PackingListGoods.Ref AS Ref,
	|	PackingListGoods.PackingList.Date AS Date,
	|	PackingListGoods.PackingList.Code AS Code
	|FROM
	|	Document.PackingList.Goods AS PackingListGoods
	|WHERE
	|	PackingListGoods.Ref IN(&ObjectsArray)
	|	AND PackingListGoods.ThisIsAPackingList";
	
	Query.SetParameter("ObjectsArray", ObjectsArray);
	
	ResultsArray = Query.ExecuteBatch();
	
	QueryResult = ResultsArray[1]; // QueryResult
	SelectionByDocuments = QueryResult.Select();
	
	QueryResult = ResultsArray[2]; // QueryResult
	SelectionByTableParts = QueryResult.Select(QueryResultIteration.ByGroups);
	
	QueryResult = ResultsArray[3]; // QueryResult
	PackingListsForDocuments = QueryResult.Unload();
	
	DocumentAttributes = New Structure("Code, Date, Presentation");
	
	Template = PrintManagement.PrintFormTemplate("Document.PackingList.PF_MXL_PackingList");
	DisplayPackingLists = GetFunctionalOption("UsePackingLists");

	HeaderArea_ 		  = Template.GetArea("Title");
	AreaWarehousePacker     = Template.GetArea("WarehousePacker");
	ScopeOfApplication_2	 	  = Template.GetArea("Basis");
	
	TableHeaderAreaStart 					= Template.GetArea("TableHeader|BeginningOfTheLine");
	AreaTableRowProductStart 			= Template.GetArea("ProductTableRow|BeginningOfTheLine");
	AreaTableRowPackingListStart	= Template.GetArea("RowTablePackingList|BeginningOfTheLine");
	AreaBasementTableTop 					= Template.GetArea("TableFooter|BeginningOfTheLine");
	
	AreaTableHeaderPackingListParent					= Template.GetArea("TableHeader|PackingListParent");
	AreaTableRowProductPackingListParent 			= Template.GetArea("ProductTableRow|PackingListParent");
	AreaTableRowPackingListPackingListParent 	= Template.GetArea("RowTablePackingList|PackingListParent");
	AreaBasementTablePackingListParent 				= Template.GetArea("TableFooter|PackingListParent");
	
	AreaTableHeaderCodeColumn 		= Template.GetArea("TableHeader|ColumnOfCodes");
	AreaTableRowItemCodeColumn 	= Template.GetArea("ProductTableRow|ColumnOfCodes");
	AreaTableRowPackingListCodeColumn = Template.GetArea("RowTablePackingList|ColumnOfCodes");
	AreaBasementTableColumnCodes 		= Template.GetArea("TableFooter|ColumnOfCodes");
			
	AreaTableHeaderCodeColumn.Parameters.NameOfCodeColumn = PresentationOfCodesColumn;
	
	ProductColumnArea_ = Template.Area("ProductColumn_");
	
	If Not DisplayPackingLists Then
		ProductColumnArea_.ColumnWidth = ProductColumnArea_.ColumnWidth + Template.Area("PackingListParent").ColumnWidth;
	EndIf;
			
	If Not OutputCodes Then	
		ProductColumnArea_.ColumnWidth = ProductColumnArea_.ColumnWidth  + Template.Area("ColumnOfCodes").ColumnWidth;
	EndIf;
	
	If Not DisplayingPackages Then
		ProductColumnArea_.ColumnWidth = ProductColumnArea_.ColumnWidth + Template.Area("ColumnOfPackagesQuantity").ColumnWidth
				+ Template.Area("ColumnOfPackagesPresentation").ColumnWidth;
	EndIf;
	
	AreaTableHeaderProductColumn 					= Template.GetArea("TableHeader|ProductColumn_");
	AreaTableRowProductColumnProducts 			= Template.GetArea("ProductTableRow|ProductColumn_");
	AreaTableRowPackingListGoodsColumn 	= Template.GetArea("RowTablePackingList|ProductColumn_");
	AreaBasementTableGoodsColumn 					= Template.GetArea("TableFooter|ProductColumn_");
	
	If DisplayingPackages Then
		AreaTableHeaderPackingColumn 					= Template.GetArea("TableHeader|ColumnOfPackages");
		AreaTableRowProductPackagingColumn 			= Template.GetArea("ProductTableRow|ColumnOfPackages");
		AreaTableRowPackingListPackingColumn	= Template.GetArea("RowTablePackingList|ColumnOfPackages");
		AreaBasementTablePackingColumn 				= Template.GetArea("TableFooter|ColumnOfPackages");
	EndIf;
	
	TableHeaderAreaEnd 					= Template.GetArea("TableHeader|EndOfRow");
	AreaTableRowProductEnd 				= Template.GetArea("ProductTableRow|EndOfRow");
	AreaRowTablePackingListEnd 	= Template.GetArea("RowTablePackingList|EndOfRow");
	AreaBasementTableEnd 					= Template.GetArea("TableFooter|EndOfRow");

	AreaHeaderTablesPackingLists 	= Template.GetArea("HeaderTablesPackingLists");  
	AreaRowTablePackingLists 	= Template.GetArea("RowTablePackingLists");
	AreaBasementTablePackingLists 	= Template.GetArea("BasementTablesPackingLists");
	FirstDocument = True;
	
	While SelectionByDocuments.Next() Do
			
		If Not SelectionByTableParts.FindNext(New Structure("Ref",SelectionByDocuments.Ref)) Then
			MessageText = NStr("vi = 'Không thể in ""%Document%"", vì chưa điền phần bảng.';
								|ru = 'Невозможно напечатать ""%Document%"", т.к. не заполнена табличная часть.';
								|en = 'Cannot print ""%Document%"" because table is not filled in.'; fa = 'Cannot print ""%Document%"" because table is not filled in.';
								|it = 'Non è possibile stampare ""%Document%"", poiché la parte tabulare non è compilata.';
								|pl = 'Nie można wydrukować ""%Document%"", ponieważ nie jest wypełniona część tabelaryczna.';
								|tr = 'Tablo kısmı doldurulmadığı için ""%Document%"" yazdırılamıyor.'");
			MessageText = StrReplace(MessageText,"%Document%", SelectionByDocuments.Presentation);
			CommonClientServer.MessageToUser(MessageText);
			Continue;
		EndIf;
		
		SamplingByTSLines = SelectionByTableParts.Select(QueryResultIteration.ByGroups);
		
		PackingSheetsOfDocument = PackingListsForDocuments.Copy(New Structure("Ref",SelectionByDocuments.Ref));
		
		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
		FirstDocument = False;
		RowNumberStart = SpreadsheetDocument.TableHeight + 1;
		
		OutputWarehouseAndPacker = True;
		If SelectionByDocuments.Kind = Enums.PackingListKinds.Incoming Then
			
			TitleText = NStr("vi = 'Phiếu đóng gói (đầu vào)';
							|ru = 'Упаковочный лист (входящий)';
							|en = 'Packing list (incoming)'; fa = 'Packing list (incoming)';
							|it = 'Distinta di imballaggio (in entrata)';
							|pl = 'Specyfikacja ładunkowa (przychodząca)';
							|tr = 'Ürün listesi (gelen)'", Common.DefaultLanguageCode());
			OutputWarehouseAndPacker = False;
			
		ElsIf SelectionByDocuments.Kind = Enums.PackingListKinds.Outgoing Then
			
			TitleText = NStr("vi = 'Phiếu đóng gói (đầu ra)';
							|ru = 'Упаковочный лист (исходящий)';
							|en = 'Packing list (outbound)'; fa = 'Packing list (outbound)';
							|it = 'Distinta di imballaggio (in uscita)';
							|pl = 'Specyfikacja ładunkowa (wychodząca)';
							|tr = 'Ürün listesi (giden)'", Common.DefaultLanguageCode());
			
		EndIf;
		
		FillPropertyValues(DocumentAttributes, SelectionByDocuments);
		
		HeaderArea_.Parameters.TitleText = SelectionByDocuments.Presentation;
		
		BarcodingOfPrintForms.OutputBarcodeToTabularDocument(SpreadsheetDocument, Template, HeaderArea_, SelectionByDocuments.Ref);
		SpreadsheetDocument.Put(HeaderArea_);
		
		ScopeOfApplication_2.Parameters.BasisPresentation = SelectionByDocuments.Basis;
		SpreadsheetDocument.Put(ScopeOfApplication_2);
		
		SpreadsheetDocument.Put(TableHeaderAreaStart);
		
		SpreadsheetDocument.Join(AreaTableHeaderPackingListParent);
		
		If OutputCodes Then
			SpreadsheetDocument.Join(AreaTableHeaderCodeColumn);
		EndIf;
		SpreadsheetDocument.Join(AreaTableHeaderProductColumn);
		If DisplayingPackages Then
			SpreadsheetDocument.Join(AreaTableHeaderPackingColumn);
		EndIf;
		SpreadsheetDocument.Join(TableHeaderAreaEnd);
		
		LineNumber = 0;
		While SamplingByTSLines.Next() Do
			LineNumber = LineNumber + 1;
			If SamplingByTSLines.ThisIsAPackingList Then
				AreaTableRowStart = AreaTableRowPackingListStart;
				ScopeRowPackingListParent = AreaTableRowPackingListPackingListParent;
				AreaRowColumnCodes = AreaTableRowPackingListCodeColumn;
				AreaTableRowProductColumn = AreaTableRowPackingListGoodsColumn;
				If OutputCodes Then
					AreaTableRowCodeColumn = AreaTableRowPackingListCodeColumn;
				EndIf;
				If DisplayingPackages Then
					AreaTableRowPackingColumn = AreaTableRowPackingListPackingColumn;
				EndIf;
				AreaTableRowEnd = AreaRowTablePackingListEnd;
			Else
				AreaTableRowStart = AreaTableRowProductStart;
				ScopeRowPackingListParent = AreaTableRowProductPackingListParent;
				AreaTableRowCodeColumn = AreaTableRowItemCodeColumn;
				AreaTableRowProductColumn = AreaTableRowProductColumnProducts;
				If OutputCodes Then
					AreaTableRowCodeColumn = AreaTableRowItemCodeColumn;
				EndIf;
				If DisplayingPackages Then
					AreaTableRowPackingColumn = AreaTableRowProductPackagingColumn;
				EndIf;
				AreaTableRowEnd = AreaTableRowProductEnd;
			EndIf;
			
			AreaTableRowStart.Parameters.LineNumber = LineNumber;
			SpreadsheetDocument.Put(AreaTableRowStart);
			
			If DisplayPackingLists Then
				ScopeRowPackingListParent.Parameters.PackingListParent = SamplingByTSLines.PackingListParentCode; 
				SpreadsheetDocument.Join(ScopeRowPackingListParent);
			EndIf;
			
			If OutputCodes Then
				AreaTableRowCodeColumn.Parameters.SKU = SamplingByTSLines[NameOfCodeColumn];
				SpreadsheetDocument.Join(AreaTableRowCodeColumn);
			EndIf;
				
			AdditionalParametersProductPresentation = ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
			AdditionalParametersProductPresentation.DefaultLanguageCode = Common.DefaultLanguageCode();
				
			AreaTableRowProductColumn.Parameters.OwnGoods = ProductsClientServer.PresentationOfProductsForPrinting(
				SamplingByTSLines.ProductsPresentation,
				SamplingByTSLines.CharacteristicPresentation,
				, // Package
				SamplingByTSLines.SeriesPresentation,
				AdditionalParametersProductPresentation);
			
			SpreadsheetDocument.Join(AreaTableRowProductColumn);
			
			If DisplayingPackages Then
				AreaTableRowPackingColumn.Parameters.Fill(SamplingByTSLines);
				SpreadsheetDocument.Join(AreaTableRowPackingColumn);
			EndIf;
			
			AreaTableRowEnd.Parameters.Fill(SamplingByTSLines);
			SpreadsheetDocument.Join(AreaTableRowEnd);
			
		EndDo;
		
		SpreadsheetDocument.Put(AreaBasementTableTop);
		If DisplayPackingLists Then
			SpreadsheetDocument.Join(AreaBasementTablePackingListParent);
		EndIf;	
		If OutputCodes Then
			SpreadsheetDocument.Join(AreaBasementTableColumnCodes);
		EndIf;
		SpreadsheetDocument.Join(AreaBasementTableGoodsColumn);
		If DisplayingPackages Then
			SpreadsheetDocument.Join(AreaBasementTablePackingColumn);
		EndIf;
		SpreadsheetDocument.Join(AreaBasementTableEnd);
		
		If OutputWarehouseAndPacker Then
			
			AreaWarehousePacker.Parameters.PackerPresentation	= PersonsTM.IndividualShortName(SelectionByDocuments.Packer, SelectionByDocuments.Date);
			AreaWarehousePacker.Parameters.WarehousePresentation		= WarehousesServer.GetWarehousePresentation(SelectionByDocuments.WarehousePresentation);
			
			SpreadsheetDocument.Put(AreaWarehousePacker);
			
		EndIf;
		
		If SelectionByDocuments.ThereIsNestingOfPackingSheets Then
			
			SpreadsheetDocument.Put(AreaHeaderTablesPackingLists);
			
			RecursivelyDerivePackingListHierarchy(SpreadsheetDocument, AreaRowTablePackingLists, PackingSheetsOfDocument, SelectionByDocuments.Ref);
			
			SpreadsheetDocument.Put(AreaBasementTablePackingLists);
			
		EndIf;
		
		PrintManagement.SetDocumentPrintArea(SpreadsheetDocument, RowNumberStart, PrintObjects, SelectionByDocuments.Ref);
	EndDo;
	
	SpreadsheetDocument.FitToPage = True;
	
	Return SpreadsheetDocument;
	
EndFunction

Procedure RecursivelyDerivePackingListHierarchy(SpreadsheetDocument, AreaRowTablePackingLists, PackingSheetsOfDocument, PackingListParent, Level = 0) Export
	
	If Level = 0 Then
		Indent = "";
	Else
		Indent = "└";
	EndIf;
	
	For Account=1 To Level Do
		Indent = Chars.NBSp + Chars.NBSp + Indent;
	EndDo;	
	
	Level = Level + 1;
	
	FoundRows = PackingSheetsOfDocument.FindRows(New Structure("PackingListParent", PackingListParent));
	
	For Each String In FoundRows Do
		
		PresentationOfPackingList = NStr("vi = '%Indent% %PackingList% ngày %Date%';
										|ru = '%Indent% %PackingList% от %Date%';
										|en = '%Indent% %PackingList% from %Date%'; fa = '%Indent% %PackingList% from %Date%';
										|it = '%Indent%%PackingList% da %Date%';
										|pl = '%Indent% %PackingList% z dnia %Date%';
										|tr = '%Date% tarihli %Indent% %PackingList%'", Common.DefaultLanguageCode());
		PresentationOfPackingList = StrReplace(PresentationOfPackingList, "%PackingList%", String.Code);
		PresentationOfPackingList = StrReplace(PresentationOfPackingList, "%Date%", String.Date);
		PresentationOfPackingList = StrReplace(PresentationOfPackingList, "%Indent%", Indent);

		AreaRowTablePackingLists.Parameters.PackingList = PresentationOfPackingList;
		SpreadsheetDocument.Put(AreaRowTablePackingLists);

		RecursivelyDerivePackingListHierarchy(SpreadsheetDocument, AreaRowTablePackingLists, PackingSheetsOfDocument, String.PackingList, Level);
		
	EndDo;
	
EndProcedure
	
#EndRegion

#EndRegion

#EndIf