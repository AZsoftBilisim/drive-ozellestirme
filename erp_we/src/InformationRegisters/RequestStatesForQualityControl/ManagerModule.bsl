#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

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
	
	Parameters.IndependentRegisters.Add(Metadata.InformationRegisters.RequestStatesForQualityControl);
	
	Return Parameters;
	
EndFunction

// The procedure for the formation of Registered Records by subordinate registers.
//
// Parameters:
//   TablesForRegisteredRecords - Structure - document data tables
//   RegisterRecords - RegisterRecordsCollection - collection of document movement record sets
//   Cancel - Boolean - indicates that the document was rejected.
//
Procedure ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, Cancel) Export
	
EndProcedure

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

// The procedure of formation of movements on the register.
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
	
	StateTableOfQualityControlApplications = Undefined;
	If Not TablesForRegisteredRecords.Property("Table" + "RequestStatesForQualityControl", StateTableOfQualityControlApplications) Then
		Return;
	EndIf;
	
	If StateTableOfQualityControlApplications.Count() = 0 Then
		Return;
	EndIf;
	
	Lot = StateTableOfQualityControlApplications[0].Lot;
	If Not TypeOf(Lot) = Type("DocumentRef.RequestForGoodsQualityControl") Then
		Return;
	EndIf;
	
	Query = New Query();
	
	QueryTexts = New ValueList();
	QueryTexts.Add(AnalyticsTempTable(),                        "");
	
	TableOfGoodsInWarehouses = Undefined;
	If Not TablesForRegisteredRecords.Property("Table" + "ProductStock", TableOfGoodsInWarehouses) Then
		QueryTexts.Add(TempTableBalancesOnControl(), "");
	Else
		If TableOfGoodsInWarehouses.Count() > 0 Then
			QueryTexts.Add(TempTableOfGoodsInWarehouses(), "");
			QueryTexts.Add(TempTableBalancesOnControlTakingIntoAccountRegisteredRecordsOfDocument(), "");
			Query.SetParameter("TableOfGoodsInWarehouses", TableOfGoodsInWarehouses);
		Else
			QueryTexts.Add(TempTableBalancesOnControl(), "");
		EndIf;
	EndIf;
	
	QueryTexts.Add(TempTableDocumentAttributes(),               "");
	QueryTexts.Add(TempTableOfCompletedStudies(),          "");
	QueryTexts.Add(TempTableOfCompletedActs(),                  "");
	QueryTexts.Add(StatusCalculationQueryText(),              "Table");
	
	Query.SetParameter("RequestForControl", Lot);
	Query.SetParameter("ControlledLotReference", StateTableOfQualityControlApplications[0].ControlledLotReference);
	Query.SetParameter("Recorder", StateTableOfQualityControlApplications[0].Recorder);
	
	Tables = TMCommonUse.UploadResultsOfQuery(Query, QueryTexts, , True);

	RecordStates(Tables.Table);
	
EndProcedure

#EndRegion

// Reflects changes in order States in the register.
//
// Parameters:
//  Request - DocumentRef.RequestForGoodsQualityControl
//  Errors - Undefined, Map of KeyAndValue - with structure:
//                          *Key     - DocumentRef -
//                          *Value - String - detailed representation of the error.
//
Procedure ReflectStateOfApplications(Request, Errors = Undefined) Export
	
	Table = TableOfChangesInStatesOfApplication(Request);
	RecordStates(Table, Errors);
	
EndProcedure

#EndRegion

#Region Private

Function TableOfChangesInStatesOfApplication(Request)
	
	SetPrivilegedMode(True);
	
	Analysts = QualityControl.AnalystsOfReceivedGoods(Request);
	DataTable = QualityControl.AnalystBalances(Analysts, False, Undefined);
	
	QueryTexts = New ValueList();
	QueryTexts.Add(TempTableDocumentAttributes(),               "");
	QueryTexts.Add(TempTableOfCompletedStudies(),          "");
	QueryTexts.Add(TempTableOfCompletedActs(),                  "");
	QueryTexts.Add(QueryTextForCalculatingStatesForResearch(), "Table");
	
	Query = New Query();
	
	If DataTable.Count() = 0 Then
		Query.SetParameter("ThereIsBalanceOfItemsUnderControl", False);
	Else
		Query.SetParameter("ThereIsBalanceOfItemsUnderControl", True);
	EndIf;
	
	Query.SetParameter("RequestForControl", Request);
	
	Tables = TMCommonUse.UploadResultsOfQuery(Query, QueryTexts, , True);

	Return Tables.Table;

