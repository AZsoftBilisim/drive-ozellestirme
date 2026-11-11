#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Generates a report on the order document in a table document
//
// Parameters:
//	ReportTable - SpreadsheetDocument - Table document to display the report in
//	DocumentOrderNumber__1 - DocumentRef.PurchaseOrder - The "order to supplier" document for which the report is generated
//
Procedure GenerateReport(ReportTable, DocumentOrderNumber__1) Export
	
	PartnerOfOrderDocument = Common.ObjectAttributeValue(DocumentOrderNumber__1, "Partner");
	
	If Not ValueIsFilled(PartnerOfOrderDocument) Then
		
		MessageText = NStr("vi = 'Trong chứng từ ""%1"", chưa điền mục tin ""Bạn hàng""';
							|ru = 'В документе ""%1"" не заполнен реквизит ""Партнер""';
							|en = 'Attribute ""Partner"" attribute in document ""%1"" is not filled in.'; fa = 'Attribute ""Partner"" attribute in document ""%1"" is not filled in.';
							|it = 'Nel documento ""%1"" non viene soddisfatto il requisito ""Partner""';
							|pl = 'W dokumencie ""%1"" nie jest wypełniony atrybut ""Partner""';
							|tr = '""%1"" belgesinde ""İş ortağı"" özniteliği doldurulmadı'");
		Raise StringFunctionsClientServer.SubstituteParametersToString(MessageText, DocumentOrderNumber__1);
		
	EndIf;
	
	// We get the layout
	Template = PrintManagement.PrintFormTemplate("Report.AnalysisOfReasonsForPurchaseOrderCancellationAccordingToDocument.AnalysisOfCancellationReason");
	
	// Getting the layout areas
	HeaderArea = Template.GetArea("Header");
	HeaderLineArea = Template.GetArea("HeaderString");
	TableHeaderArea_ = Template.GetArea("TableHeader");
	ScopeOfCancellationReasonLine = Template.GetArea("CancellationReasonString");
	EmptyReportArea = Template.GetArea("EmptyReport");
	AreaAllOrders = Template.GetArea("AllOrders");
	TableBasementArea_ = Template.GetArea("TableFooter");
	TableBasementAreaIsEmpty = Template.GetArea("TableBasementIsEmpty");
	
	ArrayOfPositionAreas = New Array; // Array of SpreadsheetDocument
	ArrayOfPositionAreas.Add(Template.GetArea("PositionString"));
	ArrayOfPositionAreas.Add(Template.GetArea("LineItemGreaterThan10"));
	
	AreaOfPositionHasNoCancellations = Template.GetArea("LineItemNoCancellations");
	
	// Forming a request package
	Query = New Query;
	Query.SetParameter("PurchaseOrder", DocumentOrderNumber__1);
	Query.SetParameter("Partner", PartnerOfOrderDocument);
	GenerateRequestForOrderDocument(Query.Text);
	
	SetPrivilegedMode(True);
	ResultsPackage = Query.ExecuteBatch();
	
	// Calculating query indexes in a document package
	NumberOfRequestsPerBatch = ResultsPackage.Count();
	IndexOfDocumentAnalysisRequest = NumberOfRequestsPerBatch - 3;
	IndexOfCancellationReasonQueryForAllRows = NumberOfRequestsPerBatch - 2;
	ProductQueryIndex = NumberOfRequestsPerBatch - 1;
	
	// Fill in the header
	StructureOfHeaderParameters = New Structure();
	StructureOfHeaderParameters.Insert("SupplierName", PartnerOfOrderDocument);
	
	DisplayEmptyReportArea = False;
	
	QueryResult = ResultsPackage[IndexOfDocumentAnalysisRequest]; // QueryResult
	SelectionOfResultsForDocuments = QueryResult.Select();
	If SelectionOfResultsForDocuments.Next() Then
		
		If SelectionOfResultsForDocuments.OrdersCount = 0 Then
			
			DisplayEmptyReportArea = True;
			
		ElsIf SelectionOfResultsForDocuments.NumberOfOrderCancellations = 0 Then
			
			StructureOfHeaderParameters.Insert("OrdersCount", SelectionOfResultsForDocuments.OrdersCount);
			AreaAllOrders.Parameters.Fill(StructureOfHeaderParameters);
			ReportTable.Put(AreaAllOrders);
			Return;
			
		EndIf;
		
	Else // The result of the analysis for all documents is empty
		
		DisplayEmptyReportArea = True;
		
	EndIf;
	
	If DisplayEmptyReportArea Then
		EmptyReportArea.Parameters.Fill(StructureOfHeaderParameters);
		ReportTable.Put(EmptyReportArea);
		
		Return;
	EndIf;
	
	EmptyLinkReasonsForCancellation = PredefinedValue("Catalog.ReasonsForPurchaseOrderCancellation.EmptyRef");
	
	StructureOfHeaderParameters.Insert("NumberOfOrderCancellations", SelectionOfResultsForDocuments.NumberOfOrderCancellations);
	StructureOfHeaderParameters.Insert("OrdersCount", SelectionOfResultsForDocuments.OrdersCount);
	StructureOfHeaderParameters.Insert("PercentageOfOrderCancellations", GetPercentageInOutputFormat(StructureOfHeaderParameters.NumberOfOrderCancellations, StructureOfHeaderParameters.OrdersCount));
	
	QueryResult = ResultsPackage[IndexOfCancellationReasonQueryForAllRows]; // QueryResult
	SelectingTotalsForCancellationReasons = QueryResult.Select(QueryResultIteration.ByGroups);
	If SelectingTotalsForCancellationReasons.Next() Then
	
		StructureOfHeaderParameters.Insert("NumberOfCancellations", SelectingTotalsForCancellationReasons.NumberOfCancellations);
		StructureOfHeaderParameters.Insert("Count", SelectingTotalsForCancellationReasons.Count);
		StructureOfHeaderParameters.Insert("PercentageOfCancellations", GetPercentageInOutputFormat(StructureOfHeaderParameters.NumberOfCancellations, StructureOfHeaderParameters.Count));
		
		HeaderArea.Parameters.Fill(StructureOfHeaderParameters);
		ReportTable.Put(HeaderArea);
		
		// Fill in the lines in the header
		SelectionForCancellationReasons = SelectingTotalsForCancellationReasons.Select();
		
		StringParameterStructure = New Structure("CancellationReason, NumberOfCancellations, Count, PercentageOfCancellations");
		While SelectionForCancellationReasons.Next() Do
			
			If SelectionForCancellationReasons.CancellationReason = EmptyLinkReasonsForCancellation Then
				Continue;
			EndIf;
			FillPropertyValues(StringParameterStructure, SelectionForCancellationReasons);
			StringParameterStructure.Count = StructureOfHeaderParameters.Count;
			StringParameterStructure.PercentageOfCancellations = GetPercentageInOutputFormat(StringParameterStructure.NumberOfCancellations, StringParameterStructure.Count);
			
			HeaderLineArea.Parameters.Fill(StringParameterStructure);
			ReportTable.Put(HeaderLineArea);
		EndDo;
		
	EndIf;
	
	// Fill in the header of the tabular part
	ReportTable.Put(TableHeaderArea_);
	NumberOfValidLines = 0;
	TotalNumberOfRows = 0;
	
	// Fill in the rows of the table
	QueryResult = ResultsPackage[ProductQueryIndex]; // QueryResult
	SampleBasedOnGeneralResults = QueryResult.Select(QueryResultIteration.ByGroups);
	If Not SampleBasedOnGeneralResults.Next() Or SampleBasedOnGeneralResults.NumberOfCancellations = 0 Then
		
		ReportTable.Put(AreaOfPositionHasNoCancellations);
		
	Else
	
		SelectionByProductType_ = SampleBasedOnGeneralResults.Select(QueryResultIteration.ByGroups);
		While SelectionByProductType_.Next() Do
			
			SelectionByCharacteristics = SelectionByProductType_.Select(QueryResultIteration.ByGroups);
			While SelectionByCharacteristics.Next() Do
				
				TotalNumberOfRows = TotalNumberOfRows + 1;
				
				If SelectionByCharacteristics.NumberOfCancellations = 0 Then
					NumberOfValidLines = NumberOfValidLines + 1;
					Continue;
				EndIf;
				
				PositionStringStructure = New Structure;
				PositionStringStructure.Insert("ProductPresentation", ProductsClientServer.ProductPresentation(SelectionByProductType_.Products,
																																SelectionByCharacteristics.Characteristic));
				PositionStringStructure.Insert("NumberOfCancellations", SelectionByCharacteristics.NumberOfCancellations);
				PositionStringStructure.Insert("Count", SelectionByCharacteristics.Count);
				PositionStringStructure.Insert("PercentageOfCancellations", GetPercentageInOutputFormat(PositionStringStructure.NumberOfCancellations, PositionStringStructure.Count));
				
				AreaIndex = AreaIndexByPercentage(PositionStringStructure.NumberOfCancellations, PositionStringStructure.Count);
				PositionLineArea = ArrayOfPositionAreas[AreaIndex]; // SpreadsheetDocument
				PositionLineArea.Parameters.Fill(PositionStringStructure);
				ReportTable.Put(PositionLineArea);
				
				SelectionForCancellationReasons = SelectionByCharacteristics.Select();
				While SelectionForCancellationReasons.Next() Do
					
					If SelectionForCancellationReasons.CancellationReason = EmptyLinkReasonsForCancellation Then
						Continue;
					EndIf;
					
					StructureOfReasonString = New Structure;
					StructureOfReasonString.Insert("CancellationReason", SelectionForCancellationReasons.CancellationReason);
					StructureOfReasonString.Insert("NumberOfCancellations", SelectionForCancellationReasons.NumberOfCancellations);
					StructureOfReasonString.Insert("Count", PositionStringStructure.Count);
					StructureOfReasonString.Insert("PercentageOfCancellations", GetPercentageInOutputFormat(StructureOfReasonString.NumberOfCancellations, StructureOfReasonString.Count));
					
					ScopeOfCancellationReasonLine.Parameters.Fill(StructureOfReasonString);
					ReportTable.Put(ScopeOfCancellationReasonLine);
					
				EndDo;
				
			EndDo;
			
		EndDo;
		
	EndIf;
	
	// We fill in the basement of the table
	BasementParameterStructure = New Structure("Count, CommonCount", NumberOfValidLines, TotalNumberOfRows);
	
	If NumberOfValidLines = 0 Then
		ReportTable.Put(TableBasementAreaIsEmpty);
	Else
		ReportTable.Put(TableBasementArea_);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Function AreaIndexByPercentage(Count, CommonCount)
	
	Share = Count/CommonCount;
	
	If Share < 0.1 Then
		Return 0;
	Else
		Return 1;
	EndIf;
	
EndFunction

Function GetPercentageInOutputFormat(Count, CommonCount)
	
	Return Format((Count / CommonCount) * 100, "NFD=2; NZ=0");
	
EndFunction

Procedure GenerateRequestForOrderDocument(QueryText)
	
	QueryText = 
	"SELECT
	|	ReasonsForPurchaseOrderCancellation.Ref AS CancellationReason
	|INTO ReasonsForAnalysis
	|FROM
	|	Catalog.ReasonsForPurchaseOrderCancellation AS ReasonsForPurchaseOrderCancellation
	|WHERE
	|	ReasonsForPurchaseOrderCancellation.InitiatorOfPurchaseOrderCancellation = VALUE(Enum.InitiatorOfPurchaseOrderCancellation.Vendor)
	|
	|INDEX BY
	|	CancellationReason
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PurchaseOrderGoods.Products AS Products,
	|	PurchaseOrderGoods.Characteristic AS Characteristic,
	|	MIN(PurchaseOrderGoods.LineNumber) AS Order
	|INTO DocumentRows
	|FROM
	|	Document.PurchaseOrder.Goods AS PurchaseOrderGoods
	|WHERE
	|	PurchaseOrderGoods.Ref = &PurchaseOrder
	|
	|GROUP BY
	|	PurchaseOrderGoods.Products,
	|	PurchaseOrderGoods.Characteristic
	|
	|INDEX BY
	|	Products,
	|	Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PurchaseOrders.PurchaseOrder AS PurchaseOrder,
	|	PurchaseOrders.Products AS Products,
	|	PurchaseOrders.Characteristic AS Characteristic,
	|	PurchaseOrders.RowCode AS RowCode,
	|	MAX(ReasonsForAnalysis.CancellationReason) AS CancellationReason
	|INTO DataForAnalysis
	|FROM
	|	Document.PurchaseOrder AS DocumentsOrderToSupplier
	|		LEFT JOIN AccumulationRegister.PurchaseOrders AS PurchaseOrders
	|			LEFT JOIN ReasonsForAnalysis AS ReasonsForAnalysis
	|			ON PurchaseOrders.CancellationReason = ReasonsForAnalysis.CancellationReason
	|		ON (PurchaseOrders.PurchaseOrder = DocumentsOrderToSupplier.Ref)
	|WHERE
	|	DocumentsOrderToSupplier.Partner = &Partner
	|	AND DocumentsOrderToSupplier.Ref <> &PurchaseOrder
	|
	|GROUP BY
	|	PurchaseOrders.PurchaseOrder,
	|	PurchaseOrders.Products,
	|	PurchaseOrders.Characteristic,
	|	PurchaseOrders.RowCode
	|
	|INDEX BY
	|	PurchaseOrder,
	|	Products,
	|	Characteristic,
	|	CancellationReason
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DataForAnalysis.PurchaseOrder AS PurchaseOrder,
	|	MAX(DataForAnalysis.CancellationReason) AS CancellationReason
	|INTO DocumentsForAnalysis
	|FROM
	|	DataForAnalysis AS DataForAnalysis
	|
	|GROUP BY
	|	DataForAnalysis.PurchaseOrder
	|
	|INDEX BY
	|	PurchaseOrder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	COUNT(DISTINCT DocumentsForAnalysis.PurchaseOrder) AS OrdersCount,
	|	SUM(CASE
	|			WHEN DocumentsForAnalysis.CancellationReason IS NULL 
	|				THEN 0
	|			ELSE 1
	|		END) AS NumberOfOrderCancellations
	|FROM
	|	DocumentsForAnalysis AS DocumentsForAnalysis
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ISNULL(DataForAnalysis.CancellationReason, VALUE(Catalog.ReasonsForPurchaseOrderCancellation.EmptyRef)) AS CancellationReason,
	|	SUM(CASE
	|			WHEN DataForAnalysis.CancellationReason IS NULL 
	|				THEN 0
	|			ELSE 1
	|		END) AS NumberOfCancellations,
	|	SUM(1) AS Count
	|FROM
	|	DataForAnalysis AS DataForAnalysis
	|
	|GROUP BY
	|	ISNULL(DataForAnalysis.CancellationReason, VALUE(Catalog.ReasonsForPurchaseOrderCancellation.EmptyRef))
	|
	|ORDER BY
	|	NumberOfCancellations DESC
	|TOTALS BY
	|	OVERALL
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PRESENTATION(DataForAnalysis.Products) AS Products,
	|	PRESENTATION(DataForAnalysis.Characteristic) AS Characteristic,
	|	ISNULL(DataForAnalysis.CancellationReason, VALUE(Catalog.ReasonsForPurchaseOrderCancellation.EmptyRef)) AS CancellationReason,
	|	SUM(1) AS Count,
	|	SUM(CASE
	|			WHEN DataForAnalysis.CancellationReason IS NULL 
	|				THEN 0
	|			ELSE 1
	|		END) AS NumberOfCancellations,
	|	MIN(DocumentRows.Order) AS Order
	|FROM
	|	DocumentRows AS DocumentRows
	|		LEFT JOIN DataForAnalysis AS DataForAnalysis
	|		ON DocumentRows.Products = DataForAnalysis.Products
	|			AND DocumentRows.Characteristic = DataForAnalysis.Characteristic
	|WHERE
	|	DataForAnalysis.PurchaseOrder IN
	|			(SELECT
	|				DocumentsForAnalysis.PurchaseOrder
	|			FROM
	|				DocumentsForAnalysis
	|			GROUP BY
	|						DocumentsForAnalysis.PurchaseOrder)
	|
	|GROUP BY
	|	ISNULL(DataForAnalysis.CancellationReason, VALUE(Catalog.ReasonsForPurchaseOrderCancellation.EmptyRef)),
	|	PRESENTATION(DataForAnalysis.Products),
	|	PRESENTATION(DataForAnalysis.Characteristic)
	|
	|ORDER BY
	|	Order,
	|	NumberOfCancellations DESC
	|TOTALS
	|	COUNT(DISTINCT CancellationReason),
	|	SUM(Count),
	|	SUM(NumberOfCancellations),
	|	MIN(Order)
	|BY
	|	OVERALL,
	|	Products,
	|	Characteristic";

EndProcedure

#EndRegion

#EndIf