EndFunction

Function QueryTextForCalculatingStatesForResearch()
	
	QueryText =
		"SELECT
		|	Table.Ref                        AS Request,
		|	Table.State                     AS State
		|FROM(
		|SELECT
		|	TTDocumentDetails.Ref AS Ref,
		|
		|	CASE WHEN NOT TTDocumentDetails.Posted THEN
		|
		|			VALUE(Enum.StatesOfResearchRequests.EmptyRef)
		|
		|		WHEN NOT &ThereIsBalanceOfItemsUnderControl THEN
		|
		|			VALUE(Enum.StatesOfResearchRequests.Completed_)
		|
		|		WHEN ISNULL(TTStudiesPerformed.TotalCount1, 0) = ISNULL(TTStudiesPerformed.NumberOfCompleted, 0)
		|			AND NOT TTIssuedCertificates.Ref IS NULL THEN
		|
		|			VALUE(Enum.StatesOfResearchRequests.PendingCertificateProcessing)
		|
		|		WHEN NOT TTStudiesPerformed.Ref IS NULL AND 
		|			ISNULL(TTStudiesPerformed.TotalCount1, 0) = ISNULL(TTStudiesPerformed.NumberOfCompleted, 0)
		|			 AND  ISNULL(TTStudiesPerformed.NumberOfCompleted, 0) <> 0 THEN
		|
		|			VALUE(Enum.StatesOfResearchRequests.ResearchCompleted)
		|
		|		WHEN NOT TTStudiesPerformed.Ref IS NULL AND 
		|			ISNULL(TTStudiesPerformed.TotalCount1, 0) > ISNULL(TTStudiesPerformed.NumberOfCompleted, 0)
		|			 AND  ISNULL(TTStudiesPerformed.TotalCount1, 0) <> 0 THEN
		|
		|			VALUE(Enum.StatesOfResearchRequests.InResearchProcess)
		|
		|		WHEN NOT TTStudiesPerformed.Ref IS NULL THEN
		|
		|			VALUE(Enum.StatesOfResearchRequests.PendingResearch)
		|
		|		ELSE
		|
		|			VALUE(Enum.StatesOfResearchRequests.PendingResearch)
		|
		|	END AS State
		|
		|FROM
		|	TTDocumentDetails AS TTDocumentDetails
		|
		|		LEFT JOIN TTStudiesPerformed AS TTStudiesPerformed
		|		ON TTStudiesPerformed.Ref = TTDocumentDetails.Ref
		|
		|		LEFT JOIN TTIssuedCertificates AS TTIssuedCertificates
		|		ON TTIssuedCertificates.Ref = TTDocumentDetails.Ref) AS Table";
	
	Return QueryText;
	
EndFunction

Function StatusCalculationQueryText()
	
	QueryText =
		"SELECT
		|	Table.Ref                        AS Request,
		|	Table.State                     AS State
		|FROM(
		|SELECT
		|	TTDocumentDetails.Ref AS Ref,
		|
		|	CASE WHEN NOT TTDocumentDetails.Posted THEN
		|
		|			VALUE(Enum.StatesOfResearchRequests.EmptyRef)
		|
		|		WHEN GoodsInTTWarehouses.ControlledLotReference IS NULL THEN
		|
		|			VALUE(Enum.StatesOfResearchRequests.Completed_)
		|
		|		WHEN ISNULL(TTStudiesPerformed.TotalCount1, 0) = ISNULL(TTStudiesPerformed.NumberOfCompleted, 0)
		|			AND NOT TTIssuedCertificates.Ref IS NULL THEN
		|
		|			VALUE(Enum.StatesOfResearchRequests.PendingCertificateProcessing)
		|
		|		WHEN NOT TTStudiesPerformed.Ref IS NULL AND 
		|			ISNULL(TTStudiesPerformed.TotalCount1, 0) = ISNULL(TTStudiesPerformed.NumberOfCompleted, 0)
		|			 AND  ISNULL(TTStudiesPerformed.NumberOfCompleted, 0) <> 0 THEN
		|
		|			VALUE(Enum.StatesOfResearchRequests.ResearchCompleted)
		|
		|		WHEN NOT TTStudiesPerformed.Ref IS NULL AND 
		|			ISNULL(TTStudiesPerformed.TotalCount1, 0) > ISNULL(TTStudiesPerformed.NumberOfCompleted, 0)
		|			 AND  ISNULL(TTStudiesPerformed.TotalCount1, 0) <> 0 THEN
		|
		|			VALUE(Enum.StatesOfResearchRequests.InResearchProcess)
		|
		|		WHEN NOT TTStudiesPerformed.Ref IS NULL THEN
		|
		|			VALUE(Enum.StatesOfResearchRequests.PendingResearch)
		|
		|		ELSE
		|
		|			VALUE(Enum.StatesOfResearchRequests.PendingResearch)
		|
		|	END AS State
		|
		|FROM
		|	TTDocumentDetails AS TTDocumentDetails
		|
		|		LEFT JOIN TTStudiesPerformed AS TTStudiesPerformed
		|		ON TTStudiesPerformed.Ref = TTDocumentDetails.Ref
		|
		|		LEFT JOIN TTIssuedCertificates AS TTIssuedCertificates
		|		ON TTIssuedCertificates.Ref = TTDocumentDetails.Ref
		|
		|		LEFT JOIN GoodsInTTWarehouses AS GoodsInTTWarehouses
		|		ON TRUE) AS Table";
	
	Return QueryText;
	
EndFunction

Function TempTableOfCompletedStudies()
	
	QueryText =
	"SELECT
	|	GoodsQualityResearch.RequestForControl AS Ref,
	|	COUNT(GoodsQualityResearch.Ref) AS TotalCount1,
	|	SUM(CASE
	|		WHEN GoodsQualityResearch.Completed = TRUE
	|			THEN 1
	|		ELSE 0
	|	END) AS NumberOfCompleted
	|INTO TTStudiesPerformed
	|FROM
	|	Document.GoodsQualityResearch AS GoodsQualityResearch
	|WHERE
	|	GoodsQualityResearch.RequestForControl = &RequestForControl
	|	AND GoodsQualityResearch.Posted = TRUE
	|GROUP BY
	|	GoodsQualityResearch.RequestForControl";
	
	Return QueryText
	
EndFunction

Function TempTableDocumentAttributes()
	
	QueryText =
		"SELECT
		|	Table.Ref AS Ref,
		|	Table.Posted AS Posted
		|INTO TTDocumentDetails
		|FROM
		|	Document.RequestForGoodsQualityControl AS Table
		|WHERE
		|	Table.Ref = &RequestForControl";
		
	Return QueryText;
	
EndFunction

Function AnalyticsTempTable()
	
	QueryText =
		"SELECT ALLOWED DISTINCT
		|	Goods.ControlledLotReference AS ControlledLotReference,
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.Warehouse AS Warehouse,
		|	Goods.Purpose AS Purpose,
		|	Goods.Premise AS Premise,
		|	Goods.Series AS Series
		|INTO AnalystsGoodsInWarehouses
		|FROM
		|	AccumulationRegister.ProductStock AS Goods
		|WHERE
		|	Goods.ControlledLotReference = &ControlledLotReference
		|";
		
	Return QueryText;
	
EndFunction

Function TempTableBalancesOnControl()
	
	QueryText =
			"SELECT TOP 1
			|	Set.ControlledLotReference AS ControlledLotReference,
			|	Set.Products AS Products,
			|	Set.Characteristic AS Characteristic,
			|	Set.Warehouse AS Warehouse,
			|	Set.Purpose AS Purpose,
			|	Set.Premise AS Premise,
			|	Set.Series AS Series,
			|	SUM(Set.Count) AS Count
			|INTO GoodsInTTWarehouses
			|FROM(
			|	SELECT
			|		ProductStock.ControlledLotReference AS ControlledLotReference,
			|		ProductStock.Products AS Products,
			|		ProductStock.Characteristic AS Characteristic,
			|		ProductStock.Warehouse AS Warehouse,
			|		ProductStock.Purpose AS Purpose,
			|		ProductStock.Premise AS Premise,
			|		ProductStock.Series AS Series,
			|		ProductStock.InStockBalance AS Count
			|	FROM
			|		AccumulationRegister.ProductStock.Balance(, (
			|				ControlledLotReference,
			|				Products,
			|				Characteristic,
			|				Warehouse,
			|				Purpose,
			|				Premise,
			|				Series)
			|			IN(
			|				SELECT
			|					Analysts.ControlledLotReference AS ControlledLotReference,
			|					Analysts.Products AS Products,
			|					Analysts.Characteristic AS Characteristic,
			|					Analysts.Warehouse AS Warehouse,
			|					Analysts.Purpose AS Purpose,
			|					Analysts.Premise AS Premise,
			|					Analysts.Series AS Series
			|				FROM
			|					AnalystsGoodsInWarehouses AS Analysts
			|				)) AS ProductStock
			|	WHERE
			|		ProductStock.InStockBalance <> 0
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		ProductStock.ControlledLotReference AS ControlledLotReference,
			|		ProductStock.Products AS Products,
			|		ProductStock.Characteristic AS Characteristic,
			|		ProductStock.Warehouse AS Warehouse,
			|		ProductStock.Purpose AS Purpose,
			|		ProductStock.Premise AS Premise,
			|		ProductStock.Series AS Series,
			|		CASE
			|			WHEN ProductStock.RecordType = VALUE(AccumulationRecordType.Receipt)
			|				THEN -ProductStock.InStock
			|			ELSE ProductStock.InStock
			|		END AS Count
			|	FROM
			|		AccumulationRegister.ProductStock AS ProductStock
			|	WHERE
			|		ProductStock.Recorder = &Recorder
			|		AND(
			|				ProductStock.ControlledLotReference,
			|				ProductStock.Products,
			|				ProductStock.Characteristic,
			|				ProductStock.Warehouse,
			|				ProductStock.Purpose,
			|				ProductStock.Premise,
			|				ProductStock.Series)
			|			IN(
			|				SELECT
			|					Analysts.ControlledLotReference AS ControlledLotReference,
			|					Analysts.Products AS Products,
			|					Analysts.Characteristic AS Characteristic,
			|					Analysts.Warehouse AS Warehouse,
			|					Analysts.Purpose AS Purpose,
			|					Analysts.Premise AS Premise,
			|					Analysts.Series AS Series
			|				FROM
			|					AnalystsGoodsInWarehouses AS Analysts)
			|				) AS Set
			|GROUP BY
			|	Set.ControlledLotReference,
			|	Set.Products,
			|	Set.Characteristic,
			|	Set.Warehouse,
			|	Set.Purpose,
			|	Set.Premise,
			|	Set.Series
			|HAVING
			|	SUM(Set.Count) > 0";
		
	Return QueryText;
	
EndFunction

Function TempTableOfGoodsInWarehouses()
	
	QueryText =
			"SELECT
			|	TableOfGoodsInWarehouses.ControlledLotReference AS ControlledLotReference,
			|	TableOfGoodsInWarehouses.Products AS Products,
			|	TableOfGoodsInWarehouses.Characteristic AS Characteristic,
			|	TableOfGoodsInWarehouses.Warehouse AS Warehouse,
			|	TableOfGoodsInWarehouses.Purpose AS Purpose,
			|	TableOfGoodsInWarehouses.Premise AS Premise,
			|	TableOfGoodsInWarehouses.Series AS Series,
			|	TableOfGoodsInWarehouses.RecordType AS RecordType,
			|	TableOfGoodsInWarehouses.InStock
			|INTO TTGoodsInWarehousesTable
			|FROM
			|	&TableOfGoodsInWarehouses AS TableOfGoodsInWarehouses";
		
	Return QueryText;
	
EndFunction

Function TempTableBalancesOnControlTakingIntoAccountRegisteredRecordsOfDocument()
	
	QueryText =
			"SELECT TOP 1
			|	Set.ControlledLotReference AS ControlledLotReference,
			|	Set.Products AS Products,
			|	Set.Characteristic AS Characteristic,
			|	Set.Warehouse AS Warehouse,
			|	Set.Purpose AS Purpose,
			|	Set.Premise AS Premise,
			|	Set.Series AS Series,
			|	SUM(Set.Count) AS Count
			|INTO GoodsInTTWarehouses
			|FROM(
			|	SELECT
			|		ProductStock.ControlledLotReference AS ControlledLotReference,
			|		ProductStock.Products AS Products,
			|		ProductStock.Characteristic AS Characteristic,
			|		ProductStock.Warehouse AS Warehouse,
			|		ProductStock.Purpose AS Purpose,
			|		ProductStock.Premise AS Premise,
			|		ProductStock.Series AS Series,
			|		ProductStock.InStockBalance AS Count
			|	FROM
			|		AccumulationRegister.ProductStock.Balance(, (
			|				ControlledLotReference,
			|				Products,
			|				Characteristic,
			|				Warehouse,
			|				Purpose,
			|				Premise,
			|				Series)
			|			IN(
			|				SELECT
			|					Analysts.ControlledLotReference AS ControlledLotReference,
			|					Analysts.Products AS Products,
			|					Analysts.Characteristic AS Characteristic,
			|					Analysts.Warehouse AS Warehouse,
			|					Analysts.Purpose AS Purpose,
			|					Analysts.Premise AS Premise,
			|					Analysts.Series AS Series
			|				FROM
			|					AnalystsGoodsInWarehouses AS Analysts
			|				)) AS ProductStock
			|	WHERE
			|		ProductStock.InStockBalance <> 0
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		ProductStock.ControlledLotReference AS ControlledLotReference,
			|		ProductStock.Products AS Products,
			|		ProductStock.Characteristic AS Characteristic,
			|		ProductStock.Warehouse AS Warehouse,
			|		ProductStock.Purpose AS Purpose,
			|		ProductStock.Premise AS Premise,
			|		ProductStock.Series AS Series,
			|		CASE
			|			WHEN ProductStock.RecordType = VALUE(AccumulationRecordType.Receipt)
			|				THEN -ProductStock.InStock
			|			ELSE ProductStock.InStock
			|		END AS Count
			|	FROM
			|		AccumulationRegister.ProductStock AS ProductStock
			|	WHERE
			|		ProductStock.Recorder = &Recorder
			|		AND(
			|				ProductStock.ControlledLotReference,
			|				ProductStock.Products,
			|				ProductStock.Characteristic,
			|				ProductStock.Warehouse,
			|				ProductStock.Purpose,
			|				ProductStock.Premise,
			|				ProductStock.Series)
			|			IN(
			|				SELECT
			|					Analysts.ControlledLotReference AS ControlledLotReference,
			|					Analysts.Products AS Products,
			|					Analysts.Characteristic AS Characteristic,
			|					Analysts.Warehouse AS Warehouse,
			|					Analysts.Purpose AS Purpose,
			|					Analysts.Premise AS Premise,
			|					Analysts.Series AS Series
			|				FROM
			|					AnalystsGoodsInWarehouses AS Analysts)
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		ProductStock.ControlledLotReference AS ControlledLotReference,
			|		ProductStock.Products AS Products,
			|		ProductStock.Characteristic AS Characteristic,
			|		ProductStock.Warehouse AS Warehouse,
			|		ProductStock.Purpose AS Purpose,
			|		ProductStock.Premise AS Premise,
			|		ProductStock.Series AS Series,
			|		CASE
			|			WHEN ProductStock.RecordType = VALUE(AccumulationRecordType.Receipt)
			|				THEN ProductStock.InStock
			|			ELSE -ProductStock.InStock
			|		END AS Count
			|	FROM
			|		TTGoodsInWarehousesTable AS ProductStock
			|	WHERE
			|		ProductStock.ControlledLotReference = &ControlledLotReference
			|) AS Set
			|GROUP BY
			|	Set.ControlledLotReference,
			|	Set.Products,
			|	Set.Characteristic,
			|	Set.Warehouse,
			|	Set.Purpose,
			|	Set.Premise,
			|	Set.Series
			|HAVING
			|	SUM(Set.Count) > 0";
		
	Return QueryText;
	
EndFunction

Function TempTableOfCompletedActs()
	
	QueryText =
	"SELECT
	|	SUM(CASE
	|		WHEN Table.Status = VALUE(Enum.StatusesOfQualityControlCertificates.IsProcessed)
	|			THEN 1
	|		ELSE 0
	|	END) AS NumberOfSpent,
	|	SUM(CASE
	|		WHEN Table.Status <> VALUE(Enum.StatusesOfQualityControlCertificates.IsProcessed)
	|			THEN 1
	|		ELSE 0
	|	END) AS NumberOfIssued,
	|	CAST(ControlledLots.Lot AS Document.RequestForGoodsQualityControl) AS Ref
	|INTO TTIssuedCertificates
	|FROM
	|	Document.GoodsQualityControlCertificate AS Table
	|		LEFT JOIN Catalog.ControlledLots AS ControlledLots
	|		ON Table.ControlledLotReference = ControlledLots.Ref
	|WHERE
	|	CAST(ControlledLots.Lot AS Document.RequestForGoodsQualityControl) = &RequestForControl
	|	AND Table.Posted = TRUE
	|GROUP BY
	|	CAST(ControlledLots.Lot AS Document.RequestForGoodsQualityControl)";
		
	Return QueryText;
	
EndFunction

Procedure RecordStates(Table, Errors = Undefined)
	
	SetPrivilegedMode(True);
	
	For Each TableRow In Table Do
	
		Set = InformationRegisters.RequestStatesForQualityControl.CreateRecordSet();
		Set.Filter.Request.Set(TableRow.Request);
		
		If Not TableRow.State.IsEmpty() Then
			SetRow = Set.Add();
			FillPropertyValues(SetRow, TableRow);
		EndIf;
		
		Try
			Set.Write(True);
		Except
			
			Request = TableRow.Request;
			
			ErrorText = StrTemplate(NStr("vi = 'Không thể phản ánh trạng thái của Giấy đề nghị: %1 với lý do: %2';
										|ru = 'Не удалось отразить состояние Заявкаи: %1 по причине: %2';
										|en = 'Cannot record the %1 request state. Reason: %2'; fa = 'Cannot record the %1 request state. Reason: %2';
										|it = 'Cannot record the %1 request state. Reason: %2';
										|pl = 'Cannot record the %1 request state. Reason: %2';
										|tr = 'Talep durumu yansıtılamadı: %1, nedeni: %2'"),
									Request,
									ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			
			WriteLogEvent(
				EventLogEvent(),
				EventLogLevel.Warning,
				Request.Metadata(),
				Request,
				ErrorText);
			
			If Errors <> Undefined Then
				Errors.Insert(TableRow.Request, ErrorText);
			EndIf;
			
		EndTry;
		
	EndDo;
	
EndProcedure

Function EventLogEvent()
	
	Return NStr("vi = 'Lỗi phản ánh trạng thái của giấy đề nghị kiểm soát chất lượng hàng hóa';
				|ru = 'Ошибка отражения состояния заявки на контроль контроль качества товаров';
				|en = 'An error occurred when recording the state of the request for goods quality control'; fa = 'An error occurred when recording the state of the request for goods quality control';
				|it = 'An error occurred when recording the state of the request for goods quality control';
				|pl = 'An error occurred when recording the state of the request for goods quality control';
				|tr = 'Ürün kalite kontrol talebi durumu yansıtma hatası'", Common.DefaultLanguageCode());
	
EndFunction

#EndRegion

#EndIf
